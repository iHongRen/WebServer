/**
 * @fileName : StreamExample.ets
 * @author : @cxy
 * @date : 2025/12/31
 * @description : 流式传输示例 - 展示WebServer的流式传输功能
 *   包含流式响应（write/chunked）和流式上传（server.stream）两大类
 */

import { HttpServer, HttpRequest, HttpResponse, UploadStream } from '@cxy/webserver';
import { socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

/**
 * 流式传输示例类
 */
export class StreamExample {
  private server: HttpServer | null = null;
  private context?: common.UIAbilityContext;
  private uploadDir: string = '';

  init(context: common.UIAbilityContext) {
    this.context = context;
    this.uploadDir = context.filesDir + '/stream-uploads';
  }

  /**
   * 初始化服务器
   */
  public async initializeServer(): Promise<void> {
    this.server = new HttpServer();
    await this.ensureDir(this.uploadDir);
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
      console.log('✅ 流式传输服务器启动成功!');
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

    // 示例1：流式发送文本数据
    this.server.get('/api/stream/text', async (req: HttpRequest, res: HttpResponse) => {
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      res.setHeader('Transfer-Encoding', 'chunked');

      // 模拟流式发送数据
      for (let i = 1; i <= 10; i++) {
        await res.write(`数据块 ${i}\n`);
        // 模拟延迟
        await this.sleep(500);
      }

      await res.end('流式传输完成\n');
    });

    // 示例2：流式发送JSON数据（Server-Sent Events风格）
    this.server.get('/api/stream/events', async (req: HttpRequest, res: HttpResponse) => {
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');

      // 发送事件流
      for (let i = 1; i <= 5; i++) {
        const eventData: Record<string, Object> = {
          'id': i,
          'message': `事件 ${i}`,
          'timestamp': Date.now()
        };
        const event = `data: ${JSON.stringify(eventData)}\n\n`;
        await res.write(event);
        await this.sleep(1000);
      }

      await res.end();
    });

    // 示例3：流式发送大量数据
    this.server.get('/api/stream/large', async (req: HttpRequest, res: HttpResponse) => {
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');

      const chunkSize = 1024; // 1KB per chunk
      const totalChunks = 100; // 总共100KB

      for (let i = 0; i < totalChunks; i++) {
        // 生成1KB的数据
        const data = 'A'.repeat(chunkSize);
        await res.write(data);
        
        // 每10个块打印一次进度
        if ((i + 1) % 10 === 0) {
          console.log(`已发送: ${(i + 1) * chunkSize / 1024}KB`);
        }
      }

      await res.end('\n流式传输完成\n');
    });

    // 示例4：流式读取并发送文件
    this.server.get('/api/stream/file', async (req: HttpRequest, res: HttpResponse, next) => {
      try {
        // 这里使用一个示例文件路径，实际应用中应该从请求参数获取
        const filePath = `${this.context?.filesDir}/test-stream.txt`;

        // 检查文件是否存在
        const exists = await fileIo.access(filePath);
        if (!exists) {
          // 创建一个测试文件
          await this.createTestFile(filePath);
        }

        // 获取文件大小
        const stat = await fileIo.stat(filePath);
        
        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        res.setHeader('Content-Length', stat.size.toString());

        // 打开文件
        const file = await fileIo.open(filePath, fileIo.OpenMode.READ_ONLY);

        try {
          // 分块读取并发送文件
          const chunkSize = 4096; // 4KB per chunk
          let offset = 0;

          while (offset < stat.size) {
            const readSize = Math.min(chunkSize, stat.size - offset);
            const buffer = new ArrayBuffer(readSize);
            
            await fileIo.read(file.fd, buffer, { offset: offset });
            await res.write(buffer);
            
            offset += readSize;
          }

          await res.end();
        } finally {
          await fileIo.close(file.fd);
        }
      } catch (error) {
        console.error('流式文件传输失败:', error);
        next(error);
      }
    });

    // 示例5：实时日志流
    this.server.get('/api/stream/logs', async (req: HttpRequest, res: HttpResponse) => {
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      res.setHeader('Transfer-Encoding', 'chunked');

      const logMessages = [
        '[INFO] 服务器启动',
        '[INFO] 加载配置文件',
        '[INFO] 连接数据库',
        '[WARN] 数据库连接缓慢',
        '[INFO] 数据库连接成功',
        '[INFO] 初始化路由',
        '[INFO] 启动HTTP服务器',
        '[INFO] 服务器就绪，监听端口 8080',
      ];

      for (const log of logMessages) {
        const timestamp = new Date().toISOString();
        await res.write(`[${timestamp}] ${log}\n`);
        await this.sleep(800);
      }

      await res.end('[INFO] 日志流结束\n');
    });

    // 示例6：进度报告
    this.server.get('/api/stream/progress', async (req: HttpRequest, res: HttpResponse) => {
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Transfer-Encoding', 'chunked');

      const totalSteps = 10;
      
      for (let step = 1; step <= totalSteps; step++) {
        const progress: Record<string, Object> = {
          'step': step,
          'total': totalSteps,
          'percentage': (step / totalSteps * 100).toFixed(2),
          'message': `处理步骤 ${step}/${totalSteps}`,
          'timestamp': Date.now()
        };
        
        await res.write(JSON.stringify(progress) + '\n');
        await this.sleep(1000);
      }

      await res.end();
    });

    // =====================================================================
    // 流式上传（server.stream）—— 边接收 body 边处理，内存占用固定在单个 TCP 包
    // =====================================================================

    // 示例7：流式上传，直接写入磁盘
    // 与普通上传（FileUpload 中间件）的核心区别：
    //   - 普通上传：整个请求体全部进内存后才触发路由
    //   - 流式上传：header 到达后立即触发路由，body 逐 TCP 包推送给 req.uploadStream
    this.server.stream('/api/stream/upload', async (req: HttpRequest, res: HttpResponse) => {
      const stream = req.uploadStream as UploadStream;

      // 从请求头读取文件名（客户端通过 X-File-Name 传递）
      const rawName = req.get('x-file-name') ?? `upload_${Date.now()}.bin`;
      const fileName = rawName.replace(/[^a-zA-Z0-9._-]/g, '_');
      const destPath = `${this.uploadDir}/${fileName}`;

      let fd: number = -1;
      let bytesWritten: number = 0;
      let hasError: boolean = false;

      try {
        const file = await fileIo.open(
          destPath,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC
        );
        fd = file.fd;
      } catch (e) {
        const err = e as Error;
        res.status(500).json({ success: false, error: '无法创建目标文件', detail: err.message } as ESObject);
        return;
      }

      // 每个 TCP 包到达时触发，逐块写入磁盘
      stream.on('data', async (chunk: ArrayBuffer) => {
        if (hasError) {
          return;
        }
        try {
          // 必须传 offset，否则每次都从文件头部写，后面的 chunk 会覆盖前面的数据
          await fileIo.write(fd, chunk, { offset: bytesWritten, length: chunk.byteLength });
          bytesWritten += chunk.byteLength;
          if (stream.contentLength > 0) {
            const pct = (stream.progress * 100).toFixed(1);
            console.log(`[StreamUpload] ${fileName} ${pct}% (${bytesWritten}/${stream.contentLength} bytes)`);
          }
        } catch (e) {
          hasError = true;
          const err = e as Error;
          console.error('[StreamUpload] write error:', err.message);
          stream._error(err);
        }
      });

      // body 全部收完
      stream.on('end', async () => {
        try {
          await fileIo.close(fd);
          fd = -1;
        } catch (_) {
        }
        const stat = await fileIo.stat(destPath).catch(() => null);
        res.json({
          success: true,
          message: '流式上传完成',
          fileName: fileName,
          size: stat?.size ?? bytesWritten,
        } as ESObject);
      });

      // 上传出错（客户端断连等）
      stream.on('error', async (err: Error) => {
        console.error('[StreamUpload] error:', err.message);
        if (fd >= 0) {
          await fileIo.close(fd).catch(() => {});
          fd = -1;
        }
        await fileIo.unlink(destPath).catch(() => {});
        if (!res.isHeadersSent()) {
          res.status(500).json({ success: false, error: '上传失败', detail: err.message } as ESObject);
        }
      });
    });

    // 示例8：流式接收，仅统计字节数（不落盘）
    // 适合接收后做实时处理（加密、转码、哈希校验等）而非直接落盘的场景
    this.server.stream('/api/stream/count', (req: HttpRequest, res: HttpResponse) => {
      const stream = req.uploadStream as UploadStream;
      let totalBytes = 0;
      let chunkCount = 0;

      stream.on('data', (chunk: ArrayBuffer) => {
        totalBytes += chunk.byteLength;
        chunkCount++;
      });

      stream.on('end', () => {
        res.json({
          success: true,
          message: '统计完成（未写盘）',
          totalBytes: totalBytes,
          chunkCount: chunkCount,
          averageChunkSize: chunkCount > 0 ? Math.round(totalBytes / chunkCount) : 0,
          declaredContentLength: stream.contentLength,
        } as ESObject);
      });

      stream.on('error', (err: Error) => {
        res.status(500).json({ success: false, error: err.message } as ESObject);
      });
    });

    // 示例9：已上传文件列表
    this.server.get('/api/stream/files', async (_req: HttpRequest, res: HttpResponse) => {
      try {
        const names = await fileIo.listFile(this.uploadDir);
        const fileList: ESObject[] = [];
        for (const n of names) {
          if (n.startsWith('.')) {
            continue;
          }
          const stat = await fileIo.stat(`${this.uploadDir}/${n}`).catch(() => null);
          const item: ESObject = {
            name: n,
            size: stat?.size ?? 0,
            sizeMB: ((stat?.size ?? 0) / 1024 / 1024).toFixed(2),
          } as ESObject;
          fileList.push(item);
        }
        res.json({ success: true, count: fileList.length, files: fileList } as ESObject);
      } catch (e) {
        res.status(500).json({ success: false, error: (e as Error).message } as ESObject);
      }
    });

    // 首页
    this.server.get('/', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        message: '流式传输示例服务器',
        endpoints: [
          '/api/stream/text     - 流式文本数据（GET）',
          '/api/stream/events   - Server-Sent Events（GET）',
          '/api/stream/large    - 大数据流（GET）',
          '/api/stream/file     - 文件流（GET）',
          '/api/stream/logs     - 实时日志流（GET）',
          '/api/stream/progress - 进度报告（GET）',
          '/api/stream/upload   - 流式上传并写入磁盘（POST，携带 X-File-Name 头）',
          '/api/stream/count    - 流式接收，仅统计字节数（POST）',
          '/api/stream/files    - 查看已上传文件列表（GET）',
        ]
      } as ESObject);
    });
  }

  /**
   * 创建测试文件
   */
  private async createTestFile(filePath: string): Promise<void> {
    const content = '这是一个测试文件，用于演示流式文件传输。\n'.repeat(100);
    const file = await fileIo.open(filePath,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
    await fileIo.write(file.fd, content);
    await fileIo.close(file.fd);
  }

  /**
   * 延迟函数
   */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 打印API端点信息
   */
  private printApiEndpoints(info: socket.NetAddress): void {
    const baseUrl = `http://${info.address}:${info.port}`;

    console.log('\n📋 流式传输API端点:');
    console.log('='.repeat(55));

    console.log('\n🌊 流式响应（服务端 → 客户端）:');
    console.log(`   GET    ${baseUrl}/                       - 首页`);
    console.log(`   GET    ${baseUrl}/api/stream/text        - 流式文本数据`);
    console.log(`   GET    ${baseUrl}/api/stream/events      - Server-Sent Events`);
    console.log(`   GET    ${baseUrl}/api/stream/large       - 大数据流`);
    console.log(`   GET    ${baseUrl}/api/stream/file        - 文件流`);
    console.log(`   GET    ${baseUrl}/api/stream/logs        - 实时日志流`);
    console.log(`   GET    ${baseUrl}/api/stream/progress    - 进度报告`);

    console.log('\n📤 流式上传（客户端 → 服务端）:');
    console.log(`   POST   ${baseUrl}/api/stream/upload      - 流式上传写入磁盘（需 X-File-Name 头）`);
    console.log(`   POST   ${baseUrl}/api/stream/count       - 流式接收，仅统计字节数`);
    console.log(`   GET    ${baseUrl}/api/stream/files       - 已上传文件列表`);

    console.log('\n🚀 测试命令:');
    console.log(`   curl ${baseUrl}/api/stream/text`);
    console.log(`   curl ${baseUrl}/api/stream/events`);
    console.log(`   curl -X POST ${baseUrl}/api/stream/upload \\`);
    console.log(`        -H "Content-Type: application/octet-stream" \\`);
    console.log(`        -H "X-File-Name: test.bin" \\`);
    console.log(`        --data-binary "@/path/to/file"`);
    console.log('='.repeat(55));
  }

  /**
   * 确保目录存在
   */
  private async ensureDir(dir: string): Promise<void> {
    try {
      const exists = await fileIo.access(dir);
      if (!exists) {
        await fileIo.mkdir(dir);
      }
    } catch (_) {
      // 目录已存在时忽略
    }
  }
}
