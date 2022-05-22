import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../../modules/modules.dart';
import '../areas/areas.dart';
import '../elements/elements.dart';
import '../templates/templates.dart';
import '../themes/themes.dart';

mixin WidgetSelectorInsets {
  List<Widget> get widgets;

  double get outerPadding => 10;
  double get innerPadding => 10;
  double get headerHeight => 14;
  double get maxItemHeight => 90;
  double get maxItemWidth => 100;
  double get sheetHeight => widgets.isNotEmpty ? maxItemHeight + outerPadding * 2 + innerPadding * 2 + headerHeight : 0;
}

class WidgetSelector<T extends ModuleElement> extends StatefulWidget with WidgetSelectorInsets {
  @override
  final List<T> widgets;
  final TemplateState templateState;
  final AreaState<Area<T>, T> areaState;

  const WidgetSelector(this.templateState, this.widgets, this.areaState, {Key? key}) : super(key: key);

  @override
  WidgetSelectorState createState() => WidgetSelectorState<T>();

  WidgetSelectorState<T>? get state => (key as GlobalKey<WidgetSelectorState<T>>).currentState;

  static Future<WidgetSelector<T>> from<T extends ModuleElement>(
    TemplateState template,
    AreaState<Area<T>, T> widgetArea,
  ) async {
    List<T> widgets = await registry.getWidgetsOf<T>(widgetArea.context);
    return WidgetSelector<T>(template, widgets, widgetArea, key: GlobalKey<WidgetSelectorState<T>>());
  }

  static bool existsIn(BuildContext context) {
    return context.findAncestorStateOfType<WidgetSelectorState>() != null;
  }
}

class WidgetSelectorState<T extends ModuleElement> extends State<WidgetSelector<T>>
    with WidgetSelectorInsets, TickerProviderStateMixin {
  @override
  late List<T> widgets;
  late ScrollController _scrollController;

  T? toDeleteElement;

  @override
  void initState() {
    super.initState();
    widgets = widget.widgets.sublist(0);

    _scrollController = ScrollController();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      var endScroll = _scrollController.position.maxScrollExtent;
      if (endScroll != 0) {
        _scrollController.customAnimateTo(
          endScroll,
          duration: Duration(milliseconds: (endScroll * 60).round()),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double shrinkFactor(Size size) {
    var heightShrink = maxItemHeight / size.height;
    var widthShrink = maxItemWidth / size.width;

    return min(heightShrink, widthShrink);
  }

  void placeWidget(T toDelete) {
    setState(() {
      toDeleteElement = toDelete;
    });
  }

  void takeWidget(T toRemove) async {
    if (toRemove == toDeleteElement) {
      setState(() {
        toDeleteElement = null;
      });
      return;
    }

    var index = widgets.indexOf(toRemove);
    var newWidget = await registry.getWidget<T>(widget.areaState.context, toRemove.module.copyId());

    setState(() {
      widgets = [...widgets.take(index), newWidget!, ...widgets.skip(index + 1)];
    });
  }

  void endDeletion() {
    setState(() {
      toDeleteElement = null;
    });
  }

  double get topEdge => (context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero).dy - 10;

  double startHeightFor(Size size) {
    var selectorHeight = maxItemHeight;
    var startItemWidth = size.width / (size.height / selectorHeight);
    if (startItemWidth > maxItemWidth) {
      var shrink = startItemWidth / maxItemWidth;
      return selectorHeight / shrink;
    } else {
      return selectorHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    var groups = widgets.fold<List<List<T>>>([], (groups, widget) {
      if (groups.isEmpty) {
        return [
          [widget]
        ];
      }
      var lastGroup = groups.last;
      if (lastGroup.isEmpty) {
        lastGroup.add(widget);
      } else {
        var lastWidget = lastGroup.last;
        if (lastWidget.module.parent == widget.module.parent) {
          lastGroup.add(widget);
        } else {
          groups.add([widget]);
        }
      }
      return groups;
    });

    return InheritedTemplate(
      state: widget.templateState,
      child: InheritedArea(
        state: widget.areaState,
        child: GroupTheme(
          theme: widget.areaState.theme,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: sheetHeight,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  color: widget.areaState.context.surfaceColor,
                  boxShadow: const [BoxShadow(blurRadius: 8, spreadRadius: -4)],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(outerPadding),
                      child: CustomScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        controller: _scrollController,
                        slivers: [
                          for (var group in groups)
                            SliverStickyHeader(
                              overlapsContent: true,
                              header: Builder(builder: (context) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: innerPadding, right: innerPadding),
                                    child: Text(
                                      group.first.module.parent.getName(context),
                                      style: context.theme.textTheme.caption!.copyWith(color: context.onSurfaceColor),
                                    ),
                                  ),
                                );
                              }),
                              sliver: SliverPadding(
                                padding: EdgeInsets.only(top: headerHeight),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.all(innerPadding),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(maxWidth: maxItemWidth),
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: ConstrainedBox(
                                              constraints: widget.areaState.constrainWidget(group[index]),
                                              child: group[index],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    childCount: group.length,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (toDeleteElement != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          color: context.theme.colorScheme.error.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(outerPadding + innerPadding) + EdgeInsets.only(top: headerHeight),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxItemWidth),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: ConstrainedBox(
                                  constraints: widget.areaState.constrainWidget(toDeleteElement!),
                                  child: toDeleteElement!,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on ScrollController {
  void customAnimateTo(double to, {required Duration duration, required Curve curve}) {
    var pos = position;
    var activity = CustomScrollActivity(
      pos as ScrollActivityDelegate,
      from: pos.pixels,
      to: to,
      duration: duration,
      curve: curve,
      vsync: pos.context.vsync,
    );
    pos.beginActivity(activity);
  }
}

class CustomScrollActivity extends DrivenScrollActivity {
  CustomScrollActivity(ScrollActivityDelegate delegate,
      {required double from,
      required double to,
      required Duration duration,
      required Curve curve,
      required TickerProvider vsync})
      : super(
          delegate,
          from: from,
          to: to,
          duration: duration,
          curve: curve,
          vsync: vsync,
        );

  @override
  bool get shouldIgnorePointer => false;
}
