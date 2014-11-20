--********************************************************************
-- 制御ファイル  : XXCMM002A11D.ctl
-- 機能概要      : 社員データ取込データロード
-- バージョン    : 1.0
-- 作成者        : SCS 佐々木 世都
-- 作成日        : 2009-01-23
-- 変更者        : SCS 吉川 博章
-- 最終変更日    : 2009-03-10
-- 変更履歴      :
--     2009-01-23 新規作成
--     2009-03-10 所属コード（旧）と勤務地拠点コード（旧）を入れ替え対応
--
--********************************************************************
OPTIONS (DIRECT=FALSE, ERRORS=2147483647)
LOAD DATA
CHARACTERSET JA16SJIS
INFILE '/ebs/ebsd03/ebsif/inbound/ad_iffile/na/TNAADM_CMM002A01.csv'
APPEND
INTO TABLE XXCMM_IN_PEOPLE_IF
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
       (
        EMPLOYEE_NUMBER                   ,
        HIRE_DATE
            NULLIF HIRE_DATE = BLANKS
            "TO_DATE(:HIRE_DATE,'yyyy/mm/dd')",
        ACTUAL_TERMINATION_DATE
            NULLIF ACTUAL_TERMINATION_DATE = BLANKS
            "TO_DATE(:ACTUAL_TERMINATION_DATE,'yyyy/mm/dd')",
        LAST_NAME_KANJI                   ,
        FIRST_NAME_KANJI                  ,
        LAST_NAME                         ,
        FIRST_NAME                        ,
        SEX                               ,
        EMPLOYEE_DIVISION                 ,
        LOCATION_CODE                     ,
        CHANGE_CODE                       ,
        ANNOUNCE_DATE                     ,
        OFFICE_LOCATION_CODE              ,
        LICENSE_CODE                      ,
        LICENSE_NAME                      ,
        JOB_POST                          ,
        JOB_POST_NAME                     ,
        JOB_DUTY                          ,
        JOB_DUTY_NAME                     ,
        JOB_TYPE                          ,
        JOB_TYPE_NAME                     ,
        JOB_SYSTEM                        ,
        JOB_SYSTEM_NAME                   ,
        JOB_POST_ORDER                    ,
        CONSENT_DIVISION                  ,
        AGENT_DIVISION                    ,
        LOCATION_CODE_OLD                 ,
        OFFICE_LOCATION_CODE_OLD          ,
        LICENSE_CODE_OLD                  ,
        LICENSE_CODE_NAME_OLD             ,
        JOB_POST_OLD                      ,
        JOB_POST_NAME_OLD                 ,
        JOB_DUTY_OLD                      ,
        JOB_DUTY_NAME_OLD                 ,
        JOB_TYPE_OLD                      ,
        JOB_TYPE_NAME_OLD                 ,
        JOB_SYSTEM_OLD                    ,
        JOB_SYSTEM_NAME_OLD               ,
        JOB_POST_ORDER_OLD                ,
        CONSENT_DIVISION_OLD              ,
        AGENT_DIVISION_OLD
        )