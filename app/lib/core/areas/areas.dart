library areas;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../bloc/trip_bloc.dart';
import '../elements/elements.dart';
import '../module/module.dart';
import '../reorderable/reorderable_manager.dart';
import '../templates/templates.dart';

part 'body_widget_area.dart';
part 'full_page_area.dart';
part 'quick_action_row_area.dart';

class InheritedWidgetArea<T extends ModuleElement> extends InheritedWidget {
  final WidgetAreaState<WidgetArea<T>, T> state;

  const InheritedWidgetArea({
    Key? key,
    required this.state,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidgetArea oldWidget) => true;
}

abstract class WidgetArea<T extends ModuleElement> extends StatefulWidget {
  final String id;
  const WidgetArea(this.id);

  static WidgetAreaState<WidgetArea<T>, T>? of<T extends ModuleElement>(BuildContext context) {
    var element = context.getElementForInheritedWidgetOfExactType<InheritedWidgetArea<T>>();
    return element != null ? (element.widget as InheritedWidgetArea<T>).state : null;
  }
}

abstract class WidgetAreaState<U extends WidgetArea<T>, T extends ModuleElement> extends State<U>
    with TickerProviderStateMixin {
  bool _isInitialized = false;

  String get id => widget.id;

  final _areaKey = GlobalKey();
  final _areaTheme = ValueNotifier<ThemeState?>(null);
  late Size _areaSize;
  late Offset _areaOffset;

  Size get areaSize => _areaSize;
  Offset get areaOffset => _areaOffset;

  ThemeState get theme => _areaTheme.value!;
  WidgetTemplateState get template => WidgetTemplate.of(context, listen: false);

  late ReorderableManager _reorderable;

  Type get elementType => T;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;

    _reorderable = template.reorderable;
    initArea(template.getWidgetsForArea<T>(widget.id));
  }

  void initArea(List<T> widgets);

  @override
  void dispose() {
    super.dispose();
  }

  void updateAreaSize(_) {
    _areaSize = (_areaKey.currentContext!.findRenderObject()! as RenderBox).size;
    _areaOffset = (_areaKey.currentContext!.findRenderObject()! as RenderBox).localToGlobal(Offset.zero);
  }

  bool get isSelected => template.selectedArea == id;

  @override
  Widget build(BuildContext context) {
    var templateState = WidgetTemplate.of(context);
    templateState.registerArea(this);

    var isSelected = templateState.selectedArea == id;
    var backgroundColor = Colors.blue.withOpacity(0.05);
    var borderColor = Colors.blue.withOpacity(0.5);

    WidgetsBinding.instance!.addPostFrameCallback(updateAreaSize);

    return InheritedWidgetArea(
      state: this,
      child: Listener(
        onPointerDown: (_) {
          templateState.selectWidgetArea<T>(this);
        },
        child: ThemedContainer(
          themeNotifier: _areaTheme,
          child: Container(
            margin: getMargin(),
            padding: getPadding(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? backgroundColor : Colors.transparent,
              border: Border.all(
                color: isSelected ? borderColor : Colors.transparent,
              ),
            ),
            child: Container(key: _areaKey, child: buildArea(context)),
          ),
        ),
      ),
    );
  }

  Widget buildArea(BuildContext context);

  EdgeInsetsGeometry getMargin() => EdgeInsets.zero;
  EdgeInsetsGeometry getPadding() => const EdgeInsets.all(10);

  Widget? decoratePlaceholder(BuildContext context, T element) => null;
  Widget? decorateElement(BuildContext context, T element) => null;

  BoxConstraints constrainWidget(T widget);

  void removeWidget(Key key) {
    setState(() {
      var widget = getWidgetFromKey(key);
      removeItem(key);

      var templateState = WidgetTemplate.of(context, listen: false);
      templateState.onWidgetRemoved(this, widget);
    });
    updateWidgetsInTrip();
  }

  Future<void> updateWidgetsInTrip() async {
    context.updateTrip({
      "modules.$id": getWidgets().map((w) => w.id).toList(),
    });
  }

  void onDrop() {
    updateWidgetsInTrip();
  }

  void cancelDrop(Key key) {
    setState(() {
      removeItem(key);
    });
  }

  Offset getOffset(Key key) => _reorderable.itemOffset(key) - areaOffset;
  Size getSize(Key key) => _reorderable.itemSize(key);
  void translateX(Key key, double delta) => _reorderable.translateItemX(key, delta);
  void translateY(Key key, double delta) => _reorderable.translateItemY(key, delta);

  bool isOverArea(Offset offset, Size size) {
    var areaRect = Rect.fromLTWH(0, 0, areaSize.width, areaSize.height);
    var itemRect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
    return itemRect.overlaps(areaRect);
  }

  bool _scheduledRebuild = false;

  bool didInsertItem(Offset offset, T item) {
    if (_scheduledRebuild) {
      return true;
    }

    if (!isOverArea(offset, getSize(item.key))) {
      if (hasKey(item.key)) {
        cancelDrop(item.key);
      }
      return false;
    }

    if (hasKey(item.key)) {
      if (didReorderItem(offset, item.key)) {
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          _scheduledRebuild = false;
        });
        _scheduledRebuild = true;
      }
      return true;
    }

    if (!canInsertItem(item)) {
      return false;
    }

    insertItem(item);

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      while (didReorderItem(offset, item.key)) {}
      _scheduledRebuild = false;
    });
    _scheduledRebuild = true;

    return true;
  }

  List<T> getWidgets();
  T getWidgetFromKey(Key key);
  void removeItem(Key key);
  bool didReorderItem(Offset offset, Key key);
  bool canInsertItem(T item) => true;
  void insertItem(T item);
  bool hasKey(Key key);

  bool isAllowed(T item) => true;
}
