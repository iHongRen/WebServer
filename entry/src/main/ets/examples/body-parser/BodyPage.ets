/**
 * @fileName : BodyPage.ets
 * @author : @cxy
 * @date : 2025/11/2
 * @description : Body Parser示例 - 展示各种请求体解析功能
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { ServerInfo } from '@cxy/webserver';
import { BodyParserExample } from './BodyParserExample';

@Builder
function bodyBuilder() {
  BodyPage()
}

@Component
struct BodyPage {
  @State title: string = 'Body Parser示例'
  @State bodyParserExample: BodyParserExample | null = null;
  @State serverInfo: ServerInfo | null = null;
  @State port: number = 8082;
  @State errorMessage: string = '';
  @State successMessage: string = '';
  @State parseResultCount: number = 0;

  aboutToAppear() {
    setTimeout(() => {
      this.startServer();
    }, 0);
  }

  aboutToDisappear() {
    this.stopServer();
  }

  /**
   * 初始化Body Parser示例
   */
  async initializeExample() {
    this.errorMessage = '';
    this.bodyParserExample = new BodyParserExample();
  }

  /**
   * 启动服务器
   */
  async startServer() {
    if (!this.bodyParserExample) {
      await this.initializeExample();
    }

    if (!this.bodyParserExample) {
      this.errorMessage = 'Body Parser服务器初始化失败';
      return;
    }

    try {
      this.errorMessage = '';

      const info = await this.bodyParserExample.start(this.port);

      if (info) {
        this.serverInfo = info;
        this.successMessage = `🔧 Body Parser服务器运行中`;
        this.startStatsUpdate();
      } else {
        this.errorMessage = 'Body Parser服务器启动失败，未获取到地址';
      }
    } catch (error) {
      const businessError = error as BusinessError;
      this.errorMessage = `启动失败: ${businessError.message}`;
    }
  }

  /**
   * 停止服务器
   */
  async stopServer() {
    if (!this.bodyParserExample) {
      return;
    }

    try {
      await this.bodyParserExample.stop();

      this.bodyParserExample = null;
      this.serverInfo = null;
      this.successMessage = '🔧 Body Parser服务器已停止';
      this.parseResultCount = 0;

    } catch (error) {
      this.errorMessage = `停止服务器失败: ${error}`;
    }
  }

  /**
   * 启动统计数据更新
   */
  startStatsUpdate() {
    const updateStats = () => {
      if (this.bodyParserExample) {
        this.parseResultCount = this.bodyParserExample.getParseResultCount();
      }
    };

    updateStats();
    setInterval(updateStats, 3000);
  }

  /**
   * 更新端口号
   */
  updatePort(newPort: string) {
    const portNum = parseInt(newPort);
    if (portNum > 0 && portNum <= 65535) {
      this.port = portNum;
      this.errorMessage = '';
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
            .textAlign(TextAlign.Center)
        } else if (this.successMessage) {
          Text(this.successMessage)
            .fontColor(Color.Green)
            .fontSize(14)
            .margin({ bottom: 10 })
            .padding(10)
            .backgroundColor('#e8f5e8')
            .borderRadius(8)
            .width('90%')
            .textAlign(TextAlign.Center)
        }

        // 服务器状态区域
        if (this.serverInfo) {
          Column({ space: 15 }) {
            // 服务器信息卡片
            Column({ space: 10 }) {
              Row() {
                Text('🔧 服务地址:')
                  .fontWeight(FontWeight.Medium)
                  .width(100)
                Text(`http://${this.serverInfo.address}:${this.serverInfo.port}`)
                  .fontColor(Color.Blue)
                  .fontSize(16)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)

              Row() {
                Text('演示页面:')
                  .fontWeight(FontWeight.Medium)
                  .width(100)
                Text(`/body-parser-demo.html`)
                  .fontSize(14)
                  .fontColor(Color.Blue)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .padding(15)
            .backgroundColor('#f0f8ff')
            .borderRadius(10)
            .width('90%')

            // 解析统计
            Column({ space: 10 }) {
              Text('📊 解析统计')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Row() {
                Text('解析次数:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text(this.parseResultCount.toString())
                  .fontSize(16)
                  .fontColor(Color.Blue)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .padding(15)
            .backgroundColor('#f0fff0')
            .borderRadius(10)
            .width('90%')

            // 解析器类型
            Column({ space: 8 }) {
              Text('🔧 支持的解析器')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Text('✅ JSON Parser (application/json)')
                .fontSize(12)
                .fontColor('#666')
              Text('✅ URL-Encoded Parser (form data)')
                .fontSize(12)
                .fontColor('#666')
              Text('✅ Multipart Parser (file upload)')
                .fontSize(12)
                .fontColor('#666')
              Text('✅ Plain Text Parser (text/plain)')
                .fontSize(12)
                .fontColor('#666')
              Text('✅ Auto Parser (智能识别)')
                .fontSize(12)
                .fontColor('#666')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(15)
            .backgroundColor('#fff3e0')
            .borderRadius(10)
            .width('90%')

            // 停止按钮
            Button('停止Body Parser服务器')
              .width('80%')
              .height(50)
              .backgroundColor('#d32f2f')
              .onClick(() => {
                this.clearMessages();
                this.stopServer();
              })
          }
          .width('100%')

        } else {
          // 服务器未运行状态
          Column({ space: 20 }) {
            // 配置区域
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
            .padding(15)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .width('90%')

            // 功能说明
            Column({ space: 8 }) {
              Text('🔧 Body Parser功能')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Text('📝 JSON数据解析')
                .fontSize(14)
                .fontColor('#666')
              Text('📋 表单数据解析')
                .fontSize(14)
                .fontColor('#666')
              Text('📁 文件上传解析')
                .fontSize(14)
                .fontColor('#666')
              Text('📄 纯文本解析')
                .fontSize(14)
                .fontColor('#666')
              Text('🤖 智能自动解析')
                .fontSize(14)
                .fontColor('#666')
              Text('📊 解析结果统计')
                .fontSize(14)
                .fontColor('#666')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(15)
            .backgroundColor('#e3f2fd')
            .borderRadius(10)
            .width('90%')

            // 启动按钮
            Button('启动Body Parser服务器')
              .width('80%')
              .height(50)
              .backgroundColor('#1976d2')
              .onClick(() => {
                this.clearMessages();
                this.startServer();
              })
          }
          .width('100%')
        }
      }
      .width('100%')
      .height('100%')
      .padding(20)
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

