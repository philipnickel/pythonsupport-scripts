#!/bin/bash
# @name: System Information
# @description: Basic macOS system information
# @category: System
# @subcategory: Information
# @timeout: 5

echo "SYSTEM INFORMATION"
echo "=================="

echo "macOS Version: $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
echo "Build Version: $(sw_vers -buildVersion 2>/dev/null || echo 'Unknown')"
echo "Product Name: $(sw_vers -productName 2>/dev/null || echo 'Unknown')"
echo "Architecture: $(uname -m 2>/dev/null || echo 'Unknown')"
echo "Hostname: $(hostname 2>/dev/null || echo 'Unknown')"
echo "Kernel: $(uname -sr 2>/dev/null || echo 'Unknown')"

echo ""
echo " System information retrieved - PASSED"