// ========================================
// PRINTER SERVICE - WINDOWS
// Handles printing via Windows Print API
// ========================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class PrinterService {
  // ========================================
  // GET AVAILABLE PRINTERS
  // ========================================

  Future<List<Printer>> getAvailablePrinters() async {
    try {
      final printers = await Printing.listPrinters();
      return printers;
    } catch (e) {
      throw PrinterException('Failed to get printers: $e');
    }
  }

  // ========================================
  // PRINT FILE
  // ========================================

  Future<bool> printFile({
    required Uint8List fileData,
    required String fileName,
    required String fileExtension,
    Printer? printer,
  }) async {
    try {
      // Check if file is PDF
      if (fileExtension.toLowerCase() == '.pdf') {
        return await _printPDF(fileData, fileName, printer);
      } else if (_isImageFile(fileExtension)) {
        return await _printImage(fileData, fileName, printer);
      } else if (_isTextFile(fileExtension)) {
        return await _printText(fileData, fileName, printer);
      } else {
        throw PrinterException(
          'Unsupported file type: $fileExtension. '
          'Supported: PDF, Image (PNG, JPG, GIF), Text (TXT)',
        );
      }
    } catch (e) {
      throw PrinterException('Print failed: $e');
    }
  }

  // ========================================
  // PRINT PDF
  // ========================================

  Future<bool> _printPDF(
    Uint8List pdfData,
    String fileName,
    Printer? printer,
  ) async {
    try {
      await Printing.printPdf(
        name: fileName,
        printer: printer,
        document: pdf.PdfDocument(
          deflate: pdf.zlib.Codec(),
        )..save(),
        format: PdfPageFormat.a4,
      );
      return true;
    } catch (e) {
      throw PrinterException('PDF print failed: $e');
    }
  }

  // ========================================
  // PRINT IMAGE
  // ========================================

  Future<bool> _printImage(
    Uint8List imageData,
    String fileName,
    Printer? printer,
  ) async {
    try {
      // Create PDF with image
      final pdf_doc = pdf.PdfDocument();
      final page = pdf_doc.addPage(
        pdf.PdfPage(
          pageFormat: PdfPageFormat.a4,
          margin: pdf.PdfEdgeInsets.all(10),
        ),
      );

      // Decode and add image
      final image = pdf.PdfImage.fromImageProvider(
        document: pdf_doc,
        image: MemoryImage(imageData),
      );

      page.canvas.drawImage(image, 0, 0, width: 200, height: 200);

      // Print
      await Printing.layoutPdf(
        name: fileName,
        printer: printer,
        format: PdfPageFormat.a4,
        onLayout: (PdfPageFormat format) async => pdf_doc.save(),
      );

      return true;
    } catch (e) {
      throw PrinterException('Image print failed: $e');
    }
  }

  // ========================================
  // PRINT TEXT
  // ========================================

  Future<bool> _printText(
    Uint8List textData,
    String fileName,
    Printer? printer,
  ) async {
    try {
      // Decode text
      final text = String.fromCharCodes(textData);

      // Create PDF with text
      final pdf_doc = pdf.PdfDocument();
      final page = pdf_doc.addPage(
        pdf.PdfPage(
          pageFormat: PdfPageFormat.a4,
          margin: pdf.PdfEdgeInsets.all(20),
        ),
      );

      // Add text
      page.canvas.drawString(
        pdf.PdfFont.helvetica(pdf_doc),
        12,
        text,
      );

      // Print
      await Printing.layoutPdf(
        name: fileName,
        printer: printer,
        format: PdfPageFormat.a4,
        onLayout: (PdfPageFormat format) async => pdf_doc.save(),
      );

      return true;
    } catch (e) {
      throw PrinterException('Text print failed: $e');
    }
  }

  // ========================================
  // PRINT TO FILE
  // ========================================

  Future<bool> printToFile({
    required Uint8List fileData,
    required String fileName,
    required String fileExtension,
    required String outputPath,
  }) async {
    try {
      final file = File(outputPath);

      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }

      await file.writeAsBytes(fileData);
      return true;
    } catch (e) {
      throw PrinterException('Print to file failed: $e');
    }
  }

  // ========================================
  // PRINT PREVIEW
  // ========================================

  Future<List<int>> generatePrintPreview({
    required Uint8List fileData,
    required String fileExtension,
  }) async {
    try {
      if (fileExtension.toLowerCase() == '.pdf') {
        return fileData.toList();
      } else if (_isImageFile(fileExtension)) {
        // Image is already previewable
        return fileData.toList();
      } else if (_isTextFile(fileExtension)) {
        // For text, convert to bytes for preview
        return fileData.toList();
      } else {
        throw PrinterException('Cannot preview file type: $fileExtension');
      }
    } catch (e) {
      throw PrinterException('Preview generation failed: $e');
    }
  }

  // ========================================
  // HELPER: CHECK IF IMAGE FILE
  // ========================================

  bool _isImageFile(String extension) {
    final ext = extension.toLowerCase();
    return ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'].contains(ext);
  }

  // ========================================
  // HELPER: CHECK IF TEXT FILE
  // ========================================

  bool _isTextFile(String extension) {
    final ext = extension.toLowerCase();
    return ['.txt', '.log', '.md', '.csv', '.json', '.xml'].contains(ext);
  }

  // ========================================
  // GET DEFAULT PRINTER
  // ========================================

  Future<Printer?> getDefaultPrinter() async {
    try {
      final printers = await getAvailablePrinters();
      if (printers.isEmpty) {
        return null;
      }

      // Try to find default printer
      for (final printer in printers) {
        if (printer.isDefault) {
          return printer;
        }
      }

      // Return first printer if no default
      return printers.first;
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // VALIDATE PRINTER
  // ========================================

  Future<bool> validatePrinter(Printer printer) async {
    try {
      final printers = await getAvailablePrinters();
      return printers.any((p) => p.id == printer.id);
    } catch (e) {
      return false;
    }
  }
}

// ========================================
// PRINTER EXCEPTION
// ========================================

class PrinterException implements Exception {
  final String message;

  PrinterException(this.message);

  @override
  String toString() => message;
}
