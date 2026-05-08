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

def queue_prompt(workflow):
    data = json.dumps({"prompt": workflow}).encode()
    req  = urllib.request.Request(f"{COMFYUI}/prompt", data=data,
                                   headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())["prompt_id"]

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
    workflow = job.get("input", {}).get("workflow")
    if not workflow:
        return {"error": "No workflow"}

    if not wait_comfyui():
        return {"error": "ComfyUI not ready"}

    prompt_id = queue_prompt(workflow)
    print(f"Queued: {prompt_id}")

    result = poll_done(prompt_id)
    if result is None:
        return {"error": "Timeout"}

    # Проверяем ошибки ComfyUI
    status = result.get("status", {})
    if status.get("status_str") == "error":
        return {"error": str(status.get("messages", "unknown"))}

    # Ищем mp4 файл
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
