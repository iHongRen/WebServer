/**
 * @fileName : BodyParserExample.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : Body Parser示例 - 展示各种请求体解析功能
 */

import {
  HttpServer, ServerInfo, HttpRequest, HttpResponse,
} from '@cxy/webserver';

interface ParseResult {
  id: number;
  type: string;
  contentType: string;
  data: ESObject;
  timestamp: Date;
}

export class BodyParserExample {
  private server: HttpServer | null = null;
  private serverInfo: ServerInfo | null = null;
  // 存储解析结果
  private parseResults: ParseResult[] = [];
  private nextId: number = 1;

  /**
   * 初始化服务器
   */
  public initializeServer(): void {
    this.server = new HttpServer();
    this.setupRoutes();
  }

  /**
   * 启动服务器
   */
  public async start(port: number): Promise<ServerInfo | null> {
    try {
      if (!this.server) {
        this.initializeServer();
      }

      if (!this.server) {
        throw new Error('Body Parser服务器初始化失败');
      }

      const info = await this.server.startServer(port);

      if (info.address) {
        this.serverInfo = info;

        console.log('✅ Body Parser服务器启动成功!');
        console.log(`🌐 访问地址: http://${info.address}:${info.port}`);
        this.printApiEndpoints(info);

        return info;
      } else {
        throw new Error('未能获取服务器地址');
      }
    } catch (error) {
      console.error('❌ 启动Body Parser服务器失败:', error);
      return null;
    }
  }

  /**
   * 停止服务器
   */
  public async stop(): Promise<void> {
    if (this.server) {
      await this.server.stopServer();
      this.serverInfo = null;
      console.log('🛑 Body Parser服务器已停止');
    }
  }

  // Getter方法
  public getServerInfo(): ServerInfo | null {
    return this.serverInfo;
  }


  public getParseResultCount(): number {
    return this.parseResults.length;
  }


  /**
   * 配置路由
   */
  private setupRoutes(): void {
    this.setupJsonRoutes();
    this.setupUrlencodedRoutes();
    this.setupMultipartRoutes();
    this.setupPlainTextRoutes();
    this.setupAutoRoutes();
    this.setupResultRoutes();
  }

  /**
   * JSON解析路由
   */
  private setupJsonRoutes(): void {
    if (!this.server) {
      return;
    }

    // 使用JSON解析器的路由
    this.server.json(); // 启用JSON解析

    this.server.post('/api/json', (req: HttpRequest, res: HttpResponse) => {
      const contentType = req.get('content-type') || '';

      if (!contentType.includes('application/json')) {
        res.status(400).json({
          error: 'Content-Type must be application/json',
          received: contentType
        });
        return
      }

      // 记录解析结果
      const result: ParseResult = {
        id: this.nextId++,
        type: 'JSON',
        contentType,
        data: req.body,
        timestamp: new Date()
      };
      this.parseResults.push(result);

      res.json({
        message: 'JSON解析成功',
        parser: 'JSON Parser',
        contentType,
        result
      });
    });
  }

  /**
   * URL编码解析路由
   */
  private setupUrlencodedRoutes(): void {
    if (!this.server) {
      return;
    }

    this.server.urlencoded(); // 启用URL编码解析

    this.server.post('/api/urlencoded', (req: HttpRequest, res: HttpResponse) => {
      const contentType = req.get('content-type') || '';

      if (!contentType.includes('application/x-www-form-urlencoded')) {
        res.status(400).json({
          error: 'Content-Type must be application/x-www-form-urlencoded',
          received: contentType
        });
        return
      }

      const result: ParseResult = {
        id: this.nextId++,
        type: 'URL-Encoded',
        contentType,
        data: req.body,
        timestamp: new Date()
      };
      this.parseResults.push(result);

      res.json({
        message: 'URL编码解析成功',
        parser: 'URL-Encoded Parser',
        contentType,
        result
      });
    });
  }

  /**
   * 多部分表单解析路由
   */
  private setupMultipartRoutes(): void {
    if (!this.server) {
      return;
    }

    this.server.multipart(); // 启用多部分表单解析

    this.server.post('/api/multipart', (req: HttpRequest, res: HttpResponse) => {
      const contentType = req.get('content-type') || '';

      if (!contentType.includes('multipart/form-data')) {
        res.status(400).json({
          error: 'Content-Type must be multipart/form-data',
          received: contentType
        });
        return
      }

      const result: ParseResult = {
        id: this.nextId++,
        type: 'Multipart',
        contentType,
        data: {
          body: req.body,
          files: Object.keys(req.files).map(key => ({
            'fieldName': key,
            'fileName': req.files?.[key]?.fileName,
            'size': req.files?.[key]?.data.byteLength,
            'contentType': req.files?.[key]?.contentType
          } as Record<string, Object>))
        },
        timestamp: new Date()
      };
      this.parseResults.push(result);

      res.json({
        message: '多部分表单解析成功',
        parser: 'Multipart Parser',
        contentType,
        result
      });
    });
  }

