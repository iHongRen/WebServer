/**
 * @fileName : ConnectionPool.ets
 * @author : @cxy
 * @date : 2025/4/11
 * @description : 连接池管理器 - 优化连接复用和资源管理
 */

import { socket } from '@kit.NetworkKit';

/**
 * 连接信息接口
 */
export interface ConnectionInfo {
  socket: socket.TCPSocketConnection | socket.TLSSocketConnection;
  clientId: number;
  createdAt: number;
  lastActivity: number;
  requestCount: number;
  isActive: boolean;
}

/**
 * 连接池配置
 */
export interface PoolConfig {
  maxConnections?: number; // 最大连接数
  connectionTimeout?: number; // 连接超时时间（毫秒）
  idleTimeout?: number; // 空闲超时时间（毫秒）
  cleanupInterval?: number; // 清理间隔（毫秒）
}

/**
 * 连接池管理器
 * 优化连接管理，提升性能和稳定性
 */
export class ConnectionPool {
  private connections: Map<number, ConnectionInfo> = new Map();
  private config: Required<PoolConfig>;
  private cleanupTimer: number | null = null;

  constructor(config?: PoolConfig) {
    this.config = {
      maxConnections: config?.maxConnections ?? 1000,
      connectionTimeout: config?.connectionTimeout ?? 30000,
      idleTimeout: config?.idleTimeout ?? 60000,
      cleanupInterval: config?.cleanupInterval ?? 10000
    };

    this.startCleanup();
  }

  /**
   * 添加连接到池
   */
  public add(socket: socket.TCPSocketConnection | socket.TLSSocketConnection): boolean {
    if (this.connections.size >= this.config.maxConnections) {
      return false;
    }

    const now = Date.now();
    const info: ConnectionInfo = {
      socket,
      clientId: socket.clientId,
      createdAt: now,
      lastActivity: now,
      requestCount: 0,
      isActive: true
    };

    this.connections.set(socket.clientId, info);
    return true;
  }

  /**
   * 更新连接活动时间
   */
  public updateActivity(clientId: number): void {
    const conn = this.connections.get(clientId);
    if (conn) {
      conn.lastActivity = Date.now();
      conn.requestCount++;
    }
  }

  /**
   * 移除连接
   */
  public remove(clientId: number): void {
    const conn = this.connections.get(clientId);
    if (conn) {
      conn.isActive = false;
      this.connections.delete(clientId);
    }
  }

  /**
   * 获取连接信息
   */
  public get(clientId: number): ConnectionInfo | undefined {
    return this.connections.get(clientId);
  }

  /**
   * 获取所有连接
   */
  public getAll(): ConnectionInfo[] {
    return Array.from(this.connections.values());
  }

  /**
   * 获取连接数
   */
  public size(): number {
    return this.connections.size;
  }

  /**
   * 停止清理并关闭所有连接
   */
  public async destroy(): Promise<void> {
    if (this.cleanupTimer !== null) {
      clearInterval(this.cleanupTimer);
      this.cleanupTimer = null;
    }
    const closePromises: Promise<void>[] = [];
    this.connections.forEach((conn) => {
      closePromises.push(conn.socket.close().catch(() => {
      }));
    });
    await Promise.all(closePromises);
    this.connections.clear();
  }

  /**
   * 清理过期连接
   */
  private async cleanup(): Promise<void> {
    const now = Date.now();
    const toRemove: number[] = [];

    this.connections.forEach((conn, clientId) => {
      const idleTime = now - conn.lastActivity;
      const totalTime = now - conn.createdAt;

      if (idleTime > this.config.idleTimeout || totalTime > this.config.connectionTimeout) {
        toRemove.push(clientId);
      }
    });

    for (const clientId of toRemove) {
      const conn = this.connections.get(clientId);
      if (conn) {
        try {
          await conn.socket.close();
        } catch (e) {
          // 忽略关闭错误
        }
        this.remove(clientId);
      }
    }
  }

  /**
   * 启动定期清理
   */
  private startCleanup(): void {
    this.cleanupTimer = setInterval(() => {
      this.cleanup();
    }, this.config.cleanupInterval);
  }
}
