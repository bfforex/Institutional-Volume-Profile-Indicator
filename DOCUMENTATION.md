# Institutional Volume Profile Indicator - Documentation

## Overview

The Institutional Volume Profile Indicator is an advanced MQL5 indicator for MetaTrader 5 that identifies high-probability reversal zones based on institutional trading activity. Unlike standard volume profile indicators that show a single Point of Control (POC) line, this indicator identifies entire institutional zones with upper and lower boundaries and generates smart entry signals at zone edges.

## Key Features

### 1. High Volume Node (HVN) Cluster Detection
- Analyzes volume distribution across price levels
- Identifies clusters of high-volume nodes that indicate institutional accumulation
- Configurable threshold multiplier to define what constitutes "high volume"
- Minimum cluster size filter to avoid false positives

### 2. Institutional Zone Boundaries
- Defines clear upper and lower zone edges instead of single POC line
- Zones represent "fortresses" where institutions have established positions
- Configurable zone expansion for safety margins
- Visual representation on chart with color-coded boundaries

### 3. First-Touch Reversal Signals
- Generates buy signals when price first touches the lower zone edge
- Generates sell signals when price first touches the upper zone edge
- Implements First-Touch principle: only the first touch generates a signal
- Prevents signal spam in ranging markets
- Configurable signal expiry

### 4. Adaptive ML-Based Filter
- Machine learning component that learns from historical signal performance
- Dynamically adjusts sensitivity based on success rate
- Reduces false signals over time
- Self-improving system that adapts to changing market conditions
- Configurable learning period for optimization

## Installation

