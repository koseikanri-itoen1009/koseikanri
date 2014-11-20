CREATE OR REPLACE VIEW xxinv_stc_trans_v 
(
  whse_code
 ,organization_id
 ,ownership_code
 ,inventory_location_id
 ,location_code
 ,location
 ,item_id
 ,item_no
 ,item_name
 ,item_short_name
 ,case_content
 ,lot_id
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
 ,ukebaraisaki_id
 ,ukebaraisaki_name
 ,deliver_to_id
 ,deliver_to_name
 ,stock_quantity
 ,leaving_quantity
) 
AS 
SELECT xstv.whse_code
      ,xstv.organization_id
      ,xstv.ownership_code
      ,xstv.inventory_location_id
      ,xstv.location_code
      ,xstv.location
      ,xstv.item_id
      ,xstv.item_no
      ,xstv.item_name
      ,xstv.item_short_name
      ,xstv.case_content
      ,xstv.lot_id
      ,CASE
        WHEN ( xstv.lot_ctl = 1 ) THEN
          xstv.lot_no                             -- ���b�g�Ǘ��i
        ELSE
          NULL                                    -- �񃍃b�g�Ǘ��i
       END                        lot_no
      ,CASE
        WHEN ( xstv.lot_ctl = 1 ) THEN
          xstv.manufacture_date                   -- ���b�g�Ǘ��i
        ELSE
          NULL                                    -- �񃍃b�g�Ǘ��i
       END                        manufacture_date
      ,CASE
        WHEN ( xstv.lot_ctl = 1 ) THEN
          xstv.uniqe_sign                         -- ���b�g�Ǘ��i
        ELSE
          NULL                                    -- �񃍃b�g�Ǘ��i
       END                        uniqe_sign
      ,CASE
        WHEN ( xstv.lot_ctl = 1 ) THEN
          xstv.expiration_date                    -- ���b�g�Ǘ��i
        ELSE
          NULL                                    -- �񃍃b�g�Ǘ��i
       END                        expiration_date
      ,xstv.arrival_date
      ,xstv.leaving_date
      ,xstv.status
      ,xstv.reason_code
      ,xstv.reason_code_name
      ,xstv.voucher_no
      ,xstv.ukebaraisaki_id
      ,xstv.ukebaraisaki_name
      ,xstv.deliver_to_id
      ,xstv.deliver_to_name
      ,xstv.stock_quantity
      ,xstv.leaving_quantity
 FROM (
        ------------------------------------------------------------------------
        -- ���ɗ\��
        ------------------------------------------------------------------------
        -- ��������\��
        SELECT xilv_in_po.whse_code                          AS whse_code
              ,xilv_in_po.mtl_organization_id                AS organization_id
              ,xilv_in_po.customer_stock_whse                AS ownership_code
              ,xilv_in_po.inventory_location_id              AS inventory_location_id
              ,xilv_in_po.segment1                           AS location_code
              ,xilv_in_po.description                        AS location
              ,ximv_in_po.item_id                            AS item_id
              ,ximv_in_po.item_no                            AS item_no
              ,ximv_in_po.item_name                          AS item_name
              ,ximv_in_po.item_short_name                    AS item_short_name
              ,ximv_in_po.num_of_cases                       AS case_content
              ,ilm_in_po.lot_id                              AS lot_id
              ,ilm_in_po.lot_no                              AS lot_no
              ,ilm_in_po.attribute1                          AS manufacture_date
              ,ilm_in_po.attribute2                          AS uniqe_sign
              ,ilm_in_po.attribute3                          AS expiration_date -- <---- �����܂ŋ���
              ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS arrival_date
              ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS leaving_date
              ,'1'                                           AS status        -- �\��
              ,xrpm_in_po.new_div_invent                     AS reason_code
              ,flv_in_po.meaning                             AS reason_code_name
              ,pha_in_po.segment1                            AS voucher_no
              ,pha_in_po.vendor_id                           AS ukebaraisaki_id
              ,xvv_in_po.vendor_full_name                    AS ukebaraisaki_name
              ,NULL                                          AS deliver_to_id
              ,NULL                                          AS deliver_to_name
              ,pla_in_po.quantity                            AS stock_quantity
              ,0                                             AS leaving_quantity
              ,ximv_in_po.lot_ctl
        FROM   xxcmn_item_locations_v  xilv_in_po                       -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v        ximv_in_po                       -- OPM�i�ڏ��VIEW
              ,ic_lots_mst             ilm_in_po                        -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst       xrpm_in_po                       -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values       flv_in_po                        -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,po_headers_all          pha_in_po                        -- �����w�b�_
              ,po_lines_all            pla_in_po                        -- ��������
--del start 2008/06/06
--              ,rcv_shipment_lines      rsl_in_po                        -- �������
--              ,rcv_transactions        rt_in_po                         -- ������
--del end 2008/06/06
              ,xxcmn_vendors_v         xvv_in_po                        -- �d������VIEW
        WHERE  xrpm_in_po.doc_type             = 'PORC'
        AND    xrpm_in_po.source_document_code = 'PO'
        AND    xrpm_in_po.use_div_invent       = 'Y'
        AND    pha_in_po.po_header_id          = pla_in_po.po_header_id
        AND    pha_in_po.attribute1           IN ( '20'                 -- �����쐬��
                                                  ,'25' )               -- �������
        AND    pla_in_po.attribute13           = 'N'                    -- ������
        AND    pla_in_po.item_id               = ximv_in_po.inventory_item_id
        AND    ilm_in_po.item_id               = ximv_in_po.item_id
--mod start 2008/06/10
--        AND (( ximv_in_po.lot_ctl              = 1                      -- ���b�g�Ǘ��i
--           AND pla_in_po.cancel_flag          <> 'Y'
--           AND pla_in_po.attribute1            = ilm_in_po.lot_no )
--          OR ( ximv_in_po.lot_ctl              = 0 ))                   -- �񃍃b�g�Ǘ��i
        AND    pla_in_po.cancel_flag          <> 'Y'
        AND    pla_in_po.attribute1            = ilm_in_po.lot_no
--mod end 2008/06/10
        AND    pha_in_po.attribute5            = xilv_in_po.segment1
        AND    TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' )
                                              <= TRUNC( SYSDATE )
--mod start 2008/06/06
--        AND    rsl_in_po.po_header_id          = pha_in_po.po_header_id
--        AND    rsl_in_po.po_line_id            = pla_in_po.po_line_id
--        AND    rt_in_po.shipment_line_id       = rsl_in_po.shipment_line_id
--        AND    rt_in_po.destination_type_code  = rsl_in_po.destination_type_code
--        AND    xrpm_in_po.transaction_type     = rt_in_po.transaction_type
--mod end 2008/06/06
--mod start 2008/06/09
--        AND    xrpm_in_po.transaction_type    in ('DELIVER','RETURN TO VENDOR')
        AND    xrpm_in_po.transaction_type    in ('DELIVER')
--mod start 2008/06/09
        AND    flv_in_po.lookup_type           = 'XXCMN_NEW_DIVISION'
        AND    flv_in_po.language              = 'JA'
        AND    flv_in_po.lookup_code           = xrpm_in_po.new_div_invent
        AND    xvv_in_po.vendor_id             = pha_in_po.vendor_id
        UNION ALL
        -- �ړ����ɗ\��(�w�� �ϑ�����)
        SELECT xilv_in_xf.whse_code
              ,xilv_in_xf.mtl_organization_id
              ,xilv_in_xf.customer_stock_whse
              ,xilv_in_xf.inventory_location_id
              ,xilv_in_xf.segment1
              ,xilv_in_xf.description
              ,ximv_in_xf.item_id
              ,ximv_in_xf.item_no
              ,ximv_in_xf.item_name
              ,ximv_in_xf.item_short_name
              ,ximv_in_xf.num_of_cases
              ,ilm_in_xf.lot_id
              ,ilm_in_xf.lot_no
              ,ilm_in_xf.attribute1
              ,ilm_in_xf.attribute2
              ,ilm_in_xf.attribute3                                      -- <---- �����܂ŋ���
              ,xmrih_in_xf.schedule_arrival_date
              ,xmrih_in_xf.schedule_ship_date
              ,'1'                                     AS status         -- �\��
              ,xrpm_in_xf.new_div_invent
              ,flv_in_xf.meaning
              ,xmrih_in_xf.mov_num
              ,xmrih_in_xf.shipped_locat_id
--mod start 2008/06/05
--              ,xilv_in_xf.description
              ,xilv_in_xf2.description
--mod end 2008/06/05
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
--mod start 2008/06/05 rev1.5
--              ,CASE
--                WHEN ( ximv_in_xf.lot_ctl = 1 ) THEN
--                  xmld_in_xf.actual_quantity                             -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_in_xf.lot_ctl = 0  ) THEN
--                  xmril_in_xf.instruct_qty                               -- �񃍃b�g�Ǘ��i(�w������)
--               END                                        stock_quantity
              ,xmld_in_xf.actual_quantity              AS stock_quantity
--mod end 2008/06/05 rev1.5
              ,0                                       AS leaving_quantity
              ,ximv_in_xf.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_xf                   -- OPM�ۊǏꏊ���VIEW
--add start 2008/06/10
              ,xxcmn_item_locations_v       xilv_in_xf2                  -- OPM�ۊǏꏊ���VIEW
--add end 2008/06/10
              ,xxcmn_item_mst_v             ximv_in_xf                   -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_xf                    -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_xf                   -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_xf                    -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_in_xf                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_in_xf                  -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_in_xf                   -- �ړ����b�g�ڍ�(�A�h�I��)
--del start 2008/06/05 rev1.6
--              ,ic_tran_pnd                  itp_in_xf                    -- OPM�ۗ��݌Ƀg�����U�N�V����
--              ,ic_xfer_mst                  ixm_in_xf                    -- OPM�݌ɓ]���}�X�^
--del end 2008/06/05 rev1.6
        WHERE  xrpm_in_xf.doc_type                = 'XFER'               -- �ړ��ϑ�����
        AND    xrpm_in_xf.use_div_invent          = 'Y'
--add start 2008/06/05 rev1.6
        AND    xrpm_in_xf.rcv_pay_div             = '1'                 -- ���
--add end 2008/06/05 rev1.6
--del start 2008/06/05 rev1.6
--        AND    itp_in_xf.delete_mark              = 0                    -- �L���`�F�b�N(OPM�ۗ��݌�)
--del end 2008/06/05 rev1.6
        AND    xmrih_in_xf.mov_hdr_id             = xmril_in_xf.mov_hdr_id
--mod start 2008/06/04 rev1.1
--        AND    xmrih_in_xf.ship_to_locat_id       = xilv_in_xf.segment1
        AND    xmrih_in_xf.ship_to_locat_id       = xilv_in_xf.inventory_location_id
--mod end 2008/06/04 rev1.1
--add start 2008/06/10
        AND    xmrih_in_xf.shipped_locat_id       = xilv_in_xf2.inventory_location_id
--add end 2008/06/10
        AND    xmril_in_xf.item_id                = ximv_in_xf.item_id
        AND    ilm_in_xf.item_id                  = ximv_in_xf.item_id
        AND    xmld_in_xf.mov_line_id             = xmril_in_xf.mov_line_id
        AND    xmld_in_xf.document_type_code      = '20'                 -- �ړ�
        AND    xmld_in_xf.record_type_code        = '10'                 -- �w��
--add start 2008/06/05 rev1.6
--        AND   (xmld_in_xf.lot_id                  = ilm_in_xf.lot_id
--         OR    xmld_in_xf.lot_id IS NULL)
        AND    xmld_in_xf.lot_id                  = ilm_in_xf.lot_id
--add end 2008/06/05 rev1.6
--add start 2008/06/10
        AND    xmrih_in_xf.mov_type               = '1'
--add end 2008/06/10
        AND    xmrih_in_xf.comp_actual_flg        = 'N'                  -- ���і��v��
        AND    xmrih_in_xf.status                IN ( '02'               -- �˗���
                                                     ,'03' )             -- ������
        AND    xmril_in_xf.delete_flg             = 'N'                  -- OFF
        AND    xmrih_in_xf.schedule_arrival_date <= TRUNC( SYSDATE )
--del start 2008/06/05 rev1.6
--        AND    TO_NUMBER( ixm_in_xf.attribute1 )  = xmril_in_xf.mov_line_id
--        AND    itp_in_xf.doc_type                 = xrpm_in_xf.doc_type
--        AND    itp_in_xf.doc_id                   = ixm_in_xf.transfer_id
--        AND    itp_in_xf.completed_ind            = 1
--        AND    itp_in_xf.whse_code                = xilv_in_xf.whse_code
--        AND    itp_in_xf.item_id                  = ximv_in_xf.item_id
--        AND    itp_in_xf.lot_id                   = ilm_in_xf.lot_id
--        AND    xrpm_in_xf.reason_code             = itp_in_xf.reason_code
--        AND    xrpm_in_xf.rcv_pay_div             = SIGN( itp_in_xf.trans_qty )
--del end 2008/06/05 rev1.6
        AND    flv_in_xf.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_in_xf.language                 = 'JA'
        AND    flv_in_xf.lookup_code              = xrpm_in_xf.new_div_invent
        UNION ALL
        -- �ړ����ɗ\��(�w�� �ϑ��Ȃ�)
        SELECT xilv_in_tr.whse_code
              ,xilv_in_tr.mtl_organization_id
              ,xilv_in_tr.customer_stock_whse
              ,xilv_in_tr.inventory_location_id
              ,xilv_in_tr.segment1
              ,xilv_in_tr.description
              ,ximv_in_tr.item_id
              ,ximv_in_tr.item_no
              ,ximv_in_tr.item_name
              ,ximv_in_tr.item_short_name
              ,ximv_in_tr.num_of_cases
              ,ilm_in_tr.lot_id
              ,ilm_in_tr.lot_no
              ,ilm_in_tr.attribute1
              ,ilm_in_tr.attribute2
              ,ilm_in_tr.attribute3                                   -- <---- �����܂ŋ���
              ,xmrih_in_tr.schedule_arrival_date
              ,xmrih_in_tr.schedule_ship_date
              ,'1'                                     AS status      -- �\��
              ,xrpm_in_tr.new_div_invent
              ,flv_in_tr.meaning
              ,xmrih_in_tr.mov_num
              ,xmrih_in_tr.shipped_locat_id
--mod start 2008/06/10
--              ,xilv_in_tr.description
              ,xilv_in_tr2.description
--mod end 2008/06/10
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
--mod start 2008/06/05 rev1.5
--              ,CASE
--                WHEN ( ximv_in_tr.lot_ctl = 1 ) THEN
--                  xmld_in_tr.actual_quantity                          -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_in_tr.lot_ctl = 0  ) THEN
--                  xmril_in_tr.instruct_qty                            -- �񃍃b�g�Ǘ��i(�w������)
--               END                                        stock_quantity
              ,xmld_in_tr.actual_quantity              stock_quantity
--mod end 2008/06/05 rev1.5
              ,0                                       AS leaving_quantity
              ,ximv_in_tr.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_tr                -- OPM�ۊǏꏊ���VIEW
--add start 2008/06/10
              ,xxcmn_item_locations_v       xilv_in_tr2               -- OPM�ۊǏꏊ���VIEW
--add end 2008/06/10
              ,xxcmn_item_mst_v             ximv_in_tr                -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_tr                 -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_tr                -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_tr                 -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_in_tr               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_in_tr               -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_in_tr                -- �ړ����b�g�ڍ�(�A�h�I��)
--del start 2008/06/05 rev1.6
--              ,ic_tran_cmp                  itc_in_tr                 -- OPM�����݌Ƀg�����U�N�V����
--              ,ic_adjs_jnl                  iaj_in_tr                 -- OPM�݌ɒ����W���[�i��
--              ,ic_jrnl_mst                  ijm_in_tr                 -- OPM�W���[�i���}�X�^
--del end 2008/06/05 rev1.6
        WHERE  xrpm_in_tr.doc_type                = 'TRNI'            -- �ړ��ϑ��Ȃ�
        AND    xrpm_in_tr.use_div_invent          = 'Y'
        AND    xmrih_in_tr.mov_hdr_id             = xmril_in_tr.mov_hdr_id
--add start 2008/06/05 rev1.6
        AND    xrpm_in_tr.rcv_pay_div             = '1'               -- ���
--add end 2008/06/05 rev1.6
--mod start 2008/06/04 rev1.1
--        AND    xmrih_in_tr.ship_to_locat_id       = xilv_in_tr.segment1
        AND    xmrih_in_tr.ship_to_locat_id       = xilv_in_tr.inventory_location_id
--mod end 2008/06/04 rev1.1
--add start 2008/06/10
        AND    xmrih_in_tr.shipped_locat_id       = xilv_in_tr2.inventory_location_id
--add end 2008/06/10
        AND    xmril_in_tr.item_id                = ximv_in_tr.item_id
        AND    ilm_in_tr.item_id                  = ximv_in_tr.item_id
        AND    xmld_in_tr.mov_line_id             = xmril_in_tr.mov_line_id
        AND    xmld_in_tr.document_type_code      = '20'              -- �ړ�
        AND    xmld_in_tr.record_type_code        = '10'              -- �w��
--add start 2008/06/05 rev1.6
--        AND   (xmld_in_tr.lot_id                  = ilm_in_tr.lot_id
--         OR    xmld_in_tr.lot_id IS NULL)
        AND    xmld_in_tr.lot_id                  = ilm_in_tr.lot_id
--add end 2008/06/05 rev1.6
        AND    xmrih_in_tr.comp_actual_flg        = 'N'               -- ���і��v��
        AND    xmrih_in_tr.status                IN ( '02'            -- �˗���
                                                     ,'03' )          -- ������
        AND    xmril_in_tr.delete_flg             = 'N'               -- OFF
        AND    xmrih_in_tr.schedule_arrival_date <= TRUNC( SYSDATE )
--add start 2008/06/10
        AND    xmrih_in_tr.mov_type                 = '2'
--add end 2008/06/10
--del start 2008/06/05 rev1.6
--        AND    TO_NUMBER( ijm_in_tr.attribute1 )  = xmril_in_tr.mov_line_id
--        AND    iaj_in_tr.journal_id               = ijm_in_tr.journal_id
--        AND    itc_in_tr.doc_type                 = iaj_in_tr.trans_type
--        AND    itc_in_tr.doc_id                   = iaj_in_tr.doc_id
--        AND    itc_in_tr.doc_line                 = iaj_in_tr.doc_line
--        AND    itc_in_tr.whse_code                = xilv_in_tr.whse_code
--        AND    itc_in_tr.item_id                  = ximv_in_tr.item_id
--        AND    itc_in_tr.lot_id                   = ilm_in_tr.lot_id
--        AND    xrpm_in_tr.doc_type                = itc_in_tr.doc_type
--        AND    xrpm_in_tr.reason_code             = itc_in_tr.reason_code
--        AND    xrpm_in_tr.rcv_pay_div             = SIGN( itc_in_tr.trans_qty )
--del end 2008/06/05 rev1.6
        AND    flv_in_tr.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_in_tr.language                 = 'JA'
        AND    flv_in_tr.lookup_code              = xrpm_in_tr.new_div_invent
        UNION ALL
        -- �ړ����ɗ\��(�o�ɕ񍐗L �ϑ�����)
        SELECT xilv_in_xf20.whse_code
              ,xilv_in_xf20.mtl_organization_id
              ,xilv_in_xf20.customer_stock_whse
              ,xilv_in_xf20.inventory_location_id
              ,xilv_in_xf20.segment1
              ,xilv_in_xf20.description
              ,ximv_in_xf20.item_id
              ,ximv_in_xf20.item_no
              ,ximv_in_xf20.item_name
              ,ximv_in_xf20.item_short_name
              ,ximv_in_xf20.num_of_cases
              ,ilm_in_xf20.lot_id
              ,ilm_in_xf20.lot_no
              ,ilm_in_xf20.attribute1
              ,ilm_in_xf20.attribute2
              ,ilm_in_xf20.attribute3                                    -- <---- �����܂ŋ���
              ,xmrih_in_xf20.schedule_arrival_date
              ,xmrih_in_xf20.schedule_ship_date
              ,'1'                                     AS status         -- �\��
              ,xrpm_in_xf20.new_div_invent
              ,flv_in_xf20.meaning
              ,xmrih_in_xf20.mov_num
              ,xmrih_in_xf20.shipped_locat_id
--mod start 2008/06/10
--              ,xilv_in_xf20.description
              ,xilv_in_xf202.description
--mod end 2008/06/10
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
--mod start 2008/06/05 rev1.5
--              ,CASE
--                WHEN ( ximv_in_xf20.lot_ctl = 1 ) THEN
--                  xmld_in_xf20.actual_quantity                           -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_in_xf20.lot_ctl = 0  ) THEN
--                  xmril_in_xf20.instruct_qty                             -- �񃍃b�g�Ǘ��i(�w������)
--               END                                        stock_quantity
              ,xmld_in_xf20.actual_quantity            stock_quantity
--mod end 2008/06/05 rev1.5
              ,0                                       AS leaving_quantity
              ,ximv_in_xf20.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_xf20                 -- OPM�ۊǏꏊ���VIEW
--add start 2008/06/10
              ,xxcmn_item_locations_v       xilv_in_xf202                -- OPM�ۊǏꏊ���VIEW
--add end 2008/06/10
              ,xxcmn_item_mst_v             ximv_in_xf20                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_xf20                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_xf20                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_xf20                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_in_xf20                -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_in_xf20                -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_in_xf20                 -- �ړ����b�g�ڍ�(�A�h�I��)
--del start 2008/06/05 rev1.6
--              ,ic_tran_pnd                  itp_in_xf20                  -- OPM�ۗ��݌Ƀg�����U�N�V����
--              ,ic_xfer_mst                  ixm_in_xf20                  -- OPM�݌ɓ]���}�X�^
--del end 2008/06/05 rev1.6
        WHERE  xrpm_in_xf20.doc_type                = 'XFER'             -- �ړ��ϑ�����
        AND    xrpm_in_xf20.use_div_invent          = 'Y'
--add start 2008/06/05 rev1.6
        AND    xrpm_in_xf20.rcv_pay_div             = '1'                -- ���
--add end 2008/06/05 rev1.6
--del start 2008/06/05 rev1.6
--        AND    itp_in_xf20.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
--del end 2008/06/05 rev1.6
        AND    xmrih_in_xf20.mov_hdr_id             = xmril_in_xf20.mov_hdr_id
--mod start 2008/06/04 rev1.1
--        AND    xmrih_in_xf20.ship_to_locat_id       = xilv_in_xf20.segment1
        AND    xmrih_in_xf20.ship_to_locat_id       = xilv_in_xf20.inventory_location_id
--mod end 2008/06/04 rev1.1
--add start 2008/06/10
        AND    xmrih_in_xf20.shipped_locat_id       = xilv_in_xf202.inventory_location_id
--add end 2008/06/10
--add start 2008/06/16
        AND    xmrih_in_xf20.mov_type               = '1'  -- �ϑ�����
--add end 2008/06/16
        AND    xmril_in_xf20.item_id                = ximv_in_xf20.item_id
        AND    ilm_in_xf20.item_id                  = ximv_in_xf20.item_id
        AND    xmld_in_xf20.mov_line_id             = xmril_in_xf20.mov_line_id
        AND    xmld_in_xf20.document_type_code      = '20'               -- �ړ�
        AND    xmld_in_xf20.record_type_code        = '20'               -- �o�Ɏ���
--add start 2008/06/05 rev1.6
        AND   (xmld_in_xf20.lot_id                  = ilm_in_xf20.lot_id
         OR    xmld_in_xf20.lot_id IS NULL)
--add end 2008/06/05 rev1.6
        AND    xmrih_in_xf20.comp_actual_flg        = 'N'                -- ���і��v��
        AND    xmrih_in_xf20.status                 = '04'               -- �o�ɕ񍐗L
        AND    xmril_in_xf20.delete_flg             = 'N'                -- OFF
        AND    xmrih_in_xf20.schedule_arrival_date <= TRUNC( SYSDATE )
--del start 2008/06/05 rev1.6
--        AND    TO_NUMBER( ixm_in_xf20.attribute1 )  = xmril_in_xf20.mov_line_id
--        AND    itp_in_xf20.doc_type                 = xrpm_in_xf20.doc_type
--        AND    itp_in_xf20.doc_id                   = ixm_in_xf20.transfer_id
--        AND    itp_in_xf20.completed_ind            = 1
--        AND    itp_in_xf20.whse_code                = xilv_in_xf20.whse_code
--        AND    itp_in_xf20.item_id                  = ximv_in_xf20.item_id
--        AND    itp_in_xf20.lot_id                   = ilm_in_xf20.lot_id
--        AND    xrpm_in_xf20.reason_code             = itp_in_xf20.reason_code
--        AND    xrpm_in_xf20.rcv_pay_div             = SIGN( itp_in_xf20.trans_qty )
--del end 2008/06/05 rev1.6
        AND    flv_in_xf20.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_in_xf20.language                 = 'JA'
        AND    flv_in_xf20.lookup_code              = xrpm_in_xf20.new_div_invent
        UNION ALL
        -- ���Y���ɗ\��
        SELECT xilv_in_pr.whse_code
              ,xilv_in_pr.mtl_organization_id
              ,xilv_in_pr.customer_stock_whse
              ,xilv_in_pr.inventory_location_id
              ,xilv_in_pr.segment1
              ,xilv_in_pr.description
              ,ximv_in_pr.item_id
              ,ximv_in_pr.item_no
              ,ximv_in_pr.item_name
              ,ximv_in_pr.item_short_name
              ,ximv_in_pr.num_of_cases
              ,ilm_in_pr.lot_id
              ,ilm_in_pr.lot_no
              ,ilm_in_pr.attribute1
              ,ilm_in_pr.attribute2
              ,ilm_in_pr.attribute3                                    -- <---- �����܂ŋ���
              ,gbh_in_pr.plan_start_date
              ,gbh_in_pr.plan_start_date
              ,'1'                                     AS status       -- �\��
              ,xrpm_in_pr.new_div_invent
              ,flv_in_pr.meaning
              ,gbh_in_pr.batch_no
              ,grb_in_pr.routing_id
--mod start 2008/06/07
--              ,grb_in_pr.routing_desc
              ,grt_in_pr.routing_desc
--mod end 2008/06/07
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,gmd_in_pr.plan_qty
              ,0                                       AS leaving_quantity
              ,ximv_in_pr.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_pr                 -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_in_pr                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_pr                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_pr                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_pr                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,gme_batch_header             gbh_in_pr                  -- ���Y�o�b�`
              ,gme_material_details         gmd_in_pr                  -- ���Y�����ڍ�
              ,gmd_routings_b               grb_in_pr                  -- �H���}�X�^
