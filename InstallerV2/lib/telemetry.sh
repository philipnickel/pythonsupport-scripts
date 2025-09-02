#!/usr/bin/env bash

telemetry_consent() {
  # Respect env/flags and CI contexts
  if [[ "${DTU_ANALYTICS_ENABLED}" != "1" ]] || [[ -n "${CI:-}" ]]; then
    echo "no"
    return 0
  fi

  # If GUI chosen and osascript available, ask via dialog
  if [[ "$UI_MODE" == "gui" ]] && command -v osascript >/dev/null 2>&1; then
    local choice
    choice=$(osascript -e 'display dialog "Allow anonymous usage analytics to improve the installer?" buttons {"No","Yes"} default button 2 with icon note' 2>/dev/null)
    if echo "$choice" | grep -q "button returned:Yes"; then echo "yes"; else echo "no"; fi
    return 0
  fi

  # CLI default to opt-in with a prompt
  read -r -p "Allow anonymous analytics to improve the installer? [Y/n] " ans
  ans=${ans:-Y}
  if [[ "$ans" =~ ^[Yy]$ ]]; then echo "yes"; else echo "no"; fi
}

telemetry_event() {
  local event="$1"; shift
  # Placeholder: integrate with existing `piwik_utility.sh` later
  :
}
