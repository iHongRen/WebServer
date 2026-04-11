/**
 * @fileName : rateLimit.ets
 * @author : @cxy
 * @date : 2025/4/11
 * @description : 限流中间件 - 防止滥用和DDoS攻击
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';
import { NextFunction, RequestHandler } from './types';

/**
 * 限流配置
 */
export interface RateLimitOptions {
  windowMs?: number; // 时间窗口（毫秒）
  max?: number; // 最大请求数
  message?: string; // 超限提示消息
  statusCode?: number; // 超限状态码
  skipSuccessfulRequests?: boolean; // 跳过成功请求
  skipFailedRequests?: boolean; // 跳过失败请求
  keyGenerator?: (req: HttpRequest) => string; // 自定义键生成器
}

/**
 * 请求记录
 */
interface RequestRecord {
  count: number;
  resetTime: number;
}

/**
 * 限流配置内部类型
 */
interface RateLimitConfig {
  windowMs: number;
  max: number;
  message: string;
  statusCode: number;
  skipSuccessfulRequests: boolean;
  skipFailedRequests: boolean;
  keyGenerator: (req: HttpRequest) => string;
}

/**
 * 限流中间件
 * 使用滑动窗口算法实现精确限流
 */
export class RateLimit {
  private static stores: Map<string, Map<string, RequestRecord>> = new Map();

  /**
   * 创建限流中间件
   */
  public static create(options?: RateLimitOptions): RequestHandler {
    const config: RateLimitConfig = {
      windowMs: options?.windowMs ?? 60000, // 1分钟
      max: options?.max ?? 100,
      message: options?.message ?? 'Too many requests, please try again later.',
      statusCode: options?.statusCode ?? 429,
      skipSuccessfulRequests: options?.skipSuccessfulRequests ?? false,
      skipFailedRequests: options?.skipFailedRequests ?? false,
      keyGenerator: options?.keyGenerator ?? ((req: HttpRequest): string => req.ip)
    };

    const storeId = `${config.windowMs}_${config.max}`;
    if (!RateLimit.stores.has(storeId)) {
      RateLimit.stores.set(storeId, new Map<string, RequestRecord>());
    }
    const store = RateLimit.stores.get(storeId)!;

    // 定期清理过期记录
    setInterval(() => {
      const now = Date.now();
      store.forEach((record: RequestRecord, key: string) => {
        if (now > record.resetTime) {
          store.delete(key);
        }
      });
    }, config.windowMs);

    return (req: HttpRequest, res: HttpResponse, next: NextFunction): void => {
      const key = config.keyGenerator(req);
      const now = Date.now();

      let record = store.get(key);

      if (!record || now > record.resetTime) {
        const newRecord: RequestRecord = {
          count: 0,
          resetTime: now + config.windowMs
        };
        store.set(key, newRecord);
        record = newRecord;
      }

      record.count++;

      // 设置响应头
      res.setHeader('X-RateLimit-Limit', config.max.toString());
      res.setHeader('X-RateLimit-Remaining', Math.max(0, config.max - record.count).toString());
      res.setHeader('X-RateLimit-Reset', new Date(record.resetTime).toISOString());

      if (record.count > config.max) {
        res.setHeader('Retry-After', Math.ceil((record.resetTime - now) / 1000).toString());
        res.status(config.statusCode).json({
          error: config.message,
          retryAfter: Math.ceil((record.resetTime - now) / 1000)
        } as ESObject);
        return;
      }

      // 监听响应完成，根据配置决定是否计数
      if (config.skipSuccessfulRequests || config.skipFailedRequests) {
        res.onFinish((statusCode: number) => {
          const isSuccess = statusCode >= 200 && statusCode < 300;
          if ((config.skipSuccessfulRequests && isSuccess) ||
            (config.skipFailedRequests && !isSuccess)) {
            if (record) {
              record.count--;
            }
          }
        });
      }

      next();
    };
  }

  /**
   * 清除所有限流记录
   */
  public static reset(): void {
    RateLimit.stores.clear();
  }
}
