/**
 * @fileName : Router.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 路由管理器
 */

import { HttpRequest } from './HttpRequest';
import { HttpResponse } from './HttpResponse';
import { NextFunction, RequestHandler, ErrorHandler } from './middleware';

/**
 * 路由接口定义
 */
export interface Route {
  method: string; // HTTP方法
  path: string; // 路由路径
  handler: RequestHandler | ErrorHandler; // 处理函数
  pathRegex: RegExp | null; // 路径正则表达式
  paramNames: string[]; // 参数名列表
  isStream?: boolean; // 是否为流式上传路由
}

/**
 * 路由管理器类
 * 负责路由的注册、匹配和执行
 */
export class Router {
  private routes: Route[] = []; // 路由列表
  // 流式路由索引：key = "METHOD:path"，用于 O(1) 快速判断
  private streamRouteKeys: Set<string> = new Set();

  /**
   * 添加路由
   * @param method HTTP方法
   * @param path 路由路径
   * @param handler 处理函数
   */
  addRoute(method: string, path: string, handler: RequestHandler | ErrorHandler) {
    this._addRouteInternal(method, path, handler, false);
  }

  /**
   * 添加流式上传路由
   * 该路由在收到完整 header 后立即触发，body 通过 req.uploadStream 增量推送
   */
  addStreamRoute(method: string, path: string, handler: RequestHandler) {
    this._addRouteInternal(method, path, handler, true);
    this.streamRouteKeys.add(`${method.toUpperCase()}:${path}`);
  }

  /**
   * 判断指定 method + path 是否为流式路由
   */
  hasStreamRoute(method: string, path: string): boolean {
    // 精确匹配
    if (this.streamRouteKeys.has(`${method.toUpperCase()}:${path}`)) {
      return true;
    }
    // 参数路由：遍历带 pathRegex 的流式路由
    for (const route of this.routes) {
      if (!route.isStream) {
        continue;
      }
      const methodMatch = route.method === method || route.method === 'ANY';
      if (!methodMatch) {
        continue;
      }
      if (route.path === path || route.path === '*') {
        return true;
      }
      if (route.pathRegex && route.pathRegex.test(path)) {
        return true;
      }
    }
    return false;
  }

  private _addRouteInternal(
    method: string,
    path: string,
    handler: RequestHandler | ErrorHandler,
    isStream: boolean
  ) {
    let pathRegex: RegExp | null = null;
    const paramNames: string[] = [];

    if (path !== '*' && path.includes(':')) {
      const regexString = path.replace(/:(\w+)/g, (_, name: string) => {
        paramNames.push(name);
        return '([^/]+)';
      });
      pathRegex = new RegExp(`^${regexString}/?$`);
    }

    const route: Route = {
      method,
      path,
      handler,
      pathRegex,
      paramNames,
      isStream
    };

    const insertIndex = this.routes.length > 0 ? this.routes.length - 1 : 0;
    const isStatic = method === 'GET' && path === '*';

    if (isStatic) {
      const firstWildcardIndex = this.routes.findIndex(r => r.path === '*');
      this.routes.splice(firstWildcardIndex, 0, route);
    } else {
      this.routes.splice(insertIndex, 0, route);
    }
  }

  /**
   * 处理HTTP请求
   * 遍历路由列表，找到匹配的路由并执行
   * @param req HTTP请求对象
   * @param res HTTP响应对象
   */
  handle(req: HttpRequest, res: HttpResponse) {
    let routeIndex = -1;

    const next: NextFunction = (err?: Error) => {
      routeIndex++;
      if (routeIndex >= this.routes.length) {
        if (err && !res.isHeadersSent()) {
          res.status(500).json({ error: 'Internal Server Error' });
        }
        return;
      }

      const route = this.routes[routeIndex];

      try {
        if (err) {
          if (route.handler.length === 4) {
            (route.handler as ErrorHandler)(err, req, res, next);
          } else {
            next(err);
          }
        } else {
          if (route.handler.length !== 4) {
            let match: RegExpExecArray | null = null;
            const methodMatch = route.method === req.method || route.method === 'ANY';
            const simpleMatch = methodMatch && (route.path === req.path || route.path === '*');
            const regexMatch = methodMatch && route.pathRegex && (match = route.pathRegex.exec(req.path));

            if (simpleMatch || regexMatch) {
              if (regexMatch && match) {
                req.params = {};
                route.paramNames.forEach((name, index) => {
                  if (match) {
                    req.params[name] = match[index + 1];
                  }
                });
              }
              (route.handler as RequestHandler)(req, res, next);
            } else {
              next();
            }
          } else {
            next();
          }
        }
      } catch (e) {
        next(e);
      }
    };

    next();
  }

  /**
   * 获取所有路由
   * @returns 路由列表
   */
  getRoutes(): Route[] {
    return this.routes;
  }
}