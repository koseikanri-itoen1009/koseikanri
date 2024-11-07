/*
テーブルリリース用スクリプト

XXCCD_EMPLOYEE_DIFFERENCE_INFOの下記項目を変更するためのALTER文スクリプト(ステップ3)

・INSTANCE_IDの型をVARCHAR2(22)に変更

●使い方
①このファイルを指定して実行
*/

prompt 8．退避用ワークテーブルの削除
DROP TABLE XXCCD_EMPLOYEE_DIFFERENCE_INFO_wk;
