import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:aquarium/shark/base_shark.dart';
import 'package:aquarium/shark/shark_action.dart';

class Shark extends BaseShark {
  Shark({
    required super.id,
    required this.sendPort,
  });

  ReceivePort? _receivePort;
  SendPort? sendPort;
  Timer? _timer;
  Random random = Random();

  @override
  FutureOr<void> start(fishCount) {
    if (_timer != null) {
      _timer?.cancel();
    }
    int interval = // fishCount > 30 ? 2 : fishCount > 20 ? 5 : 10;
        Random().nextInt(30 ~/ fishCount) + 5;
    //fishCount > 30 ? 2 : fishCount > 20 ? 5: 10;
    _timer = Timer.periodic(Duration(seconds: interval), (timer) {
      _killFish();
    });
  }

  @override
  FutureOr<void> waiting() {
    _timer?.cancel();
  }

  void _killFish() {
    sendPort?.send(SharkAction.killFish);
  }

  void createReceivePort() {
    _receivePort = ReceivePort();
    _listener();
    sendPort?.send(_receivePort!.sendPort);
  }

  void _listener() {
    _receivePort?.listen((message) {
      if (message is Map<String, dynamic>) {
        switch (message['action']) {
          case SharkAction.start:
            if (_timer?.isActive ?? false) {
              return;
            } else {
              start(message['fishCount']);
            }
            break;
          case SharkAction.waiting:
            waiting();
            break;
          default:
            break;
        }
      }
    });
  }

  static run(Shark shark) {
    shark.createReceivePort();
  }
}
