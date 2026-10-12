// lib/core/widgets/dot_matrix_text.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders numbers (and a few symbols) as a 5x7 dot-matrix display.
/// Drawn with a CustomPainter, so no font asset is needed.
///
/// Supported characters: 0-9 % / . - : space, and the letters U n l o s t
/// (for the Unlost wordmark). Anything else is blank.
class DotMatrixText extends StatelessWidget {
  final String text;
  final double dotSize;
  final double gap;
  final Color? color;

  const DotMatrixText(
    this.text, {
    super.key,
    this.dotSize = 4,
    this.gap = 1.6,
    this.color,
  });

  static const Map<String, List<String>> _glyphs = {
    '0': [' ### ', '#   #', '#  ##', '# # #', '##  #', '#   #', ' ### '],
    '1': ['  #  ', ' ##  ', '  #  ', '  #  ', '  #  ', '  #  ', ' ### '],
    '2': [' ### ', '#   #', '    #', '   # ', '  #  ', ' #   ', '#####'],
    '3': [' ### ', '#   #', '    #', '  ## ', '    #', '#   #', ' ### '],
    '4': ['   # ', '  ## ', ' # # ', '#  # ', '#####', '   # ', '   # '],
    '5': ['#####', '#    ', '#### ', '    #', '    #', '#   #', ' ### '],
    '6': [' ### ', '#    ', '#    ', '#### ', '#   #', '#   #', ' ### '],
    '7': ['#####', '    #', '   # ', '  #  ', ' #   ', ' #   ', ' #   '],
    '8': [' ### ', '#   #', '#   #', ' ### ', '#   #', '#   #', ' ### '],
    '9': [' ### ', '#   #', '#   #', ' ####', '    #', '    #', ' ### '],
    '%': ['##  #', '##  #', '   # ', '  #  ', ' #   ', '#  ##', '#  ##'],
    '/': ['    #', '    #', '   # ', '  #  ', ' #   ', '#    ', '#    '],
    '.': ['     ', '     ', '     ', '     ', '     ', ' ##  ', ' ##  '],
    ':': ['     ', ' ##  ', ' ##  ', '     ', ' ##  ', ' ##  ', '     '],
    '-': ['     ', '     ', '     ', '#####', '     ', '     ', '     '],
    // Letters for the "Unlost" wordmark.
    'U': ['#   #', '#   #', '#   #', '#   #', '#   #', '#   #', ' ### '],
    'n': ['     ', '     ', '# ## ', '##  #', '#   #', '#   #', '#   #'],
    'l': [' ##  ', '  #  ', '  #  ', '  #  ', '  #  ', '  #  ', ' ### '],
    'o': ['     ', '     ', ' ### ', '#   #', '#   #', '#   #', ' ### '],
    's': ['     ', '     ', ' ####', '#    ', ' ### ', '    #', '#### '],
    't': [' #   ', ' #   ', '#### ', ' #   ', ' #   ', ' #  #', '  ## '],
    ' ': ['     ', '     ', '     ', '     ', '     ', '     ', '     '],
  };

  /// Width / height this text will occupy for the given dot metrics.
  static Size measure(String text, double dotSize, double gap) {
    final pitch = dotSize + gap;
    final cols = text.isEmpty ? 0 : text.length * 5 + (text.length - 1);
    return Size(cols * pitch - (cols > 0 ? gap : 0), 7 * pitch - gap);
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.text;
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: CustomPaint(
          size: measure(text, dotSize, gap),
          painter: _DotMatrixPainter(text, dotSize, gap, c),
        ),
      ),
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  final String text;
  final double dotSize;
  final double gap;
  final Color color;

  _DotMatrixPainter(this.text, this.dotSize, this.gap, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final pitch = dotSize + gap;
    final r = dotSize / 2;
    var col = 0;
    for (final ch in text.split('')) {
      final glyph = DotMatrixText._glyphs[ch] ?? DotMatrixText._glyphs[' ']!;
      for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 5; x++) {
          if (glyph[y][x] == '#') {
            canvas.drawCircle(
              Offset((col + x) * pitch + r, y * pitch + r),
              r,
              paint,
            );
          }
        }
      }
      col += 6; // 5 columns + 1 column spacing
    }
  }

  @override
  bool shouldRepaint(covariant _DotMatrixPainter old) =>
      old.text != text ||
      old.dotSize != dotSize ||
      old.gap != gap ||
      old.color != color;
}
