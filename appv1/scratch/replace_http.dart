import 'dart:io';

void main() {
  final dir = Directory('lib/features/teacher');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  int updated = 0;
  for (var file in files) {
    var content = file.readAsStringSync();
    
    // Look for the http import
    if (content.contains("import 'package:http/http.dart' as http;")) {
      content = content.replaceAll(
        "import 'package:http/http.dart' as http;",
        "import 'package:appv1/core/network/dio_http_adapter.dart' as http;"
      );
      file.writeAsStringSync(content);
      updated++;
    }
  }
  print('Updated $updated files in teacher portal to use Dio adapter.');
}
