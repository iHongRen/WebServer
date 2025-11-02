/**
 * @fileName : HttpsPage.ets
 * @author : @cxy
 * @date : 2025/11/2
 * @description : 文件描述
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Builder
function httpsBuilder() {
  HttpsPage()
}

@Component
struct HttpsPage {
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

  requestHttps() {
    // Configure security settings
    const securityConfig: rcp.SecurityConfiguration = {
      remoteValidation: "skip",
    };

    const session = rcp.createSession({ requestConfiguration: { security: securityConfig } });

    session.get("https://192.168.2.38:8443/api/status").then((response) => {
      console.info(`Succeeded in getting the response ${response}`);
    }).catch((err: BusinessError) => {
      console.error(`err: err code is ${err.code}, err message is ${JSON.stringify(err)}`);
    });
  }
}