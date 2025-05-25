# Complete Setup Instructions

## 📁 Repository Structure

Create your public repository with this exact structure:

```
git-rebase-push-action/
├── action.yml              # Action definition
├── Dockerfile              # Container configuration  
├── entrypoint.sh           # Main script
├── README.md               # Documentation
├── LICENSE                 # MIT License
├── .gitignore             # Git ignore file
├── SETUP.md               # This file
└── .github/
    └── workflows/
        └── test.yml        # Test workflow
```

## 🚀 Quick Setup Commands

```bash
# 1. Create and clone your repository
git clone https://github.com/YOUR_USERNAME/git-rebase-push-action.git
cd git-rebase-push-action

# 2. Create directory structure
mkdir -p .github/workflows

# 3. Copy all files from the artifacts above into respective locations

# 4. Make entrypoint executable
chmod +x entrypoint.sh

# 5. Replace YOUR_USERNAME in README.md with your actual GitHub username

# 6. Replace [Your Name] in LICENSE with your actual name

# 7. Initial commit and push
git add .
git commit -m "Initial release of git rebase push action"
git push origin main

# 8. Create and push first release tag
git tag -a v1.0.0 -m "v1.0.0 - Initial release"
git push origin v1.0.0
```

## 📋 File Checklist

- [ ] `action.yml` - Action metadata and inputs/outputs
- [ ] `Dockerfile` - Container with git, yq, and bash