ALTER TABLE XXCOS.XXCOS_EDI_ERRORS  ADD (
  ERR_MESSAGE_CODE                 VARCHAR2(20)        NULL                               -- エラーメッセージコード
 ,EDI_ITEM_NAME                    VARCHAR2(20)        NULL                               -- EDI品目名称
 ,EDI_RECEIVED_DATE                DATE                NULL                               -- EDI受信日
 ,ERR_LIST_OUT_FLAG                VARCHAR2(2)         NULL                               -- 受注エラーリスト出力済フラグ
);
--
COMMENT ON COLUMN XXCOS.XXCOS_EDI_ERRORS.ERR_MESSAGE_CODE                            IS  'エラーメッセージコード';
COMMENT ON COLUMN XXCOS.XXCOS_EDI_ERRORS.EDI_ITEM_NAME                               IS  'EDI品目名称';
COMMENT ON COLUMN XXCOS.XXCOS_EDI_ERRORS.EDI_RECEIVED_DATE                           IS  'EDI受信日';
COMMENT ON COLUMN XXCOS.XXCOS_EDI_ERRORS.ERR_LIST_OUT_FLAG                           IS  '受注エラーリスト出力済フラグ';
