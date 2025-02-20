
send_command_to_every_tmux_pane() {
    for session in `tmux list-sessions -F '#S'`; do
        for window in `tmux list-windows -t $session -F '#I' | sort`; do
            for pane in `tmux list-panes -t $session:$window -F '#P' | sort`; do
                tmux send-keys -t "$session:$window.$pane" "$*" C-m;
            done
        done
    done
}

## Start/attach `main` session
ss_tmux() {
    tmux -u new -As main;
}

## Start/attach `vsc` session
ss_tmux_vsc() {
    tmux -u new-session -As vsc;
}
