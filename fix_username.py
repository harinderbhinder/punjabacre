c = open('lib/home/home_screen.dart', encoding='utf-8').read()

# Fix userName getter references
old = "auth.userName?.isNotEmpty == true ? auth.userName![0] : '?'"
new = "auth.user?['name']?.isNotEmpty == true ? (auth.user!['name'] as String)[0] : '?'"

if old in c:
    c = c.replace(old, new)
    print('Fixed userName reference')
else:
    print('Pattern not found, searching...')
    idx = c.find('auth.userName')
    print('Found at:', idx)
    print('Context:', c[idx-20:idx+60])

with open('lib/home/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(c)
print('Done, chars:', len(c))
