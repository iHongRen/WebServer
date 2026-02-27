import { common } from '@kit.AbilityKit';
import { LoggerExample } from './LoggerExample';
import { socket } from '@kit.NetworkKit';

@Builder
function loggerBuilder() {
  LoggerPage()
}

@Component
struct LoggerPage {
  @State title: string = 'Logger示例'
  @State loggerExample: LoggerExample = new LoggerExample()
  @State serverInfo: socket.NetAddress | null = null;
  @State port: number = 8085;
  @State errorMessage: string = '';
  @State successMessage: string = '';

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.loggerExample.init(context)
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

    const info = await this.loggerExample.start(this.port);
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
    await this.loggerExample.stop();
    this.serverInfo = null;
    this.successMessage = '服务器已停止';
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
                Text('服务地址:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text(`http://${this.serverInfo.address}:${this.serverInfo.port}`)
                  .fontColor(Color.Blue)
                  .fontSize(16)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)

              Row() {
                Text('日志格式:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text(this.loggerExample.logFormat.toUpperCase())
                  .fontSize(14)
                  .fontColor(Color.Green)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)

              Row() {
                Text('日志级别:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text(this.loggerExample.logLevel.toUpperCase())
                  .fontSize(14)
                  .fontColor(Color.Orange)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .padding(15)
            .backgroundColor('#f0f8ff')
            .borderRadius(10)
            .width('90%')

            // 日志统计
            Column({ space: 10 }) {
              Text('📊 日志统计')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Row() {
                Text('日志条数:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text(this.loggerExample.logRecords.length.toString())
                  .fontSize(16)
                  .fontColor(Color.Blue)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .padding(15)
            .backgroundColor('#f0fff0')
            .borderRadius(10)
            .width('90%')

            // 日志特性
            Column({ space: 8 }) {
              Text('Logger特性')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Text('✅ 多格式日志记录')
                .fontSize(12)
                .fontColor('#666')
              Text('✅ 日志级别控制')
                .fontSize(12)
                .fontColor('#666')
              Text('✅ 文件日志存储')
                .fontSize(12)
                .fontColor('#666')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(15)
            .backgroundColor('#fff3e0')
            .borderRadius(10)
            .width('90%')

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
            // 配置区域
            Column({ space: 15 }) {
              Text('Logger服务器配置')
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
                    this.port = parseInt(value)
                  })
              }
              .width('100%')
            }
            .padding(15)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .width('90%')

            // 功能说明
            Column({ space: 8 }) {
              Text('Logger功能')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Text('多格式日志记录')
                .fontSize(14)
                .fontColor('#666')
              Text('日志级别过滤')
                .fontSize(14)
                .fontColor('#666')
              Text('文件日志存储')
                .fontSize(14)
                .fontColor('#666')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(15)
            .backgroundColor('#e3f2fd')
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

