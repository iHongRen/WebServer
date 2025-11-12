/**
 * @fileName : HttpExample.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : HTTP服务器示例 - 展示WebServer的各种功能
 */

import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import {
  HttpServer,
  ErrorHandler,
  ServerInfo,
  ServerEventType,
  HttpRequest,
  HttpResponse,
} from '@cxy/webserver';


/**
 * 用户数据接口
 */
interface User {
  id: number;
  name: string;
}


/**
 * HTTP服务器示例类
 * 提供完整的RESTful API和文件上传功能演示
 */
export class HttpExample {
  public staticRoot: string = ''
  private server: HttpServer | null = null;
  private context?: common.UIAbilityContext;
  // 模拟数据存储
  private users: User[] = [];
  private nextUserId: number = 1;

  init(context: common.UIAbilityContext) {
    this.context = context;
    this.staticRoot = context.filesDir + '/static'
    this.users = [
      {
        id: 1,
        name: 'cxy',
      },
      {
        id: 2,
        name: 'ihongren',
      }
    ];
    this.nextUserId = 3;
  }

  /**
   * 设置静态文件
   */
  public async setupStaticFiles(): Promise<void> {
    // 检查并创建静态文件目录
    const access = await fileIo.access(this.staticRoot);
    if (!access) {
      await fileIo.mkdir(this.staticRoot);
    }
    // 复制静态文件到沙箱目录
    await this.copyStaticFile('index.html');
    await this.copyStaticFile('upload.html');
  }

  /**
   * 初始化服务器
   */
  public async initializeServer(): Promise<void> {
    this.server = new HttpServer();
    // 设置服务器事件处理
    this.setupEventHandling();

    // 配置中间件
    this.setupMiddleware();

    // 配置路由
    this.setupRoutes();

    // 设置全局错误处理中间件
    this.setupGlobalErrorHandler();

    // 静态文件
    await this.setupStaticFiles();
  }

