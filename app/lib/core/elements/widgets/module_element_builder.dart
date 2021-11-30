import 'dart:math';

import 'package:flutter/material.dart';

import '../../reorderable/reorderable_item.dart';
import '../../reorderable/reorderable_listener.dart';
import '../../templates/widget_template.dart';
import '../../widgets/widget_selector.dart';
import '../module_element.dart';
import 'removable_draggable_module_widget.dart';

mixin ModuleElementBuilder<T extends ModuleElement> on ModuleElement {
  Widget buildElement(BuildContext context);
  Widget buildPlaceholder(BuildContext context);
  Widget decorationBuilder(Widget child, double opacity);

  @override
  Widget build(BuildContext context) {
    if (WidgetSelector.existsIn(context)) {
      return ReorderableItem(
        key: key,
        builder: (context, state, child) {
          return state == ReorderableState.placeholder ? buildPlaceholder(context) : child;
        },
        decorationBuilder: decorationBuilder,
        child: ReorderableListener<T>(
          delay: const Duration(milliseconds: 200),
          child: AbsorbPointer(child: buildElement(context)),
        ),
      );
    }

    return ReorderableItem(
      key: key,
      builder: (context, state, child) {
        if (state == ReorderableState.placeholder) {
          return buildPlaceholder(context);
        } else if (state == ReorderableState.normal) {
          var animation = CurvedAnimation(parent: PhasedAnimation.of(context), curve: Curves.easeInOut);
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: (animation.value - 0.5) * 0.015,
                child: child,
              );
            },
            child: child,
          );
        } else {
          return AbsorbPointer(child: buildElement(context));
        }
      },
      decorationBuilder: decorationBuilder,
      child: RemovableDraggableModuleWidget<T>(
        key: key,
        child: Builder(builder: buildElement),
      ),
    );
  }
}

class PhasedAnimation extends CompoundAnimation<double> {
  double shift;

  PhasedAnimation({required Animation<double> phase, required Animation<double> intensity, this.shift = 0.0})
      : super(first: phase, next: intensity);

  @override
  double get value {
    var phase = (first.value + shift > 1 ? first.value + shift - 1 : first.value + shift) * 2;
    phase = phase > 1 ? 2 - phase : phase;
    return ((phase - 0.5) * next.value) + 0.5;
  }

  factory PhasedAnimation.of(BuildContext context) {
    var state = WidgetTemplate.of(context, listen: false);
    return PhasedAnimation(phase: state.wiggle, intensity: state.transition, shift: Random().nextDouble());
  }
}
