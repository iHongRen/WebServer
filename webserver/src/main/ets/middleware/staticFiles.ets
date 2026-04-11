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
import { ResponseCache, CacheStats } from '../ResponseCache';

/**
 * 静态文件服务类
 * 提供静态文件访问功能，支持缓存控制和性能优化
 */
export class StaticFiles {
  private static cache: ResponseCache = new ResponseCache();

  /**
   * 创建静态文件服务中间件
   * 处理静态文件请求，支持缓存和ETag
   * @param directoryPath 静态文件目录路径
   * @param options 缓存配置选项
   * @returns 中间件处理函数
   */
  static serve(directoryPath: string, options?: CacheOptions): RequestHandler {
    const cache = StaticFiles.cache;
    
    return async (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      if (req.method !== 'GET') {
        next();
        return;
      }
      
      const decodedPath = decodeURIComponent(req.path);
      const requestedPath = Utils.normalizePath(decodedPath);
      
      // 安全检查：防止路径遍历攻击
      if (requestedPath.includes('..')) {
        res.status(400).send('Invalid Path');
        return;
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
          res.status(304).send(); // Not Modified
          return;
        }

        // 尝试从服务器缓存获取
        const cacheKey = fullPath;
        const cached = cache.get(cacheKey);

        if (cached && cached.etag === etag) {
          // 使用缓存数据
          cached.headers.forEach((value: string, key: string) => {
            res.setHeader(key, value);
          });
          res.send(cached.data);
          return;
        }

        // 读取文件
        const buf = new ArrayBuffer(stat.size);
        const file = fileIo.openSync(fullPath, fileIo.OpenMode.READ_ONLY);
        fileIo.readSync(file.fd, buf);
        fileIo.closeSync(file.fd);

        // 设置响应头
        const mimeType = Utils.getMimeType(fullPath);
        const headers = new Map<string, string>();
        headers.set('Content-Type', mimeType);
        headers.set('Cache-Control', `public, max-age=${maxAge}`);
        headers.set('ETag', etag);
        headers.set('Last-Modified', new Date(stat.mtime).toUTCString());

        // 存入缓存
        cache.set(cacheKey, buf, headers, etag);

        // 设置响应头
        headers.forEach((value: string, key: string) => {
          res.setHeader(key, value);
        });
        
        res.send(buf);
      } catch (e) {
        // 文件不存在或其他错误，传递给下一个处理器
        next();
      }
    };
  }

  /**
   * 清空静态文件缓存
   */
  static clearCache(): void {
    StaticFiles.cache.clear();
  }

  /**
   * 获取缓存统计
   */
  static getCacheStats(): CacheStats {
    return StaticFiles.cache.getStats();
  }
}