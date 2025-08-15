import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { ErrorHandler, ServerInfo, WebServer } from '@cxy/webserver';

@Entry
@Component
struct Index {
  @State server: WebServer | null = null;
  @State serverInfo: ServerInfo | null = null;
  @State isRunning: boolean = false;
  @State port: number = 8080;
  @State staticFilesRoot: string = '';

  aboutToAppear() {
    this.initContext();
  }

  async initContext() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.staticFilesRoot = context.filesDir;
    await this.createSampleFile();
    this.initServer();
  }

  async createSampleFile() {
    const filePath = this.staticFilesRoot + '/index.html';
    const fileContent =
      '<!DOCTYPE html><html><head><title>Welcome</title><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>body { font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background-color: #f0f0f0; color: #333; } div { text-align: center; } h1 { color: #007aff; } p { font-size: 1.2em; }</style></head><body><div><h1>Hello from ArkTS Web Server!</h1><p>This file is served from the device.</p></div></body></html>';
    try {
      const file = await fileIo.open(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      await fileIo.write(file.fd, fileContent);
      await fileIo.close(file);
      console.log('Sample file created at:', filePath);
    } catch (e) {
      console.error('Failed to create sample file:', e)
    }
  }

  aboutToDisappear() {
    this.stop();
  }

  initServer() {
    this.server = new WebServer();

    // 注册静态文件服务，这是最先被检查的路由之一
    this.server.serveStatic(this.staticFilesRoot);

    // 1. 在定义API路由之前，调用 server.json()
    // 这会为所有请求启用JSON请求体自动解析
    this.server.json();
    this.server.cors();

    // 这是一个会触发错误的路由
    this.server.get('/oops', (req, res, next) => {
      // 模拟一个异步操作后发生的错误
      const err = new Error('Something went wrong!');
      // 将错误传递给 next()，启动错误处理流程
      next(err);
    });

    // 这是一个会直接抛出同步异常的路由
    this.server.get('/crash', (req, res, next) => {
      // 框架会自动捕获这个同步异常，并调用 next(error)
      throw new Error('This route crashed!');
    });

    // ... 其他正常路由 ...
    this.server.get('/', (req, res, next) => {
      res.send('<h1>Welcome</h1>');
    });

    //  定义一个POST路由
    this.server.post('/api/users', (req, res, next) => {
      // 直接使用 req.body，它已经是解析好的JavaScript对象
      console.log('Received user data:', req.body);

      res.status(201).json(req.body);
    });

    // 注册API路由
    this.server.get('/api/device', (req, res, next) => {
      res.json({
        model: 'My HarmonyOS Device',
        timestamp: new Date().getTime(),
        filesDir: this.staticFilesRoot
      });
    });

    this.server.post('/api/echo', (req, res, next) => {
      res.json(req.getBodyAsJson());
    });


    // --- 统一错误处理中间件 ---
    // **注意**: 它有4个参数，并且通常注册在所有其他中间件和路由之后
    const customErrorHandler: ErrorHandler = (error, req, res, next) => {
      console.error('An error occurred:', error.message);

      // 避免在已经发送响应头后再次发送
      if (res.isHeadersSent()) {
        return next(error); // 交给默认的最终处理器
      }

      res.status(500).json({
        error: 'Internal Server Error',
        message: error.message || 'An unknown error occurred.'
      });
    };
    this.server.use(customErrorHandler);
  }

  async start() {
    if (!this.server) {
      this.initServer();
    }
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
          .margin({ bottom: 20 })

        if (this.isRunning && this.serverInfo) {
          Column({
            space: 10
          }) {
            Text('服务器运行中...').fontColor(Color.Green).fontWeight(FontWeight.Bold)
            Text(`访问地址: http://${this.serverInfo.address}:${this.serverInfo.port}`)
            Text('服务目录:').margin({ top: 10 })
            Text(this.staticFilesRoot)
              .fontSize(12)
              .fontColor(Color.Gray)
              .width('90%')
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .maxLines(2)

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
            Text('服务器已停止').fontColor(Color.Red).fontWeight(FontWeight.Bold).margin({ bottom: 10 })
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
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.Center)
    }
    .height('100%')
  }
}
