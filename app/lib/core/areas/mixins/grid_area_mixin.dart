import 'package:flutter/material.dart';

import '../../elements/module_element.dart';
import '../widget_area.dart';

class GridIndex {
  int row;
  int column;
  SegmentSize size;
  GridIndex(this.row, this.column, this.size);
}

mixin GridAreaMixin<U extends WidgetArea<T>, T extends ModuleElement> on WidgetAreaState<U, T> {
  List<List<T>> grid = [];

  SegmentSize sizeOf(T element);

  @override
  void initArea(List<T> widgets) {
    List<T>? row;
    grid = [];
    for (T element in widgets) {
      if (sizeOf(element) == SegmentSize.square) {
        if (row == null) {
          row = [element];
          grid.add(row);
        } else {
          row.add(element);
          row = null;
        }
      } else {
        grid.add([element]);
      }
    }
  }

  @override
  bool hasKey(Key key) {
    return grid.any((row) => row.any((element) => element.key == key));
  }

  GridIndex indexOf(Key key) {
    var rowIndex = grid.indexWhere((row) => row.any((element) => element.key == key));
    var columnIndex = grid[rowIndex].indexWhere((element) => element.key == key);
    return GridIndex(rowIndex, columnIndex, sizeOf(grid[rowIndex][columnIndex]));
  }

  @override
  T getWidgetFromKey(Key key) {
    var index = indexOf(key);
    return grid[index.row][index.column];
  }

  @override
  void insertItem(Offset offset, T item) {
    setState(() {
      if (grid.isEmpty || sizeOf(grid[grid.length - 1][0]) == SegmentSize.wide || grid[grid.length - 1].length == 2) {
        grid.add([item]);
      } else if (sizeOf(item) == SegmentSize.wide) {
        grid.insert(grid.length - 1, [item]);
      } else {
        grid[grid.length - 1].add(item);
      }
    });
  }

  @override
  List<T> getWidgets() {
    List<T> sortedWidgets = [];
    for (var row in grid) {
      for (var item in row) {
        sortedWidgets.add(item);
      }
    }
    return sortedWidgets;
  }
}