  /**
   * 启动服务器
   */
  public async start(port: number): Promise<ServerInfo | null> {
    if (!this.server) {
      await this.initializeServer();
    }

    const info = await this.server?.startServer(port);
    if (info) {
      console.log('✅ HTTP服务器启动成功!');
      console.log(`🌐 访问地址: http://${info.address}:${info.port}`);
      this.printApiEndpoints(info);
      return info;
    } else {
      console.error('❌ 启动服务器失败:');
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
   * 复制静态文件到沙箱目录
   */
  private async copyStaticFile(fileName: string): Promise<void> {
    const buffer = await this.context?.resourceManager.getRawFileContent(fileName);
    const filePath = `${this.staticRoot}/${fileName}`;

    const file = await fileIo.open(filePath,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
    await fileIo.write(file.fd, buffer?.buffer);
    await fileIo.close(file.fd);
  }


  /**
   * 设置错误处理和事件监听
   */
  private setupEventHandling(): void {
    if (!this.server) {
      return;
    }

    // 监听服务器错误
    this.server.onError((error) => {
      console.error(`🚨 服务器错误 [${error.type}]: ${JSON.stringify(error.error)}`);
    });

    // 监听服务器事件
    this.server.on(ServerEventType.SERVER_STARTED, (event) => {
      console.log('✅ 服务器启动成功:', JSON.stringify(event.data));
    });

    this.server.on(ServerEventType.SERVER_STOPPED, () => {
      console.log('🛑 服务器已停止');
    });
  }

  /**
   * 配置中间件
   */
  private setupMiddleware(): void {
    if (!this.server) {
      return;
    }

    // 1. 日志中间件（最先执行）
    this.server.logger({
      format: 'dev',
      stream: (log: string) => {
        console.log(`📝 ${log}`);
      }
    });

    // 2. CORS中间件
    this.server.cors({
      origin: '*'
    });

    // 3. 请求体解析中间件
    this.server.auto();

    // 4. 静态文件服务（在API路由之前）
    this.server.serveStatic(this.staticRoot);
  }

  /**
   * 配置所有路由
   */
  private setupRoutes(): void {
    this.setupApiRoutes();
    this.setupFileRoutes();
  }


  /**
   * 配置API路由
   */
  private setupApiRoutes(): void {
    if (!this.server) {
      return;
    }

    // ==================== 用户管理API ====================

    // GET /api/users - 获取所有用户（支持分页和搜索）
    this.server.get('/api/users', (req: HttpRequest, res: HttpResponse) => {
      const page = parseInt(req.query.get('page') || '1');
      const limit = parseInt(req.query.get('limit') || '10');
      const search = req.query.get('search') || '';

      let filteredUsers = this.users;

      // 搜索功能
      if (search) {
        filteredUsers = this.users.filter(user =>
        user.name.toLowerCase().includes(search.toLowerCase())
        );
      }

      // 分页
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      const paginatedUsers = filteredUsers.slice(startIndex, endIndex);

      res.json({
        users: paginatedUsers,
        pagination: {
          page,
          limit,
          total: filteredUsers.length,
          totalPages: Math.ceil(filteredUsers.length / limit)
        } as ESObject,
        search
      });
    });

    // GET /api/users/:id - 获取单个用户
    this.server.get('/api/users/:id', (req: HttpRequest, res: HttpResponse) => {
      const userId = parseInt(req.params['id']);
      const user = this.users.find(u => u.id === userId);

      if (user) {
        res.json({ user });
      } else {
        res.status(404).json({
          error: 'User not found',
          userId
        });
      }
    });

    // POST /api/users - 创建新用户
    this.server.post('/api/users', (req, res, next) => {
      const data = req.body as Record<string, string>;

      if (!data.name) {
        res.status(400).json({
          error: 'Name is required'
        });
        return
      }

      const newUser: User = {
        id: this.nextUserId++,
        name: data.name,
      };

      this.users.push(newUser);
      console.log('👤 创建新用户:', JSON.stringify(newUser));

      res.status(201).json({
        message: 'User created successfully',
        user: newUser
      });
    });

    // PUT /api/users/:id - 更新用户
    this.server.put('/api/users/:id', (req, res, next) => {
      const userId = parseInt(req.params['id']);
      const userIndex = this.users.findIndex(u => u.id === userId);

      if (userIndex === -1) {
        res.status(404).json({
          error: 'User not found',
          userId
        });
        return
      }

      const data = req.body as Record<string, string>;
      if (data.name) {
        this.users[userIndex].name = data.name;
      }
      res.json({
        message: 'User updated successfully',
        user: this.users[userIndex]
      });
    });

    // DELETE /api/users/:id - 删除用户
    this.server.delete('/api/users/:id', (req, res, next) => {
      const userId = parseInt(req.params['id']);
      const userIndex = this.users.findIndex(u => u.id === userId);

      if (userIndex === -1) {
        res.status(404).json({
          error: 'User not found',
          userId
        });
        return
      }

      const deletedUser = this.users.splice(userIndex, 1)[0];

      res.json({
        message: 'User deleted successfully',
        user: deletedUser
      });
    });
  }

  /**
   * 配置文件相关路由
   */
  private setupFileRoutes(): void {
    if (!this.server) {
      return;
    }

    // POST /api/upload - 文件上传
    this.server.post('/api/upload', async (req: HttpRequest, res: HttpResponse, next) => {
      try {
        const uploadedFile = req.files?.['uploadFile'];

        if (!uploadedFile) {
          return res.status(400).json({
            error: 'No file uploaded',
            hint: 'Use form field name "uploadFile"'
          });
        }

        // 生成唯一文件名
        const timestamp = Date.now();
        const fileName = `${timestamp}_${uploadedFile.fileName}`;
        const filePath = `${this.context?.filesDir}/${fileName}`;

        // 保存文件
        const file = await fileIo.open(filePath,
          fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        await fileIo.write(file.fd, uploadedFile.data);
        await fileIo.close(file.fd);

        console.log(`📁 文件上传成功: ${fileName}`);

        res.json({
          message: 'File uploaded successfully',
          file: {
            originalName: uploadedFile.fileName,
            savedName: fileName,
            size: uploadedFile.data.byteLength,
            contentType: uploadedFile.contentType,
            uploadTime: new Date().toISOString(),
            path: filePath
          } as ESObject
        });
      } catch (error) {
        console.error('❌ 文件上传失败:', error);
        next(error);
      }
    });

    // GET /api/files - 获取已上传文件列表
    this.server.get('/api/files', async (req: HttpRequest, res: HttpResponse) => {
      try {
        if (this.context) {
          const files = await fileIo.listFile(this.context.filesDir);
          const fileList: Record<string, string>[] = files
            .filter(file => !file.startsWith('.'))
            .map(file => {
              const item: Record<string, string> = {
                'name': file,
                'path': `${this.context?.filesDir}/${file}`
              }
              return item
            });

          res.json({
            files: fileList,
            count: fileList.length
          });
        } else {
          res.status(500).json({ error: 'context is undefined' });
        }
      } catch (error) {
        console.error('❌ 获取文件列表失败:', error);
        res.status(500).json({ error: 'Failed to list files' });
      }
    });
  }


  /**
   * 设置全局错误处理中间件, 需放到所有路由之后注册
   */
  private setupGlobalErrorHandler(): void {
    if (!this.server) {
      return;
    }

    const errorHandler: ErrorHandler = (error, req, res, next) => {
      console.error(`🚨 [Global Error Handler] ${req.method} ${req.path}: ${error.message}`);

      if (res.isHeadersSent()) {
        return next(error);
      }

      // 根据错误类型返回不同的状态码
      let statusCode = 500;
      let errorType = 'Internal Server Error';

      if (error.message.includes('Validation')) {
        statusCode = 400;
        errorType = 'Validation Error';
      } else if (error.message.includes('timeout')) {
        statusCode = 408;
        errorType = 'Request Timeout';
      }

      res.status(statusCode).json({
        error: errorType,
        message: error.message,
        timestamp: new Date().toISOString(),
        path: req.path,
        method: req.method
      });
    };

    this.server.use(errorHandler);
  }

  /**
   * 打印API端点信息
   */
  private printApiEndpoints(info: ServerInfo): void {
    const baseUrl = `http://${info.address}:${info.port}`;

    console.log('\n📋 可用的API端点:');
    console.log('='.repeat(50));

    // 静态文件
    console.log('📄 静态文件:');
    console.log(`   GET  ${baseUrl}/                    - 首页`);
    console.log(`   GET  ${baseUrl}/upload.html         - 文件上传页面`);

    // 用户管理API
    console.log('\n👥 用户管理API:');
    console.log(`   GET    ${baseUrl}/api/users         - 获取用户列表`);
    console.log(`   GET    ${baseUrl}/api/users/:id     - 获取单个用户`);
    console.log(`   POST   ${baseUrl}/api/users         - 创建用户`);
    console.log(`   PUT    ${baseUrl}/api/users/:id     - 更新用户`);
    console.log(`   DELETE ${baseUrl}/api/users/:id     - 删除用户`);

    // 文件管理API
    console.log('\n📁 文件管理API:');
    console.log(`   POST   ${baseUrl}/api/upload        - 上传文件`);
    console.log(`   GET    ${baseUrl}/api/files         - 获取文件列表`);

    console.log('='.repeat(50));
  }
}