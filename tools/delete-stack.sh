#!/bin/bash
NAME=$1

echo "Deleting stack ${NAME}..."
aws cloudformation delete-stack \
--stack-name ${NAME}

echo "Waiting for stack ${NAME} to be deleted..."
aws cloudformation wait stack-delete-complete \
--stack-name ${NAME}