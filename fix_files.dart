import 'dart:io';

void main() {
  // Target the src directory to catch Kotlin/Java files as well as res
  final dir = Directory('android/app/src');
  if (!dir.existsSync()) {
    print('Directory not found: ${dir.path}');
    return;
  }
  
  print('Scanning ${dir.path}...');
  
  int count = 0;
  for (var entity in dir.listSync(recursive: true)) {
    if (entity is File) {
      try {
        final bytes = entity.readAsBytesSync();
        entity.deleteSync();
        File(entity.path).writeAsBytesSync(bytes);
        count++;
      } catch (e) {
        print('Failed to fix ${entity.path}: $e');
      }
    }
  }
  print('Finished. processed $count files.');
}
