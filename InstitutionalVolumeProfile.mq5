//+------------------------------------------------------------------+
//|                                 InstitutionalVolumeProfile.mq5   |
//|                          Advanced ML-Enhanced Volume Profile      |
//|                  Institutional Zone Detection & Signal System     |
//+------------------------------------------------------------------+
#property copyright "Institutional Trading Systems"
#property link      ""
#property version   "2.00"
#property description "Volume Profile with Institutional Zone Detection"
#property description "Advanced ML-Enhanced Signal Filtering (18 features)"
#property description "Market Regime Detection + MTF Confluence"
#property description "Neural Network + Logistic Regression Ensemble"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   2

// Include all modules
#include "VolumeProfileEngine.mqh"
#include "InstitutionalZoneDetector.mqh"
#include "SignalEngine.mqh"
#include "EnsembleML.mqh"
#include "Visualizer.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+

// === Calculation Mode ===
input group "===== Volume Profile Settings ====="
input ENUM_CALC_MODE InpCalculationMode = SESSION_DAILY;  // Calculation Mode
input int InpLookbackBars = 100;                          // Lookback Bars (for Fixed/Anchored)
input double InpPriceStepMultiplier = 10.0;               // Price Step Multiplier
input double InpValueAreaPercent = 70.0;                  // Value Area Percentage

// === Zone Detection ===
input group "===== Institutional Zone Settings ====="
input double InpZoneSensitivity = 0.70;                   // Zone Sensitivity (HVN Threshold)

// === Signal Settings ===
input group "===== Signal Generation ====="
input ENUM_SIGNAL_MODE InpSignalMode = ON_CANDLE_CLOSE;   // Signal Trigger Mode
input bool InpShowArrows = true;                          // Show Signal Arrows
input bool InpEnableAlerts = true;                        // Enable Alerts
input bool InpEnablePushNotifications = false;            // Enable Push Notifications

// === ML Filter Settings ===
input group "===== Machine Learning Filter ====="
input bool InpMLEnabled = true;                           // Enable ML Filter
input double InpMLConfidenceThreshold = 0.65;             // ML Confidence Threshold
input double InpLRLearningRate = 0.01;                    // LR Learning Rate
input double InpNNLearningRate = 0.001;                   // NN Learning Rate
input double InpEnsembleWeightLR = 0.3;                   // Ensemble Weight: LR
input double InpEnsembleWeightNN = 0.7;                   // Ensemble Weight: NN

// === Advanced Features ===
input group "===== Advanced ML Features ====="
input bool InpEnableRegimeDetection = true;               // Enable Market Regime Detection
input bool InpEnableMTFAnalysis = true;                   // Enable MTF Confluence
input double InpMTFConfluenceThreshold = 0.4;             // Min MTF Confluence Score

// === Visual Settings ===
input group "===== Visual Settings ====="
input color InpPOCColor = clrRed;                         // POC Color
input color InpVAHColor = clrDarkGreen;                   // VAH Color
input color InpVALColor = clrDarkGreen;                   // VAL Color
input color InpZoneUpperColor = clrCrimson;               // Zone Upper Boundary
input color InpZoneLowerColor = clrDodgerBlue;            // Zone Lower Boundary
input color InpBuyVolumeColor = clrDodgerBlue;            // Buy Volume
input color InpSellVolumeColor = clrGold;                 // Sell Volume
input color InpLongArrowColor = clrLime;                  // Long Arrow
input color InpShortArrowColor = clrRed;                  // Short Arrow
input bool InpShowHistogram = true;                       // Show Volume Histogram
input bool InpShowValueArea = true;                       // Show Value Area
input bool InpShowLVN = true;                             // Show LVN Markers

//+------------------------------------------------------------------+
//| Indicator Buffers                                                |
//+------------------------------------------------------------------+
double LongSignalBuffer[];
double ShortSignalBuffer[];
double POCBuffer[];
double ConfidenceBuffer[];

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
CVolumeProfileEngine* g_vpEngine;
CInstitutionalZoneDetector* g_zoneDetector;
CSignalEngine* g_signalEngine;
CEnsembleML* g_ensembleML;
CVolumeProfileVisualizer* g_visualizer;

