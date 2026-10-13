# The version is passed in (--define "ver <version>") from demoreel's own
# __version__, so a bump never has to reach this file
# (docs/specs/DEMO-0068-linux-packages.md INV-7).
Name:           demoreel
Version:        %{ver}
Release:        1
Summary:        Record a GUI app on a private virtual display
License:        MIT
URL:            https://github.com/milnet01/demoreel
Source0:        demoreel-%{version}.tar.gz
BuildArch:      noarch

# Files, not package names, so one .rpm serves Fedora and openSUSE (§ 4.2).
Requires:       /usr/bin/python3
Requires:       /usr/bin/Xvfb
Requires:       /usr/bin/xauth
Requires:       /usr/bin/xdotool
Requires:       /usr/bin/ffmpeg
Requires:       /usr/bin/fc-match
Requires:       font(dejavusans)
Recommends:     /usr/bin/cage
Recommends:     /usr/bin/Xwayland
Recommends:     /usr/bin/wlr-randr
Recommends:     /usr/bin/wf-recorder

# The installed script is the tagged file, byte for byte (INV-3).
%undefine __brp_mangle_shebangs

%description
demoreel records a video or a picture of one app running on a display of
its own, so nothing of your desktop can end up in frame. It can also trim,
caption and join recordings, and make a short film from them.

The recommended packages are for --gpu, which records apps that need the
graphics card.

%prep
%setup -q

%build

%install
DESTDIR=%{buildroot} PREFIX=%{_prefix} packaging/install.sh

%files
%license LICENSE
%{_bindir}/demoreel
%{_datadir}/demoreel/
%{_mandir}/man1/demoreel.1*
%{_datadir}/bash-completion/completions/demoreel
%{_datadir}/zsh/site-functions/_demoreel
%{_datadir}/fish/vendor_completions.d/demoreel.fish
