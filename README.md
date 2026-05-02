# ComfyUI + Wan2 для RunPod Serverless

## Быстрый старт

1. Форкни этот репозиторий на GitHub
2. Добавь секреты в Settings → Secrets:
   - `DOCKERHUB_USERNAME` — твой логин на hub.docker.com
   - `DOCKERHUB_TOKEN` — Access Token из Docker Hub Settings
3. Запусти workflow вручную: Actions → Build and Push → Run workflow
4. Через ~15 минут образ появится на Docker Hub
5. В RunPod Serverless → Manage → Edit → Container image:
   `ТВОЙ_ЛОГИН/comfyui-wan2:latest`

## Структура моделей на Network Volume

```
/runpod-volume/
├── models/
│   ├── checkpoints/   ← diffusion_pytorch_model-*.safetensors
│   ├── vae/           ← Wan2.1_VAE.pth
│   └── text_encoders/ ← models_t5_umt5-xxl-enc-bf16.pth
```