datetime g_lastCalculationTime = 0;
datetime g_lastSignalTime = 0;
bool g_initialized = false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== Institutional Volume Profile Initializing ===");
   
   // Set indicator buffers
   SetIndexBuffer(0, LongSignalBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ShortSignalBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, POCBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, ConfidenceBuffer, INDICATOR_DATA);
   
   // Set buffer properties
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_ARROW);
   PlotIndexSetInteger(0, PLOT_ARROW, 233);  // Up arrow
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, InpLongArrowColor);
   PlotIndexSetString(0, PLOT_LABEL, "Long Signal");
   
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_ARROW);
   PlotIndexSetInteger(1, PLOT_ARROW, 234);  // Down arrow
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, InpShortArrowColor);
   PlotIndexSetString(1, PLOT_LABEL, "Short Signal");
   
   // Initialize arrays
   ArraySetAsSeries(LongSignalBuffer, true);
   ArraySetAsSeries(ShortSignalBuffer, true);
   ArraySetAsSeries(POCBuffer, true);
   ArraySetAsSeries(ConfidenceBuffer, true);
   
   // Initialize arrays with EMPTY_VALUE
   ArrayInitialize(LongSignalBuffer, EMPTY_VALUE);
   ArrayInitialize(ShortSignalBuffer, EMPTY_VALUE);
   ArrayInitialize(POCBuffer, EMPTY_VALUE);
   ArrayInitialize(ConfidenceBuffer, 0);
   
   // Create engine instances
   g_vpEngine = new CVolumeProfileEngine();
   g_zoneDetector = new CInstitutionalZoneDetector();
   g_signalEngine = new CSignalEngine();
   g_ensembleML = new CEnsembleML();
   g_visualizer = new CVolumeProfileVisualizer();
   
   // Check allocation
   if(g_vpEngine == NULL || g_zoneDetector == NULL || g_signalEngine == NULL || 
      g_ensembleML == NULL || g_visualizer == NULL)
   {
      Print("ERROR: Failed to allocate engine objects");
      return INIT_FAILED;
   }
   
   // Initialize Volume Profile Engine
   double price_step = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * InpPriceStepMultiplier;
   if(!g_vpEngine.Initialize(_Symbol, PERIOD_CURRENT, InpCalculationMode, 
                             price_step, InpValueAreaPercent / 100.0))
   {
      Print("ERROR: Failed to initialize Volume Profile Engine");
      return INIT_FAILED;
   }
   
   g_vpEngine.SetLookbackBars(InpLookbackBars);
   
   // Initialize Ensemble ML Filter
   if(InpMLEnabled)
   {
      if(!g_ensembleML.Initialize(InpLRLearningRate, InpNNLearningRate, 
                                  InpMLConfidenceThreshold, _Symbol))
      {
         Print("WARNING: Ensemble ML initialization failed - continuing without ML");
      }
      else
      {
         g_ensembleML.SetEnsembleWeights(InpEnsembleWeightLR, InpEnsembleWeightNN);
         Print("=== Ensemble ML initialized successfully ===");
         Print("LR Weight: ", InpEnsembleWeightLR, " NN Weight: ", InpEnsembleWeightNN);
      }
   }
   
   // Initialize Zone Detector
   if(!g_zoneDetector.Initialize(g_vpEngine, InpZoneSensitivity))
   {
      Print("ERROR: Failed to initialize Zone Detector");
      return INIT_FAILED;
   }
   
   // Initialize Signal Engine
   if(!g_signalEngine.Initialize(g_zoneDetector, g_ensembleML, InpSignalMode, 
                                 InpMLEnabled, InpEnableRegimeDetection, InpEnableMTFAnalysis))
   {
      Print("ERROR: Failed to initialize Signal Engine");
      return INIT_FAILED;
   }
   
   // Initialize Visualizer
   if(!g_visualizer.Initialize(g_vpEngine, g_zoneDetector))
   {
      Print("ERROR: Failed to initialize Visualizer");
      return INIT_FAILED;
   }
   
   // Set custom colors
   g_visualizer.SetColors(InpPOCColor, InpVAHColor, InpVALColor, 
                          InpZoneUpperColor, InpZoneLowerColor,
                          InpBuyVolumeColor, InpSellVolumeColor,
                          InpLongArrowColor, InpShortArrowColor);
   
   // Set indicator name
   string indicator_name = "Institutional Volume Profile [" + 
                          EnumToString(InpCalculationMode) + "]";
   if(InpMLEnabled)
      indicator_name += " + ML";
   
   IndicatorSetString(INDICATOR_SHORTNAME, indicator_name);
   
   Print("=== Initialization Complete ===");
   Print("Calculation Mode: ", EnumToString(InpCalculationMode));
   Print("Zone Sensitivity: ", InpZoneSensitivity);
   Print("ML Filter: ", InpMLEnabled ? "ENABLED" : "DISABLED");
   if(InpMLEnabled)
      Print("ML Confidence Threshold: ", InpMLConfidenceThreshold);
   
   g_initialized = true;
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("=== Institutional Volume Profile Deinitializing ===");
   
   // Clean up visual objects
   if(g_visualizer != NULL)
   {
      g_visualizer.ClearAll();
      delete g_visualizer;
      g_visualizer = NULL;
   }
   
   // Save ML state before deletion
   if(g_ensembleML != NULL)
   {
      g_ensembleML.Deinitialize();
      delete g_ensembleML;
      g_ensembleML = NULL;
   }
   
   // Delete other objects
   if(g_signalEngine != NULL)
   {
      delete g_signalEngine;
      g_signalEngine = NULL;
   }
   
   if(g_zoneDetector != NULL)
   {
      delete g_zoneDetector;
      g_zoneDetector = NULL;
   }
   
   if(g_vpEngine != NULL)
   {
      delete g_vpEngine;
      g_vpEngine = NULL;
   }
   
   Print("Deinitialization complete. Reason: ", reason);
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
   if(!g_initialized)
      return 0;
   
   // Check if we need to recalculate (new bar or session change)
   datetime current_time = time[rates_total - 1];
   bool should_recalculate = false;
   
   // Check for new bar
   if(current_time != g_lastCalculationTime)
   {
      should_recalculate = true;
      g_lastCalculationTime = current_time;
   }
   
   // Recalculate volume profile
   if(should_recalculate || prev_calculated == 0)
   {
      if(!g_vpEngine.CalculateProfile())
      {
         Print("WARNING: Volume Profile calculation failed");
         return prev_calculated;
      }
      
      // Detect institutional zones
      if(!g_zoneDetector.DetectZones())
      {
         Print("WARNING: Zone detection failed");
         return prev_calculated;
      }
      
      // Update visualization
      g_visualizer.ClearAll();
      g_visualizer.DrawAll();
      
      // Update POC buffer
      double poc = g_vpEngine.GetPOC();
      for(int i = 0; i < rates_total; i++)
      {
         POCBuffer[i] = poc;
      }
   }
   
   // Check for trading signals on every tick (or bar close depending on mode)
   TradingSignal signal;
   if(g_signalEngine.CheckForSignal(signal))
   {
      // Avoid duplicate signals
      if(signal.signal_time != g_lastSignalTime)
      {
         g_lastSignalTime = signal.signal_time;
         
         // Update buffers
         int signal_bar = iBarShift(_Symbol, PERIOD_CURRENT, signal.signal_time);
         
         if(signal.signal_type == 1) // Long
         {
            LongSignalBuffer[signal_bar] = signal.entry_price;
            ConfidenceBuffer[signal_bar] = signal.confidence;
         }
         else if(signal.signal_type == -1) // Short
         {
            ShortSignalBuffer[signal_bar] = signal.entry_price;
            ConfidenceBuffer[signal_bar] = signal.confidence;
         }
         
         // Draw signal arrow
         if(InpShowArrows)
            g_visualizer.DrawSignalArrow(signal);
         
         // Trigger alerts
         if(InpEnableAlerts)
         {
            string alert_message = "Institutional VP Signal: " + 
                                  (signal.signal_type == 1 ? "LONG" : "SHORT") + 
                                  " at " + DoubleToString(signal.entry_price, _Digits) +
                                  " | Confidence: " + DoubleToString(signal.confidence * 100, 1) + "%";
            
            Alert(alert_message);
            
            if(InpEnablePushNotifications)
               SendNotification(alert_message);
         }
         
         // Log signal details
         Print("=== NEW SIGNAL ===");
         Print("Type: ", signal.signal_type == 1 ? "LONG" : "SHORT");
         Print("Entry: ", signal.entry_price);
         Print("Stop Loss: ", signal.stop_loss);
         Print("Take Profit: ", signal.take_profit);
         Print("Confidence: ", signal.confidence * 100, "%");
         Print("ML Approved: ", signal.ml_approved ? "YES" : "NO");
         Print("First Touch: ", signal.is_first_touch ? "YES" : "NO");
         Print("Reason: ", signal.signal_reason);
         
         // Display ML statistics
         if(InpMLEnabled && g_ensembleML != NULL)
         {
            Print("=== ML Statistics ===");
             Print("=== Ensemble ML Statistics ===");
             Print("Total Predictions: ", g_ensembleML.GetTotalPredictions());
             Print("Successful: ", g_ensembleML.GetSuccessfulPredictions());
             Print("Accuracy: ", g_ensembleML.GetAccuracy() * 100, "%");
         }
      }
   }
   
   return rates_total;
}

//+------------------------------------------------------------------+
//| Chart event handler (for manual trade outcome updates)           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // Could be extended to handle manual trade outcome feedback
   // For example, user clicks on a signal arrow to mark it as success/failure
}

//+------------------------------------------------------------------+
//| Timer function (optional - for periodic ML updates)              |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Could be used for periodic ML model saving or retraining
}
//+------------------------------------------------------------------+
