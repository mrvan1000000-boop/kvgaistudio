FROM runpod/worker-comfyui:5.8.5-base-cuda12.8.1

# Обновляем ComfyUI для поддержки OpenCLIP XLM-RoBERTa
RUN cd /comfyui && git fetch origin master && git reset --hard origin/master

RUN git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git \
        /opt/wanvideo/ComfyUI-WanVideoWrapper && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
        /opt/vhs/ComfyUI-VideoHelperSuite

RUN /opt/venv/bin/pip install einops imageio scipy torchvision accelerate gguf ftfy diffusers \
        transformers sentencepiece tokenizers huggingface-hub \
        opencv-python-headless av imageio-ffmpeg runpod \
        --no-cache-dir --quiet && \
    /opt/venv/bin/pip install -r /opt/wanvideo/ComfyUI-WanVideoWrapper/requirements.txt \
        --no-cache-dir --ignore-errors --quiet || true && \
    /opt/venv/bin/pip install -r /opt/vhs/ComfyUI-VideoHelperSuite/requirements.txt \
        --no-cache-dir --quiet || true

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /handler.py

RUN echo '#!/bin/bash' > /start_custom.sh && \
    echo 'mkdir -p /comfyui/custom_nodes' >> /start_custom.sh && \
    echo 'ln -sfn /opt/wanvideo/ComfyUI-WanVideoWrapper /comfyui/custom_nodes/ComfyUI-WanVideoWrapper' >> /start_custom.sh && \
    echo 'ln -sfn /opt/vhs/ComfyUI-VideoHelperSuite /comfyui/custom_nodes/ComfyUI-VideoHelperSuite' >> /start_custom.sh && \
    echo 'cd /comfyui' >> /start_custom.sh && \
    echo '/opt/venv/bin/python main.py --listen 0.0.0.0 --port 8188 &' >> /start_custom.sh && \
    echo 'sleep 45' >> /start_custom.sh && \
    echo '/opt/venv/bin/python -u /handler.py' >> /start_custom.sh && \
    chmod +x /start_custom.sh

CMD ["/start_custom.sh"]
