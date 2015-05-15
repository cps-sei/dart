#!/bin/bash

#check command line options
if [ "$#" == "1" ] && [ "$1" != "-mzsrm" ]; then
    MZSRM="0"
    ROOT="$1"
elif [ "$#" == "2" ] && [ "$1" == "-mzsrm" ]; then
    MZSRM="1"
    ROOT="$2"
else
    echo "Usage : $0 [-mzsrm] <install-dir>"
    exit 1
fi

function cleanup {
    echo ""; echo ""; echo "###############################################"
    echo "ERROR: something went wrong !! Check $LOG for details!!"
    echo "For a fresh install, run the following command:"
    if [ "$MZSRM" == "1" ]; then
        echo "rm -fr $ROOT && $0 -mzsrm $ROOT"
    else
        echo "rm -fr $ROOT && $0 $ROOT"
    fi
    exit 1
}

trap "cleanup" SIGINT SIGTERM SIGHUP

LOG=$ROOT/install.log
rm -f $LOG

function create_install_dir {
    if [ ! -d $ROOT ]; then
        rm -fr $ROOT
        mkdir $ROOT
    fi
}

function install_packages {
    echo "Installing packages ..." | tee -a $LOG
    sudo apt-get install perl git build-essential subversion libboost-all-dev bison flex realpath cbmc tk xvfb

    if [ "$MZSRM" == "1" ]; then
        echo "Installing Java ..." | tee -a $LOG
        sudo apt-get install openjdk-7-jdk
        export JAVA_ROOT=/usr/lib/jvm/java-7-openjdk-amd64
        export LD_LIBRARY_PATH=$JAVA_ROOT/jre/lib/amd64/server:$LD_LIBRARY_PATH
    fi
}

function install_ace {
    export ACE_ROOT=$ROOT/ace/ACE_wrappers
    export MADARA_ROOT=$ROOT/madara
    export LD_LIBRARY_PATH=$ACE_ROOT/lib:$MADARA_ROOT/lib:$LD_LIBRARY_PATH
    export PATH=$ACE_ROOT/bin:$MADARA_ROOT/bin:$PATH        
    if [ -d $ROOT/ace ]; then
        echo "ACE is already installed at $ROOT/ace ..." | tee -a $LOG
    else
        echo "Installing ACE ..." | tee -a $LOG
        mkdir $ROOT/ace
        echo "Checking out and configuring ACE ..." | tee -a $LOG
        svn checkout svn://svn.dre.vanderbilt.edu/DOC/Middleware/sets-anon/ACE $ROOT/ace 2>&1 | tee -a $LOG
        cd $ACE_ROOT/ace
        echo "#include \"ace/config-linux.h\"" > config.h
        cd $ACE_ROOT/include/makeinclude
        echo "include \$(ACE_ROOT)/include/makeinclude/platform_linux.GNU" > platform_macros.GNU
        cd $ACE_ROOT/ace
        perl $ACE_ROOT/bin/mwc.pl -type gnuace ace.mwc 2>&1 | tee -a $LOG
        echo "Compiling ACE ..." | tee -a $LOG
        make 2>&1 | tee -a $LOG
    fi
}

function install_madara {
    if [ -d $ROOT/madara ]; then
        echo "MADARA is already installed at $ROOT/madara ..." | tee -a $LOG
    else
        echo "Installing MADARA ..." | tee -a $LOG
        mkdir $ROOT/madara
        echo "Checking out and configuring MADARA ..." | tee -a $LOG
        git clone git://git.code.sf.net/p/madara/code $ROOT/madara 2>&1 | tee -a $LOG
        cd $MADARA_ROOT
        git checkout dart 2>&1 | tee -a $LOG
        perl $ACE_ROOT/bin/mwc.pl -type gnuace MADARA.mwc 2>&1 | tee -a $LOG
        echo "Compiling MADARA ..." | tee -a $LOG
        make tests=1 2>&1 | tee -a $LOG
    fi
}

