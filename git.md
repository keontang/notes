# git操作
## 笔记本电脑上 Global setup
git config --global user.name "user name"  
git config --global user.email "user email"  
git config --global core.editor vim

可选：github上添加公钥

## common commands
![Alt text](pics/git.jpg)

### git clone
将[指定远程仓库]远程项目repo克隆到本地目录local_dir下，如果不使用“-o”选项，远程仓库将被自动命名为“origin”

---
    git clone [-o repo_name] <repo.git> ［local_dir］ 

### git remote
- 列出所有远程仓库

---
    git remote [-v]

- 查看远程仓库的详细信息

---
    git remote show <repo_name>

- 添加远程仓库

---
    git remote add <repo_name> <repo.git>

- 删除远程仓库

---
    git remote rm <repo_name>

- 重命名远程仓库

---
    git remote rename <old_repo_name> <new_repo_name>

### git fetch
- 获取远程仓库所有分支的更新

---
    git fetch <repo_name>

- 获取远程仓库指定分支到更新

---
    git fetch <repo_name> <branch_name>

所有取回来的更新，需要用“repo_name/branch_name”形式读取。

---
    git branch -r //查看远程分支
    git branch -a //查看所有分支

可以在所取回来分支的基础上，创建一个新的分支

---
    git checkout -b new_branch repo_name/branch_name

此外，可以利用“git merge”或者“git rebase”命令，在本地分支上合并远程分支

---
    git merge repo_name/branch_name
    git rebase repo_name/branch_name //或者

- 获取远程仓库指定 tag

---
    git fetch <repo_name> refs/tags/tag_name:refs/tags/tag_name
    git checkout tags/tag_name -b new_branch_name

### git pull
- 取回远程主机某个分支的更新，再与本地的指定分支合并

---
    git pull <repo_name> <branch>:<local_branch>

 如果远程分支将要与当前分支合并，则冒号之后的内容可以省略。“git pull”实际上等价于先“git fetch”再“git merge”

### git push
- 将本地分支的更新，推送到远程仓库

---
    git push <repo_name> <local_branch>:<branch>

- 将本地所有分支都推送到远程仓库

---
    git push --all repo_name  

## 参考  
1. [Git远程操作详解](http://www.ruanyifeng.com/blog/2014/06/git_remote.html)

## github 详解  
1. [GotGitHub](http://www.worldhello.net/gotgithub/index.html)  
2. [git笔记](https://pylemons-note.readthedocs.org/en/latest/git.html)  



