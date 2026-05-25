import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR from URL',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
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
  Uint8List? _imageBytes;
  String _text = '';
  String _translatedText = '';
  bool _isProcessing = false;
  final TextEditingController _urlController = TextEditingController();

  final TextRecognizer _textRecognizer = TextRecognizer();
  final GoogleTranslator _translator = GoogleTranslator();
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _processImageUrl() async {
    final imageUrl = _urlController.text.trim();
    if (imageUrl.isEmpty) {
      _showError('Por favor, introduce una URL de imagen.');
      return;
    }

    final uri = Uri.tryParse(imageUrl);
    if (uri == null || !uri.hasAbsolutePath || !uri.scheme.startsWith('http')) {
      _showError('URL no válida.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _imageBytes = null;
      _text = '';
      _translatedText = '';
    });

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        setState(() {
          _imageBytes = imageBytes;
        });
        await _processImageFromBytes(imageBytes);
      } else {
        _showError('Error al descargar la imagen: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error al procesar la URL: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processImageFromBytes(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(tempDir.path, 'temp_image.jpg');
    final tempFile = File(tempPath);

    try {
      await tempFile.writeAsBytes(imageBytes);

      final inputImage = InputImage.fromFilePath(tempPath);
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
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR desde URL', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildUrlInput(),
          const SizedBox(height: 20),
          _buildImagePreview(),
          const SizedBox(height: 20),
          _buildProcessingIndicator(),
          if (!_isProcessing && _text.isNotEmpty) _buildExtractedText(),
          if (!_isProcessing && _translatedText.isNotEmpty) _buildTranslatedText(),
        ],
      ),
    );
  }

  Widget _buildUrlInput() {
    return Column(
      children: [
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'URL de la Imagen',
            hintText: 'https://example.com/image.png',
            prefixIcon: Icon(Icons.link),
          ),
          onSubmitted: (_) => _isProcessing ? null : _processImageUrl(),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _processImageUrl,
          icon: const Icon(Icons.cloud_download),
          label: const Text('Procesar URL'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_imageBytes == null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text('La imagen se mostrará aquí.', textAlign: TextAlign.center),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurple, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return _isProcessing
        ? const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('Procesando...'),
              ],
            ),
          )
        : Container();
  }

  Widget _buildExtractedText() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _speak,
                icon: const Icon(Icons.volume_up, color: Colors.deepPurple, size: 30),
                tooltip: 'Escuchar traducción',
              ),
            ),
          ],
        ),
      ),
    );
  }
}