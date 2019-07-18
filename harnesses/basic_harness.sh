#!/bin/sh
#------------------------------------------------------------------
# November 2014, created within ASIG
# Author James Spadaro (jaspadar)
# Co-Author Lilith Wyatt (liwyatt)
#------------------------------------------------------------------
# Copyright (c) 2014-2017 by Cisco Systems, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the Cisco Systems, Inc. nor the
#    names of its contributors may be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#------------------------------------------------------------------

target=$1
args=$2
if [ -z "$target" ] ; then
    echo "Usage: $0 \"<cmdline args for proc to run>\""
    exit
fi

sample_cmds="
#----sample harness_cmds.txt----\n
set pagination off\n
set follow-fork-mode child\n
handle SIGPIPE nostop noprint pass\n
handle SIGSTOP nostop noprint pass\n
run\n
############\n
# Cmd to run after crash\n
info reg\n
bt\n
x/4i \$pc\n
############\n
quit\n
"

dir="harness_logs"
mkdir $dir 2>/dev/null

if [ ! -f ./harness_cmds.txt ]; then
    echo $sample_cmds > ./harness_cmds.txt
fi

# break on ctrl-c
trap break_loop INT

break_loop() {
    echo "[^_^] Exiting basic harness"
    exit
}

while true; do
	gdb -x harness_cmds.txt --args $args 2>&1 | tee $dir/harness.log || echo "No target? ($args)"; sleep 2 
    grep "SIGSEGV" $dir/harness.log && mv $dir/harness.log "$dir/harness.log.`date`"
    grep "SIGABRT" $dir/harness.log && mv $dir/harness.log "$dir/harness.log.`date`"
    grep "ERROR: AddressSanitizer" $dir/harness.log && mv $dir/harness.log "$dir/harness.log.`date`"

done
