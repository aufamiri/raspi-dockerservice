#!/bin/bash

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

# send a simple email to the recipient
function notifyEmail {
  SUBJECT=${1}
  BODY=${2}
  RECIPIENT_EMAIL=${3}
  printf "Subject: %s\n\n%s" "${SUBJECT}" "${BODY}" | sudo -u pi msmtp --from=default -t "${RECIPIENT_EMAIL}"
}

# catch error from command in the previous line
function errorCatcher {
  # we're using $? here instead of directly feed the command to the if-else as command wise, it is nicer to look at
  # i.e if we feed the command to if-else, we need call this function like this:
  #           errorCatcher "cat files.log" "test" "something went wrong when reading files"
  # whereas if we're using $?, we can call it like this:
  #           cat files.log
  #           errorCatcher "test" "something went wrong when reading files"
  # additionally, we can get the intellisense working for the command if we're using the $? method, instead of
  # passing it as "string" like the other method.
  commandResult=$?
  subjectErrorMail=${1}
  optionalMessages=${2}
  recipientEmail=${3}
  if [[ $commandResult -ne 0 ]]; then
    notifyEmail "${subjectErrorMail}" "${optionalMessages} $(cat "${LOG_NAME}")" "${recipientEmail}"
  fi
}
