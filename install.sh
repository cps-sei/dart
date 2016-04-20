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

DEF_VERSION="0.3.0"
VERSION=$DEF_VERSION
MZSRM="0"
ROOT=""

#print usage
function usage {
    echo "Usage : install.sh [-args] <install-dir>"
    echo "  Optional Arguments:"
    echo "    -mz | --mzsrm       Install MZSRM scheduler and analysis"
    echo "    -v  | --version V   Install version V (default $DEF_VERSION)."
}

#parse command line options
argc=0
while true; do
    case "$1" in
        -mz|--mzsrm)
            MZSRM=1
            ;;
        -v|--version)
            shift
            VERSION="$1"
            if [ -z $VERSION ]; then
                echo "ERROR: No version specified after -v|--version!!"; usage; exit 1
            fi
            ;;
        "")
            break
            ;;
        *)
            case "$argc" in
                0)
                    ROOT="$1"
                    ;;
                *)
                    echo Unexpected argument: $1
                    usage
                    exit 1
            esac
            argc=$((argc+1))
            ;;
    esac
    shift
done

#check install dir
[ -z "$ROOT" ] && echo "ERROR: no install dir specified!!" && usage && exit 1

#check if the specified version is legal
VALID_VERSIONS="0.1 0.2.1 0.2.2 0.2.3 0.3.0"
function valid_version {
    for i in $VALID_VERSIONS; do
        if [ "$i" == "$1" ]; then
            echo 1
            return
        fi
    done
    echo 0
}

#check legal version
if [ $(valid_version $VERSION) == "0" ]; then
    echo "ERROR : Illegal version $VERSION ..."
    echo "ERROR : Version must one of { $VALID_VERSIONS }"
    usage
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
SETENV=$ROOT/setenv.sh
rm -f $SETENV

#create installation directory
function create_install_dir {
    if [ ! -d $ROOT ]; then
        rm -fr $ROOT
        mkdir $ROOT
    fi
}

#required packages
PKGS="perl git build-essential subversion libboost-all-dev bison flex realpath tk xvfb libyaml-cpp-dev"

#check for package binaries. if not found, add them to packages to be
#installed
function check_package_bin {
    local PKG="$1"
    local PKG_BIN=$(which $PKG)
    if [[ "$?" == "0" ]]; then
        echo "$PKG found : $PKG_BIN"
    else
        PKGS+=" $PKG"
    fi
}

#install packages
function install_packages {
    echo "Checking packages ..." | tee -a $LOG

    #check for binaries
    for i in cbmc ant; do check_package_bin $i; done
    
    NOT_FOUND=""
    for i in $PKGS; do
        if ! dpkg -l $i &> /dev/null; then
            NOT_FOUND+=" $i"
        fi
    done
    if [ "x$NOT_FOUND" != "x" ]; then
        echo "ERROR: please install packages:$NOT_FOUND" | tee -a $LOG
        echo "e.g., run sudo apt-get install$NOT_FOUND" | tee -a $LOG
        return 1
    fi

    if [ "$MZSRM" == "1" ]; then
        echo "Checking Java ..." | tee -a $LOG
        PKG="openjdk-7-jdk"
        if ! dpkg -l $PKG &> /dev/null; then
            echo "ERROR: please install packages: $PKG" | tee -a $LOG
            echo "e.g., run sudo apt-get install $PKG" | tee -a $LOG
            return 1
        fi
        export JAVA_ROOT=/usr/lib/jvm/java-7-openjdk-amd64
        export LD_LIBRARY_PATH=$JAVA_ROOT/jre/lib/amd64/server:$LD_LIBRARY_PATH
    fi
}

