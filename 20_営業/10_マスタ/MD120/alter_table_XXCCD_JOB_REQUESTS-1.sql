/*
テーブルリリース用スクリプト

XXCCD_JOB_REQUESTSの下記項目を変更するためのALTER文スクリプト(ステップ1)

・INSTANCE_IDの型をVARCHAR2(22)に変更
・ERROR_DETAILの桁数を4000に拡張
・CREATED_BYの桁数を113に拡張
・LAST_UPDATED_BYの桁数を113に拡張

●使い方
①このファイルを指定して実行
②2．の最大サイズがVARCHAR(22)を超えていない、かつ3．の件数が一致していればCOMMITを行う
*/

prompt 1．XXCCD_JOB_REQUESTSのデータをコピーした、退避用ワークテーブルを作成
CREATE TABLE XXCCD_JOB_REQUESTS_wk AS SELECT * FROM XXCCD_JOB_REQUESTS;

prompt 2．インスタンスID格納項目の最大サイズ確認
prompt 件数：XXCCD_JOB_REQUESTS_wk
select MAX(LENGTH(INSTANCE_ID)) FROM XXCCD_JOB_REQUESTS_wk;

prompt 3．XXCCD_JOB_REQUESTSと退避用ワークテーブルの件数確認
prompt 3-1．XXCCD_JOB_REQUESTS_wk
select count(*) FROM XXCCD_JOB_REQUESTS_wk;

prompt 3-2．XXCCD_JOB_REQUESTS
select count(*) FROM XXCCD_JOB_REQUESTS;

prompt 4．XXCCD_JOB_REQUESTSのデータを削除
DELETE FROM XXCCD_JOB_REQUESTS;

prompt 2．の最大サイズがVARCHAR(22)を超えていない、かつ3．の件数が一致していればCOMMITを行う
