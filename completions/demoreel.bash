# bash completion for demoreel (DEMO-0056).
# Load it from ~/.bashrc:   source /path/to/demoreel/completions/demoreel.bash
# or install it as /usr/share/bash-completion/completions/demoreel.

# The names of recordings still running, for `demoreel stop`. Asked of
# demoreel's own live_runs(), the test `stop` itself uses: every run leaves its
# state file behind, so the files alone would offer finished runs too. Never
# test the run's lock instead -- taking it, even for a moment, can make a run
# starting at that instant refuse to record.
_demoreel_running() {
    local exe
    exe=$(command -v -- "$1") || return
    python3 -c 'import importlib.machinery as m, importlib.util as u, sys
l = m.SourceFileLoader("demoreel", sys.argv[1])
d = u.module_from_spec(u.spec_from_loader("demoreel", l))
l.exec_module(d)
sys.stdout.write("".join(e["name"] + "\n" for e in d.live_runs()))' \
        "$exe" 2>/dev/null
}

_demoreel() {
    local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
    local i sub=
    for ((i = 1; i < COMP_CWORD; i++)); do
        case ${COMP_WORDS[i]} in
            record | shot | check | stop)
                [[ -z $sub ]] && sub=${COMP_WORDS[i]} ;;
            --)
                # Everything after -- is the app's own command line.
                if [[ $sub == record || $sub == shot ]]; then
                    if declare -F _command_offset >/dev/null; then
                        _command_offset $((i + 1))
                    elif ((COMP_CWORD == i + 1)); then
                        mapfile -t COMPREPLY < <(compgen -c -- "$cur")
                    else
                        compopt -o default
                        COMPREPLY=()
                    fi
                    return
                fi ;;
        esac
    done

    case $prev in
        -o | --output | --app-log)
            compopt -o default
            COMPREPLY=()
            return ;;
        -a | --action)
            # A step is one quoted word, 'click 400 300', so offer the verb
            # with its opening quote and let the user finish the step.
            local quote=${cur:0:1} verb
            [[ $quote == \' || $quote == \" ]] || quote=\'
            COMPREPLY=()
            for verb in wait move click type key hold; do
                [[ $verb == "${cur#[\'\"]}"* ]] && COMPREPLY+=("$quote$verb ")
            done
            compopt -o nospace
            return ;;
        -d | --duration | -s | --size | -r | --framerate | -n | --name | \
            --settle | --startup-timeout)
            return ;;
    esac

    local words
    case $sub in
        "")
            if [[ $cur == -* ]]; then
                words="-h --help --version"
            else
                words="record shot check stop"
            fi ;;
        record) words="-o --output -d --duration -s --size -r --framerate
                -n --name -a --action --app-log --settle --gpu --cursor
                --startup-timeout -h --help --" ;;
        shot) words="-o --output -s --size -a --action --app-log --settle
                --gpu --cursor --startup-timeout -h --help --" ;;
        check) words="-h --help" ;;
        stop)
            if [[ $cur == -* ]]; then
                words="-h --help"
            else
                mapfile -t COMPREPLY < <(compgen -W \
                    "$(_demoreel_running "${COMP_WORDS[0]}")" -- "$cur")
                return
            fi ;;
    esac
    mapfile -t COMPREPLY < <(compgen -W "$words" -- "$cur")
}

complete -F _demoreel demoreel
