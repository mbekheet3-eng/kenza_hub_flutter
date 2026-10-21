#!/usr/bin/env python3
"""
ChatGPT Code Review Bot
Analyzes PR changes and provides intelligent code review suggestions
"""

import os
import json
import re
import subprocess
from openai import OpenAI

# Initialize clients
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
github_token = os.getenv('GITHUB_TOKEN')
repo = os.getenv('GITHUB_REPOSITORY')
pr_number = os.getenv('PR_NUMBER')

def get_pr_changes():
    """Get the diff of the PR"""
    try:
        result = subprocess.run(
            ['git', 'diff', f'origin/main...HEAD'],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error getting PR diff: {e}")
        return ""

def analyze_code_with_chatgpt(code_diff):
    """Send code to ChatGPT for review"""
    prompt = f"""You are an expert Flutter/Dart code reviewer for a production marketplace app (Kenza Hub).

Review this pull request code and provide:
1. **Critical Issues**: Security, crashes, data loss risks
2. **High Priority**: Performance, memory leaks, poor practices
3. **Medium Priority**: Code style, maintainability, consistency
4. **Low Priority**: Documentation, minor improvements

Code to review:
```diff
{code_diff[:4000]}  # Limit to 4000 chars for token usage
```

Format your response as:
## 🔴 Critical Issues
- [issue]

## 🟠 High Priority
- [issue]

## 🟡 Medium Priority
- [issue]

## 🟢 Suggestions
- [suggestion]

## ✅ Good Practices Found
- [praise]

Be specific and actionable. Reference line numbers if visible in diff."""

    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "system",
                    "content": "You are an expert Flutter/Dart code reviewer. Be thorough but constructive."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.5,
            max_tokens=2000
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"Error calling OpenAI API: {e}")
        return ""

def format_review(analysis):
    """Format the review for GitHub"""
    header = """## 🤖 ChatGPT Code Review

This automated code review is provided by OpenAI's GPT-4 model.

"""
    footer = """

---
*This review was generated automatically. Please verify suggestions before implementing.*"""
    
    return header + analysis + footer

def main():
    print("📝 Getting PR changes...")
    code_diff = get_pr_changes()
    
    if not code_diff:
        print("⚠️ No code changes found or error reading diff")
        with open('review_output.txt', 'w') as f:
            f.write("No code changes to review")
        return
    
    print("🔍 Analyzing code with ChatGPT...")
    analysis = analyze_code_with_chatgpt(code_diff)
    
    if not analysis:
        print("⚠️ Failed to get analysis from ChatGPT")
        analysis = "Failed to analyze code. Please check API key and rate limits."
    
    print("📄 Formatting review...")
    review = format_review(analysis)
    
    # Save to file for GitHub Action
    with open('review_output.txt', 'w') as f:
        f.write(review)
    
    print("✅ Code review completed!")
    print(review[:500] + "..." if len(review) > 500 else review)

if __name__ == "__main__":
    main()
