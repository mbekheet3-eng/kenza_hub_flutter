#!/bin/bash

# ============================================
# Kenza Hub Flutter - Push to GitHub Script
# ============================================
# 
# هذا الـ script يرفع المشروع على GitHub
# قبل الاستخدام: تأكد أن لديك git و GitHub account
#
# الاستخدام:
# chmod +x PUSH_TO_GITHUB.sh
# ./PUSH_TO_GITHUB.sh
# ============================================

echo "🚀 Kenza Hub Flutter - GitHub Push Script"
echo "=========================================="
echo ""

# Step 1: Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed!"
    echo "Please install Git from https://git-scm.com"
    exit 1
fi

echo "✅ Git found"
echo ""

# Step 2: Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found!"
    echo "Please run this script from kenza_hub_flutter directory"
    exit 1
fi

echo "✅ In correct directory"
echo ""

# Step 3: Check if .git exists
if [ ! -d ".git" ]; then
    echo "⚠️  Git repository not found. Initializing..."
    git init
    git config user.name "Kenza Hub Developer"
    git config user.email "kenza@example.com"
    git add .
    git commit -m "Initial commit: Kenza Hub Flutter Phase 1"
    echo "✅ Git repository initialized"
else
    echo "✅ Git repository exists"
fi

echo ""
echo "=========================================="
echo "NEXT STEP: Connect to GitHub"
echo "=========================================="
echo ""
echo "Your GitHub repository URL:"
echo "https://github.com/mbekheet3-eng/kenza_hub_flutter"
echo ""
echo "Run these commands:"
echo ""
echo "  git branch -M main"
echo "  git remote add origin https://github.com/mbekheet3-eng/kenza_hub_flutter.git"
echo "  git push -u origin main"
echo ""
echo "Or copy-paste this (replacing with your actual details):"
echo ""

read -p "Press Enter to continue..." 

# Step 4: Set branch to main
echo ""
echo "Renaming branch to main..."
git branch -M main
echo "✅ Branch renamed to main"
echo ""

# Step 5: Add remote origin
echo "Adding remote origin..."
git remote add origin https://github.com/mbekheet3-eng/kenza_hub_flutter.git 2>/dev/null || echo "⚠️  Remote may already exist"
echo "✅ Remote origin configured"
echo ""

# Step 6: Push to GitHub
echo "=========================================="
echo "Pushing to GitHub..."
echo "=========================================="
echo ""
echo "You may be prompted for credentials:"
echo "- GitHub username"
echo "- Personal Access Token (not password)"
echo ""
echo "To create a token: https://github.com/settings/tokens"
echo ""

git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ SUCCESS!"
    echo "=========================================="
    echo ""
    echo "Your project is now on GitHub:"
    echo "https://github.com/mbekheet3-eng/kenza_hub_flutter"
    echo ""
    echo "Next steps:"
    echo "1. Visit the repository URL above"
    echo "2. Read README.md"
    echo "3. Read MIGRATION_REPORT.md (current status)"
    echo "4. Read PROJECT_ROADMAP.md (future plans)"
    echo "5. Schedule team review meeting"
    echo ""
    echo "Happy coding! 🚀"
else
    echo ""
    echo "=========================================="
    echo "❌ PUSH FAILED"
    echo "=========================================="
    echo ""
    echo "Possible reasons:"
    echo "1. Network issues"
    echo "2. Invalid credentials"
    echo "3. Repository URL incorrect"
    echo ""
    echo "Try again with:"
    echo "  git push -u origin main"
    echo ""
fi
