/**
 * @fileName : HttpResponse.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : HTTP 响应构建类
 */

import { socket } from '@kit.NetworkKit';
import { StatusCode } from './StatusCode';
import { Utils } from './Utils';


/**
 * 响应完成回调函数类型
 */
export type ResponseFinishCallback = (statusCode: number, responseSize: number) => void;

/**
 * HTTP响应类
 * 用于构建和发送HTTP响应
 * 支持普通响应和流式传输
 */
export class HttpResponse {
  private socket: socket.TCPSocketConnection | socket.TLSSocketConnection
  private statusCode: number = 200; // HTTP状态码
  private headers: Map<string, string> = new Map(); // 响应头集合
  private _headersSent: boolean = false; // 响应头是否已发送
  private finishCallbacks: ResponseFinishCallback[] = []; // 响应完成回调列表
  private _finished: boolean = false; // 响应是否已完成
  private totalBytesSent: number = 0; // 已发送的总字节数
  private isChunked: boolean = false; // 是否使用分块传输编码

  /**
   * 构造函数
   * @param socket TCP或TLS连接对象
   */
  constructor(socket: socket.TCPSocketConnection | socket.TLSSocketConnection) {
    this.socket = socket;
    // 设置默认响应头
    this.setHeader('Connection', 'keep-alive');
  }

  /**
   * 检查响应头是否已发送
   * @returns 是否已发送
   */
  public isHeadersSent(): boolean {
    return this._headersSent;
  }

  /**
   * 检查响应是否已完成
   * @returns 是否已完成
   */
  public isFinished(): boolean {
    return this._finished;
  }

  /**
   * 获取响应头
   * @param name 响应头名称
   * @returns 响应头值
   */
  public getHeader(name: string): string | undefined {
    return this.headers.get(name);
  }

  /**
   * 设置响应头
   * @param name 响应头名称
   * @param value 响应头值
   * @returns 当前响应对象（支持链式调用）
   */
  public setHeader(name: string, value: string): HttpResponse {
    if (this._headersSent) {
      console.error("Cannot set headers after they are sent.");
      return this;
    }
    this.headers.set(name, value);
    return this;
  }

  /**
   * 移除响应头
   * @param name 响应头名称
   * @returns 当前响应对象（支持链式调用）
   */
  public removeHeader(name: string): HttpResponse {
    if (this._headersSent) {
      console.error("Cannot remove headers after they are sent.");
      return this;
    }
    this.headers.delete(name);
    return this;
  }

  /**
   * 设置HTTP状态码
   * @param code 状态码
   * @returns 当前响应对象（支持链式调用）
   */
  public status(code: number): HttpResponse {
    this.statusCode = code;
    return this;
  }

  /**
   * 获取当前状态码
   * @returns 状态码
   */
  public getStatusCode(): number {
    return this.statusCode;
  }

  /**
   * 添加响应完成回调
   * @param callback 回调函数
   */
  public onFinish(callback: ResponseFinishCallback): void {
    this.finishCallbacks.push(callback);
  }

  /**
   * 发送响应头
   * 在流式传输中，需要先发送响应头
   */
  private async sendHeaders(): Promise<void> {
    if (this._headersSent) {
      return;
    }

    // 如果没有设置Content-Length且不是分块传输，则使用分块传输
    if (!this.headers.has('Content-Length') && !this.headers.has('Transfer-Encoding')) {
      this.setHeader('Transfer-Encoding', 'chunked');
      this.isChunked = true;
    } else if (this.headers.get('Transfer-Encoding') === 'chunked') {
      this.isChunked = true;
      // 分块传输时不能有Content-Length
      this.removeHeader('Content-Length');
    }

    const statusText = StatusCode[this.statusCode] || 'OK';
    let headerString = `HTTP/1.1 ${this.statusCode} ${statusText}\r\n`;
    this.headers.forEach((value, name) => {
      headerString += `${name}: ${value}\r\n`;
    });
    headerString += '\r\n';

    const headerBytes = Utils.strToArrayBuffer(headerString);
    await this.sendToSocket(headerBytes);
    this._headersSent = true;
  }

