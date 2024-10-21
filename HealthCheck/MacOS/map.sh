#!/bin/bash

# Configuration
export STORE_DIR=$(mktemp -d ${TMPDIR:-/tmp}/healthCheck-maps.XXXXXXXX)

# Ensure store directory exists with proper permissions
mkdir -p "$STORE_DIR"
chmod 755 "$STORE_DIR"

# Function to encode the key to avoid conflicts with special characters
encode_key() {
    echo "$1" | sed 's/[^a-zA-Z0-9]/_/g'
}

# Function to get the storage file path for a map
get_store_path() {
    local map_name=$1
    echo "${STORE_DIR}/${map_name}.store"
}

# Function to get the lock file path for a map
get_lock_path() {
    local map_name=$1
    echo "${STORE_DIR}/${map_name}.lock"
}

# Acquire a lock for the map
acquire_lock() {
    local map_name=$1
    local lock_file=$(get_lock_path "$map_name")
    local start_time=$(date +%s)
    
    while ! mkdir "$lock_file" 2>/dev/null; do
        if [ $(($(date +%s) - start_time)) -gt 10 ]; then
            echo "Failed to acquire lock for $map_name" >&2
            return 1
        fi
        sleep 0.1
    done
    return 0
}

# Release the lock
release_lock() {
    local map_name=$1
    local lock_file=$(get_lock_path "$map_name")
    rm -rf "$lock_file"
}

# Set a key-value pair
map_set() {
    local map_name=$1
    local key=$(encode_key "$2")
    local value=$3
    local store_file=$(get_store_path "$map_name")
    
    if ! acquire_lock "$map_name"; then
        return 1
    fi
    
    # Create or truncate the store file if it doesn't exist
    touch "$store_file"
    
    # Create a temporary file in the same directory
    local temp_file="${store_file}.tmp"
    
    # Remove the key if it exists and write the new value
    grep -v "^${key}=" "$store_file" > "$temp_file" 2>/dev/null || touch "$temp_file"
    echo "${key}=${value}" >> "$temp_file"
    
    # Replace the original file with the temporary file
    mv "$temp_file" "$store_file"
    
    release_lock "$map_name"
}

# Get a value by key
map_get() {
    local map_name=$1
    local key=$(encode_key "$2")
    local store_file=$(get_store_path "$map_name")
    
    if ! acquire_lock "$map_name"; then
        return 1
    fi
    
    if [ -f "$store_file" ]; then
        local value=$(grep "^${key}=" "$store_file" | cut -d= -f2-)
        release_lock "$map_name"
        echo "$value"
        return 0
    fi
    
    release_lock "$map_name"
    return 1
}

# Delete a key-value pair
map_delete() {
    local map_name=$1
    local key=$(encode_key "$2")
    local store_file=$(get_store_path "$map_name")
    
    if ! acquire_lock "$map_name"; then
        return 1
    fi
    
    if [ -f "$store_file" ]; then
        local temp_file="${store_file}.tmp"
        grep -v "^${key}=" "$store_file" > "$temp_file"
        mv "$temp_file" "$store_file"
    fi
    
    release_lock "$map_name"
}

# List all keys in a map
map_keys() {
    local map_name=$1
    local store_file=$(get_store_path "$map_name")
    
    if ! acquire_lock "$map_name"; then
        return 1
    fi
    
    if [ -f "$store_file" ]; then
        cut -d= -f1 "$store_file"
    fi
    
    release_lock "$map_name"
}

# Clean up a map (delete the store file)
map_cleanup() {
    local map_name=$1
    local store_file=$(get_store_path "$map_name")
    local lock_file=$(get_lock_path "$map_name")
    
    if ! acquire_lock "$map_name"; then
        return 1
    fi
    
    rm -f "$store_file"
    release_lock "$map_name"
}

# Clean up all maps
map_cleanup_all() {
    rm -rf "${STORE_DIR}"/*
}