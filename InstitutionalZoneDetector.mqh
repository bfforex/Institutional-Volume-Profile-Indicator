//+------------------------------------------------------------------+
//|                                  InstitutionalZoneDetector.mqh   |
//|                           HVN Cluster Detection & Zone Definition |
//+------------------------------------------------------------------+
#property copyright "Institutional Volume Profile System"
#property link      ""
#property version   "1.00"
#property strict

#include "VolumeProfileEngine.mqh"

//+------------------------------------------------------------------+
//| Institutional Zone Structure                                     |
//+------------------------------------------------------------------+
struct InstitutionalZone
{
   double upper_boundary;      // Resistance edge (top of HVN cluster)
   double lower_boundary;      // Support edge (bottom of HVN cluster)
   double poc_price;           // Central POC within zone
   long   total_volume;        // Total volume in zone
   
   bool   is_resistance;       // Acting as resistance
   bool   is_support;          // Acting as support
   
   double nearest_lvn_above;   // Nearest LVN above (for SL placement)
   double nearest_lvn_below;   // Nearest LVN below (for SL placement)
   
   int    strength;            // Zone strength (1-5)
   datetime first_touch_time;  // Time of first touch for tracking
   bool   touched_from_above;  // Last touch direction
   bool   touched_from_below;  
   
   int    touch_count;         // Number of times touched
};

//+------------------------------------------------------------------+
//| Zone Detector Class                                              |
//+------------------------------------------------------------------+
class CInstitutionalZoneDetector
{
private:
   CVolumeProfileEngine* m_vp_engine;
   
   double m_zone_sensitivity;     // HVN cluster sensitivity (0.7 = 70% of POC volume)
   InstitutionalZone m_zones[];   // Detected zones
   int    m_zone_count;
   
public:
   CInstitutionalZoneDetector();
   ~CInstitutionalZoneDetector();
   
   bool Initialize(CVolumeProfileEngine* vp_engine, double sensitivity);
   
   // Zone detection
   bool DetectZones();
   void ClearZones();
   
   // Zone queries
   int GetZoneCount() { return m_zone_count; }
   InstitutionalZone* GetZone(int index);
   bool IsPriceInZone(double price, int &zone_index);
   bool IsPriceAtZoneEdge(double price, bool &is_upper_edge, int &zone_index, double edge_tolerance);
   
   // LVN detection
   void IdentifyNearestLVNs();
   double GetNearestLVNAbove(double price);
   double GetNearestLVNBelow(double price);
   