function install_vrep {
    export VREP_ROOT=$ROOT/vrep
    if [ -d $ROOT/vrep ]; then
        echo "VREP is already installed at $ROOT/vrep ..." | tee -a $LOG
    else
        echo "Installing V-REP ..." | tee -a $LOG
        cd $ROOT
        if [ -f /tmp/V-REP_PRO_EDU_V3_1_3_rev2b_64_Linux.tar.gz ]; then
            cp /tmp/V-REP_PRO_EDU_V3_1_3_rev2b_64_Linux.tar.gz .
        else
            wget http://coppeliarobotics.com/V-REP_PRO_EDU_V3_1_3_rev2b_64_Linux.tar.gz
        fi
        echo "Unpacking V-REP ..." | tee -a $LOG
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
        echo "GAMS is already installed at $ROOT/gams ..." | tee -a $LOG
    else
        echo "Installing GAMS ..." | tee -a $LOG
        cd $ROOT
        echo "Checking out and configuring GAMS ..." | tee -a $LOG
        git clone https://github.com/jredmondson/gams.git gams 2>&1 | tee -a $LOG
        cd $GAMS_ROOT
        git checkout dart 2>&1 | tee -a $LOG
        mwc.pl -features vrep=1 -type gnuace gams.mwc 2>&1 | tee -a $LOG
        echo "Compiling GAMS ..." | tee -a $LOG
        make tests=1 vrep=1 2>&1 | tee -a $LOG
    fi
}

function install_mzsrm {
    export MZSRM_ROOT=$ROOT/mzsrm
    if [ "$MZSRM" == "1" ]; then
        if [ -d $ROOT/mzsrm ]; then
            echo "MZSRM scheduler is already installed at $ROOT/mzsrm ..." | tee -a $LOG
        else
            echo "Installing MZSRM Scheduler ..." | tee -a $LOG
            cd $ROOT
            echo "Checking out MZSRM Scheduler ..." | tee -a $LOG
            git clone https://github.com/cps-sei/mzsrm.git mzsrm 2>&1 | tee -a $LOG
            echo "Compiling MZSRM ..." | tee -a $LOG
            cd $MZSRM_ROOT && make 2>&1 | tee -a $LOG
        fi
    fi
}

function install_dmplc {
    export DMPL_ROOT=$ROOT/dmplc
    export PATH=$DMPL_ROOT/src/dmplc:$PATH
    export PATH=$DMPL_ROOT/src/vrep:$PATH
    if [ -d $ROOT/dmplc ]; then
        echo "DMPLC is already installed at $ROOT/dmplc ..." | tee -a $LOG
    else
        echo "Installing DMPLC ..." | tee -a $LOG
        cd $ROOT
        echo "Checking out DMPLC ..." | tee -a $LOG
        git clone schaki@linux.andrew.cmu.edu:/afs/andrew.cmu.edu/usr12/schaki/git-repos/dmplc.git
        cd $DMPL_ROOT
        git checkout stable 2>&1 | tee -a $LOG
        echo "Compiling DMPLC ..." | tee -a $LOG
        make MZSRM=$MZSRM 2>&1 | tee -a $LOG
    fi
}

function create_setenv {
    echo "Creating file with commands to set environment variables ..." | tee -a $LOG
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

(create_install_dir && install_packages && install_ace && install_madara && install_vrep && install_gams && install_mzsrm && install_dmplc && create_setenv) || cleanup

echo "##################################################" | tee -a $LOG
echo "Installation Complete!! Check $LOG for details." | tee -a $LOG
echo "environment variables are in $ROOT/setenv.sh" | tee -a $LOG
echo "you should append the contents of this file to your .bashrc" | tee -a $LOG
echo "alternatively, source this file before running any DART commands" | tee -a $LOG
echo "##################################################" | tee -a $LOG
