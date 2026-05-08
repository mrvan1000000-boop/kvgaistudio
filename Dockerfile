FROM runpod/worker-comfyui:5.2.0-base

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    cd ComfyUI-WanVideoWrapper && \
    pip install -r requirements.txt --no-cache-dir

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /handler.py

# Создаём свой start скрипт
RUN echo '#!/bin/bash\n\
echo "Starting ComfyUI..."\n\
python /comfyui/main.py --listen 0.0.0.0 --port 8188 &\n\
echo "Waiting for ComfyUI..."\n\
sleep 30\n\
echo "Starting handler..."\n\
python -u /handler.py' > /start_custom.sh && \
    chmod +x /start_custom.sh

CMD ["/start_custom.sh"]
