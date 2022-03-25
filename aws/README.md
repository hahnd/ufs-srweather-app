# SRW-UFS

The following documentation shows how to install ParallelCluster, start a cluster on AWS, connect to
the cluster, start a job on the cluster with Slurm, and stop the cluster.

## Environment Setup

### Install Dependencies - ParallelCluster, AWS CLI, NodeJS, and jq:

<details>
<summary><b>AWS Command Line Interface (CLI) and ParallelCluster</b></summary>

```
python3 -m pip install --user awscli aws-parallelcluster==3.0.2
```


It may be necessary to add the python bin directory to your PATH variable:
```
# Linux
    # bash
    echo 'export PATH="${HOME}/.local/bin:${PATH}"' | tee -a ~/.bashrc
    source ~/.bashrc

    # csh
    echo 'setenv PATH "${HOME}/.local/bin:${PATH}"' | tee -a ~/.cshrc
    source ~/.cshrc

# MacOS -- may need to adjust python version number below
    # bash
    echo 'export PATH="${HOME}/Library/Python/3.9/bin:${PATH}"' | tee -a ~/.bashrc
    source ~/.bashrc
    
    # csh
    echo 'setenv PATH "${HOME}/Library/Python/3.9/bin:${PATH}"' | tee -a ~/.cshrc
    source ~/.cshrc
```
</details>

<details>
<summary><b>Install NodeJS</b></summary>
NodeJS can be installed anywhere, as long as it ends up in your
PATH variable.  The example below installs it in ${HOME}/srw,
but you can change the installation location to whatever you like.

```
# download from NodeJS.org
mkdir -p ${HOME}/opt && cd ${HOME}/opt
wget https://nodejs.org/dist/v16.13.2/node-v16.13.2-darwin-x64.tar.gz 
  -- don't have wget?  use curl --
curl https://nodejs.org/dist/v16.13.2/node-v16.13.2-darwin-x64.tar.gz > node-v16.13.2-darwin-x64.tar.gz

# compute and compare checksums
echo 900a952bb77533d349e738ff8a5179a4344802af694615f36320a888b49b07e6 
shasum -a 256 node-v16.13.2-darwin-x64.tar.gz

# DO NOT CONTINUE if checksum does not match
tar -xzf node-v16.13.2-darwin-x64.tar.gz
ln -s node-v16.13.2-darwin-x64 nodejs

# add to path for BASH users:
echo 'export PATH="${PATH}:${HOME}/opt/nodejs/bin"' | tee -a ~/.bashrc

# add to path for CSH users:
echo 'setenv PATH "${PATH}:${HOME}/opt/nodejs/bin"' | tee -a ~/.cshrc
```
</details>

<details>
<summary><b>Install jq</b></summary>

The jq utility is for parsing JSON formatted data on the command line
and is used by the srwcluster.sh script.  It can be installed with brew
or [ask RAL IT](mailto:ral-rt@rap.ucar.edu) to install it.
```
brew install jq

  -- or --

email: ral-rt@rap.ucar.edu
```
</details>

### Create your credentials file and set permissions
```
mkdir ~/.aws
chmod 700 ~/.aws
touch ~/.aws/credentials
chmod 600 ~/.aws/credentials
${EDITOR} ~/.aws/credentials
```

### Add your AWS access keys to the _credentials_ file as follows
```
[default]
aws_access_key_id = AKIAxxxxxxxxxxxx
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
region = us-east-2
output = json
```

### Test your AWS command line interface
```
aws s3 ls
```

### Upload your SSH public key to AWS
```
aws --region us-east-1 ec2 import-key-pair --key-name ${USER} --public-key-material fileb://${HOME}/.ssh/id_rsa.pub
```


---

## ImageBuilder
The _AWS/imagebuilder_ directory of this repository contains CloudFormation template with ImageBuilder
resources to build an image for SRW.  The image contains the full OS, model 
dependencies, and the model code.  The build steps can be found in the YAML files in the _SrwComponent_ 
section.

### Build and image for each system
The _imagebuilder.sh_ script will hide details of the CloudFormation stacks and ImageBuilder process.
This script takes one parameter: _command_

The _command_ parameter can be one of: _create_, _delete_, _replace_, _status_, _build_

#### Steps to build an image
Check the status to see if the image builder is running
```
./imagebuilder.sh status
  SrwGnuImageBuilder ... <STACK_DOES_NOT_EXIST> ... 2022-01-28 13:36:57
```

If the status shows that the stack does not exist, it must be created:
```
./imagebuilder.sh create
Creating stack...
  SrwGnuImageBuilder ... CREATE_IN_PROGRESS ... 2022-01-28 13:37:34
  SrwGnuImageBuilder ... CREATE_IN_PROGRESS ... 2022-01-28 13:37:37
  SrwGnuImageBuilder ... CREATE_IN_PROGRESS ... 2022-01-28 13:37:40
  SrwGnuImageBuilder ... CREATE_IN_PROGRESS ... 2022-01-28 13:37:43
  SrwGnuImageBuilder ... CREATE_IN_PROGRESS ... 2022-01-28 13:37:46
  SrwGnuImageBuilder ... CREATE_IN_PROGRESS ... 2022-01-28 13:37:48
  SrwGnuImageBuilder ... CREATE_IN_PROGRESS ... 2022-01-28 13:37:51

./imagebuilder.sh status
  SrwGnuImageBuilder ... CREATE_COMPLETE ... 2022-01-28 13:38:06
```

When the status shows as _CREATE_COMPLETE_, you can build the image:
```
./imagebuilder.sh build
...
Started image build.
```
The image build takes about an hour and the result can be seen on the [AWS EC2 console](https://console.aws.amazon.com/ec2).

The resulting AMI IDs can then be put into the ParallelCluster configuration file in the pcluster directory in this repository.

#### Updating build steps
If you update the build steps in the YAML files, you will want to run _replace_ before building again.  The 
_replace_ command is just a shortcut for _delete_ and _create_.
```
./imagebuilder.sh replace
```

#### This CloudFormation stack does not cost anything to leave it running, so it can be left alone or deleted.
```
./imagebuilder.sh delete
```

---
## ParallelCluster

### Start command:
```
./srwcluster.sh start
```

### Connect command:
```
./srwcluster.sh connect
```

## Slurm

```
echo 'export PATH="/opt/slurm/bin:${PATH}"' | sudo tee -a /etc/bashrc
source /etc/bashrc
```
### Run interactive job
```
srun -p srw --pty bash -i
```


### Example sbatch file
```
#!/bin/bash
#SBATCH --job-name=srw               # Job name
#SBATCH --ntasks=576                 # Number of MPI tasks (i.e. processes)
#SBATCH --cpus-per-task=1            # Number of cores per MPI task
#SBATCH --nodes=6                    # Maximum number of nodes to be allocated
#SBATCH --ntasks-per-node=96         # Maximum number of tasks on each node
#SBATCH --output=srw_%j.log          # Path to the standard output and error files relative to the working directory

cd /data/run
srun --mpi=pmi2 /opt/ufs-srweather-app/bin/NEMS.exe
```

### Stop command:
```
./srwcluster.sh stop
```
