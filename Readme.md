# What is included

## Summary of what the environment will look like
- Tmux with custom configuration
- Vim with custom configuration
- Git autocompletion
- Oh-my-posh
- FZF
- `fss` commands (easy way to execute predefined commands in a fzf fashion)
- mongo-tools - essential tools for MongoDB (bsondump, mongoimport, ...)
- Mongo shell
- MongoDB binaries
- Wired Tiger binaries
- etc.
  

# Installation

## 1. Create local bin directory and add it to PATH
    mkdir -p ~/.local/bin
    export PATH=~/.local/bin:$PATH

## 2. Install the environment tools

### Oh-my-posh
A prompt theme engine for any shell.

Website: https://ohmyposh.dev

Installation:
    
    sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v16.4.0/posh-linux-arm64 -O ~/.local/bin/oh-my-posh
    sudo chmod +x $HOME/.local/bin/oh-my-posh
    oh-my-posh font install Meslo
    
### Tmux
Tmux is a terminal multiplexer. It lets you switch easily between several programs in one terminal, detach them (they keep running in the background) and reattach them to a different terminal.

Repository:  https://github.com/tmux/tmux

Installation: You'll need a version newer or equal than v3.3

    sudo apt-get install tmux
    
### jq
`jq` is a lightweight and flexible command-line JSON processor.

Repository: https://github.com/jqlang/jq

Installation:

    sudo apt-get install jq
    
### fzf
`fzf` is an interactive filter program for any kind of list

Repository: https://github.com/junegunn/fzf

Installation:

    git clone --depth 1 https://github.com/junegunn/fzf $HOME/.fzf
    $HOME/.fzf/install
    
### diff-so-fancy
`diff-so-fancy` strives to make your diffs human readable instead of machine readable.

Repository: https://github.com/so-fancy/diff-so-fancy

Installation:

##### Linux
    git clone https://github.com/so-fancy/diff-so-fancy $HOME/.diff-so-fancy
    ln -s $HOME/.diff-so-fancy/diff-so-fancy $HOME/.local/bin/diff-so-fancy
    
##### MacOS
    brew install diff-so-fancy

### mrlog
`mrlog` makes mongod logs more human-readable. It was built by a MondoDB developer (Mark Benvenuto).

Repository: https://github.com/markbenvenuto/mrlog

To install it, follow the instructions on the repository link.<br><br>


### MongoDB Database Tools
The MongoDB Database Tools are a suite of official command-line utilities for working with MongoDB, like mongorestore, mongodump, bsondump, etc.

Website: https://www.mongodb.com/docs/database-tools/installation/installation/

To install them, follow the instructions on the given website.

This is the internal repo for the mongo tools: https://github.com/mongodb/mongo-tools.<br><br>

### fss
`fss` is a tool to execute predefined and parametrized commands in a fzf fashion.

Repository: https://github.com/silviasuhu/fss

To install this tool, follow the instructions from the repository link.<br><br>


### forgit
Utility tool for using git interactively. Powered by fzf.

Repository: https://github.com/wfxr/forgit

Installation:

    git clone https://github.com/wfxr/forgit $HOME/.forgit
    
### fzf-tab
Replace zsh's default completion selection menu with fzf!

Repository: https://github.com/Aloxaf/fzf-tab

### fd
`fd` is a program to find entries in your filesystem. It is a simple, fast and user-friendly alternative to find.

Repository: https://github.com/sharkdp/fd

Installation:

##### Linux
    sudo apt-get install fd-find
    ln -s $(which fdfind) $HOME/.local/bin/fd
##### MacOS
    brew install fd

### task-spooler
It's a CLI tool to queue and execute jobs. It's especially useful to serialize different commands.

Repository: https://github.com/justanhduc/task-spooler

### bat
A cat(1) clone with syntax highlighting and Git integration.

Repository: https://github.com/sharkdp/bat

To install it follow the instructions from the given repository.

### mtools
`mtools` is a collection of helper scripts to parse, filter, and visualize MongoDB log files.

`mtools` also includes `mlaunch`, a utility to quickly set up complex MongoDB test environments on a local machine

Repository: https://github.com/rueckstiess/mtools

To install these tools, follow the instructions from https://rueckstiess.github.io/mtools/install.html.  

Make sure binaries are in your PATH env variable.<br><br>

### m

`m` helps you download, use, and manage multiple versions of the MongoDB server and command-line tools.

Repository: https://github.com/aheckmann/m

To install it, follow the instructions from https://github.com/aheckmann/m#installation.

Make sure the m binary is in your PATH env variable.<br><br>

### WiredTiger

Wired Tiger is the Storage Engine that runs under the hood of a `mongod` process.

Website: https://source.wiredtiger.com

To install it, follow the instructions from the given website

The internal repo is https://github.com/wiredtiger/wiredtiger.git.<br><br>

### Wired Tiger Scripts

You'll find interesting WT scripts on https://github.com/wiredtiger/wiredtiger/blob/develop/tools.<br><br>

### t2

The `t2` tool visualizes timeseries data, primarily geared towards efficiently visualizing the large amount of full-time diagnostic data capture (FTDC) data captured by mongod 3.2 and later.

It's especially useful to investigate HELP tickets.

Repository: https://github.com/10gen/t2

You can only install it on the laptop because it requires GUI.

Installation:

