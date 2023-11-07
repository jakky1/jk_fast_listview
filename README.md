# JkFastListView

ListView / GridView for Flutter. Support fast scrolling among a large amount of data, flexible widget size, index-based scrolling, item recycler.

## Features

- Most API are the same with official flutter's ListView / GridView.
- Fast scrolling among a large amount of data.
- Flexible widget size.
- scroll to item with specified index.
- Listen to index of current first visible item.
- Item recycler.

## Who need this package?

- If all the items has the same width & height, please use official flutter [ListView][1] and [GridView][2]. Both classes work well with fixed-size items, also support fast scrolling among a large amount of data in this case.
- If the width & height of items are variable, and you need to fast jump to far-far-away item (by call jumpToIndex / animateToIndex, or drag scrollbar by user), please use this package. This is useful for some applications (ex. chat app).

# Quick Start

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  jk_fast_listview: ^0.8.0
```

# Usage

## Build a ListView

NOTE: name of most of the params are the same with official flutter's [ListView][1] and [GridView][2]. We don't explain each params here again.

```
var listview = JkFastListView(
  itemCount: 999999,
  itemBuilder: (context, index) => Text("Item $index"),

  // optional, cannot be used in grid type
  separatorBuilder: (context, index) => const Divider(), // optional
);
```

## Build a GridView

```
var listview = JkFastListView(
  itemCount: 999999,
  itemBuilder: (context, index) => Text("Item $index"),

  crossAxisCount: 3, // add this line to make 3 items per row

  // another way to specify item count per row, cannot use with 'crossAxisCount'
  // maxCrossAxisExtent: 300,

  mainAxisSpacing: 20,  // optional
  crossAxisSpacing: 20, // optional
);
```

## other common optional params

The definition of these following parameters can be found in [ListView][1]

```
var listview = JkFastListView(
  ...
  cacheExtent: 300,                 // optional
  scrollDirection: Axis.horizontal, // optional
  reverse: true,                    // optional
);
```

## set initial item index

```
final itemController = JkItemController();

// [optional] set which item should be visible from the beginning
// initialIndex: index of item that should be visible from the beginning
// alignment: null or 0~1 (double)
//   null: not specified the position of item
//   0: place the item at the beginning of listview
//   1: place the item at the end of listview
//   0.5: place the item at the center of listview
itemController.setInitialIndex(initialIndex: 1000, alignment: 0.5);

var listview = JkFastListView(
  ...
  itemController: itemController,
);
```

## scrollTo / animateTo item with specified index

```
// jump to item with index 1000
itemController.jumpToIndex(1000, alignment: 1);

// like 'jumpToIndex', but with animation
itemController.animateToIndex(1000,
  alignment: 1,
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeIn);
```

## Listen to index of current first visible item

```
var listview = JkFastListView(
  ...
  onScrollPosition: (index, ratio) {
    log("first visible item index is $index");
    // ratio: 0~1 (double),
    //   0: not visible,
    //   1: totally visible,
    //   0.5: only bottom-half of the item is visible
  },
);
```

## get current first visible item index

```
int topIndex = itemController.getFirstVisibleIndex();
```

## Precautions about recycler

There are something different from the official flutter's [ListView][1] and [GridView][2].

This package use recycler to recycle (not delete) items when items scroll out-of visible area, and restore (not create) back items when items scroll into visible area.

So, for some case (ex. your items have animation effect), you should override [didUpdateWidget][3] method in State of StatefulWidget of your item widget, and do something to cleanup some resources or state here (ex. stop animation).

The method [didUpdateWidget][3] will be called every time when a widget restore-back from recycler, with a new widget configuration pass into.

# Performance tuning

Not assign a key as possible.

- A widget without a key will use recycler to increase performance. Such a widget will be recycled when it is scroll out of screen, and will be reused later when a another new item (maybe with different index) scroll-in.
- A widget with a key won't be recycled. Such a widget is always created and destroyed when it is scrolling in and out of visible area.
- only assign a key to widget if items in the visible area will be reordered / removed, and your widget has state that you want to keep after items reordered / removed in visible area.
- I think it is better to remember item state outside of item widget.


[1]: https://api.flutter.dev/flutter/widgets/ListView-class.html "ListView"
[2]: https://api.flutter.dev/flutter/widgets/GridView-class.html "GridView"
[3]: https://api.flutter.dev/flutter/widgets/State/didUpdateWidget.html "didUpdateWidget"