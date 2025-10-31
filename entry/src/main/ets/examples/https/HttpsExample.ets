/**
 * @fileName : HttpsExample.ets
 * @author : @cxy
 * @date : 2025/10/24
 * @description : HTTPS服务器使用示例
 */

import { TLSServer, CertManager, HttpRequest, HttpResponse } from '@cxy/webserver';
import { socket } from '@kit.NetworkKit'


/**
 * HTTPS服务器示例类
 */
export class HttpsExample {
  /**
   * 创建基本的HTTPS服务器
   */
  public static async createBasicHttpsServer(): Promise<TLSServer> {
    // 方式1: 使用自签名证书（开发环境）
    const tlsOptions = HttpsExample.createSelfSignedConfig();

    // 方式2: 从文件加载证书（生产环境）
    // const tlsOptions = await CertificateManager.loadFromFiles(
    //   '/server.key',
    //   '/server.crt',
    //   // '/path/to/ca-certificate.pem' // 可选
    // );

    // 验证证书配置
    if (!CertManager.validateConfig(tlsOptions)) {
      throw new Error('证书配置无效');
    }

    // 创建HTTPS服务器
    const httpsServer = new TLSServer(tlsOptions);

    // 配置中间件
    httpsServer.logger(); // 启用日志
    httpsServer.cors(); // 启用CORS
    httpsServer.json(); // 启用JSON解析

    return httpsServer;
  }

