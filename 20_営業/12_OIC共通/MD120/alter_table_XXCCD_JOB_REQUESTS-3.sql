/*
テーブルリリース用スクリプト

XXCCD_JOB_REQUESTSの下記項目を変更するためのALTER文スクリプト(ステップ3)

・INSTANCE_IDの型をVARCHAR2(22)に変更
・ERROR_DETAILの桁数を4000に拡張
・CREATED_BYの桁数を113に拡張
・LAST_UPDATED_BYの桁数を113に拡張

●使い方
①このファイルを指定して実行
*/

prompt 8．退避用ワークテーブルの削除
DROP TABLE XXCCD_JOB_REQUESTS_wk;
