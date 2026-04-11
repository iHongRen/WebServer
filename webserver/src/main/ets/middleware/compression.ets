/**
 * @fileName : compression.ets
 * @author : @cxy
 * @date : 2025/4/11
 * @description : 压缩中间件 - 提升传输效率（简化版，移除Gzip功能）
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';
import { NextFunction, RequestHandler } from './types';

/**
 * 压缩配置
 */
export interface CompressionOptions {
  threshold?: number; // 压缩阈值（字节）
  filter?: (req: HttpRequest, res: HttpResponse) => boolean; // 过滤函数
}

/**
 * 压缩配置内部类型
 */
interface CompressionConfig {
  threshold: number;
  filter: (req: HttpRequest, res: HttpResponse) => boolean;
}

/**
 * 压缩中间件
 * 注意：由于 ArkTS 限制，暂时移除 Gzip 压缩功能
 * 仅保留框架结构，可在未来版本中实现
 */
export class Compression {
  /**
   * 创建压缩中间件
   */
  public static create(options?: CompressionOptions): RequestHandler {
    const config: CompressionConfig = {
      threshold: options?.threshold ?? 1024, // 1KB
      filter: options?.filter ?? Compression.defaultFilter
    };

    return (req: HttpRequest, res: HttpResponse, next: NextFunction): void => {
      // 检查客户端是否支持压缩
      const acceptEncoding = req.get('accept-encoding') || '';
      const supportsGzip = acceptEncoding.includes('gzip');

      if (!supportsGzip || !config.filter(req, res)) {
        next();
        return;
      }

      // 注意：由于 ArkTS 限制，暂时无法实现方法重写
      // 未来版本可能会支持
      
      next();
    };
  }

  /**
   * 默认过滤器：只压缩文本类型
   */
  private static defaultFilter(req: HttpRequest, res: HttpResponse): boolean {
    const contentType = res.getHeader('content-type') || '';
    return /text|json|javascript|xml|svg/.test(contentType);
  }
}
