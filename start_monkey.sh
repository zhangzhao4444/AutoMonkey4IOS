#!/bin/bash

EVENT_TAG="XCTestMonkey"

TagHead() {
echo "=============== $1 ==============="
}

CURRENT_DIR=`dirname $0`
INFO_FILE="${CURRENT_DIR}/config/appinfo.txt"

if [ ! -f "${INFO_FILE}" ]; then
	echo "ERROR: must config info file first. file: ${INFO_FILE}"
	echo "Content as below:"
	echo -e "[\n\t{\n\t\t\"appName\": \"Crasher\",\n\t\t\"bundleId\": \"app.cyan.retriever.xisco\",\n\t\t\"username\": \"\",\n\t\t\"password\": \"\"\n\t}\n]"
	exit 1
fi

UDID=
DEVICE_NAME=
RUN_TIME=60m
LOOP_NUM=2
PORT=8001

usage()
{
	echo ""
	echo "	AutoMonkey4I is used to perform IOS app monkey test automatically with"
	echo "	run time, catch log, loop number"
	echo ""
	echo "	Usage: `basename $0`"
	echo "	       `basename $0` -u <udid> -p <port> -t <run_time> -n <loop_num>"
	echo "	Usage: `basename $0` with options. -u, -t and -n all of them are optional"
	echo ""
	echo "	options:"
	echo "		-u <udid>       the ios device's udid"
	echo "		-p <port>		the port forward"
	echo "		-t <run_time>   the total event count or running time," 
	echo "		                20s means 20 seconds,20m means 20 minutes"
	echo "		-n <loop_num>   the number of loops each application needs to run,"
	echo "		                default value is 2"
	echo "	Sample: $0 -u e55f18280b4f924b7cecca5d180bec93e654f351 -t 20m -n 5"  
	echo ""
	echo "	Furthermore, save packages' infomation to config/appinfo.txt."
	echo "	This script will test it one by one."
}

if [ $# -eq 0 ]; then
	echo "Test with default options"
	UDID=`idevice_id -l | awk 'NR==1{print $1}'`
	DEVICE_NAME=`ideviceinfo -u ${UDID} -k DeviceName`
fi

#option_string以冒号开头表示屏蔽脚本的系统提示错误，自己处理错误提示。
#后面接合法的单字母选项，选项后若有冒号，则表示该选项必须接具体的参数
while getopts :ut:n:p:h OPTION
do
    case $OPTION in
        u)
            UDID=$OPTARG
            if [ -z "${UDID}" ]; then
				usage
				exit 1
			fi
            DEVICE_NAME=`ideviceinfo -u ${UDID} -k DeviceName`
            ;;
        p)
			PORT=$OPTARG
			;;
        t)
            RUN_TIME=$OPTARG
            ;;
        n)
			LOOP_NUM=$OPTARG
			;;
        h)
            usage
            ;;
    esac
done

if [ -z "${UDID}" ]; then
	echo "Test with default udid"
	UDID=`idevice_id -l | awk 'NR==1{print $1}'`
	DEVICE_NAME=`ideviceinfo -u ${UDID} -k DeviceName`
fi

valid_udid=`idevice_id -l |grep ${UDID}`
full_udid=`idevice_id -l |grep -o ${UDID}`

if [ -z "${valid_udid}"  ]; then
	echo "ERROR: You must input right udid with -u option"
	usage
	exit 1
fi

if [ "${valid_udid}" != "${full_udid}" ]; then
	echo "ERROR: You must input the full udid string with -u option"
	usage
	exit 1
fi

if [ -z `echo ${RUN_TIME} | grep -e '^[0-9]*[sSmM]$'` ]; then
	echo "  ERROR: invalid monkey running time ${RUN_TIME}!\n"
	usage
	exit 1
fi

if [ -z `echo $PORT | grep -e '^[0-9]*$'` ]; then
	echo "  ERROR: invalid port ${PORT}!\n"
	usage
	exit 1
fi

if [ -z `echo ${LOOP_NUM} | grep -e '^[0-9]*$'` ]; then
	echo "  ERROR: invalid loop number ${LOOP_NUM}!\n"
	usage
	exit 1
fi

# convert running time to second.
if [ `echo ${RUN_TIME} | grep -e '^[0-9]*[sS]$'` ]; then
	RUN_TIME_IN_SECOND=`echo ${RUN_TIME} | sed -e "s/[sS]$//"`
