#!/bin/bash
set +euo pipefail

# Install apt-get packages 
export DEBIAN_FRONTEND=noninteractive
printf "\nInstall ansible in python virtual environment\n"
apt-get update &>/dev/null
apt-get install -y python3-venv
python3 -m venv --system-site-packages ~/venv
. ~/venv/bin/activate
python3 -m pip install ansible

cat << EOF

Run the following commands to setup the environment with Ansible:

. ~/venv/bin/activate
ansible-playbook -l localhost playbook.yml

After succesfull completion of the playbook, to deactivate the python virtual environment run the following command:

deactivate

You can also (optionally) delete ~/venv if the playbook runs succesfully.

EOF

