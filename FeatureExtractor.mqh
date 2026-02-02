//+------------------------------------------------------------------+
//|                                            FeatureExtractor.mqh   |
//|                         Advanced Feature Engineering for ML        |
//+------------------------------------------------------------------+
#property copyright "Institutional Volume Profile ML System"
#property link      ""
#property version   "2.00"
#property strict

#include "InstitutionalZoneDetector.mqh"

//+------------------------------------------------------------------+
//| Extended ML Feature Vector Structure (18 features)               |
//+------------------------------------------------------------------+
struct ExtendedMLFeatures
{
   // Original 8 features
   double distance_to_poc;        // X1: Distance from entry to POC
   double distance_to_edge;       // X2: Distance to zone boundary
   double volume_delta;           // X3: Buy-sell volume imbalance
   double rejection_ratio;        // X4: Wick to body ratio
   double atr_normalized_vol;     // X5: ATR-normalized volatility
   double trend_slope;            // X6: Higher timeframe trend
   double time_since_break;       // X7: Bars since zone break
   double lvn_proximity;          // X8: Distance to nearest LVN
   
   // New 10 features
   double order_flow_imbalance;   // X9: Aggressive buy vs sell delta
   double market_session;         // X10: Trading session encoded
   double spread_normalized;      // X11: Current spread vs average
   double rsi_value;              // X12: RSI normalized to 0-1
   double rsi_divergence;         // X13: Price vs RSI divergence
   double vwap_distance;          // X14: Distance from VWAP
   double cumulative_delta;       // X15: Running buy-sell imbalance
   double bb_position;            // X16: Position within Bollinger Bands
   double historical_zone_winrate;// X17: Past performance at zone
   double candle_body_ratio;      // X18: Body size / Total range
   
   // Metadata
   int    signal_type;            // 1=Long, -1=Short
   double entry_price;
   datetime entry_time;
   int    outcome;                // 1=success, 0=failure, -1=pending
   double actual_rr;              // Actual risk-reward achieved
};

//+------------------------------------------------------------------+
//| Feature Extraction Class                                         |
//+------------------------------------------------------------------+
class CFeatureExtractor
{
private:
   string m_symbol;
   ENUM_TIMEFRAMES m_timeframe;
   double m_atr_value;
   int m_atr_period;
   
   // Indicator handles
   int m_rsi_handle;
   int m_bb_handle;
   
   // VWAP calculation
   double m_session_vwap;
   long   m_session_volume;
   double m_session_tpv;          // Total Price * Volume
   datetime m_session_start;
   
   // Cumulative delta tracking
   double m_cumulative_delta;
   datetime m_last_delta_update;
   
   // Spread tracking
   double m_spread_history[];
   int m_spread_history_size;
   int m_spread_period;
   
   // Historical zone performance tracking
   struct ZonePerformance
   {
      double price_level;
      int wins;
      int losses;
      datetime last_update;
   };
   ZonePerformance m_zone_history[];
   int m_zone_history_count;
   
public:
   CFeatureExtractor();
   ~CFeatureExtractor();
   
   bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe);
   void Deinitialize();
   
   // Main feature extraction
   ExtendedMLFeatures ExtractAllFeatures(int signal_type, double entry_price, 
                                         InstitutionalZone* zone, int zone_index);
   
   // Individual feature extractors
   double CalculateOrderFlowImbalance(int lookback_bars = 10);
   double GetMarketSession();
   double CalculateSpreadNormalized();
   double GetRSIValue(int period = 14);
   double DetectRSIDivergence(int lookback = 10);
   double CalculateVWAPDistance(double price);
   double GetCumulativeDelta();
   double GetBollingerBandPosition();
   double GetHistoricalZoneWinRate(double zone_price, double tolerance = 0.0001);
   double CalculateCandleBodyRatio(int bar_index = 0);
   
   // Session VWAP management
   void ResetSessionVWAP();
   void UpdateSessionVWAP();
   bool IsNewSession();
   
   // Historical performance tracking
   void UpdateZonePerformance(double zone_price, int outcome);
   
   // Normalization
   void NormalizeFeatures(ExtendedMLFeatures &features, double min_vals[], double max_vals[]);
   
   // Helper functions
   double GetATR();
   double CalculateRejectionRatio(int bar_index);
   double CalculateVolumeDelta(int bar_index);
   double CalculateTrendSlope();
   int GetBarsSinceZoneBreak(int zone_index);
   
