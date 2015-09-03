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
MZSRM="0"
if [ "$#" == "1" ]; then
    ROOT="$1"
else
    echo "Usage : $0 <install-dir>"
    exit 1
fi

function cleanup {
    echo ""; echo ""; echo "###############################################"
    echo "ERROR: something went wrong !! Check $LOG for details!!"
    echo "For a fresh install, run the following command:"
    echo "rm -fr $ROOT && $0 $ROOT"
    exit 1
}

trap "cleanup" SIGINT SIGTERM SIGHUP

LOG=$ROOT/install.log
rm -f $LOG

function create_install_dir {
    if [ ! -d $ROOT ]; then
        rm -fr $ROOT
        mkdir -p $ROOT
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
        echo "Downloading DMPLC ..." | tee -a $LOG
        wget https://dl.dropboxusercontent.com/u/83609895/dmplc.tgz | tee -a $LOG
        echo "Unpacking DMPLC ..." | tee -a $LOG
        tar xfz dmplc.tgz | tee -a $LOG
        chmod u+x $DMPL_ROOT/src/dmplc/dmplc
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
}

(create_install_dir && install_dmplc && create_setenv) || cleanup

echo "##################################################" | tee -a $LOG
echo "Installation Complete!! Check $LOG for details." | tee -a $LOG
echo "environment variables are in $ROOT/setenv.sh" | tee -a $LOG
echo "you should append the contents of this file to your .bashrc" | tee -a $LOG
echo "alternatively, source this file before running any DART commands" | tee -a $LOG
echo "##################################################" | tee -a $LOG
