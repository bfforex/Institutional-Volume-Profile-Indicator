# Installation Guide

## Prerequisites

### MetaTrader 5 Platform
- **Version**: Build 3440 or higher (recommended)
- **Download**: [MetaTrader 5](https://www.metatrader5.com/en/download)
- **Operating System**: Windows 7/8/10/11, macOS (via Wine), or Linux (via Wine)

### Broker Requirements
- Any MT5-compatible broker
- Sufficient historical data (minimum 500 bars)
- Volume data available (tick volume or real volume)

---

## Installation Methods

### Method 1: Manual Installation (Recommended)

#### Step 1: Locate Your MT5 Data Folder
1. Open MetaTrader 5
2. Click **File** → **Open Data Folder**
3. Navigate to `MQL5` → `Indicators` folder

**Default Paths**:
- **Windows**: `C:\Users\[YourUsername]\AppData\Roaming\MetaQuotes\Terminal\[TerminalID]\MQL5\Indicators\`
- **macOS** (Wine): `~/.wine/drive_c/users/[username]/Application Data/MetaQuotes/Terminal/[TerminalID]/MQL5/Indicators/`

#### Step 2: Copy Indicator File
1. Download `InstitutionalVolumeProfile.mq5` from the repository
2. Copy it to the `Indicators` folder found in Step 1

#### Step 3: Compile the Indicator
1. Open MetaTrader 5
2. Press **F4** or click **Tools** → **MetaQuotes Language Editor**
3. In the Navigator panel (left side), expand `Indicators`
4. Double-click `InstitutionalVolumeProfile.mq5`
5. Press **F7** or click **Compile** button
6. Check for compilation success (should show "0 error(s), 0 warning(s)")

#### Step 4: Apply to Chart
1. Go back to MT5 main window
2. Press **Ctrl+N** or click **View** → **Navigator**
3. Expand **Indicators** → **Custom**
4. Drag `InstitutionalVolumeProfile` onto your chart
5. Configure parameters in the popup window
6. Click **OK**

---

### Method 2: Direct Copy (No Compilation Required)

If you have the compiled `.ex5` file:

1. Download `InstitutionalVolumeProfile.ex5`
2. Open MT5 Data Folder (**File** → **Open Data Folder**)
3. Navigate to `MQL5` → `Indicators`
4. Copy the `.ex5` file here
5. Restart MT5 or right-click Navigator → **Refresh**
6. Apply to chart as described in Method 1, Step 4

---

### Method 3: Import via MQL5 Market (Future)

When available on MQL5 Market:
1. Open MT5
2. Click **View** → **Toolbox** → **Market** tab
3. Search for "Institutional Volume Profile"
4. Click **Download** or **Purchase**
5. Apply from **Navigator** → **Indicators** → **Market**

---

## Post-Installation Steps

### 1. Verify Installation
1. Open any chart (e.g., EUR/USD H1)
2. Apply the indicator
3. You should see:
   - Blue zone boundaries
   - Yellow POC line (if enabled)
   - Potentially some arrows if signals are present

### 2. Load Historical Data
For best results, ensure sufficient historical data:
1. Open chart
2. Press **Home** key to scroll to the beginning
3. Let MT5 load history (status bar shows loading progress)
4. Minimum 500 bars required, 1000+ recommended

### 3. Configure Initial Settings
Use the **Balanced** preset for first-time setup:
```
InpPeriod = 100
InpPriceRows = 50
InpHVNThreshold = 1.5
InpMLSensitivity = 0.5
InpFirstTouchOnly = true
```

See [PRESETS.md](PRESETS.md) for more configurations.

---

## Troubleshooting Installation Issues

### Issue 1: Indicator Not Appearing in Navigator

**Solutions**:
- Restart MetaTrader 5 completely
- Right-click on Navigator → **Refresh**
- Verify file is in correct folder (`MQL5/Indicators/`)
- Check file extension (`.mq5` for source, `.ex5` for compiled)

### Issue 2: Compilation Errors

**Common Errors and Solutions**:

**Error**: "Cannot open include file"
- **Solution**: Ensure you have the complete MT5 installation
- Reinstall MetaTrader 5 if necessary

**Error**: "Undeclared identifier"
- **Solution**: Make sure you copied the complete source code
- Check for any copy-paste issues

**Error**: "Invalid version directive"
- **Solution**: Update MT5 to latest build (3440+)

### Issue 3: Indicator Shows Nothing on Chart

**Solutions**:
- Ensure sufficient historical data loaded (press **Home** key)
- Try decreasing `InpHVNThreshold` to 1.2
- Check that `InpShowZones` is enabled
- Verify chart has volume data (check **View** → **Volume**)

### Issue 4: Permission Denied / Access Error

**Solutions**:
- Run MetaTrader 5 as Administrator
- Check Windows folder permissions
- Ensure antivirus is not blocking the file
- Disable Windows SmartScreen temporarily

### Issue 5: Indicator Crashes or Freezes MT5

**Solutions**:
- Reduce `InpPeriod` to 50
- Reduce `InpPriceRows` to 30
- Ensure sufficient system memory (4GB+ RAM recommended)
- Close other applications

---

## Updating the Indicator

### To Update to a New Version:

1. **Backup your current settings**:
   - Right-click chart → **Template** → **Save Template**
   - Name it (e.g., "IVP_MySettings_Backup")

2. **Remove old version**:
   - Remove indicator from all charts
   - Delete old `.mq5` and `.ex5` files from `MQL5/Indicators/`

3. **Install new version**:
   - Follow Method 1 or Method 2 above
   - Apply your saved template to restore settings

4. **Check changelog**:
   - Review [CHANGELOG.md](CHANGELOG.md) for new features
   - Adjust settings if recommended

---

## System Requirements

### Minimum Requirements
- **OS**: Windows 7 or higher
- **Processor**: 1 GHz or faster
- **RAM**: 2 GB
- **MT5 Build**: 3000 or higher
- **Internet**: Stable connection for data

### Recommended Requirements
- **OS**: Windows 10/11 64-bit
- **Processor**: 2 GHz dual-core or better
- **RAM**: 4 GB or more
- **MT5 Build**: 3440 or higher
- **Internet**: Broadband connection
- **Display**: 1920x1080 or higher

---

## Multi-Chart Setup

### To Apply to Multiple Charts:

#### Option 1: Manual Application
1. Apply to first chart
2. Configure settings
3. Save as template
4. Apply template to other charts

#### Option 2: Profile Setup
1. Create chart layout with indicator
2. **File** → **Save Profile** → Name it (e.g., "IVP_Trading")
3. Open profile anytime: **File** → **Profiles** → Select your profile

---

## Multiple Timeframe Setup

Recommended configuration for multi-timeframe analysis:

1. **Higher Timeframe** (H4 or Daily):
   - Conservative preset
   - Identifies major institutional zones
   - Determines overall trend

2. **Trading Timeframe** (H1):
   - Balanced preset
   - Entry signals and execution
   - Main trading reference

3. **Lower Timeframe** (M15):
   - Aggressive preset (optional)
   - Fine-tune entry timing
   - Monitor position development

---

## Uninstallation

### To Remove the Indicator:

1. **Remove from charts**:
   - Right-click chart → **Indicators List**
   - Select "Institutional Volume Profile"
   - Click **Delete**

2. **Delete files**:
   - Open Data Folder (**File** → **Open Data Folder**)
   - Navigate to `MQL5/Indicators/`
   - Delete `InstitutionalVolumeProfile.mq5` and `.ex5` files

3. **Restart MT5**:
   - Close and reopen MetaTrader 5

---

## Getting Help

If you encounter issues not covered here:

1. **Check documentation**:
   - [DOCUMENTATION.md](DOCUMENTATION.md) - Full feature guide
   - [EXAMPLES.md](EXAMPLES.md) - Usage examples
   - [PRESETS.md](PRESETS.md) - Configuration presets

2. **Common issues**:
   - Review troubleshooting section above
   - Check [CHANGELOG.md](CHANGELOG.md) for known issues

3. **Community support**:
   - Open an issue on GitHub
   - Include: MT5 version, OS, error messages, screenshots

4. **Broker support**:
   - Some issues may be broker-specific
   - Contact your broker for data/platform issues

---

## Tips for Smooth Installation

✅ **Do's**:
- Keep MT5 updated to latest build
- Ensure sufficient historical data loaded
- Start with default/balanced preset
- Save your custom settings as templates
- Test on demo account first

❌ **Don'ts**:
- Don't modify source code unless you know MQL5
- Don't run on extremely low timeframes (< M5) without optimization
- Don't use on charts with insufficient data
- Don't expect instant profitability without proper testing
- Don't apply to too many charts simultaneously (performance)

---

## Next Steps After Installation

1. **Read documentation**: Familiarize yourself with features
2. **Review examples**: See real-world usage scenarios
3. **Test on demo**: Practice with virtual money first
4. **Optimize settings**: Find what works for your trading style
5. **Monitor ML filter**: Let it learn for 2-4 weeks
6. **Track performance**: Record results and adjust

---

## Installation Complete! 🎉

You're now ready to use the Institutional Volume Profile Indicator. Start with the **Balanced** preset, let the ML filter learn for a few weeks, and gradually optimize based on your trading results.

Happy trading! 📈
