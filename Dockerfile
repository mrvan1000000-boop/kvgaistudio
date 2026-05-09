FROM runpod/worker-comfyui:5.2.0-base

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    cd ComfyUI-WanVideoWrapper && \
    pip install -r requirements.txt --no-cache-dir

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /handler.py

RUN printf '#!/bin/bash\ncd /comfyui\npython main.py --listen 0.0.0.0 --port 8188 &\necho "Waiting for ComfyUI..."\nsleep 30\necho "Starting handler..."\npython -u /handler.py\n' > /start_custom.sh && \
    chmod +x /start_custom.sh

CMD ["/start_custom.sh"]
