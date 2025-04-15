### --- Stage 1: Build whisper.cpp ---
  FROM ubuntu:22.04 as whisper-builder

  RUN apt-get update && apt-get install -y \
    build-essential cmake curl git && \
    rm -rf /var/lib/apt/lists/*
  
  WORKDIR /build
  RUN git clone https://github.com/ggerganov/whisper.cpp.git
  
  WORKDIR /build/whisper.cpp
  RUN make
  
  # دانلود مدل small (فارسی)
  RUN mkdir -p models && \
      curl -L -o models/ggml-small.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
  
  RUN test -f ./main
  
  # --- Stage 2: Final Node.js API ---
  FROM node:18-slim
  
  WORKDIR /app
  
  # نصب ffmpeg برای تبدیل صوت
  RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*
  
  # کپی whisper.cpp شامل main و مدل
  COPY --from=whisper-builder /build/whisper.cpp ./whisper.cpp
  
  # نصب Node.js dependencies
  COPY package*.json ./
  RUN npm install
  COPY server.js .
  
  # ساخت پوشه‌ی آپلود
  RUN mkdir uploads
  
  EXPOSE 5000
  CMD ["node", "server.js"]
  