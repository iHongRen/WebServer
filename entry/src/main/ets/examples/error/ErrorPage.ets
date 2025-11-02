/**
 * @fileName : ErrorPage.ets
 * @author : @cxy
 * @date : 2025/11/2
 * @description : 文件描述
 */

@Builder
function errorBuilder() {
  ErrorPage()
}

@Component
struct ErrorPage {
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