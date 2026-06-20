import 'package:flutter/material.dart';

class AutoSizeText extends StatelessWidget {
  const AutoSizeText(
    this.data, {
    super.key,
    this.maxLines,
    this.minFontSize = 12,
    this.overflow = TextOverflow.clip,
    this.style,
    this.textAlign,
  });

  final String data;
  final int? maxLines;
  final double minFontSize;
  final TextOverflow overflow;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final baseFontSize = effectiveStyle.fontSize ?? 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        var fontSize = baseFontSize;

        while (fontSize > minFontSize) {
          final painter = TextPainter(
            maxLines: maxLines,
            text: TextSpan(
              text: data,
              style: effectiveStyle.copyWith(fontSize: fontSize),
            ),
            textDirection: direction,
            textScaler: textScaler,
          )..layout(maxWidth: constraints.maxWidth);

          if (!painter.didExceedMaxLines &&
              painter.height <= constraints.maxHeight) {
            break;
          }
          fontSize -= 1;
        }

        return Text(
          data,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
          style: effectiveStyle.copyWith(
            fontSize: fontSize.clamp(minFontSize, baseFontSize).toDouble(),
          ),
        );
      },
    );
  }
}
