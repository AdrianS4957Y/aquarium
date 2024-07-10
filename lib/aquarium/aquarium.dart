import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:aquarium/shark/shark.dart';
import 'package:aquarium/shark/shark_action.dart';
import 'package:uuid/uuid.dart';

import '../fish/fish.dart';
import '../fish/fish_action.dart';
import '../fish/fish_request.dart';
import '../fish/genders.dart';
import '../utils/fish_names.dart';
import 'fish_model.dart';

class Aquarium {
  int workTime = 0;
  final Random _random = Random();
  final LinkedHashMap<String, FishModel> _fishList = LinkedHashMap();
  final ReceivePort _mainReceivePort = ReceivePort();
  int _diedFishCount = 0;
  SendPort? sharkSendPort;
  Isolate? sharkIsolate;

  void runApp() {
    stdout.write("Enter initial fish count: ");
    final int count = int.tryParse(stdin.readLineSync() ?? '0') ?? 0;
    portListener();
    initial(count);
    createShark();
    Timer.periodic(Duration(seconds: 1), (timer) => workTime++);
  }

  void portListener() {
    _mainReceivePort.listen((value) {
      if (value is FishRequest) {
        switch (value.action) {
          case FishAction.sendPort:
            _fishList.update(
              value.fishId,
              (model) {
                (value.args as SendPort?)?.send(FishAction.startLife);
                return model.copyWith(
                  sendPort: (value.args as SendPort?),
                );
              },
            );
            break;
          case FishAction.fishDied:
            _fishDied(value.fishId);

            // print(toString());
            break;
          case FishAction.killIsolate:
            final model = _fishList[value.fishId];
            _fishKillIsolate(value.action, model);
            print(toString());
            break;
          case FishAction.needPopulate:
            population(value.fishId, value.args as Genders);
            break;
          default:
            break;
        }
      } else if (value is SendPort) {
        sharkSendPort = value;
        _checkFishCount();
      } else if (value == SharkAction.killFish) {
        _killRandomFish();
      }
    });
  }

  void _fishDied(fishId) {
    final model = _fishList[fishId];
    model?.sendPort?.send(FishAction.close);
    _diedFishCount++;
    _fishKillIsolate(fishId, model);
    if (_fishList.isEmpty) closeAquarium();
  }

  void _fishKillIsolate(fishId, model) {
    model?.isolate.kill(
      priority: Isolate.immediate,
    );
    _fishList.remove(fishId);
    _checkFishCount();
  }

  void _checkFishCount() {
    if (sharkSendPort != null) {
      final fishCount = _fishList.length;
      if (fishCount > 10) {
        sharkSendPort?.send({
          'action': SharkAction.start,
          'fishCount': fishCount,
        });
      } else {
        sharkSendPort?.send({'action': SharkAction.waiting});
      }
    }
  }

  Future<void> createShark() async {
    final String id = Uuid().v1();
    final shark = Shark(id: id, sendPort: _mainReceivePort.sendPort);
    sharkIsolate = await Isolate.spawn(Shark.run, shark);
  }

  void _killRandomFish() {
    if (_fishList.isNotEmpty) {
      final randomFishId =
          _fishList.keys.elementAt(_random.nextInt(_fishList.length));
      final model = _fishList[randomFishId];
      _fishDied(randomFishId);
      // _fishKillIsolate(randomFishId, model);
      print(
          '\x1B[31mShark ate fish with id \x1B[35m$randomFishId\x1B[0m (${model?.genders.name})\x1B[0m');
    }
  }

  void population(String fishId, Genders gender) {
    // print(_fishList.keys.length);
    if (_fishList.isNotEmpty) {
      final sortFishList = _fishList.entries
          .where(
            (element) => element.value.genders != gender,
          )
          .toList();
      // print(sortFishList);
      if (sortFishList.isNotEmpty) {
        final findIndex = _random.nextInt(sortFishList.length);
        final findFishId = sortFishList[findIndex].key;
        createFish(
          maleId: gender.isMale ? fishId : findFishId,
          femaleId: gender.isMale ? findFishId : fishId,
        );
      }
    } else {
      closeAquarium();
    }
  }

  void initial(int count) {
    for (int i = 0; i < count; i++) {
      createFish();
    }
  }

  void createFish({
    String? maleId,
    String? femaleId,
  }) async {
    final fishId = Uuid().v1(options: {
      "Male": maleId,
      "Female": femaleId,
    });
    final gender = _random.nextBool() ? Genders.male : Genders.female;
    final firstName = gender.isMale
        ? FishNames.maleFirst[_random.nextInt(FishNames.maleFirst.length)]
        : FishNames.femaleFirst[_random.nextInt(FishNames.femaleFirst.length)];
    final lastName = gender.isMale
        ? FishNames.maleLast[_random.nextInt(FishNames.maleLast.length)]
        : FishNames.femaleLast[_random.nextInt(FishNames.femaleLast.length)];
    final lifespan = Duration(seconds: _random.nextInt(60) + 10);
    final populateCount = _random.nextInt(3) + 1;
    final List<Duration> listPopulationTime = List.generate(
      populateCount,
      (index) => Duration(
          seconds: _random
                  .nextInt((_fishList.isNotEmpty ? _fishList.length : 15) + 5) +
              5),
    );

    final fish = Fish(
      id: fishId,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      lifespan: lifespan,
      listPopulationTime: listPopulationTime,
      sendPort: _mainReceivePort.sendPort,
    );
    final isolate = await Isolate.spawn(Fish.run, fish);
    _fishList[fishId] = FishModel(
      isolate: isolate,
      genders: gender,
    );
    print(toString());
    _checkFishCount();
  }

  void closeAquarium() {
    print('Aquarium is empty');
    exit(0);
  }

  @override
  String toString() {
    int fishCount = 0;
    int maleCount = 0;
    int femaleCount = 0;

    _fishList.forEach((key, value) {
      fishCount++;
      if (value.genders == Genders.male) {
        maleCount++;
      } else {
        femaleCount++;
      }
    });

    if (fishCount == 0) {
      closeAquarium();
    }
    return 'Aquarium info - Fish count: $fishCount, \x1B[36mMale fishes: $maleCount, \x1B[35mFemale fishes: $femaleCount,\x1B[31m Died fishes: $_diedFishCount\x1B[0m. Code work time: ${workTime ~/ 60} minutes, ${workTime % 60} seconds';
  }
}
