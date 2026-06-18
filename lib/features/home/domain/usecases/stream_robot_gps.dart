// lib/domain/usecases/stream_robot_gps.dart
import '../../data/model/gps_model.dart';
import '../../data/repositories/gps_repository.dart';

class StreamRobotGpsUseCase {
  final GpsRepository _repository;

  StreamRobotGpsUseCase({required GpsRepository repository})
      : _repository = repository;

  Stream<RobotGpsModel> call(String deviceMac) =>
      _repository.getRobotGpsStream(deviceMac);
}