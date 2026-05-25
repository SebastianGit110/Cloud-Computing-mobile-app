import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? _image;
  String _text = '';
  String _translatedText = '';
  bool _isProcessing = false;

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final GoogleTranslator _translator = GoogleTranslator();
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
          _text = '';
          _translatedText = '';
        });
        _processImage();
      }
    } catch (e) {
      _showError('Error al seleccionar la imagen: $e');
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final inputImage = InputImage.fromFilePath(_image!.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      setState(() {
        _text = recognizedText.text;
      });

      if (_text.isNotEmpty) {
        final translation = await _translator.translate(_text, to: 'en');
        setState(() {
          _translatedText = translation.text;
        });
      }
    } catch (e) {
      _showError('Error al procesar la imagen: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _speak() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.speak(_translatedText);
    } catch (e) {
      _showError('Error al reproducir el audio: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR App', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildImagePickerButtons(),
          const SizedBox(height: 20),
          _buildImagePreview(),
          const SizedBox(height: 20),
          _buildProcessingIndicator(),
          if (_text.isNotEmpty) _buildExtractedText(),
          if (_translatedText.isNotEmpty) _buildTranslatedText(),
        ],
      ),
    );
  }

  Widget _buildImagePickerButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Cámara'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.deepPurple,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library),
          label: const Text('Galería'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return _image == null
        ? const Text('No has seleccionado ninguna imagen.', textAlign: TextAlign.center)
        : Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepPurple, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: kIsWeb
                  ? Image.network(_image!.path, fit: BoxFit.cover)
                  : Image.file(File(_image!.path), fit: BoxFit.cover),
            ),
          );
  }

  Widget _buildProcessingIndicator() {
    return _isProcessing ? const Center(child: CircularProgressIndicator()) : Container();
  }

  Widget _buildExtractedText() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Texto Extraído', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 10),
            SelectableText(_text, textAlign: TextAlign.justify),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslatedText() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Traducción (Inglés)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 10),
            SelectableText(_translatedText, textAlign: TextAlign.justify),
            const SizedBox(height: 10),
            IconButton(
              onPressed: _speak,
              icon: const Icon(Icons.volume_up, color: Colors.deepPurple, size: 30),
              tooltip: 'Escuchar traducción',
            ),
          ],
        ),
      ),
    );
  }
}
