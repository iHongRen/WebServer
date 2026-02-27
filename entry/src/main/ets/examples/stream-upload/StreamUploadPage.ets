/**
 * @fileName : StreamUploadPage.ets
 * @author : @cxy
 * @date : 2025/12/31
 * @description : 流式上传示例页面
 */

import { StreamUploadExample } from './StreamUploadExample';
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Builder
function streamUploadBuilder() {
  StreamUploadPage()
}

@Entry
@Component
struct StreamUploadPage {
  @State title: string = '流式上传示例页面'
  @State serverStatus: string = '未启动';
  @State serverInfo: string = '';
  @State port: number = 8087;
  @State isRunning: boolean = false;
  private streamUploadExample: StreamUploadExample = new StreamUploadExample();

  aboutToAppear(): void {
    this.streamUploadExample.init(getContext(this) as common.UIAbilityContext);
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
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
                .type(ButtonType.Normal)
                .borderRadius(8)
                .backgroundColor(this.isRunning ? Color.Blue : Color.Red)
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
            Text('功能说明')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text('本示例展示如何接收客户端使用 Transfer-Encoding: chunked 的流式上传数据。')
              .fontSize(14)
              .fontColor('#666')

            Divider()

            Text('支持的上传类型：')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Column({ space: 8 }) {
              this.featureItem('📝', '流式文本上传', '接收分块传输的文本数据')
              this.featureItem('📊', '流式JSON上传', '接收分块传输的JSON数据')
              this.featureItem('📁', '流式文件上传', '接收并保存流式上传的文件')
              this.featureItem('📦', '大文件上传', '支持大文件的流式上传')
              this.featureItem('📋', '文件列表', '查看已上传的文件')
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
              this.apiItem('POST', '/api/upload/stream-text', '流式文本上传')
              this.apiItem('POST', '/api/upload/stream-json', '流式JSON上传')
              this.apiItem('POST', '/api/upload/stream-file', '流式文件上传')
              this.apiItem('POST', '/api/upload/stream-large', '大文件流式上传')
              this.apiItem('GET', '/api/upload/files', '获取文件列表')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // 测试说明
          Column({ space: 12 }) {
            Text('测试方法')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text('使用curl命令测试流式上传：')
              .fontSize(14)
              .fontColor('#666')

            Text('# 流式文本上传\ncurl -X POST http://IP:8087/api/upload/stream-text \\\n  -H "Transfer-Encoding: chunked" \\\n  -d "Hello, Streaming!"')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('# 流式JSON上传\ncurl -X POST http://IP:8087/api/upload/stream-json \\\n  -H "Transfer-Encoding: chunked" \\\n  -H "Content-Type: application/json" \\\n  -d \'{"name":"test","data":"value"}\'')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('详细测试脚本请查看: test-stream-upload.sh')
              .fontSize(12)
              .fontColor('#999')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
        }
        .padding(16)
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
        .backgroundColor(method === 'GET' ? '#4CAF50' : '#2196F3')
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

  private async startServer() {
    try {
      this.serverStatus = '启动中...';
      const info = await this.streamUploadExample.start(this.port);
      if (info) {
        this.isRunning = true;
        this.serverStatus = '运行中';
        this.serverInfo = `服务器地址: http://${info.address}:${info.port}`;
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
      await this.streamUploadExample.stop();
      this.isRunning = false;
      this.serverStatus = '已停止';
      this.serverInfo = '';
    } catch (error) {
      this.serverInfo = `停止失败: ${error.message}`;
    }
  }
}

