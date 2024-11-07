/*
テーブルリリース用スクリプト

XXCCD_USER_ROLE_TMPの下記項目を変更するためのALTER文スクリプト(ステップ1)

・INSTANCE_IDの型をVARCHAR2(22)に変更

●使い方
①このファイルを指定して実行
②2．の最大サイズがVARCHAR(22)を超えていない、かつ3．の件数が一致していればCOMMITを行う
*/

prompt 1．XXCCD_USER_ROLE_TMPのデータをコピーした、退避用ワークテーブルを作成
CREATE TABLE XXCCD_USER_ROLE_TMP_wk AS SELECT * FROM XXCCD_USER_ROLE_TMP;

prompt 2．インスタンスID格納項目の最大サイズ確認
prompt 件数：XXCCD_USER_ROLE_TMP_wk
select MAX(LENGTH(INSTANCE_ID)) FROM XXCCD_USER_ROLE_TMP_wk;

prompt 3．XXCCD_USER_ROLE_TMPと退避用ワークテーブルの件数確認
prompt 3-1．XXCCD_USER_ROLE_TMP_wk
select count(*) FROM XXCCD_USER_ROLE_TMP_wk;

prompt 3-2．XXCCD_USER_ROLE_TMP
select count(*) FROM XXCCD_USER_ROLE_TMP;

prompt 4．XXCCD_USER_ROLE_TMPのデータを削除
DELETE FROM XXCCD_USER_ROLE_TMP;

prompt 2．の最大サイズがVARCHAR(22)を超えていない、かつ3．の件数が一致していればCOMMITを行う
