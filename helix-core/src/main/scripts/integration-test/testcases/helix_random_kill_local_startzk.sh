#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

# test that we can kill/restart mock participant remotely
export TEST_NAME=helix_random_kill_local_startzk
source setup_env.inc

# users/machines/dirs info for each test machine
# USER_TAB=( "zzhang" "zzhang" "zzhang" "zzhang" )
MACHINE_TAB=( "localhost" )
# SCRIPT_DIR_TAB=( "/export/home/zzhang/workspace/helix/helix-core/src/main/scripts/integration-test/script" "/export/home/zzhang/workspace/helix/helix-core/src/main/scripts/integration-test/script" "/export/home/zzhang/workspace/helix/helix-core/src/main/scripts/integration-test/script" "/export/home/zzhang/workspace/helix/helix-core/src/main/scripts/integration-test/script" )
SCRIPT_DIR_TAB=( "../script" )

# constants
machine_nb=${#MACHINE_TAB[*]}
controller_idx=0
mocks_per_node=10

# colorful echo
red='\e[00;31m'
green='\e[00;32m'
function cecho
{
  message="$1"
  if [ -n "$message" ]; then
    color="$2"
    if [ -z "$color" ]; then
      echo "$message"
    else
      echo -e "$color$message\e[00m"
    fi
  fi
}

# zookeeper_server_ports="localhost:2188"
# use the first machine as zookeeper and controller
# zookeeper_address=${MACHINE_TAB[0]}:2191
# zookeeper_address=eat1-app207.stg:12913,eat1-app208.stg:12913,eat1-app209.stg:12913
# zookeeper_address=localhost:2181,localhost:2182,localhost:2183
zookeeper_address=localhost:2187

# default datadir integration_test/var/work/zookeeper/data/1
# start the zookeeper cluster
# for i in `seq 0 2`; do
# ssh ${USER_TAB[$i]}@${MACHINE_TAB[$i]} "${SCRIPT_DIR_TAB[$i]}/cm_driver.py -n ${TEST_NAME} -c zookeeper -o start --zookeeper_reset --zookeeper_server_ports=\"$zookeeper_address\" --zookeeper_server_ids=$i --cmdline_props=\"tickTime=2000;initLimit=5;syncLimit=2\""
# done
${SCRIPT_DIR_TAB[0]}/cm_driver.py -n ${TEST_NAME} -c zookeeper -o start --zookeeper_reset --zookeeper_server_ports=$zookeeper_address --cmdline_props="tickTime=2000;initLimit=5;syncLimit=2"

#read ch
#${SCRIPT_DIR_TAB[0]}/cm_driver.py -n ${TEST_NAME} -c zookeeper -o stop
#exit





test_timestamps_file=$VIEW_ROOT/$LOG_DIR_FROM_ROOT/test_timestamps_`date +"%y%m%d_%H%M%S"`.log
#echo `date +"%y%m%d_%H%M%S_%N"` >> ${test_timestamps_file}
test_start_time=`date +"%y%m%d_%H%M%S_%N"`

# drop cluster
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} -dropCluster test-cluster"

# create cluster
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} -addCluster test-cluster"

# enable healthCheck
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --setConfig CLUSTER=test-cluster healthChange.enabled=true"

# set thread pool size to 40
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --setConfig CLUSTER=test-cluster,RESOURCE=test-db maxThreads=40"

# add alerts
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MeanMysqlLatency))CMP(GREATER)CON(2.132700625)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MinLuceneLatency))CMP(GREATER)CON(1.765905)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MaxServerLatency))CMP(GREATER)CON(167.714205)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MeanLuceneLatency))CMP(GREATER)CON(16.107599458333335)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MeanLucenePoolLatency))CMP(GREATER)CON(8.120545333333335)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MinServerLatency))CMP(GREATER)CON(0.425275)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.IndexStoreMismatchCount))CMP(GREATER)CON(5)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.ErrorCount))CMP(GREATER)CON(5)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MeanMysqlPoolLatency))CMP(GREATER)CON(1.0704102916666665)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MinLucenePoolLatency))CMP(GREATER)CON(0.008185)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MinMysqlLatency))CMP(GREATER)CON(0.709695)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MaxMysqlPoolLatency))CMP(GREATER)CON(8.606975)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MinMysqlPoolLatency))CMP(GREATER)CON(0.091885)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MaxLucenePoolLatency))CMP(GREATER)CON(65.930565)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MaxMysqlLatency))CMP(GREATER)CON(9.369825)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.TimeStamp))CMP(GREATER)CON(1332895048145)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MeanConcurrencyLevel))CMP(GREATER)CON(1.5)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.QueryStartCount))CMP(GREATER)CON(5)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MeanServerLatency))CMP(GREATER)CON(39.5451535)\""
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} --addAlert test-cluster \"EXP(decay(1.0)(*.MockRestQueryStats@DBName=BizProfile.MaxLuceneLatency))CMP(GREATER)CON(111.78795)\""


