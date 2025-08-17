# ==== INSTALL COMFYUI (Updated 2025) ====

cd /workspace
# Клонируем свежую версию
git clone https://github.com/comfyanonymous/ComfyUI.git
cd /workspace/ComfyUI/custom_nodes

# Ставим ComfyUI-Manager (для управления нодами)
git clone https://github.com/ltdrdata/ComfyUI-Manager.git

cd /workspace/ComfyUI

# Создаём виртуальное окружение
python3 -m venv venv
source venv/bin/activate

# Устанавливаем актуальный PyTorch (CUDA 12.1)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Устанавливаем xformers (стабильный релиз)
pip install xformers -U

# Основные зависимости ComfyUI
pip install -r requirements.txt

# Дополнительные полезные пакеты (для новых узлов в 2025)
pip install onnxruntime-gpu safetensors accelerate transformers tqdm

# ==== START COMFYUI ====
apt update -y
apt install -y psmisc

# Убиваем процесс, если порт 3000 занят
fuser -k 1111/tcp || true

# Запуск ComfyUI
cd /workspace/ComfyUI
source venv/bin/activate
python main.py --listen 0.0.0.0 --port 1111


