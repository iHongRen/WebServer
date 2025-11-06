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
 */
export class HttpResponse {
  private socket: socket.TCPSocketConnection | socket.TLSSocketConnection
  private statusCode: number = 200; // HTTP状态码
  private headers: Map<string, string> = new Map(); // 响应头集合
  private _headersSent: boolean = false; // 响应头是否已发送
  private finishCallbacks: ResponseFinishCallback[] = []; // 响应完成回调列表

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
   * 获取相应头
   * @param name 响应头名称
   * @returns
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
    this.headers.set(name, value);
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
   * 发送响应数据
   * @param body 响应体数据
   */
  public async send(body?: string | ArrayBuffer): Promise<void> {
    if (this._headersSent) {
      console.error("Headers already sent.");
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

    // 通过判断属性是否为 undefined 来确定 socket 类型
    if ((this.socket as socket.TLSSocketConnection).getRemoteCertificate !== undefined) {
      await (this.socket as socket.TLSSocketConnection).send(responseData);
    } else {
      await (this.socket as socket.TCPSocketConnection).send({ data: responseData });
    }
    this._headersSent = true;

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
