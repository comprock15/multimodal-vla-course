#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
if [[ "${ACCEPT_EULA:-}" != Y ]]; then
    echo 'Set ACCEPT_EULA=Y after reading the NVIDIA license linked in README.md.' >&2
    exit 1
fi
image="${SO101_IMAGE:-so101-course:0.1}"
if ! docker image inspect "$image" >/dev/null 2>&1; then
    echo "Course image '$image' is missing. Build it once with: docker build -t so101-course:0.1 ." >&2
    exit 1
fi
mkdir -p data runs
docker_command=(docker run --runtime=nvidia --gpus "device=${GPU_INDEX:-0}")
if [[ "${SO101_GPU_MODE:-toolkit}" == direct ]]; then
    docker_command=(python3 scripts/direct_gpu.py "${GPU_INDEX:-0}")
fi
# Mount the checkout over the image's source tree so code edits are live.
exec "${docker_command[@]}" --rm --shm-size=2g \
    -e HTTPS_PROXY -e HTTP_PROXY -e NO_PROXY \
    -e ACCEPT_EULA=Y -e OMNI_KIT_ACCEPT_EULA=YES -e OMNI_KIT_ALLOW_ROOT=1 \
    -e NVIDIA_DRIVER_CAPABILITIES=all -e PRIVACY_CONSENT="${PRIVACY_CONSENT:-N}" \
    -e XDG_CACHE_HOME=/opt/so101/data/cache -e PYTHONPATH=/opt/so101 \
    -e TOKENIZERS_PARALLELISM=false \
    -v "$PWD:/opt/so101" \
    --workdir /opt/so101 --entrypoint /opt/so101/scripts/entrypoint.sh \
    "$image" "$@"
