#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$root"
dataset_dir="${1:-${DATASET_DIR:-$root/runs/lerobot-demos}}"
output_dir="${2:-${OUTPUT_DIR:-$root/runs/smolvla-finetune-$(date +%Y%m%d-%H%M%S)}}"
model_dir="${SMOLVLA_BASE:-}"
train_bin="${LEROBOT_TRAIN_BIN:-}"

if [[ ! -x "$train_bin" ]]; then
    echo "LeRobot trainer is not executable: $train_bin" >&2
    echo 'Set LEROBOT_TRAIN_BIN to the lerobot-train executable in your venv.' >&2
    exit 1
fi
if [[ ! -f "$model_dir/config.json" || ! -f "$model_dir/model.safetensors" ]]; then
    echo "SmolVLA checkpoint is missing config.json or model.safetensors: $model_dir" >&2
    exit 1
fi
if [[ ! -f "$dataset_dir/meta/info.json" || ! -d "$dataset_dir/data" ]]; then
    echo "Not a local LeRobot dataset (expected meta/info.json and data/): $dataset_dir" >&2
    exit 1
fi
if [[ -e "$output_dir" ]]; then
    echo "Output already exists; choose a new OUTPUT_DIR: $output_dir" >&2
    exit 1
fi

dataset_dir="$(cd -- "$dataset_dir" && pwd)"
mkdir -p "$(dirname -- "$output_dir")"

# This dataset has top and left_wrist views. SmolVLA can train with those two
# views; any checkpoint camera slot without a matching batch key is skipped.
rename_map='{"observation.images.top":"observation.images.camera1","observation.images.left_wrist":"observation.images.camera2"}'

exec "$train_bin" \
    --dataset.repo_id=local/so101-pick-place \
    --dataset.root="$dataset_dir" \
    --policy.path="$model_dir" \
    --policy.device="${DEVICE:-cuda}" \
    --policy.push_to_hub=false \
    --policy.empty_cameras=0 \
    --rename_map="$rename_map" \
    --output_dir="$output_dir" \
    --job_name=so101_smolvla_finetune \
    --steps="${STEPS:-20000}" \
    --batch_size="${BATCH_SIZE:-2}" \
    --num_workers="${NUM_WORKERS:-4}" \
    --save_freq="${SAVE_FREQ:-2000}" \
    --log_freq="${LOG_FREQ:-50}" \
    --wandb.enable=false \
    "$@"
