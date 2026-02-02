//+------------------------------------------------------------------+
//|                                          VolumeProfileEngine.mqh |
//|                                      Core Volume Profile Analysis |
//+------------------------------------------------------------------+
#property copyright "Institutional Volume Profile System"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Enumerations                                                      |
//+------------------------------------------------------------------+
enum ENUM_CALC_MODE
{
   SESSION_DAILY,      // Reset each trading day
   FIXED_RANGE,        // User-defined start/end time
   ANCHORED,           // Anchored to vertical line
   VISIBLE_RANGE       // Based on chart view
};

//+------------------------------------------------------------------+
//| Volume Profile Price Level Structure                             |
//+------------------------------------------------------------------+
struct PriceLevel
{
   double price;           // Price level
   long   buy_volume;      // Buying volume
   long   sell_volume;     // Selling volume
   long   total_volume;    // Total volume
   bool   is_hvn;          // High Volume Node flag
   bool   is_lvn;          // Low Volume Node flag
   bool   in_value_area;   // Within Value Area flag
};

//+------------------------------------------------------------------+
//| Volume Profile Data Structure                                    |
//+------------------------------------------------------------------+
struct VolumeProfileData
{
   PriceLevel levels[];    // Array of price levels
   int        level_count; // Number of levels
   
   double     poc_price;   // Point of Control price
   int        poc_index;   // POC index in levels array
   
   double     vah;         // Value Area High
   double     val;         // Value Area Low
   
   long       total_volume; // Total volume in profile
   
   datetime   start_time;  // Profile start time
   datetime   end_time;    // Profile end time
};

//+------------------------------------------------------------------+
//| Volume Profile Engine Class                                      |
//+------------------------------------------------------------------+
class CVolumeProfileEngine
{
private:
   // Configuration
   string m_symbol;
   ENUM_TIMEFRAMES m_timeframe;
   ENUM_CALC_MODE  m_calc_mode;
   
   double m_price_step;           // Price aggregation step
   double m_value_area_percent;   // Value area percentage (default 70%)
   
   // Data
   VolumeProfileData m_profile;
   
   // Range parameters
   datetime m_fixed_start;
   datetime m_fixed_end;
   int      m_lookback_bars;
   
   // Volume source
   bool m_use_real_volume;
   
public:
   CVolumeProfileEngine();
   ~CVolumeProfileEngine();
   
   bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_CALC_MODE mode,
                   double price_step, double value_area_percent);
   
   // Core calculation functions
   bool CalculateProfile(datetime start_time, datetime end_time);
   bool CalculateProfile(); // Auto-detect range based on mode
   
   // Getters
   VolumeProfileData* GetProfile() { return &m_profile; }
   double GetPOC() { return m_profile.poc_price; }
   double GetVAH() { return m_profile.vah; }
   double GetVAL() { return m_profile.val; }
   
   PriceLevel* GetLevel(int index);
   int GetLevelCount() { return m_profile.level_count; }
   
   // Utility functions
   void SetFixedRange(datetime start, datetime end);
   void SetLookbackBars(int bars) { m_lookback_bars = bars; }
   
   bool IsRealVolumeAvailable();
   
