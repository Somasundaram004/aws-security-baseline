#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=false
for argument in "$@"; do
  if [[ "$argument" == --dry-run ]]; then
    DRY_RUN=true
  fi
done

command -v terraform >/dev/null 2>&1 || { printf 'Terraform 1.6+ is required.\n' >&2; exit 1; }
[[ -f "$ROOT_DIR/terraform.tfvars" ]] || { printf 'Copy terraform.tfvars.example to terraform.tfvars and fill real values.\n' >&2; exit 1; }

if [[ "$DRY_RUN" == true || "${APPLY:-false}" != true ]]; then
  printf 'NACL plan mode: no AWS changes will be made.\n'
  terraform -chdir="$ROOT_DIR" init
  terraform -chdir="$ROOT_DIR" validate
  terraform -chdir="$ROOT_DIR" plan -var-file=terraform.tfvars -out=nacl.tfplan
  if [[ "$DRY_RUN" == true ]]; then
    exit 0
  fi
  printf 'Review nacl.tfplan, then rerun with APPLY=true to apply the exact plan.\n'
  exit 0
fi

terraform -chdir="$ROOT_DIR" apply -input=false nacl.tfplan
printf 'NACL resources applied. Verify subnet associations and flow logs before closing the change.\n'