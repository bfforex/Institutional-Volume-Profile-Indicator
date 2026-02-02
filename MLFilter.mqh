//+------------------------------------------------------------------+
//|                                                     MLFilter.mqh |
//|                                   Machine Learning Signal Filter |
//|                          Adaptive false signal detection system  |
//+------------------------------------------------------------------+
#property copyright "Institutional Volume Profile ML System"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| ML Feature Vector Structure                                      |
//+------------------------------------------------------------------+
struct MLFeatures
{
   double distance_to_poc;        // X1: Distance from entry to POC
   double distance_to_edge;       // X2: Distance to zone boundary
   double volume_delta;           // X3: Buy-sell volume imbalance
   double rejection_ratio;        // X4: Wick to body ratio
   double atr_normalized_vol;     // X5: ATR-normalized volatility
   double trend_slope;            // X6: Higher timeframe trend
   double time_since_break;       // X7: Bars since zone break
   double lvn_proximity;          // X8: Distance to nearest LVN
   
   int    signal_type;            // 1=Long, -1=Short
   double entry_price;
   datetime entry_time;
   
   // Trade outcome (for learning)
   int    outcome;                // 1=success, 0=failure, -1=pending
   double actual_rr;              // Actual risk-reward achieved
};

//+------------------------------------------------------------------+
//| Logistic Regression Classifier (Online Learning)                 |
//+------------------------------------------------------------------+
class CMLFilter
{
private:
   // Model parameters
   double m_weights[8];           // Weight vector for 8 features
   double m_bias;                 // Bias term
   double m_learning_rate;        // SGD learning rate
   double m_confidence_threshold; // Minimum confidence to accept signal
   
   // Performance tracking
   int    m_total_signals;
   int    m_accepted_signals;
   int    m_successful_trades;
   int    m_failed_trades;
   
   // History storage
   MLFeatures m_history[];
   int    m_history_size;
   int    m_max_history;
   
   // File handling
   string m_history_file;
   int    m_file_handle;
   
   // Normalization parameters (for feature scaling)
   double m_feature_min[8];
   double m_feature_max[8];
   
public:
   CMLFilter();
   ~CMLFilter();
   
   bool Initialize(double learning_rate, double confidence_threshold, string symbol);
   void Deinitialize();
   
   // Core ML functions
   bool EvaluateSignal(MLFeatures &features, double &confidence);
   void UpdateModel(MLFeatures &features, int outcome);
   double PredictProbability(MLFeatures &features);
   
   // Feature engineering
   void NormalizeFeatures(MLFeatures &features);
   double CalculateConfidence(double probability);
   
   // History management
   bool SaveHistory();
   bool LoadHistory();
   void AddToHistory(MLFeatures &features);
   
   // Performance metrics
   double GetAccuracy();
   double GetPrecision();
   int GetTotalSignals() { return m_total_signals; }
   int GetAcceptedSignals() { return m_accepted_signals; }
   
