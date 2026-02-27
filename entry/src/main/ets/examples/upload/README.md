# 分片上传示例

这是一个完整的大文件分片上传实现示例，展示了如何使用 WebServer 框架处理大文件上传。

## 文件说明

- `UploadExample.ets` - 服务器端实现，包含所有API端点
- `UploadPage.ets` - UI页面，用于启动和管理服务器
- `chunk-upload.html` - Web前端页面，提供可视化上传界面
- `test-upload.sh` - 自动化测试脚本
- `分片上传最佳实践.md` - 详细的使用指南和最佳实践
- `README.md` - 本文件

## 快速开始

### 1. 启动服务器

在应用中打开"分片上传示例"页面，点击"启动服务器"按钮。

默认端口：8085

### 2. 使用Web界面测试

在浏览器中访问：`http://服务器IP:8085/chunk-upload.html`

Web界面提供了完整的可视化上传功能：
- 拖拽或点击选择文件
- 配置服务器地址、分片大小、并发数
- 实时查看上传进度和速度
- 支持暂停、继续、取消上传
- 详细的日志输出
- 浏览器兼容：支持现代浏览器（Chrome 60+, Firefox 55+, Safari 11+, Edge 79+）

### 3. 使用命令行测试

```bash
cd entry/src/main/ets/examples/upload
./test-upload.sh
```

测试脚本会自动：
- 创建测试文件
- 分片上传
- 测试断点续传
- 测试取消上传
- 清理测试文件

### 4. 手动测试

参考 `分片上传最佳实践.md` 中的详细说明。

## 核心功能

✅ 分片上传 - 将大文件分割成小块上传  
✅ 断点续传 - 支持上传中断后继续  
✅ 进度跟踪 - 实时显示上传进度  
✅ 任务管理 - 查询和取消上传任务  
✅ 自动合并 - 上传完成后自动合并文件  

## API端点

- `POST /api/upload/check` - 检查上传状态
- `POST /api/upload/chunk` - 上传分片
- `POST /api/upload/merge` - 合并分片
- `DELETE /api/upload/cancel/:fileHash` - 取消上传
- `GET /api/upload/tasks` - 查询上传任务
- `GET /api/upload/files` - 查询已上传文件

## 更多信息

详细的使用说明、最佳实践和常见问题，请参考 `分片上传最佳实践.md`。
