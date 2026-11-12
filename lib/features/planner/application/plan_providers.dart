import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_storage.dart';
import '../data/plan_repository.dart';

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => HivePlanRepository(Hive.box(HiveBoxes.plan)),
);

final planProvider = StreamProvider<Map<String, String>>(
  (ref) => ref.watch(planRepositoryProvider).watchAll(),
);
