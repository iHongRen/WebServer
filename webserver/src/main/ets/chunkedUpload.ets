import { fileIo } from '@kit.CoreFileKit';
import { HttpRequest } from './HttpRequest';
import { HttpResponse } from './HttpResponse';
import { NextFunction } from './WebServer';
import { Utils } from './Utils';

export async function checkChunk(req: HttpRequest, res: HttpResponse, next: NextFunction) {
  const query = req.query

  const flowChunkNumber = query.get('flowChunkNumber')
  const flowIdentifier = query.get('flowIdentifier')

  const tempUploadsRoot = req.getConfig('tempUploadsRoot');

  if (!flowChunkNumber || !flowIdentifier || !tempUploadsRoot) {
    return res.status(400).send('Missing required query parameters or server configuration.');
  }

  const chunkDir = `${tempUploadsRoot}/${flowIdentifier}`;
  const chunkPath = `${chunkDir}/chunk_${flowChunkNumber}`;

  try {
    await fileIo.access(chunkPath);
    res.status(200).send('Chunk exists.');
  } catch (e) {
    res.status(404).send('Chunk not found.');
  }
}

export async function handleChunkUpload(req: HttpRequest, res: HttpResponse, next: NextFunction) {
  const body = req.body as Record<string, string>;
  const flowChunkNumber = body.flowChunkNumber
  const flowTotalChunks = body.flowTotalChunks
  const flowIdentifier = body.flowIdentifier
  const flowFilename = body.flowFilename

  const file = req.files['file'];
  const tempUploadsRoot = req.getConfig('tempUploadsRoot');

  if (!flowChunkNumber || !flowTotalChunks || !flowIdentifier || !flowFilename || !file || !tempUploadsRoot) {
    return res.status(400).send('Missing required form fields, file, or server configuration.');
  }

  const chunkDir = `${tempUploadsRoot}/${flowIdentifier}`;
  const chunkPath = `${chunkDir}/chunk_${flowChunkNumber}`;

  try {
    if (!await fileIo.access(chunkDir)) {
      await fileIo.mkdir(chunkDir);
    }

    const fileStream = await fileIo.open(chunkPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    await fileIo.write(fileStream.fd, file.data);
    await fileIo.close(fileStream);

    const filesInDir = await fileIo.listFile(chunkDir);
    if (filesInDir.length === parseInt(flowTotalChunks, 10)) {
      await combineChunks(req, flowIdentifier, flowFilename, parseInt(flowTotalChunks, 10));
    }

    res.status(200).send('Chunk uploaded successfully.');
  } catch (error) {
    next(error);
  }
}

async function combineChunks(req: HttpRequest, identifier: string, filename: string, totalChunks: number) {
  const staticFilesRoot = req.getConfig('staticFilesRoot');
  const tempUploadsRoot = req.getConfig('tempUploadsRoot');
  const sanitizedFilename = Utils.sanitizeFilename(filename);
  const finalFilePath = `${staticFilesRoot}/${sanitizedFilename}`;
  const chunkDir = `${tempUploadsRoot}/${identifier}`;

  try {
    const finalFile = await fileIo.open(finalFilePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);

    for (let i = 1; i <= totalChunks; i++) {
      const chunkPath = `${chunkDir}/chunk_${i}`;
      const chunkStat = await fileIo.stat(chunkPath);
      const chunkBuffer = new ArrayBuffer(chunkStat.size);
      const chunkFile = await fileIo.open(chunkPath, fileIo.OpenMode.READ_ONLY);
      await fileIo.read(chunkFile.fd, chunkBuffer);
      await fileIo.write(finalFile.fd, chunkBuffer);
      await fileIo.close(chunkFile.fd);
      await fileIo.unlink(chunkPath);
    }

    await fileIo.close(finalFile.fd);
    await fileIo.rmdir(chunkDir);

    console.log(`File combined successfully: ${finalFilePath}`);
  } catch (error) {
    console.error('Error combining chunks:', error);
  }
}
