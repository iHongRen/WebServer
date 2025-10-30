import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { WebServer, ErrorHandler, ServerInfo } from '@cxy/webserver';
import { LoggerExample } from '../examples/logger/LoggerExample';
import { CorsExample } from '../examples/cors/CorsExample';
import { BodyParserExample } from '../examples/body-parser/BodyParserExample';
import { StaticExample } from '../examples/static/StaticExample';
import { RouterExample } from '../examples/router/RouterExample';
import { HttpsExample } from '../examples/https/HttpsExample';
import { rcp } from '@kit.RemoteCommunicationKit';

interface User {
  id: number,
  name: string
}

@Entry
@Component
struct Index {
  @State server: WebServer | null = null;
  @State serverInfo: ServerInfo | null = null;
  @State isRunning: boolean = false;
  @State port: number = 8080;
  @State staticFilesRoot: string = '';

  async aboutToAppear() {
    HttpsExample.startCompleteExample()
    setTimeout(() => {
      this.requestHttps()
    }, 5000)
    // this.setupStatic();
    // this.initServer();
    //
    // this.runExamples()
  }

  requestHttps() {
    // Configure security settings
    const securityConfig: rcp.SecurityConfiguration = {
      remoteValidation: "skip",
    };

    const session = rcp.createSession({ requestConfiguration: { security: securityConfig } });

    session.get("https://192.168.2.38:8443/api/status").then((response) => {
      console.info(`Succeeded in getting the response ${response}`);
    }).catch((err: BusinessError) => {
      console.error(`err: err code is ${err.code}, err message is ${JSON.stringify(err)}`);
    });
  }

  aboutToDisappear() {
    this.stop();
  }

  // 拷贝到沙箱服务器目录
  async copyToStaticRoot(fileName: string) {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const buf = await context.resourceManager.getRawFileContent(fileName)
    const path = this.staticFilesRoot + '/' + fileName
    const outFile = await fileIo.open(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC)
    await fileIo.write(outFile.fd, buf.buffer)
    await fileIo.close(outFile.fd)
  }

