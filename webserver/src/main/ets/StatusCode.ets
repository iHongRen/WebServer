/**
 * @fileName : StatusCode.ets
 * @author : @cxy
 * @date : 2025/10/31
 * @description : HTTP状态码映射表
 */

export const StatusCode: Record<number, string> = {
  // 信息性状态码 (1xx)
  100: 'Continue', // 服务器已接收请求头，客户端可继续发送请求体
  101: 'Switching Protocols', // 服务器同意客户端切换协议
  102: 'Processing', // 服务器正在处理请求（WebDAV）
  103: 'Early Hints', // 返回预热资源提示

  // 成功状态码 (2xx)
  200: 'OK', // 请求成功
  201: 'Created', // 请求已创建新资源
  202: 'Accepted', // 请求已接受但尚未处理
  203: 'Non-Authoritative Information', // 响应信息来自非源服务器
  204: 'No Content', // 请求成功但无返回内容
  205: 'Reset Content', // 重置文档视图
  206: 'Partial Content', // 部分内容（断点续传）
  207: 'Multi-Status', // 多状态响应（WebDAV）
  208: 'Already Reported', // 已在其他地方报告（WebDAV）
  226: 'IM Used', // 服务器已执行GET请求的变体

  // 重定向状态码 (3xx)
  300: 'Multiple Choices', // 多种资源选择
  301: 'Moved Permanently', // 资源永久迁移
  302: 'Found', // 资源临时迁移（历史上叫Moved Temporarily）
  303: 'See Other', // 应使用GET请求另一个URI
  304: 'Not Modified', // 资源未修改（缓存命中）
  305: 'Use Proxy', // 需通过代理访问（已废弃）
  307: 'Temporary Redirect', // 临时重定向（保持原方法）
  308: 'Permanent Redirect', // 永久重定向（保持原方法）

  // 客户端错误状态码 (4xx)
  400: 'Bad Request', // 请求格式错误
  401: 'Unauthorized', // 未认证（需登录）
  402: 'Payment Required', // 需付费（预留）
  403: 'Forbidden', // 服务器拒绝访问
  404: 'Not Found', // 资源不存在
  405: 'Method Not Allowed', // 请求方法不允许
  406: 'Not Acceptable', // 无法满足Accept头
  407: 'Proxy Authentication Required', // 需代理认证
  408: 'Request Timeout', // 请求超时
  409: 'Conflict', // 请求冲突（如资源已存在）
  410: 'Gone', // 资源永久删除
  411: 'Length Required', // 缺少Content-Length头
  412: 'Precondition Failed', // 前置条件失败
  413: 'Payload Too Large', // 请求体过大
  414: 'URI Too Long', // 请求URI过长
  415: 'Unsupported Media Type', // 不支持的媒体类型
  416: 'Range Not Satisfiable', // 范围请求无效
  417: 'Expectation Failed', // 无法满足Expect头
  418: "I'm a teapot", // 愚人节彩蛋（不能煮咖啡）
  421: 'Misdirected Request', // 请求被错误路由
  422: 'Unprocessable Entity', // 请求格式正确但语义错误（WebDAV）
  423: 'Locked', // 资源被锁定（WebDAV）
  424: 'Failed Dependency', // 依赖请求失败（WebDAV）
  425: 'Too Early', // 防止重放攻击
  426: 'Upgrade Required', // 需升级协议
  428: 'Precondition Required', // 要求前置条件
  429: 'Too Many Requests', // 请求过于频繁
  431: 'Request Header Fields Too Large', // 请求头过大
  451: 'Unavailable For Legal Reasons', // 因法律原因不可用

  // 服务器错误状态码 (5xx)
  500: 'Internal Server Error', // 服务器内部错误
  501: 'Not Implemented', // 服务器不支持该功能
  502: 'Bad Gateway', // 网关错误
  503: 'Service Unavailable', // 服务暂时不可用
  504: 'Gateway Timeout', // 网关超时
  505: 'HTTP Version Not Supported', // 不支持的HTTP版本
  506: 'Variant Also Negotiates', // 变体协商循环
  507: 'Insufficient Storage', // 存储不足（WebDAV）
  508: 'Loop Detected', // 检测到循环（WebDAV）
  510: 'Not Extended', // 需要扩展
  511: 'Network Authentication Required' // 需要网络认证
};
