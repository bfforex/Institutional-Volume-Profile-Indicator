# 🚀 Quick Installation Guide

## Step-by-Step Installation for MT5

### 📁 File Organization

You have received these files:

**Main Indicator:**
- `InstitutionalVolumeProfile.mq5`

**Include Files (Dependencies):**
- `VolumeProfileEngine.mqh`
- `InstitutionalZoneDetector.mqh`
- `SignalEngine.mqh`
- `MLFilter.mqh`
- `Visualizer.mqh`

**Documentation:**
- `README.md` - Overview and features
- `UserGuide.md` - Complete parameter reference
- `BacktestGuide.md` - Testing methodology

---

## 🔧 Installation Steps

### 1️⃣ Locate Your MT5 Data Folder

**Windows:**
```
File → Open Data Folder
(or press Ctrl+Shift+D in MT5)
```

This opens: `C:\Users\[YourName]\AppData\Roaming\MetaQuotes\Terminal\[ID]\`

**Mac:**
```
Finder → Go → Go to Folder
Type: ~/Library/Application Support/MetaTrader 5/
```

---

### 2️⃣ Copy Files to Correct Locations

**A) Copy Include Files (.mqh)**

Navigate to: `MQL5/Include/`

Copy these 5 files here:
```
✓ VolumeProfileEngine.mqh
✓ InstitutionalZoneDetector.mqh
✓ SignalEngine.mqh
✓ MLFilter.mqh
✓ Visualizer.mqh
```

**Final path should look like:**
```
Terminal/[ID]/MQL5/Include/VolumeProfileEngine.mqh
Terminal/[ID]/MQL5/Include/InstitutionalZoneDetector.mqh
... (etc)
```

**B) Copy Main Indicator (.mq5)**

Navigate to: `MQL5/Indicators/`

Copy this file here:
```
✓ InstitutionalVolumeProfile.mq5
```

**Final path:**
```
Terminal/[ID]/MQL5/Indicators/InstitutionalVolumeProfile.mq5
```

---

### 3️⃣ Compile the Indicator

**Option A: Automatic Compilation (Easiest)**
1. Close and restart MT5
2. MT5 will auto-compile when you drag indicator to chart

**Option B: Manual Compilation**
1. Open MetaEditor (F4 in MT5)
2. Navigator → Indicators → InstitutionalVolumeProfile.mq5
3. Double-click to open
4. Click "Compile" button (or press F7)
5. Check "Errors" tab for any issues
   - Should show "0 error(s), 0 warning(s)"

---

### 4️⃣ Apply to Chart

1. In MT5, open any chart (e.g., EURUSD H1)
2. Navigator panel (Ctrl+N) → Indicators
3. Find "InstitutionalVolumeProfile"
4. Drag onto chart
5. Settings window appears:

**Recommended First-Time Settings:**
```
Volume Profile Settings:
├─ Calculation Mode: SESSION_DAILY
├─ Lookback Bars: 100
├─ Price Step Multiplier: 10
└─ Value Area Percentage: 70

Institutional Zone Settings:
└─ Zone Sensitivity: 0.70

Signal Generation:
├─ Signal Trigger Mode: ON_CANDLE_CLOSE
├─ Show Arrows: ✓
├─ Enable Alerts: ✓
└─ Enable Push Notifications: ✗

Machine Learning Filter:
├─ Enable ML Filter: ✓
├─ ML Confidence Threshold: 0.65
└─ ML Learning Rate: 0.01

Visual Settings:
(Use defaults or customize colors)
```

6. Click "OK"

---

### 5️⃣ Verify Installation

**You should see:**

✅ Volume histogram on right side of chart (blue/yellow bars)  
✅ Red bold POC line (Point of Control)  
✅ Green dashed VAH/VAL lines (Value Area)  
✅ Red/Blue dashed zone boundaries  
✅ Gray dotted LVN markers  

**In Terminal (Experts tab):**
```
=== Institutional Volume Profile Initializing ===
Volume Profile: Using Real Volume (or Tick Volume)
ML Filter initialized successfully
=== Initialization Complete ===
Calculation Mode: SESSION_DAILY
Zone Sensitivity: 0.7
ML Filter: ENABLED
```

---

## 🧪 Test Installation

### Quick Test Procedure:

1. **Load Historical Data**
   - Scroll back 3-6 months on chart
   - Let MT5 download history

2. **Look for Signals**
   - Green up arrows = Long signals
   - Red down arrows = Short signals
   - Should see 5-20 signals in 6 months (H1 timeframe)

3. **Check ML System**
   - Open: `MT5/MQL5/Files/Common/`
   - Look for: `ML_History_EURUSD.csv` (or your symbol)
   - If file exists → ML is working ✅

4. **Verify Alerts**
   - Wait for new signal on live chart
   - Alert should popup with signal details
   - Check Terminal → Experts for signal log

---

## 🔧 Troubleshooting

### ❌ "Indicator not found in Navigator"

**Fix:**
- Restart MT5 completely
- Check file is in `MQL5/Indicators/` folder
- Try manual compilation in MetaEditor

---

### ❌ "Compilation errors"

**Common Causes:**

**Error: "Cannot open include file"**
```
Fix: Ensure .mqh files are in MQL5/Include/
     NOT in a subfolder
