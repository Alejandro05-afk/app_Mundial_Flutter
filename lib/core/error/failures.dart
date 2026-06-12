abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure() : super('La solicitud tardó demasiado. Verifica tu conexión.');
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
