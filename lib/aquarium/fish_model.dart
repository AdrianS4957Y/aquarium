import 'dart:isolate';


import '../fish/genders.dart';

class FishModel {
  final SendPort? sendPort;
  final Isolate isolate;
  final Genders genders;

  const FishModel({
    this.sendPort,
    required this.isolate,
    required this.genders,
  });

  FishModel copyWith({
    SendPort? sendPort,
    Isolate? isolate,
    Genders? genders,
  }) =>
      FishModel(
        sendPort: sendPort ?? this.sendPort,
        isolate: isolate ?? this.isolate,
        genders: genders ?? this.genders,
      );
}
