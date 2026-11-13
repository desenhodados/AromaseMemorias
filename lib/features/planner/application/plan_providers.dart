import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_storage.dart';
import '../data/plan_repository.dart';
import '../domain/plan_entry.dart';

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => HivePlanRepository(Hive.box(HiveBoxes.plan)),
);

final planProvider = StreamProvider<Map<String, PlanEntry>>(
  (ref) => ref.watch(planRepositoryProvider).watchAll(),
);
