FROM runpod/worker-comfyui:5.2.0-base

# Устанавливаем WanVideoWrapper при сборке
RUN cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    pip install -r ComfyUI-WanVideoWrapper/requirements.txt --no-cache-dir && \
    echo "Nodes installed:" && \
    ls /comfyui/custom_nodes/

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /handler.py

# Простой старт без set -e
RUN echo '#!/bin/bash' > /start_custom.sh && \
    echo 'echo "=== Custom nodes:"' >> /start_custom.sh && \
    echo 'ls /comfyui/custom_nodes/' >> /start_custom.sh && \
    echo 'cd /comfyui' >> /start_custom.sh && \
    echo 'python main.py --listen 0.0.0.0 --port 8188 &' >> /start_custom.sh && \
    echo 'sleep 45' >> /start_custom.sh && \
    echo 'python -u /handler.py' >> /start_custom.sh && \
    chmod +x /start_custom.sh

CMD ["/start_custom.sh"]
