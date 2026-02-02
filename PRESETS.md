# Parameter Configuration Presets

This file contains pre-configured parameter sets optimized for different trading scenarios. Copy and paste these into your MT5 indicator settings.

## Quick Reference

| Preset Name | Best For | Timeframe | Risk Level |
|-------------|----------|-----------|------------|
| Conservative | Swing trading, lower frequency | H4, Daily | Low |
| Balanced | Day trading, moderate frequency | H1, H4 | Medium |
| Aggressive | Scalping, high frequency | M5, M15 | High |
| Trending | Strong directional markets | All | Medium |
| Ranging | Sideways markets | H1, H4 | Low |
| Volatile | High volatility instruments (crypto, indices) | M15, H1 | High |

---

## Preset 1: Conservative (Recommended for Beginners)

**Best for**: Swing trading, position trading, learning the indicator

```
InpPeriod = 150
InpPriceRows = 60
InpHVNThreshold = 2.0
InpMinClusterSize = 4
InpZoneExpansion = 0.12
InpEnableMLFilter = true
InpMLSensitivity = 0.65
InpMLLearningPeriod = 500
InpShowZones = true
InpShowSignals = true
InpShowPOC = true
InpFirstTouchOnly = true
InpSignalExpiry = 15
```

**Characteristics**:
- Very selective signals (high quality over quantity)
- Stable zones that don't change frequently
- Lower false positive rate
- Suitable for part-time traders
- Less screen time required

**Expected Signal Frequency**: 1-3 per week per pair

---

## Preset 2: Balanced (Default - Recommended for Most Traders)

**Best for**: Day trading, general purpose use

```
InpPeriod = 100
InpPriceRows = 50
InpHVNThreshold = 1.5
InpMinClusterSize = 3
InpZoneExpansion = 0.1
InpEnableMLFilter = true
InpMLSensitivity = 0.5
InpMLLearningPeriod = 500
InpShowZones = true
InpShowSignals = true
InpShowPOC = true
InpFirstTouchOnly = true
InpSignalExpiry = 10
```

**Characteristics**:
- Good balance between signal frequency and quality
- Moderate zone stability
- Adaptable to various market conditions
- Suitable for active traders

**Expected Signal Frequency**: 3-7 per week per pair

---

## Preset 3: Aggressive (Advanced Traders Only)

**Best for**: Scalping, active intraday trading

```
InpPeriod = 50
InpPriceRows = 40
InpHVNThreshold = 1.3
InpMinClusterSize = 2
InpZoneExpansion = 0.08
InpEnableMLFilter = true
InpMLSensitivity = 0.7
InpMLLearningPeriod = 300
InpShowZones = true
InpShowSignals = true
InpShowPOC = false
InpFirstTouchOnly = true
InpSignalExpiry = 5
```

**Characteristics**:
- Higher signal frequency
- More responsive to market changes
- Higher ML sensitivity to filter noise
- Requires active monitoring
- Higher false positive risk

**Expected Signal Frequency**: 5-15 per day per pair

---

## Preset 4: Trending Markets

**Best for**: Strong trending markets, breakout trading

```
InpPeriod = 120
InpPriceRows = 50
InpHVNThreshold = 1.8
InpMinClusterSize = 4
InpZoneExpansion = 0.1
InpEnableMLFilter = true
InpMLSensitivity = 0.45
InpMLLearningPeriod = 500
InpShowZones = true
InpShowSignals = true
InpShowPOC = true
InpFirstTouchOnly = false
InpSignalExpiry = 12
```

**Characteristics**:
- Multiple touches allowed (better for trending markets)
- Higher HVN threshold for major zones only
- Lower ML sensitivity to catch trend continuations
- Larger clusters required

**Expected Signal Frequency**: 2-5 per week per pair

---

## Preset 5: Ranging Markets

**Best for**: Sideways markets, range trading

