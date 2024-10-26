import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class SignLanguageTranslator {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('fsl_model.tflite');
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  // Example list of labels corresponding to sign language gestures
  final List<String> _labels = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'
    // Add more labels as per your model's output
  ];

  List<double> processImageForModel(image) {
    // Process your image to the required input format for the model.
    // Example: resize, normalize, convert to tensor, etc.
    ImageProcessor imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(224, 224,
            ResizeMethod.BILINEAR)) // Adjust size as per model's input.
        .add(NormalizeOp(0,
            255)) // Normalize if needed (for example, scale pixel values to [0, 1])
        .build();

    TensorImage tensorImage = TensorImage.fromImage(image);
    tensorImage = imageProcessor.process(tensorImage);

    return tensorImage.buffer.asFloat32List(); // Convert to float list.
  }

  Future<String> predict(image) async {
    var input = processImageForModel(image);

    // Assuming the model outputs a list of probabilities for each label
    var output = List.filled(_labels.length, 0).reshape([1, _labels.length]);

    // Run inference
    _interpreter?.run(input, output);

    // Find the label with the highest probability
    int maxIndex = output[0]
        .indexWhere((val) => val == output[0].reduce((a, b) => a > b ? a : b));

    // Return the corresponding label as the translation
    String translatedText = _labels[maxIndex];

    return translatedText;
  }
}
