#!/bin/bash

#ファイル読み込み
DIR=$(cd $(dirname $0); pwd)
source $DIR/sckeduler_fun.sh

#設定
R1=20 #(2)初期設定温度
R2=30 #(3)この温度まで上昇・下降させる
R3=15 #(5)終了温度
S=5 #(3)(4)rの上げ下げ温度
M=15 #運転時間

#スケジューラー
scheduler1 $R1 $R2 $R3 $S $M
