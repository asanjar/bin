#!/bin/bash -eux

L_PORT=8080
R_PORT=443

JUJU_UNIT=juju-gui
SSH_HOST=YOUR_HOST
SSH_PORT=22
SSH_USER=ubuntu
SSH_CONTROL=`basename $0`-control

PROTO=http
case $R_PORT in
  443)
    PROTO=https
    ;;
esac

echo "Finding the IP address for ${JUJU_UNIT}"
UNIT_IP=`ssh -l ${SSH_USER} -p ${SSH_PORT} ${SSH_HOST} juju status ${JUJU_UNIT} | grep public-address | head -1 | awk '{print $2}'`

if [[ -z ${UNIT_IP} ]]; then
  echo "No IP address found for ${JUJU_UNIT}"
  exit 1
fi

echo "Creating tunnel localhost:${L_PORT}->${UNIT_IP}:${R_PORT}"
ssh -M -S ${SSH_CONTROL} -fnNT -L ${L_PORT}:${UNIT_IP}:${R_PORT} -l ${SSH_USER} -p ${SSH_PORT} ${SSH_HOST}

echo "Opening browser to local tunnel"
open "${PROTO}://localhost:${L_PORT}"

echo "Close tunnel?"
select i in "yes" "no"; do
  case $i in 
    yes)
      echo "Closing tunnel"
      ssh -S ${SSH_CONTROL} -O exit -l ${SSH_USER} -p ${SSH_PORT} ${SSH_HOST}
      break
      ;;
    no)
      echo "Tunnel Status:"
      ssh -S ${SSH_CONTROL} -O check -l ${SSH_USER} -p ${SSH_PORT} ${SSH_HOST}
      echo "Close tunnel?"
      ;;
    *)
      echo "Pick 1..2"
      echo "Close tunnel?"
      ;;
  esac
done
