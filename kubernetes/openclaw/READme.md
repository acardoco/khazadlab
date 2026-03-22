kubectl label node andres-worker-2 workload=ai
## necesario crear docker-registry con token de read:packages

## descargar modelo
kubectl -n ai-ops exec -it deploy/ollama -- ollama pull gemma3:1b

## y comprobar
kubectl -n ai-ops exec -it deploy/ollama -- ollama list

## sobre los modelos
gemma3:1b — Ollama publica esa variante con 815 MB y 32K de contexto.

llama3.2:1b — Ollama publica esa variante con 1.3 GB y 128K de contexto.

qwen2.5:0.5b — existe en Ollama y tiene versión alrededor de 398 MB en la librería.

# instalar canal de whatsapp
kubectl -n ai-ops exec -it deploy/openclaw -- openclaw plugins install @openclaw/whatsapp