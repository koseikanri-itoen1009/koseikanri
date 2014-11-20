CREATE OR REPLACE FORCE VIEW "APPS"."XXINV_STC_LOV_INFO_SEC_V" (
   "USER_ID"
  ,"WHSE_CODE"
  ,"WHSE_NAME"
  ) AS 
  SELECT
    INFO_SEC.USER_ID,              -- ユーザーID
    INFO_SEC.WHSE_CODE,            -- 倉庫コード
    INFO_SEC.WHSE_NAME             -- 摘要
  FROM(
       SELECT
         FU.USER_ID,                  -- ユーザーID
         IWM.WHSE_CODE,               -- 倉庫コード
         IWM.WHSE_NAME                -- 摘要
       FROM
         FND_USER FU,                    -- ユーザーマスタ
         PER_ALL_PEOPLE_F PAPF,          -- 従業員割当マスタ
         MTL_ITEM_LOCATIONS MIL,         -- OPM保管場所マスタ
         HR_ALL_ORGANIZATION_UNITS HAOU, -- 在庫組織マスタ
         IC_WHSE_MST IWM                 -- OPM倉庫マスタ
       WHERE
         FU.EMPLOYEE_ID = PAPF.PERSON_ID
       AND TRUNC(SYSDATE) BETWEEN TRUNC(PAPF.EFFECTIVE_START_DATE)
                          AND TRUNC(PAPF.EFFECTIVE_END_DATE)
       AND PAPF.ATTRIBUTE4 = MIL.ATTRIBUTE13
       AND HAOU.ORGANIZATION_ID    =   MIL.ORGANIZATION_ID
       AND IWM.MTL_ORGANIZATION_ID =   HAOU.ORGANIZATION_ID
       AND HAOU.DATE_FROM          <=  TRUNC(SYSDATE)
       AND ( HAOU.DATE_TO IS NULL
         OR  HAOU.DATE_TO >= TRUNC(SYSDATE) )
       AND MIL.DISABLE_DATE        IS NULL
       UNION
       SELECT
         FU.USER_ID,                  -- ユーザーID
         IWM.WHSE_CODE,               -- 倉庫コード
         IWM.WHSE_NAME                -- 摘要
       FROM
         FND_USER FU,                    -- ユーザーマスタ
         PER_ALL_PEOPLE_F PAPF,          -- 従業員割当マスタ
         MTL_ITEM_LOCATIONS MIL,         -- OPM保管場所マスタ
         MTL_ITEM_LOCATIONS MIL2,        -- OPM保管場所マスタ
         HR_ALL_ORGANIZATION_UNITS HAOU, -- 在庫組織マスタ
         IC_WHSE_MST IWM                 -- OPM倉庫マスタ
       WHERE
         FU.EMPLOYEE_ID = PAPF.PERSON_ID
       AND TRUNC(SYSDATE) BETWEEN TRUNC(PAPF.EFFECTIVE_START_DATE)
                          AND TRUNC(PAPF.EFFECTIVE_END_DATE)
       AND PAPF.ATTRIBUTE4 = MIL.ATTRIBUTE13
       AND MIL.SEGMENT1  = MIL2.ATTRIBUTE8
       AND HAOU.ORGANIZATION_ID    =  MIL2.ORGANIZATION_ID
       AND IWM.MTL_ORGANIZATION_ID =  HAOU.ORGANIZATION_ID
       AND HAOU.DATE_FROM          <= TRUNC(SYSDATE)
       AND ( HAOU.DATE_TO IS NULL
         OR  HAOU.DATE_TO >= TRUNC(SYSDATE) )
       AND MIL.DISABLE_DATE  IS NULL
       AND MIL2.DISABLE_DATE IS NULL
       ) INFO_SEC
  GROUP BY INFO_SEC.USER_ID,
           INFO_SEC.WHSE_CODE,
           INFO_SEC.WHSE_NAME
  ;
--
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.USER_ID  IS 'ユーザーID';
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.WHSE_CODE  IS '倉庫コード';
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.WHSE_NAME  IS '倉庫名';
--
COMMENT ON TABLE  XXINV_STC_LOV_INFO_SEC_V IS '在庫_値セット用VIEW_情報セキュリティ' ;

/