c = open('lib/home/home_screen.dart', encoding='utf-8').read()

# Horizontal card (width: 180)
old1 = "decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),\n          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))])"
new1 = "decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),\n          border: Border.all(color: const Color(0xFFE8E8E8), width: 1),\n          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))])"

# Grid card
old2 = "decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),\n          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))])"
new2 = "decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),\n          border: Border.all(color: const Color(0xFFE8E8E8), width: 1),\n          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))])"

found1 = old1 in c
found2 = old2 in c
print('Horizontal card found:', found1)
print('Grid card found:', found2)

if found1:
    c = c.replace(old1, new1)
if found2:
    c = c.replace(old2, new2)

open('lib/home/home_screen.dart', 'w', encoding='utf-8').write(c)
print('Done')
