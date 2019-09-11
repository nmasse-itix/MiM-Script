#!/bin/sh

host="tipi.wifirst.fr"
host_ip="213.91.4.194"
port="443"
tmp="/tmp"

function on_exit () {
  kill "$pid_server" "$pid_client" "$pid_tee1" "$pid_tee2" &>/dev/null
  rm -f "$fifo1" "$fifo2" "$fifo3" "$fifo4"
}

fifo1="$tmp/fifo1"
fifo2="$tmp/fifo2"
fifo3="$tmp/fifo3"
fifo4="$tmp/fifo4"

key="$tmp/$host-key.pem"
cert="$tmp/$host-cert.pem"
dump_file="$tmp/$host-dump.txt"

rm -f "$dump_file"

if [ ! \( -e "$key" -a -e "$cert" \) ]; then
  rm -f "$key" "$cert"
  openssl req -newkey rsa:1024 -keyout "$key" -nodes -subj "/O=Fake/OU=Fake/CN=$host" -x509 -out "$cert" 
fi

mkfifo "$fifo1"
mkfifo "$fifo2"
mkfifo "$fifo3"
mkfifo "$fifo4"

trap on_exit EXIT

openssl s_server -accept "$port" -key "$key" -cert "$cert" -quiet > /tmp/fifo1 < /tmp/fifo2 &
pid_server="$!"
openssl s_client -host "$host_ip" -port "$port" -quiet < /tmp/fifo3 > /tmp/fifo4 &
pid_client="$!"

tee -a "$dump_file" < /tmp/fifo1 > /tmp/fifo3 &
pid_tee1="$!"
tee -a "$dump_file" < /tmp/fifo4 > /tmp/fifo2 &
pid_tee2="$!"

wait "$pid_client"

