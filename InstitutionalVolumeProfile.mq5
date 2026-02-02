//+------------------------------------------------------------------+
//|                                  InstitutionalVolumeProfile.mq5 |
//|                        Copyright 2026, Institutional Trading Co. |
//|                                           https://bfforex.com     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Institutional Trading Co."
#property link      "https://bfforex.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5

//--- plot Zone Upper Boundary
#property indicator_label1  "Zone Upper"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- plot Zone Lower Boundary
#property indicator_label2  "Zone Lower"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- plot Buy Signal
#property indicator_label3  "Buy Signal"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrLime
#property indicator_width3  3

//--- plot Sell Signal
#property indicator_label4  "Sell Signal"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrRed
#property indicator_width4  3

//--- plot POC (Point of Control)
#property indicator_label5  "POC"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrYellow
#property indicator_style5  STYLE_DOT
#property indicator_width5  1

//+------------------------------------------------------------------+
//| Input Parameters                                                   |
//+------------------------------------------------------------------+
input int      InpPeriod = 100;                    // Volume Profile Period
input int      InpPriceRows = 50;                  // Number of Price Rows
input double   InpHVNThreshold = 1.5;              // HVN Threshold Multiplier
input int      InpMinClusterSize = 3;              // Minimum HVN Cluster Size
input double   InpZoneExpansion = 0.1;             // Zone Expansion (% of cluster range)
input bool     InpEnableMLFilter = true;           // Enable ML-Based Filter
input double   InpMLSensitivity = 0.5;             // ML Filter Sensitivity (0.0-1.0)
input int      InpMLLearningPeriod = 500;          // ML Learning Period (bars)
input bool     InpShowZones = true;                // Show Institutional Zones
input bool     InpShowSignals = true;              // Show Entry Signals
input bool     InpShowPOC = true;                  // Show POC Line
input bool     InpFirstTouchOnly = true;           // First-Touch Principle
input int      InpSignalExpiry = 10;               // Signal Expiry (bars)

//+------------------------------------------------------------------+
//| Indicator Buffers                                                  |
//+------------------------------------------------------------------+
double ZoneUpperBuffer[];
double ZoneLowerBuffer[];
double BuySignalBuffer[];
double SellSignalBuffer[];
double POCBuffer[];

//+------------------------------------------------------------------+
//| Global Variables                                                   |
//+------------------------------------------------------------------+
struct VolumeNode
{
   double price;
   double volume;
};

struct InstitutionalZone
{
   double upperEdge;
   double lowerEdge;
   double poc;
   double totalVolume;
   int    startBar;
   bool   upperTouched;
   bool   lowerTouched;
};

struct MLSignalRecord
{
   datetime time;
   double   price;
   int      signalType;  // 1=buy, -1=sell
   bool     wasSuccessful;
   double   confidence;
};

