import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

abstract class IJkItemController {
  int getFirstVisibleIndex();
  void jumpToIndex(int index, {double? alignment});
  Future<void> animateToIndex(int index,
      {double? alignment, required Duration duration, required Curve curve});
}

class JkItemController implements IJkItemController {
  IJkItemController? _ref;
  int? _initialIndex;
  double? _initialAlignment;

  void _connect(IJkItemController? c) => _ref = c;

  void _checkParams(int? index, double? alignment) {
    assert(index == null || index >= 0);
    assert(
        alignment == null ||
            (alignment >= 0 && alignment <= 1 && index != null),
        "alignment must be null or between 0.0 ~ 1.0");
  }

  JkItemController({int? initialIndex, double? alignment}) {
    _checkParams(initialIndex, alignment);
    _initialIndex = initialIndex;
    _initialAlignment = alignment;
  }

  /// Auto scroll to 'index' when ListView initialized.
  /// This method do nothing after ListView initialized,
  /// so call this method ONLY before you create ListView widget.
  void setInitialIndex(int index, {double? alignment}) {
    _checkParams(index, alignment);
    _initialIndex = index;
    _initialAlignment = alignment;
  }

  @override
  int getFirstVisibleIndex() {
    return _ref?.getFirstVisibleIndex() ?? -1;
  }

  /// scroll to the item at 'index' position immediately
  /// alignment: null: make item visible with minimum distance scrolling
  /// alignment: 0.0: place the item to beginning of screen
  /// alignment: 1.0: place the item to end of screen
  @override
  void jumpToIndex(int index, {double? alignment}) {
    _checkParams(index, alignment);
    _ref?.jumpToIndex(index, alignment: alignment);
  }

  /// scroll to the item at 'index' position with an animation
  /// alignment: null: make item visible with minimum distance scrolling
  /// alignment: 0.0: place the item to beginning of screen
  /// alignment: 1.0: place the item to end of screen
  @override
  Future<void> animateToIndex(int index,
      {double? alignment,
      required Duration duration,
      required Curve curve}) async {
    _checkParams(index, alignment);
    await _ref?.animateToIndex(index,
        alignment: alignment, duration: duration, curve: curve);
  }
}

// --------------------------------------------------------------------------

typedef JkOnScrollPositionCallback = void Function(
    int firstIndex, double fisrtVisibleRatio);

class JkFastListView extends BoxScrollView {
  final NullableIndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final IndexedWidgetBuilder? separatorBuilder;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final int crossAxisCount;
  final double? maxCrossAxisExtent; // if not null, ignore crossAxisCount
  final JkItemController? itemController;
  final SliverChildBuilderDelegate childrenDelegate;

  /// Called every time when scrolling position changed.
  /// You can get the index of first visible item index here.
  /// Don't run time-consuming task.
  final JkOnScrollPositionCallback? onScrollPosition; //TODO: implement it

  JkFastListView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    super.padding,
    required this.itemBuilder,
    required this.itemCount,
    this.separatorBuilder,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.crossAxisCount = 1,
    this.maxCrossAxisExtent,
    this.itemController,
    this.onScrollPosition,
    bool addAutomaticKeepAlives = false, // keepAlives cost too many resources
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  })  : assert(!addAutomaticKeepAlives,
            "[JkLargeListView] addAutomaticKeepAlives not supported since it cost too many resources when itemCount is large"),
        childrenDelegate = SliverChildBuilderDelegate(
          itemBuilder,
          //findChildIndexCallback: findChildIndexCallback,
          childCount: itemCount,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          //semanticIndexCallback: ,
        );

  @override
  List<Widget> buildSlivers(BuildContext context) => const [];

  @override
  Widget buildChildLayout(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    // this only called when first time or widget rebuild,
    // and won't re-called when scrolling
    final AxisDirection axisDirection = getDirection(context);
    return _JkLazyViewport(
      offset: offset,
      itemBuilder: childrenDelegate.build,
      itemCount: itemCount,
      axisDirection: axisDirection,
      cacheExtent: cacheExtent ?? 0,
      separatorBuilder: separatorBuilder,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      crossAxisCount: crossAxisCount,
      maxCrossAxisExtent: maxCrossAxisExtent,
      itemController: itemController,
      onScrollPosition: onScrollPosition,
    );
  }
}

// --------------------------------------------------------------------------

class _JkLazyViewport extends RenderObjectWidget {
  final ViewportOffset offset;
  final AxisDirection axisDirection;
  final NullableIndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final double cacheExtent;
  final IndexedWidgetBuilder? separatorBuilder;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final int crossAxisCount;
  final double? maxCrossAxisExtent; // if not null, ignore crossAxisCount
  final JkItemController? itemController;
  final JkOnScrollPositionCallback? onScrollPosition;

  const _JkLazyViewport({
    super.key,
    required this.offset,
    required this.itemBuilder,
    required this.itemCount,
    this.axisDirection = AxisDirection.down,
    this.cacheExtent = 0,
    this.separatorBuilder,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.crossAxisCount = 1,
    this.maxCrossAxisExtent,
    this.itemController,
    this.onScrollPosition,
  });

  @override
  _JkLazyViewportRenderObjectElement createElement() =>
      _JkLazyViewportRenderObjectElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    final element = context as _JkLazyViewportRenderObjectElement;
    var ro = _JkLazyViewportRenderObject(element);
    ro.updateWidgetInfo(this, false);
    return ro;
  }

  @override
  void updateRenderObject(
      BuildContext context, _JkLazyViewportRenderObject renderObject) {
    // called when listview rebuild
    super.updateRenderObject(context, renderObject);
    renderObject.updateWidgetInfo(this, true);
  }

  @override
  void didUnmountRenderObject(covariant RenderObject renderObject) {
    super.didUnmountRenderObject(renderObject);
  }
}

// --------------------------------------------------------------------------

class _JkLazyViewportRenderObjectElement extends RenderObjectElement {
  final childManager = _ChildManager();

  _JkLazyViewportRenderObjectElement(super.widget);

