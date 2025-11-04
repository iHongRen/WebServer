import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { ServerInfo } from '@cxy/webserver';

// import { CorsExample } from './CorsExample';

@Builder
function corsBuilder() {
  CorsPage()
}

@Component
struct CorsPage {
  build() {

  }

  // @State title: string = 'CORS示例'
  // @State corsExample: CorsExample | null = null;
  // @State serverInfo: ServerInfo | null = null;
  // @State port: number = 8083;
  // @State errorMessage: string = '';
  // @State successMessage: string = '';
  // @State corsRequestCount: number = 0;
  // @State allowAllOrigins: boolean = true;
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
  //  * 初始化CORS示例
  //  */
  // async initializeExample() {
  //   this.errorMessage = '';
  //   const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  //
  //   const corsOrigins = this.allowAllOrigins ? ['*'] : ['http://localhost:3000', 'http://127.0.0.1:3000'];
  //
  //   this.corsExample = new CorsExample(context, {
  //     port: this.port,
  //     enableLogging: true,
  //     corsOrigins: corsOrigins,
  //     corsMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  //     corsHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  //     corsCredentials: true
  //   });
  //   await this.corsExample.setupStaticFiles();
  // }
  //
  // /**
  //  * 启动服务器
  //  */
  // async startServer() {
  //   if (!this.corsExample) {
  //     await this.initializeExample();
  //   }
  //
  //   if (!this.corsExample) {
  //     this.errorMessage = 'CORS服务器初始化失败';
  //     return;
  //   }
  //
  //   try {
  //     this.errorMessage = '';
  //
  //     const info = await this.corsExample.start();
  //
  //     if (info) {
  //       this.serverInfo = info;
  //       this.successMessage = `🌐 CORS服务器运行中`;
  //       this.startStatsUpdate();
  //     } else {
  //       this.errorMessage = 'CORS服务器启动失败，未获取到地址';
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
  //   if (!this.corsExample) {
  //     return;
  //   }
  //
  //   try {
  //     await this.corsExample.stop();
  //
  //     this.corsExample = null;
  //     this.serverInfo = null;
  //     this.successMessage = '🌐 CORS服务器已停止';
  //     this.corsRequestCount = 0;
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
  //     if (this.corsExample) {
  //       this.corsRequestCount = this.corsExample.getCorsRequestCount();
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
  //               Text('🌐 CORS服务地址:')
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
  //               Text('演示页面:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(120)
  //               Text(`/cors-demo.html`)
  //                 .fontSize(14)
  //                 .fontColor(Color.Blue)
  //             }
  //             .width('100%')
  //             .justifyContent(FlexAlign.Start)
  //
  //             Row() {
  //               Text('CORS策略:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(120)
  //               Text(this.allowAllOrigins ? '允许所有来源 (*)' : '限制特定来源')
  //                 .fontSize(14)
  //                 .fontColor(this.allowAllOrigins ? Color.Orange : Color.Green)
  //             }
  //             .width('100%')
  //             .justifyContent(FlexAlign.Start)
  //           }
  //           .padding(15)
  //           .backgroundColor('#f0f8ff')
  //           .borderRadius(10)
  //           .width('90%')
  //
  //           // CORS统计
  //           Column({ space: 10 }) {
  //             Text('📊 CORS请求统计')
  //               .fontWeight(FontWeight.Bold)
  //               .fontSize(16)
  //               .margin({ bottom: 5 })
  //
  //             Row() {
  //               Text('请求次数:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(80)
  //               Text(this.corsRequestCount.toString())
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
  //           // CORS特性
  //           Column({ space: 8 }) {
  //             Text('🌐 CORS特性')
  //               .fontWeight(FontWeight.Bold)
  //               .fontSize(16)
  //               .margin({ bottom: 5 })
  //
  //             Text('✅ 跨域请求支持')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 预检请求处理')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 凭证请求支持')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 自定义头部支持')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 来源白名单控制')
  //               .fontSize(12)
  //               .fontColor('#666')
  //             Text('✅ 请求统计分析')
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
  //           Button('停止CORS服务器')
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
  //             Text('CORS服务器配置')
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
  //               Text('CORS策略:')
  //                 .fontWeight(FontWeight.Medium)
  //                 .width(80)
  //               Row() {
  //                 Radio({ value: 'all', group: 'corsPolicy' })
  //                   .checked(this.allowAllOrigins)
  //                   .onChange((isChecked) => {
  //                     if (isChecked) {
  //                       this.allowAllOrigins = true;
  //                     }
  //                   })
  //                 Text('允许所有来源')
  //                   .fontSize(14)
  //                   .margin({ left: 5, right: 15 })
  //
  //                 Radio({ value: 'restricted', group: 'corsPolicy' })
  //                   .checked(!this.allowAllOrigins)
  //                   .onChange((isChecked) => {
  //                     if (isChecked) {
  //                       this.allowAllOrigins = false;
  //                     }
  //                   })
  //                 Text('限制来源')
  //                   .fontSize(14)
  //                   .margin({ left: 5 })
  //               }
  //               .layoutWeight(1)
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
  //             Text('🌐 CORS功能')
  //               .fontWeight(FontWeight.Bold)
  //               .fontSize(16)
  //               .margin({ bottom: 5 })
  //
  //             Text('🔄 跨域资源共享')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('🛡️ 来源访问控制')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('🔍 预检请求处理')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('🔑 凭证请求支持')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('📋 自定义头部管理')
  //               .fontSize(14)
  //               .fontColor('#666')
  //             Text('📊 请求统计分析')
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
  //           Button('启动CORS服务器')
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

