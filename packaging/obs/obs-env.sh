# shellcheck shell=bash disable=SC2034  # its callers read these
# The OBS settings obs-setup.sh, obs-submit.sh and obs-status.sh share, each
# overridable from the environment. Sourced, not run. One home, so a trial
# under OBS_PACKAGE=demoreel-test sets up, submits to and watches the same
# package.
api=${OBS_API:-https://api.opensuse.org}
project=${OBS_PROJECT:-home:milnet:demoreel}
package=${OBS_PACKAGE:-demoreel}
