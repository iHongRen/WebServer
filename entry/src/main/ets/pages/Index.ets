import { ServerInfo, WebServer } from '@cxy/webserver';
import { BusinessError } from '@kit.BasicServicesKit';


@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @State server: WebServer | null = null;
  @State serverInfo: ServerInfo | null = null;
  @State isRunning: boolean = false;
  @State port: number = 8080;

  aboutToAppear() {
    this.initServer();
  }

  aboutToDisappear() {
    this.stop();
  }

  initServer() {
    this.server = new WebServer();

    // 添加默认路由
    this.server.get('/', (req, res) => {
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.send('<h1>鸿蒙 Web Server</h1><p>It works!</p>');
    });

    this.server.get('/api/device', (req, res) => {
      // 示例API，返回一些设备信息
      res.json({
        model: 'My HarmonyOS Device',
        timestamp: new Date().getTime()
      });
    });

    this.server.post('/api/echo', (req, res) => {
      // 示例POST，回显body
      res.json(req.getBodyAsJson());
    });
  }

  async start() {
    if (!this.server) {
      return;
    }
    try {
      const info = await this.server.startServer(this.port);
      if (info.address) {
        this.serverInfo = info;
        this.isRunning = true;
      } else {
        console.error("启动失败，未获取到地址");
      }
    } catch (e) {
      const error = e as BusinessError;
      console.error(`启动失败: ${error.message}, code: ${error.code}`);
    }
  }

  async stop() {
    if (!this.server) {
      return;
    }
    await this.server.stopServer();
    this.isRunning = false;
    this.serverInfo = null;
  }

  build() {
    Row() {
      Column() {
        Text('ArkTS Web Server')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 30 })

        if (this.isRunning && this.serverInfo) {
          Column({
            space: 10
          }) {
            Text('服务器运行中...').fontColor(Color.Green)
            Text(`访问地址: http://${this.serverInfo.address}:${this.serverInfo.port}`)
          }.margin({ bottom: 20 })

          Button('停止服务器')
            .width('80%')
            .height(50)
            .backgroundColor(Color.Red)
            .onClick(() => {
              this.stop();
            })

        } else {
          Column({
            space: 10
          }) {
            Text('服务器已停止').fontColor(Color.Red)
            TextInput({
              text: this.port.toString(),
              placeholder: '请输入端口号'
            })
              .type(InputType.Number)
              .onChange((val) => {
                this.port = parseInt(val) || 8080;
              })
              .width('80%')
              .height(50)
              .margin({ bottom: 10 })

          }.margin({ bottom: 20 })

          Button('启动服务器')
            .width('80%')
            .height(50)
            .onClick(() => {
              this.start();
            })
        }

      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .height('100%')
  }
}
