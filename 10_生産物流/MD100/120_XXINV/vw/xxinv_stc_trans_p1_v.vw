CREATE OR REPLACE VIEW xxinv_stc_trans_p1_v 
(
  ownership_code
 ,inventory_location_id
 ,item_id
 ,lot_no
 ,manufacture_date
 ,uniqe_sign
 ,expiration_date
 ,arrival_date
 ,leaving_date
 ,status
 ,reason_code
 ,reason_code_name
 ,voucher_no
 ,ukebaraisaki_name
 ,deliver_to_name
 ,stock_quantity
 ,leaving_quantity
) 
AS 
  ------------------------------------------------------------------------
  -- ���ɗ\��
  ------------------------------------------------------------------------
  -- ��������\��
  SELECT iwm_in_po.attribute1                          AS ownership_code
        ,mil_in_po.inventory_location_id               AS inventory_location_id
        ,iimb_in_po.item_id                            AS item_id
        ,ilm_in_po.lot_no                              AS lot_no
        ,ilm_in_po.attribute1                          AS manufacture_date
        ,ilm_in_po.attribute2                          AS uniqe_sign
        ,ilm_in_po.attribute3                          AS expiration_date -- <---- �����܂ŋ���
        ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS arrival_date
        ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS leaving_date
        ,'1'                                           AS status        -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,pha_in_po.segment1                            AS voucher_no
        ,xv_in_po.vendor_name                          AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,pla_in_po.quantity                            AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   po_headers_all          pha_in_po                        -- �����w�b�_
        ,po_lines_all            pla_in_po                        -- ��������
        ,po_vendors              pv_in_po                         -- �d����}�X�^
        ,xxcmn_vendors           xv_in_po                         -- �d����A�h�I���}�X�^
        ,ic_whse_mst             iwm_in_po                        -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations      mil_in_po                        -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b           iimb_in_po                       -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b      msib_in_po                       -- �i�ڃ}�X�^
        ,ic_lots_mst             ilm_in_po                        -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_po.new_div_invent
                ,flv_in_po.meaning 
          FROM   xxcmn_rcv_pay_mst       xrpm_in_po               -- �󕥋敪�A�h�I���}�X�^
                ,fnd_lookup_values       flv_in_po                -- �N�C�b�N�R�[�h
          WHERE  flv_in_po.lookup_type           = 'XXCMN_NEW_DIVISION'
          AND    flv_in_po.language              = 'JA'
          AND    flv_in_po.lookup_code           = xrpm_in_po.new_div_invent
          AND    xrpm_in_po.doc_type             = 'PORC'
          AND    xrpm_in_po.source_document_code = 'PO'
          AND    xrpm_in_po.use_div_invent       = 'Y'
          AND    xrpm_in_po.transaction_type     = 'DELIVER'
         ) xrpm
  WHERE  pha_in_po.po_header_id         = pla_in_po.po_header_id
  AND    pha_in_po.attribute4          <= TO_CHAR( TRUNC( SYSDATE ), 'YYYY/MM/DD' )
  AND    pha_in_po.attribute1          IN ( '20'                 -- �����쐬��
                                           ,'25' )               -- �������
  AND    pla_in_po.attribute13          = 'N'                    -- ������
  AND    pla_in_po.cancel_flag         <> 'Y'
  AND    pla_in_po.item_id              = msib_in_po.inventory_item_id
  AND    pla_in_po.attribute1           = ilm_in_po.lot_no
  AND    ilm_in_po.item_id              = iimb_in_po.item_id
  AND    iimb_in_po.item_no             = msib_in_po.segment1
  AND    msib_in_po.organization_id     = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    pha_in_po.attribute5           = mil_in_po.segment1
  AND    pha_in_po.vendor_id            = pv_in_po.vendor_id
  AND    pv_in_po.vendor_id             = xv_in_po.vendor_id
  AND    pv_in_po.end_date_active      IS NULL
  AND    xv_in_po.start_date_active    <= TRUNC( SYSDATE )
  AND    xv_in_po.end_date_active      >= TRUNC( SYSDATE )
  AND    iwm_in_po.mtl_organization_id  = mil_in_po.organization_id
  UNION ALL
  -- �ړ����ɗ\��(�w�� �ϑ�����)
  SELECT iwm_in_xf.attribute1                          AS ownership_code
        ,mil_in_xf.inventory_location_id               AS inventory_location_id
        ,xmld_in_xf.item_id                            AS item_id
        ,ilm_in_xf.lot_no                              AS lot_no
        ,ilm_in_xf.attribute1                          AS manufacture_date
        ,ilm_in_xf.attribute2                          AS uniqe_sign
        ,ilm_in_xf.attribute3                          AS expiration_date -- <---- �����܂ŋ���
        ,xmrih_in_xf.schedule_arrival_date             AS arrival_date
        ,xmrih_in_xf.schedule_ship_date                AS leaving_date
        ,'1'                                           AS status         -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_xf.mov_num                           AS voucher_no
        ,mil2_in_xf.description                        AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,xmld_in_xf.actual_quantity                    AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_in_xf                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_in_xf                  -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_in_xf                   -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_in_xf                    -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_xf                    -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_in_xf                   -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_xf                    -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_xf.new_div_invent
                ,flv_in_xf.meaning 
          FROM   xxcmn_rcv_pay_mst       xrpm_in_xf               -- �󕥋敪�A�h�I���}�X�^
                ,fnd_lookup_values       flv_in_xf                -- �N�C�b�N�R�[�h
          WHERE  flv_in_xf.lookup_type     = 'XXCMN_NEW_DIVISION'
          AND    flv_in_xf.language        = 'JA'
          AND    flv_in_xf.lookup_code     = xrpm_in_xf.new_div_invent
          AND    xrpm_in_xf.doc_type       = 'XFER'               -- �ړ��ϑ�����
          AND    xrpm_in_xf.use_div_invent = 'Y'
          AND    xrpm_in_xf.rcv_pay_div    = '1'                  -- ���
         ) xrpm
  WHERE  xmrih_in_xf.mov_hdr_id             = xmril_in_xf.mov_hdr_id
  AND    xmrih_in_xf.ship_to_locat_id       = mil_in_xf.inventory_location_id
  AND    iwm_in_xf.mtl_organization_id      = mil_in_xf.organization_id
  AND    xmrih_in_xf.shipped_locat_id       = mil2_in_xf.inventory_location_id
  AND    xmld_in_xf.mov_line_id             = xmril_in_xf.mov_line_id
  AND    xmld_in_xf.item_id                 = ilm_in_xf.item_id
  AND    xmld_in_xf.lot_id                  = ilm_in_xf.lot_id
  AND    xmld_in_xf.document_type_code      = '20'                 -- �ړ�
  AND    xmld_in_xf.record_type_code        = '10'                 -- �w��
  AND    xmrih_in_xf.schedule_arrival_date <= TRUNC( SYSDATE )
  AND    xmrih_in_xf.mov_type               = '1'
  AND    xmrih_in_xf.comp_actual_flg        = 'N'                  -- ���і��v��
  AND    xmrih_in_xf.status                IN ( '02'               -- �˗���
                                               ,'03' )             -- ������
  AND    xmril_in_xf.delete_flg             = 'N'                  -- OFF
  UNION ALL
  -- �ړ����ɗ\��(�w�� �ϑ��Ȃ�)
  SELECT iwm_in_tr.attribute1                          AS ownership_code
        ,mil_in_tr.inventory_location_id               AS inventory_location_id
        ,xmld_in_tr.item_id                            AS item_id
        ,ilm_in_tr.lot_no                              AS lot_no
        ,ilm_in_tr.attribute1                          AS manufacture_date
        ,ilm_in_tr.attribute2                          AS uniqe_sign
        ,ilm_in_tr.attribute3                          AS expiration_date -- <---- �����܂ŋ���
        ,xmrih_in_tr.schedule_arrival_date             AS arrival_date
        ,xmrih_in_tr.schedule_ship_date                AS leaving_date
        ,'1'                                           AS status      -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_tr.mov_num                           AS voucher_no
        ,mil2_in_tr.description                        AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,xmld_in_tr.actual_quantity                    AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_in_tr               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_in_tr               -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_in_tr                -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_in_tr                    -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_tr                    -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_in_tr                   -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_tr                    -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_tr.new_div_invent
                ,flv_in_tr.meaning 
          FROM   xxcmn_rcv_pay_mst       xrpm_in_tr               -- �󕥋敪�A�h�I���}�X�^
                ,fnd_lookup_values       flv_in_tr                -- �N�C�b�N�R�[�h
          WHERE  flv_in_tr.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_tr.language                 = 'JA'
          AND    flv_in_tr.lookup_code              = xrpm_in_tr.new_div_invent
          AND    xrpm_in_tr.doc_type                = 'TRNI'            -- �ړ��ϑ��Ȃ�
          AND    xrpm_in_tr.use_div_invent          = 'Y'
          AND    xrpm_in_tr.rcv_pay_div             = '1'               -- ���
         ) xrpm
  WHERE  xmrih_in_tr.mov_hdr_id             = xmril_in_tr.mov_hdr_id
  AND    xmrih_in_tr.ship_to_locat_id       = mil_in_tr.inventory_location_id
  AND    iwm_in_tr.mtl_organization_id      = mil_in_tr.organization_id
  AND    xmrih_in_tr.shipped_locat_id       = mil2_in_tr.inventory_location_id
  AND    xmld_in_tr.mov_line_id             = xmril_in_tr.mov_line_id
  AND    xmld_in_tr.item_id                 = ilm_in_tr.item_id
  AND    xmld_in_tr.lot_id                  = ilm_in_tr.lot_id
  AND    xmld_in_tr.document_type_code      = '20'              -- �ړ�
  AND    xmld_in_tr.record_type_code        = '10'              -- �w��
  AND    xmrih_in_tr.schedule_arrival_date <= TRUNC( SYSDATE )
  AND    xmrih_in_tr.mov_type               = '2'
  AND    xmrih_in_tr.comp_actual_flg        = 'N'               -- ���і��v��
  AND    xmrih_in_tr.status                IN ( '02'            -- �˗���
                                               ,'03' )          -- ������
  AND    xmril_in_tr.delete_flg             = 'N'               -- OFF
  UNION ALL
  -- �ړ����ɗ\��(�o�ɕ񍐗L �ϑ�����)
  SELECT iwm_in_xf20.attribute1                        AS ownership_code
        ,mil_in_xf20.inventory_location_id             AS inventory_location_id
        ,xmld_in_xf20.item_id                          AS item_id
        ,ilm_in_xf20.lot_no                            AS lot_no
        ,ilm_in_xf20.attribute1                        AS manufacture_date
        ,ilm_in_xf20.attribute2                        AS uniqe_sign
        ,ilm_in_xf20.attribute3                        AS expiration_date -- <---- �����܂ŋ���
        ,xmrih_in_xf20.schedule_arrival_date           AS arrival_date
        ,xmrih_in_xf20.schedule_ship_date              AS leaving_date
        ,'1'                                           AS status         -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_xf20.mov_num                         AS voucher_no
        ,mil2_in_xf20.description                      AS deliver_to_name
        ,NULL                                          AS deliver_to_name
        ,xmld_in_xf20.actual_quantity                  AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_in_xf20                -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_in_xf20                -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_in_xf20                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_in_xf20                    -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_xf20                    -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_in_xf20                   -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_xf20                  -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_xf20.new_div_invent
                ,flv_in_xf20.meaning 
          FROM   xxcmn_rcv_pay_mst       xrpm_in_xf20               -- �󕥋敪�A�h�I���}�X�^
                ,fnd_lookup_values       flv_in_xf20                -- �N�C�b�N�R�[�h
          WHERE  flv_in_xf20.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_xf20.language                 = 'JA'
          AND    flv_in_xf20.lookup_code              = xrpm_in_xf20.new_div_invent
          AND    xrpm_in_xf20.doc_type                = 'XFER'             -- �ړ��ϑ�����
          AND    xrpm_in_xf20.use_div_invent          = 'Y'
          AND    xrpm_in_xf20.rcv_pay_div             = '1'                -- ���
         ) xrpm
  WHERE  xmrih_in_xf20.mov_hdr_id             = xmril_in_xf20.mov_hdr_id
  AND    xmrih_in_xf20.ship_to_locat_id       = mil_in_xf20.inventory_location_id
  AND    iwm_in_xf20.mtl_organization_id      = mil_in_xf20.organization_id
  AND    xmrih_in_xf20.shipped_locat_id       = mil2_in_xf20.inventory_location_id
  AND    xmld_in_xf20.mov_line_id             = xmril_in_xf20.mov_line_id
  AND    xmld_in_xf20.item_id                 = ilm_in_xf20.item_id
  AND    xmld_in_xf20.lot_id                  = ilm_in_xf20.lot_id
  AND    xmld_in_xf20.document_type_code      = '20'               -- �ړ�
  AND    xmld_in_xf20.record_type_code        = '20'               -- �o�Ɏ���
  AND    xmrih_in_xf20.schedule_arrival_date <= TRUNC( SYSDATE )
  AND    xmrih_in_xf20.mov_type               = '1'  -- �ϑ�����
  AND    xmrih_in_xf20.comp_actual_flg        = 'N'                -- ���і��v��
  AND    xmrih_in_xf20.status                 = '04'               -- �o�ɕ񍐗L
  AND    xmril_in_xf20.delete_flg             = 'N'                -- OFF
  UNION ALL
  -- ���Y���ɗ\��
  SELECT iwm_in_pr.attribute1                          AS ownership_code
        ,mil_in_pr.inventory_location_id               AS inventory_location_id
        ,gmd_in_pr.item_id                             AS item_id
        ,ilm_in_pr.lot_no                              AS lot_no
        ,ilm_in_pr.attribute1                          AS manufacture_date
        ,ilm_in_pr.attribute2                          AS uniqe_sign
        ,ilm_in_pr.attribute3                          AS expiration_date -- <---- �����܂ŋ���
        ,gbh_in_pr.plan_start_date                     AS arrival_date
        ,gbh_in_pr.plan_start_date                     AS leaving_date
        ,'1'                                           AS status       -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_in_pr.batch_no                            AS voucher_no
        ,grt_in_pr.routing_desc                        AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
-- 2008/11/19 Y.Yamamoto v1.2 update start
--        ,gmd_in_pr.plan_qty                            AS stock_quantity
        ,TO_NUMBER(NVL(gbh_in_pr.attribute23,'0'))     AS stock_quantity
