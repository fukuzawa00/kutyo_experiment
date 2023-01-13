#!/bin/bash

#ファイル読み込み
DIR=$(cd $(dirname -- $0); pwd)
source $DIR/scheduler_fun.sh

#設定
R=`mosquitto_sub -h localhost -t snk/0 -C 1|sed -e 's/,/\n/g'|grep '"r"'|awk '{print $2}'` #現在の設定温度(r)を取得
R1=10 #(2)初期設定温度
R2=30 #(3)この温度まで上昇・下降させる
R3=40 #(5)終了温度
S=5 #(3)(4)rの上げ下げ温度
M=15 #運転時間

#スケジューラー
scheduler $R1 $R2 $R3 $S $M
