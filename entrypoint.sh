#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Get inputs from environment variables
REPOSITORY_PATH=${INPUT_REPOSITORY_PATH:-.}
COMMIT_MESSAGE=${INPUT_COMMIT_MESSAGE}
BRANCH=${INPUT_BRANCH:-main}
USER_NAME=${INPUT_USER_NAME:-"GitHub Actions Bot"}
USER_EMAIL=${INPUT_USER_EMAIL:-"github-actions-bot@github.com"}
YQ_COMMAND=${INPUT_YQ_COMMAND}
RETRY_DELAY=${INPUT_RETRY_DELAY:-2}
MAX_RETRIES=${INPUT_MAX_RETRIES:-0}

print_info "Starting Git Rebase Push Action..."
print_info "Repository path: $REPOSITORY_PATH"
print_info "Branch: $BRANCH"
print_info "Commit message: $COMMIT_MESSAGE"
print_info "Max retries: $([ $MAX_RETRIES -eq 0 ] && echo "infinite" || echo $MAX_RETRIES)"
print_info "Retry delay: ${RETRY_DELAY}s"

# Validate inputs
if [ -z "$COMMIT_MESSAGE" ]; then
    print_error "commit_message is required"
    exit 1
fi

# Change to repository directory
if [ ! -d "$REPOSITORY_PATH" ]; then
    print_error "Repository path '$REPOSITORY_PATH' does not exist"
    exit 1
fi

cd "$REPOSITORY_PATH"

# THE KEY FIX: Check if it's a git repository, initialize if needed
if [ ! -d ".git" ]; then
    print_warning "No .git directory found, initializing git repository"
    git init
    
    # Set safe directory for git operations
    git config --global --add safe.directory "$(pwd)"
    
    # Check if we're in a checkout situation (files exist but no .git)
    if [ "$(ls -A . 2>/dev/null)" ]; then
        print_info "Found existing files, creating initial commit"
        git add .
        git commit -m "Initial commit from existing files" || true
    fi
else
    # Set safe directory for existing repo
    git config --global --add safe.directory "$(pwd)"
fi

# Configure git
git config user.name "$USER_NAME"
git config user.email "$USER_EMAIL"

print_info "Git configured with user: $USER_NAME <$USER_EMAIL>"

# Check if there are changes to commit
if git diff --quiet && git diff --cached --quiet; then
    print_warning "No changes to commit"
    echo "result=no-changes" >> $GITHUB_OUTPUT
    echo "attempts=0" >> $GITHUB_OUTPUT
    exit 0
fi

# Show what will be committed
print_info "Changes to be committed:"
git status --porcelain

# Commit the changes
print_info "Creating commit..."
git add .
git commit -m "$COMMIT_MESSAGE"

print_success "Commit created successfully"

# Initialize counters
attempt=1

print_info "Starting push with rebase retry loop..."

# Check if max_retries is 0 (skip push)
if [ $MAX_RETRIES -eq 0 ]; then
    print_info "Max retries set to 0 - skipping push operations"
    print_success "🎉 Git operations completed successfully (commit only mode)"
    print_info "Final commit SHA: $(git rev-parse HEAD)"
    echo "result=success" >> $GITHUB_OUTPUT
    echo "attempts=0" >> $GITHUB_OUTPUT
    exit 0
fi

# Push with rebase retry loop
while true; do
    print_info "Attempting to push... (attempt $attempt)"
    
    if git push origin "$BRANCH"; then
        print_success "Push successful after $attempt attempts!"
        echo "result=success" >> $GITHUB_OUTPUT
        echo "attempts=$attempt" >> $GITHUB_OUTPUT
        break
    else
        print_warning "Push failed, will rebase and retry..."
        
        # Check if we've exceeded max retries (if set)
        if [ $MAX_RETRIES -gt 0 ] && [ $attempt -ge $MAX_RETRIES ]; then
            print_error "Maximum retries ($MAX_RETRIES) exceeded"
            echo "result=max-retries-exceeded" >> $GITHUB_OUTPUT
            echo "attempts=$attempt" >> $GITHUB_OUTPUT
            exit 1
        fi
        
        # Fetch latest changes
        print_info "Fetching latest changes from origin/$BRANCH"
        if ! git fetch origin "$BRANCH"; then
            print_error "Failed to fetch from origin/$BRANCH"
            echo "result=fetch-failed" >> $GITHUB_OUTPUT
            echo "attempts=$attempt" >> $GITHUB_OUTPUT
            exit 1
        fi
        
        # Rebase our commit on top of latest branch
        print_info "Rebasing on origin/$BRANCH"
        if git rebase "origin/$BRANCH"; then
            print_success "Rebase successful, retrying push..."
        else
            print_warning "Rebase conflict occurred, resolving..."
            
            # Re-apply specific changes if YQ command provided
            if [ -n "$YQ_COMMAND" ]; then
                print_info "Re-applying changes with: $YQ_COMMAND"
                if eval "$YQ_COMMAND"; then
                    print_success "YQ command executed successfully"
                else
                    print_error "YQ command failed"
                    git rebase --abort
                    echo "result=yq-command-failed" >> $GITHUB_OUTPUT
                    echo "attempts=$attempt" >> $GITHUB_OUTPUT
                    exit 1
                fi
            fi
            
            # Stage files and continue rebase
            git add .
            
            # Check if rebase can continue
            if git rebase --continue; then
                print_success "Rebase conflicts resolved"
            else
                print_error "Failed to resolve rebase conflicts"
                git rebase --abort
                echo "result=rebase-failed" >> $GITHUB_OUTPUT
                echo "attempts=$attempt" >> $GITHUB_OUTPUT
                exit 1
            fi
        fi
        
        # Increment attempt counter and add delay
        attempt=$((attempt + 1))
        print_info "Waiting ${RETRY_DELAY} seconds before next attempt..."
        sleep "$RETRY_DELAY"
    fi
done

print_success "🎉 Git rebase push completed successfully!"
print_info "Final commit SHA: $(git rev-parse HEAD)"
print_info "Total attempts: $attempt"