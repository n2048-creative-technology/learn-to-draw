#!/bin/bash

let "a = $(curl -k -s https://draw.neurohub.io/api/list | jq | wc -l) / 3"

echo $a;

