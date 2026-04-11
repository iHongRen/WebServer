/**
 * @fileName : StaticExample.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : Static示例 - 展示静态文件服务功能和多站点支持
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
 * OpenAPI Info
 */
interface OpenAPIInfo {
  title: string;
  version: string;
}

/**
 * OpenAPI Path Item
 */
interface OpenAPIPathItem {
  summary: string;
}

/**
 * OpenAPI Path Methods
 */
class OpenAPIPathMethods {
  get?: OpenAPIPathItem;
  post?: OpenAPIPathItem;
  put?: OpenAPIPathItem;
  delete?: OpenAPIPathItem;
  patch?: OpenAPIPathItem;
}

/**
 * OpenAPI Paths
 */
class OpenAPIPaths {
  '/users'?: OpenAPIPathMethods;
  '/products'?: OpenAPIPathMethods;
}

/**
 * OpenAPI Spec
 */
interface OpenAPISpec {
  openapi: string;
  info: OpenAPIInfo;
  paths: OpenAPIPaths;
}

/**
 * Gallery Data
 */
interface GalleryData {
  name: string;
  albums: string[];
  totalPhotos: number;
}

/**
 * Site Info
 */
interface SiteInfo {
  prefix: string;
  root: string;
  maxAge?: number;
  directoryListing?: boolean;
  index?: string[];
}

/**
 * Sites Response
 */
interface SitesResponse {
  total: number;
  sites?: SiteInfo[];
}

/**
 * Main Site Data
 */
interface MainSiteData {
  name: string;
  version: string;
  features: string[];
  sites: string[];
  created: string;
}

/**
 * Static示例类
 * 展示静态文件服务的各种功能，包括多站点支持
 */
export class StaticExample {
  public staticRoot: string = ''
  public site1Root: string = ''
  public site2Root: string = ''
  public site3Root: string = ''
  private server: HttpServer | null = null;
  private context?: common.UIAbilityContext;

  init(context: common.UIAbilityContext) {
    this.context = context;
    this.staticRoot = context.filesDir + '/staticExample'
    this.site1Root = context.filesDir + '/site1'
    this.site2Root = context.filesDir + '/site2'
    this.site3Root = context.filesDir + '/site3'
    this.setupStaticFiles()
  }

  /**
   * 设置静态文件
   */
  public async setupStaticFiles(): Promise<void> {
    // 创建主站点
    await this.ensureDirectory(this.staticRoot);
    await this.createExampleFiles();

    // 创建多个子站点
    await this.ensureDirectory(this.site1Root);
    await this.createSite1Files();

    await this.ensureDirectory(this.site2Root);
    await this.createSite2Files();

    await this.ensureDirectory(this.site3Root);
    await this.createSite3Files();
  }

