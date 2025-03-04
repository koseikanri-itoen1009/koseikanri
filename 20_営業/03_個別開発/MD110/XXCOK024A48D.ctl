--********************************************************************
-- 制御ファイル  : XXCOK024A48D.ctl
-- 機能概要      : 控除支払承認ステータスロード
-- バージョン    : 1.0
-- 作成者        : SCSK 郭 有司
-- 作成日        : 2024-12-12
-- 変更者        : SCSK 郭 有司
-- 最終変更日    : 2024-12-12
-- 変更履歴      :
--     2024-12-12 新規作成
--
--********************************************************************
OPTIONS (DIRECT=FALSE, ERRORS=2147483647)
LOAD DATA
CHARACTERSET JA16SJIS
INFILE 'xxxxxxxxxxx'
APPEND
INTO TABLE XXCOK_DEDUCTION_RECON_STATUS
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
       (
        RECON_STATUS_ID         SEQUENCE(MAX)                               ,
        RECON_SLIP_NUM                                                      ,
        STATUS                                                              ,
        APPROVAL_DATE           "TO_DATE(:APPROVAL_DATE,'yyyy/mm/dd')"      ,
        APPROVER                                                            ,
        CANCELLATION_DATE       "TO_DATE(:CANCELLATION_DATE,'yyyy/mm/dd')"  ,
        PROCESSED_FLAG          CONSTANT "N"                                ,
        CREATED_BY              CONSTANT "-1"                               ,
        CREATION_DATE           SYSDATE                                     ,
        LAST_UPDATED_BY         CONSTANT "-1"                               ,
        LAST_UPDATE_DATE        SYSDATE                                     ,
        LAST_UPDATE_LOGIN       CONSTANT "-1"                               ,
        REQUEST_ID              CONSTANT "-1"                               ,
        PROGRAM_APPLICATION_ID  CONSTANT "-1"                               ,
        PROGRAM_ID              CONSTANT "-1"                               ,
        PROGRAM_UPDATE_DATE     SYSDATE
        )
