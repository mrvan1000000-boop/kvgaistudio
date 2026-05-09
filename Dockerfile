FROM runpod/worker-comfyui:5.2.0-base

RUN git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git \
        /opt/wanvideo/ComfyUI-WanVideoWrapper

RUN pip install einops imageio scipy torchvision --no-cache-dir --quiet

RUN pip install -r /opt/wanvideo/ComfyUI-WanVideoWrapper/requirements.txt \
        --no-cache-dir --ignore-errors --quiet || true

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /handler.py

RUN echo '#!/bin/bash' > /start_custom.sh && \
    echo 'mkdir -p /comfyui/custom_nodes' >> /start_custom.sh && \
    echo 'ln -sfn /opt/wanvideo/ComfyUI-WanVideoWrapper /comfyui/custom_nodes/ComfyUI-WanVideoWrapper' >> /start_custom.sh && \
    echo 'echo "Nodes: $(ls /comfyui/custom_nodes/)"' >> /start_custom.sh && \
    echo 'cd /comfyui' >> /start_custom.sh && \
    echo 'python main.py --listen 0.0.0.0 --port 8188 &' >> /start_custom.sh && \
    echo 'sleep 45' >> /start_custom.sh && \
    echo 'python -u /handler.py' >> /start_custom.sh && \
    chmod +x /start_custom.sh

CMD ["/start_custom.sh"]
