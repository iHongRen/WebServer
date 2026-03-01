/**
 * @fileName : UploadPage.ets
 * @author : @cxy
 * @date : 2025/12/31
 * @description : 分片上传示例页面
 */

import { common } from '@kit.AbilityKit';
import { UploadExample } from './UploadExample';

@Builder
function uploadBuilder() {
  UploadPage()
}

@Entry
@Component
struct UploadPage {
  @State title: string = '分片上传示例页面'
  @State serverStatus: string = '未启动';
  @State serverInfo: string = '';
  @State port: number = 8088;
  @State isRunning: boolean = false;
  private uploadExample: UploadExample = new UploadExample();

  aboutToAppear(): void {
    this.uploadExample.init(getContext(this) as common.UIAbilityContext);
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

            Text('本示例展示WebServer框架的大文件分片上传功能，支持断点续传和并发上传。')
              .fontSize(14)
              .fontColor('#666')

            Divider()

            Text('支持的上传功能：')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Column({ space: 8 }) {
              this.featureItem('📦', '分片上传', '将大文件分割成小块上传')
              this.featureItem('🔄', '断点续传', '支持上传中断后继续')
              this.featureItem('⚡', '并发上传', '多个分片同时上传')
              this.featureItem('✅', '完整性校验', 'MD5校验确保数据完整')
              this.featureItem('📊', '进度跟踪', '实时上传进度监控')
              this.featureItem('🗂️', '任务管理', '查看和管理上传任务')
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
              this.apiItem('POST', '/api/upload/check', '检查上传状态')
              this.apiItem('POST', '/api/upload/chunk', '上传分片')
              this.apiItem('POST', '/api/upload/merge', '合并分片')
              this.apiItem('GET', '/api/upload/tasks', '查看上传任务')
              this.apiItem('GET', '/api/upload/files', '查看已上传文件')
              this.apiItem('DELETE', '/api/upload/task/:hash', '删除上传任务')
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

            Text('使用curl命令测试分片上传：')
              .fontSize(14)
              .fontColor('#666')

            Text('# 检查上传状态\ncurl -X POST http://IP:8088/api/upload/check \\\n  -H "Content-Type: application/json" \\\n  -d \'{"hash":"file-hash","fileName":"test.zip"}\'')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('# 上传分片\ncurl -X POST http://IP:8088/api/upload/chunk \\\n  -F "hash=file-hash" \\\n  -F "chunkIndex=0" \\\n  -F "chunk=@chunk-0.bin"')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('详细测试脚本请查看: test-upload.sh')
              .fontSize(12)
              .fontColor('#999')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // Web界面说明
          Column({ space: 12 }) {
            Text('Web测试界面')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text('访问Web界面进行可视化测试：')
              .fontSize(14)
              .fontColor('#666')

            Text('http://IP:8088/chunk-upload.html')
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor(Color.Blue)
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')

            Text('Web界面提供拖拽上传、进度显示、断点续传等功能')
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
      const info = await this.uploadExample.start(this.port);
      if (info) {
        this.isRunning = true;
        this.serverStatus = '运行中';
        this.serverInfo = `服务器地址: http://${info.address}:${info.port}\nWeb界面: http://${info.address}:${info.port}/chunk-upload.html`;
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
      await this.uploadExample.stop();
      this.isRunning = false;
      this.serverStatus = '已停止';
      this.serverInfo = '';
    } catch (error) {
      this.serverInfo = `停止失败: ${error.message}`;
    }
  }
}
