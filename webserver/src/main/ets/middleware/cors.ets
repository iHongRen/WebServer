/**
 * @fileName : cors.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : CORS跨域中间件
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';
import { NextFunction, RequestHandler, CorsOptions } from './types';

/**
 * CORS跨域资源共享中间件类
 * 处理跨域请求的访问控制
 */
export class Cors {
  /**
   * 创建CORS中间件
   * 设置跨域访问控制头部
   * @param options CORS配置选项
   * @returns 中间件处理函数
   */
  static create(options?: CorsOptions): RequestHandler {
    return (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      const requestOrigin = req.get('origin');
      if (!requestOrigin) {
        return next();
      }
      
      const configuredOrigin = options?.origin || '*';
      let allowedOrigin: string | null = null;
      
      if (typeof configuredOrigin === 'string') {
        allowedOrigin = configuredOrigin;
      } else if (Array.isArray(configuredOrigin)) {
        if (configuredOrigin.includes(requestOrigin)) {
          allowedOrigin = requestOrigin;
        }
      }
      
      if (allowedOrigin) {
        res.setHeader('Access-Control-Allow-Origin', allowedOrigin);
        res.setHeader('Vary', 'Origin');
      }
      
      res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      
      if (req.method === 'OPTIONS') {
        res.status(204).send();
        return;
      }
      
      next();
    };
  }
}