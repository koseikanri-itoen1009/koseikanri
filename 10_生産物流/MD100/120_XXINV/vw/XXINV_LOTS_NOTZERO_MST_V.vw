  CREATE OR REPLACE FORCE VIEW "APPS"."XXINV_LOTS_NOTZERO_MST_V" 
  (
    "ITEM_ID"
  , "LOT_ID"
  , "WHSE_CODE"
  , "LOCATION"
  ) AS 
  SELECT  ili.item_id
        , ili.lot_id
        , ili.whse_code
        , ili.location
  FROM    ic_loct_inv ili
  WHERE 
      (
        -- 手持数量が０以外
        (ili.loct_onhand <> 0)
        OR
        (
          ili.loct_onhand = 0 
          AND EXISTS
            (
              -- ic_tran_pnd に過去3ヶ月データがある
              SELECT 'X'
              FROM  ic_tran_pnd itp
              WHERE itp.item_id  = ili.item_id
              AND   itp.lot_id   = ili.lot_id
              AND   itp.location = ili.location
              AND   itp.trans_date > 
                    ADD_MONTHS(TO_DATE(TO_CHAR(SYSDATE,'YYYYMM')||'01','YYYYMMDD'),-3)
              AND   ROWNUM = 1
              UNION ALL
              -- ic_tran_cmp に過去3ヶ月データがある
              SELECT 'X'
              FROM  ic_tran_cmp itc
              WHERE itc.item_id  = ili.item_id
              AND   itc.lot_id   = ili.lot_id
              AND   itc.location = ili.location
              AND   itc.trans_date > 
                    ADD_MONTHS(TO_DATE(TO_CHAR(SYSDATE,'YYYYMM')||'01','YYYYMMDD'),-3)
              AND   ROWNUM = 1
            )
        )
      )
;

