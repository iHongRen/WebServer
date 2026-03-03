/**
 * @fileName : fileUpload.ets
 * @author : @cxy
 * @date : 2025/3/3
 * @description : 文件上传中间件 - 参考 express-fileupload 实现
 */

import { HttpRequest } from '../HttpRequest';
import type { File } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';
import { NextFunction, RequestHandler } from './types';
import { fileIo as fs } from '@kit.CoreFileKit';
import { Utils } from '../Utils';

/**
 * 上传文件接口
 */
export interface UploadedFile {
  name: string; // 原始文件名
  data: ArrayBuffer; // 文件数据
  size: number; // 文件大小
  encoding: string; // 编码
  tempFilePath: string; // 临时文件路径
  truncated: boolean; // 是否被截断
  mimetype: string; // MIME类型
  md5?: string; // MD5哈希（可选）
  mv: (path: string) => Promise<void>; // 移动文件方法
}

/**
 * 文件限制配置
 */
export interface FileLimits {
  fileSize?: number; // 单个文件最大大小（字节）
  files?: number; // 最大文件数量
  fields?: number; // 最大字段数量
  fieldSize?: number; // 字段最大大小
}

/**
 * 文件上传配置选项
 */
export interface FileUploadOptions {
  createParentPath?: boolean; // 自动创建父目录
  uriDecodeFileNames?: boolean; // 解码文件名
  safeFileNames?: boolean; // 安全文件名（移除特殊字符）
  preserveExtension?: boolean; // 保留文件扩展名
  abortOnLimit?: boolean; // 超过限制时中止
  useTempFiles?: boolean; // 使用临时文件
  tempFileDir?: string; // 临时文件目录
  debug?: boolean; // 调试模式
  limits?: FileLimits; // 文件限制
}

/**
 * 解析结果接口
 */
export interface ParseResult {
  fields: Record<string, string>;
  files: Record<string, UploadedFile>;
}

/**
 * 部分处理结果接口
 */
export interface PartResult {
  type: string;
  name: string;
  value: string | UploadedFile;
}

/**
 * 文件上传解析器
 */
class FileUploadParser {
  private boundary: string;
  private options: FileUploadOptions;
  private fileCount: number = 0;
  private fieldCount: number = 0;
  private tempDir: string;

  constructor(boundary: string, options: FileUploadOptions) {
    this.boundary = boundary;
    this.options = options;
    this.tempDir = options.tempFileDir || '/tmp/uploads';
  }

  /**
   * 解析请求数据
   */
  async parse(data: ArrayBuffer, contentType: string): Promise<ParseResult> {
    const fields: Record<string, string> = {};
    const files: Record<string, UploadedFile> = {};

    // 处理 multipart/form-data
    if (contentType.includes('multipart/form-data')) {
      const result = await this.parseMultipart(data);
      // 合并 fields
      const fieldKeys = Object.keys(result.fields);
      for (let i = 0; i < fieldKeys.length; i++) {
        const key = fieldKeys[i];
        fields[key] = result.fields[key];
      }
      // 合并 files
      const fileKeys = Object.keys(result.files);
      for (let i = 0; i < fileKeys.length; i++) {
        const key = fileKeys[i];
        files[key] = result.files[key];
      }
    }
    // 处理 application/octet-stream (单文件流式上传)
    else if (contentType.includes('application/octet-stream')) {
      const file = await this.parseOctetStream(data);
      if (file) {
        files['file'] = file;
      }
    }

    const parseResult: ParseResult = { fields, files };
    return parseResult;
  }

  throwError(e: Error) {
    throw e
  }

