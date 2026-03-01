/**
 * @fileName : BodyPage.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : Body Parser示例页面
 */

import { BodyParserExample } from './BodyParserExample';

@Builder
function bodyBuilder() {
  BodyPage()
}

@Entry
@Component
struct BodyPage {
  @State title: string = 'Body Parser示例页面'
  @State serverStatus: string = '未启动';
  @State serverInfo: string = '';
  @State port: number = 8082;
  @State isRunning: boolean = false;
  private bodyParserExample: BodyParserExample = new BodyParserExample();

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
            Text('功能说明')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text('本示例展示WebServer框架的请求体解析功能，支持多种Content-Type自动解析。')
              .fontSize(14)
              .fontColor('#666')

            Divider()

            Text('支持的解析器：')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Column({ space: 8 }) {
              this.featureItem('📝', 'JSON解析器', 'application/json')
              this.featureItem('📋', 'URL编码解析器', 'application/x-www-form-urlencoded')
              this.featureItem('📦', '多部分表单解析器', 'multipart/form-data (文件上传)')
              this.featureItem('📄', '纯文本解析器', 'text/plain')
              this.featureItem('🔄', '自动解析器', '根据Content-Type自动选择')
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
              this.apiItem('POST', '/api/json', 'JSON数据解析')
              this.apiItem('POST', '/api/urlencoded', 'URL编码数据解析')
              this.apiItem('POST', '/api/multipart', '多部分表单解析')
              this.apiItem('POST', '/api/plain', '纯文本解析')
              this.apiItem('POST', '/api/auto', '自动解析')
              this.apiItem('GET', '/api/results', '获取解析结果')
              this.apiItem('DELETE', '/api/results', '清除所有结果')
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

            Text('使用curl命令测试解析器：')
              .fontSize(14)
              .fontColor('#666')

            Text('# JSON解析\ncurl -X POST http://IP:8082/api/json \\\n  -H "Content-Type: application/json" \\\n  -d \'{"name":"test","value":123}\'')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('# URL编码解析\ncurl -X POST http://IP:8082/api/urlencoded \\\n  -H "Content-Type: application/x-www-form-urlencoded" \\\n  -d "name=test&value=123"')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('详细测试脚本请查看: test-body-parser.sh')
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

  private async startServer() {
    try {
      this.serverStatus = '启动中...';
      const info = await this.bodyParserExample.start(this.port);
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
      await this.bodyParserExample.stop();
      this.isRunning = false;
      this.serverStatus = '已停止';
      this.serverInfo = '';
    } catch (error) {
      this.serverInfo = `停止失败: ${error.message}`;
    }
  }
}
