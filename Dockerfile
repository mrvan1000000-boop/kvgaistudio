FROM runpod/worker-comfyui:5.2.0-base

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    cd ComfyUI-WanVideoWrapper && \
    pip install -r requirements.txt --no-cache-dir

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /rp_handler.py

CMD ["/start.sh"]
