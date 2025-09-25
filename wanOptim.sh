#!/bin/bash
set -euo pipefail

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

APT_PACKAGES=(
    # "package-1"
    # "package-2"
)

PIP_PACKAGES=(
    # "package-1"
    # "package-2"
)

NODES=(
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
    "https://github.com/city96/ComfyUI-GGUF"
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/cubiq/ComfyUI_essentials"
)

WORKFLOWS=(
    "https://raw.githubusercontent.com/XXXXRomanXXXX/Script/refs/heads/main/Wan%202.2%20Lightning%20Olivio.json"
)

CLIP_MODELS=(
    "https://huggingface.co/chatpig/encoder/resolve/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors?download=true"
)

UNET_MODELS=(
    "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/HighNoise/Wan2.2-I2V-A14B-HighNoise-Q6_K.gguf?download=true"
    "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/LowNoise/Wan2.2-I2V-A14B-LowNoise-Q6_K.gguf?download=true"
)

LORAS_MODELS=(
    "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/high_noise_model.safetensors?download=true"
    "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/low_noise_model.safetensors?download=true"
)

VAE_MODELS=(
    "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/VAE/Wan2.1_VAE.safetensors?download=true"
)

UPDATE=(
    "https://raw.githubusercontent.com/XXXXRomanXXXX/Script/main/update.py"
)

### FUNCTIONS ###

provisioning_start() {
    provisioning_print_header
    [[ ${#APT_PACKAGES[@]} -gt 0 ]] && provisioning_get_apt_packages
    [[ ${#NODES[@]} -gt 0 ]] && provisioning_get_nodes
    [[ ${#PIP_PACKAGES[@]} -gt 0 ]] && provisioning_get_pip_packages

    workflows_dir="${COMFYUI_DIR}/user/default/workflows"
    mkdir -p "${workflows_dir}"

    provisioning_get_files "${workflows_dir}" "${WORKFLOWS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/loras" "${LORAS_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/unet" "${UNET_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/vae" "${VAE_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/clip" "${CLIP_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}" "${UPDATE[@]}"

    provisioning_print_end
}

provisioning_get_apt_packages() {
    sudo apt-get update -y
    sudo apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}"
}

provisioning_get_pip_packages() {
    pip install --no-cache-dir "${PIP_PACKAGES[@]}"
}

provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="${COMFYUI_DIR}/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"

        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                echo "Updating node: $repo"
                ( cd "$path" && git pull --ff-only )
                [[ -f $requirements ]] && pip install --no-cache-dir -r "$requirements"
            fi
        else
            echo "Cloning node: $repo"
            git clone --recursive "$repo" "$path"
            [[ -f $requirements ]] && pip install --no-cache-dir -r "$requirements"
        fi
    done
}

provisioning_get_files() {
    local dir="$1"; shift
    [[ $# -eq 0 ]] && return
    mkdir -p "$dir"

    echo "Downloading $# file(s) to $dir..."
    for url in "$@"; do
        provisioning_download "$url" "$dir"
    done
}

provisioning_print_header() {
    cat <<'EOF'

##############################################
#                                            #
#          Provisioning container            #
#                                            #
#         This will take some time           #
#                                            #
# Your container will be ready on completion #
#                                            #
##############################################

EOF
}

provisioning_print_end() {
    echo -e "\nProvisioning complete: Application will start now\n"
}

provisioning_download() {
    local url="$1" dest="$2" auth_token="" header_args=()

    if [[ -n ${HF_TOKEN:-} && $url =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co ]]; then
        auth_token="$HF_TOKEN"
    elif [[ -n ${CIVITAI_TOKEN:-} && $url =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com ]]; then
        auth_token="$CIVITAI_TOKEN"
    fi

    [[ -n $auth_token ]] && header_args+=( "--header=Authorization: Bearer $auth_token" )

    mkdir -p "$dest"

    if command -v aria2c >/dev/null 2>&1; then
        echo "Downloading with aria2c: $url"
        aria2c -c -x 8 -s 8 --file-allocation=none -d "$dest" "${header_args[@]}" "$url"
    else
        echo "Downloading with wget: $url"
        wget -c -q --show-progress --content-disposition -e dotbytes=4M -P "$dest" "${header_args[@]}" "$url"
    fi
}

### MAIN ###

if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi

cd "$COMFYUI_DIR"
python update.py "$COMFYUI_DIR"

if [[ -f update_new.py ]]; then
    mv -f update_new.py update.py
    echo "Running updater again since it got updated."
    python update.py "$COMFYUI_DIR" --skip_self_update
fi
