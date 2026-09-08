import 'package:flutter_test/flutter_test.dart';
import 'package:vetos/models/meteo.dart';

void main() {
  test('THI статусы совпадают со шкалой радара', () {
    expect(ThiStatus.of(64.5).label, 'норма');
    expect(ThiStatus.of(69).label, 'внимание');
    expect(ThiStatus.of(73).label, 'стресс');
    expect(ThiStatus.of(81).label, 'экстрим');
  });
}
