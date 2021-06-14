#!/bin/bash
set -e

echo "Installing aide-qc..."
git clone --quiet https://github.com/aide-qc/aide-qc $HOME/.aideqc_tmp >/dev/null 
cd $HOME/.aideqc_tmp
python3 -m pip install --quiet --user . 
echo "Installation successful."
if ! [ -x "$(command -v aide-qc)" ]; then
   export p=$(python3 -m site --user-base)/bin
   echo ""
   echo "Install location ($p) is not on your PATH."
   echo "You must run the command below to use aide-qc."
   echo "To make it permanant (suggested)"
   echo "add the command to your bash profile (.bashrc, .bash_profile, .profile, etc.)."
   echo ""
   echo "export PATH=\$PATH:$(python3 -m site --user-base)/bin"
   echo ""
fi 
rm -rf $HOME/.aideqc_tmp 