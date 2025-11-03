/**
 * @fileName : index.ets
 * @author : @cxy
 * @date : 2025/11/2
 * @description : WebServer
 */
@Entry
@Component
struct Index {
  pageStack: NavPathStack = new NavPathStack()
  items: string[][] = [
    ['http示例', 'HttpPage'],
    ['https示例', 'HttpsPage'],
    ['路由示例', 'RouterPage'],
    ['body解析示例', 'BodyPage'],
    ['跨域示例', 'CorsPage'],
    ['日志示例', 'LoggerPage'],
    ['静态文件服务示例', 'StaticPage'],
    ['事件处理示例', 'EventPage'],
  ]

  build() {
    Navigation(this.pageStack) {
      List() {
        ForEach(this.items, (item: string[]) => {
          ListItem() {
            Row() {
              Text(item[0])
                .fontColor('#333')
                .fontSize(18)

              Image($r('sys.media.ohos_ic_public_arrow_right'))
                .width(20)
                .height(20)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .padding(10)
          .onClick(() => {
            this.pushToName(item)
          })
        })
      }
      .height('100%')
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(true)
    .mode(NavigationMode.Stack)
    .title('WebServer Demo')

  }

  pushToName(item: string[]) {
    this.pageStack.pushPathByName(item[1], item[0])
  }
}

