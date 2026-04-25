import 'lib/services/task_parser_service.dart';

void main() {
  final parser = TaskParserService();
  
  final res1 = parser.parse("I want to go to the gym at ten PM today");
  print("ENG 1: title='${res1.title}' scheduledAt=${res1.scheduledAt}");

  final res2 = parser.parse("أريد أن أذهب إلى الجيم الساعة العاشرة مساءً اليوم");
  print("AR 1: title='${res2.title}' scheduledAt=${res2.scheduledAt}");
}