1- Download the source code from the last release https://github.com/10gen/t2/releases.
2- Build the code following the instructions from https://github.com/10gen/t2.
3- To run it you will have to go to t2 directory and:
    ./build/t2/t2 test/data/mongodb_6.0/*

### Mongo shell
`mongosh` is the official CLI tool for accessing a MongoDB server.

Website: https://www.mongodb.com/docs/mongodb-shell/

To install it, you can download binaries from https://www.mongodb.com/try/download/shell

The internal repo for the Mongo shell is: https://github.com/mongodb-js/mongosh.<br><br>


### db-contrib-tools
It is used to setup a multiversion environment. However, I'm using `m` instead of `db-contrib-tools`.

Repository: https://github.com/10gen/db-contrib-tool

To install it, follow the instructions from https://github.com/10gen/db-contrib-tool.<br><br>

## 2. Download this repo (modify WORKSPACE_DIR as desired)
    WORKSPACE_DIR=$HOME/workspace
    git clone https://github.com/silviasuhu/workspace.git $WORKSPACE_DIR

## 3. Create symbolic links and copies from downloaded files to HOME directory
    ln -s $WORKSPACE_DIR/mongodb/bashrc_lnx $HOME/.bashrc
    ln -s $WORKSPACE_DIR/mongodb/gitignore $HOME/.gitignore
    ln -s $WORKSPACE_DIR/common/vim/vimrc $HOME/.vimrc
    ln -s $WORKSPACE_DIR/common/tmux/tmux.conf $HOME/.tmux.conf
    ln -s $WORKSPACE_DIR/common/updateGitRepositories/updateGitRepositories.json $HOME/.updateGitRepositories.json
    ln -s $WORKSPACE_DIR/mongodb/vscode/settings.json $HOME/.vscode-server/data/Machine/settings.json
    
    mkdir -p $HOME/.lnav/formats/installed
    ln -s $WORKSPACE_DIR/mongodb/lnav/formats/* $HOME/.lnav/formats/installed
    
    cp $WORKSPACE_DIR/mongodb/evergreen.yml $HOME/.evergreen.yml
    cp $WORKSPACE_DIR/mongodb/gitconfig $HOME/.gitconfig
    
    echo "$WORKSPACE_DIR/common/fss/*" > $HOME/.fss.conf
    echo "$WORKSPACE_DIR/mongodb/fss/*" >> $HOME/.fss.conf

## 4. Enable executable mode on downloaded scripts
    chmod +x $WORKSPACE_DIR/common/scripts/bin/*
    chmod +x $WORKSPACE_DIR/mongodb/scripts/bin/*
        
## 5. Customize config files
    
1- Update ~/.evergreen.yml file with the header you will find in the "Evergreen website -> Preferences -> CLI & API -> Download the authentication file" (https://spruce.mongodb.com/preferences/cli). 

2- Update ~/.gitconfig file with your personal data. 
    
3- Update ~/.updateGitRepositories.json as desired.  

## 6. Install mongodbtoolchain (if necessary)
1- Follow steps on https://github.com/10gen/toolchain-builder/blob/master/INSTALL.md.  
2- Create symbolic links to some of the included binaries. 

    ln -s /opt/mongodbtoolchain/v4/bin/gdb $HOME/.local/bin/gdb
        
## 7. Install vim plugins (optional)
1- Clone the vim plugin manager

    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

2- Open vim

    vim
3- Run :PlugInstall command

    :PlugInstall
4- Wait pluggins to be installed and restart vim

Note: plugins to be installed are read from .vimrc file

More info here https://github.com/junegunn/vim-plug#unix
    
## 8. Install tmux plugins (optional)
1- Clone the tpm repository

    mkdir -p $HOME/.tmux/plugins
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm 

2- Enter a tmux session

3- Press prefix + I (capital i, as in Install)

## 9. Configure crontab to execute automatic scripts periodically (optional)
1- Open crontab:  

    crontab -e
        
2- Add the desired scripts. The following example will update git reporitories every day at 5AM and will clean /tmp directory at 7AM:  

    0 5 * * * /home/ubuntu/.config/workspace/common/scripts/bin/updateGitRepositories.sh
    0 7 * * * /home/ubuntu/.config/workspace/common/scripts/bin/cleanTmp.sh
        
3- Save and exit the crontab editor.  
    
## 10. Install mongo repositories

    mkdir -p ~/devel/mongo-enterprise-modules
    git clone git@github.com:10gen/mongo-enterprise-modules.git mongo-enterprise-modules
    
    mkdir -p ~/devel/mongodb-mongo-tools
    git clone git@github.com:mongodb/mongo-tools.git ~/devel/mongodb-mongo-tools
    
    mkdir -p ~/devel/mongo
    cd ~/devel/mongo
    git clone --bare git@github.com:10gen/mongo.git .bare
    echo "gitdir: ./.bare" > .git
    git worktree add --track -B master master origin/master
    git worktree add --track -B v7.0 v7.0 origin/v7.0
    git worktree add devel1 master
    git worktree add devel2 master
    git worktree add devel3 master
    
## 11. Link /data/db path to $HOME/.data to prevent full disk scenarios
    sudo mv /data ~/.data
    sudo ln -s ~/.data /data

# Other resources

- Oh my posh: https://ohmyposh.dev/docs/
- FZF tutorial video: https://www.youtube.com/watch?v=tB-AgxzBmH8&t=1031s
- FZF examples: https://github.com/junegunn/fzf/wiki/examples
- FZF advanced examples: https://github.com/junegunn/fzf/blob/master/ADVANCED.md
- Lnav: https://lnav.org
- How to test locally: https://github.com/mongodb/mongo/wiki/Running-Tests-from-Evergreen-Tasks-Locally
- WT guide: https://www.percona.com/blog/wiredtiger-file-forensics-part-3-viewing-all-the-mongodb-data
- Git worktree guildeline: https://morgan.cugerone.com/blog/how-to-use-git-worktree-and-in-a-clean-way/
