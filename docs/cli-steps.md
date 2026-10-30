# How many steps the common tasks take

The shortest command for each common task, and how many options it needs beyond
the files it works on (DEMO-0263). Later versions compare against this table.
Counted 2026-10-30 from each command's `--help`, for the version after 0.9.0.

`ci.sh`'s check *without -o, a command names its file and writes nothing over*
runs the finishing commands below in the form shown, apart from a time or text
it chooses itself.

| Task | Shortest command | Options |
|---|---|---|
| See whether this machine can record | `demoreel check` | 0 |
| Record an app, for 30 seconds | `demoreel record -- kate` | 0 |
| Take a picture of an app | `demoreel shot -- kate` | 0 |
| Trim a video | `demoreel trim demo.mp4 --to 20` | 1 |
| Caption a video | `demoreel caption demo.mp4 --text 'Hello'` | 1 |
| Join videos | `demoreel join a.mp4 b.mp4` | 0 |
| Make a title card | `demoreel card --text 'A title'` | 1 |
| Make a film from a script | `demoreel edit film.txt` | 0 |
| Find where a video stands still | `demoreel motion demo.mp4` | 0 |
| Make a poster | `demoreel poster demo.mp4 -t 5` | 1 |
| Make a YouTube thumbnail | `demoreel thumbnail demo.mp4 -t 5` | 1 |
| See a video's frames at a glance | `demoreel sheet demo.mp4` | 0 |

## What stays required, and why

- **`poster` and `thumbnail` take `-t`.** Their one frame is what gets published,
  and a frame picked for the caller may be a poor one (user's decision,
  2026-10-30).
- **`caption` takes `--text`.** It has no other purpose.
- **`trim` takes something to do.** Without one it would only encode the video
  again and lose quality.

## Finding a feature from `--help`

`demoreel --help` lists every command. `demoreel COMMAND --help` lists every
option of that command, so an option is one step further. The words of an `edit`
script are not options, so `edit --help` names where they are listed.
