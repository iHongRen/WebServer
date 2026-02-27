/**
 * @fileName : StaticExample.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : Static示例 - 展示静态文件服务功能
 */

import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import {
  HttpServer, HttpRequest, HttpResponse, NextFunction,
} from '@cxy/webserver';
import { util } from '@kit.ArkTS';
import { socket } from '@kit.NetworkKit';

/**
 * 静态文件
 */
interface FileItem {
  name: string,
  path: string,
  isDirectory: boolean,
  size: number,
  mtime: string
}

/**
 * Static示例类
 * 展示静态文件服务的各种功能
 */
export class StaticExample {
  public staticRoot: string = ''
  private server: HttpServer | null = null;
  private context?: common.UIAbilityContext;

  init(context: common.UIAbilityContext) {
    this.context = context;
    this.staticRoot = context.filesDir + '/staticExample'
    this.setupStaticFiles()
  }

  /**
   * 设置静态文件
   */
  public async setupStaticFiles(): Promise<void> {
    const access = await fileIo.access(this.staticRoot);
    if (!access) {
      await fileIo.mkdir(this.staticRoot);
    }

    // 创建示例文件结构
    await this.createExampleFiles();
  }

  /**
   * 初始化服务器
   */
  public initializeServer(): void {
    this.server = new HttpServer();
    this.setupMiddleware();
    this.setupRoutes();
  }

  /**
   * 启动服务器
   */
  public async start(port: number): Promise<socket.NetAddress | null> {
    if (!this.server) {
      this.initializeServer();
    }

    const info = await this.server?.startServer(port);
    if (info) {
      console.log('服务器启动成功!');
      console.log(`访问地址: http://${info.address}:${info.port}`);
      this.printApiEndpoints(info);
      return info;
    } else {
      console.error('启动服务器失败:');
      return null;
    }
  }

  /**
   * 停止服务器
   */
  public async stop(): Promise<void> {
    if (this.server) {
      await this.server.stopServer();
    }
  }


  /**
   * 创建示例文件
   */
  private async createExampleFiles(): Promise<void> {
    // 创建子目录
    const dirs = ['css', 'js', 'images', 'docs'];
    for (const dir of dirs) {
      const dirPath = `${this.staticRoot}/${dir}`;
      const exists = await fileIo.access(dirPath);
      if (!exists) {
        await fileIo.mkdir(dirPath);
      }
    }

    // 创建示例HTML文件
    await this.createFile('index.html', `<!DOCTYPE html>
<html>
<head>
    <title>Static File Server Demo</title>
    <meta charset="utf-8" />
    <link rel="stylesheet" href="/css/style.css">
</head>
<script src="/js/app.js"></script>
<body>
    <h1>静态文件服务器演示</h1>
    <p>这是一个静态HTML文件示例</p>
</body>
</html>`);

    // 创建CSS文件
    await this.createFile('css/style.css', `body {
    font-family: Arial, sans-serif;
    margin: 40px;
    background-color: #f5f5f5;
}

h1 {
    color: #333;
    text-align: center;
}

p {
    color: #666;
    line-height: 1.6;
}`);

    // 创建JavaScript文件
    await this.createFile('js/app.js', `console.log('Static file server is working!');

document.addEventListener('DOMContentLoaded', function() {
    console.log('Page loaded successfully');

    // 添加一些交互
    const h1 = document.querySelector('h1');
    if (h1) {
        h1.addEventListener('click', function() {
            alert('Hello from static JavaScript!');
        });
    }
});`);

    // 创建文档文件
    await this.createFile('docs/readme.txt', `Static File Server Documentation

This is a demonstration of static file serving capabilities.

Features:
- File serving with proper MIME types
- Caching support
- Access logging
- File browser
- Upload functionality

Created: ${new Date().toISOString()}`);

    // 创建JSON数据文件
    await this.createFile('data.json', JSON.stringify({
      name: 'Static File Server',
      version: '1.0.0',
      features: ['file serving', 'caching', 'logging'],
      created: new Date().toISOString()
    }, null, 2));
  }

