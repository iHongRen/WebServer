/**
 * @fileName : UploadStream.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : 流式上传支持 - 提供边接收边处理的请求体流对象
 * https://github.com/iHongRen/WebServer
 */

/**
 * 数据块事件回调
 */
export type ChunkHandler = (chunk: ArrayBuffer) => void | Promise<void>;

/**
 * 结束事件回调
 */
export type EndHandler = () => void | Promise<void>;

/**
 * 流错误事件回调
 */
export type StreamErrorHandler = (error: Error) => void;

/**
 * 流状态枚举
 */
export enum StreamState {
  IDLE = 'idle',
  FLOWING = 'flowing',
  ENDED = 'ended',
  ERRORED = 'errored',
}

/**
 * UploadStream - 请求体流对象
 *
 * 用于流式处理上传数据，边接收 TCP 数据包边处理，
 * 无需等待整个请求体完全到达内存。
 *
 * 使用示例：
 * ```
 * server.post('/upload', streamUpload(), (req, res) => {
 *   const stream = req.uploadStream!;
 *   stream.on('data', (chunk) => { ... });  // 每个 TCP 包触发
 *   stream.on('end', () => res.json({ ok: true }));
 * });
 * ```
 */
export class UploadStream {
  /** 期望接收的总字节数（来自 Content-Length），-1 表示未知（chunked） */
  public readonly contentLength: number;
  /** 已接收字节数 */
  public bytesReceived: number = 0;

  private state: StreamState = StreamState.IDLE;
  private chunkHandlers: ChunkHandler[] = [];
  private endHandlers: EndHandler[] = [];
  private errorHandlers: StreamErrorHandler[] = [];

  // 在 handlers 注册前到达的 chunks 暂存队列（背压缓冲）
  private pendingChunks: ArrayBuffer[] = [];
  private ended: boolean = false;
  private endedError: Error | null = null;
  // end/error 是否已实际触发（与 ended 区分：ended 表示输入端结束，endTriggered 表示输出端已派发）
  private endTriggered: boolean = false;
  private errorTriggered: boolean = false;

  // 串行化 Promise 链：保证多个 async data handler 按顺序执行，不并发
  private dispatchChain: Promise<void> = Promise.resolve();

  constructor(contentLength: number) {
    this.contentLength = contentLength;
  }

  /**
   * 注册事件监听器
   * @param event 'data' | 'end' | 'error'
   * @param handler 回调函数
   */
  public on(event: string, handler: ChunkHandler | EndHandler | StreamErrorHandler): UploadStream {
    if (event === 'data') {
      // 已 end 或 error 后再注册 data 监听器无意义（也不会再有数据），直接忽略
      if (this.state === StreamState.ENDED || this.state === StreamState.ERRORED) {
        return this;
      }
      this.chunkHandlers.push(handler as ChunkHandler);
      this.state = StreamState.FLOWING;

      // 若注册 data 之前已有 pending chunks，串到链上依次消费
      if (this.pendingChunks.length > 0) {
        const chunks = this.pendingChunks.slice();
        this.pendingChunks = [];
        for (const chunk of chunks) {
          this.dispatchChain = this.dispatchChain
            .then(() => this.dispatchChunk(chunk))
            .catch((err: Error) => this._error(err));
        }
        // 若此时已经 ended，等链上所有 chunk 处理完再触发 end
        if (this.ended && this.endedError === null) {
          this.dispatchChain = this.dispatchChain.then(() => {
            if (this.state !== StreamState.ERRORED && !this.endTriggered) {
              this.state = StreamState.ENDED;
              this.triggerEnd();
            }
          }).catch((err: Error) => this._error(err));
        }
      }
    } else if (event === 'end') {
      // 已 end 或 error 后再注册 end：仅当尚未触发过 end 时立即派发
      if (this.ended && this.endedError === null && !this.endTriggered) {
        this.endHandlers.push(handler as EndHandler);
        this.triggerEnd();
      } else {
        this.endHandlers.push(handler as EndHandler);
      }
    } else if (event === 'error') {
      // 已 error 后再注册 error：仅当尚未触发过 error 时立即派发
      if (this.ended && this.endedError !== null && !this.errorTriggered) {
        this.errorHandlers.push(handler as StreamErrorHandler);
        this.triggerError(this.endedError);
      } else {
        this.errorHandlers.push(handler as StreamErrorHandler);
      }
    }
    return this;
  }

