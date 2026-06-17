import os
import re

# Files that still have issues from the revert NOT catching them
# (weather_details_screen.dart and soil_analysis_screen.dart still have const + Theme.of issues)
target_files = [
    r"D:\My Lang\Flutter\agriguard_project\lib\features\home\view\soil_analysis_screen.dart",
    r"D:\My Lang\Flutter\agriguard_project\lib\features\home\view_model\weather_details_screen.dart",
]

def fix_const_theme(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Fix: const TextStyle(color: Theme.of(context)...) -> TextStyle(color: ...)
    # Pattern: const TextStyle( ... color: Theme.of(context)... )
    # Just remove const from TextStyle when it contains Theme.of(context)
    
    # Replace Theme.of(context).colorScheme.surface inside const blocks -> Colors.white
    content = content.replace(
        "color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87)",
        "color: Colors.black87"
    )
    content = content.replace(
        "color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)",
        "color: Colors.black87"
    )
    
    # Inline replacements in const TextStyle blocks
    # Pattern: const TextStyle(\n   ...\n   color: Theme.of(...)...\n)
    # We need to remove 'const' from TextStyle when it has Theme.of(context)
    
    # Simple approach: find all occurrences of "const TextStyle(" and check if there's a Theme.of within the block
    # Use line-by-line approach:
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Check if this is a "const TextStyle(" line
        if 'const TextStyle(' in line and 'Theme.of' not in line:
            # Look ahead to see if Theme.of appears within the next few lines (until closing )
            depth = line.count('(') - line.count(')')
            lookahead = [line]
            j = i + 1
            has_theme = False
            while j < len(lines) and depth > 0:
                lookahead.append(lines[j])
                depth += lines[j].count('(') - lines[j].count(')')
                if 'Theme.of' in lines[j]:
                    has_theme = True
                j += 1
            if has_theme:
                # Remove 'const ' from the TextStyle line
                result.append(line.replace('const TextStyle(', 'TextStyle('))
            else:
                result.append(line)
        else:
            result.append(line)
        i += 1
    
    content = '\n'.join(result)
    
    # Also replace specific problematic patterns
    content = content.replace(
        "Theme.of(context).colorScheme.surface",
        "Colors.white"
    )
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed: {filepath}")
    else:
        print(f"No changes: {filepath}")

for f in target_files:
    fix_const_theme(f)

print("Done.")
