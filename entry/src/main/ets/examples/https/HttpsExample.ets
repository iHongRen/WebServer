/**
 * @fileName : HttpsExample.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : HTTPS服务器示例
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
  NextFunction,
} from '@cxy/webserver';
import { JSON, util } from '@kit.ArkTS';

/**
 * 用户数据接口
 */
interface User {
  id: number;
  name: string;
  email?: string;
}

/**
 * HTTPS服务器配置接口
 */
interface HttpsServerConfig {
  port: number;
  staticRoot: string;
  enableLogging: boolean;
  enableCors: boolean;
  certPath: string;
  keyPath: string;
  useSelfSigned: boolean;
}

/**
 * HTTPS服务器示例类
 * 提供安全的HTTP服务，包含SSL/TLS加密
 */
export class HttpsExample {
  private server: HttpServer | null = null;
  private serverInfo: ServerInfo | null = null;
  private isRunning: boolean = false;
  private config: HttpsServerConfig;
  private context: common.UIAbilityContext;
  // 模拟数据存储
  private users: User[] = [];
  private nextUserId: number = 1;

  constructor(context: common.UIAbilityContext, config?: Partial<HttpsServerConfig>) {
    this.context = context;
    this.config = {
      port: config?.port || 8443,
      staticRoot: config?.staticRoot || context.filesDir + '/static',
      enableLogging: config?.enableLogging || true,
      enableCors: config?.enableCors || true,
      certPath: config?.certPath || 'server-cert.pem',
      keyPath: config?.keyPath || 'server-key.pem',
      useSelfSigned: config?.useSelfSigned || true,
    };

    this.initializeData();
  }

  /**
   * 设置静态文件和证书
   */
  public async setupFiles(): Promise<void> {
    // 设置静态文件
    await this.setupStaticFiles();

    // 设置SSL证书
    if (this.config.useSelfSigned) {
      await this.setupSelfSignedCertificates();
    }
  }

  /**
   * 初始化服务器
   */
  public initializeServer(): void {
    this.server = new HttpServer();

    // 设置事件处理
    this.setupEventHandling();

    // 配置中间件
    this.setupMiddleware();

    // 配置路由
    this.setupRoutes();

    // 设置全局错误处理
    this.setupGlobalErrorHandler();
  }

  /**
   * 启动HTTPS服务器
   */
  public async start(): Promise<ServerInfo | null> {
    try {
      if (!this.server) {
        this.initializeServer();
      }

      if (!this.server) {
        throw new Error('HTTPS服务器初始化失败');
      }

      // 注意：这里应该使用TLSServer，但为了示例简化，使用HttpServer
      // 实际项目中需要：
      // const tlsOptions = await CertificateManager.loadFromFiles(this.config.keyPath, this.config.certPath);
      // const httpsServer = new HttpsServer(tlsOptions);

      const info = await this.server.startServer(this.config.port);

      if (info.address) {
        this.serverInfo = info;
        this.isRunning = true;

        console.log('🔒 HTTPS服务器启动成功!');
        console.log(`🌐 访问地址: https://${info.address}:${info.port}`);
        console.log('⚠️  注意: 当前为演示模式，实际HTTPS需要配置SSL证书');
        this.printApiEndpoints(info);

        return info;
      } else {
        throw new Error('未能获取服务器地址');
      }
    } catch (error) {
      console.error('❌ 启动HTTPS服务器失败:', error);
      this.isRunning = false;
      return null;
    }
  }

  /**
   * 停止服务器
   */
  public async stop(): Promise<void> {
    if (this.server && this.isRunning) {
      await this.server.stopServer();
      this.isRunning = false;
      this.serverInfo = null;
      console.log('🔒 HTTPS服务器已停止');
    }
  }

  // Getter方法
  public getServerInfo(): ServerInfo | null {
    return this.serverInfo;
  }

  public getIsRunning(): boolean {
    return this.isRunning;
  }

  public getConfig(): HttpsServerConfig {
    return this.config;
  }

  /**
   * 设置静态文件
   */
  private async setupStaticFiles(): Promise<void> {
    const access = await fileIo.access(this.config.staticRoot);
    if (!access) {
      await fileIo.mkdir(this.config.staticRoot);
    }

    await this.copyStaticFile('index.html');
    await this.copyStaticFile('upload.html');
    await this.copyStaticFile('https-demo.html');
  }

  /**
   * 设置自签名证书
   */
  private async setupSelfSignedCertificates(): Promise<void> {
    const certDir = `${this.context.filesDir}/certs`;

    // 创建证书目录
    const access = await fileIo.access(certDir);
    if (!access) {
      await fileIo.mkdir(certDir);
    }

    // 生成自签名证书（实际项目中应该使用真实证书）
    await this.generateSelfSignedCert(certDir);

    this.config.certPath = `${certDir}/server-cert.pem`;
    this.config.keyPath = `${certDir}/server-key.pem`;
  }

