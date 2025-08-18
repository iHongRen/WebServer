/**
 * @fileName : bodyParser.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 请求体解析中间件
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';
import { NextFunction, RequestHandler } from './types';

export class BodyParser {
  /**
   * JSON解析中间件
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
   * 通用解析中间件，自动检测Content-Type
   */
  static auto(): RequestHandler {
    return (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      req.parseBody();
      next();
    };
  }
}