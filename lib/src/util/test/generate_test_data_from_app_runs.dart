// Top level function which we can temporarily plug in code
//   to generate test data, which can be included in tests (by pasting them)

// todo-00-last-delete - not null safe : import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

void collectTestData(String functionName, List passedParamsInOrder, Object result) {
  // todo-00-last-last
  passedParamsInOrder.add(result);
  List paramsAndResult = passedParamsInOrder;

/*
//  File('$filePath/$functionName').writeAsStringSync(
  var file = File('$functionName');
  
  file.writeAsStringSync(
    'paramsAndResult.toString()',
    mode: FileMode.write,
    encoding: utf8,
    flush: true,
  );
*/

// getLocalPathAndSaveFile();
  print ('$functionName: ${paramsAndResult.toString()}');
}

/*  todo-00-last-delete but look at await async
Future<void> getLocalPathAndSaveFile() async {
  String filePath = await getFilePath();
  saveLocalFile(filePath);
}

Future<String> getFilePath() async {
  Directory appDocumentsDirectory = await getApplicationDocumentsDirectory(); // 1
  String appDocumentsPath = appDocumentsDirectory.path; // 2
  String filePath = '$appDocumentsPath/demoTextFile.txt'; // 3

  return filePath;
}

void saveLocalFile(String path) async {
  File file = File(path); // 1
  file.writeAsString('This is my demo text that will be saved to : demoTextFile.txt'); // 2
}
*/
