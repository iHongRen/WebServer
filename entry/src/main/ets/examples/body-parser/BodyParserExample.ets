/**
 * @fileName : BodyParserExample.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : Body Parser示例 - 展示各种请求体解析功能
 */

import {
  HttpServer, ServerInfo, HttpRequest, HttpResponse,
} from '@cxy/webserver';

// 定义用于存储解析结果的接口
interface ParseResult {
  id: number;
  type: string; // 解析器类型 (e.g., 'JSON', 'URL-Encoded')
  contentType: string; // 请求的 Content-Type
  data: ESObject; // 解析后的数据
  timestamp: Date; // 解析时间
}

export class BodyParserExample {
  private server: HttpServer | null = null;
  private serverInfo: ServerInfo | null = null;
  // 使用数组存储每次请求的解析结果，用于在UI上展示
  private parseResults: ParseResult[] = [];
  private nextId: number = 1; // 自增ID

  /**
   * 初始化服务器实例和路由
   */
  public initializeServer(): void {
    this.server = new HttpServer();
    this.setupRoutes(); // 配置所有API路由
  }

  /**
   * 启动服务器
   * @param port - 监听的端口号
   * @returns 服务器信息或 null
   */
  public async start(port: number): Promise<ServerInfo | null> {
    try {
      if (!this.server) {
        this.initializeServer();
      }

      if (!this.server) {
        throw new Error('Body Parser服务器初始化失败');
      }

      // 启动服务器并监听指定端口
      const info = await this.server.startServer(port);

      if (info.address) {
        this.serverInfo = info;

        console.log('✅ Body Parser服务器启动成功!');
        console.log(`🌐 访问地址: http://${info.address}:${info.port}`);
        this.printApiEndpoints(info); // 在控制台打印所有可用的API端点

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

  // --- Getter方法 ---
  public getServerInfo(): ServerInfo | null {
    return this.serverInfo;
  }


  public getParseResultCount(): number {
    return this.parseResults.length;
  }


  /**
   * 集中配置所有路由
   */
  private setupRoutes(): void {
    // 为不同类型的内容分别设置解析器和路由
    this.setupJsonRoutes();
    this.setupUrlencodedRoutes();
    this.setupMultipartRoutes();
    this.setupPlainTextRoutes();
    this.setupAutoRoutes();
    // 用于查询和管理解析结果的路由
    this.setupResultRoutes();
  }

  /**
   * JSON解析路由: 处理 application/json
   */
  private setupJsonRoutes(): void {
    if (!this.server) {
      return;
    }

    // 启用JSON解析器。此后所有请求都会尝试用JSON解析。
    this.server.json(); // 启用JSON解析

    this.server.post('/api/json', (req: HttpRequest, res: HttpResponse) => {
      const contentType = req.get('content-type') || '';

      // 严格检查 Content-Type
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
        data: req.body, // 解析后的数据在 req.body 中
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
   * URL编码解析路由: 处理 application/x-www-form-urlencoded
   */
  private setupUrlencodedRoutes(): void {
    if (!this.server) {
      return;
    }

    // 启用URL编码解析器
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
        data: req.body, // 解析后的数据在 req.body 中
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
   * 多部分表单解析路由: 处理 multipart/form-data (常用于文件上传)
   */
  private setupMultipartRoutes(): void {
    if (!this.server) {
      return;
    }

    // 启用多部分表单解析器
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
          body: req.body, // 表单中的文本字段在 req.body
          files: Object.keys(req.files).map(key => ({ // 上传的文件在 req.files
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
   * 纯文本解析路由: 处理 text/plain
   */
  private setupPlainTextRoutes(): void {
    if (!this.server) {
      return;
    }

    // 启用纯文本解析器
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
        data: req.body, // 解析后的文本在 req.body (string)
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
   * 自动解析路由: 根据 Content-Type 自动选择解析器
   */
  private setupAutoRoutes(): void {
    if (!this.server) {
      return;
    }

    // 启用自动解析器
    this.server.auto(); // 启用自动解析

    this.server.post('/api/auto', (req: HttpRequest, res: HttpResponse) => {
      const contentType = req.get('content-type') || '';

      // 判断是哪个解析器处理了请求
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
   * 结果查询路由: 用于获取、查询和清除解析结果
   */
  private setupResultRoutes(): void {
    if (!this.server) {
      return;
    }

    // GET /api/results - 获取解析结果列表 (支持分页)
    this.server.get('/api/results', (req: HttpRequest, res: HttpResponse) => {
      const limit = parseInt(req.query.get('limit') || '20');
      const offset = parseInt(req.query.get('offset') || '0');

      const results = this.parseResults
        .slice() // 创建副本以避免修改原数组
        .reverse() // 最新的在前
        .slice(offset, offset + limit);

      res.json({
        results,
        total: this.parseResults.length,
        limit,
        offset,
        totalParsed: this.parseResults.length,
        byType: this.getResultsByType()
      });
    });

    // GET /api/results/:id - 获取特定ID的解析结果
    this.server.get('/api/results/:id', (req: HttpRequest, res: HttpResponse) => {
      const id = parseInt(req.params['id']);
      const result = this.parseResults.find(r => r.id === id);

      if (result) {
        res.json({ result });
      } else {
        res.status(404).json({ error: 'Result not found', id });
      }
    });

    // DELETE /api/results - 清除所有解析结果
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
   * 在控制台打印所有可用的API端点，方便开发者测试
   */
  private printApiEndpoints(info: ServerInfo): void {
    const baseUrl = `http://${info.address}:${info.port}`;

    console.log('\n📋 Body Parser API端点:');
    console.log('='.repeat(50));

    console.log('\n🔧 解析器端点 (POST):');
    console.log(`   ${baseUrl}/api/json`);
    console.log(`   ${baseUrl}/api/urlencoded`);
    console.log(`   ${baseUrl}/api/multipart`);
    console.log(`   ${baseUrl}/api/plain`);
    console.log(`   ${baseUrl}/api/auto`);

    console.log('\n📊 结果管理:');
    console.log(`   GET    ${baseUrl}/api/results           - 获取解析结果`);
    console.log(`   GET    ${baseUrl}/api/results/:id       - 获取特定结果`);
    console.log(`   DELETE ${baseUrl}/api/results           - 清除所有结果`);

    console.log('\n🚀 测试命令:');
    console.log(`   sh ./entry/src/main/ets/examples/body-parser/test-body-parser.sh`);
    console.log('='.repeat(50));
  }
}