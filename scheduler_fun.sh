#!/bin/bash

scheduler1 () {
	R=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"r"'|awk '{print $2}'` #現在の温度(R3=R)
	R1=$1 #設定
	R2=$2 #基準温度
	R3=$3 #終了温度
	S=$4 #何度ずつ上げ下げ
	M=$5 #運転時間

	#スケジュール運転
	echo "スケジュール運転開始"
	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
	echo "r:$R1 ℃ 運転時間:$M m"
	sleep "$M"s

	while [ $R1 < $R2 ]
	do
        	#(3)
        	R1=$((R1+S))    #S℃ずつ上げる
        	echo "rを$S℃ずつ上昇"
        	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
        	echo "r:$R1 ℃ 運転時間:$M m"
        	sleep "$M"s     #M分経過

        	if [ $R1 -eq $R2 ]; then
                	while [ $R1 > $R3 ]
                	do
                        	#(4)
                        	R1=$((R1-S)) #S℃ずつ下げる
                        	echo "rを$S℃ずつ下降"
                        	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
                        	echo "r:$R1 ℃ 運転時間:$M m"
                        	sleep "$M"s     #M分経過

                        	#(5)
                        	if [ $R1 -eq $R3 ]; then
                                	echo "運転終了"
                                	exit 0
                        	fi
                	done
        	fi
	done
}
