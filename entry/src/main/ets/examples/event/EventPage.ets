import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { ServerInfo } from '@cxy/webserver';

// import { EventExample } from './EventExample';

@Builder
function eventBuilder() {
  EventPage()
}

@Component
struct EventPage {
  build() {

  }

  // @State title: string = 'Event示例'
  // @State eventExample: EventExample | null = null;
  // @State serverInfo: ServerInfo | null = null;
  // @State port: number = 8084;
  // @State errorMessage: string = '';
  // @State successMessage: string = '';
  // @State eventCount: number = 0;
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
  //  * 初始化Event示例
  //  */
  // async initializeExample() {
  //   this.errorMessage = '';
  //   const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  //   this.eventExample = new EventExample(context, {
  //     port: this.port,
  //     enableLogging: true,
  //     enableCors: true,
  //     eventHistoryLimit: 1000
  //   });
  //   await this.eventExample.setupStaticFiles();
  // }
  //
  // /**
  //  * 启动服务器
  //  */
  // async startServer() {
  //   if (!this.eventExample) {
  //     await this.initializeExample();
  //   }
  //
  //   if (!this.eventExample) {
  //     this.errorMessage = 'Event服务器初始化失败';
  //     return;
  //   }
  //
  //   try {
  //     this.errorMessage = '';
  //
  //     const info = await this.eventExample.start();
  //
  //     if (info) {
  //       this.serverInfo = info;
  //       this.successMessage = `📡 Event服务器运行中`;
  //       this.startStatsUpdate();
  //     } else {
  //       this.errorMessage = 'Event服务器启动失败，未获取到地址';
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
  //   if (!this.eventExample) {
  //     return;
  //   }
  //
  //   try {
  //     await this.eventExample.stop();
  //
  //     this.eventExample = null;
  //     this.serverInfo = null;
  //     this.successMessage = '📡 Event服务器已停止';
  //     this.eventCount = 0;
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
  //     if (this.eventExample) {
  //       this.eventCount = this.eventExample.getEventCount();
  //     }
  //   };
  //
  //   updateStats();
  //   setInterval(updateStats, 2000);
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
  //               Text('📡 Event服务地址:')
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
  //               Text('监控页面:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(120)
  //               Text(`/event-monitor.html`)
  //                 .fontSize(14)
  //                 .fontColor(Color.Blue)
  //             }
  //             .width('100%')
  //             .justifyContent(FlexAlign.Start)
  //           }
  //           .padding(15)
  //           .backgroundColor('#f0f8ff')
  //           .borderRadius(10)
  //           .width('90%')
  //
  //           // 事件统计
  //           Column({ space: 10 }) {
  //             Text('📊 事件统计')
  //               .fontWeight(FontWeight.Bold)
  //               .fontSize(16)
  //               .margin({ bottom: 5 })
  //
  //             Row() {
  //               Text('事件总数:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(80)
  //               Text(this.eventCount.toString())
  //                 .fontSize(16)
  //                 .fontColor(Color.Blue)
  //             }
  //             .width('100%')
  //             .justifyContent(FlexAlign.Start)
  //           }
  //           .padding(15)
  //           .backgroundColor('#f0fff0')
  //           .borderRadius(10)
  //           .width('90%')
  //
  //           // 事件系统特性
  //           Column({ space: 8 }) {
  //             Text('📡 事件系统特性')
  //               .fontWeight(FontWeight.Bold)
  //               .fontSize(16)
  //               .margin({ bottom: 5 })
  //
  //             Text('✅ 服务器事件监听')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 错误事件捕获')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 客户端连接事件')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 自定义事件触发')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 事件历史记录')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 实时事件监控')
  //               .fontSize(12)
  //               .fontColor('#666')
  //           }
  //           .alignItems(HorizontalAlign.Start)
  //           .padding(15)
  //           .backgroundColor('#fff3e0')
  //           .borderRadius(10)
  //           .width('90%')
  //
  //           // 停止按钮
  //           Button('停止Event服务器')
  //             .width('80%')
  //             .height(50)
  //             .backgroundColor('#d32f2f')
  //             .onClick(() => {
  //               this.clearMessages();
  //               this.stopServer();
  //             })
  //         }
  //         .width('100%')
  //
  //       } else {
  //         // 服务器未运行状态
  //         Column({ space: 20 }) {
  //           // 配置区域
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
  //           // 功能说明
  //           Column({ space: 8 }) {
  //             Text('📡 Event系统功能')
  //               .fontWeight(FontWeight.Bold)
  //               .fontSize(16)
  //               .margin({ bottom: 5 })
  //
  //             Text('🎯 事件监听和触发')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('📊 事件统计分析')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('🔍 实时事件监控')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('📝 事件历史记录')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('⚠️ 错误事件捕获')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('🔗 客户端连接跟踪')
  //               .fontSize(14)
  //               .fontColor('#666')
  //           }
  //           .alignItems(HorizontalAlign.Start)
  //           .padding(15)
  //           .backgroundColor('#e3f2fd')
  //           .borderRadius(10)
  //           .width('90%')
  //
  //           // 启动按钮
  //           Button('启动Event服务器')
  //             .width('80%')
  //             .height(50)
  //             .backgroundColor('#1976d2')
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

