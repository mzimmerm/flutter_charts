// Top level function which we can temporarily plug in code
//   to generate test data, which can be included in tests (by cutting output from terminal, pasting to test)

void collectTestData(String functionName, List passedParamsInOrder, Object result) {
  // todo-00-last-last
  passedParamsInOrder.add(result);
  List paramsAndResult = passedParamsInOrder;
  print ('$functionName: ${paramsAndResult.toString()}'); 
}
