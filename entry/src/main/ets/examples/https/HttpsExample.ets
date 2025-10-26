/**
 * @fileName : HttpsExample.ets
 * @author : @cxy
 * @date : 2025/10/24
 * @description : HTTPS服务器使用示例
 */

import { HttpsServer, CertificateManager, HttpRequest, HttpResponse } from '@cxy/webserver';
import { socket } from '@kit.NetworkKit'

let _httpsServer: HttpsServer

/**
 * HTTPS服务器示例类
 */
export class HttpsExample {
  /**
   * 创建基本的HTTPS服务器
   */
  public static async createBasicHttpsServer(): Promise<HttpsServer> {
    // 方式1: 使用自签名证书（开发环境）
    const tlsOptions = HttpsExample.createSelfSignedConfig();

    // 方式2: 从文件加载证书（生产环境）
    // const tlsOptions = await CertificateManager.loadFromFiles(
    //   '/path/to/private-key.pem',
    //   '/path/to/certificate.pem',
    //   '/path/to/ca-certificate.pem' // 可选
    // );

    // 验证证书配置
    if (!CertificateManager.validateConfig(tlsOptions)) {
      throw new Error('证书配置无效');
    }

    // 创建HTTPS服务器
    const httpsServer = new HttpsServer(tlsOptions);

    // 配置中间件
    httpsServer.logger(); // 启用日志
    httpsServer.cors(); // 启用CORS
    httpsServer.json(); // 启用JSON解析

    return httpsServer;
  }

  /**
   * 配置路由示例
   */
  public static configureRoutes(server: HttpsServer): void {
    // 根路径
    server.get('/', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        message: 'Welcome to HTTPS Server!',
        secure: true,
        timestamp: new Date().toISOString()
      });
    });

    // API路由
    server.get('/api/status', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        status: 'ok',
        protocol: 'https',
        server: 'HarmonyOS WebServer'
      });
    });

    // 带参数的路由
    server.get('/api/users/:id', (req: HttpRequest, res: HttpResponse) => {
      const userId = req.params['id'];
      res.json({
        userId: userId,
        message: `User ${userId} data over HTTPS`
      });
    });

    // POST路由
    server.post('/api/data', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        received: req.body,
        secure: true,
        method: req.method
      });
    });

    // 静态文件服务（HTTPS）
    server.serveStatic('/static');
  }

  /**
   * 启动完整的HTTPS服务器示例
   */
  public static async startCompleteExample(): Promise<void> {
    try {
      // 创建服务器
      _httpsServer = await HttpsExample.createBasicHttpsServer();

      // 配置路由
      HttpsExample.configureRoutes(_httpsServer);

      // 启动服务器
      const serverInfo = await _httpsServer.startServer(8443); // 使用标准HTTPS端口

      if (serverInfo.address) {
        console.log(`✅ HTTPS服务器启动成功!`);
        console.log(`🔒 访问地址: https://${serverInfo.address}:${serverInfo.port}`);
        console.log(`📋 API端点:`);
        console.log(`   - GET  https://${serverInfo.address}:${serverInfo.port}/`);
        console.log(`   - GET  https://${serverInfo.address}:${serverInfo.port}/api/status`);
        console.log(`   - GET  https://${serverInfo.address}:${serverInfo.port}/api/users/:id`);
        console.log(`   - POST https://${serverInfo.address}:${serverInfo.port}/api/data`);
      } else {
        console.error('❌ HTTPS服务器启动失败');
      }
    } catch (error) {
      console.error('启动HTTPS服务器时出错:', error);
    }
  }

  /**
   * 创建生产环境HTTPS服务器配置
   */
  public static async createProductionServer(
    keyPath: string,
    certPath: string,
    caPath?: string
  ): Promise<HttpsServer> {
    // 从文件加载证书
    const tlsOptions = await CertificateManager.loadFromFiles(keyPath, certPath, caPath);

    // 验证配置
    if (!CertificateManager.validateConfig(tlsOptions)) {
      throw new Error('证书配置验证无效');
    }

    const httpsServer = new HttpsServer(tlsOptions);
    return httpsServer;
  }

  /**
   * 创建自签名证书配置（用于开发环境）
   * @returns 开发环境TLS配置
   */
  public static createSelfSignedConfig(): socket.TLSSecureOptions {
    // 注意：这里只是示例，实际使用时需要真实的证书
    const selfSignedKey = `-----BEGIN PRIVATE KEY-----
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
KT1YWCiHsxFPdvoh4coHzt0wHybS
-----END PRIVATE KEY-----`;

    const selfSignedCert = `-----BEGIN CERTIFICATE-----
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
o7ikOjHK/SM=
-----END CERTIFICATE-----`;

    return {
      key: selfSignedKey,
      cert: selfSignedCert,
      protocols: [socket.Protocol.TLSv12, socket.Protocol.TLSv13]
    };
  }
}