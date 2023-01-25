#!/bin/bash

#英語・日本語切り替え
source "/usr/bin/gettext.sh"

TEXTDOMAIN="ex_function"
export TEXTDOMAIN

TEXTDOMAINDIR="$(pwd)/locale"
export TEXTDOMAINDIR

#終了ハンドラ
trap 'ex_fin' 1 2 3 15

# プログラムやデータの配置場所
DEST=/opt/snk

#過去データ消去
ex_erase () {
	echo
	echo "******************************************************************"
	echo "$(eval_gettext 'ExperimentPreparation')"

	#optimizerの停止
	if [ "$(supervisorctl status all|grep ^optimizer)" != "" ]; then
	    supervisorctl stop optimizer
	    supervisorctl remove optimizer
	    echo "$(eval_gettext 'Optimizer has been stopped')"
	    #echo "optimizerを停止しました"
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
		    printf "$(eval_gettext 'Log/json in %s/output has been erased')\n"
    		    "$DEST"
		    #echo "$DEST/outputの中のlog・jsonを消去しました"
		elif [ "$i" == "data" ]; then
		    rm -f $DEST/data/pid.json
		    echo "$(eval_gettext 'Deleted pid.json in data')"
		    #echo "dataの中のpid.jsonを消去しました"
		fi
	    done

	    #デーモン再起動
	    supervisorctl start cyclic controller
	    echo "$(eval_gettext 'waiting for daemon')"
	    #echo "デーモン起動待ち"
	    while [ "$(supervisorctl status cyclic|grep RUNNING)" == "" ]; do
		sleep 1s
	    done
	    echo "$(eval_gettext 'cyclic has been activated.')"
	    #echo "cyclicが起動しました"
	    while [ "$(supervisorctl status controller|grep RUNNING)" == "" ]; do
		sleep 1s
	    done
	    echo "$(eval_gettext 'controller has been activated.')"
	    #echo "controllerが起動しました"
	fi
}

#暖機運転開始
ex_warm () {
	echo
	echo "******************************************************************"
	echo "$(eval_gettext 'Start warm-up operation')"
	#echo "暖気運転を開始"

	#PID1,PID2をMNモードに変更
	mosquitto_pub -h localhost -t snk/1 -m '{"PID1-AT/MT-remote": 1}'
	mosquitto_pub -h localhost -t snk/1 -m '{"PID2-AT/MT-remote": 1}'
	mosquitto_pub -h localhost -t snk/1 -m '{"PID1-value-remote": 1.0}'
	mosquitto_pub -h localhost -t snk/1 -m '{"PID2-value-remote": 0.0}'
	echo "$(eval_gettext 'Heater outlet control set to 100%, inlet control set to 0')"
	#echo "ヒーター出口制御100%、入口制御0%に設定しました"

	#電源、ヒーターON
	mosquitto_pub -h localhost -t snk/1 -m '{"on/off-remote": 1}'
	mosquitto_pub -h localhost -t snk/1 -m '{"Heater-value-remote": 100}'
	echo "$(eval_gettext 'Power and heaters turned on.')"
	#echo "電源、ヒーターをonにしました"
}

#指定した時間だけ待つ
ex_wait () {
    echo
    echo "$(eval_gettext 'waiting time')"
    #echo "待ち時間"
    printf "$(eval_gettext '%s I will wait.')\n"
    "$1"
    #echo "$1待ちます"
    sleep "$1"
}

