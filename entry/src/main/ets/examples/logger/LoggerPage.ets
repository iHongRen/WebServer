import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { ServerInfo } from '@cxy/webserver';

// import { LoggerExample } from './LoggerExample';

@Builder
function loggerBuilder() {
  LoggerPage()
}

@Component
struct LoggerPage {
  build() {

  }

  // @State title: string = 'Logger示例'
  // @State loggerExample: LoggerExample | null = null;
  // @State serverInfo: ServerInfo | null = null;
  // @State port: number = 8085;
  // @State errorMessage: string = '';
  // @State successMessage: string = '';
  // @State logCount: number = 0;
  // @State logFormat: string = 'dev';
  // @State logLevel: string = 'info';
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
  //  * 初始化Logger示例
  //  */
  // async initializeExample() {
  //   this.errorMessage = '';
  //   const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  //   this.loggerExample = new LoggerExample(context, {
  //     port: this.port,
  //     enableCors: true,
  //     logFormat: this.logFormat as ESObject,
  //     logLevel: this.logLevel as ESObject,
  //     logToFile: true
  //   });
  //   await this.loggerExample.setupStaticFiles();
  // }
  //
  // /**
  //  * 启动服务器
  //  */
  // async startServer() {
  //   if (!this.loggerExample) {
  //     await this.initializeExample();
  //   }
  //
  //   if (!this.loggerExample) {
  //     this.errorMessage = 'Logger服务器初始化失败';
  //     return;
  //   }
  //
  //   try {
  //     this.errorMessage = '';
  //
  //     const info = await this.loggerExample.start();
  //
  //     if (info) {
  //       this.serverInfo = info;
  //       this.successMessage = `📝 Logger服务器运行中`;
  //       this.startStatsUpdate();
  //     } else {
  //       this.errorMessage = 'Logger服务器启动失败，未获取到地址';
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
  //   if (!this.loggerExample) {
  //     return;
  //   }
  //
  //   try {
  //     await this.loggerExample.stop();
  //
  //     this.loggerExample = null;
  //     this.serverInfo = null;
  //     this.successMessage = '📝 Logger服务器已停止';
  //     this.logCount = 0;
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
  //     if (this.loggerExample) {
  //       this.logCount = this.loggerExample.getLogCount();
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
  //               Text('📝 Logger服务地址:')
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
  //               Text('日志格式:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(120)
  //               Text(this.logFormat.toUpperCase())
  //                 .fontSize(14)
  //                 .fontColor(Color.Green)
  //             }
  //             .width('100%')
  //             .justifyContent(FlexAlign.Start)
  //
  //             Row() {
  //               Text('日志级别:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(120)
  //               Text(this.logLevel.toUpperCase())
  //                 .fontSize(14)
  //                 .fontColor(Color.Orange)
  //             }
  //             .width('100%')
  //             .justifyContent(FlexAlign.Start)
  //           }
  //           .padding(15)
  //           .backgroundColor('#f0f8ff')
  //           .borderRadius(10)
  //           .width('90%')
  //
  //           // 日志统计
  //           Column({ space: 10 }) {
  //             Text('📊 日志统计')
  //               .fontWeight(FontWeight.Bold)
  //               .fontSize(16)
  //               .margin({ bottom: 5 })
  //
  //             Row() {
  //               Text('日志条数:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(80)
  //               Text(this.logCount.toString())
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
  //           // 日志特性
  //           Column({ space: 8 }) {
  //             Text('📝 Logger特性')
  //               .fontWeight(FontWeight.Bold)
  //               .fontSize(16)
  //               .margin({ bottom: 5 })
  //
  //             Text('✅ 多格式日志记录')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 日志级别控制')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 文件日志存储')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 日志统计分析')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 实时日志查看')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 动态配置管理')
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
  //           Button('停止Logger服务器')
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
  //           Column({ space: 15 }) {
  //             Text('Logger服务器配置')
  //               .fontWeight(FontWeight.Bold)
  //               .fontSize(16)
  //
  //             Row() {
  //               Text('端口号:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(80)
  //               TextInput({
  //                 text: this.port.toString(),
  //                 placeholder: '请输入端口号 (1-65535)'
  //               })
  //                 .type(InputType.Number)
  //                 .layoutWeight(1)
  //                 .height(40)
  //                 .onChange((value) => {
  //                   this.updatePort(value);
  //                 })
  //             }
  //             .width('100%')
  //
  //             Row() {
  //               Text('日志格式:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(80)
  //               Select([
  //                 { value: 'dev' },
  //                 { value: 'combined' },
  //                 { value: 'common' },
  //                 { value: 'short' },
  //                 { value: 'tiny' }
  //               ])
  //                 .selected(0)
  //                 .value(this.logFormat)
  //                 .onSelect((index: number, value?: string) => {
  //                   if (value) {
  //                     this.logFormat = value;
  //                   }
  //                 })
  //                 .layoutWeight(1)
  //                 .height(40)
  //             }
  //             .width('100%')
  //
  //             Row() {
  //               Text('日志级别:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(80)
  //               Select([
  //                 { value: 'debug' },
  //                 { value: 'info' },
  //                 { value: 'warn', },
  //                 { value: 'error' }
  //               ])
  //                 .selected(1)
  //                 .value(this.logLevel)
  //                 .onSelect((index: number, value?: string) => {
  //                   if (value) {
  //                     this.logLevel = value;
  //                   }
  //                 })
  //                 .layoutWeight(1)
  //                 .height(40)
  //             }
  //             .width('100%')
  //           }
  //           .padding(15)
  //           .backgroundColor('#f5f5f5')
  //           .borderRadius(10)
  //           .width('90%')
  //
  //           // 功能说明
  //           Column({ space: 8 }) {
  //             Text('📝 Logger功能')
  //               .fontWeight(FontWeight.Bold)
  //               .fontSize(16)
  //               .margin({ bottom: 5 })
  //
  //             Text('📊 多格式日志记录')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('🔍 日志级别过滤')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('💾 文件日志存储')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('📈 日志统计分析')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('⚙️ 动态配置管理')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('🧪 日志测试工具')
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
  //           Button('启动Logger服务器')
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

