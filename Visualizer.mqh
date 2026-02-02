//+------------------------------------------------------------------+
//|                                                   Visualizer.mqh |
//|                     Volume Profile & Zone Visualization System   |
//+------------------------------------------------------------------+
#property copyright "Institutional Volume Profile System"
#property link      ""
#property version   "1.00"
#property strict

#include "VolumeProfileEngine.mqh"
#include "InstitutionalZoneDetector.mqh"
#include "SignalEngine.mqh"

//+------------------------------------------------------------------+
//| Visualization Configuration                                      |
//+------------------------------------------------------------------+
struct VisualConfig
{
   color poc_color;
   color vah_color;
   color val_color;
   color zone_upper_color;
   color zone_lower_color;
   color buy_volume_color;
   color sell_volume_color;
   color long_arrow_color;
   color short_arrow_color;
   color lvn_color;
   
   int   poc_width;
   int   zone_line_width;
   int   arrow_size;
   
   bool  show_histogram;
   bool  show_value_area;
   bool  show_lvn;
};

//+------------------------------------------------------------------+
//| Visualizer Class                                                 |
//+------------------------------------------------------------------+
class CVolumeProfileVisualizer
{
private:
   CVolumeProfileEngine* m_vp_engine;
   CInstitutionalZoneDetector* m_zone_detector;
   
   VisualConfig m_config;
   
   // Object name prefixes
   string m_prefix;
   
   // Drawing boundaries
   int m_chart_width_bars;
   double m_histogram_width_pct;
   
public:
   CVolumeProfileVisualizer();
   ~CVolumeProfileVisualizer();
   
   bool Initialize(CVolumeProfileEngine* vp_engine, 
                   CInstitutionalZoneDetector* zone_detector,
                   string prefix = "IVP_");
   
   void SetColors(color poc, color vah, color val, color zone_upper, color zone_lower,
                  color buy_vol, color sell_vol, color long_arrow, color short_arrow);
   
   // Main drawing functions
   void DrawAll();
   void ClearAll();
   
   void DrawVolumeProfile();
   void DrawInstitutionalZones();
   void DrawSignalArrow(TradingSignal &signal);
   void DrawLVNs();
   
   // Individual component drawing
   void DrawPOC(double poc_price, datetime start_time, datetime end_time);
   void DrawValueArea(double vah, double val, datetime start_time, datetime end_time);
   void DrawHistogram(VolumeProfileData* profile, datetime start_time);
   void DrawZoneBoundaries(InstitutionalZone* zone, datetime start_time, datetime end_time);
   
   // Helper functions
   void DeleteObject(string name);
   void DeleteObjectsByPrefix(string prefix);
   
private:
   // Drawing primitives
   void DrawHorizontalLine(string name, double price, color clr, int width, int style,
                          datetime start_time = 0, datetime end_time = 0);
   void DrawRectangle(string name, double price1, double price2, 
                     datetime time1, datetime time2, color clr, bool fill);
   void DrawArrow(string name, datetime time, double price, int arrow_code, color clr);
   void DrawText(string name, datetime time, double price, string text, color clr);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CVolumeProfileVisualizer::CVolumeProfileVisualizer()
{
   m_prefix = "IVP_";
   m_chart_width_bars = 100;
   m_histogram_width_pct = 0.25; // Histogram takes 25% of chart width
   
   // Default colors
   m_config.poc_color = clrRed;
   m_config.vah_color = clrDarkGreen;
   m_config.val_color = clrDarkGreen;
   m_config.zone_upper_color = clrCrimson;
   m_config.zone_lower_color = clrDodgerBlue;
   m_config.buy_volume_color = clrDodgerBlue;
   m_config.sell_volume_color = clrGold;
   m_config.long_arrow_color = clrLime;
   m_config.short_arrow_color = clrRed;
   m_config.lvn_color = clrGray;
   
   m_config.poc_width = 2;
   m_config.zone_line_width = 1;
   m_config.arrow_size = 3;
   
   m_config.show_histogram = true;
   m_config.show_value_area = true;
   m_config.show_lvn = true;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CVolumeProfileVisualizer::~CVolumeProfileVisualizer()
{
   ClearAll();
}

//+------------------------------------------------------------------+
//| Initialize visualizer                                            |
//+------------------------------------------------------------------+
bool CVolumeProfileVisualizer::Initialize(CVolumeProfileEngine* vp_engine,
                                          CInstitutionalZoneDetector* zone_detector,
                                          string prefix)
{
   if(vp_engine == NULL || zone_detector == NULL)
      return false;
   
   m_vp_engine = vp_engine;
   m_zone_detector = zone_detector;
   m_prefix = prefix;
   
   return true;
}

//+------------------------------------------------------------------+
//| Set custom colors                                                |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::SetColors(color poc, color vah, color val, 
                                         color zone_upper, color zone_lower,
                                         color buy_vol, color sell_vol, 
                                         color long_arrow, color short_arrow)
{
   m_config.poc_color = poc;
   m_config.vah_color = vah;
   m_config.val_color = val;
   m_config.zone_upper_color = zone_upper;
   m_config.zone_lower_color = zone_lower;
   m_config.buy_volume_color = buy_vol;
   m_config.sell_volume_color = sell_vol;
   m_config.long_arrow_color = long_arrow;
   m_config.short_arrow_color = short_arrow;
}

//+------------------------------------------------------------------+
//| Draw all components                                              |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawAll()
{
   DrawVolumeProfile();
   DrawInstitutionalZones();
   
   if(m_config.show_lvn)
      DrawLVNs();
}

//+------------------------------------------------------------------+
//| Clear all drawings                                               |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::ClearAll()
{
   DeleteObjectsByPrefix(m_prefix);
}

//+------------------------------------------------------------------+
//| Draw complete volume profile                                     |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawVolumeProfile()
{
   VolumeProfileData* profile = m_vp_engine.GetProfile();
   if(profile == NULL || profile.level_count == 0)
      return;
   
   // Draw POC
   DrawPOC(profile.poc_price, profile.start_time, profile.end_time);
   
   // Draw Value Area
   if(m_config.show_value_area)
      DrawValueArea(profile.vah, profile.val, profile.start_time, profile.end_time);
   
   // Draw Histogram
   if(m_config.show_histogram)
      DrawHistogram(profile, profile.end_time);
}

//+------------------------------------------------------------------+
//| Draw POC line                                                    |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawPOC(double poc_price, datetime start_time, datetime end_time)
{
   string name = m_prefix + "POC";
   DrawHorizontalLine(name, poc_price, m_config.poc_color, m_config.poc_width, 
                     STYLE_SOLID, start_time, end_time);
   
   // Add label
   string label_name = m_prefix + "POC_Label";
   DrawText(label_name, end_time, poc_price, "POC", m_config.poc_color);
}

//+------------------------------------------------------------------+
//| Draw Value Area High and Low                                     |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawValueArea(double vah, double val, 
                                              datetime start_time, datetime end_time)
{
   // VAH line
   string vah_name = m_prefix + "VAH";
   DrawHorizontalLine(vah_name, vah, m_config.vah_color, 1, STYLE_DOT, start_time, end_time);
   
   // VAL line
   string val_name = m_prefix + "VAL";
   DrawHorizontalLine(val_name, val, m_config.val_color, 1, STYLE_DOT, start_time, end_time);
   
   // VA rectangle (semi-transparent)
   string va_rect = m_prefix + "VA_Rect";
   DrawRectangle(va_rect, vah, val, start_time, end_time, m_config.vah_color, true);
}

