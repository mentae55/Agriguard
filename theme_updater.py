import os
import re

lib_dir = r"D:\My Lang\Flutter\agriguard_project\lib"

def update_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    # Check if the file contains context in its build method, otherwise skip or be careful.
    if 'BuildContext context' in content or 'build(BuildContext context)' in content:
        # We can safely assume context is available in most widget files.
        # But for global constants, it might fail. So let's skip core/constants/app_colors.dart
        if 'app_colors.dart' in filepath or 'app_theme.dart' in filepath or 'theme_provider.dart' in filepath:
            return

        # Replace primaryColor
        content = re.sub(r'(?<!\.)\bprimaryColor\b', 'Theme.of(context).primaryColor', content)
        
        # Replace background colors where applicable
        # We will manually do scaffoldBackgroundColor in specific places.
        content = re.sub(r'Colors\.white(?!\.)', 'Theme.of(context).colorScheme.surface', content)
        content = re.sub(r'Colors\.black87', '(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87)', content)
        content = re.sub(r'Colors\.black(?!\.)', '(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)', content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            update_file(os.path.join(root, file))

print("Done.")
