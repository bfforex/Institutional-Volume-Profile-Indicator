# Usage Examples

## Example 1: Standard Setup for EUR/USD H1

### Configuration
```
Symbol: EUR/USD
Timeframe: H1 (1 Hour)
Parameters:
- InpPeriod = 100
- InpPriceRows = 50
- InpHVNThreshold = 1.5
- InpMinClusterSize = 3
- InpZoneExpansion = 0.1
- InpEnableMLFilter = true
- InpMLSensitivity = 0.5
- InpFirstTouchOnly = true
```

### Expected Behavior
- Zones appear as blue horizontal boundaries
- Buy signals (green arrows) at lower boundary during uptrend pullbacks
- Sell signals (red arrows) at upper boundary during downtrend pullbacks
- POC line (yellow dotted) shows institutional fair value

### Trading Plan
1. Wait for price to approach zone boundary
2. Look for rejection candle (long wick)
3. Enter on signal arrow appearance
4. Stop loss: 15 pips beyond zone boundary
5. Take profit: Opposite boundary or 2:1 R:R

---

## Example 2: Scalping Setup for GBP/USD M15

### Configuration
```
Symbol: GBP/USD
Timeframe: M15 (15 Minutes)
Parameters:
- InpPeriod = 60
- InpPriceRows = 40
- InpHVNThreshold = 1.4
- InpMinClusterSize = 3
- InpZoneExpansion = 0.08
- InpEnableMLFilter = true
- InpMLSensitivity = 0.65
- InpFirstTouchOnly = true
```

### Rationale
- Shorter period (60) for faster zone updates
- Higher ML sensitivity (0.65) to filter noise on lower timeframe
- Smaller zone expansion (0.08) for tighter entries
- Lower HVN threshold (1.4) for more responsive zones

### Trading Plan
1. Monitor during London or New York session
2. Trade only first touch of each zone
3. Enter immediately on signal arrow
4. Stop loss: 8-10 pips beyond zone
5. Take profit: POC line or 1.5:1 R:R
6. Maximum 3 trades per session

---

## Example 3: Swing Trading Setup for Gold (XAU/USD) H4

### Configuration
```
Symbol: XAU/USD
Timeframe: H4 (4 Hours)
Parameters:
- InpPeriod = 150
- InpPriceRows = 60
- InpHVNThreshold = 1.8
- InpMinClusterSize = 4
- InpZoneExpansion = 0.12
- InpEnableMLFilter = true
- InpMLSensitivity = 0.45
- InpFirstTouchOnly = false
```

### Rationale
- Longer period (150) for more stable zones
- Higher HVN threshold (1.8) for major institutional zones only
- First-touch disabled to catch multiple touches in ranging gold market
- Lower ML sensitivity (0.45) to capture more opportunities

### Trading Plan
1. Analyze daily timeframe for overall trend
2. Wait for H4 signal in trend direction
3. Enter on signal with confirmation from candlestick pattern
4. Stop loss: $15-20 beyond zone boundary
5. Take profit: Opposite boundary (typically $30-50)
6. Trail stop once price reaches POC

---

## Example 4: Cryptocurrency (BTC/USD) H1 - High Volatility

### Configuration
```
Symbol: BTC/USD
Timeframe: H1
Parameters:
- InpPeriod = 80
- InpPriceRows = 50
- InpHVNThreshold = 1.6
- InpMinClusterSize = 3
- InpZoneExpansion = 0.15
- InpEnableMLFilter = true
- InpMLSensitivity = 0.7
- InpFirstTouchOnly = true
```

### Rationale
- Shorter period (80) to adapt quickly to volatile crypto markets
- Larger zone expansion (0.15) for wider stop losses due to volatility
- High ML sensitivity (0.7) to filter out many false breakouts common in crypto
- Moderate HVN threshold (1.6) balanced for crypto volume patterns

### Trading Plan
1. Trade only during high liquidity hours
2. Wait for clear rejection at zone boundary
3. Enter with 1-2% account risk
4. Stop loss: $200-300 beyond zone (adjust for BTC price)
5. Take profit: POC or 2:1 R:R minimum
6. Consider partial profit-taking at POC

---

## Example 5: Index Trading (S&P 500) Daily

### Configuration
```
Symbol: US500 (S&P 500)
Timeframe: Daily
Parameters:
- InpPeriod = 200
- InpPriceRows = 60
- InpHVNThreshold = 2.0
- InpMinClusterSize = 5
- InpZoneExpansion = 0.1
- InpEnableMLFilter = true
- InpMLSensitivity = 0.4
- InpFirstTouchOnly = false
```

### Rationale
- Long period (200) for major institutional zones on daily chart
- Very high HVN threshold (2.0) to identify only the strongest zones
- Large minimum cluster size (5) for significant zones
- First-touch disabled for position trading approach
- Low ML sensitivity (0.4) to catch all valid opportunities

### Trading Plan
1. Identify prevailing trend on weekly chart
2. Wait for daily signal in trend direction
3. Enter on signal confirmation
4. Stop loss: 1-2% beyond zone boundary
5. Take profit: Opposite boundary or trail with 50% at POC
6. Hold for multiple days/weeks

---

## Example 6: Range Trading (AUD/USD) H4

