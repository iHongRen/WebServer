import { common } from '@kit.AbilityKit';
import { StaticExample } from './StaticExample';
import { socket } from '@kit.NetworkKit';

@Builder
function staticBuilder() {
  StaticPage()
}

@Component
struct StaticPage {
  @State title: string = 'Static示例'
  @State staticExample: StaticExample = new StaticExample()
  @State serverInfo: socket.NetAddress | null = null;
  @State port: number = 8087;
  @State errorMessage: string = '';
  @State successMessage: string = '';

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.staticExample.init(context)
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

    const info = await this.staticExample.start(this.port);
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
    await this.staticExample.stop();
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
                Text('静态目录:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text(this.staticExample?.staticRoot || '')
                  .layoutWeight(1)
                  .fontSize(12)
                  .fontColor(Color.Gray)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)

            }
            .padding(15)
            .backgroundColor('#f0f8ff')
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

