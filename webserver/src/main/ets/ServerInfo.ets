/**
 * @fileName : ServerInfo.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : 服务器信息接口定义
 */

/**
 * 服务器信息接口
 * 用于描述服务器的基本信息
 */
export interface ServerInfo {
  address: string // 服务器IP地址
  port: number // 服务器端口号
}
