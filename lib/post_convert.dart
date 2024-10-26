import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class SignLanguageTranslator {
  Interpreter? _interpreter;

  // Load the TFLite model
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('fsl_model.tflite');
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  // Preprocess the image for model prediction
  List<List<List<List<double>>>> processImage(img.Image image) {
    // Convert image to Tensor
    final input = List.generate(
        1,
        (i) => List.generate(
            64,
            (j) => List.generate(
                64,
                (k) => List.generate(
                    3,
                    (l) =>
                        image.getPixel(k, j) /
                        255.0)))); // Normalize pixel values to [0, 1]
    return input;
  }

  // Predict the gesture
  Future<String> predict(CameraImage cameraImage) async {
    // Convert cameraImage to usable input (this may need adjustment)
    img.Image image = img.Image.fromBytes(
      cameraImage.width,
      cameraImage.height,
      cameraImage.planes[0].bytes,
      format: img.Format.rgb,
    );

    var input = processImage(image);
    var output = List.generate(1,
        (i) => List.filled(10, 0.0)); // Adjust based on the number of gestures

    _interpreter?.run(input, output);

    // Get the label with the highest probability
    int predictedIndex = output[0].indexWhere(
        (element) => element == output[0].reduce((a, b) => a > b ? a : b));

    return predictedIndex.toString(); // Map this to your actual label list
  }
}
