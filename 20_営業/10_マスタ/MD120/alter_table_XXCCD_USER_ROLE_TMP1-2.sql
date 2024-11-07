/*
テーブルリリース用スクリプト

XXCCD_USER_ROLE_TMPの下記項目を変更するためのALTER文スクリプト(ステップ2)

・INSTANCE_IDの型をVARCHAR2(22)に変更

●使い方
①このファイルを指定して実行
②7．の件数が一致していればCOMMITを行う
*/

prompt 5．ALTER文実行
prompt 5-1．INSTANCE_IDの型変更
ALTER TABLE XXCCD_USER_ROLE_TMP MODIFY (INSTANCE_ID VARCHAR2 (22));

prompt 6．退避用ワークテーブルからXXCCD_USER_ROLE_TMPにデータを戻す
  INSERT INTO XXCCD_USER_ROLE_TMP
    SELECT * FROM
      XXCCD_USER_ROLE_TMP_wk;

prompt 7．XXCCD_USER_ROLE_TMPと退避用ワークテーブルの件数確認
prompt 7-1．XXCCD_USER_ROLE_TMP_wk
select count(*) FROM XXCCD_USER_ROLE_TMP_wk;

prompt 7-2．XXCCD_USER_ROLE_TMP
select count(*) FROM XXCCD_USER_ROLE_TMP;

prompt 7．の件数が一致していればCOMMITを行う