elif [ `echo ${RUN_TIME} | grep -e '^[0-9]*[mM]$'` ]; then
	RUN_TIME_IN_SECOND=`echo ${RUN_TIME} | sed -e "s/[mM]$//"`
	RUN_TIME_IN_SECOND=$((RUN_TIME_IN_SECOND*60))
fi

echo "RUN_TIME_IN_SECOND=${RUN_TIME_IN_SECOND} LOOP_NUM=${LOOP_NUM} DEVICE_NAME=${DEVICE_NAME} UDID=${UDID}"

# get apps num
jsons=`cat $INFO_FILE | jq .`
apps_num=`echo $jsons|jq length`
echo $apps_num

PROJECT_FOLDER="${CURRENT_DIR}/XCTestWD-master/XCTestWD"
DERIVED_DATA_DIR="${CURRENT_DIR}/tmp_${UDID}"
OUTPUT="${CURRENT_DIR}/output"
RESULT_FILE="result.txt"
XCODE_LOG="${DERIVED_DATA_DIR}/temp_xcode.txt"
XCODE_BUILD_SUCESS="XCTestWDUITests-Runner.app: replacing existing signature"

if [ ! -d "${OUTPUT}" ]; then
	mkdir -p ${OUTPUT}
fi

time_tamp=`date +%Y%m%d%H%M%S`
log_dir="${DEVICE_NAME}_app_${time_tamp}"
log_dir="${OUTPUT}/${log_dir}"
echo $log_dir
if [ ! -d "${log_dir}" ]; then
	mkdir -p ${log_dir}
fi

INDEX=0

TagHead "Clear Process"
iporxy_process="iproxy $PORT $PORT"
XCTestWD_process="XCTESTWD_PORT=$PORT"
ps aux|grep "${iporxy_process}"|grep -v "grep"|awk '{print $2}'|xargs kill -9
echo "Clear Iproxy process"
ps aux|grep "${XCTestWD_process}"|grep -v "grep"|awk '{print $2}'|xargs kill -9
echo "Clear XCTestWD Process"

TagHead "Clear phone old crash logs"
mkdir -p ./oldlogs
idevicecrashreport -u ${UDID} -e ./oldlogs
rm -rf ./oldlogs

TagHead "Iproxy Setup"
iproxy $PORT $PORT $UDID >/dev/null &
echo $PORT, $UDID
sleep 20

