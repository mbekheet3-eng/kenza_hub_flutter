# 🤖 ChatGPT Code Review Bot

Automated code review powered by OpenAI's GPT-4 model for Kenza Hub Flutter project.

## ✨ Features

- ✅ Automatic code review on every Pull Request
- ✅ Intelligent suggestions for code improvements
- ✅ Auto-fixes for code style and formatting issues
- ✅ Security vulnerability detection
- ✅ Performance optimization suggestions
- ✅ Best practices recommendations
- ✅ Automatic commit of fixes (with permission)

## 🔧 How It Works

### 1. **Code Analysis Phase**
- Analyzes changes in PR
- Sends code to ChatGPT (GPT-4)
- Categorizes issues by severity

### 2. **Review Comments Phase**
- Posts detailed review on PR
- Provides actionable suggestions
- Links to best practices

### 3. **Auto-Fix Phase**
- Attempts to fix code style issues
- Formats code properly
- Removes unused imports
- Fixes naming conventions
- Commits fixes automatically

## 📋 Review Categories

### 🔴 Critical Issues
- Security vulnerabilities
- Crash-causing bugs
- Data loss risks
- Memory leaks

### 🟠 High Priority
- Performance problems
- Poor architecture patterns
- Missing error handling
- API misuse

### 🟡 Medium Priority
- Code style inconsistencies
- Maintainability issues
- Naming convention violations

### 🟢 Suggestions
- Improvements
- Optimizations
- Best practices
- Documentation

## 🚀 Setup

### Prerequisites
1. GitHub repository admin access
2. OpenAI API key with GPT-4 access
3. GitHub Actions enabled

### Configuration

1. **Add OpenAI API Key to Secrets**
   ```
   Settings → Secrets and variables → Actions
   Create new secret: OPENAI_API_KEY
   ```

2. **Workflow automatically triggers on:**
   - Pull Request opened
   - Pull Request synchronized (new commits)
   - Pull Request reopened
   - Dart files changed

3. **Workflow checks:**
   - `lib/**/*.dart` - Application code
   - `pubspec.yaml` - Dependencies
   - `pubspec.lock` - Lockfile

## 📝 Review Output

### PR Comment Example
```
## 🤖 ChatGPT Code Review

### 🔴 Critical Issues
- Potential null pointer exception in line 42
- Missing error handling for async operation

### 🟡 Medium Priority
- Inconsistent naming: use camelCase for 'product_id'
- Missing const keyword for Widget

### ✅ Good Practices Found
- Excellent use of Provider pattern
- Good error handling implementation
```

## 🔐 Security

- API key stored securely in GitHub Secrets
- Code review bot has no access to secrets beyond API key
- All communications encrypted
- No code stored on external servers
- Review comments posted through GitHub API only

## ⚙️ Customization

### Modify Review Criteria
Edit `code_review.py` prompt section to change:
- Issues to detect
- Review categories
- Severity levels

### Change Auto-Fix Behavior
Edit `auto_fix.py` to:
- Enable/disable auto-fixes
- Change formatting rules
- Add custom linting

### Adjust Workflow Triggers
Edit `.github/workflows/code-review.yml`:
- Change trigger events
- Modify file paths
- Adjust timeout

## 📊 Cost Estimation

- **Per PR Review**: ~0.01 USD (using GPT-4)
- **Per Auto-Fix**: ~0.02 USD
- **Monthly (50 PRs)**: ~1.50 USD

## 🐛 Troubleshooting

### "API Key Error"
- Check GitHub Secret is correctly named `OPENAI_API_KEY`
- Verify API key is valid
- Check OpenAI account has API access

### "Timeout"
- Review is taking too long
- Increase timeout in workflow file
- Check OpenAI API status

### "No Review Posted"
- Check PR has Dart file changes
- Verify workflow permissions
- Check GitHub Actions logs

## 📚 Files

- `.github/workflows/code-review.yml` - Main workflow
- `.github/scripts/code_review.py` - Review analysis script
- `.github/scripts/auto_fix.py` - Auto-fix script
- `.github/scripts/README.md` - This documentation

## 🤝 Contributing

To improve the bot:
1. Test changes in a fork
2. Adjust prompts carefully
3. Monitor cost and quality
4. Document changes

## 📞 Support

For issues:
1. Check GitHub Actions logs
2. Verify API key and permissions
3. Check OpenAI API status
4. Review workflow configuration

---

**Status:** ✅ Active and monitoring all PRs

**Last Updated:** October 21, 2026
