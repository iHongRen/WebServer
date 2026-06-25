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
            if (this.state !== StreamState.ERRORED) {
              this.state = StreamState.ENDED;
              this.triggerEnd();
            }
          }).catch((err: Error) => this._error(err));
        }
      }
    } else if (event === 'end') {
      this.endHandlers.push(handler as EndHandler);
      // 若注册 end 之前已经结束，立即触发
      if (this.ended && this.endedError === null) {
        this.triggerEnd();
      }
    } else if (event === 'error') {
      this.errorHandlers.push(handler as StreamErrorHandler);
      // 若注册 error 之前已经报错，立即触发
      if (this.ended && this.endedError !== null) {
        this.triggerError(this.endedError);
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
    if (this.state === StreamState.ENDED || this.state === StreamState.ERRORED) {
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
    this.ended = true;
    if (this.state === StreamState.ENDED || this.state === StreamState.ERRORED) {
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
      if (this.state !== StreamState.ERRORED) {
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