  /**
   * 创建文件
   */
  private async createFile(relativePath: string, content: string): Promise<void> {
    try {
      const filePath = `${this.staticRoot}/${relativePath}`;
      const file = await fileIo.open(filePath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      await fileIo.write(file.fd, util.TextEncoder.create().encodeInto(content).buffer);
      await fileIo.close(file.fd);
    } catch (error) {
      console.warn(`创建文件失败 ${relativePath}:`, error);
    }
  }


  /**
   * 配置中间件
   */
  private setupMiddleware(): void {
    if (!this.server) {
      return;
    }

    this.server.logger()
    this.server.cors();
    this.server.auto();


    // 配置静态文件服务
    this.server.serveStatic(this.staticRoot, {
      maxAge: 0, //不缓存
    });

    this.server.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      res.setHeader('Cache-Control', 'no-cache');
      next(); // 继续执行后续中间件
    });

  }


  /**
   * 文件管理路由
   */
  private setupRoutes(): void {
    if (!this.server) {
      return;
    }

    // 文件浏览器API
    this.server.get('/api/files', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const path = req.query.get('path') || '';
        const fullPath = `${this.staticRoot}/${path}`.replace(/\/+/g, '/');

        const files = await fileIo.listFile(fullPath);
        const fileList: FileItem[] = [];

        for (const fileName of files) {
          const filePath = `${fullPath}/${fileName}`;
          try {
            const stat = await fileIo.stat(filePath);
            fileList.push({
              name: fileName,
              path: `${path}/${fileName}`.replace(/^\//, ''),
              isDirectory: stat.isDirectory(),
              size: stat.size,
              mtime: new Date(stat.mtime).toISOString()
            });
          } catch (e) {
            // 忽略无法访问的文件
          }
        }

        res.json({
          currentPath: path,
          files: fileList.sort((a, b) => {
            if (a.isDirectory && !b.isDirectory) {
              return -1;
            }
            if (!a.isDirectory && b.isDirectory) {
              return 1;
            }
            return a.name.localeCompare(b.name);
          })
        });
      } catch (error) {
        res.status(500).json({ error: 'Failed to list files' });
      }
    });

    // 文件上传API
    this.server.post('/api/upload', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const uploadedFile = req.files?.['file'];

        if (!uploadedFile) {
          return res.status(400).json({ error: 'No file uploaded' });
        }

        const fileName = uploadedFile.fileName;
        const filePath = `${this.staticRoot}/${fileName}`;

        const file = await fileIo.open(filePath,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
        await fileIo.write(file.fd, uploadedFile.data);
        await fileIo.close(file.fd);

        res.json({
          message: 'File uploaded successfully',
          fileName,
          size: uploadedFile.data.byteLength,
          url: `/${fileName}`
        });
      } catch (error) {
        res.status(500).json({ error: 'Upload failed' });
      }
    });

    // 文件删除API
    this.server.delete('/api/files/*', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const filePath = req.path.replace('/api/files/', '');
        const fullPath = `${this.staticRoot}/${filePath}`;

        await fileIo.unlink(fullPath);

        res.json({
          message: 'File deleted successfully',
          filePath
        });
      } catch (error) {
        res.status(500).json({ error: 'Delete failed' });
      }
    });
  }


  /**
   * 打印API端点信息
   */
  private printApiEndpoints(info: socket.NetAddress): void {
    const baseUrl = `http://${info.address}:${info.port}`;

    console.log('\n Static File Server API端点:');
    console.log('='.repeat(50));

    console.log(' 静态文件:');
    console.log(`   GET  ${baseUrl}/                      - 首页`);
    console.log(`   GET  ${baseUrl}/css/style.css         - CSS文件`);
    console.log(`   GET  ${baseUrl}/js/app.js             - JavaScript文件`);
    console.log(`   GET  ${baseUrl}/data.json             - JSON数据`);

    console.log('\n 文件管理:');
    console.log(`   GET    ${baseUrl}/api/files           - 文件浏览器`);
    console.log(`   POST   ${baseUrl}/api/upload          - 文件上传`);
    console.log(`   DELETE ${baseUrl}/api/files/*         - 文件删除`);

    console.log('='.repeat(50));
  }
}