private:
   // Internal helpers
   void InitializeIndicators();
   void UpdateSpreadHistory();
   datetime GetSessionStart(datetime current_time);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CFeatureExtractor::CFeatureExtractor()
{
   m_symbol = "";
   m_timeframe = PERIOD_CURRENT;
   m_atr_period = 14;
   m_atr_value = 0;
   m_rsi_handle = INVALID_HANDLE;
   m_bb_handle = INVALID_HANDLE;
   
   m_session_vwap = 0;
   m_session_volume = 0;
   m_session_tpv = 0;
   m_session_start = 0;
   
   m_cumulative_delta = 0;
   m_last_delta_update = 0;
   
   m_spread_history_size = 0;
   m_spread_period = 20;
   
   m_zone_history_count = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CFeatureExtractor::~CFeatureExtractor()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize feature extractor                                     |
//+------------------------------------------------------------------+
bool CFeatureExtractor::Initialize(string symbol, ENUM_TIMEFRAMES timeframe)
{
   m_symbol = symbol;
   m_timeframe = timeframe;
   
   // Initialize indicators
   InitializeIndicators();
   
   // Initialize spread tracking
   ArrayResize(m_spread_history, m_spread_period);
   ArrayInitialize(m_spread_history, 0);
   
   // Initialize zone performance tracking
   ArrayResize(m_zone_history, 100); // Initial capacity
   m_zone_history_count = 0;
   
   // Initialize session tracking
   m_session_start = GetSessionStart(TimeCurrent());
   UpdateSessionVWAP();
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize and release resources                               |
//+------------------------------------------------------------------+
void CFeatureExtractor::Deinitialize()
{
   if(m_rsi_handle != INVALID_HANDLE)
   {
      IndicatorRelease(m_rsi_handle);
      m_rsi_handle = INVALID_HANDLE;
   }
   
   if(m_bb_handle != INVALID_HANDLE)
   {
      IndicatorRelease(m_bb_handle);
      m_bb_handle = INVALID_HANDLE;
   }
   
   ArrayFree(m_spread_history);
   ArrayFree(m_zone_history);
}

//+------------------------------------------------------------------+
//| Initialize technical indicators                                  |
//+------------------------------------------------------------------+
void CFeatureExtractor::InitializeIndicators()
{
   // RSI indicator
   m_rsi_handle = iRSI(m_symbol, m_timeframe, 14, PRICE_CLOSE);
   if(m_rsi_handle == INVALID_HANDLE)
      Print("Warning: Failed to create RSI indicator handle");
   
   // Bollinger Bands indicator
   m_bb_handle = iBands(m_symbol, m_timeframe, 20, 0, 2.0, PRICE_CLOSE);
   if(m_bb_handle == INVALID_HANDLE)
      Print("Warning: Failed to create Bollinger Bands indicator handle");
}

//+------------------------------------------------------------------+
//| Extract all 18 features for a signal                             |
//+------------------------------------------------------------------+
ExtendedMLFeatures CFeatureExtractor::ExtractAllFeatures(int signal_type, double entry_price,
                                                          InstitutionalZone* zone, int zone_index)
{
   ExtendedMLFeatures features;
   
   // Update ATR value
   m_atr_value = GetATR();
   if(m_atr_value <= 0) m_atr_value = 0.0001; // Prevent division by zero
   
   // Check for new session and update VWAP
   if(IsNewSession())
      ResetSessionVWAP();
   UpdateSessionVWAP();
   
   // Original 8 features
   if(zone != NULL)
   {
      features.distance_to_poc = MathAbs(entry_price - zone.poc_price) / m_atr_value;
      
      double edge_dist = (signal_type == 1) ? 
                         MathAbs(entry_price - zone.lower_boundary) :
                         MathAbs(entry_price - zone.upper_boundary);
      features.distance_to_edge = edge_dist / m_atr_value;
      
      double nearest_lvn = (signal_type == 1) ? 
                           zone.nearest_lvn_below :
                           zone.nearest_lvn_above;
      features.lvn_proximity = (nearest_lvn > 0) ? 
                              MathAbs(entry_price - nearest_lvn) / m_atr_value : 1.0;
   }
   else
   {
      features.distance_to_poc = 0;
      features.distance_to_edge = 0;
      features.lvn_proximity = 1.0;
   }
   
   features.volume_delta = CalculateVolumeDelta(0);
   features.rejection_ratio = CalculateRejectionRatio(0);
   
   double price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   features.atr_normalized_vol = (price > 0) ? m_atr_value / price : 0;
   
   features.trend_slope = CalculateTrendSlope();
   features.time_since_break = GetBarsSinceZoneBreak(zone_index);
   
   // New 10 features
   features.order_flow_imbalance = CalculateOrderFlowImbalance(10);
   features.market_session = GetMarketSession();
   features.spread_normalized = CalculateSpreadNormalized();
   features.rsi_value = GetRSIValue(14);
   features.rsi_divergence = DetectRSIDivergence(10);
   features.vwap_distance = CalculateVWAPDistance(entry_price);
   features.cumulative_delta = GetCumulativeDelta();
   features.bb_position = GetBollingerBandPosition();
   features.historical_zone_winrate = (zone != NULL) ? 
                                      GetHistoricalZoneWinRate(zone.poc_price, 0.0001) : 0.5;
   features.candle_body_ratio = CalculateCandleBodyRatio(0);
   
   // Metadata
   features.signal_type = signal_type;
   features.entry_price = entry_price;
   features.entry_time = TimeCurrent();
   features.outcome = -1; // Pending
   features.actual_rr = 0;
   
   return features;
}

//+------------------------------------------------------------------+
//| Calculate order flow imbalance from tick data                    |
//+------------------------------------------------------------------+
double CFeatureExtractor::CalculateOrderFlowImbalance(int lookback_bars = 10)
{
   // Simplified version using candle direction as proxy
   // Full implementation would use CopyTicks() for actual tick analysis
   double aggressive_buy = 0;
   double aggressive_sell = 0;
   
   for(int i = 0; i < lookback_bars; i++)
   {
      double open = iOpen(m_symbol, m_timeframe, i);
      double close = iClose(m_symbol, m_timeframe, i);
      long volume = iVolume(m_symbol, m_timeframe, i);
      
      if(close > open)
         aggressive_buy += volume;
      else if(close < open)
         aggressive_sell += volume;
   }
   
   double total = aggressive_buy + aggressive_sell;
   if(total == 0) return 0;
   
   return (aggressive_buy - aggressive_sell) / total; // Range: -1 to +1
}

//+------------------------------------------------------------------+
//| Get current market session encoded                               |
//+------------------------------------------------------------------+
double CFeatureExtractor::GetMarketSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hour = dt.hour; // UTC hour
   
   // Asian session: 0:00 - 8:00 UTC = 0.33
   if(hour >= 0 && hour < 8)
      return 0.33;
   
   // London session: 8:00 - 16:00 UTC = 0.66
   if(hour >= 8 && hour < 16)
      return 0.66;
   
   // New York session: 16:00 - 24:00 UTC = 1.0
   return 1.0;
}

//+------------------------------------------------------------------+
//| Calculate normalized spread                                      |
//+------------------------------------------------------------------+
double CFeatureExtractor::CalculateSpreadNormalized()
{
   UpdateSpreadHistory();
   
   long current_spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
   
   // Calculate average spread from history
   double sum = 0;
   int count = 0;
   for(int i = 0; i < m_spread_history_size; i++)
   {
      if(m_spread_history[i] > 0)
      {
         sum += m_spread_history[i];
         count++;
      }
   }
   
   if(count == 0) return 1.0;
   
   double avg_spread = sum / count;
   if(avg_spread <= 0) return 1.0;
   
   return current_spread / avg_spread; // >1 = wider than average, <1 = tighter
}

//+------------------------------------------------------------------+
//| Update spread history buffer                                     |
//+------------------------------------------------------------------+
void CFeatureExtractor::UpdateSpreadHistory()
{
   long current_spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
   
   // Shift array and add new value
   if(m_spread_history_size >= m_spread_period)
   {
      for(int i = m_spread_period - 1; i > 0; i--)
         m_spread_history[i] = m_spread_history[i - 1];
      m_spread_history[0] = current_spread;
   }
   else
   {
      m_spread_history[m_spread_history_size] = current_spread;
      m_spread_history_size++;
   }
}

//+------------------------------------------------------------------+
//| Get RSI value normalized to 0-1                                  |
//+------------------------------------------------------------------+
double CFeatureExtractor::GetRSIValue(int period = 14)
{
   if(m_rsi_handle == INVALID_HANDLE)
      return 0.5; // Neutral if indicator unavailable
   
   double rsi_buffer[];
   ArraySetAsSeries(rsi_buffer, true);
   
   if(CopyBuffer(m_rsi_handle, 0, 0, 1, rsi_buffer) <= 0)
      return 0.5;
   
   return rsi_buffer[0] / 100.0; // Normalize from 0-100 to 0-1
}

//+------------------------------------------------------------------+
//| Detect RSI divergence                                            |
//+------------------------------------------------------------------+
double CFeatureExtractor::DetectRSIDivergence(int lookback = 10)
{
   if(m_rsi_handle == INVALID_HANDLE)
      return 0; // No divergence
   
   double rsi_buffer[];
   ArraySetAsSeries(rsi_buffer, true);
   
   if(CopyBuffer(m_rsi_handle, 0, 0, lookback + 1, rsi_buffer) <= 0)
      return 0;
   
   // Calculate price slope
   double price_start = iClose(m_symbol, m_timeframe, lookback);
   double price_end = iClose(m_symbol, m_timeframe, 0);
   double price_slope = price_end - price_start;
   
   // Calculate RSI slope
   double rsi_slope = rsi_buffer[0] - rsi_buffer[lookback];
   
   // Detect divergence: price and RSI moving in opposite directions
   if(price_slope > 0 && rsi_slope < 0)
      return -1.0; // Bearish divergence
   else if(price_slope < 0 && rsi_slope > 0)
      return 1.0; // Bullish divergence
   
   return 0; // No divergence
}

//+------------------------------------------------------------------+
//| Calculate distance from VWAP                                     |
//+------------------------------------------------------------------+
double CFeatureExtractor::CalculateVWAPDistance(double price)
{
   if(m_session_vwap == 0 || m_atr_value == 0)
      return 0;
   
   return (price - m_session_vwap) / m_atr_value;
}

//+------------------------------------------------------------------+
//| Get cumulative delta                                             |
//+------------------------------------------------------------------+
double CFeatureExtractor::GetCumulativeDelta()
{
   // Update cumulative delta with latest bar
   datetime current_time = TimeCurrent();
   if(current_time != m_last_delta_update)
   {
      double delta = CalculateVolumeDelta(0);
      m_cumulative_delta += delta;
      m_last_delta_update = current_time;
      
      // Reset on new session
      if(IsNewSession())
         m_cumulative_delta = 0;
   }
   
   return m_cumulative_delta;
}

//+------------------------------------------------------------------+
//| Get price position within Bollinger Bands                        |
//+------------------------------------------------------------------+
double CFeatureExtractor::GetBollingerBandPosition()
{
   if(m_bb_handle == INVALID_HANDLE)
      return 0.5; // Middle if indicator unavailable
   
   double upper[], lower[], middle[];
   ArraySetAsSeries(upper, true);
   ArraySetAsSeries(lower, true);
   ArraySetAsSeries(middle, true);
   
   if(CopyBuffer(m_bb_handle, 0, 0, 1, middle) <= 0 ||
      CopyBuffer(m_bb_handle, 1, 0, 1, upper) <= 0 ||
      CopyBuffer(m_bb_handle, 2, 0, 1, lower) <= 0)
      return 0.5;
   
   double price = iClose(m_symbol, m_timeframe, 0);
   double range = upper[0] - lower[0];
   
   if(range == 0) return 0.5;
   
   // Position: 0 = lower band, 0.5 = middle, 1 = upper band
   double position = (price - lower[0]) / range;
   return MathMax(0, MathMin(1.0, position));
}

//+------------------------------------------------------------------+
//| Get historical win rate at similar zones                         |
//+------------------------------------------------------------------+
double CFeatureExtractor::GetHistoricalZoneWinRate(double zone_price, double tolerance = 0.0001)
{
   int wins = 0;
   int losses = 0;
   
   // Search for zones within tolerance
   for(int i = 0; i < m_zone_history_count; i++)
   {
      if(MathAbs(m_zone_history[i].price_level - zone_price) <= tolerance)
      {
         wins += m_zone_history[i].wins;
         losses += m_zone_history[i].losses;
      }
   }
   
   int total = wins + losses;
   if(total == 0) return 0.5; // No history = neutral
   
   return (double)wins / (double)total;
}

//+------------------------------------------------------------------+
//| Calculate candle body ratio                                      |
//+------------------------------------------------------------------+
double CFeatureExtractor::CalculateCandleBodyRatio(int bar_index = 0)
{
   double open = iOpen(m_symbol, m_timeframe, bar_index);
   double close = iClose(m_symbol, m_timeframe, bar_index);
   double high = iHigh(m_symbol, m_timeframe, bar_index);
   double low = iLow(m_symbol, m_timeframe, bar_index);
   
   double body = MathAbs(close - open);
   double range = high - low;
   
   if(range == 0) return 0;
   
   return body / range; // 0 = all wick, 1 = all body
}

//+------------------------------------------------------------------+
//| Reset session VWAP calculation                                   |
//+------------------------------------------------------------------+
void CFeatureExtractor::ResetSessionVWAP()
{
   m_session_vwap = 0;
   m_session_volume = 0;
   m_session_tpv = 0;
   m_session_start = GetSessionStart(TimeCurrent());
}

//+------------------------------------------------------------------+
//| Update session VWAP                                              |
//+------------------------------------------------------------------+
void CFeatureExtractor::UpdateSessionVWAP()
{
   double close = iClose(m_symbol, m_timeframe, 0);
   long volume = iVolume(m_symbol, m_timeframe, 0);
   
   m_session_tpv += close * volume;
   m_session_volume += volume;
   
   if(m_session_volume > 0)
      m_session_vwap = m_session_tpv / m_session_volume;
}

//+------------------------------------------------------------------+
//| Check if new session has started                                 |
//+------------------------------------------------------------------+
bool CFeatureExtractor::IsNewSession()
{
   datetime current_session = GetSessionStart(TimeCurrent());
   if(current_session != m_session_start)
   {
      m_session_start = current_session;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Get session start time                                           |
//+------------------------------------------------------------------+
datetime CFeatureExtractor::GetSessionStart(datetime current_time)
{
   MqlDateTime dt;
   TimeToStruct(current_time, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Update zone performance history                                  |
//+------------------------------------------------------------------+
void CFeatureExtractor::UpdateZonePerformance(double zone_price, int outcome)
{
   bool found = false;
   double tolerance = 0.0001;
   
   // Find existing zone record
   for(int i = 0; i < m_zone_history_count; i++)
   {
      if(MathAbs(m_zone_history[i].price_level - zone_price) <= tolerance)
      {
         if(outcome == 1)
            m_zone_history[i].wins++;
         else if(outcome == 0)
            m_zone_history[i].losses++;
         
         m_zone_history[i].last_update = TimeCurrent();
         found = true;
         break;
      }
   }
   
   // Add new zone record if not found
   if(!found)
   {
      if(m_zone_history_count >= ArraySize(m_zone_history))
         ArrayResize(m_zone_history, m_zone_history_count + 50);
      
      m_zone_history[m_zone_history_count].price_level = zone_price;
      m_zone_history[m_zone_history_count].wins = (outcome == 1) ? 1 : 0;
      m_zone_history[m_zone_history_count].losses = (outcome == 0) ? 1 : 0;
      m_zone_history[m_zone_history_count].last_update = TimeCurrent();
      m_zone_history_count++;
   }
}

//+------------------------------------------------------------------+
//| Get ATR value                                                    |
//+------------------------------------------------------------------+
double CFeatureExtractor::GetATR()
{
   double atr = iATR(m_symbol, m_timeframe, m_atr_period, 0);
   return (atr > 0) ? atr : 0.0001;
}

//+------------------------------------------------------------------+
//| Calculate rejection ratio (wick to body)                         |
//+------------------------------------------------------------------+
double CFeatureExtractor::CalculateRejectionRatio(int bar_index)
{
   double open = iOpen(m_symbol, m_timeframe, bar_index);
   double close = iClose(m_symbol, m_timeframe, bar_index);
   double high = iHigh(m_symbol, m_timeframe, bar_index);
   double low = iLow(m_symbol, m_timeframe, bar_index);
   
   double body = MathAbs(close - open);
   double upper_wick = high - MathMax(open, close);
   double lower_wick = MathMin(open, close) - low;
   
   if(body == 0) return 0;
   
   double max_wick = MathMax(upper_wick, lower_wick);
   return max_wick / body;
}

//+------------------------------------------------------------------+
//| Calculate volume delta (buy vs sell pressure)                    |
//+------------------------------------------------------------------+
double CFeatureExtractor::CalculateVolumeDelta(int bar_index)
{
   double open = iOpen(m_symbol, m_timeframe, bar_index);
   double close = iClose(m_symbol, m_timeframe, bar_index);
   
   if(close > open)
      return 1.0; // Bullish
   else if(close < open)
      return -1.0; // Bearish
   else
      return 0.0; // Neutral
}

//+------------------------------------------------------------------+
//| Calculate trend slope from higher timeframe                      |
//+------------------------------------------------------------------+
double CFeatureExtractor::CalculateTrendSlope()
{
   ENUM_TIMEFRAMES htf = PERIOD_H1;
   if(m_timeframe == PERIOD_H1) htf = PERIOD_H4;
   if(m_timeframe == PERIOD_H4) htf = PERIOD_D1;
   
   double ema_now = iMA(m_symbol, htf, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema_prev = iMA(m_symbol, htf, 50, 0, MODE_EMA, PRICE_CLOSE, 5);
   
   if(m_atr_value == 0) return 0;
   
   return (ema_now - ema_prev) / m_atr_value;
}

//+------------------------------------------------------------------+
//| Get bars since zone was broken                                   |
//+------------------------------------------------------------------+
int CFeatureExtractor::GetBarsSinceZoneBreak(int zone_index)
{
   // Simplified - returns placeholder value
   // Full implementation would track historical zone breaks
   return 10;
}

//+------------------------------------------------------------------+
//| Normalize features to [0, 1] range                               |
//+------------------------------------------------------------------+
void CFeatureExtractor::NormalizeFeatures(ExtendedMLFeatures &features, 
                                         double min_vals[], double max_vals[])
{
   double raw_features[18];
   raw_features[0] = features.distance_to_poc;
   raw_features[1] = features.distance_to_edge;
   raw_features[2] = features.volume_delta;
   raw_features[3] = features.rejection_ratio;
   raw_features[4] = features.atr_normalized_vol;
   raw_features[5] = features.trend_slope;
   raw_features[6] = features.time_since_break;
   raw_features[7] = features.lvn_proximity;
   raw_features[8] = features.order_flow_imbalance;
   raw_features[9] = features.market_session;
   raw_features[10] = features.spread_normalized;
   raw_features[11] = features.rsi_value;
   raw_features[12] = features.rsi_divergence;
   raw_features[13] = features.vwap_distance;
   raw_features[14] = features.cumulative_delta;
   raw_features[15] = features.bb_position;
   raw_features[16] = features.historical_zone_winrate;
   raw_features[17] = features.candle_body_ratio;
   
   // Normalize each feature
   for(int i = 0; i < 18; i++)
   {
      double range = max_vals[i] - min_vals[i];
      if(range > 0.0001)
         raw_features[i] = (raw_features[i] - min_vals[i]) / range;
      else
         raw_features[i] = 0.5;
   }
   
   // Update features with normalized values
   features.distance_to_poc = raw_features[0];
   features.distance_to_edge = raw_features[1];
   features.volume_delta = raw_features[2];
   features.rejection_ratio = raw_features[3];
   features.atr_normalized_vol = raw_features[4];
   features.trend_slope = raw_features[5];
   features.time_since_break = raw_features[6];
   features.lvn_proximity = raw_features[7];
   features.order_flow_imbalance = raw_features[8];
   features.market_session = raw_features[9];
   features.spread_normalized = raw_features[10];
   features.rsi_value = raw_features[11];
   features.rsi_divergence = raw_features[12];
   features.vwap_distance = raw_features[13];
   features.cumulative_delta = raw_features[14];
   features.bb_position = raw_features[15];
   features.historical_zone_winrate = raw_features[16];
   features.candle_body_ratio = raw_features[17];
}
//+------------------------------------------------------------------+
