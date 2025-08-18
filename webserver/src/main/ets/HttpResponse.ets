/**
 * @fileName : HttpResponse.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : HTTP 响应构建类
 */

import { socket } from '@kit.NetworkKit';
import { Utils } from './Utils';

/**
 * HTTP状态码映射表
 */
const STATUS_CODES: Record<number, string> = {
  200: 'OK',
  201: 'Created',
  204: 'No Content',
  400: 'Bad Request',
  404: 'Not Found',
  500: 'Internal Server Error'
};

/**
 * HTTP响应类
 * 用于构建和发送HTTP响应
 */
export class HttpResponse {
  private socket: socket.TCPSocketConnection; // TCP连接
  private statusCode: number = 200; // HTTP状态码
  private headers: Map<string, string> = new Map(); // 响应头集合
  private _headersSent: boolean = false; // 响应头是否已发送

  /**
   * 构造函数
   * @param socket TCP连接对象
   */
  constructor(socket: socket.TCPSocketConnection) {
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
   * 发送响应数据
   * @param body 响应体数据
   */
  public async send(body?: string | ArrayBuffer): Promise<void> {
    if (this._headersSent) {
      console.error("Headers already sent.");
      return;
    }

    const bodyBytes = this.getBodyBytes(body);
    this.setHeader('Content-Length', bodyBytes.byteLength.toString());

    const statusText = STATUS_CODES[this.statusCode] || 'OK';
    let headerString = `HTTP/1.1 ${this.statusCode} ${statusText}\r\n`;
    this.headers.forEach((value, name) => {
      headerString += `${name}: ${value}\r\n`;
    });
    headerString += '\r\n';

    const headerBytes = Utils.strToArrayBuffer(headerString);
    const responseData = Utils.mergeArrayBuffers(headerBytes, bodyBytes);

    await this.socket.send({ data: responseData });
    this._headersSent = true;
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
