#!/bin/bash

set -e
LB="${LB_IP:-34.117.69.179}"
DNS="${GRPC_HOST:-app.revamp-online.test-2.nimblebox.ai}"
# check if we have a PEM file or it's two components, otherwise generate a self-signed one
if [[ -f $HITCH_KEY && -f $HITCH_CERT ]] && [[ ! (-z $HITCH_PEM && -f $HITCH_PEM) ]]; then
  HITCH_PEM=/etc/ssl/hitch/combined.pem
  touch $HITCH_PEM
  chmod 440 $HITCH_PEM
  cat $HITCH_KEY $HITCH_CERT >$HITCH_PEM
  echo Combined $HITCH_KEY and $HITCH_CERT
elif [ -f $HITCH_PEM ]; then
  echo Using $HITCH_PEM
else
  echo "Couldn't find PEM file, creating one for domain $IP"
  cd /etc/ssl/hitch
  # please replace X.X.X.X with external IP and public.dns.name with external FQDN
  openssl req -newkey rsa:2048 -sha256 -keyout example.com.key -nodes -x509 -days 36500 -out example.crt -subj "/C=IN/ST=TN/L=Uthandi/O=Nimblebox.ai/OU=Engineering/CN=$LB" -addext "subjectAltName=IP.1:$MY_POD_IP,IP.2:$LB,IP.3:127.0.0.1,DNS.1:$DNS"
  cat example.com.key example.crt >combined.pem
fi

exec bash -c \
  "exec /usr/local/sbin/hitch --user=hitch \
  $HITCH_PARAMS \
  --ciphers=$HITCH_CIPHER \
  --tls-protos="TLSv1.2" \
  --alpn-protos="h2" \
  $HITCH_PEM"
