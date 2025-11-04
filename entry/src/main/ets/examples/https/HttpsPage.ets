import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { ServerInfo } from '@cxy/webserver';
import { HttpsExample } from './HttpsExample';

@Builder
function httpsBuilder() {
  HttpsPage()
}

@Component
struct HttpsPage {
  @State title: string = 'HTTPS服务器示例'
  @State httpsExample: HttpsExample | null = null;
  @State serverInfo: ServerInfo | null = null;
  @State port: number = 8443;
  @State errorMessage: string = '';
  @State successMessage: string = '';
  @State useSelfSigned: boolean = true;

  aboutToAppear() {
    setTimeout(() => {
      this.startServer();
    }, 0);
  }

  aboutToDisappear() {
    this.stopServer();
  }

  /**
   * 初始化HTTPS示例
   */
  async initializeExample() {
    this.errorMessage = '';
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.httpsExample = new HttpsExample(context, {
      port: this.port,
      enableLogging: true,
      enableCors: true,
      useSelfSigned: this.useSelfSigned
    });
    await this.httpsExample.setupFiles();
  }

  /**
   * 启动服务器
   */
  async startServer() {
    if (!this.httpsExample) {
      await this.initializeExample();
    }

    if (!this.httpsExample) {
      this.errorMessage = 'HTTPS服务器初始化失败';
      return;
    }

    try {
      this.errorMessage = '';

      const info = await this.httpsExample.start();

      if (info) {
        this.serverInfo = info;
        this.successMessage = `🔒 HTTPS服务器运行中`;
      } else {
        this.errorMessage = 'HTTPS服务器启动失败，未获取到地址';
      }
    } catch (error) {
      const businessError = error as BusinessError;
      this.errorMessage = `启动失败: ${businessError.message}`;
    }
  }

  /**
   * 停止服务器
   */
  async stopServer() {
    if (!this.httpsExample) {
      return;
    }

    try {
      await this.httpsExample.stop();

      this.httpsExample = null;
      this.serverInfo = null;
      this.successMessage = '🔒 HTTPS服务器已停止';

    } catch (error) {
      this.errorMessage = `停止服务器失败: ${error}`;
    }
  }

  /**
   * 更新端口号
   */
  updatePort(newPort: string) {
    const portNum = parseInt(newPort);
    if (portNum > 0 && portNum <= 65535) {
      this.port = portNum;
      this.errorMessage = '';
    } else {
      this.errorMessage = '端口号必须在1-65535之间';
    }
  }

  /**
   * 清除消息
   */
  clearMessages() {
    this.errorMessage = '';
    this.successMessage = '';
  }