  /**
   * 写入数据块（流式传输）
   * @param chunk 数据块（字符串或ArrayBuffer）
   * @param encoding 编码（可选，默认utf-8）
   * @returns Promise<boolean> 是否成功写入
   */
  public async write(chunk: string | ArrayBuffer, encoding?: string): Promise<boolean> {
    if (this._finished) {
      console.error("Cannot write after response has finished.");
      return false;
    }

    try {
      // 如果响应头未发送，先发送响应头
      if (!this._headersSent) {
        await this.sendHeaders();
      }

      const chunkBytes = this.getBodyBytes(chunk);
      
      if (this.isChunked) {
        // 分块传输编码格式：
        // 十六进制长度\r\n
        // 数据\r\n
        const chunkSize = chunkBytes.byteLength;
        const chunkHeader = `${chunkSize.toString(16)}\r\n`;
        const chunkHeaderBytes = Utils.strToArrayBuffer(chunkHeader);
        const chunkFooter = Utils.strToArrayBuffer('\r\n');
        
        const fullChunk = Utils.mergeArrayBuffers(
          chunkHeaderBytes,
          Utils.mergeArrayBuffers(chunkBytes, chunkFooter)
        );
        
        await this.sendToSocket(fullChunk);
      } else {
        // 非分块传输，直接发送数据
        await this.sendToSocket(chunkBytes);
      }

      this.totalBytesSent += chunkBytes.byteLength;
      return true;
    } catch (error) {
      console.error("Error writing chunk:", error);
      return false;
    }
  }

  /**
   * 结束响应（流式传输）
   * @param chunk 可选的最后一块数据
   * @param encoding 编码（可选）
   */
  public async end(chunk?: string | ArrayBuffer, encoding?: string): Promise<void> {
    if (this._finished) {
      console.error("Response already finished.");
      return;
    }

    try {
      // 如果有最后一块数据，先写入
      if (chunk !== undefined) {
        await this.write(chunk, encoding);
      }

      // 如果响应头未发送，先发送响应头
      if (!this._headersSent) {
        await this.sendHeaders();
      }

      // 如果是分块传输，发送结束标记
      if (this.isChunked) {
        const endChunk = Utils.strToArrayBuffer('0\r\n\r\n');
        await this.sendToSocket(endChunk);
      }

      this._finished = true;

      // 触发响应完成回调
      this.triggerFinishCallbacks(this.totalBytesSent);
    } catch (error) {
      console.error("Error ending response:", error);
      this._finished = true;
    }
  }

  /**
   * 发送响应数据（非流式，一次性发送）
   * @param body 响应体数据
   */
  public async send(body?: string | ArrayBuffer): Promise<void> {
    if (this._headersSent) {
      console.error("Headers already sent.");
      return;
    }

    if (this._finished) {
      console.error("Response already finished.");
      return;
    }

    const bodyBytes = this.getBodyBytes(body);
    const responseSize = bodyBytes.byteLength;

    // 如果是字符串且未设置Content-Type，则默认为text/html
    if (typeof body === 'string' && !this.headers.has('Content-Type')) {
      this.setHeader('Content-Type', 'text/html; charset=utf-8');
    }

    this.setHeader('Content-Length', responseSize.toString());

    const statusText = StatusCode[this.statusCode] || 'OK';
    let headerString = `HTTP/1.1 ${this.statusCode} ${statusText}\r\n`;
    this.headers.forEach((value, name) => {
      headerString += `${name}: ${value}\r\n`;
    });
    headerString += '\r\n';

    const headerBytes = Utils.strToArrayBuffer(headerString);
    const responseData = Utils.mergeArrayBuffers(headerBytes, bodyBytes);

    await this.sendToSocket(responseData);
    this._headersSent = true;
    this._finished = true;
    this.totalBytesSent = responseSize;

    // 触发响应完成回调
    this.triggerFinishCallbacks(responseSize);
  }

  /**
   * 发送JSON响应
   * @param data 要序列化为JSON的数据
   */
  public async json(data: ESObject): Promise<void> {
    this.setHeader('Content-Type', 'application/json; charset=utf-8');
    const jsonString = JSON.stringify(data);
    await this.send(jsonString);
  }

  /**
   * 发送到Socket
   * @param data 要发送的数据
   */
  private async sendToSocket(data: ArrayBuffer): Promise<void> {
    // 通过判断属性是否为 undefined 来确定 socket 类型
    if ((this.socket as socket.TLSSocketConnection).getRemoteCertificate !== undefined) {
      await (this.socket as socket.TLSSocketConnection).send(data);
    } else {
      await (this.socket as socket.TCPSocketConnection).send({ data: data });
    }
  }

  /**
   * 触发响应完成回调
   * @param responseSize 响应大小
   */
  private triggerFinishCallbacks(responseSize: number): void {
    this.finishCallbacks.forEach(callback => {
      try {
        callback(this.statusCode, responseSize);
      } catch (error) {
        console.error('响应完成回调执行错误:', error);
      }
    });
  }

  /**
   * 将响应体转换为ArrayBuffer
   * @param body 响应体数据
   * @returns ArrayBuffer格式的数据
   */
  private getBodyBytes(body?: string | ArrayBuffer): ArrayBuffer {
    if (typeof body === 'string') {
      return Utils.strToArrayBuffer(body);
    } else if (body instanceof ArrayBuffer) {
      return body;
    }
    return new ArrayBuffer(0);
  }
}
