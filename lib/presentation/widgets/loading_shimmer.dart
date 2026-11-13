import 'package:flutter/material.dart';

/// Grey placeholder cards that gently fade in and out while loading.
/// Built with a simple AnimationController, no extra package needed.
class LoadingShimmer extends StatefulWidget {
  /// 1 = list layout (phones), more = grid layout (tablets).
  final int columns;

  const LoadingShimmer({super.key, this.columns = 1});

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGrid = widget.columns > 1;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_controller),
      child: isGrid
          ? GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: 8,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.columns,
                mainAxisExtent: 320,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, _) => const _GridPlaceholder(),
            )
          : ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: 6,
              itemBuilder: (_, _) => const _ListPlaceholder(),
            ),
    );
  }
}

class _Box extends StatelessWidget {
  final double? width;
  final double height;

  const _Box({this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _ListPlaceholder extends StatelessWidget {
  const _ListPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            _Box(width: 110, height: 110),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Box(height: 16),
                  SizedBox(height: 8),
                  _Box(width: 80, height: 12),
                  SizedBox(height: 12),
                  _Box(height: 10),
                  SizedBox(height: 6),
                  _Box(height: 10),
                  SizedBox(height: 14),
                  _Box(width: 60, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPlaceholder extends StatelessWidget {
  const _GridPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Box(height: 160),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(height: 16),
                SizedBox(height: 8),
                _Box(width: 80, height: 12),
                SizedBox(height: 12),
                _Box(height: 10),
                SizedBox(height: 14),
                _Box(width: 60, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
