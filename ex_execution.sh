#!/bin/bash

#関数ファイル読み込み
DIR=$(cd $(dirname -- $0); pwd)
source $DIR/ex_function.sh

#実験準備
ex_erase output data

#PID設定温度(目標温度SV)の設定
ex_pidSV2 42.0 36.0

#PID制御設定値の変更(Kp,Td,Ti)
#ex_pid 0.09976 257.5 623.2

#PID制御値ランダム設定
ex_pidrandam

#暖機運転開始
ex_warm

#ヒーター出口温度の上昇
ex_tempup 44.0

#モード切替,実験開始時刻
ex_time

#PID制御設定値・電気ヒータスケジュールランダム設定
#ex_pid_schedule

#実験開始(負荷率,実験時間)
ex_start 100 1h
ex_start 75 1h
ex_start 50 1.5h
ex_start 75 1.5h
ex_start 100 1.5h

#実験終了
ex_fin