while [ $INDEX -lt $apps_num ]
do
	appjson=`echo $jsons |jq ".[${INDEX}]"`

	appName=`echo $appjson | jq .appName | sed 's/"//g'`
	bundleId=`echo $appjson | jq .bundleId | sed 's/"//g'`
	username=`echo $appjson | jq .username | sed 's/"//g'`
	password=`echo $appjson | jq .password | sed 's/"//g'`

	package_dir="${log_dir}/${bundleId}"
	if [ ! -d "${package_dir}" ]; then
		mkdir -p ${package_dir}
	fi

	#找不到指定app，跳出继续执行下一个app
	CAN_RUN=`ideviceinstaller -u ${UDID} -l|awk '{print $1}'|grep "${bundleId}"`
	if [ -z "${CAN_RUN}" ]; then
		echo "\t!!! Error, no such app: ${bundleId}."
		echo "\t!!! Monkey aborted, will test next app."
		echo "N/A" > ${package_dir}/${RESULT_FILE}
		INDEX=$(($INDEX + 1))
		continue
	elif [ "${CAN_RUN}" != "${bundleId}" ]; then
		echo "\t!!! Error, no such app: ${bundleId}."
		echo "\t!!! Monkey aborted, will test next app."
		echo "N/A" > ${package_dir}/${RESULT_FILE}
		INDEX=$(($INDEX + 1))
		continue
	fi

	appVersion=`ideviceinstaller -u ${UDID} -l|grep "${bundleId}"|awk '{print $4}'`

	LOOP=1

	#add start test time
	startTime=`date +%s`
	echo $startTime
	startTime=$(($startTime+50))
	echo $startTime
	echo "Time:${startTime}" > ${package_dir}/${RESULT_FILE}

	while [ $LOOP -le $LOOP_NUM ]
	do
		TagHead "Start the ${appName} app test, test loop $LOOP"
		echo "Kill display log Process"
		ps aux|grep "tail -f ${XCODE_LOG}"|grep -v "grep"|awk '{print $2}'|xargs kill -9
		#if XCTestWD terminaled , restart.
		TagHead "Clear tmp log"
		rm -rf $DERIVED_DATA_DIR
		mkdir $DERIVED_DATA_DIR
		TagHead "Start XCTestWD"
		xcodebuild -project "${PROJECT_FOLDER}/XCTestWD.xcodeproj" -scheme XCTestWDUITests -destination 'platform=iOS,name='${DEVICE_NAME}'' -derivedDataPath ${DERIVED_DATA_DIR} XCTESTWD_PORT=${PORT} test > ${XCODE_LOG} &
		tail -f ${XCODE_LOG} &
		for i in {1..10}  
		do  
			sleep 20
			isSucess=`grep "${XCODE_BUILD_SUCESS}" ${XCODE_LOG}`
    		if [ -n "${isSucess}" ];then
    			echo "Xcode build sucessed!"
    			sleep 10
    			break 1
    		fi
    		if [ $i -eq 9 ]; then
    			echo "Xcode build failed!"
    			break 2
    		fi
    		echo "wait 20 seconds and checking agin!"
		done  

		TagHead "Start Monkey"
		if [ -z "${username}" -a -z "${password}" ]; then
			curl_cmd='curl -X POST -H "Content-Type:application/json" -d "{\"desiredCapabilities\":{\"deviceName\":\"'${DEVICE_NAME}'\",\"platformName\":\"iOS\", \"bundleId\":\"'${bundleId}'\",\"autoAcceptAlerts\":\"false\"}}" http://127.0.0.1:'${PORT}'/wd/hub/monkey &'
		else
			curl_cmd='curl -X POST -H "Content-Type:application/json" -d "{\"desiredCapabilities\":{\"deviceName\":\"'${DEVICE_NAME}'\",\"platformName\":\"iOS\", \"bundleId\":\"'${bundleId}'\",\"autoAcceptAlerts\":\"false\",\"username\":\"'${username}'\",\"password\":\"'${password}'\"}}" http://127.0.0.1:'${PORT}'/wd/hub/monkey &'
		fi 

		echo $curl_cmd
		eval $curl_cmd
		
		#catch device sys log
		echo "Start catch system log"
		idevicesyslog -u ${UDID} -g ${appName} > "${package_dir}/syslog_${LOOP}.txt" &

		#monitor if XCTestWD working
		echo "Start monitor process to avoid interrupted"
		monitor_cmd='./monitor_working.sh '${DEVICE_NAME}' '${DERIVED_DATA_DIR}' '${PORT}' '${XCTestWD_process}' '\'${curl_cmd}\'''
		echo $monitor_cmd
		eval $monitor_cmd &

		sleep $(($RUN_TIME_IN_SECOND))

		TagHead "Stop this test loop"
		echo "Fetch crash logs and event logs"
		idevicecrashreport -u ${UDID} -e -g ${appName} "${package_dir}/"
		grep ${EVENT_TAG} ${XCODE_LOG} > ${package_dir}/event_log_${LOOP}.txt
		
		echo "Stop system log and event log"
		ps aux|grep "idevicesyslog -u ${UDID}"|grep -v "grep"|awk '{print $2}'|xargs kill -9
		echo "Kill monitor process"
		ps aux|grep "./monitor_working.sh ${DEVICE_NAME} ${DERIVED_DATA_DIR} ${PORT}"|grep -v "grep"|awk '{print $2}'|xargs kill -9
		echo "Stop XCTestWD Process"
		ps aux|grep "${XCTestWD_process}"|grep -v "grep"|awk '{print $2}'|xargs kill -9
		echo "Kill display log Process"
		ps aux|grep "tail -f ${XCODE_LOG}"|grep -v "grep"|awk '{print $2}'|xargs kill -9

		TagHead "Clear tmp log"
		rm -rf $DERIVED_DATA_DIR

		LOOP=$(($LOOP+1))
	done

	Crash_Num=`ls ${package_dir} | grep ".ips$" | wc -l |awk '{print $1}'`
	echo "Version:${appVersion}" >> ${package_dir}/${RESULT_FILE}
	echo "Crash:${Crash_Num}" >> ${package_dir}/${RESULT_FILE}
	echo "`ls ${package_dir}|grep ".ips"`" >>${package_dir}/${RESULT_FILE}
	INDEX=$(($INDEX + 1))
done

TagHead "Stop test, stop process"
ps aux|grep "${iporxy_process}"|grep -v "grep"|awk '{print $2}'|xargs kill -9
echo "Stop Iproxy process"

# summary test result
TagHead "Generate Test Report"
./summary.sh ${RUN_TIME} ${LOOP_NUM} ${UDID} ${log_dir} 120m
java Xml2Html ${log_dir}




