/**
 * @fileName : UploadExample.ets
 * @author : @cxy
 * @date : 2025/12/31
 * @description : 分片上传示例 - 展示大文件分片上传的最佳实践
 */

import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { HttpServer, HttpRequest, HttpResponse } from '@cxy/webserver';
import { socket } from '@kit.NetworkKit';

/**
 * 分片信息接口
 */
interface ChunkInfo {
  chunkIndex: number; // 分片索引
  totalChunks: number; // 总分片数
  chunkSize: number; // 分片大小
  fileName: string; // 文件名
  fileHash: string; // 文件哈希值（用于标识唯一文件）
}

/**
 * 上传任务接口
 */
interface UploadTask {
  fileHash: string; // 文件哈希
  fileName: string; // 文件名
  totalChunks: number; // 总分片数
  uploadedChunks: Set<number>; // 已上传的分片索引
  chunkPaths: Map<number, string>; // 分片文件路径
  createdAt: Date; // 创建时间
  updatedAt: Date; // 更新时间
}

/**
 * 分片上传示例类
 */
export class UploadExample {
  private server: HttpServer | null = null;
  private context?: common.UIAbilityContext;
  private uploadDir: string = ''; // 上传目录
  private tempDir: string = ''; // 临时分片目录
  private staticDir: string = ''; // 静态文件目录
  private uploadTasks: Map<string, UploadTask> = new Map(); // 上传任务映射

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
      console.log('✅ 分片上传服务器启动成功!');
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
      // 清理临时文件
      await this.cleanupTempFiles();
    }
  }

  /**
   * 初始化上传目录
   */
  private async setupDirectories(): Promise<void> {
    // 创建上传目录
    const uploadAccess = await fileIo.access(this.uploadDir);
    if (!uploadAccess) {
      await fileIo.mkdir(this.uploadDir);
    }

    // 创建临时目录
    const tempAccess = await fileIo.access(this.tempDir);
    if (!tempAccess) {
      await fileIo.mkdir(this.tempDir);
    }

    // 创建静态文件目录
    const staticAccess = await fileIo.access(this.staticDir);
    if (!staticAccess) {
      await fileIo.mkdir(this.staticDir);
    }

    // 复制HTML文件到静态目录
    await this.copyStaticFile('chunk-upload.html');
  }

  /**
   * 复制静态文件到沙箱目录
   */
  private async copyStaticFile(fileName: string): Promise<void> {
    try {
      const buffer = await this.context?.resourceManager.getRawFileContent(fileName);
      const filePath = `${this.staticDir}/${fileName}`;

      const file = await fileIo.open(filePath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      await fileIo.write(file.fd, buffer?.buffer);
      await fileIo.close(file.fd);
    } catch (error) {
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

    // 自动解析请求体
    this.server.auto();

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

    // 检查文件是否已存在
    this.server.post('/api/upload/check', (req: HttpRequest, res: HttpResponse) => {
      const data = req.body as Record<string, string>;
      const fileHash = data.fileHash;
      const fileName = data.fileName;

      if (!fileHash || !fileName) {
        res.status(400).json({
          error: 'fileHash and fileName are required'
        });
        return;
      }

      const task = this.uploadTasks.get(fileHash);
      if (task) {
        // 返回已上传的分片
        res.json({
          exists: true,
          uploadedChunks: Array.from(task.uploadedChunks),
          totalChunks: task.totalChunks
        });
      } else {
        res.json({
          exists: false,
          uploadedChunks: []
        });
      }
    });

    // 上传分片
    this.server.post('/api/upload/chunk', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const chunkFile = req.files?.['chunk'];
        const data = req.body as Record<string, string>;

        if (!chunkFile) {
          res.status(400).json({ error: 'No chunk file uploaded' });
          return;
        }

        const chunkInfo: ChunkInfo = {
          chunkIndex: parseInt(data.chunkIndex),
          totalChunks: parseInt(data.totalChunks),
          chunkSize: chunkFile.data.byteLength,
          fileName: data.fileName,
          fileHash: data.fileHash
        };

        // 验证参数
        if (!chunkInfo.fileHash || !chunkInfo.fileName ||
        isNaN(chunkInfo.chunkIndex) || isNaN(chunkInfo.totalChunks)) {
          res.status(400).json({ error: 'Invalid chunk parameters' });
          return;
        }

        // 获取或创建上传任务
        let task = this.uploadTasks.get(chunkInfo.fileHash);
        if (!task) {
          task = {
            fileHash: chunkInfo.fileHash,
            fileName: chunkInfo.fileName,
            totalChunks: chunkInfo.totalChunks,
            uploadedChunks: new Set<number>(),
            chunkPaths: new Map<number, string>(),
            createdAt: new Date(),
            updatedAt: new Date()
          };
          this.uploadTasks.set(chunkInfo.fileHash, task);
        }

        // 保存分片
        const chunkPath = `${this.tempDir}/${chunkInfo.fileHash}_${chunkInfo.chunkIndex}`;
        const file = await fileIo.open(chunkPath,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
        await fileIo.write(file.fd, chunkFile.data);
        await fileIo.close(file.fd);

        // 更新任务状态
        task.uploadedChunks.add(chunkInfo.chunkIndex);
        task.chunkPaths.set(chunkInfo.chunkIndex, chunkPath);
        task.updatedAt = new Date();

        console.log(`📦 分片上传成功: ${chunkInfo.fileName} [${chunkInfo.chunkIndex + 1}/${chunkInfo.totalChunks}]`);

        res.json({
          message: 'Chunk uploaded successfully',
          chunkIndex: chunkInfo.chunkIndex,
          uploadedChunks: task.uploadedChunks.size,
          totalChunks: task.totalChunks,
          progress: (task.uploadedChunks.size / task.totalChunks * 100).toFixed(2)
        });
      } catch (error) {
        console.error('❌ 分片上传失败:', error);
        res.status(500).json({ error: 'Failed to upload chunk' });
      }
    });

    // 合并分片
    this.server.post('/api/upload/merge', async (req: HttpRequest, res: HttpResponse, next) => {
      try {
        const data = req.body as Record<string, string>;
        const fileHash = data.fileHash;
        const fileName = data.fileName;

        if (!fileHash || !fileName) {
          res.status(400).json({ error: 'fileHash and fileName are required' });
          return;
        }

        const task = this.uploadTasks.get(fileHash);
        if (!task) {
          res.status(404).json({ error: 'Upload task not found' });
          return;
        }

        // 检查是否所有分片都已上传
        if (task.uploadedChunks.size !== task.totalChunks) {
          res.status(400).json({
            error: 'Not all chunks uploaded',
            uploaded: task.uploadedChunks.size,
            total: task.totalChunks
          });
          return;
        }

        // 合并分片
        const finalPath = `${this.uploadDir}/${fileName}`;
        const finalFile = await fileIo.open(finalPath,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);

        // 按顺序写入分片
        for (let i = 0; i < task.totalChunks; i++) {
          const chunkPath = task.chunkPaths.get(i);
          if (chunkPath) {
            const chunkFile = await fileIo.open(chunkPath, fileIo.OpenMode.READ_ONLY);
            const stat = await fileIo.stat(chunkPath);
            const buffer = new ArrayBuffer(stat.size);
            await fileIo.read(chunkFile.fd, buffer);
            await fileIo.write(finalFile.fd, buffer);
            await fileIo.close(chunkFile.fd);
          }
        }

        await fileIo.close(finalFile.fd);

        // 获取文件信息
        const stat = await fileIo.stat(finalPath);

        // 清理临时分片
        await this.cleanupTaskChunks(task);
        this.uploadTasks.delete(fileHash);

        console.log(`✅ 文件合并成功: ${fileName} (${stat.size} bytes)`);

        const fileInfo: Record<string, Object> = {
          'name': fileName,
          'size': stat.size,
          'path': finalPath,
          'hash': fileHash,
          'uploadTime': new Date().toISOString()
        };

        res.json({
          message: 'File merged successfully',
          file: fileInfo as ESObject
        } as ESObject);
      } catch (error) {
        console.error('❌ 文件合并失败:', error);
        res.status(500).json({ error: 'Failed to merge file' });
      }
    });

    // 取消上传
    this.server.delete('/api/upload/cancel/:fileHash', async (req: HttpRequest, res: HttpResponse, next) => {
      const fileHash = req.params['fileHash'];
      const task = this.uploadTasks.get(fileHash);

      if (!task) {
        res.status(404).json({ error: 'Upload task not found' });
        return;
      }

      await this.cleanupTaskChunks(task);
      this.uploadTasks.delete(fileHash);

      res.json({
        message: 'Upload cancelled successfully',
        fileHash: fileHash
      } as ESObject);
    });

    // 获取上传任务列表
    this.server.get('/api/upload/tasks', (req: HttpRequest, res: HttpResponse) => {
      const tasks = Array.from(this.uploadTasks.values()).map(task => {
        const taskInfo: Record<string, Object> = {
          'fileHash': task.fileHash,
          'fileName': task.fileName,
          'totalChunks': task.totalChunks,
          'uploadedChunks': task.uploadedChunks.size,
          'progress': (task.uploadedChunks.size / task.totalChunks * 100).toFixed(2),
          'createdAt': task.createdAt.toISOString(),
          'updatedAt': task.updatedAt.toISOString()
        };
        return taskInfo;
      });

      res.json({
        tasks,
        count: tasks.length
      });
    });

    // 获取已上传文件列表
    this.server.get('/api/upload/files', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const files = await fileIo.listFile(this.uploadDir);
        const fileList = await Promise.all(
          files.filter(file => !file.startsWith('.')).map(async (file) => {
            const filePath = `${this.uploadDir}/${file}`;
            const stat = await fileIo.stat(filePath);
            const fileInfo: Record<string, Object> = {
              'name': file,
              'size': stat.size,
              'path': filePath,
              'modifiedTime': new Date(stat.mtime).toISOString()
            };
            return fileInfo;
          })
        );

        res.json({
          files: fileList,
          count: fileList.length
        });
      } catch (error) {
        console.error('❌ 获取文件列表失败:', error);
        res.status(500).json({ error: 'Failed to list files' });
      }
    });
  }

  /**
   * 清理任务的临时分片文件
   */
  private async cleanupTaskChunks(task: UploadTask): Promise<void> {
    for (const chunkPath of task.chunkPaths.values()) {
      try {
        const exists = await fileIo.access(chunkPath);
        if (exists) {
          await fileIo.unlink(chunkPath);
        }
      } catch (error) {
        console.error(`清理分片失败: ${chunkPath}`, error);
      }
    }
  }

  /**
   * 清理所有临时文件
   */
  private async cleanupTempFiles(): Promise<void> {
    try {
      const files = await fileIo.listFile(this.tempDir);
      for (const file of files) {
        const filePath = `${this.tempDir}/${file}`;
        await fileIo.unlink(filePath);
      }
      console.log('🧹 临时文件清理完成');
    } catch (error) {
      console.error('清理临时文件失败:', error);
    }
  }

  /**
   * 打印API端点信息
   */
  private printApiEndpoints(info: socket.NetAddress): void {
    const baseUrl = `http://${info.address}:${info.port}`;

    console.log('\n📋 分片上传API端点:');
    console.log('='.repeat(50));

    console.log('\n🌐 Web界面:');
    console.log(`   GET    ${baseUrl}/chunk-upload.html   - 分片上传测试页面`);

    console.log('\n🔧 上传相关:');
    console.log(`   POST   ${baseUrl}/api/upload/check    - 检查文件上传状态`);
    console.log(`   POST   ${baseUrl}/api/upload/chunk    - 上传分片`);
    console.log(`   POST   ${baseUrl}/api/upload/merge    - 合并分片`);
    console.log(`   DELETE ${baseUrl}/api/upload/cancel/:fileHash - 取消上传`);

    console.log('\n📊 查询相关:');
    console.log(`   GET    ${baseUrl}/api/upload/tasks    - 获取上传任务列表`);
    console.log(`   GET    ${baseUrl}/api/upload/files    - 获取已上传文件列表`);

    console.log('\n🚀 测试方式:');
    console.log(`   1. 浏览器访问: ${baseUrl}/chunk-upload.html`);
    console.log(`   2. 命令行测试: sh ./entry/src/main/ets/examples/upload/test-upload.sh`);
    console.log('='.repeat(50));
  }
}
