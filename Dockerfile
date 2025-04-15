### --- Stage 1: Build whisper.cpp ---
  FROM ubuntu:22.04 as whisper-builder

  # نصب ابزارهای مورد نیاز برای ساخت whisper.cpp
  RUN apt-get update && apt-get install -y \
    build-essential cmake curl git && \
    rm -rf /var/lib/apt/lists/*
  
  # کلون whisper.cpp و ساخت فایل اجرایی
  WORKDIR /build
  RUN git clone https://github.com/ggerganov/whisper.cpp.git
  
  WORKDIR /build/whisper.cpp
  RUN make
  
  # دانلود مدل فارسی (small)
  RUN mkdir -p models && \
      curl -L -o models/ggml-small.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
  
  # اطمینان از ساخت صحیح فایل main
  RUN test -f ./main
  
  ---
  
  ### --- Stage 2: نهایی برای اجرای Node.js API ---
  FROM node:18-slim
  
  WORKDIR /app
  
  # نصب ffmpeg برای تبدیل فرمت‌های صوتی
  RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*
  
  # کپی whisper.cpp از مرحله‌ی اول
  COPY --from=whisper-builder /build/whisper.cpp ./whisper.cpp
  
  # کپی سورس Node.js
  COPY package*.json ./
  RUN npm install
  COPY server.js .
  
  # ساخت پوشه‌ی آپلود برای فایل‌ها
  RUN mkdir uploads
  
  EXPOSE 5000
  CMD ["node", "server.js"]
  