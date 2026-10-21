# fish completion for demoreel (DEMO-0056).
# Install it as ~/.config/fish/completions/demoreel.fish, or
# /usr/share/fish/vendor_completions.d/demoreel.fish.
#
# demoreel.bash and _demoreel beside this file hold their own copies of the
# same commands and options. The gate checks the commands, the options of
# record and shot, the -a steps and stop's run names, in all three shells.
# Nothing checks the other commands' options: after changing one, run
# ./ci.sh --option-places OPTION COMMAND, which asks each shell.

# The names of recordings still running, for `demoreel stop`. Asked of
# demoreel's own live_runs(), the test `stop` itself uses: every run leaves its
# state file behind, so the files alone would offer finished runs too. Never
# test the run's lock instead -- taking it, even for a moment, can make a run
# starting at that instant refuse to record.
function __demoreel_running
    set -l exe (command -v -- (commandline -opc)[1]); or return
    python3 -c 'import importlib.machinery as m, importlib.util as u, sys
l = m.SourceFileLoader("demoreel", sys.argv[1])
d = u.module_from_spec(u.spec_from_loader("demoreel", l))
l.exec_module(d)
sys.stdout.write("".join(e["name"] + "\n" for e in d.live_runs()))' \
        $exe 2>/dev/null
end

# True once `--` follows record or shot: everything after it is the app's own
# command. The other commands start no app.
function __demoreel_in_app
    contains -- -- (commandline -opc); and __fish_seen_subcommand_from record shot
end

# Complete the app's command line as fish would on its own. Not
# __fish_complete_subcommand --fcs-skip: that counts only the words that are
# not options, so an option's value such as demo.mp4 throws the count off.
function __demoreel_app
    set -l tokens (commandline -opc)
    set -l app
    set -l at (contains -i -- -- $tokens)
    test $at -lt (count $tokens); and set app (string escape -- $tokens[(math $at + 1)..-1])
    complete -C (string join ' ' -- $app (commandline -ct))
end

function __demoreel_on
    not __demoreel_in_app; and __fish_seen_subcommand_from $argv
end

complete -c demoreel -f
complete -c demoreel -n __demoreel_in_app -x -a '(__demoreel_app)'

complete -c demoreel -n __fish_use_subcommand -s h -l help -d 'show help'
complete -c demoreel -n __fish_use_subcommand -l version -d 'show the version'
# Each command's description is its help in demoreel's build_parser(). A new
# command also joins the -h line below and, if it takes files, the finishing
# commands' line further down.
complete -c demoreel -n __fish_use_subcommand -a record -d 'record an app and write a video file'
complete -c demoreel -n __fish_use_subcommand -a shot -d 'take one picture of an app and write a PNG'
complete -c demoreel -n __fish_use_subcommand -a check -d 'test whether this machine can record, without recording'
complete -c demoreel -n __fish_use_subcommand -a stop -d 'end a running recording early'
complete -c demoreel -n __fish_use_subcommand -a edit -d 'make a film from a script of scenes'
complete -c demoreel -n __fish_use_subcommand -a trim -d 'cut the start and the end off a video'
complete -c demoreel -n __fish_use_subcommand -a caption -d 'put text over part of a video'
complete -c demoreel -n __fish_use_subcommand -a join -d 'put videos end to end'
complete -c demoreel -n __fish_use_subcommand -a card -d 'make a clip from a picture, or from text'
complete -c demoreel -n __fish_use_subcommand -a motion -d 'report how smooth a video is and where it stands still'
complete -c demoreel -n __fish_use_subcommand -a poster -d 'save one frame of a video as a picture'
complete -c demoreel -n __fish_use_subcommand -a sheet -d 'save several frames of a video, with their times, as one picture'

complete -c demoreel -n '__demoreel_on record shot check stop edit trim caption join card motion poster sheet' -s h -l help -d 'show help'

complete -c demoreel -n '__demoreel_on record' -s o -l output -r -F -d 'video file to write'
complete -c demoreel -n '__demoreel_on shot' -s o -l output -r -F -d 'picture file to write'
complete -c demoreel -n '__demoreel_on record' -s d -l duration -x -d 'seconds to record; 0 means until stop'
complete -c demoreel -n '__demoreel_on record' -s r -l framerate -x -d 'frames per second'
complete -c demoreel -n '__demoreel_on record' -s n -l name -x -d 'name for this run'
complete -c demoreel -n '__demoreel_on record shot' -s s -l size -x -d 'virtual display size'
complete -c demoreel -n '__demoreel_on record shot' -s a -l action -x \
    -a "'wait ' 'move ' 'click ' 'type ' 'key ' 'hold ' 'drag '" -d 'scripted step'
