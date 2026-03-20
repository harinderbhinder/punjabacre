c = open('lib/home/home_screen.dart', encoding='utf-8').read()

old = """  String _formatPrice(double price) {
    if (price >= 10000000) return '${(price / 10000000).toStringAsFixed(1)}Cr';
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}

// ── Horizontal Ad Card"""

new = """  String _formatPrice(double price) {
    final n = price.toInt().toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = n.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(n[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }
}

// ── Horizontal Ad Card"""

if old in c:
    c = c.replace(old, new)
    print('Fixed state _formatPrice')
else:
    print('Pattern not found')

# Fix _HorizontalAdCard _formatPrice
old2 = """  String _formatPrice(double price) {
    if (price >= 10000000) return '${(price / 10000000).toStringAsFixed(1)}Cr';
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}

// ── Grid Ad Card"""

new2 = """  String _formatPrice(double price) {
    final n = price.toInt().toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = n.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(n[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }
}

// ── Grid Ad Card"""

if old2 in c:
    c = c.replace(old2, new2)
    print('Fixed HorizontalAdCard _formatPrice')
else:
    print('Pattern2 not found')

# Fix _AdGridCard _formatPrice (last one)
old3 = """  String _formatPrice(double price) {
    if (price >= 10000000) return '${(price / 10000000).toStringAsFixed(1)}Cr';
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}
"""

new3 = """  String _formatPrice(double price) {
    final n = price.toInt().toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = n.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(n[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }
}
"""

if old3 in c:
    c = c.replace(old3, new3)
    print('Fixed AdGridCard _formatPrice')
else:
    print('Pattern3 not found')

with open('lib/home/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(c)
print('Done, chars:', len(c))
