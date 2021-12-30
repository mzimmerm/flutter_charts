import 'dart:convert';
import 'dart:io';

// todo-00-last-last delete
void main() {
  var file = File('MY_FILE');

  file.writeAsStringSync(
    'MY_STRING',
    mode: FileMode.write,
    encoding: utf8,
    flush: true,
  );
}