#任意のレジスタの設定値変更
ex_set_value () {
        register=$1
	value=$2
        echo
	echo "******************************************************************"
        echo "$(eval_gettext 'Setting value change')"
	#echo "設定値変更"
	printf "$(eval_gettext 'Sets the value of %s to ')"
    	"$register"
        printf "$(eval_gettext '%s')"
        "$value"
	#echo "$registerの値を$valueに設定します"
	mosquitto_pub -h localhost -t snk/1 -m "{\"$register\": $value}"
	v=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep "\"$register\":"|awk '{print $2}'`
        printf "$(eval_gettext 'The value of %s is now ')"
        "$register"
        printf "$(eval_gettext '%s')\n"
        "$v"
	#echo "$registerの値が$vになりました"
	if [ "$value" != "$v" ]; then
	    printf "$(eval_gettext 'Error: %s and ')"
            "$value"
            printf "$(eval_gettext '%s are different')\n"
            "$v"
	    #echo "Error: $valueと$vが異なっています"
	fi
}

#PID設定温度(目標温度SV)の設定
ex_pidSV () {
        echo
        echo "******************************************************************"
        echo "$(eval_gettext 'PID set temperature (target temperature SV)')"
	#echo "PID設定温度(目標温度SV)を設定"
	printf "$(eval_gettext 'Set to r:%s°C')\n"
        "$1"
	#echo "r:$1℃に設定します"
	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $1}"
	r=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"r"'|awk '{print $2}'`
        printf "$(eval_gettext 'r:%s°C now.')\n"
        "$r"
	#echo "r:$r℃になりました"
}

#PID設定温度(目標温度SV)の設定(2系統ある場合)
ex_pidSV2 () {
	echo
        echo "******************************************************************"
        echo "$(eval_gettext 'PID set temperature (target temperature SV)')"
	#echo "PID設定温度(目標温度SV)を設定"
	printf "$(eval_gettext 'Set to r:%s°C, r1:%s°C')\n"
        "$1" "$2"
	#echo "r:$1℃, r1:$2℃に設定します"
	mosquitto_pub -h localhost -t snk/1 -m "{\"r\": $1}"
        mosquitto_pub -h localhost -t snk/1 -m "{\"r1\": $2}"
	r=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"r"'|awk '{print $2}'`
	r1=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"r1"'|awk '{print $2}'`
        printf "$(eval_gettext 'r:%s°C, r1:%s°C now.')\n"
        "$r" "$r1"
	#echo "r:$r℃, r1:$r1℃になりました"
}

#PID制御値をランダムに選別
ex_pidrandam () {
        echo
        echo "******************************************************************"
        echo "$(eval_gettext 'Changes the PID control setpoint.')"
        #echo "PID制御パラメータを変更します"
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
	#### 設定されたかsubで読み込んで確認した結果を表示したい ####
	Kpsub=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"Kp"'|awk '{print $2}'`
        Tdsub=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"Td"'|awk '{print $2}'`
	Tisub=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"Ti"'|awk '{print $2}'`
	echo "$(eval_gettext 'Set by random numbers')"
	#echo "乱数で設定"
	echo "Kp:$randKp1, Td:$randTd1, Ti:$randTi1"

	echo "$(eval_gettext 'Loading with sub')"
	#echo "subで読み込み"
	echo "Kp:$Kpsub, Td:$Tdsub, Ti:$Tisub"
}

#PID制御設定値の変更
ex_pid () {
	echo
        echo "******************************************************************"
        echo "$(eval_gettext 'Changes the PID control setpoint.')"
        #echo "PID制御設定値を変更します"
	#Kpの制御設定値
	mosquitto_pub -h localhost -t snk/1 -m "{\"Kp\": $1}"
	#Tdの制御設定値
	mosquitto_pub -h localhost -t snk/1 -m "{\"Td\": $2}"
	#Tiの制御設定値
	mosquitto_pub -h localhost -t snk/1 -m "{\"Ti\": $3}"
	#### 設定されたかsubで読み込んで確認した結果を表示したい ####
        Kpsub=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"Kp"'|awk '{print $2}'`
        Tdsub=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"Td"'|awk '{print $2}'`
        Tisub=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"Ti"'|awk '{print $2}'`
	echo "$(eval_gettext 'Set to the following PID control parameters')"
	#echo "以下のPID制御パラメータに設定"
	echo "Kp:$1, Td:$2, Ti:$3"

	echo "$(eval_gettext 'Loading with sub')"
        #echo "subで読み込み"
        echo "Kp:$Kpsub, Td:$Tdsub, Ti:$Tisub"
}

