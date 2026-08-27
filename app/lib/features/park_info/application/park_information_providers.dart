import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/data/park_info/bundled_park_info_database.dart';
import 'package:ladepark_explorer/data/park_info/sqlite/sqlite_park_information_repository.dart';
import 'package:ladepark_explorer/features/park_info/domain/models/park_information.dart';
import 'package:ladepark_explorer/features/park_info/domain/repositories/park_information_repository.dart';

final parkInformationRepositoryProvider =
    FutureProvider<ParkInformationRepository>((ref) async {
      final path = await const BundledParkInfoDatabase().resolve();
      final repository = SqliteParkInformationRepository.open(path);
      ref.onDispose(repository.close);
      return repository;
    });

final parkInformationProvider =
    FutureProvider.family<ParkInformation?, ({String ids, bool german})>((
      ref,
      argument,
    ) async {
      final repository = await ref.watch(
        parkInformationRepositoryProvider.future,
      );
      return repository.findForStations(
        argument.ids.split('|'),
        german: argument.german,
      );
    });
