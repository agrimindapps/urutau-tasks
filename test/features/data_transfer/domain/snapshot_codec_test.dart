import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/data_snapshot.dart';

void main() {
  Map<String, Object?> baseDocument({Map<String, Object?>? dataOverride}) {
    return {
      'format_version': 1,
      'exported_at': '2026-09-25T12:00:00.000Z',
      'data': dataOverride ??
          {
            'tasks': <Object?>[],
            'subtasks': <Object?>[],
            'lists': <Object?>[],
            'groups': <Object?>[],
            'categories': <Object?>[],
            'tags': <Object?>[],
            'task_tags': <Object?>[],
            'recurring_series': <Object?>[],
            'my_day_entries': <Object?>[],
          },
    };
  }

  Map<String, Object?> task({String id = 't1', String? listId}) {
    return {
      'id': id,
      'title': 'T',
      'notes': '',
      'status': 'active',
      'status_before_trash': null,
      'created_at': '2026-09-25T12:00:00.000Z',
      'updated_at': '2026-09-25T12:00:00.000Z',
      'completed_at': null,
      'position': 0,
      'list_id': listId,
      'category_id': null,
      'priority': null,
      'due_date': null,
      'reminder': null,
      'series_id': null,
    };
  }

  String encode(Map<String, Object?> doc) => jsonEncode(doc);

  test('roundtrip preserva o retrato (CA-02/CA-03)', () {
    final doc = baseDocument(dataOverride: {
      'tasks': [task()],
      'subtasks': [
        {
          'id': 's1',
          'task_id': 't1',
          'description': 'Etapa',
          'is_completed': true,
          'position': 0,
        }
      ],
      'lists': <Object?>[],
      'groups': <Object?>[],
      'categories': <Object?>[],
      'tags': <Object?>[],
      'task_tags': <Object?>[],
      'recurring_series': <Object?>[],
      'my_day_entries': [
        {'id': 'e1', 'task_id': 't1', 'date': '2026-09-25', 'position': 0}
      ],
    });

    final decoded = DataSnapshot.decode(encode(doc));
    expect(decoded.tasks, hasLength(1));
    expect(decoded.tasks.single['id'], 't1');
    expect(decoded.subtasks.single['description'], 'Etapa');
    expect(decoded.myDayEntries.single['date'], '2026-09-25');

    final reencoded = DataSnapshot.decode(decoded.encode());
    expect(reencoded.tasks, decoded.tasks);
    expect(reencoded.subtasks, decoded.subtasks);
  });

  test('semântica temporal preservada (CA-03)', () {
    final doc = baseDocument(dataOverride: {
      'tasks': [
        {
          ...task(),
          'due_date': '2026-09-30',
          'reminder': '2026-10-01T09:00:00.000Z',
        }
      ],
      'subtasks': <Object?>[],
      'lists': <Object?>[],
      'groups': <Object?>[],
      'categories': <Object?>[],
      'tags': <Object?>[],
      'task_tags': <Object?>[],
      'recurring_series': <Object?>[],
      'my_day_entries': <Object?>[],
    });
    final decoded = DataSnapshot.decode(encode(doc));
    expect(decoded.tasks.single['due_date'], '2026-09-30');
    expect(decoded.tasks.single['reminder'], '2026-10-01T09:00:00.000Z');
  });

  test('JSON malformado e estrutura errada são rejeitados (CA-12)', () {
    expect(
      () => DataSnapshot.decode('não é json'),
      throwsA(isA<SnapshotException>().having(
        (e) => e.failure,
        'failure',
        SnapshotFailure.malformedJson,
      )),
    );
    expect(
      () => DataSnapshot.decode(encode({'format_version': 1})),
      throwsA(isA<SnapshotException>()),
    );
  });

  test('versão mais nova é rejeitada sem tocar nos dados (CA-13)', () {
    final doc = baseDocument();
    doc['format_version'] = 2;
    expect(
      () => DataSnapshot.decode(encode(doc)),
      throwsA(isA<SnapshotException>().having(
        (e) => e.failure,
        'failure',
        SnapshotFailure.unsupportedVersion,
      )),
    );
  });

  test('JSON inválido: id duplicado e referência quebrada (CA-12)', () {
    final duplicate = baseDocument(dataOverride: {
      'tasks': [task(), task()],
      'subtasks': <Object?>[],
      'lists': <Object?>[],
      'groups': <Object?>[],
      'categories': <Object?>[],
      'tags': <Object?>[],
      'task_tags': <Object?>[],
      'recurring_series': <Object?>[],
      'my_day_entries': <Object?>[],
    });
    expect(
      () => DataSnapshot.decode(encode(duplicate)),
      throwsA(isA<SnapshotException>().having(
        (e) => e.failure,
        'failure',
        SnapshotFailure.duplicateId,
      )),
    );

    final broken = baseDocument(dataOverride: {
      'tasks': <Object?>[],
      'subtasks': [
        {
          'id': 's1',
          'task_id': 'fantasma',
          'description': 'E',
          'is_completed': false,
          'position': 0,
        }
      ],
      'lists': <Object?>[],
      'groups': <Object?>[],
      'categories': <Object?>[],
      'tags': <Object?>[],
      'task_tags': <Object?>[],
      'recurring_series': <Object?>[],
      'my_day_entries': <Object?>[],
    });
    expect(
      () => DataSnapshot.decode(encode(broken)),
      throwsA(isA<SnapshotException>().having(
        (e) => e.failure,
        'failure',
        SnapshotFailure.brokenReference,
      )),
    );
  });

  test('campos desconhecidos com dados não são descartados (CA-12)', () {
    final doc = baseDocument(dataOverride: {
      'tasks': [
        {...task(), 'futuro_campo': 'dado'},
      ],
      'subtasks': <Object?>[],
      'lists': <Object?>[],
      'groups': <Object?>[],
      'categories': <Object?>[],
      'tags': <Object?>[],
      'task_tags': <Object?>[],
      'recurring_series': <Object?>[],
      'my_day_entries': <Object?>[],
    });
    expect(
      () => DataSnapshot.decode(encode(doc)),
      throwsA(isA<SnapshotException>().having(
        (e) => e.failure,
        'failure',
        SnapshotFailure.unknownField,
      )),
    );
  });

  test('campo desconhecido nulo é aceito (tolerância sem dados)', () {
    final doc = baseDocument(dataOverride: {
      'tasks': [
        {...task(), 'futuro_campo': null},
      ],
      'subtasks': <Object?>[],
      'lists': <Object?>[],
      'groups': <Object?>[],
      'categories': <Object?>[],
      'tags': <Object?>[],
      'task_tags': <Object?>[],
      'recurring_series': <Object?>[],
      'my_day_entries': <Object?>[],
    });
    expect(DataSnapshot.decode(encode(doc)).tasks, hasLength(1));
  });
}
