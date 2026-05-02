FROM runpod/worker-comfyui:5.8.5-base

RUN cd /comfyui/custom_nodes && \
    git clone --depth=1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    cd ComfyUI-WanVideoWrapper && \
    pip install -r requirements.txt --no-cache-dir

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

CMD ["/start.sh"]
