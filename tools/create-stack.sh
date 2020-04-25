#!/bin/bash
# create-stack.sh
# This script creates or updates a cloudformation stack. See usage ./create-stack.sh -h
# 
# Martin Ansong
usage="Usage: $(basename "$0") stack-name template-file parameter-file region [aws-cli-opts]

where:
  stack-name     - the stack name
  template-file  - the cloudformation template file
  parameter-file - json file with parameters
  region         - the AWS region
  aws-cli-opts   - extra options passed directly to create-stack/update-stack
"

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "usage" ]; then
  echo "$usage"
  exit -1
fi

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] ; then
  echo "$usage"
  exit -1
fi

NAME=$1
TEMP_FILE=$2
PARAM_FILE=$3
REGION=$4
DIR="$(PWD)"

##################################### Functions Definitions #####################################
function validate_template() {
   aws cloudformation validate-template \
   --template-body file://${DIR}/${TEMP_FILE}
}

function create_stack () {
    aws cloudformation create-stack \
    --stack-name ${NAME} \
    --template-body file://${DIR}/${TEMP_FILE} \
    --parameters file://${DIR}/${PARAM_FILE} \
    --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
    --region ${REGION}
}

function wait_create_stack () {
    aws cloudformation wait stack-create-complete \
    --region ${REGION} \
    --stack-name ${NAME}
}

function wait_delete_stack () {
    aws cloudformation wait stack-delete-complete \
    --region ${REGION} \
    --stack-name ${NAME}
}

function update_stack () {
    aws cloudformation update-stack \
    --stack-name ${NAME} \
    --template-body file://${DIR}/${TEMP_FILE} \
    --parameters file://${DIR}/${PARAM_FILE} \
    --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
    --region ${REGION}
}

function delete_stack () {
    echo "Deleting stack ${NAME}..."
    aws cloudformation delete-stack \
    --stack-name ${NAME}
}

echo "Validating template file ${TEMP_FILE}..."
validation_output=`validate_template 2>&1`
valid_status=$?

if [ $valid_status -ne 0 ] ; then
    if [[ $validation_output == *"ValidationError"* ]] ; then
        echo -e "\nValidation Failed. Invalid yaml\n"
        echo -e "${validation_output}\n"
        exit 1;
    fi
fi

echo "Checking if stack ${NAME} exists..."

if ! aws cloudformation describe-stacks --region ${REGION} --stack-name ${NAME} ; then
    echo "Stack does not exist.., Creating stack ${NAME}..."
    create_stack
    echo "Waiting for stack to be created..."
    wait_create_stack
else
    echo "Stack exists, attempting update/re-create..."
    update_output=`update_stack 2>&1`
    status=$?
    if [ $status -ne 0 ] ; then
            if [[ $update_output == *"ValidationError"* && $update_output == *"No updates"* ]] ; then
                echo -e "\nFinished create/update - no updates to be performed"
                exit 0;
            elif [[ $update_output == *"ValidationError"* && $update_output == *"ROLLBACK_COMPLETE"* ]] ; then
                echo -e "\nStack is in ROLLBACK_COMPLETE state so can not be updated. Deleting and Recreating stack..."
                delete_stack
                echo "Waiting for stack ${NAME} to be deleted and re-created..."
                wait_delete_stack
                echo "Stack ${NAME} deleted. Recreating..."
                create_stack
                echo "Waiting for stack to be created..."
                wait_create_stack
                exit 0;
            fi
    fi
fi

echo "Finished creating/updating stack ${NAME}"