//+------------------------------------------------------------------+
//| Draw volume histogram                                            |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawHistogram(VolumeProfileData* profile, datetime start_time)
{
   if(profile == NULL || profile.level_count == 0)
      return;
   
   // Find maximum volume for scaling
   long max_volume = 0;
   for(int i = 0; i < profile.level_count; i++)
   {
      if(profile.levels[i].total_volume > max_volume)
         max_volume = profile.levels[i].total_volume;
   }
   
   if(max_volume == 0) return;
   
   // Calculate histogram time width
   int bars_for_histogram = (int)(m_chart_width_bars * m_histogram_width_pct);
   datetime end_time = start_time + bars_for_histogram * PeriodSeconds(PERIOD_CURRENT);
   
   // Draw each price level's volume
   for(int i = 0; i < profile.level_count; i++)
   {
      double volume_ratio = (double)profile.levels[i].total_volume / (double)max_volume;
      int bar_width = (int)(bars_for_histogram * volume_ratio);
      
      datetime bar_end = start_time + bar_width * PeriodSeconds(PERIOD_CURRENT);
      
      // Determine color based on buy/sell dominance
      color bar_color;
      if(profile.levels[i].buy_volume > profile.levels[i].sell_volume)
         bar_color = m_config.buy_volume_color;
      else
         bar_color = m_config.sell_volume_color;
      
      // Highlight if in value area
      if(profile.levels[i].in_value_area)
      {
         // Make brighter
         bar_color = (bar_color == m_config.buy_volume_color) ? 
                     clrDeepSkyBlue : clrYellow;
      }
      
      // Draw histogram bar
      string bar_name = m_prefix + "Hist_" + IntegerToString(i);
      double price_upper = profile.levels[i].price + SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 5;
      double price_lower = profile.levels[i].price - SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 5;
      
      DrawRectangle(bar_name, price_upper, price_lower, start_time, bar_end, bar_color, true);
   }
}

//+------------------------------------------------------------------+
//| Draw institutional zones                                         |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawInstitutionalZones()
{
   int zone_count = m_zone_detector.GetZoneCount();
   
   for(int i = 0; i < zone_count; i++)
   {
      InstitutionalZone* zone = m_zone_detector.GetZone(i);
      if(zone != NULL)
      {
         VolumeProfileData* profile = m_vp_engine.GetProfile();
         DrawZoneBoundaries(zone, profile.start_time, profile.end_time);
      }
   }
}

