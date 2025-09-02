#!/usr/bin/env bash

post_verify() {
  local findings_file="$1"
  local ok=0
  command -v python3 >/dev/null 2>&1 || ok=1
  command -v code >/dev/null 2>&1 || ok=1
  # Could generate HTML using your existing Diagnostics scripts later
  return $ok
}

