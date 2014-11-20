--*******************************************************************
-- 受払情報_製品以外 中間VIEW
--   【使用対象VIEW】
--     ・XXSKY_受払情報_製品以外_基本_V
--     ・XXSKY_受払情報_製品以外_数量_V
--*******************************************************************
CREATE OR REPLACE VIEW APPS.XXSKY_UH_MATERIALS_V
(
 whse_code
,item_id
,lot_id
,trans_qty
,column_no
,trans_date
)
AS
SELECT
        UHG.whse_code              whse_code           --倉庫コード
       ,UHG.item_id                item_id             --品目ID
       ,UHG.lot_id                 lot_id              --ロットID
       ,UHG.trans_qty              trans_qty           --受払数
       ,UHG.column_no              column_no           --項目番号
       ,UHG.trans_date             trans_date          --取引日
  FROM (
    --****************************************************************************
    -- 対象のデータを取得 START (参考コード：XXCMN770002C にインデントを合わせる)
    --****************************************************************************
      ------------------------------------------------------
      -- 棚卸月末在庫テーブルから月首在庫数を取得
      ------------------------------------------------------
      SELECT  XSIMS.whse_code            whse_code                                 --倉庫コード
             ,XSIMS.item_id              item_id                                   --品目ID
             ,XSIMS.lot_id               lot_id                                    --ロットID
             ,NVL(XSIMS.monthly_stock, 0) + NVL(XSIMS.cargo_stock, 0) trans_qty    --月首在庫数
             ,'0'                        column_no
             ,TRUNC(ADD_MONTHS(TO_DATE(XSIMS.invent_ym, 'YYYYMM'), 1), 'MM')       trans_date    --棚卸年月
        FROM  xxinv_stc_inventory_month_stck     XSIMS
             ,ic_whse_mst                        IWM
       WHERE  
              IWM.whse_code  = XSIMS.whse_code
         AND  IWM.attribute1 = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- XFER :経理受払区分情報ＶＩＷ移動積送あり
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             itp.whse_code                        whse_code
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,xmrh.actual_arrival_date               trans_date
      FROM   ic_tran_pnd                      itp
            ,ic_xfer_mst                      ixm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itp.doc_type            = 'XFER'
      AND    itp.reason_code         = 'X122'
      AND    itp.completed_ind       = 1
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itp.doc_id              = ixm.transfer_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itp.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL --trni
      -- ----------------------------------------------------
      -- TRNI :経理受払区分情報ＶＩＷ移動積送なし
      -- ----------------------------------------------------
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      SELECT /*+ leading (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
      SELECT
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
             itc.whse_code                        whse_code
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,xmrh.actual_arrival_date             trans_date
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itc.doc_type            = 'TRNI'
      AND    itc.reason_code         = 'X122'
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itc.doc_type            = iaj.trans_type
      AND    itc.doc_id              = iaj.doc_id
      AND    itc.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    xmril.mov_line_id          = TO_NUMBER(ijm.attribute1)
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itc.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.rcv_pay_div        = itc.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分情報VIEW在庫調整(他)
      -- ----------------------------------------------------
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2)*/
      SELECT
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
             itc.whse_code                        whse_code
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,itc.trans_date                       trans_date
      FROM   ic_tran_cmp                      itc
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itc.doc_type            = 'ADJI'    --文書タイプ
      AND    itc.reason_code        IN ('X911'
                                       ,'X912'
                                       ,'X921'
                                       ,'X922'
                                       ,'X931'
                                       ,'X932'
                                       ,'X941'
                                       ,'X952'
                                       ,'X953'
                                       ,'X954'
                                       ,'X955'
                                       ,'X956'
                                       ,'X957'
                                       ,'X958'
                                       ,'X959'
                                       ,'X960'
                                       ,'X961'
                                       ,'X962'
                                       ,'X963'
                                       ,'X964'
                                       ,'X965'
                                       ,'X966')
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分情報VIEW在庫調整(仕入)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             itc.whse_code                        whse_code
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,itc.trans_date                       trans_date
      FROM   ic_tran_cmp                      itc
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itc.doc_type            = 'ADJI'
      AND    itc.reason_code         = 'X201'
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分情報ＶＩＷ在庫調整(浜岡)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             itc.whse_code                        whse_code
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,itc.trans_date                       trans_date
      FROM   ic_tran_cmp                      itc
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itc.doc_type            = 'ADJI'
      AND    itc.reason_code         = 'X988'
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分情報ＶＩＷ在庫調整(移動)
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             itc.whse_code                        whse_code
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,xmrh.actual_arrival_date             trans_date
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmrl
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itc.doc_type            = 'ADJI'
      AND    itc.reason_code         = 'X123'
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itc.trans_qty >= 0 THEN -1
                                       ELSE 1
                                       END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分情報ＶＩＷ在庫調整(その他払出)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             itc.whse_code                        whse_code
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,itc.trans_date                       trans_date
      FROM   ic_tran_cmp                      itc
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itc.doc_type            = 'ADJI'
      AND    itc.reason_code        IN ('X942'
                                       ,'X943'
                                       ,'X950'
                                       ,'X951')
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      --  PROD :経理受払区分情報ＶＩＷ生産関連（Reverse_idなし）品種・品目振替なし
      -- ----------------------------------------------------
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2)*/
      SELECT
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
             itp.whse_code                        whse_code
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,itp.trans_date                       trans_date
      FROM   ic_tran_pnd                      itp
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itp.doc_type            = 'PROD'
      AND    itp.completed_ind       = 1
      AND    itp.reverse_id          IS NULL
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      <> '70'
      UNION ALL
      -- ----------------------------------------------------
      --  PROD :経理受払区分情報ＶＩＷ生産関連（Reverse_idなし）品種・品目振替
      -- ----------------------------------------------------
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2 gmd gbh grb) use_nl (itp gic1 mcb1 gic2 mcb2 gmd gbh grb)*/
      SELECT
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
             itp.whse_code                        whse_code
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,itp.trans_date                       trans_date
      FROM   ic_tran_pnd                      itp
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itp.doc_type            = 'PROD'
      AND    itp.completed_ind       = 1
      AND    itp.reverse_id          IS NULL
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      = '70'
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
      UNION ALL
      -- ----------------------------------------------------
      --  SQL11
      -- ----------------------------------------------------
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
             itp.whse_code                        whse_code
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,xoha.arrival_date                    trans_date
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--            ,oe_order_headers_all             ooha
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.req_status         IN ('04','08')
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xola.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--      AND    xoha.header_id          = ooha.header_id
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      UNION ALL
      -- ----------------------------------------------------
      --  SQL12
      -- ----------------------------------------------------
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
             itp.whse_code                        whse_code
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,xoha.arrival_date                    trans_date
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--            ,oe_order_headers_all             ooha
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_rcv_pay_mst                xrpm
            ,xxsky_item_class_v               xicv1
            ,xxsky_item_class_v               xicv2
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.req_status         IN ('04','08')
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--      AND    xoha.header_id          = ooha.header_id
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xicv1.item_id           = iimb2.item_id
      AND    xrpm.item_div_ahead     = xicv1.item_class_code
      AND    xicv2.item_id            = itp.item_id
      AND    xicv2.item_class_code   <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      --  SQL13
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm) */
             itp.whse_code                        whse_code
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,xoha.arrival_date                    trans_date
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_rcv_pay_mst                xrpm
            ,xxsky_item_class_v               xicv1
            ,xxsky_item_class_v               xicv2
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.req_status         = '04'
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xicv1.item_id           = iimb2.item_id
      AND    xrpm.item_div_ahead     = xicv1.item_class_code
      AND    xicv2.item_id           = iimb.item_id
      AND    xicv2.item_class_code  <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      --  SQL14
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             itp.whse_code                        whse_code
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,xoha.arrival_date                    trans_date
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      --  SQL15
      -- ----------------------------------------------------
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2) */
      SELECT
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
             itp.whse_code                        whse_code
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,itp.trans_date                       trans_date
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,rcv_transactions                 rt
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rt.transaction_id       = itp.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      --  SQL16
      -- ----------------------------------------------------
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
             itp.whse_code                        whse_code
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,xoha.arrival_date                    trans_date
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--            ,oe_order_headers_all             ooha
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itp.doc_type            = 'OMSO'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.req_status         IN ('04','08')
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--      AND    xoha.header_id          = ooha.header_id
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      UNION ALL
      -- ----------------------------------------------------
      --  SQL17
      -- ----------------------------------------------------
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
             itp.whse_code                        whse_code
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,xoha.arrival_date                    trans_date
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--            ,oe_order_headers_all             ooha
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_rcv_pay_mst                xrpm
            ,xxsky_item_class_v               xicv1
            ,xxsky_item_class_v               xicv2
      WHERE  itp.doc_type            = 'OMSO'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.req_status         = '08'
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--      AND    xoha.header_id          = ooha.header_id
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xicv1.item_id           = iimb2.item_id
      AND    xrpm.item_div_ahead     = xicv1.item_class_code
      AND    xicv2.item_id           = iimb.item_id
      AND    xicv2.item_class_code  <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      --  SQL18
      -- ----------------------------------------------------
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 otta xrpm) */
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
             itp.whse_code                        whse_code
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,xoha.arrival_date                    trans_date
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--            ,oe_order_headers_all             ooha
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_rcv_pay_mst                xrpm
            ,xxsky_item_class_v               xicv1
            ,xxsky_item_class_v               xicv2
      WHERE  itp.doc_type            = 'OMSO'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.req_status         = '04'
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--      AND    xoha.header_id          = ooha.header_id
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xicv1.item_id           = iimb2.item_id
      AND    xrpm.item_div_ahead     = xicv1.item_class_code
      AND    xicv2.item_id           = iimb.item_id
      AND    xicv2.item_class_code  <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      --  SQL19
      -- ----------------------------------------------------
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
      SELECT
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
             itp.whse_code                        whse_code
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_01,'-') = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  WHEN xrpm.dealings_div_name = '仕入'
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,'-') -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,'-') +1)
             END                                  column_no
            ,xoha.arrival_date                    trans_date
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--            ,oe_order_headers_all             ooha
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itp.doc_type            = 'OMSO'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2010/02/16 T.Yoshimoto Add Start 本稼動#1168
      AND    xoha.req_status         = '04'
