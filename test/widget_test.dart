import 'package:flutter_test/flutter_test.dart';
import 'package:vetos/models/feeds.dart';
import 'package:vetos/models/meteo.dart';

void main() {
  test('THI статусы совпадают со шкалой радара', () {
    expect(ThiStatus.of(64.5).label, 'норма');
    expect(ThiStatus.of(69).label, 'внимание');
    expect(ThiStatus.of(73).label, 'стресс');
    expect(ThiStatus.of(81).label, 'экстрим');
  });

  test('OutlookSlice парсится и находит станцию', () {
    final slice = OutlookSlice.fromJson({
      'generatedAt': '2026-09-07T17:42:46.500Z',
      'horizon': '7 дней',
      'stations': [
        {
          'id': 'taganrog',
          'name': 'Таганрог',
          'thiMax7': 77.7,
          'days72': 3,
          'days80': 0,
          'precip7': 0.7,
          'perDay': [68.1, 66.6, 68.6, 71.8, 74, 74.2, 77.7],
        },
      ],
      'digest': ['Таганрог: THI>72 — 3 дн из 7'],
    });
    expect(slice.horizon, '7 дней');
    final st = slice.byId('taganrog');
    expect(st, isNotNull);
    expect(st!.thiMax7, 77.7);
    expect(st.days72, 3);
    expect(st.days80, 0);
    expect(st.perDay.length, 7);
    expect(st.perDay[4], 74);
    expect(slice.digest, hasLength(1));
    expect(slice.byId('нет-такой'), isNull);
  });

  test('OutbreaksSlice: свежие — сначала новые, метки дат', () {
    final slice = OutbreaksSlice.fromJson({
      'updated': '2026-09-06',
      'total': 33,
      'outbreaks': [
        {'k': 'rabies', 'n': 'Бешенство', 'dt': '2026-06-24', 'r': 'РО'},
        {'k': 'asf', 'n': 'АЧС', 'dt': '2026-08-01', 'r': 'РО'},
        {'k': 'svc', 'n': 'svc', 'dt': '2026-06-19', 'r': 'РО'},
      ],
    });
    expect(slice.total, 33);
    expect(slice.updatedLabel, '06.09');
    final recent = slice.recent(3);
    expect(recent.first.name, 'АЧС');
    expect(recent.first.dateLabel, '01.08');
    expect(recent[1].dateLabel, '24.06');
    // запись без даты не валит сортировку
    final noDate = OutbreaksSlice.fromJson({
      'total': 1,
      'outbreaks': [
        {'k': 'x', 'n': 'X'},
      ],
    });
    expect(noDate.recent(1).single.name, 'X');
  });

  test('VerifySlice: MAE из model.mae, поля деградируют в null', () {
    final v = VerifySlice.fromJson({
      'generatedAt': '2026-09-07T19:23:35.366Z',
      'verdict': 'малые',
      'thi': 1.1,
      'model': {
        'days': 30,
        'stations': 49,
        'mae': {'t': 1, 'rh': 5.4, 'wind': 1, 'thi': 1.1},
      },
    });
    expect(v.verdict, 'малые');
    expect(v.thiMae, 1.1);
    expect(v.days, 30);
    expect(v.stations, 49);

    final bare = VerifySlice.fromJson({'verdict': '—'});
    expect(bare.thiMae, isNull);
    expect(bare.days, isNull);
  });

  test('WeeklySlice: дайджест-строки на месте', () {
    final w = WeeklySlice.fromJson({
      'generatedAt': '2026-09-06T18:34:23.240Z',
      'from': '2026-09-06',
      'to': '2026-09-06',
      'digest': ['Сальск: 1 ч THI>72', 'покрытие архива: 1 дн из 7'],
    });
    expect(w.from, w.to);
    expect(w.digest, hasLength(2));
  });
}
