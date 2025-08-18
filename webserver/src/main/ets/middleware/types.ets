/**
 * @fileName : types.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 中间件类型定义
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';

export type NextFunction = (error?: Error) => void;

export type RequestHandler = (req: HttpRequest, res: HttpResponse, next: NextFunction) => void;

export type ErrorHandler = (error: Error, req: HttpRequest, res: HttpResponse, next: NextFunction) => void;

export interface CorsOptions {
  origin?: string | string[]
}

export interface CacheOptions {
  maxAge?: number
}