# add resource
#$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} -addResource test-cluster test-db 2400 MasterSlave"

$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} -addResource test-cluster test-db 1200 MasterSlave"


# add nodes
start_port=8900
for j in `seq 0 $(($machine_nb-1))`; do
	for i in `seq 1 $mocks_per_node`; do
  	port=$(($start_port + $i))
		$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} -addNode test-cluster ${MACHINE_TAB[$j]}:${port}"
	done
done

# rebalance
$SCRIPT_DIR/cm_driver.py -c clm_console --cmdline_args="-zkSvr ${zookeeper_address} -rebalance test-cluster test-db 3"

# Launch mock health report process
# for j in {0..1}; do
for j in `seq 0 $(($machine_nb-1))`; do
	for i in `seq 1 $mocks_per_node`; do
  	port=$(($start_port + $i))
#  ssh ${USER_TAB[$j]}@${MACHINE_TAB[$j]} "${SCRIPT_DIR_TAB[$j]}/cm_driver.py -n ${TEST_NAME} -c mock-health-report-process -o start -l \"integration-test/config/log4j-info.properties\" --save_process_id --component_id=$i --cmdline_args=\"-zkSvr ${zookeeper_address} -cluster test-cluster -host ${MACHINE_TAB[$j]} -port ${port}\""
  ${SCRIPT_DIR_TAB[$j]}/cm_driver.py -n ${TEST_NAME} -c mock-health-report-process -o start --jvm_args="" -l "integration-test/config/log4j-info.properties" --save_process_id --component_id=$i --cmdline_args="-zkSvr ${zookeeper_address} -cluster test-cluster -host ${MACHINE_TAB[$j]} -port ${port}"
	done
done


#sleep 10

# Launch cluster manager
# -Djava.rmi.server.hostname=${MACHINE_TAB[$controller_idx]}
# ssh ${USER_TAB[$controller_idx]}@${MACHINE_TAB[$controller_idx]} "${SCRIPT_DIR_TAB[$controller_idx]}/cm_driver.py -n ${TEST_NAME} -c cluster-manager -o start --jvm_args=\"-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.port=27960 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false\" -l \"integration-test/config/log4j-info.properties\" --cmdline_args=\"-zkSvr ${zookeeper_address} -cluster test-cluster\""

# ${SCRIPT_DIR_TAB[$controller_idx]}/cm_driver.py -n ${TEST_NAME} -c cluster-manager -o start --jvm_args="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.port=27960 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false" -l "integration-test/config/log4j-info.properties" --cmdline_args="-zkSvr ${zookeeper_address} -cluster test-cluster"

# sleep 3


# record the start timestamp of the test
# echo `date +"%y%m%d_%H%M%S_%N"` >> ${test_timestamps_file}

# Launch cluster manager
# -Djava.rmi.server.hostname=${MACHINE_TAB[$controller_idx]}
# ssh ${USER_TAB[$controller_idx]}@${MACHINE_TAB[$controller_idx]} "${SCRIPT_DIR_TAB[$controller_idx]}/cm_driver.py -n ${TEST_NAME} -c cluster-manager -o start --jvm_args=\"-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.port=27960 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false\" -l \"integration-test/config/log4j-info.properties\" --cmdline_args=\"-zkSvr ${zookeeper_address} -cluster test-cluster\""

${SCRIPT_DIR_TAB[$controller_idx]}/cm_driver.py -n ${TEST_NAME} -c cluster-manager -o start --jvm_args="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.port=27980 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false" -l "integration-test/config/log4j-info.properties" --cmdline_args="-zkSvr ${zookeeper_address} -cluster test-cluster"

#verify cluster state
verifier_output=$VIEW_ROOT/$LOG_DIR_FROM_ROOT/verifier_`date +"%y%m%d_%H%M%S"`.log

#$SCRIPT_DIR/cm_driver.py -n ${TEST_NAME} -c cluster-state-verifier -o start --logfile=$verifier_output -l "integration-test/config/log4j-info.properties" --cmdline_args="-zkSvr ${zookeeper_address} -cluster test-cluster -timeout 1200000"
echo "verify cluster here------------"
$SCRIPT_DIR/cm_driver.py -n ${TEST_NAME} -c cluster-state-verifier -o start --logfile=$verifier_output -l "integration-test/config/log4j-info.properties" --cmdline_args="-zkSvr ${zookeeper_address} -cluster test-cluster -timeout 240000"

echo "verifier_output=$verifier_output"
verifier_result=`grep 'Successful\|fail' $verifier_output`
cecho "$verifier_result" $red

sleep 5

# kill m random and restart

