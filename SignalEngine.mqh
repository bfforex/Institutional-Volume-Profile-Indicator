//+------------------------------------------------------------------+
//|                                                 SignalEngine.mqh |
//|                        Zone Edge Reversal Signal Generation      |
//+------------------------------------------------------------------+
#property copyright "Institutional Volume Profile System"
#property link      ""
#property version   "2.00"
#property strict

#include "InstitutionalZoneDetector.mqh"
#include "FeatureExtractor.mqh"
#include "MarketRegime.mqh"
#include "MultiTimeframeAnalyzer.mqh"
#include "EnsembleML.mqh"

//+------------------------------------------------------------------+
//| Signal Trigger Mode                                              |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_MODE
{
   ON_TOUCH,           // Signal when price touches edge
   ON_CANDLE_CLOSE     // Signal only on candle close with rejection
};

//+------------------------------------------------------------------+
//| Trading Signal Structure                                         |
//+------------------------------------------------------------------+
struct TradingSignal
{
   int      signal_type;        // 1=Long, -1=Short, 0=None
   double   entry_price;        
   double   stop_loss;
   double   take_profit;
   
   double   confidence;         // ML confidence score
   bool     ml_approved;        // Passed ML filter
   double   regime_multiplier;  // Market regime adjustment
   double   confluence_score;   // MTF confluence score
   
   int      zone_index;         // Which zone triggered signal
   datetime signal_time;
   
   bool     is_first_touch;     // First-touch principle flag
   ENUM_MARKET_REGIME market_regime; // Current market regime
   
   string   signal_reason;      // Description for logging
};

//+------------------------------------------------------------------+
//| Signal Engine Class                                              |
//+------------------------------------------------------------------+
class CSignalEngine
{
private:
   CInstitutionalZoneDetector* m_zone_detector;
   CEnsembleML* m_ensemble_ml;
   CFeatureExtractor* m_feature_extractor;
   CMarketRegimeDetector* m_regime_detector;
   CMultiTimeframeAnalyzer* m_mtf_analyzer;
   
   ENUM_SIGNAL_MODE m_signal_mode;
   bool m_ml_enabled;
   bool m_regime_enabled;
   bool m_mtf_enabled;
   
   // Price tracking for first-touch detection
   struct ZoneTouch
   {
      int zone_index;
      bool touched_upper;
      bool touched_lower;
      datetime last_touch_time;
      double last_price_before_touch;
   };
   
   ZoneTouch m_zone_touches[];
   int m_touch_count;
   
   // Signal state
   TradingSignal m_last_signal;
   bool m_signal_pending;
   
   // ATR for stops/targets
   double m_atr_value;
   int m_atr_period;
   
public:
   CSignalEngine();
   ~CSignalEngine();
   
   bool Initialize(CInstitutionalZoneDetector* zone_detector, 
                   CEnsembleML* ensemble_ml,
                   ENUM_SIGNAL_MODE signal_mode,
                   bool ml_enabled,
                   bool regime_enabled = true,
                   bool mtf_enabled = true);
   
   // Signal generation
   bool CheckForSignal(TradingSignal &signal);
   
   // Feature extraction (now handled by CFeatureExtractor)
   // Removed old ExtractFeatures method
   
   // Touch tracking
   void UpdateZoneTouches(double current_price, double previous_price);
   bool IsFirstTouch(int zone_index, bool is_upper_edge);
   void ResetTouch(int zone_index, bool is_upper_edge);
   
   // Signal validation
   bool ValidateLongSignal(int zone_index, double price);
   bool ValidateShortSignal(int zone_index, double price);
   
   // Stop loss / Take profit calculation
   double CalculateStopLoss(int signal_type, int zone_index);
   double CalculateTargetPrice(int signal_type, double entry_price, double stop_loss);
   
