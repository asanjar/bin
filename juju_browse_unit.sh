#!/bin/bash -eu

L_PORT=8080
R_PORT=443

JUJU_USER=ubuntu
JUJU_HOST=juju-host
JUJU_UNIT=juju-gui

PROTO=http
case $R_PORT in
  443)
    PROTO=https
    ;;
esac

SSH_CONTROL=`basename $0`-control

echo "Finding the IP address for ${JUJU_UNIT}"
UNIT_IP=`ssh -l ${JUJU_USER} ${JUJU_HOST} juju status "*${JUJU_UNIT}*" 2>/dev/null | grep public-address | awk '{print $2}'`

if [[ -z ${UNIT_IP} ]]; then
  echo "No IP address found for ${JUJU_UNIT}"
  exit 1
fi

echo "Creating tunnel localhost:${L_PORT}->${UNIT_IP}:${R_PORT}"
ssh -M -S ${SSH_CONTROL} -fnNT -L ${L_PORT}:${UNIT_IP}:${R_PORT} -l ${JUJU_USER} ${JUJU_HOST}

echo "Opening browser to local tunnel"
open "${PROTO}://localhost:${L_PORT}"

echo "Close tunnel?"
select i in "yes" "no"; do
  case $i in 
    yes)
      echo "Closing tunnel"
      ssh -S ${SSH_CONTROL} -O exit -l ${JUJU_USER} ${JUJU_HOST}
      break
      ;;
    no)
      echo "Tunnel Status:"
      ssh -S ${SSH_CONTROL} -O check -l ${JUJU_USER} ${JUJU_HOST}
      echo "Close tunnel?"
      ;;
  esac
done
