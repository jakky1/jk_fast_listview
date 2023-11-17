// ignore_for_file: unnecessary_overrides

import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jk_fast_listview/jk_fast_listview.dart';

import 'input_dialog.dart';

void main() {
  //debugRepaintRainbowEnabled = true;
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final List<MyItemWidget> widgetList;

  static const int initialItemCount = 100000;
  int lastIndex = initialItemCount;
  MyItemWidget createItem(int index) {
    Key? key;
    if (index % 3 == 0) key = ValueKey(index);
    return MyItemWidget(
      index,
      key: key,
      onSwapClicked: (index) {
        int pos = widgetList.indexWhere((element) => element.index == index);
        var child1 = widgetList.removeAt(pos + 3);
        var child2 = widgetList.removeAt(pos);
        widgetList.insert(pos, child1);
        widgetList.insert(pos + 3, child2);
        setState(() {});
      },
      onAddClicked: (index) {
        int pos = widgetList.indexWhere((element) => element.index == index);
        widgetList.insert(pos + 1, createItem(lastIndex++));
        setState(() {});
      },
      onRemoveClicked: (index) {
        int pos = widgetList.indexWhere((element) => element.index == index);
        widgetList.removeAt(pos);
        setState(() {});
      },
    );
  }

  @override
  void initState() {
    super.initState();
    widgetList = List.generate(lastIndex++, createItem);
  }

  int? findIndexByKey(Key key) {
    int pos = widgetList.indexWhere((element) => element.key == key);
    if (pos < 0) return null;
    log("findIndexByKey() : $pos");
    return pos;
  }

  final scrollController = ScrollController();
  //final itemController = JkItemController();
  final itemController = JkItemController(initialIndex: 1000, alignment: 0.5);
  final itemCountValue = ValueNotifier<int>(initialItemCount);

  Widget buildListView(BuildContext context) {
    Widget list = ValueListenableBuilder<int>(
        valueListenable: itemCountValue,
        builder: (context, value, child) {
          log("ListView rebuild now");

          return JkFastListView(
            //return JkFastSliverList(
            itemController: itemController,
            onScrollPosition: (index, ratio) {
              //log("onScroll: item $index, visible: $ratio, ${itemController.getFirstVisibleIndex()}");
            },

            //return ListView.separated(
            //findChildIndexCallback: findIndexByKey,
            //return ListView.builder(
            /*
          //return GridView.builder(

            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300),
            */
            /*
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              */

            //findChildIndexCallback: findIndexByKey,

            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            //crossAxisCount: 2,
            maxCrossAxisExtent: 300,
            //separatorBuilder: (context, index) => MySeparator(index),

            controller: scrollController,
            cacheExtent: 300,
            reverse: true,
            scrollDirection: Axis.horizontal,
            itemCount: value,
            //itemCount: 300000,
            itemBuilder: (context, index) {
              return widgetList[index];
              //if (true) return Text("test now $index");
              //log("widget created: $index");
            },
          );
        });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    Widget list = buildListView(context);
    list = Scrollbar(
      controller: scrollController,
      child: list,
    );

    Widget controls = Row(children: [
      TextButton(
          onPressed: () => setState(() {}), child: const Text("rebuild")),
      TextButton(
          onPressed: () async {
            int? num = await showIntInputDialog(context, "set itemCount");
            if (num != null) {
              itemCountValue.value = num;
            }
          },
          child: const Text("itemCount")),
      TextButton(
          onPressed: () async {
            int? num = await showIntInputDialog(context, "jumpToIndex");
            if (num != null) {
              //scrollController.animateTo(num.toDouble(), duration: const Duration(milliseconds: 2000), curve: Curves.easeIn);
              //itemController.jumpToIndex(num, alignment: 0.5);

              itemController.animateToIndex(num,
                  alignment: 1,
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeIn);
            }
          },
          child: const Text("jumpToIndex")),
    ]);

    Widget body = Column(children: [controls, Expanded(child: list)]);

    body = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        }),
        child: body);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: body,
    );
  }
}

typedef ParamCallback<T> = void Function(T param);

class MyItemWidget extends StatefulWidget {
  final int index;
  final ParamCallback<int>? onAddClicked;
  final ParamCallback<int>? onRemoveClicked;
  final ParamCallback<int>? onSwapClicked;

  const MyItemWidget(
    this.index, {
    super.key,
    this.onAddClicked,
    this.onRemoveClicked,
    this.onSwapClicked,
  });

  @override
  State<StatefulWidget> createState() => MyItemWidgetState();
}

class MyItemWidgetState extends State<MyItemWidget>
    with SingleTickerProviderStateMixin {
  int tickCount = 0;

  @override
  void initState() {
    super.initState();
    initAnimation();
  }

  @override
  void deactivate() {
    super.deactivate();
    //log("deactivate item widget ${widget.index}");
  }

  @override
  void activate() {
    super.activate();
    //log("activate item widget ${widget.index}");
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
    //log("dispose item widget ${widget.index}");
  }

  late Animation<double> animation;
  late AnimationController controller;
  double widgetSizeDiff = 0;
  void initAnimation() {
    controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
  }

  bool stopAnimation = false;
  @override
  @protected
  void didUpdateWidget(covariant MyItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    //log("didUpdateWidget");
    stopAnimation = true;
    controller.reset();
  }

  void startAnimation() async {
    animation = Tween<double>(begin: 200, end: 500).animate(controller);
    animation.addListener(() {
      widgetSizeDiff = animation.value;
      setState(() {});
    });
    //controller.forward();
    stopAnimation = false;
    await controller.forward();
    if (!stopAnimation) {
      await controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    //log("build widget ${widget.index}");
    //if (true) return Text("Item ${widget.index}");
    Widget child = Row(children: [
      tickCount == 0
          ? Text("Item ${widget.index}")
          : Text("Item ${widget.index} ($tickCount)"),
      //Text(" CC"),

      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              log("button clicked: ${widget.index}");
            },
            child: const Text("log"),
          ),
          TextButton(
            onPressed: () {
              tickCount++;
              setState(() {});
            },
            child: const Text("tick"),
          ),
          IconButton(
            onPressed: () {
              log("animation");
              startAnimation();
            },
            icon: const Icon(Icons.animation),
          ),
          TextButton(
            onPressed: () => widget.onSwapClicked!(widget.index),
            child: const Text("swap+3"),
          ),
          IconButton(
            onPressed: () => widget.onAddClicked!(widget.index),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () => widget.onRemoveClicked!(widget.index),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
    ]);

    child = Container(
      color: Colors.black12,
      width: widgetSizeDiff == 0 ? null : widgetSizeDiff,
      height: widgetSizeDiff == 0 ? null : widgetSizeDiff,
      child: child,
    );

    return child;
  }
}

// --------------------------------------------------------------------------

class MySeparator extends StatefulWidget {
  final int index;

  const MySeparator(this.index, {super.key});

  @override
  State<MySeparator> createState() => _MySeparatorState();
}

class _MySeparatorState extends State<MySeparator> {
  @override
  void deactivate() {
    super.deactivate();
    //log("deactivate separator widget ${widget.index}");
  }

  @override
  void activate() {
    super.activate();
    //log("activate separator widget ${widget.index}");
  }

  @override
  void dispose() {
    super.dispose();
    log("dispose separator widget ${widget.index}");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: Text("${widget.index}"),
    );
  }
}
