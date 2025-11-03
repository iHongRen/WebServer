import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { ServerInfo } from '@cxy/webserver';
import { HttpExample } from './HttpExample';

@Builder
function httpBuilder() {
  HttpPage()
}

@Component
struct HttpPage {
  @State title: string = 'HTTP服务器示例'
  @State httpExample: HttpExample | null = null;
  @State serverInfo: ServerInfo | null = null;
  @State port: number = 8080;
  @State errorMessage: string = '';
  @State successMessage: string = '';

  aboutToAppear() {
    setTimeout(() => {
      this.startServer();
    }, 0);
  }

  aboutToDisappear() {
    this.stopServer();
  }

  /**
   * 初始化HTTP示例
   */
  async initializeExample() {
    this.errorMessage = '';
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.httpExample = new HttpExample(context, {
      port: this.port,
      enableLogging: true,
      enableCors: true
    });
    await this.httpExample.setupStaticFiles();
  }

  /**
   * 启动服务器
   */
  async startServer() {
    if (!this.httpExample) {
      await this.initializeExample();
    }

    if (!this.httpExample) {
      this.errorMessage = '服务器初始化失败';
      return;
    }

    try {
      this.errorMessage = '';

      const info = await this.httpExample.start();

      if (info) {
        this.serverInfo = info;
        this.successMessage = `🟢服务器运行中`;
      } else {
        this.errorMessage = '服务器启动失败，未获取到地址';
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
    if (!this.httpExample) {
      return;
    }

    try {
      await this.httpExample.stop();

      this.httpExample = null;
      this.serverInfo = null;
      this.successMessage = '🛑 服务器已停止';

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
                Text('静态目录:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text(this.httpExample?.getConfig().staticRoot || '')
                  .layoutWeight(1)
                  .fontSize(12)
                  .fontColor(Color.Gray)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
              .alignItems(VerticalAlign.Top)
            }
            .padding(15)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .width('90%')

            // 停止按钮
            Button('停止服务器')
              .width('80%')
              .height(50)
              .backgroundColor(Color.Red)
              .onClick(() => {
                this.clearMessages();
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
                  this.updatePort(value);
                })
            }
            .padding(15)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .width('90%')


            // 启动按钮
            Button('启动服务器')
              .width('80%')
              .height(50)
              .backgroundColor( Color.Blue)
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

