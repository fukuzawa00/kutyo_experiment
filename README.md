# 空調制御実験スケジュール運転自動化プログラム

## ファイル
- ex_function.sh: シナリオ作成のためのライブラリ関数群
  - ex_execution.sh: サンプルシナリオ
  - ex_execution2.sh: サンプルシナリオ
  - ex_execution3.sh: サンプルシナリオ

  - ex_execution_snk.sh: 新日本空調環境での自動試験シナリオ
  - ex_execution_fin.sh: 終了処理のみ強制的に呼び出すシナリオ

- scheduler_fun.sh: スケジュール運転のためのライブラリ関数群
  - scheduler_test.sh: スケジュール運転のサンプル
  - scheduler_test2.sh: スケジュール運転のサンプル

- test.sh: お試し用
- test2.sh: お試し用


## ex_function.sh内の関数
- ex_erase: 実験準備。デーモンの停止起動、ログの消去など。
- ex_time: モード切替、実験開始時刻記録
- ex_warm: 暖機運転開始
- ex_tempup: 室温が指定値に上がるまで待つ。引数: 目標室温
- ex_set_value: レジスタの設定値変更。引数: レジスタ名 値
  - ex_pidSV: rの設定。"ex_set_value r 値"と同じ。
  - ex_pidSV2: r, r1の設定。"ex_set_value r 値; ex_set_value r1 値"と同じ。
  - ex_pid: PID制御設定値の変更。"ex_set_value Kp 値; ex_set_value: Td 値; ex_setvalue Ti 値"と同じ。
- ex_wait: 待ち時間。引数: 60s, 60mなど
- ex_fin: ログ保存、終了処理など。

- ex_pidrandam: 未
- ex_pid_schedule: 未
- ex_start: 未


## scheduler_fun.sh内の関数
- 未


## 表示の英語化
- 現場環境など、日本語が表示できない環境でも使えるようにしたい。
- https://docs.oracle.com/cd/E19455-01/806-2802/6jc0bne56/index.html
