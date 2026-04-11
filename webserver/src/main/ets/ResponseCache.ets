/**
 * @fileName : ResponseCache.ets
 * @author : @cxy
 * @date : 2025/4/11
 * @description : 响应缓存管理器 - 提升静态资源性能
 */

/**
 * 缓存项接口
 */
export interface CacheEntry {
  data: ArrayBuffer;
  headers: Map<string, string>;
  etag: string;
  timestamp: number;
  hits: number;
  size: number;
}

/**
 * 缓存配置
 */
export interface CacheConfig {
  maxSize?: number; // 最大缓存大小（字节）
  maxAge?: number; // 最大缓存时间（毫秒）
  maxEntries?: number; // 最大缓存条目数
}

/**
 * 缓存统计接口
 */
export interface CacheStats {
  entries: number;
  size: number;
  maxSize: number;
  hitRate: number;
}

/**
 * 响应缓存管理器
 * 使用 LRU 策略优化内存使用
 */
export class ResponseCache {
  private cache: Map<string, CacheEntry> = new Map();
  private config: Required<CacheConfig>;
  private currentSize: number = 0;

  constructor(config?: CacheConfig) {
    this.config = {
      maxSize: config?.maxSize ?? 100 * 1024 * 1024, // 100MB
      maxAge: config?.maxAge ?? 3600000, // 1小时
      maxEntries: config?.maxEntries ?? 1000
    };
  }

  /**
   * 设置缓存
   */
  public set(key: string, data: ArrayBuffer, headers: Map<string, string>, etag: string): void {
    const size = data.byteLength;

    // 检查单个文件是否超过最大缓存大小的 10%
    if (size > this.config.maxSize * 0.1) {
      return;
    }

    // 如果缓存已满，执行清理
    if (this.cache.size >= this.config.maxEntries || this.currentSize + size > this.config.maxSize) {
      this.evict(size);
    }

    const entry: CacheEntry = {
      data,
      headers,
      etag,
      timestamp: Date.now(),
      hits: 0,
      size
    };

    this.cache.set(key, entry);
    this.currentSize += size;
  }

  /**
   * 获取缓存
   */
  public get(key: string): CacheEntry | null {
    const entry = this.cache.get(key);

    if (!entry) {
      return null;
    }

    // 检查是否过期
    if (Date.now() - entry.timestamp > this.config.maxAge) {
      this.delete(key);
      return null;
    }

    // 更新命中次数
    entry.hits++;

    // LRU: 将访问的项移到末尾
    this.cache.delete(key);
    this.cache.set(key, entry);

    return entry;
  }

  /**
   * 删除缓存
   */
  public delete(key: string): void {
    const entry = this.cache.get(key);
    if (entry) {
      this.currentSize -= entry.size;
      this.cache.delete(key);
    }
  }

  /**
   * 清空缓存
   */
  public clear(): void {
    this.cache.clear();
    this.currentSize = 0;
  }

  /**
   * 获取缓存统计
   */
  public getStats(): CacheStats {
    let totalHits = 0;
    let totalRequests = 0;

    this.cache.forEach((entry: CacheEntry) => {
      totalHits += entry.hits;
      totalRequests += entry.hits + 1; // +1 for initial set
    });

    const stats: CacheStats = {
      entries: this.cache.size,
      size: this.currentSize,
      maxSize: this.config.maxSize,
      hitRate: totalRequests > 0 ? totalHits / totalRequests : 0
    };
    return stats;
  }

  /**
   * 驱逐策略：LRU + 最少命中
   */
  private evict(requiredSize: number): void {
    const now = Date.now();
    const toRemove: string[] = [];

    // 首先移除过期项
    this.cache.forEach((entry: CacheEntry, key: string) => {
      if (now - entry.timestamp > this.config.maxAge) {
        toRemove.push(key);
      }
    });

    // 如果还需要更多空间，移除命中率最低的项
    if (this.currentSize + requiredSize > this.config.maxSize || this.cache.size >= this.config.maxEntries) {
      const entries = Array.from(this.cache.entries());
      entries.sort((a: [string, CacheEntry], b: [string, CacheEntry]) => a[1].hits - b[1].hits);

      for (let i = 0; i < entries.length; i++) {
        const key = entries[i][0];
        if (this.currentSize + requiredSize <= this.config.maxSize && this.cache.size < this.config.maxEntries) {
          break;
        }
        toRemove.push(key);
      }
    }

    // 执行删除
    toRemove.forEach((key: string) => this.delete(key));
  }
}
