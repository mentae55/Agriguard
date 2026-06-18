// lib/domain/usecases/fetch_soil_data.dart
import '../../data/model/soil_model.dart';
import '../../data/repositories/soil_repository.dart';

class FetchSoilDataUseCase {
  final SoilRepository _repository;

  FetchSoilDataUseCase({required SoilRepository repository})
      : _repository = repository;

  Stream<SoilSnapshot> call() => _repository.soilStream;
}