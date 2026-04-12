import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class RemoteFailure extends Failure {
  final int? statusCode;

  const RemoteFailure(super.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Sem conexão com a internet.');
}
