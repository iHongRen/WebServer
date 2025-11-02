/**
 * @fileName : LoggerPage.ets
 * @author : @cxy
 * @date : 2025/11/2
 * @description : 文件描述
 */

@Builder
function loggerBuilder() {
  LoggerPage()
}

@Component
struct LoggerPage {
  @State title: string = ''

  build() {
    NavDestination() {
      Column() {

      }
    }
    .title(this.title)
    .onReady((ctx) => {
      this.title = ctx.pathInfo.param as string
    })
  }
}