/*
テーブルリリース用スクリプト

XXCCD_USER_ROLE_BKの下記項目を変更するためのALTER文スクリプト(ステップ1)

・UPDATE_IDの型をVARCHAR2(22)に変更

●使い方
①このファイルを指定して実行
②2．の最大サイズがVARCHAR(22)を超えていない、かつ3．の件数が一致していればCOMMITを行う
*/

prompt 1．XXCCD_USER_ROLE_BKのデータをコピーした、退避用ワークテーブルを作成
CREATE TABLE XXCCD_USER_ROLE_BK_wk AS SELECT * FROM XXCCD_USER_ROLE_BK;

prompt 2．インスタンスID格納項目の最大サイズ確認
prompt 件数：XXCCD_USER_ROLE_BK_wk
select MAX(LENGTH(UPDATE_ID)) FROM XXCCD_USER_ROLE_BK;

prompt 3．XXCCD_USER_ROLE_BKと退避用ワークテーブルの件数確認
prompt 3-1．XXCCD_USER_ROLE_BK_wk
select count(*) FROM XXCCD_USER_ROLE_BK_wk;

prompt 3-2．XXCCD_USER_ROLE_BK
select count(*) FROM XXCCD_USER_ROLE_BK;

prompt 4．XXCCD_USER_ROLE_BKのデータを削除
DELETE FROM XXCCD_USER_ROLE_BK;

prompt 2．の最大サイズがVARCHAR(22)を超えていない、かつ3．の件数が一致していればCOMMITを行う
