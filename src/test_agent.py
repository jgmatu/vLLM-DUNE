#!/usr/bin/env python3
import json
import os
import sys
import urllib.error
import urllib.request


def main() -> int:
    base_url = os.getenv("VLLM_BASE_URL", "http://localhost:8000")
    model = os.getenv("VLLM_MODEL", "Qwen2.5-7B-Instruct")
    stream = False
    max_tokens = int(os.getenv("MAX_TOKENS", "128"))
    args = sys.argv[1:]
    if "--stream" in args:
        stream = True
        args = [a for a in args if a != "--stream"]
    if "--max-tokens" in args:
        idx = args.index("--max-tokens")
        if idx + 1 >= len(args):
            print("ERROR: --max-tokens requires a value")
            return 1
        max_tokens = int(args[idx + 1])
        args = [a for i, a in enumerate(args) if i not in (idx, idx + 1)]
    prompt = " ".join(args).strip() or "Di hola en una linea."

    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": "Eres un asistente util y breve."},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.2,
        "max_tokens": max_tokens,
        "stream": stream,
    }

    url = f"{base_url.rstrip('/')}/v1/chat/completions"
    req = urllib.request.Request(
        url=url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            if stream:
                print("=== Stream (anon) ===")
                for raw in resp:
                    line = raw.decode("utf-8", errors="replace").strip()
                    if not line.startswith("data: "):
                        continue
                    data_part = line[6:]
                    if data_part == "[DONE]":
                        break
                    try:
                        evt = json.loads(data_part)
                        delta = evt.get("choices", [{}])[0].get("delta", {}).get("content", "")
                        if delta:
                            print(delta, end="", flush=True)
                    except Exception:
                        continue
                print()
                return 0
            body = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        err = exc.read().decode("utf-8", errors="replace")
        print(f"HTTPError {exc.code}: {err}")
        return 1
    except Exception as exc:
        print(f"Request failed: {exc}")
        return 1

    data = json.loads(body)
    choices = data.get("choices", [])
    if not choices:
        print("No choices in response:")
        print(body)
        return 1

    text = choices[0].get("message", {}).get("content", "").strip()
    print("=== Prompt ===")
    print(prompt)
    print("\n=== Model ===")
    print(model)
    print("\n=== Response ===")
    print(text or "(empty response)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
