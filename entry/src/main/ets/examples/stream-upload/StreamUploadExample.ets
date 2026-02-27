/**
 * @fileName : StreamUploadExample.ets
 * @author : @cxy
 * @date : 2025/12/31
 * @description : 流式上传示例 - 展示如何接收客户端的流式上传数据
 */

import { HttpServer, HttpRequest, HttpResponse } from '@cxy/webserver';
import { socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

/**
 * 流式上传示例类
 */
export class StreamUploadExample {
  private server: HttpServer | null = null;
  private context?: common.UIAbilityContext;

  init(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 初始化服务器
   */
  public async initializeServer(): Promise<void> {
    this.server = new HttpServer();
    this.setupMiddleware();
    this.setupRoutes();
  }

  /**
   * 启动服务器
   */
  public async start(port: number): Promise<socket.NetAddress | null> {
    if (!this.server) {
      await this.initializeServer();
    }

    const info = await this.server?.startServer(port);
    if (info) {
      console.log('✅ 流式上传服务器启动成功!');
      console.log(`🌐 访问地址: http://${info.address}:${info.port}`);
      this.printApiEndpoints(info);
      return info;
    } else {
      console.error('❌ 启动服务器失败');
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
   * 配置中间件
   */
  private setupMiddleware(): void {
    if (!this.server) {
      return;
    }

    // 日志中间件
    this.server.logger({
      format: 'dev',
      stream: (log: string) => {
        console.log(`📝 ${log}`);
      }
    });

    // CORS中间件
    this.server.cors();
  }

  /**
   * 配置路由
   */
  private setupRoutes(): void {
    if (!this.server) {
      return;
    }

    // 示例1：接收流式上传的文本数据
    this.server.post('/api/upload/stream-text', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const transferEncoding = req.get('transfer-encoding');
        const isChunked = transferEncoding && transferEncoding.toLowerCase().includes('chunked');

        // 获取原始请求体
        const rawBody = req.getRawBody();
        const bodyText = req.body as string;

        res.json({
          success: true,
          message: '流式文本数据接收成功',
          isChunked: isChunked,
          receivedSize: rawBody.byteLength,
          contentPreview: bodyText.substring(0, 100)
        } as ESObject);
      } catch (error) {
        res.status(500).json({
          success: false,
          error: '处理失败',
          message: error.message
        } as ESObject);
      }
    });

    // 示例2：接收流式上传的JSON数据
    this.server.post('/api/upload/stream-json', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const transferEncoding = req.get('transfer-encoding');
        const isChunked = transferEncoding && transferEncoding.toLowerCase().includes('chunked');

        res.json({
          success: true,
          message: '流式JSON数据接收成功',
          isChunked: isChunked,
          receivedData: req.body,
          dataSize: JSON.stringify(req.body).length
        } as ESObject);
      } catch (error) {
        res.status(500).json({
          success: false,
          error: '处理失败',
          message: error.message
        } as ESObject);
      }
    });

    // 示例3：接收流式上传并保存到文件
    this.server.post('/api/upload/stream-file', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const transferEncoding = req.get('transfer-encoding');
        const isChunked = transferEncoding && transferEncoding.toLowerCase().includes('chunked');
        
        // 获取文件名（从查询参数或默认值）
        const filename = req.query.get('filename') || `upload-${Date.now()}.dat`;
        const filePath = `${this.context?.filesDir}/${filename}`;

        // 获取原始数据并保存
        const rawBody = req.getRawBody();
        const file = await fileIo.open(filePath,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
        
        await fileIo.write(file.fd, rawBody);
        await fileIo.close(file.fd);

        // 获取文件信息
        const stat = await fileIo.stat(filePath);

        res.json({
          success: true,
          message: '流式文件上传成功',
          isChunked: isChunked,
          filename: filename,
          filePath: filePath,
          fileSize: stat.size
        } as ESObject);
      } catch (error) {
        res.status(500).json({
          success: false,
          error: '文件保存失败',
          message: error.message
        } as ESObject);
      }
    });

    // 示例4：接收大文件流式上传
    this.server.post('/api/upload/stream-large', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const transferEncoding = req.get('transfer-encoding');
        const isChunked = transferEncoding && transferEncoding.toLowerCase().includes('chunked');
        const contentType = req.get('content-type') || 'application/octet-stream';

        const rawBody = req.getRawBody();
        const receivedSize = rawBody.byteLength;

        // 保存大文件
        const filename = `large-${Date.now()}.bin`;
        const filePath = `${this.context?.filesDir}/${filename}`;
        
        const file = await fileIo.open(filePath,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
        await fileIo.write(file.fd, rawBody);
        await fileIo.close(file.fd);

        res.json({
          success: true,
          message: '大文件流式上传成功',
          isChunked: isChunked,
          contentType: contentType,
          filename: filename,
          receivedSize: receivedSize,
          sizeInMB: (receivedSize / 1024 / 1024).toFixed(2)
        } as ESObject);
      } catch (error) {
        res.status(500).json({
          success: false,
          error: '大文件上传失败',
          message: error.message
        } as ESObject);
      }
    });

    // 示例5：获取上传的文件列表
    this.server.get('/api/upload/files', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const filesDir = this.context?.filesDir || '';
        const files: Array<Record<string, Object>> = [];

        // 列出目录中的文件
        const fileList = await fileIo.listFile(filesDir);
        
        for (const fileName of fileList) {
          const filePath = `${filesDir}/${fileName}`;
          
          try {
            const stat = await fileIo.stat(filePath);
            files.push({
              'name': fileName,
              'size': stat.size,
              'sizeInKB': (stat.size / 1024).toFixed(2),
              'mtime': stat.mtime
            });
          } catch (e) {
            // 跳过无法访问的文件
          }
        }

        res.json({
          success: true,
          filesDir: filesDir,
          count: files.length,
          files: files
        } as ESObject);
      } catch (error) {
        res.status(500).json({
          success: false,
          error: '获取文件列表失败',
          message: error.message
        } as ESObject);
      }
    });

    // 首页
    this.server.get('/', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        message: '流式上传示例服务器',
        description: '支持接收客户端使用Transfer-Encoding: chunked的流式上传',
        endpoints: [
          'POST /api/upload/stream-text - 接收流式文本数据',
          'POST /api/upload/stream-json - 接收流式JSON数据',
          'POST /api/upload/stream-file?filename=xxx - 接收流式文件上传',
          'POST /api/upload/stream-large - 接收大文件流式上传',
          'GET  /api/upload/files - 获取已上传的文件列表'
        ]
      } as ESObject);
    });
  }

  /**
   * 打印API端点信息
   */
  private printApiEndpoints(info: socket.NetAddress): void {
    const baseUrl = `http://${info.address}:${info.port}`;

    console.log('\n📋 流式上传API端点:');
    console.log('='.repeat(50));

    console.log('\n📤 流式上传示例:');
    console.log(`   POST   ${baseUrl}/api/upload/stream-text    - 流式文本上传`);
    console.log(`   POST   ${baseUrl}/api/upload/stream-json    - 流式JSON上传`);
    console.log(`   POST   ${baseUrl}/api/upload/stream-file    - 流式文件上传`);
    console.log(`   POST   ${baseUrl}/api/upload/stream-large   - 大文件流式上传`);
    console.log(`   GET    ${baseUrl}/api/upload/files          - 文件列表`);

    console.log('\n🚀 测试命令:');
    console.log(`   curl -X POST ${baseUrl}/api/upload/stream-text \\`);
    console.log(`        -H "Transfer-Encoding: chunked" \\`);
    console.log(`        -d "Hello, Streaming Upload!"`);
    console.log('='.repeat(50));
  }
}
