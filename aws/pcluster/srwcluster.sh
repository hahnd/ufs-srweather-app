#! /bin/bash


#
# Global variables used in multiple functions across all cluster types
#
function init_global()
{
  export profile="default"
  export aws="aws --region ${region} --profile ${profile}"
}


#
# Set the global variables for SRW
#
function init_srw()
{
  export region="us-east-1"
  export subnet="subnet-0927a21518035f16a"
  export ami="ami-0d9dca56fc1e718c8"
}


#
# Use pcluster to start a new cluster for the current user
#
# No parameters
#
function start_cluster()
{
  __get_stack_status
  if [[ "${status}" != "" ]]; then
    echo "Cluster ${USER} is already running.  Try connect command."
    return
  fi

  cat srwcluster.yaml \
    | sed "s/__USER__/${USER}/g" \
    | sed "s/__SUBNET_ID__/${subnet}/g" \
    | sed "s/__AMI_ID__/${ami}/g" \
    | sed "s/__REGION__/${region}/g" \
      > /tmp/${USER}.srwcluster.yaml
  pcluster create-cluster --region ${region} --cluster-name ${USER} --cluster-configuration /tmp/${USER}.srwcluster.yaml
  rm -f /tmp/${USER}.srwcluster.yaml
  __wait_for_stack_status CREATE_COMPLETE
}


#
# Use pcluster to stop the current user's cluster
#
# No parameters
#
function stop_cluster()
{
  __get_stack_status
  if [[ "${status}" == "" ]]; then
    echo "Cluster ${USER} is not running."
    return
  fi

  pcluster delete-cluster --region ${region} --cluster-name ${USER}
  __wait_for_stack_status ""
}


#
# Use pcluster to connect to the current user's cluster
#
# No parameters
#
function connect_cluster()
{
  __get_stack_status
  if [[ "${status}" == "" ]]; then
    echo "Cluster ${USER} is not running."
  fi

  __print_status_message
  exec pcluster ssh --region ${region} --cluster-name ${USER}
}


#
# Use CloudFormation to check on the current user's cluster's status
#
# No parameters
#
function status_cluster()
{
  __get_stack_status
  __print_status_message
}


#
# Open the CloudWatch dashboard for the user-specified cluster
#
function dashboard_cluster()
{
  status_cluster
  url="https://${region}.console.aws.amazon.com/cloudwatch/home?region=${region}#dashboards:name=${USER}-${region}"
  echo "Dashboard at:"
  echo "  ${url}"
  open "${url}"
}


#
# Make an API call to get the stack status.  Sets the 'status' variable before return.
#
# No parameters
#
function __get_stack_status()
{
    status=$(${aws} cloudformation describe-stacks \
      --stack-name ${USER} \
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
    s1="<CLUSTER_DOES_NOT_EXIST>"
  fi
  echo "  ${USER} ... ${s1} ... $(date '+%Y-%m-%d %H:%M:%S')"
}


#
# Prints the script usage and exits
#
# No parameters
#
function __print_usage_and_exit()
{
  echo "Script to help start up the SRW Cluster with ParallelCluster"
  echo "Usage:"
  echo "  $0 <status|start|stop|connect|dashboard>"
  exit 0
}


# check the command line parameter usage
if [[ $# != 1 ]]; then
  __print_usage_and_exit
fi


# initialize variables for the user-specified cluster type
init_srw
init_global


# run the user-specified command
command="${1}"
if [[ "${command}" == "start" ]]; then
  start_cluster
elif [[ "${command}" == "stop" ]]; then
  stop_cluster
elif [[ "${command}" == "connect" ]]; then
  connect_cluster
elif [[ "${command}" == "status" ]]; then
  status_cluster
elif [[ "${command}" == "dashboard" ]]; then
  dashboard_cluster
else
  __print_usage_and_exit
fi
