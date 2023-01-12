#!/bin/bash

#スケジューラー処理
scheduler() {
        R=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"r"'|awk '{print $2}'` #現在の温度
	R1=$1 #設定温度
        R2=$2 #基準温度
        R3=$3 #終了温度
        S=$4 #何度ずつ上げ下げ
        M=$5 #運転時間

	#現在温度が基準温度より小さい(R1<R2)
	if [ "$R1" -lt "$R2" ]; then
		#スケジュール運転
        	echo "スケジュール運転開始"
        	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
        	echo "r:$R1 ℃ 運転時間:$M m"
        	sleep "$M"m

        	while [ "$R1" -lt "$R2" ]	#R1<R2
        	do
                	#(3)
                	R1=$((R1+S))    #S℃ずつ上げる
                	echo "rを$S℃ずつ上昇"
                	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
                	echo "r:$R1 ℃ 運転時間:$M m"
                	sleep "$M"m     #M分経過

                	if [ $R1 -eq $R2 ]; then
				#終了温度(元運転していた時のr)が現在温度より小さい(R1>R3)とき
                        	while [ "$R1" -gt "$R3" ]
                        	do
                                	#(4)
                                	R1=$((R1-S)) #S℃ずつ下げる
                                	echo "rを$S℃ずつ下降"
                                	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
                                	echo "r:$R1 ℃ 運転時間:$M m"
                                	sleep "$M"m     #M分経過

                                	#(5)
                                	if [ $R1 -eq $R3 ]; then
                                        	echo "運転終了"
                                        	exit 0
                                	fi
                        	done

				#終了温度(元運転していた時のr)が現在温度より大きい(R1<R3)とき
                        	while [ "$R1" -lt "$R3" ]
                        	do
                                	#(4)
                                	R1=$((R1+S)) #S℃ずつ上げる
                                	echo "rを$S℃ずつ上昇"
                                	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
                                	echo "r:$R1 ℃ 運転時間:$M m"
                                	sleep "$M"m     #M分経過

                                	#(5)
                                	if [ $R1 -eq $R3 ]; then
                                        	echo "運転終了"
                                        	exit 0
                                	fi
                        	done
                	fi
        	done

	#現在温度が基準温度より大きい(R1>R2)
	elif [ "$R1" -gt "$R2" ]; then
		#スケジュール運転
                echo "スケジュール運転開始"
                mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
                echo "r:$R1 ℃ 運転時間:$M m"
                sleep "$M"m

                while [ "$R1" -gt "$R2" ]       #R1>R3
                do
                	#(3)
                        R1=$((R1-S))    #S℃ずつ上げる
                        echo "rを$S℃ずつ下降"
                        mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
                        echo "r:$R1 ℃ 運転時間:$M m"
                        sleep "$M"m     #M分経過

                        if [ $R1 -eq $R2 ]; then
                        	#終了温度(元運転していた時のr)が現在温度より小さい(R1>R3)とき
                                while [ "$R1" -gt "$R3" ]       #R1>R3
                                do
                                	#(4)
                                        R1=$((R1-S)) #S℃ずつ下げる
                                        echo "rを$S℃ずつ下降"
                                        mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
                                        echo "r:$R1 ℃ 運転時間:$M m"
                                        sleep "$M"m     #M分経過

                                        #(5)
                                        if [ $R1 -eq $R3 ]; then
                                        	echo "運転終了"
                                                exit 0
                                        fi
                       		done

                                #終了温度(元運転していた時のr)が現在温度より大きい(R1<R3)とき
                                while [ "$R1" -lt "$R3" ]
                                do
                                        #(4)
                                        R1=$((R1+S)) #S℃ずつ上げる
                                        echo "rを$S℃ずつ上昇"
                                        mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
                                        echo "r:$R1 ℃ 運転時間:$M m"
                                        sleep "$M"m     #M分経過

                                        #(5)
                                        if [ $R1 -eq $R3 ]; then
                                                echo "運転終了"
                                                exit 0
                                        fi
                                done
			fi
		done
	else
		echo "NO"
	fi
}