-- 2008/11/19 Y.Yamamoto v1.2 update end
        ,0                                             AS leaving_quantity
  FROM   gme_batch_header             gbh_in_pr                  -- ���Y�o�b�`
        ,gme_material_details         gmd_in_pr                  -- ���Y�����ڍ�
        ,gmd_routings_b               grb_in_pr                  -- �H���}�X�^
        ,gmd_routings_tl              grt_in_pr                  -- �H���}�X�^���{��
-- 2008/10/28 Y.Yamamoto v1.1 add start
        ,xxinv_mov_lot_details        xmld_in_pr                 -- �ړ����b�g�ڍ�(�A�h�I��)
-- 2008/10/28 Y.Yamamoto v1.1 add end
        ,ic_tran_pnd                  itp_in_pr                  -- OPM�ۗ��݌Ƀg�����U�N�V����
        ,ic_whse_mst                  iwm_in_pr                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_pr                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_pr                  -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_pr.new_div_invent
                ,flv_in_pr.meaning
                ,xrpm_in_pr.doc_type
                ,xrpm_in_pr.routing_class
                ,xrpm_in_pr.line_type
                ,xrpm_in_pr.hit_in_div
          FROM   xxcmn_rcv_pay_mst       xrpm_in_pr               -- �󕥋敪�A�h�I���}�X�^
                ,fnd_lookup_values       flv_in_pr                -- �N�C�b�N�R�[�h
          WHERE  flv_in_pr.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_pr.language                 = 'JA'
          AND    flv_in_pr.lookup_code              = xrpm_in_pr.new_div_invent
          AND    xrpm_in_pr.doc_type                = 'PROD'
          AND    xrpm_in_pr.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_in_pr.batch_id                 = gmd_in_pr.batch_id
  AND    gmd_in_pr.line_type               IN ( 1                -- �����i
                                               ,2 )              -- ���Y��
  AND    itp_in_pr.doc_type                 = xrpm.doc_type
  AND    itp_in_pr.doc_id                   = gmd_in_pr.batch_id
  AND    itp_in_pr.line_id                  = gmd_in_pr.material_detail_id
  AND    itp_in_pr.doc_line                 = gmd_in_pr.line_no
  AND    itp_in_pr.line_type                = gmd_in_pr.line_type
  AND    itp_in_pr.item_id                  = gmd_in_pr.item_id
  AND    itp_in_pr.completed_ind            = 0
  AND    itp_in_pr.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
  AND    itp_in_pr.item_id                  = ilm_in_pr.item_id
  AND    itp_in_pr.lot_id                   = ilm_in_pr.lot_id
  AND    grb_in_pr.attribute9               = mil_in_pr.segment1
-- 2008/10/28 Y.Yamamoto v1.1 update start
--  AND    EXISTS ( SELECT 1
--                  FROM   xxinv_mov_lot_details xmld
--                  WHERE  xmld.mov_line_id        = gmd_in_pr.material_detail_id
--                  AND    xmld.document_type_code = '40'    -- ���Y�w��
--                  AND    xmld.record_type_code   = '10'    -- �w��
--                  AND    ROWNUM = 1)
  AND    xmld_in_pr.mov_line_id             = gmd_in_pr.material_detail_id
  AND    xmld_in_pr.document_type_code      = '40'    -- ���Y�w��
  AND    xmld_in_pr.record_type_code        = '10'    -- �w��
  AND    xmld_in_pr.lot_id                  = ilm_in_pr.lot_id
-- 2008/10/28 Y.Yamamoto v1.1 update start
-- 2008/11/19 Y.Yamamoto v1.2 update start
--  AND    NOT EXISTS( SELECT 1
--                     FROM   gme_batch_header gbh_in_pr_ex
--                     WHERE  gbh_in_pr_ex.batch_id      = gbh_in_pr.batch_id
--                     AND    gbh_in_pr_ex.batch_status IN ( 7     -- ����
--                                                          ,8     -- �N���[�Y
--                                                          ,-1 )) -- ���
  AND    gbh_in_pr.batch_status            IN ( 1                  -- �ۗ�
                                               ,2 )                -- WIP
-- 2008/11/19 Y.Yamamoto v1.2 update end
  AND    gbh_in_pr.plan_start_date         <= TRUNC( SYSDATE )
  AND    grb_in_pr.routing_id               = gbh_in_pr.routing_id
  AND    xrpm.routing_class                 = grb_in_pr.routing_class
  AND    xrpm.line_type                     = gmd_in_pr.line_type
  AND ((( gmd_in_pr.attribute5             IS NULL )
    AND ( xrpm.hit_in_div                  IS NULL ))
  OR   (( gmd_in_pr.attribute5             IS NOT NULL )
    AND ( xrpm.hit_in_div                   = gmd_in_pr.attribute5 )))
  AND    grb_in_pr.routing_id               = grt_in_pr.routing_id
  AND    grt_in_pr.language                 = 'JA'
  AND    iwm_in_pr.mtl_organization_id      = mil_in_pr.organization_id
  UNION ALL
  ------------------------------------------------------------------------
  -- �o�ɗ\��
  ------------------------------------------------------------------------
  -- �ړ��o�ɗ\��(�w�� �ϑ�����)
  SELECT iwm_out_xf.attribute1                         AS ownership_code
        ,mil_out_xf.inventory_location_id              AS inventory_location_id
        ,xmld_out_xf.item_id                           AS item_id
        ,ilm_out_xf.lot_no                             AS lot_no
        ,ilm_out_xf.attribute1                         AS manufacture_date
        ,ilm_out_xf.attribute2                         AS uniqe_sign
        ,ilm_out_xf.attribute3                         AS expiration_date -- <---- �����܂ŋ���
        ,xmrih_out_xf.schedule_arrival_date            AS arrival_date
        ,xmrih_out_xf.schedule_ship_date               AS leaving_date
        ,'1'                                           AS status         -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_xf.mov_num                          AS voucher_no
        ,mil2_out_xf.description                       AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_xf.actual_quantity                   AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_xf                 -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_out_xf                 -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_xf                  -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_out_xf                   -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_xf                   -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_out_xf                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_xf                   -- OPM���b�g�}�X�^
        ,(SELECT xrpm_out_xf.new_div_invent
                ,flv_out_xf.meaning
          FROM   fnd_lookup_values flv_out_xf                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_xf                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_xf.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_xf.language                 = 'JA'
          AND    flv_out_xf.lookup_code              = xrpm_out_xf.new_div_invent
          AND    xrpm_out_xf.doc_type                = 'XFER'              -- �ړ��ϑ�����
          AND    xrpm_out_xf.use_div_invent          = 'Y'
          AND    xrpm_out_xf.rcv_pay_div             = '-1'                -- ���o
         ) xrpm
  WHERE  xmrih_out_xf.mov_hdr_id             = xmril_out_xf.mov_hdr_id
  AND    xmrih_out_xf.shipped_locat_id       = mil_out_xf.inventory_location_id
  AND    iwm_out_xf.mtl_organization_id      = mil_out_xf.organization_id
  AND    xmrih_out_xf.ship_to_locat_id       = mil2_out_xf.inventory_location_id
  AND    xmld_out_xf.mov_line_id             = xmril_out_xf.mov_line_id
  AND    xmld_out_xf.item_id                 = ilm_out_xf.item_id
  AND    xmld_out_xf.lot_id                  = ilm_out_xf.lot_id
  AND    xmld_out_xf.document_type_code      = '20'                -- �ړ�
  AND    xmld_out_xf.record_type_code        = '10'                -- �w��
  AND    xmrih_out_xf.schedule_ship_date    <= TRUNC( SYSDATE )
  AND    xmrih_out_xf.mov_type               = '1'
  AND    xmrih_out_xf.comp_actual_flg        = 'N'                 -- ���і��v��
  AND    xmrih_out_xf.status                IN ( '02'              -- �˗���
                                                ,'03' )            -- ������
  AND    xmril_out_xf.delete_flg             = 'N'                 -- OFF
  UNION ALL
  -- �ړ��o�ɗ\��(�w�� �ϑ��Ȃ�)
  SELECT iwm_out_tr.attribute1                         AS ownership_code
        ,mil_out_tr.inventory_location_id              AS inventory_location_id
        ,xmld_out_tr.item_id                           AS item_id
        ,ilm_out_tr.lot_no                             AS lot_no
        ,ilm_out_tr.attribute1                         AS manufacture_date
        ,ilm_out_tr.attribute2                         AS uniqe_sign
        ,ilm_out_tr.attribute3                         AS expiration_date -- <---- �����܂ŋ���
        ,xmrih_out_tr.schedule_arrival_date            AS arrival_date
        ,xmrih_out_tr.schedule_ship_date               AS leaving_date
        ,'1'                                           AS status       -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_tr.mov_num                          AS voucher_no
        ,mil2_out_tr.description                       AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_tr.actual_quantity                   AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_tr               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_out_tr               -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_tr                -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_out_tr                   -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_tr                   -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_out_tr                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_tr                 -- OPM���b�g�}�X�^
        ,(SELECT xrpm_out_tr.new_div_invent
                ,flv_out_tr.meaning
          FROM   fnd_lookup_values flv_out_tr                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_tr                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_tr.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_tr.language                 = 'JA'
          AND    flv_out_tr.lookup_code              = xrpm_out_tr.new_div_invent
          AND    xrpm_out_tr.doc_type                = 'TRNI'            -- �ړ��ϑ��Ȃ�
          AND    xrpm_out_tr.use_div_invent          = 'Y'
          AND    xrpm_out_tr.rcv_pay_div             = '-1'              -- ���o
         ) xrpm
  WHERE  xmrih_out_tr.mov_hdr_id             = xmril_out_tr.mov_hdr_id
  AND    xmrih_out_tr.shipped_locat_id       = mil_out_tr.inventory_location_id
  AND    iwm_out_tr.mtl_organization_id      = mil_out_tr.organization_id
  AND    xmrih_out_tr.ship_to_locat_id       = mil2_out_tr.inventory_location_id
  AND    xmld_out_tr.mov_line_id             = xmril_out_tr.mov_line_id
  AND    xmld_out_tr.item_id                 = ilm_out_tr.item_id
  AND    xmld_out_tr.lot_id                  = ilm_out_tr.lot_id
  AND    xmld_out_tr.document_type_code      = '20'              -- �ړ�
  AND    xmld_out_tr.record_type_code        = '10'             -- �w��
  AND    xmrih_out_tr.schedule_ship_date    <= TRUNC( SYSDATE )
  AND    xmrih_out_tr.mov_type               = '2'
  AND    xmrih_out_tr.comp_actual_flg        = 'N'               -- ���і��v��
  AND    xmrih_out_tr.status                IN ( '02'            -- �˗���
                                                ,'03' )          -- ������
  AND    xmril_out_tr.delete_flg             = 'N'               -- OFF
  UNION ALL
  -- �ړ��o�ɗ\��(���ɕ񍐗L �ϑ�����)
  SELECT iwm_out_xf20.attribute1                       AS ownership_code
        ,mil_out_xf20.inventory_location_id            AS inventory_location_id
        ,xmld_out_xf20.item_id                         AS item_id
        ,ilm_out_xf20.lot_no                           AS lot_no
        ,ilm_out_xf20.attribute1                       AS manufacture_date
        ,ilm_out_xf20.attribute2                       AS uniqe_sign
        ,ilm_out_xf20.attribute3                       AS expiration_date -- <---- �����܂ŋ���
        ,xmrih_out_xf20.schedule_arrival_date          AS arrival_date
        ,xmrih_out_xf20.schedule_ship_date             AS leaving_date
        ,'1'                                           AS status         -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_xf20.mov_num                        AS voucher_no
        ,mil2_out_xf20.description                     AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_xf20.actual_quantity                 AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_xf20                -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_out_xf20                -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_xf20                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_out_xf20                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_xf20                  -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_out_xf20                 -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_xf20                  -- OPM���b�g�}�X�^
        ,(SELECT xrpm_out_xf20.new_div_invent
                ,flv_out_xf20.meaning
          FROM   fnd_lookup_values flv_out_xf20                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_xf20                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_xf20.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_xf20.language                 = 'JA'
          AND    flv_out_xf20.lookup_code              = xrpm_out_xf20.new_div_invent
          AND    xrpm_out_xf20.doc_type                = 'XFER'             -- �ړ��ϑ�����
          AND    xrpm_out_xf20.use_div_invent          = 'Y'
          AND    xrpm_out_xf20.rcv_pay_div             = '-1'                -- ���o
         ) xrpm
  WHERE  xmrih_out_xf20.mov_hdr_id             = xmril_out_xf20.mov_hdr_id
  AND    xmrih_out_xf20.shipped_locat_id       = mil_out_xf20.inventory_location_id
  AND    iwm_out_xf20.mtl_organization_id      = mil_out_xf20.organization_id
  AND    xmrih_out_xf20.ship_to_locat_id       = mil2_out_xf20.inventory_location_id
  AND    xmld_out_xf20.mov_line_id             = xmril_out_xf20.mov_line_id
  AND    xmld_out_xf20.item_id                 = ilm_out_xf20.item_id
  AND    xmld_out_xf20.lot_id                  = ilm_out_xf20.lot_id
  AND    xmld_out_xf20.document_type_code      = '20'               -- �ړ�
  AND    xmld_out_xf20.record_type_code        = '30'               -- ���Ɏ���
  AND    xmrih_out_xf20.schedule_ship_date    <= TRUNC( SYSDATE )
  AND    xmrih_out_xf20.mov_type               = '1'  -- �ϑ�����
  AND    xmrih_out_xf20.comp_actual_flg        = 'N'                -- ���і��v��
  AND    xmrih_out_xf20.status                 = '05'               -- ���ɕ񍐗L
  AND    xmril_out_xf20.delete_flg             = 'N'                -- OFF
  UNION ALL
  -- �󒍏o�ח\��
  SELECT iwm_out_om.attribute1                         AS ownership_code
        ,mil_out_om.inventory_location_id              AS inventory_location_id
        ,xmld_out_om.item_id                           AS item_id
        ,ilm_out_om.lot_no                             AS lot_no
        ,ilm_out_om.attribute1                         AS manufacture_date
        ,ilm_out_om.attribute2                         AS uniqe_sign
        ,ilm_out_om.attribute3                         AS expiration_date -- <---- �����܂ŋ���
        ,xoha_out_om.schedule_arrival_date             AS arrival_date
        ,xoha_out_om.schedule_ship_date                AS leaving_date
        ,'1'                                           AS status        -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om.request_no                        AS voucher_no
        ,hpat_out_om.attribute19                       AS ukebaraisaki_name
        ,xpas_out_om.party_site_name                   AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_om.actual_quantity                   AS leaving_quantity
  FROM   xxwsh_order_headers_all      xoha_out_om                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,oe_transaction_types_all     otta_out_om                 -- �󒍃^�C�v
        ,ic_whse_mst                  iwm_out_om                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb2_out_om                -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib2_out_om                -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om                  -- OPM���b�g�}�X�^
        ,hz_parties                   hpat_out_om
        ,hz_cust_accounts             hcsa_out_om
        ,hz_party_sites               hpas_out_om
        ,xxcmn_party_sites            xpas_out_om
        ,gmi_item_categories          gic_out_om
        ,mtl_categories_b             mcb_out_om
        ,(SELECT xrpm_out_om.new_div_invent
                ,flv_out_om.meaning
                ,xrpm_out_om.shipment_provision_div
                ,xrpm_out_om.ship_prov_rcv_pay_category
          FROM   fnd_lookup_values flv_out_om                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om.lookup_type               = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om.language                  = 'JA'
          AND    flv_out_om.lookup_code               = xrpm_out_om.new_div_invent
          AND    xrpm_out_om.doc_type                 = 'OMSO'
          AND    xrpm_out_om.use_div_invent           = 'Y'
          AND    xrpm_out_om.shipment_provision_div   = '1'       -- �o�׈˗�
          AND    xrpm_out_om.item_div_origin          = '5'
          AND    xrpm_out_om.item_div_ahead           = '5'
         ) xrpm
  WHERE  xoha_out_om.order_header_id                  = xola_out_om.order_header_id
  AND    xoha_out_om.deliver_from_id                  = mil_out_om.inventory_location_id
  AND    iwm_out_om.mtl_organization_id               = mil_out_om.organization_id
  AND    xola_out_om.request_item_id                  = msib2_out_om.inventory_item_id
  AND    iimb2_out_om.item_no                         = msib2_out_om.segment1
  AND    msib2_out_om.organization_id                 = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om.mov_line_id                      = xola_out_om.order_line_id
  AND    xmld_out_om.document_type_code               = '10'      -- �o�׈˗�
  AND    xmld_out_om.record_type_code                 = '10'      -- �w��
  AND    xmld_out_om.item_id                          = ilm_out_om.item_id
  AND    xmld_out_om.lot_id                           = ilm_out_om.lot_id
  AND    xoha_out_om.req_status                       = '03'      -- ���ߍ�
  AND    NVL( xoha_out_om.actual_confirm_class, 'N' ) = 'N'       -- ���і��v��
  AND    xoha_out_om.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om.delete_flag                      = 'N'       -- OFF
  AND    xoha_out_om.schedule_ship_date              <= TRUNC( SYSDATE )
  AND    xoha_out_om.order_type_id                    = otta_out_om.transaction_type_id
  AND    xrpm.shipment_provision_div                  = otta_out_om.attribute1
  AND    gic_out_om.item_id                           = iimb2_out_om.item_id
  AND    gic_out_om.category_id                       = mcb_out_om.category_id
  AND    gic_out_om.category_set_id                   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om.segment1                          = '5'
  AND   (xrpm.ship_prov_rcv_pay_category              = otta_out_om.attribute11
  OR     xrpm.ship_prov_rcv_pay_category             IS NULL)
  AND    xoha_out_om.customer_id                      = hpat_out_om.party_id
  AND    hpat_out_om.party_id                         = hcsa_out_om.party_id
  AND    hpat_out_om.status                           = 'A'
  AND    hcsa_out_om.status                           = 'A'
  AND    xoha_out_om.deliver_to_id                    = hpas_out_om.party_site_id
  AND    hpas_out_om.party_site_id                    = xpas_out_om.party_site_id
  AND    hpas_out_om.party_id                         = xpas_out_om.party_id
  AND    hpas_out_om.location_id                      = xpas_out_om.location_id
  AND    hpas_out_om.status                           = 'A'
  AND    xpas_out_om.start_date_active               <= TRUNC(SYSDATE)
  AND    xpas_out_om.end_date_active                 >= TRUNC(SYSDATE)
  UNION ALL
  -- �L���o�ח\��
  SELECT iwm_out_om2.attribute1                        AS ownership_code
        ,mil_out_om2.inventory_location_id             AS inventory_location_id
        ,xmld_out_om2.item_id                          AS item_id
        ,ilm_out_om2.lot_no                            AS lot_no
        ,ilm_out_om2.attribute1                        AS manufacture_date
        ,ilm_out_om2.attribute2                        AS uniqe_sign
        ,ilm_out_om2.attribute3                        AS expiration_date -- <---- �����܂ŋ���
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2.schedule_arrival_date            AS arrival_date
        ,NVL(xoha_out_om2.schedule_arrival_date
            ,xoha_out_om2.schedule_ship_date)          AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
        ,xoha_out_om2.schedule_ship_date               AS leaving_date
        ,'1'                                           AS status        -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2.request_no                       AS voucher_no
        ,xvsa_out_om2.vendor_site_name                 AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2.actual_quantity                  AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2.actual_quantity ) * -1
          ELSE
            xmld_out_om2.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om2                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om2                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,oe_transaction_types_all     otta_out_om2                 -- �󒍃^�C�v
        ,ic_whse_mst                  iwm_out_om2                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om2                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_om2                 -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_om2                 -- �i�ڃ}�X�^
        ,ic_item_mst_b                iimb2_out_om2                -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib2_out_om2                -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om2                  -- OPM���b�g�}�X�^
        ,gmi_item_categories          gic_out_om2
        ,mtl_categories_b             mcb_out_om2
        ,gmi_item_categories          gic2_out_om2
        ,mtl_categories_b             mcb2_out_om2
        ,xxcmn_vendor_sites_all       xvsa_out_om2
        ,(SELECT xrpm_out_om2.new_div_invent
                ,flv_out_om2.meaning
                ,xrpm_out_om2.shipment_provision_div
                ,xrpm_out_om2.ship_prov_rcv_pay_category
-- 2008/10/24 Y.Yamamoto v1.1 add start
                ,xrpm_out_om2.item_div_origin
                ,xrpm_out_om2.item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 add end
          FROM   fnd_lookup_values flv_out_om2                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om2                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om2.lookup_type               = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2.language                  = 'JA'
          AND    flv_out_om2.lookup_code               = xrpm_out_om2.new_div_invent
          AND    xrpm_out_om2.doc_type                 = 'OMSO'
          AND    xrpm_out_om2.use_div_invent           = 'Y'
          AND    xrpm_out_om2.shipment_provision_div   = '2'       -- �x���˗�
          AND    xrpm_out_om2.item_div_origin          = '5'
          AND    xrpm_out_om2.item_div_ahead           = '5'
          AND    xrpm_out_om2.prod_div_origin         IS NOT NULL
          AND    xrpm_out_om2.prod_div_ahead          IS NOT NULL
         ) xrpm
  WHERE  xoha_out_om2.order_header_id                  = xola_out_om2.order_header_id
  AND    xoha_out_om2.deliver_from_id                  = mil_out_om2.inventory_location_id
  AND    iwm_out_om2.mtl_organization_id               = mil_out_om2.organization_id
  AND    xola_out_om2.shipping_inventory_item_id      <> xola_out_om2.request_item_id
  AND    xola_out_om2.request_item_id                  = msib_out_om2.inventory_item_id
  AND    iimb_out_om2.item_no                          = msib_out_om2.segment1
  AND    msib_out_om2.organization_id                  = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2.shipping_inventory_item_id       = msib2_out_om2.inventory_item_id
  AND    iimb2_out_om2.item_no                         = msib2_out_om2.segment1
  AND    msib2_out_om2.organization_id                 = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2.mov_line_id                      = xola_out_om2.order_line_id
  AND    xmld_out_om2.document_type_code               = '30'      -- �x���w��
  AND    xmld_out_om2.record_type_code                 = '10'      -- �w��
  AND    ilm_out_om2.item_id                           = iimb2_out_om2.item_id
  AND    xmld_out_om2.lot_id                           = ilm_out_om2.lot_id
  AND    xoha_out_om2.req_status                       = '07'      -- ��̍�
  AND    NVL( xoha_out_om2.actual_confirm_class, 'N' ) = 'N'       -- ���і��v��
  AND    xoha_out_om2.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om2.delete_flag                      = 'N'       -- OFF
  AND    xoha_out_om2.schedule_ship_date              <= TRUNC( SYSDATE )
  AND    xoha_out_om2.order_type_id                    = otta_out_om2.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2.attribute1
  AND    gic_out_om2.item_id                           = iimb_out_om2.item_id
  AND    gic_out_om2.category_id                       = mcb_out_om2.category_id
  AND    gic_out_om2.category_set_id                   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2.segment1                          = '5'
  AND    gic2_out_om2.item_id                          = iimb2_out_om2.item_id
  AND    gic2_out_om2.category_id                      = mcb2_out_om2.category_id
  AND    gic2_out_om2.category_set_id                  = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb2_out_om2.segment1                         = '5'
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2.attribute11
  OR     xrpm.ship_prov_rcv_pay_category              IS NULL)
-- 2008/10/24 Y.Yamamoto v1.1 add start
  AND    xrpm.item_div_origin                          = mcb2_out_om2.segment1
  AND    xrpm.item_div_ahead                           = mcb_out_om2.segment1
-- 2008/10/24 Y.Yamamoto v1.1 add end
  AND    xvsa_out_om2.vendor_site_id                   = xoha_out_om2.vendor_site_id
  AND    xvsa_out_om2.start_date_active               <= TRUNC(SYSDATE)
  AND    xvsa_out_om2.end_date_active                 >= TRUNC(SYSDATE)
  UNION ALL
  SELECT iwm_out_om2.attribute1                        AS ownership_code
        ,mil_out_om2.inventory_location_id             AS inventory_location_id
        ,xmld_out_om2.item_id                          AS item_id
        ,ilm_out_om2.lot_no                            AS lot_no
        ,ilm_out_om2.attribute1                        AS manufacture_date
        ,ilm_out_om2.attribute2                        AS uniqe_sign
        ,ilm_out_om2.attribute3                        AS expiration_date -- <---- �����܂ŋ���
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2.schedule_arrival_date            AS arrival_date
        ,NVL(xoha_out_om2.schedule_arrival_date
            ,xoha_out_om2.schedule_ship_date)          AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
        ,xoha_out_om2.schedule_ship_date               AS leaving_date
        ,'1'                                           AS status        -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2.request_no                       AS voucher_no
        ,xvsa_out_om2.vendor_site_name                 AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2.actual_quantity                  AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2.actual_quantity ) * -1
          ELSE
            xmld_out_om2.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om2                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om2                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,oe_transaction_types_all     otta_out_om2                 -- �󒍃^�C�v
        ,ic_whse_mst                  iwm_out_om2                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om2                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_om2                 -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_om2                 -- �i�ڃ}�X�^
        ,ic_item_mst_b                iimb2_out_om2                -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib2_out_om2                -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om2                  -- OPM���b�g�}�X�^
        ,gmi_item_categories          gic_out_om2
        ,mtl_categories_b             mcb_out_om2
        ,gmi_item_categories          gic2_out_om2
        ,mtl_categories_b             mcb2_out_om2
        ,xxcmn_vendor_sites_all       xvsa_out_om2
        ,(SELECT xrpm_out_om2.new_div_invent
                ,flv_out_om2.meaning
                ,xrpm_out_om2.shipment_provision_div
                ,xrpm_out_om2.ship_prov_rcv_pay_category
-- 2008/10/24 Y.Yamamoto v1.1 update start
--                ,nvl(xrpm_out_om2.item_div_origin,'Dummy')         AS item_div_origin
--                ,nvl(xrpm_out_om2.item_div_ahead,'Dummy')          AS item_div_ahead
                ,xrpm_out_om2.item_div_origin
                ,DECODE(xrpm_out_om2.item_div_ahead,'5','5','Dummy') AS item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 update end
          FROM   fnd_lookup_values flv_out_om2                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om2                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om2.lookup_type               = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2.language                  = 'JA'
          AND    flv_out_om2.lookup_code               = xrpm_out_om2.new_div_invent
          AND    xrpm_out_om2.doc_type                 = 'OMSO'
          AND    xrpm_out_om2.use_div_invent           = 'Y'
          AND    xrpm_out_om2.shipment_provision_div   = '2'       -- �x���˗�
          AND    xrpm_out_om2.item_div_origin          = '5'
          AND    xrpm_out_om2.prod_div_origin         IS NULL
          AND    xrpm_out_om2.prod_div_ahead          IS NULL
         ) xrpm
  WHERE  xoha_out_om2.order_header_id                  = xola_out_om2.order_header_id
  AND    xoha_out_om2.deliver_from_id                  = mil_out_om2.inventory_location_id
  AND    iwm_out_om2.mtl_organization_id               = mil_out_om2.organization_id
  AND    xola_out_om2.shipping_inventory_item_id      <> xola_out_om2.request_item_id
  AND    xola_out_om2.request_item_id                  = msib_out_om2.inventory_item_id
  AND    iimb_out_om2.item_no                          = msib_out_om2.segment1
  AND    msib_out_om2.organization_id                  = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2.shipping_inventory_item_id       = msib2_out_om2.inventory_item_id
  AND    iimb2_out_om2.item_no                         = msib2_out_om2.segment1
  AND    msib2_out_om2.organization_id                 = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2.mov_line_id                      = xola_out_om2.order_line_id
  AND    xmld_out_om2.document_type_code               = '30'      -- �x���w��
  AND    xmld_out_om2.record_type_code                 = '10'      -- �w��
  AND    ilm_out_om2.item_id                           = iimb2_out_om2.item_id
  AND    xmld_out_om2.lot_id                           = ilm_out_om2.lot_id
  AND    xoha_out_om2.req_status                       = '07'      -- ��̍�
  AND    NVL( xoha_out_om2.actual_confirm_class, 'N' ) = 'N'       -- ���і��v��
  AND    xoha_out_om2.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om2.delete_flag                      = 'N'       -- OFF
  AND    xoha_out_om2.schedule_ship_date              <= TRUNC( SYSDATE )
  AND    xoha_out_om2.order_type_id                    = otta_out_om2.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2.attribute1
  AND    gic_out_om2.item_id                           = iimb_out_om2.item_id
  AND    gic_out_om2.category_id                       = mcb_out_om2.category_id
  AND    gic_out_om2.category_set_id                   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2.segment1                          = '5'
  AND    gic2_out_om2.item_id                          = iimb2_out_om2.item_id
  AND    gic2_out_om2.category_id                      = mcb2_out_om2.category_id
  AND    gic2_out_om2.category_set_id                  = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2.segment1,'5','5','Dummy')
-- 2008/10/24 Y.Yamamoto v1.1 update start
--  AND    xrpm.item_div_ahead                           = DECODE(mcb_out_om2.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2.segment1
-- 2008/10/24 Y.Yamamoto v1.1 update end
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2.attribute11
  OR     xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xvsa_out_om2.vendor_site_id                   = xoha_out_om2.vendor_site_id
  AND    xvsa_out_om2.start_date_active               <= TRUNC(SYSDATE)
  AND    xvsa_out_om2.end_date_active                 >= TRUNC(SYSDATE)
-- 2008/10/24 Y.Yamamoto v1.1 add start
  UNION ALL
  SELECT iwm_out_om2.attribute1                        AS ownership_code
        ,mil_out_om2.inventory_location_id             AS inventory_location_id
        ,xmld_out_om2.item_id                          AS item_id
        ,ilm_out_om2.lot_no                            AS lot_no
        ,ilm_out_om2.attribute1                        AS manufacture_date
        ,ilm_out_om2.attribute2                        AS uniqe_sign
        ,ilm_out_om2.attribute3                        AS expiration_date -- <---- �����܂ŋ���
        ,NVL(xoha_out_om2.schedule_arrival_date
            ,xoha_out_om2.schedule_ship_date)          AS arrival_date
        ,xoha_out_om2.schedule_ship_date               AS leaving_date
        ,'1'                                           AS status        -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2.request_no                       AS voucher_no
        ,xvsa_out_om2.vendor_site_name                 AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2.actual_quantity                  AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2.actual_quantity ) * -1
          ELSE
            xmld_out_om2.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om2                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om2                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,oe_transaction_types_all     otta_out_om2                 -- �󒍃^�C�v
        ,ic_whse_mst                  iwm_out_om2                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om2                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_om2                 -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_om2                 -- �i�ڃ}�X�^
        ,ic_item_mst_b                iimb2_out_om2                -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib2_out_om2                -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om2                  -- OPM���b�g�}�X�^
        ,gmi_item_categories          gic_out_om2
        ,mtl_categories_b             mcb_out_om2
        ,gmi_item_categories          gic2_out_om2
        ,mtl_categories_b             mcb2_out_om2
        ,xxcmn_vendor_sites_all       xvsa_out_om2
        ,(SELECT xrpm_out_om2.new_div_invent
                ,flv_out_om2.meaning
                ,xrpm_out_om2.shipment_provision_div
                ,xrpm_out_om2.ship_prov_rcv_pay_category
                ,xrpm_out_om2.item_div_origin
                ,DECODE(xrpm_out_om2.item_div_ahead,'5','5','Dummy') AS item_div_ahead
          FROM   fnd_lookup_values flv_out_om2                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om2                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om2.lookup_type               = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2.language                  = 'JA'
          AND    flv_out_om2.lookup_code               = xrpm_out_om2.new_div_invent
          AND    xrpm_out_om2.doc_type                 = 'OMSO'
          AND    xrpm_out_om2.use_div_invent           = 'Y'
          AND    xrpm_out_om2.shipment_provision_div   = '2'       -- �x���˗�
          AND    xrpm_out_om2.item_div_origin          = '5'
          AND    xrpm_out_om2.prod_div_origin         IS NULL
          AND    xrpm_out_om2.prod_div_ahead          IS NULL
         ) xrpm
  WHERE  xoha_out_om2.order_header_id                  = xola_out_om2.order_header_id
  AND    xoha_out_om2.deliver_from_id                  = mil_out_om2.inventory_location_id
  AND    iwm_out_om2.mtl_organization_id               = mil_out_om2.organization_id
  AND    xola_out_om2.shipping_inventory_item_id       = xola_out_om2.request_item_id
  AND    xola_out_om2.request_item_id                  = msib_out_om2.inventory_item_id
  AND    iimb_out_om2.item_no                          = msib_out_om2.segment1
  AND    msib_out_om2.organization_id                  = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2.shipping_inventory_item_id       = msib2_out_om2.inventory_item_id
  AND    iimb2_out_om2.item_no                         = msib2_out_om2.segment1
  AND    msib2_out_om2.organization_id                 = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2.mov_line_id                      = xola_out_om2.order_line_id
  AND    xmld_out_om2.document_type_code               = '30'      -- �x���w��
  AND    xmld_out_om2.record_type_code                 = '10'      -- �w��
  AND    ilm_out_om2.item_id                           = iimb2_out_om2.item_id
  AND    xmld_out_om2.lot_id                           = ilm_out_om2.lot_id
  AND    xoha_out_om2.req_status                       = '07'      -- ��̍�
  AND    NVL( xoha_out_om2.actual_confirm_class, 'N' ) = 'N'       -- ���і��v��
  AND    xoha_out_om2.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om2.delete_flag                      = 'N'       -- OFF
  AND    xoha_out_om2.schedule_ship_date              <= TRUNC( SYSDATE )
  AND    xoha_out_om2.order_type_id                    = otta_out_om2.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2.attribute1
  AND    gic_out_om2.item_id                           = iimb_out_om2.item_id
  AND    gic_out_om2.category_id                       = mcb_out_om2.category_id
  AND    gic_out_om2.category_set_id                   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2.segment1                          = '5'
  AND    gic2_out_om2.item_id                          = iimb2_out_om2.item_id
  AND    gic2_out_om2.category_id                      = mcb2_out_om2.category_id
  AND    gic2_out_om2.category_set_id                  = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2.attribute11
  OR     xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2.segment1
  AND    xvsa_out_om2.vendor_site_id                   = xoha_out_om2.vendor_site_id
  AND    xvsa_out_om2.start_date_active               <= TRUNC(SYSDATE)
  AND    xvsa_out_om2.end_date_active                 >= TRUNC(SYSDATE)
-- 2008/10/24 Y.Yamamoto v1.1 add end
  UNION ALL
  -- ���Y���������\��
  SELECT iwm_out_pr.attribute1                         AS ownership_code
        ,mil_out_pr.inventory_location_id              AS inventory_location_id
        ,xmld_out_pr.item_id                           AS item_id
        ,ilm_out_pr.lot_no                             AS lot_no
        ,ilm_out_pr.attribute1                         AS manufacture_date
        ,ilm_out_pr.attribute2                         AS uniqe_sign
        ,ilm_out_pr.attribute3                         AS expiration_date -- <---- �����܂ŋ���
        ,gbh_out_pr.plan_start_date                    AS arrival_date
        ,gbh_out_pr.plan_start_date                    AS leaving_date
        ,'1'                                           AS status       -- �\��
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_out_pr.batch_no                           AS voucher_no
        ,grt_out_pr.routing_desc                       AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_pr.actual_quantity                   AS leaving_quantity
  FROM   gme_batch_header             gbh_out_pr                  -- ���Y�o�b�`
        ,gme_material_details         gmd_out_pr                  -- ���Y�����ڍ�
        ,xxinv_mov_lot_details        xmld_out_pr                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,gmd_routings_b               grb_out_pr                  -- �H���}�X�^
        ,gmd_routings_tl              grt_out_pr                  -- �H���}�X�^���{��
-- 2008/11/19 Y.Yamamoto v1.2 add start
        ,ic_tran_pnd                  itp_out_pr                  -- OPM�ۗ��݌Ƀg�����U�N�V����
-- 2008/11/19 Y.Yamamoto v1.2 add end
        ,ic_whse_mst                  iwm_out_pr                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_pr                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_pr                  -- OPM���b�g�}�X�^
        ,(SELECT xrpm_out_pr.new_div_invent
                ,flv_out_pr.meaning
                ,xrpm_out_pr.routing_class
                ,xrpm_out_pr.line_type
                ,xrpm_out_pr.hit_in_div
-- 2008/11/19 Y.Yamamoto v1.2 add start
                ,xrpm_out_pr.doc_type
-- 2008/11/19 Y.Yamamoto v1.2 add end
          FROM   fnd_lookup_values flv_out_pr                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_pr                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_pr.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_pr.language                 = 'JA'
          AND    flv_out_pr.lookup_code              = xrpm_out_pr.new_div_invent
          AND    xrpm_out_pr.doc_type                = 'PROD'
          AND    xrpm_out_pr.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_out_pr.batch_id                 = gmd_out_pr.batch_id
  AND    gmd_out_pr.material_detail_id       = xmld_out_pr.mov_line_id
  AND    gmd_out_pr.line_type                = -1                 -- �����i
-- 2008/11/19 Y.Yamamoto v1.2 add start
  AND    itp_out_pr.doc_type                 = xrpm.doc_type
  AND    itp_out_pr.doc_id                   = gmd_out_pr.batch_id
  AND    itp_out_pr.line_id                  = gmd_out_pr.material_detail_id
  AND    itp_out_pr.doc_line                 = gmd_out_pr.line_no
  AND    itp_out_pr.line_type                = gmd_out_pr.line_type
  AND    itp_out_pr.item_id                  = gmd_out_pr.item_id
  AND    itp_out_pr.completed_ind            = 0
  AND    itp_out_pr.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
  AND    itp_out_pr.item_id                  = ilm_out_pr.item_id
  AND    itp_out_pr.lot_id                   = ilm_out_pr.lot_id
-- 2008/11/19 Y.Yamamoto v1.2 add end
  AND    xmld_out_pr.document_type_code      = '40'
  AND    xmld_out_pr.record_type_code        = '10'
  AND    xmld_out_pr.item_id                 = ilm_out_pr.item_id
  AND    xmld_out_pr.lot_id                  = ilm_out_pr.lot_id
  AND    grb_out_pr.attribute9               = mil_out_pr.segment1
  AND    iwm_out_pr.mtl_organization_id      = mil_out_pr.organization_id
-- 2008/11/19 Y.Yamamoto v1.2 update start
--  AND    NOT EXISTS( SELECT 1
--                     FROM   gme_batch_header gbh_out_pr_ex
--                     WHERE  gbh_out_pr_ex.batch_id      = gbh_out_pr.batch_id
--                     AND    gbh_out_pr_ex.batch_status IN ( 7     -- ����
--                                                           ,8     -- �N���[�Y
--                                                           ,-1 )) -- ���
  AND    gbh_out_pr.batch_status            IN ( 1                  -- �ۗ�
                                                ,2 )                -- WIP
-- 2008/11/19 Y.Yamamoto v1.2 update end
  AND    gbh_out_pr.plan_start_date         <= TRUNC( SYSDATE )
  AND    grb_out_pr.routing_id               = gbh_out_pr.routing_id
  AND    xrpm.routing_class                  = grb_out_pr.routing_class
  AND    xrpm.line_type                      = gmd_out_pr.line_type
  AND ((( gmd_out_pr.attribute5             IS NULL )
    AND ( xrpm.hit_in_div                   IS NULL ))
  OR   (( gmd_out_pr.attribute5              = 'Y' )
    AND ( xrpm.hit_in_div                    = gmd_out_pr.attribute5 )))
  AND    grb_out_pr.routing_id               = grt_out_pr.routing_id
  AND    grt_out_pr.language                 = 'JA'
  UNION ALL
  -- �����݌ɏo�ɗ\��
  SELECT iwm_out_ad.attribute1                          AS ownership_code
        ,mil_out_ad.inventory_location_id               AS inventory_location_id
        ,iimb_out_ad.item_id                            AS item_id
        ,ilm_out_ad.lot_no                              AS lot_no
        ,ilm_out_ad.attribute1                          AS manufacture_date
        ,ilm_out_ad.attribute2                          AS uniqe_sign
        ,ilm_out_ad.attribute3                          AS expiration_date -- <---- �����܂ŋ���
        ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) AS arrival_date
        ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) AS leaving_date
        ,'1'                                            AS status        -- �\��
        ,xrpm.new_div_invent                            AS reason_code
        ,xrpm.meaning                                   AS reason_code_name
        ,pha_out_ad.segment1                            AS voucher_no
        ,xv_out_ad.vendor_name                          AS ukebaraisaki_name
        ,NULL                                           AS deliver_to_name
        ,0                                              AS stock_quantity
        ,pla_out_ad.quantity                            AS leaving_quantity
  FROM   po_headers_all               pha_out_ad                  -- �����w�b�_
        ,po_lines_all                 pla_out_ad                  -- ��������
        ,xxinv_mov_lot_details        xmld_out_ad                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_out_ad                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_ad                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_ad                 -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_ad                 -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_ad                  -- OPM���b�g�}�X�^
        ,po_vendors                   pv_out_ad                   -- �d����}�X�^
        ,xxcmn_vendors                xv_out_ad                   -- �d����A�h�I���}�X�^
        ,(SELECT xrpm_out_ad.new_div_invent
                ,flv_out_ad.meaning
          FROM   fnd_lookup_values flv_out_ad                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_ad                     -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_ad.lookup_type           = 'XXCMN_NEW_DIVISION'
          AND    flv_out_ad.language              = 'JA'
          AND    flv_out_ad.lookup_code           = xrpm_out_ad.new_div_invent
          AND    xrpm_out_ad.doc_type             = 'ADJI'
          AND    xrpm_out_ad.use_div_invent       = 'Y'
          AND    xrpm_out_ad.reason_code          = 'X977'                 -- �����݌�
          AND    xrpm_out_ad.rcv_pay_div          = '-1'                   -- ���o
         ) xrpm
  WHERE  pha_out_ad.po_header_id          = pla_out_ad.po_header_id
  AND    pha_out_ad.attribute1           IN ( '20'                 -- �����쐬��
                                             ,'25' )               -- �������
  AND    pla_out_ad.attribute13           = 'N'                    -- ������
  AND    pha_out_ad.attribute11           = '3'
  AND    pla_out_ad.po_line_id            = xmld_out_ad.mov_line_id
  AND    pla_out_ad.item_id               = msib_out_ad.inventory_item_id
  AND    iimb_out_ad.item_no              = msib_out_ad.segment1
  AND    msib_out_ad.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_ad.item_id              = ilm_out_ad.item_id
  AND    xmld_out_ad.lot_id               = ilm_out_ad.lot_id
  AND    xmld_out_ad.document_type_code   = '50'
  AND    xmld_out_ad.record_type_code     = '10'
  AND    pla_out_ad.attribute12           = mil_out_ad.segment1
  AND    iwm_out_ad.mtl_organization_id   = mil_out_ad.organization_id
  AND    pha_out_ad.attribute4           <= TO_CHAR( SYSDATE, 'YYYY/MM/DD' )
  AND    pha_out_ad.vendor_id             = xv_out_ad.vendor_id   -- �d������VIEW
  AND    pv_out_ad.vendor_id              = xv_out_ad.vendor_id
  AND    pv_out_ad.end_date_active       IS NULL
  AND    xv_out_ad.start_date_active     <= TRUNC( SYSDATE )
  AND    xv_out_ad.end_date_active       >= TRUNC( SYSDATE )
  UNION ALL
  ------------------------------------------------------------------------
  -- ���Ɏ���
  ------------------------------------------------------------------------
  --�����������
  SELECT iwm_in_po_e.attribute1                        AS ownership_code
        ,mil_in_po_e.inventory_location_id             AS inventory_location_id
        ,iimb_in_po_e.item_id                          AS item_id
        ,ilm_in_po_e.lot_no                            AS lot_no
        ,ilm_in_po_e.attribute1                        AS manufacture_date
        ,ilm_in_po_e.attribute2                        AS uniqe_sign
        ,ilm_in_po_e.attribute3                        AS expiration_date -- <---- �����܂ŋ���
        ,xrart_in_po_e.txns_date                       AS arrival_date
        ,xrart_in_po_e.txns_date                       AS leaving_date
        ,'2'                                           AS status        -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,pha_in_po_e.segment1                          AS voucher_no
        ,xv_in_po_e.vendor_name                        AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,xrart_in_po_e.quantity                        AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   po_headers_all               pha_in_po_e               -- �����w�b�_
        ,po_lines_all                 pla_in_po_e               -- ��������
        ,xxpo_rcv_and_rtn_txns        xrart_in_po_e             -- ����ԕi����(�A�h�I��)
        ,rcv_shipment_lines           rsl_in_po_e               -- �������
        ,rcv_transactions             rt_in_po_e                -- ������
        ,po_vendors                   pv_in_po_e                -- �d����}�X�^
        ,xxcmn_vendors                xv_in_po_e                -- �d����A�h�I���}�X�^
        ,ic_whse_mst                  iwm_in_po_e               -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_po_e               -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_in_po_e              -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_in_po_e              -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_in_po_e               -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_po_e.new_div_invent
                ,flv_in_po_e.meaning
                ,xrpm_in_po_e.transaction_type
          FROM   fnd_lookup_values flv_in_po_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_in_po_e                     -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_po_e.lookup_type           = 'XXCMN_NEW_DIVISION'
          AND    flv_in_po_e.language              = 'JA'
          AND    flv_in_po_e.lookup_code           = xrpm_in_po_e.new_div_invent
          AND    xrpm_in_po_e.doc_type             = 'PORC'
          AND    xrpm_in_po_e.source_document_code = 'PO'
          AND    xrpm_in_po_e.use_div_invent       = 'Y'
         ) xrpm
  WHERE  pha_in_po_e.po_header_id          = pla_in_po_e.po_header_id
  AND    pha_in_po_e.attribute5            = mil_in_po_e.segment1
  AND    iwm_in_po_e.mtl_organization_id   = mil_in_po_e.organization_id
  AND    pla_in_po_e.item_id               = msib_in_po_e.inventory_item_id
  AND    iimb_in_po_e.item_no              = msib_in_po_e.segment1
  AND    msib_in_po_e.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    iimb_in_po_e.item_id              = ilm_in_po_e.item_id
  AND    pla_in_po_e.attribute1            = ilm_in_po_e.lot_no
  AND    pha_in_po_e.attribute1           IN ( '25'                 -- �������
                                              ,'30'                 -- ���ʊm���
                                              ,'35' )               -- ���z�m���
  AND    pla_in_po_e.attribute13           = 'Y'                    -- ������
  AND    pha_in_po_e.segment1              = xrart_in_po_e.source_document_number
  AND    pla_in_po_e.line_num              = xrart_in_po_e.source_document_line_num
  AND    xrart_in_po_e.txns_type           = '1'                    -- ���
  AND    pla_in_po_e.cancel_flag          <> 'Y'
  AND    rsl_in_po_e.po_header_id          = pha_in_po_e.po_header_id
  AND    rsl_in_po_e.po_line_id            = pla_in_po_e.po_line_id
  AND    xrart_in_po_e.txns_id             = rsl_in_po_e.attribute1
  AND    rt_in_po_e.shipment_line_id       = rsl_in_po_e.shipment_line_id
  AND    rt_in_po_e.destination_type_code  = rsl_in_po_e.destination_type_code
  AND    xrpm.transaction_type             = rt_in_po_e.transaction_type
  AND    pha_in_po_e.vendor_id             = xv_in_po_e.vendor_id   -- �d������VIEW
  AND    pv_in_po_e.vendor_id              = xv_in_po_e.vendor_id
  AND    pv_in_po_e.end_date_active       IS NULL
  AND    xv_in_po_e.start_date_active     <= TRUNC( SYSDATE )
  AND    xv_in_po_e.end_date_active       >= TRUNC( SYSDATE )
  UNION ALL
  -- �ړ����Ɏ���(�ϑ�����)
  SELECT /*+ index(XMLD XXINV_MLD_N04) */
         iwm_in_xf_e.attribute1                        AS ownership_code
        ,mil_in_xf_e.inventory_location_id             AS inventory_location_id
        ,xmld_in_xf_e.item_id                          AS item_id
        ,ilm_in_xf_e.lot_no                            AS lot_no
        ,ilm_in_xf_e.attribute1                        AS manufacture_date
        ,ilm_in_xf_e.attribute2                        AS uniqe_sign
        ,ilm_in_xf_e.attribute3                        AS expiration_date -- <---- �����܂ŋ���
        ,xmrih_in_xf_e.actual_arrival_date             AS arrival_date
        ,xmrih_in_xf_e.actual_ship_date                AS leaving_date
        ,'2'                                           AS status           -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_xf_e.mov_num                         AS voucher_no
        ,mil2_in_xf_e.description                      AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,xmld_in_xf_e.actual_quantity                  AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_in_xf_e                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_in_xf_e                  -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_in_xf_e                   -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_in_xf_e                    -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_xf_e                    -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_in_xf_e                   -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_xf_e                    -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_xf_e.new_div_invent
                ,flv_in_xf_e.meaning
          FROM   fnd_lookup_values flv_in_xf_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_in_xf_e                     -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_xf_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_xf_e.language                 = 'JA'
          AND    flv_in_xf_e.lookup_code              = xrpm_in_xf_e.new_div_invent
          AND    xrpm_in_xf_e.doc_type                = 'XFER'               -- �ړ��ϑ�����
          AND    xrpm_in_xf_e.use_div_invent          = 'Y'
          AND    xrpm_in_xf_e.rcv_pay_div             = '1'
         ) xrpm
  WHERE  xmrih_in_xf_e.mov_hdr_id             = xmril_in_xf_e.mov_hdr_id
  AND    xmril_in_xf_e.mov_line_id            = xmld_in_xf_e.mov_line_id
  AND    xmrih_in_xf_e.ship_to_locat_id       = mil_in_xf_e.inventory_location_id
  AND    iwm_in_xf_e.mtl_organization_id      = mil_in_xf_e.organization_id
  AND    xmrih_in_xf_e.shipped_locat_id       = mil2_in_xf_e.inventory_location_id
  AND    xmld_in_xf_e.item_id                 = ilm_in_xf_e.item_id
  AND    xmld_in_xf_e.lot_id                  = ilm_in_xf_e.lot_id
  AND    xmld_in_xf_e.document_type_code      = '20'                 -- �ړ�
  AND    xmld_in_xf_e.record_type_code        = '30'                 -- ���Ɏ���
  AND    xmrih_in_xf_e.mov_type               = '1'                  -- �ϑ�����
  AND    xmril_in_xf_e.delete_flg             = 'N'                  -- OFF
  AND    xmrih_in_xf_e.status                IN ( '06'               -- ���o�ɕ񍐗L
                                                 ,'05' )             -- ���ɕ񍐗L
  UNION ALL
  -- �ړ����Ɏ���(�ϑ��Ȃ�)
  SELECT /*+ index(XMLD XXINV_MLD_N04) */
         iwm_in_tr_e.attribute1                        AS ownership_code
        ,mil_in_tr_e.inventory_location_id             AS inventory_location_id
        ,xmld_in_tr_e.item_id                          AS item_id
        ,ilm_in_tr_e.lot_no                            AS lot_no
        ,ilm_in_tr_e.attribute1                        AS manufacture_date
        ,ilm_in_tr_e.attribute2                        AS uniqe_sign
        ,ilm_in_tr_e.attribute3                        AS expiration_date -- <---- �����܂ŋ���
        ,xmrih_in_tr_e.actual_arrival_date             AS arrival_date
        ,xmrih_in_tr_e.actual_ship_date                AS leaving_date
        ,'2'                                           AS status        -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_tr_e.mov_num                         AS voucher_no
        ,mil2_in_tr_e.description                      AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,xmld_in_tr_e.actual_quantity                  AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_in_tr_e               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_in_tr_e               -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_in_tr_e                -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_in_tr_e                    -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_tr_e                    -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_in_tr_e                   -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_tr_e                 -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_tr_e.new_div_invent
                ,flv_in_tr_e.meaning
          FROM   fnd_lookup_values flv_in_tr_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_in_tr_e                     -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_tr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_tr_e.language                 = 'JA'
          AND    flv_in_tr_e.lookup_code              = xrpm_in_tr_e.new_div_invent
          AND    xrpm_in_tr_e.doc_type                = 'TRNI'            -- �ړ��ϑ��Ȃ�
          AND    xrpm_in_tr_e.use_div_invent          = 'Y'
          AND    xrpm_in_tr_e.rcv_pay_div             = '1'
         ) xrpm
  WHERE  xmrih_in_tr_e.mov_hdr_id             = xmril_in_tr_e.mov_hdr_id
  AND    xmril_in_tr_e.mov_line_id            = xmld_in_tr_e.mov_line_id
  AND    xmrih_in_tr_e.ship_to_locat_id       = mil_in_tr_e.inventory_location_id
  AND    iwm_in_tr_e.mtl_organization_id      = mil_in_tr_e.organization_id
  AND    xmrih_in_tr_e.shipped_locat_id       = mil2_in_tr_e.inventory_location_id
  AND    xmld_in_tr_e.item_id                 = ilm_in_tr_e.item_id
  AND    xmld_in_tr_e.lot_id                  = ilm_in_tr_e.lot_id
  AND    xmld_in_tr_e.document_type_code      = '20'              -- �ړ�
  AND    xmld_in_tr_e.record_type_code        = '30'              -- ���Ɏ���
  AND    xmrih_in_tr_e.mov_type               = '2'               -- �ϑ��Ȃ�
  AND    xmrih_in_tr_e.status                 = '06'              -- ���o�ɕ񍐗L
  AND    xmril_in_tr_e.delete_flg             = 'N'               -- OFF
  UNION ALL
  -- ���Y���Ɏ���
  SELECT iwm_in_pr_e.attribute1                        AS ownership_code
        ,mil_in_pr_e.inventory_location_id             AS inventory_location_id
        ,gmd_in_pr_e.item_id                           AS item_id
        ,ilm_in_pr_e.lot_no                            AS lot_no
        ,ilm_in_pr_e.attribute1                        AS manufacture_date
        ,ilm_in_pr_e.attribute2                        AS uniqe_sign
        ,ilm_in_pr_e.attribute3                        AS expiration_date -- <---- �����܂ŋ���
        ,itp_in_pr_e.trans_date                        AS arrival_date
        ,itp_in_pr_e.trans_date                        AS leaving_date
        ,'2'                                           AS status         -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_in_pr_e.batch_no                          AS voucher_no
        ,grt_in_pr_e.routing_desc                      AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itp_in_pr_e.trans_qty                         AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   gme_batch_header             gbh_in_pr_e                  -- ���Y�o�b�`
        ,gme_material_details         gmd_in_pr_e                  -- ���Y�����ڍ�
        ,ic_tran_pnd                  itp_in_pr_e                  -- OPM�ۗ��݌Ƀg�����U�N�V����
        ,gmd_routings_b               grb_in_pr_e                  -- �H���}�X�^
        ,gmd_routings_tl              grt_in_pr_e                  -- �H���}�X�^���{��
        ,ic_whse_mst                  iwm_in_pr_e                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_pr_e                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_pr_e                  -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_pr_e.new_div_invent
                ,flv_in_pr_e.meaning
                ,xrpm_in_pr_e.doc_type
                ,xrpm_in_pr_e.transaction_type
                ,xrpm_in_pr_e.routing_class
                ,xrpm_in_pr_e.line_type
                ,xrpm_in_pr_e.hit_in_div
          FROM   fnd_lookup_values flv_in_pr_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_in_pr_e                     -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_pr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_pr_e.language                 = 'JA'
          AND    flv_in_pr_e.lookup_code              = xrpm_in_pr_e.new_div_invent
          AND    xrpm_in_pr_e.doc_type                = 'PROD'
          AND    xrpm_in_pr_e.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_in_pr_e.batch_id                 = gmd_in_pr_e.batch_id
  AND    itp_in_pr_e.doc_id                   = gmd_in_pr_e.batch_id
  AND    itp_in_pr_e.doc_line                 = gmd_in_pr_e.line_no
  AND    itp_in_pr_e.line_type                = gmd_in_pr_e.line_type
  AND    itp_in_pr_e.item_id                  = gmd_in_pr_e.item_id
  AND    itp_in_pr_e.item_id                  = ilm_in_pr_e.item_id
  AND    itp_in_pr_e.lot_id                   = ilm_in_pr_e.lot_id
  AND    itp_in_pr_e.location                 = mil_in_pr_e.segment1
  AND    grb_in_pr_e.attribute9               = mil_in_pr_e.segment1
  AND    mil_in_pr_e.organization_id          = iwm_in_pr_e.mtl_organization_id
  AND    itp_in_pr_e.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
  AND    gmd_in_pr_e.line_type               IN ( 1                -- �����i
                                                 ,2 )              -- ���Y��
  AND    itp_in_pr_e.doc_type                 = xrpm.doc_type
  AND    itp_in_pr_e.completed_ind            = 1
  AND    itp_in_pr_e.reverse_id              IS NULL
  AND    grb_in_pr_e.routing_id               = gbh_in_pr_e.routing_id
  AND    xrpm.routing_class                   = grb_in_pr_e.routing_class
  AND    xrpm.line_type                       = gmd_in_pr_e.line_type
  AND ((( gmd_in_pr_e.attribute5              IS NULL )
    AND ( xrpm.hit_in_div                     IS NULL ))
  OR   (( gmd_in_pr_e.attribute5              = 'Y' )
    AND ( xrpm.hit_in_div                     = gmd_in_pr_e.attribute5 )))
  AND    grb_in_pr_e.routing_id               = grt_in_pr_e.routing_id
  AND    grt_in_pr_e.language                 = 'JA'
  AND NOT EXISTS 
    ( SELECT 1
      FROM   gmd_routing_class_b   grcb_in_pr_ex          -- �H���敪�}�X�^
            ,gmd_routing_class_tl  grct_in_pr_ex          -- �H���敪�}�X�^���{��
      WHERE  grcb_in_pr_ex.routing_class      = grb_in_pr_e.routing_class
      AND    grct_in_pr_ex.routing_class      = grcb_in_pr_ex.routing_class
      AND    grct_in_pr_ex.language           = 'JA'
      AND    grct_in_pr_ex.routing_class_desc IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
                                                 ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')
                                                 ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET'))
    )
  UNION ALL
  -- ���Y���Ɏ��� �i�ڐU�� �i��U��
  SELECT iwm_in_pr_e70.attribute1                      AS ownership_code
        ,mil_in_pr_e70.inventory_location_id           AS inventory_location_id
        ,gmd_in_pr_e70a.item_id                        AS item_id
        ,ilm_in_pr_e70.lot_no                          AS lot_no
        ,ilm_in_pr_e70.attribute1                      AS manufacture_date
        ,ilm_in_pr_e70.attribute2                      AS uniqe_sign
        ,ilm_in_pr_e70.attribute3                      AS expiration_date -- <---- �����܂ŋ���
        ,itp_in_pr_e70.trans_date                      AS arrival_date
        ,itp_in_pr_e70.trans_date                      AS leaving_date
        ,'2'                                           AS status         -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_in_pr_e70.batch_no                        AS voucher_no
        ,grt_in_pr_e70.routing_desc                    AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itp_in_pr_e70.trans_qty                       AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   gme_batch_header             gbh_in_pr_e70                  -- ���Y�o�b�`
        ,gme_material_details         gmd_in_pr_e70a                 -- ���Y�����ڍ�(�U�֐�)
        ,gme_material_details         gmd_in_pr_e70b                 -- ���Y�����ڍ�(�U�֌�)
        ,ic_tran_pnd                  itp_in_pr_e70                  -- OPM�ۗ��݌Ƀg�����U�N�V����
        ,gmd_routings_b               grb_in_pr_e70                  -- �H���}�X�^
        ,gmd_routings_tl              grt_in_pr_e70                  -- �H���}�X�^���{��
        ,gmd_routing_class_b          grcb_in_pr_e70                 -- �H���敪�}�X�^
        ,gmd_routing_class_tl         grct_in_pr_e70                 -- �H���敪�}�X�^���{��
        ,ic_whse_mst                  iwm_in_pr_e70                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_pr_e70                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_pr_e70                  -- OPM���b�g�}�X�^
        ,gmi_item_categories          gic_in_pr_e70_s
        ,mtl_categories_b             mcb_in_pr_e70_s
        ,gmi_item_categories          gic_in_pr_e70_r
        ,mtl_categories_b             mcb_in_pr_e70_r
        ,(SELECT xrpm_in_pr_e70.new_div_invent
                ,flv_in_pr_e70.meaning
                ,xrpm_in_pr_e70.doc_type
                ,xrpm_in_pr_e70.routing_class
                ,xrpm_in_pr_e70.line_type
                ,xrpm_in_pr_e70.item_div_ahead
                ,xrpm_in_pr_e70.item_div_origin
          FROM   fnd_lookup_values flv_in_pr_e70                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_in_pr_e70                     -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_pr_e70.language                 = 'JA'
          AND    flv_in_pr_e70.lookup_code              = xrpm_in_pr_e70.new_div_invent
          AND    xrpm_in_pr_e70.doc_type                = 'PROD'
          AND    xrpm_in_pr_e70.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_in_pr_e70.batch_id                 = gmd_in_pr_e70a.batch_id
  AND    gmd_in_pr_e70a.batch_id                = itp_in_pr_e70.doc_id
  AND    gmd_in_pr_e70a.line_no                 = itp_in_pr_e70.doc_line
  AND    gmd_in_pr_e70a.line_type               = itp_in_pr_e70.line_type
  AND    gmd_in_pr_e70a.item_id                 = itp_in_pr_e70.item_id
  AND    itp_in_pr_e70.item_id                  = ilm_in_pr_e70.item_id
  AND    itp_in_pr_e70.lot_id                   = ilm_in_pr_e70.lot_id
  AND    itp_in_pr_e70.location                 = mil_in_pr_e70.segment1
  AND    mil_in_pr_e70.organization_id          = iwm_in_pr_e70.mtl_organization_id
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    grb_in_pr_e70.attribute9               = mil_in_pr_e70.segment1
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    grct_in_pr_e70.language                = 'JA'
  AND    grct_in_pr_e70.routing_class           = grcb_in_pr_e70.routing_class
  AND    grcb_in_pr_e70.routing_class           = grb_in_pr_e70.routing_class
  AND    grt_in_pr_e70.language                 = 'JA'
  AND    grb_in_pr_e70.routing_id               = grt_in_pr_e70.routing_id
  AND    itp_in_pr_e70.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
  AND    gmd_in_pr_e70a.line_type               = 1                  -- �����i
  AND    itp_in_pr_e70.doc_type                 = xrpm.doc_type
  AND    itp_in_pr_e70.completed_ind            = 1
  AND    grb_in_pr_e70.routing_id               = gbh_in_pr_e70.routing_id
  AND    xrpm.routing_class                     = grb_in_pr_e70.routing_class
  AND    xrpm.line_type                         = gmd_in_pr_e70a.line_type
  AND    grct_in_pr_e70.routing_class_desc      = FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
  AND    gic_in_pr_e70_s.item_id                = itp_in_pr_e70.item_id
  AND    gic_in_pr_e70_s.category_id            = mcb_in_pr_e70_s.category_id
  AND    gic_in_pr_e70_s.category_set_id        = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_in_pr_e70_s.segment1               = xrpm.item_div_ahead
  AND    gic_in_pr_e70_r.item_id                = gmd_in_pr_e70b.item_id
  AND    gic_in_pr_e70_r.category_id            = mcb_in_pr_e70_r.category_id
  AND    gic_in_pr_e70_r.category_set_id        = gic_in_pr_e70_s.category_set_id
  AND    mcb_in_pr_e70_r.segment1               = xrpm.item_div_origin
  AND    gbh_in_pr_e70.batch_id                 = gmd_in_pr_e70b.batch_id
  AND    gmd_in_pr_e70a.batch_id                = gmd_in_pr_e70b.batch_id
  AND    gmd_in_pr_e70b.line_type               = -1                  -- �����i
  UNION ALL
  -- ���Y���Ɏ��� ���
  SELECT iwm_in_pr_e70.attribute1                      AS ownership_code
        ,mil_in_pr_e70.inventory_location_id           AS inventory_location_id
        ,gmd_in_pr_e70.item_id                         AS item_id
        ,ilm_in_pr_e70.lot_no                          AS lot_no
        ,ilm_in_pr_e70.attribute1                      AS manufacture_date
        ,ilm_in_pr_e70.attribute2                      AS uniqe_sign
        ,ilm_in_pr_e70.attribute3                      AS expiration_date -- <---- �����܂ŋ���
        ,itp_in_pr_e70.trans_date                      AS arrival_date
        ,itp_in_pr_e70.trans_date                      AS leaving_date
        ,'2'                                           AS status         -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_in_pr_e70.batch_no                        AS voucher_no
        ,grt_in_pr_e70.routing_desc                    AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itp_in_pr_e70.trans_qty                       AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   gme_batch_header             gbh_in_pr_e70                  -- ���Y�o�b�`
        ,gme_material_details         gmd_in_pr_e70                  -- ���Y�����ڍ�
        ,ic_tran_pnd                  itp_in_pr_e70                  -- OPM�ۗ��݌Ƀg�����U�N�V����
        ,ic_whse_mst                  iwm_in_pr_e70                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_pr_e70                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_pr_e70                  -- OPM���b�g�}�X�^
        ,gmd_routings_b               grb_in_pr_e70                  -- �H���}�X�^
        ,gmd_routings_tl              grt_in_pr_e70                  -- �H���}�X�^���{��
        ,gmd_routing_class_b          grcb_in_pr_e70                 -- �H���敪�}�X�^
        ,gmd_routing_class_tl         grct_in_pr_e70                 -- �H���敪�}�X�^���{��
        ,(SELECT xrpm_in_pr_e70.new_div_invent
                ,flv_in_pr_e70.meaning
                ,xrpm_in_pr_e70.doc_type
                ,xrpm_in_pr_e70.routing_class
                ,xrpm_in_pr_e70.line_type
          FROM   fnd_lookup_values flv_in_pr_e70                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_in_pr_e70                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_pr_e70.language                 = 'JA'
          AND    flv_in_pr_e70.lookup_code              = xrpm_in_pr_e70.new_div_invent
          AND    xrpm_in_pr_e70.doc_type                = 'PROD'
          AND    xrpm_in_pr_e70.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_in_pr_e70.batch_id                 = gmd_in_pr_e70.batch_id
  AND    gmd_in_pr_e70.batch_id                 = itp_in_pr_e70.doc_id
  AND    gmd_in_pr_e70.line_no                  = itp_in_pr_e70.doc_line
  AND    gmd_in_pr_e70.line_type                = itp_in_pr_e70.line_type
  AND    grct_in_pr_e70.routing_class_desc     IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET')       -- �ԕi����
                                                  ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')) -- ��̔����i
  AND    grct_in_pr_e70.language                = 'JA'
  AND    grct_in_pr_e70.routing_class           = grcb_in_pr_e70.routing_class
  AND    grcb_in_pr_e70.routing_class           = grb_in_pr_e70.routing_class
  AND    grt_in_pr_e70.language                 = 'JA'
  AND    grb_in_pr_e70.routing_id               = grt_in_pr_e70.routing_id
  AND    itp_in_pr_e70.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
  AND    gmd_in_pr_e70.line_type                = 1                  -- �����i
  AND    itp_in_pr_e70.doc_type                 = xrpm.doc_type
  AND    itp_in_pr_e70.completed_ind            = 1
  AND    itp_in_pr_e70.item_id                  = ilm_in_pr_e70.item_id
  AND    itp_in_pr_e70.lot_id                   = ilm_in_pr_e70.lot_id
  AND    itp_in_pr_e70.location                 = mil_in_pr_e70.segment1
  AND    mil_in_pr_e70.organization_id          = iwm_in_pr_e70.mtl_organization_id
  AND    grb_in_pr_e70.attribute9               = mil_in_pr_e70.segment1
  AND    grb_in_pr_e70.routing_id               = gbh_in_pr_e70.routing_id
  AND    xrpm.routing_class                     = grb_in_pr_e70.routing_class
  AND    xrpm.line_type                         = gmd_in_pr_e70.line_type
  UNION ALL
  -- �q�֕ԕi ���Ɏ���
  SELECT iwm_in_po_e_rma.attribute1                    AS ownership_code
        ,mil_in_po_e_rma.inventory_location_id         AS inventory_location_id
        ,xmld_in_po_e_rma.item_id                      AS item_id
        ,ilm_in_po_e_rma.lot_no                        AS lot_no
        ,ilm_in_po_e_rma.attribute1                    AS manufacture_date
        ,ilm_in_po_e_rma.attribute2                    AS uniqe_sign
        ,ilm_in_po_e_rma.attribute3                    AS expiration_date -- <---- �����܂ŋ���
        ,xoha_in_po_e_rma.arrival_date                 AS arrival_date
        ,xoha_in_po_e_rma.shipped_date                 AS leaving_date
        ,'2'                                           AS status              -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_in_po_e_rma.request_no                   AS voucher_no
        ,hpat_in_po_e_rma.attribute19                  AS ukebaraisaki_name
        ,xpas_in_po_e_rma.party_site_name              AS deliver_to_name
        ,xmld_in_po_e_rma.actual_quantity              AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxwsh_order_headers_all      xoha_in_po_e_rma                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_in_po_e_rma                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_in_po_e_rma                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_in_po_e_rma                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_po_e_rma                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_po_e_rma                  -- OPM���b�g�}�X�^
        ,oe_transaction_types_all     otta_in_po_e_rma                 -- �󒍃^�C�v
        ,hz_parties                   hpat_in_po_e_rma
        ,hz_cust_accounts             hcsa_in_po_e_rma
        ,hz_party_sites               hpas_in_po_e_rma
        ,xxcmn_party_sites            xpas_in_po_e_rma
        ,(SELECT xrpm_in_po_e_rma.new_div_invent
                ,flv_in_po_e_rma.meaning
                ,xrpm_in_po_e_rma.shipment_provision_div
                ,xrpm_in_po_e_rma.ship_prov_rcv_pay_category
          FROM   fnd_lookup_values flv_in_po_e_rma                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_in_po_e_rma                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_po_e_rma.lookup_type                  = 'XXCMN_NEW_DIVISION'
          AND    flv_in_po_e_rma.language                     = 'JA'
          AND    flv_in_po_e_rma.lookup_code                  = xrpm_in_po_e_rma.new_div_invent
          AND    xrpm_in_po_e_rma.doc_type                    = 'PORC'
          AND    xrpm_in_po_e_rma.source_document_code        = 'RMA'
          AND    xrpm_in_po_e_rma.use_div_invent              = 'Y'
          AND    xrpm_in_po_e_rma.rcv_pay_div                 = '1'            -- ���
         ) xrpm
  WHERE  xoha_in_po_e_rma.order_header_id             = xola_in_po_e_rma.order_header_id
  AND    xola_in_po_e_rma.order_line_id               = xmld_in_po_e_rma.mov_line_id
  AND    xoha_in_po_e_rma.deliver_from_id             = mil_in_po_e_rma.inventory_location_id
  AND    mil_in_po_e_rma.organization_id              = iwm_in_po_e_rma.mtl_organization_id
  AND    xmld_in_po_e_rma.item_id                     = ilm_in_po_e_rma.item_id
  AND    xmld_in_po_e_rma.lot_id                      = ilm_in_po_e_rma.lot_id
  AND    xmld_in_po_e_rma.document_type_code          = '10'           -- �o�׈˗�
  AND    xmld_in_po_e_rma.record_type_code            = '20'           -- �o�Ɏ���
  AND    xoha_in_po_e_rma.order_type_id               = otta_in_po_e_rma.transaction_type_id
  AND    otta_in_po_e_rma.attribute1                  = '3'            -- �q�֕ԕi
  AND    otta_in_po_e_rma.attribute1                  = xrpm.shipment_provision_div
  AND    xoha_in_po_e_rma.req_status                  = '04'           -- �o�׎��ьv���
  AND    xrpm.ship_prov_rcv_pay_category              = otta_in_po_e_rma.attribute11
                                                                        -- �󕥋敪�A�h�I���𕡐��ǂ܂Ȃ���
  AND    otta_in_po_e_rma.attribute11                 in  ('03','04')
  AND    otta_in_po_e_rma.order_category_code         = 'RETURN'
  AND    xoha_in_po_e_rma.latest_external_flag        = 'Y'            -- ON
  AND    xola_in_po_e_rma.delete_flag                 = 'N'            -- OFF
  AND    xoha_in_po_e_rma.customer_id                 = hpat_in_po_e_rma.party_id
  AND    hpat_in_po_e_rma.party_id                    = hcsa_in_po_e_rma.party_id
  AND    hpat_in_po_e_rma.status                      = 'A'
  AND    hcsa_in_po_e_rma.status                      = 'A'
  AND    xoha_in_po_e_rma.result_deliver_to_id        = hpas_in_po_e_rma.party_site_id
  AND    hpas_in_po_e_rma.party_site_id               = xpas_in_po_e_rma.party_site_id
  AND    hpas_in_po_e_rma.party_id                    = xpas_in_po_e_rma.party_id
  AND    hpas_in_po_e_rma.location_id                 = xpas_in_po_e_rma.location_id
  AND    hpas_in_po_e_rma.status                      = 'A'
  AND    xpas_in_po_e_rma.start_date_active          <= TRUNC(SYSDATE)
  AND    xpas_in_po_e_rma.end_date_active            >= TRUNC(SYSDATE)
  UNION ALL
  -- �݌ɒ��� ���Ɏ���(�����݌�)
  SELECT iwm_in_ad_e_x97.attribute1                    AS ownership_code
        ,mil_in_ad_e_x97.inventory_location_id         AS inventory_location_id
        ,itc_in_ad_e_x97.item_id                       AS item_id
        ,ilm_in_ad_e_x97.lot_no                        AS lot_no
        ,ilm_in_ad_e_x97.attribute1                    AS manufacture_date
        ,ilm_in_ad_e_x97.attribute2                    AS uniqe_sign
        ,ilm_in_ad_e_x97.attribute3                    AS expiration_date -- <---- �����܂ŋ���
        ,itc_in_ad_e_x97.trans_date                    AS arrival_date
        ,itc_in_ad_e_x97.trans_date                    AS leaving_date
        ,'2'                                           AS status        -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,ijm_in_ad_e_x97.journal_no                    AS voucher_no
        ,xrpm.meaning                                  AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itc_in_ad_e_x97.trans_qty                     AS leaving_quantity
        ,0                                             AS stock_quantity
  FROM   ic_tran_cmp                  itc_in_ad_e_x97                        -- OPM�����݌Ƀg�����U�N�V����
        ,ic_jrnl_mst                  ijm_in_ad_e_x97                        -- OPM�W���[�i���}�X�^
        ,ic_adjs_jnl                  iaj_in_ad_e_x97                        -- OPM�݌ɒ����W���[�i��
        ,ic_whse_mst                  iwm_in_ad_e_x97                        -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_ad_e_x97                        -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_ad_e_x97                        -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_ad_e_x97.new_div_invent
                ,flv_in_ad_e_x97.meaning
                ,xrpm_in_ad_e_x97.doc_type
                ,xrpm_in_ad_e_x97.reason_code
                ,xrpm_in_ad_e_x97.rcv_pay_div
          FROM   fnd_lookup_values flv_in_ad_e_x97                           -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_in_ad_e_x97                          -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_ad_e_x97.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_in_ad_e_x97.language                = 'JA'
          AND    flv_in_ad_e_x97.lookup_code             = xrpm_in_ad_e_x97.new_div_invent
          AND    xrpm_in_ad_e_x97.doc_type               = 'ADJI'
          AND    xrpm_in_ad_e_x97.use_div_invent         = 'Y'
          AND    xrpm_in_ad_e_x97.reason_code            = 'X977'            -- �����݌�
          AND    xrpm_in_ad_e_x97.rcv_pay_div            = '1'               -- ���
         ) xrpm
  WHERE  itc_in_ad_e_x97.doc_type                = xrpm.doc_type
  AND    itc_in_ad_e_x97.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_in_ad_e_x97.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_in_ad_e_x97.item_id                 = ilm_in_ad_e_x97.item_id
  AND    itc_in_ad_e_x97.lot_id                  = ilm_in_ad_e_x97.lot_id
  AND    itc_in_ad_e_x97.whse_code               = iwm_in_ad_e_x97.whse_code
  AND    itc_in_ad_e_x97.location                = mil_in_ad_e_x97.segment1
  AND    mil_in_ad_e_x97.organization_id         = iwm_in_ad_e_x97.mtl_organization_id
  AND    ijm_in_ad_e_x97.journal_id              = iaj_in_ad_e_x97.journal_id   --OPM�W���[�i���}�X�^���o����
  AND    iaj_in_ad_e_x97.doc_id                  = itc_in_ad_e_x97.doc_id       --OPM�݌ɒ����W���[�i�����o����
  AND    iaj_in_ad_e_x97.doc_line                = itc_in_ad_e_x97.doc_line     --OPM�݌ɒ����W���[�i�����o����
  AND    ijm_in_ad_e_x97.attribute1             IS NULL                         --OPM�W���[�i���}�X�^.����ID��NULL
  UNION ALL
  -- �݌ɒ��� ���Ɏ���(�O���o����)
  SELECT iwm_in_ad_e_x97.attribute1                    AS ownership_code
        ,mil_in_ad_e_x97.inventory_location_id         AS inventory_location_id
        ,itc_in_ad_e_x97.item_id                       AS item_id
        ,ilm_in_ad_e_x97.lot_no                        AS lot_no
        ,ilm_in_ad_e_x97.attribute1                    AS manufacture_date
        ,ilm_in_ad_e_x97.attribute2                    AS uniqe_sign
        ,ilm_in_ad_e_x97.attribute3                    AS expiration_date -- <---- �����܂ŋ���
        ,itc_in_ad_e_x97.trans_date                    AS arrival_date
        ,itc_in_ad_e_x97.trans_date                    AS leaving_date
        ,'2'                                           AS status        -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,NULL                                          AS voucher_no        -- �`�[No
        ,xv_in_ad_e_x97.vendor_name                    AS ukebaraisaki_name -- �󕥐於
        ,NULL                                          AS deliver_to_name
        ,itc_in_ad_e_x97.trans_qty                     AS leaving_quantity
        ,0                                             AS stock_quantity
  FROM   ic_tran_cmp                  itc_in_ad_e_x97                        -- OPM�����݌Ƀg�����U�N�V����
        ,ic_jrnl_mst                  ijm_in_ad_e_x97                        -- OPM�W���[�i���}�X�^
        ,ic_adjs_jnl                  iaj_in_ad_e_x97                        -- OPM�݌ɒ����W���[�i��
        ,ic_whse_mst                  iwm_in_ad_e_x97                        -- OPM�q�Ƀ}�X�^
        ,xxpo_vendor_supply_txns      xvst_in_ad_e_x97                       -- �O���o��������
        ,mtl_item_locations           mil_in_ad_e_x97                        -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_ad_e_x97                        -- OPM���b�g�}�X�^
        ,po_vendors                   pv_in_ad_e_x97                         -- �d����}�X�^
        ,xxcmn_vendors                xv_in_ad_e_x97                         -- �d����A�h�I���}�X�^
        ,(SELECT xrpm_in_ad_e_x97.new_div_invent
                ,flv_in_ad_e_x97.meaning
                ,xrpm_in_ad_e_x97.doc_type
                ,xrpm_in_ad_e_x97.reason_code
                ,xrpm_in_ad_e_x97.rcv_pay_div
          FROM   fnd_lookup_values    flv_in_ad_e_x97                           -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst    xrpm_in_ad_e_x97                          -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_ad_e_x97.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_in_ad_e_x97.language                = 'JA'
          AND    flv_in_ad_e_x97.lookup_code             = xrpm_in_ad_e_x97.new_div_invent
          AND    xrpm_in_ad_e_x97.doc_type               = 'ADJI'
          AND    xrpm_in_ad_e_x97.use_div_invent         = 'Y'
          AND    xrpm_in_ad_e_x97.reason_code            = 'X977'               -- �����݌�
          AND    xrpm_in_ad_e_x97.rcv_pay_div            = '1'                  -- ���
         ) xrpm
  WHERE  itc_in_ad_e_x97.doc_type                = xrpm.doc_type
  AND    itc_in_ad_e_x97.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_in_ad_e_x97.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_in_ad_e_x97.item_id                 = ilm_in_ad_e_x97.item_id
  AND    itc_in_ad_e_x97.lot_id                  = ilm_in_ad_e_x97.lot_id
  AND    itc_in_ad_e_x97.whse_code               = iwm_in_ad_e_x97.whse_code
  AND    itc_in_ad_e_x97.location                = mil_in_ad_e_x97.segment1
  AND    mil_in_ad_e_x97.organization_id         = iwm_in_ad_e_x97.mtl_organization_id
  AND    ijm_in_ad_e_x97.journal_id              = iaj_in_ad_e_x97.journal_id         -- OPM�W���[�i���}�X�^���o����
  AND    iaj_in_ad_e_x97.doc_id                  = itc_in_ad_e_x97.doc_id             -- OPM�݌ɒ����W���[�i�����o����
  AND    iaj_in_ad_e_x97.doc_line                = itc_in_ad_e_x97.doc_line           -- OPM�݌ɒ����W���[�i�����o����
  AND    ijm_in_ad_e_x97.attribute1             IS NOT NULL                           -- OPM�W���[�i���}�X�^.����ID��NULL�łȂ�
  AND    ijm_in_ad_e_x97.attribute1              = TO_CHAR(xvst_in_ad_e_x97.txns_id)  -- ����ID
  AND    xvst_in_ad_e_x97.vendor_id              = xv_in_ad_e_x97.vendor_id          -- �d����ID
  AND    pv_in_ad_e_x97.vendor_id                = xv_in_ad_e_x97.vendor_id
  AND    pv_in_ad_e_x97.end_date_active         IS NULL
  AND    xv_in_ad_e_x97.start_date_active       <= TRUNC( SYSDATE )
  AND    xv_in_ad_e_x97.end_date_active         >= TRUNC( SYSDATE )
  UNION ALL
  -- �݌ɒ��� ���Ɏ���(�l������)
  SELECT iwm_in_ad_e_x9.attribute1                     AS ownership_code
        ,mil_in_ad_e_x9.inventory_location_id          AS inventory_location_id
        ,itc_in_ad_e_x9.item_id                        AS item_id
        ,ilm_in_ad_e_x9.lot_no                         AS lot_no
        ,ilm_in_ad_e_x9.attribute1                     AS manufacture_date
        ,ilm_in_ad_e_x9.attribute2                     AS uniqe_sign
        ,ilm_in_ad_e_x9.attribute3                     AS expiration_date -- <---- �����܂ŋ���
        ,itc_in_ad_e_x9.trans_date                     AS arrival_date
        ,itc_in_ad_e_x9.trans_date                     AS leaving_date
        ,'2'                                           AS status      -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xnpt_in_ad_e_x9.entry_number                  AS voucher_no
        ,xrpm.meaning                                  AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itc_in_ad_e_x9.trans_qty                      AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   ic_adjs_jnl                  iaj_in_ad_e_x9                        -- OPM�݌ɒ����W���[�i��
        ,ic_jrnl_mst                  ijm_in_ad_e_x9                        -- OPM�W���[�i���}�X�^
        ,ic_tran_cmp                  itc_in_ad_e_x9                        -- OPM�����݌Ƀg�����U�N�V����
        ,xxpo_namaha_prod_txns        xnpt_in_ad_e_x9                       -- ���t���сi�A�h�I���j
        ,ic_whse_mst                  iwm_in_ad_e_x9                        -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_ad_e_x9                        -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_ad_e_x9                        -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_ad_e_x9.new_div_invent
                ,flv_in_ad_e_x9.meaning
                ,xrpm_in_ad_e_x9.doc_type
                ,xrpm_in_ad_e_x9.reason_code
                ,xrpm_in_ad_e_x9.rcv_pay_div
          FROM   fnd_lookup_values flv_in_ad_e_x9                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_in_ad_e_x9                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_ad_e_x9.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_in_ad_e_x9.language                = 'JA'
          AND    flv_in_ad_e_x9.lookup_code             = xrpm_in_ad_e_x9.new_div_invent
          AND    xrpm_in_ad_e_x9.doc_type               = 'ADJI'
          AND    xrpm_in_ad_e_x9.use_div_invent         = 'Y'
          AND    xrpm_in_ad_e_x9.reason_code            = 'X988'               -- �l������
          AND    xrpm_in_ad_e_x9.rcv_pay_div            = '1'                  -- ���
         ) xrpm
  WHERE  itc_in_ad_e_x9.doc_type                = xrpm.doc_type
  AND    itc_in_ad_e_x9.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_in_ad_e_x9.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_in_ad_e_x9.item_id                 = ilm_in_ad_e_x9.item_id
  AND    itc_in_ad_e_x9.lot_id                  = ilm_in_ad_e_x9.lot_id
  AND    itc_in_ad_e_x9.whse_code               = iwm_in_ad_e_x9.whse_code
  AND    itc_in_ad_e_x9.location                = mil_in_ad_e_x9.segment1
  AND    mil_in_ad_e_x9.organization_id         = iwm_in_ad_e_x9.mtl_organization_id
  AND    iaj_in_ad_e_x9.journal_id              = ijm_in_ad_e_x9.journal_id
  AND    itc_in_ad_e_x9.doc_type                = iaj_in_ad_e_x9.trans_type
  AND    itc_in_ad_e_x9.doc_id                  = iaj_in_ad_e_x9.doc_id
  AND    itc_in_ad_e_x9.doc_line                = iaj_in_ad_e_x9.doc_line
  AND    ijm_in_ad_e_x9.attribute1              = xnpt_in_ad_e_x9.entry_number
  UNION ALL
  -- �݌ɒ��� ���Ɏ���(�ړ����ђ���)
  SELECT iwm_in_ad_e_xx.attribute1                     AS ownership_code
        ,mil_in_ad_e_xx.inventory_location_id          AS inventory_location_id
        ,itc_in_ad_e_xx.item_id                        AS item_id
        ,ilm_in_ad_e_xx.lot_no                         AS lot_no
        ,ilm_in_ad_e_xx.attribute1                     AS manufacture_date
        ,ilm_in_ad_e_xx.attribute2                     AS uniqe_sign
        ,ilm_in_ad_e_xx.attribute3                     AS expiration_date -- <---- �����܂ŋ���
        ,itc_in_ad_e_xx.trans_date                     AS arrival_date
        ,itc_in_ad_e_xx.trans_date                     AS leaving_date
        ,'2'                                           AS status   -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_ad_e_xx.mov_num                      AS voucher_no
        ,mil2_in_ad_e_xx.description                   AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update start
--        ,ABS(itc_in_ad_e_xx.trans_qty)                 AS leaving_quantity
        ,itc_in_ad_e_xx.trans_qty                      AS leaving_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update end
  FROM   xxinv_mov_req_instr_headers  xmrih_in_ad_e_xx               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_in_ad_e_xx               -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmldt_in_ad_e_xx               -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_adjs_jnl                  iaj_in_ad_e_xx                 -- OPM�݌ɒ����W���[�i��
        ,ic_jrnl_mst                  ijm_in_ad_e_xx                 -- OPM�W���[�i���}�X�^
        ,ic_tran_cmp                  itc_in_ad_e_xx                 -- OPM�����݌Ƀg�����U�N�V����
        ,ic_whse_mst                  iwm_in_ad_e_xx                 -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_ad_e_xx                 -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_in_ad_e_xx                -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_ad_e_xx                 -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_ad_e_xx.new_div_invent
                ,flv_in_ad_e_xx.meaning
                ,xrpm_in_ad_e_xx.doc_type
                ,xrpm_in_ad_e_xx.reason_code
                ,xrpm_in_ad_e_xx.rcv_pay_div
          FROM   fnd_lookup_values flv_in_ad_e_xx                    -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_in_ad_e_xx                   -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_ad_e_xx.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_in_ad_e_xx.language                = 'JA'
          AND    flv_in_ad_e_xx.lookup_code             = xrpm_in_ad_e_xx.new_div_invent
          AND    xrpm_in_ad_e_xx.doc_type               = 'ADJI'
          AND    xrpm_in_ad_e_xx.use_div_invent         = 'Y'
          AND    xrpm_in_ad_e_xx.reason_code            = 'X123'               -- �ړ����ђ���
          AND    xrpm_in_ad_e_xx.rcv_pay_div            = '-1'                 -- ���o
         ) xrpm
  WHERE  xmrih_in_ad_e_xx.mov_hdr_id            = xmril_in_ad_e_xx.mov_hdr_id
  AND    xmril_in_ad_e_xx.mov_line_id           = xmldt_in_ad_e_xx.mov_line_id
  AND    itc_in_ad_e_xx.doc_type                = xrpm.doc_type
  AND    itc_in_ad_e_xx.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_in_ad_e_xx.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_in_ad_e_xx.item_id                 = xmril_in_ad_e_xx.item_id
  AND    itc_in_ad_e_xx.lot_id                  = xmldt_in_ad_e_xx.lot_id
  AND    itc_in_ad_e_xx.location                = xmrih_in_ad_e_xx.ship_to_locat_code
  AND    itc_in_ad_e_xx.doc_type                = iaj_in_ad_e_xx.trans_type
  AND    itc_in_ad_e_xx.doc_id                  = iaj_in_ad_e_xx.doc_id
  AND    itc_in_ad_e_xx.doc_line                = iaj_in_ad_e_xx.doc_line
  AND    iaj_in_ad_e_xx.journal_id              = ijm_in_ad_e_xx.journal_id
  AND    xmril_in_ad_e_xx.mov_line_id           = TO_NUMBER( ijm_in_ad_e_xx.attribute1 )
  AND    xmrih_in_ad_e_xx.ship_to_locat_id      = mil_in_ad_e_xx.inventory_location_id
  AND    mil_in_ad_e_xx.organization_id         = iwm_in_ad_e_xx.mtl_organization_id
  AND    xmrih_in_ad_e_xx.shipped_locat_id      = mil2_in_ad_e_xx.inventory_location_id
  AND    xmldt_in_ad_e_xx.item_id               = ilm_in_ad_e_xx.item_id
  AND    xmldt_in_ad_e_xx.lot_id                = ilm_in_ad_e_xx.lot_id
  AND    xmldt_in_ad_e_xx.record_type_code      = '30'
  AND    xmldt_in_ad_e_xx.document_type_code    = '20'
  UNION ALL
  -- �݌ɒ��� ���Ɏ���(��L�ȊO)
  SELECT iwm_in_ad_e_xx.attribute1                     AS ownership_code
        ,mil_in_ad_e_xx.inventory_location_id          AS inventory_location_id
        ,itc_in_ad_e_xx.item_id                        AS item_id
        ,ilm_in_ad_e_xx.lot_no                         AS lot_no
        ,ilm_in_ad_e_xx.attribute1                     AS manufacture_date
        ,ilm_in_ad_e_xx.attribute2                     AS uniqe_sign
        ,ilm_in_ad_e_xx.attribute3                     AS expiration_date -- <---- �����܂ŋ���
        ,itc_in_ad_e_xx.trans_date                     AS arrival_date
        ,itc_in_ad_e_xx.trans_date                     AS leaving_date
        ,'2'                                           AS status   -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,ijm_in_ad_e_xx.journal_no                     AS voucher_no
        ,xrpm.meaning                                  AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itc_in_ad_e_xx.trans_qty                      AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   ic_adjs_jnl                  iaj_in_ad_e_xx                 -- OPM�݌ɒ����W���[�i��
        ,ic_jrnl_mst                  ijm_in_ad_e_xx                 -- OPM�W���[�i���}�X�^
        ,ic_tran_cmp                  itc_in_ad_e_xx                 -- OPM�����݌Ƀg�����U�N�V����
        ,ic_whse_mst                  iwm_in_ad_e_xx                 -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_in_ad_e_xx                 -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_in_ad_e_xx                 -- OPM���b�g�}�X�^
        ,(SELECT xrpm_in_ad_e_xx.new_div_invent
                ,flv_in_ad_e_xx.meaning
                ,xrpm_in_ad_e_xx.doc_type
                ,xrpm_in_ad_e_xx.reason_code
                ,xrpm_in_ad_e_xx.rcv_pay_div
          FROM   fnd_lookup_values flv_in_ad_e_xx                    -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_in_ad_e_xx                   -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_in_ad_e_xx.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_in_ad_e_xx.language                = 'JA'
          AND    flv_in_ad_e_xx.lookup_code             = xrpm_in_ad_e_xx.new_div_invent
          AND    xrpm_in_ad_e_xx.doc_type               = 'ADJI'
          AND    xrpm_in_ad_e_xx.use_div_invent         = 'Y'
          AND    xrpm_in_ad_e_xx.reason_code       NOT IN ('X977','X988','X123')
          AND    xrpm_in_ad_e_xx.rcv_pay_div            = '1'                  -- ���
         ) xrpm
  WHERE  itc_in_ad_e_xx.doc_type                = xrpm.doc_type
  AND    itc_in_ad_e_xx.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_in_ad_e_xx.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_in_ad_e_xx.item_id                 = ilm_in_ad_e_xx.item_id
  AND    itc_in_ad_e_xx.lot_id                  = ilm_in_ad_e_xx.lot_id
  AND    itc_in_ad_e_xx.whse_code               = iwm_in_ad_e_xx.whse_code
  AND    itc_in_ad_e_xx.location                = mil_in_ad_e_xx.segment1
  AND    mil_in_ad_e_xx.organization_id         = iwm_in_ad_e_xx.mtl_organization_id
  AND    iaj_in_ad_e_xx.journal_id              = ijm_in_ad_e_xx.journal_id
  AND    itc_in_ad_e_xx.doc_type                = iaj_in_ad_e_xx.trans_type
  AND    itc_in_ad_e_xx.doc_id                  = iaj_in_ad_e_xx.doc_id
  AND    itc_in_ad_e_xx.doc_line                = iaj_in_ad_e_xx.doc_line
  UNION ALL
  ------------------------------------------------------------------------
  -- �o�Ɏ���
  ------------------------------------------------------------------------
  -- �ړ��o�Ɏ���(�ϑ�����)
  SELECT /*+ index(XMLD XXINV_MLD_N04) */
         iwm_out_xf_e.attribute1                       AS ownership_code
        ,mil_out_xf_e.inventory_location_id            AS inventory_location_id
        ,xmld_out_xf_e.item_id                         AS item_id
        ,ilm_out_xf_e.lot_no                           AS lot_no
        ,ilm_out_xf_e.attribute1                       AS manufacture_date
        ,ilm_out_xf_e.attribute2                       AS uniqe_sign
        ,ilm_out_xf_e.attribute3                       AS expiration_date -- <---- �����܂ŋ���
        ,xmrih_out_xf_e.actual_arrival_date            AS arrival_date
        ,xmrih_out_xf_e.actual_ship_date               AS leaving_date
        ,'2'                                           AS status           -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_xf_e.mov_num                        AS voucher_no
        ,mil2_out_xf_e.description                     AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_xf_e.actual_quantity                 AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_xf_e                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_out_xf_e                  -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_xf_e                   -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_out_xf_e                 -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_xf_e                 -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_out_xf_e                -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_xf_e                    -- OPM���b�g�}�X�^
        ,(SELECT xrpm_out_xf_e.new_div_invent
                ,flv_out_xf_e.meaning
          FROM   fnd_lookup_values flv_out_xf_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_xf_e                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_xf_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_xf_e.language                 = 'JA'
          AND    flv_out_xf_e.lookup_code              = xrpm_out_xf_e.new_div_invent
          AND    xrpm_out_xf_e.doc_type                = 'XFER'               -- �ړ��ϑ�����
          AND    xrpm_out_xf_e.use_div_invent          = 'Y'
          AND    xrpm_out_xf_e.rcv_pay_div             = '-1'
         ) xrpm
  WHERE  xmrih_out_xf_e.mov_hdr_id             = xmril_out_xf_e.mov_hdr_id
  AND    xmril_out_xf_e.mov_line_id            = xmld_out_xf_e.mov_line_id
  AND    xmrih_out_xf_e.shipped_locat_id       = mil_out_xf_e.inventory_location_id
  AND    mil_out_xf_e.organization_id          = iwm_out_xf_e.mtl_organization_id
  AND    xmrih_out_xf_e.ship_to_locat_id       = mil2_out_xf_e.inventory_location_id
  AND    xmld_out_xf_e.item_id                 = ilm_out_xf_e.item_id
  AND    xmld_out_xf_e.lot_id                  = ilm_out_xf_e.lot_id
  AND    xmld_out_xf_e.document_type_code      = '20'                 -- �ړ�
  AND    xmld_out_xf_e.record_type_code        = '20'                -- �o�Ɏ���
  AND    xmrih_out_xf_e.mov_type               = '1'                  -- �ϑ�����
  AND    xmril_out_xf_e.delete_flg             = 'N'                  -- OFF
  AND    xmrih_out_xf_e.status                IN ( '06'               -- ���o�ɕ񍐗L
                                                  ,'04' )             -- �o�ɕ񍐗L
  UNION ALL
  -- �ړ��o�Ɏ���(�ϑ��Ȃ�)
  SELECT /*+ index(XMLD XXINV_MLD_N04) */
         iwm_out_tr_e.attribute1                       AS ownership_code
        ,mil_out_tr_e.inventory_location_id            AS inventory_location_id
        ,xmld_out_tr_e.item_id                         AS item_id
        ,ilm_out_tr_e.lot_no                           AS lot_no
        ,ilm_out_tr_e.attribute1                       AS manufacture_date
        ,ilm_out_tr_e.attribute2                       AS uniqe_sign
        ,ilm_out_tr_e.attribute3                       AS expiration_date -- <---- �����܂ŋ���
        ,xmrih_out_tr_e.actual_arrival_date            AS arrival_date
        ,xmrih_out_tr_e.actual_ship_date               AS leaving_date
        ,'2'                                           AS status        -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_tr_e.mov_num                        AS voucher_no
        ,mil2_out_tr_e.description                     AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_tr_e.actual_quantity                 AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_tr_e               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_out_tr_e               -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_tr_e                -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_out_tr_e                 -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_tr_e                 -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_out_tr_e                -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_tr_e                 -- OPM���b�g�}�X�^
        ,(SELECT xrpm_out_tr_e.new_div_invent
                ,flv_out_tr_e.meaning
          FROM   fnd_lookup_values flv_out_tr_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_tr_e                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_tr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_tr_e.language                 = 'JA'
          AND    flv_out_tr_e.lookup_code              = xrpm_out_tr_e.new_div_invent
          AND    xrpm_out_tr_e.doc_type                = 'TRNI'            -- �ړ��ϑ��Ȃ�
          AND    xrpm_out_tr_e.use_div_invent          = 'Y'
          AND    xrpm_out_tr_e.rcv_pay_div             = '-1'
         ) xrpm
  WHERE  xmrih_out_tr_e.mov_hdr_id             = xmril_out_tr_e.mov_hdr_id
  AND    xmril_out_tr_e.mov_line_id            = xmld_out_tr_e.mov_line_id
  AND    xmrih_out_tr_e.shipped_locat_id       = mil_out_tr_e.inventory_location_id
  AND    mil_out_tr_e.organization_id          = iwm_out_tr_e.mtl_organization_id
  AND    xmrih_out_tr_e.ship_to_locat_id       = mil2_out_tr_e.inventory_location_id
  AND    xmld_out_tr_e.item_id                 = ilm_out_tr_e.item_id
  AND    xmld_out_tr_e.lot_id                  = ilm_out_tr_e.lot_id
  AND    xmld_out_tr_e.document_type_code      = '20'              -- �ړ�
  AND    xmld_out_tr_e.record_type_code        = '20'              -- �o�Ɏ���
  AND    xmrih_out_tr_e.mov_type               = '2'               -- �ϑ��Ȃ�
  AND    xmrih_out_tr_e.status                 = '06'              -- ���o�ɕ񍐗L
  AND    xmril_out_tr_e.delete_flg             = 'N'               -- OFF
  UNION ALL
  -- ���Y�o�Ɏ���
  SELECT iwm_out_pr_e.attribute1                       AS ownership_code
        ,mil_out_pr_e.inventory_location_id            AS inventory_location_id
        ,itp_out_pr_e.item_id                          AS item_id
        ,ilm_out_pr_e.lot_no                           AS lot_no
        ,ilm_out_pr_e.attribute1                       AS manufacture_date
        ,ilm_out_pr_e.attribute2                       AS uniqe_sign
        ,ilm_out_pr_e.attribute3                       AS expiration_date -- <---- �����܂ŋ���
        ,itp_out_pr_e.trans_date                       AS arrival_date
        ,itp_out_pr_e.trans_date                       AS leaving_date
        ,'2'                                           AS status         -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_out_pr_e.batch_no                         AS voucher_no
        ,grt_out_pr_e.routing_desc                     AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,ABS(itp_out_pr_e.trans_qty)                   AS leaving_quantity
  FROM   gme_batch_header             gbh_out_pr_e                  -- ���Y�o�b�`
        ,gme_material_details         gmd_out_pr_e                  -- ���Y�����ڍ�
        ,ic_tran_pnd                  itp_out_pr_e                  -- OPM�ۗ��݌Ƀg�����U�N�V����
        ,gmd_routings_b               grb_out_pr_e                  -- �H���}�X�^
        ,gmd_routings_tl              grt_out_pr_e                  -- �H���}�X�^���{��
        ,ic_whse_mst                  iwm_out_pr_e                 -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_pr_e                 -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_pr_e                  -- OPM���b�g�}�X�^
        ,(SELECT xrpm_out_pr_e.new_div_invent
                ,flv_out_pr_e.meaning
                ,xrpm_out_pr_e.doc_type
                ,xrpm_out_pr_e.routing_class
                ,xrpm_out_pr_e.line_type
                ,xrpm_out_pr_e.hit_in_div
          FROM   fnd_lookup_values flv_out_pr_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_pr_e                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_pr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_pr_e.language                 = 'JA'
          AND    flv_out_pr_e.lookup_code              = xrpm_out_pr_e.new_div_invent
          AND    xrpm_out_pr_e.doc_type                = 'PROD'
          AND    xrpm_out_pr_e.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_out_pr_e.batch_id                 = gmd_out_pr_e.batch_id
  AND    itp_out_pr_e.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
  AND    gmd_out_pr_e.line_type                = -1                 -- �����i
  AND    itp_out_pr_e.completed_ind            = 1
  AND    itp_out_pr_e.reverse_id              IS NULL
  AND    itp_out_pr_e.doc_type                 = xrpm.doc_type
  AND    itp_out_pr_e.item_id                  = ilm_out_pr_e.item_id
  AND    itp_out_pr_e.lot_id                   = ilm_out_pr_e.lot_id
  AND    itp_out_pr_e.location                 = mil_out_pr_e.segment1
  AND    mil_out_pr_e.organization_id          = iwm_out_pr_e.mtl_organization_id
  AND    itp_out_pr_e.item_id                  = gmd_out_pr_e.item_id
  AND    itp_out_pr_e.doc_id                   = gmd_out_pr_e.batch_id
  AND    itp_out_pr_e.doc_line                 = gmd_out_pr_e.line_no
  AND    itp_out_pr_e.line_type                = gmd_out_pr_e.line_type
  AND    grb_out_pr_e.attribute9               = mil_out_pr_e.segment1
  AND    grb_out_pr_e.routing_id               = gbh_out_pr_e.routing_id
  AND    xrpm.routing_class                    = grb_out_pr_e.routing_class
  AND    xrpm.line_type                        = gmd_out_pr_e.line_type
  AND ((( gmd_out_pr_e.attribute5             IS NULL )
    AND ( xrpm.hit_in_div                     IS NULL ))
  OR   (( gmd_out_pr_e.attribute5              = 'Y' )
    AND ( xrpm.hit_in_div                      = gmd_out_pr_e.attribute5 )))
  AND    grb_out_pr_e.routing_id               = grt_out_pr_e.routing_id
  AND    grt_out_pr_e.language                 = 'JA'
  AND NOT EXISTS 
    ( SELECT 1
      FROM   gmd_routing_class_b   grcb_out_pr_ex          -- �H���敪�}�X�^
            ,gmd_routing_class_tl  grct_out_pr_ex          -- �H���敪�}�X�^���{��
      WHERE  grcb_out_pr_ex.routing_class      = grb_out_pr_e.routing_class
      AND    grct_out_pr_ex.routing_class      = grcb_out_pr_ex.routing_class
      AND    grct_out_pr_ex.language           = 'JA'
      AND    grct_out_pr_ex.routing_class_desc IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
                                                  ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')
                                                  ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET'))
    )
  UNION ALL
  -- ���Y�o�Ɏ��� �i�ڐU�� �i��U��
  SELECT iwm_out_pr_e70.attribute1                     AS ownership_code
        ,mil_out_pr_e70.inventory_location_id          AS inventory_location_id
        ,gmd_out_pr_e70a.item_id                       AS item_id
        ,ilm_out_pr_e70.lot_no                         AS lot_no
        ,ilm_out_pr_e70.attribute1                     AS manufacture_date
        ,ilm_out_pr_e70.attribute2                     AS uniqe_sign
        ,ilm_out_pr_e70.attribute3                     AS expiration_date -- <---- �����܂ŋ���
        ,itp_out_pr_e70.trans_date                     AS arrival_date
        ,itp_out_pr_e70.trans_date                     AS leaving_date
        ,'2'                                           AS status            -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_out_pr_e70.batch_no                       AS voucher_no
        ,grt_out_pr_e70.routing_desc                   AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,ABS(itp_out_pr_e70.trans_qty)                 AS leaving_quantity
  FROM   gme_batch_header             gbh_out_pr_e70                  -- ���Y�o�b�`
        ,gme_material_details         gmd_out_pr_e70a                 -- ���Y�����ڍ�(�U�֌�)
        ,gme_material_details         gmd_out_pr_e70b                 -- ���Y�����ڍ�(�U�֐�)
        ,ic_tran_pnd                  itp_out_pr_e70                  -- OPM�ۗ��݌Ƀg�����U�N�V����
        ,ic_whse_mst                  iwm_out_pr_e70                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_pr_e70                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_pr_e70                  -- OPM���b�g�}�X�^
        ,gmd_routings_b               grb_out_pr_e70                  -- �H���}�X�^
        ,gmd_routings_tl              grt_out_pr_e70                  -- �H���}�X�^���{��
        ,gmd_routing_class_b          grcb_out_pr_e70                 -- �H���敪�}�X�^
        ,gmd_routing_class_tl         grct_out_pr_e70                 -- �H���敪�}�X�^���{��
-- 2008/10/31 Y.Yamamoto v1.1 update start
--        ,gmi_item_categories          gic_in_pr_e70_r
--        ,mtl_categories_b             mcb_in_pr_e70_r
        ,gmi_item_categories          gic_out_pr_e70_r
        ,mtl_categories_b             mcb_out_pr_e70_r
        ,gmi_item_categories          gic_out_pr_e70_s
        ,mtl_categories_b             mcb_out_pr_e70_s
-- 2008/10/31 Y.Yamamoto v1.1 update end
        ,(SELECT xrpm_out_pr_e70.new_div_invent
                ,flv_out_pr_e70.meaning
                ,xrpm_out_pr_e70.doc_type
                ,xrpm_out_pr_e70.routing_class
                ,xrpm_out_pr_e70.line_type
                ,xrpm_out_pr_e70.item_div_origin
                ,xrpm_out_pr_e70.item_div_ahead
          FROM   fnd_lookup_values flv_out_pr_e70                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_pr_e70                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_pr_e70.language                 = 'JA'
          AND    flv_out_pr_e70.lookup_code              = xrpm_out_pr_e70.new_div_invent
          AND    xrpm_out_pr_e70.doc_type                = 'PROD'
          AND    xrpm_out_pr_e70.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_out_pr_e70.batch_id                 = gmd_out_pr_e70a.batch_id
  AND    grct_out_pr_e70.language                = 'JA'
  AND    grct_out_pr_e70.routing_class           = grcb_out_pr_e70.routing_class
  AND    grcb_out_pr_e70.routing_class           = grb_out_pr_e70.routing_class
  AND    grt_out_pr_e70.language                 = 'JA'
  AND    grb_out_pr_e70.routing_id               = grt_out_pr_e70.routing_id
  AND    itp_out_pr_e70.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
  AND    gmd_out_pr_e70a.line_type               = -1                 -- �����i
  AND    itp_out_pr_e70.doc_type                 = xrpm.doc_type
  AND    itp_out_pr_e70.doc_id                   = gmd_out_pr_e70a.batch_id
  AND    itp_out_pr_e70.doc_line                 = gmd_out_pr_e70a.line_no
  AND    itp_out_pr_e70.line_type                = gmd_out_pr_e70a.line_type
  AND    itp_out_pr_e70.completed_ind            = 1
  AND    itp_out_pr_e70.item_id                  = gmd_out_pr_e70a.item_id
  AND    itp_out_pr_e70.item_id                  = ilm_out_pr_e70.item_id
  AND    itp_out_pr_e70.lot_id                   = ilm_out_pr_e70.lot_id
  AND    itp_out_pr_e70.whse_code                = iwm_out_pr_e70.whse_code
  AND    itp_out_pr_e70.location                 = mil_out_pr_e70.segment1
  AND    iwm_out_pr_e70.mtl_organization_id      = mil_out_pr_e70.organization_id
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    grb_out_pr_e70.attribute9               = mil_out_pr_e70.segment1
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    grb_out_pr_e70.routing_id               = gbh_out_pr_e70.routing_id
  AND    xrpm.routing_class                      = grb_out_pr_e70.routing_class
  AND    xrpm.line_type                          = gmd_out_pr_e70a.line_type
  AND    grct_out_pr_e70.routing_class_desc      = FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
-- 2008/10/31 Y.Yamamoto v1.1 update start
  AND    gic_out_pr_e70_s.item_id                = itp_out_pr_e70.item_id
  AND    gic_out_pr_e70_s.category_id            = mcb_out_pr_e70_s.category_id
  AND    gic_out_pr_e70_s.category_set_id        = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_pr_e70_s.segment1               = xrpm.item_div_ahead
  AND    gic_out_pr_e70_r.item_id                = gmd_out_pr_e70b.item_id
  AND    gic_out_pr_e70_r.category_id            = mcb_out_pr_e70_r.category_id
  AND    gic_out_pr_e70_r.category_set_id        = gic_out_pr_e70_s.category_set_id
  AND    mcb_out_pr_e70_r.segment1               = xrpm.item_div_origin
--  AND    xrpm.item_div_origin                    = '5'
--  AND    xrpm.item_div_ahead                     = mcb_in_pr_e70_r.segment1
  AND    gbh_out_pr_e70.batch_id                 = gmd_out_pr_e70b.batch_id
  AND    gmd_out_pr_e70a.batch_id                = gmd_out_pr_e70b.batch_id
  AND    gmd_out_pr_e70b.line_type               = 1                   -- �����i
--  AND    gmd_out_pr_e70b.item_id                 = gic_in_pr_e70_r.item_id
--  AND    gic_in_pr_e70_r.category_id             = mcb_in_pr_e70_r.category_id
--  AND    gic_in_pr_e70_r.category_set_id         = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
-- 2008/10/31 Y.Yamamoto v1.1 update start
  UNION ALL
  -- ���Y�o�Ɏ��� ���
  SELECT iwm_out_pr_e70.attribute1                     AS ownership_code
        ,mil_out_pr_e70.inventory_location_id          AS inventory_location_id
        ,gmd_out_pr_e70.item_id                        AS item_id
        ,ilm_out_pr_e70.lot_no                         AS lot_no
        ,ilm_out_pr_e70.attribute1                     AS manufacture_date
        ,ilm_out_pr_e70.attribute2                     AS uniqe_sign
        ,ilm_out_pr_e70.attribute3                     AS expiration_date -- <---- �����܂ŋ���
        ,itp_out_pr_e70.trans_date                     AS arrival_date
        ,itp_out_pr_e70.trans_date                     AS leaving_date
        ,'2'                                           AS status            -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_out_pr_e70.batch_no                       AS voucher_no
        ,grt_out_pr_e70.routing_desc                   AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,ABS(itp_out_pr_e70.trans_qty)                 AS leaving_quantity
  FROM   gme_batch_header             gbh_out_pr_e70                  -- ���Y�o�b�`
        ,gme_material_details         gmd_out_pr_e70                  -- ���Y�����ڍ�
        ,ic_tran_pnd                  itp_out_pr_e70                  -- OPM�ۗ��݌Ƀg�����U�N�V����
        ,ic_whse_mst                  iwm_out_pr_e70                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_pr_e70                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_pr_e70                  -- OPM���b�g�}�X�^
        ,gmd_routings_b               grb_out_pr_e70                  -- �H���}�X�^
        ,gmd_routings_tl              grt_out_pr_e70                  -- �H���}�X�^���{��
        ,gmd_routing_class_b          grcb_out_pr_e70                 -- �H���敪�}�X�^
        ,gmd_routing_class_tl         grct_out_pr_e70                 -- �H���敪�}�X�^���{��
        ,(SELECT xrpm_out_pr_e70.new_div_invent
                ,flv_out_pr_e70.meaning
                ,xrpm_out_pr_e70.doc_type
                ,xrpm_out_pr_e70.routing_class
                ,xrpm_out_pr_e70.line_type
          FROM   fnd_lookup_values flv_out_pr_e70                     -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_pr_e70                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_pr_e70.language                 = 'JA'
          AND    flv_out_pr_e70.lookup_code              = xrpm_out_pr_e70.new_div_invent
          AND    xrpm_out_pr_e70.doc_type                = 'PROD'
          AND    xrpm_out_pr_e70.use_div_invent          = 'Y'
         ) xrpm
  WHERE  grct_out_pr_e70.language                = 'JA'
  AND    grct_out_pr_e70.routing_class           = grcb_out_pr_e70.routing_class
  AND    grcb_out_pr_e70.routing_class           = grb_out_pr_e70.routing_class
  AND    grt_out_pr_e70.language                 = 'JA'
  AND    grb_out_pr_e70.routing_id               = grt_out_pr_e70.routing_id
  AND    itp_out_pr_e70.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
  AND    gbh_out_pr_e70.batch_id                 = gmd_out_pr_e70.batch_id
  AND    gmd_out_pr_e70.line_type                = -1                 -- �����i
  AND    itp_out_pr_e70.doc_type                 = xrpm.doc_type
  AND    itp_out_pr_e70.doc_id                   = gmd_out_pr_e70.batch_id
  AND    itp_out_pr_e70.doc_line                 = gmd_out_pr_e70.line_no
  AND    itp_out_pr_e70.line_type                = gmd_out_pr_e70.line_type
  AND    itp_out_pr_e70.completed_ind            = 1
  AND    itp_out_pr_e70.item_id                  = gmd_out_pr_e70.item_id
  AND    itp_out_pr_e70.item_id                  = ilm_out_pr_e70.item_id
  AND    itp_out_pr_e70.lot_id                   = ilm_out_pr_e70.lot_id
  AND    itp_out_pr_e70.whse_code                = iwm_out_pr_e70.whse_code
  AND    itp_out_pr_e70.location                 = mil_out_pr_e70.segment1
  AND    iwm_out_pr_e70.mtl_organization_id      = mil_out_pr_e70.organization_id
  AND    grb_out_pr_e70.attribute9               = mil_out_pr_e70.segment1
  AND    grb_out_pr_e70.routing_id               = gbh_out_pr_e70.routing_id
  AND    xrpm.routing_class                      = grb_out_pr_e70.routing_class
  AND    xrpm.line_type                          = gmd_out_pr_e70.line_type
  AND    grct_out_pr_e70.routing_class_desc      IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')
                                                    ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET'))
  UNION ALL
  -- �󒍏o�׎���
  SELECT /*+ index(XMLD XXINV_MLD_N04) */
         iwm_out_om_e.attribute1                       AS ownership_code
        ,mil_out_om_e.inventory_location_id            AS inventory_location_id
        ,xmld_out_om_e.item_id                         AS item_id
        ,ilm_out_om_e.lot_no                           AS lot_no
        ,ilm_out_om_e.attribute1                       AS manufacture_date
        ,ilm_out_om_e.attribute2                       AS uniqe_sign
        ,ilm_out_om_e.attribute3                       AS expiration_date -- <---- �����܂ŋ���
        ,xoha_out_om_e.arrival_date                    AS arrival_date
        ,xoha_out_om_e.shipped_date                    AS leaving_date
        ,'2'                                           AS status          -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om_e.request_no                      AS voucher_no
        ,hpat_out_om_e.attribute19                     AS ukebaraisaki_name
        ,xpas_out_om_e.party_site_name                 AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_om_e.actual_quantity                 AS leaving_quantity
  FROM   xxwsh_order_headers_all      xoha_out_om_e                    -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om_e                    -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om_e                    -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_out_om_e                     -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om_e                     -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_om_e                    -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_om_e                    -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om_e                     -- OPM���b�g�}�X�^
        ,oe_transaction_types_all     otta_out_om_e                    -- �󒍃^�C�v
        ,hz_parties                   hpat_out_om_e
        ,hz_cust_accounts             hcsa_out_om_e
        ,hz_party_sites               hpas_out_om_e
        ,xxcmn_party_sites            xpas_out_om_e
        ,gmi_item_categories          gic_out_om_e
        ,mtl_categories_b             mcb_out_om_e
        ,(SELECT xrpm_out_om_e.new_div_invent
                ,flv_out_om_e.meaning
                ,xrpm_out_om_e.shipment_provision_div
                ,xrpm_out_om_e.ship_prov_rcv_pay_category
                ,xrpm_out_om_e.stock_adjustment_div
                ,xrpm_out_om_e.item_div_ahead
          FROM   fnd_lookup_values flv_out_om_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om_e                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om_e.lookup_type                       = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om_e.language                          = 'JA'
          AND    flv_out_om_e.lookup_code                       = xrpm_out_om_e.new_div_invent
          AND    xrpm_out_om_e.doc_type                         = 'OMSO'
          AND    xrpm_out_om_e.use_div_invent                   = 'Y'
          AND    xrpm_out_om_e.stock_adjustment_div             = '1'
          AND    xrpm_out_om_e.item_div_origin                  = '5'
          AND    xrpm_out_om_e.item_div_ahead                   = '5'
         ) xrpm
  WHERE  otta_out_om_e.order_category_code              = 'ORDER'
  AND    xoha_out_om_e.order_header_id                  = xola_out_om_e.order_header_id
  AND    xoha_out_om_e.deliver_from_id                  = mil_out_om_e.inventory_location_id
  AND    iwm_out_om_e.mtl_organization_id               = mil_out_om_e.organization_id
  AND    xola_out_om_e.request_item_id                  = msib_out_om_e.inventory_item_id
  AND    iimb_out_om_e.item_no                          = msib_out_om_e.segment1
  AND    msib_out_om_e.organization_id                  = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om_e.mov_line_id                      = xola_out_om_e.order_line_id
  AND    xmld_out_om_e.document_type_code               = '10'      -- �o�׈˗�
  AND    xmld_out_om_e.record_type_code                 = '20'      -- �o�Ɏ���
  AND    xmld_out_om_e.item_id                          = ilm_out_om_e.item_id
  AND    xmld_out_om_e.lot_id                           = ilm_out_om_e.lot_id
  AND    xoha_out_om_e.req_status                       = '04'      -- �o�׎��ьv���
  AND    xoha_out_om_e.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om_e.delete_flag                      = 'N'       -- OFF
  AND    otta_out_om_e.attribute1                       = '1'       -- �o�׈˗�
  AND    xoha_out_om_e.order_type_id                    = otta_out_om_e.transaction_type_id
  AND    xrpm.shipment_provision_div                    = otta_out_om_e.attribute1
  AND    gic_out_om_e.item_id                           = iimb_out_om_e.item_id
  AND    gic_out_om_e.category_id                       = mcb_out_om_e.category_id
  AND    gic_out_om_e.category_set_id                   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om_e.segment1                          = '5'
  AND   (xrpm.ship_prov_rcv_pay_category                = otta_out_om_e.attribute11
      OR xrpm.ship_prov_rcv_pay_category               IS NULL)
  AND    xoha_out_om_e.customer_id                      = hpat_out_om_e.party_id
  AND    hpat_out_om_e.party_id                         = hcsa_out_om_e.party_id
  AND    hpat_out_om_e.status                           = 'A'
  AND    hcsa_out_om_e.status                           = 'A'
  AND    xoha_out_om_e.result_deliver_to_id             = hpas_out_om_e.party_site_id
  AND    hpas_out_om_e.party_site_id                    = xpas_out_om_e.party_site_id
  AND    hpas_out_om_e.party_id                         = xpas_out_om_e.party_id
  AND    hpas_out_om_e.location_id                      = xpas_out_om_e.location_id
  AND    hpas_out_om_e.status                           = 'A'
  AND    xpas_out_om_e.start_date_active               <= TRUNC(SYSDATE)
  AND    xpas_out_om_e.end_date_active                 >= TRUNC(SYSDATE)
  AND    xrpm.stock_adjustment_div                      = otta_out_om_e.attribute4
  UNION ALL
  -- �L���o�׎���
  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,ilm_out_om2_e.lot_no                          AS lot_no
        ,ilm_out_om2_e.attribute1                      AS manufacture_date
        ,ilm_out_om2_e.attribute2                      AS uniqe_sign
        ,ilm_out_om2_e.attribute3                      AS expiration_date -- <---- �����܂ŋ���
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2_e.arrival_date                   AS arrival_date
        ,NVL(xoha_out_om2_e.arrival_date
            ,xoha_out_om2_e.shipped_date)              AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,'2'                                           AS status           -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,oe_transaction_types_all     otta_out_om2_e                 -- �󒍃^�C�v
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om2_e                     -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_om2_e                    -- �i�ڃ}�X�^
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib2_out_om2_e                -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om2_e                  -- OPM���b�g�}�X�^
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
-- 2008/10/24 Y.Yamamoto v1.1 add start
                ,xrpm_out_om2_e.item_div_origin
                ,xrpm_out_om2_e.item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 add end
          FROM   fnd_lookup_values flv_out_om2_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'OMSO'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.item_div_ahead                  = '5'
          AND    xrpm_out_om2_e.prod_div_origin                IS NOT NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NOT NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'ORDER'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id    <> xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- �x���w��
  AND    xmld_out_om2_e.record_type_code               = '20'      -- �o�Ɏ���
  AND    xmld_out_om2_e.item_id                        = ilm_out_om2_e.item_id
  AND    xmld_out_om2_e.lot_id                         = ilm_out_om2_e.lot_id
  AND    xoha_out_om2_e.req_status                     = '08'      -- �o�׎��ьv���
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- �x���˗�
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb2_out_om2_e.segment1                       = '5'
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
-- 2008/10/24 Y.Yamamoto v1.1 add start
  AND    xrpm.item_div_origin                          = mcb2_out_om2_e.segment1
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
-- 2008/10/24 Y.Yamamoto v1.1 add end
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
  UNION ALL
  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,ilm_out_om2_e.lot_no                          AS lot_no
        ,ilm_out_om2_e.attribute1                      AS manufacture_date
        ,ilm_out_om2_e.attribute2                      AS uniqe_sign
        ,ilm_out_om2_e.attribute3                      AS expiration_date -- <---- �����܂ŋ���
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2_e.arrival_date                   AS arrival_date
        ,NVL(xoha_out_om2_e.arrival_date
            ,xoha_out_om2_e.shipped_date)              AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,'2'                                           AS status           -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,oe_transaction_types_all     otta_out_om2_e                 -- �󒍃^�C�v
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om2_e                     -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_om2_e                    -- �i�ڃ}�X�^
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib2_out_om2_e                -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om2_e                  -- OPM���b�g�}�X�^
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
-- 2008/10/24 Y.Yamamoto v1.1 add start
                ,xrpm_out_om2_e.item_div_origin
                ,xrpm_out_om2_e.item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 add end
          FROM   fnd_lookup_values flv_out_om2_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'PORC'
          AND    xrpm_out_om2_e.source_document_code            = 'RMA'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.item_div_ahead                  = '5'
          AND    xrpm_out_om2_e.prod_div_origin                IS NOT NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NOT NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'RETURN'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id    <> xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- �x���w��
  AND    xmld_out_om2_e.record_type_code               = '20'      -- �o�Ɏ���
  AND    xmld_out_om2_e.item_id                        = ilm_out_om2_e.item_id
  AND    xmld_out_om2_e.lot_id                         = ilm_out_om2_e.lot_id
  AND    xoha_out_om2_e.req_status                     = '08'      -- �o�׎��ьv���
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- �x���˗�
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb2_out_om2_e.segment1                       = '5'
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
-- 2008/10/24 Y.Yamamoto v1.1 add start
  AND    xrpm.item_div_origin                          = mcb2_out_om2_e.segment1
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
-- 2008/10/24 Y.Yamamoto v1.1 add end
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
  UNION ALL
  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,ilm_out_om2_e.lot_no                          AS lot_no
        ,ilm_out_om2_e.attribute1                      AS manufacture_date
        ,ilm_out_om2_e.attribute2                      AS uniqe_sign
        ,ilm_out_om2_e.attribute3                      AS expiration_date -- <---- �����܂ŋ���
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2_e.arrival_date                   AS arrival_date
        ,NVL(xoha_out_om2_e.arrival_date
            ,xoha_out_om2_e.shipped_date)              AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,'2'                                           AS status           -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,oe_transaction_types_all     otta_out_om2_e                 -- �󒍃^�C�v
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om2_e                     -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_om2_e                    -- �i�ڃ}�X�^
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib2_out_om2_e                -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om2_e                  -- OPM���b�g�}�X�^
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
-- 2008/10/24 Y.Yamamoto v1.1 update start
--                ,nvl(xrpm_out_om2_e.item_div_origin,'Dummy')         AS item_div_origin
--                ,nvl(xrpm_out_om2_e.item_div_ahead,'Dummy')          AS item_div_ahead
                ,xrpm_out_om2_e.item_div_origin
                ,DECODE(xrpm_out_om2_e.item_div_ahead,'5','5','Dummy') AS item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 update end
          FROM   fnd_lookup_values flv_out_om2_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'OMSO'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.prod_div_origin                IS NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'ORDER'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id    <> xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- �x���w��
  AND    xmld_out_om2_e.record_type_code               = '20'      -- �o�Ɏ���
  AND    xmld_out_om2_e.item_id                        = ilm_out_om2_e.item_id
  AND    xmld_out_om2_e.lot_id                         = ilm_out_om2_e.lot_id
  AND    xoha_out_om2_e.req_status                     = '08'      -- �o�׎��ьv���
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- �x���˗�
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2_e.segment1,'5','5','Dummy')
-- 2008/10/24 Y.Yamamoto v1.1 update start
--  AND    xrpm.item_div_ahead                           = DECODE(mcb_out_om2_e.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
-- 2008/10/24 Y.Yamamoto v1.1 update end
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
  UNION ALL
  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,ilm_out_om2_e.lot_no                          AS lot_no
        ,ilm_out_om2_e.attribute1                      AS manufacture_date
        ,ilm_out_om2_e.attribute2                      AS uniqe_sign
        ,ilm_out_om2_e.attribute3                      AS expiration_date -- <---- �����܂ŋ���
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2_e.arrival_date                   AS arrival_date
        ,NVL(xoha_out_om2_e.arrival_date
            ,xoha_out_om2_e.shipped_date)              AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,'2'                                           AS status           -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,oe_transaction_types_all     otta_out_om2_e                 -- �󒍃^�C�v
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om2_e                     -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_om2_e                    -- �i�ڃ}�X�^
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib2_out_om2_e                -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om2_e                  -- OPM���b�g�}�X�^
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
-- 2008/10/24 Y.Yamamoto v1.1 update start
--                ,nvl(xrpm_out_om2_e.item_div_origin,'Dummy')         AS item_div_origin
--                ,nvl(xrpm_out_om2_e.item_div_ahead,'Dummy')          AS item_div_ahead
                ,xrpm_out_om2_e.item_div_origin
                ,DECODE(xrpm_out_om2_e.item_div_ahead,'5','5','Dummy') AS item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 update end
          FROM   fnd_lookup_values flv_out_om2_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'PORC'
          AND    xrpm_out_om2_e.source_document_code            = 'RMA'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.prod_div_origin                IS NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'RETURN'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id    <> xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- �x���w��
  AND    xmld_out_om2_e.record_type_code               = '20'      -- �o�Ɏ���
  AND    xmld_out_om2_e.item_id                        = ilm_out_om2_e.item_id
  AND    xmld_out_om2_e.lot_id                         = ilm_out_om2_e.lot_id
  AND    xoha_out_om2_e.req_status                     = '08'      -- �o�׎��ьv���
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- �x���˗�
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2_e.segment1,'5','5','Dummy')
-- 2008/10/24 Y.Yamamoto v1.1 update start
--  AND    xrpm.item_div_ahead                           = DECODE(mcb_out_om2_e.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
-- 2008/10/24 Y.Yamamoto v1.1 update end
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
-- 2008/10/24 Y.Yamamoto v1.1 add start
  UNION ALL
  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,ilm_out_om2_e.lot_no                          AS lot_no
        ,ilm_out_om2_e.attribute1                      AS manufacture_date
        ,ilm_out_om2_e.attribute2                      AS uniqe_sign
        ,ilm_out_om2_e.attribute3                      AS expiration_date -- <---- �����܂ŋ���
        ,NVL(xoha_out_om2_e.arrival_date
            ,xoha_out_om2_e.shipped_date)              AS arrival_date
        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,'2'                                           AS status           -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,oe_transaction_types_all     otta_out_om2_e                 -- �󒍃^�C�v
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om2_e                     -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_om2_e                    -- �i�ڃ}�X�^
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib2_out_om2_e                -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om2_e                  -- OPM���b�g�}�X�^
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
                ,xrpm_out_om2_e.item_div_origin
                ,DECODE(xrpm_out_om2_e.item_div_ahead,'5','5','Dummy') AS item_div_ahead
          FROM   fnd_lookup_values flv_out_om2_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'OMSO'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.prod_div_origin                IS NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'ORDER'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id     = xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- �x���w��
  AND    xmld_out_om2_e.record_type_code               = '20'      -- �o�Ɏ���
  AND    xmld_out_om2_e.item_id                        = ilm_out_om2_e.item_id
  AND    xmld_out_om2_e.lot_id                         = ilm_out_om2_e.lot_id
  AND    xoha_out_om2_e.req_status                     = '08'      -- �o�׎��ьv���
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- �x���˗�
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2_e.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
  UNION ALL
  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,ilm_out_om2_e.lot_no                          AS lot_no
        ,ilm_out_om2_e.attribute1                      AS manufacture_date
        ,ilm_out_om2_e.attribute2                      AS uniqe_sign
        ,ilm_out_om2_e.attribute3                      AS expiration_date -- <---- �����܂ŋ���
        ,NVL(xoha_out_om2_e.arrival_date
            ,xoha_out_om2_e.shipped_date)              AS arrival_date
        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,'2'                                           AS status           -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,oe_transaction_types_all     otta_out_om2_e                 -- �󒍃^�C�v
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om2_e                     -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_om2_e                    -- �i�ڃ}�X�^
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib2_out_om2_e                -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om2_e                  -- OPM���b�g�}�X�^
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
                ,xrpm_out_om2_e.item_div_origin
                ,DECODE(xrpm_out_om2_e.item_div_ahead,'5','5','Dummy') AS item_div_ahead
          FROM   fnd_lookup_values flv_out_om2_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'PORC'
          AND    xrpm_out_om2_e.source_document_code            = 'RMA'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.prod_div_origin                IS NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'RETURN'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id     = xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- �x���w��
  AND    xmld_out_om2_e.record_type_code               = '20'      -- �o�Ɏ���
  AND    xmld_out_om2_e.item_id                        = ilm_out_om2_e.item_id
  AND    xmld_out_om2_e.lot_id                         = ilm_out_om2_e.lot_id
  AND    xoha_out_om2_e.req_status                     = '08'      -- �o�׎��ьv���
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- �x���˗�
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2_e.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
-- 2008/10/24 Y.Yamamoto v1.1 add end
  UNION ALL
  -- �݌ɒ��� �o�Ɏ���(�o�� ���{�o�� �p�p�o��)
  SELECT iwm_out_om3_e.attribute1                      AS ownership_code
        ,mil_out_om3_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om3_e.item_id                        AS item_id
        ,ilm_out_om3_e.lot_no                          AS lot_no
        ,ilm_out_om3_e.attribute1                      AS manufacture_date
        ,ilm_out_om3_e.attribute2                      AS uniqe_sign
        ,ilm_out_om3_e.attribute3                      AS expiration_date -- <---- �����܂ŋ���
        ,xoha_out_om3_e.shipped_date                   AS arrival_date
        ,xoha_out_om3_e.shipped_date                   AS leaving_date
        ,'2'                                           AS status          -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om3_e.request_no                     AS voucher_no
        ,hpat_out_om3_e.attribute19                    AS ukebaraisaki_name
        ,xpas_out_om3_e.party_site_name                AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_om3_e.actual_quantity                AS leaving_quantity
  FROM   xxwsh_order_headers_all      xoha_out_om3_e                 -- �󒍃w�b�_(�A�h�I��)
        ,xxwsh_order_lines_all        xola_out_om3_e                 -- �󒍖���(�A�h�I��)
        ,xxinv_mov_lot_details        xmld_out_om3_e                 -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_whse_mst                  iwm_out_om3_e                     -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_om3_e                     -- OPM�ۊǏꏊ�}�X�^
        ,ic_item_mst_b                iimb_out_om3_e                    -- OPM�i�ڃ}�X�^
        ,mtl_system_items_b           msib_out_om3_e                    -- �i�ڃ}�X�^
        ,ic_lots_mst                  ilm_out_om3_e                  -- OPM���b�g�}�X�^
        ,oe_transaction_types_all     otta_out_om3_e                 -- �󒍃^�C�v
        ,hz_parties                   hpat_out_om3_e
        ,hz_cust_accounts             hcsa_out_om3_e
        ,hz_party_sites               hpas_out_om3_e
        ,xxcmn_party_sites            xpas_out_om3_e
        ,(SELECT xrpm_out_om3_e.new_div_invent
                ,flv_out_om3_e.meaning
                ,xrpm_out_om3_e.stock_adjustment_div
                ,xrpm_out_om3_e.ship_prov_rcv_pay_category
          FROM   fnd_lookup_values flv_out_om3_e                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_om3_e                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_om3_e.lookup_type                       = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om3_e.language                          = 'JA'
          AND    flv_out_om3_e.lookup_code                       = xrpm_out_om3_e.new_div_invent
          AND    xrpm_out_om3_e.doc_type                         = 'OMSO'
          AND    xrpm_out_om3_e.use_div_invent                   = 'Y'
         ) xrpm
  WHERE  otta_out_om3_e.order_category_code              = 'ORDER'
  AND    xoha_out_om3_e.order_header_id                  = xola_out_om3_e.order_header_id
  AND    xoha_out_om3_e.deliver_from_id                  = mil_out_om3_e.inventory_location_id
  AND    iwm_out_om3_e.mtl_organization_id               = mil_out_om3_e.organization_id
  AND    xola_out_om3_e.shipping_inventory_item_id       = msib_out_om3_e.inventory_item_id
  AND    iimb_out_om3_e.item_no                          = msib_out_om3_e.segment1
  AND    msib_out_om3_e.organization_id                  = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om3_e.mov_line_id                      = xola_out_om3_e.order_line_id
  AND    xmld_out_om3_e.document_type_code               = '10'      -- �o�׈˗�
  AND    xmld_out_om3_e.record_type_code                 = '20'      -- �o�Ɏ���
  AND    xmld_out_om3_e.item_id                          = ilm_out_om3_e.item_id
  AND    xmld_out_om3_e.lot_id                           = ilm_out_om3_e.lot_id
  AND    xoha_out_om3_e.req_status                       = '04'      -- �o�׎��ьv���
  AND    xoha_out_om3_e.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om3_e.delete_flag                      = 'N'       -- OFF
  AND    otta_out_om3_e.attribute1                       = '1'       -- �o�׈˗�
  AND    xoha_out_om3_e.order_type_id                    = otta_out_om3_e.transaction_type_id
  AND    xrpm.stock_adjustment_div                       = otta_out_om3_e.attribute4
  AND    xrpm.stock_adjustment_div                       = '2'
  AND    xrpm.ship_prov_rcv_pay_category                 = otta_out_om3_e.attribute11
  AND    xrpm.ship_prov_rcv_pay_category                IN ( '01' , '02' )
  AND    xoha_out_om3_e.customer_id                      = hpat_out_om3_e.party_id
  AND    hpat_out_om3_e.party_id                         = hcsa_out_om3_e.party_id
  AND    hpat_out_om3_e.status                           = 'A'
  AND    hcsa_out_om3_e.status                           = 'A'
  AND    xoha_out_om3_e.result_deliver_to_id             = hpas_out_om3_e.party_site_id
  AND    hpas_out_om3_e.party_site_id                    = xpas_out_om3_e.party_site_id
  AND    hpas_out_om3_e.party_id                         = xpas_out_om3_e.party_id
  AND    hpas_out_om3_e.location_id                      = xpas_out_om3_e.location_id
  AND    hpas_out_om3_e.status                           = 'A'
  AND    xpas_out_om3_e.start_date_active               <= TRUNC(SYSDATE)
  AND    xpas_out_om3_e.end_date_active                 >= TRUNC(SYSDATE)
  UNION ALL
  -- �݌ɒ��� �o�Ɏ���(�����݌�)
  SELECT iwm_out_ad_e_x97.attribute1                   AS ownership_code
        ,mil_out_ad_e_x97.inventory_location_id        AS inventory_location_id
        ,itc_out_ad_e_x97.item_id                      AS item_id
        ,ilm_out_ad_e_x97.lot_no                       AS lot_no
        ,ilm_out_ad_e_x97.attribute1                   AS manufacture_date
        ,ilm_out_ad_e_x97.attribute2                   AS uniqe_sign
        ,ilm_out_ad_e_x97.attribute3                   AS expiration_date -- <---- �����܂ŋ���
        ,itc_out_ad_e_x97.trans_date                   AS arrival_date
        ,itc_out_ad_e_x97.trans_date                   AS leaving_date
        ,'2'                                           AS status        -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,ijm_out_ad_e_x97.journal_no                   AS voucher_no
        ,xrpm.meaning                                  AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update start
--        ,ABS(itc_out_ad_e_x97.trans_qty)               AS leaving_quantity
        ,itc_out_ad_e_x97.trans_qty                    AS leaving_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update end
  FROM   ic_tran_cmp                  itc_out_ad_e_x97                  -- OPM�����݌Ƀg�����U�N�V����
        ,ic_jrnl_mst                  ijm_out_ad_e_x97                  -- OPM�W���[�i���}�X�^
        ,ic_adjs_jnl                  iaj_out_ad_e_x97                  -- OPM�݌ɒ����W���[�i��
        ,ic_whse_mst                  iwm_out_ad_e_x97                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_ad_e_x97                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_ad_e_x97                  -- OPM���b�g�}�X�^
        ,(SELECT xrpm_out_ad_e_x97.new_div_invent
                ,flv_out_ad_e_x97.meaning
                ,xrpm_out_ad_e_x97.reason_code
                ,xrpm_out_ad_e_x97.rcv_pay_div
          FROM   fnd_lookup_values flv_out_ad_e_x97                     -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_ad_e_x97                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_ad_e_x97.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_out_ad_e_x97.language                = 'JA'
          AND    flv_out_ad_e_x97.lookup_code             = xrpm_out_ad_e_x97.new_div_invent
          AND    xrpm_out_ad_e_x97.doc_type               = 'ADJI'
          AND    xrpm_out_ad_e_x97.use_div_invent         = 'Y'
          AND    xrpm_out_ad_e_x97.reason_code            = 'X977'               -- �����݌�
          AND    xrpm_out_ad_e_x97.rcv_pay_div            = '-1'                 -- ���o
         ) xrpm
  WHERE  itc_out_ad_e_x97.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_out_ad_e_x97.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_out_ad_e_x97.item_id                 = ilm_out_ad_e_x97.item_id
  AND    itc_out_ad_e_x97.lot_id                  = ilm_out_ad_e_x97.lot_id
  AND    iwm_out_ad_e_x97.mtl_organization_id     = mil_out_ad_e_x97.organization_id
  AND    itc_out_ad_e_x97.whse_code               = iwm_out_ad_e_x97.whse_code
  AND    itc_out_ad_e_x97.location                = mil_out_ad_e_x97.segment1
  AND    ijm_out_ad_e_x97.journal_id              = iaj_out_ad_e_x97.journal_id   -- OPM�W���[�i���}�X�^���o����
  AND    iaj_out_ad_e_x97.doc_id                  = itc_out_ad_e_x97.doc_id       -- OPM�݌ɒ����W���[�i�����o����
  AND    iaj_out_ad_e_x97.doc_line                = itc_out_ad_e_x97.doc_line     -- OPM�݌ɒ����W���[�i�����o����
  AND    ijm_out_ad_e_x97.attribute1             IS NULL                          -- OPM�W���[�i���}�X�^.����ID��NULL
  UNION ALL
  -- �����݌ɏo�Ɏ���
  SELECT iwm_out_ad_e_x97.attribute1                   AS ownership_code
        ,mil_out_ad_e_x97.inventory_location_id        AS inventory_location_id
        ,itc_out_ad_e_x97.item_id                      AS item_id
        ,ilm_out_ad_e_x97.lot_no                       AS lot_no
        ,ilm_out_ad_e_x97.attribute1                   AS manufacture_date
        ,ilm_out_ad_e_x97.attribute2                   AS uniqe_sign
        ,ilm_out_ad_e_x97.attribute3                   AS expiration_date -- <---- �����܂ŋ���
        ,itc_out_ad_e_x97.trans_date                   AS arrival_date
        ,itc_out_ad_e_x97.trans_date                   AS leaving_date
        ,'2'                                           AS status        -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xrart_out_ad_e_x97.source_document_number     AS voucher_no        -- �`�[No
        ,xv_out_ad_e_x97.vendor_name                   AS ukebaraisaki_name -- �󕥐於
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update start
--        ,ABS(itc_out_ad_e_x97.trans_qty)               AS leaving_quantity
        ,itc_out_ad_e_x97.trans_qty                    AS leaving_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update end
  FROM   ic_tran_cmp                  itc_out_ad_e_x97                  -- OPM�����݌Ƀg�����U�N�V����
        ,ic_jrnl_mst                  ijm_out_ad_e_x97                  -- OPM�W���[�i���}�X�^
        ,ic_adjs_jnl                  iaj_out_ad_e_x97                  -- OPM�݌ɒ����W���[�i��
        ,xxpo_rcv_and_rtn_txns        xrart_out_ad_e_x97                -- ����ԕi���уA�h�I��
        ,ic_whse_mst                  iwm_out_ad_e_x97                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_ad_e_x97                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_ad_e_x97                  -- OPM���b�g�}�X�^
        ,po_vendors                   pv_out_ad_e_x97                   -- �d����}�X�^
        ,xxcmn_vendors                xv_out_ad_e_x97                   -- �d����A�h�I���}�X�^
        ,(SELECT xrpm_out_ad_e_x97.new_div_invent
                ,flv_out_ad_e_x97.meaning
                ,xrpm_out_ad_e_x97.reason_code
                ,xrpm_out_ad_e_x97.rcv_pay_div
          FROM   fnd_lookup_values flv_out_ad_e_x97                     -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_ad_e_x97                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_ad_e_x97.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_out_ad_e_x97.language                = 'JA'
          AND    flv_out_ad_e_x97.lookup_code             = xrpm_out_ad_e_x97.new_div_invent
          AND    xrpm_out_ad_e_x97.doc_type               = 'ADJI'
          AND    xrpm_out_ad_e_x97.use_div_invent         = 'Y'
          AND    xrpm_out_ad_e_x97.reason_code            = 'X977'               -- �����݌�
          AND    xrpm_out_ad_e_x97.rcv_pay_div            = '-1'                 -- ���o
         ) xrpm
  WHERE  itc_out_ad_e_x97.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_out_ad_e_x97.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_out_ad_e_x97.item_id                 = ilm_out_ad_e_x97.item_id
  AND    itc_out_ad_e_x97.lot_id                  = ilm_out_ad_e_x97.lot_id
  AND    iwm_out_ad_e_x97.mtl_organization_id     = mil_out_ad_e_x97.organization_id
  AND    itc_out_ad_e_x97.whse_code               = iwm_out_ad_e_x97.whse_code
  AND    itc_out_ad_e_x97.location                = mil_out_ad_e_x97.segment1
  AND    ijm_out_ad_e_x97.journal_id              = iaj_out_ad_e_x97.journal_id   -- OPM�W���[�i���}�X�^���o����
  AND    iaj_out_ad_e_x97.doc_id                  = itc_out_ad_e_x97.doc_id       -- OPM�݌ɒ����W���[�i�����o����
  AND    iaj_out_ad_e_x97.doc_line                = itc_out_ad_e_x97.doc_line     -- OPM�݌ɒ����W���[�i�����o����
  AND    ijm_out_ad_e_x97.attribute1             IS NOT NULL                      -- OPM�W���[�i���}�X�^.����ID��NULL�łȂ�
  AND    TO_NUMBER(ijm_out_ad_e_x97.attribute1)   = xrart_out_ad_e_x97.txns_id    -- ����ID
  AND    xrart_out_ad_e_x97.vendor_id             = xv_out_ad_e_x97.vendor_id     -- �d����ID
  AND    pv_out_ad_e_x97.vendor_id                = xv_out_ad_e_x97.vendor_id
  AND    pv_out_ad_e_x97.end_date_active         IS NULL
  AND    xv_out_ad_e_x97.start_date_active       <= TRUNC( SYSDATE )
  AND    xv_out_ad_e_x97.end_date_active         >= TRUNC( SYSDATE )
  UNION ALL
  -- �݌ɒ��� �o�Ɏ���(�d����ԕi)
  SELECT iwm_out_ad_e_x2.attribute1                    AS ownership_code
        ,mil_out_ad_e_x2.inventory_location_id         AS inventory_location_id
        ,itc_out_ad_e_x2.item_id                       AS item_id
        ,ilm_out_ad_e_x2.lot_no                        AS lot_no
        ,ilm_out_ad_e_x2.attribute1                    AS manufacture_date
        ,ilm_out_ad_e_x2.attribute2                    AS uniqe_sign
        ,ilm_out_ad_e_x2.attribute3                    AS expiration_date -- <---- �����܂ŋ���
        ,itc_out_ad_e_x2.trans_date                    AS arrival_date
        ,itc_out_ad_e_x2.trans_date                    AS leaving_date
        ,'2'                                           AS status      -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xrart_out_ad_e_x2.rcv_rtn_number              AS voucher_no
        ,xv_out_ad_e_x2.vendor_name                    AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itc_out_ad_e_x2.trans_qty                     AS deliver_to_name
        ,0                                             AS leaving_quantity
  FROM   ic_adjs_jnl                  iaj_out_ad_e_x2                   -- OPM�݌ɒ����W���[�i��
        ,ic_jrnl_mst                  ijm_out_ad_e_x2                   -- OPM�W���[�i���}�X�^
        ,ic_tran_cmp                  itc_out_ad_e_x2                   -- OPM�����݌Ƀg�����U�N�V����
        ,xxpo_rcv_and_rtn_txns        xrart_out_ad_e_x2                 -- ����ԕi���сi�A�h�I���j
        ,ic_whse_mst                  iwm_out_ad_e_x2                   -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_ad_e_x2                   -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_ad_e_x2                   -- OPM���b�g�}�X�^
        ,po_vendors                   pv_out_ad_e_x2                    -- �d����}�X�^
        ,xxcmn_vendors                xv_out_ad_e_x2                    -- �d����A�h�I���}�X�^
        ,(SELECT xrpm_out_ad_e_x2.new_div_invent
                ,flv_out_ad_e_x2.meaning
                ,xrpm_out_ad_e_x2.doc_type
                ,xrpm_out_ad_e_x2.reason_code
                ,xrpm_out_ad_e_x2.rcv_pay_div
          FROM   fnd_lookup_values flv_out_ad_e_x2                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_ad_e_x2                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_ad_e_x2.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_out_ad_e_x2.language                = 'JA'
          AND    flv_out_ad_e_x2.lookup_code             = xrpm_out_ad_e_x2.new_div_invent
          AND    xrpm_out_ad_e_x2.doc_type               = 'ADJI'
          AND    xrpm_out_ad_e_x2.use_div_invent         = 'Y'
          AND    xrpm_out_ad_e_x2.reason_code            = 'X201'               -- �d���ԕi�o��
          AND    xrpm_out_ad_e_x2.rcv_pay_div            = '-1'                 -- ���o
         ) xrpm
  WHERE  itc_out_ad_e_x2.doc_type                = xrpm.doc_type
  AND    itc_out_ad_e_x2.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_out_ad_e_x2.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_out_ad_e_x2.item_id                 = ilm_out_ad_e_x2.item_id
  AND    itc_out_ad_e_x2.lot_id                  = ilm_out_ad_e_x2.lot_id
  AND    iwm_out_ad_e_x2.mtl_organization_id     = mil_out_ad_e_x2.organization_id
  AND    itc_out_ad_e_x2.whse_code               = iwm_out_ad_e_x2.whse_code
  AND    itc_out_ad_e_x2.location                = mil_out_ad_e_x2.segment1
  AND    iaj_out_ad_e_x2.journal_id              = ijm_out_ad_e_x2.journal_id
  AND    itc_out_ad_e_x2.doc_type                = iaj_out_ad_e_x2.trans_type
  AND    itc_out_ad_e_x2.doc_id                  = iaj_out_ad_e_x2.doc_id
  AND    itc_out_ad_e_x2.doc_line                = iaj_out_ad_e_x2.doc_line
  AND    TO_NUMBER( ijm_out_ad_e_x2.attribute1 ) = xrart_out_ad_e_x2.txns_id
  AND    xrart_out_ad_e_x2.vendor_id             = xv_out_ad_e_x2.vendor_id     -- �d����ID
  AND    pv_out_ad_e_x2.vendor_id                = xv_out_ad_e_x2.vendor_id
  AND    pv_out_ad_e_x2.end_date_active         IS NULL
  AND    xv_out_ad_e_x2.start_date_active       <= TRUNC( SYSDATE )
  AND    xv_out_ad_e_x2.end_date_active         >= TRUNC( SYSDATE )
  UNION ALL
  -- �݌ɒ��� �o�Ɏ���(�ړ����ђ���)
  SELECT iwm_out_ad_e_12.attribute1                    AS ownership_code
        ,mil_out_ad_e_12.inventory_location_id         AS inventory_location_id
        ,xmldt_out_ad_e_12.item_id                     AS item_id
        ,ilm_out_ad_e_12.lot_no                        AS lot_no
        ,ilm_out_ad_e_12.attribute1                    AS manufacture_date
        ,ilm_out_ad_e_12.attribute2                    AS uniqe_sign
        ,ilm_out_ad_e_12.attribute3                    AS expiration_date -- <---- �����܂ŋ���
        ,itc_out_ad_e_12.trans_date                    AS arrival_date
        ,itc_out_ad_e_12.trans_date                    AS leaving_date
        ,'2'                                           AS status   -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_ad_e_12.mov_num                     AS voucher_no
        ,mil2_out_ad_e_12.description                  AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itc_out_ad_e_12.trans_qty                     AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_ad_e_12                -- �ړ��˗�/�w���w�b�_(�A�h�I��)
        ,xxinv_mov_req_instr_lines    xmril_out_ad_e_12                -- �ړ��˗�/�w������(�A�h�I��)
        ,xxinv_mov_lot_details        xmldt_out_ad_e_12                -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_adjs_jnl                  iaj_out_ad_e_12                  -- OPM�݌ɒ����W���[�i��
        ,ic_jrnl_mst                  ijm_out_ad_e_12                  -- OPM�W���[�i���}�X�^
        ,ic_tran_cmp                  itc_out_ad_e_12                  -- OPM�����݌Ƀg�����U�N�V����
        ,ic_whse_mst                  iwm_out_ad_e_12                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_ad_e_12                  -- OPM�ۊǏꏊ�}�X�^
        ,mtl_item_locations           mil2_out_ad_e_12                 -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_ad_e_12                  -- OPM���b�g�}�X�^
        ,(SELECT xrpm_out_ad_e_12.new_div_invent
                ,flv_out_ad_e_12.meaning
                ,xrpm_out_ad_e_12.doc_type
                ,xrpm_out_ad_e_12.reason_code
                ,xrpm_out_ad_e_12.rcv_pay_div
          FROM   fnd_lookup_values flv_out_ad_e_12                      -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_ad_e_12                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_ad_e_12.lookup_type            = 'XXCMN_NEW_DIVISION'
          AND    flv_out_ad_e_12.language               = 'JA'
          AND    flv_out_ad_e_12.lookup_code            = xrpm_out_ad_e_12.new_div_invent
          AND    xrpm_out_ad_e_12.doc_type              = 'ADJI'
          AND    xrpm_out_ad_e_12.use_div_invent        = 'Y'
          AND    xrpm_out_ad_e_12.reason_code           = 'X123'               -- �ړ����ђ���
          AND    xrpm_out_ad_e_12.rcv_pay_div           = '1'                  -- ���
         ) xrpm
  WHERE  itc_out_ad_e_12.doc_type               = xrpm.doc_type
  AND    itc_out_ad_e_12.reason_code            = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_out_ad_e_12.trans_qty )      = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_out_ad_e_12.item_id                = xmldt_out_ad_e_12.item_id
  AND    itc_out_ad_e_12.lot_id                 = xmldt_out_ad_e_12.lot_id
  AND    itc_out_ad_e_12.location               = xmrih_out_ad_e_12.shipped_locat_code
  AND    itc_out_ad_e_12.doc_type               = iaj_out_ad_e_12.trans_type
  AND    itc_out_ad_e_12.doc_id                 = iaj_out_ad_e_12.doc_id
  AND    itc_out_ad_e_12.doc_line               = iaj_out_ad_e_12.doc_line
  AND    iaj_out_ad_e_12.journal_id             = ijm_out_ad_e_12.journal_id
  AND    xmril_out_ad_e_12.mov_line_id          = TO_NUMBER( ijm_out_ad_e_12.attribute1 )
  AND    xmldt_out_ad_e_12.item_id              = ilm_out_ad_e_12.item_id
  AND    xmldt_out_ad_e_12.lot_id               = ilm_out_ad_e_12.lot_id
  AND    xmldt_out_ad_e_12.record_type_code     = '20'
  AND    xmldt_out_ad_e_12.document_type_code   = '20'
  AND    xmril_out_ad_e_12.mov_line_id          = xmldt_out_ad_e_12.mov_line_id
  AND    xmrih_out_ad_e_12.mov_hdr_id           = xmril_out_ad_e_12.mov_hdr_id
  AND    xmrih_out_ad_e_12.shipped_locat_id     = mil_out_ad_e_12.inventory_location_id
  AND    iwm_out_ad_e_12.mtl_organization_id    = mil_out_ad_e_12.organization_id
  AND    xmrih_out_ad_e_12.ship_to_locat_id     = mil2_out_ad_e_12.inventory_location_id
  UNION ALL
  -- �݌ɒ��� �o�Ɏ���(��L�ȊO)
  SELECT iwm_out_ad_e_xx.attribute1                    AS ownership_code
        ,mil_out_ad_e_xx.inventory_location_id         AS inventory_location_id
        ,itc_out_ad_e_xx.item_id                       AS item_id
        ,ilm_out_ad_e_xx.lot_no                        AS lot_no
        ,ilm_out_ad_e_xx.attribute1                    AS manufacture_date
        ,ilm_out_ad_e_xx.attribute2                    AS uniqe_sign
        ,ilm_out_ad_e_xx.attribute3                    AS expiration_date -- <---- �����܂ŋ���
        ,itc_out_ad_e_xx.trans_date                    AS arrival_date
        ,itc_out_ad_e_xx.trans_date                    AS leaving_date
        ,'2'                                           AS status   -- ����
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,ijm_out_ad_e_xx.journal_no                    AS voucher_no
        ,xrpm.meaning                                  AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update start