InstitutionalZone currentZone;
MLSignalRecord mlHistory[];
int mlHistorySize = 0;
double mlAdaptiveSensitivity;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- indicator buffers mapping
   SetIndexBuffer(0, ZoneUpperBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ZoneLowerBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, BuySignalBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, SellSignalBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, POCBuffer, INDICATOR_DATA);
   
   //--- set arrow codes
   PlotIndexSetInteger(2, PLOT_ARROW, 233);  // Up arrow for buy
   PlotIndexSetInteger(3, PLOT_ARROW, 234);  // Down arrow for sell
   
   //--- set empty values
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0.0);
   
   //--- initialize arrays
   ArraySetAsSeries(ZoneUpperBuffer, true);
   ArraySetAsSeries(ZoneLowerBuffer, true);
   ArraySetAsSeries(BuySignalBuffer, true);
   ArraySetAsSeries(SellSignalBuffer, true);
   ArraySetAsSeries(POCBuffer, true);
   
   //--- initialize ML filter
   mlAdaptiveSensitivity = InpMLSensitivity;
   ArrayResize(mlHistory, InpMLLearningPeriod);
   mlHistorySize = 0;
   
   //--- initialize zone
   currentZone.upperEdge = 0;
   currentZone.lowerEdge = 0;
   currentZone.poc = 0;
   currentZone.totalVolume = 0;
   currentZone.startBar = 0;
   currentZone.upperTouched = false;
   currentZone.lowerTouched = false;
   
   //--- indicator short name
   IndicatorSetString(INDICATOR_SHORTNAME, "Institutional Volume Profile");
   
   //--- set digits
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   //--- set arrays as series
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(tick_volume, true);
   
   //--- check for minimum bars
   if(rates_total < InpPeriod)
      return(0);
   
   //--- determine calculation range
   int limit = rates_total - prev_calculated;
   if(limit > InpPeriod)
      limit = InpPeriod;
   
   //--- main calculation loop
   for(int i = limit; i >= 0; i--)
   {
      //--- initialize buffers
      ZoneUpperBuffer[i] = 0.0;
      ZoneLowerBuffer[i] = 0.0;
      BuySignalBuffer[i] = 0.0;
      SellSignalBuffer[i] = 0.0;
      POCBuffer[i] = 0.0;
      
      //--- calculate volume profile for the period
      VolumeNode volumeProfile[];
      if(!CalculateVolumeProfile(i, InpPeriod, high, low, close, tick_volume, volumeProfile))
         continue;
      
      //--- identify HVN clusters
      int hvnClusters[];
      if(!IdentifyHVNClusters(volumeProfile, hvnClusters))
         continue;
      
      //--- define institutional zone boundaries
      if(!DefineInstitutionalZone(volumeProfile, hvnClusters, i))
         continue;
      
      //--- display zones
      if(InpShowZones && currentZone.upperEdge > 0 && currentZone.lowerEdge > 0)
      {
         ZoneUpperBuffer[i] = currentZone.upperEdge;
         ZoneLowerBuffer[i] = currentZone.lowerEdge;
      }
      
      //--- display POC
      if(InpShowPOC && currentZone.poc > 0)
      {
         POCBuffer[i] = currentZone.poc;
      }
      
      //--- generate signals at zone edges
      if(InpShowSignals && i > 0)
      {
         GenerateSignals(i, time, high, low, close);
      }
   }
   
   //--- update ML filter based on signal outcomes
   if(InpEnableMLFilter && mlHistorySize > 10)
   {
      UpdateMLFilter();
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Calculate Volume Profile                                          |
//+------------------------------------------------------------------+
bool CalculateVolumeProfile(int currentBar, int period, const double &high[], 
                           const double &low[], const double &close[], 
                           const long &tick_volume[], VolumeNode &profile[])
{
   //--- find price range
   double maxPrice = high[currentBar];
   double minPrice = low[currentBar];
   
   for(int i = currentBar; i < currentBar + period && i < ArraySize(high); i++)
   {
      if(high[i] > maxPrice) maxPrice = high[i];
      if(low[i] < minPrice) minPrice = low[i];
   }
   
   if(maxPrice <= minPrice)
      return false;
   
   //--- calculate price row height
   double priceStep = (maxPrice - minPrice) / InpPriceRows;
   if(priceStep <= 0)
      return false;
   
   //--- initialize volume profile array
   ArrayResize(profile, InpPriceRows);
   for(int i = 0; i < InpPriceRows; i++)
   {
      profile[i].price = minPrice + (i + 0.5) * priceStep;
      profile[i].volume = 0;
   }
   
   //--- accumulate volume into price rows
   for(int bar = currentBar; bar < currentBar + period && bar < ArraySize(close); bar++)
   {
      double barHigh = high[bar];
      double barLow = low[bar];
      long barVolume = tick_volume[bar];
      
      //--- distribute volume to affected price rows
      for(int row = 0; row < InpPriceRows; row++)
      {
         double rowLow = minPrice + row * priceStep;
         double rowHigh = minPrice + (row + 1) * priceStep;
         
         //--- check if bar overlaps this row
         if(barHigh >= rowLow && barLow <= rowHigh)
         {
            //--- calculate overlap percentage
            double overlapLow = MathMax(barLow, rowLow);
            double overlapHigh = MathMin(barHigh, rowHigh);
            double overlapPct = (overlapHigh - overlapLow) / (barHigh - barLow + 0.0001);
            
            profile[row].volume += barVolume * overlapPct;
         }
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Identify High Volume Node Clusters                               |
//+------------------------------------------------------------------+
bool IdentifyHVNClusters(const VolumeNode &profile[], int &clusters[])
{
   int profileSize = ArraySize(profile);
   if(profileSize == 0)
      return false;
   
   //--- calculate average volume
   double totalVolume = 0;
   for(int i = 0; i < profileSize; i++)
   {
      totalVolume += profile[i].volume;
   }
   double avgVolume = totalVolume / profileSize;
   
   //--- identify nodes above threshold
   double hvnThreshold = avgVolume * InpHVNThreshold;
   bool isHVN[];
   ArrayResize(isHVN, profileSize);
   
   for(int i = 0; i < profileSize; i++)
   {
      isHVN[i] = (profile[i].volume >= hvnThreshold);
   }
   
   //--- find contiguous clusters
   ArrayResize(clusters, 0);
   int clusterStart = -1;
   int clusterSize = 0;
   
   for(int i = 0; i < profileSize; i++)
   {
      if(isHVN[i])
      {
         if(clusterStart == -1)
         {
            clusterStart = i;
            clusterSize = 1;
         }
         else
         {
            clusterSize++;
         }
      }
      else
      {
         if(clusterStart != -1 && clusterSize >= InpMinClusterSize)
         {
            //--- store cluster start and end
            int idx = ArraySize(clusters);
            ArrayResize(clusters, idx + 2);
            clusters[idx] = clusterStart;
            clusters[idx + 1] = clusterStart + clusterSize - 1;
         }
         clusterStart = -1;
         clusterSize = 0;
      }
   }
   
   //--- check last cluster
   if(clusterStart != -1 && clusterSize >= InpMinClusterSize)
   {
      int idx = ArraySize(clusters);
      ArrayResize(clusters, idx + 2);
      clusters[idx] = clusterStart;
      clusters[idx + 1] = clusterStart + clusterSize - 1;
   }
   
   return(ArraySize(clusters) > 0);
}

//+------------------------------------------------------------------+
//| Define Institutional Zone Boundaries                             |
//+------------------------------------------------------------------+
bool DefineInstitutionalZone(const VolumeNode &profile[], const int &clusters[], int bar)
{
   if(ArraySize(clusters) == 0)
      return false;
   
   //--- find the largest cluster (highest total volume)
   int bestClusterIdx = 0;
   double maxClusterVolume = 0;
   
   for(int i = 0; i < ArraySize(clusters); i += 2)
   {
      int clusterStart = clusters[i];
      int clusterEnd = clusters[i + 1];
      
      double clusterVolume = 0;
      for(int j = clusterStart; j <= clusterEnd; j++)
      {
         clusterVolume += profile[j].volume;
      }
      
      if(clusterVolume > maxClusterVolume)
      {
         maxClusterVolume = clusterVolume;
         bestClusterIdx = i;
      }
   }
   
   //--- get best cluster boundaries
   int clusterStart = clusters[bestClusterIdx];
   int clusterEnd = clusters[bestClusterIdx + 1];
   
   //--- find POC (highest volume node in cluster)
   int pocIdx = clusterStart;
   double maxVolume = profile[clusterStart].volume;
   
   for(int i = clusterStart; i <= clusterEnd; i++)
   {
      if(profile[i].volume > maxVolume)
      {
         maxVolume = profile[i].volume;
         pocIdx = i;
      }
   }
   
   //--- calculate zone boundaries with expansion
   double clusterRange = profile[clusterEnd].price - profile[clusterStart].price;
   double expansion = clusterRange * InpZoneExpansion;
   
   currentZone.lowerEdge = profile[clusterStart].price - expansion;
   currentZone.upperEdge = profile[clusterEnd].price + expansion;
   currentZone.poc = profile[pocIdx].price;
   currentZone.totalVolume = maxClusterVolume;
   currentZone.startBar = bar;
   
   //--- reset touch flags if new zone
   if(bar == 0 || currentZone.startBar != bar)
   {
      currentZone.upperTouched = false;
      currentZone.lowerTouched = false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Generate Entry Signals at Zone Edges                             |
//+------------------------------------------------------------------+
void GenerateSignals(int bar, const datetime &time[], const double &high[], 
                    const double &low[], const double &close[])
{
   if(currentZone.upperEdge == 0 || currentZone.lowerEdge == 0)
      return;
   
   //--- check for price touching lower edge (buy signal)
   if(low[bar] <= currentZone.lowerEdge && close[bar] > currentZone.lowerEdge)
   {
      //--- apply First-Touch principle
      if(!InpFirstTouchOnly || !currentZone.lowerTouched)
      {
         double confidence = CalculateSignalConfidence(bar, 1, time, high, low, close);
         
         //--- apply ML filter
         if(!InpEnableMLFilter || PassesMLFilter(confidence))
         {
            BuySignalBuffer[bar] = low[bar];
            currentZone.lowerTouched = true;
            
            //--- record signal for ML learning
            if(InpEnableMLFilter)
            {
               RecordSignal(time[bar], low[bar], 1, confidence);
            }
         }
      }
   }
   
   //--- check for price touching upper edge (sell signal)
   if(high[bar] >= currentZone.upperEdge && close[bar] < currentZone.upperEdge)
   {
      //--- apply First-Touch principle
      if(!InpFirstTouchOnly || !currentZone.upperTouched)
      {
         double confidence = CalculateSignalConfidence(bar, -1, time, high, low, close);
         
         //--- apply ML filter
         if(!InpEnableMLFilter || PassesMLFilter(confidence))
         {
            SellSignalBuffer[bar] = high[bar];
            currentZone.upperTouched = true;
            
            //--- record signal for ML learning
            if(InpEnableMLFilter)
            {
               RecordSignal(time[bar], high[bar], -1, confidence);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Signal Confidence                                       |
//+------------------------------------------------------------------+
double CalculateSignalConfidence(int bar, int signalType, const datetime &time[],
                                const double &high[], const double &low[], 
                                const double &close[])
{
   double confidence = 0.5;  // base confidence
   
   //--- factor 1: distance from POC (closer = higher confidence)
   double currentPrice = (signalType == 1) ? low[bar] : high[bar];
   double distanceFromPOC = MathAbs(currentPrice - currentZone.poc);
   double zoneRange = currentZone.upperEdge - currentZone.lowerEdge;
   double pocFactor = 1.0 - (distanceFromPOC / (zoneRange + 0.0001));
   confidence += pocFactor * 0.2;
   
   //--- factor 2: volume at zone (higher = higher confidence)
   double volumeFactor = MathMin(currentZone.totalVolume / 1000.0, 1.0);
   confidence += volumeFactor * 0.15;
   
   //--- factor 3: rejection candle pattern
   if(bar < ArraySize(close) - 1)
   {
      double bodySize = MathAbs(close[bar] - close[bar + 1]);
      double wickSize = (signalType == 1) ? 
         (close[bar] - low[bar]) : (high[bar] - close[bar]);
      
      if(wickSize > bodySize * 1.5)
         confidence += 0.15;  // strong rejection wick
   }
   
   //--- normalize confidence to 0-1 range
   confidence = MathMax(0.0, MathMin(1.0, confidence));
   
   return confidence;
}

//+------------------------------------------------------------------+
//| ML Filter: Check if Signal Passes Adaptive Threshold             |
//+------------------------------------------------------------------+
bool PassesMLFilter(double confidence)
{
   return(confidence >= mlAdaptiveSensitivity);
}

//+------------------------------------------------------------------+
//| Record Signal for ML Learning                                     |
//+------------------------------------------------------------------+
void RecordSignal(datetime signalTime, double signalPrice, int signalType, double confidence)
{
   //--- shift array if full
   if(mlHistorySize >= InpMLLearningPeriod)
   {
      for(int i = InpMLLearningPeriod - 1; i > 0; i--)
      {
         mlHistory[i] = mlHistory[i - 1];
      }
      mlHistorySize = InpMLLearningPeriod;
   }
   
   //--- add new signal
   mlHistory[mlHistorySize].time = signalTime;
   mlHistory[mlHistorySize].price = signalPrice;
   mlHistory[mlHistorySize].signalType = signalType;
   mlHistory[mlHistorySize].confidence = confidence;
   mlHistory[mlHistorySize].wasSuccessful = false;  // will be evaluated later
   
   mlHistorySize++;
}

//+------------------------------------------------------------------+
//| Update ML Filter Based on Historical Performance                 |
//+------------------------------------------------------------------+
void UpdateMLFilter()
{
   //--- evaluate recent signals
   int successCount = 0;
   int totalEvaluated = 0;
   
   for(int i = 0; i < mlHistorySize; i++)
   {
      //--- check if signal is old enough to evaluate
      datetime currentTime = TimeCurrent();
      int barsSince = (int)((currentTime - mlHistory[i].time) / PeriodSeconds());
      
      if(barsSince > InpSignalExpiry && barsSince < InpMLLearningPeriod)
      {
         //--- evaluate success (simple check: price moved in signal direction)
         double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         bool success = false;
         
         if(mlHistory[i].signalType == 1)  // buy signal
         {
            success = (currentPrice > mlHistory[i].price);
         }
         else  // sell signal
         {
            success = (currentPrice < mlHistory[i].price);
         }
         
         mlHistory[i].wasSuccessful = success;
         if(success) successCount++;
         totalEvaluated++;
      }
   }
   
   //--- adjust sensitivity based on success rate
   if(totalEvaluated > 20)
   {
      double successRate = (double)successCount / totalEvaluated;
      
      //--- increase sensitivity if success rate is high (accept more signals)
      if(successRate > 0.65)
      {
         mlAdaptiveSensitivity = MathMax(0.2, mlAdaptiveSensitivity - 0.01);
      }
      //--- decrease sensitivity if success rate is low (be more selective)
      else if(successRate < 0.45)
      {
         mlAdaptiveSensitivity = MathMin(0.9, mlAdaptiveSensitivity + 0.01);
      }
   }
   
   //--- ensure sensitivity stays within bounds
   mlAdaptiveSensitivity = MathMax(0.1, MathMin(0.95, mlAdaptiveSensitivity));
}

//+------------------------------------------------------------------+
//| Timer function                                                    |
//+------------------------------------------------------------------+
void OnTimer()
{
   //--- update ML filter periodically
   if(InpEnableMLFilter)
   {
      UpdateMLFilter();
   }
}
