library templates;

import 'dart:collection';
import 'dart:ui';

// ignore: import_of_legacy_library_into_null_safe
import 'package:flare_dart/math/mat2d.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flare_flutter/flare.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flare_flutter/flare_actor.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:tuple/tuple.dart';

import '../areas/areas.dart';
import '../module/module.dart';

part 'basic_template.dart';
part 'reorderable/reorderable_item.dart';
part 'reorderable/reorderable_listener.dart';
part 'reorderable/reorderable_manager.dart';
part 'widgets/reorder_toggle.dart';
part 'widgets/widget_selector.dart';

class _InheritedWidgetTemplate extends InheritedWidget {
  final WidgetTemplateState state;

  const _InheritedWidgetTemplate({
    Key? key,
    required this.state,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant _InheritedWidgetTemplate oldWidget) => true;
}

abstract class WidgetTemplate extends StatefulWidget {
  final String id;
  final ModuleData moduleData;
  const WidgetTemplate(this.id, this.moduleData);

  Widget build(BuildContext context);

  @override
  State<StatefulWidget> createState() => WidgetTemplateState();

  static WidgetTemplateState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<_InheritedWidgetTemplate>()!.state;
    } else {
      var element = context.getElementForInheritedWidgetOfExactType<_InheritedWidgetTemplate>()!;
      return (element.widget as _InheritedWidgetTemplate).state;
    }
  }
}

class WidgetTemplateState extends State<WidgetTemplate> with TickerProviderStateMixin {
  late AnimationController _transitionController;
  late AnimationController _wiggleController;

  bool _isEditing = false;

  late List<ModuleWidgetFactory> _widgetFactories;

  final Map<String, WidgetAreaState> _widgetAreas = {};
  String? _selectedArea, _lastSelectedArea;
  WidgetSelectorController? _widgetSelector;

  Animation<double> get transition => _transitionController.view;
  Animation<double> get wiggle => _wiggleController.view;

  bool get isEditing => _isEditing;
  String? get selectedArea => _selectedArea;

  late ReorderableManager _reorderableManager;
  ReorderableManager get reorderable => _reorderableManager;

  @override
  void initState() {
    super.initState();

    _transitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _wiggleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _widgetFactories = ModuleRegistry.getModuleWidgetFactories(widget.moduleData);
    _reorderableManager = ReorderableManager(this);
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _wiggleController.dispose();
    _reorderableManager.dispose();
    super.dispose();
  }

  void toggleEdit() {
    if (_isEditing) {
      _finishEdit();
    } else {
      _beginEdit();
    }
  }

  void _beginEdit() {
    setState(() {
      _isEditing = true;
    });
    _wiggleController.repeat();
    _transitionController.forward();
    selectWidgetArea(_widgetAreas[_lastSelectedArea]!);
  }

  void _finishEdit() {
    _isEditing = false;
    _transitionController.reverse().whenComplete(() {
      _wiggleController.stop();
      //updateIndices();
      setState(() {});
    });

    _unselectArea();
  }

  List<T> getWidgetsForArea<T extends ModuleWidget>(String areaId) {
    //allModuleCards.where((card) => moduleData.trip.modules.contains(card.id)).toList()
    //  ..sort((a, b) => moduleData.trip.modules.indexOf(a.id) - moduleData.trip.modules.indexOf(b.id));
    return _widgetFactories.where((f) => f.type == T).map((f) => f.getWidget() as T).toList();
  }

  void selectWidgetArea<T extends ModuleWidget>(WidgetAreaState<WidgetArea<T>, T> area) {
    if (!isEditing) return;
    if (_selectedArea == area.id) {
      return;
    } else if (_selectedArea != null) {
      _unselectArea();
    }

    print(area);

    _selectedArea = area.id;
    _lastSelectedArea = _selectedArea;
    _widgetSelector = WidgetSelector.show<T>(this);

    setState(() {});
  }

  void _unselectArea() {
    _selectedArea = null;

    if (_widgetSelector != null) {
      _widgetSelector!.close();
      _widgetSelector = null;
    }

    setState(() {});
  }

  void registerArea(WidgetAreaState area) {
    _widgetAreas[area.id] = area;
    _lastSelectedArea ??= area.id;
  }

  void onWidgetRemoved<T extends ModuleWidget>(WidgetAreaState<WidgetArea<T>, T> area, T widget) {
    if (_widgetSelector != null && _widgetSelector!.isForArea(area)) {
      _widgetSelector!.state!.addWidget(null, widget);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedWidgetTemplate(
      state: this,
      child: widget.build(context),
    );
  }

  Widget decorateItem(Widget widget, double opacity) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(
          blurRadius: 8,
          spreadRadius: -2,
          color: Colors.black.withOpacity(opacity * 0.5),
        )
      ]),
      child: widget,
    );
  }
}
