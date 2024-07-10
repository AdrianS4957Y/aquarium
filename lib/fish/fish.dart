import 'dart:async';
import 'dart:isolate';
// ignore: unused_import
import 'dart:math';

import 'base_fish.dart';
import 'fish_action.dart';
import 'fish_request.dart';

class Fish extends BaseFish {
  Fish({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.gender,
    required super.lifespan,
    required super.listPopulationTime,
    required this.sendPort,
  });

  ReceivePort? _receiverPort;
  SendPort? sendPort;
  Timer? _populationTimer;
  Timer? _lifeTimer;

  @override
  FutureOr<void> died() {
    sendPort?.send(
      FishRequest(
        fishId: id,
        action: FishAction.fishDied,
      ),
    );
    printMessage(true);
  }

  @override
  FutureOr<void> population() {
    int secondCount = 1;
    _populationTimer = Timer.periodic(
      Duration(seconds: 1),
      (timer) {
        if (listPopulationTime.isNotEmpty) {
          // print(listPopulationTime);
          if (secondCount >= listPopulationTime.first.inSeconds) {
            // print(listPopulationTime);
            //(Random().nextInt(listPopulationTime.length)) + 5) {
            //listPopulationTime.first.inSeconds
            sendPort?.send(
              FishRequest(
                fishId: id,
                action: FishAction.needPopulate,
                args: gender,
              ),
            );
            listPopulationTime.remove(listPopulationTime.first);
            secondCount = 1;
          }
        } else {
          timer.cancel();
        }
        secondCount++;
      },
    );
  }

  @override
  FutureOr<void> startLife() {
    _lifeTimer ??= Timer(lifespan, died);
    population();
  }

  void createReceivePort() {
    _receiverPort = ReceivePort();
    _actionListener();
    sendPort?.send(
      FishRequest(
        fishId: id,
        action: FishAction.sendPort,
        args: _receiverPort?.sendPort,
      ),
    );
    printMessage(false);
  }

  FutureOr<void> _close() {
    _populationTimer?.cancel();
    _lifeTimer?.cancel();
    _receiverPort?.close();
    _receiverPort = null;
    // printMessage(true);
    sendPort?.send(
      FishRequest(
        fishId: id,
        action: FishAction.killIsolate,
      ),
    );
    sendPort = null;
  }

  void _actionListener() {
    _receiverPort?.listen((message) {
      if (message is FishAction) {
        switch (message) {
          case FishAction.startLife:
            startLife();
            break;
          case FishAction.close:
            died();
            _close();
            break;
          default:
            break;
        }
      }
    });
  }

  static run(Fish fish) {
    fish.createReceivePort();
  }

  void printMessage(bool isDied) {
    if (isDied) {
      print(
          '\x1B[31mFish $firstName $lastName (${gender.name}) is dead. ID: $id\x1B[0m');
    } else {
      print(
          '\x1B[32mCreated New Fish: $firstName $lastName, id: $id (${gender.name})\x1B[0m');
    }
  }
}
