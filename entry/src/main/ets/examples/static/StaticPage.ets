import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { ServerInfo } from '@cxy/webserver';

// import { StaticExample } from './StaticExample';

@Builder
function staticBuilder() {
  StaticPage()
}

@Component
struct StaticPage {
  build() {

  }

  // @State title: string = 'Static示例'
  // @State staticExample: StaticExample | null = null;
  // @State serverInfo: ServerInfo | null = null;
  // @State port: number = 8087;
  // @State errorMessage: string = '';
  // @State successMessage: string = '';
  // @State accessCount: number = 0;
  // @State enableCache: boolean = true;
  //
  // aboutToAppear() {
  //   setTimeout(() => {
  //     this.startServer();
  //   }, 0);
  // }
  //
  // aboutToDisappear() {
  //   this.stopServer();
  // }
  //
  // /**
  //  * 初始化Static示例
  //  */
  // async initializeExample() {
  //   this.errorMessage = '';
  //   const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  //   this.staticExample = new StaticExample(context, {
  //     port: this.port,
  //     enableLogging: true,
  //     enableCors: true,
  //     enableCache: this.enableCache,
  //     maxAge: 3600
  //   });
  //   await this.staticExample.setupStaticFiles();
  // }
  //
  // /**
  //  * 启动服务器
  //  */
  // async startServer() {
  //   if (!this.staticExample) {
  //     await this.initializeExample();
  //   }
  //
  //   if (!this.staticExample) {
  //     this.errorMessage = 'Static服务器初始化失败';
  //     return;
  //   }
  //
  //   try {
  //     this.errorMessage = '';
  //
  //     const info = await this.staticExample.start();
  //
  //     if (info) {
  //       this.serverInfo = info;
  //       this.successMessage = `📁 Static服务器运行中`;
  //       this.startStatsUpdate();
  //     } else {
  //       this.errorMessage = 'Static服务器启动失败，未获取到地址';
  //     }
  //   } catch (error) {
  //     const businessError = error as BusinessError;
  //     this.errorMessage = `启动失败: ${businessError.message}`;
  //   }
  // }
  //
  // /**
  //  * 停止服务器
  //  */
  // async stopServer() {
  //   if (!this.staticExample) {
  //     return;
  //   }
  //
  //   try {
  //     await this.staticExample.stop();
  //
  //     this.staticExample = null;
  //     this.serverInfo = null;
  //     this.successMessage = '📁 Static服务器已停止';
  //     this.accessCount = 0;
  //
  //   } catch (error) {
  //     this.errorMessage = `停止服务器失败: ${error}`;
  //   }
  // }
  //
  // /**
  //  * 启动统计数据更新
  //  */
  // startStatsUpdate() {
  //   const updateStats = () => {
  //     if (this.staticExample) {
  //       this.accessCount = this.staticExample.getAccessCount();
  //     }
  //   };
  //
  //   updateStats();
  //   setInterval(updateStats, 3000);
  // }
  //
  // /**
  //  * 更新端口号
  //  */
  // updatePort(newPort: string) {
  //   const portNum = parseInt(newPort);
  //   if (portNum > 0 && portNum <= 65535) {
  //     this.port = portNum;
  //     this.errorMessage = '';
  //   } else {
  //     this.errorMessage = '端口号必须在1-65535之间';
  //   }
  // }
  //
  // /**
  //  * 清除消息
  //  */
  // clearMessages() {
  //   this.errorMessage = '';
  //   this.successMessage = '';
  // }
  //
  // build() {
  //   NavDestination() {
  //     Column() {
  //       // 消息显示区域
  //       if (this.errorMessage) {
  //         Text(this.errorMessage)
  //           .fontColor(Color.Red)
  //           .fontSize(14)
  //           .margin({ bottom: 10 })
  //           .padding(10)
  //           .backgroundColor('#ffebee')
  //           .borderRadius(8)
  //           .width('90%')
  //           .textAlign(TextAlign.Center)
  //       } else if (this.successMessage) {
  //         Text(this.successMessage)
  //           .fontColor(Color.Green)
  //           .fontSize(14)
  //           .margin({ bottom: 10 })
  //           .padding(10)
  //           .backgroundColor('#e8f5e8')
  //           .borderRadius(8)
  //           .width('90%')
  //           .textAlign(TextAlign.Center)
  //       }
  //
  //       // 服务器状态区域
  //       if (this.serverInfo) {
  //         Column({ space: 15 }) {
  //           // 服务器信息卡片
  //           Column({ space: 10 }) {
  //             Row() {
  //               Text('📁 Static服务地址:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(120)
  //               Text(`http://${this.serverInfo.address}:${this.serverInfo.port}`)
  //                 .fontColor(Color.Blue)
  //                 .fontSize(16)
  //             }
  //             .width('100%')
  //             .justifyContent(FlexAlign.Start)
  //
  //             Row() {
  //               Text('静态目录:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(120)
  //               Text(this.staticExample?.getConfig().staticRoot || '')
  //                 .fontSize(12)
  //                 .fontColor(Color.Gray)
  //                 .maxLines(1)
  //                 .textOverflow({ overflow: TextOverflow.Ellipsis })
  //             }
  //             .width('100%')
  //             .justifyContent(FlexAlign.Start)
  //
  //             Row() {
  //               Text('缓存状态:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(120)
  //               Text(this.enableCache ? '已启用' : '已禁用')
  //                 .fontSize(14)
  //                 .fontColor(this.enableCache ? Color.Green : Color.Orange)
  //             }
  //             .width('100%')
  //             .justifyContent(FlexAlign.Start)
  //           }
  //           .padding(15)
  //           .backgroundColor('#f0f8ff')
  //           .borderRadius(10)
  //           .width('90%')
  //
  //           // 访问统计
  //           Column({ space: 10 }) {
  //             Text('📊 访问统计')
  //               .fontWeight(FontWeight.Bold)
  //               .fontSize(16)
  //
  //             Row() {
  //               Text('文件访问次数:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(120)
  //               Text(this.accessCount.toString())
  //                 .fontColor(Color.Blue)
  //             }
  //             .width('100%')
  //             .justifyContent(FlexAlign.Start)
  //           }
  //           .padding(15)
  //           .backgroundColor('#f9f9f9')
  //           .borderRadius(10)
  //           .width('90%')
  //
  //           // 停止按钮
  //           Button('停止服务器')
  //             .width('80%')
  //             .height(50)
  //             .backgroundColor(Color.Red)
  //             .onClick(() => {
  //               this.clearMessages();
  //               this.stopServer();
  //             })
  //
  //         }
  //         .width('100%')
  //
  //       } else {
  //         // 服务器未运行状态
  //         Column({ space: 20 }) {
  //           Row() {
  //             Text('端口号:')
  //               .fontWeight(FontWeight.Medium)
  //               .width(80)
  //             TextInput({
  //               text: this.port.toString(),
  //               placeholder: '请输入端口号 (1-65535)'
  //             })
  //               .type(InputType.Number)
  //               .layoutWeight(1)
  //               .height(40)
  //               .onChange((value) => {
  //                 this.updatePort(value);
  //               })
  //           }
  //           .padding(15)
  //           .backgroundColor('#f5f5f5')
  //           .borderRadius(10)
  //           .width('90%')
  //
  //           // 缓存配置
  //           Row() {
  //             Text('启用缓存:')
  //               .fontWeight(FontWeight.Medium)
  //               .width(80)
  //             Toggle({ type: ToggleType.Switch, isOn: this.enableCache })
  //               .onChange((isOn) => {
  //                 this.enableCache = isOn;
  //               })
  //           }
  //           .padding(15)
  //           .backgroundColor('#f5f5f5')
  //           .borderRadius(10)
  //           .width('90%')
  //
  //           // 启动按钮
  //           Button('启动服务器')
  //             .width('80%')
  //             .height(50)
  //             .backgroundColor(Color.Blue)
  //             .onClick(() => {
  //               this.clearMessages();
  //               this.startServer();
  //             })
  //         }
  //         .width('100%')
  //       }
  //     }
  //     .width('100%')
  //     .height('100%')
  //     .padding(20)
  //     .justifyContent(FlexAlign.Start)
  //   }
  //   .title(this.title)
  //   .onReady((ctx) => {
  //     if (ctx.pathInfo.param) {
  //       this.title = ctx.pathInfo.param as string;
  //     }
  //   })
  // }
}

