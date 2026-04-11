/**
 * @fileName : performance.ets
 * @author : @cxy
 * @date : 2025/4/11
 * @description : 性能监控中间件
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';
import { NextFunction, RequestHandler } from './types';

/**
 * 性能指标接口
 */
export interface PerformanceMetrics {
  totalRequests: number;
  successfulRequests: number;
  failedRequests: number;
  averageResponseTime: number;
  minResponseTime: number;
  maxResponseTime: number;
  requestsPerSecond: number;
  bytesTransferred: number;
}

/**
 * 性能监控配置
 */
export interface PerformanceOptions {
  sampleRate?: number; // 采样率 (0-1)
  slowThreshold?: number; // 慢请求阈值（毫秒）
  onSlowRequest?: (req: HttpRequest, duration: number) => void; // 慢请求回调
}

/**
 * 性能监控配置内部类型
 */
interface PerformanceConfig {
  sampleRate: number;
  slowThreshold: number;
  onSlowRequest?: (req: HttpRequest, duration: number) => void;
}

/**
 * 性能监控中间件
 * 收集和分析服务器性能指标
 */
export class Performance {
  private static metrics: PerformanceMetrics = {
    totalRequests: 0,
    successfulRequests: 0,
    failedRequests: 0,
    averageResponseTime: 0,
    minResponseTime: Infinity,
    maxResponseTime: 0,
    requestsPerSecond: 0,
    bytesTransferred: 0
  };

  private static responseTimes: number[] = [];
  private static startTime: number = Date.now();
  private static lastResetTime: number = Date.now();

  /**
   * 创建性能监控中间件
   */
  public static create(options?: PerformanceOptions): RequestHandler {
    const config: PerformanceConfig = {
      sampleRate: options?.sampleRate ?? 1.0,
      slowThreshold: options?.slowThreshold ?? 1000,
      onSlowRequest: options?.onSlowRequest
    };

    return (req: HttpRequest, res: HttpResponse, next: NextFunction): void => {
      // 采样检查
      if (Math.random() > config.sampleRate) {
        next();
        return;
      }

      const startTime = Date.now();

      // 监听响应完成
      res.onFinish((statusCode: number, responseSize: number) => {
        const duration = Date.now() - startTime;

        // 更新指标
        Performance.updateMetrics(statusCode, duration, responseSize);

        // 检查慢请求
        if (duration > config.slowThreshold && config.onSlowRequest) {
          config.onSlowRequest(req, duration);
        }
      });

      next();
    };
  }

  /**
   * 更新性能指标
   */
  private static updateMetrics(statusCode: number, duration: number, responseSize: number): void {
    Performance.metrics.totalRequests++;

    if (statusCode >= 200 && statusCode < 400) {
      Performance.metrics.successfulRequests++;
    } else {
      Performance.metrics.failedRequests++;
    }

    Performance.responseTimes.push(duration);
    Performance.metrics.bytesTransferred += responseSize;

    // 更新响应时间统计
    Performance.metrics.minResponseTime = Math.min(Performance.metrics.minResponseTime, duration);
    Performance.metrics.maxResponseTime = Math.max(Performance.metrics.maxResponseTime, duration);

    // 计算平均响应时间（使用滑动窗口，最多保留1000个样本）
    if (Performance.responseTimes.length > 1000) {
      Performance.responseTimes.shift();
    }

    const sum = Performance.responseTimes.reduce((a: number, b: number): number => a + b, 0);
    Performance.metrics.averageResponseTime = sum / Performance.responseTimes.length;

    // 计算每秒请求数
    const elapsedSeconds = (Date.now() - Performance.startTime) / 1000;
    Performance.metrics.requestsPerSecond = Performance.metrics.totalRequests / elapsedSeconds;
  }

  /**
   * 获取性能指标
   */
  public static getMetrics(): PerformanceMetrics {
    const metrics: PerformanceMetrics = {
      totalRequests: Performance.metrics.totalRequests,
      successfulRequests: Performance.metrics.successfulRequests,
      failedRequests: Performance.metrics.failedRequests,
      averageResponseTime: Performance.metrics.averageResponseTime,
      minResponseTime: Performance.metrics.minResponseTime,
      maxResponseTime: Performance.metrics.maxResponseTime,
      requestsPerSecond: Performance.metrics.requestsPerSecond,
      bytesTransferred: Performance.metrics.bytesTransferred
    };
    return metrics;
  }

  /**
   * 重置性能指标
   */
  public static reset(): void {
    Performance.metrics = {
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      averageResponseTime: 0,
      minResponseTime: Infinity,
      maxResponseTime: 0,
      requestsPerSecond: 0,
      bytesTransferred: 0
    };
    Performance.responseTimes = [];
    Performance.startTime = Date.now();
    Performance.lastResetTime = Date.now();
  }

  /**
   * 获取性能报告
   */
  public static getReport(): string {
    const metrics = Performance.getMetrics();
    const uptime = (Date.now() - Performance.startTime) / 1000;

    const report = `
=== 性能报告 ===
运行时间: ${uptime.toFixed(2)}秒
总请求数: ${metrics.totalRequests}
成功请求: ${metrics.successfulRequests}
失败请求: ${metrics.failedRequests}
成功率: ${((metrics.successfulRequests / metrics.totalRequests) * 100).toFixed(2)}%
平均响应时间: ${metrics.averageResponseTime.toFixed(2)}ms
最小响应时间: ${metrics.minResponseTime === Infinity ? 0 : metrics.minResponseTime}ms
最大响应时间: ${metrics.maxResponseTime}ms
每秒请求数: ${metrics.requestsPerSecond.toFixed(2)}
传输字节数: ${(metrics.bytesTransferred / 1024 / 1024).toFixed(2)}MB
================
    `;
    return report.trim();
  }
}
