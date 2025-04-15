### --- Stage 1: build whisper.cpp ---
    FROM ubuntu:22.04 AS whisper-builder

    RUN apt-get update && apt-get install -y \
      build-essential cmake curl git && \
      rm -rf /var/lib/apt/lists/*
    
    WORKDIR /build
    RUN git clone https://github.com/ggerganov/whisper.cpp.git && \
        cd whisper.cpp && make
    
    ### --- Stage 2: final API ---
    FROM node:18-slim
    
    WORKDIR /app
    
    # نصب وابستگی‌های ضروری
    RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*
    
    # کپی whisper باینری از مرحله قبلی
    COPY --from=whisper-builder /build/whisper.cpp/main ./whisper.cpp/main
    COPY --from=whisper-builder /build/whisper.cpp/models ./whisper.cpp/models
    
    # کپی سورس API
    COPY package*.json ./
    RUN npm install
    COPY server.js .
    
    # ساخت پوشه آپلود
    RUN mkdir uploads
    
    EXPOSE 5000
    CMD ["node", "server.js"]
    