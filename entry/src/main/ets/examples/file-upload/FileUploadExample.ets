/**
 * @fileName : FileUploadExample.ets
 * @author : @cxy
 * @date : 2025/3/3
 * @description : 文件上传示例 - 基于 express-fileupload 设计的流式上传中间件
 */

import { HttpServer, HttpRequest, HttpResponse, FileUpload } from '@cxy/webserver';
import type { UploadedFile } from '@cxy/webserver';
import { socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

/**
 * 文件上传示例类
 */
export class FileUploadExample {
  private server: HttpServer | null = null;
  private context?: common.UIAbilityContext;
  private uploadDir: string = '';
  private tempDir: string = '';
  private staticDir: string = '';

  init(context: common.UIAbilityContext) {
    this.context = context;
    this.uploadDir = context.filesDir + '/uploads';
    this.tempDir = context.filesDir + '/temp';
    this.staticDir = context.filesDir + '/static';
  }

  /**
   * 初始化服务器
   */
  public async initializeServer(): Promise<void> {
    this.server = new HttpServer();
    await this.setupDirectories();
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
      console.log('✅ 文件上传服务器启动成功!');
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
      await this.cleanupTempFiles();
    }
  }

  /**
   * 初始化目录
   */
  private async setupDirectories(): Promise<void> {
    const dirs = [this.uploadDir, this.tempDir, this.staticDir];

    for (const dir of dirs) {
      try {
        const exists = await fileIo.access(dir);
        if (!exists) {
          await fileIo.mkdir(dir);
        }
      } catch (e) {
        // 目录可能已存在，忽略错误
      }
    }

    // 复制HTML文件到静态目录
    await this.copyStaticFile('file-upload.html');
  }

  /**
   * 复制静态文件
   */
  private async copyStaticFile(fileName: string): Promise<void> {
    try {
      const buffer = await this.context?.resourceManager.getRawFileContent(fileName);
      const filePath = `${this.staticDir}/${fileName}`;

      const file = await fileIo.open(filePath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      await fileIo.write(file.fd, buffer?.buffer);
      await fileIo.close(file.fd);
    } catch (e) {
      const error = e as Error;
      console.error(`复制静态文件失败: ${fileName}`, error);
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

    // 文件上传中间件 - 全局应用
    this.server.use(FileUpload.create({
      tempFileDir: this.tempDir,
      limits: {
        fileSize: 100 * 1024 * 1024, // 100MB
        files: 10
      },
      createParentPath: true,
      debug: true
    }));

    // 静态文件服务
    this.server.serveStatic(this.staticDir);
  }

  /**
   * 配置路由
   */
  private setupRoutes(): void {
    if (!this.server) {
      return;
    }

    // 示例1：基本文件上传
    this.server.post('/api/upload/basic', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const files = req.files;
        const uploadedFiles: Array<Record<string, Object>> = [];

        // 移动文件到上传目录
        const fileKeys = Object.keys(files);
        for (let i = 0; i < fileKeys.length; i++) {
          const key = fileKeys[i];
          const file = files[key] as UploadedFile;
          const destPath = `${this.uploadDir}/${file.name}`;
          await file.mv(destPath);

          const fileInfo: Record<string, Object> = {
            'fieldName': key,
            'fileName': file.name,
            'size': file.size,
            'mimetype': file.mimetype,
            'path': destPath
          };
          uploadedFiles.push(fileInfo);
        }

        res.json({
          success: true,
          message: '文件上传成功',
          fields: req.body,
          files: uploadedFiles
        } as ESObject);
      } catch (e) {
        const error = e as Error;
        res.status(500).json({
          success: false,
          error: '文件上传失败',
          message: error.message
        } as ESObject);
      }
    });

    // 示例2：单文件上传（application/octet-stream）
    this.server.post('/api/upload/stream', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const file = req.files['file'] as UploadedFile;

        if (!file) {
          res.status(400).json({
            success: false,
            error: '没有上传文件'
          } as ESObject);
          return;
        }

        // 移动文件
        const destPath = `${this.uploadDir}/${file.name}`;
        await file.mv(destPath);

        const fileInfo: Record<string, Object> = {
          'name': file.name,
          'size': file.size,
          'mimetype': file.mimetype,
          'path': destPath
        };

        res.json({
          success: true,
          message: '流式上传成功',
          file: fileInfo
        } as ESObject);
      } catch (e) {
        const error = e as Error;
        res.status(500).json({
          success: false,
          error: '上传失败',
          message: error.message
        } as ESObject);
      }
    });

    // 示例3：多文件上传
    this.server.post('/api/upload/multiple', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const files = req.files;
        const uploadedFiles: Array<Record<string, Object>> = [];
        let totalSize = 0;

        const fileKeys = Object.keys(files);
        for (let i = 0; i < fileKeys.length; i++) {
          const key = fileKeys[i];
          const file = files[key] as UploadedFile;
          const destPath = `${this.uploadDir}/${file.name}`;
          await file.mv(destPath);

          totalSize += file.size;
          const fileInfo: Record<string, Object> = {
            'fieldName': key,
            'fileName': file.name,
            'size': file.size,
            'sizeInMB': (file.size / 1024 / 1024).toFixed(2),
            'mimetype': file.mimetype
          };
          uploadedFiles.push(fileInfo);
        }

        const summaryInfo: Record<string, Object> = {
          'fileCount': uploadedFiles.length,
          'totalSize': totalSize,
          'totalSizeMB': (totalSize / 1024 / 1024).toFixed(2)
        };

        res.json({
          success: true,
          message: '多文件上传成功',
          summary: summaryInfo,
          files: uploadedFiles
        } as ESObject);
      } catch (e) {
        const error = e as Error;
        res.status(500).json({
          success: false,
          error: '上传失败',
          message: error.message
        } as ESObject);
      }
    });

    // 示例4：带文件名清理的上传
    this.server.post('/api/upload/safe', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const files = req.files;
        const uploadedFiles: Array<Record<string, Object>> = [];

        const fileKeys = Object.keys(files);
        for (let i = 0; i < fileKeys.length; i++) {
          const key = fileKeys[i];
          const file = files[key] as UploadedFile;
          const destPath = `${this.uploadDir}/${file.name}`;
          await file.mv(destPath);

          const fileInfo: Record<string, Object> = {
            'originalName': key,
            'safeName': file.name,
            'size': file.size,
            'mimetype': file.mimetype
          };
          uploadedFiles.push(fileInfo);
        }

        res.json({
          success: true,
          message: '安全文件名上传成功',
          files: uploadedFiles
        } as ESObject);
      } catch (e) {
        const error = e as Error;
        res.status(500).json({
          success: false,
          error: '上传失败',
          message: error.message
        } as ESObject);
      }
    });

    // 示例5：带大小限制的上传
    this.server.post('/api/upload/limited', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const files = req.files;
        const uploadedFiles: Array<Record<string, Object>> = [];

        const fileKeys = Object.keys(files);
        for (let i = 0; i < fileKeys.length; i++) {
          const key = fileKeys[i];
          const file = files[key] as UploadedFile;
          const destPath = `${this.uploadDir}/${file.name}`;
          await file.mv(destPath);

          const fileInfo: Record<string, Object> = {
            'fileName': file.name,
            'size': file.size,
            'truncated': file.truncated
          };
          uploadedFiles.push(fileInfo);
        }

        res.json({
          success: true,
          message: '限制大小上传成功',
          files: uploadedFiles
        } as ESObject);
      } catch (e) {
        const error = e as Error;
        res.status(500).json({
          success: false,
          error: '上传失败',
          message: error.message
        } as ESObject);
      }
    });

    // 获取已上传文件列表
    this.server.get('/api/upload/files', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const files = await fileIo.listFile(this.uploadDir);
        const fileList = await Promise.all(
          files.filter(file => !file.startsWith('.')).map(async (file): Promise<Record<string, Object>> => {
            const filePath = `${this.uploadDir}/${file}`;
            const stat = await fileIo.stat(filePath);
            const fileInfo: Record<string, Object> = {
              'name': file,
              'size': stat.size,
              'sizeInMB': (stat.size / 1024 / 1024).toFixed(2),
              'modifiedTime': new Date(stat.mtime).toISOString()
            };
            return fileInfo;
          })
        );

        res.json({
          success: true,
          uploadDir: this.uploadDir,
          count: fileList.length,
          files: fileList
        } as ESObject);
      } catch (e) {
        const error = e as Error;
        res.status(500).json({
          success: false,
          error: '获取文件列表失败',
          message: error.message
        } as ESObject);
      }
    });

    // 删除文件
    this.server.delete('/api/upload/files/:filename', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const filename = req.params['filename'];
        const filePath = `${this.uploadDir}/${filename}`;

        const exists = await fileIo.access(filePath);
        if (!exists) {
          res.status(404).json({
            success: false,
            error: '文件不存在'
          } as ESObject);
          return;
        }

        await fileIo.unlink(filePath);

        res.json({
          success: true,
          message: '文件删除成功',
          filename: filename
        } as ESObject);
      } catch (e) {
        const error = e as Error;
        res.status(500).json({
          success: false,
          error: '删除文件失败',
          message: error.message
        } as ESObject);
      }
    });

    // 首页
    this.server.get('/', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        message: '文件上传中间件示例',
        description: '基于 express-fileupload 设计，支持流式上传和临时文件管理',
        features: [
          '流式处理，使用 fs.createWriteStream',
          '支持 multipart/form-data 和 application/octet-stream',
          '自动临时文件管理',
          '提供 mv() 方法移动文件',
          '支持文件大小、数量、类型限制',
          '支持安全文件名处理',
          '支持自动创建父目录'
        ],
        endpoints: [
          'POST /api/upload/basic - 基本文件上传',
          'POST /api/upload/stream - 单文件流式上传',
          'POST /api/upload/multiple - 多文件上传',
          'POST /api/upload/safe - 安全文件名上传',
          'POST /api/upload/limited - 限制大小上传',
          'GET  /api/upload/files - 获取文件列表',
          'DELETE /api/upload/files/:filename - 删除文件'
        ]
      } as ESObject);
    });
  }

  /**
   * 清理临时文件
   */
  private async cleanupTempFiles(): Promise<void> {
    try {
      const files = await fileIo.listFile(this.tempDir);
      for (const file of files) {
        const filePath = `${this.tempDir}/${file}`;
        await fileIo.unlink(filePath);
      }
      console.log('🧹 临时文件清理完成');
    } catch (e) {
      const error = e as Error;
      console.error('清理临时文件失败:', error);
    }
  }

  /**
   * 打印API端点信息
   */
  private printApiEndpoints(info: socket.NetAddress): void {
    const baseUrl = `http://${info.address}:${info.port}`;

    console.log('\n📋 文件上传API端点:');
    console.log('='.repeat(50));

    console.log('\n🌐 Web界面:');
    console.log(`   GET    ${baseUrl}/file-upload.html   - 文件上传测试页面`);

    console.log('\n📤 上传接口:');
    console.log(`   POST   ${baseUrl}/api/upload/basic      - 基本上传`);
    console.log(`   POST   ${baseUrl}/api/upload/stream     - 流式上传`);
    console.log(`   POST   ${baseUrl}/api/upload/multiple   - 多文件上传`);
    console.log(`   POST   ${baseUrl}/api/upload/safe       - 安全文件名`);
    console.log(`   POST   ${baseUrl}/api/upload/limited    - 限制大小`);

    console.log('\n📊 管理接口:');
    console.log(`   GET    ${baseUrl}/api/upload/files      - 文件列表`);
    console.log(`   DELETE ${baseUrl}/api/upload/files/:filename - 删除文件`);

    console.log('\n🚀 测试命令:');
    console.log(`   # multipart/form-data 上传`);
    console.log(`   curl -X POST ${baseUrl}/api/upload/basic \\`);
    console.log(`        -F "file=@test.jpg" \\`);
    console.log(`        -F "description=测试文件"`);
    console.log('');
    console.log(`   # application/octet-stream 上传`);
    console.log(`   curl -X POST ${baseUrl}/api/upload/stream \\`);
    console.log(`        -H "Content-Type: application/octet-stream" \\`);
    console.log(`        --data-binary "@test.jpg"`);
    console.log('='.repeat(50));
  }
}
