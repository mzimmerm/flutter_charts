import 'dart:convert';
import 'dart:io';

void main() {
  var file = File('MY_FILE');

  file.writeAsStringSync(
    'MY_STRING',
    mode: FileMode.write,
    encoding: utf8,
    flush: true,
  );
}