#!/bin/bash
# @name: Timeout Test Script
# @description: Test script that will timeout to demonstrate copy command functionality
# @category: System
# @subcategory: Test
# @timeout: 2

echo "TIMEOUT TEST SCRIPT"
echo "=================="
echo "This script will run for 5 seconds to test timeout functionality..."
echo ""

for i in {1..5}; do
    echo "Step $i: Processing..."
    sleep 1
done

echo "✅ Test completed successfully!"