--mod start 2008/06/07
              ,gmd_routings_tl              grt_in_pr                  -- �H���}�X�^���{��
--mod end 2008/06/07
              ,xxinv_mov_lot_details        xmld_in_pr                 -- �ړ����b�g�ڍ�(�A�h�I��)
              ,ic_tran_pnd                  itp_in_pr                  -- OPM�ۗ��݌Ƀg�����U�N�V����
        WHERE  xrpm_in_pr.doc_type                = 'PROD'
        AND    xrpm_in_pr.use_div_invent          = 'Y'
        AND    itp_in_pr.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
        AND    gbh_in_pr.batch_id                 = gmd_in_pr.batch_id
        AND    gmd_in_pr.line_type               IN ( 1                -- �����i
                                                     ,2 )              -- ���Y��
        AND    itp_in_pr.doc_type                 = xrpm_in_pr.doc_type
        AND    itp_in_pr.doc_id                   = gmd_in_pr.batch_id
--mod start 2008/06/06
        AND    itp_in_pr.line_id                  = gmd_in_pr.material_detail_id
--mod end 2008/06/06
        AND    itp_in_pr.doc_line                 = gmd_in_pr.line_no
        AND    itp_in_pr.line_type                = gmd_in_pr.line_type
        AND    itp_in_pr.completed_ind            = 0
        AND    gmd_in_pr.material_detail_id       = xmld_in_pr.mov_line_id
        AND    gmd_in_pr.item_id                  = ximv_in_pr.item_id
        AND    ilm_in_pr.item_id                  = ximv_in_pr.item_id
        AND    itp_in_pr.lot_id                   = ilm_in_pr.lot_id
        AND    grb_in_pr.attribute9               = xilv_in_pr.segment1
        AND    xmld_in_pr.document_type_code      = '40'               -- ���Y�w��
        AND    xmld_in_pr.record_type_code        = '10'               -- �w��
        AND    NOT EXISTS( SELECT 'X'
                           FROM   gme_batch_header gbh_in_pr_ex
                           WHERE  gbh_in_pr_ex.batch_id      = gbh_in_pr.batch_id
                           AND    gbh_in_pr_ex.batch_status IN ( 7     -- ����
                                                                ,8     -- �N���[�Y
                                                                ,-1 )) -- ���
        AND    gbh_in_pr.plan_start_date         <= TRUNC( SYSDATE )
        AND    grb_in_pr.routing_id               = gbh_in_pr.routing_id
        AND    xrpm_in_pr.routing_class           = grb_in_pr.routing_class
        AND    xrpm_in_pr.line_type               = gmd_in_pr.line_type
--mod start 2008/06/23
--        AND (( gmd_in_pr.attribute5              IS NULL )
--          OR ( xrpm_in_pr.hit_in_div              = gmd_in_pr.attribute5 ) )
        AND ((( gmd_in_pr.attribute5              IS NULL )
          AND ( xrpm_in_pr.hit_in_div             IS NULL ))
        OR   (( gmd_in_pr.attribute5              IS NOT NULL )
          AND ( xrpm_in_pr.hit_in_div              = gmd_in_pr.attribute5 )))
--mod start 2008/06/23
        AND    flv_in_pr.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_in_pr.language                 = 'JA'
        AND    flv_in_pr.lookup_code              = xrpm_in_pr.new_div_invent
--mod start 2008/06/07
        AND    grb_in_pr.routing_id               = grt_in_pr.routing_id
        AND    grt_in_pr.language                 = 'JA'
--mod end 2008/06/07
        UNION ALL
        ------------------------------------------------------------------------
        -- �o�ɗ\��
        ------------------------------------------------------------------------
        -- �ړ��o�ɗ\��(�w�� �ϑ�����)
        SELECT xilv_out_xf.whse_code
              ,xilv_out_xf.mtl_organization_id
              ,xilv_out_xf.customer_stock_whse
              ,xilv_out_xf.inventory_location_id
              ,xilv_out_xf.segment1
              ,xilv_out_xf.description
              ,ximv_out_xf.item_id
              ,ximv_out_xf.item_no
              ,ximv_out_xf.item_name
              ,ximv_out_xf.item_short_name
              ,ximv_out_xf.num_of_cases
              ,ilm_out_xf.lot_id
              ,ilm_out_xf.lot_no
              ,ilm_out_xf.attribute1
              ,ilm_out_xf.attribute2
              ,ilm_out_xf.attribute3                                     -- <---- �����܂ŋ���
              ,xmrih_out_xf.schedule_arrival_date
              ,xmrih_out_xf.schedule_ship_date
              ,'1'                                     AS status         -- �\��
              ,xrpm_out_xf.new_div_invent
              ,flv_out_xf.meaning
              ,xmrih_out_xf.mov_num
              ,xmrih_out_xf.ship_to_locat_id
--mod start 2008/06/10
--              ,xilv_out_xf.description
              ,xilv_out_xf2.description
--mod end 2008/06/10
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,0                                       AS stock_quantity
--mod start 2008/06/05 rev1.5
--              ,CASE
--                WHEN ( ximv_out_xf.lot_ctl = 1 ) THEN
--                  xmld_out_xf.actual_quantity                            -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_out_xf.lot_ctl = 0  ) THEN
--                  xmril_out_xf.instruct_qty                              -- �񃍃b�g�Ǘ��i(�w������)
--               END                                        leaving_quantity
              ,xmld_out_xf.actual_quantity             AS leaving_quantity
--mod end 2008/06/05 rev1.5
              ,ximv_out_xf.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_xf                  -- OPM�ۊǏꏊ���VIEW
--add start 2008/06/10
              ,xxcmn_item_locations_v       xilv_out_xf2                 -- OPM�ۊǏꏊ���VIEW
--add end 2008/06/10
              ,xxcmn_item_mst_v             ximv_out_xf                  -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_xf                   -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_xf                  -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_xf                   -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_out_xf                 -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_out_xf                 -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_xf                  -- �ړ����b�g�ڍ�(�A�h�I��)
--del start 2008/06/05 rev1.6
--              ,ic_tran_pnd                  itp_out_xf                   -- OPM�ۗ��݌Ƀg�����U�N�V����
--              ,ic_xfer_mst                  ixm_out_xf                   -- OPM�݌ɓ]���}�X�^
--del end 2008/06/05 rev1.6
        WHERE  xrpm_out_xf.doc_type                = 'XFER'              -- �ړ��ϑ�����
        AND    xrpm_out_xf.use_div_invent          = 'Y'
--add start 2008/06/05 rev1.6
        AND    xrpm_out_xf.rcv_pay_div             = '-1'                -- ���o
--add end 2008/06/05 rev1.6
--del start 2008/06/05 rev1.6
--        AND    itp_out_xf.delete_mark              = 0                   -- �L���`�F�b�N(OPM�ۗ��݌�)
--del end 2008/06/05 rev1.6
        AND    xmrih_out_xf.mov_hdr_id             = xmril_out_xf.mov_hdr_id
--mod start 2008/06/04 rev1.1
--        AND    xmrih_out_xf.shipped_locat_id       = xilv_out_xf.segment1
        AND    xmrih_out_xf.shipped_locat_id       = xilv_out_xf.inventory_location_id
--mod end 2008/06/04 rev1.1
--add start 2008/06/10
        AND    xmrih_out_xf.ship_to_locat_id       = xilv_out_xf2.inventory_location_id
--add end 2008/06/10
        AND    xmril_out_xf.item_id                = ximv_out_xf.item_id
        AND    ilm_out_xf.item_id                  = ximv_out_xf.item_id
        AND    xmld_out_xf.mov_line_id             = xmril_out_xf.mov_line_id
        AND    xmld_out_xf.document_type_code      = '20'                -- �ړ�
        AND    xmld_out_xf.record_type_code        = '10'                -- �w��
--add start 2008/06/10
        AND    xmrih_out_xf.mov_type               = '1'
--add end 2008/06/10
--add start 2008/06/05 rev1.6
        AND   (xmld_out_xf.lot_id                  = ilm_out_xf.lot_id
         OR    xmld_out_xf.lot_id IS NULL)
--add end 2008/06/05 rev1.6
        AND    xmrih_out_xf.comp_actual_flg        = 'N'                 -- ���і��v��
        AND    xmrih_out_xf.status                IN ( '02'              -- �˗���
                                                      ,'03' )            -- ������
        AND    xmril_out_xf.delete_flg             = 'N'                 -- OFF
        AND    xmrih_out_xf.schedule_ship_date    <= TRUNC( SYSDATE )
--del start 2008/06/05 rev1.6
--        AND    TO_NUMBER( ixm_out_xf.attribute1 )  = xmril_out_xf.mov_line_id
--        AND    itp_out_xf.doc_type                 = xrpm_out_xf.doc_type
--        AND    itp_out_xf.doc_id                   = ixm_out_xf.transfer_id
--        AND    itp_out_xf.completed_ind            = 1
--        AND    itp_out_xf.whse_code                = xilv_out_xf.whse_code
--        AND    itp_out_xf.item_id                  = ximv_out_xf.item_id
--        AND    itp_out_xf.lot_id                   = ilm_out_xf.lot_id
--        AND    xrpm_out_xf.reason_code             = itp_out_xf.reason_code
--        AND    xrpm_out_xf.rcv_pay_div             = SIGN( itp_out_xf.trans_qty )
--del end 2008/06/05 rev1.6
        AND    flv_out_xf.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_out_xf.language                 = 'JA'
        AND    flv_out_xf.lookup_code              = xrpm_out_xf.new_div_invent
        UNION ALL
        -- �ړ��o�ɗ\��(�w�� �ϑ��Ȃ�)
        SELECT xilv_out_tr.whse_code
              ,xilv_out_tr.mtl_organization_id
              ,xilv_out_tr.customer_stock_whse
              ,xilv_out_tr.inventory_location_id
              ,xilv_out_tr.segment1
              ,xilv_out_tr.description
              ,ximv_out_tr.item_id
              ,ximv_out_tr.item_no
              ,ximv_out_tr.item_name
              ,ximv_out_tr.item_short_name
              ,ximv_out_tr.num_of_cases
              ,ilm_out_tr.lot_id
              ,ilm_out_tr.lot_no
              ,ilm_out_tr.attribute1
              ,ilm_out_tr.attribute2
              ,ilm_out_tr.attribute3                                   -- <---- �����܂ŋ���
              ,xmrih_out_tr.schedule_arrival_date
              ,xmrih_out_tr.schedule_ship_date
              ,'1'                                     AS status       -- �\��
              ,xrpm_out_tr.new_div_invent
              ,flv_out_tr.meaning
              ,xmrih_out_tr.mov_num
              ,xmrih_out_tr.ship_to_locat_id
--mod start 2008/06/10
--              ,xilv_out_tr.description
              ,xilv_out_tr2.description
--mod end 2008/06/10
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,0                                       AS stock_quantity
--mod start 2008/06/05 rev1.5
--              ,CASE
--                WHEN ( ximv_out_tr.lot_ctl = 1 ) THEN
--                  xmld_out_tr.actual_quantity                            -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_out_tr.lot_ctl = 0  ) THEN
--                  xmril_out_tr.instruct_qty                              -- �񃍃b�g�Ǘ��i(�w������)
--               END                                        leaving_quantity
              ,xmld_out_tr.actual_quantity             leaving_quantity
--mod end 2008/06/05 rev1.5
              ,ximv_out_tr.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_tr                -- OPM�ۊǏꏊ���VIEW
--mod start 2008/06/10
              ,xxcmn_item_locations_v       xilv_out_tr2               -- OPM�ۊǏꏊ���VIEW
--mod end 2008/06/10
              ,xxcmn_item_mst_v             ximv_out_tr                -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_tr                 -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_tr                -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_tr                 -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_out_tr               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_out_tr               -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_tr                -- �ړ����b�g�ڍ�(�A�h�I��)
--del start 2008/06/05 rev1.6
--              ,ic_tran_cmp                  itc_out_tr                 -- OPM�����݌Ƀg�����U�N�V����
--              ,ic_adjs_jnl                  iaj_out_tr                 -- OPM�݌ɒ����W���[�i��
--              ,ic_jrnl_mst                  ijm_out_tr                 -- OPM�W���[�i���}�X�^
--del end 2008/06/05 rev1.6
        WHERE  xrpm_out_tr.doc_type                = 'TRNI'            -- �ړ��ϑ��Ȃ�
        AND    xrpm_out_tr.use_div_invent          = 'Y'
--add start 2008/06/05 rev1.6
        AND    xrpm_out_tr.rcv_pay_div             = '-1'              -- ���o
--add end 2008/06/05 rev1.6
        AND    xmrih_out_tr.mov_hdr_id             = xmril_out_tr.mov_hdr_id
--mod start 2008/06/04 rev1.1
--        AND    xmrih_out_tr.shipped_locat_id       = xilv_out_tr.segment1
        AND    xmrih_out_tr.shipped_locat_id       = xilv_out_tr.inventory_location_id
--mod end 2008/06/04 rev1.1
--add start 2008/06/10
        AND    xmrih_out_tr.ship_to_locat_id       = xilv_out_tr2.inventory_location_id
--add end 2008/06/10
        AND    xmril_out_tr.item_id                = ximv_out_tr.item_id
        AND    ilm_out_tr.item_id                  = ximv_out_tr.item_id
        AND    xmld_out_tr.mov_line_id             = xmril_out_tr.mov_line_id
        AND    xmld_out_tr.document_type_code      = '20'              -- �ړ�
        AND    xmld_out_tr.record_type_code        = '10'             -- �w��
--add start 2008/06/05 rev1.6
--        AND   (xmld_out_tr.lot_id                  = ilm_out_tr.lot_id
--         OR    xmld_out_tr.lot_id IS NULL)
        AND    xmld_out_tr.lot_id                  = ilm_out_tr.lot_id
--add end 2008/06/05 rev1.6
        AND    xmrih_out_tr.comp_actual_flg        = 'N'               -- ���і��v��
        AND    xmrih_out_tr.status                IN ( '02'            -- �˗���
                                                      ,'03' )          -- ������
        AND    xmril_out_tr.delete_flg             = 'N'               -- OFF
        AND    xmrih_out_tr.schedule_ship_date    <= TRUNC( SYSDATE )
--add start 2008/06/10
        AND    xmrih_out_tr.mov_type               = '2'
--add end 2008/06/10
--del start 2008/06/05 rev1.6
--        AND    TO_NUMBER( ijm_out_tr.attribute1 )  = xmril_out_tr.mov_line_id
--        AND    iaj_out_tr.journal_id               = ijm_out_tr.journal_id
--        AND    itc_out_tr.doc_type                 = iaj_out_tr.trans_type
--        AND    itc_out_tr.doc_id                   = iaj_out_tr.doc_id
--        AND    itc_out_tr.doc_line                 = iaj_out_tr.doc_line
--        AND    itc_out_tr.whse_code                = xilv_out_tr.whse_code
--        AND    itc_out_tr.item_id                  = ximv_out_tr.item_id
--        AND    itc_out_tr.lot_id                   = ilm_out_tr.lot_id
--        AND    xrpm_out_tr.doc_type                = itc_out_tr.doc_type
--        AND    xrpm_out_tr.reason_code             = itc_out_tr.reason_code
--        AND    xrpm_out_tr.rcv_pay_div             = SIGN( itc_out_tr.trans_qty )
--del end 2008/06/05 rev1.6
        AND    flv_out_tr.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_out_tr.language                 = 'JA'
        AND    flv_out_tr.lookup_code              = xrpm_out_tr.new_div_invent
        UNION ALL
        -- �ړ��o�ɗ\��(���ɕ񍐗L �ϑ�����)
        SELECT xilv_out_xf20.whse_code
              ,xilv_out_xf20.mtl_organization_id
              ,xilv_out_xf20.customer_stock_whse
              ,xilv_out_xf20.inventory_location_id
              ,xilv_out_xf20.segment1
              ,xilv_out_xf20.description
              ,ximv_out_xf20.item_id
              ,ximv_out_xf20.item_no
              ,ximv_out_xf20.item_name
              ,ximv_out_xf20.item_short_name
              ,ximv_out_xf20.num_of_cases
              ,ilm_out_xf20.lot_id
              ,ilm_out_xf20.lot_no
              ,ilm_out_xf20.attribute1
              ,ilm_out_xf20.attribute2
              ,ilm_out_xf20.attribute3                                    -- <---- �����܂ŋ���
              ,xmrih_out_xf20.schedule_arrival_date
              ,xmrih_out_xf20.schedule_ship_date
              ,'1'                                     AS status         -- �\��
              ,xrpm_out_xf20.new_div_invent
              ,flv_out_xf20.meaning
              ,xmrih_out_xf20.mov_num
              ,xmrih_out_xf20.ship_to_locat_id
--mod start 2008/06/10
--              ,xilv_out_xf20.description
              ,xilv_out_xf202.description
--mod end 2008/06/10
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,0                                       AS stock_quantity
--mod start 2008/06/05 rev1.5
--              ,CASE
--                WHEN ( ximv_out_xf20.lot_ctl = 1 ) THEN
--                  xmld_out_xf20.actual_quantity                           -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_out_xf20.lot_ctl = 0  ) THEN
--                  xmril_out_xf20.instruct_qty                             -- �񃍃b�g�Ǘ��i(�w������)
--               END                                        leaving_quantity
              ,xmld_out_xf20.actual_quantity           leaving_quantity
--mod end 2008/06/05 rev1.5
              ,ximv_out_xf20.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_xf20                 -- OPM�ۊǏꏊ���VIEW
--mod start 2008/06/10
              ,xxcmn_item_locations_v       xilv_out_xf202                -- OPM�ۊǏꏊ���VIEW
--mod end 2008/06/10
              ,xxcmn_item_mst_v             ximv_out_xf20                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_xf20                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_xf20                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_xf20                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_out_xf20                -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_out_xf20                -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_xf20                 -- �ړ����b�g�ڍ�(�A�h�I��)
--del start 2008/06/05 rev1.6
--              ,ic_tran_pnd                  itp_out_xf20                  -- OPM�ۗ��݌Ƀg�����U�N�V����
--              ,ic_xfer_mst                  ixm_out_xf20                  -- OPM�݌ɓ]���}�X�^
--del end 2008/06/05 rev1.6
        WHERE  xrpm_out_xf20.doc_type                = 'XFER'             -- �ړ��ϑ�����
        AND    xrpm_out_xf20.use_div_invent          = 'Y'
--add start 2008/06/05 rev1.6
        AND    xrpm_out_xf20.rcv_pay_div             = '-1'                -- ���o
--add end 2008/06/05 rev1.6
--del start 2008/06/05 rev1.6
--        AND    itp_out_xf20.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
--del end 2008/06/05 rev1.6
        AND    xmrih_out_xf20.mov_hdr_id             = xmril_out_xf20.mov_hdr_id
--mod start 2008/06/04 rev1.1
--        AND    xmrih_out_xf20.shipped_locat_id       = xilv_out_xf20.segment1
        AND    xmrih_out_xf20.shipped_locat_id       = xilv_out_xf20.inventory_location_id
--mod end 2008/06/04 rev1.1
--add start 2008/06/10
        AND    xmrih_out_xf20.ship_to_locat_id       = xilv_out_xf202.inventory_location_id
--add end 2008/06/10
--add start 2008/06/16
        AND    xmrih_out_xf20.mov_type               = '1'  -- �ϑ�����
--add end 2008/06/16
        AND    xmril_out_xf20.item_id                = ximv_out_xf20.item_id
        AND    ilm_out_xf20.item_id                  = ximv_out_xf20.item_id
        AND    xmld_out_xf20.mov_line_id             = xmril_out_xf20.mov_line_id
        AND    xmld_out_xf20.document_type_code      = '20'               -- �ړ�
        AND    xmld_out_xf20.record_type_code        = '30'               -- ���Ɏ���
--add start 2008/06/05 rev1.6
        AND   (xmld_out_xf20.lot_id                  = ilm_out_xf20.lot_id
         OR    xmld_out_xf20.lot_id                 IS NULL)
--add end 2008/06/05 rev1.6
        AND    xmrih_out_xf20.comp_actual_flg        = 'N'                -- ���і��v��
        AND    xmrih_out_xf20.status                 = '05'               -- ���ɕ񍐗L
        AND    xmril_out_xf20.delete_flg             = 'N'                -- OFF
        AND    xmrih_out_xf20.schedule_ship_date    <= TRUNC( SYSDATE )
--del start 2008/06/05 rev1.6
--        AND    TO_NUMBER( ixm_out_xf20.attribute1 )  = xmril_out_xf20.mov_line_id
--        AND    itp_out_xf20.doc_type                 = xrpm_out_xf20.doc_type
--        AND    itp_out_xf20.doc_id                   = ixm_out_xf20.transfer_id
--        AND    itp_out_xf20.completed_ind            = 1
--        AND    itp_out_xf20.whse_code                = xilv_out_xf20.whse_code
--        AND    itp_out_xf20.item_id                  = ximv_out_xf20.item_id
--        AND    itp_out_xf20.lot_id                   = ilm_out_xf20.lot_id
--        AND    xrpm_out_xf20.reason_code             = itp_out_xf20.reason_code
--        AND    xrpm_out_xf20.rcv_pay_div             = SIGN( itp_out_xf20.trans_qty )
--del end 2008/06/05 rev1.6
        AND    flv_out_xf20.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_out_xf20.language                 = 'JA'
        AND    flv_out_xf20.lookup_code              = xrpm_out_xf20.new_div_invent
        UNION ALL
        -- �󒍏o�ח\��
        SELECT xilv_out_om.whse_code
              ,xilv_out_om.mtl_organization_id
              ,xilv_out_om.customer_stock_whse
              ,xilv_out_om.inventory_location_id
              ,xilv_out_om.segment1
              ,xilv_out_om.description
--mod start 2008/06/04 rev1.4
--              ,ximv_out_om.item_id
--              ,ximv_out_om.item_no
--              ,ximv_out_om.item_name
--              ,ximv_out_om.item_short_name
--              ,ximv_out_om.num_of_cases
              ,ximv_out_om_s.item_id
              ,ximv_out_om_s.item_no
              ,ximv_out_om_s.item_name
              ,ximv_out_om_s.item_short_name
              ,ximv_out_om_s.num_of_cases
--mod end 2008/06/04 rev1.4
              ,ilm_out_om.lot_id
              ,ilm_out_om.lot_no
              ,ilm_out_om.attribute1
              ,ilm_out_om.attribute2
              ,ilm_out_om.attribute3                                    -- <---- �����܂ŋ���
              ,xoha_out_om.schedule_arrival_date
              ,xoha_out_om.schedule_ship_date
              ,'1'                                     AS status        -- �\��
              ,xrpm_out_om.new_div_invent
              ,flv_out_om.meaning
              ,xoha_out_om.request_no
              ,TO_NUMBER( xoha_out_om.head_sales_branch )
              ,xcav_out_om.party_name
              ,xoha_out_om.deliver_to_id
              ,xpsv_out_om.party_site_full_name
              ,0                                       AS stock_quantity
--mod start 2008/06/05 rev1.5
--              ,CASE
----mod start 2008/06/04 rev1.4
----                WHEN ( ximv_out_om.lot_ctl = 1 ) THEN
----                  xmld_out_om.actual_quantity                           -- ���b�g�Ǘ��i(���ѐ���)
----                WHEN ( ximv_out_om.lot_ctl = 0  ) THEN
----                  xola_out_om.quantity                                  -- �񃍃b�g�Ǘ��i(����)
----               END                                        leaving_quantity
----              ,ximv_out_om.lot_ctl
--                WHEN ( ximv_out_om_s.lot_ctl = 1 ) THEN
--                  xmld_out_om.actual_quantity                           -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_out_om_s.lot_ctl = 0  ) THEN
--                  xola_out_om.quantity                                  -- �񃍃b�g�Ǘ��i(����)
--               END                                        leaving_quantity
----mod end 2008/06/04 rev1.4
              ,xmld_out_om.actual_quantity                leaving_quantity
--mod end 2008/06/05 rev1.5
              ,ximv_out_om_s.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_om                 -- OPM�ۊǏꏊ���VIEW
--mod start 2008/06/04 rev1.4
--              ,xxcmn_item_mst_v             ximv_out_om                 -- OPM�i�ڏ��VIEW
              ,xxcmn_item_mst_v             ximv_out_om_s               -- OPM�i�ڏ��VIEW(�o�וi��)
              ,xxcmn_item_mst_v             ximv_out_om_r               -- OPM�i�ڏ��VIEW(�˗��i��)
--mod end 2008/06/04 rev1.4
              ,ic_lots_mst                  ilm_out_om                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_om                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_om                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxwsh_order_headers_all      xoha_out_om                 -- �󒍃w�b�_(�A�h�I��)
              ,xxwsh_order_lines_all        xola_out_om                 -- �󒍖���(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_om                 -- �ړ����b�g�ڍ�(�A�h�I��)
              ,oe_transaction_types_all     otta_out_om                 -- �󒍃^�C�v
              ,xxcmn_cust_accounts_v        xcav_out_om                 -- �ڋq���VIEW
              ,xxcmn_party_sites_v          xpsv_out_om                 -- �p�[�e�B�T�C�g���VIEW
--mod start 2008/06/04 rev1.4
--              ,xxcmn_item_categories4_v     xicv_out_om                 -- OPM�i�ڃJ�e�S���������VIEW4
              ,xxcmn_item_categories4_v     xicv_out_om_s               -- OPM�i�ڃJ�e�S���������VIEW4(�o�וi��)
              ,xxcmn_item_categories4_v     xicv_out_om_r               -- OPM�i�ڃJ�e�S���������VIEW4(�˗��i��)
--mod end 2008/06/04 rev1.4
        WHERE  xrpm_out_om.doc_type                         = 'OMSO'
        AND    xrpm_out_om.use_div_invent                   = 'Y'
        AND    xoha_out_om.order_header_id                  = xola_out_om.order_header_id
--mod start 2008/06/04 rev1.1
--        AND    xoha_out_om.deliver_from_id                  = xilv_out_om.segment1
        AND    xoha_out_om.deliver_from_id                  = xilv_out_om.inventory_location_id
--mod end 2008/06/04 rev1.1
--mod start 2008/06/04 rev1.4
--        AND    xola_out_om.shipping_inventory_item_id       = ximv_out_om.inventory_item_id
--        AND    ilm_out_om.item_id                           = ximv_out_om.item_id
        AND    xola_out_om.shipping_inventory_item_id       = ximv_out_om_s.inventory_item_id
--add start 2008/06/04 rev1.4
        AND    xola_out_om.request_item_id                  = ximv_out_om_r.inventory_item_id
--add end 2008/06/04 rev1.4
        AND    ilm_out_om.item_id                           = ximv_out_om_s.item_id
--mod end 2008/06/04 rev1.4
        AND    xmld_out_om.mov_line_id                      = xola_out_om.order_line_id
        AND    xmld_out_om.document_type_code               = '10'      -- �o�׈˗�
        AND    xmld_out_om.record_type_code                 = '10'      -- �w��
--mod start 2008/06/04 rev1.4
--        AND (( ximv_out_om.lot_ctl                          = 1         -- ���b�g�Ǘ��i
--           AND ximv_out_om.item_id                          = xmld_out_om.item_id
--           AND xmld_out_om.lot_id                           = ilm_out_om.lot_id )
--          OR ( ximv_out_om.lot_ctl                          = 0 ))      -- �񃍃b�g�Ǘ��i
--mod start 2008/06/07
--        AND (( ximv_out_om_s.lot_ctl                        = 1         -- ���b�g�Ǘ��i
--           AND ximv_out_om_s.item_id                        = xmld_out_om.item_id
--           AND xmld_out_om.lot_id                           = ilm_out_om.lot_id )
--          OR ( ximv_out_om_s.lot_ctl                        = 0 ))      -- �񃍃b�g�Ǘ��i
--        AND ximv_out_om_s.item_id                           = xmld_out_om.item_id
        AND xmld_out_om.lot_id                              = ilm_out_om.lot_id
--        AND ximv_out_om_s.item_id                           = ilm_out_om.item_id
--mod end 2008/06/07
--mod end 2008/06/04 rev1.4
        AND    xoha_out_om.req_status                       = '03'      -- ���ߍ�
        AND    NVL( xoha_out_om.actual_confirm_class, 'N' ) = 'N'       -- ���і��v��
        AND    xoha_out_om.latest_external_flag             = 'Y'       -- ON
        AND    xola_out_om.delete_flag                      = 'N'       -- OFF
        AND    xoha_out_om.schedule_ship_date              <= TRUNC( SYSDATE )
        AND    xrpm_out_om.shipment_provision_div           = '1'       -- �o�׈˗�
        AND    xoha_out_om.order_type_id                    = otta_out_om.transaction_type_id
        AND    xrpm_out_om.shipment_provision_div           = otta_out_om.attribute1
--mod start 2008/06/04 rev1.4
--        AND    xicv_out_om.item_id                          = ximv_out_om.item_id
        AND    xicv_out_om_s.item_id                        = ximv_out_om_s.item_id
        AND    xicv_out_om_r.item_id                        = ximv_out_om_r.item_id
--mod end 2008/06/04 rev1.4
--mod start 2008/06/04
--        AND    NVL(xrpm_out_om.item_div_ahead, xicv_out_om.item_class_code)
--                                                            = xicv_out_om.item_class_code
--        AND    NVL(xrpm_out_om.item_div_origin, xicv_out_om.item_class_code)
--                                                            = xicv_out_om.item_class_code
        AND    NVL(xrpm_out_om.item_div_origin,'Dummy')     = DECODE(xicv_out_om_s.item_class_code,'5','5','Dummy') --�U�֌��i�ڋ敪 = �o�וi�ڋ敪
        AND    NVL(xrpm_out_om.item_div_ahead ,'Dummy')     = DECODE(xicv_out_om_r.item_class_code,'5','5','Dummy') --�U�֐�i�ڋ敪 = �˗��i�ڋ敪
        AND   (xrpm_out_om.ship_prov_rcv_pay_category       = otta_out_om.attribute11
        OR     xrpm_out_om.ship_prov_rcv_pay_category      IS NULL)
--mod end 2008/06/04
        AND    flv_out_om.lookup_type                       = 'XXCMN_NEW_DIVISION'
        AND    flv_out_om.language                          = 'JA'
        AND    flv_out_om.lookup_code                       = xrpm_out_om.new_div_invent
        AND    xoha_out_om.customer_id                      = xcav_out_om.party_id
        AND    xoha_out_om.deliver_to_id                    = xpsv_out_om.party_site_id
        UNION ALL
        -- �L���o�ח\��
        SELECT xilv_out_om2.whse_code
              ,xilv_out_om2.mtl_organization_id
              ,xilv_out_om2.customer_stock_whse
              ,xilv_out_om2.inventory_location_id
              ,xilv_out_om2.segment1
              ,xilv_out_om2.description
--mod start 2008/06/04 rev1.4
--              ,ximv_out_om2.item_id
--              ,ximv_out_om2.item_no
--              ,ximv_out_om2.item_name
--              ,ximv_out_om2.item_short_name
--              ,ximv_out_om2.num_of_cases
              ,ximv_out_om2_s.item_id
              ,ximv_out_om2_s.item_no
              ,ximv_out_om2_s.item_name
              ,ximv_out_om2_s.item_short_name
              ,ximv_out_om2_s.num_of_cases
--mod end 2008/06/04 rev1.4
              ,ilm_out_om2.lot_id
              ,ilm_out_om2.lot_no
              ,ilm_out_om2.attribute1
              ,ilm_out_om2.attribute2
              ,ilm_out_om2.attribute3                                    -- <---- �����܂ŋ���
              ,xoha_out_om2.schedule_arrival_date
              ,xoha_out_om2.schedule_ship_date
              ,'1'                                     AS status        -- �\��
              ,xrpm_out_om2.new_div_invent
              ,flv_out_om2.meaning
              ,xoha_out_om2.request_no
--mod start 2008/06/09
--              ,xoha_out_om2.deliver_to_id
              ,xoha_out_om2.vendor_site_id
--mod end 2008/06/09
--mod start 2008/06/05 rev1.8
----mod start 2008/06/04 rev1.3
----              ,xpsv_out_om2.party_site_full_name
--              ,xvsv_out_om2.vendor_site_name
--              ,xoha_out_om2.deliver_to_id
----              ,xpsv_out_om2.party_site_full_name
--              ,xvsv_out_om2.vendor_site_name
----mod end 2008/06/04 rev1.3
              ,xvsv_out_om2.vendor_site_name
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS vendor_site_name
--mod end 2008/06/05 rev1.8
              ,0                                       AS stock_quantity
--mod start 2008/06/05 rev1.5
--              ,CASE
----mod start 2008/06/04 rev1.4
----                WHEN ( ximv_out_om2.lot_ctl = 1 ) THEN
----                  xmld_out_om2.actual_quantity                           -- ���b�g�Ǘ��i(���ѐ���)
----                WHEN ( ximv_out_om2.lot_ctl = 0  ) THEN
----                  xola_out_om2.quantity                                  -- �񃍃b�g�Ǘ��i(����)
----               END                                        leaving_quantity
----              ,ximv_out_om2.lot_ctl
--                WHEN ( ximv_out_om2_s.lot_ctl = 1 ) THEN
--                  xmld_out_om2.actual_quantity                           -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_out_om2_s.lot_ctl = 0  ) THEN
--                  xola_out_om2.quantity                                  -- �񃍃b�g�Ǘ��i(����)
--               END                                        leaving_quantity
              ,xmld_out_om2.actual_quantity            AS leaving_quantity
--mod end 2008/06/05 rev1.5
              ,ximv_out_om2_s.lot_ctl
--mod end 2008/06/04 rev1.4
        FROM   xxcmn_item_locations_v       xilv_out_om2                 -- OPM�ۊǏꏊ���VIEW
--mod start 2008/06/04 rev1.4
--              ,xxcmn_item_mst_v             ximv_out_om2                 -- OPM�i�ڏ��VIEW
              ,xxcmn_item_mst_v             ximv_out_om2_s               -- OPM�i�ڏ��VIEW(�o�וi��)
              ,xxcmn_item_mst_v             ximv_out_om2_r               -- OPM�i�ڏ��VIEW(�˗��i��)
--mod end 2008/06/04 rev1.4
              ,ic_lots_mst                  ilm_out_om2                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_om2                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_om2                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxwsh_order_headers_all      xoha_out_om2                 -- �󒍃w�b�_(�A�h�I��)
              ,xxwsh_order_lines_all        xola_out_om2                 -- �󒍖���(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_om2                 -- �ړ����b�g�ڍ�(�A�h�I��)
              ,oe_transaction_types_all     otta_out_om2                 -- �󒍃^�C�v
--mod start 2008/06/04 rev1.3
--              ,xxcmn_party_sites_v          xpsv_out_om2                 -- �p�[�e�B�T�C�g���VIEW
              ,xxcmn_vendor_sites_v         xvsv_out_om2                 -- �d����T�C�g���VIEW
--mod end 2008/06/04 rev1.3
--mod start 2008/06/04 rev1.4
--              ,xxcmn_item_categories4_v     xicv_out_om2                 -- OPM�i�ڃJ�e�S���������VIEW4
              ,xxcmn_item_categories4_v     xicv_out_om2_s               -- OPM�i�ڃJ�e�S���������VIEW4(�o�וi��)
              ,xxcmn_item_categories4_v     xicv_out_om2_r               -- OPM�i�ڃJ�e�S���������VIEW4(�˗��i��)
--mod end 2008/06/04 rev1.4
        WHERE  xrpm_out_om2.doc_type                         = 'OMSO'
        AND    xrpm_out_om2.use_div_invent                   = 'Y'
        AND    xoha_out_om2.order_header_id                  = xola_out_om2.order_header_id
--mod start 2008/06/04 rev1.1
--        AND    xoha_out_om2.deliver_from_id                  = xilv_out_om2.segment1
        AND    xoha_out_om2.deliver_from_id                  = xilv_out_om2.inventory_location_id
--mod end 2008/06/04 rev1.1
--mod start 2008/06/04 rev1.4
--        AND    xola_out_om2.shipping_inventory_item_id       = ximv_out_om2.inventory_item_id
--        AND    ilm_out_om2.item_id                           = ximv_out_om2.item_id
        AND    xola_out_om2.shipping_inventory_item_id       = ximv_out_om2_s.inventory_item_id
--add start 2008/06/04 rev1.4
        AND    xola_out_om2.request_item_id                  = ximv_out_om2_r.inventory_item_id
--add end 2008/06/04 rev1.4
        AND    ilm_out_om2.item_id                           = ximv_out_om2_s.item_id
--mod end 2008/06/04 rev1.4
        AND    xmld_out_om2.mov_line_id                      = xola_out_om2.order_line_id
        AND    xmld_out_om2.document_type_code               = '30'      -- �x���w��
        AND    xmld_out_om2.record_type_code                 = '10'      -- �w��
--mod start 2008/06/04 rev1.4
--        AND (( ximv_out_om2.lot_ctl                          = 1         -- ���b�g�Ǘ��i
--           AND ximv_out_om2.item_id                          = xmld_out_om2.item_id
--           AND xmld_out_om2.lot_id                           = ilm_out_om2.lot_id )
--          OR ( ximv_out_om2.lot_ctl                          = 0 ))      -- �񃍃b�g�Ǘ��i
--mod start 2008/06/07
--        AND (( ximv_out_om2_s.lot_ctl                        = 1         -- ���b�g�Ǘ��i
--           AND ximv_out_om2_s.item_id                        = xmld_out_om2.item_id
--           AND xmld_out_om2.lot_id                           = ilm_out_om2.lot_id )
--          OR ( ximv_out_om2_s.lot_ctl                        = 0 ))      -- �񃍃b�g�Ǘ��i
--        AND ximv_out_om2_s.item_id                           = xmld_out_om2.item_id
        AND    xmld_out_om2.lot_id                           = ilm_out_om2.lot_id
--mod end 2008/06/07
--mod end 2008/06/04 rev1.4
        AND    xoha_out_om2.req_status                       = '07'      -- ��̍�
        AND    NVL( xoha_out_om2.actual_confirm_class, 'N' ) = 'N'       -- ���і��v��
        AND    xoha_out_om2.latest_external_flag             = 'Y'       -- ON
        AND    xola_out_om2.delete_flag                      = 'N'       -- OFF
        AND    xoha_out_om2.schedule_ship_date              <= TRUNC( SYSDATE )
        AND    xrpm_out_om2.shipment_provision_div           = '2'       -- �x���˗�
        AND    xoha_out_om2.order_type_id                    = otta_out_om2.transaction_type_id
        AND    xrpm_out_om2.shipment_provision_div           = otta_out_om2.attribute1
--mod start 2008/06/04 rev1.4
--        AND    xicv_out_om2.item_id                          = ximv_out_om2.item_id
        AND    xicv_out_om2_s.item_id                        = ximv_out_om2_s.item_id
        AND    xicv_out_om2_r.item_id                        = ximv_out_om2_r.item_id
--mod end 2008/06/04 rev1.4
--mod start 2008/06/04
--        AND    NVL(xrpm_out_om2.item_div_ahead, xicv_out_om2.item_class_code)
--                                                             = xicv_out_om2.item_class_code
--        AND    NVL(xrpm_out_om2.item_div_origin, xicv_out_om2.item_class_code)
--                                                             = xicv_out_om2.item_class_code
        AND    NVL(xrpm_out_om2.item_div_origin,'Dummy')     = DECODE(xicv_out_om2_s.item_class_code,'5','5','Dummy') --�U�֌��i�ڋ敪 = �o�וi�ڋ敪
        AND    NVL(xrpm_out_om2.item_div_ahead ,'Dummy')     = DECODE(xicv_out_om2_r.item_class_code,'5','5','Dummy') --�U�֐�i�ڋ敪 = �˗��i�ڋ敪
        AND   (xrpm_out_om2.ship_prov_rcv_pay_category       = otta_out_om2.attribute11
        OR     xrpm_out_om2.ship_prov_rcv_pay_category      IS NULL)
--mod start 2008/06/10
        AND  ( (xola_out_om2.shipping_inventory_item_id      = xola_out_om2.request_item_id
          AND   xrpm_out_om2.prod_div_origin                IS NULL
          AND   xrpm_out_om2.prod_div_ahead                 IS NULL )
        OR     (xola_out_om2.shipping_inventory_item_id     <> xola_out_om2.request_item_id
          AND   xicv_out_om2_s.item_class_code               = '5'
          AND   xicv_out_om2_r.item_class_code               = '5'
          AND   xrpm_out_om2.prod_div_origin                IS NOT NULL
          AND   xrpm_out_om2.prod_div_ahead                 IS NOT NULL )
        OR     (xola_out_om2.shipping_inventory_item_id     <> xola_out_om2.request_item_id
          AND  (xicv_out_om2_s.item_class_code              <> '5'
          OR    xicv_out_om2_r.item_class_code              <> '5')
          AND   xrpm_out_om2.prod_div_origin                IS NULL
          AND   xrpm_out_om2.prod_div_ahead                 IS NULL) )
--mod end   2008/06/10
--mod end 2008/06/04
        AND    flv_out_om2.lookup_type                       = 'XXCMN_NEW_DIVISION'
        AND    flv_out_om2.language                          = 'JA'
        AND    flv_out_om2.lookup_code                       = xrpm_out_om2.new_div_invent
--mod start 2008/06/04 rev1.3
--        AND    xoha_out_om2.deliver_to_id                    = xpsv_out_om2.party_site_id
        AND    xvsv_out_om2.vendor_site_id                   = xoha_out_om2.vendor_site_id
--mod end 2008/06/04 rev1.3
        UNION ALL
        -- ���Y���������\��
        SELECT xilv_out_pr.whse_code
              ,xilv_out_pr.mtl_organization_id
              ,xilv_out_pr.customer_stock_whse
              ,xilv_out_pr.inventory_location_id
              ,xilv_out_pr.segment1
              ,xilv_out_pr.description
              ,ximv_out_pr.item_id
              ,ximv_out_pr.item_no
              ,ximv_out_pr.item_name
              ,ximv_out_pr.item_short_name
              ,ximv_out_pr.num_of_cases
              ,ilm_out_pr.lot_id
              ,ilm_out_pr.lot_no
              ,ilm_out_pr.attribute1
              ,ilm_out_pr.attribute2
              ,ilm_out_pr.attribute3                                    -- <---- �����܂ŋ���
              ,gbh_out_pr.plan_start_date
              ,gbh_out_pr.plan_start_date
              ,'1'                                     AS status       -- �\��
              ,xrpm_out_pr.new_div_invent
              ,flv_out_pr.meaning
              ,gbh_out_pr.batch_no
              ,grb_out_pr.routing_id
--mod start 2008/06/07
--              ,grb_out_pr.routing_desc
              ,grt_out_pr.routing_desc
--mod end 2008/06/07
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,0                                       AS stock_quantity
--mod start 2008/06/10
--              ,xmd_out_pr.instructions_qty
              ,xmld_out_pr.actual_quantity             AS leaving_quantity
--mod end 2008/06/10
              ,ximv_out_pr.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_pr                 -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_out_pr                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_pr                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_pr                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_pr                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,gme_batch_header             gbh_out_pr                  -- ���Y�o�b�`
              ,gme_material_details         gmd_out_pr                  -- ���Y�����ڍ�
