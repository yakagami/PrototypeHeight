import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum PrototypeHeightSlot {
  prototypeItem,
  child,
}

class PrototypeHeight extends RenderObjectWidget
    with SlottedMultiChildRenderObjectWidgetMixin<PrototypeHeightSlot> {
  const PrototypeHeight({
    super.key,
    this.prototype,
    this.child,
    this.backgroundColor,
  });

  final Widget? prototype;
  final Widget? child;
  final Color? backgroundColor;

  @override
  Iterable<PrototypeHeightSlot> get slots => PrototypeHeightSlot.values;

  @override
  Widget? childForSlot(PrototypeHeightSlot slot) {
    switch (slot) {
      case PrototypeHeightSlot.prototypeItem:
        return prototype;
      case PrototypeHeightSlot.child:
        return child;
    }
  }

  @override
  SlottedContainerRenderObjectMixin<PrototypeHeightSlot> createRenderObject(
      BuildContext context,
      ) {
    return RenderPrototypeHeight(
      backgroundColor: backgroundColor,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context,
      SlottedContainerRenderObjectMixin<PrototypeHeightSlot> renderObject,
      ) {
    (renderObject as RenderPrototypeHeight).backgroundColor = backgroundColor;
  }
}

class RenderPrototypeHeight extends RenderBox
    with
        SlottedContainerRenderObjectMixin<PrototypeHeightSlot>,
        DebugOverflowIndicatorMixin {
  RenderPrototypeHeight({Color? backgroundColor}) : _backgroundColor = backgroundColor;

  Color? get backgroundColor => _backgroundColor;
  Color? _backgroundColor;
  set backgroundColor(Color? value) {
    assert(value != null);
    if (_backgroundColor == value) {
      return;
    }
    _backgroundColor = value;
    markNeedsPaint();
  }

  // Getters to simplify accessing the slotted children.
  RenderBox? get _prototype => childForSlot(PrototypeHeightSlot.prototypeItem);
  RenderBox? get _child => childForSlot(PrototypeHeightSlot.child);

  // The size this render object would have if the incoming constraints were
  // unconstrained; calculated during performLayout used during paint for an
  // assertion that checks for unintended overflow.
  late Size _childrenSize;
  // LAYOUT

  @override
  void performLayout() {
    // Children are allowed to be as big as they want (= unconstrained).
    const BoxConstraints childConstraints = BoxConstraints();

    Size prototypeSize = Size.zero;
    final RenderBox? prototype = _prototype;
    if (prototype != null) {
      prototype.layout(childConstraints, parentUsesSize: true);
      _positionChild(prototype, Offset.zero);
      prototypeSize = prototype.size;
    }


    Size childSize = Size.zero;
    BoxConstraints siblingConstraints = BoxConstraints(
      maxHeight: prototypeSize.height,
      //maxWidth: prototypeSize.width,
    );
    final RenderBox? child = _child;
    if (child != null) {
      child.layout(siblingConstraints, parentUsesSize: true);
      childSize = child.size;
    }
    
    _childrenSize = Size(
      childSize.width,
      prototypeSize.height,
    );
    size = constraints.constrain(_childrenSize);
  }

  void _positionChild(RenderBox child, Offset offset) {
    (child.parentData! as BoxParentData).offset = offset;
  }

  // PAINT

  @override
  void paint(PaintingContext context, Offset offset) {
    // Paint the background.
    if (backgroundColor != null) {
      context.canvas.drawRect(
        offset & size,
        Paint()..color = backgroundColor!,
      );
    }

    void paintChild(RenderBox child, PaintingContext context, Offset offset) {
      final BoxParentData childParentData = child.parentData! as BoxParentData;
      context.paintChild(child, childParentData.offset + offset);
    }

    final RenderBox? child = _child;
    if (child != null) {
      paintChild(child, context, offset);
    }

    // Paint an overflow indicator in debug mode if the children want to be
    // larger than the incoming constraints allow.
    assert(() {
      paintOverflowIndicator(
        context,
        offset,
        Offset.zero & size,
        Offset.zero & _childrenSize,
      );
      return true;
    }());
  }

  // HIT TEST

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = _child;
    if(child != null){
      final BoxParentData parentData = child.parentData! as BoxParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - parentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  // INTRINSICS

  // Incoming height/width are ignored as children are always laid out unconstrained.

  @override
  double computeMinIntrinsicWidth(double height) {
    final double prototypeWidth =
        _prototype?.getMinIntrinsicWidth(double.infinity) ?? 0;
    final double childWidth =
        _child?.getMinIntrinsicWidth(double.infinity) ?? 0;
    return prototypeWidth + childWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double prototypeWidth =
        _prototype?.getMaxIntrinsicWidth(double.infinity) ?? 0;
    final double childWidth =
        _child?.getMaxIntrinsicWidth(double.infinity) ?? 0;
    return prototypeWidth + childWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double prototypeHeight =
        _prototype?.getMinIntrinsicHeight(double.infinity) ?? 0;
    final double childHeight =
        _child?.getMinIntrinsicHeight(double.infinity) ?? 0;
    return prototypeHeight + childHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double prototypeHeight =
        _prototype?.getMaxIntrinsicHeight(double.infinity) ?? 0;
    final double childHeight =
        _child?.getMaxIntrinsicHeight(double.infinity) ?? 0;
    return prototypeHeight + childHeight;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    const BoxConstraints childConstraints = BoxConstraints();
    final Size prototypeSize =
        _prototype?.computeDryLayout(childConstraints) ?? Size.zero;
    final Size childSize =
        _child?.computeDryLayout(childConstraints) ?? Size.zero;
    return constraints.constrain(Size(
      prototypeSize.width + childSize.width,
      prototypeSize.height + childSize.height,
    ));
  }
}
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slotted RenderObject Example')),
      body: Column(
        children: [
          PrototypeHeight(
            prototype: Row(
              children: [
                TextButton(onPressed: (){print("clicked");}, child: const Text("Click!")),
              ],
            ),
            backgroundColor: Colors.white,
            child: Container(
              width: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                   color: Colors.grey,
                   child: TextButton(onPressed: (){print("clicked");}, child: const Text("Click!")),
                  );
                }),
            ),
          ),
        ],
      ),
    );
  }
}
