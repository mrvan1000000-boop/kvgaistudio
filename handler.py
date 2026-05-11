import runpod, json, base64, os, glob, time, urllib.request

COMFYUI = "http://127.0.0.1:8188"

def wait_comfyui(max_sec=120):
    for _ in range(max_sec):
        try:
            urllib.request.urlopen(f"{COMFYUI}/system_stats", timeout=2)
            return True
        except:
            time.sleep(1)
    return False

def upload_image(image_b64: str, filename: str = "input_image.jpg") -> str:
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
    print(f"Uploaded image: {result['name']}")
    return result["name"]

def queue_prompt(workflow):
    data = json.dumps({"prompt": workflow}).encode()
    req = urllib.request.Request(f"{COMFYUI}/prompt", data=data,
                                  headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())["prompt_id"]
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        raise RuntimeError(f"ComfyUI 400: {body}")

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

def handler(job):
    job_input = job.get("input", {})
    workflow  = job_input.get("workflow")
    image_b64 = job_input.get("image_b64")

    if not workflow:
        return {"error": "No workflow"}

    if not wait_comfyui():
        return {"error": "ComfyUI not ready"}

    # Если есть изображение — загружаем в ComfyUI
    if image_b64:
        try:
            img_name = upload_image(image_b64)
            if "11" in workflow:
                workflow["11"]["inputs"]["image"] = img_name
        except Exception as e:
            return {"error": f"Image upload failed: {e}"}

    prompt_id = queue_prompt(workflow)
    print(f"Queued: {prompt_id}")

    result = poll_done(prompt_id)
    if result is None:
        return {"error": "Timeout"}

    status = result.get("status", {})
    if status.get("status_str") == "error":
        return {"error": str(status.get("messages", "unknown"))}

    out_dir = "/comfyui/output"
    mp4s = sorted(glob.glob(f"{out_dir}/**/*.mp4", recursive=True) +
                  glob.glob(f"{out_dir}/*.mp4"),
                  key=os.path.getmtime)

    if not mp4s:
        files = os.listdir(out_dir) if os.path.exists(out_dir) else []
        return {"error": "No mp4 found", "files": files}

    path = mp4s[-1]
    size = os.path.getsize(path)
    print(f"Video: {path} ({size} bytes)")

    with open(path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode()
    os.remove(path)
    return {"video_b64": b64, "size": size}

runpod.serverless.start({"handler": handler})
