FROM runpod/worker-comfyui:5.2.0-base

# Устанавливаем WanVideoWrapper в безопасное место вне /comfyui/
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git \
        /opt/wanvideo/ComfyUI-WanVideoWrapper && \
    pip install -r /opt/wanvideo/ComfyUI-WanVideoWrapper/requirements.txt \
        --no-cache-dir && \
    echo "Installed to /opt/wanvideo/"

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /handler.py

RUN echo '#!/bin/bash' > /start_custom.sh && \
    echo '# Создаём симлинк при каждом старте' >> /start_custom.sh && \
    echo 'mkdir -p /comfyui/custom_nodes' >> /start_custom.sh && \
    echo 'ln -sfn /opt/wanvideo/ComfyUI-WanVideoWrapper /comfyui/custom_nodes/ComfyUI-WanVideoWrapper' >> /start_custom.sh && \
    echo 'echo "Custom nodes: $(ls /comfyui/custom_nodes/)"' >> /start_custom.sh && \
    echo 'cd /comfyui' >> /start_custom.sh && \
    echo 'python main.py --listen 0.0.0.0 --port 8188 &' >> /start_custom.sh && \
    echo 'sleep 45' >> /start_custom.sh && \
    echo 'python -u /handler.py' >> /start_custom.sh && \
    chmod +x /start_custom.sh

CMD ["/start_custom.sh"]
