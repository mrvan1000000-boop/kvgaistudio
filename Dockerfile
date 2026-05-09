FROM runpod/worker-comfyui:5.2.0-base

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /handler.py

RUN printf '#!/bin/bash\n\
set -e\n\
echo "=== Checking WanVideoWrapper ==="\n\
if [ ! -d "/comfyui/custom_nodes/ComfyUI-WanVideoWrapper" ]; then\n\
    echo "Installing WanVideoWrapper..."\n\
    cd /comfyui/custom_nodes\n\
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git\n\
    pip install -r ComfyUI-WanVideoWrapper/requirements.txt --no-cache-dir\n\
    echo "Done!"\n\
else\n\
    echo "WanVideoWrapper already installed"\n\
fi\n\
echo "=== Starting ComfyUI ==="\n\
cd /comfyui\n\
python main.py --listen 0.0.0.0 --port 8188 &\n\
echo "Waiting 40s for ComfyUI + nodes to load..."\n\
sleep 40\n\
echo "=== Starting handler ==="\n\
python -u /handler.py\n' > /start_custom.sh && chmod +x /start_custom.sh

CMD ["/start_custom.sh"]
