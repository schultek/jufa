part of templates;

class ReorderToggle extends StatefulWidget {
  @override
  _ReorderToggleState createState() => _ReorderToggleState();
}

class _ReorderToggleState extends State<ReorderToggle> with FlareController {
  FlutterActorArtboard? artboard;
  ActorAnimation? iconAnimation;

  @override
  Widget build(BuildContext context) {
    var state = WidgetTemplate.of(context, listen: false);

    return IconButton(
      icon: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            colors: <Color>[Colors.grey.shade600, Colors.grey.shade600],
          ).createShader(bounds);
        },
        child: AnimatedBuilder(
          animation: state.transition,
          builder: (context, child) {
            if (iconAnimation != null) {
              var time = state.transition.value * iconAnimation!.duration;
              iconAnimation!.apply(time, artboard, 1.0);
              isActive.value = true;
            }
            return child!;
          },
          child: FlareActor(
            "lib/assets/animations/reorder_icon.flr",
            controller: this,
          ),
        ),
      ),
      onPressed: () {
        state.toggleEdit();
      },
    );
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    this.artboard = artboard;
    iconAnimation = artboard.getAnimation("go");
    iconAnimation!.apply(0, artboard, 1.0);
  }

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) => false;

  @override
  void setViewTransform(Mat2D viewTransform) {}
}
