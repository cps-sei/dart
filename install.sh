#!/bin/bash

if [ "$#" != "1" ]; then
    echo "Usage : $0 <install-dir>"
    exit 1
fi

function cleanup {
    echo "ERROR: something went wrong ... run the following command!!"
    echo "rm -fr $ROOT && $0 $ROOT"
    exit 1
}

trap "cleanup" SIGINT SIGTERM SIGHUP

ROOT="$1"
function create_install_dir {
    if [ ! -d $ROOT ]; then
        rm -fr $ROOT
        mkdir $ROOT
    fi
}

function install_packages {
    echo "Installing packages ..."
    sudo apt-get install perl git build-essential subversion libboost-all-dev bison flex realpath cbmc tk xvfb

    echo "Installing Java ..."
    sudo apt-get install openjdk-7-jdk
    export JAVA_ROOT=/usr/lib/jvm/java-7-openjdk-amd64
    export LD_LIBRARY_PATH=$JAVA_ROOT/jre/lib/amd64/server:$LD_LIBRARY_PATH
}

function install_ace {
    export ACE_ROOT=$ROOT/ace/ACE_wrappers
    export MADARA_ROOT=$ROOT/madara
    export LD_LIBRARY_PATH=$ACE_ROOT/lib:$MADARA_ROOT/lib:$LD_LIBRARY_PATH
    export PATH=$ACE_ROOT/bin:$MADARA_ROOT/bin:$PATH        
    if [ -d $ROOT/ace ]; then
        echo "ACE is already installed at $ROOT/ace ..."
    else
        echo "Installing ACE ..."
        mkdir $ROOT/ace
        svn co svn://svn.dre.vanderbilt.edu/DOC/Middleware/sets-anon/ACE $ROOT/ace
        cd $ACE_ROOT/ace
        echo "#include \"ace/config-linux.h\"" > config.h
        cd $ACE_ROOT/include/makeinclude
        echo "include \$(ACE_ROOT)/include/makeinclude/platform_linux.GNU" > platform_macros.GNU
        cd $ACE_ROOT/ace
        perl $ACE_ROOT/bin/mwc.pl -type gnuace ace.mwc
        echo "Compiling ACE ..."
        make &> /dev/null
    fi
}

function install_madara {
    if [ -d $ROOT/madara ]; then
        echo "MADARA is already installed at $ROOT/madara ..."
    else
        echo "Installing MADARA ..."
        mkdir $ROOT/madara
        git clone git://git.code.sf.net/p/madara/code $ROOT/madara
        cd $MADARA_ROOT
        git checkout dart
        perl $ACE_ROOT/bin/mwc.pl -type gnuace MADARA.mwc
        echo "Compiling MADARA ..."
        make tests=1 &> /dev/null
    fi
}

function install_vrep {
    export VREP_ROOT=$ROOT/vrep
    if [ -d $ROOT/vrep ]; then
        echo "VREP is already installed at $ROOT/vrep ..."
    else
        echo "Installing V-REP ..."
        cd $ROOT
        if [ ! -f V-REP_PRO_EDU_V3_1_3_rev2b_64_Linux.tar.gz ]; then
            wget http://coppeliarobotics.com/V-REP_PRO_EDU_V3_1_3_rev2b_64_Linux.tar.gz
        fi
        echo "Unpacking V-REP ..."
        mkdir vrep
        tar xfz V-REP_PRO_EDU_V3_1_3_rev2b_64_Linux.tar.gz -C vrep  --strip-components 1
        for i in doNotShowOpenglSettingsMessage doNotShowCrashRecoveryMessage doNotShowUpdateCheckMessage; do
            cat vrep/system/usrset.txt | sed "s/$i = false/$i = true/g" > vrep/system/usrset.txt1
            mv vrep/system/usrset.txt1 vrep/system/usrset.txt
        done
    fi
}

function install_gams {
    export GAMS_ROOT=$ROOT/gams
    export LD_LIBRARY_PATH=$GAMS_ROOT/lib:$LD_LIBRARY_PATH
    export PATH=$GAMS_ROOT/bin:$PATH
    if [ -d $ROOT/gams ]; then
        echo "GAMS is already installed at $ROOT/gams ..."
    else
        echo "Installing GAMS ..."
        cd $ROOT
        git clone https://github.com/jredmondson/gams.git gams
        cd $GAMS_ROOT
        git checkout dart
        mwc.pl -features vrep=1 -type gnuace gams.mwc
        echo "Compiling GAMS ..."
        make tests=1 vrep=1 &> /dev/null
    fi
}

function install_mzsrm {
    export MZSRM_ROOT=$ROOT/mzsrm
    if [ -d $ROOT/mzsrm ]; then
        echo "MZSRM scheduler is already installed at $ROOT/mzsrm ..."
    else
        echo "Installing MZSRM Scheduler ..."
        cd $ROOT
        git clone https://github.com/cps-sei/mzsrm.git mzsrm
        echo "Compiling MZSRM ..."
        cd $MZSRM_ROOT && make &> /dev/null
    fi
}

function install_dmplc {
    export DMPL_ROOT=$ROOT/dmplc
    export PATH=$DMPL_ROOT/src/dmplc:$PATH
    export PATH=$DMPL_ROOT/src/vrep:$PATH
    if [ -d $ROOT/dmplc ]; then
        echo "DMPLC is already installed at $ROOT/dmplc ..."
    else
        echo "Installing DMPLC ..."
        cd $ROOT
        git clone schaki@linux.andrew.cmu.edu:/afs/andrew.cmu.edu/usr12/schaki/git-repos/dmplc.git
        cd $DMPL_ROOT
        git checkout stable
        echo "Compiling DMPLC ..."
        make &> /dev/null
    fi
}

function create_setenv {
    echo "Creating file with commands to set environment variables ..."
    cat <<EOF > $ROOT/setenv.sh
export ACE_ROOT=$ROOT/ace/ACE_wrappers
export MADARA_ROOT=$ROOT/madara 
export LD_LIBRARY_PATH=\$ACE_ROOT/lib:\$MADARA_ROOT/lib:\$LD_LIBRARY_PATH
export PATH=\$ACE_ROOT/bin:\$MADARA_ROOT/bin:\$PATH
export JAVA_ROOT=/usr/lib/jvm/java-7-openjdk-amd64
export LD_LIBRARY_PATH=\$JAVA_ROOT/jre/lib/amd64/server:\$LD_LIBRARY_PATH
export VREP_ROOT=$ROOT/vrep
export GAMS_ROOT=$ROOT/gams
export LD_LIBRARY_PATH=\$GAMS_ROOT/lib:\$LD_LIBRARY_PATH
export PATH=\$GAMS_ROOT/bin:\$PATH
export MZSRM_ROOT=$ROOT/mzsrm
export DMPL_ROOT=$ROOT/dmplc
export PATH=\$DMPL_ROOT/src/dmplc:\$PATH
export PATH=\$DMPL_ROOT/src/vrep:\$PATH
EOF
}

(create_install_dir && install_packages && install_ace && install_madara && install_vrep && install_gams && install_mzsrm && intall_dmplc && create_setenv) || cleanup

echo "##################################################"
echo "Installation Complete!!"
echo "environment variables are in $ROOT/setenv.sh"
echo "you should append the contents of this file to your .bashrc"
echo "alternatively, source this file before running any DART commands"
echo "##################################################"
