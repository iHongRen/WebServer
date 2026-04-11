/**
 * @fileName : CorsPage.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : CORS示例页面
 */

import { CorsExample } from './CorsExample';

@Builder
function corsBuilder() {
  CorsPage()
}

@Entry
@Component
struct CorsPage {
  @State title: string = 'CORS示例页面'
  @State serverStatus: string = '未启动';
  @State serverInfo: string = '';
  @State port: number = 8080;
  @State isRunning: boolean = false;
  private corsExample: CorsExample = new CorsExample();

  aboutToDisappear(): void {
    if (this.isRunning) {
      this.stopServer()
    }
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

            Text('本示例展示WebServer框架的跨域资源共享(CORS)功能，支持简单请求、预检请求和凭证请求。')
              .fontSize(14)
              .fontColor('#666')

            Divider()

            Text('支持的CORS特性：')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Column({ space: 8 }) {
              this.featureItem('🌐', '简单请求', 'GET、POST等简单跨域请求')
              this.featureItem('✈️', '预检请求', 'OPTIONS预检请求处理')
              this.featureItem('🔐', '凭证请求', '支持携带Cookies的请求')
              this.featureItem('📋', '自定义头部', '支持自定义HTTP头部')
              this.featureItem('⚙️', '配置管理', '动态CORS配置和测试')
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

            Text('CORS测试:')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Column({ space: 8 }) {
              this.apiItem('GET', '/api/cors/simple', '简单请求测试')
              this.apiItem('POST', '/api/cors/preflight', '预检请求测试')
              this.apiItem('POST', '/api/cors/credentials', '凭证请求测试')
              this.apiItem('PUT', '/api/cors/custom-headers', '自定义头部测试')
            }

            Divider()

            Text('CORS配置:')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Column({ space: 8 }) {
              this.apiItem('GET', '/api/cors/config', '获取CORS配置')
              this.apiItem('POST', '/api/cors/test-origin', '测试来源是否允许')
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

            Text('使用curl命令测试CORS：')
              .fontSize(14)
              .fontColor('#666')

            Text('# 简单请求\ncurl http://IP:8080/api/cors/simple \\\n  -H "Origin: http://example.com"')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('# 预检请求\ncurl -X OPTIONS http://IP:8080/api/cors/preflight \\\n  -H "Origin: http://example.com" \\\n  -H "Access-Control-Request-Method: POST"')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('详细测试脚本请查看: test-cors.sh')
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
        .backgroundColor(method === 'GET' ? '#4CAF50' :
          method === 'POST' ? '#2196F3' : method === 'PUT' ? '#FF9800' : '#9C27B0')
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
      const info = await this.corsExample.start(this.port);
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
      await this.corsExample.stop();
      this.isRunning = false;
      this.serverStatus = '已停止';
      this.serverInfo = '';
    } catch (error) {
      this.serverInfo = `停止失败: ${error.message}`;
    }
  }
}
