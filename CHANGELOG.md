# Changelog

All notable changes to the Institutional Volume Profile Indicator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-02

### Added
- Initial release of Institutional Volume Profile Indicator
- Core volume profile calculation engine with price row distribution
- High Volume Node (HVN) cluster detection algorithm
- Institutional zone boundary definition (upper/lower edges)
- Point of Control (POC) calculation and display
- First-Touch principle for signal generation
- Buy signal generation at lower zone boundary
- Sell signal generation at upper zone boundary
- ML-based adaptive filter for signal quality enhancement
- Dynamic sensitivity adjustment based on historical performance
- Signal confidence scoring system based on multiple factors:
  - Distance from POC
  - Zone volume strength
  - Rejection candle pattern detection
- Configurable parameters for all major features
- Visual display system with color-coded indicators:
  - Blue zone boundaries
  - Green buy arrows
  - Red sell arrows
  - Yellow POC line
- Signal history tracking for ML learning
- Automatic performance evaluation after signal expiry
- Touch tracking for First-Touch principle implementation
- Support for all MetaTrader 5 timeframes (M1 to MN)
- Support for all instrument types (forex, indices, commodities, crypto)

### Features by Category

#### Volume Profile Features
- Customizable analysis period (InpPeriod)
- Adjustable price row granularity (InpPriceRows)
- Volume distribution across price levels
- Overlap-based volume allocation for accuracy

#### HVN Detection Features
- Threshold-based node identification (InpHVNThreshold)
- Contiguous cluster grouping
- Minimum cluster size filtering (InpMinClusterSize)
- Largest cluster selection for primary zone

#### Zone Definition Features
- Upper and lower boundary calculation
- Zone expansion buffer (InpZoneExpansion)
- POC identification within cluster
- Dynamic zone updates with market evolution

#### Signal Generation Features
- Edge touch detection (upper and lower)
- First-Touch principle option (InpFirstTouchOnly)
- Rejection candle pattern recognition
- Multi-factor confidence calculation
- Signal expiry tracking (InpSignalExpiry)

#### ML Filter Features
- Historical signal recording
- Success rate calculation
- Adaptive sensitivity adjustment
- Learning period customization (InpMLLearningPeriod)
- Enable/disable option (InpEnableMLFilter)
- Initial sensitivity setting (InpMLSensitivity)
- Automatic threshold optimization

#### Display Features
- Toggle zones display (InpShowZones)
- Toggle signals display (InpShowSignals)
- Toggle POC display (InpShowPOC)
- Custom arrow indicators for buy/sell signals
- Color-coded visual elements

### Technical Implementation
- 5 indicator buffers for efficient rendering
- Optimized array operations with series indexing
- Modular function architecture for maintainability
- Struct-based data management
- Dynamic memory allocation for ML history
- Timer-based ML filter updates

### Documentation
- Comprehensive README with quick start guide
- Detailed DOCUMENTATION.md with all features explained
- EXAMPLES.md with 6+ real-world usage scenarios
- Parameter optimization guidelines
- Trading strategy recommendations
- Troubleshooting guide

## [Unreleased]

### Planned Features
- Multi-timeframe zone analysis
- Alert system for signal notifications
- Export signal history to CSV
- Backtesting report generation
- Custom zone color schemes
- Additional signal filters (momentum, volatility)
- Performance dashboard overlay
- Zone strength indicator (volume intensity gauge)
- Historical zone persistence tracking
- Support/resistance confluence detection

### Under Consideration
- Integration with other indicators via buffers
- Custom sound alerts for signals
- Email/push notifications for signals
- Zone breakout detection and alerts
- Volume anomaly detection
- Order flow analysis integration
- Institutional footprint visualization
- Advanced ML models (neural networks)
- Real-time performance metrics display
- Cloud-based signal sharing

## Version Numbering Scheme

- **Major version** (X.0.0): Breaking changes, major new features, architecture changes
- **Minor version** (1.X.0): New features, non-breaking improvements, significant enhancements
- **Patch version** (1.0.X): Bug fixes, minor improvements, documentation updates

## Support Policy

- Latest version receives active development and bug fixes
- Previous minor versions receive critical bug fixes for 6 months
- Documentation kept current with latest version only

## Migration Guide

### From Version X.X.X to Version 1.0.0
N/A - Initial release

## Known Issues

### Version 1.0.0
- None reported yet

## Deprecation Notices

### Version 1.0.0
- No deprecations in initial release

---

## How to Report Issues

If you encounter any issues:
1. Check the DOCUMENTATION.md troubleshooting section
2. Verify you're using the latest version
3. Check Known Issues in this changelog
4. Open an issue on GitHub with:
   - Version number
   - Platform (MT5 build number)
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable

## How to Request Features

Feature requests are welcome! Please open an issue on GitHub with:
- Clear description of the feature
- Use case and benefits
- Any relevant examples or mockups

---

**Note**: This changelog will be updated with each release. Subscribe to the repository to receive notifications of new versions.
