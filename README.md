# Institutional Volume Profile Indicator

![MT5](https://img.shields.io/badge/Platform-MetaTrader%205-blue)
![MQL5](https://img.shields.io/badge/Language-MQL5-orange)
![Version](https://img.shields.io/badge/Version-1.0-green)
![License](https://img.shields.io/badge/License-Proprietary-red)

## 🎯 Advanced MT5 Indicator for Institutional Zone Edge Reversals

A sophisticated MQL5 indicator that goes beyond traditional Volume Profile analysis by identifying institutional trading zones and generating high-probability reversal signals at zone edges using machine learning-enhanced filtering.

## ✨ Key Features

### 🏰 Institutional Zone Detection
- **HVN Cluster Identification**: Detects High Volume Node clusters that represent institutional accumulation/distribution zones
- **Zone Boundaries**: Defines clear upper and lower edges instead of a single POC line
- **Dynamic Updates**: Zones adapt to market structure in real-time

### 🎯 Smart Signal Generation
- **First-Touch Principle**: Generates signals only on the first touch of zone boundaries to avoid signal spam
- **Edge Reversals**: Identifies high-probability reversal points at institutional zone edges
- **Confidence Scoring**: Each signal includes a confidence score based on multiple factors

### 🤖 ML-Based Adaptive Filter
- **Self-Learning**: Analyzes historical signal performance to improve accuracy
- **Dynamic Sensitivity**: Automatically adjusts filtering threshold based on success rate
- **False Signal Reduction**: Learns from mistakes to reduce false positives over time

### 📊 Visual Clarity
- **Zone Boundaries**: Clear blue lines showing institutional zone edges
- **Entry Signals**: Green (buy) and red (sell) arrows at optimal entry points
- **POC Line**: Optional Point of Control reference line
- **Clean Interface**: Non-intrusive visual design

## 🚀 Quick Start

### Installation
1. Download `InstitutionalVolumeProfile.mq5`
2. Copy to: `MetaTrader 5/MQL5/Indicators/`
3. Restart MT5 or refresh Navigator
4. Drag indicator onto any chart

### Basic Usage
1. Apply indicator to your chart (works on any timeframe)
2. Wait for blue zone boundaries to appear
3. Look for green arrow (buy) at lower boundary
4. Look for red arrow (sell) at upper boundary
5. Enter trades according to your risk management rules

## 📈 How It Works

### 1. Volume Profile Analysis
The indicator analyzes the last N bars and creates a volume distribution across price levels:
```
Price Levels    Volume
   ↑           
$50,100      ▓▓▓▓▓▓▓▓▓▓▓▓▓  ← HVN (High Volume Node)
$50,090      ▓▓▓▓▓▓▓▓▓▓▓▓▓  ← HVN (Institutional Zone)
$50,080      ▓▓▓▓▓▓▓▓▓▓     ← HVN
$50,070      ▓▓▓▓           
$50,060      ▓▓▓            
```

### 2. HVN Cluster Detection
Identifies contiguous groups of high-volume nodes that represent institutional zones:
- Calculates average volume across all levels
- Marks nodes exceeding threshold (e.g., 1.5x average)
- Groups consecutive HVN nodes into clusters
- Selects largest cluster as primary institutional zone

### 3. Zone Boundary Definition
Establishes trading zones with precise boundaries:
- **Lower Edge**: Bottom of HVN cluster minus expansion buffer
- **Upper Edge**: Top of HVN cluster plus expansion buffer
- **POC**: Highest volume node within cluster (optional display)

### 4. Signal Generation & ML Filter
Generates and filters signals for optimal accuracy:
- Detects price touches at zone edges
- Calculates confidence based on:
  - Distance from POC
  - Zone volume strength
  - Rejection candle patterns
- ML filter evaluates historical performance
- Dynamically adjusts acceptance threshold

## ⚙️ Configuration

### Essential Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| InpPeriod | 100 | Bars to analyze for volume profile |
| InpHVNThreshold | 1.5 | Volume multiplier for HVN detection |
| InpMLSensitivity | 0.5 | Initial ML filter threshold (0.0-1.0) |
| InpFirstTouchOnly | true | Only signal on first zone touch |

### Advanced Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| InpPriceRows | 50 | Price level granularity |
| InpMinClusterSize | 3 | Minimum HVN nodes for valid cluster |
| InpZoneExpansion | 0.1 | Zone boundary expansion (10%) |
| InpMLLearningPeriod | 500 | Historical signals for ML learning |
| InpSignalExpiry | 10 | Bars before signal evaluation |

## 📖 Documentation

For detailed documentation, see [DOCUMENTATION.md](DOCUMENTATION.md) which includes:
- Comprehensive parameter explanations
- Trading strategy guidelines
- Optimization tips for different market conditions
- Troubleshooting guide
- Technical implementation details

## 🎓 Trading Strategy

### Entry Rules
- **Long**: Buy signal at lower boundary + bullish rejection
- **Short**: Sell signal at upper boundary + bearish rejection

### Stop Loss
- **Long**: Below lower boundary (e.g., -10 pips)
- **Short**: Above upper boundary (e.g., +10 pips)

### Take Profit
- **Target 1**: POC line (partial profit)
- **Target 2**: Opposite boundary (full profit)
- **Alternative**: Fixed R:R ratio (2:1 or 3:1)

## 🔧 Optimization Guide

### For Different Timeframes

**Scalping (M5, M15)**
```
InpPeriod = 50-75
InpMLSensitivity = 0.6-0.7
InpHVNThreshold = 1.3-1.5
```

**Day Trading (H1, H4)**
```
InpPeriod = 100-150
InpMLSensitivity = 0.5
InpHVNThreshold = 1.5
```

**Swing Trading (Daily, Weekly)**
```
InpPeriod = 200-300
InpMLSensitivity = 0.4-0.5
InpHVNThreshold = 1.8-2.0
```

### For Different Market Conditions

**Trending Markets**
- Increase `InpHVNThreshold` to 2.0
- Set `InpFirstTouchOnly = false`
- Increase `InpPeriod` to 150-200

**Ranging Markets**
- Decrease `InpHVNThreshold` to 1.2-1.3
- Set `InpFirstTouchOnly = true`
- Standard `InpPeriod` (100)

## 🧪 Testing Recommendations

1. **Backtest** on historical data to find optimal parameters
2. **Forward Test** on demo account for 2-4 weeks
3. **Monitor ML Filter** performance and adjust if needed
4. **Start Small** on live account while building confidence

## 🛠️ Technical Requirements

- **Platform**: MetaTrader 5 (Build 3440 or higher recommended)
- **Chart Data**: Minimum 500 bars of history
- **Timeframes**: Works on all timeframes (M1 to MN)
- **Instruments**: All forex pairs, indices, commodities, crypto

## 📊 Performance Metrics

The ML-based filter continuously tracks:
- Signal success rate
- False positive rate
- Average confidence scores
- Adaptive sensitivity adjustments

Monitor these internally to ensure the indicator is performing optimally for your trading style.

## ⚠️ Important Notes

- **Not a Holy Grail**: Use as part of a complete trading system
- **Risk Management**: Always use proper position sizing and stop losses
- **Market Conditions**: Performance varies across different market environments
- **Continuous Learning**: ML filter needs time to adapt (2-4 weeks minimum)

## 🤝 Contributing

This is a proprietary indicator. For feature requests or bug reports, please open an issue on GitHub.

## 📄 License

Copyright 2026, Institutional Trading Co. All rights reserved.

## ⚠️ Disclaimer

**RISK WARNING**: Trading financial instruments involves substantial risk of loss. This indicator is provided for educational purposes only. Past performance is not indicative of future results. Always conduct thorough testing and use proper risk management.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/bfforex/Institutional-Volume-Profile-Indicator/issues)
- **Documentation**: [DOCUMENTATION.md](DOCUMENTATION.md)
- **Website**: https://bfforex.com

---

**Made with ❤️ for serious traders who demand institutional-grade analysis**
