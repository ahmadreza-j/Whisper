import express from 'express';
import multer from 'multer';
import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// تعریف __dirname در ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const upload = multer({ dest: 'uploads/' });

app.post('/transcribe', upload.single('file'), (req, res) => {
  const file = req.file;
  if (!file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  const modelPath = 'models/ggml-small.bin';
  const outputTxt = file.path + '.txt';

  const whisper = spawn('./whisper.cpp/main', [
    '-m', modelPath,
    '-f', file.path,
    '-l', 'fa',
    '-otxt'
  ]);

  whisper.on('error', (err) => {
    console.error('❌ Failed to start whisper:', err);
    fs.unlink(file.path, () => {});
    return res.status(500).json({ error: 'Failed to execute whisper' });
  });

  whisper.on('close', (code) => {
    if (code !== 0) {
      console.error(`❌ Whisper exited with code ${code}`);
      fs.unlink(file.path, () => {});
      return res.status(500).json({ error: 'Whisper process failed' });
    }

    const txtPath = path.join(__dirname, 'whisper.cpp', outputTxt);

    fs.readFile(txtPath, 'utf8', (err, data) => {
      fs.unlink(file.path, () => {}); // پاک‌سازی فایل آپلود شده

      if (err) {
        console.error('❌ Error reading output file:', err);
        return res.status(500).json({ error: 'Transcription failed' });
      }

      res.json({ text: data.trim() });
    });
  });
});

app.listen(5000, () => {
  console.log('✅ Whisper API running on http://localhost:5000');
});