  @override
  _JkLazyViewport get widget => super.widget as _JkLazyViewport;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    super.unmount();
    childInfoMap.forEach((index, info) {
      childManager.recycleInfo(info);
    });
    childInfoMap.clear();
    childManager.destroyRecycler();
  }

  @override
  void deactivate() {
    super.deactivate();
    // called by [_deactivateRecursively] in framework,
    // and [_deactivateRecursively] will call visitChildren(_deactivateRecursively)
    // so don't call child.deactivate() here
    // so as activate()
  }

  @override
  void activate() {
    super.activate();
  }

  @override
  void update(covariant _JkLazyViewport newWidget) {
    super.update(newWidget);
    performRebuild();
  }

  // ----------------
  // rebuilding visible children when listview widget rebuild
  // ----------------

  final Set<_ChildInfo> keepStateChildren = {}; //keep children state in rebuild
  void rebuildChild(
      int index, _ChildInfo info, Map<Key, _ChildInfo> keepStateInfoMap) {
    final oldWidget = info.element.widget;
    final newWidget = widget.itemBuilder(this, index)!;

    if (oldWidget == newWidget) {
      // do nothing
    } else if (Widget.canUpdate(oldWidget, newWidget)) {
      // rules are referenced from element.updateChild()
      // in this case, original child can be reused and assign to newWidget
      info.updateWidget(newWidget);
    } else {
      // in this case, original child cannot be assigned to newWidget
      assert(oldWidget.key != newWidget.key);

      // if new widget has key and state,
      // try to find is there any active child with the same key,
      // and move it here
      int? targetIndex; // the active child index with the same newWidget.key
      _ChildInfo? targetInfo;
      if (newWidget.key != null) {
        targetInfo = keepStateInfoMap.remove(newWidget.key);
        if (targetInfo == null) {
          targetIndex = childIndexByKey(newWidget.key!);
          if (targetIndex != null) {
            targetInfo = childAt(targetIndex);
          }
        }
      }

      if (targetInfo != null) {
        // if any child with newWidget.key found, move it here
        // and assign newWidget to this child
        assert(Widget.canUpdate(newWidget, targetInfo.element.widget));
        targetInfo.updateWidget(newWidget);

        if (targetIndex == null) {
          // target found in 'keepStateInfoMap', so:
          // if oldWidget has key, we move old child into 'keepStateInfoMap'
          // otherwise, destroy old child
          if (oldWidget.key != null) {
            assert(keepStateInfoMap.containsKey(oldWidget.key!) == false);
            keepStateInfoMap[oldWidget.key!] = info;
          } else {
            childManager.recycleInfo(info);
          }

          info = targetInfo;
          childInfoMap[index] = info;
        } else {
          // target found in 'keepStateInfoMap'
          // so we swap info in oldWidget & newWidget position
          childInfoMap[targetIndex] = info;
          info = targetInfo;
          childInfoMap[index] = info;
        }
      } else {
        if (oldWidget.key != null) {
          // if old child has key and state,
          // move it to keepStateInfoMap to keep its state
          assert(keepStateInfoMap.containsKey(oldWidget.key) == false);
          keepStateInfoMap[oldWidget.key!] = info;
        } else {
          childManager.recycleInfo(info);
        }

        info = childManager.createInfo(this, newWidget);
        childInfoMap[index] = info;
      }
    }

    // update separator widget
    Widget? newSeparatorWidget;
    if (widget.separatorBuilder != null && index < widget.itemCount) {
      newSeparatorWidget = widget.separatorBuilder!(this, index);
    }
    info.updateSeparator(newSeparatorWidget);
  }

  @override
  void performRebuild() {
    // when widget rebuild, all children cannot be paint without re-build children
    //log("performRebuild cc");
    super.performRebuild();

    final Map<Key, _ChildInfo> keepStateInfoMap = {};
    for (var index in childInfoMap.keys.toList()) {
      var info = childAt(index)!;
      if (index >= widget.itemCount) {
        // remove this later
        // because if this widget has key and state, and user move it backward,
        // then this widget's state may need to be reserved
        continue;
      }
      rebuildChild(index, info, keepStateInfoMap);
    }

    // remove unused state
    keepStateInfoMap.forEach((key, info) {
      childManager.recycleInfo(info);
    });

    // remove children with index >= itemCount
    // this case occurs when user scroll to end, and delete an item
    for (int index = widget.itemCount;; index++) {
      var info = childInfoMap.remove(index);
      if (info == null) break;
      childManager.recycleInfo(info);
    }

    // clear the separator of the last item
    if (widget.itemCount > 0) {
      childInfoMap[widget.itemCount - 1]?.updateSeparator(null);
    }
  }

  // ----------------
  // children management
  // ----------------

  final childInfoMap = <int, _ChildInfo>{};
  _ChildInfo? childAt(int index) => childInfoMap[index];
  int? childIndexByKey(Key key) {
    for (var entry in childInfoMap.entries) {
      if (entry.value.element.widget.key == key) return entry.key;
    }
    return null;
  }

  bool removeChildAt(int index) {
    var info = childInfoMap.remove(index);
    if (info != null) {
      childManager.recycleInfo(info);
    }
    return info != null;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    childInfoMap.forEach((index, info) {
      visitor(info.element);
      if (info.separator?.element != null) {
        visitor(info.separator!.element);
      }
    });
  }

  @override
  void insertRenderObjectChild(
      covariant RenderObject child, covariant _ChildInfo slot) {
    // these two lines must be here to enable item animation
    renderObject.adoptChild(child);
    child.parentData = slot;
  }

  @override
  void moveRenderObjectChild(covariant RenderObject child,
      covariant Object? oldSlot, covariant Object? newSlot) {
    // do nothing
  }

  @override
  void removeRenderObjectChild(
      covariant RenderObject child, covariant Object? slot) {
    // this lines must be here to enable item animation
    renderObject.dropChild(child);
  }
}

// --------------------------------------------------------------------------

class _ChildManager {
  bool _isAlive = true;
  int _childCount = 0; // debug only, current children count
  int _separatorCount = 0; // debug only, current separator count
  List<_ChildInfo> _bucket = [];
  List<_ChildInfo> _tmpBucket = [];

  void _addChildCount(bool isSeparator, int incValue) {
    if (!isSeparator) {
      _childCount += incValue;
    } else {
      _separatorCount += incValue;
    }
  }

  _ChildInfo createInfo(Element parentElement, Widget widget,
      {bool isSeparator = false}) {
    assert(_isAlive);
    _ChildInfo? info;
    bool isFromTempBucket = false;
    if (widget.key == null) {
      if (_tmpBucket.isNotEmpty) {
        info = _tmpBucket.removeLast();
        isFromTempBucket = true;
      } else if (_bucket.isNotEmpty) {
        info = _bucket.removeLast();
      }
    }

    if (info != null) {
      if (Widget.canUpdate(widget, info.element.widget)) {
        if (isFromTempBucket == false) {
          _activateInfo(info);
        }
        info.updateWidget(widget);
        //log("[child] reuse");
        return info;
      } else {
        if (isFromTempBucket) {
          _tmpBucket.add(info);
        } else {
          _bucket.add(info);
        }
      }
    }

    _addChildCount(isSeparator, 1);
    //log("[child] create new");
    return _ChildInfo._create(this, parentElement, widget,
        isSeparator: isSeparator);
  }

  void _activateInfo(_ChildInfo info) {
    assert(_isAlive);
    if (info._element != null) {
      info._element?.activate();
      _addChildCount(info.isSeparator, 1);
    }
    if (info._separator != null) {
      _activateInfo(info._separator!);
    }
  }

  void _deactivateInfo(_ChildInfo info) {
    assert(_isAlive);
    if (info._element != null) {
      info._element?.deactivate();
      _addChildCount(info.isSeparator, -1);
    }
    if (info._separator != null) {
      _deactivateInfo(info._separator!);
    }
  }

  void recycleInfo(_ChildInfo info) {
    assert(_isAlive);
    assert(!info.isSeparator);
    if (info._element!.widget.key == null) {
      //info._deactivate();
      _tmpBucket.add(info);
    } else {
      info._doDestroy();
    }
  }

