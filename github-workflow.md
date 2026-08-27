Short answer: **`git push` uploads your commits — but because you protected `main` (and `develop`), you never push to them directly. You push a feature branch, then merge it via Pull Request.** That's exactly your own 1.3 §2 rule ("no direct pushes; every change = pull request"), and every PR becomes interview evidence (IA-2, SK-8).

## 🔁 The daily loop (do this every time you change code)

```powershell
cd C:\project-zuri-pulse

# 0. Start from a fresh, current base
git checkout develop
git pull origin develop

# 1. Create a branch for THIS change (naming per 1.3 §2)
git checkout -b feature/phase2-terraform-modules

# 2. Make your edits, then inspect them
git status
git diff

# 3. Stage + commit (say WHAT and WHY, e.g. feat/fix/docs/chore)
git add -A
git commit -m "feat(terraform): add aws-vpc module and dev networking stack"

# 4. Push the branch to GitHub (this is what "updates GitHub")
git push -u origin feature/phase2-terraform-modules
```

(`-u` is only needed the first time you push that branch; afterwards plain `git push` works.)

## 🔀 Then finish on GitHub

1. GitHub shows a **"Compare & pull request"** banner for your new branch → open a PR **into `develop`**.
2. Write a 3-line description: *what changed / why / evidence* (for infra PRs, paste the `terraform plan` output — your 1.3 §3 checklist requires it).
3. The `terraform-validation.yml` workflow runs as a status check. Wait for green.
4. Merge (squash is fine). Enable "automatically delete head branches" so GitHub cleans up.
5. Sync locally and delete the old branch:

```powershell
git checkout develop
git pull origin develop
git branch -d feature/phase2-terraform-modules
```

## 🚀 Promoting to `main`

When a phase is complete and proven in `develop`, open a second PR **`develop` → `main`** (Create a merge commit) . `main`'s protection (PR required + checks green) gates it. That two-step promotion *is* your Change & Release Process (1.3 §4) in action — say so in the interview.

## ⚠️ If you accidentally committed on `main` locally

The push will be rejected (protected). Don't fight it — move the commit:

```powershell
git branch feature/my-change      # keep the commit on a new branch
git reset --hard origin/main      # reset local main to GitHub's main
git checkout feature/my-change
git push -u origin feature/my-change   # then open the PR as normal
```

## ✅ Pre-flight reminders before your first `git add`

- `git check-ignore -v .env` must return a match (secrets never go up).
- Terraform artifacts are covered by the `.gitignore` additions (`.terraform/`, `*.tfstate`, `backend/*.hcl`, `*.auto.tfvars.json`, `plan.tfplan`).
- `git status` should show only real source/docs changes.

**Cheat sheet:** change → `git add -A` → `git commit -m "..."` → `git push` (feature branch) → PR → green checks → merge → `git pull` on `develop`. That's the whole loop — and by Phase 10 you'll have dozens of merged PRs proving you work the way the Pavago JD expects.














## Workflow Example








# #########################################################################################################################

# Make local an EXACT mirror of remote develop/main

git fetch origin

# 2. Make local develop an EXACT mirror of remote develop
git checkout develop
git reset --hard origin/develop

# 3. Same for main
git checkout main
git reset --hard origin/main




# ###########################################################################################################################


# Start every change from a fresh, synced develop
git checkout develop
git pull origin develop          # pull on develop is ALLOWED (it's a read)
git checkout -b feature/next-change

# ...edit files...
git add .
git commit -m "feat: my next platform change"
git push -u origin feature/next-change   # ONLY feature branches get pushed



1
feature/next-change → develop
Squash Merge
2
develop → main
Merge Commit (no fast-forward)


git checkout develop
.......................

# ###########################################################################################################################






# ########################################################################################################################3

# When you re initialize git or create a new git -> (git init) and want to update develop and main branches that have history and data


# 1. Create empty local repo
git init

# 2. Tell Git WHERE the remote lives (just saves the URL)
PS C:\ds-platform> git remote add origin git@ssh.dev.azure.com:v3/ahootech/ds-platform/ds-platform

# 3. DOWNLOAD all remote branch info (critical step!)
git fetch origin
#    ↑ This creates origin/develop, origin/main locally
#    ↑ Now Git KNOWS what's on the server

# 4. Create your feature branch BASED ON the remote develop
git checkout -b feature/god-mode-scaffold origin/develop
#    ↑ Your branch now inherits all of develop's history
#    ↑ Your new files are ADDED on top, not replacing

# 5. Add your new scaffold files
git add .
git commit -m "feat: implement Ultimate God Mode Architecture scaffold"

# 1. Rename your CURRENT local branch to the feature branch name
git branch -m feature/god-mode-scaffold

# 2. Push it to Azure DevOps and link it to the remote
git push -u origin feature/god-mode-scaffold



1
feature/next-change → develop
Squash Merge
2
develop → main
Merge Commit (no fast-forward)


git checkout develop
.......................








####  ###################################################################################################################################################


# Solved merge conflicts example



cd C:\ds-platform
git fetch origin
git checkout feature/god-mode-scaffold

# Bring develop into your branch (histories are unrelated, hence the flag)
git merge origin/develop --allow-unrelated-histories -m "merge: align feature branch with develop"

# Keep YOUR new versions of the 3 conflicted files
git checkout --ours -- "D&S-Azure-DevOps-(Organization).md" "README.md" "todo.md"
git add "D&S-Azure-DevOps-(Organization).md" "README.md" "todo.md"
git commit -m "chore: resolve conflicts keeping God Mode versions"
git push origin feature/god-mode-scaffold



Access AWS =  aws sts get-caller-identity --profile zuri-platform