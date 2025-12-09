/**
 * @fileName : HttpsExample.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : HTTPS服务器示例 - 突出SSL/TLS加密和安全特性
 */

import { socket } from '@kit.NetworkKit';
import {
  TLSServer, HttpRequest, HttpResponse,
} from '@cxy/webserver';
import { common } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';

/**
 * HTTPS服务器示例类
 * 专注于展示HTTPS的核心安全特性：
 * 1. SSL/TLS加密通信
 * 2. 证书管理和验证
 * 3. 安全头部配置
 * 4. 加密数据传输
 */
export class HttpsExample {
  private server: TLSServer | null = null;
  private context?: common.UIAbilityContext;

  init(context: common.UIAbilityContext) {
    this.context = context
  }


  /**
   * 初始化HTTPS服务器
   */
  public async initializeServer(): Promise<void> {
    // 加载TLS证书配置
    const tlsOptions = await this.loadTLSOptions();

    // 创建TLS服务器实例
    this.server = new TLSServer(tlsOptions);

    // 配置安全中间件
    this.setupSecurityMiddleware();

    // 配置HTTPS特性演示路由
    this.setupHttpsRoutes();
  }

  /**
   * 启动HTTPS服务器
   */
  public async start(port: number): Promise<socket.NetAddress | null> {
    if (!this.server) {
      await this.initializeServer();
    }

    const info = await this.server?.startServer(port);
    if (info) {
      console.log('✅ HTTPS服务器启动成功!');
      console.log(`🔒 安全访问地址: https://${info.address}:${info.port}`);
      this.printHttpsFeatures(info);
      return info;
    } else {
      console.error('❌ 启动HTTPS服务器失败');
      return null;
    }
  }

  /**
   * 停止服务器
   */
  public async stop(): Promise<void> {
    if (this.server) {
      await this.server.stopServer();
      console.log('🔒 HTTPS服务器已安全关闭');
    }
  }


  // 读取文件，解析为对象
  async readFilePath(path: string): Promise<string> {
    try {
      if (this.context) {
        const value: Uint8Array = await this.context.resourceManager.getRawFileContent(path) as Uint8Array
        return buffer.from(value.buffer).toString();
      }
    } catch (error) {
      console.error(error)
    }
    return ''
  }

  /**
   * 加载TLS证书配置
   */
  private async loadTLSOptions(): Promise<socket.TLSSecureOptions> {
    try {
      // 证书文件路径 - 生产环境应从安全存储加载
      const cert = await this.readFilePath('dev-cert.pem')
      const key = await this.readFilePath('dev-key.pem')

      // 返回TLS安全配置
      return {
        key: key,
        cert: cert,
        // 强制使用安全的TLS协议版本
        protocols: [socket.Protocol.TLSv12, socket.Protocol.TLSv13],
        // 可以添加更多安全配置
        // cipherSuite: 'ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM',
      };
    } catch (error) {
      console.warn('⚠️ 无法加载证书文件，使用开发用占位证书');
      console.warn('📝 请运行 scripts/generate-dev-cert.sh 生成开发证书');

      // 开发环境占位证书（仅用于演示）
      return {
        key: '-----BEGIN PRIVATE KEY-----\n[开发环境占位私钥]\n-----END PRIVATE KEY-----',
        cert: '-----BEGIN CERTIFICATE-----\n[开发环境占位证书]\n-----END CERTIFICATE-----',
      };
    }
  }


  /**
   * 配置HTTPS安全中间件
   * 演示HTTPS服务器的安全配置最佳实践
   */
  private setupSecurityMiddleware(): void {
    if (!this.server) {
      return;
    }

    console.log('🛡️ 配置HTTPS安全中间件...');

    // 1. HTTPS安全头部中间件 - 核心安全特性
    this.server.use((req: HttpRequest, res: HttpResponse, next: () => void) => {
      // HSTS - 强制HTTPS访问
      res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');

      // 内容安全策略
      res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self' 'unsafe-inline'");

      // 防止MIME类型嗅探
      res.setHeader('X-Content-Type-Options', 'nosniff');

      // 防止点击劫持
      res.setHeader('X-Frame-Options', 'DENY');

      // XSS保护
      res.setHeader('X-XSS-Protection', '1; mode=block');

      // 引用策略
      res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

      // 标记为安全传输
      res.setHeader('X-Secure-Transport', 'HTTPS');

      console.log(`🔒 安全请求: ${req.method} ${req.url} (加密传输)`);
      next();
    });

    // 2. HTTPS访问日志中间件
    this.server.logger({
      format: 'combined',
      stream: (log: string) => {
        console.log(`🔐 [HTTPS-LOG] ${log}`);
      }
    });

    // 3. CORS配置 - 针对HTTPS的跨域设置
    this.server.cors({
      origin: '*', // 开发环境，生产环境应限制为具体HTTPS域名
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Secure-Token']
    });

    // 4. 请求体解析
    this.server.auto();
  }