#ヒーター出口温度の上昇
ex_tempup () {
        temp=$1

	echo
	echo "******************************************************************"
        printf "$(eval_gettext 'Raises the measured temperature (y) of PID1 to %s°C')\n"
        "$temp"
	#echo "PID1の計測温度(y)を$temp℃まで上げます"

	y=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"y"'|awk '{print $2}'`
	until [ `echo "$y >= $temp"|bc` == 1 ]
	do
    		y=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"y"'|awk '{print $2}'`
	done
        printf "$(eval_gettext 'Measured temperature (y) of PID1 has increased to %s°C')\n"
        "$temp"
	#echo "PID1の計測温度(y)が$temp℃まで上昇しました"
}

#モード切替、実験開始時刻記録
ex_time () {
	#実験開始時刻
	echo
	echo "******************************************************************"
        echo "$(eval_gettext 'Start of experiment')"
	#echo "実験開始"
	time2=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"time"'|awk '{print $2}'`
	time3=${time2/%?/}
	time4=$(date -d @$time3)
        printf "$(eval_gettext 'Experiment start time:%s')\n"
        "$temp"
	#echo "実験開始時刻:$time4"

        #atモードに切り替え
        echo "$(eval_gettext 'Switch to AUTO mode')"
        #echo "ATモードに切り替え"
        mosquitto_pub -h localhost -t snk/1 -m '{"PID1-AT/MT-remote": 0}'
        mosquitto_pub -h localhost -t snk/1 -m '{"PID2-AT/MT-remote": 0}'
}


#ランダム設定
ex_pid_schedule () {
	echo
	echo "******************************************************************"
        echo "$(eval_gettext 'pid control parameters, electric heater output schedule random setting')"
	#echo "pid制御パラメータ、電気ヒーター出力スケジュールランダム設定"
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
			printf "$(eval_gettext 'Load factor %s % Experiment time %s')\n"
        		"$r_schedule" "$r_etime"
			#echo "負荷率:$r_schedule % 実験時間:$r_etime"
			mosquitto_pub -h localhost -t snk/1 -m "{\"Heater-value-remote\": $r_schedule}"
			sleep "$r_etime"
		done
	done
}

#実験開始
ex_start () {
        printf "$(eval_gettext 'Load factor:%s % Experiment time:%s')\n"
        "$1" "$2"
	#echo "負荷率$1% 実験時間$2"
	mosquitto_pub -h localhost -t snk/1 -m "{\"Heater-value-remote\": $1}"
	etime="$2"
	sleep "$etime"
}

#実験終了
ex_fin () {
	echo
        echo "******************************************************************"
        echo "$(eval_gettext 'End of experiment')"
	#echo "実験終了"

	#装置停止
	mosquitto_pub -h localhost -t snk/1 -m '{"Heater-value-remote": 0}'
	mosquitto_pub -h localhost -t snk/1 -m '{"on/off-remote": 0}'
	echo "$(eval_gettext 'Equipment has been shut down.')"
	#echo "装置を停止しました"

	#時刻計算
	time2=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"time"'|awk '{print $2}'`
	time3=${time2/%?/}
	time4=$(date -d @$time3)

	#ファイル保存
	time=`date '+%Y%m%d_%H%M%S'`
	mkdir -p result_${time}
	cp -pr $DEST/data result_${time}/
        printf "$(eval_gettext 'Copied %s/data to result_%s/data.')\n"
        "$DEST" "$time"
	#echo "$DEST/dataをresult_${time}/dataにコピーしました。"
	cp -pr $DEST/output result_${time}/
        printf "$(eval_gettext 'Copied %s/data to result_%s/output.')\n"
        "$DEST" "$time"
	#echo "$DEST/outputをresult_${time}/outputにコピーしました。"

        printf "$(eval_gettext 'Experiment end time:%s')\n"
        "$time4"
	#echo "実験終了時刻:$time4"
}
