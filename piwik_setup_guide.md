# Piwik PRO Setup Guide for macOS Installation Scripts

## What You Need to Do in Piwik PRO

### 1. Dashboard Setup

#### Dashboard 1: "Installation Overview"
**Purpose**: High-level operational metrics

**Widgets to Add:**
1. **Success Rate Metric**
   - Widget: Custom metric
   - Formula: `(Events with value > 0) / (Total events) * 100`
   - Time period: Last 30 days
   - Size: Large tile

2. **Daily Installation Volume**
   - Widget: Line chart
   - Metric: Event count
   - Group by: Date
   - Filter: All installer categories

3. **Success vs Failure Distribution**
   - Widget: Pie chart
   - Dimension: Event value (0 vs >0)
   - Show: Count and percentage

4. **Environment Distribution**
   - Widget: Bar chart
   - Dimension: Event category
   - Metrics: Event count
   - Shows: Installer_PROD vs Installer_DEV vs Installer_CI vs Installer_STAGING

#### Dashboard 2: "System Compatibility"
**Purpose**: Hardware and OS analysis

**Widgets to Add:**
1. **Operating System Analysis**
   - Widget: Table
   - Rows: Custom Dimension 1 (OS Version)
   - Metrics: Event count, Success rate, Failure rate
   - Formula for success rate: `Events with value>0 / Total events`

2. **Architecture Performance**
   - Widget: Table
   - Rows: Custom Dimension 2 (Architecture)
   - Metrics: Event count, Success rate, Average duration
   - Sort by: Event count descending

3. **OS Version Trends**
   - Widget: Line chart
   - X-axis: Date
   - Lines: Event count by OS version
   - Group by: Custom Dimension 1

#### Dashboard 3: "Component Analysis"
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

3. **Component Performance Matrix**
   - Widget: Heat map
   - Rows: Event name (component)
   - Columns: Architecture
   - Values: Success rate percentage

#### Dashboard 4: "Development Insights"
**Purpose**: Code version and CI/CD analysis

**Widgets to Add:**
1. **Commit Performance**
   - Widget: Table
   - Rows: Custom Dimension 3 (Commit SHA)
   - Metrics: Event count, Success rate, Failure rate
   - Sort by: Date descending

2. **Environment Performance Comparison**
   - Widget: Comparison table
   - Compare: Installer_CI vs Installer_PROD categories
   - Metrics: Success rate, component failure patterns

3. **Test Environment Usage**
   - Widget: Pie chart
   - Dimension: Event category
   - Filter: Last 7 days
   - Shows: Testing activity levels

### 2. Custom Reports Setup

#### Report 1: "Weekly Operations Summary"
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
- Exclude Installer_DEV and Installer_CI categories
- Last 7 days vs previous 7 days
```

#### Report 2: "Component Health Report"
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

#### Report 3: "System Compatibility Report"
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

### 3. Alerting Configuration

#### Critical Alerts (Immediate notification)

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

#### Warning Alerts (Next business day)

**Architecture-Specific Issues**
```
Trigger: One architecture has >15% higher failure rate than the other
Time window: Daily comparison
Include: Component breakdown and OS version analysis
```

**New OS Version Detection**
```
Trigger: New macOS version detected (not seen in last 30 days)
Action: Email to development team
Include: Version details and initial success rate
```

### 4. GDPR Compliance

**Simple Opt-Out System:**
- **Temporary File**: `/tmp/piwik_analytics_choice` stores user choice
- **Apple Native Dialog**: Uses `osascript` to show native macOS popup
- **Automatic Prompting**: Shows dialog on first use if no choice made
- **Fallback**: Command-line prompt if GUI not available

**Privacy Notice:**
- Anonymous usage analytics only
- No personal information collected
- Data used for installation process improvement
- Users can opt out at any time

**Compliance Features:**
- Native macOS dialog for user choice
- Simple file-based choice storage
- Commands work regardless of analytics status
- Clear privacy notice in dialog
- Easy opt-in/opt-out/reset functions

### 5. Data Structure

**Event Data Being Sent:**
- **Category**: Environment-based (Installer_PROD/DEV/CI/STAGING)
- **Action**: "Event" (static)
- **Name**: Event name + error suffix (if applicable)
- **Value**: Duration (success) or 0 (failure)
- **Dimension 1**: OS + Version + Codename (e.g., "macOS15.5 (Sequoia)")
- **Dimension 2**: Architecture (x86_64, arm64)
- **Dimension 3**: Git commit SHA (7 characters)

**Example Events:**
```
python_install_3.11          # Success: Python installation
python_install_3.11_network_error  # Failure: Network error during Python install
homebrew_install             # Success: Homebrew installation
vscode_extensions_install    # Success: VS Code extensions
```

### 6. Quick Setup Checklist

**In Piwik PRO Interface:**
- [ ] Create the 4 dashboards listed above
- [ ] Set up weekly operations report
- [ ] Configure critical success rate alerts (< 75%)
- [ ] Create segments for Architecture and OS versions
- [ ] Set up component failure alerts
- [ ] Configure new OS version detection alerts

**Monitoring Setup:**
- [ ] Set up Slack/email notifications for critical alerts
- [ ] Create runbook for responding to alerts
- [ ] Schedule weekly review of dashboard data
- [ ] Plan monthly analysis of trends and compatibility

### 7. Expected Analytics Insights

**System Compatibility:**
- Track macOS version adoption (Sequoia, Sonoma, Ventura, etc.)
- Monitor Apple Silicon vs Intel performance
- Identify OS-specific installation issues

**Component Performance:**
- Identify most problematic installation components
- Track success rates by component and system type
- Monitor performance improvements over time

**Development Workflow:**
- Compare CI vs production performance
- Track commit-level success rates
- Monitor test environment usage

**Operational Excellence:**
- Real-time success rate monitoring
- Early detection of new failure patterns
- Proactive system compatibility monitoring

This setup will provide comprehensive monitoring and analytics for your installation scripts across different environments, operating systems, and architectures.