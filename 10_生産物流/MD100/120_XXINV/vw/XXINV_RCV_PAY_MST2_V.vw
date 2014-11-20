
CREATE OR REPLACE VIEW xxinv_rcv_pay_mst2_v
( 
  new_div_invent
 ,use_div_invent
 ,use_div_invent_rep
 ,new_div_account
 ,dealings_div
 ,rcv_pay_div
 ,routing_class
 ,item_transfer_div
 ,doc_type
 ,doc_id
 ,doc_line
 ,line_type
) AS
   SELECT xrpm.new_div_invent
        ,xrpm.use_div_invent
        ,xrpm.use_div_invent_rep
        ,xrpm.new_div_account
        ,xrpm.dealings_div
        ,xrpm.rcv_pay_div
        ,xrpm.routing_class
        ,xrpm.item_transfer_div
        ,xrpm.doc_type
        ,xrpm.doc_id
        ,xrpm.doc_line
        ,xrpm.line_type
  FROM (
        SELECT xrpm_a.new_div_invent
              ,xrpm_a.use_div_invent
              ,xrpm_a.use_div_invent_rep
              ,xrpm_a.new_div_account
              ,xrpm_a.dealings_div
              ,xrpm_a.rcv_pay_div
              ,xrpm_a.routing_class
              ,xrpm_a.doc_type
              ,gmd_a.batch_id   AS doc_id
              ,gmd_a.line_no    AS doc_line
              ,gmd_a.line_type  AS line_type
              ,gbh_a.attribute7 AS item_transfer_div
        FROM   xxcmn_rcv_pay_mst        xrpm_a
              ,gme_material_details     gmd_a
              ,gme_batch_header         gbh_a
              ,gmd_routings_b           grb_a
        WHERE  xrpm_a.doc_type          = 'PROD'
        AND    xrpm_a.routing_class    <> '70'
        AND    gbh_a.batch_id           = gmd_a.batch_id
        AND    grb_a.routing_id         = gbh_a.routing_id
        AND    xrpm_a.routing_class     = grb_a.routing_class
        AND    xrpm_a.line_type         = gmd_a.line_type
--mod start 2008/07/08 Y.Yamamoto
--        AND (( gmd_a.attribute5         IS NULL )
--          OR ( xrpm_a.hit_in_div        = gmd_a.attribute5 ) )
        AND ((( gmd_a.attribute5        IS NULL )
          AND ( xrpm_a.hit_in_div       IS NULL ))
         OR  (( gmd_a.attribute5        IS NOT NULL )
          AND ( xrpm_a.hit_in_div       = gmd_a.attribute5 )))
--mod start 2008/07/08 Y.Yamamoto
        UNION ALL
        SELECT xrpm_b.new_div_invent
              ,xrpm_b.use_div_invent
              ,xrpm_b.use_div_invent_rep
              ,xrpm_b.new_div_account
              ,xrpm_b.dealings_div
              ,xrpm_b.rcv_pay_div
              ,xrpm_b.routing_class
              ,xrpm_b.doc_type
              ,gmd_b.batch_id   AS doc_id
              ,gmd_b.line_no    AS doc_line
              ,gmd_b.line_type  AS line_type
              ,gbh_b.attribute7 AS item_transfer_div
        FROM   xxcmn_rcv_pay_mst        xrpm_b
              ,gme_material_details     gmd_b
              ,gme_batch_header         gbh_b
              ,gmd_routings_b           grb_b
--mod start 2008/09/22 Y.Yamamoto PT 2_1_12 #63 再改修
--              ,( SELECT gbh_item.batch_id
--                       ,gmd_item.line_no
--                       ,MAX(DECODE(gmd_item.line_type,-1,xicv.item_class_code,null)) item_class_origin
--                       ,MAX(DECODE(gmd_item.line_type, 1,xicv.item_class_code,null)) item_class_ahead
--                 FROM   gme_batch_header         gbh_item
--                       ,gme_material_details     gmd_item
--                       ,gmd_routings_b           grb_item
--                       ,xxcmn_item_categories4_v xicv
--                 WHERE  gbh_item.batch_id      = gmd_item.batch_id
--                 AND    gbh_item.routing_id    = grb_item.routing_id
--                 AND    grb_item.routing_class = '70'
--                 AND    gmd_item.item_id       = xicv.item_id
--                 GROUP BY gbh_item.batch_id
--                         ,gmd_item.line_no ) gmd_item_b
--mod end 2008/09/22 Y.Yamamoto
        WHERE  xrpm_b.doc_type          = 'PROD'
        AND    xrpm_b.routing_class     = '70'
        AND    gbh_b.batch_id           = gmd_b.batch_id
        AND    grb_b.routing_id         = gbh_b.routing_id
        AND    xrpm_b.routing_class     = grb_b.routing_class
        AND    xrpm_b.line_type         = gmd_b.line_type
--mod start 2008/07/08 Y.Yamamoto
--        AND (( gmd_b.attribute5         IS NULL )
--          OR ( xrpm_b.hit_in_div        = gmd_b.attribute5 ) )
        AND ((( gmd_b.attribute5        IS NULL )
          AND ( xrpm_b.hit_in_div       IS NULL ))
         OR  (( gmd_b.attribute5        IS NOT NULL )
          AND ( xrpm_b.hit_in_div       = gmd_b.attribute5 )))
--mod start 2008/07/08 Y.Yamamoto
--mod start 2008/09/22 Y.Yamamoto PT 2_1_12 #63 再改修
--        AND    gmd_item_b.batch_id      = gmd_b.batch_id
--        AND    gmd_item_b.line_no       = gmd_b.line_no
--        AND    xrpm_b.item_div_ahead    = gmd_item_b.item_class_ahead
--        AND    xrpm_b.item_div_origin   = gmd_item_b.item_class_origin
        AND    EXISTS
               ( SELECT 1
                 FROM   gme_batch_header         gbh_item
                       ,gme_material_details     gmd_item
                       ,gmd_routings_b           grb_item
                       ,xxcmn_item_categories4_v xicv
                 WHERE  gbh_item.batch_id      = gmd_item.batch_id
                 AND    gbh_item.routing_id    = grb_item.routing_id
                 AND    grb_item.routing_class = '70'
                 AND    gmd_item.item_id       = xicv.item_id
                 AND    gmd_item.batch_id      = gmd_b.batch_id
                 AND    gmd_item.line_no       = gmd_b.line_no
                 GROUP BY gbh_item.batch_id
                         ,gmd_item.line_no
                 HAVING
                        xrpm_b.item_div_origin = MAX(DECODE(gmd_item.line_type,-1,xicv.item_class_code,null)) 
                 AND    xrpm_b.item_div_ahead  = MAX(DECODE(gmd_item.line_type, 1,xicv.item_class_code,null)) 
               )
--mod end 2008/09/22 Y.Yamamoto PT 2_1_12 #63 再改修
  ) xrpm
  ;
--
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.new_div_invent     IS '新区分（在庫用）' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.use_div_invent     IS '在庫使用区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.use_div_invent_rep IS '在庫帳票使用区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.new_div_account    IS '新経理受払区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.dealings_div       IS '取引区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.rcv_pay_div        IS '受払区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.routing_class      IS '工順区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.item_transfer_div  IS '品目振替目的' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.doc_type           IS '文書タイプ' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.doc_id             IS '文書ID' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.doc_line           IS '取引明細番号' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst2_v.line_type          IS 'ラインタイプ' ;
--
COMMENT ON TABLE  xxinv_rcv_pay_mst2_v IS '受払区分情報VIEW生産' ;
/
