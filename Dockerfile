FROM runpod/worker-comfyui:5.8.5-base-cuda12.8.1

# ───────────────────────────────────────────────
# 1. Кастомные ноды
# ───────────────────────────────────────────────
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git \
        /opt/wanvideo/ComfyUI-WanVideoWrapper && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
        /opt/vhs/ComfyUI-VideoHelperSuite && \
    git clone --depth 1 https://github.com/SkyReels/ComfyUI-SkyReelsWrapper.git \
        /opt/skyreels/ComfyUI-SkyReelsWrapper && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-LTXVideo.git \
        /opt/ltx/ComfyUI-LTXVideo && \
    git clone --depth 1 https://github.com/Acly/comfyui-upscale.git \
        /opt/upscale/ComfyUI-Upscale

# ───────────────────────────────────────────────
# 2. Зависимости
# ───────────────────────────────────────────────
RUN /opt/venv/bin/pip install \
        einops imageio scipy torchvision accelerate gguf ftfy diffusers \
        transformers sentencepiece tokenizers huggingface-hub \
        opencv-python-headless av imageio-ffmpeg runpod \
        --no-cache-dir --quiet && \
    /opt/venv/bin/pip install -r /opt/wanvideo/ComfyUI-WanVideoWrapper/requirements.txt \
        --no-cache-dir --quiet || true && \
    /opt/venv/bin/pip install -r /opt/vhs/ComfyUI-VideoHelperSuite/requirements.txt \
        --no-cache-dir --quiet || true && \
    /opt/venv/bin/pip install -r /opt/skyreels/ComfyUI-SkyReels/requirements.txt \
        --no-cache-dir --quiet || true && \
    /opt/venv/bin/pip install -r /opt/ltx/ComfyUI-LTXVideo/requirements.txt \
        --no-cache-dir --quiet || true && \
    /opt/venv/bin/pip install -r /opt/upscale/ComfyUI-Upscale/requirements.txt \
        --no-cache-dir --quiet || true

# ───────────────────────────────────────────────
# 3. Конфиги и handler
# ───────────────────────────────────────────────
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /handler.py

# ───────────────────────────────────────────────
# 4. Стартовый скрипт
# ───────────────────────────────────────────────
RUN echo '#!/bin/bash' > /start_custom.sh && \
    echo 'set -e' >> /start_custom.sh && \
    echo 'echo "[INIT] Linking custom nodes..."' >> /start_custom.sh && \
    echo 'mkdir -p /comfyui/custom_nodes' >> /start_custom.sh && \
    echo 'ln -sfn /opt/wanvideo/ComfyUI-WanVideoWrapper /comfyui/custom_nodes/WanVideoWrapper' >> /start_custom.sh && \
    echo 'ln -sfn /opt/vhs/ComfyUI-VideoHelperSuite /comfyui/custom_nodes/VideoHelperSuite' >> /start_custom.sh && \
    echo 'ln -sfn /opt/skyreels/ComfyUI-SkyReels /comfyui/custom_nodes/SkyReels' >> /start_custom.sh && \
    echo 'ln -sfn /opt/ltx/ComfyUI-LTXVideo /comfyui/custom_nodes/LTXVideo' >> /start_custom.sh && \
    echo 'ln -sfn /opt/upscale/ComfyUI-Upscale /comfyui/custom_nodes/Upscale' >> /start_custom.sh && \
    echo '' >> /start_custom.sh && \
    echo 'echo "[INIT] Starting ComfyUI..."' >> /start_custom.sh && \
    echo 'cd /comfyui' >> /start_custom.sh && \
    echo '/opt/venv/bin/python main.py --listen 0.0.0.0 --port 8188 & ' >> /start_custom.sh && \
    echo '' >> /start_custom.sh && \
    echo 'echo "[INIT] Waiting for ComfyUI warmup..."' >> /start_custom.sh && \
    echo 'sleep 40' >> /start_custom.sh && \
    echo '' >> /start_custom.sh && \
    echo 'echo "[INIT] Starting handler..."' >> /start_custom.sh && \
    echo '/opt/venv/bin/python -u /handler.py' >> /start_custom.sh && \
    chmod +x /start_custom.sh

CMD ["/start_custom.sh"]
