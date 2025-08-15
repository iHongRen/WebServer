/**
 * @fileName : HttpResponse.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : HTTP 响应构建类
 */

import { socket } from '@kit.NetworkKit';
import { Utils } from './Utils';

const STATUS_CODES: Record<number, string> = {
  200: 'OK',
  201: 'Created',
  204: 'No Content',
  400: 'Bad Request',
  404: 'Not Found',
  500: 'Internal Server Error'
};

export class HttpResponse {
  private socket: socket.TCPSocketConnection;
  private statusCode: number = 200;
  private headers: Map<string, string> = new Map();
  private _headersSent: boolean = false;

  constructor(socket: socket.TCPSocketConnection) {
    this.socket = socket;
    // Default headers
    this.setHeader('Connection', 'keep-alive');
  }

  public isHeadersSent(): boolean {
    return this._headersSent;
  }

  public setHeader(name: string, value: string): HttpResponse {
    this.headers.set(name, value);
    return this;
  }

  public status(code: number): HttpResponse {
    this.statusCode = code;
    return this;
  }

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

  public async json(data: ESObject): Promise<void> {
    this.setHeader('Content-Type', 'application/json; charset=utf-8');
    const jsonString = JSON.stringify(data);
    await this.send(jsonString);
  }

  private getBodyBytes(body?: string | ArrayBuffer): ArrayBuffer {
    if (typeof body === 'string') {
      return Utils.strToArrayBuffer(body);
    } else if (body instanceof ArrayBuffer) {
      return body;
    }
    return new ArrayBuffer(0);
  }
}
