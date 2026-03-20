import glob

NEW_BODY = """    final n = price.toInt().toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = n.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(n[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();"""

files = glob.glob('lib/**/*.dart', recursive=True)
for path in files:
    c = open(path, encoding='utf-8').read()
    if '10000000' not in c:
        continue

    lines = c.split('\n')
    out = []
    i = 0
    changed = False
    while i < len(lines):
        line = lines[i]
        if 'if (price >= 10000000)' in line:
            i += 1  # skip Cr line
            if i < len(lines) and 'if (price >= 100000)' in lines[i]:
                i += 1  # skip Lakh line
            # skip old body lines until closing brace (keep the brace)
            while i < len(lines) and lines[i].strip() not in ('}', '  }'):
                i += 1
            # Insert new body lines
            for nb in NEW_BODY.split('\n'):
                out.append(nb)
            # Now append the closing brace line (don't skip it)
            if i < len(lines):
                out.append(lines[i])
                i += 1
            changed = True
        else:
            out.append(line)
            i += 1

    if changed:
        with open(path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(out))
        print(f'Fixed: {path}')

print('All done')
