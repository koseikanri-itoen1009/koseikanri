CREATE OR REPLACE VIEW xxinv_stc_entry_no_v
(
  ENTRY_NO
--2009/01/15 Add Start #3
 ,CLASS
--2009/01/15 Add End   #3
)
AS 
--2009/01/15 Add Start #3
SELECT TO_CHAR(gbh.batch_no) AS ENTRY_NO
      ,'1'                   AS CLASS
FROM   gme_batch_header             gbh                  -- 生産バッチ
      ,gmd_routings_b               grb                  -- 工順マスタ
WHERE  gbh.routing_id               = grb.routing_id
AND    gbh.batch_status        NOT IN (-1,4)
AND    grb.routing_class            = '70'
UNION
--2009/01/15 Add End   #3
SELECT DISTINCT TO_CHAR(gbh1.batch_no) AS ENTRY_NO
--2009/01/15 Add Start #3
      ,'2'                             AS CLASS
--2009/01/15 Add End   #3
FROM   xxcmn_rcv_pay_mst            xrpm1                 -- 受払区分アドオンマスタ
      ,gme_batch_header             gbh1                  -- 生産バッチ
      ,gme_material_details         gmd1                  -- 生産原料詳細
      ,gmd_routings_b               grb1                  -- 工順マスタ
      ,ic_tran_pnd                  itp1                  -- OPM保留在庫トランザクション
WHERE  gbh1.batch_id                = gmd1.batch_id
AND (( xrpm1.new_div_invent        IN ('310','311','320','321')
    AND xrpm1.line_type             = -1 )
  OR   xrpm1.new_div_invent         = xrpm1.new_div_invent )
AND    xrpm1.use_div_invent_rep     = 'Y'
AND    itp1.doc_type                = xrpm1.doc_type
AND    gbh1.batch_id                = gmd1.batch_id
AND    itp1.doc_id                  = gmd1.batch_id
AND    itp1.doc_line                = gmd1.line_no
AND    itp1.line_type               = gmd1.line_type
AND    itp1.completed_ind           = 1
AND    itp1.reverse_id             IS NULL
AND    grb1.routing_id              = gbh1.routing_id
AND    xrpm1.routing_class          = grb1.routing_class
AND    xrpm1.line_type              = gmd1.line_type
AND (( gmd1.attribute5             IS NULL )
  OR ( xrpm1.hit_in_div             = gmd1.attribute5 ))
UNION
SELECT DISTINCT ijm2.journal_no   AS ENTRY_NO
--2009/01/15 Add Start #3
      ,'2'                        AS CLASS
--2009/01/15 Add End   #3
FROM   xxcmn_rcv_pay_mst            xrpm2                       -- 受払区分アドオンマスタ
      ,ic_adjs_jnl                  iaj2                        -- OPM在庫調整ジャーナル
      ,ic_jrnl_mst                  ijm2                        -- OPMジャーナルマスタ
      ,ic_tran_cmp                  itc2                        -- OPM完了在庫トランザクション
WHERE  xrpm2.doc_type               = 'ADJI'
AND    xrpm2.use_div_invent_rep     = 'Y'
AND    itc2.doc_type                = xrpm2.doc_type
AND    itc2.reason_code             = xrpm2.reason_code
AND    SIGN( itc2.trans_qty )       = xrpm2.rcv_pay_div
AND    iaj2.journal_id              = ijm2.journal_id
AND    itc2.doc_type                = iaj2.trans_type
AND    itc2.doc_id                  = iaj2.doc_id
AND    itc2.doc_line                = iaj2.doc_line
UNION
SELECT DISTINCT xoha3.request_no AS ENTRY_NO
--2009/01/15 Add Start #3
      ,'2'                       AS CLASS
--2009/01/15 Add End   #3
FROM   xxcmn_rcv_pay_mst            xrpm3                 -- 受払区分アドオンマスタ
      ,xxwsh_order_lines_all        xola3                 -- 受注明細(アドオン)
      ,oe_transaction_types_all     otta3                 -- 受注タイプ
      ,xxwsh_order_headers_all      xoha3                 -- 受注ヘッダ(アドオン)
WHERE  xrpm3.doc_type               = 'OMSO'
AND    xrpm3.use_div_invent_rep     = 'Y'
AND    xoha3.order_header_id        = xola3.order_header_id
AND    xoha3.order_type_id          = otta3.transaction_type_id
AND    NVL(xrpm3.shipment_provision_div,otta3.attribute1) = otta3.attribute1
AND    xrpm3.STOCK_ADJUSTMENT_DIV = '2'
AND    xrpm3.ship_prov_rcv_pay_category =  otta3.attribute11
;
--
COMMENT ON COLUMN xxinv_stc_entry_no_v.ENTRY_NO     IS '伝票No';
COMMENT ON COLUMN xxinv_stc_entry_no_v.CLASS        IS '分類';
--
COMMENT ON TABLE  xxinv_stc_entry_no_v IS '在庫_値セット用VIEW_伝票No' ;
/