--del start 2008/06/10
--              ,xxwip_material_detail        xmd_out_pr                  -- ���Y�����ڍ�(�A�h�I��)
--del end 2008/06/10
              ,gmd_routings_b               grb_out_pr                  -- �H���}�X�^
--mod start 2008/06/07
              ,gmd_routings_tl              grt_out_pr                  -- �H���}�X�^���{��
--mod end 2008/06/07
              ,xxinv_mov_lot_details        xmld_out_pr                 -- �ړ����b�g�ڍ�(�A�h�I��)
--del start 2008/06/10
--              ,ic_tran_pnd                  itp_out_pr                  -- OPM�ۗ��݌Ƀg�����U�N�V����
--del end 2008/06/10
        WHERE  xrpm_out_pr.doc_type                = 'PROD'
        AND    xrpm_out_pr.use_div_invent          = 'Y'
--        AND    itp_out_pr.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
        AND    gbh_out_pr.batch_id                 = gmd_out_pr.batch_id
--mod start 2008/06/10
--        AND    gmd_out_pr.batch_id                 = xmd_out_pr.batch_id
--        AND    gmd_out_pr.material_detail_id       = xmd_out_pr.material_detail_id
--mod end 2008/06/10
        AND    gmd_out_pr.material_detail_id       = xmld_out_pr.mov_line_id
        AND    gmd_out_pr.line_type                = -1                 -- �����i
--        AND    itp_out_pr.doc_type                 = xrpm_out_pr.doc_type
--        AND    itp_out_pr.doc_id                   = gmd_out_pr.batch_id
--        AND    itp_out_pr.doc_line                 = gmd_out_pr.line_no
--        AND    itp_out_pr.line_type                = gmd_out_pr.line_type
--        AND    itp_out_pr.completed_ind            = 0
        AND    gmd_out_pr.material_detail_id       = xmld_out_pr.mov_line_id
--mod start 2008/06/09
        AND    xmld_out_pr.document_type_code      = '40'
        AND    xmld_out_pr.record_type_code        = '10'
--mod end   2008/06/09
        AND    gmd_out_pr.item_id                  = ximv_out_pr.item_id
        AND    ilm_out_pr.item_id                  = ximv_out_pr.item_id
--mod start 2008/06/10
--        AND (( ximv_out_pr.lot_ctl                 = 1                  -- ���b�g�Ǘ��i
--           AND xmld_out_pr.lot_id                  = ilm_out_pr.lot_id )
--          OR ( ximv_out_pr.lot_ctl                 = 0                  -- �񃍃b�g�Ǘ��i
--           AND xmd_out_pr.plan_type                = '4' ))             -- ����
        AND xmld_out_pr.lot_id                     = ilm_out_pr.lot_id
---mod end 2008/06/10
        AND    grb_out_pr.attribute9               = xilv_out_pr.segment1
        AND    NOT EXISTS( SELECT 'X'
                           FROM   gme_batch_header gbh_out_pr_ex
                           WHERE  gbh_out_pr_ex.batch_id      = gbh_out_pr.batch_id
                           AND    gbh_out_pr_ex.batch_status IN ( 7     -- ����
                                                                 ,8     -- �N���[�Y
                                                                 ,-1 )) -- ���
        AND    gbh_out_pr.plan_start_date         <= TRUNC( SYSDATE )
        AND    grb_out_pr.routing_id               = gbh_out_pr.routing_id
        AND    xrpm_out_pr.routing_class           = grb_out_pr.routing_class
        AND    xrpm_out_pr.line_type               = gmd_out_pr.line_type
--mod start 2008/06/23
--        AND (( gmd_out_pr.attribute5              IS NULL )
--          OR ( xrpm_out_pr.hit_in_div              = gmd_out_pr.attribute5 ) )
        AND ((( gmd_out_pr.attribute5              IS NULL )
          AND ( xrpm_out_pr.hit_in_div             IS NULL ))
        OR   (( gmd_out_pr.attribute5              IS NOT NULL )
          AND ( xrpm_out_pr.hit_in_div             = gmd_out_pr.attribute5 )))
--mod start 2008/06/23
        AND    flv_out_pr.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_out_pr.language                 = 'JA'
        AND    flv_out_pr.lookup_code              = xrpm_out_pr.new_div_invent
--mod start 2008/06/07
        AND    grb_out_pr.routing_id               = grt_out_pr.routing_id
        AND    grt_out_pr.language                 = 'JA'
--mod end 2008/06/07
        UNION ALL
        -- �����݌ɏo�ɗ\��
        SELECT xilv_out_ad.whse_code
              ,xilv_out_ad.mtl_organization_id
              ,xilv_out_ad.customer_stock_whse
              ,xilv_out_ad.inventory_location_id
              ,xilv_out_ad.segment1
              ,xilv_out_ad.description
              ,ximv_out_ad.item_id
              ,ximv_out_ad.item_no
              ,ximv_out_ad.item_name
              ,ximv_out_ad.item_short_name
              ,ximv_out_ad.num_of_cases
              ,ilm_out_ad.lot_id
              ,ilm_out_ad.lot_no
              ,ilm_out_ad.attribute1
              ,ilm_out_ad.attribute2
              ,ilm_out_ad.attribute3                                     -- <---- �����܂ŋ���
              ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) AS arrival_date
              ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) AS leaving_date
              ,'1'                                            AS status        -- �\��
              ,xrpm_out_ad.new_div_invent
              ,flv_out_ad.meaning
              ,NULL                                           AS voucher_no
--mod start 2008/06/06
--              ,TO_NUMBER( pla_out_ad.attribute12 )
              ,xilv_out_ad.inventory_location_id              AS ukebaraisaki_id
--mod end 2008/06/06
              ,xilv_out_ad.description
              ,NULL                                           AS deliver_to_id
              ,NULL                                           AS deliver_to_name
              ,0                                              AS stock_quantity
--mod start 2008/06/05 rev1.6
--              ,itc_out_ad.trans_qty
              ,pla_out_ad.quantity                            AS leaving_quantity
--mod end 2008/06/05 rev1.6
              ,ximv_out_ad.lot_ctl
        FROM   xxcmn_item_locations_v  xilv_out_ad                       -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v        ximv_out_ad                       -- OPM�i�ڏ��VIEW
              ,ic_lots_mst             ilm_out_ad                        -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst       xrpm_out_ad                       -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values       flv_out_ad                        -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,po_headers_all          pha_out_ad                        -- �����w�b�_
              ,po_lines_all            pla_out_ad                        -- ��������
--del start 2008/06/05 rev1.6
--              ,rcv_shipment_lines      rsl_out_ad                        -- �������
--              ,rcv_transactions        rt_out_ad                         -- ������
--del end 2008/06/05 rev1.6
              ,xxinv_mov_lot_details   xmld_out_ad                       -- �ړ����b�g�ڍ�(�A�h�I��)
--del start 2008/06/05 rev1.6
--              ,ic_tran_cmp             itc_out_ad                        -- OPM�����݌Ƀg�����U�N�V����
--del end 2008/06/05 rev1.6
        WHERE  xrpm_out_ad.doc_type             = 'ADJI'
        AND    xrpm_out_ad.reason_code          = 'X977'                 -- �����݌�
        AND    xrpm_out_ad.rcv_pay_div          = '-1'                   -- ���o
        AND    xrpm_out_ad.use_div_invent       = 'Y'
--mod start 2008/06/05 rev1.9
--        AND    pha_out_ad.po_header_id          = pha_out_ad.po_header_id
        AND    pha_out_ad.po_header_id          = pla_out_ad.po_header_id
--mod end 2008/06/05 rev1.9
--del start 2008/06/05 rev1.6
--        AND    itc_out_ad.reason_code           = xrpm_out_ad.reason_code
--        AND    SIGN( itc_out_ad.trans_qty )     = xrpm_out_ad.rcv_pay_div
--del end 2008/06/05 rev1.6
        AND    pha_out_ad.attribute1           IN ( '20'                 -- �����쐬��
                                                   ,'25' )               -- �������
        AND    pla_out_ad.attribute13           = 'N'                    -- ������
--mod start 2008/06/06
        AND    pha_out_ad.attribute11           = '3'
--mod end 2008/06/06
        AND    pla_out_ad.po_line_id            = xmld_out_ad.mov_line_id
        AND    pla_out_ad.item_id               = ximv_out_ad.inventory_item_id
        AND    ilm_out_ad.item_id               = ximv_out_ad.item_id
        AND    ilm_out_ad.lot_id                = xmld_out_ad.lot_id
--mod start 2008/06/09
        AND    xmld_out_ad.document_type_code   = '50'
        AND    xmld_out_ad.record_type_code     = '10'
--mod end   2008/06/09
        AND    pla_out_ad.attribute12           = xilv_out_ad.segment1
        AND    TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' )
                                               <= TRUNC( SYSDATE )
--del start 2008/06/05 rev1.6
--        AND    rsl_out_ad.po_header_id          = pha_out_ad.po_header_id
--        AND    rsl_out_ad.po_line_id            = pla_out_ad.po_line_id
--        AND    rt_out_ad.shipment_line_id       = rsl_out_ad.shipment_line_id
--        AND    rt_out_ad.destination_type_code  = rsl_out_ad.destination_type_code
--        AND    itc_out_ad.item_id               = xmld_out_ad.item_id
--        AND    itc_out_ad.lot_id                = xmld_out_ad.lot_id
--        AND    itc_out_ad.whse_code             = xilv_out_ad.whse_code
--        AND    itc_out_ad.location              = xilv_out_ad.segment1
--del end 2008/06/05 rev1.6
        AND    flv_out_ad.lookup_type           = 'XXCMN_NEW_DIVISION'
        AND    flv_out_ad.language              = 'JA'
        AND    flv_out_ad.lookup_code           = xrpm_out_ad.new_div_invent
        UNION ALL
        ------------------------------------------------------------------------
        -- ���Ɏ���
        ------------------------------------------------------------------------
        --�����������
        SELECT xilv_in_po_e.whse_code
              ,xilv_in_po_e.mtl_organization_id
              ,xilv_in_po_e.customer_stock_whse
              ,xilv_in_po_e.inventory_location_id
              ,xilv_in_po_e.segment1
              ,xilv_in_po_e.description
              ,ximv_in_po_e.item_id
              ,ximv_in_po_e.item_no
              ,ximv_in_po_e.item_name
              ,ximv_in_po_e.item_short_name
              ,ximv_in_po_e.num_of_cases
              ,ilm_in_po_e.lot_id
              ,ilm_in_po_e.lot_no
              ,ilm_in_po_e.attribute1
              ,ilm_in_po_e.attribute2
              ,ilm_in_po_e.attribute3                                     -- <---- �����܂ŋ���
              ,xrart_in_po_e.txns_date
              ,xrart_in_po_e.txns_date
              ,'2'                                           AS status        -- ����
              ,xrpm_in_po_e.new_div_invent
              ,flv_in_po_e.meaning
              ,pha_in_po_e.segment1
              ,pha_in_po_e.vendor_id
              ,xvv_in_po_e.vendor_full_name
              ,NULL                                          AS deliver_to_id
              ,NULL                                          AS deliver_to_name
              ,xrart_in_po_e.quantity
              ,0                                             AS leaving_quantity
              ,ximv_in_po_e.lot_ctl
        FROM   xxcmn_item_locations_v  xilv_in_po_e                       -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v        ximv_in_po_e                       -- OPM�i�ڏ��VIEW
              ,ic_lots_mst             ilm_in_po_e                        -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst       xrpm_in_po_e                       -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values       flv_in_po_e                        -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,po_headers_all          pha_in_po_e                        -- �����w�b�_
              ,po_lines_all            pla_in_po_e                        -- ��������
              ,xxpo_rcv_and_rtn_txns   xrart_in_po_e                      -- ����ԕi����(�A�h�I��)
              ,rcv_shipment_lines      rsl_in_po_e                        -- �������
              ,rcv_transactions        rt_in_po_e                         -- ������
              ,xxcmn_vendors_v         xvv_in_po_e                        -- �d������VIEW
        WHERE  xrpm_in_po_e.doc_type             = 'PORC'
        AND    xrpm_in_po_e.source_document_code = 'PO'
        AND    xrpm_in_po_e.use_div_invent       = 'Y'
        AND    pha_in_po_e.po_header_id          = pla_in_po_e.po_header_id
        AND    pha_in_po_e.attribute5            = xilv_in_po_e.segment1
        AND    pla_in_po_e.item_id               = ximv_in_po_e.inventory_item_id
        AND    ilm_in_po_e.lot_no                = pla_in_po_e.attribute1(+)
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
        AND    rt_in_po_e.shipment_line_id       = rsl_in_po_e.shipment_line_id
        AND    rt_in_po_e.destination_type_code  = rsl_in_po_e.destination_type_code
        AND    xrpm_in_po_e.transaction_type     = rt_in_po_e.transaction_type
        AND    flv_in_po_e.lookup_type           = 'XXCMN_NEW_DIVISION'
        AND    flv_in_po_e.language              = 'JA'
        AND    flv_in_po_e.lookup_code           = xrpm_in_po_e.new_div_invent
        AND    xvv_in_po_e.vendor_id             = pha_in_po_e.vendor_id
        UNION ALL
        -- �ړ����Ɏ���(�ϑ�����)
        SELECT xilv_in_xf_e.whse_code
              ,xilv_in_xf_e.mtl_organization_id
              ,xilv_in_xf_e.customer_stock_whse
              ,xilv_in_xf_e.inventory_location_id
              ,xilv_in_xf_e.segment1
              ,xilv_in_xf_e.description
              ,ximv_in_xf_e.item_id
              ,ximv_in_xf_e.item_no
              ,ximv_in_xf_e.item_name
              ,ximv_in_xf_e.item_short_name
              ,ximv_in_xf_e.num_of_cases
              ,ilm_in_xf_e.lot_id
              ,ilm_in_xf_e.lot_no
              ,ilm_in_xf_e.attribute1
              ,ilm_in_xf_e.attribute2
              ,ilm_in_xf_e.attribute3                                      -- <---- �����܂ŋ���
              ,xmrih_in_xf_e.actual_arrival_date
              ,xmrih_in_xf_e.actual_ship_date
              ,'2'                                     AS status           -- ����
              ,xrpm_in_xf_e.new_div_invent
              ,flv_in_xf_e.meaning
              ,xmrih_in_xf_e.mov_num
              ,xmrih_in_xf_e.shipped_locat_id
              ,xilv_in_xf_e2.description
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,xmld_in_xf_e.actual_quantity            AS stock_quantity
              ,0                                       AS leaving_quantity
              ,ximv_in_xf_e.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_xf_e                   -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_locations_v       xilv_in_xf_e2                  -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_in_xf_e                   -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_xf_e                    -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_xf_e                   -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_xf_e                    -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_in_xf_e                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_in_xf_e                  -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_in_xf_e                   -- �ړ����b�g�ڍ�(�A�h�I��)
        WHERE  xrpm_in_xf_e.doc_type                = 'XFER'               -- �ړ��ϑ�����
        AND    xrpm_in_xf_e.use_div_invent          = 'Y'
        AND    xrpm_in_xf_e.rcv_pay_div             = '1'
        AND    xmrih_in_xf_e.mov_hdr_id             = xmril_in_xf_e.mov_hdr_id
        AND    xmril_in_xf_e.item_id                = ximv_in_xf_e.item_id
        AND    xmrih_in_xf_e.ship_to_locat_id       = xilv_in_xf_e.inventory_location_id
        AND    xmrih_in_xf_e.shipped_locat_id       = xilv_in_xf_e2.inventory_location_id
        AND    ilm_in_xf_e.item_id                  = xmril_in_xf_e.item_id
        AND    ilm_in_xf_e.lot_id                   = xmld_in_xf_e.lot_id
        AND    xmld_in_xf_e.mov_line_id             = xmril_in_xf_e.mov_line_id
        AND    xmld_in_xf_e.document_type_code      = '20'                 -- �ړ�
        AND    xmld_in_xf_e.record_type_code        = '30'                 -- ���Ɏ���
        AND    xmrih_in_xf_e.mov_type               = '1'                  -- �ϑ�����
        AND    xmril_in_xf_e.delete_flg             = 'N'                  -- OFF
        AND    xmrih_in_xf_e.status                IN ( '06'               -- ���o�ɕ񍐗L
                                                       ,'05' )             -- ���ɕ񍐗L
        AND    flv_in_xf_e.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_in_xf_e.language                 = 'JA'
        AND    flv_in_xf_e.lookup_code              = xrpm_in_xf_e.new_div_invent
        UNION ALL
        -- �ړ����Ɏ���(�ϑ��Ȃ�)
        SELECT xilv_in_tr_e.whse_code
              ,xilv_in_tr_e.mtl_organization_id
              ,xilv_in_tr_e.customer_stock_whse
              ,xilv_in_tr_e.inventory_location_id
              ,xilv_in_tr_e.segment1
              ,xilv_in_tr_e.description
              ,ximv_in_tr_e.item_id
              ,ximv_in_tr_e.item_no
              ,ximv_in_tr_e.item_name
              ,ximv_in_tr_e.item_short_name
              ,ximv_in_tr_e.num_of_cases
              ,ilm_in_tr_e.lot_id
              ,ilm_in_tr_e.lot_no
              ,ilm_in_tr_e.attribute1
              ,ilm_in_tr_e.attribute2
              ,ilm_in_tr_e.attribute3                                   -- <---- �����܂ŋ���
              ,xmrih_in_tr_e.actual_arrival_date
              ,xmrih_in_tr_e.actual_ship_date
              ,'2'                                     AS status        -- ����
              ,xrpm_in_tr_e.new_div_invent
              ,flv_in_tr_e.meaning
              ,xmrih_in_tr_e.mov_num
              ,xmrih_in_tr_e.shipped_locat_id
              ,xilv_in_tr_e2.description
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,xmld_in_tr_e.actual_quantity            AS stock_quantity
              ,0                                       AS leaving_quantity
              ,ximv_in_tr_e.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_tr_e                -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_locations_v       xilv_in_tr_e2               -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_in_tr_e                -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_tr_e                 -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_tr_e                -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_tr_e                 -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_in_tr_e               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_in_tr_e               -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_in_tr_e                -- �ړ����b�g�ڍ�(�A�h�I��)
        WHERE  xrpm_in_tr_e.doc_type                = 'TRNI'            -- �ړ��ϑ��Ȃ�
        AND    xrpm_in_tr_e.use_div_invent          = 'Y'
        AND    xrpm_in_tr_e.rcv_pay_div             = '1'
        AND    xmrih_in_tr_e.mov_hdr_id             = xmril_in_tr_e.mov_hdr_id
        AND    xmril_in_tr_e.item_id                = ximv_in_tr_e.item_id
        AND    xmrih_in_tr_e.ship_to_locat_id       = xilv_in_tr_e.inventory_location_id
        AND    xmrih_in_tr_e.shipped_locat_id       = xilv_in_tr_e2.inventory_location_id
        AND    ilm_in_tr_e.item_id                  = xmril_in_tr_e.item_id
        AND    ilm_in_tr_e.lot_id                   = xmld_in_tr_e.lot_id
        AND    xmld_in_tr_e.mov_line_id             = xmril_in_tr_e.mov_line_id
        AND    xmld_in_tr_e.document_type_code      = '20'              -- �ړ�
        AND    xmld_in_tr_e.record_type_code        = '30'              -- ���Ɏ���
        AND    xmrih_in_tr_e.mov_type               = '2'               -- �ϑ��Ȃ�
        AND    xmrih_in_tr_e.status                 = '06'              -- ���o�ɕ񍐗L
        AND    xmril_in_tr_e.delete_flg             = 'N'               -- OFF
        AND    flv_in_tr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_in_tr_e.language                 = 'JA'
        AND    flv_in_tr_e.lookup_code              = xrpm_in_tr_e.new_div_invent
