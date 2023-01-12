#!/bin/bash

# プログラムやデータの配置場所
DEST=/opt/snk

#実験準備
ex_erase () {
	echo "●データ消去"
	#データの消去
	supervisorctl stop all
	supervisorctl remove optimizer
	rm -f $DEST/output/*.log
	rm -f $DEST/output/*.json
	rm -f $DEST/data/*.json
	echo "●/data・・outputの中のlog・jsonを消去しました"
	supervisorctl start cyclic controller

	#システム再起動用
	sleep 30s
}

#暖機運転開始
ex_warm () {
	echo "●暖気運転を開始"

	#PID1,PID2をMNモードに変更
	mosquitto_pub -h localhost -t snk/1 -m '{"PID1-AT/MT-remote": 1}'
	mosquitto_pub -h localhost -t snk/1 -m '{"PID2-AT/MT-remote": 1}'
	mosquitto_pub -h localhost -t snk/1 -m '{"PID1-value-remote": 1.0}'
	mosquitto_pub -h localhost -t snk/1 -m '{"PID2-value-remote": 0.0}'
	echo "●ヒーター出口制御100%、入口制御0%に設定しました"

	#電源、ヒーターON
	mosquitto_pub -h localhost -t snk/1 -m '{"on/off-remote": 1}'
	mosquitto_pub -h localhost -t snk/1 -m '{"Heater-value-remote": 100}'
	echo "●電源、ヒーターをonにしました"
}

#PID設定温度(目標温度SV)の設定
ex_pidSV () {
	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $1}"
	mosquitto_pub -h localhost -t snk/1 -m "{\"r1\": $2}"
	echo "PID設定温度(目標温度SV)を設定"
	echo "r:$1℃ $r1:$2℃"
}

#PID制御値をランダムに選別
ex_pidrandam () {
	#Kpの制御設定
	randKp=`shuf -i 1-50000 -n1`
	fewKp1=`shuf -i 1-99 -n1`
	randKp1=$(python -c "print($randKp*0.000001)")
	#Tdの制御設定
	randTd=`shuf -i 1-300 -n1`
	fewTd1=`shuf -i 1-99 -n1`
	fewTd2=$(python -c "print($fewTd1*0.01)")
	randTd1=$(python -c "print($randTd+$fewTd2)")
	#Tiの制御設定値
	randTi=`shuf -i 0-300 -n1`
	fewTi1=`shuf -i 1-99 -n1`
	fewTi2=$(python -c "print($fewTi1*0.01)")
	randTi1=$(python -c "print($randTi+$fewTi2)")
	mosquitto_pub -h localhost -t snk/1 -m "{\"Kp\": $randKp1}"
	mosquitto_pub -h localhost -t snk/1 -m "{\"Td\": $randTd1}"
	mosquitto_pub -h localhost -t snk/1 -m "{\"Ti\": $randTi1}"
        echo "●PID制御設定値が変更されました"
        echo "Kp:$randKp1, Td:$randTd1, Ti:$randTi1"
}

#PID制御設定値の変更
ex_pid () {
	#Kpの制御設定値
	mosquitto_pub -h localhost -t snk/1 -m "{\"Kp\": $1}"
	#Tdの制御設定値
	mosquitto_pub -h localhost -t snk/1 -m "{\"Td\": $2}"
	#Tiの制御設定値
	mosquitto_pub -h localhost -t snk/1 -m "{\"Ti\": $3}"
	echo "●PID制御設定値が変更されました"
	echo "Kp:$1, Td:$2, Ti:$3"
}

#ヒーター出口温度の上昇
ex_tempup () {
	temp=$1

	echo "●PID1の計測温度(y)を$temp℃まで上げます"

	y=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"y"'|awk '{print $2}'`
	until [ `echo "$y >= $temp"|bc` == 1 ]
	do
    		y=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"y"'|awk '{print $2}'`
	done

	echo "●PID1の計測温度(y)が$temp℃まで上昇しました"
}

#モード切替、実験開始時刻記録
ex_time () {
	#atモードに切り替え
	echo "●ATモードに切り替え"
        mosquitto_pub -h localhost -t snk/1 -m '{"PID1-AT/MT-remote": 0}'
        mosquitto_pub -h localhost -t snk/1 -m '{"PID2-AT/MT-remote": 0}'

	#実験開始時刻
	echo "●実験開始"
	time2=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"time"'|awk '{print $2}'`
	time3=${time2/%?/}
	time4=$(date -d @$time3)
	echo "実験開始時刻:$time4"
}


#ランダム設定
ex_pid_schedule () {
	#pidランダム設定
	#パターン数決定
	pid_pattern=`shuf -i 1-10 -n1`
	for ((k=0 ; k<pid_pattern ; k++))
	do
		#pidランダム設定呼び出し
		ex_pidrandam
		#電気ヒータ出力スケジュールランダム設定
		#パターン数決定
                schedule_pattern=`shuf -i 1-10 -n1`
		for ((j=0 ; j<schedule_pattern ; j++))
		do
			#ヒータ出力
                        r_schedule=`shuf -i 0-100 -n1`
                        #実験時間
                        r_etime=`shuf -i 60-100 -n1`
			echo "負荷率$r_schedule % 実験時間$r_etime s"
			mosquitto_pub -h localhost -t snk/1 -m "{\"Heater-value-remote\": $r_schedule}"
			sleep "$r_etime"s
		done
	done
}

#実験開始
ex_start () {
	echo "負荷率$1% 実験時間$2h"
	mosquitto_pub -h localhost -t snk/1 -m "{\"Heater-value-remote\": $1}"
	etime="$2"
	sleep "$etime"s
}

#実験終了
ex_fin () {
	echo "●実験終了"
	time2=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"time"'|awk '{print $2}'`
	time3=${time2/%?/}
	time4=$(date -d @$time3)

	#ファイル保存
	time=`date '+%Y%m%d_%H%M%S'`
	cp $DEST/output/data.json $DEST/output/data_${time}.json
	echo "実験終了時刻:$time4"
	mosquitto_pub -h localhost -t snk/1 -m '{"Heater-value-remote": 0}'
	mosquitto_pub -h localhost -t snk/1 -m '{"on/off-remote": 0}'
}

#終了ハンドラ
ex_final () {
	echo "強制終了されたため装置の電源をoffにします"
	mosquitto_pub -h localhost -t snk/1 -m '{"Heater-value-remote": 0}'
	mosquitto_pub -h localhost -t snk/1 -m '{"on/off-remote": 0}'
	exit 0
}
