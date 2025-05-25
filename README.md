# Git Rebase Push Action 🚀

[![GitHub release](https://img.shields.io/github/release/Artur-Davtyan/git-rebase-push-action.svg)](https://github.com/Artur-Davtyan/git-rebase-push-action/releases)
[![Test Action](https://github.com/Artur-Davtyan/git-rebase-push-action/actions/workflows/test.yml/badge.svg)](https://github.com/Artur-Davtyan/git-rebase-push-action/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful GitHub Action that handles concurrent git commits with automatic rebase retry loop. **Perfect for GitOps workflows** where multiple processes update the same repository simultaneously.

## 🌟 Features

- ✅ **Automatic rebase** on push conflicts
- ✅ **Infinite retry loop** (or configurable max retries)  
- ✅ **Smart conflict resolution** with custom YQ commands
- ✅ **Preserves concurrent commits** from other processes
- ✅ **GitOps optimized** for image tag updates
- ✅ **Handles missing git directories** automatically
- ✅ **Zero configuration** - works out of the box
- ✅ **Detailed logging** with colored output
- ✅ **Error handling** with meaningful exit codes

## 🚀 Quick Start - GitOps Example

```yaml
name: Deploy to GitOps
on: [push]

jobs:
  update-gitops:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout GitOps repository
        uses: actions/checkout@v4
        with:
          repository: your-org/gitops
          token: ${{ secrets.GITOPS_TOKEN }}
          path: gitops
      
      - name: Update image tag
        uses: mikefarah/yq@master
        with:
          cmd: yq eval '.image.tag = "${{ github.sha }}"' -i gitops/apps/myapp/values.yaml
      
      - name: Commit and push with automatic retry
        uses: Artur-Davtyan/git-rebase-push-action@v1
        with:
          repository_path: gitops
          commit_message: "Update myapp to ${{ github.sha }}"
          yq_command: 'yq eval ".image.tag = \"${{ github.sha }}\"" -i apps/myapp/values.yaml'
```

## 📋 Complete Input Reference

| Input | Description | Required | Default | Example |
|-------|-------------|----------|---------|---------|
| `repository_path` | Path to git repository | ✅ | `.` | `gitops` |
| `commit_message` | Commit message | ✅ | - | `"Update app to v1.2.3"` |
| `branch` | Target branch | ❌ | `main` | `develop` |
| `user_name` | Git user name | ❌ | `GitHub Actions Bot` | `Deploy Bot` |
| `user_email` | Git user email | ❌ | `github-actions-bot@github.com` | `deploy@company.com` |
| `yq_command` | Command to re-apply after conflicts | ❌ | - | `yq eval '.image.tag = "v1.2.3"' -i values.yaml` |
| `retry_delay` | Delay between retries (seconds) | ❌ | `2` | `5` |
| `max_retries` | Maximum retries (0 = infinite) | ❌ | `0` | `10` |

## 📤 Outputs

| Output | Description | Possible Values |
|--------|-------------|-----------------|
| `result` | Operation result | `success`, `no-changes`, `rebase-failed`, `max-retries-exceeded`, `fetch-failed`, `yq-command-failed` |
| `attempts` | Number of push attempts | `0`, `1`, `2`, ... |

## 🎯 Perfect for GitOps - Real World Example

### The Problem
Multiple applications trying to update the same GitOps repository simultaneously:

```
App A: commits image tag update → pushes ✅
App B: commits image tag update → push FAILS ❌ (branch moved forward)
App C: commits image tag update → push FAILS ❌ (branch moved forward)
```

### The Solution
This action automatically rebases and retries:

```yaml
# In your application's CI/CD pipeline:
- name: Update GitOps repository  
  uses: Artur-Davtyan/git-rebase-push-action@v1
  with:
    repository_path: gitops
    commit_message: "Update ${{ env.APP_NAME }} to ${{ env.IMAGE_TAG }}"
    yq_command: 'yq eval ".image.tag = \"${{ env.IMAGE_TAG }}\"" -i apps/${{ env.APP_NAME }}/values.yaml'
```

**Result**: All apps get their image tags updated without conflicts! 🎉

### Real GitOps Workflow
```yaml
# Replace stefanzweifel/git-auto-commit-action with this:
Update-tag:
  runs-on: ubuntu-latest
  needs: [build-push, security-scan]
  steps:
    - name: Checkout GitOps repository
      uses: actions/checkout@v4
      with:
        repository: your-org/gitops
        ssh-key: ${{ secrets.GITOPS_GITHUB_SSH }}
        path: gitops

    - name: Change image tag in GitOps repository  
      uses: mikefarah/yq@master
      with:
        cmd: yq eval '.image.tag = "${{ env.TARGET_IMAGE_TAG }}"' -i gitops/apps/${{ env.APP_NAME }}/env-values/${{ env.ENV }}/values.yaml

    - name: Commit and push with rebase retry
      uses: Artur-Davtyan/git-rebase-push-action@v1
      with:
        repository_path: gitops
        commit_message: "Update ${{ env.APP_NAME }} to ${{ env.TARGET_IMAGE_TAG }} in ${{ env.ENV }}"
        yq_command: 'yq eval ".image.tag = \"${{ env.TARGET_IMAGE_TAG }}\"" -i apps/${{ env.APP_NAME }}/env-values/${{ env.ENV }}/values.yaml'
        user_name: "GitHub Actions Bot"
        user_email: "github-actions-bot@github.com"
```

## 💡 Advanced Usage Examples

### Basic GitOps Update
```yaml
- uses: Artur-Davtyan/git-rebase-push-action@v1
  with:
    repository_path: gitops
    commit_message: "Deploy app v${{ github.run_number }}"
```

### With Custom YQ Command
```yaml
- uses: Artur-Davtyan/git-rebase-push-action@v1
  with:
    repository_path: gitops
    commit_message: "Update Helm values"
    yq_command: |
      yq eval '.image.tag = "${{ env.NEW_TAG }}"' -i values.yaml &&
      yq eval '.replicas = 3' -i values.yaml
```

### With Custom Branch and Retry Settings
```yaml
- uses: Artur-Davtyan/git-rebase-push-action@v1
  with:
    repository_path: gitops
    branch: development
    commit_message: "Deploy to dev environment"
    max_retries: 5
    retry_delay: 10
```

### Multiple File Updates
```yaml
- uses: Artur-Davtyan/git-rebase-push-action@v1
  with:
    repository_path: gitops
    commit_message: "Update multiple environments"
    yq_command: |
      yq eval '.image.tag = "${{ env.TAG }}"' -i apps/prod/values.yaml &&
      yq eval '.image.tag = "${{ env.TAG }}"' -i apps/staging/values.yaml
```

### With Output Handling
```yaml
- name: Push changes
  id: push
  uses: Artur-Davtyan/git-rebase-push-action@v1
  with:
    repository_path: gitops
    commit_message: "Update app"

- name: Handle result
  run: |
    echo "Result: ${{ steps.push.outputs.result }}"
    echo "Attempts: ${{ steps.push.outputs.attempts }}"
    
    if [ "${{ steps.push.outputs.result }}" = "success" ]; then
      echo "✅ Deployment successful!"
    elif [ "${{ steps.push.outputs.result }}" = "no-changes" ]; then
      echo "ℹ️ No changes to deploy"
    else
      echo "❌ Deployment failed"
      exit 1
    fi
```

## 🛠️ How It Works

1. **Commit Changes**: Creates a commit with your changes
2. **Try Push**: Attempts to push to the target branch
3. **On Conflict**: 
   - Fetches latest changes from remote
   - Rebases your commit on top of latest changes
   - If conflicts occur, runs your `yq_command` to re-apply changes
   - Retries the push
4. **Repeat**: Continues until successful or max retries reached

## 🔧 Troubleshooting

### Common Issues

**Push keeps failing**
- Check if your token has push permissions
- Verify the branch exists
- Ensure the repository path is correct

**YQ command fails**
- Test your YQ command locally first
- Make sure file paths are relative to repository root
- Check YQ syntax with `yq --version`

**Rebase conflicts**
- Ensure your `yq_command` targets the correct files
- Consider using more specific file paths
- Check if other processes are modifying the same files

### Debug Mode
Enable debug logging by setting:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with the provided test workflow
5. Submit a pull request

### Testing Locally

```bash
# Build the Docker image
docker build -t git-rebase-push-action .

# Test with sample inputs
docker run --rm \
  -e INPUT_REPOSITORY_PATH=/tmp/test-repo \
  -e INPUT_COMMIT_MESSAGE="Test commit" \
  -e INPUT_BRANCH=main \
  git-rebase-push-action
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- 🐛 [Report Bug](https://github.com/Artur-Davtyan/git-rebase-push-action/issues)
- 💡 [Request Feature](https://github.com/Artur-Davtyan/git-rebase-push-action/issues)
- 💬 [Discussions](https://github.com/Artur-Davtyan/git-rebase-push-action/discussions)
- ⭐ Star this repo if you find it helpful!

## 🏷️ Changelog

### v1.0.1
- 🔧 **Fix**: Handle missing git directories in GitOps workflows
- ✨ **New**: Automatic git repository initialization  
- 🎯 **Improvement**: Better handling of checkout scenarios
- 📝 **Docs**: Updated with real GitOps examples

### v1.0.0
- 🎉 **Initial release**
- ✅ Basic rebase retry functionality
- ✅ YQ command support  
- ✅ Configurable retry settings
- ✅ Comprehensive error handling

## 🆚 vs Other Actions

| Feature | This Action | stefanzweifel/git-auto-commit | Standard Git |
|---------|-------------|-------------------------------|--------------|
| **Concurrent commits** | ✅ **Handles automatically** | ❌ Fails | ❌ Fails |
| **Automatic rebase** | ✅ **Yes** | ❌ No | ❌ Manual |
| **Retry on conflicts** | ✅ **Infinite/Configurable** | ❌ None | ❌ Manual |
| **GitOps optimized** | ✅ **YQ integration** | ❌ Basic | ❌ No |
| **Conflict resolution** | ✅ **Smart** | ❌ Basic | ❌ Manual |

## 🤝 Migration from Other Actions

### From stefanzweifel/git-auto-commit-action
```yaml
# BEFORE:
- uses: stefanzweifel/git-auto-commit-action@v5
  with:
    commit_message: "Update files"
    repository: .

# AFTER:  
- uses: Artur-Davtyan/git-rebase-push-action@v1
  with:
    repository_path: .
    commit_message: "Update files"
```

### From Manual Git Commands
```yaml
# BEFORE:
- run: |
    git add .
    git commit -m "Update"
    git push  # ❌ Fails on conflicts

# AFTER:
- uses: Artur-Davtyan/git-rebase-push-action@v1
  with:
    commit_message: "Update"  # ✅ Handles conflicts automatically
```

---

Made with ❤️ for the GitOps community