  build() {
    NavDestination() {
      Column() {
        // 消息显示区域
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontColor(Color.Red)
            .fontSize(14)
            .margin({ bottom: 10 })
            .padding(10)
            .backgroundColor('#ffebee')
            .borderRadius(8)
            .width('90%')
            .textAlign(TextAlign.Center)
        } else if (this.successMessage) {
          Text(this.successMessage)
            .fontColor(Color.Green)
            .fontSize(14)
            .margin({ bottom: 10 })
            .padding(10)
            .backgroundColor('#e8f5e8')
            .borderRadius(8)
            .width('90%')
            .textAlign(TextAlign.Center)
        }

        // 服务器状态区域
        if (this.serverInfo) {
          Column({ space: 15 }) {
            // 服务器信息卡片
            Column({ space: 10 }) {
              Row() {
                Text('🔒 HTTPS地址:')
                  .fontWeight(FontWeight.Medium)
                  .width(100)
                Text(`https://${this.serverInfo.address}:${this.serverInfo.port}`)
                  .fontColor(Color.Blue)
                  .fontSize(16)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)

              Row() {
                Text('SSL状态:')
                  .fontWeight(FontWeight.Medium)
                  .width(100)
                Text(this.useSelfSigned ? '自签名证书' : '正式证书')
                  .fontSize(14)
                  .fontColor(this.useSelfSigned ? Color.Orange : Color.Green)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)

              Row() {
                Text('安全等级:')
                  .fontWeight(FontWeight.Medium)
                  .width(100)
                Text('TLS 1.3 加密')
                  .fontSize(14)
                  .fontColor(Color.Green)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .padding(15)
            .backgroundColor('#f0f8ff')
            .borderRadius(10)
            .width('90%')

            // 安全特性
            Column({ space: 8 }) {
              Text('🛡️ 安全特性')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Text('✅ SSL/TLS 加密传输')
                .fontSize(12)
                .fontColor('#666')
              Text('✅ HSTS 安全头部')
                .fontSize(12)
                .fontColor('#666')
              Text('✅ XSS 防护')
                .fontSize(12)
                .fontColor('#666')
              Text('✅ 安全用户认证')
                .fontSize(12)
                .fontColor('#666')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(15)
            .backgroundColor('#f0fff0')
            .borderRadius(10)
            .width('90%')

            // 停止按钮
            Button('停止HTTPS服务器')
              .width('80%')
              .height(50)
              .backgroundColor('#d32f2f')
              .onClick(() => {
                this.clearMessages();
                this.stopServer();
              })
          }
          .width('100%')

        } else {
          // 服务器未运行状态
          Column({ space: 20 }) {
            // 配置区域
            Column({ space: 15 }) {
              Text('HTTPS服务器配置')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)

              Row() {
                Text('端口号:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                TextInput({
                  text: this.port.toString(),
                  placeholder: '请输入端口号 (1-65535)'
                })
                  .type(InputType.Number)
                  .layoutWeight(1)
                  .height(40)
                  .onChange((value) => {
                    this.updatePort(value);
                  })
              }
              .width('100%')

              Row() {
                Text('证书类型:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Row() {
                  Radio({ value: 'self', group: 'certType' })
                    .checked(this.useSelfSigned)
                    .onChange((isChecked) => {
                      if (isChecked) {
                        this.useSelfSigned = true;
                      }
                    })
                  Text('自签名')
                    .fontSize(14)
                    .margin({ left: 5, right: 15 })
                  
                  Radio({ value: 'official', group: 'certType' })
                    .checked(!this.useSelfSigned)
                    .onChange((isChecked) => {
                      if (isChecked) {
                        this.useSelfSigned = false;
                      }
                    })
                  Text('正式证书')
                    .fontSize(14)
                    .margin({ left: 5 })
                }
                .layoutWeight(1)
              }
              .width('100%')
            }
            .padding(15)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .width('90%')

            // 安全说明
            Column({ space: 8 }) {
              Text('🔒 HTTPS安全特性')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Text('🔐 端到端加密传输')
                .fontSize(14)
                .fontColor('#666')
              Text('🛡️ 防止中间人攻击')
                .fontSize(14)
                .fontColor('#666')
              Text('🔑 安全身份验证')
                .fontSize(14)
                .fontColor('#666')
              Text('📋 安全API接口')
                .fontSize(14)
                .fontColor('#666')
              Text('⚠️ 浏览器可能显示证书警告')
                .fontSize(12)
                .fontColor(Color.Orange)
            }
            .alignItems(HorizontalAlign.Start)
            .padding(15)
            .backgroundColor('#e3f2fd')
            .borderRadius(10)
            .width('90%')

            // 启动按钮
            Button('启动HTTPS服务器')
              .width('80%')
              .height(50)
              .backgroundColor('#1976d2')
              .onClick(() => {
                this.clearMessages();
                this.startServer();
              })
          }
          .width('100%')
        }
      }
      .width('100%')
      .height('100%')
      .padding(20)
      .justifyContent(FlexAlign.Start)
    }
    .title(this.title)
    .onReady((ctx) => {
      if (ctx.pathInfo.param) {
        this.title = ctx.pathInfo.param as string;
      }
    })
  }
}

export { httpsBuilder }