import 'package:http_parser/http_parser.dart';
import 'dio_http_adapter.dart' as http;

/// Builds a multipart part the backend can actually identify.
///
/// Two things go wrong otherwise, and both only bite on web (the PWA):
///
/// * **Filename has no extension.** On Android `takePicture()` writes a real
///   file, so `XFile.name` is something like `CAP1234.jpg`. On web the photo is
///   a blob and the name is a bare UUID. A backend that infers the type from
///   the extension rejects that with 400.
/// * **Part content type defaults to `application/octet-stream`.** MultipartFile
///   never guesses it, so an upload endpoint validating `image/*` refuses the
///   part no matter what the bytes are.
///
/// Passing an explicit filename and content type makes the request identical
/// on every platform.
http.MultipartFile buildUploadPart(
  String field,
  List<int> bytes, {
  required String? name,
  String? mimeType,
  bool isPdf = false,
}) {
  final mime = _resolveMime(mimeType, name, isPdf);
  return http.MultipartFile.fromBytes(
    field,
    bytes,
    filename: _resolveFilename(name, mime),
    contentType: MediaType.parse(mime),
  );
}

String _resolveMime(String? mimeType, String? name, bool isPdf) {
  if (mimeType != null && mimeType.contains('/')) return mimeType;

  final ext = _extensionOf(name);
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
  }
  return isPdf ? 'application/pdf' : 'image/jpeg';
}

/// Keeps the original name when it's usable, otherwise synthesises one with an
/// extension that matches [mime].
String _resolveFilename(String? name, String mime) {
  if (name != null && _extensionOf(name).isNotEmpty) return name;

  final subtype = mime.split('/').last.toLowerCase();
  final ext = subtype == 'jpeg' ? 'jpg' : subtype;
  return 'upload_${DateTime.now().millisecondsSinceEpoch}.$ext';
}

String _extensionOf(String? name) {
  if (name == null) return '';
  final base = name.split('/').last.split('\\').last;
  final dot = base.lastIndexOf('.');
  // Guard against a trailing dot and against a "." inside a UUID-ish name.
  if (dot <= 0 || dot == base.length - 1) return '';
  return base.substring(dot + 1).toLowerCase();
}
