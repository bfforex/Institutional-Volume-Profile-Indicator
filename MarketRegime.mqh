//+------------------------------------------------------------------+
//|                                               MarketRegime.mqh    |
//|                    Market Regime Classification System             |
//+------------------------------------------------------------------+
#property copyright "Institutional Volume Profile ML System"
#property link      ""
#property version   "2.00"
#property strict

//+------------------------------------------------------------------+
//| Market Regime Enumeration                                         |
//+------------------------------------------------------------------+
enum ENUM_MARKET_REGIME
{
   REGIME_TRENDING_UP,      // Strong uptrend (ADX > 25, +DI > -DI)
   REGIME_TRENDING_DOWN,    // Strong downtrend (ADX > 25, -DI > +DI)
   REGIME_RANGING,          // Sideways (ADX < 20, BB squeeze)
   REGIME_VOLATILE,         // High volatility (ATR > 1.5x average)
   REGIME_LOW_LIQUIDITY     // Low volume/wide spreads
};

//+------------------------------------------------------------------+
//| Regime Analysis Structure                                         |
//+------------------------------------------------------------------+
struct RegimeAnalysis
{
   ENUM_MARKET_REGIME current_regime;
   double regime_confidence;      // 0.0 - 1.0
   double adx_value;
   double plus_di;
   double minus_di;
   double atr_ratio;              // Current ATR / 20-period average ATR
   double bb_squeeze;             // Bollinger Band width ratio
   double volume_ratio;           // Current volume / average volume
   bool   is_favorable_for_long;
   bool   is_favorable_for_short;
};

//+------------------------------------------------------------------+
//| Market Regime Detector Class                                     |
//+------------------------------------------------------------------+
class CMarketRegimeDetector
{
private:
   string m_symbol;
   ENUM_TIMEFRAMES m_timeframe;
   
   // Indicator handles
   int m_adx_handle;
   int m_atr_handle;
   int m_bb_handle;
   
   RegimeAnalysis m_current_analysis;
   
   // Regime history for stability detection
   ENUM_MARKET_REGIME m_regime_history[];
   int m_history_size;
   int m_max_history;
   
   // Parameters
   double m_adx_trending_threshold;
   double m_adx_ranging_threshold;
   double m_atr_volatile_multiplier;
   double m_bb_squeeze_threshold;
   double m_volume_low_threshold;
   
public:
   CMarketRegimeDetector();
   ~CMarketRegimeDetector();
   
   bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe);
   void Deinitialize();
   
   // Core detection
   ENUM_MARKET_REGIME DetectRegime();
   RegimeAnalysis GetFullAnalysis();
   double GetRegimeConfidence();
   
   // Signal filtering
   bool IsRegimeFavorableForSignal(int signal_type);
   double GetRegimeMultiplier(int signal_type);  // Confidence adjustment
   
   // Regime stability
   bool IsRegimeStable(int lookback_periods = 5);
   ENUM_MARKET_REGIME GetDominantRegime(int periods);
   
   // Getters
   string GetRegimeName(ENUM_MARKET_REGIME regime);
   
