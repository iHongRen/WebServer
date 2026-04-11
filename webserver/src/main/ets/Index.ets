/**
 * @fileName : Index.ets
 * @author : @cxy
 * @date : 2025/3/3
 * @description : WebServer 主导出文件
 */

// 导出核心类
export { HttpServer } from './HttpServer';

export { HttpRequest } from './HttpRequest';

export { HttpResponse } from './HttpResponse';

export { Router } from './Router';

export { TLSServer } from './TLSServer';

// 导出优化模块
export { ConnectionPool } from './ConnectionPool';
export type { ConnectionInfo, PoolConfig } from './ConnectionPool';

export { RequestParser } from './RequestParser';
export type { ParsedRequest } from './RequestParser';

export { ResponseCache } from './ResponseCache';
export type { CacheEntry, CacheConfig, CacheStats } from './ResponseCache';

// 导出类型
export type { File } from './HttpRequest';

export { ServerEventType, ServerErrorType } from './ServerEvents';
export type { ServerEvent, ServerError, ErrorEventListener, ServerEventListener } from './ServerEvents';

// 导出中间件
export * from './middleware/index';

// 导出工具
export { StatusCode } from './StatusCode';

export { Utils } from './Utils';
