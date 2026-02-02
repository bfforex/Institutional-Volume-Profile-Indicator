//+------------------------------------------------------------------+
//|                                              NeuralNetwork.mqh    |
//|                    Multi-Layer Perceptron for Signal Prediction   |
//+------------------------------------------------------------------+
#property copyright "Institutional Volume Profile ML System"
#property link      ""
#property version   "2.00"
#property strict

#include "FeatureExtractor.mqh"

// Network architecture: 18 → 32 → 16 → 1
#define NN_INPUT_SIZE 18
#define NN_HIDDEN1_SIZE 32
#define NN_HIDDEN2_SIZE 16
#define NN_OUTPUT_SIZE 1

//+------------------------------------------------------------------+
//| Activation Function Types                                        |
//+------------------------------------------------------------------+
enum ENUM_ACTIVATION
{
   ACTIVATION_RELU,
   ACTIVATION_SIGMOID,
   ACTIVATION_TANH,
   ACTIVATION_LEAKY_RELU
};

//+------------------------------------------------------------------+
//| Neural Network Class                                             |
//+------------------------------------------------------------------+
class CNeuralNetwork
{
private:
   // Layer weights and biases
   double m_weights_h1[][NN_HIDDEN1_SIZE];     // Input → Hidden1 [18][32]
   double m_bias_h1[NN_HIDDEN1_SIZE];
   
   double m_weights_h2[][NN_HIDDEN2_SIZE];     // Hidden1 → Hidden2 [32][16]
   double m_bias_h2[NN_HIDDEN2_SIZE];
   
   double m_weights_out[][NN_OUTPUT_SIZE];     // Hidden2 → Output [16][1]
   double m_bias_out[NN_OUTPUT_SIZE];
   
   // Training parameters
   double m_learning_rate;
   double m_momentum;
   double m_dropout_rate;
   
   // Momentum terms for training
   double m_velocity_h1[][NN_HIDDEN1_SIZE];
   double m_velocity_h2[][NN_HIDDEN2_SIZE];
   double m_velocity_out[][NN_OUTPUT_SIZE];
   
   // Layer activations (for backprop)
   double m_input[NN_INPUT_SIZE];
   double m_hidden1[NN_HIDDEN1_SIZE];
   double m_hidden2[NN_HIDDEN2_SIZE];
   double m_output[NN_OUTPUT_SIZE];
   
   // Normalization parameters
   double m_feature_mean[NN_INPUT_SIZE];
   double m_feature_std[NN_INPUT_SIZE];
   int    m_samples_seen;
   
   // File handling
   string m_model_file;
   
   // Performance tracking
   int m_training_iterations;
   double m_last_loss;
   
public:
   CNeuralNetwork();
   ~CNeuralNetwork();
   
   bool Initialize(double learning_rate = 0.001, double momentum = 0.9);
   void Deinitialize();
   
   // Forward pass
   double Predict(ExtendedMLFeatures &features);
   double PredictFromArray(double input_array[]);
   
   // Training
   void Train(ExtendedMLFeatures &features, int actual_outcome);
   void TrainBatch(ExtendedMLFeatures &batch[], int outcomes[], int batch_size);
   void Backpropagate(double target);
   
   // Online learning (incremental updates)
   void OnlineLearningUpdate(ExtendedMLFeatures &features, int outcome);
   
   // Normalization
   void UpdateNormalizationStats(double input[]);
   void NormalizeInput(double input[], double normalized[]);
   
   // Model persistence
   bool SaveModel(string filename);
   bool LoadModel(string filename);
   
   // Diagnostics
   double GetLastLoss() { return m_last_loss; }
   int GetTrainingIterations() { return m_training_iterations; }
   void GetFeatureImportance(double importance[]);
   
private:
   // Activation functions
   double ReLU(double x);
   double ReLUDerivative(double x);
   double Sigmoid(double x);
   double SigmoidDerivative(double x);
   double LeakyReLU(double x, double alpha = 0.01);
   double LeakyReLUDerivative(double x, double alpha = 0.01);
   
   // Weight initialization
   void InitializeWeights();
   void XavierInitialization(double &weights[][], int rows, int cols);
   
   // Forward pass helpers
   void ForwardHidden1(double input[]);
   void ForwardHidden2();
   void ForwardOutput();
   
   // Backprop helpers
   void BackpropOutput(double target);
   void BackpropHidden2(double output_gradient[]);
   void BackpropHidden1(double h2_gradient[], double input[]);
   
