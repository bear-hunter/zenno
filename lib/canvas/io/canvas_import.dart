import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/pdf/pdf_raster_service.dart';
import 'package:zenno/core/util/id.dart';

/// A picked-and-prepared image, ready to become an [ImageElement].
///
/// The importer has already copied the picked file into the app documents
/// directory ([storedPath]) and decoded its bitmap ([raster]); the controller
/// only has to place it on the canvas.
@immutable
class ImportedImage {
  /// Creates an imported-image descriptor.
  const ImportedImage({
    required this.storedPath,
    required this.intrinsicSize,
    required this.raster,
  });

  /// Absolute path of the app-local copy of the picture.
  final String storedPath;

  /// Native pixel size of the decoded image.
  final ui.Size intrinsicSize;

  /// The decoded bitmap, handed straight to the first [ImageElement] so the
  /// picture is visible the instant it lands on the canvas.
  final ui.Image raster;
}

/// A picked-and-prepared PDF, ready to become one [PdfElement] per page.
///
/// The importer has copied the PDF into the app documents directory
/// ([storedPath]) and probed it for [pages]; the controller creates an element
/// per page and schedules each page's raster lazily.
@immutable
class ImportedPdf {
  /// Creates an imported-PDF descriptor.
  const ImportedPdf({
    required this.storedPath,
    required this.originalFileName,
    required this.pages,
  });

  /// Absolute path of the app-local copy of the PDF.
  final String storedPath;

  /// The PDF's original file name, kept for display / persistence metadata.
  final String originalFileName;

  /// One entry per page, in document order, with page number and size.
  final List<PdfPageInfo> pages;
}

/// Picks media files and stages them for placement on the canvas.
///
/// This is the engine's import boundary. It uses `file_picker` to let the user
/// choose an image or a PDF, then **copies the chosen file into the app's
/// documents directory** (via `path_provider`). The copy matters: the OS file
/// picker hands back a path into a cache or a content-provider location that
/// is not guaranteed to survive — copying gives the element a stable,
/// app-owned path that step 1.7 can persist verbatim.
///
/// The class is stateless apart from the shared [PdfRasterService] it borrows
/// for probing PDFs; the controller owns that service's lifetime.
class CanvasImporter {
  /// Creates an importer that probes PDFs via [pdfRasterService].
  const CanvasImporter({required this.pdfRasterService});

  /// Shared PDF service, used here only to probe a picked PDF for its pages.
  final PdfRasterService pdfRasterService;

  /// Sub-directory of the app documents directory holding imported media.
  static const String _mediaDirName = 'canvas_media';

  /// Opens the system picker for a single image, copies it app-local and
  /// decodes it.
  ///
  /// Returns `null` if the user cancels the picker. Throws if the picked file
  /// cannot be read or decoded.
  Future<ImportedImage?> pickImage() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
    );
    final String? sourcePath = _singlePath(result);
    if (sourcePath == null) {
      return null;
    }

    final String storedPath = await _copyIntoMediaDir(sourcePath);
    final Uint8List bytes = await File(storedPath).readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    codec.dispose();
    final ui.Image image = frame.image;

    return ImportedImage(
      storedPath: storedPath,
      intrinsicSize: ui.Size(
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      raster: image,
    );
  }

  /// Opens the system picker for a single PDF, copies it app-local and probes
  /// its pages.
  ///
  /// Returns `null` if the user cancels the picker. Throws if the picked file
  /// is not a readable PDF.
  Future<ImportedPdf?> pickPdf() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
    );
    final String? sourcePath = _singlePath(result);
    if (sourcePath == null) {
      return null;
    }

    final String storedPath = await _copyIntoMediaDir(sourcePath);
    final List<PdfPageInfo> pages = await pdfRasterService.probe(storedPath);

    return ImportedPdf(
      storedPath: storedPath,
      originalFileName: result?.files.first.name ?? _baseName(sourcePath),
      pages: pages,
    );
  }

  /// Extracts the single picked file's path from a picker [result].
  ///
  /// Returns `null` when the user cancelled (no result) or the platform did
  /// not surface a filesystem path for the pick.
  static String? _singlePath(FilePickerResult? result) {
    if (result == null || result.files.isEmpty) {
      return null;
    }
    return result.files.first.path;
  }

  /// Copies [sourcePath] into the app documents media directory.
  ///
  /// The destination file name is a fresh uuid plus the original extension, so
  /// two imports of the same-named file never collide. Returns the absolute
  /// path of the copy.
  Future<String> _copyIntoMediaDir(String sourcePath) async {
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final Directory mediaDir = Directory(
      '${docsDir.path}${Platform.pathSeparator}$_mediaDirName',
    );
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final String destName = '${newId()}${_extension(sourcePath)}';
    final String destPath =
        '${mediaDir.path}${Platform.pathSeparator}$destName';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// Returns the file-name component of [path] (after the last separator).
  static String _baseName(String path) {
    final int slash = path.lastIndexOf(RegExp(r'[\\/]'));
    return slash < 0 ? path : path.substring(slash + 1);
  }

  /// Returns the lower-cased extension of [path] including the leading dot,
  /// or an empty string when the file name has no extension.
  static String _extension(String path) {
    final String base = _baseName(path);
    final int dot = base.lastIndexOf('.');
    if (dot <= 0) {
      return '';
    }
    return base.substring(dot).toLowerCase();
  }
}