   // Zone strength calculation
   int CalculateZoneStrength(InstitutionalZone &zone);
   
private:
   // Internal detection methods
   bool ExpandZoneFromPOC(VolumeProfileData* profile);
   bool MergeOverlappingZones();
   void AssignZoneRoles(double current_price);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CInstitutionalZoneDetector::CInstitutionalZoneDetector()
{
   m_zone_sensitivity = 0.70;
   m_zone_count = 0;
   m_vp_engine = NULL;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CInstitutionalZoneDetector::~CInstitutionalZoneDetector()
{
   ArrayFree(m_zones);
}

//+------------------------------------------------------------------+
//| Initialize detector                                              |
//+------------------------------------------------------------------+
bool CInstitutionalZoneDetector::Initialize(CVolumeProfileEngine* vp_engine, double sensitivity)
{
   if(vp_engine == NULL)
      return false;
   
   m_vp_engine = vp_engine;
   m_zone_sensitivity = sensitivity;
   
   return true;
}

//+------------------------------------------------------------------+
//| Clear all detected zones                                         |
//+------------------------------------------------------------------+
void CInstitutionalZoneDetector::ClearZones()
{
   ArrayResize(m_zones, 0);
   m_zone_count = 0;
}

//+------------------------------------------------------------------+
//| Detect institutional zones from volume profile                   |
//+------------------------------------------------------------------+
bool CInstitutionalZoneDetector::DetectZones()
{
   ClearZones();
   
   VolumeProfileData* profile = m_vp_engine.GetProfile();
   if(profile == NULL || profile.level_count == 0)
      return false;
   
   // Expand zone from POC based on HVN cluster
   if(!ExpandZoneFromPOC(profile))
      return false;
   
   // Identify nearest LVNs for each zone
   IdentifyNearestLVNs();
   
   // Calculate zone strength
   for(int i = 0; i < m_zone_count; i++)
   {
      m_zones[i].strength = CalculateZoneStrength(m_zones[i]);
   }
   
   // Assign zone roles based on current price
   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   AssignZoneRoles(current_price);
   
   return true;
}

//+------------------------------------------------------------------+
//| Expand zone from POC using HVN cluster algorithm                 |
//+------------------------------------------------------------------+
bool CInstitutionalZoneDetector::ExpandZoneFromPOC(VolumeProfileData* profile)
{
   int poc_index = profile.poc_index;
   long poc_volume = profile.levels[poc_index].total_volume;
   long volume_threshold = (long)(poc_volume * m_zone_sensitivity);
   
   // Start from POC and expand up and down
   int upper_index = poc_index;
   int lower_index = poc_index;
   
   // Expand upward
   while(upper_index < profile.level_count - 1)
   {
      if(profile.levels[upper_index + 1].total_volume >= volume_threshold)
         upper_index++;
      else
         break;
   }
   
   // Expand downward
   while(lower_index > 0)
   {
      if(profile.levels[lower_index - 1].total_volume >= volume_threshold)
         lower_index--;
      else
         break;
   }
   
   // Create institutional zone
   ArrayResize(m_zones, 1);
   m_zone_count = 1;
   
   m_zones[0].upper_boundary = profile.levels[upper_index].price;
   m_zones[0].lower_boundary = profile.levels[lower_index].price;
   m_zones[0].poc_price = profile.poc_price;
   
   // Calculate total volume in zone
   m_zones[0].total_volume = 0;
   for(int i = lower_index; i <= upper_index; i++)
   {
      m_zones[0].total_volume += profile.levels[i].total_volume;
   }
   
   m_zones[0].touch_count = 0;
   m_zones[0].first_touch_time = 0;
   m_zones[0].touched_from_above = false;
   m_zones[0].touched_from_below = false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Identify nearest LVNs for stop-loss placement                    |
//+------------------------------------------------------------------+
void CInstitutionalZoneDetector::IdentifyNearestLVNs()
{
   VolumeProfileData* profile = m_vp_engine.GetProfile();
   if(profile == NULL) return;
   
   for(int z = 0; z < m_zone_count; z++)
   {
      m_zones[z].nearest_lvn_above = 0;
      m_zones[z].nearest_lvn_below = 0;
      
      // Find LVN above zone
      for(int i = 0; i < profile.level_count; i++)
      {
         if(profile.levels[i].is_lvn && 
            profile.levels[i].price > m_zones[z].upper_boundary)
         {
            m_zones[z].nearest_lvn_above = profile.levels[i].price;
            break;
         }
      }
      
      // Find LVN below zone
      for(int i = profile.level_count - 1; i >= 0; i--)
      {
         if(profile.levels[i].is_lvn && 
            profile.levels[i].price < m_zones[z].lower_boundary)
         {
            m_zones[z].nearest_lvn_below = profile.levels[i].price;
            break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get nearest LVN above price                                      |
//+------------------------------------------------------------------+
double CInstitutionalZoneDetector::GetNearestLVNAbove(double price)
{
   VolumeProfileData* profile = m_vp_engine.GetProfile();
   if(profile == NULL) return 0;
   
   for(int i = 0; i < profile.level_count; i++)
   {
      if(profile.levels[i].is_lvn && profile.levels[i].price > price)
         return profile.levels[i].price;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get nearest LVN below price                                      |
//+------------------------------------------------------------------+
double CInstitutionalZoneDetector::GetNearestLVNBelow(double price)
{
   VolumeProfileData* profile = m_vp_engine.GetProfile();
   if(profile == NULL) return 0;
   
   for(int i = profile.level_count - 1; i >= 0; i--)
   {
      if(profile.levels[i].is_lvn && profile.levels[i].price < price)
         return profile.levels[i].price;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Calculate zone strength (1-5 scale)                              |
//+------------------------------------------------------------------+
int CInstitutionalZoneDetector::CalculateZoneStrength(InstitutionalZone &zone)
{
   VolumeProfileData* profile = m_vp_engine.GetProfile();
   if(profile == NULL) return 1;
   
   int strength = 1;
   
   // Factor 1: Volume relative to total profile volume
   double volume_ratio = (double)zone.total_volume / (double)profile.total_volume;
   if(volume_ratio > 0.30) strength++;
   if(volume_ratio > 0.50) strength++;
   
   // Factor 2: Zone thickness (tighter = stronger)
   double zone_thickness = zone.upper_boundary - zone.lower_boundary;
   double atr = iATR(_Symbol, PERIOD_CURRENT, 14, 0);
   if(zone_thickness < atr * 0.5) strength++;
   
   // Factor 3: Historical touch behavior
   if(zone.touch_count > 2) strength++;
   
   // Cap at 5
   if(strength > 5) strength = 5;
   
   return strength;
}

//+------------------------------------------------------------------+
//| Assign zone roles based on current price position                |
//+------------------------------------------------------------------+
void CInstitutionalZoneDetector::AssignZoneRoles(double current_price)
{
   for(int i = 0; i < m_zone_count; i++)
   {
      if(current_price < m_zones[i].lower_boundary)
      {
         // Price is below zone -> zone is resistance
         m_zones[i].is_resistance = true;
         m_zones[i].is_support = false;
      }
      else if(current_price > m_zones[i].upper_boundary)
      {
         // Price is above zone -> zone is support
         m_zones[i].is_resistance = false;
         m_zones[i].is_support = true;
      }
      else
      {
         // Price is inside zone -> neutral
         m_zones[i].is_resistance = false;
         m_zones[i].is_support = false;
      }
   }
}

//+------------------------------------------------------------------+
//| Get zone by index                                                |
//+------------------------------------------------------------------+
InstitutionalZone* CInstitutionalZoneDetector::GetZone(int index)
{
   if(index < 0 || index >= m_zone_count)
      return NULL;
   
   return &m_zones[index];
}

//+------------------------------------------------------------------+
//| Check if price is within any zone                                |
//+------------------------------------------------------------------+
bool CInstitutionalZoneDetector::IsPriceInZone(double price, int &zone_index)
{
   for(int i = 0; i < m_zone_count; i++)
   {
      if(price >= m_zones[i].lower_boundary && 
         price <= m_zones[i].upper_boundary)
      {
         zone_index = i;
         return true;
      }
   }
   
   zone_index = -1;
   return false;
}

//+------------------------------------------------------------------+
//| Check if price is at zone edge (for signal generation)           |
//+------------------------------------------------------------------+
bool CInstitutionalZoneDetector::IsPriceAtZoneEdge(double price, bool &is_upper_edge, 
                                                   int &zone_index, double edge_tolerance)
{
   for(int i = 0; i < m_zone_count; i++)
   {
      // Check upper boundary
      if(MathAbs(price - m_zones[i].upper_boundary) <= edge_tolerance)
      {
         is_upper_edge = true;
         zone_index = i;
         return true;
      }
      
      // Check lower boundary
      if(MathAbs(price - m_zones[i].lower_boundary) <= edge_tolerance)
      {
         is_upper_edge = false;
         zone_index = i;
         return true;
      }
   }
   
   zone_index = -1;
   return false;
}
//+------------------------------------------------------------------+
