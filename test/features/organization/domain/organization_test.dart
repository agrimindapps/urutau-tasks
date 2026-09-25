import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization.dart';

void main() {
  group('Nomes (RF-01)', () {
    test('rejeita nome vazio ou só espaços', () {
      for (final invalid in ['', '   ', '\t']) {
        expect(
          () => TaskList.create(id: 'l1', name: invalid),
          throwsA(isA<OrganizationException>().having(
            (e) => e.failure,
            'failure',
            OrganizationFailure.emptyName,
          )),
        );
      }
      expect(
        () => TaskGroup.create(id: 'g1', name: '  '),
        throwsA(isA<OrganizationException>()),
      );
      expect(
        () => TaskCategory.create(id: 'c1', name: ''),
        throwsA(isA<OrganizationException>()),
      );
      expect(
        () => TaskTag.create(id: 't1', name: ' '),
        throwsA(isA<OrganizationException>()),
      );
    });

    test('trim é aplicado nos nomes', () {
      expect(TaskList.create(id: 'l1', name: '  Casa  ').name, 'Casa');
      expect(TaskGroup.create(id: 'g1', name: ' Trabalho ').name, 'Trabalho');
    });
  });

  group('Tags (RF-09, CA-12)', () {
    test('normaliza identidade com trim e minúsculas', () {
      final tag = TaskTag.create(id: 't1', name: ' Trabalho ');
      expect(tag.name, 'Trabalho');
      expect(tag.normalizedName, 'trabalho');

      expect(tag.sameIdentity('trabalho'), isTrue);
      expect(tag.sameIdentity('TRABALHO'), isTrue);
      expect(tag.sameIdentity(' trabalho '), isTrue);
      expect(tag.sameIdentity('Casa'), isFalse);
    });

    test('renomear preserva a identidade normalizada correta', () {
      final tag = TaskTag.create(id: 't1', name: 'Antes');
      final renamed = tag.rename(' Casa ');
      expect(renamed.name, 'Casa');
      expect(renamed.normalizedName, 'casa');
    });
  });

  group('Listas e grupos (RF-02, RF-04)', () {
    test('mover para grupo e remover grupo preservam identidade', () {
      final list = TaskList.create(id: 'l1', name: 'Casa');
      final inGroup = list.moveToGroup('g1');
      expect(inGroup.groupId, 'g1');

      final withoutGroup = inGroup.moveToGroup(null);
      expect(withoutGroup.groupId, isNull);
      expect(withoutGroup.id, 'l1');
      expect(withoutGroup.name, 'Casa');
    });

    test('renomear preserva posição e grupo', () {
      final list = TaskList.create(
        id: 'l1',
        name: 'Antes',
        position: 3,
        groupId: 'g1',
      );
      final renamed = list.rename('Depois');
      expect(renamed.position, 3);
      expect(renamed.groupId, 'g1');
      expect(renamed.name, 'Depois');
    });
  });
}
