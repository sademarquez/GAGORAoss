#!/bin/bash
# build_models.sh - Build sin ejecutar

set -e

# Verificar memoria disponible
available_ram=$(free -g | awk '/^Mem:/{print $7}')
if [ $available_ram -lt 3 ]; then
    echo "❌ Necesitas al menos 3GB RAM libres"
    echo " Cierra aplicaciones o añade swap"
    exit 1
fi

echo " Iniciando build de modelos..."

# Build GPT-OSS 1B (Factible con 4GB)
echo " Building GPT-OSS 1B..."
docker build \
    --build-arg MODEL_SIZE=1b \
    --memory=3g \
    --memory-swap=6g \
    -t agora/gpt-oss-1b:latest \
    .

# Exportar a Ollama
echo " Exportando a Ollama..."
docker run --rm \
    -v $(pwd)/ollama_models:/export \
    agora/gpt-oss-1b:latest \
    cp -r /model/ /export/gpt-oss-1b/

# Importar en Ollama
ollama create agora-gpt-1b -f ollama_models/gpt-oss-1b/Modelfile

echo "✅ GPT-OSS 1B listo en Ollama!"

# Build GPT-OSS 7B (Requiere Swap)
if [ $(swapon --show | wc -l) -gt 1 ]; then
    echo " Building GPT-OSS 7B con Swap..."
    
    # Configurar límites más conservadores
    docker build \
        --build-arg MODEL_SIZE=7b \
        --memory=3g \
        --memory-swap=10g \
        --cpu-period=100000 \
        --cpu-quota=200000 \
        -t agora/gpt-oss-7b:latest \
        .
    
    echo "⚠️ Build completado (lento por swap)"
else
    echo "⚠️ Saltando GPT-OSS 7B - configura swap primero"
fi

# GPT-OSS 20B - Solo via CI/CD
echo " GPT-OSS 20B requiere build externo"
echo " Configura GitHub Actions para este modelo"

echo " Build completado!"
