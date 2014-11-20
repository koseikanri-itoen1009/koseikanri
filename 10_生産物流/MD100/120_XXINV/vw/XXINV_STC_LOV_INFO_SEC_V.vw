CREATE OR REPLACE FORCE VIEW "APPS"."XXINV_STC_LOV_INFO_SEC_V" (
   "USER_ID"
  ,"WHSE_CODE"
  ,"WHSE_NAME"
  ) AS 
  SELECT
    info_sec.user_id,              -- ユーザーID
    info_sec.whse_code,            -- 倉庫コード
    info_sec.whse_name             -- 摘要
  FROM(
       SELECT
         fu.user_id,                  -- ユーザーID
         iwm.whse_code,               -- 倉庫コード
         iwm.whse_name                -- 摘要
       FROM
         fnd_user                  fu,   -- ユーザーマスタ
         per_all_people_f          papf, -- 従業員割当マスタ
         mtl_item_locations        mil,  -- OPM保管場所マスタ
         hr_all_organization_units haou, -- 在庫組織マスタ
         ic_whse_mst               iwm   -- OPM倉庫マスタ
       WHERE fu.employee_id           = papf.person_id
       AND   TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)
                                AND TRUNC(papf.effective_end_date)
       AND   papf.attribute4          = mil.attribute13
       AND   papf.attribute3          = '2'
       AND   haou.organization_id     = mil.organization_id
       AND   iwm.mtl_organization_id  = haou.organization_id
       AND   haou.date_from          <=  TRUNC(SYSDATE)
       AND ( haou.date_to            IS NULL
         OR  haou.date_to            >= TRUNC(SYSDATE) )
       AND   mil.disable_date        IS NULL
       UNION
       SELECT
         fu.user_id,                  -- ユーザーID
         iwm.whse_code,               -- 倉庫コード
         iwm.whse_name                -- 摘要
       FROM
         fnd_user                  fu,   -- ユーザーマスタ
         per_all_people_f          papf, -- 従業員割当マスタ
         mtl_item_locations        mil,  -- OPM保管場所マスタ
         mtl_item_locations        mil2, -- OPM保管場所マスタ
         hr_all_organization_units haou, -- 在庫組織マスタ
         ic_whse_mst               iwm   -- OPM倉庫マスタ
       WHERE fu.employee_id           = papf.person_id
       AND   TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)
                                AND TRUNC(papf.effective_end_date)
       AND   papf.attribute4          = mil.attribute13
       AND   papf.attribute3          = '2'
       AND   mil.segment1             = mil2.attribute8
       AND   haou.organization_id     = mil2.organization_id
       AND   iwm.mtl_organization_id  = haou.organization_id
       AND   haou.date_from          <= TRUNC(SYSDATE)
       AND ( haou.date_to            IS NULL
         OR  haou.date_to            >= TRUNC(SYSDATE) )
       AND   mil.disable_date        IS NULL
       AND   mil2.disable_date       IS NULL
       UNION
       SELECT
         fu.user_id,                  -- ユーザーID
         iwm.whse_code,               -- 倉庫コード
         iwm.whse_name                -- 摘要
       FROM
         fnd_user                  fu,   -- ユーザーマスタ
         per_all_people_f          papf, -- 従業員割当マスタ
         mtl_item_locations        mil,  -- OPM保管場所マスタ
         hr_all_organization_units haou, -- 在庫組織マスタ
         ic_whse_mst               iwm   -- OPM倉庫マスタ
       WHERE fu.employee_id           = papf.person_id
       AND   TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)
                                AND TRUNC(papf.effective_end_date)
       AND   papf.attribute3          = '1'
       AND   haou.organization_id     = mil.organization_id
       AND   iwm.mtl_organization_id  = haou.organization_id
       AND   haou.date_from          <= TRUNC(SYSDATE)
       AND ( haou.date_to            IS NULL
         OR  haou.date_to            >= TRUNC(SYSDATE) )
       AND   mil.disable_date        IS NULL
       ) INFO_SEC
  GROUP BY info_sec.user_id,
           info_sec.whse_code,
           info_sec.whse_name
  ;
--
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.USER_ID  IS 'ユーザーID';
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.WHSE_CODE  IS '倉庫コード';
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.WHSE_NAME  IS '倉庫名';
--
COMMENT ON TABLE  XXINV_STC_LOV_INFO_SEC_V IS '在庫_値セット用VIEW_情報セキュリティ' ;

/