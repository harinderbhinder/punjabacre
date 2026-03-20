import glob

# The broken pattern: new body was inserted but old closing brace was kept,
# resulting in duplicate return + extra closing brace
# Pattern to find and fix:
# "    return buf.toString().split('').reversed.join();\n    }\n    return buf..."

DUPE = "    return buf.toString().split('').reversed.join();\n    }\n    return buf.toString().split('').reversed.join();\n  }"
FIXED = "    return buf.toString().split('').reversed.join();\n  }"

files = glob.glob('lib/**/*.dart', recursive=True)
for path in files:
    c = open(path, encoding='utf-8').read()
    if DUPE in c:
        c = c.replace(DUPE, FIXED)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(c)
        print(f'Fixed dupe in: {path}')
    elif "return buf.toString().split('').reversed.join();" in c:
        print(f'OK (no dupe): {path}')

print('Done')
