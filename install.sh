#!/bin/bash

# Copyright (c) 2015 Carnegie Mellon University. All Rights Reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:

# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following acknowledgments
# and disclaimers.

# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.

# 3. The names "Carnegie Mellon University," "SEI" and/or "Software
# Engineering Institute" shall not be used to endorse or promote
# products derived from this software without prior written
# permission. For written permission, please contact
# permission@sei.cmu.edu.

# 4. Products derived from this software may not be called "SEI" nor
# may "SEI" appear in their names without prior written permission of
# permission@sei.cmu.edu.

# 5. Redistributions of any form whatsoever must retain the following
# acknowledgment:

# Copyright 2015 Carnegie Mellon University

# This material is based upon work funded and supported by the
# Department of Defense under Contract No. FA8721-05-C-0003 with
# Carnegie Mellon University for the operation of the Software
# Engineering Institute, a federally funded research and development
# center.

# Any opinions, findings and conclusions or recommendations expressed
# in this material are those of the author(s) and do not necessarily
# reflect the views of the United States Department of Defense.

# NO WARRANTY. THIS CARNEGIE MELLON UNIVERSITY AND SOFTWARE
# ENGINEERING INSTITUTE MATERIAL IS FURNISHED ON AN "AS-IS"
# BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, AS TO ANY MATTER INCLUDING, BUT NOT
# LIMITED TO, WARRANTY OF FITNESS FOR PURPOSE OR MERCHANTABILITY,
# EXCLUSIVITY, OR RESULTS OBTAINED FROM USE OF THE MATERIAL. CARNEGIE
# MELLON UNIVERSITY DOES NOT MAKE ANY WARRANTY OF ANY KIND WITH
# RESPECT TO FREEDOM FROM PATENT, TRADEMARK, OR COPYRIGHT
# INFRINGEMENT.

# This material has been approved for public release and unlimited
# distribution.

# DM-0002489

#check command line options
if [ "$#" == "2" ] && [ "$1" != "-mzsrm" ]; then
    MZSRM="0"
    ROOT="$1"
    VERSION="$2"
elif [ "$#" == "3" ] && [ "$1" == "-mzsrm" ]; then
    MZSRM="1"
    ROOT="$2"
    VERSION="$3"
else
    echo "Usage : $0 [-mzsrm] <install-dir> <version>"
    exit 1
fi

#check legal version
if [ "$VERSION" != "0.1" ] && [ "$VERSION" != "0.2.1" ] && [ "$VERSION" != "0.2.2" ] && \
       [ "$VERSION" != "0.2.3" ]; then
    echo "ERROR : Illegal version $VERSION ..."
    echo "ERROR : Version must be 0.1 or 0.2.1 or 0.2.2 or 0.2.3 ..."
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
    sudo apt-get install perl git build-essential subversion libboost-all-dev bison flex realpath cbmc tk xvfb libyaml-cpp-dev ant

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
        git clone -b dart-$VERSION git://git.code.sf.net/p/madara/code $ROOT/madara 2>&1 | tee -a $LOG
        cd $MADARA_ROOT
        perl $ACE_ROOT/bin/mwc.pl -type gnuace MADARA.mwc 2>&1 | tee -a $LOG
        echo "Compiling MADARA ..." | tee -a $LOG
        make tests=1 2>&1 | tee -a $LOG
    fi
}

function install_vrep {
    export VREP_ROOT=$ROOT/vrep
    VREP_PKG=V-REP_PRO_EDU_V3_2_2_64_Linux.tar.gz
    if [ -d $ROOT/vrep ]; then
        echo "VREP is already installed at $ROOT/vrep ..." | tee -a $LOG
    else
        echo "Installing V-REP ..." | tee -a $LOG
        cd $ROOT
        if [ -f /tmp/$VREP_PKG ]; then
            cp /tmp/$VREP_PKG .
        else
            wget http://coppeliarobotics.com/$VREP_PKG
        fi
        echo "Unpacking V-REP ..." | tee -a $LOG
        mkdir vrep
        tar xfz $VREP_PKG -C vrep  --strip-components 1
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
        git clone -b dart-$VERSION https://github.com/jredmondson/gams.git gams 2>&1 | tee -a $LOG
        cd $GAMS_ROOT
        mwc.pl -features vrep=1 -type gnuace gams.mwc 2>&1 | tee -a $LOG
        echo "Compiling GAMS ..." | tee -a $LOG
        make tests=1 vrep=1 2>&1 | tee -a $LOG
    fi
}

function install_mzsrm {
    if [ "$MZSRM" == "1" ]; then
        export MZSRM_ROOT=$ROOT/mzsrm
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
        git clone -b release-$VERSION https://github.com/cps-sei/dmplc.git
        cd $DMPL_ROOT
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
export DMPL_ROOT=$ROOT/dmplc
export PATH=\$DMPL_ROOT/src/dmplc:\$PATH
export PATH=\$DMPL_ROOT/src/vrep:\$PATH
EOF
    if [ "$MZSRM" == "1" ]; then
    cat <<EOF >> $ROOT/setenv.sh
export MZSRM_ROOT=$ROOT/mzsrm
EOF
    fi
}

(create_install_dir && install_packages && install_ace && install_madara && install_vrep && install_gams && install_mzsrm && install_dmplc && create_setenv) || cleanup

echo "##################################################" | tee -a $LOG
echo "Installation Complete!! Check $LOG for details." | tee -a $LOG
echo "environment variables are in $ROOT/setenv.sh" | tee -a $LOG
echo "you should append the contents of this file to your .bashrc" | tee -a $LOG
echo "alternatively, source this file before running any DART commands" | tee -a $LOG
echo "##################################################" | tee -a $LOG
