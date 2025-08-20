#!/bin/bash

# Progress Indicator Helper for DTU Python PKG Installer
# Provides functions to show progress during PKG installation
# Optimized for macOS Installer.app and command-line installations

# Configuration
PROGRESS_ENABLED=${PKG_PROGRESS_ENABLED:-true}
NOTIFICATION_ENABLED=${PKG_NOTIFICATION_ENABLED:-true}
USER_NAME="${USER:-$(stat -f%Su /dev/console)}"

# Detect installation context
IS_COMMAND_LINE=${COMMAND_LINE_INSTALL:-0}
IS_PKG_INSTALLER=$([[ -n "$INSTALLER_TEMP" ]] && echo "1" || echo "0")

# Function to show progress in installer log and optionally as dialog
show_progress_log() {
    local message="$1"
    local level="${2:-INFO}"  # INFO, WARN, ERROR
    
    if [[ "$PROGRESS_ENABLED" != "true" ]]; then
        return 0
    fi
    
    # Always log to installer log (visible with ⌘L in Installer.app)
    echo "$(date '+%H:%M:%S') [$level] DTU Python Installer: $message"
    
    # For command-line installs, also show progress differently
    if [[ "$IS_COMMAND_LINE" == "1" ]]; then
        printf "\r\033[K🔧 DTU Python Installer: $message"
        sleep 0.5
    fi
}

# Function to show progress with estimated time
show_progress_step() {
    local step_number="$1"
    local total_steps="$2"
    local step_name="$3"
    local estimated_time="${4:-}"
    
    local progress_bar=""
    local filled=$((step_number * 20 / total_steps))
    
    # Create simple ASCII progress bar
    for ((i=1; i<=20; i++)); do
        if [[ $i -le $filled ]]; then
            progress_bar+="█"
        else
            progress_bar+="░"
        fi
    done
    
    local time_info=""
    if [[ -n "$estimated_time" ]]; then
        time_info=" (~$estimated_time)"
    fi
    
    show_progress_log "[$progress_bar] Step $step_number/$total_steps: $step_name$time_info"
}

# Function to show component installation progress
show_component_progress() {
    local component_name="$1"
    local status="$2"  # starting, progress, completed, failed, skipped
    
    case "$status" in
        "starting")
            show_progress_log "🚀 Starting $component_name installation..." "INFO"
            ;;
        "progress")
            local message="${3:-Installing...}"
            show_progress_log "⚙️  $component_name: $message" "INFO"
            ;;
        "completed")
            show_progress_log "✅ $component_name installation completed successfully" "INFO"
            ;;
        "failed")
            local error="${3:-Unknown error}"
            show_progress_log "❌ $component_name installation failed: $error" "ERROR"
            ;;
        "skipped")
            local reason="${3:-Already installed}"
            show_progress_log "⏭️  $component_name installation skipped: $reason" "INFO"
            ;;
    esac
}

# Function to show final completion notification (post-installation)
show_completion_notification() {
    local success="$1"
    local message="$2"
    
    if [[ "$NOTIFICATION_ENABLED" != "true" ]]; then
        return 0
    fi
    
    # Log completion
    if [[ "$success" == "true" ]]; then
        show_progress_log "🎉 Installation completed successfully!" "INFO"
    else
        show_progress_log "💥 Installation completed with errors" "ERROR"
    fi
    
    # Only show notification dialog after installation (not during PKG process)
    # This runs after the PKG installer has finished
    {
        sleep 2  # Wait for installer to close
        local icon="note"
        local title="DTU Python Installation Complete"
        
        if [[ "$success" != "true" ]]; then
            icon="caution"
            title="DTU Python Installation Error"
        fi
        
        sudo -u "$USER_NAME" osascript -e "
            display notification \"$message\" \\
                with title \"$title\" \\
                sound name \"Glass\"
        " 2>/dev/null || true
        
        # Also show a dialog for important information
        sudo -u "$USER_NAME" osascript -e "
            display dialog \"$message\" \\
                with title \"$title\" \\
                with icon $icon \\
                buttons {\"OK\"} \\
                default button 1
        " 2>/dev/null || true
    } &
}

# Function to show installation summary
show_installation_summary() {
    local components_installed="$1"
    local total_time="$2"
    
    show_progress_log "📊 Installation Summary:" "INFO"
    show_progress_log "   Components: $components_installed" "INFO"
    if [[ -n "$total_time" ]]; then
        show_progress_log "   Total time: $total_time" "INFO"
    fi
    show_progress_log "   Ready to use! Open Terminal and type 'python3'" "INFO"
}

# Function to show installer header
show_installer_header() {
    show_progress_log "╭─────────────────────────────────────────────────╮" "INFO"
    show_progress_log "│           DTU Python Installation              │" "INFO"
    show_progress_log "│   Complete Python Development Environment      │" "INFO"
    show_progress_log "╰─────────────────────────────────────────────────╯" "INFO"
    show_progress_log "" "INFO"
}

# Function to clean up any background processes
cleanup_processes() {
    # Kill any background animation processes
    jobs -p | xargs -r kill 2>/dev/null || true
}

# Compatibility aliases for existing code
show_loading_dialog() { show_progress_log "$1"; }
show_progress_notification() { show_progress_log "$1"; }
show_step_dialog() { show_progress_step "$1" "$2" "$3" "$4"; }
show_completion_dialog() { show_completion_notification "$1" "$2"; }
show_welcome_dialog() { show_installer_header; }
cleanup_loading_dialogs() { cleanup_processes; }
show_animated_loading() { show_progress_log "Starting $1..."; }

# Export functions for use in other scripts
export -f show_progress_log
export -f show_progress_step
export -f show_component_progress
export -f show_completion_notification
export -f show_installation_summary
export -f show_installer_header
export -f cleanup_processes

# Export compatibility functions
export -f show_loading_dialog
export -f show_progress_notification
export -f show_step_dialog
export -f show_completion_dialog
export -f show_welcome_dialog
export -f cleanup_loading_dialogs
export -f show_animated_loading