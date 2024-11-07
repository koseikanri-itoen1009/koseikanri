/*
テーブルリリース用スクリプト

XXCCD_USER_ROLE_BKの下記項目を変更するためのALTER文スクリプト(ステップ2)

・UPDATE_IDの型をVARCHAR2(22)に変更

●使い方
①このファイルを指定して実行
②7．の件数が一致していればCOMMITを行う
*/

prompt 5．ALTER文実行
prompt 5-1．UPDATE_IDの型変更
ALTER TABLE XXCCD_USER_ROLE_BK MODIFY (UPDATE_ID VARCHAR2 (22));

prompt 6．退避用ワークテーブルからXXCCD_USER_ROLE_BKにデータを戻す
  INSERT INTO XXCCD_USER_ROLE_BK
    SELECT * FROM
      XXCCD_USER_ROLE_BK_wk;

prompt 7．XXCCD_USER_ROLE_BKと退避用ワークテーブルの件数確認
prompt 7-1．XXCCD_USER_ROLE_BK_wk
select count(*) FROM XXCCD_USER_ROLE_BK_wk;

prompt 7-2．XXCCD_USER_ROLE_BK
select count(*) FROM XXCCD_USER_ROLE_BK;

prompt 7．の件数が一致していればCOMMITを行う