n=$((${#MACHINE_TAB[*]} * ${mocks_per_node}))
m=1

# do kill m random and restart for r rounds
for r in {0..0}; do
# : <<'END'
  # record the start timestamp of failing
  echo `date +"%y%m%d_%H%M%S_%N"` >> ${test_timestamps_file}

  to_kill=`shuf --input-range=1-$n | head -${m}`
  for k in ${to_kill[*]}; do
    j=$((($k - 1) / $mocks_per_node))
    i=$((($k - 1) % $mocks_per_node + 1))
	  port=$(($start_port + $i))
    cecho "kill ${MACHINE_TAB[$j]}:$port" $red
#	  ssh ${USER_TAB[$j]}@${MACHINE_TAB[$j]} "${SCRIPT_DIR_TAB[$j]}/cm_driver.py -n ${TEST_NAME} -c mock-health-report-process -o stop --component_id=$i"
	  ${SCRIPT_DIR_TAB[$j]}/cm_driver.py -n ${TEST_NAME} -c mock-health-report-process -o stop --component_id=$i
#    sleep 3
  done
#  sleep 10

  # verify cluster state after kill
  verifier_output=$VIEW_ROOT/$LOG_DIR_FROM_ROOT/verifier_`date +"%y%m%d_%H%M%S"`.log
  echo "veirfy cluster here------------"
  $SCRIPT_DIR/cm_driver.py -c cluster-state-verifier -o start --logfile=$verifier_output -l "integration-test/config/log4j-info.properties" --cmdline_args="-zkSvr ${zookeeper_address} -cluster test-cluster -timeout 60000"
  echo "verifier_output=$verifier_output"
  verifier_result=`grep 'Successful\|fail' $verifier_output`
  cecho "$verifier_result" $red
#  sleep 10
# END

: <<'END'
  for k in ${to_kill[*]}; do
    j=$((($k - 1) / 5))
    i=$((($k - 1) % 5 + 1))
  	port=$(($start_port + $i))
    cecho "restart ${MACHINE_TAB[$j]}:$port" $green
  	ssh ${USER_TAB[$j]}@${MACHINE_TAB[$j]} "${SCRIPT_DIR_TAB[$j]}/cm_driver.py -n ${TEST_NAME} -c mock-health-report-process -o start -l \"integration-test/config/log4j-info.properties\" --save_process_id --component_id=$i --cmdline_args=\"-zkSvr ${zookeeper_address} -cluster test-cluster -host ${MACHINE_TAB[$j]} -port ${port}\""
#    sleep 1
  done
#  sleep 3

  #verify cluster state after restart
  verifier_output=$VIEW_ROOT/$LOG_DIR_FROM_ROOT/verifier_`date +"%y%m%d_%H%M%S"`.log
  $SCRIPT_DIR/cm_driver.py -c cluster-state-verifier -o start --logfile=$verifier_output -l "integration-test/config/log4j-info.properties" --cmdline_args="-zkSvr ${zookeeper_address} -cluster test-cluster -timeout 120000"
  echo "verifier_output=$verifier_output"
  verifier_result=`grep 'Successful\|fail' $verifier_output`
  cecho "$verifier_result" $red  
  sleep 10
END

done
# END

# clean up
cecho "clean up..." $green
# sleep 600
# read ch

# ssh ${USER_TAB[$controller_idx]}@${MACHINE_TAB[$controller_idx]} "${SCRIPT_DIR_TAB[$controller_idx]}/cm_driver.py -n ${TEST_NAME} -c cluster-manager -o stop"
${SCRIPT_DIR_TAB[$controller_idx]}/cm_driver.py -n ${TEST_NAME} -c cluster-manager -o stop

#for j in {0..1}; do
for j in `seq 0 $(($machine_nb-1))`; do
	for i in `seq 1 $mocks_per_node`; do
#		ssh ${USER_TAB[$j]}@${MACHINE_TAB[$j]} "${SCRIPT_DIR_TAB[$j]}/cm_driver.py -n ${TEST_NAME} -c mock-health-report-process -o stop --component_id=$i"
		${SCRIPT_DIR_TAB[$j]}/cm_driver.py -n ${TEST_NAME} -c mock-health-report-process -o stop --component_id=$i
	done
done

# for i in {0..2}; do
#  ssh ${USER_TAB[$i]}@${MACHINE_TAB[$i]} "${SCRIPT_DIR_TAB[$i]}/cm_driver.py -n ${TEST_NAME} -c zookeeper -o stop"
# done
${SCRIPT_DIR_TAB[0]}/cm_driver.py -n ${TEST_NAME} -c zookeeper -o stop


# analyze zk log
test_start_time=${test_start_time:0:`expr length "$test_start_time" - 6`}
echo "test_start_time: $test_start_time"
../../../../../target/helix-core-pkg/bin/zk-log-analyzer $VIEW_ROOT/$LOG_DIR_FROM_ROOT/zookeeper_data/0 test-cluster $test_start_time

echo == GREP SUCCEED ==
grep Successful $verifier_output

source report_pass_fail.inc
exit $all_stat


