//+------------------------------------------------------------------+
//|                                                 EnsembleML.mqh    |
//|                   Ensemble ML combining LR + Neural Network       |
//+------------------------------------------------------------------+
#property copyright "Institutional Volume Profile ML System"
#property link      ""
#property version   "2.00"
#property strict

#include "MLFilter.mqh"
#include "NeuralNetwork.mqh"

//+------------------------------------------------------------------+
//| Ensemble ML Class                                                |
//+------------------------------------------------------------------+
class CEnsembleML
{
private:
   CMLFilter* m_logistic_regression;
   CNeuralNetwork* m_neural_network;
   
   // Ensemble weights
   double m_lr_weight;
   double m_nn_weight;
   
   // Performance tracking
   int m_total_predictions;
   int m_successful_predictions;
   
   // Model selection flags
   bool m_use_lr;
   bool m_use_nn;
   bool m_ensemble_mode;
   
   // Confidence thresholds
   double m_confidence_threshold;
   
public:
   CEnsembleML();
   ~CEnsembleML();
   
   bool Initialize(double lr_learning_rate, double nn_learning_rate,
                   double confidence_threshold, string symbol);
   void Deinitialize();
   
   // Core prediction functions
   bool EvaluateSignal(ExtendedMLFeatures &features, double &confidence);
   double PredictProbability(ExtendedMLFeatures &features);
   
   // Training
   void UpdateModels(ExtendedMLFeatures &features, int outcome);
   
   // Configuration
   void SetEnsembleWeights(double lr_weight, double nn_weight);
   void SetModelMode(bool use_lr, bool use_nn, bool ensemble);
   
   // Performance metrics
   double GetAccuracy();
   int GetTotalPredictions() { return m_total_predictions; }
   int GetSuccessfulPredictions() { return m_successful_predictions; }
   