   // Update trade outcome for ML learning
   void UpdateTradeOutcome(TradingSignal &signal, int outcome, double actual_rr);
   
private:
   // Helper functions
   double GetATR();
   double CalculateRejectionRatio(int bar_index);
   double CalculateVolumeDelta(int bar_index);
   double CalculateTrendSlope();
   int GetBarsSinceZoneBreak(int zone_index);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CSignalEngine::CSignalEngine()
{
   m_signal_mode = ON_CANDLE_CLOSE;
   m_ml_enabled = true;
   m_regime_enabled = true;
   m_mtf_enabled = true;
   m_touch_count = 0;
   m_signal_pending = false;
   m_atr_period = 14;
   m_zone_detector = NULL;
   m_ensemble_ml = NULL;
   m_feature_extractor = NULL;
   m_regime_detector = NULL;
   m_mtf_analyzer = NULL;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CSignalEngine::~CSignalEngine()
{
   ArrayFree(m_zone_touches);
   
   // Clean up allocated objects
   if(m_feature_extractor != NULL)
   {
      delete m_feature_extractor;
      m_feature_extractor = NULL;
   }
   
   if(m_regime_detector != NULL)
   {
      delete m_regime_detector;
      m_regime_detector = NULL;
   }
   
   if(m_mtf_analyzer != NULL)
   {
      delete m_mtf_analyzer;
      m_mtf_analyzer = NULL;
   }
}

//+------------------------------------------------------------------+
//| Initialize signal engine                                         |
//+------------------------------------------------------------------+
bool CSignalEngine::Initialize(CInstitutionalZoneDetector* zone_detector,
                               CEnsembleML* ensemble_ml,
                               ENUM_SIGNAL_MODE signal_mode,
                               bool ml_enabled,
                               bool regime_enabled,
                               bool mtf_enabled)
{
   if(zone_detector == NULL)
      return false;
   
   m_zone_detector = zone_detector;
   m_ensemble_ml = ensemble_ml;
   m_signal_mode = signal_mode;
   m_ml_enabled = ml_enabled;
   m_regime_enabled = regime_enabled;
   m_mtf_enabled = mtf_enabled;
   
   // Initialize Feature Extractor
   m_feature_extractor = new CFeatureExtractor();
   if(m_feature_extractor == NULL)
   {
      Print("Error: Failed to create Feature Extractor");
      return false;
   }
   
   if(!m_feature_extractor.Initialize(_Symbol, PERIOD_CURRENT))
   {
      Print("Error: Failed to initialize Feature Extractor");
      delete m_feature_extractor;
      m_feature_extractor = NULL;
      return false;
   }
   
   // Initialize Market Regime Detector
   if(m_regime_enabled)
   {
      m_regime_detector = new CMarketRegimeDetector();
      if(m_regime_detector == NULL)
      {
         Print("Warning: Failed to create Market Regime Detector");
         m_regime_enabled = false;
      }
      else if(!m_regime_detector.Initialize(_Symbol, PERIOD_CURRENT))
      {
         Print("Warning: Failed to initialize Market Regime Detector");
         delete m_regime_detector;
         m_regime_detector = NULL;
         m_regime_enabled = false;
      }
   }
   
   // Initialize Multi-Timeframe Analyzer
   if(m_mtf_enabled)
   {
      m_mtf_analyzer = new CMultiTimeframeAnalyzer();
      if(m_mtf_analyzer == NULL)
      {
         Print("Warning: Failed to create MTF Analyzer");
         m_mtf_enabled = false;
      }
      else if(!m_mtf_analyzer.Initialize(_Symbol, PERIOD_CURRENT))
      {
         Print("Warning: Failed to initialize MTF Analyzer");
         delete m_mtf_analyzer;
         m_mtf_analyzer = NULL;
         m_mtf_enabled = false;
      }
   }
   
   // Initialize zone touch tracking
   int zone_count = m_zone_detector.GetZoneCount();
   ArrayResize(m_zone_touches, zone_count);
   m_touch_count = zone_count;
   
   for(int i = 0; i < m_touch_count; i++)
   {
      m_zone_touches[i].zone_index = i;
      m_zone_touches[i].touched_upper = false;
      m_zone_touches[i].touched_lower = false;
      m_zone_touches[i].last_touch_time = 0;
      m_zone_touches[i].last_price_before_touch = 0;
   }
   
   Print("=== Signal Engine v2.0 Initialized ===");
   Print("Feature Extractor: ", (m_feature_extractor != NULL) ? "OK" : "FAILED");
   Print("Market Regime: ", m_regime_enabled ? "ENABLED" : "DISABLED");
   Print("MTF Analysis: ", m_mtf_enabled ? "ENABLED" : "DISABLED");
   Print("ML Filter: ", m_ml_enabled ? "ENABLED" : "DISABLED");
   
   return true;
}

//+------------------------------------------------------------------+
//| Check for trading signal                                         |
//+------------------------------------------------------------------+
bool CSignalEngine::CheckForSignal(TradingSignal &signal)
{
   signal.signal_type = 0; // No signal by default
   signal.ml_approved = false;
   signal.regime_multiplier = 1.0;
   signal.confluence_score = 0.5;
   
   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double previous_price = iClose(_Symbol, PERIOD_CURRENT, 1);
   
   // Update zone touch tracking
   UpdateZoneTouches(current_price, previous_price);
   
   // Update market regime
   ENUM_MARKET_REGIME current_regime = REGIME_RANGING;
   if(m_regime_enabled && m_regime_detector != NULL)
   {
      current_regime = m_regime_detector.DetectRegime();
      signal.market_regime = current_regime;
   }
   
   // Update MTF zones periodically
   if(m_mtf_enabled && m_mtf_analyzer != NULL)
   {
      m_mtf_analyzer.AnalyzeHigherTimeframes();
   }
   
   // Check if price is at any zone edge
   bool is_upper_edge;
   int zone_index;
   m_atr_value = GetATR();
   double edge_tolerance = m_atr_value * 0.1; // 10% of ATR as tolerance
   
   if(!m_zone_detector.IsPriceAtZoneEdge(current_price, is_upper_edge, zone_index, edge_tolerance))
      return false;
   
   InstitutionalZone* zone = m_zone_detector.GetZone(zone_index);
   if(zone == NULL)
      return false;
   
   // Check for LONG signal (bounce from lower boundary)
   if(!is_upper_edge && zone.is_support)
   {
      if(ValidateLongSignal(zone_index, current_price))
      {
         signal.signal_type = 1;
         signal.entry_price = current_price;
         signal.zone_index = zone_index;
         signal.is_first_touch = IsFirstTouch(zone_index, false);
      }
   }
   
   // Check for SHORT signal (rejection from upper boundary)
   if(is_upper_edge && zone.is_resistance)
   {
      if(ValidateShortSignal(zone_index, current_price))
      {
         signal.signal_type = -1;
         signal.entry_price = current_price;
         signal.zone_index = zone_index;
         signal.is_first_touch = IsFirstTouch(zone_index, true);
      }
   }
   
   // No signal generated
   if(signal.signal_type == 0)
      return false;
   
   // Only accept first-touch signals
   if(!signal.is_first_touch)
      return false;
   
   // Check market regime favorability
   if(m_regime_enabled && m_regime_detector != NULL)
   {
      if(!m_regime_detector.IsRegimeFavorableForSignal(signal.signal_type))
      {
         signal.signal_reason = "Market regime unfavorable: " + m_regime_detector.GetRegimeName(current_regime);
         return false;
      }
      
      signal.regime_multiplier = m_regime_detector.GetRegimeMultiplier(signal.signal_type);
   }
   
   // Calculate confluence score
   if(m_mtf_enabled && m_mtf_analyzer != NULL)
   {
      ConfluenceScore conf_score = m_mtf_analyzer.CalculateConfluence(
         signal.signal_type, signal.entry_price, zone, signal.is_first_touch);
      
      signal.confluence_score = conf_score.total_confluence;
      
      // Filter out low-confluence signals
      if(conf_score.total_confluence < 0.4)
      {
         signal.signal_reason = "Low MTF confluence: " + DoubleToString(conf_score.total_confluence, 2);
         return false;
      }
   }
   
   // Extract features using FeatureExtractor
   ExtendedMLFeatures features;
   if(m_feature_extractor != NULL)
   {
      features = m_feature_extractor.ExtractAllFeatures(signal.signal_type, signal.entry_price, 
                                                        zone, zone_index);
   }
   
   // Ensemble ML evaluation
   if(m_ml_enabled && m_ensemble_ml != NULL)
   {
      double confidence;
      bool ml_accept = m_ensemble_ml.EvaluateSignal(features, confidence);
      
      // Apply regime multiplier to confidence
      confidence *= signal.regime_multiplier;
      
      signal.confidence = confidence;
      signal.ml_approved = ml_accept;
      
      if(!ml_accept)
      {
         signal.signal_reason = "ML Filter rejected (confidence: " + DoubleToString(confidence, 2) + ")";
         return false; // Signal rejected by ML
      }
   }
   else
   {
      signal.confidence = 1.0;
      signal.ml_approved = true;
   }
   
   // Calculate stops and targets
   signal.stop_loss = CalculateStopLoss(signal.signal_type, zone_index);
   signal.take_profit = CalculateTargetPrice(signal.signal_type, signal.entry_price, signal.stop_loss);
   signal.signal_time = TimeCurrent();
   
   // Build signal reason
   string reason = "Zone edge reversal - First touch";
   if(m_regime_enabled)
      reason += " | Regime: " + m_regime_detector.GetRegimeName(current_regime);
   if(m_mtf_enabled)
      reason += " | MTF Conf: " + DoubleToString(signal.confluence_score, 2);
   
   signal.signal_reason = reason;
   
   // Reset touch flag for this zone edge
   ResetTouch(zone_index, is_upper_edge);
   
   // Update zone touch for MTF analyzer
   if(m_mtf_analyzer != NULL)
      m_mtf_analyzer.UpdateZoneTouch(zone.poc_price);
   
   m_last_signal = signal;
   return true;
}

//+------------------------------------------------------------------+
//| Update zone touch tracking                                       |
//+------------------------------------------------------------------+
void CSignalEngine::UpdateZoneTouches(double current_price, double previous_price)
{
   int zone_count = m_zone_detector.GetZoneCount();
   
   for(int i = 0; i < zone_count; i++)
   {
      InstitutionalZone* zone = m_zone_detector.GetZone(i);
      if(zone == NULL) continue;
      
      // Check if price crossed upper boundary
      if(previous_price > zone.upper_boundary && current_price <= zone.upper_boundary)
      {
         if(i < m_touch_count)
         {
            m_zone_touches[i].touched_upper = true;
            m_zone_touches[i].last_touch_time = TimeCurrent();
            m_zone_touches[i].last_price_before_touch = previous_price;
         }
      }
      
      // Check if price crossed lower boundary
      if(previous_price < zone.lower_boundary && current_price >= zone.lower_boundary)
      {
         if(i < m_touch_count)
         {
            m_zone_touches[i].touched_lower = true;
            m_zone_touches[i].last_touch_time = TimeCurrent();
            m_zone_touches[i].last_price_before_touch = previous_price;
         }
      }
      
      // Reset if price moves far from zone
      if(current_price > zone.upper_boundary + m_atr_value ||
         current_price < zone.lower_boundary - m_atr_value)
      {
         if(i < m_touch_count)
         {
            m_zone_touches[i].touched_upper = false;
            m_zone_touches[i].touched_lower = false;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if this is first touch of zone edge                        |
//+------------------------------------------------------------------+
bool CSignalEngine::IsFirstTouch(int zone_index, bool is_upper_edge)
{
   if(zone_index >= m_touch_count)
      return false;
   
   if(is_upper_edge)
      return !m_zone_touches[zone_index].touched_upper;
   else
      return !m_zone_touches[zone_index].touched_lower;
}

//+------------------------------------------------------------------+
//| Reset touch flag after signal generated                          |
//+------------------------------------------------------------------+
void CSignalEngine::ResetTouch(int zone_index, bool is_upper_edge)
{
   if(zone_index >= m_touch_count)
      return;
   
   if(is_upper_edge)
      m_zone_touches[zone_index].touched_upper = true;
   else
      m_zone_touches[zone_index].touched_lower = true;
}

//+------------------------------------------------------------------+
//| Validate LONG signal conditions                                  |
//+------------------------------------------------------------------+
bool CSignalEngine::ValidateLongSignal(int zone_index, double price)
{
   InstitutionalZone* zone = m_zone_detector.GetZone(zone_index);
   if(zone == NULL) return false;
   
   // Price must be at lower boundary
   if(price < zone.lower_boundary - m_atr_value * 0.1)
      return false;
   
   // For candle close mode, check for rejection
   if(m_signal_mode == ON_CANDLE_CLOSE)
   {
      double rejection_ratio = CalculateRejectionRatio(0);
      if(rejection_ratio < 0.5) // Needs significant lower wick
         return false;
      
      // Candle must close above zone
      double close = iClose(_Symbol, PERIOD_CURRENT, 0);
      if(close <= zone.lower_boundary)
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Validate SHORT signal conditions                                 |
//+------------------------------------------------------------------+
bool CSignalEngine::ValidateShortSignal(int zone_index, double price)
{
   InstitutionalZone* zone = m_zone_detector.GetZone(zone_index);
   if(zone == NULL) return false;
   
   // Price must be at upper boundary
   if(price > zone.upper_boundary + m_atr_value * 0.1)
      return false;
   
   // For candle close mode, check for rejection
   if(m_signal_mode == ON_CANDLE_CLOSE)
   {
      double rejection_ratio = CalculateRejectionRatio(0);
      if(rejection_ratio < 0.5) // Needs significant upper wick
         return false;
      
      // Candle must close below zone
      double close = iClose(_Symbol, PERIOD_CURRENT, 0);
      if(close >= zone.upper_boundary)
         return false;
   }
   
   return true;
}
//+------------------------------------------------------------------+
//| Calculate stop loss based on zone and LVN                        |
//+------------------------------------------------------------------+
double CSignalEngine::CalculateStopLoss(int signal_type, int zone_index)
{
   InstitutionalZone* zone = m_zone_detector.GetZone(zone_index);
   if(zone == NULL)
      return 0;
   
   double sl;
   
   if(signal_type == 1) // Long
   {
      // Place SL at nearest LVN below, or below zone
      if(zone.nearest_lvn_below > 0)
         sl = zone.nearest_lvn_below - m_atr_value * 0.2;
      else
         sl = zone.lower_boundary - m_atr_value * 0.5;
   }
   else // Short
   {
      // Place SL at nearest LVN above, or above zone
      if(zone.nearest_lvn_above > 0)
         sl = zone.nearest_lvn_above + m_atr_value * 0.2;
      else
         sl = zone.upper_boundary + m_atr_value * 0.5;
   }
   
   return sl;
}

//+------------------------------------------------------------------+
//| Calculate target price (2:1 RR minimum)                          |
//+------------------------------------------------------------------+
double CSignalEngine::CalculateTargetPrice(int signal_type, double entry_price, double stop_loss)
{
   double risk = MathAbs(entry_price - stop_loss);
   double reward = risk * 2.0; // 2:1 RR
   
   if(signal_type == 1) // Long
      return entry_price + reward;
   else // Short
      return entry_price - reward;
}

//+------------------------------------------------------------------+
//| Get ATR value                                                    |
//+------------------------------------------------------------------+
double CSignalEngine::GetATR()
{
   return iATR(_Symbol, PERIOD_CURRENT, m_atr_period, 0);
}

//+------------------------------------------------------------------+
//| Calculate rejection ratio (wick to body)                         |
//+------------------------------------------------------------------+
double CSignalEngine::CalculateRejectionRatio(int bar_index)
{
   double open = iOpen(_Symbol, PERIOD_CURRENT, bar_index);
   double close = iClose(_Symbol, PERIOD_CURRENT, bar_index);
   double high = iHigh(_Symbol, PERIOD_CURRENT, bar_index);
   double low = iLow(_Symbol, PERIOD_CURRENT, bar_index);
   
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
double CSignalEngine::CalculateVolumeDelta(int bar_index)
{
   double open = iOpen(_Symbol, PERIOD_CURRENT, bar_index);
   double close = iClose(_Symbol, PERIOD_CURRENT, bar_index);
   long volume = iVolume(_Symbol, PERIOD_CURRENT, bar_index);
   
   // Estimate buy/sell based on candle direction
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
double CSignalEngine::CalculateTrendSlope()
{
   // Use EMA 50 slope on higher timeframe as trend indicator
   ENUM_TIMEFRAMES htf = PERIOD_H1;
   if(Period() == PERIOD_H1) htf = PERIOD_H4;
   if(Period() == PERIOD_H4) htf = PERIOD_D1;
   
   double ema_now = iMA(_Symbol, htf, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema_prev = iMA(_Symbol, htf, 50, 0, MODE_EMA, PRICE_CLOSE, 5);
   
   return (ema_now - ema_prev) / m_atr_value; // Normalized slope
}

//+------------------------------------------------------------------+
//| Get bars since zone was broken                                   |
//+------------------------------------------------------------------+
int CSignalEngine::GetBarsSinceZoneBreak(int zone_index)
{
   // Simplified - would track historical breaks
   return 10; // Placeholder
}

//+------------------------------------------------------------------+
//| Update ML model with trade outcome                               |
//+------------------------------------------------------------------+
void CSignalEngine::UpdateTradeOutcome(TradingSignal &signal, int outcome, double actual_rr)
{
   if(!m_ml_enabled || m_ensemble_ml == NULL || m_feature_extractor == NULL)
      return;
   
   InstitutionalZone* zone = m_zone_detector.GetZone(signal.zone_index);
   ExtendedMLFeatures features = m_feature_extractor.ExtractAllFeatures(
      signal.signal_type, signal.entry_price, zone, signal.zone_index);
   
   features.outcome = outcome;
   features.actual_rr = actual_rr;
   
   // Update ensemble models
   m_ensemble_ml.UpdateModels(features, outcome);
   
   // Update zone performance in feature extractor
   if(zone != NULL)
      m_feature_extractor.UpdateZonePerformance(zone.poc_price, outcome);
}
//+------------------------------------------------------------------+
