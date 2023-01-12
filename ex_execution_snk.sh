#!/bin/bash

#関数ファイル読み込み
DIR=$(cd $(dirname $0); pwd)
source $DIR/ex_function.sh

# 指定した室温設定値で15分ずつ運転
for i in 15.0 20.0 25.0 30.0 25.0 20.0 15.0; do
    ex_pidSV $i
    ex_wait_min 15
done

#実験終了
ex_fin
