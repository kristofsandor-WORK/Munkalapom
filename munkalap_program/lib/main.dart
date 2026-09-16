import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:signature/signature.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MunkalapApp());
}

class MunkalapApp extends StatelessWidget {
  const MunkalapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DR Industrie - Munkalap',
      theme: ThemeData(primarySwatch: Colors.deepOrange, useMaterial3: true),
      home: const MunkalapFormScreen(),
    );
  }
}

class MunkalapFormScreen extends StatefulWidget {
  const MunkalapFormScreen({super.key});

  @override
  State<MunkalapFormScreen> createState() => _MunkalapFormScreenState();
}

class _MunkalapFormScreenState extends State<MunkalapFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _driSzamController = TextEditingController();
  final TextEditingController _ugyfelController = TextEditingController();
  final TextEditingController _helyszinController = TextEditingController();
  final TextEditingController _gepController = TextEditingController();
  final TextEditingController _idotartamController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _elvegzettMunkaController = TextEditingController();
  final TextEditingController _hibaLeirasController = TextEditingController();
  final TextEditingController _datumController = TextEditingController(
    text: 'Miskolc, ${DateTime.now().year}.${DateTime.now().month}.${DateTime.now().day}.',
  );

  final SignatureController _ugyfelSigController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );
  final SignatureController _szervizSigController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  late stt.SpeechToText _speech;
  bool _isListening = false;
  TextEditingController? _activeListeningController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // Csupa nagy kezdőbetűs szóátalakítás (Minden Szó Nagybetűvel Kezdődik)
  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  // Mondatkezdő nagybetűs átalakítás
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _toggleListening(TextEditingController controller) async {
    if (_isListening && _activeListeningController == controller) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _activeListeningController = null;
      });
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _activeListeningController = controller;
        });
        _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            localeId: 'hu_HU',
          ),
          onResult: (val) {
            setState(() {
              // Ha az ügyfél mezőbe diktálsz, MINDEN SZÓ nagybetűs lesz (pl. Kovács István)
              if (controller == _ugyfelController) {
                controller.text = _capitalizeWords(val.recognizedWords);
              } else {
                controller.text = _capitalizeFirstLetter(val.recognizedWords);
              }
            });
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A beszédfelismerő nem érhető el ezen a készüléken.')),
        );
      }
    }
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    final ttfBase = await PdfGoogleFonts.robotoRegular();
    final ttfBold = await PdfGoogleFonts.robotoBold();

    final ByteData bgData = await rootBundle.load('assets/sablon.png');
    final Uint8List bgBytes = bgData.buffer.asUint8List();
    final pw.ImageProvider bgImage = pw.MemoryImage(bgBytes);

    final Uint8List? ugyfelBytes = await _ugyfelSigController.toPngBytes();
    final Uint8List? szervizBytes = await _szervizSigController.toPngBytes();
    final pw.ImageProvider? ugyfelImg = ugyfelBytes != null ? pw.MemoryImage(ugyfelBytes) : null;
    final pw.ImageProvider? szervizImg = szervizBytes != null ? pw.MemoryImage(szervizBytes) : null;

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData(
          defaultTextStyle: pw.TextStyle(font: ttfBase),
        ).copyWith(
          paragraphStyle: pw.TextStyle(font: ttfBase),
        ),
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // HÁTTÉR SABLON KÉP
              pw.Positioned.fill(
                child: pw.Image(bgImage, fit: pw.BoxFit.cover),
              ),

              // DRI Munkalap szám
              pw.Positioned(
                left: 710,
                top: 55,
                child: pw.Text(_driSzamController.text, style: pw.TextStyle(font: ttfBold, fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ),

              // Ügyfél / Customer 
              pw.Positioned(
                left: 140,
                top: 136,
                child: pw.Text(_ugyfelController.text, style: pw.TextStyle(font: ttfBase, fontSize: 10)),
              ),

              // Munkavégzés helye / Location of work
              pw.Positioned(
                left: 225,
                top: 172,
                child: pw.Text(_helyszinController.text, style: pw.TextStyle(font: ttfBase, fontSize: 10)),
              ),
              
              // Gép típusa / Type of machine 
              pw.Positioned(
                left: 180,
                top: 209,
                child: pw.Text(_gepController.text, style: pw.TextStyle(font: ttfBase, fontSize: 10)),
              ),

              // Munkavégzés időtartama / Duration of work 
              pw.Positioned(
                left: 245,
                top: 243,
                child: pw.Text(_idotartamController.text, style: pw.TextStyle(font: ttfBase, fontSize: 10)),
              ),

              // Megtett km / Traveled distance 
              pw.Positioned(
                left: 190,
                top: 279,
                child: pw.Text(_kmController.text, style: pw.TextStyle(font: ttfBase, fontSize: 10)),
              ),

              // Elvégzett munka 
              pw.Positioned(
                left: 45,
                top: 360,
                child: pw.Container(
                  width: 500,
                  height: 95,
                  child: pw.Text(_elvegzettMunkaController.text, style: pw.TextStyle(font: ttfBase, fontSize: 10)),
                ),
              ),

              // Hiba leírása + javaslat
              pw.Positioned(
                left: 45,
                top: 500,
                child: pw.Container(
                  width: 500,
                  height: 95,
                  child: pw.Text(_hibaLeirasController.text, style: pw.TextStyle(font: ttfBase, fontSize: 10)),
                ),
              ),

              // Hely, dátum
              pw.Positioned(
                left: 135,
                top: 610,
                child: pw.Text(_datumController.text, style: pw.TextStyle(font: ttfBase, fontSize: 10)),
              ),

              // Ügyfél aláírása
              if (ugyfelImg != null)
                pw.Positioned(
                  left: 45,
                  top: 645,
                  child: pw.Image(ugyfelImg, width: 160, height: 40),
                ),

              // Szerviz aláírása
              if (szervizImg != null)
                pw.Positioned(
                  left: 385,
                  top: 645,
                  child: pw.Image(szervizImg, width: 160, height: 40),
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  void dispose() {
    _driSzamController.dispose();
    _ugyfelController.dispose();
    _helyszinController.dispose();
    _gepController.dispose();
    _idotartamController.dispose();
    _kmController.dispose();
    _elvegzettMunkaController.dispose();
    _hibaLeirasController.dispose();
    _datumController.dispose();
    _ugyfelSigController.dispose();
    _szervizSigController.dispose();
    super.dispose();
  }

  Widget _buildTextFieldWithMic({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    bool isThisListening = _isListening && _activeListeningController == controller;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
        suffixIcon: IconButton(
          icon: Icon(
            isThisListening ? Icons.mic : Icons.mic_none,
            color: isThisListening ? Colors.red : Colors.deepOrange,
          ),
          onPressed: () => _toggleListening(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DR Industrie - Munkalap'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('DRI-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextFieldWithMic(controller: _driSzamController, labelText: 'Munkalap száma')),
                  ],
                ),
                const SizedBox(height: 12),
                // ÜGYFÉL: Gépelve és diktálva is MINDEN SZÓ Nagy Kezdőbetűs lesz!
                _buildTextFieldWithMic(
                  controller: _ugyfelController, 
                  labelText: 'Ügyfél / Customer',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _buildTextFieldWithMic(controller: _helyszinController, labelText: 'Munkavégzés helye'),
                const SizedBox(height: 12),
                _buildTextFieldWithMic(controller: _gepController, labelText: 'Gép típusa'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextFieldWithMic(controller: _idotartamController, labelText: 'Munkavégzés időtartama')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextFieldWithMic(controller: _kmController, labelText: 'Megtett km')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextFieldWithMic(
                  controller: _elvegzettMunkaController,
                  labelText: 'Elvégzett munka / Work Performed',
                  maxLines: 6,
                ),
                const SizedBox(height: 12),
                _buildTextFieldWithMic(
                  controller: _hibaLeirasController,
                  labelText: 'Hiba leírása + javaslat',
                  maxLines: 6,
                ),
                const SizedBox(height: 12),
                _buildTextFieldWithMic(controller: _datumController, labelText: 'Hely, dátum / Date'),
                const SizedBox(height: 16),

                const Text('Ügyfél aláírása:', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey)), child: Signature(controller: _ugyfelSigController, height: 110, backgroundColor: Colors.grey[100]!)),
                TextButton(onPressed: () => _ugyfelSigController.clear(), child: const Text('Aláírás törlése')),

                const SizedBox(height: 10),
                const Text('Szerviz aláírása:', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey)), child: Signature(controller: _szervizSigController, height: 110, backgroundColor: Colors.grey[100]!)),
                TextButton(onPressed: () => _szervizSigController.clear(), child: const Text('Aláírás törlése')),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final pdfBytes = await _generatePdf();
                        await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF GENERÁLÁS ÉS NYOMTATÁS', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}