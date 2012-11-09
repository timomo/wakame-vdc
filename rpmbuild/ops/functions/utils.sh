# -*-Shell-script-*-
#
# description:
#  Various utility functions
#
# requires:
#  bash
#
# imports:
#

function extract_args() {
  CMD_ARGS=
  local arg=
  for arg in ${*}; do
    case "${arg}" in
    --*=*)
      key=${arg%%=*}; key=$(echo ${key##--} | tr - _)
      value=${arg##--*=}
      eval "${key}=\"${value}\""
      ;;
    *)
      CMD_ARGS="${CMD_ARGS} ${arg}"
      ;;
    esac
  done
  unset arg key value
  # trim
  CMD_ARGS=${CMD_ARGS%% }
  CMD_ARGS=${CMD_ARGS## }
}

function run_cmd() {
  #
  # Runs a command.
  #
  # Locale is reset to C to make parsing error messages possible.
  #
  export LANG=C
  export LC_ALL=C
  eval $*
}

function checkroot() {
  #
  # Check if we're running as root, and bail out if we're not.
  #
  [[ "${UID}" -ne 0 ]] && {
    echo "[ERROR] Must run as root." >&2
    return 1
  } || :
}
