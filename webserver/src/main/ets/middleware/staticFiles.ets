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
 * 静态站点配置
 */
export interface StaticSiteConfig extends CacheOptions {
  /** 站点根目录 */
  root: string;
  /** URL路径前缀 */
  prefix: string;
  /** 默认索引文件列表 */
  index?: string[];
  /** 是否启用目录浏览 */
  directoryListing?: boolean;
}

/**
 * 目录项
 */
interface DirectoryItem {
  name: string;
  isDirectory: boolean;
  size: number;
  mtime: string;
}

/**
 * 静态文件服务类
 * 提供静态文件访问功能，支持缓存控制、性能优化和多站点管理
 */
export class StaticFiles {
  private static cache: ResponseCache = new ResponseCache();
  private static sites: StaticSiteConfig[] = [];

  /**
   * 创建静态文件服务中间件
   * 处理静态文件请求，支持缓存和ETag
   * @param directoryPath 静态文件目录路径
   * @param options 缓存配置选项
   * @returns 中间件处理函数
   */
  static serve(directoryPath: string, options?: CacheOptions): RequestHandler {
    const cache = StaticFiles.cache;
    const defaultIndex = ['index.html', 'index.htm'];
    
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
          // 尝试查找索引文件
          let indexFound = false;
          for (const indexFile of defaultIndex) {
            const indexPath = Utils.joinPath(fullPath, indexFile);
            try {
              stat = await fileIo.stat(indexPath);
              fullPath = indexPath;
              indexFound = true;
              break;
            } catch (e) {
              // 继续尝试下一个索引文件
            }
          }
          
          if (!indexFound) {
            next();
            return;
          }
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
   * 注册静态站点
   * 支持多个静态站点，每个站点有独立的路径前缀和配置
   * @param config 站点配置
   */
  static registerSite(config: StaticSiteConfig): void {
    // 规范化前缀
    let prefix = config.prefix.trim();
    if (!prefix.startsWith('/')) {
      prefix = '/' + prefix;
    }
    if (prefix.endsWith('/') && prefix.length > 1) {
      prefix = prefix.slice(0, -1);
    }

    const siteConfig: StaticSiteConfig = {
      root: config.root,
      prefix: prefix,
      maxAge: config.maxAge,
      index: config.index || ['index.html', 'index.htm'],
      directoryListing: config.directoryListing ?? false
    };

    // 检查是否已存在相同前缀的站点
    const existingIndex = StaticFiles.sites.findIndex(s => s.prefix === prefix);
    if (existingIndex >= 0) {
      StaticFiles.sites[existingIndex] = siteConfig;
    } else {
      StaticFiles.sites.push(siteConfig);
      // 按前缀长度降序排序，确保最长匹配优先
      StaticFiles.sites.sort((a, b) => b.prefix.length - a.prefix.length);
    }
  }

  /**
   * 注销静态站点
   * @param prefix 站点路径前缀
   */
  static unregisterSite(prefix: string): boolean {
    const normalizedPrefix = prefix.startsWith('/') ? prefix : '/' + prefix;
    const index = StaticFiles.sites.findIndex(s => s.prefix === normalizedPrefix);
    if (index >= 0) {
      StaticFiles.sites.splice(index, 1);
      return true;
    }
    return false;
  }

  /**
   * 获取所有已注册的站点
   */
  static getSites(): StaticSiteConfig[] {
    return [...StaticFiles.sites];
  }

  /**
   * 创建多站点静态文件服务中间件
   * 根据URL前缀匹配对应的站点并提供文件服务
   * @returns 中间件处理函数
   */
  static serveMultiSite(): RequestHandler {
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

      // 查找匹配的站点（最长前缀匹配）
      let matchedSite: StaticSiteConfig | null = null;
      for (const site of StaticFiles.sites) {
        if (requestedPath === site.prefix || requestedPath.startsWith(site.prefix + '/')) {
          matchedSite = site;
          break;
        }
      }

      if (!matchedSite) {
        next();
        return;
      }

      // 计算相对于站点根目录的路径
      const relativePath = requestedPath === matchedSite.prefix 
        ? '/' 
        : requestedPath.slice(matchedSite.prefix.length);

      let fullPath = matchedSite.root + relativePath;

      try {
        let stat = await fileIo.stat(fullPath);

        if (stat.isDirectory()) {
          // 尝试查找索引文件
          let indexFound = false;
          for (const indexFile of matchedSite.index!) {
            const indexPath = Utils.joinPath(fullPath, indexFile);
            try {
              stat = await fileIo.stat(indexPath);
              fullPath = indexPath;
              indexFound = true;
              break;
            } catch (e) {
              // 继续尝试下一个索引文件
            }
          }

          if (!indexFound) {
            if (matchedSite.directoryListing) {
              // 返回目录列表
              await StaticFiles.sendDirectoryListing(fullPath, relativePath, matchedSite.prefix, res);
              return;
            } else {
              next();
              return;
            }
          }
        }

        // 缓存逻辑
        const maxAge = matchedSite.maxAge ?? 3600;
        const etag = `W/"${stat.size}-${stat.mtime}"`;

        // 检查客户端缓存
        const ifNoneMatch = req.get('if-none-match');
        if (ifNoneMatch === etag) {
          res.status(304).send();
          return;
        }

        // 尝试从服务器缓存获取
        const cacheKey = fullPath;
        const cached = cache.get(cacheKey);

        if (cached && cached.etag === etag) {
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
        next();
      }
    };
  }

  /**
   * 发送目录列表
   */
  private static async sendDirectoryListing(
    fullPath: string,
    relativePath: string,
    prefix: string,
    res: HttpResponse
  ): Promise<void> {
    try {
      const files = await fileIo.listFile(fullPath);
      const fileList: DirectoryItem[] = [];

      for (const fileName of files) {
        const filePath = Utils.joinPath(fullPath, fileName);
        try {
          const stat = await fileIo.stat(filePath);
          const item: DirectoryItem = {
            name: fileName,
            isDirectory: stat.isDirectory(),
            size: stat.size,
            mtime: new Date(stat.mtime).toISOString()
          };
          fileList.push(item);
        } catch (e) {
          // 忽略无法访问的文件
        }
      }

      // 生成HTML目录列表
      const html = StaticFiles.generateDirectoryListingHTML(relativePath, prefix, fileList);
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.send(html);
    } catch (e) {
      res.status(500).send('Failed to list directory');
    }
  }

  /**
   * 生成目录列表HTML
   */
  private static generateDirectoryListingHTML(
    path: string,
    prefix: string,
    files: DirectoryItem[]
  ): string {
    const sortedFiles = files.sort((a, b) => {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.localeCompare(b.name);
    });

    const fileRows = sortedFiles.map(file => {
      const url = `${prefix}${path === '/' ? '' : path}/${file.name}`;
      const icon = file.isDirectory ? '📁' : '📄';
      const size = file.isDirectory ? '-' : StaticFiles.formatFileSize(file.size);
      return `
        <tr>
          <td><a href="${url}">${icon} ${file.name}${file.isDirectory ? '/' : ''}</a></td>
          <td>${size}</td>
          <td>${new Date(file.mtime).toLocaleString()}</td>
        </tr>`;
    }).join('');

    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Index of ${path}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { border-bottom: 1px solid #ccc; padding-bottom: 10px; }
    table { width: 100%; border-collapse: collapse; }
    th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
    th { background-color: #f5f5f5; }
    a { text-decoration: none; color: #0066cc; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <h1>Index of ${path}</h1>
  <table>
    <thead>
      <tr>
        <th>Name</th>
        <th>Size</th>
        <th>Modified</th>
      </tr>
    </thead>
    <tbody>
      ${path !== '/' ? '<tr><td><a href="../">📁 ..</a></td><td>-</td><td>-</td></tr>' : ''}
      ${fileRows}
    </tbody>
  </table>
</body>
</html>`;
  }

  /**
   * 格式化文件大小
   */
  private static formatFileSize(bytes: number): string {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
    if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
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