  /**
   * 获取当前流状态
   */
  public getState(): StreamState {
    return this.state;
  }

  /**
   * 获取上传进度 (0~1)，仅在 Content-Length 已知时有效
   */
  public get progress(): number {
    if (this.contentLength <= 0) {
      return -1;
    }
    return Math.min(this.bytesReceived / this.contentLength, 1);
  }

  // ==================== 内部方法（由 HttpServer 调用）====================

  /**
   * 推送一个数据块（由 HttpServer message 回调调用）
   * @internal
   */
  public _push(chunk: ArrayBuffer): void {
    // 已 end（含 end 触发后）或 error：丢弃后续数据，防止 end 后的 data 触发二次 end
    if (this.ended || this.state === StreamState.ENDED || this.state === StreamState.ERRORED) {
      return;
    }

    this.bytesReceived += chunk.byteLength;

    if (this.chunkHandlers.length === 0) {
      // 还没有 data 监听器，先缓存
      this.pendingChunks.push(chunk);
    } else {
      // 串到全局链上，保证每个 chunk 严格按顺序执行，不并发
      this.dispatchChain = this.dispatchChain
        .then(() => this.dispatchChunk(chunk))
        .catch((err: Error) => this._error(err));
    }
  }

  /**
   * 标记流结束（由 HttpServer 调用）
   * @internal
   */
  public _end(): void {
    // 重复 _end 调用直接忽略，防止 triggerEnd 二次触发
    if (this.ended) {
      return;
    }
    this.ended = true;
    if (this.state === StreamState.ERRORED) {
      return;
    }

    // 等所有正在进行的 chunk 处理完成后，再触发 end
    this.dispatchChain = this.dispatchChain.then(() => {
      // 消费注册前积压的 pending chunks（若有）
      if (this.pendingChunks.length > 0) {
        const chunks = this.pendingChunks.slice();
        this.pendingChunks = [];
        let chain = Promise.resolve();
        for (const chunk of chunks) {
          chain = chain.then(() => this.dispatchChunk(chunk));
        }
        return chain;
      }
      return Promise.resolve();
    }).then(() => {
      if (this.state !== StreamState.ERRORED && !this.endTriggered) {
        this.state = StreamState.ENDED;
        this.triggerEnd();
      }
    }).catch((err: Error) => {
      this._error(err);
    });
  }

  /**
   * 标记流出错（由 HttpServer 调用）
   * @internal
   */
  public _error(err: Error): void {
    // 重复 _error 调用直接忽略，防止 triggerError 二次触发
    if (this.endedError !== null) {
      return;
    }
    this.endedError = err;
    this.ended = true;
    if (this.state === StreamState.ERRORED) {
      return;
    }
    this.state = StreamState.ERRORED;
    this.pendingChunks = [];
    this.triggerError(err);
  }

  // ==================== 私有方法 ====================

  private dispatchChunk(chunk: ArrayBuffer): Promise<void> {
    let chain = Promise.resolve();
    for (const handler of this.chunkHandlers) {
      chain = chain.then(() => {
        const result = handler(chunk);
        return result instanceof Promise ? result : Promise.resolve();
      });
    }
    return chain;
  }

  private triggerEnd(): void {
    // 防重入：on('end') 在 ended 状态下注册时可能多次调用
    if (this.endTriggered) {
      return;
    }
    this.endTriggered = true;
    for (const handler of this.endHandlers) {
      try {
        const result = handler();
        if (result instanceof Promise) {
          result.catch((err: Error) => this._error(err));
        }
      } catch (e) {
        this._error(e as Error);
      }
    }
  }

  private triggerError(err: Error): void {
    if (this.errorTriggered) {
      return;
    }
    this.errorTriggered = true;
    if (this.errorHandlers.length === 0) {
      console.error('[UploadStream] Unhandled stream error:', err.message);
      return;
    }
    for (const handler of this.errorHandlers) {
      try {
        (handler as StreamErrorHandler)(err);
      } catch (_) {
        // 忽略 error handler 自身的错误
      }
    }
  }
}
