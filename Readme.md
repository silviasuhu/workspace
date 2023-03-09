# What is included

## Generic environment
- Tmux v3.3 with custom configuration
- Vim with custom configuration
- Oh-my-posh
- FZF
- lnav
- `fss` command (easy way to execute predefined commands using `fzf`)

## MongoDB development
- evergreen.yml template file
- Automatically pull mongo repositories with `updateGitRepositories.sh`
- Selfmade development scripts accessed by `fss`
- mongodbtoolchain installation guide (https://github.com/10gen/toolchain-builder/blob/master)
- mtools (https://github.com/rueckstiess/mtools). Bunch of tools like `mlaunch` (which spawns a MongoDB cluster) and `mloginfo` and `mlogfilter` (which helps you analyzing mongodb logs)
- m (https://github.com/aheckmann/m). Helps you download, use, and manage multiple versions of the MongoDB server and command-line tools.
- mrlog (https://github.com/markbenvenuto/mrlog). Improves mongodb log reading.
- git-co-evg-base (https://github.com/evergreen-ci/git-co-evg-base)
- t2 (https://github.com/10gen/t2) Tool to graph server statistics

## MongoDB binaries
- MongoShell `mongo`

# Installation

## 1. Create local bin directory
    mkdir -p ~/.local/bin

## 2. Install dependencies

#### oh-my-posh
    sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O ~/.local/bin/oh-my-posh
    sudo chmod +x $HOME/.local/bin/oh-my-posh
    oh-my-posh font install Meslo
#### tmux (v3.3)
    sudo apt-get remove tmux
    sudo apt-get install libevent-dev ncurses-dev build-essential bison pkg-config
        
    cd $HOME
    wget https://github.com/tmux/tmux/releases/download/3.3/tmux-3.3.tar.gz
    tar -xf tmux-3.3.tar.gz
    cd tmux-3.3
    ./configure --prefix=$HOME/.local
    make && sudo make install
    rm $HOME/tmux-3.3.tar.gz 
#### fzf
    git clone --depth 1 https://github.com/junegunn/fzf $HOME/.fzf
    $HOME/.fzf/install
#### fd
###### Linux
    sudo apt-get install fd-find
    ln -s $(which fdfind) $HOME/.local/bin/fd
###### MacOS
    brew install fd
#### diff-so-fancy
###### Linux
    git clone https://github.com/so-fancy/diff-so-fancy $HOME/.diff-so-fancy
    ln -s $HOME/.diff-so-fancy/diff-so-fancy $HOME/.local/bin/diff-so-fancy
###### MacOS
    brew install diff-so-fancy
#### forgit
    git clone https://github.com/wfxr/forgit $HOME/.forgit
#### m
Follow instructions from https://github.com/aheckmann/m#installation.  

Be sure m binary is in your PATH env variable.
#### mtools
Follow instructions from https://rueckstiess.github.io/mtools/install.html.  

Be sure binaries are in your PATH env variable.  
#### mrlog
Follow instructions from https://github.com/markbenvenuto/mrlog.  
#### git-co-evg-base
Follow instructions from https://github.com/evergreen-ci/git-co-evg-base#installation.  
#### t2
Follow instructions from https://github.com/10gen/t2.  

Note: it requires GUI.  
#### lnav
Follow instructions from https://lnav.org/downloads.  

## 2. Download this repo (modify WORKSPACE_DIR as desired)
    WORKSPACE_DIR=$HOME/.config/workspace
    mkdir -p $WORKSPACE_DIR
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

## 6. Install mongodbtoolchain (if needed)
1- Follow steps on https://github.com/10gen/toolchain-builder/blob/master/INSTALL.md.  
2- Create symbolic links to some of the included binaries. 

    ln -s /opt/mongodbtoolchain/v4/bin/gdb $HOME/.local/bin/gdb
        
## 7. Install vim plugins
1- Clone the vim plugin manager

    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

2- Open vim

    vim
3- Run :PlugInstall command

    :PlugInstall
4- Wait pluggins to be installed and restart vim

Note: plugins to be installed are read from .vimrc file

More info here https://github.com/junegunn/vim-plug#unix
    
## 8. Install tmux plugins
1- Clone the tpm repository

    mkdir -p $HOME/.tmux/plugins
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm 

2- Enter a tmux session

3- Press prefix + I (capital i, as in Install)

## 9. Configure crontab to execute automatic scripts periodically
1- Open crontab:  

    crontab -e
        
2- Add the desired scripts. The following example will update git reporitories every day at 5AM and will clean /tmp directory at 7AM:  

    0 5 * * * /home/ubuntu/.config/workspace/common/scripts/bin/updateGitRepositories.sh
    0 7 * * * /home/ubuntu/.config/workspace/common/scripts/bin/cleanTmp.sh
        
3- Save and exit the crontab editor.  
    

# Other resources

- Tmux plugins: https://github.com/tmux-plugins/tpm
- Oh my posh: https://ohmyposh.dev/docs/
- FZF tutorial video: https://www.youtube.com/watch?v=tB-AgxzBmH8&t=1031s
- FZF examples: https://github.com/junegunn/fzf/wiki/examples
- FZF advanced examples: https://github.com/junegunn/fzf/blob/master/ADVANCED.md
- Diff so fancy: https://github.com/so-fancy/diff-so-fancy
- Lnav: https://lnav.org
