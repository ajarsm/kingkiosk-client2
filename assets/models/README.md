# Person Detection Model

This directory should contain the TensorFlow Lite person detection model file.

## Model Requirements:
- File name: person_detect.tflite
- Input: 224x224x3 RGB image (normalized to [0,1])
- Output: Single probability value for person presence OR [no_person_prob, person_prob]
- Model size: ~250KB (recommended for mobile)

## Recommended Models:
1. MobileNetV2-based person detection
2. EfficientNet-Lite for person detection
3. Custom trained model on person/no-person dataset

## Usage:
Replace this README with additional documentation if needed. The model file 'person_detect.tflite' is now present.