   // Adaptive sensitivity
   void AdjustSensitivity();
   
private:
   // Helper functions
   double Sigmoid(double x);
   double DotProduct(double weights[], MLFeatures &features);
   void InitializeWeights();
   void UpdateNormalizationParams(MLFeatures &features);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CMLFilter::CMLFilter()
{
   m_learning_rate = 0.01;
   m_confidence_threshold = 0.65;
   m_bias = 0.0;
   m_total_signals = 0;
   m_accepted_signals = 0;
   m_successful_trades = 0;
   m_failed_trades = 0;
   m_history_size = 0;
   m_max_history = 1000;
   
   InitializeWeights();
   
   // Initialize normalization parameters
   for(int i = 0; i < 8; i++)
   {
      m_feature_min[i] = 1e10;
      m_feature_max[i] = -1e10;
   }
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CMLFilter::~CMLFilter()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize ML Filter                                             |
//+------------------------------------------------------------------+
bool CMLFilter::Initialize(double learning_rate, double confidence_threshold, string symbol)
{
   m_learning_rate = learning_rate;
   m_confidence_threshold = confidence_threshold;
   m_history_file = "ML_History_" + symbol + ".csv";
   
   // Load previous learning history
   if(!LoadHistory())
   {
      Print("ML Filter: Starting with fresh model (no history found)");
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize and save state                                      |
//+------------------------------------------------------------------+
void CMLFilter::Deinitialize()
{
   SaveHistory();
}

//+------------------------------------------------------------------+
//| Initialize weights with small random values                      |
//+------------------------------------------------------------------+
void CMLFilter::InitializeWeights()
{
   MathSrand((int)TimeLocal());
   for(int i = 0; i < 8; i++)
   {
      m_weights[i] = (MathRand() / 32768.0 - 0.5) * 0.01; // Small random values
   }
   m_bias = 0.0;
}

//+------------------------------------------------------------------+
//| Sigmoid activation function                                      |
//+------------------------------------------------------------------+
double CMLFilter::Sigmoid(double x)
{
   // Prevent overflow
   if(x > 20.0) return 1.0;
   if(x < -20.0) return 0.0;
   return 1.0 / (1.0 + MathExp(-x));
}

//+------------------------------------------------------------------+
//| Calculate dot product of weights and features                    |
//+------------------------------------------------------------------+
double CMLFilter::DotProduct(double weights[], MLFeatures &features)
{
   double sum = m_bias;
   
   sum += weights[0] * features.distance_to_poc;
   sum += weights[1] * features.distance_to_edge;
   sum += weights[2] * features.volume_delta;
   sum += weights[3] * features.rejection_ratio;
   sum += weights[4] * features.atr_normalized_vol;
   sum += weights[5] * features.trend_slope;
   sum += weights[6] * features.time_since_break;
   sum += weights[7] * features.lvn_proximity;
   
   return sum;
}

//+------------------------------------------------------------------+
//| Normalize features to [0, 1] range                               |
//+------------------------------------------------------------------+
void CMLFilter::NormalizeFeatures(MLFeatures &features)
{
   UpdateNormalizationParams(features);
   
   // Create array of feature values for normalization
   double raw_features[8];
   raw_features[0] = features.distance_to_poc;
   raw_features[1] = features.distance_to_edge;
   raw_features[2] = features.volume_delta;
   raw_features[3] = features.rejection_ratio;
   raw_features[4] = features.atr_normalized_vol;
   raw_features[5] = features.trend_slope;
   raw_features[6] = features.time_since_break;
   raw_features[7] = features.lvn_proximity;
   
   // Normalize each feature
   for(int i = 0; i < 8; i++)
   {
      double range = m_feature_max[i] - m_feature_min[i];
      if(range > 0.0001) // Avoid division by zero
      {
         raw_features[i] = (raw_features[i] - m_feature_min[i]) / range;
      }
      else
      {
         raw_features[i] = 0.5; // Default to middle value
      }
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
}

//+------------------------------------------------------------------+
//| Update normalization parameters                                  |
//+------------------------------------------------------------------+
void CMLFilter::UpdateNormalizationParams(MLFeatures &features)
{
   double raw_features[8];
   raw_features[0] = features.distance_to_poc;
   raw_features[1] = features.distance_to_edge;
   raw_features[2] = features.volume_delta;
   raw_features[3] = features.rejection_ratio;
   raw_features[4] = features.atr_normalized_vol;
   raw_features[5] = features.trend_slope;
   raw_features[6] = features.time_since_break;
   raw_features[7] = features.lvn_proximity;
   
   for(int i = 0; i < 8; i++)
   {
      if(raw_features[i] < m_feature_min[i])
         m_feature_min[i] = raw_features[i];
      if(raw_features[i] > m_feature_max[i])
         m_feature_max[i] = raw_features[i];
   }
}

//+------------------------------------------------------------------+
//| Predict probability of signal success                            |
//+------------------------------------------------------------------+
double CMLFilter::PredictProbability(MLFeatures &features)
{
   NormalizeFeatures(features);
   double z = DotProduct(m_weights, features);
   return Sigmoid(z);
}

//+------------------------------------------------------------------+
//| Calculate confidence score                                       |
//+------------------------------------------------------------------+
double CMLFilter::CalculateConfidence(double probability)
{
   // Confidence is how far the probability is from 0.5 (uncertain)
   return MathAbs(probability - 0.5) * 2.0;
}

//+------------------------------------------------------------------+
//| Evaluate if signal should be accepted                            |
//+------------------------------------------------------------------+
bool CMLFilter::EvaluateSignal(MLFeatures &features, double &confidence)
{
   m_total_signals++;
   
   // Predict probability of success
   double probability = PredictProbability(features);
   confidence = CalculateConfidence(probability);
   
   // Decision: accept if confidence is high enough
   bool accept = (confidence >= m_confidence_threshold);
   
   if(accept)
   {
      m_accepted_signals++;
      features.outcome = -1; // Pending (outcome unknown)
      AddToHistory(features);
   }
   
   return accept;
}

//+------------------------------------------------------------------+
//| Update model with trade outcome (online learning)                |
//+------------------------------------------------------------------+
void CMLFilter::UpdateModel(MLFeatures &features, int outcome)
{
   // Update trade statistics
   if(outcome == 1)
      m_successful_trades++;
   else if(outcome == 0)
      m_failed_trades++;
   
   // Normalize features
   NormalizeFeatures(features);
   
   // Calculate prediction
   double z = DotProduct(m_weights, features);
   double prediction = Sigmoid(z);
   
   // Calculate error (gradient)
   double error = (double)outcome - prediction;
   
   // Update weights using stochastic gradient descent
   double feature_array[8];
   feature_array[0] = features.distance_to_poc;
   feature_array[1] = features.distance_to_edge;
   feature_array[2] = features.volume_delta;
   feature_array[3] = features.rejection_ratio;
   feature_array[4] = features.atr_normalized_vol;
   feature_array[5] = features.trend_slope;
   feature_array[6] = features.time_since_break;
   feature_array[7] = features.lvn_proximity;
   
   for(int i = 0; i < 8; i++)
   {
      m_weights[i] += m_learning_rate * error * feature_array[i];
   }
   
   m_bias += m_learning_rate * error;
   
   // Update history
   for(int i = 0; i < m_history_size; i++)
   {
      if(m_history[i].entry_time == features.entry_time &&
         m_history[i].entry_price == features.entry_price)
      {
         m_history[i].outcome = outcome;
         m_history[i].actual_rr = features.actual_rr;
         break;
      }
   }
   
   // Adaptive sensitivity adjustment
   AdjustSensitivity();
}

//+------------------------------------------------------------------+
//| Adjust sensitivity based on performance                          |
//+------------------------------------------------------------------+
void CMLFilter::AdjustSensitivity()
{
   if(m_accepted_signals < 10) return; // Need minimum data
   
   double accuracy = GetAccuracy();
   
   // If accuracy is low, increase threshold (be more selective)
   if(accuracy < 0.40 && m_confidence_threshold < 0.85)
   {
      m_confidence_threshold += 0.02;
      Print("ML Filter: Increasing threshold to ", m_confidence_threshold, " (accuracy: ", accuracy, ")");
   }
   // If accuracy is high, decrease threshold (accept more signals)
   else if(accuracy > 0.65 && m_confidence_threshold > 0.50)
   {
      m_confidence_threshold -= 0.01;
      Print("ML Filter: Decreasing threshold to ", m_confidence_threshold, " (accuracy: ", accuracy, ")");
   }
}

//+------------------------------------------------------------------+
//| Add features to history                                          |
//+------------------------------------------------------------------+
void CMLFilter::AddToHistory(MLFeatures &features)
{
   if(m_history_size >= m_max_history)
   {
      // Remove oldest entry (FIFO)
      for(int i = 0; i < m_history_size - 1; i++)
      {
         m_history[i] = m_history[i + 1];
      }
      m_history_size--;
   }
   
   ArrayResize(m_history, m_history_size + 1);
   m_history[m_history_size] = features;
   m_history_size++;
}

//+------------------------------------------------------------------+
//| Calculate accuracy                                               |
//+------------------------------------------------------------------+
double CMLFilter::GetAccuracy()
{
   int total = m_successful_trades + m_failed_trades;
   if(total == 0) return 0.5; // No data yet
   
   return (double)m_successful_trades / (double)total;
}

//+------------------------------------------------------------------+
//| Calculate precision                                              |
//+------------------------------------------------------------------+
double CMLFilter::GetPrecision()
{
   if(m_accepted_signals == 0) return 0.0;
   return (double)m_successful_trades / (double)m_accepted_signals;
}

//+------------------------------------------------------------------+
//| Save history to CSV file                                         |
//+------------------------------------------------------------------+
bool CMLFilter::SaveHistory()
{
   m_file_handle = FileOpen(m_history_file, FILE_WRITE | FILE_CSV | FILE_COMMON);
   
   if(m_file_handle == INVALID_HANDLE)
   {
      Print("ML Filter: Failed to save history file");
      return false;
   }
   
   // Write header
   FileWrite(m_file_handle, "EntryTime", "EntryPrice", "SignalType", 
             "DistPOC", "DistEdge", "VolDelta", "RejRatio", "ATRVol", 
             "TrendSlope", "TimeSinceBreak", "LVNProx", "Outcome", "ActualRR");
   
   // Write data
   for(int i = 0; i < m_history_size; i++)
   {
      FileWrite(m_file_handle, 
                TimeToString(m_history[i].entry_time),
                DoubleToString(m_history[i].entry_price, 5),
                IntegerToString(m_history[i].signal_type),
                DoubleToString(m_history[i].distance_to_poc, 5),
                DoubleToString(m_history[i].distance_to_edge, 5),
                DoubleToString(m_history[i].volume_delta, 2),
                DoubleToString(m_history[i].rejection_ratio, 3),
                DoubleToString(m_history[i].atr_normalized_vol, 3),
                DoubleToString(m_history[i].trend_slope, 5),
                DoubleToString(m_history[i].time_since_break, 1),
                DoubleToString(m_history[i].lvn_proximity, 5),
                IntegerToString(m_history[i].outcome),
                DoubleToString(m_history[i].actual_rr, 2));
   }
   
   // Write model parameters
   FileWrite(m_file_handle, "--- Model Parameters ---");
   FileWrite(m_file_handle, "Weights", m_weights[0], m_weights[1], m_weights[2], 
             m_weights[3], m_weights[4], m_weights[5], m_weights[6], m_weights[7]);
   FileWrite(m_file_handle, "Bias", m_bias);
   FileWrite(m_file_handle, "Threshold", m_confidence_threshold);
   FileWrite(m_file_handle, "Accuracy", GetAccuracy());
   
   FileClose(m_file_handle);
   return true;
}

//+------------------------------------------------------------------+
//| Load history from CSV file                                       |
//+------------------------------------------------------------------+
bool CMLFilter::LoadHistory()
{
   m_file_handle = FileOpen(m_history_file, FILE_READ | FILE_CSV | FILE_COMMON);
   
   if(m_file_handle == INVALID_HANDLE)
   {
      return false; // No history file exists yet
   }
   
   // Skip header
   string line = FileReadString(m_file_handle);
   
   m_history_size = 0;
   ArrayResize(m_history, 0);
   
   // Read data
   while(!FileIsEnding(m_file_handle))
   {
      line = FileReadString(m_file_handle);
      
      // Check for model parameters section
      if(StringFind(line, "Model Parameters") >= 0)
      {
         // Read weights
         if(!FileIsEnding(m_file_handle))
         {
            FileReadString(m_file_handle); // "Weights" label
            for(int i = 0; i < 8; i++)
            {
               m_weights[i] = StringToDouble(FileReadString(m_file_handle));
            }
         }
         
         // Read bias
         if(!FileIsEnding(m_file_handle))
         {
            FileReadString(m_file_handle); // "Bias" label
            m_bias = StringToDouble(FileReadString(m_file_handle));
         }
         
         // Read threshold
         if(!FileIsEnding(m_file_handle))
         {
            FileReadString(m_file_handle); // "Threshold" label
            m_confidence_threshold = StringToDouble(FileReadString(m_file_handle));
         }
         
         break;
      }
      
      // Parse feature data (simplified - would need full CSV parsing)
      ArrayResize(m_history, m_history_size + 1);
      m_history_size++;
   }
   
   FileClose(m_file_handle);
   Print("ML Filter: Loaded ", m_history_size, " historical records");
   return true;
}
//+------------------------------------------------------------------+
