import { RouterExample } from './RouterExample';
import { socket } from '@kit.NetworkKit';

@Builder
function routerBuilder() {
  RouterPage()
}

@Component
struct RouterPage {
  @State title: string = 'Router示例'
  @State routerExample: RouterExample = new RouterExample()
  @State serverInfo: socket.NetAddress | null = null;
  @State port: number = 8086;
  @State errorMessage: string = '';
  @State successMessage: string = '';

  aboutToAppear() {
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

    const info = await this.routerExample.start(this.port);
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
    await this.routerExample.stop();
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
            }
            .padding(15)
            .backgroundColor('#f0f8ff')
            .borderRadius(10)
            .width('90%')

            // 路由统计
            Column({ space: 10 }) {
              Text('路由统计')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Row() {
                Text('请求次数:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text(this.routerExample.getRouteCount().toString())
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

            // 路由特性
            Column({ space: 8 }) {
              Text('Router特性')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })
              Text('✅ 基本路由')
                .fontSize(12)
                .fontColor('#666')
              Text('✅ 参数路由 (/users/:id)')
                .fontSize(12)
                .fontColor('#666')
              Text('✅ 路由管理')
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

            // 功能说明
            Column({ space: 8 }) {
              Text('Router功能')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Text('基础路由')
                .fontSize(14)
                .fontColor('#666')
              Text('路由参数')
                .fontSize(14)
                .fontColor('#666')
              Text('路由管理')
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