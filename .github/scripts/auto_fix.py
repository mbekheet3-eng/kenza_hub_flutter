#!/usr/bin/env python3
"""
ChatGPT Auto-Fix Bot
Automatically fixes code style and common issues
"""

import os
import subprocess
import json
from openai import OpenAI

client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

def get_changed_files():
    """Get list of changed Dart files"""
    try:
        result = subprocess.run(
            ['git', 'diff', '--name-only', 'origin/main...HEAD'],
            capture_output=True,
            text=True,
            check=True
        )
        files = [f for f in result.stdout.strip().split('\n') if f.endswith('.dart')]
        return files
    except subprocess.CalledProcessError:
        return []

def read_file(filepath):
    """Read file content"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return ""

def write_file(filepath, content):
    """Write file content"""
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    except Exception as e:
        print(f"Error writing {filepath}: {e}")
        return False

def fix_code_with_chatgpt(filepath, code_content):
    """Use ChatGPT to fix code issues"""
    prompt = f"""Fix code style and common issues in this Dart/Flutter file.

Apply these fixes:
1. Format code properly (4-space indentation)
2. Fix import ordering (dart -> package -> relative)
3. Remove unused imports
4. Fix naming conventions (camelCase for variables/functions)
5. Add missing const keywords
6. Remove trailing whitespace
7. Fix indentation consistency
8. Add proper spacing between methods/classes

Return ONLY the fixed code, no explanations or markdown.

File: {filepath}

Code:
```dart
{code_content}
```"""

    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "system",
                    "content": "You are a Dart/Flutter code formatter. Return only the fixed code."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.3,
            max_tokens=4000
        )
        fixed_code = response.choices[0].message.content
        
        # Remove markdown code blocks if present
        if fixed_code.startswith('```'):
            fixed_code = fixed_code.split('```')[1]
            if fixed_code.startswith('dart'):
                fixed_code = fixed_code[4:]
        
        return fixed_code.strip()
    except Exception as e:
        print(f"Error fixing {filepath}: {e}")
        return None

def main():
    print("🔧 Starting auto-fix process...")
    
    changed_files = get_changed_files()
    if not changed_files:
        print("ℹ️ No Dart files changed")
        print("::set-output name=changes_made::false")
        return
    
    print(f"📄 Found {len(changed_files)} changed Dart files")
    
    changes_made = False
    
    for filepath in changed_files:
        print(f"\n🔍 Processing: {filepath}")
        
        if not os.path.exists(filepath):
            print(f"⚠️ File not found: {filepath}")
            continue
        
        original_content = read_file(filepath)
        if not original_content:
            continue
        
        print(f"🔧 Fixing code...")
        fixed_content = fix_code_with_chatgpt(filepath, original_content)
        
        if fixed_content and fixed_content != original_content:
            if write_file(filepath, fixed_content):
                print(f"✅ Fixed: {filepath}")
                changes_made = True
            else:
                print(f"❌ Failed to write: {filepath}")
        elif fixed_content:
            print(f"ℹ️ No changes needed: {filepath}")
        else:
            print(f"❌ Failed to fix: {filepath}")
    
    if changes_made:
        print("\n✅ Auto-fixes completed!")
        print("::set-output name=changes_made::true")
    else:
        print("\n ℹ️ No auto-fixes needed")
        print("::set-output name=changes_made::false")

if __name__ == "__main__":
    main()
