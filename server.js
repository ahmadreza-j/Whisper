const express = require('express');
const multer = require('multer');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const app = express();
const upload = multer({ dest: 'uploads/' });

app.post('/transcribe', upload.single('file'), async (req, res) => {
  const file = req.file;
  if (!file) return res.status(400).json({ error: 'No file uploaded' });

  const modelPath = 'models/ggml-small.bin';
  const outputTxt = file.path + '.txt';

  const whisper = spawn('./main', ['-m', modelPath, '-f', file.path, '-l', 'fa', '-otxt'], {
    cwd: 'whisper.cpp'
  });

  whisper.on('close', (code) => {
    if (code !== 0) return res.status(500).json({ error: 'Transcription failed' });

    fs.readFile(path.join('whisper.cpp', outputTxt), 'utf8', (err, data) => {
      fs.unlinkSync(file.path); // پاک کردن فایل آپلودشده
      if (err) return res.status(500).json({ error: 'Output not found' });
      res.json({ text: data.trim() });
    });
  });
});

app.listen(5000, () => {
  console.log('Whisper API running on http://localhost:5000');
});