```
InpPeriod = 80
InpPriceRows = 50
InpHVNThreshold = 1.3
InpMinClusterSize = 3
InpZoneExpansion = 0.08
InpEnableMLFilter = false
InpMLSensitivity = 0.0
InpMLLearningPeriod = 500
InpShowZones = true
InpShowSignals = true
InpShowPOC = true
InpFirstTouchOnly = true
InpSignalExpiry = 10
```

**Characteristics**:
- ML filter disabled (ranges are predictable)
- Shorter period for faster zone adaptation
- Lower HVN threshold to catch range boundaries
- First-touch principle to avoid overtrading

**Expected Signal Frequency**: 4-8 per week per pair

---

## Preset 6: High Volatility (Crypto, News Events)

**Best for**: Cryptocurrency, high volatility instruments

```
InpPeriod = 80
InpPriceRows = 50
InpHVNThreshold = 1.6
InpMinClusterSize = 3
InpZoneExpansion = 0.15
InpEnableMLFilter = true
InpMLSensitivity = 0.7
InpMLLearningPeriod = 400
InpShowZones = true
InpShowSignals = true
InpShowPOC = true
InpFirstTouchOnly = true
InpSignalExpiry = 8
```

**Characteristics**:
- Larger zone expansion for wider stops
- High ML sensitivity to filter volatility noise
- Shorter period for faster adaptation
- Moderate HVN threshold

**Expected Signal Frequency**: 5-10 per week per pair

---

## Preset 7: Forex Majors (EUR/USD, GBP/USD, USD/JPY)

**Best for**: Major forex pairs during liquid sessions

```
InpPeriod = 100
InpPriceRows = 50
InpHVNThreshold = 1.5
InpMinClusterSize = 3
InpZoneExpansion = 0.1
InpEnableMLFilter = true
InpMLSensitivity = 0.5
InpMLLearningPeriod = 500
InpShowZones = true
InpShowSignals = true
InpShowPOC = true
InpFirstTouchOnly = true
InpSignalExpiry = 10
```

**Characteristics**:
- Default settings work well for liquid forex pairs
- Balanced approach for consistent performance
- Suitable for London and New York sessions

**Expected Signal Frequency**: 3-6 per week per pair

---

## Preset 8: Gold (XAU/USD)

**Best for**: Gold trading on H1 or H4 timeframes

```
InpPeriod = 120
InpPriceRows = 60
InpHVNThreshold = 1.7
InpMinClusterSize = 4
InpZoneExpansion = 0.12
InpEnableMLFilter = true
InpMLSensitivity = 0.55
InpMLLearningPeriod = 500
InpShowZones = true
InpShowSignals = true
InpShowPOC = true
InpFirstTouchOnly = false
InpSignalExpiry = 12
```

**Characteristics**:
- Higher threshold for gold's strong institutional zones
- Multiple touches allowed (gold often tests levels)
- Larger expansion for gold's volatility
- More price rows for precision

**Expected Signal Frequency**: 2-4 per week

---

## Preset 9: Stock Indices (S&P 500, NASDAQ)

**Best for**: Index trading on H4 or Daily

```
InpPeriod = 150
InpPriceRows = 60
InpHVNThreshold = 1.8
InpMinClusterSize = 4
InpZoneExpansion = 0.1
InpEnableMLFilter = true
InpMLSensitivity = 0.45
InpMLLearningPeriod = 600
InpShowZones = true
InpShowSignals = true
InpShowPOC = true
InpFirstTouchOnly = false
InpSignalExpiry = 15
```

**Characteristics**:
- Longer period for major institutional zones
- High HVN threshold for significant levels only
- Lower ML sensitivity to catch all valid moves
- Larger learning period for better adaptation

**Expected Signal Frequency**: 1-3 per week

---

## Preset 10: Weekend Trader (Daily Charts)

**Best for**: Part-time traders checking charts once per day

