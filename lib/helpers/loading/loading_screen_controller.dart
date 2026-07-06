import 'package:flutter/foundation.dart' show immutable;

typedef CloseLoadingScreen = void Function();
typedef UpdateLoadingScreen = void Function(String text);

@immutable
class LoadingScreenController{
final CloseLoadingScreen close;
final UpdateLoadingScreen update;

  LoadingScreenController({required this.close, required this.update});
}