import os

lib_dir = r"D:\My Lang\Flutter\agriguard_project\lib"

def revert_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    # Do NOT revert app_colors.dart, app_theme.dart, theme_provider.dart, profile_screen.dart, edit_profile_screen.dart
    if 'app_colors.dart' in filepath or 'app_theme.dart' in filepath or 'theme_provider.dart' in filepath or 'profile_screen.dart' in filepath or 'edit_profile_screen.dart' in filepath or 'home_screen.dart' in filepath:
        return

    content = content.replace('Theme.of(context).primaryColor', 'primaryColor')
    content = content.replace('(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87)', 'Colors.black87')
    content = content.replace('(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)', 'Colors.black')
    content = content.replace('Theme.of(context).colorScheme.surface', 'Colors.white')

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Reverted {filepath}")

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            revert_file(os.path.join(root, file))

print("Done reverting.")
