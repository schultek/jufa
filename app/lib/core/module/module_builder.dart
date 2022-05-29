import 'dart:async';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

import '../elements/elements.dart';
import 'module_context.dart';

abstract class ModuleBuilder {
  final String id;
  ModuleBuilder(this.id);

  String getName(BuildContext context);

  Map<String, ElementBuilder> get elements;

  void preload(BuildContext context) {}

  Iterable<Route> generateInitialRoutes(BuildContext context) => [];

  @mustCallSuper
  void dispose() {}

  Iterable<Widget>? getSettings(BuildContext context) => null;

  Future<void> handleMessage(ModuleMessage message) async {}
}

@MappableClass(discriminatorKey: 'type')
class ModuleMessage {
  final String? moduleId;

  ModuleMessage(this.moduleId);
}

typedef ElementBuilder<T extends ModuleElement> = FutureOr<T?> Function(ModuleContext module);

mixin ElementBuilderMixin<T extends ModuleElement> {
  FutureOr<T?> build(ModuleContext module);

  FutureOr<T?> call(ModuleContext module) => build(module);
}