private:
   // Internal calculation methods
   double CalculateADX();
   double CalculatePlusDI();
   double CalculateMinusDI();
   double CalculateBBSqueeze();
   double CalculateATRRatio();
   double CalculateVolumeRatio();
   void UpdateRegimeHistory(ENUM_MARKET_REGIME regime);
   
   // Regime classification logic
   ENUM_MARKET_REGIME ClassifyRegime(double adx, double plus_di, double minus_di,
                                     double atr_ratio, double bb_squeeze, double vol_ratio);
   double CalculateRegimeConfidence(ENUM_MARKET_REGIME regime, double adx, 
                                    double atr_ratio, double bb_squeeze);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CMarketRegimeDetector::CMarketRegimeDetector()
{
   m_symbol = "";
   m_timeframe = PERIOD_CURRENT;
   
   m_adx_handle = INVALID_HANDLE;
   m_atr_handle = INVALID_HANDLE;
   m_bb_handle = INVALID_HANDLE;
   
   m_history_size = 0;
   m_max_history = 50;
   
   // Default thresholds
   m_adx_trending_threshold = 25.0;
   m_adx_ranging_threshold = 20.0;
   m_atr_volatile_multiplier = 1.5;
   m_bb_squeeze_threshold = 0.5;
   m_volume_low_threshold = 0.7;
   
   // Initialize analysis
   m_current_analysis.current_regime = REGIME_RANGING;
   m_current_analysis.regime_confidence = 0.5;
   m_current_analysis.adx_value = 0;
   m_current_analysis.plus_di = 0;
   m_current_analysis.minus_di = 0;
   m_current_analysis.atr_ratio = 1.0;
   m_current_analysis.bb_squeeze = 0;
   m_current_analysis.volume_ratio = 1.0;
   m_current_analysis.is_favorable_for_long = true;
   m_current_analysis.is_favorable_for_short = true;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CMarketRegimeDetector::~CMarketRegimeDetector()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize regime detector                                       |
//+------------------------------------------------------------------+
bool CMarketRegimeDetector::Initialize(string symbol, ENUM_TIMEFRAMES timeframe)
{
   m_symbol = symbol;
   m_timeframe = timeframe;
   
   // Create ADX indicator
   m_adx_handle = iADX(m_symbol, m_timeframe, 14);
   if(m_adx_handle == INVALID_HANDLE)
   {
      Print("Error: Failed to create ADX indicator handle");
      return false;
   }
   
   // Create ATR indicator
   m_atr_handle = iATR(m_symbol, m_timeframe, 14);
   if(m_atr_handle == INVALID_HANDLE)
   {
      Print("Error: Failed to create ATR indicator handle");
      return false;
   }
   
   // Create Bollinger Bands indicator
   m_bb_handle = iBands(m_symbol, m_timeframe, 20, 0, 2.0, PRICE_CLOSE);
   if(m_bb_handle == INVALID_HANDLE)
   {
      Print("Error: Failed to create Bollinger Bands indicator handle");
      return false;
   }
   
   // Initialize history
   ArrayResize(m_regime_history, m_max_history);
   ArrayInitialize(m_regime_history, REGIME_RANGING);
   
   Print("Market Regime Detector initialized successfully");
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize and release resources                               |
//+------------------------------------------------------------------+
void CMarketRegimeDetector::Deinitialize()
{
   if(m_adx_handle != INVALID_HANDLE)
   {
      IndicatorRelease(m_adx_handle);
      m_adx_handle = INVALID_HANDLE;
   }
   
   if(m_atr_handle != INVALID_HANDLE)
   {
      IndicatorRelease(m_atr_handle);
      m_atr_handle = INVALID_HANDLE;
   }
   
   if(m_bb_handle != INVALID_HANDLE)
   {
      IndicatorRelease(m_bb_handle);
      m_bb_handle = INVALID_HANDLE;
   }
   
   ArrayFree(m_regime_history);
}

//+------------------------------------------------------------------+
//| Detect current market regime                                     |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME CMarketRegimeDetector::DetectRegime()
{
   // Calculate all regime indicators
   double adx = CalculateADX();
   double plus_di = CalculatePlusDI();
   double minus_di = CalculateMinusDI();
   double atr_ratio = CalculateATRRatio();
   double bb_squeeze = CalculateBBSqueeze();
   double vol_ratio = CalculateVolumeRatio();
   
   // Classify regime
   ENUM_MARKET_REGIME regime = ClassifyRegime(adx, plus_di, minus_di, 
                                              atr_ratio, bb_squeeze, vol_ratio);
   
   // Calculate confidence
   double confidence = CalculateRegimeConfidence(regime, adx, atr_ratio, bb_squeeze);
   
   // Update current analysis
   m_current_analysis.current_regime = regime;
   m_current_analysis.regime_confidence = confidence;
   m_current_analysis.adx_value = adx;
   m_current_analysis.plus_di = plus_di;
   m_current_analysis.minus_di = minus_di;
   m_current_analysis.atr_ratio = atr_ratio;
   m_current_analysis.bb_squeeze = bb_squeeze;
   m_current_analysis.volume_ratio = vol_ratio;
   
   // Determine favorability for signal types
   switch(regime)
   {
      case REGIME_TRENDING_UP:
         m_current_analysis.is_favorable_for_long = true;
         m_current_analysis.is_favorable_for_short = false;
         break;
      
      case REGIME_TRENDING_DOWN:
         m_current_analysis.is_favorable_for_long = false;
         m_current_analysis.is_favorable_for_short = true;
         break;
      
      case REGIME_RANGING:
         m_current_analysis.is_favorable_for_long = true;
         m_current_analysis.is_favorable_for_short = true;
         break;
      
      case REGIME_VOLATILE:
         m_current_analysis.is_favorable_for_long = true;
         m_current_analysis.is_favorable_for_short = true;
         break;
      
      case REGIME_LOW_LIQUIDITY:
         m_current_analysis.is_favorable_for_long = false;
         m_current_analysis.is_favorable_for_short = false;
         break;
   }
   
   // Update regime history
   UpdateRegimeHistory(regime);
   
   return regime;
}

//+------------------------------------------------------------------+
//| Classify market regime based on indicators                       |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME CMarketRegimeDetector::ClassifyRegime(double adx, double plus_di, 
                                                         double minus_di, double atr_ratio,
                                                         double bb_squeeze, double vol_ratio)
{
   // Priority 1: Check for low liquidity (avoid trading)
   if(vol_ratio < m_volume_low_threshold)
   {
      return REGIME_LOW_LIQUIDITY;
   }
   
   // Priority 2: Check for high volatility
   if(atr_ratio > m_atr_volatile_multiplier)
   {
      return REGIME_VOLATILE;
   }
   
   // Priority 3: Check for trending conditions
   if(adx > m_adx_trending_threshold)
   {
      if(plus_di > minus_di)
         return REGIME_TRENDING_UP;
      else
         return REGIME_TRENDING_DOWN;
   }
   
   // Priority 4: Check for ranging conditions
   if(adx < m_adx_ranging_threshold || bb_squeeze < m_bb_squeeze_threshold)
   {
      return REGIME_RANGING;
   }
   
   // Default to ranging
   return REGIME_RANGING;
}

//+------------------------------------------------------------------+
//| Calculate regime confidence                                      |
//+------------------------------------------------------------------+
double CMarketRegimeDetector::CalculateRegimeConfidence(ENUM_MARKET_REGIME regime, 
                                                        double adx, double atr_ratio, 
                                                        double bb_squeeze)
{
   double confidence = 0.5; // Base confidence
   
   switch(regime)
   {
      case REGIME_TRENDING_UP:
      case REGIME_TRENDING_DOWN:
         // Higher ADX = more confidence in trend
         confidence = MathMin(1.0, adx / 50.0); // 50 ADX = 100% confidence
         break;
      
      case REGIME_RANGING:
         // Lower ADX and tighter BB = more confidence in range
         double adx_score = 1.0 - (adx / 50.0);
         double bb_score = 1.0 - bb_squeeze;
         confidence = (adx_score + bb_score) / 2.0;
         break;
      
      case REGIME_VOLATILE:
         // Higher ATR ratio = more confidence in volatility
         confidence = MathMin(1.0, (atr_ratio - 1.0) / 1.0);
         break;
      
      case REGIME_LOW_LIQUIDITY:
         // Full confidence - clear avoid signal
         confidence = 1.0;
         break;
   }
   
   return MathMax(0.0, MathMin(1.0, confidence));
}

//+------------------------------------------------------------------+
//| Get full regime analysis                                         |
//+------------------------------------------------------------------+
RegimeAnalysis CMarketRegimeDetector::GetFullAnalysis()
{
   return m_current_analysis;
}

//+------------------------------------------------------------------+
//| Get regime confidence                                            |
//+------------------------------------------------------------------+
double CMarketRegimeDetector::GetRegimeConfidence()
{
   return m_current_analysis.regime_confidence;
}

//+------------------------------------------------------------------+
//| Check if regime is favorable for signal                          |
//+------------------------------------------------------------------+
bool CMarketRegimeDetector::IsRegimeFavorableForSignal(int signal_type)
{
   if(signal_type == 1) // Long
      return m_current_analysis.is_favorable_for_long;
   else if(signal_type == -1) // Short
      return m_current_analysis.is_favorable_for_short;
   
   return false;
}

//+------------------------------------------------------------------+
//| Get regime multiplier for confidence adjustment                  |
//+------------------------------------------------------------------+
double CMarketRegimeDetector::GetRegimeMultiplier(int signal_type)
{
   ENUM_MARKET_REGIME regime = m_current_analysis.current_regime;
   
   // Regime-Signal Compatibility Matrix
   switch(regime)
   {
      case REGIME_TRENDING_UP:
         return (signal_type == 1) ? 1.2 : 0.7;  // Favor longs, reduce shorts
      
      case REGIME_TRENDING_DOWN:
         return (signal_type == -1) ? 1.2 : 0.7; // Favor shorts, reduce longs
      
      case REGIME_RANGING:
         return 1.0; // Neutral for reversals
      
      case REGIME_VOLATILE:
         return 0.8; // Reduce confidence due to wider stops needed
      
      case REGIME_LOW_LIQUIDITY:
         return 0.3; // Strong discourage
   }
   
   return 1.0;
}

//+------------------------------------------------------------------+
//| Check if regime has been stable                                  |
//+------------------------------------------------------------------+
bool CMarketRegimeDetector::IsRegimeStable(int lookback_periods)
{
   if(m_history_size < lookback_periods)
      return false;
   
   ENUM_MARKET_REGIME first_regime = m_regime_history[m_history_size - 1];
   
   // Check if all recent periods have same regime
   for(int i = m_history_size - lookback_periods; i < m_history_size; i++)
   {
      if(m_regime_history[i] != first_regime)
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get dominant regime over period                                  |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME CMarketRegimeDetector::GetDominantRegime(int periods)
{
   if(m_history_size < periods)
      periods = m_history_size;
   
   if(periods == 0)
      return REGIME_RANGING;
   
   // Count occurrences of each regime
   int regime_counts[5]; // 5 regime types
   ArrayInitialize(regime_counts, 0);
   
   for(int i = m_history_size - periods; i < m_history_size; i++)
   {
      regime_counts[m_regime_history[i]]++;
   }
   
   // Find most common regime
   int max_count = 0;
   ENUM_MARKET_REGIME dominant = REGIME_RANGING;
   
   for(int i = 0; i < 5; i++)
   {
      if(regime_counts[i] > max_count)
      {
         max_count = regime_counts[i];
         dominant = (ENUM_MARKET_REGIME)i;
      }
   }
   
   return dominant;
}

//+------------------------------------------------------------------+
//| Get regime name as string                                        |
//+------------------------------------------------------------------+
string CMarketRegimeDetector::GetRegimeName(ENUM_MARKET_REGIME regime)
{
   switch(regime)
   {
      case REGIME_TRENDING_UP:   return "Trending Up";
      case REGIME_TRENDING_DOWN: return "Trending Down";
      case REGIME_RANGING:       return "Ranging";
      case REGIME_VOLATILE:      return "Volatile";
      case REGIME_LOW_LIQUIDITY: return "Low Liquidity";
   }
   return "Unknown";
}

//+------------------------------------------------------------------+
//| Calculate ADX value                                              |
//+------------------------------------------------------------------+
double CMarketRegimeDetector::CalculateADX()
{
   if(m_adx_handle == INVALID_HANDLE)
      return 0;
   
   double adx_buffer[];
   ArraySetAsSeries(adx_buffer, true);
   
   if(CopyBuffer(m_adx_handle, 0, 0, 1, adx_buffer) <= 0)
      return 0;
   
   return adx_buffer[0];
}

//+------------------------------------------------------------------+
//| Calculate +DI value                                              |
//+------------------------------------------------------------------+
double CMarketRegimeDetector::CalculatePlusDI()
{
   if(m_adx_handle == INVALID_HANDLE)
      return 0;
   
   double plus_di_buffer[];
   ArraySetAsSeries(plus_di_buffer, true);
   
   if(CopyBuffer(m_adx_handle, 1, 0, 1, plus_di_buffer) <= 0)
      return 0;
   
   return plus_di_buffer[0];
}

//+------------------------------------------------------------------+
//| Calculate -DI value                                              |
//+------------------------------------------------------------------+
double CMarketRegimeDetector::CalculateMinusDI()
{
   if(m_adx_handle == INVALID_HANDLE)
      return 0;
   
   double minus_di_buffer[];
   ArraySetAsSeries(minus_di_buffer, true);
   
   if(CopyBuffer(m_adx_handle, 2, 0, 1, minus_di_buffer) <= 0)
      return 0;
   
   return minus_di_buffer[0];
}

//+------------------------------------------------------------------+
//| Calculate Bollinger Band squeeze                                 |
//+------------------------------------------------------------------+
double CMarketRegimeDetector::CalculateBBSqueeze()
{
   if(m_bb_handle == INVALID_HANDLE)
      return 1.0;
   
   double upper[], lower[], middle[];
   ArraySetAsSeries(upper, true);
   ArraySetAsSeries(lower, true);
   ArraySetAsSeries(middle, true);
   
   if(CopyBuffer(m_bb_handle, 0, 0, 1, middle) <= 0 ||
      CopyBuffer(m_bb_handle, 1, 0, 1, upper) <= 0 ||
      CopyBuffer(m_bb_handle, 2, 0, 1, lower) <= 0)
      return 1.0;
   
   double current_width = upper[0] - lower[0];
   
   // Calculate average width over 20 periods
   double sum_width = 0;
   int periods = 20;
   
   for(int i = 0; i < periods; i++)
   {
      double u[], l[];
      ArraySetAsSeries(u, true);
      ArraySetAsSeries(l, true);
      
      if(CopyBuffer(m_bb_handle, 1, i, 1, u) > 0 &&
         CopyBuffer(m_bb_handle, 2, i, 1, l) > 0)
      {
         sum_width += (u[0] - l[0]);
      }
   }
   
   double avg_width = sum_width / periods;
   
   if(avg_width == 0) return 1.0;
   
   return current_width / avg_width; // <1 = squeeze, >1 = expansion
}

//+------------------------------------------------------------------+
//| Calculate ATR ratio                                              |
//+------------------------------------------------------------------+
double CMarketRegimeDetector::CalculateATRRatio()
{
   if(m_atr_handle == INVALID_HANDLE)
      return 1.0;
   
   double atr_buffer[];
   ArraySetAsSeries(atr_buffer, true);
   
   if(CopyBuffer(m_atr_handle, 0, 0, 21, atr_buffer) < 21)
      return 1.0;
   
   double current_atr = atr_buffer[0];
   
   // Calculate average ATR over 20 periods
   double sum_atr = 0;
   for(int i = 1; i < 21; i++)
   {
      sum_atr += atr_buffer[i];
   }
   
   double avg_atr = sum_atr / 20.0;
   
   if(avg_atr == 0) return 1.0;
   
   return current_atr / avg_atr;
}

//+------------------------------------------------------------------+
//| Calculate volume ratio                                           |
//+------------------------------------------------------------------+
double CMarketRegimeDetector::CalculateVolumeRatio()
{
   long current_volume = iVolume(m_symbol, m_timeframe, 0);
   
   // Calculate average volume over 20 periods
   long sum_volume = 0;
   int periods = 20;
   
   for(int i = 1; i <= periods; i++)
   {
      sum_volume += iVolume(m_symbol, m_timeframe, i);
   }
   
   double avg_volume = (double)sum_volume / periods;
   
   if(avg_volume == 0) return 1.0;
   
   return (double)current_volume / avg_volume;
}

//+------------------------------------------------------------------+
//| Update regime history                                            |
//+------------------------------------------------------------------+
void CMarketRegimeDetector::UpdateRegimeHistory(ENUM_MARKET_REGIME regime)
{
   // Shift array if at capacity
   if(m_history_size >= m_max_history)
   {
      for(int i = 0; i < m_max_history - 1; i++)
      {
         m_regime_history[i] = m_regime_history[i + 1];
      }
      m_regime_history[m_max_history - 1] = regime;
   }
   else
   {
      m_regime_history[m_history_size] = regime;
      m_history_size++;
   }
}
//+------------------------------------------------------------------+
