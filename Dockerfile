FROM runpod/worker-comfyui:5.2.0-base

# Устанавливаем ComfyUI-WanVideoWrapper и зависимости
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    cd ComfyUI-WanVideoWrapper && \
    pip install -r requirements.txt --no-cache-dir

# Конфиг путей к моделям на Network Volume
RUN cat > /comfyui/extra_model_paths.yaml << 'YAML'
wan2_volume:
  base_path: /runpod-volume/
  checkpoints: models/checkpoints/
  vae: models/vae/
  text_encoders: models/text_encoders/
  clip: models/clip/
YAML

CMD ["/start.sh"]