   // Gradient clipping
   double ClipGradient(double gradient, double max_val = 1.0);
   
   // Loss calculation
   double CalculateBinaryCrossEntropy(double predicted, double actual);
   
   // Convert ExtendedMLFeatures to array
   void FeaturesToArray(ExtendedMLFeatures &features, double output[]);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CNeuralNetwork::CNeuralNetwork()
{
   m_learning_rate = 0.001;
   m_momentum = 0.9;
   m_dropout_rate = 0.0;
   m_samples_seen = 0;
   m_training_iterations = 0;
   m_last_loss = 0;
   m_model_file = "NeuralNetwork_Model.dat";
   
   // Initialize arrays
   ArrayResize(m_weights_h1, NN_INPUT_SIZE);
   ArrayResize(m_velocity_h1, NN_INPUT_SIZE);
   for(int i = 0; i < NN_INPUT_SIZE; i++)
   {
      ArrayResize(m_weights_h1[i], NN_HIDDEN1_SIZE);
      ArrayResize(m_velocity_h1[i], NN_HIDDEN1_SIZE);
      ArrayInitialize(m_velocity_h1[i], 0);
   }
   
   ArrayResize(m_weights_h2, NN_HIDDEN1_SIZE);
   ArrayResize(m_velocity_h2, NN_HIDDEN1_SIZE);
   for(int i = 0; i < NN_HIDDEN1_SIZE; i++)
   {
      ArrayResize(m_weights_h2[i], NN_HIDDEN2_SIZE);
      ArrayResize(m_velocity_h2[i], NN_HIDDEN2_SIZE);
      ArrayInitialize(m_velocity_h2[i], 0);
   }
   
   ArrayResize(m_weights_out, NN_HIDDEN2_SIZE);
   ArrayResize(m_velocity_out, NN_HIDDEN2_SIZE);
   for(int i = 0; i < NN_HIDDEN2_SIZE; i++)
   {
      ArrayResize(m_weights_out[i], NN_OUTPUT_SIZE);
      ArrayResize(m_velocity_out[i], NN_OUTPUT_SIZE);
      ArrayInitialize(m_velocity_out[i], 0);
   }
   
   ArrayInitialize(m_bias_h1, 0);
   ArrayInitialize(m_bias_h2, 0);
   ArrayInitialize(m_bias_out, 0);
   
   ArrayInitialize(m_feature_mean, 0);
   ArrayInitialize(m_feature_std, 1.0);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CNeuralNetwork::~CNeuralNetwork()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize neural network                                        |
//+------------------------------------------------------------------+
bool CNeuralNetwork::Initialize(double learning_rate = 0.001, double momentum = 0.9)
{
   m_learning_rate = learning_rate;
   m_momentum = momentum;
   
   InitializeWeights();
   
   Print("Neural Network initialized: 18→32→16→1 architecture");
   Print("Learning rate: ", m_learning_rate, ", Momentum: ", m_momentum);
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize and clean up                                        |
//+------------------------------------------------------------------+
void CNeuralNetwork::Deinitialize()
{
   // Arrays are automatically freed by MQL5
}

//+------------------------------------------------------------------+
//| Initialize weights using Xavier/Glorot initialization            |
//+------------------------------------------------------------------+
void CNeuralNetwork::InitializeWeights()
{
   MathSrand((int)TimeLocal());
   
   // Xavier initialization for Hidden1
   double limit_h1 = MathSqrt(6.0 / (NN_INPUT_SIZE + NN_HIDDEN1_SIZE));
   for(int i = 0; i < NN_INPUT_SIZE; i++)
   {
      for(int j = 0; j < NN_HIDDEN1_SIZE; j++)
      {
         m_weights_h1[i][j] = (MathRand() / 32768.0 * 2.0 - 1.0) * limit_h1;
      }
   }
   
   // Xavier initialization for Hidden2
   double limit_h2 = MathSqrt(6.0 / (NN_HIDDEN1_SIZE + NN_HIDDEN2_SIZE));
   for(int i = 0; i < NN_HIDDEN1_SIZE; i++)
   {
      for(int j = 0; j < NN_HIDDEN2_SIZE; j++)
      {
         m_weights_h2[i][j] = (MathRand() / 32768.0 * 2.0 - 1.0) * limit_h2;
      }
   }
   
   // Xavier initialization for Output
   double limit_out = MathSqrt(6.0 / (NN_HIDDEN2_SIZE + NN_OUTPUT_SIZE));
   for(int i = 0; i < NN_HIDDEN2_SIZE; i++)
   {
      for(int j = 0; j < NN_OUTPUT_SIZE; j++)
      {
         m_weights_out[i][j] = (MathRand() / 32768.0 * 2.0 - 1.0) * limit_out;
      }
   }
}

//+------------------------------------------------------------------+
//| Predict from ExtendedMLFeatures                                  |
//+------------------------------------------------------------------+
double CNeuralNetwork::Predict(ExtendedMLFeatures &features)
{
   double input[NN_INPUT_SIZE];
   FeaturesToArray(features, input);
   
   double normalized[NN_INPUT_SIZE];
   NormalizeInput(input, normalized);
   
   return PredictFromArray(normalized);
}

//+------------------------------------------------------------------+
//| Predict from array input                                         |
//+------------------------------------------------------------------+
double CNeuralNetwork::PredictFromArray(double input_array[])
{
   // Copy input
   ArrayCopy(m_input, input_array, 0, 0, NN_INPUT_SIZE);
   
   // Forward pass through network
   ForwardHidden1(m_input);
   ForwardHidden2();
   ForwardOutput();
   
   return m_output[0];
}

//+------------------------------------------------------------------+
//| Forward pass: Input → Hidden1                                    |
//+------------------------------------------------------------------+
void CNeuralNetwork::ForwardHidden1(double input[])
{
   for(int j = 0; j < NN_HIDDEN1_SIZE; j++)
   {
      double sum = m_bias_h1[j];
      
      for(int i = 0; i < NN_INPUT_SIZE; i++)
      {
         sum += input[i] * m_weights_h1[i][j];
      }
      
      m_hidden1[j] = ReLU(sum);
   }
}

//+------------------------------------------------------------------+
//| Forward pass: Hidden1 → Hidden2                                  |
//+------------------------------------------------------------------+
void CNeuralNetwork::ForwardHidden2()
{
   for(int j = 0; j < NN_HIDDEN2_SIZE; j++)
   {
      double sum = m_bias_h2[j];
      
      for(int i = 0; i < NN_HIDDEN1_SIZE; i++)
      {
         sum += m_hidden1[i] * m_weights_h2[i][j];
      }
      
      m_hidden2[j] = ReLU(sum);
   }
}

//+------------------------------------------------------------------+
//| Forward pass: Hidden2 → Output                                   |
//+------------------------------------------------------------------+
void CNeuralNetwork::ForwardOutput()
{
   for(int j = 0; j < NN_OUTPUT_SIZE; j++)
   {
      double sum = m_bias_out[j];
      
      for(int i = 0; i < NN_HIDDEN2_SIZE; i++)
      {
         sum += m_hidden2[i] * m_weights_out[i][j];
      }
      
      m_output[j] = Sigmoid(sum);
   }
}

//+------------------------------------------------------------------+
//| Train network with single sample                                 |
//+------------------------------------------------------------------+
void CNeuralNetwork::Train(ExtendedMLFeatures &features, int actual_outcome)
{
   // Forward pass
   double prediction = Predict(features);
   
   // Calculate loss
   m_last_loss = CalculateBinaryCrossEntropy(prediction, actual_outcome);
   
   // Backpropagation
   Backpropagate((double)actual_outcome);
   
   m_training_iterations++;
}

//+------------------------------------------------------------------+
//| Backpropagation                                                  |
//+------------------------------------------------------------------+
void CNeuralNetwork::Backpropagate(double target)
{
   // Output layer gradients
   double output_gradient[NN_OUTPUT_SIZE];
   for(int i = 0; i < NN_OUTPUT_SIZE; i++)
   {
      // Binary cross-entropy derivative with sigmoid
      output_gradient[i] = m_output[i] - target;
   }
   
   // Hidden2 → Output weights update
   for(int i = 0; i < NN_HIDDEN2_SIZE; i++)
   {
      for(int j = 0; j < NN_OUTPUT_SIZE; j++)
      {
         double gradient = output_gradient[j] * m_hidden2[i];
         gradient = ClipGradient(gradient);
         
         // Momentum SGD
         m_velocity_out[i][j] = m_momentum * m_velocity_out[i][j] - m_learning_rate * gradient;
         m_weights_out[i][j] += m_velocity_out[i][j];
      }
   }
   
   // Output bias update
   for(int j = 0; j < NN_OUTPUT_SIZE; j++)
   {
      m_bias_out[j] -= m_learning_rate * output_gradient[j];
   }
   
   // Hidden2 layer gradients
   double h2_gradient[NN_HIDDEN2_SIZE];
   for(int i = 0; i < NN_HIDDEN2_SIZE; i++)
   {
      double sum = 0;
      for(int j = 0; j < NN_OUTPUT_SIZE; j++)
      {
         sum += output_gradient[j] * m_weights_out[i][j];
      }
      h2_gradient[i] = sum * ReLUDerivative(m_hidden2[i]);
   }
   
   // Hidden1 → Hidden2 weights update
   for(int i = 0; i < NN_HIDDEN1_SIZE; i++)
   {
      for(int j = 0; j < NN_HIDDEN2_SIZE; j++)
      {
         double gradient = h2_gradient[j] * m_hidden1[i];
         gradient = ClipGradient(gradient);
         
         m_velocity_h2[i][j] = m_momentum * m_velocity_h2[i][j] - m_learning_rate * gradient;
         m_weights_h2[i][j] += m_velocity_h2[i][j];
      }
   }
   
   // Hidden2 bias update
   for(int j = 0; j < NN_HIDDEN2_SIZE; j++)
   {
      m_bias_h2[j] -= m_learning_rate * h2_gradient[j];
   }
   
   // Hidden1 layer gradients
   double h1_gradient[NN_HIDDEN1_SIZE];
   for(int i = 0; i < NN_HIDDEN1_SIZE; i++)
   {
      double sum = 0;
      for(int j = 0; j < NN_HIDDEN2_SIZE; j++)
      {
         sum += h2_gradient[j] * m_weights_h2[i][j];
      }
      h1_gradient[i] = sum * ReLUDerivative(m_hidden1[i]);
   }
   
   // Input → Hidden1 weights update
   for(int i = 0; i < NN_INPUT_SIZE; i++)
   {
      for(int j = 0; j < NN_HIDDEN1_SIZE; j++)
      {
         double gradient = h1_gradient[j] * m_input[i];
         gradient = ClipGradient(gradient);
         
         m_velocity_h1[i][j] = m_momentum * m_velocity_h1[i][j] - m_learning_rate * gradient;
         m_weights_h1[i][j] += m_velocity_h1[i][j];
      }
   }
   
   // Hidden1 bias update
   for(int j = 0; j < NN_HIDDEN1_SIZE; j++)
   {
      m_bias_h1[j] -= m_learning_rate * h1_gradient[j];
   }
}

//+------------------------------------------------------------------+
//| Online learning update                                           |
//+------------------------------------------------------------------+
void CNeuralNetwork::OnlineLearningUpdate(ExtendedMLFeatures &features, int outcome)
{
   Train(features, outcome);
}

//+------------------------------------------------------------------+
//| Train batch of samples                                           |
//+------------------------------------------------------------------+
void CNeuralNetwork::TrainBatch(ExtendedMLFeatures &batch[], int outcomes[], int batch_size)
{
   for(int i = 0; i < batch_size; i++)
   {
      Train(batch[i], outcomes[i]);
   }
}

//+------------------------------------------------------------------+
//| Update normalization statistics                                  |
//+------------------------------------------------------------------+
void CNeuralNetwork::UpdateNormalizationStats(double input[])
{
   m_samples_seen++;
   
   for(int i = 0; i < NN_INPUT_SIZE; i++)
   {
      // Online mean update
      double delta = input[i] - m_feature_mean[i];
      m_feature_mean[i] += delta / m_samples_seen;
      
      // Online variance update (Welford's algorithm)
      double delta2 = input[i] - m_feature_mean[i];
      m_feature_std[i] += delta * delta2;
   }
}

//+------------------------------------------------------------------+
//| Normalize input                                                  |
//+------------------------------------------------------------------+
void CNeuralNetwork::NormalizeInput(double input[], double normalized[])
{
   for(int i = 0; i < NN_INPUT_SIZE; i++)
   {
      double std = (m_samples_seen > 1) ? MathSqrt(m_feature_std[i] / (m_samples_seen - 1)) : 1.0;
      if(std < 0.0001) std = 1.0;
      
      normalized[i] = (input[i] - m_feature_mean[i]) / std;
   }
}

//+------------------------------------------------------------------+
//| Convert features to array                                        |
//+------------------------------------------------------------------+
void CNeuralNetwork::FeaturesToArray(ExtendedMLFeatures &features, double output[])
{
   output[0] = features.distance_to_poc;
   output[1] = features.distance_to_edge;
   output[2] = features.volume_delta;
   output[3] = features.rejection_ratio;
   output[4] = features.atr_normalized_vol;
   output[5] = features.trend_slope;
   output[6] = features.time_since_break;
   output[7] = features.lvn_proximity;
   output[8] = features.order_flow_imbalance;
   output[9] = features.market_session;
   output[10] = features.spread_normalized;
   output[11] = features.rsi_value;
   output[12] = features.rsi_divergence;
   output[13] = features.vwap_distance;
   output[14] = features.cumulative_delta;
   output[15] = features.bb_position;
   output[16] = features.historical_zone_winrate;
   output[17] = features.candle_body_ratio;
}

//+------------------------------------------------------------------+
//| Activation: ReLU                                                 |
//+------------------------------------------------------------------+
double CNeuralNetwork::ReLU(double x)
{
   return (x > 0) ? x : 0;
}

//+------------------------------------------------------------------+
//| ReLU Derivative                                                  |
//+------------------------------------------------------------------+
double CNeuralNetwork::ReLUDerivative(double x)
{
   return (x > 0) ? 1.0 : 0.0;
}

//+------------------------------------------------------------------+
//| Activation: Sigmoid                                              |
//+------------------------------------------------------------------+
double CNeuralNetwork::Sigmoid(double x)
{
   if(x > 20.0) return 1.0;
   if(x < -20.0) return 0.0;
   return 1.0 / (1.0 + MathExp(-x));
}

//+------------------------------------------------------------------+
//| Sigmoid Derivative                                               |
//+------------------------------------------------------------------+
double CNeuralNetwork::SigmoidDerivative(double x)
{
   double s = Sigmoid(x);
   return s * (1.0 - s);
}

//+------------------------------------------------------------------+
//| Activation: Leaky ReLU                                           |
//+------------------------------------------------------------------+
double CNeuralNetwork::LeakyReLU(double x, double alpha = 0.01)
{
   return (x > 0) ? x : alpha * x;
}

//+------------------------------------------------------------------+
//| Leaky ReLU Derivative                                            |
//+------------------------------------------------------------------+
double CNeuralNetwork::LeakyReLUDerivative(double x, double alpha = 0.01)
{
   return (x > 0) ? 1.0 : alpha;
}

//+------------------------------------------------------------------+
//| Clip gradient to prevent explosion                               |
//+------------------------------------------------------------------+
double CNeuralNetwork::ClipGradient(double gradient, double max_val = 1.0)
{
   if(gradient > max_val) return max_val;
   if(gradient < -max_val) return -max_val;
   return gradient;
}

//+------------------------------------------------------------------+
//| Calculate binary cross-entropy loss                              |
//+------------------------------------------------------------------+
double CNeuralNetwork::CalculateBinaryCrossEntropy(double predicted, double actual)
{
   // Avoid log(0)
   predicted = MathMax(0.0001, MathMin(0.9999, predicted));
   
   return -(actual * MathLog(predicted) + (1.0 - actual) * MathLog(1.0 - predicted));
}

//+------------------------------------------------------------------+
//| Get feature importance (simplified - use weight magnitudes)      |
//+------------------------------------------------------------------+
void CNeuralNetwork::GetFeatureImportance(double importance[])
{
   ArrayInitialize(importance, 0);
   
   // Sum absolute weights from input layer
   for(int i = 0; i < NN_INPUT_SIZE; i++)
   {
      for(int j = 0; j < NN_HIDDEN1_SIZE; j++)
      {
         importance[i] += MathAbs(m_weights_h1[i][j]);
      }
   }
   
   // Normalize to 0-1
   double max_importance = 0;
   for(int i = 0; i < NN_INPUT_SIZE; i++)
   {
      if(importance[i] > max_importance)
         max_importance = importance[i];
   }
   
   if(max_importance > 0)
   {
      for(int i = 0; i < NN_INPUT_SIZE; i++)
      {
         importance[i] /= max_importance;
      }
   }
}

//+------------------------------------------------------------------+
//| Save model to file (simplified binary format)                    |
//+------------------------------------------------------------------+
bool CNeuralNetwork::SaveModel(string filename)
{
   // Simplified - would save all weights and biases to binary file
   // Not implementing full file I/O for this initial version
   Print("Neural Network model save requested (not yet implemented)");
   return true;
}

//+------------------------------------------------------------------+
//| Load model from file                                             |
//+------------------------------------------------------------------+
bool CNeuralNetwork::LoadModel(string filename)
{
   // Simplified - would load all weights and biases from binary file
   Print("Neural Network model load requested (not yet implemented)");
   return false;
}
//+------------------------------------------------------------------+
