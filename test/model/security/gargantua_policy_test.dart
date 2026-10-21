import 'package:aves/model/security/gargantua.dart';
import 'package:flutter_test/flutter_test.dart';

// Truth table of the Gargantua exit policy, without any `BuildContext`.
void main() {
  const shareOnly = {GargantuaCategory.share};

  GargantuaPolicy policy({
    bool master = true,
    Set<GargantuaCategory> categories = shareOnly,
    bool rule = true,
    bool itemLocks = false,
    bool storeError = false,
  }) => GargantuaPolicy(
    masterEnabled: master,
    enabledCategories: categories,
    requireMasterCode: rule,
    itemLocksEnabled: itemLocks,
    storeError: storeError,
  );

  GargantuaDecision decide(
    GargantuaPolicy value, {
    GargantuaCategory category = GargantuaCategory.share,
    bool marked = false,
  }) => value.decide(category: category, hasMarkedItems: marked);

  group('Gargantua policy', () {
    test('master off lets every exit through', () {
      expect(decide(policy(master: false), marked: true), GargantuaDecision.allow);
      expect(decide(policy(master: false, rule: false)), GargantuaDecision.allow);
    });

    test('enabled master without the category lets the exit through', () {
      expect(decide(policy(categories: {})), GargantuaDecision.allow);
      expect(decide(policy(categories: {GargantuaCategory.open})), GargantuaDecision.allow);
      expect(decide(policy(categories: {GargantuaCategory.open}), category: GargantuaCategory.open), GargantuaDecision.askMasterCode);
    });

    test('a marked item asks for its own lock, without the Master Code on top', () {
      expect(decide(policy(itemLocks: true), marked: true), GargantuaDecision.askItemLock);
      // even with the Master Code rule on: a single, stronger factor
      expect(decide(policy(itemLocks: true, rule: true), marked: true), GargantuaDecision.askItemLock);
    });

    test('marks are ignored when item locks are off', () {
      expect(decide(policy(itemLocks: false), marked: true), GargantuaDecision.askMasterCode);
    });

    test('unmarked items follow the Master Code rule', () {
      expect(decide(policy(itemLocks: true), marked: false), GargantuaDecision.askMasterCode);
      expect(decide(policy(itemLocks: true, rule: false), marked: false), GargantuaDecision.allow);
    });

    test('no rule and no marked item lets the exit through', () {
      expect(decide(policy(rule: false), marked: false), GargantuaDecision.allow);
    });

    test('an unreadable secure store fails closed', () {
      expect(decide(policy(storeError: true), marked: true), GargantuaDecision.deny);
      expect(decide(policy(storeError: true, master: false)), GargantuaDecision.deny);
      expect(decide(policy(storeError: true, categories: {})), GargantuaDecision.deny);
    });
  });
}
