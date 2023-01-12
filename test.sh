#!/bin/bash

#関数ファイル読み込み

#現在の温度(R3=R)
R1=20 #設定
R2=30 #基準温度
R3=15 #終了温度
S=5 #何度ずつ上げ下げ
M=15 #運転時間

while [ $R1 < $R2 ]
do
	#(3)
        R1=$((R1+S))	#S℃ずつ上げる
        mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
	sleep $M s	#M分経過
        echo "rを$S℃ずつ上昇"
        echo "r:$R1"

	if [ $R1 -eq $R2 ]; then
		while [ $R1 > R$3 ]
		do
			#(4)
			R1=$((R1-S)) #S℃ずつ下げる
			mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $R1}"
			echo "rを$S℃ずつ下降"
			echo "r:$R1"

			#(5)
			if [ $R1 -eq $R3 ]; then
				exit 0
			fi
		done
	fi
done