-- 2010/02/16 T.Yoshimoto Add End 本稼動#1168
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
      AND    otta.attribute4         = '2'
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--      AND    xoha.header_id          = ooha.header_id
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      UNION ALL
      -- 倉庫移動
      -- ----------------------------------------------------
      -- XFER :経理受払区分移動積送あり
      -- ----------------------------------------------------
      SELECT 
             itp.whse_code              whse_code
            ,itp.item_id                item_id
            ,itp.lot_id                 lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,xmrih.actual_arrival_date  trans_date
      FROM   ic_tran_pnd                itp
            ,ic_xfer_mst                ixm
            ,xxinv_mov_req_instr_lines  xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,xxcmn_rcv_pay_mst          xrpm
      WHERE  itp.doc_type            = 'XFER'
-- 2010/02/16 T.Yoshimoto Add Start 本稼動#1168
      AND    itp.reason_code         = 'X122'
-- 2010/02/16 T.Yoshimoto Add End 本稼動#1168
      AND    itp.completed_ind       = 1
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    ixm.transfer_id         = itp.doc_id
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    xmril.mov_line_id       = TO_NUMBER(ixm.attribute1)
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itp.trans_qty >= 0
                                         THEN '1'
                                         ELSE '-1'
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      UNION ALL
      -- 倉庫移動
      -- ----------------------------------------------------
      -- TRNI :経理受払区分移動積送なし
      -- ----------------------------------------------------
      SELECT 
             itc.whse_code              whse_code
            ,itc.item_id                item_id
            ,itc.lot_id                 lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,xmrih.actual_arrival_date        trans_date
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_lines        xmril
            ,xxinv_mov_req_instr_headers      xmrih
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itc.doc_type            = 'TRNI'
      AND    itc.reason_code         = 'X122'
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    iaj.trans_type          = itc.doc_type
      AND    itc.doc_id              = iaj.doc_id
      AND    itc.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    xmril.mov_line_id       = TO_NUMBER(ijm.attribute1)
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itc.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      UNION ALL
      -- 廃却・見本・総務払出・棚卸減耗
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(他)
      -- ----------------------------------------------------
      SELECT
             itc.whse_code              whse_code
            ,itc.item_id                item_id
            ,itc.lot_id                 lot_id
            ,CASE WHEN xrpm.rcv_pay_div = '-1'
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
                  WHEN xrpm.rcv_pay_div = '1' AND itc.reason_code = 'X911'
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) * -1
                  ELSE NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,itc.trans_date             trans_date
      FROM   ic_tran_cmp                itc
            ,xxcmn_rcv_pay_mst          xrpm
      WHERE  itc.doc_type          = 'ADJI'
      AND    itc.reason_code       IN ('X911'
                                      ,'X912'
                                      ,'X921'
                                      ,'X922'
                                      ,'X941'
                                      ,'X931'
                                      ,'X953'
                                      ,'X955'
                                      ,'X957'
                                      ,'X959'
                                      ,'X961'
                                      ,'X963'
                                      ,'X952'
                                      ,'X954'
                                      ,'X956'
                                      ,'X958'
                                      ,'X960'
                                      ,'X962'
                                      ,'X964'
                                      ,'X965'
                                      ,'X966'
                                      ,'X932')
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      UNION ALL
      -- 浜岡
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(浜岡)
      -- ----------------------------------------------------
      SELECT 
             itc.whse_code              whse_code
            ,itc.item_id                item_id
            ,itc.lot_id                 lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,itc.trans_date             trans_date
      FROM   ic_tran_cmp                itc
            ,xxcmn_rcv_pay_mst          xrpm
      WHERE  itc.doc_type            = 'ADJI'
      AND    itc.reason_code         = 'X988'
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(移動)
      -- ----------------------------------------------------
      SELECT
             itc.whse_code              whse_code
            ,itc.item_id                item_id
            ,itc.lot_id                 lot_id
            ,NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)  trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,xmrih.actual_arrival_date  trans_date
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines  xmrl
            ,xxinv_mov_req_instr_headers xmrih
            ,xxcmn_rcv_pay_mst          xrpm
      WHERE  itc.doc_type            = 'ADJI'
      AND    itc.reason_code         = 'X123'
      AND    xmrih.mov_hdr_id        = xmrl.mov_hdr_id
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    xmrl.mov_line_id       = TO_NUMBER(ijm.attribute1)
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= 0
                                         THEN '-1'
                                         WHEN itc.trans_qty <  0
                                         THEN '1'
                                         ELSE xrpm.rcv_pay_div
                                       END
      AND    xrpm.break_col_03       IS NOT NULL
      UNION ALL
      -- その他
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(その他払出)
      -- ----------------------------------------------------
      SELECT
             itc.whse_code              whse_code
            ,itc.item_id                item_id
            ,itc.lot_id                 lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,itc.trans_date             trans_date
      FROM   ic_tran_cmp                itc
            ,xxcmn_rcv_pay_mst          xrpm
      WHERE  itc.doc_type            = 'ADJI'
      AND    itc.reason_code        IN ('X942','X943','X950','X951')
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      UNION ALL
      -- 品種移動
      -- ----------------------------------------------------
      -- PROD :経理受払区分生産関連（Reverse_idなし）品種・品目振替なし
      -- ----------------------------------------------------
      SELECT
             itp.whse_code              whse_code
            ,itp.item_id                item_id
            ,itp.lot_id                 lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,itp.trans_date             trans_date
      FROM   ic_tran_pnd                itp
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,xxcmn_rcv_pay_mst          xrpm
      WHERE  itp.doc_type            = 'PROD'
      AND    itp.completed_ind       = 1
      AND    itp.reverse_id          IS NULL
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_03       IS NOT NULL
      AND    xrpm.dealings_div       = '309'
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
      UNION ALL
    -- 廃却・見本
    -- ----------------------------------------------------
    -- OMSO8 :経理受払区分受注関連 (見本,廃却)
    -- ----------------------------------------------------
      SELECT
             itp.whse_code              whse_code
            ,itp.item_id                item_id
            ,itp.lot_id                 lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--            ,oe_order_headers_all             ooha
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itp.doc_type            = 'OMSO'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2010/02/16 T.Yoshimoto Add Start 本稼動#1168
      AND    xoha.req_status         = '04'
