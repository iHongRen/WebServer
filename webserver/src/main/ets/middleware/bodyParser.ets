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
      req.parseBody();
      next();
    };
  }

  /**
   * URL编码解析中间件
   */
  static urlencoded(): RequestHandler {
    return (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      req.parseBody();
      next();
    };
  }

  /**
   * 多部分表单解析中间件
   */
  static multipart(): RequestHandler {
    return (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      req.parseBody();
      next();
    };
  }
}