  /**
   * 纯文本解析路由
   */
  private setupPlainTextRoutes(): void {
    if (!this.server) {
      return;
    }

    this.server.plain(); // 启用纯文本解析

    this.server.post('/api/plain', (req: HttpRequest, res: HttpResponse) => {
      const contentType = req.get('content-type') || '';

      if (!contentType.includes('text/plain')) {
        res.status(400).json({
          error: 'Content-Type must be text/plain',
          received: contentType
        });
        return
      }

      const result: ParseResult = {
        id: this.nextId++,
        type: 'Plain Text',
        contentType,
        data: req.body,
        timestamp: new Date()
      };
      this.parseResults.push(result);

      res.json({
        message: '纯文本解析成功',
        parser: 'Plain Text Parser',
        contentType,
        parsedData: req.body,
        textLength: (req.body as string).length,
        result
      });
    });
  }

  /**
   * 自动解析路由
   */
  private setupAutoRoutes(): void {
    if (!this.server) {
      return;
    }

    this.server.auto(); // 启用自动解析

    this.server.post('/api/auto', (req: HttpRequest, res: HttpResponse) => {
      const contentType = req.get('content-type') || '';

      let parserType = 'Unknown';
      if (contentType.includes('application/json')) {
        parserType = 'JSON (Auto)';
      } else if (contentType.includes('application/x-www-form-urlencoded')) {
        parserType = 'URL-Encoded (Auto)';
      } else if (contentType.includes('multipart/form-data')) {
        parserType = 'Multipart (Auto)';
      } else if (contentType.includes('text/plain')) {
        parserType = 'Plain Text (Auto)';
      }

      const result: ParseResult = {
        id: this.nextId++,
        type: parserType,
        contentType,
        data: req.body,
        timestamp: new Date()
      };
      this.parseResults.push(result);

      res.json({
        message: '自动解析成功',
        parser: 'Auto Parser',
        detectedType: parserType,
        contentType,
        parsedData: req.body,
        hasFiles: req.files ? Object.keys(req.files).length > 0 : false,
        files: req.files ? Object.keys(req.files) : [],
        result
      });
    });
  }

  /**
   * 结果查询路由
   */
  private setupResultRoutes(): void {
    if (!this.server) {
      return;
    }

    // 获取解析结果列表
    this.server.get('/api/results', (req: HttpRequest, res: HttpResponse) => {
      const limit = parseInt(req.query.get('limit') || '20');
      const offset = parseInt(req.query.get('offset') || '0');

      const results = this.parseResults
        .slice(offset, offset + limit)
        .reverse(); // 最新的在前

      res.json({
        results,
        total: this.parseResults.length,
        limit,
        offset,
        totalParsed: this.parseResults.length,
        byType: this.getResultsByType()
      });
    });

    // 获取特定解析结果
    this.server.get('/api/results/:id', (req: HttpRequest, res: HttpResponse) => {
      const id = parseInt(req.params['id']);
      const result = this.parseResults.find(r => r.id === id);

      if (result) {
        res.json({ result });
      } else {
        res.status(404).json({ error: 'Result not found', id });
      }
    });

    // 清除解析结果
    this.server.delete('/api/results', (req: HttpRequest, res: HttpResponse) => {
      const count = this.parseResults.length;
      this.parseResults = [];
      this.nextId = 1;

      res.json({
        message: 'All results cleared',
        clearedCount: count
      });
    });

  }

  /**
   * 获取按类型分组的结果统计
   */
  private getResultsByType(): Record<string, number> {
    const stats: Record<string, number> = {};
    this.parseResults.forEach(result => {
      stats[result.type] = (stats[result.type] || 0) + 1;
    });
    return stats;
  }


  /**
   * 打印API端点信息
   */
  private printApiEndpoints(info: ServerInfo): void {
    const baseUrl = `http://${info.address}:${info.port}`;

    console.log('\n📋 Body Parser API端点:');
    console.log('='.repeat(50));

    console.log('\n🔧 解析器端点:');
    console.log(`   POST   ${baseUrl}/api/json              - JSON解析器`);
    console.log(`   POST   ${baseUrl}/api/urlencoded        - URL编码解析器`);
    console.log(`   POST   ${baseUrl}/api/multipart         - 多部分表单解析器`);
    console.log(`   POST   ${baseUrl}/api/plain             - 纯文本解析器`);
    console.log(`   POST   ${baseUrl}/api/auto              - 自动解析器`);

    console.log('\n📊 结果管理:');
    console.log(`   GET    ${baseUrl}/api/results           - 获取解析结果`);
    console.log(`   GET    ${baseUrl}/api/results/:id       - 获取特定结果`);
    console.log(`   DELETE ${baseUrl}/api/results           - 清除所有结果`);
    console.log(`   GET    ${baseUrl}/api/parsers           - 解析器信息`);

    console.log('='.repeat(50));
  }
}