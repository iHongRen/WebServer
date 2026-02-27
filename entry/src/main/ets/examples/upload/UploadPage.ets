/**
 * @fileName : UploadPage.ets
 * @author : @cxy
 * @date : 2025/12/31
 * @description : 分片上传示例页面
 */

import { common } from '@kit.AbilityKit';
import { UploadExample } from './UploadExample';
import { socket } from '@kit.NetworkKit';

@Builder
function uploadBuilder() {
  UploadPage()
}

@Component
struct UploadPage {
  @State title: string = '分片上传示例'
  @State uploadExample: UploadExample = new UploadExample();
  @State serverInfo: socket.NetAddress | null = null;
  @State port: number = 8088;
  @State errorMessage: string = '';
  @State successMessage: string = '';

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.uploadExample.init(context);
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

    const info = await this.uploadExample.start(this.port);
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
    await this.uploadExample.stop();
    this.serverInfo = null;
    this.successMessage = '服务器已停止';
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

        // 服务器状态区域
        if (this.serverInfo) {
          Column({ space: 15 }) {
            // 服务器信息卡片
            Column({ space: 10 }) {
              Row() {
                Text('访问地址:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text(`http://${this.serverInfo.address}:${this.serverInfo.port}`)
                  .fontColor(Color.Blue)
                  .fontSize(16)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)

              Row() {
                Text('功能:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text('大文件分片上传')
                  .layoutWeight(1)
                  .fontSize(14)
                  .fontColor(Color.Gray)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .padding(15)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .width('90%')

            // API端点说明
            Column({ space: 8 }) {
              Text('API端点:')
                .fontWeight(FontWeight.Bold)
                .fontSize(14)
                .width('100%')

              Text('POST /api/upload/check - 检查上传状态')
                .fontSize(12)
                .fontColor('#666')
                .width('100%')

              Text('POST /api/upload/chunk - 上传分片')
                .fontSize(12)
                .fontColor('#666')
                .width('100%')

              Text('POST /api/upload/merge - 合并分片')
                .fontSize(12)
                .fontColor('#666')
                .width('100%')

              Text('GET /api/upload/tasks - 查看任务')
                .fontSize(12)
                .fontColor('#666')
                .width('100%')

              Text('GET /api/upload/files - 查看文件')
                .fontSize(12)
                .fontColor('#666')
                .width('100%')
            }
            .padding(15)
            .backgroundColor('#f9f9f9')
            .borderRadius(10)
            .width('90%')
            .alignItems(HorizontalAlign.Start)

            // 停止按钮
            Button('停止服务器')
              .type(ButtonType.Capsule)
              .width('80%')
              .height(50)
              .backgroundColor(Color.Red)
              .onClick(() => {
                this.stopServer();
              })
          }
          .width('100%')

        } else {
          // 服务器未运行状态
          Column({ space: 20 }) {
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
                  this.port = parseInt(value);
                })
            }
            .padding(15)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .width('90%')

            // 启动按钮
            Button('启动服务器')
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