```

**Error: "Undeclared identifier"**
```
Fix: Missing #include statement
     Re-download all files and replace
```

**Error: "Old style"**
```
Fix: Make sure you're using MT5, not MT4
     These files are MT5 only
```

---

### ❌ "No signals appearing"

**Checklist:**
- ✓ Wait for market to touch zone boundaries
- ✓ Check "Show Arrows" is enabled in settings
- ✓ Try lowering ML Threshold to 0.55
- ✓ Switch to VISIBLE_RANGE calculation mode
- ✓ Ensure you're on a liquid timeframe (M15-H4)

---

### ❌ "ML accuracy stuck at 50%"

**This is normal initially:**
- ML starts neutral (random 50/50)
- Needs 20-30 signals to begin learning
- After 50+ signals, accuracy should improve to 55-65%

**If stuck after 100+ signals:**
- Check ML_History.csv is being created
- Verify "Enable ML Filter" is checked
- Try deleting ML_History.csv to restart learning

---

### ❌ "Zones not showing"

**Possible Causes:**
- No sufficient volume data (check broker provides volume)
- Lookback bars too small (increase to 200)
- Price Step too large (decrease to 5)
- Zone Sensitivity too high (try 0.65)

---

## 📚 Next Steps

### After Successful Installation:

1. **Read UserGuide.md**
   - Understand all parameters
   - Learn signal interpretation
   - Master ML system usage

2. **Read BacktestGuide.md**
   - Validate indicator on historical data
   - Optimize for your symbol/timeframe
   - Build confidence before live trading

3. **Demo Trade 1-2 Months**
   - Follow signals manually
   - Track results in spreadsheet
   - Let ML system learn your market

4. **Go Live Gradually**
   - Start with minimum lot sizes
   - Scale up only after proven results
   - Maintain strict risk management

---

## 📁 File Summary

**After installation, your MT5 folder structure:**

```
Terminal/[ID]/MQL5/
├── Indicators/
│   └── InstitutionalVolumeProfile.mq5  ← Main indicator
│
├── Include/
│   ├── VolumeProfileEngine.mqh         ← Volume calculation
│   ├── InstitutionalZoneDetector.mqh   ← Zone detection
│   ├── SignalEngine.mqh                ← Signal logic
│   ├── MLFilter.mqh                    ← Machine learning
│   └── Visualizer.mqh                  ← Drawing system
│
└── Files/Common/
    └── ML_History_[SYMBOL].csv         ← Auto-generated ML data
```

**Documentation (keep separate for reference):**
```
README.md           ← Overview
UserGuide.md        ← Parameter reference
BacktestGuide.md    ← Testing methodology
```

---

## ✅ Installation Checklist

Before using live:

- [ ] All .mqh files in MQL5/Include/
- [ ] Main .mq5 file in MQL5/Indicators/
- [ ] Indicator compiles without errors
- [ ] Indicator loads on chart successfully
- [ ] Volume histogram visible
- [ ] Zone boundaries showing
- [ ] ML_History.csv file being created
- [ ] Alerts working when signals appear
- [ ] Read UserGuide.md completely
- [ ] Backtested on historical data
- [ ] Demo traded for at least 1 month
- [ ] Risk management plan in place

---

## 🎯 Quick Reference Card

**Best Timeframes:** M15, M30, H1, H4  
**Best Symbols:** EURUSD, GBPUSD, GOLD, BTC  
**Best Sessions:** London, New York overlap  
**Risk Per Trade:** 1-2% maximum  
**Minimum Confidence:** 65%+ (ML filter)  
**Expected Win Rate:** 50-55% (with 2:1 RR)  

---

**Installation Complete! Happy Trading! 📈**

*If you encounter any issues not covered here, check the Terminal → Experts tab for detailed error messages.*
