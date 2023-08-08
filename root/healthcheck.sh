#!/bin/bash

# check to see if M172DMR is running (addd -x to support qemu wrapper)
[[ ! -z $( pidof -x /usr/local/bin/M172DMR ) ]]

