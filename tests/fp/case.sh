#!/bin/sh
sed -i 's/[A-Z]/\L&/g' $1