complete -c demoreel -n '__demoreel_on record shot' -l steps -r -F -d 'read the scripted steps from a file'
complete -c demoreel -n '__demoreel_on record shot' -l app-log -r -F -d "keep the app's own output"
complete -c demoreel -n '__demoreel_on record shot' -l settle -x -d 'wait for the first frame'
complete -c demoreel -n '__demoreel_on record shot' -l gpu -d 'for an app that needs the graphics card'
complete -c demoreel -n '__demoreel_on record shot' -l cursor -d 'show the mouse pointer'
complete -c demoreel -n '__demoreel_on shot' -l region -x -d 'keep only this rectangle of the picture'
complete -c demoreel -n '__demoreel_on record' -l audio -d "put the app's own sound in the video"
complete -c demoreel -n '__demoreel_on record shot' -l startup-timeout -x -d "how long to wait for the app's window"

complete -c demoreel -n '__demoreel_on stop' -a '(__demoreel_running)' -d 'running recording'

# The finishing commands take files: a script, videos, a picture.
complete -c demoreel -n '__demoreel_on edit trim caption join card motion poster sheet' -F
complete -c demoreel -n '__demoreel_on edit trim caption join card' -s o -l output -r -F -d 'video file to write'
complete -c demoreel -n '__demoreel_on poster sheet' -s o -l output -r -F -d 'picture file to write'
complete -c demoreel -n '__demoreel_on edit card' -s s -l size -x -d 'the picture size'
complete -c demoreel -n '__demoreel_on edit card' -s r -l framerate -x -d 'frames per second'
complete -c demoreel -n '__demoreel_on trim caption motion' -l from -x -d 'where it starts'
complete -c demoreel -n '__demoreel_on trim caption motion' -l to -x -d 'where it ends'
complete -c demoreel -n '__demoreel_on trim caption join card' -l fade-in -x -d 'start black'
complete -c demoreel -n '__demoreel_on trim caption join card' -l fade-out -x -d 'end on black'
complete -c demoreel -n '__demoreel_on trim' -l fade-at -x -d 'fade to black and back around this moment'
complete -c demoreel -n '__demoreel_on trim' -l fade-length -x -d 'how long each half of a fade-at takes'
complete -c demoreel -n '__demoreel_on join' -l crossfade -x -d 'fade from each video into the next'
complete -c demoreel -n '__demoreel_on trim caption join card' -l music -r -F -d 'lay this sound file under the film'
complete -c demoreel -n '__demoreel_on trim caption join card' -l music-level -x -d 'the level the music averages'
complete -c demoreel -n '__demoreel_on trim caption join card' -l music-fade-in -x -d 'the music arrives over this long'
complete -c demoreel -n '__demoreel_on trim caption join card' -l music-fade-out -x -d 'the music goes over this long'
complete -c demoreel -n '__demoreel_on trim caption join' -l no-sound -d "leave out the videos' own sound"
complete -c demoreel -n '__demoreel_on caption card' -l text -x -d 'one line of text'
complete -c demoreel -n '__demoreel_on caption card' -l text-size -x -d 'the height of the text'
complete -c demoreel -n '__demoreel_on card' -s d -l duration -x -d 'how many seconds the card lasts'
complete -c demoreel -n '__demoreel_on card' -l background -x -d 'the background colour'
complete -c demoreel -n '__demoreel_on card' -l like -r -F -d 'take the size and frame rate from this video'
complete -c demoreel -n '__demoreel_on motion' -l still -x -d 'report a stretch with no change longer than this'
complete -c demoreel -n '__demoreel_on motion' -l json -d 'print the report as one JSON object'
complete -c demoreel -n '__demoreel_on poster' -s t -l time -x -d 'which moment to save'
complete -c demoreel -n '__demoreel_on motion' -l region -x -d 'look only at this rectangle of the picture'
complete -c demoreel -n '__demoreel_on sheet' -l every -x -d 'take a frame every so many seconds'
complete -c demoreel -n '__demoreel_on sheet' -l at -x -d 'take the frames at these times'
complete -c demoreel -n '__demoreel_on sheet' -l region -x -d 'show only this rectangle of each frame'
complete -c demoreel -n '__demoreel_on sheet' -l width -x -d "each frame's width"
complete -c demoreel -n '__demoreel_on sheet' -l columns -x -d 'how many frames side by side'