/*
        -- �ړ����Ɏ���(�ϑ�����)
        SELECT xilv_in_xf_e.whse_code
              ,xilv_in_xf_e.mtl_organization_id
              ,xilv_in_xf_e.customer_stock_whse
              ,xilv_in_xf_e.inventory_location_id
              ,xilv_in_xf_e.segment1
              ,xilv_in_xf_e.description
              ,ximv_in_xf_e.item_id
              ,ximv_in_xf_e.item_no
              ,ximv_in_xf_e.item_name
              ,ximv_in_xf_e.item_short_name
              ,ximv_in_xf_e.num_of_cases
              ,ilm_in_xf_e.lot_id
              ,ilm_in_xf_e.lot_no
              ,ilm_in_xf_e.attribute1
              ,ilm_in_xf_e.attribute2
              ,ilm_in_xf_e.attribute3                                      -- <---- �����܂ŋ���
              ,xmrih_in_xf_e.actual_arrival_date
              ,xmrih_in_xf_e.actual_ship_date
              ,'2'                                     AS status           -- ����
              ,xrpm_in_xf_e.new_div_invent
              ,flv_in_xf_e.meaning
              ,xmrih_in_xf_e.mov_num
              ,xmrih_in_xf_e.shipped_locat_id
              ,xilv_in_xf_e.description
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
--mod start 2008/06/05 rev1.5
--              ,CASE
--                WHEN ( ximv_in_xf_e.lot_ctl = 1 ) THEN
--                  xmld_in_xf_e.actual_quantity                             -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_in_xf_e.lot_ctl = 0  ) THEN
--                  xmril_in_xf_e.ship_to_quantity                           -- �񃍃b�g�Ǘ��i(���Ɏ��ѐ���)
--               END                                        stock_quantity
--
--              ,xmld_in_xf_e.actual_quantity            stock_quantity
              ,itp_in_xf_e.trans_qty                   AS stock_quantity
--mod end 2008/06/05 rev1.5
              ,0                                       AS leaving_quantity
              ,ximv_in_xf_e.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_xf_e                   -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_in_xf_e                   -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_xf_e                    -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_xf_e                   -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_xf_e                    -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_in_xf_e                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_in_xf_e                  -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_in_xf_e                   -- �ړ����b�g�ڍ�(�A�h�I��)
              ,ic_tran_pnd                  itp_in_xf_e                    -- OPM�ۗ��݌Ƀg�����U�N�V����
              ,ic_xfer_mst                  ixm_in_xf_e                    -- OPM�݌ɓ]���}�X�^
        WHERE  xrpm_in_xf_e.doc_type                = 'XFER'               -- �ړ��ϑ�����
        AND    xrpm_in_xf_e.use_div_invent          = 'Y'
        AND    itp_in_xf_e.delete_mark              = 0                    -- �L���`�F�b�N(OPM�ۗ��݌�)
        AND    xmrih_in_xf_e.mov_hdr_id             = xmril_in_xf_e.mov_hdr_id
        AND    xmril_in_xf_e.item_id                = ximv_in_xf_e.item_id
--mod start 2008/06/04 rev1.1
--        AND    xmrih_in_xf_e.ship_to_locat_id       = xilv_in_xf_e.segment1
        AND    xmrih_in_xf_e.ship_to_locat_id       = xilv_in_xf_e.inventory_location_id
--mod end 2008/06/04 rev1.1
--mod start 2008/06/09
--        AND    ilm_in_xf_e.item_id                  = ximv_in_xf_e.item_id
        AND    ilm_in_xf_e.item_id                  = xmril_in_xf_e.item_id
        AND    ilm_in_xf_e.lot_id                   = xmld_in_xf_e.lot_id
--mod end 2008/06/09
        AND    xmld_in_xf_e.mov_line_id             = xmril_in_xf_e.mov_line_id
        AND    xmld_in_xf_e.document_type_code      = '20'                 -- �ړ�
        AND    xmld_in_xf_e.record_type_code        = '30'                 -- ���Ɏ���
        AND    xmrih_in_xf_e.mov_type               = '1'                  -- �ϑ�����
        AND    xmril_in_xf_e.delete_flg             = 'N'                  -- OFF
        AND    xmrih_in_xf_e.status                IN ( '06'               -- ���o�ɕ񍐗L
                                                       ,'05' )             -- ���ɕ񍐗L
        AND    TO_NUMBER( ixm_in_xf_e.attribute1 )  = xmril_in_xf_e.mov_line_id
        AND    itp_in_xf_e.doc_type                 = xrpm_in_xf_e.doc_type
        AND    itp_in_xf_e.doc_id                   = ixm_in_xf_e.transfer_id
        AND    itp_in_xf_e.completed_ind            = 1
        AND    itp_in_xf_e.whse_code                = xilv_in_xf_e.whse_code
        AND    itp_in_xf_e.item_id                  = ximv_in_xf_e.item_id
        AND    itp_in_xf_e.lot_id                   = ilm_in_xf_e.lot_id
        AND    xrpm_in_xf_e.reason_code             = itp_in_xf_e.reason_code
        AND    xrpm_in_xf_e.rcv_pay_div             = SIGN( itp_in_xf_e.trans_qty )
        AND    flv_in_xf_e.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_in_xf_e.language                 = 'JA'
        AND    flv_in_xf_e.lookup_code              = xrpm_in_xf_e.new_div_invent
        UNION ALL
        -- �ړ����Ɏ���(�ϑ��Ȃ�)
        SELECT xilv_in_tr_e.whse_code
              ,xilv_in_tr_e.mtl_organization_id
              ,xilv_in_tr_e.customer_stock_whse
              ,xilv_in_tr_e.inventory_location_id
              ,xilv_in_tr_e.segment1
              ,xilv_in_tr_e.description
              ,ximv_in_tr_e.item_id
              ,ximv_in_tr_e.item_no
              ,ximv_in_tr_e.item_name
              ,ximv_in_tr_e.item_short_name
              ,ximv_in_tr_e.num_of_cases
              ,ilm_in_tr_e.lot_id
              ,ilm_in_tr_e.lot_no
              ,ilm_in_tr_e.attribute1
              ,ilm_in_tr_e.attribute2
              ,ilm_in_tr_e.attribute3                                   -- <---- �����܂ŋ���
              ,xmrih_in_tr_e.actual_arrival_date
              ,xmrih_in_tr_e.actual_ship_date
              ,'2'                                     AS status        -- ����
              ,xrpm_in_tr_e.new_div_invent
              ,flv_in_tr_e.meaning
              ,xmrih_in_tr_e.mov_num
              ,xmrih_in_tr_e.shipped_locat_id
              ,xilv_in_tr_e.description
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
--mod start 2008/06/05 rev1.5
--              ,CASE
--                WHEN ( ximv_in_tr_e.lot_ctl = 1 ) THEN
--                  xmld_in_tr_e.actual_quantity                          -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_in_tr_e.lot_ctl = 0  ) THEN
--                  xmril_in_tr_e.ship_to_quantity                        -- �񃍃b�g�Ǘ��i(���Ɏ��ѐ���)
--               END                                        stock_quantity
--              ,xmld_in_tr_e.actual_quantity            stock_quantity
              ,itc_in_tr_e.trans_qty                   AS stock_quantity
--mod end 2008/06/05 rev1.5
              ,0                                       AS leaving_quantity
              ,ximv_in_tr_e.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_tr_e                -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_in_tr_e                -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_tr_e                 -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_tr_e                -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_tr_e                 -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_in_tr_e               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_in_tr_e               -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_in_tr_e                -- �ړ����b�g�ڍ�(�A�h�I��)
              ,ic_tran_cmp                  itc_in_tr_e                 -- OPM�����݌Ƀg�����U�N�V����
              ,ic_adjs_jnl                  iaj_in_tr_e                 -- OPM�݌ɒ����W���[�i��
              ,ic_jrnl_mst                  ijm_in_tr_e                 -- OPM�W���[�i���}�X�^
        WHERE  xrpm_in_tr_e.doc_type                = 'TRNI'            -- �ړ��ϑ��Ȃ�
        AND    xrpm_in_tr_e.use_div_invent          = 'Y'
        AND    xmrih_in_tr_e.mov_hdr_id             = xmril_in_tr_e.mov_hdr_id
        AND    xmril_in_tr_e.item_id                = ximv_in_tr_e.item_id
--mod start 2008/06/04 rev1.1
--        AND    xmrih_in_tr_e.ship_to_locat_id       = xilv_in_tr_e.segment1
        AND    xmrih_in_tr_e.ship_to_locat_id       = xilv_in_tr_e.inventory_location_id
--mod end 2008/06/04 rev1.1
--mod start 2008/06/09
--        AND    ilm_in_tr_e.item_id                  = ximv_in_tr_e.item_id
        AND    ilm_in_tr_e.item_id                  = xmril_in_tr_e.item_id
        AND    ilm_in_tr_e.lot_id                   = xmld_in_tr_e.lot_id
--mod end 2008/06/09
        AND    xmld_in_tr_e.mov_line_id             = xmril_in_tr_e.mov_line_id
        AND    xmld_in_tr_e.document_type_code      = '20'              -- �ړ�
        AND    xmld_in_tr_e.record_type_code        = '30'              -- ���Ɏ���
        AND    xmrih_in_tr_e.mov_type               = '2'               -- �ϑ��Ȃ�
        AND    xmrih_in_tr_e.status                 = '06'              -- ���o�ɕ񍐗L
        AND    xmril_in_tr_e.delete_flg             = 'N'               -- OFF
        AND    TO_NUMBER( ijm_in_tr_e.attribute1 )  = xmril_in_tr_e.mov_line_id
        AND    iaj_in_tr_e.journal_id               = ijm_in_tr_e.journal_id
        AND    itc_in_tr_e.doc_type                 = iaj_in_tr_e.trans_type
        AND    itc_in_tr_e.doc_id                   = iaj_in_tr_e.doc_id
        AND    itc_in_tr_e.doc_line                 = iaj_in_tr_e.doc_line
--mod start 2008/06/05 
--        AND    itc_in_tr_e.whse_code                = xilv_in_tr_e.whse_code
        AND    itc_in_tr_e.location                 = xilv_in_tr_e.segment1
--mod end   2008/06/05 
        AND    itc_in_tr_e.item_id                  = ximv_in_tr_e.item_id
        AND    itc_in_tr_e.lot_id                   = ilm_in_tr_e.lot_id
        AND    xrpm_in_tr_e.doc_type                = itc_in_tr_e.doc_type
        AND    xrpm_in_tr_e.reason_code             = itc_in_tr_e.reason_code
        AND    xrpm_in_tr_e.rcv_pay_div             = SIGN( itc_in_tr_e.trans_qty )
        AND    flv_in_tr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_in_tr_e.language                 = 'JA'
        AND    flv_in_tr_e.lookup_code              = xrpm_in_tr_e.new_div_invent
*/
        UNION ALL
        -- ���Y���Ɏ���
        SELECT xilv_in_pr_e.whse_code
              ,xilv_in_pr_e.mtl_organization_id
              ,xilv_in_pr_e.customer_stock_whse
              ,xilv_in_pr_e.inventory_location_id
              ,xilv_in_pr_e.segment1
              ,xilv_in_pr_e.description
              ,ximv_in_pr_e.item_id
              ,ximv_in_pr_e.item_no
              ,ximv_in_pr_e.item_name
              ,ximv_in_pr_e.item_short_name
              ,ximv_in_pr_e.num_of_cases
              ,ilm_in_pr_e.lot_id
              ,ilm_in_pr_e.lot_no
              ,ilm_in_pr_e.attribute1
              ,ilm_in_pr_e.attribute2
              ,ilm_in_pr_e.attribute3                                    -- <---- �����܂ŋ���
              ,itp_in_pr_e.trans_date
              ,itp_in_pr_e.trans_date
              ,'2'                                     AS status         -- ����
              ,xrpm_in_pr_e.new_div_invent
              ,flv_in_pr_e.meaning
              ,gbh_in_pr_e.batch_no
              ,grb_in_pr_e.routing_id
--mod start 2008/06/07
--              ,grb_in_pr_e.routing_desc
              ,grt_in_pr_e.routing_desc
