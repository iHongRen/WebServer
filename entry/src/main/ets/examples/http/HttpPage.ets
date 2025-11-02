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
  @State isRunning: boolean = false;
  @State port: number = 8080;
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State successMessage: string = '';

  async aboutToAppear() {
    await this.initializeExample();
  }

  aboutToDisappear() {
    this.stopServer();
  }

  /**
   * 初始化HTTP示例
   */
  async initializeExample() {
    try {
      this.isLoading = true;
      this.errorMessage = '';

      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;

      // 创建HTTP示例实例
      this.httpExample = new HttpExample(context, {
        port: this.port,
        enableLogging: true,
        enableCors: true
      });

      // 设置静态文件
      await this.httpExample.setupStaticFiles();

      // 初始化服务器
      this.httpExample.initializeServer();

      this.successMessage = '✅ HTTP示例初始化完成';
      console.log('HTTP示例初始化完成');

    } catch (error) {
      this.errorMessage = `初始化失败: ${error}`;
      console.error('初始化HTTP示例失败:', error);
    } finally {
      this.isLoading = false;
    }
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
      this.isLoading = true;
      this.errorMessage = '';

      const info = await this.httpExample.start();

      if (info) {
        this.serverInfo = info;
        this.isRunning = true;
        this.successMessage = `🟢服务器启动成功！访问\n http://${info.address}:${info.port}`;
      } else {
        this.errorMessage = '服务器启动失败，未获取到地址';
      }
    } catch (error) {
      const businessError = error as BusinessError;
      this.errorMessage = `启动失败: ${businessError.message}`;
      console.error('启动服务器失败:', error);
    } finally {
      this.isLoading = false;
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
      this.isLoading = true;
      await this.httpExample.stop();

      this.isRunning = false;
      this.serverInfo = null;
      this.successMessage = '🛑 服务器已停止';

    } catch (error) {
      this.errorMessage = `停止服务器失败: ${error}`;
      console.error('停止服务器失败:', error);
    } finally {
      this.isLoading = false;
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

      // 如果服务器正在运行，需要重新初始化
      if (this.httpExample) {
        this.httpExample = null;
      }
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
        // 标题区域
        Text(this.title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })

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
        }

        if (this.successMessage) {
          Text(this.successMessage)
            .fontColor(Color.Green)
            .fontSize(14)
            .margin({ bottom: 10 })
            .padding(10)
            .backgroundColor('#e8f5e8')
            .borderRadius(8)
            .width('90%')
        }

        // 服务器状态区域
        if (this.isRunning && this.serverInfo) {
          Column({ space: 15 }) {
            // 运行状态
            Row() {
              Text('🟢')
                .fontSize(20)
              Text('服务器运行中')
                .fontColor(Color.Green)
                .fontWeight(FontWeight.Bold)
                .fontSize(18)
            }
            .justifyContent(FlexAlign.Center)

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
                Text('端口:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text(this.serverInfo.port.toString())
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

            // API端点信息
            Column({ space: 8 }) {
              Text('📋 主要API端点')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Text('• GET /api/users - 获取用户列表')
                .fontSize(12)
                .fontColor('#666')
              Text('• POST /api/users - 创建用户')
                .fontSize(12)
                .fontColor('#666')
              Text('• POST /api/upload - 文件上传')
                .fontSize(12)
                .fontColor('#666')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(15)
            .backgroundColor('#fff3e0')
            .borderRadius(10)
            .width('90%')

            // 停止按钮
            Button('停止服务器')
              .width('80%')
              .height(50)
              .backgroundColor(Color.Red)
              .enabled(!this.isLoading)
              .onClick(() => {
                this.clearMessages();
                this.stopServer();
              })

          }
          .width('100%')
          .margin({ bottom: 20 })

        } else {
          // 服务器未运行状态
          Column({ space: 20 }) {
            // 停止状态
            Row() {
              Text('🔴')
                .fontSize(20)
              Text('服务器已停止')
                .fontColor(Color.Red)
                .fontWeight(FontWeight.Bold)
                .fontSize(18)
            }
            .justifyContent(FlexAlign.Center)

            // 端口配置
            Column({ space: 10 }) {
              Text('服务器配置')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)

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
              .width('100%')
            }
            .padding(15)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .width('90%')

            // 功能说明
            Column({ space: 8 }) {
              Text('🚀 功能特性')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Text('✅ RESTful API (用户管理)')
                .fontSize(14)
                .fontColor('#666')
              Text('✅ 文件上传下载')
                .fontSize(14)
                .fontColor('#666')
              Text('✅ 静态文件服务')
                .fontSize(14)
                .fontColor('#666')
              Text('✅ 错误处理和日志')
                .fontSize(14)
                .fontColor('#666')
              Text('✅ CORS跨域支持')
                .fontSize(14)
                .fontColor('#666')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(15)
            .backgroundColor('#e3f2fd')
            .borderRadius(10)
            .width('90%')

            // 启动按钮
            Button(this.isLoading ? '启动中...' : '启动服务器')
              .width('80%')
              .height(50)
              .backgroundColor(this.isLoading ? Color.Gray : Color.Blue)
              .enabled(!this.isLoading)
              .onClick(() => {
                this.clearMessages();
                this.startServer();
              })
          }
          .width('100%')
        }

        // 加载指示器
        if (this.isLoading) {
          Row() {
            LoadingProgress()
              .width(30)
              .height(30)
              .margin({ right: 10 })
            Text('处理中...')
              .fontSize(14)
              .fontColor('#666')
          }
          .margin({ top: 20 })
        }

      }
      .width('100%')
      .height('100%')
      .padding({
        top: 20,
        left: 20,
        right: 20,
        bottom: 20
      })
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

export { httpBuilder }