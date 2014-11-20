
  CREATE OR REPLACE FORCE VIEW "APPS"."XXINV_INFO_SEC_V" ("USER_ID", "INVENTORY_LOCATION_ID", "SEGMENT1", "DESCRIPTION", "CUSTOMER_STOCK_WHSE") AS 
  SELECT
        fu.user_id                  -- ユーザーID
       ,xilv.inventory_location_id  -- 保管場所ID
       ,xilv.segment1               -- 保管倉庫コード
       ,xilv.description            -- 摘要
-- 2009-03-16 H.Iida ADD START 本番障害#1313
       ,xilv.customer_stock_whse    -- 相手先在庫管理倉庫
-- 2009-03-16 H.Iida ADD END
  FROM
        fnd_user            fu     -- ユーザーマスタ
       ,per_all_people_f    papf   -- 従業員割当マスタ
       ,xxcmn_item_locations_v  xilv    -- OPM保管場所VIEW
  WHERE
        fu.employee_id   = papf.person_id
    AND papf.attribute4  = xilv.purchase_code
    AND TRUNC(SYSDATE)   BETWEEN TRUNC(papf.effective_start_date)
                         AND     TRUNC(papf.effective_end_date)
    AND papf.attribute3 = '2'
  UNION
  SELECT
        fu.user_id                  -- ユーザーID
       ,xilv2.inventory_location_id -- 保管場所ID
       ,xilv2.segment1              -- 保管倉庫コード
       ,xilv2.description           -- 摘要
-- 2009-03-16 H.Iida ADD START 本番障害#1313
       ,xilv2.customer_stock_whse   -- 相手先在庫管理倉庫
-- 2009-03-16 H.Iida ADD END
  FROM
        fnd_user           fu      -- ユーザーマスタ
       ,per_all_people_f   papf    -- 従業員割当マスタ
       ,xxcmn_item_locations_v  xilv    -- OPM保管場所VIEW
       ,xxcmn_item_locations_v  xilv2   -- OPM保管場所VIEW
  WHERE
        fu.employee_id    = papf.person_id
    AND papf.attribute4   = xilv.purchase_code
    AND xilv.segment1     = xilv2.frequent_whse_code
    AND TRUNC(SYSDATE)    BETWEEN TRUNC(papf.effective_start_date)
                          AND     TRUNC(papf.effective_end_date)
    AND papf.attribute3 = '2'
  UNION
  SELECT
        -1                          -- ユーザーID
       ,xilv.inventory_location_id  -- 保管場所ID
       ,xilv.segment1               -- 保管倉庫コード
       ,xilv.description            -- 摘要
-- 2009-03-16 H.Iida ADD START 本番障害#1313
       ,xilv.customer_stock_whse    -- 相手先在庫管理倉庫
-- 2009-03-16 H.Iida ADD END
  FROM
        xxcmn_item_locations_v xilv -- OPM保管場所VIEW
        ;
 