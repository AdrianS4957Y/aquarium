

import 'fish_action.dart';

class FishRequest {
  final String fishId;
  final FishAction action;
  final Object? args;

  const FishRequest({
    required this.fishId,
    required this.action,
    this.args,
  });
}