   // Model access
   CMLFilter* GetLRModel() { return m_logistic_regression; }
   CNeuralNetwork* GetNNModel() { return m_neural_network; }
   
private:
   double CalculateEnsembleProbability(double lr_prob, double nn_prob);
   double CalculateConfidence(double probability);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CEnsembleML::CEnsembleML()
{
   m_logistic_regression = NULL;
   m_neural_network = NULL;
   
   // Default ensemble weights: 30% LR, 70% NN
   m_lr_weight = 0.3;
   m_nn_weight = 0.7;
   
   m_total_predictions = 0;
   m_successful_predictions = 0;
   
   // Default: use ensemble mode
   m_use_lr = true;
   m_use_nn = true;
   m_ensemble_mode = true;
   
   m_confidence_threshold = 0.65;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CEnsembleML::~CEnsembleML()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize ensemble models                                       |
//+------------------------------------------------------------------+
bool CEnsembleML::Initialize(double lr_learning_rate, double nn_learning_rate,
                             double confidence_threshold, string symbol)
{
   m_confidence_threshold = confidence_threshold;
   
   // Initialize Logistic Regression
   m_logistic_regression = new CMLFilter();
   if(m_logistic_regression == NULL)
   {
      Print("Error: Failed to create Logistic Regression model");
      return false;
   }
   
   if(!m_logistic_regression.Initialize(lr_learning_rate, confidence_threshold, symbol))
   {
      Print("Error: Failed to initialize Logistic Regression model");
      delete m_logistic_regression;
      m_logistic_regression = NULL;
      return false;
   }
   
   // Initialize Neural Network
   m_neural_network = new CNeuralNetwork();
   if(m_neural_network == NULL)
   {
      Print("Error: Failed to create Neural Network model");
      return false;
   }
   
   if(!m_neural_network.Initialize(nn_learning_rate, 0.9))
   {
      Print("Error: Failed to initialize Neural Network model");
      delete m_neural_network;
      m_neural_network = NULL;
      return false;
   }
   
   Print("=== Ensemble ML Initialized ===");
   Print("Logistic Regression: ", (m_logistic_regression != NULL) ? "OK" : "FAILED");
   Print("Neural Network: ", (m_neural_network != NULL) ? "OK" : "FAILED");
   Print("Ensemble weights: LR=", m_lr_weight, " NN=", m_nn_weight);
   Print("Confidence threshold: ", m_confidence_threshold);
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize and clean up                                        |
//+------------------------------------------------------------------+
void CEnsembleML::Deinitialize()
{
   if(m_logistic_regression != NULL)
   {
      m_logistic_regression.Deinitialize();
      delete m_logistic_regression;
      m_logistic_regression = NULL;
   }
   
   if(m_neural_network != NULL)
   {
      m_neural_network.Deinitialize();
      delete m_neural_network;
      m_neural_network = NULL;
   }
}

//+------------------------------------------------------------------+
//| Evaluate signal using ensemble prediction                        |
//+------------------------------------------------------------------+
bool CEnsembleML::EvaluateSignal(ExtendedMLFeatures &features, double &confidence)
{
   m_total_predictions++;
   
   // Get ensemble probability
   double probability = PredictProbability(features);
   
   // Calculate confidence
   confidence = CalculateConfidence(probability);
   
   // Decision: accept if confidence is high enough
   bool accept = (confidence >= m_confidence_threshold);
   
   if(accept)
   {
      features.outcome = -1; // Pending
      
      // Add to both model histories
      if(m_logistic_regression != NULL && m_use_lr)
      {
         double dummy_conf;
         m_logistic_regression.EvaluateSignal(features, dummy_conf);
      }
   }
   
   return accept;
}

//+------------------------------------------------------------------+
//| Predict probability using ensemble                               |
//+------------------------------------------------------------------+
double CEnsembleML::PredictProbability(ExtendedMLFeatures &features)
{
   double lr_prob = 0.5;
   double nn_prob = 0.5;
   
   // Get LR prediction
   if(m_logistic_regression != NULL && m_use_lr)
   {
      lr_prob = m_logistic_regression.PredictProbability(features);
   }
   
   // Get NN prediction
   if(m_neural_network != NULL && m_use_nn)
   {
      nn_prob = m_neural_network.Predict(features);
   }
   
   // Combine predictions based on mode
   if(m_ensemble_mode && m_use_lr && m_use_nn)
   {
      return CalculateEnsembleProbability(lr_prob, nn_prob);
   }
   else if(m_use_nn)
   {
      return nn_prob;
   }
   else if(m_use_lr)
   {
      return lr_prob;
   }
   
   return 0.5; // Default
}

//+------------------------------------------------------------------+
//| Calculate ensemble probability (weighted average)                |
//+------------------------------------------------------------------+
double CEnsembleML::CalculateEnsembleProbability(double lr_prob, double nn_prob)
{
   // Weighted average of predictions
   double ensemble_prob = (lr_prob * m_lr_weight) + (nn_prob * m_nn_weight);
   
   // Ensure result is in [0, 1]
   return MathMax(0.0, MathMin(1.0, ensemble_prob));
}

//+------------------------------------------------------------------+
//| Calculate confidence from probability                            |
//+------------------------------------------------------------------+
double CEnsembleML::CalculateConfidence(double probability)
{
   // Confidence is how far the probability is from 0.5 (uncertain)
   return MathAbs(probability - 0.5) * 2.0;
}

//+------------------------------------------------------------------+
//| Update both models with trade outcome                            |
//+------------------------------------------------------------------+
void CEnsembleML::UpdateModels(ExtendedMLFeatures &features, int outcome)
{
   // Track performance
   if(outcome == 1)
      m_successful_predictions++;
   
   // Update LR model
   if(m_logistic_regression != NULL && m_use_lr)
   {
      m_logistic_regression.UpdateModel(features, outcome);
   }
   
   // Update NN model
   if(m_neural_network != NULL && m_use_nn)
   {
      m_neural_network.OnlineLearningUpdate(features, outcome);
   }
   
   // Log performance periodically
   if(m_total_predictions % 10 == 0 && m_total_predictions > 0)
   {
      Print("=== Ensemble ML Performance ===");
      Print("Total predictions: ", m_total_predictions);
      Print("Successful: ", m_successful_predictions);
      Print("Accuracy: ", GetAccuracy() * 100, "%");
      
      if(m_neural_network != NULL)
      {
         Print("NN Training iterations: ", m_neural_network.GetTrainingIterations());
         Print("NN Last loss: ", m_neural_network.GetLastLoss());
      }
   }
}

//+------------------------------------------------------------------+
//| Set ensemble weights                                             |
//+------------------------------------------------------------------+
void CEnsembleML::SetEnsembleWeights(double lr_weight, double nn_weight)
{
   // Normalize weights to sum to 1.0
   double total = lr_weight + nn_weight;
   if(total > 0)
   {
      m_lr_weight = lr_weight / total;
      m_nn_weight = nn_weight / total;
   }
   else
   {
      m_lr_weight = 0.3;
      m_nn_weight = 0.7;
   }
   
   Print("Ensemble weights updated: LR=", m_lr_weight, " NN=", m_nn_weight);
}

//+------------------------------------------------------------------+
//| Set model mode                                                   |
//+------------------------------------------------------------------+
void CEnsembleML::SetModelMode(bool use_lr, bool use_nn, bool ensemble)
{
   m_use_lr = use_lr;
   m_use_nn = use_nn;
   m_ensemble_mode = ensemble;
   
   string mode = "";
   if(ensemble && use_lr && use_nn)
      mode = "Ensemble (LR + NN)";
   else if(use_nn)
      mode = "Neural Network Only";
   else if(use_lr)
      mode = "Logistic Regression Only";
   else
      mode = "No ML (disabled)";
   
   Print("Ensemble mode set to: ", mode);
}

//+------------------------------------------------------------------+
//| Get overall accuracy                                             |
//+------------------------------------------------------------------+
double CEnsembleML::GetAccuracy()
{
   if(m_total_predictions == 0)
      return 0.5;
   
   return (double)m_successful_predictions / (double)m_total_predictions;
}
//+------------------------------------------------------------------+
