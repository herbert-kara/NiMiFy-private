import 'package:flutter/material.dart';

/// Inherited home-page background accent (status color), shared between the
/// home scaffold background painter and the connection button.
class HomeBgAccent extends InheritedWidget {
  final ValueNotifier<Color> accent;

  const HomeBgAccent({
    super.key,
    required this.accent,
    required super.child,
  }) : super();

  static ValueNotifier<Color>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeBgAccent>()?.accent;

  @override
  bool updateShouldNotify(HomeBgAccent old) => old.accent != accent;
}
