#!/bin/bash
set -e
export use_brew=false
if [ "$1" == "--use-brew" ]; then
   export use_brew=true
fi

if [ "$1" == "-qcs" ]; then
    # This is for installing aide-qc stack on 
    # Rigetti QCS JupyterLab IDE. Does not require sudo :)
    
    # pull down llvm and xacc deb packages
    wget https://raw.githubusercontent.com/aide-qc/deploy/master/xacc/debian/focal/xacc-1.0.0.deb    
    wget https://raw.githubusercontent.com/aide-qc/deploy/master/clang_syntax_handler/debian/focal/LLVM-10.0.0git-Linux.deb
    dpkg -x xacc-1.0.0.deb $HOME/.aideqc_install 
    dpkg -x LLVM-10.0.0git-Linux.deb $HOME/.aideqc_install 
    
    python3 -m pip install cmake ipopo qsearch scikit-quant --user 
    export MY_CWD=$PWD
    git clone https://github.com/eclipse/xacc
    cd xacc/quantum/plugins/rigetti/qcs 
    cp ../accelerator/QuilVisitor.hpp .
    mv CMakeLists.standalone.txt CMakeLists.txt
    mkdir tpls && cd tpls

    wget https://dl.bintray.com/boostorg/release/1.74.0/source/boost_1_74_0.tar.gz
    tar -xzvf boost_1_74_0.tar.gz && cd boost_1_74_0
    ./bootstrap.sh --prefix=$HOME/.boost
    ./b2 --with-system --with-chrono install
    cd ..

    # msgpack
    git clone -b cpp_master https://github.com/msgpack/msgpack-c
    cd msgpack-c && mkdir build && cd build
    CC=gcc CXX=g++ cmake .. -DCMAKE_INSTALL_PREFIX=~/.zmq -DBOOST_ROOT=$HOME/.boost
    make -j4 install
    cd ../../

    #cppzmq
    git clone https://github.com/zeromq/cppzmq
    cd cppzmq/ && mkdir build && cd build/
    CC=gcc CXX=g++ cmake .. -DCMAKE_INSTALL_PREFIX=~/.zmq \
                            -DCMAKE_PREFIX_PATH=~/.zmq \
                            -DCPPZMQ_BUILD_TESTS=FALSE
    make -j12 install
    cd ../../

    # qcs
    cd .. && mkdir build && cd build
    CC=gcc CXX=g++ cmake .. -DXACC_DIR=~/.aideqc_install/usr/local/xacc -DBOOST_ROOT=$HOME/.boost
    make -j4 install
    
    cd $MY_CWD && rm -rf xacc
    git clone https://github.com/ornl-qci/qcor
    cd qcor && mkdir build && cd build
    CC=gcc CXX=g++ cmake .. -DLLVM_ROOT=$HOME/.aideqc_install/usr/local/xacc/llvm \
                            -DXACC_DIR=$HOME/.aideqc_install/usr/local/xacc \
                            -DCMAKE_CXX_FLAGS="-D__STDC_FORMAT_MACROS" \
                            -DCMAKE_INSTALL_PREFIX=$HOME/.qcor
    make -j4 install
    cd ../../ && rm -rf qcor *.deb 
    
    echo ""
    echo "AIDE-QC installed on Rigetti QCS."
    echo ""
    echo "Your XACC install location is "
    echo "$HOME/.aideqc_install/usr/local/xacc"
    echo ""
    echo "Your QCOR install location is "
    echo "$HOME/.qcor"
    echo ""
    echo "Export your PATH to include the qcor binary executable location:"
    echo "export PATH=\$PATH:$HOME/.qcor/bin"
    echo ""
    echo "To use the Python API, please run the following (and add to your .bashrc or .bash_profile)"
    echo "export PYTHONPATH=\$PYTHONPATH:$HOME/.aideqc_install/usr/local/xacc:$HOME/.qcor"
    echo ""
    exit 0
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

       # If this is 18.04, then need to install special build-essential with glibc 2.29
       export ubuntu_distro=$(lsb_release -cs)
       if [ $ubuntu_distro == "bionic" ]; then
           sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138
           echo "deb http://ftp.us.debian.org/debian testing main contrib non-free" | sudo tee -a /etc/apt/sources.list
           sudo apt-get update && sudo apt-get install -y build-essential || true
       else
           echo "Ubuntu distro was not bionic, it was $ubuntu_distro"
       fi
    fi

elif [[ $DISTRO == "fedora"* ]]; then
    sudo dnf update -y && sudo dnf install -y gcc gcc-c++ lapack-devel git
fi

if ! command -v brew &> /dev/null
then
    echo "Homebrew not found. Installing it now..."
    CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# May be possible that brew is not in PATH after install
if ! command -v brew &> /dev/null
then
   if [ "$UNAME" == "darwin" ]; then 
      echo "Could not find brew in PATH, setting up environment for Mac OS X."
      echo 'eval $(/usr/local/bin/brew shellenv)' >> $HOME/.bash_profile
      eval $(/usr/local/bin/brew shellenv)
   else 
      echo "Could not find brew in PATH, setting up homebrew environment for Linux."
      echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> $HOME/.bashrc
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
python3 -m pip install --user ipopo cmake qsearch scikit-quant
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
