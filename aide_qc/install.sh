#!/bin/bash
set +x 
export use_brew=false
if [ "$1" == "--use-brew" ]; then
   export use_brew=true
fi

export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=false
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi
echo "$UNAME"
# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" == "" ] && export DISTRO=$UNAME

# if Ubuntu, install lapack
if [ "$DISTRO" == "Ubuntu" ]; then
    sudo apt-get update -y && sudo apt-get install -y wget gnupg lsb-release curl liblapack-dev git gcc g++
    if [ "$use_brew" == "false" ]; then
       wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/PUBLIC-KEY.gpg | sudo apt-key add -
       if [ ! -e "/etc/apt/sources.list.d/aide-qc.list" ]; then
          wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/$(lsb_release -cs)/aide-qc.list" | sudo tee -a /etc/apt/sources.list.d/aide-qc.list
       fi
       sudo apt-get update
       sudo apt-get install -y qcor
       if [ "$?" -eq "0" ]; then
          echo "AIDE-QC installed via apt-get."
          echo ""
          echo ""
          echo "Your XACC and QCOR install location is "
          echo "/usr/local/xacc"
          echo ""
          echo "To use the Python API, please run the following (and add to your .bashrc)"
          echo "export PYTHONPATH=$PYTHONPATH:/usr/local/xacc"
          exit 0
       else
          echo "Could not install via apt-get, will try Homebrew."
          read -p "Would you like to try the Homebrew install?? " -n 1 -r
          echo    # (optional) move to a new line
          if [[ $REPLY =~ ^[Nn]$ ]]
          then
            exit 1
          fi
       fi
    else
       echo "Skipping apt-get install, will try homebrew at user request (--use-brew)."
    fi

elif [[ $DISTRO == "fedora"* ]]; then
    sudo dnf update -y && sudo dnf install -y gcc gcc-c++ lapack-devel git
fi

if ! command -v brew &> /dev/null
then
    echo "Homebrew not found. Installing it now..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# May be possible that brew is not in PATH after install
if ! command -v brew &> /dev/null
then
   if [ "$UNAME" == "darwin" ]; then 
      echo "Could not find brew in PATH, setting up environment for Mac OS X."
      echo 'eval $(/usr/local/bin/brew shellenv)' >> $HOME/.profile
      eval $(/usr/local/bin/brew shellenv)
   else 
      echo "Could not find brew in PATH, setting up homebrew environment for Linux."
      echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> $HOME/.profile
      eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
   fi
fi 

# If we still can't find brew, then we should fail
if ! command -v brew &> /dev/null
then 
   echo "Still unable to locate Homebrew. Install manually, instructions at https://brew.sh"
   exit 1
fi

brew tap aide-qc/deploy
brew install qcor
brew uninstall gcc
python3 -m pip install --user ipopo
echo "AIDE-QC installed via Homebrew."
echo ""
echo ""
echo "Your XACC install location is "
brew --prefix xacc 
echo ""
echo "Your QCOR install location is "
brew --prefix qcor
echo ""
echo "To use the Python API, please run the following (and add to your .bashrc or .bash_profile)"
echo "export PYTHONPATH=$PYTHONPATH:$(brew --prefix xacc):$(brew --prefix qcor)"