private:
   // Internal calculation methods
   bool BuildPriceLevels(datetime start_time, datetime end_time);
   void AggregateVolume(datetime start_time, datetime end_time);
   void CalculatePOC();
   void CalculateValueArea();
   void IdentifyHVNandLVN();
   
   double NormalizePriceToStep(double price);
   int FindPriceLevelIndex(double price);
   
   // Volume extraction
   long GetVolumeAtBar(int bar_index, bool &is_buy);
   bool GetRealVolume(int bar_index, long &buy_vol, long &sell_vol);
   bool GetTickVolume(int bar_index, long &volume);
   
   // Range detection
   datetime GetSessionStartTime();
   datetime GetVisibleRangeStart();
   datetime GetVisibleRangeEnd();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CVolumeProfileEngine::CVolumeProfileEngine()
{
   m_price_step = 0.0001;
   m_value_area_percent = 0.70;
   m_use_real_volume = false;
   m_lookback_bars = 100;
   m_calc_mode = SESSION_DAILY;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CVolumeProfileEngine::~CVolumeProfileEngine()
{
   ArrayFree(m_profile.levels);
}

//+------------------------------------------------------------------+
//| Initialize the engine                                            |
//+------------------------------------------------------------------+
bool CVolumeProfileEngine::Initialize(string symbol, ENUM_TIMEFRAMES timeframe, 
                                      ENUM_CALC_MODE mode, double price_step, 
                                      double value_area_percent)
{
   m_symbol = symbol;
   m_timeframe = timeframe;
   m_calc_mode = mode;
   m_price_step = price_step;
   m_value_area_percent = value_area_percent;
   
   // Check if real volume is available
   m_use_real_volume = IsRealVolumeAvailable();
   
   if(m_use_real_volume)
      Print("Volume Profile: Using Real Volume");
   else
      Print("Volume Profile: Using Tick Volume (Real Volume not available)");
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if real volume is available                                |
//+------------------------------------------------------------------+
bool CVolumeProfileEngine::IsRealVolumeAvailable()
{
   long volume[];
   int copied = CopyRealVolume(m_symbol, m_timeframe, 0, 1, volume);
   
   if(copied > 0 && volume[0] > 0)
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Calculate profile with auto-detected range                       |
//+------------------------------------------------------------------+
bool CVolumeProfileEngine::CalculateProfile()
{
   datetime start_time, end_time;
   
   switch(m_calc_mode)
   {
      case SESSION_DAILY:
         start_time = GetSessionStartTime();
         end_time = TimeCurrent();
         break;
         
      case FIXED_RANGE:
         start_time = m_fixed_start;
         end_time = m_fixed_end;
         break;
         
      case VISIBLE_RANGE:
         start_time = GetVisibleRangeStart();
         end_time = GetVisibleRangeEnd();
         break;
         
      case ANCHORED:
         // Would need to find anchor line - simplified here
         start_time = iTime(m_symbol, m_timeframe, m_lookback_bars);
         end_time = TimeCurrent();
         break;
         
      default:
         return false;
   }
   
   return CalculateProfile(start_time, end_time);
}

//+------------------------------------------------------------------+
//| Calculate profile for specific time range                        |
//+------------------------------------------------------------------+
bool CVolumeProfileEngine::CalculateProfile(datetime start_time, datetime end_time)
{
   m_profile.start_time = start_time;
   m_profile.end_time = end_time;
   
   // Build price level structure
   if(!BuildPriceLevels(start_time, end_time))
      return false;
   
   // Aggregate volume into price levels
   AggregateVolume(start_time, end_time);
   
   // Calculate POC
   CalculatePOC();
   
   // Calculate Value Area
   CalculateValueArea();
   
   // Identify HVN and LVN
   IdentifyHVNandLVN();
   
   return true;
}

//+------------------------------------------------------------------+
//| Build price level structure                                      |
//+------------------------------------------------------------------+
bool CVolumeProfileEngine::BuildPriceLevels(datetime start_time, datetime end_time)
{
   // Get price range for the period
   int start_bar = iBarShift(m_symbol, m_timeframe, start_time);
   int end_bar = iBarShift(m_symbol, m_timeframe, end_time);
   
   if(start_bar < 0 || end_bar < 0)
      return false;
   
   // Find high and low of range
   double range_high = iHigh(m_symbol, m_timeframe, iHighest(m_symbol, m_timeframe, MODE_HIGH, start_bar - end_bar + 1, end_bar));
   double range_low = iLow(m_symbol, m_timeframe, iLowest(m_symbol, m_timeframe, MODE_LOW, start_bar - end_bar + 1, end_bar));
   
   // Calculate number of price levels
   int num_levels = (int)MathCeil((range_high - range_low) / m_price_step) + 1;
   
   // Initialize price levels
   ArrayResize(m_profile.levels, num_levels);
   m_profile.level_count = num_levels;
   
   for(int i = 0; i < num_levels; i++)
   {
      m_profile.levels[i].price = NormalizePriceToStep(range_low + i * m_price_step);
      m_profile.levels[i].buy_volume = 0;
      m_profile.levels[i].sell_volume = 0;
      m_profile.levels[i].total_volume = 0;
      m_profile.levels[i].is_hvn = false;
      m_profile.levels[i].is_lvn = false;
      m_profile.levels[i].in_value_area = false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Normalize price to step size                                     |
//+------------------------------------------------------------------+
double CVolumeProfileEngine::NormalizePriceToStep(double price)
{
   return MathRound(price / m_price_step) * m_price_step;
}

//+------------------------------------------------------------------+
//| Find price level index for given price                           |
//+------------------------------------------------------------------+
int CVolumeProfileEngine::FindPriceLevelIndex(double price)
{
   double normalized_price = NormalizePriceToStep(price);
   
   for(int i = 0; i < m_profile.level_count; i++)
   {
      if(MathAbs(m_profile.levels[i].price - normalized_price) < m_price_step * 0.5)
         return i;
   }
   
   return -1;
}

//+------------------------------------------------------------------+
//| Aggregate volume into price levels                               |
//+------------------------------------------------------------------+
void CVolumeProfileEngine::AggregateVolume(datetime start_time, datetime end_time)
{
   int start_bar = iBarShift(m_symbol, m_timeframe, start_time);
   int end_bar = iBarShift(m_symbol, m_timeframe, end_time);
   
   m_profile.total_volume = 0;
   
   for(int bar = end_bar; bar <= start_bar; bar++)
   {
      double open = iOpen(m_symbol, m_timeframe, bar);
      double close = iClose(m_symbol, m_timeframe, bar);
      double high = iHigh(m_symbol, m_timeframe, bar);
      double low = iLow(m_symbol, m_timeframe, bar);
      
      long buy_vol = 0, sell_vol = 0;
      bool is_buy;
      
      // Get volume for this bar
      if(m_use_real_volume)
      {
         GetRealVolume(bar, buy_vol, sell_vol);
      }
      else
      {
         long tick_vol;
         GetTickVolume(bar, tick_vol);
         
         // Estimate buy/sell based on candle direction
         if(close > open)
         {
            buy_vol = (long)(tick_vol * 0.6);
            sell_vol = tick_vol - buy_vol;
         }
         else
         {
            sell_vol = (long)(tick_vol * 0.6);
            buy_vol = tick_vol - sell_vol;
         }
      }
      
      // Distribute volume across touched price levels
      double price_range = high - low;
      if(price_range < m_price_step) price_range = m_price_step;
      
      int levels_touched = (int)MathCeil(price_range / m_price_step);
      
      for(double price = low; price <= high; price += m_price_step)
      {
         int level_index = FindPriceLevelIndex(price);
         if(level_index >= 0)
         {
            long vol_per_level_buy = buy_vol / levels_touched;
            long vol_per_level_sell = sell_vol / levels_touched;
            
            m_profile.levels[level_index].buy_volume += vol_per_level_buy;
            m_profile.levels[level_index].sell_volume += vol_per_level_sell;
            m_profile.levels[level_index].total_volume += vol_per_level_buy + vol_per_level_sell;
            
            m_profile.total_volume += vol_per_level_buy + vol_per_level_sell;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get real volume data                                             |
//+------------------------------------------------------------------+
bool CVolumeProfileEngine::GetRealVolume(int bar_index, long &buy_vol, long &sell_vol)
{
   long volume[];
   int copied = CopyRealVolume(m_symbol, m_timeframe, bar_index, 1, volume);
   
   if(copied <= 0)
      return false;
   
   // Real volume doesn't distinguish buy/sell in MT5 standard
   // Use price action to estimate
   double open = iOpen(m_symbol, m_timeframe, bar_index);
   double close = iClose(m_symbol, m_timeframe, bar_index);
   
   if(close > open)
   {
      buy_vol = (long)(volume[0] * 0.6);
      sell_vol = volume[0] - buy_vol;
   }
   else
   {
      sell_vol = (long)(volume[0] * 0.6);
      buy_vol = volume[0] - sell_vol;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get tick volume data                                             |
//+------------------------------------------------------------------+
bool CVolumeProfileEngine::GetTickVolume(int bar_index, long &volume)
{
   long vol[];
   int copied = CopyTickVolume(m_symbol, m_timeframe, bar_index, 1, vol);
   
   if(copied <= 0)
      return false;
   
   volume = vol[0];
   return true;
}

//+------------------------------------------------------------------+
//| Calculate Point of Control (POC)                                 |
//+------------------------------------------------------------------+
void CVolumeProfileEngine::CalculatePOC()
{
   long max_volume = 0;
   int max_index = 0;
   
   for(int i = 0; i < m_profile.level_count; i++)
   {
      if(m_profile.levels[i].total_volume > max_volume)
      {
         max_volume = m_profile.levels[i].total_volume;
         max_index = i;
      }
   }
   
   m_profile.poc_index = max_index;
   m_profile.poc_price = m_profile.levels[max_index].price;
}

//+------------------------------------------------------------------+
//| Calculate Value Area (VA)                                        |
//+------------------------------------------------------------------+
void CVolumeProfileEngine::CalculateValueArea()
{
   long target_volume = (long)(m_profile.total_volume * m_value_area_percent);
   long accumulated_volume = m_profile.levels[m_profile.poc_index].total_volume;
   
   int va_high_index = m_profile.poc_index;
   int va_low_index = m_profile.poc_index;
   
   // Expand VA symmetrically from POC
   while(accumulated_volume < target_volume)
   {
      long vol_above = 0;
      long vol_below = 0;
      
      if(va_high_index < m_profile.level_count - 1)
         vol_above = m_profile.levels[va_high_index + 1].total_volume;
      
      if(va_low_index > 0)
         vol_below = m_profile.levels[va_low_index - 1].total_volume;
      
      // Expand in direction of higher volume
      if(vol_above > vol_below && va_high_index < m_profile.level_count - 1)
      {
         va_high_index++;
         accumulated_volume += vol_above;
      }
      else if(va_low_index > 0)
      {
         va_low_index--;
         accumulated_volume += vol_below;
      }
      else if(va_high_index < m_profile.level_count - 1)
      {
         va_high_index++;
         accumulated_volume += vol_above;
      }
      else
      {
         break; // Can't expand further
      }
   }
   
   m_profile.vah = m_profile.levels[va_high_index].price;
   m_profile.val = m_profile.levels[va_low_index].price;
   
   // Mark levels in value area
   for(int i = va_low_index; i <= va_high_index; i++)
   {
      m_profile.levels[i].in_value_area = true;
   }
}

//+------------------------------------------------------------------+
//| Identify High Volume Nodes (HVN) and Low Volume Nodes (LVN)      |
//+------------------------------------------------------------------+
void CVolumeProfileEngine::IdentifyHVNandLVN()
{
   if(m_profile.level_count == 0) return;
   
   // Calculate average volume
   long total_vol = 0;
   for(int i = 0; i < m_profile.level_count; i++)
   {
      total_vol += m_profile.levels[i].total_volume;
   }
   double avg_volume = (double)total_vol / m_profile.level_count;
   
   // HVN: volume > 150% of average
   // LVN: volume < 50% of average
   for(int i = 0; i < m_profile.level_count; i++)
   {
      if(m_profile.levels[i].total_volume > avg_volume * 1.5)
         m_profile.levels[i].is_hvn = true;
      
      if(m_profile.levels[i].total_volume < avg_volume * 0.5)
         m_profile.levels[i].is_lvn = true;
   }
}

//+------------------------------------------------------------------+
//| Get pointer to specific price level                              |
//+------------------------------------------------------------------+
PriceLevel* CVolumeProfileEngine::GetLevel(int index)
{
   if(index < 0 || index >= m_profile.level_count)
      return NULL;
   
   return &m_profile.levels[index];
}

//+------------------------------------------------------------------+
//| Set fixed time range                                             |
//+------------------------------------------------------------------+
void CVolumeProfileEngine::SetFixedRange(datetime start, datetime end)
{
   m_fixed_start = start;
   m_fixed_end = end;
}

//+------------------------------------------------------------------+
//| Get session start time (for daily mode)                          |
//+------------------------------------------------------------------+
datetime CVolumeProfileEngine::GetSessionStartTime()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Get visible range start (simplified)                             |
//+------------------------------------------------------------------+
datetime CVolumeProfileEngine::GetVisibleRangeStart()
{
   int visible_bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
   return iTime(m_symbol, m_timeframe, visible_bars);
}

//+------------------------------------------------------------------+
//| Get visible range end                                            |
//+------------------------------------------------------------------+
datetime CVolumeProfileEngine::GetVisibleRangeEnd()
{
   return iTime(m_symbol, m_timeframe, 0);
}
//+------------------------------------------------------------------+
