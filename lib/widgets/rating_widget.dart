import 'package:flutter/material.dart';

class RatingWidget extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;
  final bool readOnly;

  const RatingWidget({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
    this.readOnly = false,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late double currentRating;

  @override
  void initState() {
    super.initState();
    currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: widget.readOnly
              ? null
              : () {
                  setState(() => currentRating = (index + 1).toDouble());
                  widget.onRatingChanged((index + 1).toDouble());
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              index < currentRating ? Icons.star : Icons.star_border,
              color: const Color(0xFF8B4A5C),
              size: 32,
            ),
          ),
        );
      }),
    );
  }
}
