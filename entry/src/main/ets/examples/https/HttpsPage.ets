/**
 * @fileName : HttpsPage.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : HTTPS服务器示例页面
 */

import { common } from '@kit.AbilityKit';
import { HttpsExample } from './HttpsExample';
import { socket } from '@kit.NetworkKit';

@Builder
function httpsBuilder() {
  HttpsPage()
}

@Component
struct HttpsPage {
  @State title: string = 'HTTPS服务器示例'
  @State httpsExample: HttpsExample = new HttpsExample();
  @State serverInfo: socket.NetAddress | null = null;
  @State port: number = 8443;
  @State errorMessage: string = '';
  @State successMessage: string = '';

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.httpsExample.init(context);
    this.startServer();
  }

  aboutToDisappear() {
    this.stopServer();
  }

  /**
   * 启动服务器
   */
  async startServer() {
    this.errorMessage = '';
    this.successMessage = '';

    const info = await this.httpsExample.start(this.port);
    if (info) {
      this.serverInfo = info;
      this.successMessage = `🟢服务器运行中`;
    } else {
      this.errorMessage = '🛑 服务器启动失败';
    }
  }

  /**
   * 停止服务器
   */
  async stopServer() {
    this.errorMessage = '';
    this.successMessage = '';
    await this.httpsExample.stop();
    this.serverInfo = null;
    this.successMessage = 'HTTPS服务器已停止';
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        // 消息显示区域
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontColor(Color.Red)
            .fontSize(14)
            .padding(10)
            .backgroundColor('#ffebee')
            .borderRadius(8)
            .width('90%')
            .textAlign(TextAlign.Center)
        } else if (this.successMessage) {
          Text(this.successMessage)
            .fontColor(Color.Green)
            .fontSize(14)
            .padding(10)
            .backgroundColor('#e8f5e8')
            .borderRadius(8)
            .width('90%')
            .textAlign(TextAlign.Center)
        }

        // 服务器运行状态
        if (this.serverInfo) {
          Column({ space: 15 }) {
            // 服务器信息卡片
            Column({ space: 10 }) {
              Row() {
                Text('HTTPS地址:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                  .fontSize(14)

                Text(`https://${this.serverInfo.address}:${this.serverInfo.port}`)
                  .fontColor(Color.Blue)
                  .fontSize(16)
                  .layoutWeight(1)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .padding(15)
            .backgroundColor('#f0f8ff')
            .borderRadius(10)
            .width('90%')

            // API端点信息
            Column({ space: 8 }) {
              Text('主要API端点:')
                .fontWeight(FontWeight.Medium)
                .fontSize(14)

              Column({ space: 4 }) {
                Text('• GET /api/secure/users - 安全用户列表')
                  .fontSize(12)
                  .fontColor(Color.Gray)
                Text('• POST /api/secure/login - 安全登录')
                  .fontSize(12)
                  .fontColor(Color.Gray)
                Text('• GET /api/ssl/info - SSL证书信息')
                  .fontSize(12)
                  .fontColor(Color.Gray)
                Text('• POST /api/secure/upload - 安全文件上传')
                  .fontSize(12)
                  .fontColor(Color.Gray)
              }
              .alignItems(HorizontalAlign.Start)
            }
            .padding(15)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .width('90%')
            .alignItems(HorizontalAlign.Start)

            // 停止按钮
            Button('停止HTTPS服务器')
              .type(ButtonType.Capsule)
              .width('80%')
              .height(50)
              .backgroundColor(Color.Red)
              .onClick(() => {
                this.stopServer();
              })
          }
          .width('100%')
        }

        // 服务器未运行状态
        else {
          Column({ space: 20 }) {
            // 配置区域
            Column({ space: 15 }) {
              Text('HTTPS服务器配置')
                .fontWeight(FontWeight.Medium)
                .fontSize(16)

              // 端口配置
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
                    this.port = parseInt(value) || 8443;
                  })
              }
              .width('100%')

            }
            .padding(15)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .width('90%')
            .alignItems(HorizontalAlign.Start)

            // 启动按钮
            Button('启动HTTPS服务器')
              .type(ButtonType.Capsule)
              .enabled(this.port > 0)
              .width('80%')
              .height(50)
              .backgroundColor(Color.Blue)
              .onClick(() => {
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

