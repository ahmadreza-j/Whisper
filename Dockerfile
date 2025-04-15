### --- Stage 1: Build whisper.cpp ---
  FROM ubuntu:22.04 as whisper-builder

  RUN apt-get update && apt-get install -y \
    build-essential cmake curl git && \
    rm -rf /var/lib/apt/lists/*
  
  WORKDIR /build
  RUN git clone https://github.com/ggerganov/whisper.cpp.git
  
  WORKDIR /build/whisper.cpp
  RUN make || (echo "❌ Make failed" && ls -l && exit 1)
  
  RUN mkdir -p models && \
      curl -L -o models/ggml-small.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
  
  # --- Stage 2: Final Node.js API ---
  FROM node:18-slim
  
  WORKDIR /app
  
  RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*
  
  COPY --from=whisper-builder /build/whisper.cpp ./whisper.cpp
  
  COPY package*.json ./
  RUN npm install
  COPY server.js .
  
  RUN mkdir uploads
  
  EXPOSE 5000
  CMD ["node", "server.js"]
  