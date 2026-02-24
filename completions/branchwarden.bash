_branchwarden_complete() {
  local cur prev words cword
  _init_completion || return
  local subs="status stale clean audit apply bulk pr-gates doctor init completion"
  if [[ $cword -eq 1 ]]; then COMPREPLY=( $(compgen -W "$subs" -- "$cur") ); return; fi
}
complete -F _branchwarden_complete branchwarden
