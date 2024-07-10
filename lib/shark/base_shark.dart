import 'dart:async';

abstract class BaseShark {
  final String id;
  const BaseShark({
    required this.id,
  });
  FutureOr<void> waiting();
  FutureOr<void> start(fishCount);
}