```
InpPeriod = 200
InpPriceRows = 60
InpHVNThreshold = 2.0
InpMinClusterSize = 5
InpZoneExpansion = 0.15
InpEnableMLFilter = true
InpMLSensitivity = 0.6
InpMLLearningPeriod = 500
InpShowZones = true
InpShowSignals = true
InpShowPOC = true
InpFirstTouchOnly = true
InpSignalExpiry = 20
```

**Characteristics**:
- Very stable zones on daily charts
- High quality signals only
- Minimal monitoring required
- Suitable for busy professionals

**Expected Signal Frequency**: 1-2 per month per pair

---

## Custom Optimization Guide

### If you're getting too many signals:
1. Increase `InpMLSensitivity` by 0.1
2. Increase `InpHVNThreshold` by 0.2
3. Enable `InpFirstTouchOnly` if disabled
4. Increase `InpMinClusterSize` by 1

### If you're getting too few signals:
1. Decrease `InpMLSensitivity` by 0.1
2. Decrease `InpHVNThreshold` by 0.2
3. Disable `InpFirstTouchOnly` if enabled
4. Decrease `InpMinClusterSize` by 1

### If zones are too unstable:
1. Increase `InpPeriod` by 25-50
2. Increase `InpMinClusterSize` by 1-2
3. Increase `InpHVNThreshold` by 0.2-0.3

### If zones are too slow to update:
1. Decrease `InpPeriod` by 25-50
2. Decrease `InpHVNThreshold` by 0.2

### If ML filter is too aggressive:
1. Decrease `InpMLSensitivity` by 0.1-0.2
2. Increase `InpMLLearningPeriod` for more data
3. Consider disabling temporarily

### If ML filter is too permissive:
1. Increase `InpMLSensitivity` by 0.1-0.2
2. Ensure sufficient learning period (minimum 300)
3. Wait for filter to adapt (2-4 weeks)

---

## How to Apply Presets

### Method 1: Manual Entry
1. Open indicator settings in MT5
2. Input tab -> Copy values from preset above
3. Click OK

### Method 2: Save as Template
1. Apply preset manually once
2. Right-click chart -> Template -> Save Template
3. Name it (e.g., "IVP_Conservative")
4. Apply template to new charts instantly

### Method 3: Set File
1. Navigate to: MQL5/Profiles/Templates/
2. Create .set file with parameters
3. Load from indicator settings

---

## Testing New Presets

When trying a new preset:

1. **Week 1**: Paper trade or demo account
2. **Week 2**: Continue demo, track all signals
3. **Week 3-4**: Let ML filter learn and adapt
4. **Week 5+**: Consider live trading with small size

**Important**: Allow at least 2-4 weeks for the ML filter to adapt to your specific trading conditions and instrument characteristics.

---

## Preset Performance Tracking

Track your results with each preset:

```
Preset: [Name]
Period: [Date Range]
Instrument: [Symbol]
Timeframe: [TF]

Total Signals: [X]
Trades Taken: [X]
Winners: [X]
Losers: [X]
Win Rate: [X%]
Avg R:R: [X:1]

Notes: [Your observations]

Adjustments Made:
- [Parameter changes and reasons]
```

---

## Recommended Combinations

### For Multiple Timeframes
- **Higher TF**: Conservative or Balanced preset (trend direction)
- **Lower TF**: Aggressive or Balanced preset (entry timing)

### For Portfolio Trading
- **Conservative**: 40% of pairs (core holdings)
- **Balanced**: 40% of pairs (active trading)
- **Aggressive**: 20% of pairs (opportunistic)

### For Different Sessions
- **Asian Session**: Ranging preset (lower volatility)
- **London Session**: Balanced or Trending preset
- **New York Session**: Balanced or Volatile preset
- **NY-London Overlap**: Aggressive or Trending preset

---

**Remember**: These presets are starting points. Your optimal settings will depend on your:
- Trading style
- Risk tolerance
- Available screen time
- Instrument characteristics
- Market conditions

Always backtest and forward test any configuration before using it with real money!
