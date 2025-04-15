### --- Stage 1: Build whisper.cpp ---
  FROM ubuntu:22.04 as whisper-builder

  RUN apt-get update && apt-get install -y \
    build-essential cmake curl git && \
    rm -rf /var/lib/apt/lists/*
  
  WORKDIR /build
  RUN git clone https://github.com/ggerganov/whisper.cpp.git && \
      cd whisper.cpp && make && \
      mkdir -p whisper.cpp/models && \
      curl -L -o whisper.cpp/models/ggml-small.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
  
  ### --- Stage 2: Final API ---
  FROM node:18-slim
  
  WORKDIR /app
  
  # نصب ffmpeg برای تبدیل صوت
  RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*
  
  # کپی whisper.cpp آماده‌شده از مرحله اول
  COPY --from=whisper-builder /build/whisper.cpp ./whisper.cpp
  
  # نصب پکیج‌های Node.js
  COPY package*.json ./
  RUN npm install
  COPY server.js .
  
  # ساخت پوشه آپلود
  RUN mkdir uploads
  
  EXPOSE 5000
  CMD ["node", "server.js"]
  