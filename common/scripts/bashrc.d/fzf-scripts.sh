
## Shows available fzf function scripts with their descriptions
fzf_scripts() {

    echo  "-- GIT OPERATIONS --" \
          ""
    echo  "** fshow_preview - git commit browser"
    echo  "** fco_preview - git commit browser"
    echo  "** fcs - get git commit sha"
    echo  "** fgst - pick files from 'git status -s'" \
          ""
    echo  "** ga - interactive 'git add'"
    echo  "** glo - interactive 'git log'"
    echo  "** gd - interactive 'git diff'"
    echo  "** grh - interactive 'git reset HEAD'"
    echo  "** gcb - interactive 'git checkout <branch>'"
    echo  "** grb - interactive 'git rebase -i'"
    echo  "** gbl - interactive 'git blame'"
}

# fshow - git commit browser
#fshow() {
#    git log --graph --color=always \
#        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
#    fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
#        --bind "ctrl-m:execute:
#            (grep -o '[a-f0-9]\{7\}' | head -1 |
#            xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
#            {}
#            FZF-EOF"
#}

# fco_preview - checkout git branch/tag, with a preview showing the commits between the tag/branch and HEAD
fco_preview() {
  local tags branches target
  branches=$(
    git --no-pager branch --all \
      --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
    | sed '/^$/d') || return
  tags=$(
    git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}') || return
  target=$(
    (echo "$branches"; echo "$tags") |
    fzf --no-hscroll --no-multi -n 2 \
        --ansi --preview="git --no-pager log -150 --pretty=format:%s '..{2}'") || return
  git checkout $(awk '{print $2}' <<<"$target" )
}

alias glNoGraph='git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an" "$@"'
_gitLogLineToHash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
_viewGitLogLine="$_gitLogLineToHash | xargs -I % sh -c 'git show --color=always % | diff-so-fancy'"

# fcoc_preview - checkout git commit with previews
#fcoc_preview() {
#  local commit
#  commit=$( glNoGraph |
#    fzf --no-sort --reverse --tiebreak=index --no-multi \
#        --ansi --preview="$_viewGitLogLine" ) &&
#  git checkout $(echo "$commit" | sed "s/ .*//")
#}

# fshow_preview - git commit browser with previews
fshow_preview() {
    glNoGraph |
        fzf --no-sort --reverse --tiebreak=index --no-multi \
            --ansi --preview="$_viewGitLogLine" \
                --header "enter to view, alt-y to copy hash" \
                --bind "enter:execute:$_viewGitLogLine   | less -R" \
                --bind "alt-y:execute:$_gitLogLineToHash | xclip"
}

# fcs - get git commit sha
# example usage: git rebase -i `fcs`
fcs() {
  local commits commit
  commits=$(git log --color=always --pretty=oneline --abbrev-commit --reverse) &&
  commit=$(echo "$commits" | fzf --tac +s +m -e --ansi --reverse) &&
  echo -n $(echo "$commit" | sed "s/ .*//")
}

# fgst - pick files from `git status -s`
fgst() {
  # "Nothing to see here, move along"
  is_in_git_repo || return

  local cmd="${FZF_CTRL_T_COMMAND:-"command git status -s"}"

  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" fzf -m "$@" | while read -r item; do
    echo "$item" | awk '{print $2}'
  done
  echo
}
