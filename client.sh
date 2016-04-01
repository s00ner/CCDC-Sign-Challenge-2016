#!/bin/bash
#usage: ./client.sh [key] [message]
#example: ./client.sh 4e9f "This is my message"
#message is the message to be sent to the sign
#key is the 4 character hex key. It changes once in awhile so don't forget to check the key file for it.
#this script sets the message timer to 30 minutes so the message will be deleted from the sign after 30 minutes has passed

message=\"$1\"
json="{\"message\":$message,\"timer\":\"30m\"}"

curl -vks --key ./client.key --cert client.crt -d "$json" https://localhost:8888/message/new

echo
