#!/usr/bin/env bash
set -euo pipefail
source /armos/build/lib.sh

setup_mounts

in_chroot '
  echo "== profile =="
  eselect profile show 2>/dev/null || readlink -f /etc/portage/make.profile
  echo "== emerge =="
  emerge --info | sed -n "1,35p"
  echo "== toolchain =="
  gcc --version | head -1
  ld --version | head -1
  echo "== disk =="
  df -h / | tail -1
  echo "== network =="
  curl -sI --max-time 20 https://distfiles.gentoo.org/ | head -1
'
