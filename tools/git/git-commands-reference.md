#### Primary section
- **Git Help**: Get help with Git commands.
   - `git help [command]`: Display help for the specified command.
- **Private branches**:
   - `master`: the master branch.
   - `origin`: the original repository.
   - `HEAD`: indicates the current point.

####Creation
- **From current files**
   - `git init`: Initialize a new Git repository.
   - `git add`: Add files to the staging area.
   - `git commit`: Create a commit of the changes.
   - `git clone [repository]`: Clone a Git repository.

#### Publishing
- `git commit -a`: Commit all modified changes and milestones.
- `git push`: Push commits to the remote repository.
- `git tag [tagname]`: Tag a specific version of the project.

#### Update
- `git fetch`: Fetch updates from the remote repository.
- `git pull`: Merge updates from the remote repository.
- `git merge`: Merge another branch into the current branch.
- `git remote set-url origin`

### the offer
- `git status`: Display the status of the repository.
- `git diff [file]`: Display changes in files.
- `git log`: View commit log.
- `git blame [file]`: Display the history of modifications to a specific file.

### backing down
- `git reset --hard`: Undo the last commits.
- `git revert`: Undo a given commit by creating a reverse commit.
- `git checkout [file]`: Restore a file to a specific commit state.
- `git cherry-pick [commit-hash]`: Pick a specific commit to apply to the current branch.
- `git reset --soft HEAD~1`
- `git reset --hard HEAD~1`

### Branches
- `git checkout [branch]`: Switch between branches.
- `git branch`: View and create branches.
- `git merge [branch]`: Merge a branch into the current branch.

### Dealing with conflicts
- `git diff`: Show diff.
- `git log --merge`: Display the log for the merge.
- `gitk --merge`: GUI for displaying conflicts.

### Useful tools
- `git archive`: Create an archive of the project.
- `git fsck`: scan the repository and verify its integrity.
- `git gc`: Clean and optimize the repository.

### Track files
- `git add`: Add new files or modify existing files.
- `git rm`: Remove files from the repository.
- `git mv`: Rename or move files.

### Structural
- **Local warehouse**:
   - `working dir`: working directory.
   - `current branch`: The current branch.
   - `.git`: Git directory.

- **Remote warehouse**:
   - `remote repository`: The remote repository (eg `origin`).