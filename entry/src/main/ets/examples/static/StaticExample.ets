/**
 * @fileName : StaticExample.ets
 * @author : @cxy
 * @date : 2025/8/20
 * @description : 静态文件服务中间件使用示例
 */
import { WebServer } from "@cxy/webserver";
import { fileIo } from "@kit.CoreFileKit";
import { common } from "@kit.AbilityKit";

/**
 * 静态文件服务中间件使用示例
 */
export class StaticExample {
  // 示例1: 静态文件
  static async example1() {
    console.log('=== 示例1: 静态文件 ===');
    const server = new WebServer();

    const root = getContext().filesDir + '/www'
    if (!fileIo.accessSync(root)) {
      fileIo.mkdirSync(root)
    }
    await StaticExample.copyToStaticRoot(root, 'index.html')
    server.serveStatic(root)
    server.startServer(8080)
  }

  // 拷贝到沙箱服务器目录
  static async copyToStaticRoot(root: string, fileName: string) {
    const context = getContext() as common.UIAbilityContext;
    const buf = await context.resourceManager.getRawFileContent(fileName)
    const path = root + '/' + fileName
    const outFile =
      await fileIo.open(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC)
    await fileIo.write(outFile.fd, buf.buffer)
    await fileIo.close(outFile.fd)
  }
}
