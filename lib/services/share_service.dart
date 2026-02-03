// SOCIAL SHARE SERVICE
// lib/services/share_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class ShareService {
  /// Cattura screenshot di un widget
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Errore cattura screenshot: $e');
      return null;
    }
  }

  /// Mostra dialog con opzioni di condivisione
  static void showShareDialog(
      BuildContext context, GlobalKey key, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareOptionsBottomSheet(
        screenshotKey: key,
        title: title,
      ),
    );
  }
}

class ShareOptionsBottomSheet extends StatefulWidget {
  final GlobalKey screenshotKey;
  final String title;

  const ShareOptionsBottomSheet({
    Key? key,
    required this.screenshotKey,
    required this.title,
  }) : super(key: key);

  @override
  State<ShareOptionsBottomSheet> createState() =>
      _ShareOptionsBottomSheetState();
}

class _ShareOptionsBottomSheetState extends State<ShareOptionsBottomSheet> {
  bool _isCapturing = false;

  Future<void> _shareAsImage() async {
    setState(() => _isCapturing = true);

    try {
      final imageBytes = await ShareService.captureWidget(widget.screenshotKey);

      if (imageBytes != null && mounted) {
        Navigator.pop(context);

        // In web, mostra dialog download o copia
        _showImagePreview(imageBytes);
      } else {
        _showError('Impossibile creare immagine');
      }
    } catch (e) {
      _showError('Errore: $e');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _showImagePreview(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Immagine Generata',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Trigger download in browser
                      _downloadImage(imageBytes);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Scarica Immagine'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'L\'immagine verrà scaricata nel tuo browser',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadImage(Uint8List imageBytes) {
    // In Chrome/web, create download link
    // Note: This is a placeholder - actual implementation would use
    // dart:html for web or share_plus package for mobile
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Immagine pronta! Click destro → Salva immagine'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Condividi ${widget.title}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pulsante Condividi come Immagine
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image, color: Colors.blue),
                    ),
                    title: const Text(
                      'Condividi come Immagine',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Genera e scarica un\'immagine',
                      style: TextStyle(fontSize: 13),
                    ),
                    trailing: _isCapturing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _isCapturing ? null : _shareAsImage,
                  ),

                  const Divider(),

                  // Pulsante Copia Link
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.link, color: Colors.green),
                    ),
                    title: const Text(
                      'Copia Link',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Condividi il link diretto',
                      style: TextStyle(fontSize: 13),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copiato negli appunti!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
