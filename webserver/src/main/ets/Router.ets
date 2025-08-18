/**
 * @fileName : Router.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 路由管理器
 */

import { HttpRequest } from './HttpRequest';
import { HttpResponse } from './HttpResponse';
import { NextFunction, RequestHandler, ErrorHandler } from './middleware';

export interface Route {
  method: string;
  path: string;
  handler: RequestHandler | ErrorHandler;
  pathRegex: RegExp | null;
  paramNames: string[];
}

export class Router {
  private routes: Route[] = [];

  /**
   * 添加路由
   */
  addRoute(method: string, path: string, handler: RequestHandler | ErrorHandler) {
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
      paramNames
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
   * 处理请求
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
   */
  getRoutes(): Route[] {
    return this.routes;
  }
}