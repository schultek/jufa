part of areas;

class BodyWidgetArea extends WidgetArea<ContentSegment> {
  final ScrollController scrollController;
  const BodyWidgetArea(this.scrollController) : super('body');

  @override
  State<StatefulWidget> createState() => BodyWidgetAreaState();
}

class BodyWidgetAreaState extends WidgetAreaState<BodyWidgetArea, ContentSegment> {
  List<List<ContentSegment>> grid = [];

  @override
  void initArea(List<ContentSegment> widgets) {
    List<ContentSegment>? row;
    grid = [];
    for (ContentSegment segment in widgets) {
      if (segment.size == SegmentSize.Square) {
        if (row == null) {
          row = [segment];
          grid.add(row);
        } else {
          row.add(segment);
          row = null;
        }
      } else {
        grid.add([segment]);
      }
    }
  }

  @override
  EdgeInsetsGeometry getPadding() => EdgeInsets.zero;

  @override
  Widget buildArea(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      alignment: Alignment.topCenter,
      curve: Curves.easeInOut,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 10),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: grid.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: index == grid.length - 1 ? 10 : 20, left: 10, right: 10),
          child: grid[index][0].size == SegmentSize.Wide
              ? grid[index][0]
              : Row(
                  children: [
                    Flexible(
                      fit: FlexFit.tight,
                      child: grid[index][0],
                    ),
                    Container(width: 20),
                    Flexible(
                      fit: FlexFit.tight,
                      child: grid[index].length == 2 ? grid[index][1] : Container(),
                    )
                  ],
                ),
        ),
      ),
    );
  }

  @override
  bool hasKey(Key key) {
    return grid.any((row) => row.any((segment) => segment.key == key));
  }

  GridIndex indexOf(Key key) {
    var rowIndex = grid.indexWhere((List<ContentSegment> row) => row.any((segment) => segment.key == key));
    var columnIndex = grid[rowIndex].indexWhere((card) => card.key == key);
    return GridIndex(rowIndex, columnIndex, grid[rowIndex][columnIndex].size);
  }

  @override
  ContentSegment getWidgetFromKey(Key key) {
    var index = indexOf(key);
    return grid[index.row][index.column];
  }

  void onReorder(Key draggedItem, Key newPosition) {
    GridIndex curIndex = indexOf(draggedItem);
    GridIndex newIndex = indexOf(newPosition);

    setState(() {
      if (curIndex.row == newIndex.row) {
        grid[curIndex.row] = grid[curIndex.row].reversed.toList();
      } else if (curIndex.size == SegmentSize.Square && newIndex.size == SegmentSize.Square) {
        var draggedCard = grid[curIndex.row][curIndex.column];
        grid[curIndex.row][curIndex.column] = grid[newIndex.row][newIndex.column];
        grid[newIndex.row][newIndex.column] = draggedCard;
      } else {
        var draggedRow = grid.removeAt(curIndex.row);
        grid.insert(newIndex.row, draggedRow);
      }
    });
  }

  @override
  void insertItem(ContentSegment item) {
    setState(() {
      if (grid.isEmpty || grid[grid.length - 1][0].size == SegmentSize.Wide || grid[grid.length - 1].length == 2) {
        grid.add([item]);
      } else if (item.size == SegmentSize.Wide) {
        grid.insert(grid.length - 1, [item]);
      } else {
        grid[grid.length - 1].add(item);
      }
    });
  }

  @override
  BoxConstraints constrainWidget(ContentSegment widget) {
    if (widget.size == SegmentSize.Wide) {
      return BoxConstraints(maxWidth: areaSize.width - 20);
    } else {
      return BoxConstraints(maxWidth: (areaSize.width - 40) / 2);
    }
  }

  @override
  List<ContentSegment> getWidgets() {
    List<ContentSegment> sortedWidgets = [];
    for (var row in grid) {
      for (var item in row) {
        sortedWidgets.add(item);
      }
    }
    return sortedWidgets;
  }

  bool _scrolling = false;

  Future<void> maybeScroll(Offset dragOffset, Key itemKey, Offset itemOffset, Size itemSize) async {
    // ignore: dead_code, invariant_booleans
    if (false && !_scrolling) {
      var position = widget.scrollController.position;
      int duration = 15; // in ms

      MediaQueryData d = MediaQuery.of(context);

      double top = d.padding.top;
      double bottom = widget.scrollController.position.viewportDimension - (d.padding.bottom);

      double? newOffset = checkScrollPosition(position, itemOffset, itemSize, top, bottom);

      if (newOffset != null && (newOffset - position.pixels).abs() >= 1.0) {
        _scrolling = true;
        await widget.scrollController.position.animateTo(
          newOffset,
          duration: Duration(milliseconds: duration),
          curve: Curves.linear,
        );
        _scrolling = false;
        if (hasKey(itemKey)) {
          didReorderItem(dragOffset, itemKey);
        }
      }
    }
  }

  @override
  bool didReorderItem(Offset offset, Key itemKey) {
    Offset itemOffset = getOffset(itemKey);
    Size itemSize = getSize(itemKey);

    maybeScroll(offset, itemKey, itemOffset, itemSize);

    if (offset.dy < itemOffset.dy - itemSize.height / 2 - 20) {
      var dragIndex = indexOf(itemKey);
      if (dragIndex.row > 0) {
        var aboveRow = grid[dragIndex.row - 1];

        if (dragIndex.size == SegmentSize.Wide) {
          onReorder(itemKey, aboveRow[0].key);

          translateY(aboveRow[0].key, -itemSize.height - 20);
          if (aboveRow.length == 2) translateY(aboveRow[1].key, -itemSize.height - 20);
        } else {
          if (aboveRow.length == 2) {
            var aboveItem = aboveRow[dragIndex.column];

            onReorder(itemKey, aboveItem.key);
            translateY(aboveItem.key, -itemSize.height - 20);
          } else if (grid[dragIndex.row].length == 2) {
            var siblingItem = grid[dragIndex.row][1 - dragIndex.column];

            onReorder(itemKey, aboveRow[0].key);
            translateY(aboveRow[0].key, -itemSize.height - 20);
            translateY(siblingItem.key, itemSize.height + 20);
          } else {
            print('FOUND ELSE?? WHAT IS THIS');
          }
        }

        return true;
      }
    } else if (offset.dy > itemOffset.dy + itemSize.height / 2 + 20) {
      var dragIndex = indexOf(itemKey);
      if (dragIndex.row < grid.length - 1) {
        var belowRow = grid[dragIndex.row + 1];

        if (dragIndex.size == SegmentSize.Wide) {
          if (belowRow[0].size == SegmentSize.Wide || belowRow.length == 2) {
            onReorder(itemKey, belowRow[0].key);

            translateY(belowRow[0].key, itemSize.height + 20);
            if (belowRow.length == 2) {
              translateY(belowRow[1].key, itemSize.height + 20);
            }
          }
        } else {
          if (belowRow.length == 2) {
            var belowItem = belowRow[dragIndex.column];

            onReorder(itemKey, belowItem.key);
            translateY(belowItem.key, itemSize.height + 20);
          } else if (belowRow[0].size == SegmentSize.Wide) {
            var siblingItem = grid[dragIndex.row][1 - dragIndex.column];

            onReorder(itemKey, belowRow[0].key);
            translateY(belowRow[0].key, itemSize.height + 20);
            translateY(siblingItem.key, -itemSize.height - 20);
          } else if (dragIndex.column == 0) {
            var belowItem = belowRow[0];

            onReorder(itemKey, belowItem.key);
            translateY(belowItem.key, itemSize.height + 20);
          } else {
            var siblingItem = grid[dragIndex.row][0];
            var belowItem = belowRow[0];

            onReorder(itemKey, siblingItem.key);
            onReorder(itemKey, belowItem.key);

            translateX(siblingItem.key, -itemSize.width - 20);
            translateY(belowItem.key, itemSize.height + 20);
          }
        }

        return true;
      }
    } else if ((offset.dx - itemOffset.dx).abs() > itemSize.width / 2 + 20) {
      var dragIndex = indexOf(itemKey);
      if (dragIndex.size == SegmentSize.Square && grid[dragIndex.row].length == 2) {
        var siblingItem = grid[dragIndex.row][1 - dragIndex.column];

        onReorder(itemKey, siblingItem.key);

        var sign = dragIndex.column == 0 ? 1 : -1;
        translateX(siblingItem.key, sign * (itemSize.width + 20));

        return true;
      }
    }

    return false;
  }

  double? checkScrollPosition(ScrollPosition position, Offset dragOffset, Size dragSize, double top, double bottom) {
    double step = 1.0;
    double overdragMax = 40.0;
    double overdragCoef = 5.0;

    if (dragOffset.dy < top && position.pixels > position.minScrollExtent) {
      var overdrag = max(top - dragOffset.dy, overdragMax);
      return max(position.minScrollExtent, position.pixels - step * overdrag / overdragCoef);
    } else if (dragOffset.dy + dragSize.height > bottom && position.pixels < position.maxScrollExtent) {
      var overdrag = max<double>(dragOffset.dy + dragSize.height - bottom, overdragMax);
      return min(position.maxScrollExtent, position.pixels + step * overdrag / overdragCoef);
    } else {
      return null;
    }
  }

  @override
  void removeItem(Key key) {
    var index = indexOf(key);
    removeAtIndex(index);
  }

  void removeAtIndex(GridIndex index) {
    var itemSize = getSize(grid[index.row][index.column].key);

    if (index.row == grid.length - 1) {
      if (index.column == 1) {
        grid[index.row].removeAt(1);
      } else {
        if (index.size == SegmentSize.Wide) {
          grid.removeAt(index.row);
        } else {
          if (grid[index.row].length == 2) {
            var siblingItem = grid[index.row][1];
            translateX(siblingItem.key, itemSize.width + 20);

            grid[index.row].removeAt(0);
          } else {
            grid.removeAt(index.row);
          }
        }
      }
    } else {
      var belowRow = grid[index.row + 1];

      if (index.size == SegmentSize.Wide) {
        translateY(belowRow[0].key, itemSize.height + 20);
        grid[index.row][0] = belowRow[0];

        if (belowRow.length == 2) {
          translateY(belowRow[1].key, itemSize.height + 20);

          if (grid[index.row].length == 2) {
            grid[index.row][1] = belowRow[1];
          } else {
            grid[index.row].add(belowRow[1]);
          }
        } else if (grid[index.row].length == 2) {
          grid[index.row].removeAt(1);
        }

        removeAtIndex(GridIndex(index.row + 1, 0, SegmentSize.Wide));
      } else {
        if (belowRow.length == 2) {
          translateY(belowRow[index.column].key, itemSize.height + 20);

          grid[index.row][index.column] = belowRow[index.column];

          removeAtIndex(GridIndex(index.row + 1, index.column, SegmentSize.Square));
        } else {
          if (index.column == 0) {
            if (belowRow[0].size == SegmentSize.Square) {
              translateY(belowRow[0].key, itemSize.height + 20);

              grid[index.row][0] = belowRow[0];

              removeAtIndex(GridIndex(index.row + 1, index.column, SegmentSize.Square));
            } else {
              translateY(belowRow[0].key, itemSize.height + 20);
              translateY(grid[index.row][1].key, -itemSize.height - 20);

              grid[index.row][0] = belowRow[0];
              belowRow.add(grid[index.row][1]);

              removeAtIndex(GridIndex(index.row + 1, index.column, SegmentSize.Square));
            }
          } else {
            if (belowRow[0].size == SegmentSize.Square) {
              translateY(belowRow[0].key, itemSize.height + 20);
              translateX(belowRow[0].key, -itemSize.width - 20);

              grid[index.row][1] = belowRow[0];

              removeAtIndex(GridIndex(index.row + 1, 0, SegmentSize.Square));
            } else {
              translateY(belowRow[0].key, itemSize.height + 20);
              translateY(grid[index.row][0].key, -itemSize.height - 20);

              grid[index.row + 1] = grid[index.row];
              grid[index.row] = belowRow;

              removeAtIndex(GridIndex(index.row + 1, index.column, SegmentSize.Square));
            }
          }
        }
      }
    }
  }
}

class GridIndex {
  int row;
  int column;
  SegmentSize size;
  GridIndex(this.row, this.column, this.size);
}
