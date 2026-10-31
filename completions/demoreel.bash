# bash completion for demoreel (DEMO-0056).
# Load it from ~/.bashrc:   source /path/to/demoreel/completions/demoreel.bash
# or install it as /usr/share/bash-completion/completions/demoreel.
#
# demoreel.fish and _demoreel beside this file hold their own copies of the
# same commands and options. The gate checks the commands, the options of
# record and shot, the -a steps and stop's run names, in all three shells.
# Nothing checks the other commands' options: after changing one, run
# ./ci.sh --option-places OPTION COMMAND, which asks each shell.

# Every command, and the finishing ones, which take files.
_demoreel_finishing="edit trim caption join card motion poster thumbnail sheet"
_demoreel_commands="record shot check stop $_demoreel_finishing"

# The names of recordings still running, for `demoreel stop`. Asked of
# demoreel's own live_runs(), the test `stop` itself uses: every run leaves its
# state file behind, so the files alone would offer finished runs too. Never
# test the run's lock instead -- taking it, even for a moment, can make a run
# starting at that instant refuse to record.
#
# This reads a file and runs python3 on the user's behalf at a key press, so it
# trusts nothing in the folder Tab is pressed in. -I keeps that folder and the
# PYTHON* variables off the import path, and -B writes no bytecode, which under
# a root shell would be a file no package owns. A command typed with a path can
# be a stranger's script, so it is not run at all.
_demoreel_running() {
    local exe
    [[ $1 == */* ]] && return
    exe=$(command -v -- "$1") || return
    python3 -I -B -c 'import importlib.machinery as m, importlib.util as u, sys
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
            --)
                # Everything after -- is the app's own command line.
                if [[ $sub == record || $sub == shot ]]; then
                    if declare -F _command_offset >/dev/null; then
                        _command_offset $((i + 1))
                    # Without the bash-completion package there is no
                    # _command_offset: offer command names, then files.
                    elif ((COMP_CWORD == i + 1)); then
                        mapfile -t COMPREPLY < <(compgen -c -- "$cur")
                    else
                        compopt -o default
                        COMPREPLY=()
                    fi
                    return
                fi ;;
            *)
                [[ -z $sub && " $_demoreel_commands " == *" ${COMP_WORDS[i]} "* ]] &&
                    sub=${COMP_WORDS[i]} ;;
        esac
    done

    # An option that takes a value is in this case as well as in its
    # command's words below; without it, Tab after the option offers options.
    case $prev in
        -o | --output | --steps | --app-log | --like | --music)
            compopt -o default
            COMPREPLY=()
            return ;;
        -a | --action)
            # A step is one quoted word, 'click 400 300', so offer the verb
            # with its opening quote and let the user finish the step.
            local quote=${cur:0:1} verb
            [[ $quote == \' || $quote == \" ]] || quote=\'
            COMPREPLY=()
            for verb in wait move click type key hold drag; do
                [[ $verb == "${cur#[\'\"]}"* ]] && COMPREPLY+=("$quote$verb ")
            done
            compopt -o nospace
            return ;;
        -d | --duration | -s | --size | -r | --framerate | -n | --name | \
            --settle | --startup-timeout | --region | --from | --to | --fade-in | \
            --fade-out | --fade-at | --fade-length | --crossfade | --text | \
            --text-size | --background | --still | -t | --time | --every | --at | \
            --width | --columns | \
            --music-level | --music-fade-in | --music-fade-out)
            return ;;
    esac

    local words
    local music="--music --music-level --music-fade-in --music-fade-out"
    case $sub in
        "")
            if [[ $cur == -* ]]; then
                words="-h --help --version"
            else
                words=$_demoreel_commands
            fi ;;
        record) words="-o --output -d --duration -s --size -r --framerate
                -n --name -a --action --steps --app-log --settle --gpu --cursor
                --audio --startup-timeout -h --help --" ;;
        shot) words="-o --output -s --size -a --action --steps --app-log --settle
                --gpu --cursor --region --startup-timeout -h --help --" ;;
        check) words="-h --help" ;;
        edit) words="-o --output -s --size -r --framerate -h --help" ;;
        trim) words="-o --output --from --to --fade-in --fade-out --fade-at
                --fade-length $music --no-sound -h --help" ;;
        caption) words="-o --output --text --from --to --text-size --fade-in
                --fade-out $music --no-sound -h --help" ;;
        join) words="-o --output --crossfade --fade-in --fade-out $music
                --no-sound -h --help" ;;
        card) words="-o --output -d --duration --text --text-size --background
                --like -s --size -r --framerate --fade-in --fade-out $music
                -h --help" ;;
        motion) words="--from --to --still --region --json -h --help" ;;
        poster) words="-o --output -t --time -h --help" ;;
        thumbnail) words="-o --output -t --time --text -h --help" ;;
        sheet) words="-o --output --every --at --region --width --columns -h --help" ;;
        stop)
            if [[ $cur == -* ]]; then
                words="-h --help"
            else
                # Matched here, never through compgen -W, which expands its
                # word list: a run's name comes from a file, and is only text.
                local name
                COMPREPLY=()
                while IFS= read -r name; do
                    [[ $name == "$cur"* ]] && COMPREPLY+=("$name")
                done < <(_demoreel_running "${COMP_WORDS[0]}")
                return
            fi ;;
    esac
    # The finishing commands take files: a script, videos, a picture.
    if [[ $cur != -* && -n $sub && " $_demoreel_finishing " == *" $sub "* ]]; then
        compopt -o default
        COMPREPLY=()
        return
    fi
    mapfile -t COMPREPLY < <(compgen -W "$words" -- "$cur")
}

complete -F _demoreel demoreel
