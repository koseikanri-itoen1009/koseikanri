
  CREATE OR REPLACE FORCE VIEW "APPS"."XXINV_INFO_SEC_V" ("USER_ID", "INVENTORY_LOCATION_ID", "SEGMENT1", "DESCRIPTION", "CUSTOMER_STOCK_WHSE") AS 
  SELECT
        fu.user_id                  -- [U[ID
       ,xilv.inventory_location_id  -- ÛÇêID
       ,xilv.segment1               -- ÛÇqÉR[h
       ,xilv.description            -- Ev
-- 2009-03-16 H.Iida ADD START {ÔáQ#1313
       ,xilv.customer_stock_whse    -- èæÝÉÇqÉ
-- 2009-03-16 H.Iida ADD END
  FROM
        fnd_user            fu     -- [U[}X^
       ,per_all_people_f    papf   -- ]Æõ}X^
       ,xxcmn_item_locations_v  xilv    -- OPMÛÇêVIEW
  WHERE
        fu.employee_id   = papf.person_id
    AND papf.attribute4  = xilv.purchase_code
    AND TRUNC(SYSDATE)   BETWEEN TRUNC(papf.effective_start_date)
                         AND     TRUNC(papf.effective_end_date)
    AND papf.attribute3 = '2'
  UNION
  SELECT
        fu.user_id                  -- [U[ID
       ,xilv2.inventory_location_id -- ÛÇêID
       ,xilv2.segment1              -- ÛÇqÉR[h
       ,xilv2.description           -- Ev
-- 2009-03-16 H.Iida ADD START {ÔáQ#1313
       ,xilv2.customer_stock_whse   -- èæÝÉÇqÉ
-- 2009-03-16 H.Iida ADD END
  FROM
        fnd_user           fu      -- [U[}X^
       ,per_all_people_f   papf    -- ]Æõ}X^
       ,xxcmn_item_locations_v  xilv    -- OPMÛÇêVIEW
       ,xxcmn_item_locations_v  xilv2   -- OPMÛÇêVIEW
  WHERE
        fu.employee_id    = papf.person_id
    AND papf.attribute4   = xilv.purchase_code
    AND xilv.segment1     = xilv2.frequent_whse_code
    AND TRUNC(SYSDATE)    BETWEEN TRUNC(papf.effective_start_date)
                          AND     TRUNC(papf.effective_end_date)
    AND papf.attribute3 = '2'
  UNION
  SELECT
        -1                          -- [U[ID
       ,xilv.inventory_location_id  -- ÛÇêID
       ,xilv.segment1               -- ÛÇqÉR[h
       ,xilv.description            -- Ev
-- 2009-03-16 H.Iida ADD START {ÔáQ#1313
       ,xilv.customer_stock_whse    -- èæÝÉÇqÉ
-- 2009-03-16 H.Iida ADD END
  FROM
        xxcmn_item_locations_v xilv -- OPMÛÇêVIEW
        ;
 