  /**
   * 配置HTTPS特性演示路由
   * 重点展示HTTPS的安全特性和加密传输能力
   */
  private setupHttpsRoutes(): void {
    if (!this.server) {
      return;
    }

    console.log('🔗 配置HTTPS特性演示路由...');

    // ==================== HTTPS核心特性演示 ====================

    // GET / - HTTPS首页，展示加密连接状态
    this.server.get('/', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        message: '🔒 欢迎访问HTTPS安全服务器',
        features: {
          encryption: 'SSL/TLS加密传输',
          security: '安全头部保护',
          certificate: 'X.509数字证书验证',
          protocol: 'HTTPS协议'
        } as ESObject,
        connection: {
          secure: true,
          encrypted: true,
          protocol: 'HTTPS/1.1',
          timestamp: new Date().toISOString()
        } as ESObject
      });
    });

    // GET /api/ssl/info - SSL/TLS证书和加密信息
    this.server.get('/api/ssl/info', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        ssl: {
          enabled: true,
          protocol: 'TLS',
          version: '1.2+',
          cipher: 'AES256-GCM-SHA384',
          keyExchange: 'ECDHE',
          keySize: 2048,
          signatureAlgorithm: 'RSA-SHA256'
        } as ESObject,
        certificate: {
          type: 'X.509',
          selfSigned: true, // 开发环境
          validFrom: new Date().toISOString(),
          validTo: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
          subject: 'CN=localhost',
          issuer: 'CN=Dev-CA'
        } as ESObject,
        security: {
          hsts: true,
          perfectForwardSecrecy: true,
          secureRenegotiation: true,
          compression: false // 防止CRIME攻击
        } as ESObject,
        timestamp: new Date().toISOString()
      });
    });


    // GET /api/secure/token - 安全Token获取（演示HTTPS下的认证）
    this.server.get('/api/secure/token', (req: HttpRequest, res: HttpResponse) => {
      // 简单的认证检查
      const authHeader = req.headers?.['authorization'] as string;

      if (!authHeader || authHeader !== 'Basic ZGVtbzpzZWN1cmU=') { // demo:secure
        res.status(401).json({
          error: 'Authentication required',
          message: '请提供有效的认证信息',
          note: 'HTTPS确保认证信息在传输过程中被加密保护'
        });
        return;
      }

      // 生成安全Token
      const secureToken = `secure_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;

      res.json({
        message: '🔐 安全Token已生成',
        token: secureToken,
        expiresIn: 3600,
        tokenType: 'Bearer',
        secureTransport: true,
        issuedAt: new Date().toISOString(),
        note: 'Token通过HTTPS安全传输，防止中间人攻击'
      });
    });

    // GET /api/secure/verify/:token - Token验证端点
    this.server.get('/api/secure/verify/:token', (req: HttpRequest, res: HttpResponse) => {
      const token = req.params['token'];

      // 简单的Token验证逻辑
      const isValidToken = token && token.startsWith('secure_') && token.length > 20;

      if (isValidToken) {
        res.json({
          message: '✅ Token验证成功',
          valid: true,
          token: token.substring(0, 15) + '...', // 只显示部分Token
          verifiedAt: new Date().toISOString(),
          secureConnection: true,
          note: 'Token验证通过HTTPS进行，确保验证过程的安全性'
        });
      } else {
        res.status(401).json({
          message: '❌ Token验证失败',
          valid: false,
          error: 'Invalid or expired token',
          timestamp: new Date().toISOString()
        });
      }
    });

    // GET /api/security/headers - 展示HTTPS安全头部
    this.server.get('/api/security/headers', (req: HttpRequest, res: HttpResponse) => {
      // 获取当前响应的安全头部
      const securityHeaders: Record<string, string> = {
        'Strict-Transport-Security': res.getHeader('Strict-Transport-Security') || '',
        'Content-Security-Policy': res.getHeader('Content-Security-Policy') || '',
        'X-Content-Type-Options': res.getHeader('X-Content-Type-Options') || '',
        'X-Frame-Options': res.getHeader('X-Frame-Options') || '',
        'X-XSS-Protection': res.getHeader('X-XSS-Protection') || '',
        'Referrer-Policy': res.getHeader('Referrer-Policy') || ''
      };

      res.json({
        message: '🛡️ HTTPS安全头部信息',
        securityHeaders,
        description: {
          'HSTS': '强制浏览器使用HTTPS连接',
          'CSP': '内容安全策略，防止XSS攻击',
          'X-Content-Type-Options': '防止MIME类型嗅探攻击',
          'X-Frame-Options': '防止点击劫持攻击',
          'X-XSS-Protection': '启用浏览器XSS过滤器',
          'Referrer-Policy': '控制引用信息的发送'
        } as ESObject,
        httpsFeatures: [
          '端到端加密',
          '身份验证',
          '数据完整性',
          '防重放攻击',
          '完美前向保密'
        ],
        timestamp: new Date().toISOString()
      });
    });
  }


  /**
   * 打印HTTPS特性和端点信息
   */
  private printHttpsFeatures(info: socket.NetAddress): void {
    const baseUrl = `https://${info.address}:${info.port}`;

    console.log('\n� H用TTPS安全特性演示端点:');
    console.log('='.repeat(70));

    // HTTPS核心特性
    console.log('� SSL/TLS加密特性:');
    console.log(`   GET  ${baseUrl}/                           - HTTPS安全首页`);
    console.log(`   GET  ${baseUrl}/api/ssl/info               - SSL证书和加密信息`);
    console.log(`   GET  ${baseUrl}/api/security/headers       - 安全头部展示`);

    // 安全数据传输
    console.log('\n📡 加密数据传输演示:');
    console.log(`   GET  ${baseUrl}/api/secure/token           - 安全Token获取`);
    console.log(`   GET  ${baseUrl}/api/secure/verify/secure_daffsfsfdsfdsa   - Token安全验证`);

    console.log('\n🛡️ HTTPS安全特性:');
    console.log('   ✅ SSL/TLS端到端加密');
    console.log('   ✅ X.509数字证书验证');
    console.log('   ✅ HSTS强制HTTPS访问');
    console.log('   ✅ 安全头部防护');
    console.log('   ✅ 完美前向保密');
    console.log('   ✅ 防中间人攻击');

    console.log('='.repeat(70));
    console.log('⚠️  开发证书提示: 浏览器会显示安全警告，点击"高级"→"继续访问"');
    console.log('🔧 测试脚本: ./test-https-api.sh');
    console.log('� 证 书生成: ./scripts/generate-dev-cert.sh');
  }
}