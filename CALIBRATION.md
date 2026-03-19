# Technical Calibration Guide for vLLM Startup

## Scope

This document defines technical constraints and startup recommendations for running vLLM with local models on GPUs with ~12 GB VRAM (e.g., NVIDIA RTX 4070 Ti).

## Observed Failure Modes

When loading 7B-class models on 12 GB VRAM, the following errors are expected if memory headroom is insufficient:

- **Weights load OOM**
  - Typical symptom: `torch.OutOfMemoryError` during model initialization.
- **KV cache allocation failure**
  - Typical symptom: `ValueError: No available memory for the cache blocks`.
  - Associated metric: `Available KV cache memory: < 0 GiB`.
- **Runtime allocation failure during profiling/compute**
  - Typical symptom: `RuntimeError: CUBLAS_STATUS_ALLOC_FAILED`.
  - Often triggered by profile runs or large batched token settings.

## Root Cause

7B-class models can consume most of the available VRAM for weights and runtime workspaces. Remaining memory may be insufficient for KV cache blocks and cuBLAS work buffers, especially under default scheduling and compilation paths.

## Operating Constraints (12 GB VRAM)

- Prefer `float16` for compatibility and lower memory.
- Keep `max_model_len` low during bootstrap.
- Limit scheduling pressure:
  - reduce `max-num-batched-tokens`
  - reduce `max-num-seqs`
- Use CPU offload as a stability lever (`--cpu-offload-gb`).
- If fragmentation/pike allocations occur, prefer eager mode (`--enforce-eager`).

## Recommended Startup Profiles

Profiles are ordered by stability (from normal to restrictive):

1. **balanced-stable**
   - `dtype=float16`
   - `max_model_len=1024`
   - `gpu_memory_utilization=0.82`
   - `cpu_offload_gb=4`
   - `--enforce-eager --max-num-batched-tokens 256 --max-num-seqs 4`

2. **aggressive-stable**
   - `dtype=float16`
   - `max_model_len=768`
   - `gpu_memory_utilization=0.88`
   - `cpu_offload_gb=6`
   - `--enforce-eager --max-num-batched-tokens 192 --max-num-seqs 3`

3. **safe-eager**
   - `dtype=float16`
   - `max_model_len=512`
   - `gpu_memory_utilization=0.92`
   - `cpu_offload_gb=8`
   - `--enforce-eager --max-num-batched-tokens 128 --max-num-seqs 2`

4. **ultra-min**
   - `dtype=float16`
   - `max_model_len=256`
   - `gpu_memory_utilization=0.97`
   - `cpu_offload_gb=8`
   - `--enforce-eager --max-num-batched-tokens 64 --max-num-seqs 1`

## Model Selection Guidance

For production-like stability on 12 GB VRAM:

- Prefer 3B-class models (e.g., `Qwen/Qwen2.5-3B-Instruct`) for predictable startup and lower tuning overhead.
- Use 7B-class models only if required by quality targets, accepting tighter memory margins and stricter runtime limits.

## Validation Checklist

After startup:

1. API health check responds: `GET /v1/models`
2. GPU process is visible in `nvidia-smi`
3. VRAM usage remains below hard OOM threshold during first prompt
4. No repeated `EngineCore failed to start` in runtime logs
