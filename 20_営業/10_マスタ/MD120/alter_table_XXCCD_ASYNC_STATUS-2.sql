/*
テーブルリリース用スクリプト

XXCCD_ASYNC_STATUSの下記項目を変更するためのALTER文スクリプト(ステップ2)

・INSTANCE_IDの型をVARCHAR2(22)に変更
・ERROR_DETAILの桁数を4000に拡張

●使い方
①このファイルを指定して実行
②7．の件数が一致していればCOMMITを行う
*/

prompt 5．ALTER文実行
prompt 5-1．INSTANCE_IDの型変更
ALTER TABLE XXCCD_ASYNC_STATUS MODIFY (INSTANCE_ID VARCHAR2 (22));

prompt 5-2．ERROR_DETAILの桁数拡張
ALTER TABLE XXCCD_ASYNC_STATUS MODIFY (ERROR_DETAIL VARCHAR2 (4000));

prompt 6．退避用ワークテーブルからXXCCD_ASYNC_STATUSにデータを戻す
  INSERT INTO XXCCD_ASYNC_STATUS
    SELECT * FROM
      XXCCD_ASYNC_STATUS_wk;

prompt 7．XXCCD_ASYNC_STATUSと退避用ワークテーブルの件数確認
prompt 7-1．XXCCD_ASYNC_STATUS_wk
select count(*) FROM XXCCD_ASYNC_STATUS_wk;

prompt 7-2．XXCCD_ASYNC_STATUS
select count(*) FROM XXCCD_ASYNC_STATUS;

prompt 7．の件数が一致していればCOMMITを行う
