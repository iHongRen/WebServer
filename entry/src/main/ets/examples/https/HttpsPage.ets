/**
 * @fileName : HttpsPage.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : HTTPS服务器示例页面
 */

import { common } from '@kit.AbilityKit';
import { HttpsExample } from './HttpsExample';

@Builder
function httpsBuilder() {
  HttpsPage()
}

@Entry
@Component
struct HttpsPage {
  @State title: string = 'HTTPS服务器示例页面'
  @State serverStatus: string = '未启动';
  @State serverInfo: string = '';
  @State port: number = 8443;
  @State isRunning: boolean = false;
  private httpsExample: HttpsExample = new HttpsExample();

  aboutToAppear(): void {
    this.httpsExample.init(getContext(this) as common.UIAbilityContext);
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          // 服务器控制区域
          Column({ space: 12 }) {
            Text('服务器控制')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Row({ space: 12 }) {
              Text('端口:')
                .fontSize(16)
              TextInput({ text: this.port.toString() })
                .width(100)
                .type(InputType.Number)
                .enabled(!this.isRunning)
                .onChange((value: string) => {
                  const newPort = parseInt(value);
                  if (!isNaN(newPort) && newPort > 0 && newPort < 65536) {
                    this.port = newPort;
                  }
                })
            }

            Row({ space: 12 }) {
              Button(this.isRunning ? '停止服务器' : '启动服务器')
                .type(ButtonType.Capsule)
                .width(120)
                .borderRadius(8)
                .backgroundColor(this.isRunning ? Color.Red : Color.Blue)
                .onClick(async () => {
                  if (this.isRunning) {
                    await this.stopServer();
                  } else {
                    await this.startServer();
                  }
                })

              Text(this.serverStatus)
                .fontSize(14)
                .fontColor(this.isRunning ? '#4CAF50' : '#999')
            }

            if (this.serverInfo) {
              Text(this.serverInfo)
                .fontSize(12)
                .fontColor('#666')
                .padding(12)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .width('100%')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // 功能说明
          Column({ space: 12 }) {
            Text('功能说明')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text('本示例展示WebServer框架的HTTPS/TLS安全连接功能，支持SSL/TLS加密通信。')
              .fontSize(14)
              .fontColor('#666')

            Divider()

            Text('支持的安全功能：')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Column({ space: 8 }) {
              this.featureItem('🔒', 'TLS加密', 'SSL/TLS安全连接')
              this.featureItem('📜', '证书管理', '自签名和CA证书支持')
              this.featureItem('🔐', '安全API', '加密的数据传输')
              this.featureItem('🛡️', '身份验证', '客户端证书验证')
              this.featureItem('📋', '证书信息', '查看SSL证书详情')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // API端点
          Column({ space: 12 }) {
            Text('API端点')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text('SSL/TLS加密特性:')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Column({ space: 8 }) {
              this.apiItem('GET', '/', 'HTTPS安全首页')
              this.apiItem('GET', '/api/ssl/info', 'SSL证书和加密信息')
              this.apiItem('GET', '/api/security/headers', '安全头部展示')
            }

            Divider()

            Text('加密数据传输:')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Column({ space: 8 }) {
              this.apiItem('GET', '/api/secure/token', '安全Token获取')
              this.apiItem('GET', '/api/secure/verify/:token', 'Token安全验证')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // 测试说明
          Column({ space: 12 }) {
            Text('测试方法')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text('使用curl命令测试HTTPS服务器：')
              .fontSize(14)
              .fontColor('#666')

            Text('# 忽略证书验证（自签名证书）\ncurl -k https://IP:8443/api/ssl/info')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('# 获取安全Token（需要认证）\ncurl -k -H "Authorization: Basic ZGVtbzpzZWN1cmU=" \\\n  https://IP:8443/api/secure/token')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('详细测试脚本请查看: test-https-api.sh')
              .fontSize(12)
              .fontColor('#999')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // 证书说明
          Column({ space: 12 }) {
            Text('证书生成')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text('使用提供的脚本生成SSL证书：')
              .fontSize(14)
              .fontColor('#666')

            Text('# 生成开发证书\n./scripts/generate-dev-cert.sh')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('详细说明请查看: scripts/HTTPS证书生成脚本使用指南.md')
              .fontSize(12)
              .fontColor('#999')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
        }
        .padding(16)
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .align(Alignment.TopStart)
    }
    .title(this.title)
    .onReady((ctx) => {
      if (ctx.pathInfo.param) {
        this.title = ctx.pathInfo.param as string;
      }
    })
  }

  @Builder
  featureItem(icon: string, title: string, description: string) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(24)

      Column({ space: 4 }) {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        Text(description)
          .fontSize(12)
          .fontColor('#999')
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F9F9F9')
    .borderRadius(8)
  }

  @Builder
  apiItem(method: string, path: string, description: string) {
    Row({ space: 12 }) {
      Text(method)
        .fontSize(12)
        .fontColor(Color.White)
        .padding({
          left: 8,
          right: 8,
          top: 4,
          bottom: 4
        })
        .backgroundColor(method === 'GET' ? '#4CAF50' : '#2196F3')
        .borderRadius(4)

      Column({ space: 4 }) {
        Text(path)
          .fontSize(13)
          .fontFamily('monospace')
          .fontWeight(FontWeight.Medium)
        Text(description)
          .fontSize(11)
          .fontColor('#999')
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#F9F9F9')
    .borderRadius(8)
  }

  private async startServer() {
    try {
      this.serverStatus = '启动中...';
      const info = await this.httpsExample.start(this.port);
      if (info) {
        this.isRunning = true;
        this.serverStatus = '运行中';
        this.serverInfo = `服务器地址: https://${info.address}:${info.port}`;
      } else {
        this.serverStatus = '启动失败';
        this.serverInfo = '无法启动服务器，请检查端口和证书配置';
      }
    } catch (error) {
      this.serverStatus = '启动失败';
      this.serverInfo = `错误: ${error.message}`;
    }
  }

  private async stopServer() {
    try {
      await this.httpsExample.stop();
      this.isRunning = false;
      this.serverStatus = '已停止';
      this.serverInfo = '';
    } catch (error) {
      this.serverInfo = `停止失败: ${error.message}`;
    }
  }
}
