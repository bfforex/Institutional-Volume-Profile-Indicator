//+------------------------------------------------------------------+
//|                                       MultiTimeframeAnalyzer.mqh  |
//|                    Multi-Timeframe Zone Confluence Detection       |
//+------------------------------------------------------------------+
#property copyright "Institutional Volume Profile ML System"
#property link      ""
#property version   "2.00"
#property strict

#include "VolumeProfileEngine.mqh"
#include "InstitutionalZoneDetector.mqh"

//+------------------------------------------------------------------+
//| MTF Zone Data Structure                                          |
//+------------------------------------------------------------------+
struct MTFZoneData
{
   ENUM_TIMEFRAMES timeframe;
   bool   has_zone;
   double zone_upper;
   double zone_lower;
   double poc_price;
   int    zone_strength;
   bool   is_aligned;        // Zone overlaps with current TF zone
};

//+------------------------------------------------------------------+
//| Confluence Score Structure                                       |
//+------------------------------------------------------------------+
struct ConfluenceScore
{
   double zone_touch_score;       // First touch = 1.0, second = 0.5, etc.
   double htf_alignment_score;    // Higher TF zone alignment (0-1)
   double ltf_confirmation;       // Lower TF showing reversal (0-1)
   double volume_confirmation;    // Volume spike at touch (0-1)
   double session_score;          // London/NY = 1.0, Asian = 0.6
   double spread_score;           // Low spread = 1.0
   double trend_alignment;        // Signal direction matches HTF trend
   double news_clearance;         // No news within 2 hours = 1.0
   
   double total_confluence;       // Weighted sum (0-1)
   int    confluence_factors;     // Number of positive factors
};

//+------------------------------------------------------------------+
//| Multi-Timeframe Analyzer Class                                   |
//+------------------------------------------------------------------+
class CMultiTimeframeAnalyzer
{
private:
   string m_symbol;
   ENUM_TIMEFRAMES m_base_timeframe;
   
   // Higher timeframe engines (dynamically allocated)
   CVolumeProfileEngine* m_htf_engine_1;
   CVolumeProfileEngine* m_htf_engine_2;
   CInstitutionalZoneDetector* m_htf_detector_1;
   CInstitutionalZoneDetector* m_htf_detector_2;
   
   ENUM_TIMEFRAMES m_htf1;
   ENUM_TIMEFRAMES m_htf2;
   
   MTFZoneData m_mtf_zones[];
   int m_mtf_zone_count;
   
   // Confluence weights
   double m_weight_zone_touch;
   double m_weight_htf_alignment;
   double m_weight_volume;
   double m_weight_session;
   double m_weight_spread;
   double m_weight_trend;
   
   // Zone touch tracking
   struct ZoneTouchRecord
   {
      double zone_price;
      int touch_count;
      datetime last_touch;
   };
   ZoneTouchRecord m_touch_records[];
   int m_touch_record_count;
   
public:
   CMultiTimeframeAnalyzer();
   ~CMultiTimeframeAnalyzer();
   
   bool Initialize(string symbol, ENUM_TIMEFRAMES base_tf);
   void Deinitialize();
   
   // MTF Zone Analysis
   bool AnalyzeHigherTimeframes();
   bool IsZoneConfluentWithHTF(InstitutionalZone* zone, double tolerance);
   int  CountConfluentTimeframes(double price_level, double tolerance);
   
   // Confluence Scoring
   ConfluenceScore CalculateConfluence(int signal_type, double entry_price,
                                       InstitutionalZone* zone, bool is_first_touch);
   
   // Individual score components
   double ScoreZoneTouch(double zone_price);
   double ScoreHTFAlignment(double price, double tolerance);
   double ScoreVolumeConfirmation(int bar_index);
   double ScoreSession();
   double ScoreSpread();
   double ScoreTrendAlignment(int signal_type);
   double ScoreNewsClearance();
   
   // Getters
   MTFZoneData* GetMTFZone(ENUM_TIMEFRAMES tf);
   int GetMTFZoneCount() { return m_mtf_zone_count; }
   