  void flushTempRecycler() {
    assert(_isAlive);
    for (var info in _tmpBucket) {
      _deactivateInfo(info);
      _bucket.add(info);
    }
    _tmpBucket.clear();
  }

  void destroyRecycler() {
    assert(_isAlive);
    _isAlive = false;

    _bucket.addAll(_tmpBucket);
    for (var info in _bucket) {
      info._doDestroy();
    }

    _tmpBucket.clear();
    _bucket.clear();
  }
}

// child information, each item has one _ChildInfo
// to keep position of child
class _ChildInfo extends SliverMultiBoxAdaptorParentData {
  bool _isActive = true;
  late _ChildManager _manager;
  Element? _parentElement;
  Element? _element;
  _ChildInfo? _separator;
  final bool isSeparator;

  Element get element => _element!;
  RenderBox get ro => _element!.renderObject as RenderBox;
  _ChildInfo? get separator => _separator;
  bool get isActive => _isActive;

  double dx = 0; // screenX when vertical, or (screenX + offset) when horizontal
  double dy = 0; // screenY when horizontal, or (screenY + offset) when vertical
  double offset = 0; // equals to dy(vertical) or dx(horizontal)
  double contentLength = 0; // content height (vertical) or width (horizontal)
  double rowMainAxisSpacing = 0; // spacing of the row which contains this item
  double get rowLength => // a 'row' contains item(content), separator, spacing
      contentLength + (separator?.contentLength ?? 0) + rowMainAxisSpacing;
  double get rowEndOffset => offset + rowLength; // bottom offset of this row

  Element? _updateChild(Element? child, Widget? newWidget, Object? newSlot) {
    Element? e;
    _parentElement!.owner!.lockState(() {
      e = _parentElement!.updateChild(child, newWidget, newSlot);
    });
    return e;
  }

  _ChildInfo._create(
      _ChildManager manager, Element parentElement, Widget widget,
      {this.isSeparator = false}) {
    _parentElement = parentElement;
    var e = _updateChild(null, widget, this);
    assert(e != null);
    //parentElement.renderObject!.adoptChild(e!.renderObject!);
    //e!.renderObject!.parentData = this;

    _manager = manager;
    _element = e;
    //_manager.onActiveChild(isSeparator);
  }

  void updateWidget(Widget newWidget) {
    assert(_isActive);
    if (newWidget == _element?.widget) return;

    var e = _updateChild(element, newWidget, this);
    assert(e != null);
    assert(e == _element);
  }

  void updateSeparator(Widget? separatorWidget) {
    assert(_isActive);
    if (separatorWidget == _separator?.element.widget) return;
    if (separatorWidget == null) {
      _separator?._doDestroy();
      _separator = null;
    } else {
      if (_separator == null) {
        _separator = _manager.createInfo(_parentElement!, separatorWidget,
            isSeparator: true);
      } else {
        _separator!.updateWidget(separatorWidget);
      }
    }
  }

  void _doDestroy() {
    assert(_isActive);
    _separator?._doDestroy();
    if (_element != null) {
      _updateChild(_element, null, null);
      //_parentElement!.renderObject!.dropChild(_element!.renderObject!);
      _manager._addChildCount(isSeparator, -1);
    }
    _parentElement = null;
    _element = null;
    _separator = null;

    //_manager.onActiveChild(isSeparator);
  }
}