//+------------------------------------------------------------------+
//| Draw zone boundaries                                             |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawZoneBoundaries(InstitutionalZone* zone, 
                                                   datetime start_time, datetime end_time)
{
   // Upper boundary (dashed line)
   string upper_name = m_prefix + "Zone_Upper";
   DrawHorizontalLine(upper_name, zone.upper_boundary, m_config.zone_upper_color, 
                     m_config.zone_line_width, STYLE_DASH, start_time, end_time);
   
   // Lower boundary (dashed line)
   string lower_name = m_prefix + "Zone_Lower";
   DrawHorizontalLine(lower_name, zone.lower_boundary, m_config.zone_lower_color, 
                     m_config.zone_line_width, STYLE_DASH, start_time, end_time);
   
   // Zone fill (semi-transparent)
   string fill_name = m_prefix + "Zone_Fill";
   color fill_color = zone.is_resistance ? clrMistyRose : clrLightBlue;
   DrawRectangle(fill_name, zone.upper_boundary, zone.lower_boundary, 
                start_time, end_time, fill_color, true);
   
   // Label zone strength
   string label_name = m_prefix + "Zone_Strength";
   double label_price = (zone.upper_boundary + zone.lower_boundary) / 2.0;
   string strength_text = "Zone ★" + IntegerToString(zone.strength);
   DrawText(label_name, end_time, label_price, strength_text, clrWhite);
}

//+------------------------------------------------------------------+
//| Draw LVN markers                                                 |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawLVNs()
{
   VolumeProfileData* profile = m_vp_engine.GetProfile();
   if(profile == NULL) return;
   
   int lvn_count = 0;
   for(int i = 0; i < profile.level_count; i++)
   {
      if(profile.levels[i].is_lvn)
      {
         string lvn_name = m_prefix + "LVN_" + IntegerToString(lvn_count);
         DrawHorizontalLine(lvn_name, profile.levels[i].price, m_config.lvn_color, 
                          1, STYLE_DOT, profile.start_time, profile.end_time);
         lvn_count++;
      }
   }
}

//+------------------------------------------------------------------+
//| Draw signal arrow                                                |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawSignalArrow(TradingSignal &signal)
{
   if(signal.signal_type == 0) return;
   
   string arrow_name = m_prefix + "Arrow_" + TimeToString(signal.signal_time);
   
   int arrow_code;
   color arrow_color;
   double arrow_price;
   
   if(signal.signal_type == 1) // Long
   {
      arrow_code = 233; // Up arrow
      arrow_color = m_config.long_arrow_color;
      arrow_price = signal.entry_price - iATR(_Symbol, PERIOD_CURRENT, 14, 0) * 0.3;
   }
   else // Short
   {
      arrow_code = 234; // Down arrow
      arrow_color = m_config.short_arrow_color;
      arrow_price = signal.entry_price + iATR(_Symbol, PERIOD_CURRENT, 14, 0) * 0.3;
   }
   
   DrawArrow(arrow_name, signal.signal_time, arrow_price, arrow_code, arrow_color);
   
   // Draw SL and TP lines
   if(signal.stop_loss > 0)
   {
      string sl_name = m_prefix + "SL_" + TimeToString(signal.signal_time);
      DrawHorizontalLine(sl_name, signal.stop_loss, clrRed, 1, STYLE_DOT, 
                        signal.signal_time, signal.signal_time + 3600 * 24);
   }
   
   if(signal.take_profit > 0)
   {
      string tp_name = m_prefix + "TP_" + TimeToString(signal.signal_time);
      DrawHorizontalLine(tp_name, signal.take_profit, clrGreen, 1, STYLE_DOT,
                        signal.signal_time, signal.signal_time + 3600 * 24);
   }
}

//+------------------------------------------------------------------+
//| Draw horizontal line                                             |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawHorizontalLine(string name, double price, color clr, 
                                                   int width, int style, 
                                                   datetime start_time, datetime end_time)
{
   DeleteObject(name);
   
   if(start_time == 0 || end_time == 0)
   {
      // Regular horizontal line
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   }
   else
   {
      // Trend line (time-bounded)
      ObjectCreate(0, name, OBJ_TREND, 0, start_time, price, end_time, price);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   }
   
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw rectangle                                                   |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawRectangle(string name, double price1, double price2,
                                              datetime time1, datetime time2, 
                                              color clr, bool fill)
{
   DeleteObject(name);
   
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FILL, fill);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   
   if(fill)
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
}

//+------------------------------------------------------------------+
//| Draw arrow                                                       |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawArrow(string name, datetime time, double price, 
                                         int arrow_code, color clr)
{
   DeleteObject(name);
   
   ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrow_code);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, m_config.arrow_size);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
}

//+------------------------------------------------------------------+
//| Draw text                                                        |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DrawText(string name, datetime time, double price, 
                                        string text, color clr)
{
   DeleteObject(name);
   
   ObjectCreate(0, name, OBJ_TEXT, 0, time, price);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
}

//+------------------------------------------------------------------+
//| Delete single object                                             |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DeleteObject(string name)
{
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
}

//+------------------------------------------------------------------+
//| Delete all objects with prefix                                   |
//+------------------------------------------------------------------+
void CVolumeProfileVisualizer::DeleteObjectsByPrefix(string prefix)
{
   int total = ObjectsTotal(0);
   
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
}
//+------------------------------------------------------------------+