### Configuration
```
Symbol: AUD/USD
Timeframe: H4
Parameters:
- InpPeriod = 120
- InpPriceRows = 50
- InpHVNThreshold = 1.3
- InpMinClusterSize = 3
- InpZoneExpansion = 0.1
- InpEnableMLFilter = false
- InpMLSensitivity = N/A
- InpFirstTouchOnly = true
```

### Rationale
- ML filter disabled (ranging markets often have consistent patterns)
- Lower HVN threshold (1.3) to identify range boundaries
- Standard period (120) balanced for H4 ranging markets
- First-touch principle to avoid overtrading in range

### Trading Plan
1. Confirm ranging market (no strong trend)
2. Buy at lower boundary, sell at upper boundary
3. Take profit at opposite boundary consistently
4. Stop loss: tight beyond zone (10-15 pips)
5. Exit if price breaks out of range
6. Best during Asian or off-peak sessions

---

## Signal Interpretation Guide

### High Confidence Signals
Look for combinations of:
- ✅ Arrow appears at zone edge
- ✅ Long rejection wick on the candle
- ✅ Signal close to POC line
- ✅ ML filter passes (indicator shows arrow)
- ✅ Higher timeframe confirms trend/support

### Medium Confidence Signals
- ✅ Arrow appears at zone edge
- ⚠️ Moderate rejection wick
- ⚠️ Further from POC
- ✅ ML filter passes

### Low Confidence Signals (Avoid)
- ❌ No rejection candle
- ❌ Far from POC
- ❌ ML filter blocks signal (no arrow shown)
- ❌ Against higher timeframe trend

---

## Optimization Process

### Step 1: Initial Testing (1-2 weeks)
- Use default parameters
- Paper trade or demo account
- Record all signals and outcomes
- Note market conditions (trending/ranging)

### Step 2: Parameter Adjustment
Based on results:
- **Too many false signals**: Increase InpHVNThreshold or InpMLSensitivity
- **Too few signals**: Decrease InpHVNThreshold or InpMLSensitivity
- **Zones too unstable**: Increase InpPeriod or InpMinClusterSize
- **Missing good trades**: Decrease InpMLSensitivity

### Step 3: Forward Testing (2-4 weeks)
- Apply adjusted parameters
- Continue demo trading
- Let ML filter learn and adapt
- Monitor success rate improvement

### Step 4: Live Trading (Small Size)
- Start with minimum position size
- Gradually increase as confidence grows
- Continue monitoring and adjusting
- Document your optimal settings

---

## Common Patterns and How to Trade Them

### Pattern 1: Bull Flag at Lower Boundary
```
Setup: Uptrend, pullback to lower zone boundary
Signal: Green buy arrow with bullish rejection
Entry: On signal confirmation
Target: Upper boundary or previous high
```

### Pattern 2: Bear Flag at Upper Boundary
```
Setup: Downtrend, rally to upper zone boundary
Signal: Red sell arrow with bearish rejection
Entry: On signal confirmation
Target: Lower boundary or previous low
```

### Pattern 3: Double Touch Reversal
```
Setup: Second touch of boundary (InpFirstTouchOnly = false)
Signal: Arrow appears on second touch with stronger rejection
Entry: More confident entry on second touch
Target: Opposite boundary
```

### Pattern 4: POC Magnet
```
Setup: Signal at zone edge, price between edge and POC
Signal: Arrow appears
Entry: On signal
Target: POC line first, then opposite boundary
```

### Pattern 5: Breakout Failure
```
Setup: Price briefly breaks zone boundary then reverses back
Signal: Arrow appears on reversal bar
Entry: High confidence - false breakout trap
Target: Opposite boundary or beyond
```

---

## Troubleshooting Scenarios

### Scenario 1: "Indicator shows no zones"
**Solution**: 
- Decrease InpHVNThreshold to 1.2
- Ensure sufficient bars loaded (500+)
- Try different timeframe
- Decrease InpMinClusterSize to 2

### Scenario 2: "Too many signals, can't trade them all"
**Solution**:
- Enable InpFirstTouchOnly
- Increase InpMLSensitivity to 0.65-0.75
- Filter signals by additional confirmation (MA, RSI, etc.)
- Trade only in trend direction

### Scenario 3: "Signals not appearing but zones are visible"
**Solution**:
- Check if InpShowSignals is enabled
- ML filter may be blocking all signals - decrease InpMLSensitivity
- Temporarily disable ML filter to check
- Increase learning period for ML (InpMLLearningPeriod)

### Scenario 4: "Zones keep changing every bar"
**Solution**:
- Increase InpPeriod for more stability
- Increase InpMinClusterSize
- Move to higher timeframe
- Increase InpHVNThreshold for more significant zones

---

## Performance Tracking Template

### Weekly Review Template
```
Week of: [Date]
Symbol: [Symbol]
Timeframe: [TF]

Signals Taken: [X]
Winners: [X]
Losers: [X]
Win Rate: [X%]

Best Setup: [Description]
Worst Setup: [Description]

Parameters Used:
- InpPeriod: [X]
- InpHVNThreshold: [X]
- InpMLSensitivity: [X]

Adjustments for Next Week:
- [List changes]

Notes:
- [Market observations]
```

Track this data to optimize your personal usage of the indicator!