class _JkLazyViewportRenderObject extends RenderBox
    implements RenderAbstractViewport, IJkItemController {
  // TODO: check this issue: https://juejin.cn/post/7134167647788204045

  final _JkLazyViewportRenderObjectElement element;
  ViewportOffset offset = ViewportOffset.zero();

  JkItemController? itemController;

  // widget attributes
  NullableIndexedWidgetBuilder? itemBuilder;
  int itemCount = 0;
  int crossAxisCount = 1; // child count per row
  double? maxCrossAxisExtent; // if not null, ignore crossAxisCount
  double cacheExtent = 0;
  AxisDirection axisDirection = AxisDirection.down;
  IndexedWidgetBuilder? separatorBuilder;
  double mainAxisSpacing = 0;
  double crossAxisSpacing = 0;
  ScrollController? controller;
  JkOnScrollPositionCallback? onScrollPosition;

  bool forceLayout = false;

  // old value variables
  int oldItemCount = 0;
  int oldCrossAxisCount = 1;
  AxisDirection oldAxisDirection = AxisDirection.down;

  BuildContext get context => element;
  _ChildManager get childManager => element.childManager;
  bool get separatorEnabled => separatorBuilder != null && crossAxisCount == 1;

  // NOTE: firstRowIndex > lastRowIndex means there is no any active child
  int firstRowIndex = -1; // first row: math.min(all active rows index)
  int lastRowIndex = -2; // last row: math.max(all active rows index)
  double averageRowHeight = 100; // including separator & spacing

  bool isReverse = false;
  bool isVertical = true;

  double minScrollExtent = 0; // remember the value of offset.minScrollExtent
  double maxScrollExtent = 0; // remember the value of offset.maxScrollExtent

  double get mainAxisScreenSize => isVertical ? size.height : size.width;
  double get crossAxisScreenSize => !isVertical ? size.height : size.width;

  _JkLazyViewportRenderObject(this.element);

  void validateWidgetInfo(_JkLazyViewport widget) {
    assert(widget.itemCount >= 0);
    //assert(widget.itemBuilder != null);
    assert(widget.cacheExtent >= 0);
    assert(widget.crossAxisCount >= 1);

    if (widget.separatorBuilder != null) {
      assert(widget.crossAxisCount == 1);
      assert(widget.maxCrossAxisExtent == null);
      assert(widget.mainAxisSpacing == 0);
      assert(widget.crossAxisSpacing == 0);
    } else {
      assert(widget.maxCrossAxisExtent == null ||
          widget.maxCrossAxisExtent! >= 10);
      assert(widget.mainAxisSpacing >= 0);
      assert(widget.crossAxisSpacing >= 0);
    }
  }

  void detectValueChanged(bool isUpdate) {
    if (!isUpdate) {
      // first time set value
      updateOldValues();
    } else {
      if (oldCrossAxisCount != crossAxisCount ||
          oldAxisDirection != axisDirection) {
        forceLayout = true;
      }
    }
  }

  void updateOldValues() {
    oldItemCount = itemCount;
    oldCrossAxisCount = crossAxisCount;
    oldAxisDirection = axisDirection;
  }

  void updateWidgetInfo(_JkLazyViewport widget, bool isUpdate) {
    validateWidgetInfo(widget);
    detectValueChanged(isUpdate);

    if (itemController != widget.itemController) {
      itemController?._connect(null);
      itemController = widget.itemController;
      itemController?._connect(this);
    }

    if (offset != widget.offset) {
      if (attached) {
        // ref: RenderViewportBase
        offset.removeListener(onScrolling);
        widget.offset.addListener(onScrolling);
      }
      offset = widget.offset;
    }

    onScrollPosition = widget.onScrollPosition;
    itemBuilder = widget.itemBuilder;
    itemCount = widget.itemCount;
    cacheExtent = widget.cacheExtent;
    mainAxisSpacing = widget.mainAxisSpacing;
    crossAxisSpacing = widget.crossAxisSpacing;
    crossAxisCount = widget.crossAxisCount;
    maxCrossAxisExtent = widget.maxCrossAxisExtent;

    if (widget.separatorBuilder != null && crossAxisCount != 1) {
      log("separatorBuilder is ignored when crossAxisCount != 1");
      separatorBuilder = null;
    } else {
      separatorBuilder = widget.separatorBuilder;
    }

    axisDirection = widget.axisDirection;
    isReverse = (axisDirection == AxisDirection.up) ||
        (axisDirection == AxisDirection.left);
    isVertical = (axisDirection == AxisDirection.up) ||
        (axisDirection == AxisDirection.down);

    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    element.childInfoMap.forEach((index, info) {
      info.ro.attach(owner); // paintChild() related
      info.separator?.ro.attach(owner);
    });

    offset.addListener(onScrolling); // ref: RenderViewportBase
  }

  @override
  void detach() {
    super.detach();
    element.childInfoMap.forEach((index, info) {
      info.ro.detach();
      info.separator?.ro.detach();
    });

    offset.removeListener(onScrolling); // ref: RenderViewportBase
  }

  @override
  void dispose() {
    super.dispose();
    // do nothing
  }

  // ----------------

  _ChildInfo inflateChildIf(int childIndex) {
    assert(childIndex < itemCount);
    var childInfo = element.childAt(childIndex);
    if (childInfo != null) return childInfo;

    final childWidget = itemBuilder!(context, childIndex);
    assert(childWidget != null,
        "[JkLargeListview] itemBuilder() return null is not allowed");

    var info = childManager.createInfo(element, childWidget!);
    element.childInfoMap[childIndex] = info;
    return info;
  }

  void inflateSeparatorIf(int childIndex) {
    assert(separatorEnabled);
    assert(childIndex < itemCount);
    var childInfo = element.childAt(childIndex);
    assert(childInfo != null);

    // if separator not created yet
    Widget? separatorWidget;
    if (childIndex < itemCount - 1) {
      separatorWidget = separatorBuilder!(context, childIndex);
    }
    childInfo!.updateSeparator(separatorWidget);
  }

  /// is the offset value in the visible area or cacheExtent area
  bool isOffsetVisible(double offset) {
    return offset >= (this.offset.pixels - cacheExtent) &&
        offset <= (this.offset.pixels + mainAxisScreenSize + cacheExtent);
  }

  /// layout children in 'rowIndex' row at 'rowOffset' position
  /// assumption: children in this row are alredy created
  /// isBackward==false: all children's offset are 'rowOffset'
  /// isBackward==true:  all children's endOffset are 'rowOffset'
  double? layoutRow(int rowIndex, double rowOffset, bool isBackward) {
    int rowFirstChildIndex = rowIndex * crossAxisCount;
    assert(element.childAt(rowFirstChildIndex) != null);

    bool isLastRow = rowIndex + 1 >= totalRowsCount;

    // NOTE: all the 'width' and 'height' are relative to vertical list
    //       to swap 'width' and 'height' when horizontal list

    // width of each item (all width of children are the same)
    double itemWidth =
        (crossAxisScreenSize - (crossAxisCount - 1) * crossAxisSpacing) /
            crossAxisCount;

    // max(children's item height), without separator & spacing
    double maxRowItemHeight = 0;

    // main axis spacing of this row (the last row has no spacing)
    double rowMainAxisSpacing = isLastRow ? 0 : mainAxisSpacing;

    // calc rowHeight
    // calc height of all children in this row, and find the max item height
    int childIndex = rowFirstChildIndex;
    for (int i = 0; i < crossAxisCount; i++, childIndex++) {
      if (childIndex >= itemCount) break;
      final childInfo = element.childAt(childIndex);
      assert(childInfo != null);

      if (childInfo!.contentLength <= 0 || forceLayout) {
        // if child not layout yet, forceLayout==true
        double itemHeight = isVertical
            ? childInfo.ro.getMaxIntrinsicHeight(itemWidth)
            : childInfo.ro.getMaxIntrinsicWidth(itemWidth);
        maxRowItemHeight = math.max(maxRowItemHeight, itemHeight);
      } else {
        maxRowItemHeight = math.max(maxRowItemHeight, childInfo.contentLength);
      }
    }

    // get size of separator if need
    double separatorHeight = 0;
    if (separatorEnabled && !isLastRow) {
      // in this case, 'crossAxisCount' must be 1, so we get child by 'rowIndex'
      // separator only enabled when crossAxisCount==1
      final childInfo = element.childAt(rowIndex);
      separatorHeight = isVertical
          ? childInfo!.separator!.ro.getMaxIntrinsicHeight(crossAxisScreenSize)
          : childInfo!.separator!.ro.getMaxIntrinsicWidth(crossAxisScreenSize);
    }

    if (isBackward) {
      rowOffset =
          rowOffset - rowMainAxisSpacing - separatorHeight - maxRowItemHeight;
    }

    // set position for all children in this row
    final layoutRule = isVertical
        ? BoxConstraints(
            minWidth: itemWidth,
            maxWidth: itemWidth,
            minHeight: maxRowItemHeight,
            maxHeight: maxRowItemHeight)
        : BoxConstraints(
            minHeight: itemWidth,
            maxHeight: itemWidth,
            minWidth: maxRowItemHeight,
            maxWidth: maxRowItemHeight);
    childIndex = rowFirstChildIndex;
    for (int i = 0; i < crossAxisCount; i++, childIndex++) {
      if (childIndex >= itemCount) break;
      final childInfo = element.childAt(childIndex);
      assert(childInfo != null);

      if (childInfo!.contentLength <= 0 || forceLayout) {
        // if child not layout yet
        childInfo.ro.layout(layoutRule);
        childInfo.contentLength =
            isVertical ? childInfo.ro.size.height : childInfo.ro.size.width;
      }

      childInfo.offset = rowOffset;
      childInfo.rowMainAxisSpacing = rowMainAxisSpacing;
      if (isVertical) {
        childInfo.dx = i * (itemWidth + crossAxisSpacing);
        childInfo.dy = rowOffset;
      } else {
        childInfo.dy = i * (itemWidth + crossAxisSpacing);
        childInfo.dx = rowOffset;
      }
    }

    // set position of separator if need
    if (separatorEnabled && !isLastRow) {
      final layoutRule = isVertical
          ? BoxConstraints(
              minWidth: itemWidth,
              maxWidth: itemWidth,
              minHeight: separatorHeight,
              maxHeight: separatorHeight)
          : BoxConstraints(
              minHeight: itemWidth,
              maxHeight: itemWidth,
              minWidth: separatorHeight,
              maxWidth: separatorHeight);
      final childInfo = element.childAt(rowIndex)!;
      if (childInfo.contentLength <= 0 || forceLayout) {
        childInfo.separator!.ro.layout(layoutRule);
      }
      var separatorOffset = rowOffset + maxRowItemHeight;
      childInfo.separator!.offset = separatorOffset;
      childInfo.separator!.contentLength = separatorHeight;
      if (isVertical) {
        childInfo.separator!.dx = 0;
        childInfo.separator!.dy = separatorOffset;
      } else {
        childInfo.separator!.dy = 0;
        childInfo.separator!.dx = separatorOffset;
      }
    }

    var rowHeight = maxRowItemHeight + separatorHeight + rowMainAxisSpacing;
    averageRowHeight = averageRowHeight * 0.7 + rowHeight * 0.3;
    return rowHeight;
  }

  /// create all children in this row, and layout them
  /// assume no children this row is alive now
  /// return null: if row cannot exist (ex. out of 'itemCount' range)
  ///              or row is out of visible range
  /// isBackward == false : new row's starts from rowOffset
  /// isBackward == true  : new row's ends at rowOffset
  /// ignoreVisibility == true : create this row even if not in visible area
  double? createRow(int rowIndex, double rowOffset, bool isBackward,
      {bool ignoreVisibility = false}) {
    int rowFirstChildIndex = rowIndex * crossAxisCount;
    //assert(element.childAt(rowFirstChildIndex) == null);
    if (rowFirstChildIndex < 0 || rowFirstChildIndex >= itemCount) return null;

    // don't create this row if 'rowOffset' is not in visible area
    if (!ignoreVisibility && !isOffsetVisible(rowOffset)) {
      return null;
    }

    // create children in this row
    int childIndex = rowFirstChildIndex;
    for (int i = 0; i < crossAxisCount; i++, childIndex++) {
      if (childIndex >= itemCount) break;
      inflateChildIf(childIndex);
    }

    // create separator if need
    if (separatorEnabled) {
      inflateSeparatorIf(rowIndex);
    }

    return layoutRow(rowIndex, rowOffset, isBackward);
  }

  bool isAnyActiveRow() {
    return firstRowIndex <= lastRowIndex;
  }

  int get totalRowsCount =>
      ((itemCount + crossAxisCount - 1) / crossAxisCount).floor();

  /// if no any active child, create a new row according to current offset
  /// 'active child' means child in visible/cacheExtent area
  void createOneRowIfNoActiveChild() {
    //if (isAnyActiveRow()) return; // if any active row exists, exit

    // if any active row exists, or if itemCount==0, exit
    if (element.childInfoMap.isNotEmpty) return;
    if (itemCount <= 0) return;

    // estimate the firstRowIndex value in the visible area
    double totalContentExtent =
        maxScrollExtent - minScrollExtent + mainAxisScreenSize;
    double estimateRowHeight = totalContentExtent / totalRowsCount;
    firstRowIndex = (((offset.pixels - minScrollExtent) / totalContentExtent) *
            totalRowsCount)
        .ceil();
    double firstRowOffset = minScrollExtent + firstRowIndex * estimateRowHeight;

    firstRowIndex = firstRowIndex.clamp(0, totalRowsCount - 1);
    firstRowOffset = firstRowOffset.clamp(
        minScrollExtent, maxScrollExtent + mainAxisScreenSize);

    var rowHeight = createRow(firstRowIndex, firstRowOffset, false);
    assert(rowHeight != null);

    lastRowIndex = firstRowIndex;
  }

  /// if itemCount increased, fill items into the 'lastRowIndex' row if possible
  /// ex. if last row child index is start from 90, with countPerRow=10,
  ///     and itemCount is changed from 95 to 200,
  ///     then we should create child (96~99) in last row
  void fillLastRowIfItemCountIncreased() {
    if (itemCount == oldItemCount) return;
    if (!isAnyActiveRow()) return;

    bool isAnyChildCreated = false;
    double rowOffset = getRowFirstChild(lastRowIndex)!.offset;

    int startIndex = lastRowIndex * crossAxisCount;
    for (int i = crossAxisCount - 1; i >= 1; i--) {
      int childIndex = startIndex + i;
      if (childIndex >= itemCount) continue;
      if (element.childAt(childIndex) != null) break;

      inflateChildIf(childIndex);
      isAnyChildCreated = true;
    }

    if (isAnyChildCreated) {
      layoutRow(lastRowIndex, rowOffset, false);
    }
  }

  _ChildInfo? getRowFirstChild(int rowIndex) {
    // return null if row not active
    return element.childAt(rowIndex * crossAxisCount);
  }

  double? getRowHeight(int rowIndex) {
    // return null if row not active
    return getRowFirstChild(rowIndex)?.contentLength;
  }

  int? anchorChildIndex; // index of top-left visible child
  double? anchorChildOffset;

  /// find top-left first on-screen child (anchor child)
  /// if success, the value 'anchorChildIndex' updated
  void findAnchorChild(int crossAxisCount) {
    if (anchorChildIndex != null) return;

    // find the top-left visible first child
    for (int rowIndex = firstRowIndex; rowIndex <= lastRowIndex; rowIndex++) {
      int childIndex = rowIndex * oldCrossAxisCount;
      var info = element.childAt(childIndex);
      if (info == null) continue;
      anchorChildIndex = childIndex;
      anchorChildOffset = info.offset;
      if (info.offset >= offset.pixels) break; //found
    }
  }

  /// re-layout all visible children if
  ///   * crossAxisCount changed
  ///   * or forceLayout==true (ex. listview widget rebuild, child rebuild)
  ///     NOTE: child cannot paint after widget rebuild without re-layout...
  /// both cases need to find the anchor (on-screen top-left) child,
  /// and re-layout all other visible children
  /// according to the anchor child's position
  bool relayoutAllVisibleChildrenByAnchor() {
    if (element.childInfoMap.isEmpty) return false;

    // NOTE: find anchor with value 'oldCrossAxisCount'
    //       if crossAxisCount changes, the position of top-left on-screen child
    //       also changes, we need to find 'anchorChildIndex' before this change
    findAnchorChild(oldCrossAxisCount);
    if (anchorChildIndex == null || anchorChildOffset == null) {
      assert(false, "findAnchorChild() fails");
      return false;
    }
    //log("relayout now, anchor child index = $anchorChildIndex");

    firstRowIndex = (anchorChildIndex! / crossAxisCount).floor();
    lastRowIndex = firstRowIndex - 1;

    // layout rows forward
    double rowOffset = anchorChildOffset!;
    while (true) {
      double? rowHeight = createRow(lastRowIndex + 1, rowOffset, false);
      if (rowHeight == null) break; // row is out of 'itemCount' range
      rowOffset += rowHeight;
      lastRowIndex++;
    }

    // layout rows backward
    rowOffset = anchorChildOffset!;
    while (firstRowIndex >= 0) {
      double? rowHeight = createRow(firstRowIndex - 1, rowOffset, true);
      if (rowHeight == null) break; // row is out of 'itemCount' range
      rowOffset -= rowHeight;
      firstRowIndex--;
    }

    // remove invisible children backward
    for (int index = firstRowIndex * crossAxisCount - 1; index >= 0; index--) {
      bool removed = element.removeChildAt(index);
      if (!removed) break;
    }

    // remove invisible children forward
    for (int index = (lastRowIndex + 1) * crossAxisCount;
        index < itemCount;
        index++) {
      bool removed = element.removeChildAt(index);
      if (!removed) break;
    }

    return true;
  }

  /// during scrolling, some area becomes visible, some becomes invisible
  /// so we remove rows in invisible area (by [removeInvisibleRows])
  /// and create rows incoming new visible area here
  void createVisibleChildrenWhenScrolling() {
    fillLastRowIfItemCountIncreased();

    // if scrolling too fast, old visible area are all invisible,
    // we remove all children in [removeInvisibleRows],
    // and call [createOneRowIfNoActiveChild] to create one row in visible area
    // according to current offset
    createOneRowIfNoActiveChild();

    // create rows backward
    double rowOffset = getRowFirstChild(firstRowIndex)?.offset ?? 0;
    while (firstRowIndex >= 0) {
      double? rowHeight = createRow(firstRowIndex - 1, rowOffset, true);
      if (rowHeight == null) break; // row is out of 'itemCount' range
      rowOffset -= rowHeight;
      firstRowIndex--;
    }

    // create rows forward
    rowOffset = getRowFirstChild(lastRowIndex)?.rowEndOffset ?? 0;
    while (true) {
      double? rowHeight = createRow(lastRowIndex + 1, rowOffset, false);
      if (rowHeight == null) break; // row is out of 'itemCount' range
      rowOffset += rowHeight;
      lastRowIndex++;
    }
  }

  void removeRow(int rowIndex) {
    int childIndex = rowIndex * crossAxisCount;

    // remove items in this row
    for (int i = 0; i < crossAxisCount; i++) {
      bool removed = element.removeChildAt(childIndex + i);
      if (!removed) break;
    }
  }

  bool removeRowIfInvisible(
      int rowIndex, double topOffset, double bottomOffset) {
    int childIndex = rowIndex * crossAxisCount;
    var info = element.childAt(childIndex);
    if (info == null) return false; // this row not activate
    if (info.rowEndOffset < topOffset || info.offset > bottomOffset) {
      // this row is invisible, so remove it
      removeRow(rowIndex);
      return true;
    }
    return false; // this row is visible, don't remove
  }

  /// remove any child in this row if it's childIndex >= itemCount
  /// return true if this whole row children are removed
  /// return false if this row has still one or more children left (so row not removed)
  bool removeChildrenInRowIfBeyondItemCount(int rowIndex) {
    int firstChildIndex = rowIndex * crossAxisCount;
    for (int i = crossAxisCount - 1; i >= 0; i--) {
      int childIndex = firstChildIndex + i;
      if (childIndex < itemCount) {
        // some children remains in this row, so not remove this row
        return false;
      }
      element.removeChildAt(childIndex);
    }
    return true; // all children in this row are removed
  }

  /// remove any rows not visible and not in cacheExtent area
  void removeInvisibleRows() {
    // don't remove invisible rows if scrolling to specified item with animation
    if (scrollingToIndex) return;

    // visible area: between [topOffset] and [bottomOffset] (including cache area)
    final double topOffset = offset.pixels - cacheExtent;
    final double bottomOffset =
        (offset.pixels + mainAxisScreenSize) + cacheExtent;

    // remove top invisible rows
    while (isAnyActiveRow()) {
      bool rowRemoved =
          removeRowIfInvisible(firstRowIndex, topOffset, bottomOffset);
      if (!rowRemoved) break;
      firstRowIndex++;
    }

    // remove bottom invisible rows
    while (isAnyActiveRow()) {
      bool rowRemoved =
          removeRowIfInvisible(lastRowIndex, topOffset, bottomOffset);
      if (!rowRemoved) break;
      lastRowIndex--;
    }

    // remove children whoes index >= itemCount
    while (isAnyActiveRow()) {
      bool rowRemoved = removeChildrenInRowIfBeyondItemCount(lastRowIndex);
      if (!rowRemoved) break;
      lastRowIndex--;
    }
  }

  /// if current active rows total height not fill the viewport's size.height,
  /// we create new rows until 'size.height' filled
  void fillEmptySpaceIf() {
    if (element.childInfoMap.isEmpty) return;

    var firstRowOffset = getRowFirstChild(firstRowIndex)!.offset;
    var lastRowEndOffset = getRowFirstChild(lastRowIndex)!.rowEndOffset;
    double remainSpace =
        mainAxisScreenSize - (lastRowEndOffset - firstRowOffset);

    // if active row fills whole viewport space, exit
    if (remainSpace <= 0) return;

    // create row backward
    double rowOffset = firstRowOffset;
    while (firstRowIndex >= 0 && remainSpace > 0) {
      double? rowHeight =
          createRow(firstRowIndex - 1, rowOffset, true, ignoreVisibility: true);
      if (rowHeight == null) break; // row is out of 'itemCount' range
      rowOffset -= rowHeight;
      firstRowIndex--;

      remainSpace -= rowHeight;
    }

    // create row forward
    rowOffset = lastRowEndOffset;
    while (lastRowIndex + 1 < totalRowsCount && remainSpace > 0) {
      double? rowHeight =
          createRow(lastRowIndex + 1, rowOffset, false, ignoreVisibility: true);
      if (rowHeight == null) break; // row is out of 'itemCount' range
      rowOffset += rowHeight;
      lastRowIndex++;

      remainSpace -= rowHeight;
    }
  }

  @override
  void markNeedsLayout() {
    // called by childing rebuild, ancestor widget rebuild, and scrolling
    super.markNeedsLayout();
    forceLayout = true;
  }

  bool isScrolling = false;
  void onScrolling() {
    isScrolling = true;
    // when scrolling, don't modify 'forceLayout'
    bool oldForceLayout = forceLayout;
    markNeedsLayout();
    forceLayout = oldForceLayout;
  }

  void updateDimensions() {
    // update minScrollExtent, maxScrollExtent
    minScrollExtent = (getRowFirstChild(firstRowIndex)?.offset ?? 0) -
        firstRowIndex * averageRowHeight;
    maxScrollExtent = (getRowFirstChild(lastRowIndex)?.rowEndOffset ?? 0) +
        (totalRowsCount - lastRowIndex - 1) * averageRowHeight -
        mainAxisScreenSize;
    maxScrollExtent = math.max(maxScrollExtent, minScrollExtent);
    if (offset.pixels > maxScrollExtent) {
      offset.correctBy(maxScrollExtent - offset.pixels);
    } else if (offset.pixels < minScrollExtent) {
      offset.correctBy(minScrollExtent - offset.pixels);
    }
    offset.applyViewportDimension(mainAxisScreenSize);
    offset.applyContentDimensions(minScrollExtent, maxScrollExtent);
    //offset.correctBy(correction);
  }

  bool isFirstTimeLayout = true;
  @override
  void performLayout() {
    //super.performLayout(); // don't call this

    if (isFirstTimeLayout) {
      size = constraints.biggest;
    }

    if (size != constraints.biggest) {
      if (forceLayout ||
          (isVertical && size.width != constraints.biggest.width) ||
          (!isVertical && size.height != constraints.biggest.height)) {
        // listview resized, force layout now
        forceLayout = true;
      }
      size = constraints.biggest;
      //log("constraints.biggest = ${constraints.biggest}");
    }

    // calc [crossAxisCount] by [maxCrossAxisExtent]
    if (maxCrossAxisExtent != null) {
      crossAxisCount = isVertical
          ? (size.width / (maxCrossAxisExtent! + crossAxisSpacing)).ceil()
          : (size.height / (maxCrossAxisExtent! + crossAxisSpacing)).ceil();
      //log("dynamic crossAxisCount = $crossAxisCount");
    }

    if (!isFirstTimeLayout && oldCrossAxisCount != crossAxisCount) {
      forceLayout = true;
    }

    invokeLayoutCallback<Constraints>((Constraints constraints) {
      element.owner!.buildScope(element, () {
        // if itemCount changes and firstRowIndex becomes invalid,
        // remove all active children
        // ex. when firstChildIndex=1000, and itemCount changes to 900
        if (firstRowIndex * oldCrossAxisCount >= itemCount) {
          for (var info in element.childInfoMap.values) {
            childManager.recycleInfo(info);
          }
          element.childInfoMap.clear();

          minScrollExtent = 0;
          maxScrollExtent = itemCount * averageRowHeight - mainAxisScreenSize;
          offset.correctBy(-offset.pixels);
          if (itemCount > 0) {
            _animateToIndex(itemCount - 1, alignment: 1);
          }
          forceLayout = false;
        }

        if (forceLayout && element.childInfoMap.isNotEmpty) {
          // according to updateWidgetInfo(), when:
          //    * crossAxisCount changed,
          //    * listview widget resized,
          //    * listview widget rebuild,
          //    * renderBox size changed,
          //    * axisDirection changed,
          // find the original on-screen top-left child (anchor),
          // and re-layout all children,
          // and place them according to position of anchor
          relayoutAllVisibleChildrenByAnchor();

          // after relayout, current active children may grow up,
          // so remove any invisible rows
          //removeInvisibleRows();

          // when user scroll to start/end,
          // and user rebuild widget,
          // and the new widget is smaller than previous ones,
          // this cause the empty top/bottom space,
          // although flutter scrollable will automatic scroll-up since we set maxScrollExtent,
          // but that will still cause empty top/bottom space...
          // so we fill the empty space here
          // this case rarely occurs...
          // and maybe not occurs with large cacheExtent
          fillEmptySpaceIf();
        } else {
          // if is first time layout,
          // scroll to the itemController._initialIndex if user specified
          if (isFirstTimeLayout && itemController?._initialIndex != null) {
            offset.applyViewportDimension(mainAxisScreenSize);
            offset.applyContentDimensions(minScrollExtent, maxScrollExtent);
            _animateToIndex(itemController!._initialIndex!,
                alignment: itemController?._initialAlignment);
          }

          // when listview scrolling, forgot anchorChildIndex
          anchorChildIndex = null;

          removeInvisibleRows();
          createVisibleChildrenWhenScrolling();
        }
      });
    });

    // notify user the item scrolling information
    if (onScrollPosition != null) {
      int firstVisibleIndex = getFirstVisibleIndex();
      double ratio = 0;
      if (firstVisibleIndex >= 0) {
        var info = element.childAt(firstVisibleIndex)!;
        ratio = (info.rowEndOffset - offset.pixels) / info.rowLength;
      }
      onScrollPosition!(firstVisibleIndex, ratio);
    }

    forceLayout = false;
    isScrolling = false;
    isFirstTimeLayout = false;
    updateDimensions();
    updateOldValues();
    childManager.flushTempRecycler();

    //log("[performLayout] visible row index: $firstRowIndex ~ $lastRowIndex");
    //log("[performLayout] active element count: ${element.childInfoMap.length}");
    //log("[performLayout] pixel: ${offset.pixels} , pixel range: $minScrollExtent ~ $maxScrollExtent");

    // check if old children destroyed
    assert(element.childInfoMap.length <=
        (lastRowIndex - firstRowIndex + 1) * crossAxisCount);
    assert(childManager._childCount <=
        (lastRowIndex - firstRowIndex + 1) * crossAxisCount);
    assert((!separatorEnabled && childManager._separatorCount == 0) ||
        (separatorEnabled &&
            childManager._separatorCount <=
                (lastRowIndex - firstRowIndex + 1) * crossAxisCount));
  }

  // ----------------

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    element.childInfoMap.forEach((index, info) {
      visitor(info.ro);
      if (info.separator != null) {
        visitor(info.separator!.ro);
      }
    });
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    element.childInfoMap.forEach((index, info) {
      visitor(info.ro);
      if (info.separator != null) {
        visitor(info.separator!.ro);
      }
    });
  }

  @override
  void redepthChildren() {
    element.childInfoMap.forEach((index, info) {
      redepthChild(info.ro);
      if (info.separator != null) {
        redepthChild(info.separator!.ro);
      }
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    for (var info in element.childInfoMap.values) {
      if (!info.isActive) continue;
      assert(!info.ro.debugNeedsLayout); // cannot paint child if not layout yet

      Offset _translate(Offset point, double diff) {
        return isVertical ? point.translate(0, diff) : point.translate(diff, 0);
      }

      // position of content (info.ro) , ignore sperator & spacing
      Offset screenXY = getChildScreenPos(info);
      if (!isReverse) {
        // paint item widget
        context.paintChild(info.ro, screenXY);

        // paint separator if exists
        if (info.separator != null) {
          screenXY = _translate(screenXY, info.contentLength);
          context.paintChild(info.separator!.ro, screenXY);
        }
      } else {
        // paint item widget
        context.paintChild(info.ro, screenXY);

        // paint separator if exists
        if (info.separator != null) {
          screenXY = _translate(screenXY, -info.separator!.contentLength);
          context.paintChild(info.separator!.ro, screenXY);
        }
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    //super.hitTestChildren(result, position: position);

    for (var value in element.childInfoMap.values) {
      Offset screenXY = getChildScreenPos(value);
      bool found = value.ro.hitTest(result, position: position - screenXY);
      if (found) {
        result.add(BoxHitTestEntry(this, position));
        break;
      }
    }
    return false;
  }

  @override
  RevealedOffset getOffsetToReveal(RenderObject target, double alignment,
      {Rect? rect}) {
    // called by FocusTraversalPolicy._moveFocus, Scrollable.ensureVisible

    RenderObject childRO = target;
    while (childRO.parent != this) {
      childRO = childRO.parent!;
    }

    var info = childRO.parentData as _ChildInfo;

    rect ??= target.paintBounds;
    rect = MatrixUtils.transformRect(target.getTransformTo(childRO), rect);

    if (isVertical) {
      double screenDestY = (size.height - rect.height) * alignment;
      double offset = info.offset + rect.top - screenDestY;
      offset = clampDouble(offset, minScrollExtent, maxScrollExtent);
      rect = Rect.fromLTWH(info.dx + rect.left, info.dy + rect.top - offset,
          rect.width, rect.height);
      //log("revealed: offset=$offset, rect.top=${rect.top}, alignment=$alignment");
      return RevealedOffset(offset: offset, rect: rect);
    } else {
      double screenDestX = (size.width - rect.width) * alignment;
      double offset = info.offset + rect.left - screenDestX;
      offset = clampDouble(offset, minScrollExtent, maxScrollExtent);
      rect = Rect.fromLTWH(info.dx + rect.left - offset, info.dy + rect.top,
          rect.width, rect.height);
      //log("revealed: offset=$offset, rect.top=${rect.top}, alignment=$alignment");
      return RevealedOffset(offset: offset, rect: rect);
    }
  }

  Offset getChildScreenPos(_ChildInfo info) {
    return MatrixUtils.transformPoint(
        info.ro.getTransformTo(this), Offset.zero);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    // this enable focus operations
    var info = child.parentData as _ChildInfo;
    double offsetDy = 0;
    if (!isReverse) {
      offsetDy = info.offset - offset.pixels;
    } else {
      // translate to 'content', ignore separator, spacing
      // otherwise hitTest may wrong
      offsetDy = mainAxisScreenSize -
          (info.offset + info.contentLength - offset.pixels);
    }

    if (isVertical) {
      transform.translate(info.dx, offsetDy);
    } else {
      transform.translate(offsetDy, info.dy);
    }
  }

  // ----------------
  // IJkItemController implementation
  // ----------------

  /// called when user ask scrolling too far,
  /// or first-time-layout with initial index assigned
  /// remove all children, and create specified row directly
  void removeAllAndScrollToIndex(int index, {double? alignment}) {
    // remove all active children
    element.childInfoMap.forEach((_, info) => childManager.recycleInfo(info));
    element.childInfoMap.clear();

    // create one row which contains 'index' item
    var targetRowIndex = (index / crossAxisCount).floor();
    var rowHeight = createRow(targetRowIndex, offset.pixels, false);
    assert(rowHeight != null);
    firstRowIndex = lastRowIndex = targetRowIndex;

    // if 'alignment' specified, adjust the row offset
    if (alignment != null) {
      double rowOffset =
          offset.pixels + (mainAxisScreenSize - rowHeight!) * alignment;
      layoutRow(targetRowIndex, rowOffset, false);
    }

    // create other rows in visible area
    createVisibleChildrenWhenScrolling();
    anchorChildIndex = null; //clear anchor
    updateDimensions();
    //markNeedsPaint();
  }

  /// if 'targetIndex' is not in active area,
  /// create rows continuously until 'targetIndex' reached
  void growRowsUntilIndex(int targetIndex) {
    assert(element.childInfoMap.isNotEmpty);
    assert(targetIndex >= 0 && targetIndex < itemCount);

    var targetRowIndex = (targetIndex / crossAxisCount).floor();
    double rowOffset = 0;

    // grow backward
    if (targetRowIndex < firstRowIndex) {
      rowOffset = getRowFirstChild(firstRowIndex)!.offset;
      while (targetRowIndex < firstRowIndex) {
        var rowHeight = createRow(firstRowIndex - 1, rowOffset, true,
            ignoreVisibility: true);
        assert(rowHeight != null);
        rowOffset -= rowHeight!;
        firstRowIndex--;
      }
    }

    // grow forward
    if (lastRowIndex < targetRowIndex) {
      rowOffset = getRowFirstChild(lastRowIndex)!.rowEndOffset;
      while (lastRowIndex < targetRowIndex) {
        var rowHeight = createRow(lastRowIndex + 1, rowOffset, false,
            ignoreVisibility: true);
        assert(rowHeight != null);
        rowOffset += rowHeight!;
        lastRowIndex++;
      }
    }
  }

  /// get how many distance to scroll to destination
  /// return null if 'index' is not in visible area
  double? getDistanceToIndex(int index, {double? alignment}) {
    double? rowHeight;
    int targetRowIndex = (index / crossAxisCount).floor();
    double distance = 0;

    if (firstRowIndex <= targetRowIndex && targetRowIndex <= lastRowIndex) {
      // target item already in visible area
      var info = element.childAt(index)!;
      rowHeight = info.rowLength;

      if (alignment != null) {
        // position target item to offset, and adjust by 'alignment' later
        distance = info.offset - offset.pixels;
        distance -= (mainAxisScreenSize - rowHeight) * alignment;
      } else {
        // check if some part of child is invisible,
        // and auto scroll to make child fully visible in a minimum distance
        if (info.offset < offset.pixels) {
          distance = info.offset - offset.pixels;
        } else if (info.rowEndOffset > offset.pixels + mainAxisScreenSize) {
          distance = info.rowEndOffset - (offset.pixels + mainAxisScreenSize);
        } else {
          distance = 0; // don't scroll
        }
      }
      return distance;
    }

    return null;
  }

  Future<void> _animateToIndex(int index,
      {double? alignment, Duration? duration, Curve? curve}) async {
    if (index >= itemCount) {
      log("jumpToIndex: index >= itemCount, ignored");
      return;
    }

    Future<void> _doScrollTo(double pixels) async {
      if (duration == null) {
        offset.jumpTo(pixels);
      } else {
        await offset.animateTo(pixels, duration: duration, curve: curve!);
      }
    }

    if (element.childInfoMap.isEmpty) {
      // this case occurs if firstTimeLayout and user specified initialIndex
      removeAllAndScrollToIndex(index, alignment: alignment);
      return;
    }

    int targetRowIndex = (index / crossAxisCount).floor();
    if (firstRowIndex <= targetRowIndex && targetRowIndex <= lastRowIndex) {
      // if target is in visible area
      double distance = getDistanceToIndex(index, alignment: alignment)!;
      await _doScrollTo(offset.pixels + distance);
    } else {
      // if target is not in visible area

      int maxRowDiffAllow = (2 * mainAxisScreenSize / averageRowHeight).floor();
      if (targetRowIndex + maxRowDiffAllow < firstRowIndex ||
          lastRowIndex + maxRowDiffAllow < targetRowIndex) {
        // scroll too far, remove all and create again
        removeAllAndScrollToIndex(index, alignment: alignment);
      } else /*if (lastRowIndex < targetRowIndex)*/ {
        // if not too far, create rows and scroll
        growRowsUntilIndex(index);
        double distance = getDistanceToIndex(index, alignment: alignment)!;
        await _doScrollTo(offset.pixels + distance);
      }
    }
  }

  @override
  void jumpToIndex(int index, {double? alignment}) {
    element.owner?.lockState(() {
      _animateToIndex(index, alignment: alignment);
    });
  }

  bool scrollingToIndex = false; // is user scrolling to specified item
  @override
  Future<void> animateToIndex(int index,
      {double? alignment,
      required Duration duration,
      required Curve curve}) async {
    scrollingToIndex = true;
    await _animateToIndex(index,
        alignment: alignment, duration: duration, curve: curve);
    scrollingToIndex = false;
  }

  @override
  int getFirstVisibleIndex() {
    if (itemCount <= 0) return -1;
    for (int rowIndex = firstRowIndex; rowIndex <= lastRowIndex; rowIndex++) {
      int childIndex = rowIndex * crossAxisCount;
      var info = element.childAt(childIndex)!;
      if (info.rowEndOffset > offset.pixels) {
        return childIndex;
      }
    }
    return -1;
  }
}