   // Touch tracking
   void UpdateZoneTouch(double zone_price);
   int GetTouchCount(double zone_price, double tolerance);
   
private:
   // Internal helpers
   ENUM_TIMEFRAMES GetHigherTimeframe(ENUM_TIMEFRAMES tf, int level);
   void SetDefaultWeights();
   bool CreateHTFEngines();
   void ReleaseHTFEngines();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CMultiTimeframeAnalyzer::CMultiTimeframeAnalyzer()
{
   m_symbol = "";
   m_base_timeframe = PERIOD_CURRENT;
   
   m_htf_engine_1 = NULL;
   m_htf_engine_2 = NULL;
   m_htf_detector_1 = NULL;
   m_htf_detector_2 = NULL;
   
   m_htf1 = PERIOD_CURRENT;
   m_htf2 = PERIOD_CURRENT;
   
   m_mtf_zone_count = 0;
   m_touch_record_count = 0;
   
   SetDefaultWeights();
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CMultiTimeframeAnalyzer::~CMultiTimeframeAnalyzer()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize analyzer                                              |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalyzer::Initialize(string symbol, ENUM_TIMEFRAMES base_tf)
{
   m_symbol = symbol;
   m_base_timeframe = base_tf;
   
   // Determine higher timeframes
   m_htf1 = GetHigherTimeframe(base_tf, 1);
   m_htf2 = GetHigherTimeframe(base_tf, 2);
   
   Print("MTF Analyzer: Base=", EnumToString(base_tf), 
         " HTF1=", EnumToString(m_htf1), 
         " HTF2=", EnumToString(m_htf2));
   
   // Create HTF engines
   if(!CreateHTFEngines())
   {
      Print("Error: Failed to create HTF engines");
      return false;
   }
   
   // Initialize arrays
   ArrayResize(m_mtf_zones, 10);
   ArrayResize(m_touch_records, 50);
   
   Print("Multi-Timeframe Analyzer initialized successfully");
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize and release resources                               |
//+------------------------------------------------------------------+
void CMultiTimeframeAnalyzer::Deinitialize()
{
   ReleaseHTFEngines();
   
   ArrayFree(m_mtf_zones);
   ArrayFree(m_touch_records);
}

//+------------------------------------------------------------------+
//| Create higher timeframe engines                                  |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalyzer::CreateHTFEngines()
{
   // Create HTF1 engines
   m_htf_engine_1 = new CVolumeProfileEngine();
   if(m_htf_engine_1 == NULL)
      return false;
   
   double price_step = SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 10.0;
   if(!m_htf_engine_1.Initialize(m_symbol, m_htf1, SESSION_DAILY, price_step, 0.70))
   {
      delete m_htf_engine_1;
      m_htf_engine_1 = NULL;
      return false;
   }
   
   m_htf_detector_1 = new CInstitutionalZoneDetector();
   if(m_htf_detector_1 == NULL)
      return false;
   
   if(!m_htf_detector_1.Initialize(m_htf_engine_1, 0.70))
   {
      delete m_htf_detector_1;
      m_htf_detector_1 = NULL;
      return false;
   }
   
   // Create HTF2 engines
   m_htf_engine_2 = new CVolumeProfileEngine();
   if(m_htf_engine_2 == NULL)
      return false;
   
   if(!m_htf_engine_2.Initialize(m_symbol, m_htf2, SESSION_DAILY, price_step, 0.70))
   {
      delete m_htf_engine_2;
      m_htf_engine_2 = NULL;
      return false;
   }
   
   m_htf_detector_2 = new CInstitutionalZoneDetector();
   if(m_htf_detector_2 == NULL)
      return false;
   
   if(!m_htf_detector_2.Initialize(m_htf_engine_2, 0.70))
   {
      delete m_htf_detector_2;
      m_htf_detector_2 = NULL;
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Release higher timeframe engines                                 |
//+------------------------------------------------------------------+
void CMultiTimeframeAnalyzer::ReleaseHTFEngines()
{
   if(m_htf_detector_1 != NULL)
   {
      delete m_htf_detector_1;
      m_htf_detector_1 = NULL;
   }
   
   if(m_htf_engine_1 != NULL)
   {
      delete m_htf_engine_1;
      m_htf_engine_1 = NULL;
   }
   
   if(m_htf_detector_2 != NULL)
   {
      delete m_htf_detector_2;
      m_htf_detector_2 = NULL;
   }
   
   if(m_htf_engine_2 != NULL)
   {
      delete m_htf_engine_2;
      m_htf_engine_2 = NULL;
   }
}

//+------------------------------------------------------------------+
//| Analyze higher timeframes                                        |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalyzer::AnalyzeHigherTimeframes()
{
   m_mtf_zone_count = 0;
   
   // Analyze HTF1
   if(m_htf_engine_1 != NULL && m_htf_detector_1 != NULL)
   {
      if(m_htf_engine_1.CalculateProfile())
      {
         if(m_htf_detector_1.DetectZones())
         {
            int zone_count = m_htf_detector_1.GetZoneCount();
            for(int i = 0; i < zone_count && i < 5; i++)
            {
               InstitutionalZone* zone = m_htf_detector_1.GetZone(i);
               if(zone != NULL)
               {
                  m_mtf_zones[m_mtf_zone_count].timeframe = m_htf1;
                  m_mtf_zones[m_mtf_zone_count].has_zone = true;
                  m_mtf_zones[m_mtf_zone_count].zone_upper = zone.upper_boundary;
                  m_mtf_zones[m_mtf_zone_count].zone_lower = zone.lower_boundary;
                  m_mtf_zones[m_mtf_zone_count].poc_price = zone.poc_price;
                  m_mtf_zones[m_mtf_zone_count].zone_strength = zone.strength;
                  m_mtf_zones[m_mtf_zone_count].is_aligned = false;
                  m_mtf_zone_count++;
               }
            }
         }
      }
   }
   
   // Analyze HTF2
   if(m_htf_engine_2 != NULL && m_htf_detector_2 != NULL)
   {
      if(m_htf_engine_2.CalculateProfile())
      {
         if(m_htf_detector_2.DetectZones())
         {
            int zone_count = m_htf_detector_2.GetZoneCount();
            for(int i = 0; i < zone_count && i < 5; i++)
            {
               InstitutionalZone* zone = m_htf_detector_2.GetZone(i);
               if(zone != NULL && m_mtf_zone_count < ArraySize(m_mtf_zones))
               {
                  m_mtf_zones[m_mtf_zone_count].timeframe = m_htf2;
                  m_mtf_zones[m_mtf_zone_count].has_zone = true;
                  m_mtf_zones[m_mtf_zone_count].zone_upper = zone.upper_boundary;
                  m_mtf_zones[m_mtf_zone_count].zone_lower = zone.lower_boundary;
                  m_mtf_zones[m_mtf_zone_count].poc_price = zone.poc_price;
                  m_mtf_zones[m_mtf_zone_count].zone_strength = zone.strength;
                  m_mtf_zones[m_mtf_zone_count].is_aligned = false;
                  m_mtf_zone_count++;
               }
            }
         }
      }
   }
   
   return (m_mtf_zone_count > 0);
}

//+------------------------------------------------------------------+
//| Check if zone is confluent with HTF                              |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalyzer::IsZoneConfluentWithHTF(InstitutionalZone* zone, double tolerance)
{
   if(zone == NULL)
      return false;
   
   for(int i = 0; i < m_mtf_zone_count; i++)
   {
      if(m_mtf_zones[i].has_zone)
      {
         // Check if zones overlap
         bool overlaps = (zone.upper_boundary >= m_mtf_zones[i].zone_lower - tolerance &&
                         zone.lower_boundary <= m_mtf_zones[i].zone_upper + tolerance);
         
         if(overlaps)
         {
            m_mtf_zones[i].is_aligned = true;
            return true;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Count confluent timeframes at price level                        |
//+------------------------------------------------------------------+
int CMultiTimeframeAnalyzer::CountConfluentTimeframes(double price_level, double tolerance)
{
   int count = 0;
   
   for(int i = 0; i < m_mtf_zone_count; i++)
   {
      if(m_mtf_zones[i].has_zone)
      {
         if(price_level >= m_mtf_zones[i].zone_lower - tolerance &&
            price_level <= m_mtf_zones[i].zone_upper + tolerance)
         {
            count++;
         }
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Calculate confluence score                                       |
//+------------------------------------------------------------------+
ConfluenceScore CMultiTimeframeAnalyzer::CalculateConfluence(int signal_type, double entry_price,
                                                             InstitutionalZone* zone, bool is_first_touch)
{
   ConfluenceScore score;
   
   // Calculate individual scores
   score.zone_touch_score = ScoreZoneTouch((zone != NULL) ? zone.poc_price : entry_price);
   score.htf_alignment_score = ScoreHTFAlignment(entry_price, SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 50);
   score.volume_confirmation = ScoreVolumeConfirmation(0);
   score.session_score = ScoreSession();
   score.spread_score = ScoreSpread();
   score.trend_alignment = ScoreTrendAlignment(signal_type);
   score.news_clearance = ScoreNewsClearance();
   score.ltf_confirmation = 0.5; // Placeholder - would need LTF analysis
   
   // Calculate weighted total
   score.total_confluence = (score.zone_touch_score * m_weight_zone_touch) +
                           (score.htf_alignment_score * m_weight_htf_alignment) +
                           (score.volume_confirmation * m_weight_volume) +
                           (score.session_score * m_weight_session) +
                           (score.spread_score * m_weight_spread) +
                           (score.trend_alignment * m_weight_trend);
   
   // Count positive factors (>0.6)
   score.confluence_factors = 0;
   if(score.zone_touch_score > 0.6) score.confluence_factors++;
   if(score.htf_alignment_score > 0.6) score.confluence_factors++;
   if(score.volume_confirmation > 0.6) score.confluence_factors++;
   if(score.session_score > 0.6) score.confluence_factors++;
   if(score.spread_score > 0.6) score.confluence_factors++;
   if(score.trend_alignment > 0.6) score.confluence_factors++;
   
   return score;
}

//+------------------------------------------------------------------+
//| Score zone touch count                                           |
//+------------------------------------------------------------------+
double CMultiTimeframeAnalyzer::ScoreZoneTouch(double zone_price)
{
   int touch_count = GetTouchCount(zone_price, SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 10);
   
   // First touch = 1.0, second = 0.5, third+ = 0.3
   if(touch_count == 0)
      return 1.0;
   else if(touch_count == 1)
      return 0.5;
   else
      return 0.3;
}

//+------------------------------------------------------------------+
//| Score HTF alignment                                              |
//+------------------------------------------------------------------+
double CMultiTimeframeAnalyzer::ScoreHTFAlignment(double price, double tolerance)
{
   int confluent_count = CountConfluentTimeframes(price, tolerance);
   
   // 0 TF = 0, 1 TF = 0.5, 2+ TF = 1.0
   if(confluent_count == 0)
      return 0;
   else if(confluent_count == 1)
      return 0.5;
   else
      return 1.0;
}

//+------------------------------------------------------------------+
//| Score volume confirmation                                        |
//+------------------------------------------------------------------+
double CMultiTimeframeAnalyzer::ScoreVolumeConfirmation(int bar_index)
{
   long current_volume = iVolume(m_symbol, m_base_timeframe, bar_index);
   
   // Calculate average volume
   long sum_volume = 0;
   int periods = 20;
   
   for(int i = 1; i <= periods; i++)
   {
      sum_volume += iVolume(m_symbol, m_base_timeframe, i);
   }
   
   double avg_volume = (double)sum_volume / periods;
   if(avg_volume == 0) return 0.5;
   
   double volume_ratio = (double)current_volume / avg_volume;
   
   // Volume > 1.5x average = 1.0, at average = 0.5, below = 0.2
   if(volume_ratio > 1.5)
      return 1.0;
   else if(volume_ratio > 1.0)
      return 0.7;
   else if(volume_ratio > 0.7)
      return 0.5;
   else
      return 0.2;
}

//+------------------------------------------------------------------+
//| Score trading session                                            |
//+------------------------------------------------------------------+
double CMultiTimeframeAnalyzer::ScoreSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hour = dt.hour; // UTC hour
   
   // London session (8-16 UTC) = 1.0
   if(hour >= 8 && hour < 16)
      return 1.0;
   
   // New York session (13-21 UTC) = 1.0
   if(hour >= 13 && hour < 21)
      return 1.0;
   
   // Asian session = 0.6
   if(hour >= 0 && hour < 8)
      return 0.6;
   
   // Off hours = 0.4
   return 0.4;
}

//+------------------------------------------------------------------+
//| Score spread                                                     |
//+------------------------------------------------------------------+
double CMultiTimeframeAnalyzer::ScoreSpread()
{
   long current_spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
   
   // Calculate average spread (simplified - would track history)
   long avg_spread = current_spread; // Placeholder
   
   if(avg_spread == 0) return 1.0;
   
   double spread_ratio = (double)current_spread / avg_spread;
   
   // Spread < average = 1.0, at average = 0.7, above = 0.3
   if(spread_ratio < 1.0)
      return 1.0;
   else if(spread_ratio < 1.2)
      return 0.7;
   else
      return 0.3;
}

//+------------------------------------------------------------------+
//| Score trend alignment                                            |
//+------------------------------------------------------------------+
double CMultiTimeframeAnalyzer::ScoreTrendAlignment(int signal_type)
{
   // Calculate HTF trend using EMA
   ENUM_TIMEFRAMES htf = GetHigherTimeframe(m_base_timeframe, 1);
   
   double ema_fast = iMA(m_symbol, htf, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema_slow = iMA(m_symbol, htf, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
   
   bool uptrend = (ema_fast > ema_slow);
   bool downtrend = (ema_fast < ema_slow);
   
   // Signal aligned with trend = 1.0, against trend = 0.3, neutral = 0.6
   if(signal_type == 1 && uptrend)
      return 1.0;
   else if(signal_type == -1 && downtrend)
      return 1.0;
   else if(signal_type == 1 && downtrend)
      return 0.3;
   else if(signal_type == -1 && uptrend)
      return 0.3;
   
   return 0.6; // Neutral
}

//+------------------------------------------------------------------+
//| Score news clearance                                             |
//+------------------------------------------------------------------+
double CMultiTimeframeAnalyzer::ScoreNewsClearance()
{
   // Simplified - always return 1.0
   // Full implementation would check economic calendar
   return 1.0;
}

//+------------------------------------------------------------------+
//| Get MTF zone by timeframe                                        |
//+------------------------------------------------------------------+
MTFZoneData* CMultiTimeframeAnalyzer::GetMTFZone(ENUM_TIMEFRAMES tf)
{
   for(int i = 0; i < m_mtf_zone_count; i++)
   {
      if(m_mtf_zones[i].timeframe == tf && m_mtf_zones[i].has_zone)
         return &m_mtf_zones[i];
   }
   
   return NULL;
}

//+------------------------------------------------------------------+
//| Update zone touch record                                         |
//+------------------------------------------------------------------+
void CMultiTimeframeAnalyzer::UpdateZoneTouch(double zone_price)
{
   double tolerance = SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 10;
   bool found = false;
   
   // Find existing record
   for(int i = 0; i < m_touch_record_count; i++)
   {
      if(MathAbs(m_touch_records[i].zone_price - zone_price) <= tolerance)
      {
         m_touch_records[i].touch_count++;
         m_touch_records[i].last_touch = TimeCurrent();
         found = true;
         break;
      }
   }
   
   // Add new record
   if(!found && m_touch_record_count < ArraySize(m_touch_records))
   {
      m_touch_records[m_touch_record_count].zone_price = zone_price;
      m_touch_records[m_touch_record_count].touch_count = 1;
      m_touch_records[m_touch_record_count].last_touch = TimeCurrent();
      m_touch_record_count++;
   }
}

//+------------------------------------------------------------------+
//| Get touch count for zone                                         |
//+------------------------------------------------------------------+
int CMultiTimeframeAnalyzer::GetTouchCount(double zone_price, double tolerance)
{
   for(int i = 0; i < m_touch_record_count; i++)
   {
      if(MathAbs(m_touch_records[i].zone_price - zone_price) <= tolerance)
         return m_touch_records[i].touch_count;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get higher timeframe                                             |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES CMultiTimeframeAnalyzer::GetHigherTimeframe(ENUM_TIMEFRAMES tf, int level)
{
   // Level 1: Next higher timeframe
   // Level 2: Two levels higher
   
   if(level == 1)
   {
      if(tf == PERIOD_M1) return PERIOD_M5;
      if(tf == PERIOD_M5) return PERIOD_M15;
      if(tf == PERIOD_M15) return PERIOD_M30;
      if(tf == PERIOD_M30) return PERIOD_H1;
      if(tf == PERIOD_H1) return PERIOD_H4;
      if(tf == PERIOD_H4) return PERIOD_D1;
      if(tf == PERIOD_D1) return PERIOD_W1;
      return PERIOD_W1;
   }
   else if(level == 2)
   {
      if(tf == PERIOD_M1) return PERIOD_M15;
      if(tf == PERIOD_M5) return PERIOD_M30;
      if(tf == PERIOD_M15) return PERIOD_H1;
      if(tf == PERIOD_M30) return PERIOD_H4;
      if(tf == PERIOD_H1) return PERIOD_D1;
      if(tf == PERIOD_H4) return PERIOD_W1;
      if(tf == PERIOD_D1) return PERIOD_MN1;
      return PERIOD_MN1;
   }
   
   return tf;
}

//+------------------------------------------------------------------+
//| Set default confluence weights                                   |
//+------------------------------------------------------------------+
void CMultiTimeframeAnalyzer::SetDefaultWeights()
{
   m_weight_zone_touch = 0.20;
   m_weight_htf_alignment = 0.25;
   m_weight_volume = 0.15;
   m_weight_session = 0.10;
   m_weight_spread = 0.05;
   m_weight_trend = 0.15;
   // News clearance = 0.10 (not included in this simplified version)
}
//+------------------------------------------------------------------+
