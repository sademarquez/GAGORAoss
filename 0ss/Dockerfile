# Multi-stage ultra-eficiente
FROM python:3.11-slim AS base
WORKDIR /app

# Stage 1: Download (solo descarga, no carga en RAM)
FROM base AS downloader
RUN pip install --no-cache-dir huggingface_hub
COPY scripts/download_model.py .
# Descarga sin cargar en memoria
RUN python download_model.py --model-size=${MODEL_SIZE} --download-only

# Stage 2: Optimize (procesa en chunks)
FROM base AS optimizer  
COPY --from=downloader /app/models/ ./models/
COPY scripts/optimize_lowram.py .
# Procesa modelo en pedazos pequeños
RUN python optimize_lowram.py --model-size=${MODEL_SIZE} --max-ram=2GB

# Stage 3: Package para Ollama
FROM base AS ollama-package
COPY --from=optimizer /app/optimized/ ./model/
COPY scripts/to_ollama_format.py .
RUN python to_ollama_format.py --model-size=${MODEL_SIZE}

# Stage 4: Final (solo archivos, sin modelo en RAM)
FROM alpine:latest AS final
COPY --from=ollama-package /app/ollama_model/ /model/
COPY scripts/deploy.sh /deploy.sh
# NO ejecuta el modelo, solo lo empaqueta
CMD ["/deploy.sh"]