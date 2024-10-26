import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSL to Text Translator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  String _translatedText = "Translated Text Here";
  Interpreter? _interpreter;

  final List<String> labels = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'Kumusta',
    'L',
    'M',
    'Mahal Kita',
    'N',
    'O',
    'Okay',
    'P',
    'Q',
    'R',
    'S',
    'Salamat',
    'T',
    'U',
    'W',
    'X',
    'Y',
    'Z'
  ];
  final int numClasses = 31;

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset("model.tflite");
      print("Model loaded");
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  void initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _cameraController =
          CameraController(cameras![0], ResolutionPreset.medium);
      await _cameraController?.initialize();
      setState(() {});
    }
  }

  void captureAndTranslate() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final image = await _cameraController!.takePicture();
      String translation = await predictGesture(image);
      setState(() {
        _translatedText = translation;
      });
    }
  }

  Future<String> predictGesture(XFile image) async {
    final imgFile = File(image.path);
    var inputImageData = await imageToByteListFloat32(imgFile, 224, 224);
    var output = List.filled(numClasses, 0).reshape([1, numClasses]);

    _interpreter?.run(inputImageData, output);
    int recognizedIndex = output[0].indexOf(output[0].reduce(max));
    String recognizedLabel =
        recognizedIndex >= 0 && recognizedIndex < labels.length
            ? labels[recognizedIndex]
            : "No gesture recognized";

    return recognizedLabel;
  }

  Future<List<double>> imageToByteListFloat32(
      File imageFile, int width, int height) async {
    final imgData = img.decodeImage(imageFile.readAsBytesSync())!;
    final resizedImg = img.copyResize(imgData, width: width, height: height);
    var byteData = Float32List(width * height * 3);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        var pixel = resizedImg.getPixel(x, y);
        byteData[(y * width + x) * 3 + 0] =
            ((img.getRed(pixel) / 255.0) - 0.5) / 0.5;
        byteData[(y * width + x) * 3 + 1] =
            ((img.getGreen(pixel) / 255.0) - 0.5) / 0.5;
        byteData[(y * width + x) * 3 + 2] =
            ((img.getBlue(pixel) / 255.0) - 0.5) / 0.5;
      }
    }

    return byteData;
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('FSL to Text Translator')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: CameraPreview(_cameraController!),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Translated Text:', style: TextStyle(fontSize: 20)),
                  Text(
                    _translatedText,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
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
    _interpreter?.close();
    super.dispose();
  }
}