--mod end 2008/06/07
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,itp_in_pr_e.trans_qty
              ,0                                       AS leaving_quantity
              ,ximv_in_pr_e.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_pr_e                 -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_in_pr_e                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_pr_e                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_pr_e                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_pr_e                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,gme_batch_header             gbh_in_pr_e                  -- ���Y�o�b�`
              ,gme_material_details         gmd_in_pr_e                  -- ���Y�����ڍ�
              ,gmd_routings_b               grb_in_pr_e                  -- �H���}�X�^
--mod start 2008/06/07
              ,gmd_routings_tl              grt_in_pr_e                  -- �H���}�X�^���{��
              ,gmd_routing_class_b          grcb_in_pr_e                 -- �H���敪�}�X�^
              ,gmd_routing_class_tl         grct_in_pr_e                 -- �H���敪�}�X�^���{��
--mod end 2008/06/07
              ,ic_tran_pnd                  itp_in_pr_e                  -- OPM�ۗ��݌Ƀg�����U�N�V����
        WHERE  xrpm_in_pr_e.doc_type                = 'PROD'
        AND    xrpm_in_pr_e.use_div_invent          = 'Y'
        AND    itp_in_pr_e.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
        AND    gbh_in_pr_e.batch_id                 = gmd_in_pr_e.batch_id
        AND    gmd_in_pr_e.line_type               IN ( 1                -- �����i
                                                       ,2 )              -- ���Y��
        AND    itp_in_pr_e.doc_type                 = xrpm_in_pr_e.doc_type
        AND    itp_in_pr_e.doc_id                   = gmd_in_pr_e.batch_id
        AND    itp_in_pr_e.doc_line                 = gmd_in_pr_e.line_no
        AND    itp_in_pr_e.line_type                = gmd_in_pr_e.line_type
        AND    itp_in_pr_e.completed_ind            = 1
        AND    itp_in_pr_e.reverse_id              IS NULL
        AND    itp_in_pr_e.item_id                  = ximv_in_pr_e.item_id
        AND    itp_in_pr_e.lot_id                   = ilm_in_pr_e.lot_id
        AND    itp_in_pr_e.location                 = xilv_in_pr_e.segment1
        AND    gmd_in_pr_e.item_id                  = ximv_in_pr_e.item_id
        AND    ilm_in_pr_e.item_id                  = ximv_in_pr_e.item_id
        AND    grb_in_pr_e.attribute9               = xilv_in_pr_e.segment1
        AND    grb_in_pr_e.routing_id               = gbh_in_pr_e.routing_id
        AND    xrpm_in_pr_e.routing_class           = grb_in_pr_e.routing_class
        AND    xrpm_in_pr_e.line_type               = gmd_in_pr_e.line_type
--mod start 2008/06/23
--        AND (( gmd_in_pr_e.attribute5              IS NULL )
--          OR ( xrpm_in_pr_e.hit_in_div              = gmd_in_pr_e.attribute5 ))
        AND ((( gmd_in_pr_e.attribute5              IS NULL )
          AND ( xrpm_in_pr_e.hit_in_div             IS NULL ))
        OR   (( gmd_in_pr_e.attribute5              IS NOT NULL )
          AND ( xrpm_in_pr_e.hit_in_div             = gmd_in_pr_e.attribute5 )))
--mod start 2008/06/23
        AND    flv_in_pr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_in_pr_e.language                 = 'JA'
        AND    flv_in_pr_e.lookup_code              = xrpm_in_pr_e.new_div_invent
--mod start 2008/06/07
        AND    grb_in_pr_e.routing_id               = grt_in_pr_e.routing_id
        AND    grt_in_pr_e.language                 = 'JA'
        AND    grct_in_pr_e.routing_class           = grcb_in_pr_e.routing_class
        AND    grcb_in_pr_e.routing_class           = grb_in_pr_e.routing_class
        AND    grct_in_pr_e.language                = 'JA'
        AND    grct_in_pr_e.routing_class_desc  NOT IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
                                                       ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')
                                                       ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET'))
--mod end 2008/06/07
        UNION ALL
--mod start 2008/06/07
        -- ���Y���Ɏ��� �i�ڐU�� �i��U��
        SELECT xilv_in_pr_e70.whse_code
              ,xilv_in_pr_e70.mtl_organization_id
              ,xilv_in_pr_e70.customer_stock_whse
              ,xilv_in_pr_e70.inventory_location_id
              ,xilv_in_pr_e70.segment1
              ,xilv_in_pr_e70.description
              ,ximv_in_pr_e70.item_id
              ,ximv_in_pr_e70.item_no
              ,ximv_in_pr_e70.item_name
              ,ximv_in_pr_e70.item_short_name
              ,ximv_in_pr_e70.num_of_cases
              ,ilm_in_pr_e70.lot_id
              ,ilm_in_pr_e70.lot_no
              ,ilm_in_pr_e70.attribute1
              ,ilm_in_pr_e70.attribute2
              ,ilm_in_pr_e70.attribute3                                    -- <---- �����܂ŋ���
              ,itp_in_pr_e70.trans_date
              ,itp_in_pr_e70.trans_date
              ,'2'                                     AS status         -- ����
              ,xrpm_in_pr_e70.new_div_invent
              ,flv_in_pr_e70.meaning
              ,gbh_in_pr_e70.batch_no
              ,grb_in_pr_e70.routing_id
              ,grt_in_pr_e70.routing_desc
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,itp_in_pr_e70.trans_qty
              ,0                                       AS leaving_quantity
              ,ximv_in_pr_e70.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_pr_e70                 -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_in_pr_e70                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_pr_e70                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_pr_e70                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_pr_e70                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,gme_batch_header             gbh_in_pr_e70                  -- ���Y�o�b�`
              ,gme_material_details         gmd_in_pr_e70a                 -- ���Y�����ڍ�(�U�֐�)
              ,gme_material_details         gmd_in_pr_e70b                 -- ���Y�����ڍ�(�U�֌�)
              ,gmd_routings_b               grb_in_pr_e70                  -- �H���}�X�^
              ,gmd_routings_tl              grt_in_pr_e70                  -- �H���}�X�^���{��
              ,gmd_routing_class_b          grcb_in_pr_e70                 -- �H���敪�}�X�^
              ,gmd_routing_class_tl         grct_in_pr_e70                 -- �H���敪�}�X�^���{��
              ,ic_tran_pnd                  itp_in_pr_e70                  -- OPM�ۗ��݌Ƀg�����U�N�V����
              ,xxcmn_item_categories4_v     xicv_in_pr_e70a                -- OPM�i�ڃJ�e�S���������VIEW4(�U�֐�)
              ,xxcmn_item_categories4_v     xicv_in_pr_e70b                -- OPM�i�ڃJ�e�S���������VIEW4(�U�֌�)
        WHERE  xrpm_in_pr_e70.doc_type                = 'PROD'
        AND    xrpm_in_pr_e70.use_div_invent          = 'Y'
        AND    grct_in_pr_e70.language                = 'JA'
        AND    grct_in_pr_e70.routing_class           = grcb_in_pr_e70.routing_class
        AND    grcb_in_pr_e70.routing_class           = grb_in_pr_e70.routing_class
        AND    grt_in_pr_e70.language                 = 'JA'
        AND    grb_in_pr_e70.routing_id               = grt_in_pr_e70.routing_id
        AND    itp_in_pr_e70.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
        AND    gbh_in_pr_e70.batch_id                 = gmd_in_pr_e70a.batch_id
        AND    gmd_in_pr_e70a.line_type               = 1                  -- �����i
        AND    itp_in_pr_e70.doc_type                 = xrpm_in_pr_e70.doc_type
        AND    itp_in_pr_e70.doc_id                   = gmd_in_pr_e70a.batch_id
        AND    itp_in_pr_e70.doc_line                 = gmd_in_pr_e70a.line_no
        AND    itp_in_pr_e70.line_type                = gmd_in_pr_e70a.line_type
        AND    itp_in_pr_e70.completed_ind            = 1
        AND    itp_in_pr_e70.item_id                  = ximv_in_pr_e70.item_id
        AND    itp_in_pr_e70.lot_id                   = ilm_in_pr_e70.lot_id
        AND    itp_in_pr_e70.location                 = xilv_in_pr_e70.segment1
        AND    gmd_in_pr_e70a.item_id                 = ximv_in_pr_e70.item_id
        AND    ilm_in_pr_e70.item_id                  = ximv_in_pr_e70.item_id
        AND    grb_in_pr_e70.attribute9               = xilv_in_pr_e70.segment1
        AND    grb_in_pr_e70.routing_id               = gbh_in_pr_e70.routing_id
        AND    xrpm_in_pr_e70.routing_class           = grb_in_pr_e70.routing_class
        AND    xrpm_in_pr_e70.line_type               = gmd_in_pr_e70a.line_type
        AND    xicv_in_pr_e70a.item_id                = itp_in_pr_e70.item_id
        AND    grct_in_pr_e70.routing_class_desc      = FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
        AND   (xrpm_in_pr_e70.item_div_ahead          = xicv_in_pr_e70a.item_class_code
        AND    xrpm_in_pr_e70.item_div_origin         = xicv_in_pr_e70b.item_class_code
        AND  ((xicv_in_pr_e70a.item_class_code       <> xicv_in_pr_e70b.item_class_code)
        OR    (xicv_in_pr_e70a.item_class_code        = xicv_in_pr_e70b.item_class_code)))
        AND    gbh_in_pr_e70.batch_id                 = gmd_in_pr_e70b.batch_id
        AND    gmd_in_pr_e70a.batch_id                = gmd_in_pr_e70b.batch_id
        AND    gmd_in_pr_e70b.line_type               = -1                  -- �����i
        AND    gmd_in_pr_e70b.item_id                 = xicv_in_pr_e70b.item_id
        AND    flv_in_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_in_pr_e70.language                 = 'JA'
        AND    flv_in_pr_e70.lookup_code              = xrpm_in_pr_e70.new_div_invent
        UNION ALL
        -- ���Y���Ɏ��� ���
        SELECT xilv_in_pr_e70.whse_code
              ,xilv_in_pr_e70.mtl_organization_id
              ,xilv_in_pr_e70.customer_stock_whse
              ,xilv_in_pr_e70.inventory_location_id
              ,xilv_in_pr_e70.segment1
              ,xilv_in_pr_e70.description
              ,ximv_in_pr_e70.item_id
              ,ximv_in_pr_e70.item_no
              ,ximv_in_pr_e70.item_name
              ,ximv_in_pr_e70.item_short_name
              ,ximv_in_pr_e70.num_of_cases
              ,ilm_in_pr_e70.lot_id
              ,ilm_in_pr_e70.lot_no
              ,ilm_in_pr_e70.attribute1
              ,ilm_in_pr_e70.attribute2
              ,ilm_in_pr_e70.attribute3                                    -- <---- �����܂ŋ���
              ,itp_in_pr_e70.trans_date
              ,itp_in_pr_e70.trans_date
              ,'2'                                     AS status         -- ����
              ,xrpm_in_pr_e70.new_div_invent
              ,flv_in_pr_e70.meaning
              ,gbh_in_pr_e70.batch_no
              ,grb_in_pr_e70.routing_id
              ,grt_in_pr_e70.routing_desc
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,itp_in_pr_e70.trans_qty
              ,0                                       AS leaving_quantity
              ,ximv_in_pr_e70.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_pr_e70                 -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_in_pr_e70                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_pr_e70                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_pr_e70                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_pr_e70                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,gme_batch_header             gbh_in_pr_e70                  -- ���Y�o�b�`
              ,gme_material_details         gmd_in_pr_e70                  -- ���Y�����ڍ�
              ,gmd_routings_b               grb_in_pr_e70                  -- �H���}�X�^
              ,gmd_routings_tl              grt_in_pr_e70                  -- �H���}�X�^���{��
              ,gmd_routing_class_b          grcb_in_pr_e70                 -- �H���敪�}�X�^
              ,gmd_routing_class_tl         grct_in_pr_e70                 -- �H���敪�}�X�^���{��
              ,ic_tran_pnd                  itp_in_pr_e70                  -- OPM�ۗ��݌Ƀg�����U�N�V����
              ,xxcmn_item_categories4_v     xicv_in_pr_e70                 -- OPM�i�ڃJ�e�S���������VIEW4
        WHERE  xrpm_in_pr_e70.doc_type                = 'PROD'
        AND    xrpm_in_pr_e70.use_div_invent          = 'Y'
        AND    grct_in_pr_e70.routing_class_desc     IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET')       -- �ԕi����
                                                        ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')) -- ��̔����i
        AND    grct_in_pr_e70.language                = 'JA'
        AND    grct_in_pr_e70.routing_class           = grcb_in_pr_e70.routing_class
        AND    grcb_in_pr_e70.routing_class           = grb_in_pr_e70.routing_class
        AND    grt_in_pr_e70.language                 = 'JA'
        AND    grb_in_pr_e70.routing_id               = grt_in_pr_e70.routing_id
        AND    itp_in_pr_e70.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
        AND    gbh_in_pr_e70.batch_id                 = gmd_in_pr_e70.batch_id
        AND    gmd_in_pr_e70.line_type                = 1                  -- �����i
        AND    itp_in_pr_e70.doc_type                 = xrpm_in_pr_e70.doc_type
        AND    itp_in_pr_e70.doc_id                   = gmd_in_pr_e70.batch_id
        AND    itp_in_pr_e70.doc_line                 = gmd_in_pr_e70.line_no
        AND    itp_in_pr_e70.line_type                = gmd_in_pr_e70.line_type
        AND    itp_in_pr_e70.completed_ind            = 1
        AND    itp_in_pr_e70.item_id                  = ximv_in_pr_e70.item_id
        AND    itp_in_pr_e70.lot_id                   = ilm_in_pr_e70.lot_id
        AND    itp_in_pr_e70.location                 = xilv_in_pr_e70.segment1
        AND    gmd_in_pr_e70.item_id                  = ximv_in_pr_e70.item_id
        AND    ilm_in_pr_e70.item_id                  = ximv_in_pr_e70.item_id
        AND    grb_in_pr_e70.attribute9               = xilv_in_pr_e70.segment1
        AND    grb_in_pr_e70.routing_id               = gbh_in_pr_e70.routing_id
        AND    xrpm_in_pr_e70.routing_class           = grb_in_pr_e70.routing_class
        AND    xrpm_in_pr_e70.line_type               = gmd_in_pr_e70.line_type
        AND    xicv_in_pr_e70.item_id                 = itp_in_pr_e70.item_id
        AND    flv_in_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_in_pr_e70.language                 = 'JA'
        AND    flv_in_pr_e70.lookup_code              = xrpm_in_pr_e70.new_div_invent
--mod end 2008/06/07
        UNION ALL
        -- �q�֕ԕi ���Ɏ���
        SELECT xilv_in_po_e_rma.whse_code
              ,xilv_in_po_e_rma.mtl_organization_id
              ,xilv_in_po_e_rma.customer_stock_whse
              ,xilv_in_po_e_rma.inventory_location_id
              ,xilv_in_po_e_rma.segment1
              ,xilv_in_po_e_rma.description
              ,ximv_in_po_e_rma.item_id
              ,ximv_in_po_e_rma.item_no
              ,ximv_in_po_e_rma.item_name
              ,ximv_in_po_e_rma.item_short_name
              ,ximv_in_po_e_rma.num_of_cases
              ,ilm_in_po_e_rma.lot_id
              ,ilm_in_po_e_rma.lot_no
              ,ilm_in_po_e_rma.attribute1
              ,ilm_in_po_e_rma.attribute2
              ,ilm_in_po_e_rma.attribute3                                    -- <---- �����܂ŋ���
              ,xoha_in_po_e_rma.arrival_date
              ,xoha_in_po_e_rma.shipped_date
              ,'2'                                     AS status              -- ����
              ,xrpm_in_po_e_rma.new_div_invent
              ,flv_in_po_e_rma.meaning
              ,xoha_in_po_e_rma.request_no
              ,xoha_in_po_e_rma.customer_id
              ,xcav_in_po_e_rma.party_name
              ,xoha_in_po_e_rma.deliver_to_id
              ,xpsv_in_po_e_rma.party_site_full_name
              ,xmld_in_po_e_rma.actual_quantity
              ,0                                       AS leaving_quantity
              ,ximv_in_po_e_rma.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_in_po_e_rma                 -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_in_po_e_rma                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_in_po_e_rma                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_in_po_e_rma                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_in_po_e_rma                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxwsh_order_headers_all      xoha_in_po_e_rma                 -- �󒍃w�b�_(�A�h�I��)
              ,xxwsh_order_lines_all        xola_in_po_e_rma                 -- �󒍖���(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_in_po_e_rma                 -- �ړ����b�g�ڍ�(�A�h�I��)
              ,oe_transaction_types_all     otta_in_po_e_rma                 -- �󒍃^�C�v
              ,xxcmn_cust_accounts_v        xcav_in_po_e_rma                 -- �ڋq���VIEW
              ,xxcmn_party_sites_v          xpsv_in_po_e_rma                 -- �p�[�e�B�T�C�g���VIEW
        WHERE  xrpm_in_po_e_rma.doc_type                    = 'PORC'
        AND    xrpm_in_po_e_rma.source_document_code        = 'RMA'
--mod start 2008/06/09
        AND    otta_in_po_e_rma.order_category_code         = 'RETURN'
--mod end 2008/06/09
        AND    xrpm_in_po_e_rma.use_div_invent              = 'Y'
        AND    xrpm_in_po_e_rma.rcv_pay_div                 = '1'            -- ���
        AND    xoha_in_po_e_rma.order_header_id             = xola_in_po_e_rma.order_header_id
--mod start 2008/06/04 rev1.1
--        AND    xoha_in_po_e_rma.deliver_from_id             = xilv_in_po_e_rma.segment1
        AND    xoha_in_po_e_rma.deliver_from_id             = xilv_in_po_e_rma.inventory_location_id
--mod end 2008/06/04 rev1.1
        AND    xola_in_po_e_rma.shipping_inventory_item_id  = ximv_in_po_e_rma.inventory_item_id
        AND    ilm_in_po_e_rma.item_id                      = ximv_in_po_e_rma.item_id
        AND    xmld_in_po_e_rma.mov_line_id                 = xola_in_po_e_rma.order_line_id
        AND    xmld_in_po_e_rma.document_type_code          = '10'           -- �o�׈˗�
        AND    xmld_in_po_e_rma.record_type_code            = '20'           -- �o�Ɏ���
--mod start 2008/06/07
--        AND (( ximv_in_po_e_rma.lot_ctl                     = 1              -- ���b�g�Ǘ��i
--           AND xmld_in_po_e_rma.item_id                     = ximv_in_po_e_rma.item_id
--           AND xmld_in_po_e_rma.lot_id                      = ilm_in_po_e_rma.lot_id )
--          OR ( ximv_in_po_e_rma.lot_ctl                     = 0 ))           -- �񃍃b�g�Ǘ��i
--        AND xmld_in_po_e_rma.item_id                        = ximv_in_po_e_rma.item_id
        AND    xmld_in_po_e_rma.lot_id                         = ilm_in_po_e_rma.lot_id
--        AND xmld_in_po_e_rma.item_id                        = ilm_in_po_e_rma.item_id
--mod end 2008/06/07
        AND    xoha_in_po_e_rma.order_type_id               = otta_in_po_e_rma.transaction_type_id
        AND    otta_in_po_e_rma.attribute1                  = '3'            -- �q�֕ԕi
        AND    otta_in_po_e_rma.attribute1                  = xrpm_in_po_e_rma.shipment_provision_div
        AND    xoha_in_po_e_rma.req_status                  = '04'           -- �o�׎��ьv���
--mod start 2008/06/07
--        AND    xrpm_in_po_e_rma.ship_prov_rcv_pay_category  = '03'           -- �󕥋敪�A�h�I���𕡐��ǂ܂Ȃ���
        AND    xrpm_in_po_e_rma.ship_prov_rcv_pay_category  = otta_in_po_e_rma.attribute11
                                                                              -- �󕥋敪�A�h�I���𕡐��ǂ܂Ȃ���
        AND    otta_in_po_e_rma.attribute11                 in  ('03','04')
--mod end 2008/06/07
        AND    xoha_in_po_e_rma.latest_external_flag        = 'Y'            -- ON
        AND    xola_in_po_e_rma.delete_flag                 = 'N'            -- OFF
        AND    flv_in_po_e_rma.lookup_type                  = 'XXCMN_NEW_DIVISION'
        AND    flv_in_po_e_rma.language                     = 'JA'
        AND    flv_in_po_e_rma.lookup_code                  = xrpm_in_po_e_rma.new_div_invent
        AND    xoha_in_po_e_rma.customer_id                 = xcav_in_po_e_rma.party_id
--mod start 2008/06/16
--        AND    xoha_in_po_e_rma.deliver_to_id               = xpsv_in_po_e_rma.party_site_id
        AND    xoha_in_po_e_rma.result_deliver_to_id        = xpsv_in_po_e_rma.party_site_id
--mod end 2008/06/16
        UNION ALL
--mod start 2008/06/06
        -- �݌ɒ��� ���Ɏ���(�����݌�)
        SELECT xilv_in_ad_e_x97.whse_code
              ,xilv_in_ad_e_x97.mtl_organization_id
              ,xilv_in_ad_e_x97.customer_stock_whse
              ,xilv_in_ad_e_x97.inventory_location_id
              ,xilv_in_ad_e_x97.segment1
              ,xilv_in_ad_e_x97.description
              ,ximv_in_ad_e_x97.item_id
              ,ximv_in_ad_e_x97.item_no
              ,ximv_in_ad_e_x97.item_name
              ,ximv_in_ad_e_x97.item_short_name
              ,ximv_in_ad_e_x97.num_of_cases
              ,ilm_in_ad_e_x97.lot_id
              ,ilm_in_ad_e_x97.lot_no
              ,ilm_in_ad_e_x97.attribute1
              ,ilm_in_ad_e_x97.attribute2
              ,ilm_in_ad_e_x97.attribute3                                     -- <---- �����܂ŋ���
              ,itc_in_ad_e_x97.trans_date
              ,itc_in_ad_e_x97.trans_date
              ,'2'                                            AS status        -- ����
              ,xrpm_in_ad_e_x97.new_div_invent
              ,flv_in_ad_e_x97.meaning
              ,NULL                                           AS voucher_no
              ,xilv_in_ad_e_x97.inventory_location_id         AS ukebaraisaki_id
              ,xilv_in_ad_e_x97.description
              ,NULL                                           AS deliver_to_id
              ,NULL                                           AS deliver_to_name
              ,itc_in_ad_e_x97.trans_qty                      AS leaving_quantity
              ,0                                              AS stock_quantity
              ,ximv_in_ad_e_x97.lot_ctl
        FROM   xxcmn_item_locations_v  xilv_in_ad_e_x97                       -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v        ximv_in_ad_e_x97                       -- OPM�i�ڏ��VIEW
              ,ic_lots_mst             ilm_in_ad_e_x97                        -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst       xrpm_in_ad_e_x97                       -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values       flv_in_ad_e_x97                        -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,ic_tran_cmp             itc_in_ad_e_x97                        -- OPM�����݌Ƀg�����U�N�V����
        WHERE  xrpm_in_ad_e_x97.doc_type               = 'ADJI'
        AND    xrpm_in_ad_e_x97.reason_code            = 'X977'               -- �����݌�
        AND    xrpm_in_ad_e_x97.rcv_pay_div            = '1'                  -- ���
        AND    xrpm_in_ad_e_x97.use_div_invent         = 'Y'
--mod start 2008/06/16
        AND    itc_in_ad_e_x97.doc_type                = xrpm_in_ad_e_x97.doc_type
--mod end 2008/06/16
        AND    itc_in_ad_e_x97.reason_code             = xrpm_in_ad_e_x97.reason_code
        AND    SIGN( itc_in_ad_e_x97.trans_qty )       = xrpm_in_ad_e_x97.rcv_pay_div
        AND    itc_in_ad_e_x97.item_id                 = ximv_in_ad_e_x97.item_id
        AND    ilm_in_ad_e_x97.item_id                 = ximv_in_ad_e_x97.item_id
        AND    itc_in_ad_e_x97.lot_id                  = ilm_in_ad_e_x97.lot_id
        AND    itc_in_ad_e_x97.whse_code               = xilv_in_ad_e_x97.whse_code
        AND    itc_in_ad_e_x97.location                = xilv_in_ad_e_x97.segment1
        AND    flv_in_ad_e_x97.lookup_type             = 'XXCMN_NEW_DIVISION'
        AND    flv_in_ad_e_x97.language                = 'JA'
        AND    flv_in_ad_e_x97.lookup_code             = xrpm_in_ad_e_x97.new_div_invent
--mod end 2008/06/06
        UNION ALL
        -- �݌ɒ��� ���Ɏ���(�l������)
        SELECT xilv_in_ad_e_x9.whse_code
              ,xilv_in_ad_e_x9.mtl_organization_id
              ,xilv_in_ad_e_x9.customer_stock_whse
              ,xilv_in_ad_e_x9.inventory_location_id
              ,xilv_in_ad_e_x9.segment1
              ,xilv_in_ad_e_x9.description
              ,ximv_in_ad_e_x9.item_id
              ,ximv_in_ad_e_x9.item_no
              ,ximv_in_ad_e_x9.item_name
              ,ximv_in_ad_e_x9.item_short_name
              ,ximv_in_ad_e_x9.num_of_cases
              ,ilm_in_ad_e_x9.lot_id
              ,ilm_in_ad_e_x9.lot_no
              ,ilm_in_ad_e_x9.attribute1
              ,ilm_in_ad_e_x9.attribute2
              ,ilm_in_ad_e_x9.attribute3                                     -- <---- �����܂ŋ���
              ,itc_in_ad_e_x9.trans_date
              ,itc_in_ad_e_x9.trans_date
              ,'2'                                            AS status      -- ����
              ,xrpm_in_ad_e_x9.new_div_invent
              ,flv_in_ad_e_x9.meaning
              ,xnpt_in_ad_e_x9.entry_number
              ,TO_NUMBER( xrpm_in_ad_e_x9.new_div_invent )
              ,flv_in_ad_e_x9.meaning
              ,NULL                                           AS deliver_to_id
              ,NULL                                           AS deliver_to_name
              ,itc_in_ad_e_x9.trans_qty
              ,0                                              AS leaving_quantity
              ,ximv_in_ad_e_x9.lot_ctl
        FROM   xxcmn_item_locations_v  xilv_in_ad_e_x9                       -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v        ximv_in_ad_e_x9                       -- OPM�i�ڏ��VIEW
              ,ic_lots_mst             ilm_in_ad_e_x9                        -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst       xrpm_in_ad_e_x9                       -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values       flv_in_ad_e_x9                        -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,ic_adjs_jnl             iaj_in_ad_e_x9                        -- OPM�݌ɒ����W���[�i��
              ,ic_jrnl_mst             ijm_in_ad_e_x9                        -- OPM�W���[�i���}�X�^
              ,ic_tran_cmp             itc_in_ad_e_x9                        -- OPM�����݌Ƀg�����U�N�V����
              ,xxpo_namaha_prod_txns   xnpt_in_ad_e_x9                       -- ���t���сi�A�h�I���j
        WHERE  xrpm_in_ad_e_x9.doc_type               = 'ADJI'
        AND    xrpm_in_ad_e_x9.reason_code            = 'X988'               -- �l������
        AND    xrpm_in_ad_e_x9.rcv_pay_div            = '1'                  -- ���
        AND    xrpm_in_ad_e_x9.use_div_invent         = 'Y'
        AND    itc_in_ad_e_x9.doc_type                = xrpm_in_ad_e_x9.doc_type
        AND    itc_in_ad_e_x9.reason_code             = xrpm_in_ad_e_x9.reason_code
        AND    SIGN( itc_in_ad_e_x9.trans_qty )       = xrpm_in_ad_e_x9.rcv_pay_div
        AND    itc_in_ad_e_x9.item_id                 = ximv_in_ad_e_x9.item_id
        AND    ilm_in_ad_e_x9.item_id                 = ximv_in_ad_e_x9.item_id
        AND    itc_in_ad_e_x9.lot_id                  = ilm_in_ad_e_x9.lot_id
        AND    itc_in_ad_e_x9.whse_code               = xilv_in_ad_e_x9.whse_code
        AND    itc_in_ad_e_x9.location                = xilv_in_ad_e_x9.segment1
        AND    iaj_in_ad_e_x9.journal_id              = ijm_in_ad_e_x9.journal_id
        AND    itc_in_ad_e_x9.doc_type                = iaj_in_ad_e_x9.trans_type
        AND    itc_in_ad_e_x9.doc_id                  = iaj_in_ad_e_x9.doc_id
        AND    itc_in_ad_e_x9.doc_line                = iaj_in_ad_e_x9.doc_line
        AND    ijm_in_ad_e_x9.attribute1              = xnpt_in_ad_e_x9.entry_number
        AND    flv_in_ad_e_x9.lookup_type             = 'XXCMN_NEW_DIVISION'
        AND    flv_in_ad_e_x9.language                = 'JA'
        AND    flv_in_ad_e_x9.lookup_code             = xrpm_in_ad_e_x9.new_div_invent
        UNION ALL
--mod start 2008/06/06
        -- �݌ɒ��� ���Ɏ���(�ړ����ђ���)
        SELECT xilv_in_ad_e_xx.whse_code
              ,xilv_in_ad_e_xx.mtl_organization_id
              ,xilv_in_ad_e_xx.customer_stock_whse
              ,xilv_in_ad_e_xx.inventory_location_id
              ,xilv_in_ad_e_xx.segment1
              ,xilv_in_ad_e_xx.description
              ,ximv_in_ad_e_xx.item_id
              ,ximv_in_ad_e_xx.item_no
              ,ximv_in_ad_e_xx.item_name
              ,ximv_in_ad_e_xx.item_short_name
              ,ximv_in_ad_e_xx.num_of_cases
              ,ilm_in_ad_e_xx.lot_id
              ,ilm_in_ad_e_xx.lot_no
              ,ilm_in_ad_e_xx.attribute1
              ,ilm_in_ad_e_xx.attribute2
              ,ilm_in_ad_e_xx.attribute3                                     -- <---- �����܂ŋ���
              ,itc_in_ad_e_xx.trans_date
              ,itc_in_ad_e_xx.trans_date
              ,'2'                                            AS status   -- ����
              ,xrpm_in_ad_e_xx.new_div_invent
              ,flv_in_ad_e_xx.meaning
              ,xmrih_in_ad_e_xx.mov_num
              ,xmrih_in_ad_e_xx.shipped_locat_id
              ,xilv_in_ad_e2_xx.description
              ,NULL                                           AS deliver_to_id
              ,NULL                                           AS deliver_to_name
              ,0
              ,ABS(itc_in_ad_e_xx.trans_qty)                  AS leaving_quantity
              ,ximv_in_ad_e_xx.lot_ctl
        FROM   xxcmn_item_locations_v  xilv_in_ad_e_xx                       -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_locations_v  xilv_in_ad_e2_xx                      -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v        ximv_in_ad_e_xx                       -- OPM�i�ڏ��VIEW
              ,ic_lots_mst             ilm_in_ad_e_xx                        -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst       xrpm_in_ad_e_xx                       -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values       flv_in_ad_e_xx                        -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,ic_adjs_jnl             iaj_in_ad_e_xx                        -- OPM�݌ɒ����W���[�i��
              ,ic_jrnl_mst             ijm_in_ad_e_xx                        -- OPM�W���[�i���}�X�^
              ,ic_tran_cmp             itc_in_ad_e_xx                        -- OPM�����݌Ƀg�����U�N�V����
              ,xxinv_mov_req_instr_headers xmrih_in_ad_e_xx                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines   xmril_in_ad_e_xx                  -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details       xmldt_in_ad_e_xx                  -- �ړ����b�g�ڍ�(�A�h�I��)
        WHERE  xrpm_in_ad_e_xx.doc_type               = 'ADJI'
        AND    xrpm_in_ad_e_xx.reason_code            = 'X123'               -- �ړ����ђ���
        AND    xrpm_in_ad_e_xx.rcv_pay_div            = '-1'                 -- ���o
        AND    xrpm_in_ad_e_xx.use_div_invent         = 'Y'
        AND    flv_in_ad_e_xx.lookup_type             = 'XXCMN_NEW_DIVISION'
        AND    flv_in_ad_e_xx.language                = 'JA'
        AND    flv_in_ad_e_xx.lookup_code             = xrpm_in_ad_e_xx.new_div_invent
        AND    itc_in_ad_e_xx.doc_type                = xrpm_in_ad_e_xx.doc_type
        AND    itc_in_ad_e_xx.reason_code             = xrpm_in_ad_e_xx.reason_code
        AND    SIGN( itc_in_ad_e_xx.trans_qty )       = xrpm_in_ad_e_xx.rcv_pay_div
        AND    itc_in_ad_e_xx.item_id                 = xmril_in_ad_e_xx.item_id
        AND    itc_in_ad_e_xx.lot_id                  = xmldt_in_ad_e_xx.lot_id
        AND    itc_in_ad_e_xx.location                = xmrih_in_ad_e_xx.ship_to_locat_code
        AND    itc_in_ad_e_xx.doc_type                = iaj_in_ad_e_xx.trans_type
        AND    itc_in_ad_e_xx.doc_id                  = iaj_in_ad_e_xx.doc_id
        AND    itc_in_ad_e_xx.doc_line                = iaj_in_ad_e_xx.doc_line
        AND    iaj_in_ad_e_xx.journal_id              = ijm_in_ad_e_xx.journal_id
        AND    xmril_in_ad_e_xx.mov_line_id           = TO_NUMBER( ijm_in_ad_e_xx.attribute1 )
        AND    xmldt_in_ad_e_xx.lot_id                = ilm_in_ad_e_xx.lot_id
        AND    xmldt_in_ad_e_xx.record_type_code      = '30'
        AND    xmldt_in_ad_e_xx.document_type_code    = '20'
        AND    xmril_in_ad_e_xx.mov_line_id           = xmldt_in_ad_e_xx.mov_line_id
        AND    xmril_in_ad_e_xx.item_id               = ximv_in_ad_e_xx.item_id
        AND    xmrih_in_ad_e_xx.mov_hdr_id            = xmril_in_ad_e_xx.mov_hdr_id
        AND    xmrih_in_ad_e_xx.ship_to_locat_id      = xilv_in_ad_e_xx.inventory_location_id
        AND    xmrih_in_ad_e_xx.shipped_locat_id      = xilv_in_ad_e2_xx.inventory_location_id
--mod end 2008/06/06
        UNION ALL
        -- �݌ɒ��� ���Ɏ���(��L�ȊO)
        SELECT xilv_in_ad_e_xx.whse_code
              ,xilv_in_ad_e_xx.mtl_organization_id
              ,xilv_in_ad_e_xx.customer_stock_whse
              ,xilv_in_ad_e_xx.inventory_location_id
              ,xilv_in_ad_e_xx.segment1
              ,xilv_in_ad_e_xx.description
              ,ximv_in_ad_e_xx.item_id
              ,ximv_in_ad_e_xx.item_no
              ,ximv_in_ad_e_xx.item_name
              ,ximv_in_ad_e_xx.item_short_name
              ,ximv_in_ad_e_xx.num_of_cases
              ,ilm_in_ad_e_xx.lot_id
              ,ilm_in_ad_e_xx.lot_no
              ,ilm_in_ad_e_xx.attribute1
              ,ilm_in_ad_e_xx.attribute2
              ,ilm_in_ad_e_xx.attribute3                                     -- <---- �����܂ŋ���
              ,itc_in_ad_e_xx.trans_date
              ,itc_in_ad_e_xx.trans_date
              ,'2'                                            AS status   -- ����
              ,xrpm_in_ad_e_xx.new_div_invent
              ,flv_in_ad_e_xx.meaning
--mod start 2008/06/06
--              ,xmrih_in_ad_e_xx.mov_num
--              ,xmrih_in_ad_e_xx.shipped_locat_id
              ,ijm_in_ad_e_xx.journal_no
              ,TO_NUMBER( xrpm_in_ad_e_xx.new_div_invent )    AS ukebaraisaki_id
--mod end 2008/06/06
              ,flv_in_ad_e_xx.meaning
              ,NULL                                           AS deliver_to_id
              ,NULL                                           AS deliver_to_name
              ,itc_in_ad_e_xx.trans_qty
              ,0                                              AS leaving_quantity
              ,ximv_in_ad_e_xx.lot_ctl
        FROM   xxcmn_item_locations_v  xilv_in_ad_e_xx                       -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v        ximv_in_ad_e_xx                       -- OPM�i�ڏ��VIEW
              ,ic_lots_mst             ilm_in_ad_e_xx                        -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst       xrpm_in_ad_e_xx                       -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values       flv_in_ad_e_xx                        -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,ic_adjs_jnl             iaj_in_ad_e_xx                        -- OPM�݌ɒ����W���[�i��
              ,ic_jrnl_mst             ijm_in_ad_e_xx                        -- OPM�W���[�i���}�X�^
              ,ic_tran_cmp             itc_in_ad_e_xx                        -- OPM�����݌Ƀg�����U�N�V����
--del start 2008/06/06
--              ,xxinv_mov_req_instr_headers xmrih_in_ad_e_xx                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
--              ,xxinv_mov_req_instr_lines   xmril_in_ad_e_xx                  -- �ړ��˗�/�w������(�A�h�I��)
--del end 2008/06/06
        WHERE  xrpm_in_ad_e_xx.doc_type               = 'ADJI'
        AND    xrpm_in_ad_e_xx.reason_code           <> 'X977'               -- �����݌�
--del start 2008/06/06
--        AND    xrpm_in_ad_e_xx.reason_code           <> 'X201'               -- �d���ԕi�o��
--del end 2008/06/06
        AND    xrpm_in_ad_e_xx.reason_code           <> 'X988'               -- �l������
--mod start 2008/06/06
        AND    xrpm_in_ad_e_xx.reason_code           <> 'X123'               -- �ړ����ђ����i�o�Ɂj
--mod end 2008/06/06
        AND    xrpm_in_ad_e_xx.rcv_pay_div            = '1'                  -- ���
        AND    xrpm_in_ad_e_xx.use_div_invent         = 'Y'
        AND    itc_in_ad_e_xx.doc_type                = xrpm_in_ad_e_xx.doc_type
        AND    itc_in_ad_e_xx.reason_code             = xrpm_in_ad_e_xx.reason_code
        AND    SIGN( itc_in_ad_e_xx.trans_qty )       = xrpm_in_ad_e_xx.rcv_pay_div
        AND    itc_in_ad_e_xx.item_id                 = ximv_in_ad_e_xx.item_id
        AND    ilm_in_ad_e_xx.item_id                 = ximv_in_ad_e_xx.item_id
        AND    itc_in_ad_e_xx.lot_id                  = ilm_in_ad_e_xx.lot_id
        AND    itc_in_ad_e_xx.whse_code               = xilv_in_ad_e_xx.whse_code
        AND    itc_in_ad_e_xx.location                = xilv_in_ad_e_xx.segment1
        AND    iaj_in_ad_e_xx.journal_id              = ijm_in_ad_e_xx.journal_id
        AND    itc_in_ad_e_xx.doc_type                = iaj_in_ad_e_xx.trans_type
        AND    itc_in_ad_e_xx.doc_id                  = iaj_in_ad_e_xx.doc_id
        AND    itc_in_ad_e_xx.doc_line                = iaj_in_ad_e_xx.doc_line
        AND    flv_in_ad_e_xx.lookup_type             = 'XXCMN_NEW_DIVISION'
        AND    flv_in_ad_e_xx.language                = 'JA'
        AND    flv_in_ad_e_xx.lookup_code             = xrpm_in_ad_e_xx.new_div_invent
--del start 2008/06/06
--        AND    xmril_in_ad_e_xx.mov_line_id           = TO_NUMBER( ijm_in_ad_e_xx.attribute1 )
--        AND    xmrih_in_ad_e_xx.mov_hdr_id            = xmril_in_ad_e_xx.mov_hdr_id
--del end 2008/06/06
        UNION ALL
        ------------------------------------------------------------------------
        -- �o�Ɏ���
        ------------------------------------------------------------------------
        -- �ړ��o�Ɏ���(�ϑ�����)
        SELECT xilv_out_xf_e.whse_code
              ,xilv_out_xf_e.mtl_organization_id
              ,xilv_out_xf_e.customer_stock_whse
              ,xilv_out_xf_e.inventory_location_id
              ,xilv_out_xf_e.segment1
              ,xilv_out_xf_e.description
              ,ximv_out_xf_e.item_id
              ,ximv_out_xf_e.item_no
              ,ximv_out_xf_e.item_name
              ,ximv_out_xf_e.item_short_name
              ,ximv_out_xf_e.num_of_cases
              ,ilm_out_xf_e.lot_id
              ,ilm_out_xf_e.lot_no
              ,ilm_out_xf_e.attribute1
              ,ilm_out_xf_e.attribute2
              ,ilm_out_xf_e.attribute3                                     -- <---- �����܂ŋ���
              ,xmrih_out_xf_e.actual_arrival_date
              ,xmrih_out_xf_e.actual_ship_date
              ,'2'                                     AS status           -- ����
              ,xrpm_out_xf_e.new_div_invent
              ,flv_out_xf_e.meaning
              ,xmrih_out_xf_e.mov_num
              ,xmrih_out_xf_e.ship_to_locat_id
              ,xilv_out_xf_e2.description
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,0                                       AS stock_quantity
              ,xmld_out_xf_e.actual_quantity           AS leaving_quantity
              ,ximv_out_xf_e.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_xf_e                   -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_locations_v       xilv_out_xf_e2                  -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_out_xf_e                   -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_xf_e                    -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_xf_e                   -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_xf_e                    -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_out_xf_e                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_out_xf_e                  -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_xf_e                   -- �ړ����b�g�ڍ�(�A�h�I��)
        WHERE  xrpm_out_xf_e.doc_type                = 'XFER'               -- �ړ��ϑ�����
        AND    xrpm_out_xf_e.use_div_invent          = 'Y'
        AND    xrpm_out_xf_e.rcv_pay_div             = '-1'
        AND    xmrih_out_xf_e.mov_hdr_id             = xmril_out_xf_e.mov_hdr_id
        AND    xmril_out_xf_e.item_id                = ximv_out_xf_e.item_id
        AND    xmrih_out_xf_e.shipped_locat_id       = xilv_out_xf_e.inventory_location_id
        AND    xmrih_out_xf_e.ship_to_locat_id       = xilv_out_xf_e2.inventory_location_id
        AND    ilm_out_xf_e.item_id                  = xmril_out_xf_e.item_id
        AND    ilm_out_xf_e.lot_id                   = xmld_out_xf_e.lot_id
        AND    xmld_out_xf_e.mov_line_id             = xmril_out_xf_e.mov_line_id
        AND    xmld_out_xf_e.document_type_code      = '20'                 -- �ړ�
        AND    xmld_out_xf_e.record_type_code        = '20'                -- �o�Ɏ���
        AND    xmrih_out_xf_e.mov_type               = '1'                  -- �ϑ�����
        AND    xmril_out_xf_e.delete_flg             = 'N'                  -- OFF
        AND    xmrih_out_xf_e.status                IN ( '06'               -- ���o�ɕ񍐗L
                                                        ,'04' )             -- �o�ɕ񍐗L
        AND    flv_out_xf_e.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_out_xf_e.language                 = 'JA'
        AND    flv_out_xf_e.lookup_code              = xrpm_out_xf_e.new_div_invent
        UNION ALL
        -- �ړ��o�Ɏ���(�ϑ��Ȃ�)
        SELECT xilv_out_tr_e.whse_code
              ,xilv_out_tr_e.mtl_organization_id
              ,xilv_out_tr_e.customer_stock_whse
              ,xilv_out_tr_e.inventory_location_id
              ,xilv_out_tr_e.segment1
              ,xilv_out_tr_e.description
              ,ximv_out_tr_e.item_id
              ,ximv_out_tr_e.item_no
              ,ximv_out_tr_e.item_name
              ,ximv_out_tr_e.item_short_name
              ,ximv_out_tr_e.num_of_cases
              ,ilm_out_tr_e.lot_id
              ,ilm_out_tr_e.lot_no
              ,ilm_out_tr_e.attribute1
              ,ilm_out_tr_e.attribute2
              ,ilm_out_tr_e.attribute3                                   -- <---- �����܂ŋ���
              ,xmrih_out_tr_e.actual_arrival_date
              ,xmrih_out_tr_e.actual_ship_date
              ,'2'                                     AS status        -- ����
              ,xrpm_out_tr_e.new_div_invent
              ,flv_out_tr_e.meaning
              ,xmrih_out_tr_e.mov_num
              ,xmrih_out_tr_e.ship_to_locat_id
              ,xilv_out_tr_e2.description
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,0                                       AS stock_quantity
              ,xmld_out_tr_e.actual_quantity           AS leaving_quantity
              ,ximv_out_tr_e.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_tr_e                -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_locations_v       xilv_out_tr_e2               -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_out_tr_e                -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_tr_e                 -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_tr_e                -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_tr_e                 -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_out_tr_e               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_out_tr_e               -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_tr_e                -- �ړ����b�g�ڍ�(�A�h�I��)
        WHERE  xrpm_out_tr_e.doc_type                = 'TRNI'            -- �ړ��ϑ��Ȃ�
        AND    xrpm_out_tr_e.use_div_invent          = 'Y'
        AND    xrpm_out_tr_e.rcv_pay_div             = '-1'
        AND    xmrih_out_tr_e.mov_hdr_id             = xmril_out_tr_e.mov_hdr_id
        AND    xmril_out_tr_e.item_id                = ximv_out_tr_e.item_id
        AND    xmrih_out_tr_e.shipped_locat_id       = xilv_out_tr_e.inventory_location_id
        AND    xmrih_out_tr_e.ship_to_locat_id       = xilv_out_tr_e2.inventory_location_id
        AND    ilm_out_tr_e.item_id                  = xmril_out_tr_e.item_id
        AND    ilm_out_tr_e.lot_id                   = xmld_out_tr_e.lot_id
        AND    xmld_out_tr_e.mov_line_id             = xmril_out_tr_e.mov_line_id
        AND    xmld_out_tr_e.document_type_code      = '20'              -- �ړ�
        AND    xmld_out_tr_e.record_type_code        = '20'              -- �o�Ɏ���
        AND    xmrih_out_tr_e.mov_type               = '2'               -- �ϑ��Ȃ�
        AND    xmrih_out_tr_e.status                 = '06'              -- ���o�ɕ񍐗L
        AND    xmril_out_tr_e.delete_flg             = 'N'               -- OFF
        AND    flv_out_tr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_out_tr_e.language                 = 'JA'
        AND    flv_out_tr_e.lookup_code              = xrpm_out_tr_e.new_div_invent
/*
        -- �ړ��o�Ɏ���(�ϑ�����)
        SELECT xilv_out_xf_e.whse_code
              ,xilv_out_xf_e.mtl_organization_id
              ,xilv_out_xf_e.customer_stock_whse
              ,xilv_out_xf_e.inventory_location_id
              ,xilv_out_xf_e.segment1
              ,xilv_out_xf_e.description
              ,ximv_out_xf_e.item_id
              ,ximv_out_xf_e.item_no
              ,ximv_out_xf_e.item_name
              ,ximv_out_xf_e.item_short_name
              ,ximv_out_xf_e.num_of_cases
              ,ilm_out_xf_e.lot_id
              ,ilm_out_xf_e.lot_no
              ,ilm_out_xf_e.attribute1
              ,ilm_out_xf_e.attribute2
              ,ilm_out_xf_e.attribute3                                     -- <---- �����܂ŋ���
              ,xmrih_out_xf_e.actual_arrival_date
              ,xmrih_out_xf_e.actual_ship_date
              ,'2'                                     AS status           -- ����
              ,xrpm_out_xf_e.new_div_invent
              ,flv_out_xf_e.meaning
              ,xmrih_out_xf_e.mov_num
              ,xmrih_out_xf_e.ship_to_locat_id
              ,xilv_out_xf_e.description
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,0                                       AS stock_quantity
--mod start 2008/06/05 rev1.5
--              ,CASE
--                WHEN ( ximv_out_xf_e.lot_ctl = 1 ) THEN
--                  xmld_out_xf_e.actual_quantity                             -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_out_xf_e.lot_ctl = 0  ) THEN
--                  xmril_out_xf_e.shipped_quantity                           -- �񃍃b�g�Ǘ��i(���Ɏ��ѐ���)
--               END                                        leaving_quantity
--              ,xmld_out_xf_e.actual_quantity           leaving_quantity
              ,itp_out_xf_e.trans_qty                  AS leaving_quantity
--mod end 2008/06/05 rev1.5
              ,ximv_out_xf_e.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_xf_e                   -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_out_xf_e                   -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_xf_e                    -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_xf_e                   -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_xf_e                    -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_out_xf_e                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_out_xf_e                  -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_xf_e                   -- �ړ����b�g�ڍ�(�A�h�I��)
              ,ic_tran_pnd                  itp_out_xf_e                    -- OPM�ۗ��݌Ƀg�����U�N�V����
              ,ic_xfer_mst                  ixm_out_xf_e                    -- OPM�݌ɓ]���}�X�^
        WHERE  xrpm_out_xf_e.doc_type                = 'XFER'               -- �ړ��ϑ�����
        AND    xrpm_out_xf_e.use_div_invent          = 'Y'
        AND    itp_out_xf_e.delete_mark              = 0                    -- �L���`�F�b�N(OPM�ۗ��݌�)
        AND    xmrih_out_xf_e.mov_hdr_id             = xmril_out_xf_e.mov_hdr_id
        AND    xmril_out_xf_e.item_id                = ximv_out_xf_e.item_id
--mod start 2008/06/04 rev1.1
--        AND    xmrih_out_xf_e.shipped_locat_id       = xilv_out_xf_e.segment1
        AND    xmrih_out_xf_e.shipped_locat_id       = xilv_out_xf_e.inventory_location_id
--mod end 2008/06/04 rev1.1
        AND    ilm_out_xf_e.item_id                  = xmril_out_xf_e.item_id
        AND    ilm_out_xf_e.lot_id                   = xmld_out_xf_e.lot_id
        AND    xmld_out_xf_e.mov_line_id             = xmril_out_xf_e.mov_line_id
        AND    xmld_out_xf_e.document_type_code      = '20'                 -- �ړ�
        AND    xmld_out_xf_e.record_type_code        = '20'                -- �o�Ɏ���
        AND    xmrih_out_xf_e.mov_type               = '1'                  -- �ϑ�����
        AND    xmril_out_xf_e.delete_flg             = 'N'                  -- OFF
        AND    xmrih_out_xf_e.status                IN ( '06'               -- ���o�ɕ񍐗L
                                                        ,'04' )             -- �o�ɕ񍐗L
        AND    TO_NUMBER( ixm_out_xf_e.attribute1 )  = xmril_out_xf_e.mov_line_id
        AND    itp_out_xf_e.doc_type                 = xrpm_out_xf_e.doc_type
        AND    itp_out_xf_e.doc_id                   = ixm_out_xf_e.transfer_id
        AND    itp_out_xf_e.completed_ind            = 1
--mod start 2008/06/05
--        AND    itp_out_xf_e.whse_code                = xilv_out_xf_e.whse_code
        AND    itp_out_xf_e.location                 = xilv_out_xf_e.segment1
--mod end 2008/06/05
        AND    itp_out_xf_e.item_id                  = ximv_out_xf_e.item_id
        AND    itp_out_xf_e.lot_id                   = ilm_out_xf_e.lot_id
        AND    xrpm_out_xf_e.reason_code             = itp_out_xf_e.reason_code
        AND    xrpm_out_xf_e.rcv_pay_div             = SIGN( itp_out_xf_e.trans_qty )
        AND    flv_out_xf_e.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_out_xf_e.language                 = 'JA'
        AND    flv_out_xf_e.lookup_code              = xrpm_out_xf_e.new_div_invent
        UNION ALL
        -- �ړ��o�Ɏ���(�ϑ��Ȃ�)
        SELECT xilv_out_tr_e.whse_code
              ,xilv_out_tr_e.mtl_organization_id
              ,xilv_out_tr_e.customer_stock_whse
              ,xilv_out_tr_e.inventory_location_id
              ,xilv_out_tr_e.segment1
              ,xilv_out_tr_e.description
              ,ximv_out_tr_e.item_id
              ,ximv_out_tr_e.item_no
              ,ximv_out_tr_e.item_name
              ,ximv_out_tr_e.item_short_name
              ,ximv_out_tr_e.num_of_cases
              ,ilm_out_tr_e.lot_id
              ,ilm_out_tr_e.lot_no
              ,ilm_out_tr_e.attribute1
              ,ilm_out_tr_e.attribute2
              ,ilm_out_tr_e.attribute3                                   -- <---- �����܂ŋ���
              ,xmrih_out_tr_e.actual_arrival_date
              ,xmrih_out_tr_e.actual_ship_date
              ,'2'                                     AS status        -- ����
              ,xrpm_out_tr_e.new_div_invent
              ,flv_out_tr_e.meaning
              ,xmrih_out_tr_e.mov_num
              ,xmrih_out_tr_e.ship_to_locat_id
              ,xilv_out_tr_e.description
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,0                                       AS stock_quantity
--mod start 2008/06/05 rev1.5
--              ,CASE
--                WHEN ( ximv_out_tr_e.lot_ctl = 1 ) THEN
--                  xmld_out_tr_e.actual_quantity                             -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_out_tr_e.lot_ctl = 0  ) THEN
--                  xmril_out_tr_e.shipped_quantity                           -- �񃍃b�g�Ǘ��i(���Ɏ��ѐ���)
--               END                                        leaving_quantity
--              ,xmld_out_tr_e.actual_quantity           leaving_quantity
              ,itc_out_tr_e.trans_qty                  AS leaving_quantity
