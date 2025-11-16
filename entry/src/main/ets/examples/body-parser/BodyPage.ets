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
  @State bodyParserExample: BodyParserExample = new BodyParserExample()
  @State serverInfo: ServerInfo | null = null;
  @State port: number = 8082;
  @State errorMessage: string = '';
  @State successMessage: string = '';

  aboutToAppear() {
    this.startServer();
  }

  aboutToDisappear() {
    this.stopServer();
  }

  /**
   * 启动服务器
   */
  async startServer() {

    this.errorMessage = '';

    const info = await this.bodyParserExample.start(this.port);

    if (info) {
      this.serverInfo = info;
      this.successMessage = `服务器运行中`;
    } else {
      this.errorMessage = '服务器启动失败，未获取到地址';
    }
  }

  /**
   * 停止服务器
   */
  async stopServer() {
    await this.bodyParserExample.stop();
    this.serverInfo = null;
    this.successMessage = '服务器已停止';
  }

  /**
   * 更新端口号
   */
  updatePort(newPort: string) {
    const portNum = parseInt(newPort);
    this.port = portNum;
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
                Text('服务地址:')
                  .fontWeight(FontWeight.Medium)
                  .width(80)
                Text(`http://${this.serverInfo.address}:${this.serverInfo.port}`)
                  .fontColor(Color.Blue)
                  .fontSize(16)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)

            }
            .padding(15)
            .backgroundColor('#f0f8ff')
            .borderRadius(10)
            .width('90%')


            // 解析器类型
            Column({ space: 8 }) {
              Text('支持的解析器')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Text('json: application/json')
                .fontSize(12)
                .fontColor('#666')
              Text('urlencoded: application/x-www-form-urlencoded')
                .fontSize(12)
                .fontColor('#666')
              Text('multipart: multipart/form-data (文件上传)')
                .fontSize(12)
                .fontColor('#666')
              Text('plain: text/plain')
                .fontSize(12)
                .fontColor('#666')
              Text('auto: 根据 Content-Type 自动识别')
                .fontSize(12)
                .fontColor('#666')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(15)
            .backgroundColor('#fff3e0')
            .borderRadius(10)
            .width('90%')

            // 新增：测试命令区域
            Column({ space: 8 }) {
              Text('如何测试')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              Text('在终端中运行以下命令:')
                .fontSize(12)
                .fontColor('#333')

              Text('sh ./test-body-parser.sh')
                .fontSize(12)
                .padding(10)
                .backgroundColor('#eee')
                .borderRadius(5)
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(15)
            .backgroundColor('#e0f7fa')
            .borderRadius(10)
            .width('90%')


            // 停止按钮
            Button('停止服务器')
              .width('80%')
              .height(50)
              .backgroundColor(Color.Red)
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
              Text('Body Parser功能')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .margin({ bottom: 5 })

              ForEach(['JSON数据解析', '表单数据解析', '多部分表单解析', '纯文本解析', '自动解析'], (item: string) => {
                Text(item)
                  .fontSize(14)
                  .fontColor('#666')
              })
            }
            .alignItems(HorizontalAlign.Start)
            .padding(15)
            .backgroundColor('#e3f2fd')
            .borderRadius(10)
            .width('90%')

            // 启动按钮
            Button('启动服务器')
              .enabled(this.port > 0)
              .width('80%')
              .height(50)
              .backgroundColor(Color.Blue)
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

