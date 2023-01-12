#!/bin/bash

# 外から呼べる関数はex_
# 外から呼ばない関数はpr_

#終了ハンドラ
trap 'pr_final' 1 2 3 15

# プログラムやデータの配置場所
DEST=/opt/snk

#実験準備
ex_erase () {
        echo
	echo "●実験準備"

	#optimizerの停止
	if [ "$(supervisorctl status all|grep ^optimizer)" != "" ]; then
	    supervisorctl stop optimizer
	    supervisorctl remove optimizer
	    echo "optimizerを停止しました"
	fi
	#

	#データ消去(指定があれば)
	if [ "$*" != "" ]; then
	    #デーモン停止
	    supervisorctl stop cyclic controller

	    for i in $*; do
		if [ "$i" == "output" ]; then
		    #データの消去
		    rm -f $DEST/output/*.log
		    rm -f $DEST/output/*.json
		    echo "outputの中のlog・jsonを消去しました"
		elif [ "$i" == "data" ]; then
		    rm -f $DEST/data/pid.json
		    echo "dataの中のpid.jsonを消去しました"
		fi
	    done

	    #デーモン再起動
	    supervisorctl start cyclic controller
	    echo "デーモン起動待ち"
	    while [ "$(supervisorctl status cyclic|grep RUNNING)" == "" ]; do
		sleep 1s
	    done
	    while [ "$(supervisorctl status controller|grep RUNNING)" == "" ]; do
		sleep 1s
	    done
	    echo "デーモンが起動しました"
	fi
}

#暖機運転開始
ex_warm () {
	echo
	echo "●暖気運転を開始"

	#PID1,PID2をMNモードに変更
	mosquitto_pub -h localhost -t snk/1 -m '{"PID1-AT/MT-remote": 1}'
	mosquitto_pub -h localhost -t snk/1 -m '{"PID2-AT/MT-remote": 1}'
	mosquitto_pub -h localhost -t snk/1 -m '{"PID1-value-remote": 1.0}'
	mosquitto_pub -h localhost -t snk/1 -m '{"PID2-value-remote": 0.0}'
	echo "ヒーター出口制御100%、入口制御0%に設定しました"

	#電源、ヒーターON
	mosquitto_pub -h localhost -t snk/1 -m '{"on/off-remote": 1}'
	mosquitto_pub -h localhost -t snk/1 -m '{"Heater-value-remote": 100}'
	echo "電源、ヒーターをonにしました"
}

# 指定した時間だけ待つ
ex_wait () {
    echo
    echo "●待ち時間"
    echo "$1待ちます"
    sleep "$1"
}

#PID設定温度(目標温度SV)の設定
ex_pidSV () {
        echo
	echo "●PID設定温度(目標温度SV)を設定"
	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $1}"
	echo "r:$1℃"
}

#PID設定温度(目標温度SV)の設定(2系統ある場合)
ex_pidSV2 () {
	echo
	echo "●PID設定温度(目標温度SV)を設定"
	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $1}"
        mosquitto_pub -h localhost -t snk/1 -m "{\"r1\": $2}"
	echo "r:$1℃ $r1:$2℃"
}

#PID制御値をランダムに選別
ex_pidrandam () {
        echo
        echo "●PID制御設定値を変更します"
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
        echo "Kp:$randKp1, Td:$randTd1, Ti:$randTi1"
}

#PID制御設定値の変更
ex_pid () {
	echo
        echo "●PID制御設定値を変更します"
	#Kpの制御設定値
	mosquitto_pub -h localhost -t snk/1 -m "{\"Kp\": $1}"
	#Tdの制御設定値
	mosquitto_pub -h localhost -t snk/1 -m "{\"Td\": $2}"
	#Tiの制御設定値
	mosquitto_pub -h localhost -t snk/1 -m "{\"Ti\": $3}"
	echo "Kp:$1, Td:$2, Ti:$3"
}

#ヒーター出口温度の上昇
ex_tempup () {
	temp=$1

	echo
	echo "●PID1の計測温度(y)を$temp℃まで上げます"

	y=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"y"'|awk '{print $2}'`
	until [ `echo "$y >= $temp"|bc` == 1 ]
	do
    		y=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"y"'|awk '{print $2}'`
	done

	echo "PID1の計測温度(y)が$temp℃まで上昇しました"
}

#モード切替、実験開始時刻記録
ex_time () {
	#atモードに切り替え
	echo
	echo "●ATモードに切り替え"
        mosquitto_pub -h localhost -t snk/1 -m '{"PID1-AT/MT-remote": 0}'
        mosquitto_pub -h localhost -t snk/1 -m '{"PID2-AT/MT-remote": 0}'

	#実験開始時刻
	echo
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
        echo
	echo "●実験終了"
	time2=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"time"'|awk '{print $2}'`
	time3=${time2/%?/}
	time4=$(date -d @$time3)

	#ファイル保存
	time=`date '+%Y%m%d_%H%M%S'`
	cp $DEST/output/data.json data_${time}.json
	echo "実験終了時刻:$time4"
	mosquitto_pub -h localhost -t snk/1 -m '{"Heater-value-remote": 0}'
	mosquitto_pub -h localhost -t snk/1 -m '{"on/off-remote": 0}'
}

#終了ハンドラ
pr_final () {
	echo "強制終了されたため装置の電源をoffにします"
	mosquitto_pub -h localhost -t snk/1 -m '{"Heater-value-remote": 0}'
	mosquitto_pub -h localhost -t snk/1 -m '{"on/off-remote": 0}'
	exit 0
}
