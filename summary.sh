#!/bin/bash
# Auto generate summary xml file.

DATE=`date +%Y/%m/%d`
TEST_TIME=$1
LOOP_NUM=$2
UDID=$3
LOG_DIR=$4
ROOT_PATH=`pwd`

products_dict='{"iPhone6,1":"iPhone 5S","iPhone6,2":"iPhone 5S","iPhone7,1":"iPhone 6 Plus","iPhone7,2":"iPhone 6","iPhone8,1":"iPhone 6S","iPhone8,2":"iPhone 6S Plus","iPhone9,1":"iPhone7","iPhone9,2":"iPhone7 Plus"}'

if [ -z $TEST_TIME ] || [ -z $LOOP_NUM ] || [ -z $UDID ] || [ -z $LOG_DIR ]; then
        echo "Usage: ./summary.sh [run_time] [loop_num] [udid] [log_dir] [Goal of MTBF]"
        exit
fi


# $4 should be the goal of MTTF for current M-gate. So if $4 is defined mean this summary is filed for M-gate review. If not, this sheet will be used for general monkey test report.
if [ -z $5 ];then
	TAGGET_MTTF="120m"
else
	TAGGET_MTTF=$5
fi

PRODUCT=`ideviceinfo -u ${UDID} -k ProductType | sed 's/\r//g'`
DEVICE=`ideviceinfo -u ${UDID} -k DeviceName | sed 's/\r//g'`
MODEL1=`ideviceinfo -u ${UDID} -k ModelNumber | sed 's/\r//g'`
REGION=`ideviceinfo -u ${UDID} -k RegionInfo | sed 's/\r//g'`
MODEL="${MODEL1}${REGION}"
VERSION=`ideviceinfo -u ${UDID} -k ProductVersion | sed 's/\r//g'`
Value=$(echo $products_dict | jq 'has('\"${PRODUCT}\"')')

if [ "${Value}" = "true" ]; then
	echo "contains the product! ${PRODUCT}"
	PRODUCT=`echo $products_dict| jq ''.\"${PRODUCT}\"''| sed 's/"//g'`
	echo $PRODUCT
fi

sheet_type=app.xsl

echo -e "\n---------------------------------------------------------------------------"
echo "Summarizing: $sheet_type - $LOG_DIR"

cat > ${LOG_DIR}/summary.xml <<HELP
<?xml version="1.0" encoding="utf-8" ?>
<?xml-stylesheet type="text/xsl" href="$sheet_type" ?>

<items>
	<sysitem>
		<text>Product</text>
		<link>$PRODUCT</link>
	</sysitem>
	<sysitem>
                <text>Model</text>
                <link>$MODEL</link>
        </sysitem>

	<sysitem>
		<text>DeviceName</text>
		<link>$DEVICE</link>
	</sysitem>
	<sysitem>
		<text>Version</text>
		<link>$VERSION</link>
	</sysitem>
	<sysitem>
		<text>Udid</text>
		<link>$UDID</link>
	</sysitem>
	<sysitem>
		<text>Date</text>
		<link>$DATE</link>
	</sysitem>
	<sysitem>
		<text>Goal of MTBF</text>
		<link>$TAGGET_MTTF</link>
	</sysitem>
HELP

if [ $sheet_type = "app.xsl" ]; then
	cd $LOG_DIR
	total_count=0
    pass_count=0
    fail_count=0
    na_count=0
	for package in *
 	do
		ACTUAL_TEST_TIME=$TEST_TIME
		if [ -f ./${package}/result.txt ]; then
			total_count=$(($total_count + 1))
			echo -e "\t<appitem>" >> ./summary.xml
			echo -e "\t\t<app>${package}</app>" >> ./summary.xml
			if [ `cat ./${package}/result.txt | awk '{print;exit}' | awk '{print $1}'` = "N/A" ]; then
				echo -e "\t\t<version>${version}</version>" >> ./summary.xml
				echo -e "\t\t<td>N/A</td>" >> ./summary.xml
				echo -e "\t\t<fc>N/A</fc>" >> ./summary.xml
				echo -e	"\t\t<tf>N/A</tf> " >> ./summary.xml
				echo -e "\t\t<mttf>N/A</mttf>" >> ./summary.xml
				echo -e "\t\t<mg>N/A</mg>" >> ./summary.xml
				echo -e "\t</appitem>" >> ./summary.xml
				na_count=$(($na_count + 1))
			else
				version=`cat ./${package}/result.txt|grep Version|awk -F ":" '{print $2}'`
				echo -e "\t\t<version>${version}</version>" >> ./summary.xml
				fc=`cat ./${package}/result.txt|grep Crash|awk -F ":" '{print $2}'`
				
				#echo "$fc", maybe others in future				
				total_failure=$(($fc))

				# convert test time to minute for calculate MTTF				
				if [ `echo ${ACTUAL_TEST_TIME} | grep -e '^[0-9]*[mM]$'` ]; then
					target_min=`echo ${ACTUAL_TEST_TIME} | sed -e "s/[mM]$//"`
				elif [ `echo ${ACTUAL_TEST_TIME} | grep -e '^[0-9]*[sS]$'` ]; then
					target_min=`echo ${ACTUAL_TEST_TIME} | sed -e "s/[sS]$//"`
					target_min=$(($target_min / 60))
				fi

				target_min="$(($target_min * $LOOP_NUM))"
				echo $target_min

                TAGGET_MTTF=`echo $TAGGET_MTTF | sed -e "s/[mM]$//"`

				#no issue found:
				if [ $total_failure -eq 0 ]; then
					mttf="----"
					firsterr="----"
					mg="pass"
              		pass_count=$(($pass_count + 1))
					echo "---------------------------------------------------------------------------"
					echo "Passed: $package "
				# found one or more issue:
				else
					echo $total_failure, $target_min
					mttf_a=$(($target_min / $total_failure))
					mttf_b=$(($target_min % $total_failure * 10 / $total_failure))
					mttf_c=$(($target_min % $total_failure * 10 % $total_failure * 10 / $total_failure))
					mttf="${mttf_a}.${mttf_b}${mttf_c}"
					#echo $mttf

					# count 1st error by finding the 1st real failure.
	                start_time=`cat ./${package}/result.txt|grep Time|awk -F ":" '{print $2}'`
	                echo ${start_time}
	                firstfile=`ls ./${package} | sort -k9 |awk 'NR==1{print $1}'`
	             	firsterr_time=`echo ${firstfile} | sed 's/.ips//g' | awk -F "-" NR==1'{print $2$3$4$5}'`
	             	firsterr_second=`date -j -f %Y%m%d%H%M%S ${firsterr_time} +%s`
	             	errat=$(($firsterr_second-$start_time))
	             	errat_MINUTE=$(($errat / 60))
	                errat_SECOND=$(($errat % 60))
	                firsterr="${errat_MINUTE}m${errat_SECOND}s"
					
					echo "---------------------------------------------------------------------------"
					echo "$package | First error: $firsterr| Total Failures: $total_failure"
					
					# compare with goal to pass or fail it.
				    if [ $mttf_a -gt $TAGGET_MTTF ];then
			 			mg="pass"
						pass_count=$(($pass_count + 1))
				    elif [ $mttf_a -lt $TAGGET_MTTF ];then
						mg="fail"
						fail_count=$(($fail_count + 1))
				    elif [ $mttf_a -eq $TAGGET_MTTF ];then
				 		if [ $mttf_b != 0 ] || [ $mttf_c != 0 ];then
				       	    mg="pass"
					    	pass_count=$(($pass_count + 1))
						else
					    	mg="fail"
					    	fail_count=$(($fail_count + 1))
						fi
				    fi
				fi
 				
				echo -e "\t\t<td>${target_min}m</td>" >> ./summary.xml
				echo -e "\t\t<fc>$fc</fc>" >> ./summary.xml
				echo -e "\t\t<firsterr>$firsterr</firsterr>" >> ./summary.xml
				echo -e	"\t\t<tf>$total_failure</tf> " >> ./summary.xml
				echo -e "\t\t<mttf>${mttf}m</mttf>" >> ./summary.xml
				echo -e "\t\t<mg>$mg</mg>" >> ./summary.xml
				echo -e "\t</appitem>" >> ./summary.xml
				
				# add the info of each failure
				if [ $total_failure -ne 0 ];then
					echo -e "\t<failreason>" >> ./summary.xml
                    echo -e "\t\t<app>$package</app>" >> ./summary.xml
					echo -e "\t\t<tf>$total_failure</tf>" >> ./summary.xml
					lerrs=`cat ./${package}/result.txt| grep "[-0-9]*.ips$"`
					i=0
					while (( i<$fc ))
					do
						i=$(($i+1))
						error=`echo $lerrs | awk '{print $'$i'}'`
						echo "\t\t<at><failure>${error} </failure></at>" >> ./summary.xml
					done
					echo -e "\t</failreason>" >> ./summary.xml
				fi
			fi
		fi
	done

	# calculate pass rate.
	pr_a=$(($pass_count * 100 / $total_count))
	pr_b=$(($pass_count * 100 % $total_count * 10 / $total_count))
	pr_c=$(($pass_count * 100 % $total_count * 10 % $total_count * 10 / $total_count))
	pr="${pr_a}.${pr_b}${pr_c}"

	echo -e "\t<resultitem>" >> ./summary.xml
   	echo -e "\t\t<text>TOTAL</text>" >> ./summary.xml
        echo -e "\t\t<No>$total_count</No>" >> ./summary.xml
       	echo -e "\t</resultitem>" >> ./summary.xml
        echo -e "\t<resultitem>" >> ./summary.xml
        echo -e "\t\t<text>PASS</text>" >> ./summary.xml
        echo -e "\t\t<No>$pass_count</No>" >> ./summary.xml
        echo -e "\t</resultitem>" >> ./summary.xml
        echo -e "\t<resultitem>" >> ./summary.xml
        echo -e "\t\t<text>FAIL</text>" >> ./summary.xml
        echo -e "\t\t<No>$fail_count</No>" >> ./summary.xml
        echo -e "\t</resultitem>" >> ./summary.xml
        echo -e "\t<resultitem>" >> ./summary.xml
        echo -e "\t\t<text>N/A</text>" >> ./summary.xml
        echo -e "\t\t<No>$na_count</No>" >> ./summary.xml
       	echo -e "\t</resultitem>" >> ./summary.xml
	echo -e "\t<resultitem>" >> ./summary.xml
	echo -e "\t\t<text>PASS RATE</text>" >> ./summary.xml
	echo -e "\t\t<No>${pr}%</No>" >> ./summary.xml
	echo -e "\t</resultitem>" >> ./summary.xml
	echo "</items>" >> ./summary.xml
	cp ${ROOT_PATH}/${sheet_type} ./
fi

