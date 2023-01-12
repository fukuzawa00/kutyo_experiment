#!/bin/bash

#関数ファイル読み込み
DIR=$(cd $(dirname $0); pwd)
source $DIR/ex_function.sh

WAIT=15m
#WAIT=1s # debug

#実験準備
ex_prepare erase

#実験開始
ex_time

#指定した室温設定値で指定した時間ずつ運転
for i in 15.0 20.0 25.0 30.0 25.0 20.0 15.0; do
    ex_pidSV $i
    ex_wait $WAIT
done

#実験終了
ex_fin
