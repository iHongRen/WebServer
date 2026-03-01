/**
 * @fileName : RouterPage.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : Router示例页面
 */

import { RouterExample } from './RouterExample';

@Builder
function routerBuilder() {
  RouterPage()
}

@Entry
@Component
struct RouterPage {
  @State title: string = 'Router示例页面'
  @State serverStatus: string = '未启动';
  @State serverInfo: string = '';
  @State port: number = 8086;
  @State isRunning: boolean = false;
  private routerExample: RouterExample = new RouterExample();

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

            Text('本示例展示WebServer框架的路由系统功能，支持基础路由、参数路由和动态路由管理。')
              .fontSize(14)
              .fontColor('#666')

            Divider()

            Text('支持的路由功能：')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Column({ space: 8 }) {
              this.featureItem('🏠', '基础路由', 'GET, POST, PUT, DELETE等方法')
              this.featureItem('🔗', '参数路由', '/users/:id, /products/:category/:id')
              this.featureItem('⚡', '动态路由', '运行时添加和删除路由')
              this.featureItem('📊', '路由统计', '请求次数、响应时间统计')
              this.featureItem('📝', '路由记录', '详细的路由访问记录')
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

            Text('基础路由:')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Column({ space: 8 }) {
              this.apiItem('GET', '/', '首页')
              this.apiItem('GET', '/about', '关于页面')
              this.apiItem('GET', '/contact', '联系页面')
            }

            Divider()

            Text('参数路由:')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Column({ space: 8 }) {
              this.apiItem('GET', '/api/users/:id', '用户详情')
              this.apiItem('GET', '/api/products/:category/:id', '产品详情')
              this.apiItem('GET', '/api/posts/:id', '文章详情')
            }

            Divider()

            Text('路由管理:')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Column({ space: 8 }) {
              this.apiItem('GET', '/api/routes/stats', '路由统计')
              this.apiItem('GET', '/api/routes/records', '路由记录')
              this.apiItem('POST', '/api/routes', '添加动态路由')
              this.apiItem('GET', '/api/routes/dynamic', '获取动态路由')
              this.apiItem('DELETE', '/api/routes/records', '清除路由记录')
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

            Text('使用curl命令测试路由：')
              .fontSize(14)
              .fontColor('#666')

            Text('# 参数路由\ncurl http://IP:8086/api/users/123')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('# 添加动态路由\ncurl -X POST http://IP:8086/api/routes \\\n  -H "Content-Type: application/json" \\\n  -d \'{"method":"GET","path":"/test","response":{"msg":"ok"}}\'')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('详细测试脚本请查看: test-router-api.sh')
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
      const info = await this.routerExample.start(this.port);
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
      await this.routerExample.stop();
      this.isRunning = false;
      this.serverStatus = '已停止';
      this.serverInfo = '';
    } catch (error) {
      this.serverInfo = `停止失败: ${error.message}`;
    }
  }
}