--mod end 2008/06/05 rev1.5
              ,ximv_out_tr_e.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_tr_e                -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_out_tr_e                -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_tr_e                 -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_tr_e                -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_tr_e                 -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxinv_mov_req_instr_headers  xmrih_out_tr_e               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines    xmril_out_tr_e               -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_tr_e                -- �ړ����b�g�ڍ�(�A�h�I��)
              ,ic_tran_cmp                  itc_out_tr_e                 -- OPM�����݌Ƀg�����U�N�V����
              ,ic_adjs_jnl                  iaj_out_tr_e                 -- OPM�݌ɒ����W���[�i��
              ,ic_jrnl_mst                  ijm_out_tr_e                 -- OPM�W���[�i���}�X�^
        WHERE  xrpm_out_tr_e.doc_type                = 'TRNI'            -- �ړ��ϑ��Ȃ�
        AND    xrpm_out_tr_e.use_div_invent          = 'Y'
        AND    xmrih_out_tr_e.mov_hdr_id             = xmril_out_tr_e.mov_hdr_id
        AND    xmril_out_tr_e.item_id                = ximv_out_tr_e.item_id
--mod start 2008/06/04 rev1.1
--        AND    xmrih_out_tr_e.shipped_locat_id       = xilv_out_tr_e.segment1
        AND    xmrih_out_tr_e.shipped_locat_id       = xilv_out_tr_e.inventory_location_id
--mod end 2008/06/04 rev1.1
        AND    ilm_out_tr_e.item_id                  = xmril_out_tr_e.item_id
        AND    ilm_out_tr_e.lot_id                   = xmld_out_tr_e.lot_id
        AND    xmld_out_tr_e.mov_line_id             = xmril_out_tr_e.mov_line_id
        AND    xmld_out_tr_e.document_type_code      = '20'              -- �ړ�
        AND    xmld_out_tr_e.record_type_code        = '20'              -- �o�Ɏ���
        AND    xmrih_out_tr_e.mov_type               = '2'               -- �ϑ��Ȃ�
        AND    xmrih_out_tr_e.status                 = '06'              -- ���o�ɕ񍐗L
        AND    xmril_out_tr_e.delete_flg             = 'N'               -- OFF
        AND    TO_NUMBER( ijm_out_tr_e.attribute1 )  = xmril_out_tr_e.mov_line_id
        AND    iaj_out_tr_e.journal_id               = ijm_out_tr_e.journal_id
        AND    itc_out_tr_e.doc_type                 = iaj_out_tr_e.trans_type
        AND    itc_out_tr_e.doc_id                   = iaj_out_tr_e.doc_id
        AND    itc_out_tr_e.doc_line                 = iaj_out_tr_e.doc_line
--mod start 2008/06/05 
--        AND    itc_out_tr_e.whse_code                = xilv_out_tr_e.whse_code
        AND    itc_out_tr_e.location                 = xilv_out_tr_e.segment1
--mod end   2008/06/05 
        AND    itc_out_tr_e.item_id                  = ximv_out_tr_e.item_id
        AND    itc_out_tr_e.lot_id                   = ilm_out_tr_e.lot_id
        AND    xrpm_out_tr_e.doc_type                = itc_out_tr_e.doc_type
        AND    xrpm_out_tr_e.reason_code             = itc_out_tr_e.reason_code
        AND    xrpm_out_tr_e.rcv_pay_div             = SIGN( itc_out_tr_e.trans_qty )
        AND    flv_out_tr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_out_tr_e.language                 = 'JA'
        AND    flv_out_tr_e.lookup_code              = xrpm_out_tr_e.new_div_invent
*/
        UNION ALL
        -- ���Y�o�Ɏ���
        SELECT xilv_out_pr_e.whse_code
              ,xilv_out_pr_e.mtl_organization_id
              ,xilv_out_pr_e.customer_stock_whse
              ,xilv_out_pr_e.inventory_location_id
              ,xilv_out_pr_e.segment1
              ,xilv_out_pr_e.description
              ,ximv_out_pr_e.item_id
              ,ximv_out_pr_e.item_no
              ,ximv_out_pr_e.item_name
              ,ximv_out_pr_e.item_short_name
              ,ximv_out_pr_e.num_of_cases
              ,ilm_out_pr_e.lot_id
              ,ilm_out_pr_e.lot_no
              ,ilm_out_pr_e.attribute1
              ,ilm_out_pr_e.attribute2
              ,ilm_out_pr_e.attribute3                                    -- <---- �����܂ŋ���
              ,itp_out_pr_e.trans_date
              ,itp_out_pr_e.trans_date
              ,'2'                                     AS status         -- ����
              ,xrpm_out_pr_e.new_div_invent
              ,flv_out_pr_e.meaning
              ,gbh_out_pr_e.batch_no
              ,grb_out_pr_e.routing_id
--mod start 2008/06/07
--              ,grb_out_pr_e.routing_desc
              ,grt_out_pr_e.routing_desc
--mod start 2008/06/07
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,0                                       AS stock_quantity
--mod start 2008/06/05
--              ,itp_out_pr_e.trans_qty
              ,ABS(itp_out_pr_e.trans_qty)
--mod end 2008/06/05
              ,ximv_out_pr_e.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_pr_e                 -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_out_pr_e                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_pr_e                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_pr_e                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_pr_e                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,gme_batch_header             gbh_out_pr_e                  -- ���Y�o�b�`
              ,gme_material_details         gmd_out_pr_e                  -- ���Y�����ڍ�
              ,gmd_routings_b               grb_out_pr_e                  -- �H���}�X�^
--mod start 2008/06/07
              ,gmd_routings_tl              grt_out_pr_e                  -- �H���}�X�^���{��
              ,gmd_routing_class_b          grcb_out_pr_e                 -- �H���敪�}�X�^
              ,gmd_routing_class_tl         grct_out_pr_e                 -- �H���敪�}�X�^���{��
--mod end 2008/06/07
              ,ic_tran_pnd                  itp_out_pr_e                  -- OPM�ۗ��݌Ƀg�����U�N�V����
        WHERE  xrpm_out_pr_e.doc_type                = 'PROD'
        AND    xrpm_out_pr_e.use_div_invent          = 'Y'
        AND    itp_out_pr_e.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
        AND    gbh_out_pr_e.batch_id                 = gmd_out_pr_e.batch_id
        AND    gmd_out_pr_e.line_type                = -1                 -- �����i
        AND    itp_out_pr_e.completed_ind            = 1
        AND    itp_out_pr_e.reverse_id              IS NULL
        AND    itp_out_pr_e.doc_type                 = xrpm_out_pr_e.doc_type
        AND    itp_out_pr_e.item_id                  = ximv_out_pr_e.item_id
        AND    itp_out_pr_e.lot_id                   = ilm_out_pr_e.lot_id
--mod start 2008/06/05
--        AND    itp_out_pr_e.whse_code                = xilv_out_pr_e.whse_code
        AND    itp_out_pr_e.location                 = xilv_out_pr_e.segment1
--mod end 2008/06/05
        AND    itp_out_pr_e.location                 = xilv_out_pr_e.segment1
        AND    itp_out_pr_e.item_id                  = gmd_out_pr_e.item_id
        AND    itp_out_pr_e.doc_id                   = gmd_out_pr_e.batch_id
        AND    itp_out_pr_e.doc_line                 = gmd_out_pr_e.line_no
        AND    itp_out_pr_e.line_type                = gmd_out_pr_e.line_type
        AND    ilm_out_pr_e.item_id                  = ximv_out_pr_e.item_id
        AND    grb_out_pr_e.attribute9               = xilv_out_pr_e.segment1
        AND    grb_out_pr_e.routing_id               = gbh_out_pr_e.routing_id
        AND    xrpm_out_pr_e.routing_class           = grb_out_pr_e.routing_class
        AND    xrpm_out_pr_e.line_type               = gmd_out_pr_e.line_type
--mod start 2008/06/23
--        AND (( gmd_out_pr_e.attribute5              IS NULL )
--          OR ( xrpm_out_pr_e.hit_in_div              = gmd_out_pr_e.attribute5 ))
        AND ((( gmd_out_pr_e.attribute5              IS NULL )
          AND ( xrpm_out_pr_e.hit_in_div             IS NULL ))
        OR   (( gmd_out_pr_e.attribute5              IS NOT NULL )
          AND ( xrpm_out_pr_e.hit_in_div             = gmd_out_pr_e.attribute5 )))
--mod start 2008/06/23
        AND    flv_out_pr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_out_pr_e.language                 = 'JA'
        AND    flv_out_pr_e.lookup_code              = xrpm_out_pr_e.new_div_invent
--mod start 2008/06/07
        AND    grb_out_pr_e.routing_id               = grt_out_pr_e.routing_id
        AND    grt_out_pr_e.language                 = 'JA'
        AND    grct_out_pr_e.routing_class           = grcb_out_pr_e.routing_class
        AND    grcb_out_pr_e.routing_class           = grb_out_pr_e.routing_class
        AND    grct_out_pr_e.language                = 'JA'
        AND    grct_out_pr_e.routing_class_desc NOT IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
                                                       ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')
                                                       ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET'))
--mod end 2008/06/07
        UNION ALL
--mod start 2008/06/07
        -- ���Y�o�Ɏ��� �i�ڐU�� �i��U��
        SELECT xilv_out_pr_e70.whse_code
              ,xilv_out_pr_e70.mtl_organization_id
              ,xilv_out_pr_e70.customer_stock_whse
              ,xilv_out_pr_e70.inventory_location_id
              ,xilv_out_pr_e70.segment1
              ,xilv_out_pr_e70.description
              ,ximv_out_pr_e70.item_id
              ,ximv_out_pr_e70.item_no
              ,ximv_out_pr_e70.item_name
              ,ximv_out_pr_e70.item_short_name
              ,ximv_out_pr_e70.num_of_cases
              ,ilm_out_pr_e70.lot_id
              ,ilm_out_pr_e70.lot_no
              ,ilm_out_pr_e70.attribute1
              ,ilm_out_pr_e70.attribute2
              ,ilm_out_pr_e70.attribute3                                    -- <---- �����܂ŋ���
              ,itp_out_pr_e70.trans_date
              ,itp_out_pr_e70.trans_date
              ,'2'                                     AS status            -- ����
              ,xrpm_out_pr_e70.new_div_invent
              ,flv_out_pr_e70.meaning
              ,gbh_out_pr_e70.batch_no
              ,grb_out_pr_e70.routing_id
              ,grt_out_pr_e70.routing_desc
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,0                                       AS stock_quantity
              ,ABS(itp_out_pr_e70.trans_qty)
              ,ximv_out_pr_e70.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_pr_e70                 -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_out_pr_e70                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_pr_e70                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_pr_e70                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_pr_e70                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,gme_batch_header             gbh_out_pr_e70                  -- ���Y�o�b�`
              ,gme_material_details         gmd_out_pr_e70a                 -- ���Y�����ڍ�(�U�֌�)
              ,gme_material_details         gmd_out_pr_e70b                 -- ���Y�����ڍ�(�U�֐�)
              ,gmd_routings_b               grb_out_pr_e70                  -- �H���}�X�^
              ,gmd_routings_tl              grt_out_pr_e70                  -- �H���}�X�^���{��
              ,gmd_routing_class_b          grcb_out_pr_e70                 -- �H���敪�}�X�^
              ,gmd_routing_class_tl         grct_out_pr_e70                 -- �H���敪�}�X�^���{��
              ,ic_tran_pnd                  itp_out_pr_e70                  -- OPM�ۗ��݌Ƀg�����U�N�V����
              ,xxcmn_item_categories4_v     xicv_out_pr_e70a                -- OPM�i�ڃJ�e�S���������VIEW4(�U�֌�)
              ,xxcmn_item_categories4_v     xicv_out_pr_e70b                -- OPM�i�ڃJ�e�S���������VIEW4(�U�֐�)
        WHERE  xrpm_out_pr_e70.doc_type                = 'PROD'
        AND    xrpm_out_pr_e70.use_div_invent          = 'Y'
        AND    grct_out_pr_e70.language                = 'JA'
        AND    grct_out_pr_e70.routing_class           = grcb_out_pr_e70.routing_class
        AND    grcb_out_pr_e70.routing_class           = grb_out_pr_e70.routing_class
        AND    grt_out_pr_e70.language                 = 'JA'
        AND    grb_out_pr_e70.routing_id               = grt_out_pr_e70.routing_id
        AND    itp_out_pr_e70.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
        AND    gbh_out_pr_e70.batch_id                 = gmd_out_pr_e70a.batch_id
        AND    gmd_out_pr_e70a.line_type               = -1                 -- �����i
        AND    itp_out_pr_e70.doc_type                 = xrpm_out_pr_e70.doc_type
        AND    itp_out_pr_e70.doc_id                   = gmd_out_pr_e70a.batch_id
        AND    itp_out_pr_e70.doc_line                 = gmd_out_pr_e70a.line_no
        AND    itp_out_pr_e70.line_type                = gmd_out_pr_e70a.line_type
        AND    itp_out_pr_e70.completed_ind            = 1
        AND    itp_out_pr_e70.item_id                  = ximv_out_pr_e70.item_id
        AND    itp_out_pr_e70.lot_id                   = ilm_out_pr_e70.lot_id
        AND    itp_out_pr_e70.whse_code                = xilv_out_pr_e70.whse_code
        AND    itp_out_pr_e70.location                 = xilv_out_pr_e70.segment1
        AND    gmd_out_pr_e70a.item_id                 = ximv_out_pr_e70.item_id
        AND    ilm_out_pr_e70.item_id                  = ximv_out_pr_e70.item_id
        AND    grb_out_pr_e70.attribute9               = xilv_out_pr_e70.segment1
        AND    grb_out_pr_e70.routing_id               = gbh_out_pr_e70.routing_id
        AND    xrpm_out_pr_e70.routing_class           = grb_out_pr_e70.routing_class
        AND    xrpm_out_pr_e70.line_type               = gmd_out_pr_e70a.line_type
        AND    xicv_out_pr_e70a.item_id                = itp_out_pr_e70.item_id
        AND    grct_out_pr_e70.routing_class_desc      = FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
        AND   (xrpm_out_pr_e70.item_div_origin         = xicv_out_pr_e70a.item_class_code
        AND    xrpm_out_pr_e70.item_div_ahead          = xicv_out_pr_e70b.item_class_code
        AND  ((xicv_out_pr_e70a.item_class_code       <> xicv_out_pr_e70b.item_class_code)
        OR    (xicv_out_pr_e70a.item_class_code        = xicv_out_pr_e70b.item_class_code)))
        AND    gbh_out_pr_e70.batch_id                 = gmd_out_pr_e70b.batch_id
        AND    gmd_out_pr_e70a.batch_id                = gmd_out_pr_e70b.batch_id
        AND    gmd_out_pr_e70b.line_type               = 1                   -- �����i
        AND    gmd_out_pr_e70b.item_id                 = xicv_out_pr_e70b.item_id
        AND    flv_out_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_out_pr_e70.language                 = 'JA'
        AND    flv_out_pr_e70.lookup_code              = xrpm_out_pr_e70.new_div_invent
        UNION ALL
        -- ���Y�o�Ɏ��� ���
        SELECT xilv_out_pr_e70.whse_code
              ,xilv_out_pr_e70.mtl_organization_id
              ,xilv_out_pr_e70.customer_stock_whse
              ,xilv_out_pr_e70.inventory_location_id
              ,xilv_out_pr_e70.segment1
              ,xilv_out_pr_e70.description
              ,ximv_out_pr_e70.item_id
              ,ximv_out_pr_e70.item_no
              ,ximv_out_pr_e70.item_name
              ,ximv_out_pr_e70.item_short_name
              ,ximv_out_pr_e70.num_of_cases
              ,ilm_out_pr_e70.lot_id
              ,ilm_out_pr_e70.lot_no
              ,ilm_out_pr_e70.attribute1
              ,ilm_out_pr_e70.attribute2
              ,ilm_out_pr_e70.attribute3                                    -- <---- �����܂ŋ���
              ,itp_out_pr_e70.trans_date
              ,itp_out_pr_e70.trans_date
              ,'2'                                     AS status            -- ����
              ,xrpm_out_pr_e70.new_div_invent
              ,flv_out_pr_e70.meaning
              ,gbh_out_pr_e70.batch_no
              ,grb_out_pr_e70.routing_id
              ,grt_out_pr_e70.routing_desc
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS deliver_to_name
              ,0                                       AS stock_quantity
              ,ABS(itp_out_pr_e70.trans_qty)
              ,ximv_out_pr_e70.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_pr_e70                 -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_out_pr_e70                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_pr_e70                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_pr_e70                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_pr_e70                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,gme_batch_header             gbh_out_pr_e70                  -- ���Y�o�b�`
              ,gme_material_details         gmd_out_pr_e70                  -- ���Y�����ڍ�
              ,gmd_routings_b               grb_out_pr_e70                  -- �H���}�X�^
              ,gmd_routings_tl              grt_out_pr_e70                  -- �H���}�X�^���{��
              ,gmd_routing_class_b          grcb_out_pr_e70                 -- �H���敪�}�X�^
              ,gmd_routing_class_tl         grct_out_pr_e70                 -- �H���敪�}�X�^���{��
              ,ic_tran_pnd                  itp_out_pr_e70                  -- OPM�ۗ��݌Ƀg�����U�N�V����
              ,xxcmn_item_categories4_v     xicv_out_pr_e70                 -- OPM�i�ڃJ�e�S���������VIEW4
        WHERE  xrpm_out_pr_e70.doc_type                = 'PROD'
        AND    xrpm_out_pr_e70.use_div_invent          = 'Y'
        AND    grct_out_pr_e70.language                = 'JA'
        AND    grct_out_pr_e70.routing_class           = grcb_out_pr_e70.routing_class
        AND    grcb_out_pr_e70.routing_class           = grb_out_pr_e70.routing_class
        AND    grt_out_pr_e70.language                 = 'JA'
        AND    grb_out_pr_e70.routing_id               = grt_out_pr_e70.routing_id
        AND    itp_out_pr_e70.delete_mark              = 0                  -- �L���`�F�b�N(OPM�ۗ��݌�)
        AND    gbh_out_pr_e70.batch_id                 = gmd_out_pr_e70.batch_id
        AND    gmd_out_pr_e70.line_type                = -1                 -- �����i
        AND    itp_out_pr_e70.doc_type                 = xrpm_out_pr_e70.doc_type
        AND    itp_out_pr_e70.doc_id                   = gmd_out_pr_e70.batch_id
        AND    itp_out_pr_e70.doc_line                 = gmd_out_pr_e70.line_no
        AND    itp_out_pr_e70.line_type                = gmd_out_pr_e70.line_type
        AND    itp_out_pr_e70.completed_ind            = 1
        AND    itp_out_pr_e70.item_id                  = ximv_out_pr_e70.item_id
        AND    itp_out_pr_e70.lot_id                   = ilm_out_pr_e70.lot_id
        AND    itp_out_pr_e70.whse_code                = xilv_out_pr_e70.whse_code
        AND    itp_out_pr_e70.location                 = xilv_out_pr_e70.segment1
        AND    gmd_out_pr_e70.item_id                  = ximv_out_pr_e70.item_id
        AND    ilm_out_pr_e70.item_id                  = ximv_out_pr_e70.item_id
        AND    grb_out_pr_e70.attribute9               = xilv_out_pr_e70.segment1
        AND    grb_out_pr_e70.routing_id               = gbh_out_pr_e70.routing_id
        AND    xrpm_out_pr_e70.routing_class           = grb_out_pr_e70.routing_class
        AND    xrpm_out_pr_e70.line_type               = gmd_out_pr_e70.line_type
        AND    xicv_out_pr_e70.item_id                 = itp_out_pr_e70.item_id
        AND    grct_out_pr_e70.routing_class_desc      IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')
                                                          ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET'))
        AND    flv_out_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
        AND    flv_out_pr_e70.language                 = 'JA'
        AND    flv_out_pr_e70.lookup_code              = xrpm_out_pr_e70.new_div_invent
--mod end 2008/06/07
        UNION ALL
        -- �󒍏o�׎���
        SELECT xilv_out_om_e.whse_code
              ,xilv_out_om_e.mtl_organization_id
              ,xilv_out_om_e.customer_stock_whse
              ,xilv_out_om_e.inventory_location_id
              ,xilv_out_om_e.segment1
              ,xilv_out_om_e.description
--mod start 2008/06/04 rev1.4
--              ,ximv_out_om_e.item_id
--              ,ximv_out_om_e.item_no
--              ,ximv_out_om_e.item_name
--              ,ximv_out_om_e.item_short_name
--              ,ximv_out_om_e.num_of_cases
              ,ximv_out_om_e_s.item_id
              ,ximv_out_om_e_s.item_no
              ,ximv_out_om_e_s.item_name
              ,ximv_out_om_e_s.item_short_name
              ,ximv_out_om_e_s.num_of_cases
--mod end 2008/06/04 rev1.4
              ,ilm_out_om_e.lot_id
              ,ilm_out_om_e.lot_no
              ,ilm_out_om_e.attribute1
              ,ilm_out_om_e.attribute2
              ,ilm_out_om_e.attribute3                                    -- <---- �����܂ŋ���
              ,xoha_out_om_e.arrival_date
              ,xoha_out_om_e.shipped_date
              ,'2'                                     AS status          -- ����
              ,xrpm_out_om_e.new_div_invent
              ,flv_out_om_e.meaning
              ,xoha_out_om_e.request_no
              ,TO_NUMBER( xoha_out_om_e.head_sales_branch )
              ,xcav_out_om_e.party_name
--mod start 2008/06/09
--              ,xoha_out_om_e.deliver_to_id
              ,xoha_out_om_e.result_deliver_to_id
--mod end 2008/06/09
              ,xpsv_out_om_e.party_site_full_name
              ,0                                       AS stock_quantity
--mod start 2008/06/05 rev1.5
--              ,CASE
--                WHEN ( ximv_out_om_e.lot_ctl = 1 ) THEN
--                  xmld_out_om_e.actual_quantity                           -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_out_om_e.lot_ctl = 0  ) THEN
--                  xola_out_om_e.quantity                                  -- �񃍃b�g�Ǘ��i(����)
--               END                                        leaving_quantity
              ,xmld_out_om_e.actual_quantity           AS leaving_quantity
