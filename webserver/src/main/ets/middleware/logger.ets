/**
 * @fileName : logger.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 日志中间件
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';
import { NextFunction, RequestHandler } from './types';

/**
 * 日志格式枚举
 */
export enum LogFormat {
  COMBINED = 'combined', // Apache combined格式
  COMMON = 'common', // Apache common格式
  DEV = 'dev', // 开发环境格式
  SHORT = 'short', // 简短格式
  TINY = 'tiny' // 最简格式
}

/**
 * 日志输出流
 */
interface LoggerStream {
  write: (message: string) => void; // 输出流
};

/**
 * 日志配置选项接口
 */
export interface LoggerOptions {
  format?: LogFormat | string; // 日志格式
  skip?: (req: HttpRequest, res: HttpResponse) => boolean; // 跳过条件
  stream?: LoggerStream;
}

/**
 * 日志中间件类
 * 提供HTTP请求日志记录功能，支持多种格式
 */
export class Logger {
  /**
   * 创建日志中间件
   * @param options 日志配置选项
   * @returns 中间件处理函数
   */
  static create(options?: LoggerOptions): RequestHandler {
    const format = options?.format || LogFormat.DEV;
    const skip = options?.skip;
    const stream = options?.stream || { write: (msg: string) => console.log(msg.trim()) };

    return (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      // 如果设置了跳过条件且满足条件，则跳过日志记录
      if (skip && skip(req, res)) {
        return next();
      }

      const startTime = Date.now();
      const startDate = new Date();

      // 使用回调机制监听响应完成
      res.onFinish((statusCode: number, responseSize: number) => {
        const endTime = Date.now();
        const responseTime = endTime - startTime;
        const logMessage = Logger.formatLog(format, req, statusCode, responseSize, responseTime, startDate);
        stream.write(logMessage);
      });

      next();
    };
  }

  /**
   * 开发环境日志格式
   * @returns 日志中间件
   */
  static dev(): RequestHandler {
    return Logger.create({ format: LogFormat.DEV });
  }

  /**
   * 生产环境日志格式（combined）
   * @returns 日志中间件
   */
  static combined(): RequestHandler {
    return Logger.create({ format: LogFormat.COMBINED });
  }

  /**
   * 通用日志格式
   * @returns 日志中间件
   */
  static common(): RequestHandler {
    return Logger.create({ format: LogFormat.COMMON });
  }

  /**
   * 简短日志格式
   * @returns 日志中间件
   */
  static short(): RequestHandler {
    return Logger.create({ format: LogFormat.SHORT });
  }

  /**
   * 最简日志格式
   * @returns 日志中间件
   */
  static tiny(): RequestHandler {
    return Logger.create({ format: LogFormat.TINY });
  }

  /**
   * 预定义的日志格式创建方法
   */

  /**
   * 格式化日志消息
   * @param format 日志格式
   * @param req HTTP请求对象
   * @param statusCode 响应状态码
   * @param responseSize 响应大小
   * @param responseTime 响应时间（毫秒）
   * @param startDate 请求开始时间
   * @returns 格式化后的日志消息
   */
  private static formatLog(
    format: LogFormat | string,
    req: HttpRequest,
    statusCode: number,
    responseSize: number,
    responseTime: number,
    startDate: Date
  ): string {
    const method = req.method;
    const url = req.url;
    const httpVersion = req.version || 'HTTP/1.1';
    const userAgent = req.userAgent || '-';
    const referer = req.referer || '-';
    const remoteAddr = req.ip || '-';
    const timestamp = Logger.formatDate(startDate);

    switch (format) {
      case LogFormat.COMBINED:
        // Apache Combined Log Format
        return `${remoteAddr} - - [${timestamp}] "${method} ${url} ${httpVersion}" ${statusCode} ${responseSize} "${referer}" "${userAgent}"\n`;

      case LogFormat.COMMON:
        // Apache Common Log Format
        return `${remoteAddr} - - [${timestamp}] "${method} ${url} ${httpVersion}" ${statusCode} ${responseSize}\n`;

      case LogFormat.DEV:
        // Development format with colors
        const statusColor = Logger.getStatusColor(statusCode);
        return `${method} ${url} ${statusColor}${statusCode}${Logger.resetColor()} ${responseTime}ms - ${responseSize}\n`;

      case LogFormat.SHORT:
        // Short format
        return `${remoteAddr} - ${method} ${url} ${httpVersion} ${statusCode} ${responseSize} - ${responseTime} ms\n`;

      case LogFormat.TINY:
        // Tiny format
        return `${method} ${url} ${statusCode} ${responseSize} - ${responseTime} ms\n`;

      default:
      // 自定义格式，支持占位符替换
        return Logger.replaceTokens(format, {
          'method': method,
          'url': url,
          'status': statusCode.toString(),
          'res[content-length]': responseSize.toString(),
          'response-time': responseTime.toString(),
          'remote-addr': remoteAddr,
          'user-agent': userAgent,
          'referrer': referer,
          'date': timestamp,
          'http-version': httpVersion
        }) + '\n';
    }
  }

  /**
   * 格式化日期为Apache日志格式
   * @param date 日期对象
   * @returns 格式化后的日期字符串
   */
  private static formatDate(date: Date): string {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    const day = date.getDate().toString().padStart(2, '0');
    const month = months[date.getMonth()];
    const year = date.getFullYear();
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    const second = date.getSeconds().toString().padStart(2, '0');

    // 时区偏移
    const offset = -date.getTimezoneOffset();
    const offsetHours = Math.floor(Math.abs(offset) / 60).toString().padStart(2, '0');
    const offsetMinutes = (Math.abs(offset) % 60).toString().padStart(2, '0');
    const offsetSign = offset >= 0 ? '+' : '-';

    return `${day}/${month}/${year}:${hour}:${minute}:${second} ${offsetSign}${offsetHours}${offsetMinutes}`;
  }

  /**
   * 根据状态码获取颜色代码
   * @param statusCode 状态码
   * @returns 颜色代码
   */
  private static getStatusColor(statusCode: number): string {
    if (statusCode >= 500) {
      return '\x1b[31m';
    } // 红色
    if (statusCode >= 400) {
      return '\x1b[33m';
    } // 黄色
    if (statusCode >= 300) {
      return '\x1b[36m';
    } // 青色
    if (statusCode >= 200) {
      return '\x1b[32m';
    } // 绿色
    return '\x1b[0m'; // 默认
  }

  /**
   * 重置颜色代码
   * @returns 重置颜色的ANSI代码
   */
  private static resetColor(): string {
    return '\x1b[0m';
  }

  /**
   * 替换自定义格式中的占位符
   * @param format 格式字符串
   * @param tokens 占位符映射
   * @returns 替换后的字符串
   */
  private static replaceTokens(format: string, tokens: Record<string, string>): string {
    let result = format;
    for (const item of Object.entries(tokens)) {
      const key = item[0]
      const value = item[1]
      result = result.replace(new RegExp(`:${key}`, 'g'), value);
    }
    return result;
  }
}