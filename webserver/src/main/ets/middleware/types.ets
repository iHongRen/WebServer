/**
 * @fileName : types.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 中间件类型定义
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';

/**
 * 下一步函数类型
 * 用于中间件链式调用
 */
export type NextFunction = (error?: Error) => void;

/**
 * 请求处理函数类型
 * 标准的中间件处理函数
 */
export type RequestHandler = (req: HttpRequest, res: HttpResponse, next: NextFunction) => void;

/**
 * 错误处理函数类型
 * 用于处理中间件中的错误
 */
export type ErrorHandler = (error: Error, req: HttpRequest, res: HttpResponse, next: NextFunction) => void;

/**
 * CORS配置选项接口
 */
export interface CorsOptions {
  origin?: string | string[] // 允许的源地址
}

/**
 * 缓存配置选项接口
 */
export interface CacheOptions {
  maxAge?: number // 缓存最大时间（秒）
}