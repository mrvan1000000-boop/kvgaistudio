import runpod, json, base64, os, glob, time, urllib.request

COMFYUI = "http://127.0.0.1:8188"

# ───────────────────────────────────────────────
# 1. Ждём ComfyUI
# ───────────────────────────────────────────────
def wait_comfyui(max_sec=120):
    for _ in range(max_sec):
        try:
            urllib.request.urlopen(f"{COMFYUI}/system_stats", timeout=2)
            return True
        except:
            time.sleep(1)
    return False


# ───────────────────────────────────────────────
# 2. Загрузка изображения
# ───────────────────────────────────────────────
def upload_image(image_b64: str, filename: str) -> str:
    img_bytes = base64.b64decode(image_b64)
    boundary = "FormBoundary7MA4YWxkTrZu0gW"

    body = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="image"; filename="{filename}"\r\n'
        f"Content-Type: image/jpeg\r\n\r\n"
    ).encode() + img_bytes + f"\r\n--{boundary}--\r\n".encode()

    req = urllib.request.Request(
        f"{COMFYUI}/upload/image",
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST"
    )

    with urllib.request.urlopen(req) as r:
        result = json.loads(r.read())

    print(f"[HANDLER] Uploaded {filename}: {result['name']}")
    return result["name"]


# ───────────────────────────────────────────────
# 3. Отправка workflow
# ───────────────────────────────────────────────
def queue_prompt(workflow):
    data = json.dumps({"prompt": workflow}).encode()
    req = urllib.request.Request(
        f"{COMFYUI}/prompt",
        data=data,
        headers={"Content-Type": "application/json"}
    )

    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())["prompt_id"]
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        raise RuntimeError(f"ComfyUI error: {body}")


# ───────────────────────────────────────────────
# 4. Ожидание результата
# ───────────────────────────────────────────────
def poll_done(prompt_id, timeout=3600):
    deadline = time.time() + timeout

    while time.time() < deadline:
        try:
            with urllib.request.urlopen(f"{COMFYUI}/history/{prompt_id}") as r:
                h = json.loads(r.read())
            if prompt_id in h:
                return h[prompt_id]
        except:
            pass

        time.sleep(3)

    return None


# ───────────────────────────────────────────────
# 5. Главный handler
# ───────────────────────────────────────────────
def handler(job):
    job_input = job.get("input", {})

    workflow        = job_input.get("workflow")
    face_b64        = job_input.get("face_image_b64")
    target_b64      = job_input.get("target_image_b64")
    control_b64     = job_input.get("control_image_b64")  # для motion control
    image_b64_legacy = job_input.get("image_b64")          # старый формат

    if not workflow:
        return {"error": "No workflow provided"}

    print("[HANDLER] Waiting for ComfyUI...")
    if not wait_comfyui():
        return {"error": "ComfyUI not ready"}

    # ───────────────────────────────────────────────
    # FaceSwap: source face
    # ───────────────────────────────────────────────
    if face_b64:
        try:
            face_name = upload_image(face_b64, "face.jpg")
            workflow["10"]["inputs"]["source_image"] = face_name
        except Exception as e:
            return {"error": f"Face upload failed: {e}"}

    # ───────────────────────────────────────────────
    # FaceSwap: target image
    # ───────────────────────────────────────────────
    if target_b64:
        try:
            target_name = upload_image(target_b64, "target.jpg")
            workflow["10"]["inputs"]["target_image"] = target_name

            # Motion Control (если нода использует image)
            for node_id, node in workflow.items():
                if isinstance(node, dict) and "inputs" in node:
                    if node["inputs"].get("image") == "__UPLOAD__":
                        node["inputs"]["image"] = target_name

        except Exception as e:
            return {"error": f"Target upload failed: {e}"}

    # ───────────────────────────────────────────────
    # Motion Control: control image (если есть)
    # ───────────────────────────────────────────────
    if control_b64:
        try:
            control_name = upload_image(control_b64, "control.jpg")

            # Подставляем в ноды 20/21 (pose/depth)
            for node_id in ["20", "21"]:
                if node_id in workflow:
                    if "image" in workflow[node_id]["inputs"]:
                        workflow[node_id]["inputs"]["image"] = control_name

        except Exception as e:
            return {"error": f"Control image upload failed: {e}"}

    # ───────────────────────────────────────────────
    # Legacy image_b64 (старый формат)
    # ───────────────────────────────────────────────
    if image_b64_legacy and not target_b64:
        try:
            img_name = upload_image(image_b64_legacy, "input.jpg")
            if "11" in workflow:
                workflow["11"]["inputs"]["image"] = img_name
        except Exception as e:
            return {"error": f"Legacy image upload failed: {e}"}

    # ───────────────────────────────────────────────
    # Запуск workflow
    # ───────────────────────────────────────────────
    prompt_id = queue_prompt(workflow)
    print(f"[HANDLER] Queued prompt: {prompt_id}")

    result = poll_done(prompt_id)
    if result is None:
        return {"error": "Timeout waiting for result"}

    status = result.get("status", {})
    if status.get("status_str") == "error":
        return {"error": str(status.get("messages", "unknown"))}

    # ───────────────────────────────────────────────
    # Ищем mp4
    # ───────────────────────────────────────────────
    out_dir = "/comfyui/output"

    mp4s = sorted(
        glob.glob(f"{out_dir}/**/*.mp4", recursive=True) +
        glob.glob(f"{out_dir}/*.mp4"),
        key=os.path.getmtime
    )

    if not mp4s:
        files = os.listdir(out_dir) if os.path.exists(out_dir) else []
        return {"error": "No mp4 found", "files": files}

    path = mp4s[-1]
    size = os.path.getsize(path)
    print(f"[HANDLER] Video ready: {path} ({size} bytes)")

    with open(path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode()

    os.remove(path)

    return {"video_b64": b64, "size": size}


# ───────────────────────────────────────────────
# 6. Запуск serverless handler
# ───────────────────────────────────────────────
runpod.serverless.start({"handler": handler})
