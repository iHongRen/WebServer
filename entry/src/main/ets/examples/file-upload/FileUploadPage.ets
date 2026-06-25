/**
 * @fileName : FileUploadPage.ets
 * @author : @cxy
 * @date : 2025/3/3
 * @description : 文件上传完整示例页面
 */

import { FileUploadExample } from './FileUploadExample';
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';

@Builder
function fileUploadBuilder() {
  FileUploadPage()
}

@Entry
@Component
struct FileUploadPage {
  @State title: string = '文件上传示例'
  @State serverStatus: string = '未启动';
  @State serverInfo: string = '';
  @State port: number = 8080;
  @State isRunning: boolean = false;
  private example: FileUploadExample = new FileUploadExample();
  private serverAddress: socket.NetAddress | null = null;

  aboutToAppear() {
    this.example.init(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  async aboutToDisappear() {
    if (this.isRunning) {
      await this.stopServer();
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {

          // 服务器控制
          Column({ space: 12 }) {
            Text('服务器控制')
              .fontSize(18).fontWeight(FontWeight.Bold)
            Row({ space: 12 }) {
              Text('端口:').fontSize(16)
              TextInput({ text: this.port.toString() })
                .width(100).type(InputType.Number).enabled(!this.isRunning)
                .onChange((v: string) => {
                  const p = parseInt(v);
                  if (!isNaN(p) && p > 0 && p < 65536) {
                    this.port = p;
                  }
                })
            }
            Row({ space: 12 }) {
              Button(this.isRunning ? '停止服务器' : '启动服务器')
                .type(ButtonType.Capsule).width(120).borderRadius(8)
                .backgroundColor(this.isRunning ? Color.Red : Color.Blue)
                .onClick(async () => {
                  if (this.isRunning) {
                    await this.stopServer();
                  } else {
                    await this.startServer();
                  }
                })
              Text(this.serverStatus).fontSize(14)
                .fontColor(this.isRunning ? '#4CAF50' : '#999')
            }
            if (this.serverInfo) {
              Text(this.serverInfo).fontSize(12).fontColor('#666')
                .padding(12).backgroundColor('#F5F5F5').borderRadius(8).width('100%')
            }
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)

          // 一、FileUpload 中间件
          Column({ space: 10 }) {
            Text('一、FileUpload 中间件').fontSize(16).fontWeight(FontWeight.Bold)
            Text('适合中小文件（< 100 MB），整体进内存后处理，支持 multipart/form-data 和多文件。')
              .fontSize(13).fontColor('#666')
            this.apiItem('POST', '/api/upload/basic', '基本上传（multipart/form-data）')
            this.apiItem('POST', '/api/upload/multiple', '多文件上传')
            this.apiItem('POST', '/api/upload/safe', '安全文件名上传')
            this.apiItem('POST', '/api/upload/limited', '限制大小上传')
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)

          // 二、流式上传
          Column({ space: 10 }) {
            Text('二、流式上传').fontSize(16).fontWeight(FontWeight.Bold)
            Text('适合 GB 级大文件。使用 server.stream() 注册，header 到达后立即触发路由，body 逐 TCP 包推送写盘，内存占用固定在单个包大小（~64 KB）。')
              .fontSize(13).fontColor('#666')
            this.apiItem('POST', '/api/upload/stream', '流式上传写磁盘（携带 X-File-Name 头）')
            Text('curl -X POST http://IP:8080/api/upload/stream \\\n     -H "X-File-Name: test.bin" -H "Expect:" \\\n     -H "Content-Type: application/octet-stream" \\\n     -T /path/to/large/file')
              .fontSize(11).fontFamily('monospace').fontColor('#333')
              .padding(10).backgroundColor('#F5F5F5').borderRadius(6).width('100%')
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)

          // 三、分片上传
          Column({ space: 10 }) {
            Text('三、分片上传（断点续传）').fontSize(16).fontWeight(FontWeight.Bold)
            Text('适合超大文件和弱网环境。客户端将文件分割后逐片上传，支持断点续传，最后合并为完整文件。')
              .fontSize(13).fontColor('#666')
            this.apiItem('POST', '/api/upload/chunk/check', '查询已上传分片（断点续传）')
            this.apiItem('POST', '/api/upload/chunk/upload', '上传单个分片')
            this.apiItem('POST', '/api/upload/chunk/merge', '合并所有分片')
            this.apiItem('GET', '/api/upload/chunk/tasks', '查看上传任务列表')
            this.apiItem('DELETE', '/api/upload/chunk/cancel/:hash', '取消上传任务')
            Text('Web 测试界面: http://IP:8080/chunk-upload.html')
              .fontSize(12).fontColor('#2196F3').padding(8)
              .backgroundColor('#F5F5F5').borderRadius(6).width('100%')
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)

          // 管理接口
          Column({ space: 10 }) {
            Text('文件管理').fontSize(16).fontWeight(FontWeight.Bold)
            this.apiItem('GET', '/api/upload/files', '查看所有已上传文件')
            this.apiItem('DELETE', '/api/upload/files/:filename', '删除文件')
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)

        }
        .padding(16)
      }
      .layoutWeight(1).backgroundColor('#F5F5F5').align(Alignment.TopStart)
    }
    .title(this.title)
    .onReady((ctx) => {
      if (ctx.pathInfo.param) {
        this.title = ctx.pathInfo.param as string;
      }
    })
  }

  @Builder
  apiItem(method: string, path: string, description: string) {
    Row({ space: 10 }) {
      Text(method)
        .fontSize(11).fontColor(Color.White)
        .padding({ left: 6, right: 6, top: 3, bottom: 3 })
        .backgroundColor(
          method === 'GET' ? '#4CAF50' :
          method === 'POST' ? '#2196F3' :
          method === 'DELETE' ? '#F44336' : '#FF9800'
        )
        .borderRadius(4)
      Column({ space: 2 }) {
        Text(path).fontSize(12).fontFamily('monospace').fontWeight(FontWeight.Medium)
        Text(description).fontSize(11).fontColor('#999')
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%').padding(8).backgroundColor('#F9F9F9').borderRadius(6)
  }

  private async startServer() {
    try {
      this.serverStatus = '启动中...';
      const info = await this.example.start(this.port);
      if (info) {
        this.isRunning = true;
        this.serverStatus = '运行中';
        this.serverInfo = `地址: http://${info.address}:${info.port}`;
        this.serverAddress = info;
      } else {
        this.serverStatus = '启动失败';
        this.serverInfo = '请检查端口是否被占用';
      }
    } catch (error) {
      this.serverStatus = '启动失败';
      this.serverInfo = `错误: ${(error as Error).message}`;
    }
  }

  private async stopServer() {
    try {
      await this.example.stop();
      this.isRunning = false;
      this.serverStatus = '已停止';
      this.serverInfo = '';
      this.serverAddress = null;
    } catch (error) {
      this.serverInfo = `停止失败: ${(error as Error).message}`;
    }
  }
}
