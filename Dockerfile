FROM runpod/worker-comfyui:5.8.5-base-cuda12.8.1

# ───────────────────────────────────────────────
# 0. Устанавливаем unzip и curl
# ───────────────────────────────────────────────
RUN apt-get update && apt-get install -y unzip curl && rm -rf /var/lib/apt/lists/*

# ───────────────────────────────────────────────
# 1. WANVideoWrapper
# ───────────────────────────────────────────────
RUN mkdir -p /opt/wanvideo && \
    curl -L https://github.com/kijai/ComfyUI-WanVideoWrapper/archive/refs/heads/main.zip -o /tmp/wan.zip && \
    unzip /tmp/wan.zip -d /opt/wanvideo && \
    mv /opt/wanvideo/ComfyUI-WanVideoWrapper-* /opt/wanvideo/ComfyUI-WanVideoWrapper && \
    rm /tmp/wan.zip

# ───────────────────────────────────────────────
# 2. VideoHelperSuite
# ───────────────────────────────────────────────
RUN mkdir -p /opt/vhs && \
    curl -L https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite/archive/refs/heads/main.zip -o /tmp/vhs.zip && \
    unzip /tmp/vhs.zip -d /opt/vhs && \
    mv /opt/vhs/ComfyUI-VideoHelperSuite-* /opt/vhs/ComfyUI-VideoHelperSuite && \
    rm /tmp/vhs.zip

# ───────────────────────────────────────────────
# 3. SkyReelsWrapper
# ───────────────────────────────────────────────
RUN mkdir -p /opt/skyreels && \
    curl -L https://github.com/SkyReels/ComfyUI-SkyReelsWrapper/archive/refs/heads/main.zip -o /tmp/sky.zip && \
    unzip /tmp/sky.zip -d /opt/skyreels && \
    mv /opt/skyreels/ComfyUI-SkyReelsWrapper-* /opt/skyreels/ComfyUI-SkyReelsWrapper && \
    rm /tmp/sky.zip

# ───────────────────────────────────────────────
# 4. LTXVideo
# ───────────────────────────────────────────────
RUN mkdir -p /opt/ltx && \
    curl -L https://github.com/ArtVentureX/ComfyUI-LTXVideo/archive/refs/heads/main.zip -o /tmp/ltx.zip && \
    unzip /tmp/ltx.zip -d /opt/ltx && \
    mv /opt/ltx/ComfyUI-LTXVideo-* /opt/ltx/ComfyUI-LTXVideo && \
    rm /tmp/ltx.zip

# ───────────────────────────────────────────────
# 5. Python зависимости
# ───────────────────────────────────────────────
RUN /opt/venv/bin/pip install \
        einops imageio scipy torchvision accelerate gguf ftfy diffusers \
        transformers sentencepiece tokenizers huggingface-hub \
        opencv-python-headless av imageio-ffmpeg runpod basicsr realesrgan \
        --no-cache-dir --quiet

RUN /opt/venv/bin/pip install -r /opt/wanvideo/ComfyUI-WanVideoWrapper/requirements.txt --no-cache-dir --quiet || true
RUN /opt/venv/bin/pip install -r /opt/vhs/ComfyUI-VideoHelperSuite/requirements.txt --no-cache-dir --quiet || true
RUN /opt/venv/bin/pip install -r /opt/skyreels/ComfyUI-SkyReelsWrapper/requirements.txt --no-cache-dir --quiet || true
RUN /opt/venv/bin/pip install -r /opt/ltx/ComfyUI-LTXVideo/requirements.txt --no-cache-dir --quiet || true

# ───────────────────────────────────────────────
# 6. Конфиги и handler
# ───────────────────────────────────────────────
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /handler.py

# ───────────────────────────────────────────────
# 7. Стартовый скрипт
# ───────────────────────────────────────────────
RUN echo '#!/bin/bash' > /start_custom.sh && \
    echo 'set -e' >> /start_custom.sh && \
    echo 'mkdir -p /comfyui/custom_nodes' >> /start_custom.sh && \
    echo 'ln -sfn /opt/wanvideo/ComfyUI-WanVideoWrapper /comfyui/custom_nodes/WanVideoWrapper' >> /start_custom.sh && \
    echo 'ln -sfn /opt/vhs/ComfyUI-VideoHelperSuite /comfyui/custom_nodes/VideoHelperSuite' >> /start_custom.sh && \
    echo 'ln -sfn /opt/skyreels/ComfyUI-SkyReelsWrapper /comfyui/custom_nodes/SkyReels' >> /start_custom.sh && \
    echo 'ln -sfn /opt/ltx/ComfyUI-LTXVideo /comfyui/custom_nodes/LTXVideo' >> /start_custom.sh && \
    echo 'cd /comfyui' >> /start_custom.sh && \
    echo '/opt/venv/bin/python main.py --listen 0.0.0.0 --port 8188 & ' >> /start_custom.sh && \
    echo 'sleep 40' >> /start_custom.sh && \
    echo '/opt/venv/bin/python -u /handler.py' >> /start_custom.sh && \
    chmod +x /start_custom.sh

CMD ["/start_custom.sh"]
