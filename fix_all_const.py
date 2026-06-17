import os
import re

lib_dir = r"D:\My Lang\Flutter\agriguard_project\lib"

SKIP_FILES = {'app_colors.dart', 'app_theme.dart', 'theme_provider.dart'}


def fix_file(filepath):
    filename = os.path.basename(filepath)
    if filename in SKIP_FILES:
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # 1. Fix "const Icon(... color: Theme.of..." -> "Icon(... color: Theme.of..."
    # 2. Fix "const TextStyle(... color: Theme.of..." -> "TextStyle(... color: Theme.of..."
    # 3. Fix "const Text(... style: const TextStyle..." when inner TextStyle has Theme.of
    # 4. Fix surface70 / surface54 -> Colors.white70 / Colors.white54

    content = content.replace('Colors.white70,', 'Colors.white.withAlpha(178),')
    content = content.replace('Colors.white54,', 'Colors.white.withAlpha(137),')
    content = re.sub(r'\.colorScheme\.surface\d+', '', content)  # remove invalid surface suffix

    # Also fix Theme.of in colorScheme.surface used inline (now surface has no number, fix the rest)
    # surface -> Colors.white
    content = content.replace('Theme.of(context).colorScheme.surface', 'Colors.white')

    # Fix the broken "(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)87" -> Colors.black87
    content = re.sub(
        r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color \?\? Colors\.black\)87',
        'Colors.black87',
        content
    )
    content = re.sub(
        r'\(Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color \?\? Colors\.black87\)',
        'Colors.black87',
        content
    )

    # Now the main fix: remove "const" keyword before widgets that contain Theme.of(context)
    # Strategy: tokenize by finding "const WidgetName(" or "const Icon(" etc.,
    # then scan to the matching ")" and if Theme.of found, remove the "const"

    # We use a regex to find all "const " prefixes before known widget constructors
    # and remove them when the argument block contains Theme.of(context)

    widget_names = r'(?:Icon|Text|TextStyle|BoxDecoration|InputDecoration|BorderSide|OutlineInputBorder|TextSpan|Container|Row|Column|SizedBox|Padding|Align|Center|Positioned|AnimatedSwitcher|EdgeInsets(?:\.all|\.symmetric|\.only|\.fromLTRB)?)'
    
    def remove_invalid_const(m):
        start = m.start()
        const_start = m.start()
        # Find the opening paren
        paren_start = content.find('(', m.end())
        if paren_start == -1:
            return m.group(0)
        # Count parens to find the closing one
        depth = 0
        i = paren_start
        while i < len(content):
            if content[i] == '(':
                depth += 1
            elif content[i] == ')':
                depth -= 1
                if depth == 0:
                    block = content[paren_start:i+1]
                    if 'Theme.of' in block:
                        return m.group(0).replace('const ', '')
                    return m.group(0)
            i += 1
        return m.group(0)

    # Apply removal for const before known widget constructors
    pattern = re.compile(r'const (?=' + widget_names + r'\()')
    new_content = pattern.sub('', content)

    # That broad approach may remove too many consts.
    # Instead let's do it line-by-line checking same-line Theme.of
    # For now use the simple line approach: if a line has both "const" and "Theme.of(context)"
    lines = new_content.split('\n')
    result = []
    for line in lines:
        if 'const ' in line and 'Theme.of(context)' in line:
            line = line.replace('const ', '', 1)
        result.append(line)
    new_content = '\n'.join(result)

    # Fix surface70/surface54 -> Colors.white.withAlpha(...)
    new_content = re.sub(r'Theme\.of\(context\)\.colorScheme\.surface\d*', 'Colors.white', new_content)

    if new_content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed: {filepath}")


for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

print("Done.")