function install_ace {
    export ACE_DIR=$ROOT/ace
    export ACE_ROOT=$ACE_DIR/ACE_wrappers
    export MADARA_ROOT=$ROOT/madara
    export LD_LIBRARY_PATH=$ACE_ROOT/lib:$MADARA_ROOT/lib:$LD_LIBRARY_PATH
    export PATH=$ACE_ROOT/bin:$MADARA_ROOT/bin:$PATH        
    if [ -d $ACE_DIR ]; then
        echo "ACE is already installed at $ACE_DIR ..." | tee -a $LOG
    else
        echo "Installing ACE ..." | tee -a $LOG
        mkdir $ACE_DIR
        echo "Checking out and configuring ACE ..." | tee -a $LOG
        svn checkout svn://svn.dre.vanderbilt.edu/DOC/Middleware/sets-anon/ACE $ACE_DIR 2>&1 | tee -a $LOG
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
    if [ -d $MADARA_ROOT ]; then
        echo "MADARA is already installed at $MADARA_ROOT ..." | tee -a $LOG
    else
        echo "Installing MADARA ..." | tee -a $LOG
        mkdir $MADARA_ROOT
        echo "Checking out and configuring MADARA ..." | tee -a $LOG
        git clone -b dart-$VERSION http://git.code.sf.net/p/madara/code $MADARA_ROOT 2>&1 | tee -a $LOG
        cd $MADARA_ROOT
        perl $ACE_ROOT/bin/mwc.pl -type gnuace MADARA.mwc 2>&1 | tee -a $LOG
        echo "Compiling MADARA ..." | tee -a $LOG
        make tests=1 2>&1 | tee -a $LOG
    fi
}

function install_vrep {
    export VREP_ROOT=$ROOT/vrep
    VREP_PKG=V-REP_PRO_EDU_V3_3_0_64_Linux.tar.gz
    if [ -d $VREP_ROOT ]; then
        echo "VREP is already installed at $VREP_ROOT ..." | tee -a $LOG
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
        if [ -f vrep/system/usrset.txt ]; then
            for i in doNotShowOpenglSettingsMessage doNotShowCrashRecoveryMessage doNotShowUpdateCheckMessage; do
                cat vrep/system/usrset.txt | sed "s/$i = false/$i = true/g" > vrep/system/usrset.txt1
                mv vrep/system/usrset.txt1 vrep/system/usrset.txt
            done
        else
            for i in doNotShowOpenglSettingsMessage doNotShowCrashRecoveryMessage doNotShowUpdateCheckMessage; do
                echo "$i = true" >> vrep/system/usrset.txt
            done
        fi
    fi
}

function install_gams {
    export GAMS_ROOT=$ROOT/gams
    export LD_LIBRARY_PATH=$GAMS_ROOT/lib:$LD_LIBRARY_PATH
    export PATH=$GAMS_ROOT/bin:$PATH
    if [ -d $GAMS_ROOT ]; then
        echo "GAMS is already installed at $GAMS_ROOT ..." | tee -a $LOG
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
        if [ -d $MZSRM_ROOT ]; then
            echo "MZSRM scheduler is already installed at $MZSRM_ROOT ..." | tee -a $LOG
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
    if [ -d $DMPL_ROOT ]; then
        echo "DMPLC is already installed at $DMPL_ROOT ..." | tee -a $LOG
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
    cat <<EOF > $SETENV
export ACE_ROOT=$ACE_DIR/ACE_wrappers
export MADARA_ROOT=$MADARA_ROOT 
export LD_LIBRARY_PATH=\$ACE_ROOT/lib:\$MADARA_ROOT/lib:\$LD_LIBRARY_PATH
export PATH=\$ACE_ROOT/bin:\$MADARA_ROOT/bin:\$PATH
export JAVA_ROOT=/usr/lib/jvm/java-7-openjdk-amd64
export LD_LIBRARY_PATH=\$JAVA_ROOT/jre/lib/amd64/server:\$LD_LIBRARY_PATH
export VREP_ROOT=$VREP_ROOT
export GAMS_ROOT=$GAMS_ROOT
export LD_LIBRARY_PATH=\$GAMS_ROOT/lib:\$LD_LIBRARY_PATH
export PATH=\$GAMS_ROOT/bin:\$PATH
export DMPL_ROOT=$DMPL_ROOT
export PATH=\$DMPL_ROOT/src/dmplc:\$PATH
export PATH=\$DMPL_ROOT/src/vrep:\$PATH
EOF
    if [ "$MZSRM" == "1" ]; then
    cat <<EOF >> $SETENV
export MZSRM_ROOT=$MZSRM_ROOT
EOF
    fi
}

(create_install_dir && install_packages && install_ace && install_madara && install_vrep && install_gams && install_mzsrm && install_dmplc && create_setenv) || cleanup

echo "##################################################" | tee -a $LOG
echo "Installation Complete!! Check $LOG for details." | tee -a $LOG
echo "environment variables are in $SETENV" | tee -a $LOG
echo "you should append the contents of this file to your .bashrc" | tee -a $LOG
echo "alternatively, source this file before running any DART commands" | tee -a $LOG
echo "##################################################" | tee -a $LOG
