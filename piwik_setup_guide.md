# Piwik PRO Analytics Setup Guide for macOS Installation Scripts

## Table of Contents
1. [Current Implementation Analysis](#current-implementation-analysis)
2. [Piwik PRO Dashboard Setup](#piwik-pro-dashboard-setup)
3. [Custom Reports to Create](#custom-reports-to-create)
4. [Alerting & Monitoring](#alerting--monitoring)
5. [Data Enhancement Opportunities](#data-enhancement-opportunities)
6. [Implementation Improvements](#implementation-improvements)

---

## Current Implementation Analysis

### What You're Currently Tracking
Based on your `piwik_utility.sh`, you're sending:

**Event Structure:**
- **Category**: `Installer`, `Installer_TEST`, or `Installer_CI` 
- **Action**: `Event` (static)
- **Name**: Event name (passed to `piwik_log` function)
- **Value**: `1` for success, `0` for failure

**Custom Dimensions:**
- **Dimension 1**: Operating System + Version (e.g., "Darwin14.2.1")
- **Dimension 2**: Architecture (x86_64, arm64)
- **Dimension 3**: Git commit SHA (7 characters)

**Environments Detected:**
- Production: `Installer` category
- Testing: `Installer_TEST` category  
- CI/CD: `Installer_CI` category

---

## Piwik PRO Dashboard Setup

### Dashboard 1: "Installation Overview"
**Purpose**: High-level operational metrics

**Widgets to Add:**

1. **Success Rate Metric**
   - Widget: Custom metric
   - Formula: `(Events with value = 1) / (Total events) * 100`
   - Time period: Last 30 days
   - Size: Large tile

2. **Daily Installation Volume**
   - Widget: Line chart
   - Metric: Event count
   - Group by: Date
   - Filter: All installer categories

3. **Success vs Failure Distribution**
   - Widget: Pie chart
   - Dimension: Event value (0 vs 1)
   - Show: Count and percentage

4. **Environment Distribution**
   - Widget: Bar chart
   - Dimension: Event category
   - Metrics: Event count
   - Shows: Production vs Test vs CI usage

### Dashboard 2: "System Compatibility"
**Purpose**: Hardware and OS analysis

**Widgets to Add:**

1. **Architecture Performance**
   - Widget: Table
   - Rows: Custom Dimension 2 (Architecture)
   - Metrics: Event count, Success rate, Failure rate
   - Formula for success rate: `Events with value=1 / Total events`

2. **macOS Version Analysis**
   - Widget: Table  
   - Rows: Custom Dimension 1 (OS Version)
   - Metrics: Event count, Success rate
   - Sort by: Event count descending

3. **Architecture vs Success Rate**
   - Widget: Combo chart
   - X-axis: Architecture (Dimension 2)
   - Bars: Total installations
   - Line: Success percentage

4. **OS Version Trends**
   - Widget: Line chart
   - X-axis: Date
   - Lines: Event count by OS version
   - Group by: Custom Dimension 1

### Dashboard 3: "Component Analysis"
**Purpose**: Individual component performance

**Widgets to Add:**

1. **Component Success Rates**
   - Widget: Table
   - Rows: Event name
   - Columns: Success count, Failure count, Success rate
   - Sort by: Failure count descending

2. **Most Problematic Components**
   - Widget: Bar chart
   - Dimension: Event name
   - Metric: Failure count (Events with value = 0)
   - Limit: Top 10

3. **Component Installation Trends**
   - Widget: Line chart
   - X-axis: Date
   - Lines: Success rate by component
   - Filter: Top 5 most used components

4. **Component Performance Matrix**
   - Widget: Heat map
   - Rows: Event name (component)
   - Columns: Architecture
   - Values: Success rate percentage

### Dashboard 4: "Development Insights"
**Purpose**: Code version and CI/CD analysis

**Widgets to Add:**

1. **Commit Performance**
   - Widget: Table
   - Rows: Custom Dimension 3 (Commit SHA)
   - Metrics: Event count, Success rate, Failure rate
   - Sort by: Date descending

2. **Version Rollback Detection**
   - Widget: Line chart
   - X-axis: Date
   - Lines: Event count by commit SHA
   - Shows: When new versions are deployed

3. **CI vs Production Performance**
   - Widget: Comparison table
   - Compare: `Installer_CI` vs `Installer` categories
   - Metrics: Success rate, component failure patterns

4. **Test Environment Usage**
   - Widget: Pie chart
   - Dimension: Event category
   - Filter: Last 7 days
   - Shows: Testing activity levels

---

## Custom Reports to Create

### Report 1: "Weekly Operations Summary"
**Schedule**: Every Monday morning
**Recipients**: Development team

**Content:**
```
Metrics to include:
- Total installations this week vs last week
- Overall success rate trend
- Top 3 failing components
- New OS versions detected
- Commit SHA performance comparison
- Architecture adoption trends

Filters:
- Exclude TEST and CI categories
- Last 7 days vs previous 7 days
```

### Report 2: "Component Health Report"
**Schedule**: Daily (for components with >10% failure rate)
**Recipients**: On-call developer

**Content:**
```
Alert triggers:
- Any component with >20% failure rate in last 24 hours
- New component failures not seen in last 7 days
- Success rate drops >15% compared to 7-day average

Include:
- Affected systems (OS + Architecture combinations)
- Recent commit SHAs when failures started
- Comparison with CI test results
```

### Report 3: "System Compatibility Report" 
**Schedule**: Monthly
**Recipients**: Product team

**Content:**
```
Analysis includes:
- New macOS versions detected
- Architecture adoption rates (Intel vs Apple Silicon)
- Compatibility issues by OS version
- Deprecation recommendations for old systems

Segments:
- Group by: Custom Dimension 1 (OS) + Dimension 2 (Architecture)
- Time period: Last 30 days
- Include trend analysis
```

---

## Alerting & Monitoring

### Critical Alerts (Immediate notification)

**Overall Success Rate Alert**
```
Trigger: Success rate < 75% in last 2 hours AND event count > 10
Action: Slack notification + Email to on-call
Include: Top failing components and affected systems
```

**New Failure Pattern Alert**
```
Trigger: Component that was >95% successful now <80% successful
Time window: Compare last 4 hours vs previous 24 hours
Action: Email to development team
Include: Recent commit changes and affected OS versions
```

**High Volume Failure Alert**
```
Trigger: >20 failures in 1 hour
Action: Immediate notification
Include: Breakdown by component and system type
```

### Warning Alerts (Next business day)

**Architecture-Specific Issues**
```
Trigger: One architecture has >15% higher failure rate than the other
Time window: Daily comparison
Include: Component breakdown and OS version analysis
```

**Commit Regression Detection**
```
Trigger: New commit SHA shows >10% worse performance than previous
Time window: 24 hours after deployment
Include: Before/after comparison and affected components
```

---

## Data Enhancement Opportunities

### Additional Context You Could Track
Without changing your core structure, you could enhance tracking:

**1. Enhanced Event Names**
Instead of generic component names, use structured naming:
```bash
# Current: piwik_log "homebrew" brew install
# Enhanced: piwik_log "homebrew_install" brew install
# Enhanced: piwik_log "homebrew_update" brew update
# Enhanced: piwik_log "python_install_3.11" pyenv install 3.11
```

**2. Duration Tracking** 
Add timing to your piwik_log function:
```bash
piwik_log_with_timing() {
    local event_name="$1"
    local start_time=$(date +%s)
    shift
    
    piwik_log "$event_name" "$@"
    local exit_code=$?
    
    local duration=$(($(date +%s) - start_time))
    # Could send duration as custom dimension 4 or event value
    
    return $exit_code
}
```

**3. Error Context**
For failures, capture more context:
```bash
# Add error type to event name for failures
piwik_log_with_error() {
    local event_name="$1"
    shift
    
    local output
    output=$("$@" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        # Enhance event name with error context
        if echo "$output" | grep -q "permission denied"; then
            event_name="${event_name}_permission_error"
        elif echo "$output" | grep -q "network\|download\|curl"; then
            event_name="${event_name}_network_error"
        elif echo "$output" | grep -q "space\|disk"; then
            event_name="${event_name}_disk_error"
        else
            event_name="${event_name}_unknown_error"
        fi
    fi
    
    # Use your existing piwik_log with enhanced name
    echo "$output"
    # Send to Piwik with enhanced event name...
}
```

---

## Implementation Improvements

### 1. Enhanced Piwik Utility
Here's an improved version of your utility that adds timing and error categorization:

```bash
#!/bin/bash
# Enhanced version of your piwik_utility.sh

# Your existing configuration
PIWIK_URL="https://pythonsupport.piwik.pro/ppms.php"
SITE_ID="0bc7bce7-fb4d-4159-a809-e6bab2b3a431"
GITHUB_REPO="dtudk/pythonsupport-page"

# Your existing helper functions (get_system_info, get_commit_sha)
# ... keep all your existing code ...

# Enhanced logging function with timing and error categorization
piwik_log_enhanced() {
    local event_name="$1"
    local start_time=$(date +%s)
    shift
    
    # Run command and capture output
    local output
    output=$("$@" 2>&1)
    local exit_code=$?
    local duration=$(($(date +%s) - start_time))
    
    # Display output
    echo "$output"
    
    # Enhance event name for failures
    if [ $exit_code -ne 0 ]; then
        if echo "$output" | grep -iq "permission denied\|not permitted"; then
            event_name="${event_name}_permission_error"
        elif echo "$output" | grep -iq "network\|download\|curl\|wget\|connection"; then
            event_name="${event_name}_network_error"
        elif echo "$output" | grep -iq "space\|disk\|storage"; then
            event_name="${event_name}_disk_error"
        elif echo "$output" | grep -iq "not found\|command not found"; then
            event_name="${event_name}_missing_dependency"
        else
            event_name="${event_name}_unknown_error"
        fi
    fi
    
    get_system_info
    local commit_sha=$(get_commit_sha)
    
    # Determine event category
    local event_category="Installer"
    if [ "$TESTING_MODE" = "true" ]; then
        event_category="Installer_TEST"
    elif [ "$GITHUB_CI" = "true" ]; then
        event_category="Installer_CI"
    fi
    
    # Set result and use duration as event value for successes
    local result="success"
    local event_value="$duration"
    
    if [ $exit_code -ne 0 ]; then
        result="failure"
        event_value="0"
    fi
    
    # Send to Piwik with duration info
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -G "$PIWIK_URL" \
        --max-time 10 \
        --connect-timeout 5 \
        --data-urlencode "idsite=$SITE_ID" \
        --data-urlencode "rec=1" \
        --data-urlencode "e_c=$event_category" \
        --data-urlencode "e_a=Event" \
        --data-urlencode "e_n=$event_name" \
        --data-urlencode "e_v=$event_value" \
        --data-urlencode "dimension1=$OS" \
        --data-urlencode "dimension2=$ARCH" \
        --data-urlencode "dimension3=$commit_sha" 2>/dev/null)
    
    return $exit_code
}

# Convenience wrapper - uses enhanced version if available
piwik_log_timed() {
    piwik_log_enhanced "$@"
}

# Keep your original piwik_log for backwards compatibility
# ... your existing piwik_log function unchanged ...
```

### 2. Usage Examples with Your Enhanced Utility

```bash
# In your installation scripts:

# Basic usage (same as before)
piwik_log "homebrew_check" which brew

# Enhanced usage with timing and error categorization
piwik_log_enhanced "homebrew_install" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

piwik_log_enhanced "python_install" brew install python@3.11

piwik_log_enhanced "conda_download" curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh

# The enhanced version will automatically categorize failures:
# - homebrew_install_permission_error
# - conda_download_network_error
# - python_install_missing_dependency
```

### 3. Quick Setup Checklist

**In Piwik PRO Interface:**
- [ ] Create the 4 dashboards listed above
- [ ] Set up weekly operations report
- [ ] Configure critical success rate alerts (< 75%)
- [ ] Create segments for Architecture and OS versions
- [ ] Set up component failure alerts

**In Your Scripts:**
- [ ] Consider using enhanced event naming for better categorization
- [ ] Add timing tracking if performance monitoring is important
- [ ] Test alert thresholds with historical data
- [ ] Document event naming conventions for your team

**Monitoring Setup:**
- [ ] Set up Slack/email notifications for critical alerts
- [ ] Create runbook for responding to alerts
- [ ] Schedule weekly review of dashboard data
- [ ] Plan monthly analysis of trends and compatibility

This approach builds on your existing simple but effective implementation while providing actionable insights for improving your installation scripts.