  /**
   * 配置路由示例
   */
  public static configureRoutes(server: TLSServer): void {
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
      const httpsServer = await HttpsExample.createBasicHttpsServer();

      // 配置路由
      HttpsExample.configureRoutes(httpsServer);

      // 启动服务器
      const serverInfo = await httpsServer.startServer(8443); // 使用标准HTTPS端口

      if (serverInfo.address) {
        console.log(`✅ HTTPS服务器启动成功!`);
        console.log(`🔒 访问地址: https://${serverInfo.address}:${serverInfo.port}`);
        console.log(`📋 API端点:`);
        console.log(`   - GET  https://${serverInfo.address}:${serverInfo.port}/`);
        console.log(`   - GET  https://${serverInfo.address}:${serverInfo.port}/api/status`);
        console.log(`   - GET  https://${serverInfo.address}:${serverInfo.port}/api/users/:id`);
        console.log(`   - POST https://${serverInfo.address}:${serverInfo.port}/api/data`);
        console.log('🔧 测试命令:');
        console.log(`   curl -k https://${serverInfo.address}:${serverInfo.port}/`);
        console.log(`   curl --cacert ca-cert.pem https://${serverInfo.address}:${serverInfo.port}/`);
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
  ): Promise<TLSServer> {
    // 从文件加载证书
    const tlsOptions = await CertManager.loadFromFiles(keyPath, certPath, caPath);

    // 验证配置
    if (!CertManager.validateConfig(tlsOptions)) {
      throw new Error('证书配置验证无效');
    }

    const httpsServer = new TLSServer(tlsOptions);
    return httpsServer;
  }

  /**
   * 创建自签名证书配置（用于开发环境）
   * @returns 开发环境TLS配置
   */
  public static createSelfSignedConfig(): socket.TLSSecureOptions {
    // 注意：这里只是示例，实际使用时需要真实的证书
    const selfSignedKey = `-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQD1SNuNyYfiYeh0
Is0qK1Nhk2g5NPmPRiddkSVsqHUAWa/yRUgFFGup+oDytfHEGL/8AYZpa84Z3+B/
xrFAdxk/c2VazSw8pXzKC7d7aCcPyKKB8jj993Sj8Hphhl0fEgFwUX79lD1P58qn
985G7UHpyNXp5bXehDsHnrILKYKDcqXmpJiSGf1VEEm4eWRI1oKEAiH4nBW6Fz4+
hUVveik0uQYEpAWYtHdxZ9Z0avDxKJLuw5TunSSfkSQJa6aFdURjeOuaO7AfhbLu
HfusZTPnTa65RaXol4b9/OutJbL6bIDirIVYcobhllUrSaksb1To4b9m0tXSUggK
wWOmWJsNAgMBAAECggEANzL0udVTH6aR9eTJEAbdBlXyfAFIci5C+KML7YaBghks
59Qgj4gXbJLDxxsb89nwBonfUkUhBiCkOI0h4ZSL2YQiGIuYu3MwgJWfboWzWLF5
pM26dqjkFmqtV9oxhab7LOgiMHXWUG+k4yT4xmxpS2/XeAIqag+O6zmS7sEiLmtD
Tu4AL5gRwtHv5Baj5KYWKrTPWB/LLxV1mFmiLIG785UbbIS+ECOVSez9PE/wElRo
N4MPE6lTFSqpTVgtjW7JxHi7z0T+msMjTEDep78i7A/W1717hCGoSdKrUosslYWp
j6BsS2bRntkonceQ3tVthnno+qSXq9SDAByfI0JM3wKBgQD+haewzUgZWm0JqIFQ
myT6EZ8IVhOZv8Rs+v1SxgUrr//KJvGKtvtImn4I2muq8HIQNCL3Uzmg1iKPwz7i
FFk3a/zc18+6N8sSKPLMtV4uAD7+l1CDvKeinDXmjA/P9TjkJUe031LlvwowgvnI
kGjLiLDB/it6YIHfak9OwYgEHwKBgQD2tXiclRK3IyobciTF9FKC8HlMvLKN0tu5
IZfAbSP9yDEhzR4hizFVjkIA42iVqUqP9PzldJHoXb2VUvw2AuZOyFmJeDrJ1Fy/
c6mnOcnryNMMcrwQy2qlqz6e5/PjuEtHLcAeARxHbW6wE1hYZ8YQXAtDgccbj5iD
SuMuFzAbUwKBgQCgA4MjgkubtN/sPIXgGUmr9bwXz5XPCWMCaOEuUtQZXTLg8o7U
eKmOQaKPClK6SyRKz5xUBXyrgzSDUWqNU+GrGDcG2J7+IemHZzsOO9AT94+jG5pA
2DBD6RVx9ghS44Z62H02V1iUnABZ8136G9/mZe9KZvMKovXDceCeUMmkXQKBgFo5
xAKAAng3xA6FkC1VTVfV2obV+/ciRnlOb9FQGPmXXWCfQ4XBAinn/PuWL4mMgFhl
oJfKKhJxNgSGdPbL2K63VwePkPB/WewqwMEHwXEZ4RWMYHtD6ZztI9m5uthtbhp6
AOj4Pv9gZjq+2HB8g1M4VmY58DeELKLXoH4avN1BAoGBAPKpkHgrDuo7+3OVKaOC
B6Yhi4u97lCgIeoPPs49FMFmRl+kWciXo1qwAeM/tDv+6hEKYGqZwQu/pywF9+F1
q82MQ4Om4gzCG8Y8nDH4S/Vr3oGJ+uy4wOmH7zi+cRfnT5SXbsEB8YbVOYlD5WvX
M7+uEh55w4DVQ1rDaW3cbRbl
-----END PRIVATE KEY-----`;

    const selfSignedCert = `-----BEGIN CERTIFICATE-----
MIIDuzCCAqOgAwIBAgIUFC0qV1REoPIwCIhn/kbn1DcRgiYwDQYJKoZIhvcNAQEL
BQAwXDELMAkGA1UEBhMCQ04xDDAKBgNVBAgMA0RldjEMMAoGA1UEBwwDRGV2MQww
CgYDVQQKDANEZXYxDDAKBgNVBAsMA0RldjEVMBMGA1UEAwwMMTkyLjE2OC4yLjM4
MB4XDTI1MTAyOTAxMzkwMVoXDTI2MTAyOTAxMzkwMVowXDELMAkGA1UEBhMCQ04x
DDAKBgNVBAgMA0RldjEMMAoGA1UEBwwDRGV2MQwwCgYDVQQKDANEZXYxDDAKBgNV
BAsMA0RldjEVMBMGA1UEAwwMMTkyLjE2OC4yLjM4MIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEA9UjbjcmH4mHodCLNKitTYZNoOTT5j0YnXZElbKh1AFmv
8kVIBRRrqfqA8rXxxBi//AGGaWvOGd/gf8axQHcZP3NlWs0sPKV8ygu3e2gnD8ii
gfI4/fd0o/B6YYZdHxIBcFF+/ZQ9T+fKp/fORu1B6cjV6eW13oQ7B56yCymCg3Kl
5qSYkhn9VRBJuHlkSNaChAIh+JwVuhc+PoVFb3opNLkGBKQFmLR3cWfWdGrw8SiS
7sOU7p0kn5EkCWumhXVEY3jrmjuwH4Wy7h37rGUz502uuUWl6JeG/fzrrSWy+myA
4qyFWHKG4ZZVK0mpLG9U6OG/ZtLV0lIICsFjplibDQIDAQABo3UwczAdBgNVHQ4E
FgQURWXGyfGAKJO0Ze5OBAwo/FIXHywwHwYDVR0jBBgwFoAURWXGyfGAKJO0Ze5O
BAwo/FIXHywwDwYDVR0TAQH/BAUwAwEB/zAgBgNVHREEGTAXhwTAqAImhwR/AAAB
gglsb2NhbGhvc3QwDQYJKoZIhvcNAQELBQADggEBAKv49lbte8ZeY3gUKvO6jMwQ
CSzfIVM9efnibT+/QybUuQQDskK+QGUc/3wNH0XHXHaKeKzfmty+wcPmJPSwUYoc
JByx7pvHNoaQNybOA/HtbaceVpcsfvNc4DSYURupuxQjYpOP1Bj4TwjaPJb8ZVLD
y054YCrhDQhUbIDG2oP6Xzf3i46f9sJ/mGh79P/zJ35C471+wozXgLUbXmlZg9T8
Rel9JJ2Sg7NDobGhHKKAl9o8K1lDbtb+VhdTXZW49pM4G/jAwyCx13jfA+76h4ja
8AV+ZyxrDyTTxUKx13W+Kv8nibE+w1TAX8Nxb1sRkKgTnzv8TG+zATUrJoZuXZQ=
-----END CERTIFICATE-----`;


    const ca = `-----BEGIN CERTIFICATE-----
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
-----END CERTIFICATE-----`

    return {
      key: selfSignedKey,
      cert: selfSignedCert,
      // ca: ca
    };
  }
}