/**
 * @fileName : FileUploadPage.ets
 * @author : @cxy
 * @date : 2025/3/3
 * @description : 文件上传示例页面
 */

import { FileUploadExample } from './FileUploadExample';
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';

@Builder
function fileUploadBuilder() {
  FileUploadPage()
}

@Entry
@Component
struct FileUploadPage {
  @State title: string = '文件上传示例页面'
  @State serverStatus: string = '未启动';
  @State serverInfo: string = '';
  @State port: number = 8080;
  @State isRunning: boolean = false;
  private example: FileUploadExample = new FileUploadExample();
  private serverAddress: socket.NetAddress | null = null;

  aboutToAppear() {
    this.example.init(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  async aboutToDisappear() {
    if (this.isRunning) {
      await this.stopServer();
    }
  }

  @Builder
  featureItem(icon: string, title: string, description: string) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(24)

      Column({ space: 4 }) {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        Text(description)
          .fontSize(12)
          .fontColor('#999')
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F9F9F9')
    .borderRadius(8)
  }

  @Builder
  apiItem(method: string, path: string, description: string) {
    Row({ space: 12 }) {
      Text(method)
        .fontSize(12)
        .fontColor(Color.White)
        .padding({
          left: 8,
          right: 8,
          top: 4,
          bottom: 4
        })
        .backgroundColor(method === 'GET' ? '#4CAF50' : method === 'POST' ? '#2196F3' : '#F44336')
        .borderRadius(4)

      Column({ space: 4 }) {
        Text(path)
          .fontSize(13)
          .fontFamily('monospace')
          .fontWeight(FontWeight.Medium)
        Text(description)
          .fontSize(11)
          .fontColor('#999')
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#F9F9F9')
    .borderRadius(8)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          // 服务器控制区域
          Column({ space: 12 }) {
            Text('服务器控制')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Row({ space: 12 }) {
              Text('端口:')
                .fontSize(16)
              TextInput({ text: this.port.toString() })
                .width(100)
                .type(InputType.Number)
                .enabled(!this.isRunning)
                .onChange((value: string) => {
                  const newPort = parseInt(value);
                  if (!isNaN(newPort) && newPort > 0 && newPort < 65536) {
                    this.port = newPort;
                  }
                })
            }

            Row({ space: 12 }) {
              Button(this.isRunning ? '停止服务器' : '启动服务器')
                .type(ButtonType.Capsule)
                .width(120)
                .borderRadius(8)
                .backgroundColor(this.isRunning ? Color.Red : Color.Blue)
                .onClick(async () => {
                  if (this.isRunning) {
                    await this.stopServer();
                  } else {
                    await this.startServer();
                  }
                })

              Text(this.serverStatus)
                .fontSize(14)
                .fontColor(this.isRunning ? '#4CAF50' : '#999')
            }

            if (this.serverInfo) {
              Text(this.serverInfo)
                .fontSize(12)
                .fontColor('#666')
                .padding(12)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .width('100%')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // 功能说明
          Column({ space: 12 }) {
            Text('功能特性')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Column({ space: 8 }) {
              this.featureItem('📄', '基本上传', 'multipart/form-data 支持')
              this.featureItem('🌊', '流式处理', '文件使用流方式写入')
              this.featureItem('📁', '多文件', '一次可上传多个文件')
              this.featureItem('🔒', '安全文件名', '自动清理名字避免注入')
              this.featureItem('📏', '大小/数量限制', '可配置最大值')
              this.featureItem('🗃️', '临时文件管理', '自动清理临时缓存')
              this.featureItem('🔀', 'mv() 移动方法', '方便移动到目标目录')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // API端点
          Column({ space: 12 }) {
            Text('API端点')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Column({ space: 8 }) {
              this.apiItem('POST', '/api/upload/basic', '基本上传')
              this.apiItem('POST', '/api/upload/stream', '流式上传')
              this.apiItem('POST', '/api/upload/multiple', '多文件')
              this.apiItem('POST', '/api/upload/safe', '安全文件名')
              this.apiItem('POST', '/api/upload/limited', '限制大小')
              this.apiItem('GET', '/api/upload/files', '文件列表')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)


          // 测试方法
          Column({ space: 12 }) {
            Text('测试方法')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text('使用 curl 命令测试常见接口：')
              .fontSize(14)
              .fontColor('#666')

            Text('# 基本上传\ncurl -X POST http://IP:8080/api/upload/basic \
  -F "uploadFile=@/path/to/file.txt"')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('# 流式上传\ncurl -X POST http://IP:8080/api/upload/stream \
  -H "Transfer-Encoding: chunked" \
  --data-binary @largefile.bin')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            if (this.isRunning && this.serverAddress) {
              Text(`浏览器访问: http://${this.serverAddress.address}:${this.serverAddress.port}/file-upload.html`)
                .fontSize(12)
                .fontColor('#2196F3')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
        }
        .width('100%')
        .padding(20)
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .align(Alignment.TopStart)

    }
    .title(this.title)
    .onReady((ctx) => {
      if (ctx.pathInfo.param) {
        this.title = ctx.pathInfo.param as string;
      }
    })

  }

  private async startServer() {
    try {
      this.serverStatus = '启动中...';
      const info = await this.example.start(this.port);
      if (info) {
        this.isRunning = true;
        this.serverStatus = '运行中';
        this.serverInfo = `服务器地址: http://${info.address}:${info.port}`;
        if (info.address && info.port) {
          this.serverInfo += `\nWeb界面: http://${info.address}:${info.port}/upload.html`;
        }
        this.serverAddress = info;
      } else {
        this.serverStatus = '启动失败';
        this.serverInfo = '无法启动服务器，请检查端口是否被占用';
      }
    } catch (error) {
      this.serverStatus = '启动失败';
      this.serverInfo = `错误: ${error.message}`;
    }
  }

  private async stopServer() {
    try {
      await this.example.stop();
      this.isRunning = false;
      this.serverStatus = '已停止';
      this.serverInfo = '';
      this.serverAddress = null;
    } catch (error) {
      this.serverInfo = `停止失败: ${error.message}`;
    }
  }
}
