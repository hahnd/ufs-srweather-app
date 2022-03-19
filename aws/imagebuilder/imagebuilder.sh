#! /bin/bash

#
# Global variables to help build the AWS command line
#
function init_global()
{
  export profile="ufs"
  export aws="aws --profile ${profile} --region ${region}"
}


#
# Set the global variables for SRW
#
function init_srw()
{
  export stack_name="SrwGnuImageBuilder"
  export cf_template_file="cf_imagebuilder_srw_gnu.yaml"
  export image_name="srw-1-0-1"
  export region="us-east-1"
}



#
# Create the stack
#
# No parameters
#
function create_stack()
{
    # ensure that the stack does not already exist
    __get_stack_status
    if [[ "${status}" != "" ]]; then
      echo "Stack already exists, use replace or delete command."
      return
    fi

    # create a new stack
    echo "Creating stack..."
    ${aws} cloudformation create-stack \
      --stack-name ${stack_name} \
      --template-body file://./${cf_template_file} > /dev/null

    # wait for stack create completion
    __wait_for_stack_status "CREATE_COMPLETE"
}


#
# Delete the stack
#
# No parameters
#
function delete_stack()
{
    # get the current stack status
    __get_stack_status

    # nothing to do if it does not exist
    if [[ "${status}" == "" ]]; then
      echo "Stack does not exist."
      return
    fi

    # delete the stack if not already in progress
    if [[ "${status}" != "DELETE_IN_PROGRESS" ]]; then
      echo "Deleting stack..."
      ${aws} cloudformation delete-stack --stack-name ${stack_name}
    fi

    # wait for stack to be gone
    __wait_for_stack_status ""
}


#
# Replace the stack (i.e., delete and create)
#
# No parameters
#
function replace_stack()
{
    delete_stack
    create_stack
}


#
# Print the status of the stack
#
# No parameters
#
function status_stack()
{
  __get_stack_status
  __print_status_message
}


#
# Run the image pipeline to build the image
#
# No parameters
#
function build_image()
{
  pipeline_arn=$(${aws} imagebuilder list-image-pipelines \
    --filters "name=name,values=${image_name}" \
    | jq -r .imagePipelineList[].arn 2> /dev/null)

  ${aws} imagebuilder start-image-pipeline-execution \
    --image-pipeline-arn "${pipeline_arn}"

  if [[ $? == 0 ]]; then
    echo "Started image build."
  else
    echo "Failed to start build for pipeline: ${pipeline_arn}."
  fi
}


#
# Make an API call to get the stack status.  Sets the 'status' variable before return.
#
# No parameters
#
function __get_stack_status()
{
    status=$(${aws} cloudformation describe-stacks \
      --stack-name ${stack_name} \
      2>&1 | jq -r .Stacks[].StackStatus 2> /dev/null)
}


#
# Waits until the stack status becomes desired state
#
# target_status {str} Exit when stack status matches the given target status
#
function __wait_for_stack_status()
{
  target_status="${1}"

  __get_stack_status
  if [[ "${status}" != "${target_status}" ]]; then
    __print_status_message
    sleep 2
    __wait_for_stack_status "${target_status}"
  fi
}


#
# Prints an information line with the current status value.  Call __get_stack_status before this one.
#
# No parameters
#
function __print_status_message()
{
  s1="${status}"
  if [[ "${s1}" == "" ]]; then
    s1="<STACK_DOES_NOT_EXIST>"
  fi
  echo "  ${stack_name} ... ${s1} ... $(date '+%Y-%m-%d %H:%M:%S')"
}


#
# Prints the script usage and exits
#
# No parameters
#
function __print_usage_and_exit()
{
  echo "Script to help manipulate the CloudFormation stack to build images."
  echo "Usage:"
  echo "  $0 <srw|fe> <status|create|delete|replace|build>"
  exit 0
}


# check the command line parameter usage
if [[ $# != 1 ]]; then
  __print_usage_and_exit
fi


# setup the specified app
init_srw
init_global


# run specified command
command="${1}"
if [[ "${command}" == "delete" ]]; then
  delete_stack
elif [[ "${command}" == "create" ]]; then
  create_stack
elif [[ "${command}" == "replace" ]]; then
  replace_stack
elif [[ "${command}" == "status" ]]; then
  status_stack
elif [[ "${command}" == "build" ]]; then
  build_image
else
  __print_usage_and_exit
fi
