/**
 * @fileName : cors.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : CORS跨域中间件
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';
import { NextFunction, RequestHandler, CorsOptions } from './types';

export class Cors {
  /**
   * CORS中间件
   */
  static create(options?: CorsOptions): RequestHandler {
    return (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      const requestOrigin = req.headers.get('origin');
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