  /**
   * 解析 multipart/form-data
   */
  private async parseMultipart(data: ArrayBuffer): Promise<ParseResult> {
    const fields: Record<string, string> = {};
    const files: Record<string, UploadedFile> = {};

    const uint8Data = new Uint8Array(data);
    const boundaryBytes = Utils.strToUint8Array(`--${this.boundary}`);
    const parts = this.splitMultipartData(uint8Data, boundaryBytes);

    for (const part of parts) {
      const result = await this.processPart(part);
      if (result) {
        if (result.type === 'field') {
          fields[result.name] = result.value as string;
        } else if (result.type === 'file') {
          files[result.name] = result.value as UploadedFile;
        }
      }
    }

    const parseResult: ParseResult = { fields, files };
    return parseResult;
  }

  /**
   * 解析 application/octet-stream
   */
  private async parseOctetStream(data: ArrayBuffer): Promise<UploadedFile | null> {
    const size = data.byteLength;

    // 检查文件大小限制
    if (this.options.limits?.fileSize && size > this.options.limits.fileSize) {
      if (this.options.abortOnLimit) {
        throw new Error(`File size limit exceeded: ${size} > ${this.options.limits.fileSize}`);
      }
    }

    const fileName = `upload_${Date.now()}.bin`;
    const tempFilePath = await this.saveTempFile(data, fileName);

    const uploadedFile: UploadedFile = {
      name: fileName,
      data: data,
      size: size,
      encoding: '7bit',
      tempFilePath: tempFilePath,
      truncated: false,
      mimetype: 'application/octet-stream',
      mv: this.createMoveFunction(tempFilePath)
    };

    return uploadedFile;
  }

  /**
   * 分割 multipart 数据
   */
  private splitMultipartData(data: Uint8Array, boundary: Uint8Array): Uint8Array[] {
    const parts: Uint8Array[] = [];
    let startIndex = 0;

    while (true) {
      const endIndex = this.findBoundary(data, boundary, startIndex);
      if (endIndex === -1) {
        break;
      }

      if (endIndex > startIndex) {
        parts.push(data.slice(startIndex, endIndex));
      }
      startIndex = endIndex + boundary.length + 2;
    }

    return parts.filter(part => part.length > 0);
  }

