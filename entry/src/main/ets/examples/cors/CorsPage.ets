/**
 * @fileName : CorsPage.ets
 * @author : @cxy
 * @date : 2025/11/2
 * @description : 文件描述
 */

@Builder
function corsBuilder() {
  CorsPage()
}

@Component
struct CorsPage {
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