  // 创建静态资源文件
  async setupStatic() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.staticFilesRoot = context.filesDir + '/static';
    const access = await fileIo.access(this.staticFilesRoot)
    if (!access) {
      await fileIo.mkdir(this.staticFilesRoot)
    }
    await this.copyToStaticRoot('index.html');
    await this.copyToStaticRoot('upload.html');
  }

  // 初始化服务器
  initServer() {
    this.server = new WebServer();

    // --- 1. 中间件注册 ---
    // 顺序很重要，通常日志和CORS最先，然后是请求体解析，再是静态文件和路由
    this.server.logger({
      stream: (log: string) => {
        console.log(log) //自定义写入日志文件
      }
    }) //日志记录
    this.server.cors(); //支持跨域

    this.server.auto(); //自动解析
    // this.server.json(); // 解析 application/json
    // this.server.urlencoded(); // 解析 application/x-www-form-urlencoded
    // this.server.multipart(); // 解析 multipart/form-data (用于文件上传)
    // this.server.plain(); // 解析文本

    this.server.serveStatic(this.staticFilesRoot); // 提供静态文件服务

    // --- 2. 模拟数据 ---
    const users: User[] = [
      { id: 1, name: 'cxy' },
      { id: 2, name: 'ihongren' },
      { id: 3, name: '仙银' }
    ];
    let nextUserId = 4;


    // --- 3. API 示例 ---
    // GET /api/users - 获取所有用户
    // curl http://192.168.2.38:8080/api/users
    this.server.get('/api/users', (req, res) => {
      res.json(users);
    });

    // GET /api/users/:id - 使用路由参数，获取单个用户
    // curl http://192.168.2.38:8080/api/users/1
    this.server.get('/api/users/:id', (req, res) => {
      const user = users.find(u => u.id === parseInt(req.params.id));
      if (user) {
        res.json(user);
      } else {
        res.status(404).json({ error: 'User not found' });
      }
    });

    // POST /api/users - 创建新用户
    // curl -X POST -H "Content-Type: application/json" -d '{"name":"NewUser"}' http://192.168.2.38:8080/api/users
    this.server.post('/api/users', (req, res) => {
      const newUser: User = {
        id: nextUserId++,
        name: (req.body as Record<string, string>).name || 'Unnamed'
      };
      users.push(newUser);
      console.log('Created new user:', JSON.stringify(newUser));
      res.status(201).json(newUser);
    });

    // post /api/users/:id - 更新用户
    // curl -X POST -H "Content-Type: application/json" -d '{"name":"UpdatedUser"}' http://192.168.2.38:8080/api/users/1
    this.server.post('/api/users/:id', (req, res) => {
      const userId = parseInt(req.params.id);
      const userIndex = users.findIndex(u => u.id === userId);
      if (userIndex !== -1) {
        users[userIndex].name = (req.body as Record<string, string>).name || users[userIndex].name;
        res.json(users[userIndex]);
      } else {
        res.status(404).json({ error: 'User not found' });
      }
    });

    // --- 4. 文件上传路由 ---
    // curl -X POST -F "uploadFile=@/path/to/your/file.txt" http://192.168.2.38:8080/api/upload
    this.server.post('/api/upload', async (req, res, next) => {
      try {
        const uploadedFile = req.files?.uploadFile; // 'uploadFile' 对应 HTML form 中的 input name
        if (!uploadedFile) {
          return res.status(400).json({ error: 'No file uploaded.' });
        }

        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const tempPath = `${context.filesDir}/${uploadedFile.fileName}`;
        const f = await fileIo.open(tempPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
        await fileIo.write(f.fd, uploadedFile.data);

        console.log(`File uploaded successfully: ${uploadedFile.fileName}`);
        res.json({
          message: 'File uploaded successfully!',
          filename: uploadedFile.fileName,
          size: uploadedFile.data.byteLength,
          contentType: uploadedFile.contentType,
          savedTo: tempPath
        });
      } catch (error) {
        next(error);
      }
    });

    // --- 5. 其他高级示例 ---
    // 路由参数示例
    // curl http://192.168.2.38:8080/api/users/123/books/456
    this.server.get('/api/users/:userId/books/:bookId', (req, res) => {
      res.json({
        message: `You requested book ${req.params.bookId} for user ${req.params.userId}.`
      });
    });

    // 获取自定义请求头示例
    // curl -H "X-Custom-Request-Header: MyValue" http://192.168.2.38:8080/api/custom-request-header
    this.server.get('/api/custom-request-header', (req, res) => {
      const customHeader = req.get('x-custom-request-header');
      res.json({
        message: 'Received custom request header',
        headerValue: customHeader || 'Not found'
      });
    });

    // 自定义响应头示例
    // curl -i http://192.168.2.38:8080/api/custom-header
    this.server.get('/api/custom-header', (req, res) => {
      res.setHeader('X-Custom-Header', 'Hello from WebServer!');
      res.json({ message: 'Check the response headers!' });
    });

    // 错误触发示例
    // curl http://192.168.2.38:8080/crash
    this.server.get('/crash', (req, res, next) => {
      // 故意抛出一个错误来测试错误处理中间件
      throw new Error('This is a simulated crash!');
    });


    // --- 6. 统一错误处理中间件 (必须在路由之后注册) ---
    const customErrorHandler: ErrorHandler = (error, req, res, next) => {
      console.error(`[WebServer Error] Path: ${req.path}, Message: ${error.message}`);
      if (res.isHeadersSent()) {
        return next(error); // 如果头已发送，则委托给默认错误处理器
      }
      res.status(500).json({
        error: 'Internal Server Error',
        message: error.message || 'An unknown error occurred.'
      });
    };
    this.server.use(customErrorHandler);
  }

  // 运行更多示例
  runExamples() {
    // BodyParserExample.example1();
    // BodyParserExample.example2();
    // BodyParserExample.example3();
    // BodyParserExample.example4();
    // BodyParserExample.example5();
    //
    // StaticExample.example1();

    // RouterExample.example1();
    //
    // LoggerExample.example1();
    // LoggerExample.example2();
    // LoggerExample.example3();
    // LoggerExample.example4();
    // LoggerExample.example5();
    // LoggerExample.example6();
    // LoggerExample.example7();
    // LoggerExample.logFormatComparison();
    // LoggerExample.performanceTest();
    //
    // CorsExample.example1();
    // CorsExample.example2();
    // CorsExample.example3();
    // CorsExample.example4();
    // CorsExample.example5();
  }

  // 启动服务
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

  // 停止服务
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