  /**
   * 查找边界
   */
  private findBoundary(data: Uint8Array, boundary: Uint8Array, start: number): number {
    for (let i = start; i <= data.length - boundary.length; i++) {
      let match = true;
      for (let j = 0; j < boundary.length; j++) {
        if (data[i + j] !== boundary[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        if (i > 0 && data[i - 1] === 0x0A && data[i - 2] === 0x0D) {
          return i - 2;
        }
      }
    }
    return -1;
  }

  /**
   * 处理单个部分
   */
  private async processPart(part: Uint8Array): Promise<PartResult | null> {
    let headersEnd = -1;
    const CRLF_CRLF = new Uint8Array([0x0D, 0x0A, 0x0D, 0x0A]);

    for (let i = 0; i <= part.length - CRLF_CRLF.length; i++) {
      if (part[i] === CRLF_CRLF[0] && part[i + 1] === CRLF_CRLF[1] &&
        part[i + 2] === CRLF_CRLF[2] && part[i + 3] === CRLF_CRLF[3]) {
        headersEnd = i;
        break;
      }
    }

    if (headersEnd === -1) {
      return null;
    }

    const headers = Utils.uint8ToStr(part.slice(0, headersEnd));
    const content = part.slice(headersEnd + 4);

    const dispositionMatch = headers.match(/Content-Disposition: form-data; name="([^"]+)"(?:; filename="([^"]+)")?/);
    if (!dispositionMatch) {
      return null;
    }

    const fieldName = dispositionMatch[1];
    const fileName = dispositionMatch[2];

    if (fileName) {
      // 处理文件
      const file = await this.processFile(fieldName, fileName, headers, content);
      return file ? { type: 'file', name: fieldName, value: file } : null;
    } else {
      // 处理字段
      this.fieldCount++;
      if (this.options.limits?.fields && this.fieldCount > this.options.limits.fields) {
        throw new Error(`Too many fields: ${this.fieldCount} > ${this.options.limits.fields}`);
      }

      const value = Utils.uint8ToStr(content);
      if (this.options.limits?.fieldSize && value.length > this.options.limits.fieldSize) {
        throw new Error(`Field size limit exceeded: ${value.length} > ${this.options.limits.fieldSize}`);
      }

      return { type: 'field', name: fieldName, value: value };
    }
  }

  /**
   * 处理文件
   */
  private async processFile(fieldName: string, fileName: string, headers: string,
    content: Uint8Array): Promise<UploadedFile | null> {
    // 检查文件数量
    this.fileCount++;
    if (this.options.limits?.files && this.fileCount > this.options.limits.files) {
      throw new Error(`Too many files: ${this.fileCount} > ${this.options.limits.files}`);
    }

    // 解析 Content-Type
    const contentTypeMatch = headers.match(/Content-Type: ([^\r\n]+)/);
    const mimetype = contentTypeMatch ? contentTypeMatch[1].trim() : 'application/octet-stream';

    // 处理文件名
    let processedFileName = fileName;
    if (this.options.uriDecodeFileNames) {
      processedFileName = decodeURIComponent(fileName);
    }
    if (this.options.safeFileNames) {
      processedFileName = this.sanitizeFileName(processedFileName);
    }

    const size = content.length;
    const truncated = this.options.limits?.fileSize ? size > this.options.limits.fileSize : false;

    // 检查文件大小
    if (this.options.limits?.fileSize && size > this.options.limits.fileSize) {
      if (this.options.abortOnLimit) {
        throw new Error(`File size limit exceeded: ${size} > ${this.options.limits.fileSize}`);
      }
    }

    // 保存临时文件
    const tempFilePath = await this.saveTempFile(content.buffer as ArrayBuffer, processedFileName);

    const uploadedFile: UploadedFile = {
      name: processedFileName,
      data: content.buffer as ArrayBuffer,
      size: size,
      encoding: '7bit',
      tempFilePath: tempFilePath,
      truncated: truncated,
      mimetype: mimetype,
      mv: this.createMoveFunction(tempFilePath)
    };

    return uploadedFile;
  }

  /**
   * 保存临时文件
   */
  private async saveTempFile(data: ArrayBuffer, fileName: string): Promise<string> {
    // 确保临时目录存在
    await this.ensureDir(this.tempDir);

    // 生成唯一文件名
    const timestamp = Date.now();
    const randomStr = Math.random().toString(36).substring(2, 8);
    const ext = fileName.includes('.') ? fileName.substring(fileName.lastIndexOf('.')) : '';
    const uniqueFileName = `${timestamp}_${randomStr}${ext}`;
    const tempFilePath = `${this.tempDir}/${uniqueFileName}`;

    // 使用流式写入
    await this.writeFileStream(tempFilePath, data);

    return tempFilePath;
  }

  /**
   * 使用流式方式写入文件
   */
  private async writeFileStream(filePath: string, data: ArrayBuffer): Promise<void> {
    const stream = fs.createWriteStream(filePath);
    try {
      stream.write(Utils.arrayBufferToStr(data));
    } catch (e) {
      this.throwError(e)
    } finally {
      stream.close();
    }
  }

  /**
   * 创建文件移动函数
   */
  private createMoveFunction(tempFilePath: string): (path: string) => Promise<void> {
    return async (destPath: string) => {
      // 如果需要创建父目录
      if (this.options.createParentPath) {
        const parentDir = destPath.substring(0, destPath.lastIndexOf('/'));
        if (parentDir) {
          await this.ensureDir(parentDir);
        }
      }

      // 复制文件
      await fs.copyFile(tempFilePath, destPath);

      // 删除临时文件
      try {
        await fs.unlink(tempFilePath);
      } catch (e) {
        // 忽略删除错误
        const error = e as Error;
        console.error('[FileUpload] Failed to delete temp file:', error.message);
      }
    };
  }

  /**
   * 清理文件名
   */
  private sanitizeFileName(fileName: string): string {
    return fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
  }

  /**
   * 确保目录存在
   */
  private async ensureDir(dir: string): Promise<void> {
    try {
      const exists = await fs.access(dir);
      if (!exists) {
        await fs.mkdir(dir);
      }
    } catch (e) {
      // 目录可能已存在
      if (this.options.debug) {
        const error = e as Error;
        console.error('[FileUpload] ensureDir error:', error.message);
      }
    }
  }
}

/**
 * 文件上传中间件
 */
export class FileUpload {
  /**
   * 创建文件上传中间件
   */
  static create(options: FileUploadOptions = {}): RequestHandler {
    // 设置默认值
    const defaultLimits: FileLimits = {
      fileSize: 50 * 1024 * 1024, // 50MB
      files: 10,
      fields: 100,
      fieldSize: 1024 * 1024 // 1MB
    };

    const defaultOptions: FileUploadOptions = {
      createParentPath: false,
      uriDecodeFileNames: false,
      safeFileNames: false,
      preserveExtension: false,
      abortOnLimit: false,
      useTempFiles: true,
      tempFileDir: '/tmp/uploads',
      debug: false,
      limits: defaultLimits
    };

    // 合并选项
    const mergedOptions: FileUploadOptions = {
      createParentPath: options.createParentPath !== undefined ? options.createParentPath :
        defaultOptions.createParentPath,
      uriDecodeFileNames: options.uriDecodeFileNames !== undefined ? options.uriDecodeFileNames :
        defaultOptions.uriDecodeFileNames,
      safeFileNames: options.safeFileNames !== undefined ? options.safeFileNames : defaultOptions.safeFileNames,
      preserveExtension: options.preserveExtension !== undefined ? options.preserveExtension :
        defaultOptions.preserveExtension,
      abortOnLimit: options.abortOnLimit !== undefined ? options.abortOnLimit : defaultOptions.abortOnLimit,
      useTempFiles: options.useTempFiles !== undefined ? options.useTempFiles : defaultOptions.useTempFiles,
      tempFileDir: options.tempFileDir || defaultOptions.tempFileDir,
      debug: options.debug !== undefined ? options.debug : defaultOptions.debug,
      limits: options.limits || defaultLimits
    };

    return async (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      const contentType = req.get('content-type');

      // 只处理文件上传相关的 Content-Type
      if (!contentType ||
        (!contentType.includes('multipart/form-data') &&
          !contentType.includes('application/octet-stream'))) {
        return next();
      }

      try {
        // 解析 boundary（如果是 multipart）
        let boundary = '';
        if (contentType.includes('multipart/form-data')) {
          const boundaryMatch = contentType.match(/boundary=(.+)/);
          if (!boundaryMatch) {
            throw new Error('Missing boundary in multipart/form-data');
          }
          boundary = boundaryMatch[1].trim();
        }

        // 创建解析器
        const parser = new FileUploadParser(boundary, mergedOptions);

        // 解析数据
        const rawBody = req.getRawBody();
        const parseResult = await parser.parse(rawBody, contentType);

        // 将结果附加到请求对象
        if (Object.keys(parseResult.fields).length > 0) {
          const currentBody = req.body as Record<string, string>;
          const fieldKeys = Object.keys(parseResult.fields);
          for (let i = 0; i < fieldKeys.length; i++) {
            const key = fieldKeys[i];
            currentBody[key] = parseResult.fields[key];
          }
          req.body = currentBody;
        }
        if (Object.keys(parseResult.files).length > 0) {
          req.files = parseResult.files;
        }

        if (mergedOptions.debug) {
          console.log(`[FileUpload] Parsed ${Object.keys(parseResult.files)
            .length} files and ${Object.keys(parseResult.fields).length} fields`);
        }

        next();
      } catch (e) {
        const error = e as Error;
        if (mergedOptions.debug) {
          console.error('[FileUpload] Error:', error.message);
        }

        res.status(500).json({
          error: 'File upload failed',
          message: error.message
        } as ESObject);
      }
    };
  }
}