1. Copy `InstitutionalVolumeProfile.mq5` to your MetaTrader 5 indicators folder:
   - Default location: `C:\Users\[YourUsername]\AppData\Roaming\MetaQuotes\Terminal\[TerminalID]\MQL5\Indicators\`

2. Restart MetaTrader 5 or refresh the Navigator panel

3. Drag and drop the indicator onto any chart

## Input Parameters

### Volume Profile Settings
- **InpPeriod** (default: 100): Number of bars to analyze for volume profile calculation
- **InpPriceRows** (default: 50): Number of price levels to divide the range into (higher = more precision)
- **InpHVNThreshold** (default: 1.5): Multiplier for average volume to identify high-volume nodes (higher = stricter)
- **InpMinClusterSize** (default: 3): Minimum number of consecutive HVN nodes to form a valid cluster

### Zone Settings
- **InpZoneExpansion** (default: 0.1): Percentage to expand zone boundaries beyond the cluster (0.1 = 10%)

### ML Filter Settings
- **InpEnableMLFilter** (default: true): Enable/disable the adaptive ML-based signal filter
- **InpMLSensitivity** (default: 0.5): Initial sensitivity threshold (0.0-1.0, lower = more signals)
- **InpMLLearningPeriod** (default: 500): Number of historical signals to analyze for learning

### Display Settings
- **InpShowZones** (default: true): Display institutional zone boundaries
- **InpShowSignals** (default: true): Display buy/sell arrow signals
- **InpShowPOC** (default: true): Display Point of Control line
- **InpFirstTouchOnly** (default: true): Only generate signal on first touch of zone edge
- **InpSignalExpiry** (default: 10): Bars after which signal is considered expired for ML evaluation

## How It Works

### Volume Profile Calculation
1. Analyzes the last N bars (InpPeriod)
2. Divides the price range into equal rows (InpPriceRows)
3. Distributes volume to price rows based on bar overlap
4. Creates a histogram of volume at each price level

### HVN Cluster Identification
1. Calculates average volume across all price levels
2. Identifies nodes with volume above threshold (avgVolume × InpHVNThreshold)
3. Groups consecutive high-volume nodes into clusters
4. Filters clusters by minimum size requirement

### Institutional Zone Definition
1. Selects the cluster with highest total volume (largest institutional position)
2. Identifies Point of Control (POC) as the highest volume node within cluster
3. Sets lower boundary at cluster bottom minus expansion
4. Sets upper boundary at cluster top plus expansion
5. Updates zone boundaries as new data becomes available

### Signal Generation
1. Monitors price action relative to zone boundaries
2. **Buy Signal**: Triggered when price touches or penetrates lower edge and closes above it
3. **Sell Signal**: Triggered when price touches or penetrates upper edge and closes below it
4. Calculates confidence score based on:
   - Distance from POC (closer = higher confidence)
   - Total volume in zone (higher = higher confidence)
   - Rejection candle patterns (longer wick = higher confidence)

### ML-Based Adaptive Filter
1. Records each signal with its confidence score
2. Evaluates signal success after expiry period:
   - Buy signal success: Price moved higher
   - Sell signal success: Price moved lower
3. Calculates success rate over learning period
4. Adjusts sensitivity dynamically:
   - High success rate (>65%): Decreases threshold (accepts more signals)
   - Low success rate (<45%): Increases threshold (becomes more selective)
5. Self-adjusts to market conditions without user intervention

## Trading Strategy

### Entry Rules
- **Long Entry**: 
  - Buy signal appears at lower zone boundary
  - Confirm with price action (rejection wick preferred)
  - Enter at market or on next bar open
  
- **Short Entry**:
  - Sell signal appears at upper zone boundary
  - Confirm with price action (rejection wick preferred)
  - Enter at market or on next bar open

### Stop Loss
- **Long**: Place below lower zone boundary (e.g., 5-10 pips below)
- **Short**: Place above upper zone boundary (e.g., 5-10 pips above)

### Take Profit
- **Option 1**: Opposite zone boundary (Lower to Upper for longs, Upper to Lower for shorts)
- **Option 2**: POC line as intermediate target
- **Option 3**: Fixed risk-reward ratio (e.g., 2:1 or 3:1)

### Risk Management
- Never risk more than 1-2% of account per trade
- Use proper position sizing based on stop loss distance
- Consider reducing position size when ML sensitivity is high (indicator is being selective)

## Optimization Tips

### For Trending Markets
- Increase InpHVNThreshold to 2.0 or higher (more selective zones)
- Disable First-Touch principle (InpFirstTouchOnly = false) to catch multiple touches
- Increase InpPeriod to 150-200 for larger context

### For Ranging Markets
- Decrease InpHVNThreshold to 1.2-1.3 (more responsive)
- Enable First-Touch principle (InpFirstTouchOnly = true)
- Decrease InpPeriod to 50-80 for more recent data

### For Higher Timeframes (H4, Daily)
- Increase InpPeriod to 200-300
- Increase InpMLLearningPeriod to 1000
- Increase InpZoneExpansion to 0.15-0.2

### For Lower Timeframes (M5, M15)
- Decrease InpPeriod to 50-75
- Enable ML filter for noise reduction
- Consider increasing InpMinClusterSize to 4-5

## Performance Optimization

- The indicator recalculates on every tick, which is normal for real-time zone updates
- For better performance on lower-end systems:
  - Reduce InpPriceRows to 30-40
  - Reduce InpPeriod to 75-100
  - Disable InpShowPOC if not needed
  
## Troubleshooting

### No Zones Appearing
- Decrease InpHVNThreshold (try 1.2)
- Decrease InpMinClusterSize (try 2)
- Ensure sufficient historical data is loaded on chart
- Check that InpShowZones is enabled

### Too Many Signals
- Enable ML filter (InpEnableMLFilter = true)
- Increase InpMLSensitivity to 0.6-0.7
- Enable First-Touch principle
- Increase InpHVNThreshold for more stable zones

### No Signals Appearing
- Disable ML filter temporarily to see if it's filtering all signals
- Decrease InpMLSensitivity to 0.3-0.4
- Check that InpShowSignals is enabled
- Verify zones are appearing on chart

### Zones Updating Too Frequently
- Increase InpPeriod for more stable zones
- Increase InpMinClusterSize to filter out smaller clusters
- Use higher timeframe charts for more stable zones

## Technical Details

### Indicator Buffers
1. **ZoneUpperBuffer**: Upper boundary of institutional zone
2. **ZoneLowerBuffer**: Lower boundary of institutional zone
3. **BuySignalBuffer**: Buy signal arrows at lower boundary
4. **SellSignalBuffer**: Sell signal arrows at upper boundary
5. **POCBuffer**: Point of Control line (optional display)

### Calculation Frequency
- Recalculates on every new bar
- ML filter updates periodically via timer
- Historical bars remain static once calculated

### Data Structures
- **VolumeNode**: Stores price and volume for each level
- **InstitutionalZone**: Stores zone boundaries, POC, and touch status
- **MLSignalRecord**: Stores signal history for machine learning

## Version History

### Version 1.00 (2026-02-02)
- Initial release
- Core volume profile calculation
- HVN cluster detection
- Institutional zone boundaries
- First-Touch signal generation
- ML-based adaptive filter
- Configurable display options

## Support and Feedback

For questions, bug reports, or feature requests, please visit:
https://github.com/bfforex/Institutional-Volume-Profile-Indicator

## License

Copyright 2026, Institutional Trading Co.
All rights reserved.

## Disclaimer

This indicator is provided for educational and informational purposes only. Trading financial instruments carries a high level of risk and may not be suitable for all investors. Past performance is not indicative of future results. Always conduct your own analysis and risk assessment before trading.
