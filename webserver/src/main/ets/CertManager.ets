/**
 * @fileName : CertManager.ets
 * @author : @cxy
 * @date : 2025/10/24
 * @description : SSL证书管理工具
 */

import { fileIo } from '@kit.CoreFileKit';
import { socket } from '@kit.NetworkKit';

/**
 * 证书管理器类
 * 提供证书加载、验证等功能
 */
export class CertManager {
  /**
   * 从文件加载证书配置
   * @param keyPath 私钥文件路径
   * @param certPath 证书文件路径
   * @param caPath CA证书文件路径（可选）
   * @returns TLS配置选项
   */
  public static async loadFromFiles(
    keyPath: string,
    certPath: string,
    caPath?: string
  ): Promise<socket.TLSSecureOptions> {
    try {
      const options: socket.TLSSecureOptions = {};

      // 加载私钥
      if (keyPath) {
        const keyContent = await fileIo.readText(keyPath);
        options.key = keyContent;
      }

      // 加载证书
      if (certPath) {
        const certContent = await fileIo.readText(certPath);
        options.cert = certContent;
      }

      // 加载CA证书（如果提供）
      if (caPath) {
        const caContent = await fileIo.readText(caPath);
        options.ca = caContent;
      }

      return options;
    } catch (error) {
      console.error('加载证书文件失败:', error);
      throw new Error('证书加载失败');
    }
  }

  /**
   * 验证证书配置
   * @param options TLS配置选项
   * @returns 是否有效
   */
  public static validateConfig(options: socket.TLSSecureOptions): boolean {
    // 检查必需的证书和私钥
    if (!options.key || !options.cert) {
      console.error('缺少必需的私钥或证书');
      return false;
    }

    // 验证证书格式
    const keyStr = typeof options.key === 'string' ? options.key : '';
    const certStr = typeof options.cert === 'string' ? options.cert : '';

    if (!keyStr.includes('BEGIN PRIVATE KEY') && !keyStr.includes('BEGIN RSA PRIVATE KEY')) {
      console.error('私钥格式无效');
      return false;
    }

    if (!certStr.includes('BEGIN CERTIFICATE')) {
      console.error('证书格式无效');
      return false;
    }

    return true;
  }
}