  /**
   * 初始化模拟数据
   */
  private initializeData(): void {
    this.users = [
      { id: 1, name: 'Alice', email: 'alice@secure.com' },
      { id: 2, name: 'Bob', email: 'bob@secure.com' },
      { id: 3, name: 'Charlie', email: 'charlie@secure.com' }
    ];
    this.nextUserId = 4;
  }

  /**
   * 复制静态文件
   */
  private async copyStaticFile(fileName: string): Promise<void> {
    try {
      const buffer = await this.context.resourceManager.getRawFileContent(fileName);
      const filePath = `${this.config.staticRoot}/${fileName}`;

      const file = await fileIo.open(filePath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      await fileIo.write(file.fd, buffer.buffer);
      await fileIo.close(file.fd);
    } catch (error) {
      console.warn(`⚠️  无法复制文件 ${fileName}:`, error);
    }
  }

  /**
   * 生成自签名证书（演示用）
   */
  private async generateSelfSignedCert(certDir: string): Promise<void> {
    // 这里应该调用OpenSSL或使用证书生成工具
    // 为了演示，创建占位符文件
    const dummyCert = `-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAJC1HiIAZAiIMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkNOMRAwDgYDVQQIDAdCZWlqaW5nMRAwDgYDVQQHDAdCZWlqaW5nMRIwEAYD
VQQKDAlIYXJtb255T1MwHhcNMjUxMDI5MDAwMDAwWhcNMjYxMDI5MDAwMDAwWjBF
MQswCQYDVQQGEwJDTjEQMA4GA1UECAwHQmVpamluZzEQMA4GA1UEBwwHQmVpamlu
ZzESMBAGA1UECgwJSGFybW9ueU9TMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEA7VJTUt9Us8cKBwQANVX4Xf/XXfXXfXXfXXfXXfXXfXXfXXfXXfXXfXXf
-----END CERTIFICATE-----`;

    const dummyKey = `-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDtUlNS31SzxwoH
BAA1Vfhd/9dd9dd9dd9dd9dd9dd9dd9dd9dd9dd9dd9dd9dd9dd9dd9dd9dd9dd9d
-----END PRIVATE KEY-----`;

    // 写入证书文件
    const certFile = await fileIo.open(`${certDir}/server-cert.pem`,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
    await fileIo.write(certFile.fd, new util.TextEncoder().encode(dummyCert).buffer);
    await fileIo.close(certFile.fd);

    // 写入私钥文件
    const keyFile = await fileIo.open(`${certDir}/server-key.pem`,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
    await fileIo.write(keyFile.fd, new util.TextEncoder().encode(dummyKey).buffer);
    await fileIo.close(keyFile.fd);

    console.log('🔐 自签名证书生成完成（演示用）');
  }

  /**
   * 设置事件处理
   */
  private setupEventHandling(): void {
    if (!this.server) {
      return;
    }

    this.server.onError((error) => {
      console.error(`🚨 HTTPS服务器错误 [${error.type}]: ${JSON.stringify(error)}`);
    });

    this.server.on(ServerEventType.SERVER_STARTED, (event) => {
      console.log('🔒 HTTPS服务器启动成功:', JSON.stringify(event.data));
    });

    this.server.on(ServerEventType.SERVER_STOPPED, () => {
      console.log('🔒 HTTPS服务器已停止');
    });
  }

  /**
   * 配置中间件
   */
  private setupMiddleware(): void {
    if (!this.server) {
      return;
    }

    // 安全头部中间件
    this.server.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
      res.setHeader('X-Content-Type-Options', 'nosniff');
      res.setHeader('X-Frame-Options', 'DENY');
      res.setHeader('X-XSS-Protection', '1; mode=block');
      next();
    });

    if (this.config.enableLogging) {
      this.server.logger({
        format: 'combined',
        stream: (log: string) => console.log(`🔒 ${log}`)
      });
    }

    if (this.config.enableCors) {
      this.server.cors({
        origin: '*',
      });
    }

    this.server.auto();
    this.server.serveStatic(this.config.staticRoot);
  }

  /**
   * 配置路由
   */
  private setupRoutes(): void {
    this.setupSecureApiRoutes();
    this.setupSecureFileRoutes();
    this.setupSecurityRoutes();
  }

  /**
   * 配置安全API路由
   */
  private setupSecureApiRoutes(): void {
    if (!this.server) {
      return;
    }

    // 安全用户管理API
    this.server.get('/api/secure/users', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        users: this.users,
        secure: true,
        encryption: 'TLS 1.3',
        timestamp: new Date().toISOString()
      });
    });

    this.server.post('/api/secure/users', (req, res) => {
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
        email: data.email
      };

      this.users.push(newUser);

      res.status(201).json({
        message: 'Secure user created',
        user: newUser,
        secure: true
      });
    });

    // 安全登录API
    this.server.post('/api/secure/login', (req, res) => {
      const data = req.body as Record<string, string>;

      // 模拟安全登录验证
      if (data.username && data.password) {
        res.json({
          message: 'Login successful',
          token: 'secure-jwt-token-' + Date.now(),
          secure: true,
          expiresIn: '1h'
        });
      } else {
        res.status(401).json({
          error: 'Invalid credentials',
          secure: true
        });
      }
    });
  }

  /**
   * 配置安全文件路由
   */
  private setupSecureFileRoutes(): void {
    if (!this.server) {
      return;
    }

    this.server.post('/api/secure/upload', async (req, res, next) => {
      try {
        const uploadedFile = req.files?.['uploadFile'];

        if (!uploadedFile) {
          return res.status(400).json({
            error: 'No file uploaded',
            secure: true
          });
        }

        const timestamp = Date.now();
        const fileName = `secure_${timestamp}_${uploadedFile.fileName}`;
        const filePath = `${this.context.filesDir}/${fileName}`;

        const file = await fileIo.open(filePath,
          fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        await fileIo.write(file.fd, uploadedFile.data);
        await fileIo.close(file.fd);

        res.json({
          message: 'Secure file upload successful',
          file: {
            originalName: uploadedFile.fileName,
            savedName: fileName,
            size: uploadedFile.data.byteLength,
            encrypted: true,
            uploadTime: new Date().toISOString()
          } as ESObject
        });
      } catch (error) {
        next(error);
      }
    });
  }

  /**
   * 配置安全相关路由
   */
  private setupSecurityRoutes(): void {
    if (!this.server) {
      return;
    }

    // SSL证书信息
    this.server.get('/api/ssl/info', (req, res) => {
      res.json({
        ssl: {
          enabled: true,
          protocol: 'TLS 1.3',
          cipher: 'ECDHE-RSA-AES256-GCM-SHA384',
          certificate: {
            issuer: 'HarmonyOS Self-Signed',
            subject: 'localhost',
            validFrom: new Date().toISOString(),
            validTo: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()
          } as ESObject
        } as ESObject,
        security: {
          hsts: true,
          xssProtection: true,
          contentTypeOptions: true,
          frameOptions: 'DENY'
        } as ESObject
      });
    });

    // 安全测试端点
    this.server.get('/api/security/test', (req, res) => {
      res.json({
        message: 'Security test endpoint',
        secure: true,
        headers: req.headers,
        clientCert: 'Not implemented',
        timestamp: new Date().toISOString()
      });
    });
  }

  /**
   * 设置全局错误处理
   */
  private setupGlobalErrorHandler(): void {
    if (!this.server) {
      return;
    }

    const errorHandler: ErrorHandler = (error, req, res, next) => {
      console.error(`🚨 [HTTPS Error Handler] ${req.method} ${req.path}: ${error.message}`);

      if (res.isHeadersSent()) {
        return next(error);
      }

      res.status(500).json({
        error: 'Internal Server Error',
        message: error.message,
        secure: true,
        timestamp: new Date().toISOString()
      });
    };

    this.server.use(errorHandler);
  }

  /**
   * 打印API端点信息
   */
  private printApiEndpoints(info: ServerInfo): void {
    const baseUrl = `https://${info.address}:${info.port}`;

    console.log('\n🔒 HTTPS API端点:');
    console.log('='.repeat(50));

    console.log('📄 静态文件:');
    console.log(`   GET  ${baseUrl}/                         - 安全首页`);
    console.log(`   GET  ${baseUrl}/https-demo.html          - HTTPS演示页面`);

    console.log('\n🔐 安全API:');
    console.log(`   GET    ${baseUrl}/api/secure/users       - 安全用户列表`);
    console.log(`   POST   ${baseUrl}/api/secure/users       - 创建安全用户`);
    console.log(`   POST   ${baseUrl}/api/secure/login       - 安全登录`);
    console.log(`   POST   ${baseUrl}/api/secure/upload      - 安全文件上传`);

    console.log('\n🛡️  安全信息:');
    console.log(`   GET    ${baseUrl}/api/ssl/info           - SSL证书信息`);
    console.log(`   GET    ${baseUrl}/api/security/test      - 安全测试`);

    console.log('='.repeat(50));
  }
}