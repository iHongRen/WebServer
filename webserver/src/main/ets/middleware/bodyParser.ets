/**
 * @fileName : bodyParser.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 请求体解析中间件
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';
import { NextFunction, RequestHandler } from './types';

/**
 * 请求体解析器类
 * 提供各种格式的请求体解析中间件
 */
export class BodyParser {
  /**
   * JSON解析中间件
   * 解析application/json格式的请求体
   * @returns 中间件处理函数
   */
  static json(): RequestHandler {
    return (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      if (req.is('application/json')) {
        req.parseBody();
      }
      next();
    };
  }

  /**
   * URL编码解析中间件
   * 解析application/x-www-form-urlencoded格式的请求体
   * @returns 中间件处理函数
   */
  static urlencoded(): RequestHandler {
    return (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      if (req.is('application/x-www-form-urlencoded')) {
        req.parseBody();
      }
      next();
    };
  }

  /**
   * 多部分表单解析中间件
   * 解析multipart/form-data格式的请求体（文件上传）
   * @returns 中间件处理函数
   */
  static multipart(): RequestHandler {
    return (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      if (req.is('multipart/form-data')) {
        req.parseBody();
      }
      next();
    };
  }

  /**
   * 文本解析中间件
   * 解析text/plain格式的请求体
   * @returns 中间件处理函数
   */
  static plain(): RequestHandler {
    return (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      if (req.is('text/plain')) {
        req.parseBody();
      }
      next();
    };
  }

  /**
   * 通用解析中间件
   * 自动检测Content-Type并选择合适的解析方式
   * @returns 中间件处理函数
   */
  static auto(): RequestHandler {
    return (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      req.parseBody();
      next();
    };
  }
}