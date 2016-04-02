#!/bin/bash
#usage: ./client.sh [message]
#example: ./client.sh "This is my message"
#message is the message to be sent to the sign
#this script sets the message timer to 30 minutes so the message will be deleted from the sign after 30 minutes has passed

message=\"$1\"
json="{\"message\":$message,\"timer\":\"30m\"}"

curl -vks --key ./client.key --cert client.crt -d "$json" https://localhost:8888/message/new

echo
