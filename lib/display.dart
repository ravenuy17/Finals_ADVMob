import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
// Your Sign Language Translator class
import 'package:path_provider/path_provider.dart';
import 'package:flutter_application_1/database.dart';
import 'package:tflite/tflite.dart'; // Add TFLite dependency

class SignLanguageTranslatorPage extends StatefulWidget {
  const SignLanguageTranslatorPage({Key? key}) : super(key: key);

  @override
  _SignLanguageTranslatorPageState createState() =>
      _SignLanguageTranslatorPageState();
}

class _SignLanguageTranslatorPageState
    extends State<SignLanguageTranslatorPage> {
  CameraController? _cameraController;
  String _translatedText = "";
  final dbHelper = DatabaseHelper(); // Initialize the database helper

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel(); // Load the TFLite model
  }

  // Load the TFLite model
  Future<void> loadModel() async {
    String? result = await Tflite.loadModel(
      model: "assets/model.tflite", // Path to your TFLite model
      labels: "assets/labels.txt", // Optional: Path to labels file
    );
    print("Model loaded: $result");
  }

  void initCamera() async {
    List<CameraDescription> cameras = await availableCameras();
    _cameraController = CameraController(cameras[1], ResolutionPreset.medium);
    await _cameraController!.initialize();
    setState(() {});
  }

  // Capture image and translate using the model
  void captureAndTranslate() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final image = await _cameraController!.takePicture();

      // Get translation from the model
      String translation = await predictGesture(image);

      // Update the UI with the translation
      setState(() {
        _translatedText = translation;
      });
    }
  }

  // Predict gesture using TFLite model
  Future<String> predictGesture(XFile image) async {
    // Prepare the image for the model (use the image path)
    var recognitions = await Tflite.runModelOnImage(
      path: image.path, // Use the path for the captured image
      numResults: 1, // Set according to your requirements
      threshold: 0.5, // Confidence threshold
      asynch: true,
    );

    // Process the recognitions to get the translated text
    if (recognitions != null && recognitions.isNotEmpty) {
      return recognitions[0]["label"] ??
          "Gesture recognized, but label missing"; // Adjust based on your model's output
    } else {
      return "No gesture recognized";
    }
  }

  Future<String?> _showLabelDialog(BuildContext context) async {
    TextEditingController labelController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Label the gesture'),
          content: TextField(
            controller: labelController,
            decoration: const InputDecoration(hintText: "Enter gesture label"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(labelController.text);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void saveLabeledImage(XFile image, String label) async {
    final directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/${DateTime.now()}.png';
    await image.saveTo(path);
    saveLabelToDatabase(label, path);
  }

  void saveLabelToDatabase(String label, String path) async {
    await dbHelper.insertLabel(label, path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FSL to Text Translator')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: _cameraController == null ||
                    !_cameraController!.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : CameraPreview(_cameraController!),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Translated Text:'),
                Text(
                  _translatedText,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: captureAndTranslate,
            child: const Text('Capture & Translate'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    Tflite.close(); // Close TFLite when disposing
    super.dispose();
  }
}
