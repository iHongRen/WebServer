/**
 * @fileName : staticFiles.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 静态文件服务中间件
 */

import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';
import { NextFunction, RequestHandler, CacheOptions } from './types';
import { Utils } from '../Utils';
import { fileIo } from '@kit.CoreFileKit';

export class StaticFiles {
  /**
   * 静态文件服务中间件
   */
  static serve(directoryPath: string, options?: CacheOptions): RequestHandler {
    return async (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      if (req.method !== 'GET') {
        return next();
      }
      
      const decodedPath = decodeURIComponent(req.path);
      const requestedPath = Utils.normalizePath(decodedPath);
      
      if (requestedPath.includes('..')) {
        return res.status(400).send('Invalid Path');
      }
      
      let fullPath = directoryPath + (requestedPath === '/' ? '/index.html' : requestedPath);
      
      try {
        let stat = await fileIo.stat(fullPath);
        
        if (stat.isDirectory()) {
          fullPath = Utils.joinPath(fullPath, 'index.html');
          stat = await fileIo.stat(fullPath);
        }

        // 缓存逻辑
        const maxAge = options?.maxAge ?? 3600; // 默认1小时
        const etag = `W/"${stat.size}-${stat.mtime}"`;

        // 检查客户端缓存
        const ifNoneMatch = req.get('if-none-match');
        if (ifNoneMatch === etag) {
          return res.status(304).send(); // Not Modified
        }

        // 设置缓存头
        res.setHeader('Cache-Control', `public, max-age=${maxAge}`);
        res.setHeader('ETag', etag);

        const mimeType = Utils.getMimeType(fullPath);
        res.setHeader('Content-Type', mimeType);
        
        const buf = new ArrayBuffer(stat.size);
        const file = fileIo.openSync(fullPath, fileIo.OpenMode.READ_WRITE);
        fileIo.readSync(file.fd, buf);
        fileIo.closeSync(file.fd);
        
        res.send(buf);
      } catch (e) {
        // 文件不存在或其他错误，传递给下一个处理器
        next();
      }
    };
  }
}