LOG_NAME="/logs/scripts.log"

function initLog {
  LOG_NAME=${1}
  echo -n "" >"${LOG_NAME}"
}

function doLog {
  echo "${1}" >>"${LOG_NAME}"
}

function breakpoint {
  doLog ""
  doLog ""
  doLog "##########################################################"
}
