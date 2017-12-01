#!/bin/bash

# bash generate random 31 character alphanumeric string (upper and lowercase) 
NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 30 | head -n 1)

echo $NEW_UUID
