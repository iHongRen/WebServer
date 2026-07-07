/**
 * @fileName : FileUploadExample.ets
 * @author : @cxy
 * @date : 2025/3/3
 * @description : 文件上传完整示例
 *   - FileUpload 中间件：multipart/form-data、多文件、安全文件名、大小限制
 *   - 流式上传：server.stream()，边接收边写盘，适合 GB 级大文件
 *   - 分片上传：断点续传、分片合并，适合超大文件或弱网环境
 */

import { HttpServer, HttpRequest, HttpResponse, FileUpload, UploadStream, Utils } from '@cxy/webserver';
import type { UploadedFile } from '@cxy/webserver';
import { socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

// ── 分片上传相关接口 ────────────────────────────────────────────────────────

interface ChunkInfo {
  chunkIndex: number;
  totalChunks: number;
  fileName: string;
  fileHash: string;
}

interface UploadTask {
  fileHash: string;
  fileName: string;
  totalChunks: number;
  uploadedChunks: Set<number>;
  chunkPaths: Map<number, string>;
  createdAt: Date;
  updatedAt: Date;
}

// ArkTS 要求对象字面量必须对应已声明接口，以下是必要的最小化接口集合

interface UploadFileInfo {
  fieldName: string;
  fileName: string;
  size: number;
  mimetype: string;
  path: string;
  // 可选扩展字段（多文件用）
  sizeMB?: string;
  // 安全上传用
  originalName?: string;
  safeName?: string;
  // 限制上传用
  truncated?: boolean;
}

interface UploadResp {
  success: boolean;
  message: string;
  files: UploadFileInfo[];
  summary?: MultiSummary;
}

interface MultiSummary {
  fileCount: number;
  totalSize: number;
  totalSizeMB: string;
}

interface StreamResp {
  success: boolean;
  message: string;
  fileName: string;
  size: number;
}

interface StreamErrResp {
  success: boolean;
  error: string;
  detail: string;
}

interface ChunkCheckResp {
  exists: boolean;
  uploadedChunks: number[];
  totalChunks?: number;
}

interface ChunkUploadResp {
  message: string;
  chunkIndex: number;
  uploadedChunks: number;
  totalChunks: number;
  progress: string;
}

interface MergeFileInfo {
  name: string;
  size: number;
  path: string;
  hash: string;
  uploadTime: string;
}

interface MergeResp {
  message: string;
  file: MergeFileInfo;
}

interface TaskInfo {
  fileHash: string;
  fileName: string;
  totalChunks: number;
  uploadedChunks: number;
  progress: string;
  createdAt: string;
  updatedAt: string;
}

interface FileListItem {
  name: string;
  size: number;
  sizeMB: string;
  modifiedTime: string;
}

interface HomeSections {
  fileUpload: string[];
  streamUpload: string[];
  chunkUpload: string[];
  manage: string[];
}

// 通用错误/成功响应（无需区分结构时复用）
interface ErrResp {
  success: boolean;
  error: string;
}

interface SimpleErrResp {
  error: string;
}

interface CancelResp {
  message: string;
  fileHash: string;
}

interface TasksResp {
  tasks: TaskInfo[];
  count: number;
}

interface FilesResp {
  success: boolean;
  count: number;
  files: FileListItem[];
}

interface DeleteResp {
  success: boolean;
  message: string;
  filename: string;
}

interface NotFoundResp {
  success: boolean;
  error: string;
}

interface HomeResp {
  message: string;
  sections: HomeSections;
}

interface MergeIncompleteResp {
  error: string;
  uploaded: number;
  total: number;
}

/**
 * 文件上传完整示例
 */
export class FileUploadExample {
  private server: HttpServer | null = null;
  private context?: common.UIAbilityContext;
  private uploadDir: string = '';
  private tempDir: string = '';
  private staticDir: string = '';
  private uploadTasks: Map<string, UploadTask> = new Map();
  // 过期任务清理：超过 2 小时未更新的任务视为废弃
  private readonly TASK_EXPIRE_MS = 2 * 60 * 60 * 1000;

  init(context: common.UIAbilityContext) {
    this.context = context;
    this.uploadDir = context.filesDir + '/uploads';
    this.tempDir = context.filesDir + '/temp';
    this.staticDir = context.filesDir + '/static';
  }

  public async initializeServer(): Promise<void> {
    this.server = new HttpServer();
    await this.setupDirectories();
    this.setupMiddleware();
    this.setupRoutes();
  }

  public async start(port: number): Promise<socket.NetAddress | null> {
    if (!this.server) {
      await this.initializeServer();
    }
    const info = await this.server?.startServer(port);
    if (info) {
      console.log('✅ 文件上传服务器启动成功!');
      this.printApiEndpoints(info);
      return info;
    }
    console.error('❌ 启动服务器失败');
    return null;
  }

  public async stop(): Promise<void> {
    if (this.server) {
      await this.server.stopServer();
      await this.cleanupTempFiles();
    }
  }

  // ── 初始化 ──────────────────────────────────────────────────────────────

  private async setupDirectories(): Promise<void> {
    for (const dir of [this.uploadDir, this.tempDir, this.staticDir]) {
      try {
        const exists = await fileIo.access(dir);
        if (!exists) {
          await fileIo.mkdir(dir);
        }
      } catch (_) {
      }
    }
    await this.copyStaticFile('file-upload.html');
  }

  private async copyStaticFile(fileName: string): Promise<void> {
    try {
      const uint8 = await this.context?.resourceManager.getRawFileContent(fileName);
      if (!uint8) {
        return;
      }
      const filePath = `${this.staticDir}/${fileName}`;
      const file = await fileIo.open(filePath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      await fileIo.write(file.fd, uint8.buffer as ArrayBuffer);
      await fileIo.close(file.fd);
    } catch (e) {
      console.error(`复制静态文件失败: ${fileName}`, e);
    }
  }

  private setupMiddleware(): void {
    if (!this.server) {
      return;
    }
    this.server.logger({ format: 'dev' });
    this.server.cors();
    this.server.json();
    this.server.use(FileUpload.create({
      tempFileDir: this.tempDir,
      limits: { fileSize: 100 * 1024 * 1024, files: 10 },
      createParentPath: true,
      debug: false
    }));
    this.server.serveStatic(this.staticDir);
  }

  // ── 路由 ────────────────────────────────────────────────────────────────

  private setupRoutes(): void {
    if (!this.server) {
      return;
    }
    this.setupFileUploadRoutes();
    this.setupStreamUploadRoutes();
    this.setupChunkUploadRoutes();
    this.setupManageRoutes();
    this.setupHomeRoute();
  }

  // =====================================================================
  // 一、FileUpload 中间件路由
  // =====================================================================

  private setupFileUploadRoutes(): void {
    if (!this.server) {
      return;
    }

    this.server.post('/api/upload/basic', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const files = req.files;
        const uploadedFiles: UploadFileInfo[] = [];
        for (const key of Object.keys(files)) {
          const file = files[key] as UploadedFile;
          const safeName = Utils.sanitizeFilename(file.name);
          if (!safeName) {
            const err: ErrResp = { success: false, error: 'Invalid filename' };
            res.status(400).json(err as ESObject);
            return;
          }
          const destPath = `${this.uploadDir}/${safeName}`;
          await file.mv(destPath);
          const fileInfo: UploadFileInfo = {
            fieldName: key, fileName: safeName,
            size: file.size, mimetype: file.mimetype, path: destPath
          };
          uploadedFiles.push(fileInfo);
        }
        const result: UploadResp = { success: true, message: '文件上传成功', files: uploadedFiles };
        res.json(result as ESObject);
      } catch (e) {
        const err: ErrResp = { success: false, error: (e as Error).message };
        res.status(500).json(err as ESObject);
      }
    });

    this.server.post('/api/upload/multiple', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const files = req.files;
        const uploadedFiles: UploadFileInfo[] = [];
        let totalSize = 0;
        for (const key of Object.keys(files)) {
          const file = files[key] as UploadedFile;
          const safeName = Utils.sanitizeFilename(file.name);
          if (!safeName) {
            const err: ErrResp = { success: false, error: 'Invalid filename' };
            res.status(400).json(err as ESObject);
            return;
          }
          const destPath = `${this.uploadDir}/${safeName}`;
          await file.mv(destPath);
          totalSize += file.size;
          const fileInfo: UploadFileInfo = {
            fieldName: key, fileName: safeName,
            size: file.size, sizeMB: (file.size / 1024 / 1024).toFixed(2), mimetype: file.mimetype, path: destPath
          };
          uploadedFiles.push(fileInfo);
        }
        const summary: MultiSummary = {
          fileCount: uploadedFiles.length, totalSize,
          totalSizeMB: (totalSize / 1024 / 1024).toFixed(2)
        };
        const result: UploadResp = { success: true, message: '多文件上传成功', summary, files: uploadedFiles };
        res.json(result as ESObject);
      } catch (e) {
        const err: ErrResp = { success: false, error: (e as Error).message };
        res.status(500).json(err as ESObject);
      }
    });

    this.server.post('/api/upload/safe', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const files = req.files;
        const uploadedFiles: UploadFileInfo[] = [];
        for (const key of Object.keys(files)) {
          const file = files[key] as UploadedFile;
          const safeName = Utils.sanitizeFilename(file.name);
          if (!safeName) {
            const err: ErrResp = { success: false, error: 'Invalid filename' };
            res.status(400).json(err as ESObject);
            return;
          }
          const destPath = `${this.uploadDir}/${safeName}`;
          await file.mv(destPath);
          const fileInfo: UploadFileInfo = {
            fieldName: key, originalName: file.name, safeName,
            fileName: safeName, size: file.size, mimetype: file.mimetype, path: destPath
          };
          uploadedFiles.push(fileInfo);
        }
        const result: UploadResp = { success: true, message: '安全文件名上传成功', files: uploadedFiles };
        res.json(result as ESObject);
      } catch (e) {
        const err: ErrResp = { success: false, error: (e as Error).message };
        res.status(500).json(err as ESObject);
      }
    });

    this.server.post('/api/upload/limited', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const files = req.files;
        const uploadedFiles: UploadFileInfo[] = [];
        for (const key of Object.keys(files)) {
          const file = files[key] as UploadedFile;
          const safeName = Utils.sanitizeFilename(file.name);
          if (!safeName) {
            const err: ErrResp = { success: false, error: 'Invalid filename' };
            res.status(400).json(err as ESObject);
            return;
          }
          const destPath = `${this.uploadDir}/${safeName}`;
          await file.mv(destPath);
          const fileInfo: UploadFileInfo = {
            fieldName: key, fileName: safeName,
            size: file.size, mimetype: file.mimetype, path: destPath, truncated: file.truncated
          };
          uploadedFiles.push(fileInfo);
        }
        const result: UploadResp = { success: true, message: '限制大小上传成功', files: uploadedFiles };
        res.json(result as ESObject);
      } catch (e) {
        const err: ErrResp = { success: false, error: (e as Error).message };
        res.status(500).json(err as ESObject);
      }
    });
  }

  // =====================================================================
  // 二、流式上传路由
  // =====================================================================

  private setupStreamUploadRoutes(): void {
    if (!this.server) {
      return;
    }

    this.server.stream('/api/upload/stream', async (req: HttpRequest, res: HttpResponse) => {
      const stream = req.uploadStream as UploadStream;
      const rawName = req.get('x-file-name') ?? `upload_${Date.now()}.bin`;
      // 先 decode（前端用 encodeURIComponent 编码），再去掉路径穿越字符
      let fileName: string;
      try {
        fileName = decodeURIComponent(rawName);
      } catch (_) {
        fileName = rawName;
      }
      // 只去掉路径分隔符和控制字符，保留中文等合法字符
      fileName = fileName.replace(/[/\\:*?"<>|\x00-\x1f]/g, '_').trim() || `upload_${Date.now()}.bin`;
      const destPath = `${this.uploadDir}/${fileName}`;

      let fd: number = -1;
      let bytesWritten: number = 0;
      let hasError: boolean = false;

      try {
        const file = await fileIo.open(
          destPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
        fd = file.fd;
      } catch (e) {
        const openErr: StreamErrResp = { success: false, error: '无法创建目标文件', detail: (e as Error).message };
        res.status(500).json(openErr as ESObject);
        return;
      }

      stream.on('data', async (chunk: ArrayBuffer) => {
        if (hasError) {
          return;
        }
        try {
          await fileIo.write(fd, chunk, { offset: bytesWritten, length: chunk.byteLength });
          bytesWritten += chunk.byteLength;
          if (stream.contentLength > 0) {
            const pct = (stream.progress * 100).toFixed(1);
            console.log(`[StreamUpload] ${fileName} ${pct}% (${bytesWritten}/${stream.contentLength} bytes)`);
          }
        } catch (e) {
          hasError = true;
          stream._error(e as Error);
        }
      });

      stream.on('end', async () => {
        try {
          await fileIo.close(fd);
          fd = -1;
        } catch (_) {
        }
        const stat = await fileIo.stat(destPath).catch(() => null);
        const streamResult: StreamResp = {
          success: true,
          message: '流式上传完成',
          fileName,
          size: stat?.size ?? bytesWritten
        };
        res.json(streamResult as ESObject);
      });

      stream.on('error', async (err: Error) => {
        console.error('[StreamUpload] error:', err.message);
        if (fd >= 0) {
          await fileIo.close(fd).catch(() => {
          });
          fd = -1;
        }
        await fileIo.unlink(destPath).catch(() => {
        });
        if (!res.isHeadersSent()) {
          const streamErr: ErrResp = { success: false, error: err.message };
          res.status(500).json(streamErr as ESObject);
        }
      });
    });
  }

  // =====================================================================
  // 三、分片上传路由
  // =====================================================================

  private setupChunkUploadRoutes(): void {
    if (!this.server) {
      return;
    }

    this.server.post('/api/upload/chunk/check', (req: HttpRequest, res: HttpResponse) => {
      const data = req.body as Record<string, string>;
      const fileHash = data.fileHash;
      const fileName = data.fileName;
      if (!fileHash || !fileName) {
        const err: SimpleErrResp = { error: 'fileHash and fileName are required' };
        res.status(400).json(err as ESObject);
        return;
      }
      const task = this.uploadTasks.get(fileHash);
      if (task) {
        const found: ChunkCheckResp =
          { exists: true, uploadedChunks: Array.from(task.uploadedChunks), totalChunks: task.totalChunks };
        res.json(found as ESObject);
      } else {
        const notFound: ChunkCheckResp = { exists: false, uploadedChunks: [] };
        res.json(notFound as ESObject);
      }
    });

    this.server.post('/api/upload/chunk/upload', async (req: HttpRequest, res: HttpResponse) => {
      // 懒惰清理：每次上传新分片时顺便清理过期任务
      this.evictExpiredTasks();
      try {
        const chunkFile = req.files?.['chunk'];
        const data = req.body as Record<string, string>;
        if (!chunkFile) {
          const err: SimpleErrResp = { error: 'No chunk file uploaded' };
          res.status(400).json(err as ESObject);
          return;
        }
        const info: ChunkInfo = {
          chunkIndex: parseInt(data.chunkIndex, 10),
          totalChunks: parseInt(data.totalChunks, 10),
          fileName: data.fileName,
          fileHash: data.fileHash
        };
        if (!info.fileHash || !info.fileName || isNaN(info.chunkIndex) || isNaN(info.totalChunks)
          || !/^[a-zA-Z0-9_-]+$/.test(info.fileHash) || info.chunkIndex < 0 || info.totalChunks <= 0) {
          const err: SimpleErrResp = { error: 'Invalid chunk parameters' };
          res.status(400).json(err as ESObject);
          return;
        }

        let task = this.uploadTasks.get(info.fileHash);
        if (!task) {
          const newTask: UploadTask = {
            fileHash: info.fileHash,
            fileName: info.fileName,
            totalChunks: info.totalChunks,
            uploadedChunks: new Set<number>(),
            chunkPaths: new Map<number, string>(),
            createdAt: new Date(),
            updatedAt: new Date()
          };
          this.uploadTasks.set(info.fileHash, newTask);
          task = newTask;
        }

        const chunkPath = `${this.tempDir}/${info.fileHash}_${info.chunkIndex}`;
        const file = await fileIo.open(chunkPath,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
        await fileIo.write(file.fd, chunkFile.data);
        await fileIo.close(file.fd);

        task.uploadedChunks.add(info.chunkIndex);
        task.chunkPaths.set(info.chunkIndex, chunkPath);
        task.updatedAt = new Date();

        console.log(`📦 分片上传: ${info.fileName} [${info.chunkIndex + 1}/${info.totalChunks}]`);
        const result: ChunkUploadResp = {
          message: 'Chunk uploaded',
          chunkIndex: info.chunkIndex,
          uploadedChunks: task.uploadedChunks.size,
          totalChunks: task.totalChunks,
          progress: (task.uploadedChunks.size / task.totalChunks * 100).toFixed(2)
        };
        res.json(result as ESObject);
      } catch (e) {
        const err: SimpleErrResp = { error: 'Failed to upload chunk' };
        res.status(500).json(err as ESObject);
      }
    });

    this.server.post('/api/upload/chunk/merge', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const data = req.body as Record<string, string>;
        const fileHash = data.fileHash;
        const rawFileName = data.fileName;
        if (!fileHash || !rawFileName) {
          const err: SimpleErrResp = { error: 'fileHash and fileName are required' };
          res.status(400).json(err as ESObject);
          return;
        }
        if (!/^[a-zA-Z0-9_-]+$/.test(fileHash)) {
          const err: SimpleErrResp = { error: 'Invalid fileHash' };
          res.status(400).json(err as ESObject);
          return;
        }
        const fileName = Utils.sanitizeFilename(rawFileName);
        if (!fileName) {
          const err: SimpleErrResp = { error: 'Invalid fileName' };
          res.status(400).json(err as ESObject);
          return;
        }
        const task = this.uploadTasks.get(fileHash);
        if (!task) {
          const err: SimpleErrResp = { error: 'Upload task not found' };
          res.status(404).json(err as ESObject);
          return;
        }
        if (task.uploadedChunks.size !== task.totalChunks) {
          const err: MergeIncompleteResp = {
            error: 'Not all chunks uploaded',
            uploaded: task.uploadedChunks.size, total: task.totalChunks
          };
          res.status(400).json(err as ESObject);
          return;
        }

        const finalPath = `${this.uploadDir}/${fileName}`;
        const finalFile = await fileIo.open(finalPath,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);

        let writeOffset = 0;
        for (let i = 0; i < task.totalChunks; i++) {
          const chunkPath = task.chunkPaths.get(i);
          if (chunkPath) {
            // 用 copyFile 的 offset 参数直接系统级追加，省去用户层 read→write 往返
            const chunkStat = await fileIo.stat(chunkPath);
            const chunkSize = chunkStat.size;
            const srcFile = await fileIo.open(chunkPath, fileIo.OpenMode.READ_ONLY);
            // 分批写入，避免把整个分片读进内存
            const PIPE_BUF = 512 * 1024; // 512 KB 管道缓冲
            let readOffset = 0;
            while (readOffset < chunkSize) {
              const toRead = Math.min(PIPE_BUF, chunkSize - readOffset);
              const buf = new ArrayBuffer(toRead);
              const bytesRead = await fileIo.read(srcFile.fd, buf, { offset: readOffset, length: toRead });
              await fileIo.write(finalFile.fd, buf, { offset: writeOffset, length: bytesRead });
              readOffset += bytesRead;
              writeOffset += bytesRead;
            }
            await fileIo.close(srcFile.fd);
          }
        }
        await fileIo.close(finalFile.fd);

        const stat = await fileIo.stat(finalPath);
        await this.cleanupTaskChunks(task);
        this.uploadTasks.delete(fileHash);

        console.log(`✅ 分片合并成功: ${fileName} (${stat.size} bytes)`);
        const fileInfo: MergeFileInfo = {
          name: fileName,
          size: stat.size,
          path: finalPath,
          hash: fileHash,
          uploadTime: new Date().toISOString()
        };
        const result: MergeResp = { message: 'File merged successfully', file: fileInfo };
        res.json(result as ESObject);
      } catch (e) {
        const err: SimpleErrResp = { error: 'Failed to merge file' };
        res.status(500).json(err as ESObject);
      }
    });

    this.server.delete('/api/upload/chunk/cancel/:fileHash', async (req: HttpRequest, res: HttpResponse) => {
      const fileHash = req.params['fileHash'];
      const task = this.uploadTasks.get(fileHash);
      if (!task) {
        const err: SimpleErrResp = { error: 'Upload task not found' };
        res.status(404).json(err as ESObject);
        return;
      }
      await this.cleanupTaskChunks(task);
      this.uploadTasks.delete(fileHash);
      const result: CancelResp = { message: 'Upload cancelled', fileHash };
      res.json(result as ESObject);
    });

    this.server.get('/api/upload/chunk/tasks', (_req: HttpRequest, res: HttpResponse) => {
      // 顺便清理过期任务
      this.evictExpiredTasks();
      const tasks: TaskInfo[] = Array.from(this.uploadTasks.values()).map(task => {
        const t: TaskInfo = {
          fileHash: task.fileHash,
          fileName: task.fileName,
          totalChunks: task.totalChunks,
          uploadedChunks: task.uploadedChunks.size,
          progress: (task.uploadedChunks.size / task.totalChunks * 100).toFixed(2),
          createdAt: task.createdAt.toISOString(),
          updatedAt: task.updatedAt.toISOString()
        };
        return t;
      });
      const result: TasksResp = { tasks, count: tasks.length };
      res.json(result as ESObject);
    });
  }

  // ── 通用管理路由 ─────────────────────────────────────────────────────────

  private setupManageRoutes(): void {
    if (!this.server) {
      return;
    }

    this.server.get('/api/upload/files', async (_req: HttpRequest, res: HttpResponse) => {
      try {
        const allFiles: FileListItem[] = [];
        const names = await fileIo.listFile(this.uploadDir).catch(() => [] as string[]);
        for (const n of names) {
          if (n.startsWith('.')) {
            continue;
          }
          const stat = await fileIo.stat(`${this.uploadDir}/${n}`).catch(() => null);
          const item: FileListItem = {
            name: n,
            size: stat?.size ?? 0,
            sizeMB: ((stat?.size ?? 0) / 1024 / 1024).toFixed(2),
            modifiedTime: stat ? new Date(stat.mtime).toISOString() : ''
          };
          allFiles.push(item);
        }
        const result: FilesResp = { success: true, count: allFiles.length, files: allFiles };
        res.json(result as ESObject);
      } catch (e) {
        const err: ErrResp = { success: false, error: (e as Error).message };
        res.status(500).json(err as ESObject);
      }
    });

    this.server.delete('/api/upload/files/:filename', async (req: HttpRequest, res: HttpResponse) => {
      try {
        const filename = Utils.sanitizeFilename(req.params['filename']);
        if (!filename) {
          const err: SimpleErrResp = { error: 'Invalid filename' };
          res.status(400).json(err as ESObject);
          return;
        }
        const filePath = `${this.uploadDir}/${filename}`;
        const exists = await fileIo.access(filePath).catch(() => false);
        if (exists) {
          await fileIo.unlink(filePath);
          const result: DeleteResp = { success: true, message: '文件删除成功', filename };
          res.json(result as ESObject);
          return;
        }
        const notFound: NotFoundResp = { success: false, error: '文件不存在' };
        res.status(404).json(notFound as ESObject);
      } catch (e) {
        const err: ErrResp = { success: false, error: (e as Error).message };
        res.status(500).json(err as ESObject);
      }
    });
  }

  private setupHomeRoute(): void {
    if (!this.server) {
      return;
    }
    this.server.get('/', (_req: HttpRequest, res: HttpResponse) => {
      const sections: HomeSections = {
        fileUpload: [
          'POST /api/upload/basic    - 基本上传（multipart/form-data）',
          'POST /api/upload/multiple - 多文件上传',
          'POST /api/upload/safe     - 安全文件名上传',
          'POST /api/upload/limited  - 限制大小上传',
        ],
        streamUpload: [
          'POST /api/upload/stream   - 流式上传（X-File-Name 头，适合 GB 级大文件）',
        ],
        chunkUpload: [
          'POST   /api/upload/chunk/check          - 断点续传查询',
          'POST   /api/upload/chunk/upload         - 上传单个分片',
          'POST   /api/upload/chunk/merge          - 合并分片',
          'DELETE /api/upload/chunk/cancel/:hash   - 取消上传',
          'GET    /api/upload/chunk/tasks          - 查看上传任务',
        ],
        manage: [
          'GET    /api/upload/files           - 文件列表',
          'DELETE /api/upload/files/:filename - 删除文件',
        ]
      };
      const result: HomeResp = { message: '文件上传完整示例', sections };
      res.json(result as ESObject);
    });
  }

  // ── 工具方法 ─────────────────────────────────────────────────────────────

  /** 清理超过 TASK_EXPIRE_MS 未更新的废弃分片任务，防止内存泄漏 */
  private evictExpiredTasks(): void {
    const now = Date.now();
    for (const hash of this.uploadTasks.keys()) {
      const task = this.uploadTasks.get(hash)!;
      if (now - task.updatedAt.getTime() > this.TASK_EXPIRE_MS) {
        this.cleanupTaskChunks(task).catch(() => {});
        this.uploadTasks.delete(hash);
        console.log(`[ChunkUpload] 清理过期任务: ${task.fileName} (${hash.substring(0, 8)}...)`);
      }
    }
  }

  private async cleanupTaskChunks(task: UploadTask): Promise<void> {
    for (const chunkPath of task.chunkPaths.values()) {
      try {
        const exists = await fileIo.access(chunkPath);
        if (exists) {
          await fileIo.unlink(chunkPath);
        }
      } catch (_) {
      }
    }
  }

  private async cleanupTempFiles(): Promise<void> {
    try {
      const files = await fileIo.listFile(this.tempDir);
      for (const file of files) {
        await fileIo.unlink(`${this.tempDir}/${file}`);
      }
    } catch (_) {
    }
  }

  private printApiEndpoints(info: socket.NetAddress): void {
    const base = `http://${info.address}:${info.port}`;
    console.log('\n🌐 Web 测试台:');
    console.log(`   ${base}/file-upload.html`);
    console.log('\n📋 文件上传API端点:');
    console.log('='.repeat(60));
    console.log('\n📄 FileUpload 中间件（整体缓冲，< 100MB）:');
    console.log(`   POST   ${base}/api/upload/basic`);
    console.log(`   POST   ${base}/api/upload/multiple`);
    console.log(`   POST   ${base}/api/upload/safe`);
    console.log(`   POST   ${base}/api/upload/limited`);
    
    console.log('\n🌊 流式上传（逐块写盘，GB 级大文件）:');
    console.log(`   POST   ${base}/api/upload/stream   (携带 X-File-Name 头)`);

    console.log('\n📦 分片上传（断点续传）:');
    console.log(`   POST   ${base}/api/upload/chunk/check`);
    console.log(`   POST   ${base}/api/upload/chunk/upload`);
    console.log(`   POST   ${base}/api/upload/chunk/merge`);
    console.log(`   GET    ${base}/api/upload/chunk/tasks`);

    console.log('\n📊 管理:');
    console.log(`   GET    ${base}/api/upload/files`);
    console.log(`   DELETE ${base}/api/upload/files/:filename`);
    console.log('='.repeat(60));
  }
}