--mod end 2008/06/05 rev1.5
--mod start 2008/06/04 rev1.4
--              ,ximv_out_om_e.lot_ctl
              ,ximv_out_om_e_s.lot_ctl
--mod end 2008/06/04 rev1.4
        FROM   xxcmn_item_locations_v       xilv_out_om_e                 -- OPM�ۊǏꏊ���VIEW
--mod start 2008/06/04 rev1.4
--              ,xxcmn_item_mst_v             ximv_out_om_e                 -- OPM�i�ڏ��VIEW
              ,xxcmn_item_mst_v             ximv_out_om_e_s               -- OPM�i�ڏ��VIEW(�o�וi��)
              ,xxcmn_item_mst_v             ximv_out_om_e_r               -- OPM�i�ڏ��VIEW(�˗��i��)
--mod end 2008/06/04 rev1.4
              ,ic_lots_mst                  ilm_out_om_e                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_om_e                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_om_e                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxwsh_order_headers_all      xoha_out_om_e                 -- �󒍃w�b�_(�A�h�I��)
              ,xxwsh_order_lines_all        xola_out_om_e                 -- �󒍖���(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_om_e                 -- �ړ����b�g�ڍ�(�A�h�I��)
              ,oe_transaction_types_all     otta_out_om_e                 -- �󒍃^�C�v
              ,xxcmn_cust_accounts_v        xcav_out_om_e                 -- �ڋq���VIEW
              ,xxcmn_party_sites_v          xpsv_out_om_e                 -- �p�[�e�B�T�C�g���VIEW
--mod start 2008/06/04 rev1.4
--              ,xxcmn_item_categories4_v     xicv_out_om_e                 -- OPM�i�ڃJ�e�S���������VIEW4
              ,xxcmn_item_categories4_v     xicv_out_om_e_s               -- OPM�i�ڃJ�e�S���������VIEW4(�o�וi��)
              ,xxcmn_item_categories4_v     xicv_out_om_e_r               -- OPM�i�ڃJ�e�S���������VIEW4(�˗��i��)
--mod end 2008/06/04 rev1.4
        WHERE  xrpm_out_om_e.doc_type                         = 'OMSO'
        AND    xrpm_out_om_e.use_div_invent                   = 'Y'
--mod start 2008/06/09
        AND    otta_out_om_e.order_category_code              = 'ORDER'
--mod end 2008/06/09
        AND    xoha_out_om_e.order_header_id                  = xola_out_om_e.order_header_id
--mod start 2008/06/04 rev1.1
--        AND    xoha_out_om_e.deliver_from_id                  = xilv_out_om_e.segment1
        AND    xoha_out_om_e.deliver_from_id                  = xilv_out_om_e.inventory_location_id
--mod end 2008/06/04 rev1.1
--mod start 2008/06/04 rev1.4
--        AND    xola_out_om_e.shipping_inventory_item_id       = ximv_out_om_e.inventory_item_id
--        AND    ilm_out_om_e.item_id                           = ximv_out_om_e.item_id
        AND    xola_out_om_e.shipping_inventory_item_id       = ximv_out_om_e_s.inventory_item_id
--add start 2008/06/04 rev1.4
        AND    xola_out_om_e.request_item_id                  = ximv_out_om_e_r.inventory_item_id
--add end 2008/06/04 rev1.4
        AND    ilm_out_om_e.item_id                           = ximv_out_om_e_s.item_id
--mod end 2008/06/04 rev1.4
        AND    xmld_out_om_e.mov_line_id                      = xola_out_om_e.order_line_id
        AND    xmld_out_om_e.document_type_code               = '10'      -- �o�׈˗�
        AND    xmld_out_om_e.record_type_code                 = '20'      -- �o�Ɏ���
--mod start 2008/06/04 rev1.4
--        AND (( ximv_out_om_e.lot_ctl                          = 1         -- ���b�g�Ǘ��i
--           AND ximv_out_om_e.item_id                          = xmld_out_om_e.item_id
--           AND xmld_out_om_e.lot_id                           = ilm_out_om_e.lot_id )
--          OR ( ximv_out_om_e.lot_ctl                          = 0 ))      -- �񃍃b�g�Ǘ��i
--mod start 2008/06/07
--        AND (( ximv_out_om_e_s.lot_ctl                        = 1         -- ���b�g�Ǘ��i
--           AND ximv_out_om_e_s.item_id                        = xmld_out_om_e.item_id
--           AND xmld_out_om_e.lot_id                           = ilm_out_om_e.lot_id )
--          OR ( ximv_out_om_e_s.lot_ctl                        = 0 ))      -- �񃍃b�g�Ǘ��i
--        AND ximv_out_om_e_s.item_id                           = xmld_out_om_e.item_id
        AND xmld_out_om_e.lot_id                              = ilm_out_om_e.lot_id
        AND ximv_out_om_e_s.item_id                           = ilm_out_om_e.item_id
--mod end 2008/06/07
--mod end 2008/06/04 rev1.4
        AND    xoha_out_om_e.req_status                       = '04'      -- �o�׎��ьv���
        AND    xoha_out_om_e.latest_external_flag             = 'Y'       -- ON
        AND    xola_out_om_e.delete_flag                      = 'N'       -- OFF
        AND    otta_out_om_e.attribute1                       = '1'       -- �o�׈˗�
        AND    xoha_out_om_e.order_type_id                    = otta_out_om_e.transaction_type_id
        AND    xrpm_out_om_e.shipment_provision_div           = otta_out_om_e.attribute1
--mod start 2008/06/04 rev1.4
--        AND    xicv_out_om_e.item_id                          = ximv_out_om_e.item_id
        AND    xicv_out_om_e_s.item_id                        = ximv_out_om_e_s.item_id
        AND    xicv_out_om_e_r.item_id                        = ximv_out_om_e_r.item_id
--mod end 2008/06/04 rev1.4
--mod start 2008/06/04
--        AND    NVL(xrpm_out_om_e.item_div_ahead, xicv_out_om_e.item_class_code)
--                                                              = xicv_out_om_e.item_class_code
--        AND    NVL(xrpm_out_om_e.item_div_origin, xicv_out_om_e.item_class_code)
--                                                              = xicv_out_om_e.item_class_code
        AND NVL(xrpm_out_om_e.item_div_origin,'Dummy')        = DECODE(xicv_out_om_e_s.item_class_code,'5','5','Dummy') --�U�֌��i�ڋ敪 = �o�וi�ڋ敪
        AND NVL(xrpm_out_om_e.item_div_ahead ,'Dummy')        = DECODE(xicv_out_om_e_r.item_class_code,'5','5','Dummy') --�U�֐�i�ڋ敪 = �˗��i�ڋ敪
        AND (xrpm_out_om_e.ship_prov_rcv_pay_category         = otta_out_om_e.attribute11
          OR xrpm_out_om_e.ship_prov_rcv_pay_category        IS NULL)
--mod end 2008/06/04
        AND    flv_out_om_e.lookup_type                       = 'XXCMN_NEW_DIVISION'
        AND    flv_out_om_e.language                          = 'JA'
        AND    flv_out_om_e.lookup_code                       = xrpm_out_om_e.new_div_invent
        AND    xoha_out_om_e.customer_id                      = xcav_out_om_e.party_id
--mod start 2008/06/09
--        AND    xoha_out_om_e.deliver_to_id                    = xpsv_out_om_e.party_site_id
        AND    xoha_out_om_e.result_deliver_to_id             = xpsv_out_om_e.party_site_id
--mod end 2008/06/09
--mod start 2008/06/10
        AND    xrpm_out_om_e.stock_adjustment_div             = otta_out_om_e.attribute4
        AND    xrpm_out_om_e.stock_adjustment_div             = '1'
--mod end 2008/06/10
        UNION ALL
        -- �L���o�׎���
        SELECT xilv_out_om2_e.whse_code
              ,xilv_out_om2_e.mtl_organization_id
              ,xilv_out_om2_e.customer_stock_whse
              ,xilv_out_om2_e.inventory_location_id
              ,xilv_out_om2_e.segment1
              ,xilv_out_om2_e.description
--mod start 2008/06/04 rev1.4
--              ,ximv_out_om2_e.item_id
--              ,ximv_out_om2_e.item_no
--              ,ximv_out_om2_e.item_name
--              ,ximv_out_om2_e.item_short_name
--              ,ximv_out_om2_e.num_of_cases
              ,ximv_out_om2_e_s.item_id
              ,ximv_out_om2_e_s.item_no
              ,ximv_out_om2_e_s.item_name
              ,ximv_out_om2_e_s.item_short_name
              ,ximv_out_om2_e_s.num_of_cases
--mod end 2008/06/04 rev1.4
              ,ilm_out_om2_e.lot_id
              ,ilm_out_om2_e.lot_no
              ,ilm_out_om2_e.attribute1
              ,ilm_out_om2_e.attribute2
              ,ilm_out_om2_e.attribute3                                    -- <---- �����܂ŋ���
              ,xoha_out_om2_e.arrival_date
              ,xoha_out_om2_e.shipped_date
              ,'2'                                     AS status           -- ����
              ,xrpm_out_om2_e.new_div_invent
              ,flv_out_om2_e.meaning
              ,xoha_out_om2_e.request_no
--mod start 2008/06/09
--              ,xoha_out_om2_e.deliver_to_id
              ,xoha_out_om2_e.vendor_site_id
--mod start 2008/06/04 rev1.3
--              ,xpsv_out_om2_e.party_site_full_name
              ,xvsv_out_om2_e.vendor_site_name
--mod start 2008/06/05 rev1.8
----mod end 2008/06/04 rev1.3
--              ,xoha_out_om2_e.deliver_to_id
----mod start 2008/06/04 rev1.3
----              ,xpsv_out_om2_e.party_site_full_name
--              ,xvsv_out_om2_e.vendor_site_name
----mod end 2008/06/04 rev1.3
              ,NULL                                    AS deliver_to_id
              ,NULL                                    AS vendor_site_name
--mod end 2008/06/05 rev1.8
              ,0                                       AS stock_quantity
--mod start 2008/06/05 rev1.5
----mod start 2008/06/04 rev1.4
----              ,CASE
----                WHEN ( ximv_out_om2_e.lot_ctl = 1 ) THEN
----                  xmld_out_om2_e.actual_quantity                           -- ���b�g�Ǘ��i(���ѐ���)
----                WHEN ( ximv_out_om2_e.lot_ctl = 0  ) THEN
----                  xola_out_om2_e.quantity                                  -- �񃍃b�g�Ǘ��i(����)
----               END                                        leaving_quantity
----              ,ximv_out_om2_e.lot_ctl
--                WHEN ( ximv_out_om2_e_s.lot_ctl = 1 ) THEN
--                  xmld_out_om2_e.actual_quantity                           -- ���b�g�Ǘ��i(���ѐ���)
--                WHEN ( ximv_out_om2_e_s.lot_ctl = 0  ) THEN
--                  xola_out_om2_e.quantity                                  -- �񃍃b�g�Ǘ��i(����)
--               END                                        leaving_quantity
              ,xmld_out_om2_e.actual_quantity          AS leaving_quantity
--mod end 2008/06/05 rev1.5
              ,ximv_out_om2_e_s.lot_ctl
--mod end 2008/06/04 rev1.4
        FROM   xxcmn_item_locations_v       xilv_out_om2_e                 -- OPM�ۊǏꏊ���VIEW
--mod start 2008/06/04 rev1.4
--              ,xxcmn_item_mst_v             ximv_out_om2_e                 -- OPM�i�ڏ��VIEW
              ,xxcmn_item_mst_v             ximv_out_om2_e_s               -- OPM�i�ڏ��VIEW(�o�וi��)
              ,xxcmn_item_mst_v             ximv_out_om2_e_r               -- OPM�i�ڏ��VIEW(�˗��i��)
--mod end 2008/06/04 rev1.4
              ,ic_lots_mst                  ilm_out_om2_e                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_om2_e                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_om2_e                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxwsh_order_headers_all      xoha_out_om2_e                 -- �󒍃w�b�_(�A�h�I��)
              ,xxwsh_order_lines_all        xola_out_om2_e                 -- �󒍖���(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_om2_e                 -- �ړ����b�g�ڍ�(�A�h�I��)
              ,oe_transaction_types_all     otta_out_om2_e                 -- �󒍃^�C�v
--mod start 2008/06/04 rev1.3
--              ,xxcmn_party_sites_v          xpsv_out_om2_e                 -- �p�[�e�B�T�C�g���VIEW
              ,xxcmn_vendor_sites_v         xvsv_out_om2_e                 -- �d����T�C�g���VIEW
--mod end 2008/06/04 rev1.3
--mod start 2008/06/04 rev1.4
--              ,xxcmn_item_categories4_v     xicv_out_om2_e                 -- OPM�i�ڃJ�e�S���������VIEW4
              ,xxcmn_item_categories4_v     xicv_out_om2_e_s               -- OPM�i�ڃJ�e�S���������VIEW4(�o�וi��)
              ,xxcmn_item_categories4_v     xicv_out_om2_e_r               -- OPM�i�ڃJ�e�S���������VIEW4(�˗��i��)
--mod end 2008/06/04 rev1.4
--mod start 2008/06/09
--        WHERE  xrpm_out_om2_e.doc_type                         = 'OMSO'
        WHERE ((xrpm_out_om2_e.doc_type                        = 'OMSO'
          AND   otta_out_om2_e.order_category_code             = 'ORDER')
        OR     (xrpm_out_om2_e.doc_type                        = 'PORC'
          AND   xrpm_out_om2_e.source_document_code            = 'RMA'
          AND   otta_out_om2_e.order_category_code             = 'RETURN'))
--mod end 2008/06/09
        AND    xrpm_out_om2_e.use_div_invent                   = 'Y'
        AND    xoha_out_om2_e.order_header_id                  = xola_out_om2_e.order_header_id
--mod start 2008/06/04 rev1.1
--        AND    xoha_out_om2_e.deliver_from_id                  = xilv_out_om2_e.segment1
        AND    xoha_out_om2_e.deliver_from_id                  = xilv_out_om2_e.inventory_location_id
--mod end 2008/06/04 rev1.1
--mod start 2008/06/04 rev1.4
--        AND    xola_out_om2_e.shipping_inventory_item_id       = ximv_out_om2_e.inventory_item_id
--        AND    ilm_out_om2_e.item_id                           = ximv_out_om2_e.item_id
        AND    xola_out_om2_e.shipping_inventory_item_id       = ximv_out_om2_e_s.inventory_item_id
--add start 2008/06/04 rev1.4
        AND    xola_out_om2_e.request_item_id                  = ximv_out_om2_e_r.inventory_item_id
--add end 2008/06/04 rev1.4
        AND    ilm_out_om2_e.item_id                           = ximv_out_om2_e_s.item_id
--mod end 2008/06/04 rev1.4
        AND    xmld_out_om2_e.mov_line_id                      = xola_out_om2_e.order_line_id
        AND    xmld_out_om2_e.document_type_code               = '30'      -- �x���w��
        AND    xmld_out_om2_e.record_type_code                 = '20'      -- �o�Ɏ���
--mod start 2008/06/04 rev1.4
--        AND (( ximv_out_om2_e.lot_ctl                          = 1         -- ���b�g�Ǘ��i
--           AND ximv_out_om2_e.item_id                          = xmld_out_om2_e.item_id
--           AND xmld_out_om2_e.lot_id                           = ilm_out_om2_e.lot_id )
--          OR ( ximv_out_om2_e.lot_ctl                          = 0 ))      -- �񃍃b�g�Ǘ��i
--mod start 2008/06/07
--        AND (( ximv_out_om2_e_s.lot_ctl                          = 1         -- ���b�g�Ǘ��i
--           AND ximv_out_om2_e_s.item_id                          = xmld_out_om2_e.item_id
--           AND xmld_out_om2_e.lot_id                           = ilm_out_om2_e.lot_id )
--          OR ( ximv_out_om2_e_s.lot_ctl                          = 0 ))      -- �񃍃b�g�Ǘ��i
--        AND ximv_out_om2_e_s.item_id                           = xmld_out_om2_e.item_id
        AND xmld_out_om2_e.lot_id                              = ilm_out_om2_e.lot_id
--        AND xmld_out_om2_e.item_id                             = ilm_out_om2_e.item_id
--mod end 2008/06/07
--mod end 2008/06/04 rev1.4
--mod start 2008/06/04 rev1.2
--        AND    xoha_out_om2_e.req_status                       = '04'      -- �o�׎��ьv���
        AND    xoha_out_om2_e.req_status                       = '08'      -- �o�׎��ьv���
--mod end 2008/06/04 rev1.2
        AND    xoha_out_om2_e.latest_external_flag             = 'Y'       -- ON
        AND    xola_out_om2_e.delete_flag                      = 'N'       -- OFF
        AND    otta_out_om2_e.attribute1                       = '2'       -- �x���˗�
        AND    xoha_out_om2_e.order_type_id                    = otta_out_om2_e.transaction_type_id
        AND    xrpm_out_om2_e.shipment_provision_div           = otta_out_om2_e.attribute1
--mod start 2008/06/04 rev1.4
--        AND    xicv_out_om2_e.item_id                          = ximv_out_om2_e.item_id
        AND   xicv_out_om2_e_s.item_id                         =  ximv_out_om2_e_s.item_id
        AND   xicv_out_om2_e_r.item_id                         =  ximv_out_om2_e_r.item_id
--mod end 2008/06/04 rev1.4
--mod start 2008/06/04
--        AND    NVL(xrpm_out_om2_e.item_div_ahead, xicv_out_om2_e.item_class_code)
--                                                               = xicv_out_om2_e.item_class_code
--        AND    NVL(xrpm_out_om2_e.item_div_origin, xicv_out_om2_e.item_class_code)
--                                                               = xicv_out_om2_e.item_class_code
        AND NVL(xrpm_out_om2_e.item_div_origin,'Dummy')        = DECODE(xicv_out_om2_e_s.item_class_code,'5','5','Dummy') --�U�֌��i�ڋ敪 = �o�וi�ڋ敪
        AND NVL(xrpm_out_om2_e.item_div_ahead ,'Dummy')        = DECODE(xicv_out_om2_e_r.item_class_code,'5','5','Dummy') --�U�֐�i�ڋ敪 = �˗��i�ڋ敪
--mod start 2008/06/10
        AND  ((xola_out_om2_e.shipping_inventory_item_id       = xola_out_om2_e.request_item_id
          AND   xrpm_out_om2_e.prod_div_origin                IS NULL
          AND   xrpm_out_om2_e.prod_div_ahead                 IS NULL )
        OR     (xola_out_om2_e.shipping_inventory_item_id     <> xola_out_om2_e.request_item_id
          AND   xicv_out_om2_e_s.item_class_code               = '5'
          AND   xicv_out_om2_e_r.item_class_code               = '5'
          AND   xrpm_out_om2_e.prod_div_origin                IS NOT NULL
          AND   xrpm_out_om2_e.prod_div_ahead                 IS NOT NULL )
        OR     (xola_out_om2_e.shipping_inventory_item_id     <> xola_out_om2_e.request_item_id
          AND  (xicv_out_om2_e_s.item_class_code              <> '5'
          OR    xicv_out_om2_e_r.item_class_code              <> '5')
          AND   xrpm_out_om2_e.prod_div_origin                IS NULL
          AND   xrpm_out_om2_e.prod_div_ahead                 IS NULL ))
--mod end   2008/06/10
        AND (xrpm_out_om2_e.ship_prov_rcv_pay_category         = otta_out_om2_e.attribute11 
          OR xrpm_out_om2_e.ship_prov_rcv_pay_category        IS NULL)
--mod end 2008/06/04
        AND    flv_out_om2_e.lookup_type                       = 'XXCMN_NEW_DIVISION'
        AND    flv_out_om2_e.language                          = 'JA'
        AND    flv_out_om2_e.lookup_code                       = xrpm_out_om2_e.new_div_invent
--mod start 2008/06/04 rev1.3
--        AND    xoha_out_om2_e.deliver_to_id                    = xpsv_out_om2_e.party_site_id
        AND    xvsv_out_om2_e.vendor_site_id                   = xoha_out_om2_e.vendor_site_id
--mod end 2008/06/04 rev1.3
        UNION ALL
        -- �݌ɒ��� �o�Ɏ���(�o�� ���{�o�� �p�p�o��)
        SELECT xilv_out_om3_e.whse_code
              ,xilv_out_om3_e.mtl_organization_id
              ,xilv_out_om3_e.customer_stock_whse
              ,xilv_out_om3_e.inventory_location_id
              ,xilv_out_om3_e.segment1
              ,xilv_out_om3_e.description
              ,ximv_out_om3_e.item_id
              ,ximv_out_om3_e.item_no
              ,ximv_out_om3_e.item_name
              ,ximv_out_om3_e.item_short_name
              ,ximv_out_om3_e.num_of_cases
              ,ilm_out_om3_e.lot_id
              ,ilm_out_om3_e.lot_no
              ,ilm_out_om3_e.attribute1
              ,ilm_out_om3_e.attribute2
              ,ilm_out_om3_e.attribute3                                    -- <---- �����܂ŋ���
              ,xoha_out_om3_e.shipped_date
              ,xoha_out_om3_e.shipped_date
              ,'2'                                     AS status          -- ����
              ,xrpm_out_om3_e.new_div_invent
              ,flv_out_om3_e.meaning
              ,xoha_out_om3_e.request_no
              ,TO_NUMBER( xoha_out_om3_e.head_sales_branch )
              ,xcav_out_om3_e.party_name
              ,xoha_out_om3_e.result_deliver_to_id
              ,xpsv_out_om3_e.party_site_full_name
              ,0                                      AS stock_quantity
              ,xmld_out_om3_e.actual_quantity         AS leaving_quantity
              ,ximv_out_om3_e.lot_ctl
        FROM   xxcmn_item_locations_v       xilv_out_om3_e                 -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v             ximv_out_om3_e                 -- OPM�i�ڏ��VIEW
              ,ic_lots_mst                  ilm_out_om3_e                  -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst            xrpm_out_om3_e                 -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values            flv_out_om3_e                  -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,xxwsh_order_headers_all      xoha_out_om3_e                 -- �󒍃w�b�_(�A�h�I��)
              ,xxwsh_order_lines_all        xola_out_om3_e                 -- �󒍖���(�A�h�I��)
              ,xxinv_mov_lot_details        xmld_out_om3_e                 -- �ړ����b�g�ڍ�(�A�h�I��)
              ,oe_transaction_types_all     otta_out_om3_e                 -- �󒍃^�C�v
              ,xxcmn_cust_accounts_v        xcav_out_om3_e                 -- �ڋq���VIEW
              ,xxcmn_party_sites_v          xpsv_out_om3_e                 -- �p�[�e�B�T�C�g���VIEW
              ,xxcmn_item_categories4_v     xicv_out_om3_e                 -- OPM�i�ڃJ�e�S���������VIEW4
        WHERE  xrpm_out_om3_e.doc_type                         = 'OMSO'
        AND    xrpm_out_om3_e.use_div_invent                   = 'Y'
        AND    otta_out_om3_e.order_category_code              = 'ORDER'
        AND    xoha_out_om3_e.order_header_id                  = xola_out_om3_e.order_header_id
        AND    xoha_out_om3_e.deliver_from_id                  = xilv_out_om3_e.inventory_location_id
        AND    xola_out_om3_e.shipping_inventory_item_id       = ximv_out_om3_e.inventory_item_id
        AND    ilm_out_om3_e.item_id                           = ximv_out_om3_e.item_id
        AND    xmld_out_om3_e.mov_line_id                      = xola_out_om3_e.order_line_id
        AND    xmld_out_om3_e.document_type_code               = '10'      -- �o�׈˗�
        AND    xmld_out_om3_e.record_type_code                 = '20'      -- �o�Ɏ���
        AND    xmld_out_om3_e.lot_id                           = ilm_out_om3_e.lot_id
        AND    xoha_out_om3_e.req_status                       = '04'      -- �o�׎��ьv���
        AND    xoha_out_om3_e.latest_external_flag             = 'Y'       -- ON
        AND    xola_out_om3_e.delete_flag                      = 'N'       -- OFF
        AND    otta_out_om3_e.attribute1                       = '1'       -- �o�׈˗�
        AND    xoha_out_om3_e.order_type_id                    = otta_out_om3_e.transaction_type_id
        AND    xrpm_out_om3_e.stock_adjustment_div             = otta_out_om3_e.attribute4
        AND    xrpm_out_om3_e.stock_adjustment_div             = '2'
        AND    xicv_out_om3_e.item_id                          = ximv_out_om3_e.item_id
        AND    xrpm_out_om3_e.ship_prov_rcv_pay_category       = otta_out_om3_e.attribute11
        AND    xrpm_out_om3_e.ship_prov_rcv_pay_category      IN ( '01' , '02' )
        AND    flv_out_om3_e.lookup_type                       = 'XXCMN_NEW_DIVISION'
        AND    flv_out_om3_e.language                          = 'JA'
        AND    flv_out_om3_e.lookup_code                       = xrpm_out_om3_e.new_div_invent
        AND    xoha_out_om3_e.customer_id                      = xcav_out_om3_e.party_id
        AND    xoha_out_om3_e.result_deliver_to_id             = xpsv_out_om3_e.party_site_id
        UNION ALL
        -- �݌ɒ��� �o�Ɏ���(�����݌�)
        SELECT xilv_out_ad_e_x97.whse_code
              ,xilv_out_ad_e_x97.mtl_organization_id
              ,xilv_out_ad_e_x97.customer_stock_whse
              ,xilv_out_ad_e_x97.inventory_location_id
              ,xilv_out_ad_e_x97.segment1
              ,xilv_out_ad_e_x97.description
              ,ximv_out_ad_e_x97.item_id
              ,ximv_out_ad_e_x97.item_no
              ,ximv_out_ad_e_x97.item_name
              ,ximv_out_ad_e_x97.item_short_name
              ,ximv_out_ad_e_x97.num_of_cases
              ,ilm_out_ad_e_x97.lot_id
              ,ilm_out_ad_e_x97.lot_no
              ,ilm_out_ad_e_x97.attribute1
              ,ilm_out_ad_e_x97.attribute2
              ,ilm_out_ad_e_x97.attribute3                                     -- <---- �����܂ŋ���
              ,itc_out_ad_e_x97.trans_date
              ,itc_out_ad_e_x97.trans_date
              ,'2'                                            AS status        -- ����
              ,xrpm_out_ad_e_x97.new_div_invent
              ,flv_out_ad_e_x97.meaning
              ,NULL                                           AS voucher_no
--mod start 2008/06/06
--              ,TO_NUMBER( pla_out_ad_e_x97.attribute12)       AS ukebaraisaki_id
              ,xilv_out_ad_e_x97.inventory_location_id        AS ukebaraisaki_id
--mod end 2008/06/06
              ,xilv_out_ad_e_x97.description
              ,NULL                                           AS deliver_to_id
              ,NULL                                           AS deliver_to_name
              ,0                                              AS stock_quantity
--mod start 2008/06/05
--              ,itc_out_ad_e_x97.trans_qty
              ,ABS(itc_out_ad_e_x97.trans_qty)
--mod end 2008/06/05
              ,ximv_out_ad_e_x97.lot_ctl
        FROM   xxcmn_item_locations_v  xilv_out_ad_e_x97                       -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v        ximv_out_ad_e_x97                       -- OPM�i�ڏ��VIEW
              ,ic_lots_mst             ilm_out_ad_e_x97                        -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst       xrpm_out_ad_e_x97                       -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values       flv_out_ad_e_x97                        -- �N�C�b�N�R�[�h <---- �����܂ŋ���
--del start 2008/06/06
--              ,po_headers_all          pha_out_ad_e_x97                        -- �����w�b�_
--              ,po_lines_all            pla_out_ad_e_x97                        -- ��������
--del end 2008/06/06
              ,ic_tran_cmp             itc_out_ad_e_x97                        -- OPM�����݌Ƀg�����U�N�V����
        WHERE  xrpm_out_ad_e_x97.doc_type               = 'ADJI'
        AND    xrpm_out_ad_e_x97.reason_code            = 'X977'               -- �����݌�
        AND    xrpm_out_ad_e_x97.rcv_pay_div            = '-1'                 -- ���o
        AND    xrpm_out_ad_e_x97.use_div_invent         = 'Y'
        AND    itc_out_ad_e_x97.reason_code             = xrpm_out_ad_e_x97.reason_code
        AND    SIGN( itc_out_ad_e_x97.trans_qty )       = xrpm_out_ad_e_x97.rcv_pay_div
        AND    itc_out_ad_e_x97.item_id                 = ximv_out_ad_e_x97.item_id
        AND    ilm_out_ad_e_x97.item_id                 = ximv_out_ad_e_x97.item_id
        AND    itc_out_ad_e_x97.lot_id                  = ilm_out_ad_e_x97.lot_id
        AND    itc_out_ad_e_x97.whse_code               = xilv_out_ad_e_x97.whse_code
        AND    itc_out_ad_e_x97.location                = xilv_out_ad_e_x97.segment1
--del start 2008/06/06
--        AND    pha_out_ad_e_x97.po_header_id            = pla_out_ad_e_x97.po_header_id
--        AND    pla_out_ad_e_x97.item_id                 = ximv_out_ad_e_x97.inventory_item_id
--        AND    pla_out_ad_e_x97.attribute12             = xilv_out_ad_e_x97.segment1
--del end 2008/06/06
        AND    flv_out_ad_e_x97.lookup_type             = 'XXCMN_NEW_DIVISION'
        AND    flv_out_ad_e_x97.language                = 'JA'
        AND    flv_out_ad_e_x97.lookup_code             = xrpm_out_ad_e_x97.new_div_invent
--mod start 2008/06/06
        UNION ALL
        -- �݌ɒ��� �o�Ɏ���(�d����ԕi)
        SELECT xilv_out_ad_e_x2.whse_code
              ,xilv_out_ad_e_x2.mtl_organization_id
              ,xilv_out_ad_e_x2.customer_stock_whse
              ,xilv_out_ad_e_x2.inventory_location_id
              ,xilv_out_ad_e_x2.segment1
              ,xilv_out_ad_e_x2.description
              ,ximv_out_ad_e_x2.item_id
              ,ximv_out_ad_e_x2.item_no
              ,ximv_out_ad_e_x2.item_name
              ,ximv_out_ad_e_x2.item_short_name
              ,ximv_out_ad_e_x2.num_of_cases
              ,ilm_out_ad_e_x2.lot_id
              ,ilm_out_ad_e_x2.lot_no
              ,ilm_out_ad_e_x2.attribute1
              ,ilm_out_ad_e_x2.attribute2
              ,ilm_out_ad_e_x2.attribute3                                     -- <---- �����܂ŋ���
              ,itc_out_ad_e_x2.trans_date
              ,itc_out_ad_e_x2.trans_date
              ,'2'                                            AS status      -- ����
              ,xrpm_out_ad_e_x2.new_div_invent
              ,flv_out_ad_e_x2.meaning
              ,xrart_out_ad_e_x2.rcv_rtn_number
              ,xrart_out_ad_e_x2.vendor_id
              ,xvv_out_ad_e_x2.vendor_full_name
              ,NULL                                           AS deliver_to_id
              ,NULL                                           AS deliver_to_name
              ,itc_out_ad_e_x2.trans_qty
              ,0                                              AS leaving_quantity
              ,ximv_out_ad_e_x2.lot_ctl
        FROM   xxcmn_item_locations_v  xilv_out_ad_e_x2                       -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v        ximv_out_ad_e_x2                       -- OPM�i�ڏ��VIEW
              ,ic_lots_mst             ilm_out_ad_e_x2                        -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst       xrpm_out_ad_e_x2                       -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values       flv_out_ad_e_x2                        -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,ic_adjs_jnl             iaj_out_ad_e_x2                        -- OPM�݌ɒ����W���[�i��
              ,ic_jrnl_mst             ijm_out_ad_e_x2                        -- OPM�W���[�i���}�X�^
              ,ic_tran_cmp             itc_out_ad_e_x2                        -- OPM�����݌Ƀg�����U�N�V����
              ,xxpo_rcv_and_rtn_txns   xrart_out_ad_e_x2                      -- ����ԕi���сi�A�h�I���j
              ,xxcmn_vendors_v         xvv_out_ad_e_x2                        -- �d������VIEW
        WHERE  xrpm_out_ad_e_x2.doc_type               = 'ADJI'
        AND    xrpm_out_ad_e_x2.reason_code            = 'X201'               -- �d���ԕi�o��
        AND    xrpm_out_ad_e_x2.rcv_pay_div            = '-1'                 -- ���o
        AND    xrpm_out_ad_e_x2.use_div_invent         = 'Y'
        AND    itc_out_ad_e_x2.doc_type                = xrpm_out_ad_e_x2.doc_type
        AND    itc_out_ad_e_x2.reason_code             = xrpm_out_ad_e_x2.reason_code
        AND    SIGN( itc_out_ad_e_x2.trans_qty )       = xrpm_out_ad_e_x2.rcv_pay_div
        AND    itc_out_ad_e_x2.item_id                 = ximv_out_ad_e_x2.item_id
        AND    ilm_out_ad_e_x2.item_id                 = ximv_out_ad_e_x2.item_id
        AND    itc_out_ad_e_x2.lot_id                  = ilm_out_ad_e_x2.lot_id
        AND    itc_out_ad_e_x2.whse_code               = xilv_out_ad_e_x2.whse_code
        AND    itc_out_ad_e_x2.location                = xilv_out_ad_e_x2.segment1
        AND    iaj_out_ad_e_x2.journal_id              = ijm_out_ad_e_x2.journal_id
        AND    itc_out_ad_e_x2.doc_type                = iaj_out_ad_e_x2.trans_type
        AND    itc_out_ad_e_x2.doc_id                  = iaj_out_ad_e_x2.doc_id
        AND    itc_out_ad_e_x2.doc_line                = iaj_out_ad_e_x2.doc_line
        AND    TO_NUMBER( ijm_out_ad_e_x2.attribute1 ) = xrart_out_ad_e_x2.txns_id
        AND    xvv_out_ad_e_x2.vendor_id               = xrart_out_ad_e_x2.vendor_id
        AND    flv_out_ad_e_x2.lookup_type             = 'XXCMN_NEW_DIVISION'
        AND    flv_out_ad_e_x2.language                = 'JA'
        AND    flv_out_ad_e_x2.lookup_code             = xrpm_out_ad_e_x2.new_div_invent
        UNION ALL
        -- �݌ɒ��� �o�Ɏ���(�ړ����ђ���)
        SELECT xilv_out_ad_e_12.whse_code
              ,xilv_out_ad_e_12.mtl_organization_id
              ,xilv_out_ad_e_12.customer_stock_whse
              ,xilv_out_ad_e_12.inventory_location_id
              ,xilv_out_ad_e_12.segment1
              ,xilv_out_ad_e_12.description
              ,ximv_out_ad_e_12.item_id
              ,ximv_out_ad_e_12.item_no
              ,ximv_out_ad_e_12.item_name
              ,ximv_out_ad_e_12.item_short_name
              ,ximv_out_ad_e_12.num_of_cases
              ,ilm_out_ad_e_12.lot_id
              ,ilm_out_ad_e_12.lot_no
              ,ilm_out_ad_e_12.attribute1
              ,ilm_out_ad_e_12.attribute2
              ,ilm_out_ad_e_12.attribute3                                    -- <---- �����܂ŋ���
              ,itc_out_ad_e_12.trans_date
              ,itc_out_ad_e_12.trans_date
              ,'2'                                            AS status   -- ����
              ,xrpm_out_ad_e_12.new_div_invent
              ,flv_out_ad_e_12.meaning
              ,xmrih_out_ad_e_12.mov_num
              ,xmrih_out_ad_e_12.ship_to_locat_id
              ,xilv_out_ad_e2_12.description
              ,NULL                                           AS deliver_to_id
              ,NULL                                           AS deliver_to_name
              ,itc_out_ad_e_12.trans_qty
              ,0                                              AS leaving_quantity
              ,ximv_out_ad_e_12.lot_ctl
        FROM   xxcmn_item_locations_v  xilv_out_ad_e_12                      -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_locations_v  xilv_out_ad_e2_12                     -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v        ximv_out_ad_e_12                      -- OPM�i�ڏ��VIEW
              ,ic_lots_mst             ilm_out_ad_e_12                       -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst       xrpm_out_ad_e_12                      -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values       flv_out_ad_e_12                       -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,ic_adjs_jnl             iaj_out_ad_e_12                       -- OPM�݌ɒ����W���[�i��
              ,ic_jrnl_mst             ijm_out_ad_e_12                       -- OPM�W���[�i���}�X�^
              ,ic_tran_cmp             itc_out_ad_e_12                       -- OPM�����݌Ƀg�����U�N�V����
              ,xxinv_mov_req_instr_headers xmrih_out_ad_e_12                 -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              ,xxinv_mov_req_instr_lines   xmril_out_ad_e_12                 -- �ړ��˗�/�w������(�A�h�I��)
              ,xxinv_mov_lot_details       xmldt_out_ad_e_12                 -- �ړ����b�g�ڍ�(�A�h�I��)
        WHERE  xrpm_out_ad_e_12.doc_type              = 'ADJI'
        AND    xrpm_out_ad_e_12.reason_code           = 'X123'               -- �ړ����ђ���
        AND    xrpm_out_ad_e_12.rcv_pay_div           = '1'                  -- ���
        AND    xrpm_out_ad_e_12.use_div_invent        = 'Y'
        AND    flv_out_ad_e_12.lookup_type            = 'XXCMN_NEW_DIVISION'
        AND    flv_out_ad_e_12.language               = 'JA'
        AND    flv_out_ad_e_12.lookup_code            = xrpm_out_ad_e_12.new_div_invent
        AND    itc_out_ad_e_12.doc_type               = xrpm_out_ad_e_12.doc_type
        AND    itc_out_ad_e_12.reason_code            = xrpm_out_ad_e_12.reason_code
        AND    SIGN( itc_out_ad_e_12.trans_qty )      = xrpm_out_ad_e_12.rcv_pay_div
        AND    itc_out_ad_e_12.item_id                = xmril_out_ad_e_12.item_id
        AND    itc_out_ad_e_12.lot_id                 = xmldt_out_ad_e_12.lot_id
        AND    itc_out_ad_e_12.location               = xmrih_out_ad_e_12.shipped_locat_code
        AND    itc_out_ad_e_12.doc_type               = iaj_out_ad_e_12.trans_type
        AND    itc_out_ad_e_12.doc_id                 = iaj_out_ad_e_12.doc_id
        AND    itc_out_ad_e_12.doc_line               = iaj_out_ad_e_12.doc_line
        AND    iaj_out_ad_e_12.journal_id             = ijm_out_ad_e_12.journal_id
        AND    xmril_out_ad_e_12.mov_line_id          = TO_NUMBER( ijm_out_ad_e_12.attribute1 )
        AND    xmldt_out_ad_e_12.lot_id               = ilm_out_ad_e_12.lot_id
        AND    xmldt_out_ad_e_12.record_type_code     = '20'
        AND    xmldt_out_ad_e_12.document_type_code   = '20'
        AND    xmril_out_ad_e_12.mov_line_id          = xmldt_out_ad_e_12.mov_line_id
        AND    xmril_out_ad_e_12.item_id              = ximv_out_ad_e_12.item_id
        AND    xmrih_out_ad_e_12.mov_hdr_id           = xmril_out_ad_e_12.mov_hdr_id
        AND    xmrih_out_ad_e_12.shipped_locat_id     = xilv_out_ad_e_12.inventory_location_id
        AND    xmrih_out_ad_e_12.ship_to_locat_id     = xilv_out_ad_e2_12.inventory_location_id
--mod end 2008/06/06
        UNION ALL
        -- �݌ɒ��� �o�Ɏ���(��L�ȊO)
        SELECT xilv_out_ad_e_xx.whse_code
              ,xilv_out_ad_e_xx.mtl_organization_id
              ,xilv_out_ad_e_xx.customer_stock_whse
              ,xilv_out_ad_e_xx.inventory_location_id
              ,xilv_out_ad_e_xx.segment1
              ,xilv_out_ad_e_xx.description
              ,ximv_out_ad_e_xx.item_id
              ,ximv_out_ad_e_xx.item_no
              ,ximv_out_ad_e_xx.item_name
              ,ximv_out_ad_e_xx.item_short_name
              ,ximv_out_ad_e_xx.num_of_cases
              ,ilm_out_ad_e_xx.lot_id
              ,ilm_out_ad_e_xx.lot_no
              ,ilm_out_ad_e_xx.attribute1
              ,ilm_out_ad_e_xx.attribute2
              ,ilm_out_ad_e_xx.attribute3                                     -- <---- �����܂ŋ���
              ,itc_out_ad_e_xx.trans_date
              ,itc_out_ad_e_xx.trans_date
              ,'2'                                            AS status   -- ����
              ,xrpm_out_ad_e_xx.new_div_invent
              ,flv_out_ad_e_xx.meaning
--mod start 2008/06/06
--              ,xmrih_out_ad_e_xx.mov_num
--              ,xmrih_out_ad_e_xx.ship_to_locat_id
              ,ijm_out_ad_e_xx.journal_no
              ,TO_NUMBER(xrpm_out_ad_e_xx.new_div_invent )    AS ukebaraisaki_id
--mod end 2008/06/06
              ,flv_out_ad_e_xx.meaning
              ,NULL                                           AS deliver_to_id
              ,NULL                                           AS deliver_to_name
              ,0                                              AS stock_quantity
--mod start 2008/06/05
--              ,itc_out_ad_e_xx.trans_qty
              ,ABS(itc_out_ad_e_xx.trans_qty)
--mod start 2008/06/05
              ,ximv_out_ad_e_xx.lot_ctl
        FROM   xxcmn_item_locations_v  xilv_out_ad_e_xx                       -- OPM�ۊǏꏊ���VIEW
              ,xxcmn_item_mst_v        ximv_out_ad_e_xx                       -- OPM�i�ڏ��VIEW
              ,ic_lots_mst             ilm_out_ad_e_xx                        -- OPM���b�g�}�X�^
              ,xxcmn_rcv_pay_mst       xrpm_out_ad_e_xx                       -- �󕥋敪�A�h�I���}�X�^
              ,fnd_lookup_values       flv_out_ad_e_xx                        -- �N�C�b�N�R�[�h <---- �����܂ŋ���
              ,ic_adjs_jnl             iaj_out_ad_e_xx                        -- OPM�݌ɒ����W���[�i��
              ,ic_jrnl_mst             ijm_out_ad_e_xx                        -- OPM�W���[�i���}�X�^
              ,ic_tran_cmp             itc_out_ad_e_xx                        -- OPM�����݌Ƀg�����U�N�V����
--del start 2008/06/06
--              ,xxinv_mov_req_instr_headers xmrih_out_ad_e_xx                  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
--              ,xxinv_mov_req_instr_lines   xmril_out_ad_e_xx                  -- �ړ��˗�/�w������(�A�h�I��)
--del end 2008/06/06
        WHERE  xrpm_out_ad_e_xx.doc_type               = 'ADJI'
        AND    xrpm_out_ad_e_xx.reason_code           <> 'X977'               -- �����݌�
--mod start 2008/06/06
        AND    xrpm_out_ad_e_xx.reason_code           <> 'X201'               -- �d���ԕi�o��
        AND    xrpm_out_ad_e_xx.reason_code           <> 'X123'               -- �ړ����ђ����i���Ɂj
--mod end 2008/06/06
        AND    xrpm_out_ad_e_xx.rcv_pay_div            = '-1'                 -- ���o
        AND    xrpm_out_ad_e_xx.use_div_invent         = 'Y'
        AND    itc_out_ad_e_xx.doc_type                = xrpm_out_ad_e_xx.doc_type
        AND    itc_out_ad_e_xx.reason_code             = xrpm_out_ad_e_xx.reason_code
        AND    SIGN( itc_out_ad_e_xx.trans_qty )       = xrpm_out_ad_e_xx.rcv_pay_div
        AND    itc_out_ad_e_xx.item_id                 = ximv_out_ad_e_xx.item_id
        AND    ilm_out_ad_e_xx.item_id                 = ximv_out_ad_e_xx.item_id
        AND    itc_out_ad_e_xx.lot_id                  = ilm_out_ad_e_xx.lot_id
        AND    itc_out_ad_e_xx.whse_code               = xilv_out_ad_e_xx.whse_code
        AND    itc_out_ad_e_xx.location                = xilv_out_ad_e_xx.segment1
        AND    iaj_out_ad_e_xx.journal_id              = ijm_out_ad_e_xx.journal_id
        AND    itc_out_ad_e_xx.doc_type                = iaj_out_ad_e_xx.trans_type
        AND    itc_out_ad_e_xx.doc_id                  = iaj_out_ad_e_xx.doc_id
        AND    itc_out_ad_e_xx.doc_line                = iaj_out_ad_e_xx.doc_line
        AND    flv_out_ad_e_xx.lookup_type             = 'XXCMN_NEW_DIVISION'
        AND    flv_out_ad_e_xx.language                = 'JA'
        AND    flv_out_ad_e_xx.lookup_code             = xrpm_out_ad_e_xx.new_div_invent
--del start 2008/06/06
--        AND    xmril_out_ad_e_xx.mov_line_id           = TO_NUMBER( ijm_out_ad_e_xx.attribute1 )
--        AND    xmrih_out_ad_e_xx.mov_hdr_id            = xmril_out_ad_e_xx.mov_hdr_id
--del end 2008/06/06
  ) xstv
  ;
--
COMMENT ON COLUMN xxinv_stc_trans_v.whse_code             IS '�q�ɃR�[�h';
COMMENT ON COLUMN xxinv_stc_trans_v.organization_id       IS '�݌ɑg�DID';
COMMENT ON COLUMN xxinv_stc_trans_v.ownership_code        IS '���`�R�[�h';
COMMENT ON COLUMN xxinv_stc_trans_v.inventory_location_id IS '�ۊǑq��ID';
COMMENT ON COLUMN xxinv_stc_trans_v.location_code         IS '�ۊǑq�ɃR�[�h';
COMMENT ON COLUMN xxinv_stc_trans_v.location              IS '�ۊǑq�ɖ�';
COMMENT ON COLUMN xxinv_stc_trans_v.item_id               IS '�i��ID';
COMMENT ON COLUMN xxinv_stc_trans_v.item_no               IS '�i�ڃR�[�h';
COMMENT ON COLUMN xxinv_stc_trans_v.item_name             IS '�i�ڐ�����';
COMMENT ON COLUMN xxinv_stc_trans_v.item_short_name       IS '�i�ڗ���';
COMMENT ON COLUMN xxinv_stc_trans_v.case_content          IS '�P�[�X����';
COMMENT ON COLUMN xxinv_stc_trans_v.lot_id                IS '���b�gID';
COMMENT ON COLUMN xxinv_stc_trans_v.lot_no                IS '���b�gNo';
COMMENT ON COLUMN xxinv_stc_trans_v.manufacture_date      IS '�����N����';
COMMENT ON COLUMN xxinv_stc_trans_v.uniqe_sign            IS '�ŗL�L��';
COMMENT ON COLUMN xxinv_stc_trans_v.expiration_date       IS '�ܖ�����';
COMMENT ON COLUMN xxinv_stc_trans_v.arrival_date          IS '����';
COMMENT ON COLUMN xxinv_stc_trans_v.leaving_date          IS '����';
COMMENT ON COLUMN xxinv_stc_trans_v.status                IS '�X�e�[�^�X';
COMMENT ON COLUMN xxinv_stc_trans_v.reason_code           IS '���R�R�[�h';
COMMENT ON COLUMN xxinv_stc_trans_v.reason_code_name      IS '���R�R�[�h��';
COMMENT ON COLUMN xxinv_stc_trans_v.voucher_no            IS '�`�[No';
COMMENT ON COLUMN xxinv_stc_trans_v.ukebaraisaki_id       IS '�󕥐�ID';
COMMENT ON COLUMN xxinv_stc_trans_v.ukebaraisaki_name     IS '�󕥐�';
COMMENT ON COLUMN xxinv_stc_trans_v.deliver_to_id         IS '�z����ID';
COMMENT ON COLUMN xxinv_stc_trans_v.deliver_to_name       IS '�z����';
COMMENT ON COLUMN xxinv_stc_trans_v.stock_quantity        IS '���ɐ�';
COMMENT ON COLUMN xxinv_stc_trans_v.leaving_quantity      IS '�o�ɐ�';
--
COMMENT ON TABLE  xxinv_stc_trans_v IS '���o�ɏ��r���[' ;
/
