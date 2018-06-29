#!/bin/bash
# Monitor ios monkey running
#./monitor_working.sh ${DEVICE_NAME} ${DERIVED_DATA_DIR} ${PORT} ${XCTestWD_process} ${curl_cmd}

DEVICE_NAME=$1
DERIVED_DATA_DIR=$2
PORT=$3
XCTestWD_process=$4
curl_cmd=$5
XCODE_LOG="${DERIVED_DATA_DIR}/temp_xcode.txt"
XCODE_BUILD_SUCESS="XCTestWDUITests-Runner.app: replacing existing signature"
BUILD_NUM=1

echo $curl_cmd

while [[ true ]]; do
	isrun=`ps aux|grep "${XCTestWD_process}"|grep -v "grep"|grep -v "monitor_working"|awk '{print $2}'`
	echo "process: " $isrun
	if [ -z "${isrun}" ]; then
		echo "Restart XCTestWD"
		echo "Clear tmp log"
		cp ${XCODE_LOG} temp_xcode.txt
		rm -rf $DERIVED_DATA_DIR
		mkdir $DERIVED_DATA_DIR
		mv temp_xcode.txt ${XCODE_LOG}
		xcodebuild -project "./XCTestWD-master/XCTestWD/XCTestWD.xcodeproj" -scheme XCTestWDUITests -destination 'platform=iOS,name='${DEVICE_NAME}'' -derivedDataPath ${DERIVED_DATA_DIR} XCTESTWD_PORT=${PORT} test >> ${XCODE_LOG} &
		tail -f ${XCODE_LOG} &
		BUILD_NUM=$[$BUILD_NUM+1]
		for i in {1..10}  
		do  
			sleep 20
			isSucess=`grep -c "${XCODE_BUILD_SUCESS}" ${XCODE_LOG}`
    		if [ ${isSucess} -eq ${BUILD_NUM} ];then
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
		eval $curl_cmd
	else
		echo "XCTestWD working well"
	fi
	sleep 60
done