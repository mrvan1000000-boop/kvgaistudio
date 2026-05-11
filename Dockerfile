FROM runpod/worker-comfyui:5.8.5-base-cuda12.8.1

RUN apt-get update && apt-get install -y unzip curl && rm -rf /var/lib/apt/lists/*

# ── 1. WanVideoWrapper
RUN mkdir -p /opt/wanvideo && \
    curl -L https://github.com/kijai/ComfyUI-WanVideoWrapper/archive/refs/heads/main.zip \
         -o /tmp/wan.zip && \
    unzip /tmp/wan.zip -d /opt/wanvideo && \
    mv /opt/wanvideo/ComfyUI-WanVideoWrapper-* /opt/wanvideo/ComfyUI-WanVideoWrapper && \
    rm /tmp/wan.zip

# ── 2. VideoHelperSuite
RUN mkdir -p /opt/vhs && \
    curl -L https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite/archive/refs/heads/main.zip \
         -o /tmp/vhs.zip && \
    unzip /tmp/vhs.zip -d /opt/vhs && \
    mv /opt/vhs/ComfyUI-VideoHelperSuite-* /opt/vhs/ComfyUI-VideoHelperSuite && \
    rm /tmp/vhs.zip

# ── 3. LTXVideo
RUN mkdir -p /opt/ltx && \
    curl -L https://github.com/Lightricks/ComfyUI-LTXVideo/archive/refs/heads/master.zip \
         -o /tmp/ltx.zip && \
    unzip /tmp/ltx.zip -d /opt/ltx && \
    mv /opt/ltx/ComfyUI-LTXVideo-* /opt/ltx/ComfyUI-LTXVideo && \
    rm /tmp/ltx.zip

# ── 4. Python зависимости
RUN /opt/venv/bin/pip install \
        einops imageio scipy torchvision accelerate gguf ftfy diffusers \
        transformers sentencepiece tokenizers huggingface-hub \
        opencv-python-headless av imageio-ffmpeg runpod basicsr realesrgan \
        --no-cache-dir --quiet

RUN /opt/venv/bin/pip install \
        -r /opt/wanvideo/ComfyUI-WanVideoWrapper/requirements.txt \
        --no-cache-dir --quiet || true
RUN /opt/venv/bin/pip install \
        -r /opt/vhs/ComfyUI-VideoHelperSuite/requirements.txt \
        --no-cache-dir --quiet || true
RUN /opt/venv/bin/pip install \
        -r /opt/ltx/ComfyUI-LTXVideo/requirements.txt \
        --no-cache-dir --quiet || true

# ── 5. Конфиги
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /handler.py

# ── 6. Стартовый скрипт
RUN printf '#!/bin/bash\nset -e\n\
mkdir -p /comfyui/custom_nodes\n\
ln -sfn /opt/wanvideo/ComfyUI-WanVideoWrapper /comfyui/custom_nodes/WanVideoWrapper\n\
ln -sfn /opt/vhs/ComfyUI-VideoHelperSuite /comfyui/custom_nodes/VideoHelperSuite\n\
ln -sfn /opt/ltx/ComfyUI-LTXVideo /comfyui/custom_nodes/LTXVideo\n\
cd /comfyui\n\
/opt/venv/bin/python main.py --listen 0.0.0.0 --port 8188 &\n\
sleep 60\n\
/opt/venv/bin/python -u /handler.py\n' > /start_custom.sh && \
    chmod +x /start_custom.sh

CMD ["/start_custom.sh"]
