_todo_completions() {
  local cur
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "add delete show" -- "$cur") )
}
complete -F _todo_completions todo
