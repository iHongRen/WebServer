/**
 * @fileName : ServerEvents.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : 服务器事件系统
 */

/**
 * 服务器错误类型枚举
 */
export enum ServerErrorType {
  STARTUP_FAILED = 'startup_failed',
  CONNECTION_ERROR = 'connection_error',
  CLIENT_ERROR = 'client_error',
  SOCKET_ERROR = 'socket_error',
  LISTEN_ERROR = 'listen_error',
  BIND_ERROR = 'bind_error',
  CERTIFICATE_ERROR = 'certificate_error',
  TLS_ERROR = 'tls_error',
  UNKNOWN_ERROR = 'unknown_error'
}

/**
 * 服务器事件类型枚举
 */
export enum ServerEventType {
  SERVER_STARTED = 'server_started',
  SERVER_STOPPED = 'server_stopped',
  ERROR = 'error',
  WARNING = 'warning',
  REQUEST_RECEIVED = 'request_received',
  RESPONSE_SENT = 'response_sent'
}

/**
 * 服务器错误信息接口
 */
export interface ServerError {
  type: ServerErrorType;
  error?: Error;
}

/**
 * 服务器事件信息接口
 */
export interface ServerEvent {
  type: ServerEventType;
  data?: ESObject;
}


/**
 * 事件监听器类型定义
 */
export type ErrorEventListener = (error: ServerError) => void;

export type ServerEventListener = (event: ServerEvent) => void;


/**
 * 服务器事件发射器类
 */
export class ServerEventEmitter {
  private errorListeners: ErrorEventListener[] = [];
  private eventListeners: Map<ServerEventType, ServerEventListener[]> = new Map();

  /**
   * 监听错误事件
   * @param listener 错误事件监听器
   */
  public onError(listener: ErrorEventListener): void {
    this.errorListeners.push(listener);
  }

  /**
   * 监听服务器事件
   * @param eventType 事件类型
   * @param listener 事件监听器
   */
  public on(eventType: ServerEventType, listener: ServerEventListener): void {
    if (!this.eventListeners.has(eventType)) {
      this.eventListeners.set(eventType, []);
    }
    this.eventListeners.get(eventType)!.push(listener);
  }

  /**
   * 发射错误事件
   * @param error 错误信息
   */
  public emitError(error: Error, type: ServerErrorType): void {
    this.errorListeners.forEach(listener => {
      try {
        listener({ error: error, type: type });
      } catch (e) {
        console.error('Error in error listener:', e);
      }
    });
  }

  /**
   * 发射服务器事件
   * @param event 事件信息
   */
  public emit(event: ServerEvent): void {
    const listeners = this.eventListeners.get(event.type);
    if (listeners) {
      listeners.forEach(listener => {
        try {
          listener(event);
        } catch (e) {
          console.error('Error in event listener:', e);
        }
      });
    }
  }

  /**
   * 移除错误监听器
   * @param listener 要移除的监听器
   */
  public removeErrorListener(listener: ErrorEventListener): void {
    const index = this.errorListeners.indexOf(listener);
    if (index > -1) {
      this.errorListeners.splice(index, 1);
    }
  }

  /**
   * 移除事件监听器
   * @param eventType 事件类型
   * @param listener 要移除的监听器
   */
  public removeListener(eventType: ServerEventType, listener: ServerEventListener): void {
    const listeners = this.eventListeners.get(eventType);
    if (listeners) {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  /**
   * 清除所有监听器
   */
  public removeAllListeners(): void {
    this.errorListeners = [];
    this.eventListeners.clear();
  }
}