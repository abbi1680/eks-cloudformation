#!/bin/bash
# Martin Ansong <martin.ansong@gmail.com>
#
# Update Image tag for kubernetes deployment
#
# Usage: ./updateImage.sh <IMAGE> <K8SDEPLOYMENT FILE>
sed -i "" "/^\([[:space:]]*image: \).*/s//\1$1/" $2