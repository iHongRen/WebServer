/**
 * @fileName : security.ets
 * @author : @cxy
 * @date : 2025/4/11
 * @description : 安全中间件 - 防护常见Web攻击
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';
import { NextFunction, RequestHandler } from './types';

/**
 * 安全配置选项
 */
export interface SecurityOptions {
  enableXssProtection?: boolean; // XSS保护
  enableFrameGuard?: boolean; // 点击劫持保护
  enableContentTypeNoSniff?: boolean; // MIME类型嗅探保护
  enableHsts?: boolean; // HTTPS严格传输安全
  hstsMaxAge?: number; // HSTS最大年龄（秒）
  enableCsp?: boolean; // 内容安全策略
  cspDirectives?: string; // CSP指令
  maxRequestSize?: number; // 最大请求大小（字节）
  maxUrlLength?: number; // 最大URL长度
  maxHeaderSize?: number; // 最大请求头大小
}

/**
 * 安全配置内部类型
 */
interface SecurityConfig {
  enableXssProtection: boolean;
  enableFrameGuard: boolean;
  enableContentTypeNoSniff: boolean;
  enableHsts: boolean;
  hstsMaxAge: number;
  enableCsp: boolean;
  cspDirectives: string;
  maxRequestSize: number;
  maxUrlLength: number;
  maxHeaderSize: number;
}

/**
 * 安全中间件
 * 提供多层安全防护
 */
export class Security {
  /**
   * 创建安全中间件
   */
  public static create(options?: SecurityOptions): RequestHandler {
    const config: SecurityConfig = {
      enableXssProtection: options?.enableXssProtection ?? true,
      enableFrameGuard: options?.enableFrameGuard ?? true,
      enableContentTypeNoSniff: options?.enableContentTypeNoSniff ?? true,
      enableHsts: options?.enableHsts ?? false,
      hstsMaxAge: options?.hstsMaxAge ?? 31536000, // 1年
      enableCsp: options?.enableCsp ?? false,
      cspDirectives: options?.cspDirectives ?? "default-src 'self'",
      maxRequestSize: options?.maxRequestSize ?? 10 * 1024 * 1024, // 10MB
      maxUrlLength: options?.maxUrlLength ?? 2048,
      maxHeaderSize: options?.maxHeaderSize ?? 8192
    };

    return (req: HttpRequest, res: HttpResponse, next: NextFunction): void => {
      // 1. 检查URL长度
      if (req.url.length > config.maxUrlLength) {
        res.status(414).json({
          error: 'URI Too Long'
        } as ESObject);
        return;
      }

      // 2. 检查请求大小
      if (req.contentLength > config.maxRequestSize) {
        res.status(413).json({
          error: 'Payload Too Large'
        } as ESObject);
        return;
      }

      // 3. 检查请求头大小
      let headerSize = 0;
      req.headers.forEach((value: string, key: string) => {
        headerSize += key.length + value.length;
      });

      if (headerSize > config.maxHeaderSize) {
        res.status(431).json({
          error: 'Request Header Fields Too Large'
        } as ESObject);
        return;
      }

      // 4. 设置安全响应头
      if (config.enableXssProtection) {
        res.setHeader('X-XSS-Protection', '1; mode=block');
      }

      if (config.enableFrameGuard) {
        res.setHeader('X-Frame-Options', 'SAMEORIGIN');
      }

      if (config.enableContentTypeNoSniff) {
        res.setHeader('X-Content-Type-Options', 'nosniff');
      }

      if (config.enableHsts) {
        res.setHeader('Strict-Transport-Security', `max-age=${config.hstsMaxAge}; includeSubDomains`);
      }

      if (config.enableCsp) {
        res.setHeader('Content-Security-Policy', config.cspDirectives);
      }

      // 5. 移除敏感响应头
      res.removeHeader('X-Powered-By');

      next();
    };
  }

  /**
   * XSS过滤器
   * 清理潜在的XSS攻击代码
   */
  public static xssFilter(): RequestHandler {
    return (req: HttpRequest, res: HttpResponse, next: NextFunction): void => {
      // 过滤查询参数
      req.query.forEach((value: string, key: string) => {
        const sanitized = Security.sanitizeXss(value);
        req.query.set(key, sanitized);
      });

      // 过滤请求体（如果是对象）
      if (typeof req.body === 'object' && req.body !== null) {
        req.body = Security.sanitizeObject(req.body);
      }

      next();
    };
  }

  /**
   * SQL注入防护
   * 检测潜在的SQL注入攻击
   */
  public static sqlInjectionProtection(): RequestHandler {
    const sqlPatterns: RegExp[] = [
      /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE)\b)/i,
      /(UNION.*SELECT)/i,
      /(OR\s+1\s*=\s*1)/i,
      /(--|\#|\/\*|\*\/)/
    ];

    return (req: HttpRequest, res: HttpResponse, next: NextFunction): void => {
      // 检查查询参数
      const queryKeys = Array.from(req.query.keys());
      for (let i = 0; i < queryKeys.length; i++) {
        const key = queryKeys[i];
        const value = req.query.get(key);
        if (value && Security.containsSqlInjection(value, sqlPatterns)) {
          res.status(400).json({
            error: 'Potential SQL injection detected'
          } as ESObject);
          return;
        }
      }

      // 检查请求体
      if (typeof req.body === 'object' && req.body !== null) {
        if (Security.checkObjectForSqlInjection(req.body, sqlPatterns)) {
          res.status(400).json({
            error: 'Potential SQL injection detected'
          } as ESObject);
          return;
        }
      }

      next();
    };
  }

  /**
   * 清理XSS攻击代码
   */
  private static sanitizeXss(input: string): string {
    return input
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;')
      .replace(/\//g, '&#x2F;');
  }

  /**
   * 清理对象中的XSS代码
   */
  private static sanitizeObject(obj: ESObject): ESObject {
    const result: ESObject = {};

    const keys = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value: Object = obj[key];
      if (typeof value === 'string') {
        result[key] = Security.sanitizeXss(value as string);
      } else if (typeof value === 'object' && value !== null) {
        result[key] = Security.sanitizeObject(value as ESObject);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /**
   * 检查字符串是否包含SQL注入
   */
  private static containsSqlInjection(input: string, patterns: RegExp[]): boolean {
    for (let i = 0; i < patterns.length; i++) {
      if (patterns[i].test(input)) {
        return true;
      }
    }
    return false;
  }

  /**
   * 检查对象是否包含SQL注入
   */
  private static checkObjectForSqlInjection(obj: ESObject, patterns: RegExp[]): boolean {
    const keys = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value: Object = obj[key];
      if (typeof value === 'string') {
        if (Security.containsSqlInjection(value as string, patterns)) {
          return true;
        }
      } else if (typeof value === 'object' && value !== null) {
        if (Security.checkObjectForSqlInjection(value as ESObject, patterns)) {
          return true;
        }
      }
    }
    return false;
  }
}
