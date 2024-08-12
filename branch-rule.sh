#!/bin/bash

# GitHub API token (ensure this is stored securely, e.g., in an environment variable)
GITHUB_TOKEN="your_github_token_here"

# File containing repository URLs
REPO_FILE="repos.txt"

# Read the repository URLs from the file
repository_urls=()
while IFS= read -r line; do
  repository_urls+=("$line")
done < "$REPO_FILE"

# Branch name to create (you can prompt the user or pass as an argument)
read -p "Enter the new branch name here (rhoai-X.Y): " new_branch_name

# Function to apply branch protection rules
apply_branch_protection() {
  repo_name=$1
  branch_name=$2

  curl -X PUT -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$repo_name/branches/$branch_name/protection" \
  -d '{
    "required_status_checks": {
      "strict": true,
      "contexts": []
    },
    "enforce_admins": true,
    "required_pull_request_reviews": {
      "dismiss_stale_reviews": true,
      "require_code_owner_reviews": true,
      "required_approving_review_count": 2
    },
    "restrictions": {
      "users": ["devops-user", "devops-bot"],
      "teams": ["devops-team"]
    },
    "required_linear_history": true,
    "allow_force_pushes": false,
    "allow_deletions": false
  }'

  echo "Branch protection applied to '$branch_name' in $repo_name."
}

# Loop through each repository URL and create a branch
for repo_url in "${repository_urls[@]}"; do
  # Extract the repository name from the URL
  repo_name=$(basename "$repo_url" .git)

  # Clone the repository (if not already cloned)
  if [ ! -d "$repo_name" ]; then
    git clone "$repo_url"
  fi

  # Change to the repository directory
  cd "$repo_name"

  # Create a new branch
  git checkout -b "$new_branch_name"

  # Push the new branch to the remote repository
  git push origin "$new_branch_name"

  # Provide a message indicating that the branch has been created
  echo "Branch '$new_branch_name' has been created and pushed to $repo_url."

  # Apply branch protection rules
  apply_branch_protection "red-hat-data-services/$repo_name" "$new_branch_name"

  # Return to the script's directory and clean up
  cd ..
  rm -rf "$repo_name"
done