  /**
   * 确保目录存在
   */
  private async ensureDirectory(path: string): Promise<void> {
    const access = await fileIo.access(path);
    if (!access) {
      await fileIo.mkdir(path);
    }
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
   * 创建示例文件（主站点）
   */
  private async createExampleFiles(): Promise<void> {
    // 创建子目录
    const dirs = ['css', 'js', 'images', 'docs'];
    for (const dir of dirs) {
      const dirPath = `${this.staticRoot}/${dir}`;
      await this.ensureDirectory(dirPath);
    }

    // 创建示例HTML文件
    await this.createFile(`${this.staticRoot}/index.html`, `<!DOCTYPE html>
<html>
<head>
    <title>主站点 - Static File Server Demo</title>
    <meta charset="utf-8" />
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <h1>主站点 - 静态文件服务器演示</h1>
    <p>这是主站点的首页</p>
    <h2>多站点导航</h2>
    <ul>
        <li><a href="/site1/">站点1 - 文档中心</a></li>
        <li><a href="/site2/">站点2 - 图片画廊</a></li>
        <li><a href="/site3/">站点3 - API文档</a></li>
    </ul>
    <script src="/js/app.js"></script>
</body>
</html>`);

    // 创建CSS文件
    await this.createFile(`${this.staticRoot}/css/style.css`, `body {
    font-family: Arial, sans-serif;
    margin: 40px;
    background-color: #f5f5f5;
}

h1 {
    color: #333;
    text-align: center;
}

h2 {
    color: #666;
    border-bottom: 2px solid #ddd;
    padding-bottom: 10px;
}

p {
    color: #666;
    line-height: 1.6;
}

ul {
    list-style: none;
    padding: 0;
}

li {
    margin: 10px 0;
}

a {
    color: #0066cc;
    text-decoration: none;
    font-size: 18px;
}

a:hover {
    text-decoration: underline;
}`);

    // 创建JavaScript文件
    await this.createFile(`${this.staticRoot}/js/app.js`, `console.log('Main site loaded!');

document.addEventListener('DOMContentLoaded', function() {
    console.log('Page loaded successfully');
    
    const h1 = document.querySelector('h1');
    if (h1) {
        h1.addEventListener('click', function() {
            alert('欢迎访问多站点静态服务器！');
        });
    }
});`);

    // 创建文档文件
    await this.createFile(`${this.staticRoot}/docs/readme.txt`, `Static File Server Documentation

This is a demonstration of multi-site static file serving capabilities.

Features:
- Multiple independent static sites
- Site-specific configurations
- Longest prefix matching
- Shared caching
- Directory listing support

Created: ${new Date().toISOString()}`);

    // 创建JSON数据文件
    const mainData: MainSiteData = {
      name: 'Multi-Site Static File Server',
      version: '2.0.0',
      features: ['multi-site', 'caching', 'directory-listing'],
      sites: ['main', 'site1', 'site2', 'site3'],
      created: new Date().toISOString()
    };
    await this.createFile(`${this.staticRoot}/data.json`, JSON.stringify(mainData, null, 2));
  }

  /**
   * 创建站点1文件（文档中心）
   */
  private async createSite1Files(): Promise<void> {
    await this.ensureDirectory(`${this.site1Root}/guides`);
    await this.ensureDirectory(`${this.site1Root}/api`);

    await this.createFile(`${this.site1Root}/index.html`, `<!DOCTYPE html>
<html>
<head>
    <title>站点1 - 文档中心</title>
    <meta charset="utf-8" />
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
        h1 { text-align: center; }
        .card { background: rgba(255,255,255,0.1); padding: 20px; margin: 20px 0; border-radius: 10px; }
        a { color: #ffd700; }
    </style>
</head>
<body>
    <h1>📚 文档中心</h1>
    <div class="card">
        <h2>快速开始</h2>
        <p>欢迎来到文档中心！这里提供完整的开发文档。</p>
        <ul>
            <li><a href="/site1/guides/getting-started.html">入门指南</a></li>
            <li><a href="/site1/api/reference.html">API参考</a></li>
        </ul>
    </div>
    <p><a href="/">← 返回主站</a></p>
</body>
</html>`);

    await this.createFile(`${this.site1Root}/guides/getting-started.html`, `<!DOCTYPE html>
<html>
<head>
    <title>入门指南</title>
    <meta charset="utf-8" />
</head>
<body>
    <h1>入门指南</h1>
    <p>这是一个入门指南文档...</p>
    <p><a href="/site1/">← 返回文档中心</a></p>
</body>
</html>`);

    await this.createFile(`${this.site1Root}/api/reference.html`, `<!DOCTYPE html>
<html>
<head>
    <title>API参考</title>
    <meta charset="utf-8" />
</head>
<body>
    <h1>API参考文档</h1>
    <p>这是API参考文档...</p>
    <p><a href="/site1/">← 返回文档中心</a></p>
</body>
</html>`);
  }

  /**
   * 创建站点2文件（图片画廊）
   */
  private async createSite2Files(): Promise<void> {
    await this.ensureDirectory(`${this.site2Root}/photos`);
    await this.ensureDirectory(`${this.site2Root}/albums`);

    await this.createFile(`${this.site2Root}/index.html`, `<!DOCTYPE html>
<html>
<head>
    <title>站点2 - 图片画廊</title>
    <meta charset="utf-8" />
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; }
        h1 { text-align: center; }
        .gallery { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .item { background: rgba(255,255,255,0.2); padding: 20px; border-radius: 10px; text-align: center; }
        a { color: white; text-decoration: none; }
    </style>
</head>
<body>
    <h1>🖼️ 图片画廊</h1>
    <div class="gallery">
        <div class="item">
            <h3>相册1</h3>
            <p>风景照片</p>
        </div>
        <div class="item">
            <h3>相册2</h3>
            <p>人物照片</p>
        </div>
        <div class="item">
            <h3>相册3</h3>
            <p>建筑照片</p>
        </div>
    </div>
    <p><a href="/">← 返回主站</a></p>
</body>
</html>`);

    const galleryData: GalleryData = {
      name: 'Photo Gallery',
      albums: ['landscapes', 'portraits', 'architecture'],
      totalPhotos: 150
    };
    await this.createFile(`${this.site2Root}/gallery.json`, JSON.stringify(galleryData, null, 2));
  }

  /**
   * 创建站点3文件（API文档）
   */
  private async createSite3Files(): Promise<void> {
    await this.ensureDirectory(`${this.site3Root}/v1`);
    await this.ensureDirectory(`${this.site3Root}/v2`);

    await this.createFile(`${this.site3Root}/index.html`, `<!DOCTYPE html>
<html>
<head>
    <title>站点3 - API文档</title>
    <meta charset="utf-8" />
    <style>
        body { font-family: 'Courier New', monospace; margin: 40px; background: #1e1e1e; color: #d4d4d4; }
        h1 { text-align: center; color: #4ec9b0; }
        .endpoint { background: #252526; padding: 15px; margin: 15px 0; border-left: 4px solid #4ec9b0; }
        .method { color: #ce9178; font-weight: bold; }
        a { color: #569cd6; }
    </style>
</head>
<body>
    <h1>⚡ API 文档</h1>
    <div class="endpoint">
        <p><span class="method">GET</span> /api/v1/users</p>
        <p>获取用户列表</p>
    </div>
    <div class="endpoint">
        <p><span class="method">POST</span> /api/v1/users</p>
        <p>创建新用户</p>
    </div>
    <div class="endpoint">
        <p><span class="method">GET</span> /api/v2/products</p>
        <p>获取产品列表（v2）</p>
    </div>
    <p><a href="/">← 返回主站</a></p>
</body>
</html>`);

    const usersPath: OpenAPIPathMethods = {
      get: { summary: 'Get users' },
      post: { summary: 'Create user' }
    };
    const v1Paths: OpenAPIPaths = {
      '/users': usersPath
    };
    const v1Spec: OpenAPISpec = {
      openapi: '3.0.0',
      info: {
        title: 'API v1',
        version: '1.0.0'
      },
      paths: v1Paths
    };
    await this.createFile(`${this.site3Root}/v1/openapi.json`, JSON.stringify(v1Spec, null, 2));

    const productsPath: OpenAPIPathMethods = {
      get: { summary: 'Get products' }
    };
    const v2Paths: OpenAPIPaths = {
      '/products': productsPath
    };
    const v2Spec: OpenAPISpec = {
      openapi: '3.0.0',
      info: {
        title: 'API v2',
        version: '2.0.0'
      },
      paths: v2Paths
    };
    await this.createFile(`${this.site3Root}/v2/openapi.json`, JSON.stringify(v2Spec, null, 2));
  }

  /**
   * 创建文件
   */
  private async createFile(filePath: string, content: string): Promise<void> {
    try {
      const file = await fileIo.open(filePath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      await fileIo.write(file.fd, util.TextEncoder.create().encodeInto(content).buffer);
      await fileIo.close(file.fd);
    } catch (error) {
      console.warn(`创建文件失败 ${filePath}:`, error);
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

    // 注册多个静态站点
    // 站点1：文档中心（/site1）
    this.server.registerStaticSite('/site1', this.site1Root, {
      maxAge: 3600, // 1小时缓存
      index: ['index.html'],
      directoryListing: false
    });

    // 站点2：图片画廊（/site2）
    this.server.registerStaticSite('/site2', this.site2Root, {
      maxAge: 7200, // 2小时缓存
      index: ['index.html'],
      directoryListing: true // 启用目录浏览
    });

    // 站点3：API文档（/site3）
    this.server.registerStaticSite('/site3', this.site3Root, {
      maxAge: 1800, // 30分钟缓存
      index: ['index.html', 'index.htm'],
      directoryListing: true
    });

    // 启用多站点服务
    this.server.serveMultiSite();

    // 主站点使用传统方式（作为后备）
    this.server.serveStatic(this.staticRoot, {
      maxAge: 0, // 不缓存
    });

    this.server.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      res.setHeader('Cache-Control', 'no-cache');
      next();
    });
  }


  /**
   * 文件管理路由
   */
  private setupRoutes(): void {
    if (!this.server) {
      return;
    }

    // 站点管理API
    this.server.get('/api/sites', (req: HttpRequest, res: HttpResponse) => {
      const sites = this.server?.getStaticSites();
      const siteInfos: SiteInfo[] = [];
      if (sites) {
        for (const site of sites) {
          const info: SiteInfo = {
            prefix: site.prefix,
            root: site.root,
            maxAge: site.maxAge,
            directoryListing: site.directoryListing,
            index: site.index
          };
          siteInfos.push(info);
        }
      }
      const response: SitesResponse = {
        total: sites?.length || 0,
        sites: siteInfos
      };
      res.json(response);
    });

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
          return res.status(400).json({ error: 'No file uploaded' } as ESObject);
        }

        const file = uploadedFile;
        const fileName = file.name;
        const filePath = `${this.staticRoot}/${fileName}`;

        const fileHandle = await fileIo.open(filePath,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
        await fileIo.write(fileHandle.fd, file.data);
        await fileIo.close(fileHandle.fd);

        res.json({
          message: 'File uploaded successfully',
          fileName,
          size: uploadedFile.data.byteLength,
          url: `/${fileName}`
        } as ESObject);
      } catch (e) {
        const error = e as Error;
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

    console.log('\n 多站点静态文件服务器 API端点:');
    console.log('='.repeat(60));

    console.log('\n 主站点:');
    console.log(`   GET  ${baseUrl}/                      - 主站首页`);
    console.log(`   GET  ${baseUrl}/css/style.css         - CSS文件`);
    console.log(`   GET  ${baseUrl}/js/app.js             - JavaScript文件`);
    console.log(`   GET  ${baseUrl}/data.json             - JSON数据`);

    console.log('\n 站点1 - 文档中心 (/site1):');
    console.log(`   GET  ${baseUrl}/site1/                - 文档中心首页`);
    console.log(`   GET  ${baseUrl}/site1/guides/         - 指南目录`);
    console.log(`   GET  ${baseUrl}/site1/api/            - API文档`);

    console.log('\n 站点2 - 图片画廊 (/site2):');
    console.log(`   GET  ${baseUrl}/site2/                - 画廊首页`);
    console.log(`   GET  ${baseUrl}/site2/photos/         - 照片目录（支持浏览）`);
    console.log(`   GET  ${baseUrl}/site2/gallery.json    - 画廊数据`);

    console.log('\n 站点3 - API文档 (/site3):');
    console.log(`   GET  ${baseUrl}/site3/                - API文档首页`);
    console.log(`   GET  ${baseUrl}/site3/v1/             - v1文档（支持浏览）`);
    console.log(`   GET  ${baseUrl}/site3/v2/             - v2文档（支持浏览）`);

    console.log('\n 管理API:');
    console.log(`   GET    ${baseUrl}/api/sites           - 获取所有站点信息`);
    console.log(`   GET    ${baseUrl}/api/files           - 文件浏览器`);
    console.log(`   POST   ${baseUrl}/api/upload          - 文件上传`);
    console.log(`   DELETE ${baseUrl}/api/files/*         - 文件删除`);

    console.log('='.repeat(60));
  }
}