--        ,ABS(itc_out_ad_e_xx.trans_qty)                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '503' ) THEN
            itc_out_ad_e_xx.trans_qty * -1
          ELSE
            itc_out_ad_e_xx.trans_qty
          END                                             leaving_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update end
  FROM   ic_adjs_jnl                  iaj_out_ad_e_xx                  -- OPM�݌ɒ����W���[�i��
        ,ic_jrnl_mst                  ijm_out_ad_e_xx                  -- OPM�W���[�i���}�X�^
        ,ic_tran_cmp                  itc_out_ad_e_xx                  -- OPM�����݌Ƀg�����U�N�V����
        ,ic_whse_mst                  iwm_out_ad_e_xx                  -- OPM�q�Ƀ}�X�^
        ,mtl_item_locations           mil_out_ad_e_xx                  -- OPM�ۊǏꏊ�}�X�^
        ,ic_lots_mst                  ilm_out_ad_e_xx                  -- OPM���b�g�}�X�^
        ,(SELECT xrpm_out_ad_e_xx.new_div_invent
                ,flv_out_ad_e_xx.meaning
                ,xrpm_out_ad_e_xx.doc_type
                ,xrpm_out_ad_e_xx.reason_code
                ,xrpm_out_ad_e_xx.rcv_pay_div
          FROM   fnd_lookup_values flv_out_ad_e_xx                     -- �N�C�b�N�R�[�h
                ,xxcmn_rcv_pay_mst xrpm_out_ad_e_xx                    -- �󕥋敪�A�h�I���}�X�^
          WHERE  flv_out_ad_e_xx.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_out_ad_e_xx.language                = 'JA'
          AND    flv_out_ad_e_xx.lookup_code             = xrpm_out_ad_e_xx.new_div_invent
          AND    xrpm_out_ad_e_xx.doc_type               = 'ADJI'
          AND    xrpm_out_ad_e_xx.use_div_invent         = 'Y'
          AND    xrpm_out_ad_e_xx.reason_code       NOT IN ('X977','X201','X123')
          AND    xrpm_out_ad_e_xx.rcv_pay_div            = '-1'                 -- ���o
         ) xrpm
  WHERE  itc_out_ad_e_xx.doc_type                = xrpm.doc_type
  AND    itc_out_ad_e_xx.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_out_ad_e_xx.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_out_ad_e_xx.item_id                 = ilm_out_ad_e_xx.item_id
  AND    itc_out_ad_e_xx.lot_id                  = ilm_out_ad_e_xx.lot_id
  AND    iwm_out_ad_e_xx.mtl_organization_id     = mil_out_ad_e_xx.organization_id
  AND    itc_out_ad_e_xx.whse_code               = iwm_out_ad_e_xx.whse_code
  AND    itc_out_ad_e_xx.location                = mil_out_ad_e_xx.segment1
  AND    iaj_out_ad_e_xx.journal_id              = ijm_out_ad_e_xx.journal_id
  AND    itc_out_ad_e_xx.doc_type                = iaj_out_ad_e_xx.trans_type
  AND    itc_out_ad_e_xx.doc_id                  = iaj_out_ad_e_xx.doc_id
  AND    itc_out_ad_e_xx.doc_line                = iaj_out_ad_e_xx.doc_line
;
--
COMMENT ON COLUMN xxinv_stc_trans_p1_v.ownership_code        IS '���`�R�[�h';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.inventory_location_id IS '�ۊǑq��ID';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.item_id               IS '�i��ID';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.lot_no                IS '���b�gNo';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.manufacture_date      IS '�����N����';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.uniqe_sign            IS '�ŗL�L��';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.expiration_date       IS '�ܖ�����';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.arrival_date          IS '����';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.leaving_date          IS '����';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.status                IS '�X�e�[�^�X';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.reason_code           IS '���R�R�[�h';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.reason_code_name      IS '���R�R�[�h��';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.voucher_no            IS '�`�[No';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.ukebaraisaki_name     IS '�󕥐�';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.deliver_to_name       IS '�z����';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.stock_quantity        IS '���ɐ�';
COMMENT ON COLUMN xxinv_stc_trans_p1_v.leaving_quantity      IS '�o�ɐ�';
--
COMMENT ON TABLE  xxinv_stc_trans_p1_v IS '���o�ɏ��r���[ ���i ���b�g�Ǘ��i' ;
/