-- 2010/02/16 T.Yoshimoto Add End 本稼動#1168
      AND    wdd.delivery_detail_id  = itp.line_detail_id
-- 2010/02/16 T.Yoshimoto Mod Start 本稼動#1168
--      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2010/02/16 T.Yoshimoto Mod End 本稼動#1168
-- 2010/02/16 T.Yoshimoto Add Start 本稼動#1168
      AND    otta.attribute1 = '1'
-- 2010/02/16 T.Yoshimoto Add End 本稼動#1168
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2010/02/16 T.Yoshimoto Del Start 本稼動#1168
--      AND    xoha.header_id          = ooha.header_id
-- 2010/02/16 T.Yoshimoto Del End 本稼動#1168
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      UNION ALL
      -- 廃却・見本
      -- ----------------------------------------------------
      -- PORC8 :経理受払区分購買関連 (見本,廃却)
      -- ----------------------------------------------------
      SELECT
             itp.whse_code              whse_code
            ,itp.item_id                item_id
            ,itp.lot_id                 lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,xxcmn_rcv_pay_mst                xrpm
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
    --****************************************************************************
    -- 対象のデータを取得 END
    --****************************************************************************
       )                           UHG                 --受払情報
       ,xxsky_item_class_v         ITEMC               --品目区分
 WHERE
   --『製品以外』を取得
        ITEMC.item_class_code     <> '5'               --'5:製品'以外
   AND  UHG.item_id                = ITEMC.item_id
/
COMMENT ON TABLE APPS.XXSKY_UH_MATERIALS_V IS 'XXSKY_受払情報_製品以外_中間VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_UH_MATERIALS_V.whse_code  IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKY_UH_MATERIALS_V.item_id    IS '品目ID'
/
COMMENT ON COLUMN APPS.XXSKY_UH_MATERIALS_V.lot_id     IS 'ロットID'
/
COMMENT ON COLUMN APPS.XXSKY_UH_MATERIALS_V.trans_qty  IS '受払数'
/
COMMENT ON COLUMN APPS.XXSKY_UH_MATERIALS_V.column_no  IS '項目番号'
/
COMMENT ON COLUMN APPS.XXSKY_UH_MATERIALS_V.trans_date IS '取引日'
/
