import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { WebServer, ErrorHandler, ServerInfo } from '@cxy/webserver';
import { http } from '@kit.NetworkKit';

@Entry
@Component
struct Index {
  @State server: WebServer | null = null;
  @State serverInfo: ServerInfo | null = null;
  @State isRunning: boolean = false;
  @State port: number = 8080;
  @State staticFilesRoot: string = '';
  @State tempUploadsRoot: string = '';
  @State fileList: string[] = [];

  aboutToAppear() {
    this.initContext();
  }

  async initContext() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.staticFilesRoot = context.filesDir + '/webserver';
    this.tempUploadsRoot = context.filesDir + '/temp_uploads';
    await this.createSampleFile();
    // 创建临时上传目录
    if (!fileIo.accessSync(this.tempUploadsRoot)) {
      await fileIo.mkdir(this.tempUploadsRoot);
    }
    await this.createUploadTestPage();
    await this.createUploadTestPage();
    this.initServer();
  }

  async createUploadTestPage() {
    const uploadTestPagePath = `${this.staticFilesRoot}/upload_test.html`;
    const uploadTestPageContent = '';
    try {
      const file = await fileIo.open(uploadTestPagePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      await fileIo.write(file.fd, uploadTestPageContent);
      await fileIo.close(file);
      console.log('Upload test page created at:', uploadTestPagePath);
    } catch (e) {
      console.error('Failed to create upload test page:', e)
    }
  }

  async createSampleFile() {
    if (!fileIo.accessSync(this.staticFilesRoot)) {
      await fileIo.mkdir(this.staticFilesRoot)
    }
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

    // 注册中间件
    this.server.serveStatic(this.staticFilesRoot);
    this.server.cors();
    this.server.json();
    this.server.urlencoded();
    this.server.multipart();
    this.server.logger()

    // 新增：获取文件列表路由
    this.server.get('/api/files', async (req, res, next) => {
      try {
        const fileNames = await fileIo.listFile(this.staticFilesRoot);
        res.json(fileNames);
      } catch (error) {
        next(error);
      }
    });


    this.server.get('/api/device', (req, res, next) => {
      res.json({
        model: 'My HarmonyOS Device',
        timestamp: new Date().getTime(),
        filesDir: this.staticFilesRoot
      });
    });

    this.server.post('/api/users', (req, res, next) => {
      console.log('Received user data (JSON): ', req.body);
      res.status(201).json(req.body);
    });

    // 新增：处理 application/x-www-form-urlencoded 请求的路由
    this.server.post('/login', (req, res, next) => {
      console.log('Received login data (urlencoded): ', req.body);
      const body = req.body as Record<string, Object>
      const username = body.username || 'guest';
      res.json({ message: `Welcome, ${username}!` });
    });


    this.server.get('/users/:userId/books/:bookId', (req, res, next) => {
      const userId = req.params.userId;
      const bookId = req.params.bookId;

      res.json({
        message: `You requested book ${bookId} for user ${userId}.`,
        user: userId,
        book: bookId
      });
    });

    // 注册错误触发示例路由
    this.server.get('/crash', (req, res, next) => {
      throw new Error('This route crashed!');
    });

    // 注册统一错误处理中间件 (必须在最后)
    const customErrorHandler: ErrorHandler = (error, req, res, next) => {
      console.error('An error occurred:', error.message);
      if (res.isHeadersSent()) {
        return next(error);
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
        this.fetchFileList();
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
    this.fileList = [];
  }

  async fetchFileList() {
    if (!this.serverInfo) {
      return;
    }

    const request = http.createHttp();
    try {
      const url = `http://${this.serverInfo?.address}:${this.serverInfo?.port}/api/files`;

      const response = await request.request(url, { method: http.RequestMethod.GET });
      if (response.responseCode === 200) {
        this.fileList = JSON.parse(response.result as string);
      } else {
        console.error('Failed to fetch file list:', response.responseCode);
      }
      request.destroy()
    } catch (e) {
      console.error('Error fetching file list:', e);
    } finally {
    }
  }

  build() {
    Row() {
      Column() {
        Text('鸿蒙 Web Server')
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
                this.port = parseInt(val);
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
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.Center)
    }
    .height('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 100 })
  }
}