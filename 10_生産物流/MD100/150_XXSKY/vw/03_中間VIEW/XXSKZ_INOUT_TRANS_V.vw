/*************************************************************************
 * 
 * View  Name      : XXSKZ_INOUT_TRANS_V
 * Description     : XXSKZ_INOUT_TRANS_V
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------
 *  Date          Ver.  Editor          Description
 * ------------- ----- ---------------- -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai    ����쐬
 *  2013/03/19    1.1   SCSK D.Sugahara E_�{�ғ�_10479 �ۑ�20�Ή�
 ************************************************************************/
--*******************************************************************
-- ���o�ɏ�� ����VIEW
--   ��VIEW�ł̓��b�g���蓖�Ă���Ă���\��f�[�^�݂̂��o�͂���
--    �� �h�����N�������
--
--   �y�g�p�Ώ�VIEW�z
--     �EXXSKZ_���o�ɏ��_��{_V
--     �EXXSKZ_���o�ɏ��_����_V
--     �EXXSKZ_���o�ɏ��_����_V
--     �EXXSKZ_���o�ɏ��_����_V
--*******************************************************************
CREATE OR REPLACE VIEW APPS.XXSKZ_INOUT_TRANS_V
(
 reason_code
,whse_code
,location_code
,location
,location_s_name
,item_id
,item_no
,item_name
,item_short_name
,case_content
,lot_ctl
,lot_id
,lot_no
,manufacture_date
,uniqe_sign
,expiration_date
,voucher_no
,line_no
,delivery_no
,loct_code
,loct_name
,in_out_kbn
,leaving_date
,arrival_date
,standard_date
,ukebaraisaki_code
,ukebaraisaki_name
,status
,deliver_to_no
,deliver_to_name
,stock_quantity
,leaving_quantity
,quantity
)
AS
--����������������������������������������������������������������������
--�� �y���ɗ\��z                                                     ��
--��    �P�D��������\��                                              ��
--��    �Q�D�ړ����ɗ\��(�w�� �ϑ�����)                               ��
--��    �R�D�ړ����ɗ\��(�w�� �ϑ��Ȃ�)                               ��
--��    �S�D�ړ����ɗ\��(�o�ɕ񍐗L �ϑ�����)                         ��
--��    �T�D���Y���ɗ\��                                              ��
--��    �U�D���Y���ɗ\�� �i�ڐU�� �i��U��                            ��
--����������������������������������������������������������������������
  -------------------------------------------------------------
  -- �P�D��������\��
  -------------------------------------------------------------
  SELECT
          xrpm_in_po.new_div_invent                     AS reason_code            -- ���R�R�[�h
         ,xilv_in_po.whse_code                          AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_po.segment1                           AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_po.description                        AS location               -- �ۊǏꏊ��
         ,xilv_in_po.short_name                         AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_po.item_id                            AS item_id                -- �i��ID
         ,ximv_in_po.item_no                            AS item_no                -- �i�ڃR�[�h
         ,ximv_in_po.item_name                          AS item_name              -- �i�ږ�
         ,ximv_in_po.item_short_name                    AS item_short_name        -- �i�ڗ���
         ,ximv_in_po.num_of_cases                       AS case_content           -- �P�[�X����
         ,ximv_in_po.lot_ctl                            AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_po.lot_id                              AS lot_id                 -- ���b�gID
         ,ilm_in_po.lot_no                              AS lot_no                 -- ���b�gNo
         ,ilm_in_po.attribute1                          AS manufacture_date       -- �����N����
         ,ilm_in_po.attribute2                          AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_po.attribute3                          AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,pha_in_po.segment1                            AS voucher_no             -- �`�[�ԍ�
         ,pla_in_po.line_num                            AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,pha_in_po.attribute10                         AS loct_code              -- �����R�[�h
         ,xlc_in_po.location_name                       AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS leaving_date           -- ���o�ɓ�_����
         ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS arrival_date           -- ���o�ɓ�_����
         ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS standard_date          -- ����i�����j
         ,xvv_in_po.segment1                            AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xvv_in_po.vendor_name                         AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,xilv_in_po.segment1                           AS deliver_to_no          -- �z����R�[�h
         ,xilv_in_po.description                        AS deliver_to_name        -- �z���於
         ,pla_in_po.quantity                            AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,pla_in_po.quantity                            AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_po                -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_po                -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_po                 -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_po                -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,po_headers_all                                pha_in_po                 -- �����w�b�_
         ,po_lines_all                                  pla_in_po                 -- ��������
         ,xxskz_vendors2_v                              xvv_in_po                 -- �d������VIEW(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_in_po                 -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_po.doc_type                           = 'PORC'
     AND  xrpm_in_po.source_document_code               = 'PO'
     AND  xrpm_in_po.use_div_invent                     = 'Y'
     AND  xrpm_in_po.transaction_type                   = 'DELIVER'
     --�����w�b�_�̏���
     AND  pha_in_po.attribute1                          IN ( '20'                 -- �����쐬��
                                                            ,'25' )               -- �������
     --�������ׂƂ̌���
     AND  NVL( pla_in_po.attribute13, 'N' )            <> 'Y'    --������
     AND  NVL( pla_in_po.cancel_flag, 'N' )            <> 'Y'
     AND  pha_in_po.po_header_id                        = pla_in_po.po_header_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  pla_in_po.item_id                             = ximv_in_po.inventory_item_id
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) >= ximv_in_po.start_date_active
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) <= ximv_in_po.end_date_active
     --���b�g���擾
     AND  ximv_in_po.item_id                            = ilm_in_po.item_id
     AND (   ( ximv_in_po.lot_ctl = 1 AND pla_in_po.attribute1 = ilm_in_po.lot_no )  -- ���b�g�Ǘ��i
          OR ( ximv_in_po.lot_ctl = 0 AND 'DEFAULTLOT'         = ilm_in_po.lot_no )  -- �񃍃b�g�Ǘ��i
         )
     --�ۊǏꏊ���擾
     AND  pha_in_po.attribute5                          = xilv_in_po.segment1
     --�������擾
     AND  xvv_in_po.vendor_id                           = pha_in_po.vendor_id
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) >= xvv_in_po.start_date_active
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) <= xvv_in_po.end_date_active
     -- �������擾(�O�������Ƃ���)
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  pha_in_po.attribute10                         = xlc_in_po.location_code(+)
--     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) >= xlc_in_po.start_date_active(+)
--     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) <= xlc_in_po.end_date_active(+)
     AND  pha_in_po.attribute10                         = xlc_in_po.location_code
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) >= xlc_in_po.start_date_active
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) <= xlc_in_po.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �P�D��������\��  END ]
UNION ALL
  -------------------------------------------------------------
  -- �Q�D�ړ����ɗ\��(�w�� �ϑ�����)
  -------------------------------------------------------------
  SELECT
          xrpm_in_xf.new_div_invent                     AS reason_code            -- ���R�R�[�h
         ,xilv_in_xf.whse_code                          AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_xf.segment1                           AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_xf.description                        AS location               -- �ۊǏꏊ��
         ,xilv_in_xf.short_name                         AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_xf.item_id                            AS item_id                -- �i��ID
         ,ximv_in_xf.item_no                            AS item_no                -- �i�ڃR�[�h
         ,ximv_in_xf.item_name                          AS item_name              -- �i�ږ�
         ,ximv_in_xf.item_short_name                    AS item_short_name        -- �i�ڗ���
         ,ximv_in_xf.num_of_cases                       AS case_content           -- �P�[�X����
         ,ximv_in_xf.lot_ctl                            AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_xf.lot_id                              AS lot_id                 -- ���b�gID
         ,ilm_in_xf.lot_no                              AS lot_no                 -- ���b�gNo
         ,ilm_in_xf.attribute1                          AS manufacture_date       -- �����N����
         ,ilm_in_xf.attribute2                          AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_xf.attribute3                          AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xmrih_in_xf.mov_num                           AS voucher_no             -- �`�[�ԍ�
         ,xmril_in_xf.line_number                       AS line_no                -- �s�ԍ�
         ,xmrih_in_xf.delivery_no                       AS delivery_no            -- �z���ԍ�
         ,xmrih_in_xf.instruction_post_code             AS loct_code              -- �����R�[�h
         ,xlc_in_xf.location_name                       AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,xmrih_in_xf.schedule_ship_date                AS leaving_date           -- ���o�ɓ�_����
         ,xmrih_in_xf.schedule_arrival_date             AS arrival_date           -- ���o�ɓ�_����
         ,xmrih_in_xf.schedule_arrival_date             AS standard_date          -- ����i�����j
         ,xilv_in_xf2.segment1                          AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xilv_in_xf2.description                       AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,xilv_in_xf2.segment1                          AS deliver_to_no          -- �z����R�[�h
         ,xilv_in_xf2.description                       AS deliver_to_name        -- �z���於
         ,CASE WHEN xmld_in_xf.mov_lot_dtl_id IS NULL THEN xmril_in_xf.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                        xmld_in_xf.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,CASE WHEN xmld_in_xf.mov_lot_dtl_id IS NULL THEN xmril_in_xf.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                        xmld_in_xf.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_in_xf                -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_xf                -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_xf                 -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_xf                -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_in_xf               -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_req_instr_lines_arc                 xmril_in_xf               -- �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_in_xf                -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,xxskz_item_locations2_v                       xilv_in_xf2               -- OPM�ۊǏꏊ���VIEW2(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_in_xf                 -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_xf.doc_type                           = 'XFER'                  -- �ړ��ϑ�����
     AND  xrpm_in_xf.use_div_invent                     = 'Y'
     AND  xrpm_in_xf.rcv_pay_div                        = '1'                     -- ���
     --�ړ��w�b�_�̏���
     AND  xmrih_in_xf.mov_type                          = '1'
     AND  NVL( xmrih_in_xf.comp_actual_flg, 'N' )       = 'N'                     -- ���і��v��
     AND  xmrih_in_xf.status                            IN ( '02'                 -- �˗���
                                                            ,'03' )               -- ������
     --�ړ����ׂƂ̌���
     AND  NVL( xmril_in_xf.delete_flg, 'N' )            = 'N'                     -- �������׈ȊO
     AND  xmrih_in_xf.mov_hdr_id                        = xmril_in_xf.mov_hdr_id
     --�ړ����b�g�ڍ׎擾
     AND  xmld_in_xf.document_type_code                 = '20'                    -- �ړ�
     AND  xmld_in_xf.record_type_code                   = '10'                    -- �w��
     AND  xmril_in_xf.mov_line_id                       = xmld_in_xf.mov_line_id
     --�i�ڃ}�X�^���擾
     AND  xmril_in_xf.item_id                           = ximv_in_xf.item_id
     AND  xmrih_in_xf.schedule_arrival_date            >= ximv_in_xf.start_date_active
     AND  xmrih_in_xf.schedule_arrival_date            <= ximv_in_xf.end_date_active
     --���b�g���擾
     AND  xmld_in_xf.item_id                            = ilm_in_xf.item_id
     AND  xmld_in_xf.lot_id                             = ilm_in_xf.lot_id
     --OPM�ۊǏꏊ���擾
     AND  xmrih_in_xf.ship_to_locat_id                  = xilv_in_xf.inventory_location_id
     --OPM�ۊǏꏊ���2�擾
     AND  xmrih_in_xf.shipped_locat_id                  = xilv_in_xf2.inventory_location_id
     -- �������擾(�O�������Ƃ���)
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xmrih_in_xf.instruction_post_code             = xlc_in_xf.location_code(+)
--     AND  xmrih_in_xf.schedule_arrival_date            >= xlc_in_xf.start_date_active(+)
--     AND  xmrih_in_xf.schedule_arrival_date            <= xlc_in_xf.end_date_active(+)
     AND  xmrih_in_xf.instruction_post_code             = xlc_in_xf.location_code
     AND  xmrih_in_xf.schedule_arrival_date            >= xlc_in_xf.start_date_active
     AND  xmrih_in_xf.schedule_arrival_date            <= xlc_in_xf.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �Q�D�ړ����ɗ\��(�w�� �ϑ�����)  END ]
UNION ALL
  -------------------------------------------------------------
  -- �R�D�ړ����ɗ\��(�w�� �ϑ��Ȃ�)
  -------------------------------------------------------------
  SELECT
          xrpm_in_tr.new_div_invent                     AS reason_code            -- ���R�R�[�h
         ,xilv_in_tr.whse_code                          AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_tr.segment1                           AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_tr.description                        AS location               -- �ۊǏꏊ��
         ,xilv_in_tr.short_name                         AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_tr.item_id                            AS item_id                -- �i��ID
         ,ximv_in_tr.item_no                            AS item_no                -- �i�ڃR�[�h
         ,ximv_in_tr.item_name                          AS item_name              -- �i�ږ�
         ,ximv_in_tr.item_short_name                    AS item_short_name        -- �i�ڗ���
         ,ximv_in_tr.num_of_cases                       AS case_content           -- �P�[�X����
         ,ximv_in_tr.lot_ctl                            AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_tr.lot_id                              AS lot_id                 -- ���b�gID
         ,ilm_in_tr.lot_no                              AS lot_no                 -- ���b�gNo
         ,ilm_in_tr.attribute1                          AS manufacture_date       -- �����N����
         ,ilm_in_tr.attribute2                          AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_tr.attribute3                          AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xmrih_in_tr.mov_num                           AS voucher_no             -- �`�[�ԍ�
         ,xmril_in_tr.line_number                       AS line_no                -- �s�ԍ�
         ,xmrih_in_tr.delivery_no                       AS delivery_no            -- �z���ԍ�
         ,xmrih_in_tr.instruction_post_code             AS loct_code              -- �����R�[�h
         ,xlc_in_tr.location_name                       AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,xmrih_in_tr.schedule_ship_date                AS leaving_date           -- ���o�ɓ�_����
         ,xmrih_in_tr.schedule_arrival_date             AS arrival_date           -- ���o�ɓ�_����
         ,xmrih_in_tr.schedule_arrival_date             AS standard_date          -- ����i�����j
         ,xilv_in_tr2.segment1                          AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xilv_in_tr2.description                       AS ukebaraisaki_name      -- �󕥐於(�󕥐於�擾�p)
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,xilv_in_tr2.segment1                          AS deliver_to_no          -- �z����R�[�h
         ,xilv_in_tr2.description                       AS deliver_to_name        -- �z���於
         ,CASE WHEN xmld_in_tr.mov_lot_dtl_id IS NULL THEN xmril_in_tr.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                        xmld_in_tr.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,CASE WHEN xmld_in_tr.mov_lot_dtl_id IS NULL THEN xmril_in_tr.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                        xmld_in_tr.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_in_tr                -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_tr                -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_tr                 -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_tr                -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_in_tr               -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_req_instr_lines_arc                 xmril_in_tr               -- �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_in_tr                -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,xxskz_item_locations2_v                       xilv_in_tr2               -- OPM�ۊǏꏊ���VIEW2(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_in_tr                 -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_tr.doc_type                           = 'TRNI'                  -- �ړ��ϑ��Ȃ�
     AND  xrpm_in_tr.use_div_invent                     = 'Y'
     AND  xrpm_in_tr.rcv_pay_div                        = '1'                     -- ���
     --�ړ��w�b�_�̏���
     AND  xmrih_in_tr.mov_type                          = '2'
     AND  NVL( xmrih_in_tr.comp_actual_flg, 'N' )       = 'N'                     -- ���і��v��
     AND  xmrih_in_tr.status                            IN ( '02'                 -- �˗���
                                                            ,'03' )               -- ������
     --�ړ����ׂƂ̌���
     AND  NVL( xmril_in_tr.delete_flg, 'N' )            = 'N'                     -- �������׈ȊO
     AND  xmrih_in_tr.mov_hdr_id                        = xmril_in_tr.mov_hdr_id
     --�ړ����b�g�ڍׂƂ̌���
     AND  xmld_in_tr.document_type_code                 = '20'                    -- �ړ�
     AND  xmld_in_tr.record_type_code                   = '10'                    -- �w��
     AND  xmril_in_tr.mov_line_id                       = xmld_in_tr.mov_line_id
     --�i�ڃ}�X�^���擾
     AND  xmril_in_tr.item_id                           = ximv_in_tr.item_id
     AND  xmrih_in_tr.schedule_arrival_date            >= ximv_in_tr.start_date_active
     AND  xmrih_in_tr.schedule_arrival_date            <= ximv_in_tr.end_date_active
     --���b�g���擾
     AND  xmld_in_tr.item_id                            = ilm_in_tr.item_id
     AND  xmld_in_tr.lot_id                             = ilm_in_tr.lot_id
     --OPM�ۊǏꏊ���擾
     AND  xmrih_in_tr.ship_to_locat_id                  = xilv_in_tr.inventory_location_id
     --OPM�ۊǏꏊ���2�擾
     AND  xmrih_in_tr.shipped_locat_id                  = xilv_in_tr2.inventory_location_id
     -- �������擾(�O�������Ƃ���)
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xmrih_in_tr.instruction_post_code             = xlc_in_tr.location_code(+)
--     AND  xmrih_in_tr.schedule_arrival_date            >= xlc_in_tr.start_date_active(+)
--     AND  xmrih_in_tr.schedule_arrival_date            <= xlc_in_tr.end_date_active(+)
     AND  xmrih_in_tr.instruction_post_code             = xlc_in_tr.location_code
     AND  xmrih_in_tr.schedule_arrival_date            >= xlc_in_tr.start_date_active
     AND  xmrih_in_tr.schedule_arrival_date            <= xlc_in_tr.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �R�D�ړ����ɗ\��(�w�� �ϑ��Ȃ�)  END ]
UNION ALL
  -------------------------------------------------------------
  -- �S�D�ړ����ɗ\��(�o�ɕ񍐗L �ϑ�����)
  -------------------------------------------------------------
  SELECT
          xrpm_in_xf20.new_div_invent                   AS reason_code            -- ���R�R�[�h
         ,xilv_in_xf20.whse_code                        AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_xf20.segment1                         AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_xf20.description                      AS location               -- �ۊǏꏊ��
         ,xilv_in_xf20.short_name                       AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_xf20.item_id                          AS item_id                -- �i��ID
         ,ximv_in_xf20.item_no                          AS item_no                -- �i�ڃR�[�h
         ,ximv_in_xf20.item_name                        AS item_name              -- �i�ږ�
         ,ximv_in_xf20.item_short_name                  AS item_short_name        -- �i�ڗ���
         ,ximv_in_xf20.num_of_cases                     AS case_content           -- �P�[�X����
         ,ximv_in_xf20.lot_ctl                          AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_xf20.lot_id                            AS lot_id                 -- ���b�gID
         ,ilm_in_xf20.lot_no                            AS lot_no                 -- ���b�gNo
         ,ilm_in_xf20.attribute1                        AS manufacture_date       -- �����N����
         ,ilm_in_xf20.attribute2                        AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_xf20.attribute3                        AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xmrih_in_xf20.mov_num                         AS voucher_no             -- �`�[�ԍ�
         ,xmril_in_xf20.line_number                     AS line_no                -- �s�ԍ�
         ,xmrih_in_xf20.delivery_no                     AS delivery_no            -- �z���ԍ�
         ,xmrih_in_xf20.instruction_post_code           AS loct_code              -- �����R�[�h
         ,xlc_in_xf20.location_name                     AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,xmrih_in_xf20.schedule_ship_date              AS leaving_date           -- ���o�ɓ�_����
         ,xmrih_in_xf20.schedule_arrival_date           AS arrival_date           -- ���o�ɓ�_����
         ,xmrih_in_xf20.schedule_arrival_date           AS standard_date          -- ����i�����j
         ,xilv_in_xf202.segment1                        AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xilv_in_xf202.description                     AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,xilv_in_xf202.segment1                        AS deliver_to_no          -- �z����R�[�h
         ,xilv_in_xf202.description                     AS deliver_to_name        -- �z���於
         ,CASE WHEN xmld_in_xf20.mov_lot_dtl_id IS NULL THEN xmril_in_xf20.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                          xmld_in_xf20.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,CASE WHEN xmld_in_xf20.mov_lot_dtl_id IS NULL THEN xmril_in_xf20.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                          xmld_in_xf20.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_in_xf20              -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_xf20              -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_xf20               -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_xf20              -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_in_xf20             -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_req_instr_lines_arc                 xmril_in_xf20             -- �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_in_xf20              -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,xxskz_item_locations2_v                       xilv_in_xf202             -- OPM�ۊǏꏊ���VIEW2(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_in_xf20               -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_xf20.doc_type                         = 'XFER'                  -- �ړ��ϑ�����
     AND  xrpm_in_xf20.use_div_invent                   = 'Y'
     AND  xrpm_in_xf20.rcv_pay_div                      = '1'                     -- ���
     --�ړ��˗�/�w���w�b�_(�A�h�I��)�̏���
     AND  xmrih_in_xf20.mov_type                        = '1'                     -- �ϑ�����
     AND  NVL( xmrih_in_xf20.comp_actual_flg, 'N' )     = 'N'                     -- ���і��v��
     AND  xmrih_in_xf20.status                          = '04'                    -- �o�ɕ񍐗L
     --�ړ��˗�/�w������(�A�h�I��)�Ƃ̌���
     AND  NVL( xmril_in_xf20.delete_flg, 'N' )          = 'N'                     -- �������׈ȊO
     AND  xmrih_in_xf20.mov_hdr_id                      = xmril_in_xf20.mov_hdr_id
     --�ړ����b�g�ڍ׎擾
     AND  xmld_in_xf20.document_type_code               = '20'                    -- �ړ�
     AND  xmld_in_xf20.record_type_code                 = '20'                    -- �o�Ɏ���
     AND  xmril_in_xf20.mov_line_id                     = xmld_in_xf20.mov_line_id
     --�i�ڃ}�X�^���擾
     AND  xmril_in_xf20.item_id                         = ximv_in_xf20.item_id
     AND  xmrih_in_xf20.schedule_arrival_date          >= ximv_in_xf20.start_date_active
     AND  xmrih_in_xf20.schedule_arrival_date          <= ximv_in_xf20.end_date_active
     --���b�g���擾
     AND  xmld_in_xf20.item_id                          = ilm_in_xf20.item_id
     AND  xmld_in_xf20.lot_id                           = ilm_in_xf20.lot_id
     --OPM�ۊǏꏊ���擾
     AND  xmrih_in_xf20.ship_to_locat_id                = xilv_in_xf20.inventory_location_id
     --OPM�ۊǏꏊ���2�擾
     AND  xmrih_in_xf20.shipped_locat_id                = xilv_in_xf202.inventory_location_id
     --�������擾(�O�������Ƃ���)
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xmrih_in_xf20.instruction_post_code           = xlc_in_xf20.location_code(+)
--     AND  xmrih_in_xf20.schedule_arrival_date          >= xlc_in_xf20.start_date_active(+)
--     AND  xmrih_in_xf20.schedule_arrival_date          <= xlc_in_xf20.end_date_active(+)
     AND  xmrih_in_xf20.instruction_post_code           = xlc_in_xf20.location_code
     AND  xmrih_in_xf20.schedule_arrival_date          >= xlc_in_xf20.start_date_active
     AND  xmrih_in_xf20.schedule_arrival_date          <= xlc_in_xf20.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �S�D�ړ����ɗ\��(�o�ɕ񍐗L �ϑ�����)  END ]
UNION ALL
  -------------------------------------------------------------
  -- �T�D���Y���ɗ\��
  -------------------------------------------------------------
  SELECT
          xrpm_in_pr.new_div_invent                     AS reason_code            -- ���R�R�[�h
         ,xilv_in_pr.whse_code                          AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_pr.segment1                           AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_pr.description                        AS location               -- �ۊǏꏊ��
         ,xilv_in_pr.short_name                         AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_pr.item_id                            AS item_id                -- �i��ID
         ,ximv_in_pr.item_no                            AS item_no                -- �i�ڃR�[�h
         ,ximv_in_pr.item_name                          AS item_name              -- �i�ږ�
         ,ximv_in_pr.item_short_name                    AS item_short_name        -- �i�ڗ���
         ,ximv_in_pr.num_of_cases                       AS case_content           -- �P�[�X����
         ,ximv_in_pr.lot_ctl                            AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_pr.lot_id                              AS lot_id                 -- ���b�gID
         ,ilm_in_pr.lot_no                              AS lot_no                 -- ���b�gNo
         ,ilm_in_pr.attribute1                          AS manufacture_date       -- �����N����
         ,ilm_in_pr.attribute2                          AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_pr.attribute3                          AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,gbh_in_pr.batch_no                            AS voucher_no             -- �`�[�ԍ�
         ,gmd_in_pr.line_no                             AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,gbh_in_pr.attribute2                          AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,gbh_in_pr.plan_start_date                     AS leaving_date           -- ���o�ɓ�_����
         ,gbh_in_pr.plan_start_date                     AS arrival_date           -- ���o�ɓ�_����
         ,gbh_in_pr.plan_start_date                     AS standard_date          -- ����i�����j
         ,grb_in_pr.routing_no                          AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,grt_in_pr.routing_desc                        AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,gmd_in_pr.plan_qty                            AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,gmd_in_pr.plan_qty                            AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_pr                -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_pr                -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_pr                 -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_pr                -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_gme_batch_header_arc                    gbh_in_pr                 -- ���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
         ,xxcmn_gme_material_details_arc                gmd_in_pr                 -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v
         ,gmd_routings_b                                grb_in_pr                 -- �H���}�X�^
         ,gmd_routings_tl                               grt_in_pr                 -- �H���}�X�^���{��
         ,xxcmn_ic_tran_pnd_arc                         itp_in_pr                 -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
   WHERE
     -- �󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_pr.doc_type                           = 'PROD'
     AND  xrpm_in_pr.use_div_invent                     = 'Y'
     -- ���Y�o�b�`�w�b�_�̏���
     AND  gbh_in_pr.batch_status                        IN ( '1', '2' )           -- 1:�ۗ��A2:WIP
     -- �H���}�X�^�Ƃ̌����i���Y�f�[�^�擾�̏����j
     AND  grb_in_pr.routing_class                       NOT IN ( '61', '62', '70' )  -- �i�ڐU��(70)�A���(61,62) �ȊO
     AND  grb_in_pr.routing_id                          = gbh_in_pr.routing_id
     AND  xrpm_in_pr.routing_class                      = grb_in_pr.routing_class
     -- ���Y�����ڍׂƂ̌���
     AND  gmd_in_pr.line_type                           IN ( 1, 2 )               -- 1:�����i�A2:���Y��
     AND  gbh_in_pr.batch_id                            = gmd_in_pr.batch_id
     AND  xrpm_in_pr.line_type                          = gmd_in_pr.line_type
     AND (   ( ( gmd_in_pr.attribute5 IS NULL     ) AND ( xrpm_in_pr.hit_in_div IS NULL ) )
          OR ( ( gmd_in_pr.attribute5 IS NOT NULL ) AND ( xrpm_in_pr.hit_in_div = gmd_in_pr.attribute5 ) )
         )
     -- OPM�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
     AND  itp_in_pr.delete_mark                         = 0                       -- �L���`�F�b�N(OPM�ۗ��݌�)
     AND  itp_in_pr.completed_ind                       = 0                       -- �������Ă��Ȃ�(�˗\��)
     AND  itp_in_pr.reverse_id                          IS NULL
     AND  itp_in_pr.doc_type                            = xrpm_in_pr.doc_type
     AND  itp_in_pr.line_id                             = gmd_in_pr.material_detail_id
     AND  itp_in_pr.location                            = grb_in_pr.attribute9
     AND  itp_in_pr.item_id                             = gmd_in_pr.item_id
     -- �i�ڃ}�X�^�Ƃ̌���
     AND  gmd_in_pr.item_id                             = ximv_in_pr.item_id
     AND  gbh_in_pr.plan_start_date                    >= ximv_in_pr.start_date_active
     AND  gbh_in_pr.plan_start_date                    <= ximv_in_pr.end_date_active
     -- ���b�g���擾
     AND  ximv_in_pr.item_id                            = ilm_in_pr.item_id
     AND  itp_in_pr.lot_id                              = ilm_in_pr.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  grb_in_pr.attribute9                          = xilv_in_pr.segment1
     -- �H���}�X�^���{��Ƃ̌���(�󕥐於�擾)
     AND  grt_in_pr.language                            = 'JA'
     AND  grb_in_pr.routing_id                          = grt_in_pr.routing_id
  -- [ �T�D���Y���ɗ\��  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �U�D���Y���ɗ\�� �i�ڐU�� �i��U��
  -- �y���z�ȉ���SQL�͕ύX����ŏ������x���x���Ȃ�܂�
  -------------------------------------------------------------
  SELECT
          xrpm_in_pr70.new_div_invent                   AS reason_code            -- ���R�R�[�h
         ,xilv_in_pr70.whse_code                        AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_pr70.segment1                         AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_pr70.description                      AS location               -- �ۊǏꏊ��
         ,xilv_in_pr70.short_name                       AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_pr70.item_id                          AS item_id                -- �i��ID
         ,ximv_in_pr70.item_no                          AS item_no                -- �i�ڃR�[�h
         ,ximv_in_pr70.item_name                        AS item_name              -- �i�ږ�
         ,ximv_in_pr70.item_short_name                  AS item_short_name        -- �i�ڗ���
         ,ximv_in_pr70.num_of_cases                     AS case_content           -- �P�[�X����
         ,ximv_in_pr70.lot_ctl                          AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_pr70.lot_id                            AS lot_id                 -- ���b�gID
         ,ilm_in_pr70.lot_no                            AS lot_no                 -- ���b�gNo
         ,ilm_in_pr70.attribute1                        AS manufacture_date       -- �����N����
         ,ilm_in_pr70.attribute2                        AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_pr70.attribute3                        AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,gbh_in_pr70.batch_no                          AS voucher_no             -- �`�[�ԍ�
         ,gmd_in_pr70a.line_no                          AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,gbh_in_pr70.attribute2                        AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,itp_in_pr70.trans_date                        AS leaving_date           -- ���o�ɓ�_����
         ,itp_in_pr70.trans_date                        AS arrival_date           -- ���o�ɓ�_����
         ,itp_in_pr70.trans_date                        AS standard_date          -- ����i�����j
         ,grb_in_pr70.routing_no                        AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,grt_in_pr70.routing_desc                      AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,gmd_in_pr70a.plan_qty                         AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,gmd_in_pr70a.plan_qty                         AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_pr70              -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_pr70              -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_pr70               -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_pr70              -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_gme_batch_header_arc                    gbh_in_pr70               -- ���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
         ,xxcmn_gme_material_details_arc                gmd_in_pr70a              -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v(�U�֐�)
         ,xxcmn_gme_material_details_arc                gmd_in_pr70b              -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v(�U�֌�)
         ,gmd_routings_b                                grb_in_pr70               -- �H���}�X�^
         ,gmd_routings_tl                               grt_in_pr70               -- �H���}�X�^���{��
         ,xxcmn_ic_tran_pnd_arc                         itp_in_pr70               -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
         ,xxskz_item_class_v                            xicv_in_pr70b             -- OPM�i�ڃJ�e�S���������VIEW5(�U�֌�)
   WHERE
     -- �󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_pr70.doc_type                         = 'PROD'
     AND  xrpm_in_pr70.use_div_invent                   = 'Y'
     -- �H���}�X�^�Ƃ̌����i�i�ڐU�փf�[�^�擾�̏����j
     AND  grb_in_pr70.routing_class                     = '70'                    -- �i�ڐU��
     AND  gbh_in_pr70.routing_id                        = grb_in_pr70.routing_id
     AND  xrpm_in_pr70.routing_class                    = grb_in_pr70.routing_class
     -- ���Y�����ڍ�(�U�֐�)�Ƃ̌���
     AND  gmd_in_pr70a.line_type                        = 1                       -- �U�֐�
     AND  gbh_in_pr70.batch_id                          = gmd_in_pr70a.batch_id
     AND  xrpm_in_pr70.line_type                        = gmd_in_pr70a.line_type
     -- ���Y�����ڍ�(�U�֌�)�Ƃ̌���
     AND  gmd_in_pr70b.line_type                        = -1                      -- �U�֌�
     AND  gbh_in_pr70.batch_id                          = gmd_in_pr70b.batch_id
     AND  gmd_in_pr70a.batch_id                         = gmd_in_pr70b.batch_id   -- ���������xUP�ɗL��
     -- OPM�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
     AND  itp_in_pr70.delete_mark                       = 0                       -- �L���`�F�b�N(OPM�ۗ��݌�)
     AND  itp_in_pr70.completed_ind                     = 0                       -- �������Ă��Ȃ�(�˗\��)
     AND  itp_in_pr70.reverse_id                        IS NULL
     AND  itp_in_pr70.lot_id                           <> 0                       -- ���ނ͂��蓾�Ȃ�
     AND  itp_in_pr70.doc_type                          = xrpm_in_pr70.doc_type
     AND  itp_in_pr70.doc_id                            = gmd_in_pr70a.batch_id   -- ���������xUP�ɗL��
     AND  itp_in_pr70.doc_line                          = gmd_in_pr70a.line_no    -- ���������xUP�ɗL��
     AND  itp_in_pr70.line_type                         = gmd_in_pr70a.line_type  -- ���������xUP�ɗL��
     AND  itp_in_pr70.line_id                           = gmd_in_pr70a.material_detail_id
     AND  itp_in_pr70.item_id                           = ximv_in_pr70.item_id
     -- OPM�i�ڏ��VIEW
     AND  gmd_in_pr70a.item_id                          = ximv_in_pr70.item_id
     AND  itp_in_pr70.trans_date                       >= ximv_in_pr70.start_date_active
     AND  itp_in_pr70.trans_date                       <= ximv_in_pr70.end_date_active
     -- OPM�i�ڃJ�e�S���������VIEW5(�U�֐�A�U�֌�)
     AND  gmd_in_pr70b.item_id                          = xicv_in_pr70b.item_id
     AND (    xrpm_in_pr70.item_div_ahead               = ximv_in_pr70.item_class_code   -- �U�֐�
          AND xrpm_in_pr70.item_div_origin              = xicv_in_pr70b.item_class_code  -- �U�֌�
          AND (   ( ximv_in_pr70.item_class_code       <> xicv_in_pr70b.item_class_code )
               OR ( ximv_in_pr70.item_class_code        = xicv_in_pr70b.item_class_code )
              )
         )
     -- OPM���b�g�}�X�^���擾
     AND  ximv_in_pr70.item_id                          = ilm_in_pr70.item_id
     AND  itp_in_pr70.lot_id                            = ilm_in_pr70.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  itp_in_pr70.whse_code                         = xilv_in_pr70.whse_code
     AND  itp_in_pr70.location                          = xilv_in_pr70.segment1
     -- �H���}�X�^���{��Ƃ̌���(�󕥐於�擾)
     AND  grt_in_pr70.language                          = 'JA'
     AND  grb_in_pr70.routing_id                        = grt_in_pr70.routing_id
  -- [ �U�D���Y���ɗ\�� �i�ڐU�� �i��U��  END ] --
-- << ���ɗ\�� END >>
UNION ALL
--����������������������������������������������������������������������
--�� �y�o�ɗ\��z                                                     ��
--��    �P�D�ړ��o�ɗ\��(�w�� �ϑ�����)                               ��
--��    �Q�D�ړ��o�ɗ\��(�w�� �ϑ��Ȃ�)                               ��
--��    �R�D�ړ��o�ɗ\��(���ɕ񍐗L �ϑ�����)                         ��
--��    �S�D�󒍏o�ח\��                                              ��
--��    �T�D�L���o�ח\��                                              ��
--��    �U�D���Y���������\��                                          ��
--��    �V�D���Y�o�ɗ\�� �i�ڐU�� �i��U��                            ��
--��    �W�D�����݌ɏo�ɗ\��                                        ��
--����������������������������������������������������������������������
  -------------------------------------------------------------
  -- �P�D�ړ��o�ɗ\��(�w�� �ϑ�����)
  -------------------------------------------------------------
  SELECT
          xrpm_out_xf.new_div_invent                    AS reason_code            -- ���R�R�[�h
         ,xilv_out_xf.whse_code                         AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_xf.segment1                          AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_xf.description                       AS location               -- �ۊǏꏊ��
         ,xilv_out_xf.short_name                        AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_xf.item_id                           AS item_id                -- �i��ID
         ,ximv_out_xf.item_no                           AS item_no                -- �i�ڃR�[�h
         ,ximv_out_xf.item_name                         AS item_name              -- �i�ږ�
         ,ximv_out_xf.item_short_name                   AS item_short_name        -- �i�ڗ���
         ,ximv_out_xf.num_of_cases                      AS case_content           -- �P�[�X����
         ,ximv_out_xf.lot_ctl                           AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_xf.lot_id                             AS lot_id                 -- ���b�gID
         ,ilm_out_xf.lot_no                             AS lot_no                 -- ���b�gNo
         ,ilm_out_xf.attribute1                         AS manufacture_date       -- �����N����
         ,ilm_out_xf.attribute2                         AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_xf.attribute3                         AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xmrih_out_xf.mov_num                          AS voucher_no             -- �`�[�ԍ�
         ,xmril_out_xf.line_number                      AS line_no                -- �s�ԍ�
         ,xmrih_out_xf.delivery_no                      AS delivery_no            -- �z���ԍ�
         ,xmrih_out_xf.instruction_post_code            AS loct_code              -- �����R�[�h
         ,xlc_out_xf.location_name                      AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,xmrih_out_xf.schedule_ship_date               AS leaving_date           -- ���o�ɓ�_����
         ,xmrih_out_xf.schedule_arrival_date            AS arrival_date           -- ���o�ɓ�_����
         ,xmrih_out_xf.schedule_ship_date               AS standard_date          -- ����i�����j
         ,xilv_out_xf2.segment1                         AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xilv_out_xf2.description                      AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,xilv_out_xf2.segment1                         AS deliver_to_no          -- �z����R�[�h
         ,xilv_out_xf2.description                      AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,CASE WHEN xmld_out_xf.mov_lot_dtl_id IS NULL THEN xmril_out_xf.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                         xmld_out_xf.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS leaving_quantity       -- �o�ɐ�
         ,CASE WHEN xmld_out_xf.mov_lot_dtl_id IS NULL THEN xmril_out_xf.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                         xmld_out_xf.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_out_xf               -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_xf               -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_xf                -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_xf               -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_out_xf              -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_req_instr_lines_arc                 xmril_out_xf              -- �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_out_xf               -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,xxskz_item_locations2_v                       xilv_out_xf2              -- OPM�ۊǏꏊ���VIEW2(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_out_xf                -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_xf.doc_type                         = 'XFER'                   -- �ړ��ϑ�����
     AND  xrpm_out_xf.use_div_invent                   = 'Y'
     AND  xrpm_out_xf.rcv_pay_div                      = '-1'                     -- ���o
     --�ړ��˗�/�w���w�b�_�̏���
     AND  xmrih_out_xf.comp_actual_flg                 = 'N'                      -- ���і��v��
     AND  xmrih_out_xf.status                          IN ( '02'                  -- �˗���
                                                           ,'03' )                -- ������
     AND  xmrih_out_xf.mov_type                        = '1'
     --�ړ��˗�/�w�����ׂƂ̌���
     AND  xmril_out_xf.delete_flg                      = 'N'                      -- OFF
     AND  xmrih_out_xf.mov_hdr_id                      = xmril_out_xf.mov_hdr_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  xmril_out_xf.item_id                         = ximv_out_xf.item_id
     AND  xmrih_out_xf.schedule_ship_date             >= ximv_out_xf.start_date_active --�K�p�J�n��
     AND  xmrih_out_xf.schedule_ship_date             <= ximv_out_xf.end_date_active   --�K�p�I����
     --�ړ����b�g�ڍ׎擾
     AND  xmld_out_xf.document_type_code               = '20'                     -- �ړ�
     AND  xmld_out_xf.record_type_code                 = '10'                     -- �w��
     AND  xmril_out_xf.mov_line_id                     = xmld_out_xf.mov_line_id
     --���b�g���擾
     AND  xmld_out_xf.item_id                          = ilm_out_xf.item_id
     AND  xmld_out_xf.lot_id                           = ilm_out_xf.lot_id
     --�ۊǏꏊ���擾
     AND  xmrih_out_xf.shipped_locat_id                = xilv_out_xf.inventory_location_id
     --�󕥐���擾
     AND  xmrih_out_xf.ship_to_locat_id                = xilv_out_xf2.inventory_location_id
     --�������擾
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xmrih_out_xf.instruction_post_code           = xlc_out_xf.location_code(+)
--     AND  xmrih_out_xf.schedule_ship_date             >= xlc_out_xf.start_date_active(+)
--     AND  xmrih_out_xf.schedule_ship_date             <= xlc_out_xf.end_date_active(+)
     AND  xmrih_out_xf.instruction_post_code           = xlc_out_xf.location_code
     AND  xmrih_out_xf.schedule_ship_date             >= xlc_out_xf.start_date_active
     AND  xmrih_out_xf.schedule_ship_date             <= xlc_out_xf.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �P�D�ړ��o�ɗ\��(�w�� �ϑ�����)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �Q�D�ړ��o�ɗ\��(�w�� �ϑ��Ȃ�)
  -------------------------------------------------------------
  SELECT
          xrpm_out_tr.new_div_invent                    AS reason_code            -- ���R�R�[�h
         ,xilv_out_tr.whse_code                         AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_tr.segment1                          AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_tr.description                       AS location               -- �ۊǏꏊ��
         ,xilv_out_tr.short_name                        AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_tr.item_id                           AS item_id                -- �i��ID
         ,ximv_out_tr.item_no                           AS item_no                -- �i�ڃR�[�h
         ,ximv_out_tr.item_name                         AS item_name              -- �i�ږ�
         ,ximv_out_tr.item_short_name                   AS item_short_name        -- �i�ڗ���
         ,ximv_out_tr.num_of_cases                      AS case_content           -- �P�[�X����
         ,ximv_out_tr.lot_ctl                           AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_tr.lot_id                             AS lot_id                 -- ���b�gID
         ,ilm_out_tr.lot_no                             AS lot_no                 -- ���b�gNo
         ,ilm_out_tr.attribute1                         AS manufacture_date       -- �����N����
         ,ilm_out_tr.attribute2                         AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_tr.attribute3                         AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xmrih_out_tr.mov_num                          AS voucher_no             -- �`�[�ԍ�
         ,xmril_out_tr.line_number                      AS line_no                -- �s�ԍ�
         ,xmrih_out_tr.delivery_no                      AS delivery_no            -- �z���ԍ�
         ,xmrih_out_tr.instruction_post_code            AS loct_code              -- �����R�[�h
         ,xlc_out_tr.location_name                      AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,xmrih_out_tr.schedule_ship_date               AS leaving_date           -- ���o�ɓ�_����
         ,xmrih_out_tr.schedule_arrival_date            AS arrival_date           -- ���o�ɓ�_����
         ,xmrih_out_tr.schedule_ship_date               AS standard_date          -- ����i�����j
         ,xilv_out_tr2.segment1                         AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xilv_out_tr2.description                      AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,xilv_out_tr2.segment1                         AS deliver_to_no          -- �z����R�[�h
         ,xilv_out_tr2.description                      AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,CASE WHEN xmld_out_tr.mov_lot_dtl_id IS NULL THEN xmril_out_tr.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                         xmld_out_tr.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS leaving_quantity       -- �o�ɐ�
         ,CASE WHEN xmld_out_tr.mov_lot_dtl_id IS NULL THEN xmril_out_tr.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                         xmld_out_tr.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_out_tr               -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_tr               -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_tr                -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_tr               -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_out_tr              -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_req_instr_lines_arc                 xmril_out_tr              -- �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_out_tr               -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,xxskz_item_locations2_v                       xilv_out_tr2              -- OPM�ۊǏꏊ���VIEW2(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_out_tr                -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_tr.doc_type                          = 'TRNI'                  -- �ړ��ϑ��Ȃ�
     AND  xrpm_out_tr.use_div_invent                    = 'Y'
     AND  xrpm_out_tr.rcv_pay_div                       = '-1'                    -- ���o
     --�ړ��˗�/�w���w�b�_�̏���
     AND  xmrih_out_tr.comp_actual_flg                  = 'N'                     -- ���і��v��
     AND  xmrih_out_tr.status                           IN ( '02'                 -- �˗���
                                                            ,'03' )               -- ������
     AND  xmrih_out_tr.mov_type                         = '2'
     --�ړ��˗�/�w�����ׂƂ̌���
     AND  xmril_out_tr.delete_flg                       = 'N'                     -- OFF
     AND  xmrih_out_tr.mov_hdr_id                       = xmril_out_tr.mov_hdr_id
     --�ړ����b�g�ڍ׎擾
     AND  xmld_out_tr.document_type_code                = '20'                    -- �ړ�
     AND  xmld_out_tr.record_type_code                  = '10'                    -- �w��
     AND  xmril_out_tr.mov_line_id                      = xmld_out_tr.mov_line_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  xmril_out_tr.item_id                          = ximv_out_tr.item_id
     AND  xmrih_out_tr.schedule_ship_date              >= ximv_out_tr.start_date_active --�K�p�J�n��
     AND  xmrih_out_tr.schedule_ship_date              <= ximv_out_tr.end_date_active   --�K�p�I����
     --���b�g���擾
     AND  xmld_out_tr.item_id                           = ilm_out_tr.item_id
     AND  xmld_out_tr.lot_id                            = ilm_out_tr.lot_id
     --�ۊǏꏊ���擾
     AND  xmrih_out_tr.shipped_locat_id                 = xilv_out_tr.inventory_location_id
     --�󕥐���擾
     AND  xmrih_out_tr.ship_to_locat_id                 = xilv_out_tr2.inventory_location_id
     --�������擾
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xmrih_out_tr.instruction_post_code            = xlc_out_tr.location_code(+)
--     AND  xmrih_out_tr.schedule_ship_date              >= xlc_out_tr.start_date_active(+)
--     AND  xmrih_out_tr.schedule_ship_date              <= xlc_out_tr.end_date_active(+)
     AND  xmrih_out_tr.instruction_post_code            = xlc_out_tr.location_code
     AND  xmrih_out_tr.schedule_ship_date              = xlc_out_tr.start_date_active
     AND  xmrih_out_tr.schedule_ship_date              = xlc_out_tr.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �Q�D�ړ��o�ɗ\��(�w�� �ϑ��Ȃ�)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �R�D�ړ��o�ɗ\��(���ɕ񍐗L �ϑ�����)
  -------------------------------------------------------------
  SELECT
          xrpm_out_xf20.new_div_invent                  AS reason_code            -- ���R�R�[�h
         ,xilv_out_xf20.whse_code                       AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_xf20.segment1                        AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_xf20.description                     AS location               -- �ۊǏꏊ��
         ,xilv_out_xf20.short_name                      AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_xf20.item_id                         AS item_id                -- �i��ID
         ,ximv_out_xf20.item_no                         AS item_no                -- �i�ڃR�[�h
         ,ximv_out_xf20.item_name                       AS item_name              -- �i�ږ�
         ,ximv_out_xf20.item_short_name                 AS item_short_name        -- �i�ڗ���
         ,ximv_out_xf20.num_of_cases                    AS case_content           -- �P�[�X����
         ,ximv_out_xf20.lot_ctl                         AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_xf20.lot_id                           AS lot_id                 -- ���b�gID
         ,ilm_out_xf20.lot_no                           AS lot_no                 -- ���b�gNo
         ,ilm_out_xf20.attribute1                       AS manufacture_date       -- �����N����
         ,ilm_out_xf20.attribute2                       AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_xf20.attribute3                       AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xmrih_out_xf20.mov_num                        AS voucher_no             -- �`�[�ԍ�
         ,xmril_out_xf20.line_number                    AS line_no                -- �s�ԍ�
         ,xmrih_out_xf20.delivery_no                    AS delivery_no            -- �z���ԍ�
         ,xmrih_out_xf20.instruction_post_code          AS loct_code              -- �����R�[�h
         ,xlc_out_xf20.location_name                    AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,xmrih_out_xf20.schedule_ship_date             AS leaving_date           -- ���o�ɓ�_����
         ,xmrih_out_xf20.schedule_arrival_date          AS arrival_date           -- ���o�ɓ�_����
         ,xmrih_out_xf20.schedule_ship_date             AS standard_date          -- ����i�����j
         ,xilv_out_xf202.segment1                       AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xilv_out_xf202.description                    AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪
         ,xilv_out_xf202.segment1                       AS deliver_to_no          -- �z����R�[�h
         ,xilv_out_xf202.description                    AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,CASE WHEN xmld_out_xf20.mov_lot_dtl_id IS NULL THEN xmril_out_xf20.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                           xmld_out_xf20.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS leaving_quantity       -- �o�ɐ�
         ,CASE WHEN xmld_out_xf20.mov_lot_dtl_id IS NULL THEN xmril_out_xf20.instruct_qty     -- ���b�g���������Ȃ�i�ڒP�ʂ̐���
               ELSE                                           xmld_out_xf20.actual_quantity   -- ���b�g�����L��Ȃ烍�b�g�P�ʂ̐���
          END                                           AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_out_xf20             -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_xf20             -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_xf20              -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_xf20             -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_out_xf20            -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_req_instr_lines_arc                 xmril_out_xf20            -- �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_out_xf20             -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,xxskz_item_locations2_v                       xilv_out_xf202            -- OPM�ۊǏꏊ���VIEW2(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_out_xf20              -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_xf20.doc_type                        = 'XFER'                  -- �ړ��ϑ�����
     AND  xrpm_out_xf20.use_div_invent                  = 'Y'
     AND  xrpm_out_xf20.rcv_pay_div                     = '-1'                    -- ���o
     --�ړ��˗�/�w���w�b�_�̏���
     AND  xmrih_out_xf20.comp_actual_flg                = 'N'                     -- ���і��v��
     AND  xmrih_out_xf20.status                         = '05'                    -- ���ɕ񍐗L
     AND  xmrih_out_xf20.mov_type                       = '1'                     -- �ϑ�����
     --�ړ��˗�/�w�����ׂƂ̌���
     AND  xmril_out_xf20.delete_flg                     = 'N'                     -- OFF
     AND  xmrih_out_xf20.mov_hdr_id                     = xmril_out_xf20.mov_hdr_id
     --�ړ����b�g�ڍ׎擾
     AND  xmld_out_xf20.document_type_code              = '20'                    -- �ړ�
     AND  xmld_out_xf20.record_type_code                = '30'                    -- ���Ɏ���
     AND  xmril_out_xf20.mov_line_id                    = xmld_out_xf20.mov_line_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  xmril_out_xf20.item_id                        = ximv_out_xf20.item_id
     AND  xmrih_out_xf20.schedule_ship_date            >= ximv_out_xf20.start_date_active --�K�p�J�n��
     AND  xmrih_out_xf20.schedule_ship_date            <= ximv_out_xf20.end_date_active   --�K�p�I����
     --���b�g���擾
     AND  xmld_out_xf20.item_id                         = ilm_out_xf20.item_id
     AND  xmld_out_xf20.lot_id                          = ilm_out_xf20.lot_id
     --�ۊǏꏊ���擾
     AND  xmrih_out_xf20.shipped_locat_id               = xilv_out_xf20.inventory_location_id
     --�󕥐���擾
     AND  xmrih_out_xf20.ship_to_locat_id               = xilv_out_xf202.inventory_location_id
     --�������擾
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xmrih_out_xf20.instruction_post_code          = xlc_out_xf20.location_code(+)
--     AND  xmrih_out_xf20.schedule_ship_date            >= xlc_out_xf20.start_date_active(+)
--     AND  xmrih_out_xf20.schedule_ship_date            <= xlc_out_xf20.end_date_active(+)
     AND  xmrih_out_xf20.instruction_post_code          = xlc_out_xf20.location_code
     AND  xmrih_out_xf20.schedule_ship_date            >= xlc_out_xf20.start_date_active
     AND  xmrih_out_xf20.schedule_ship_date            <= xlc_out_xf20.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �R�D�ړ��o�ɗ\��(���ɕ񍐗L �ϑ�����)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �S�D�󒍏o�ח\��
  -------------------------------------------------------------
  SELECT
          xrpm_out_om.new_div_invent                    AS reason_code            -- ���R�R�[�h
         ,xilv_out_om.whse_code                         AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_om.segment1                          AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_om.description                       AS location               -- �ۊǏꏊ��
         ,xilv_out_om.short_name                        AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_om_s.item_id                         AS item_id                -- �i��ID
         ,ximv_out_om_s.item_no                         AS item_no                -- �i�ڃR�[�h
         ,ximv_out_om_s.item_name                       AS item_name              -- �i�ږ�
         ,ximv_out_om_s.item_short_name                 AS item_short_name        -- �i�ڗ���
         ,ximv_out_om_s.num_of_cases                    AS case_content           -- �P�[�X����
         ,ximv_out_om_s.lot_ctl                         AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_om.lot_id                             AS lot_id                 -- ���b�gID
         ,ilm_out_om.lot_no                             AS lot_no                 -- ���b�gNo
         ,ilm_out_om.attribute1                         AS manufacture_date       -- �����N����
         ,ilm_out_om.attribute2                         AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_om.attribute3                         AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xoha_out_om.request_no                        AS voucher_no             -- �`�[�ԍ�
         ,xola_out_om.order_line_number                 AS line_no                -- �s�ԍ�
         ,xoha_out_om.delivery_no                       AS delivery_no            -- �z���ԍ�
         ,xoha_out_om.performance_management_dept       AS loct_code              -- �����R�[�h
         ,xlc_out_om.location_name                      AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,xoha_out_om.schedule_ship_date                AS leaving_date           -- ���o�ɓ�_����
         ,xoha_out_om.schedule_arrival_date             AS arrival_date           -- ���o�ɓ�_����
         ,xoha_out_om.schedule_ship_date                AS standard_date          -- ����i�����j
         ,CASE WHEN xcst_out_om.customer_class_code = '10' THEN xoha_out_om.head_sales_branch  --�ڋq�R�[�h���ڋq�ł���ΊǊ����_��\��
               ELSE                                             xoha_out_om.customer_code      --�ڋq�R�[�h�����_�ł���΂��̋��_��\��
          END                                           AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,CASE WHEN xcst_out_om.customer_class_code = '10' THEN xcst_out_om_h.party_name       --�ڋq�R�[�h���ڋq�ł���ΊǊ����_����\��
               ELSE                                             xcst_out_om.party_name         --�ڋq�R�[�h�����_�ł���΂��̋��_����\��
          END                                           AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪
         ,xpas_out_om.party_site_number                 AS deliver_to_no          -- �z����R�[�h
         ,xpas_out_om.party_site_name                   AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,xmld_out_om.actual_quantity                   AS leaving_quantity       -- �o�ɐ�
         ,xmld_out_om.actual_quantity                   AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_out_om               -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_om_s             -- OPM�i�ڏ��VIEW(�o�וi��)
         ,ic_lots_mst                                   ilm_out_om                -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_om               -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_order_headers_all_arc                   xoha_out_om               -- �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_order_lines_all_arc                     xola_out_om               -- �󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_out_om               -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,oe_transaction_types_all                      otta_out_om               -- �󒍃^�C�v
         ,xxskz_item_mst2_v                             ximv_out_om_r             -- OPM�i�ڏ��VIEW(�˗��i��)
         ,xxskz_cust_accounts2_v                        xcst_out_om               -- �󕥐�(���_)�擾�p
         ,xxskz_cust_accounts2_v                        xcst_out_om_h             -- �󕥐�(�Ǌ����_)�擾�p
         ,xxskz_party_sites2_v                          xpas_out_om               -- �z���於�擾�p
         ,xxskz_locations2_v                            xlc_out_om                -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_om.doc_type                          = 'OMSO'
     AND  xrpm_out_om.use_div_invent                    = 'Y'
     AND  xrpm_out_om.shipment_provision_div            = '1'                     -- �o�׈˗�
     --�󒍃^�C�v�̏����i�܂ށF�󕥋敪�A�h�I���}�X�^�̍i���ݏ����j
     AND  otta_out_om.attribute1                        = '1'                     -- �o�׈˗�
     AND  (   xrpm_out_om.ship_prov_rcv_pay_category    IS NULL
           OR xrpm_out_om.ship_prov_rcv_pay_category    = otta_out_om.attribute11
          )
     --�󒍃w�b�_�̏���
     AND  xoha_out_om.req_status                        = '03'                    -- ���ߍ�
     AND  NVL( xoha_out_om.actual_confirm_class, 'N' )  = 'N'                     -- ���і��v��
     AND  xoha_out_om.latest_external_flag              = 'Y'                     -- ON
     AND  otta_out_om.transaction_type_id               = xoha_out_om.order_type_id
     --�󒍖��ׂƂ̌���
     AND  NVL( xola_out_om.delete_flag, 'N' )           = 'N'                     -- �������׈ȊO
     AND  xoha_out_om.order_header_id                   = xola_out_om.order_header_id
     --�ړ����b�g�ڍ׎擾
     AND  xmld_out_om.document_type_code                = '10'                    -- �o�׈˗�
     AND  xmld_out_om.record_type_code                  = '10'                    -- �w��
     AND  xola_out_om.order_line_id                     = xmld_out_om.mov_line_id
     --�i�ڃ}�X�^(�o�וi��)�Ƃ̌���
     AND  xola_out_om.shipping_inventory_item_id        = ximv_out_om_s.inventory_item_id
     AND  xoha_out_om.schedule_ship_date               >= ximv_out_om_s.start_date_active --�K�p�J�n��
     AND  xoha_out_om.schedule_ship_date               <= ximv_out_om_s.end_date_active   --�K�p�I����
     AND  NVL( xrpm_out_om.item_div_origin, 'Dummy' )   = DECODE( ximv_out_om_s.item_class_code,'5','5','Dummy' ) --�U�֌��i�ڋ敪 = �o�וi�ڋ敪
     --�i�ڃ}�X�^(�˗��i��)�Ƃ̌���
     AND  xola_out_om.request_item_id                   = ximv_out_om_r.inventory_item_id
     AND  xoha_out_om.schedule_ship_date               >= ximv_out_om_r.start_date_active --�K�p�J�n��
     AND  xoha_out_om.schedule_ship_date               <= ximv_out_om_r.end_date_active   --�K�p�I����
     AND  NVL( xrpm_out_om.item_div_ahead , 'Dummy' )   = DECODE( ximv_out_om_r.item_class_code,'5','5','Dummy' ) --�U�֐�i�ڋ敪 = �˗��i�ڋ敪
     --���b�g���擾�i���b�g�����Ă���Ă��Ȃ��f�[�^���o�͑ΏƂƂ���ׂɊO���������s���j
     AND  xmld_out_om.item_id                           = ilm_out_om.item_id
     AND  xmld_out_om.lot_id                            = ilm_out_om.lot_id
     --�ۊǏꏊ���擾
     AND  xoha_out_om.deliver_from_id                   = xilv_out_om.inventory_location_id
     --�󕥐���擾�i���_�j
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
--     AND  xoha_out_om.customer_id                       = xcst_out_om.party_id
     AND  xpas_out_om.party_id                          = xcst_out_om.party_id
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
     AND  xoha_out_om.schedule_ship_date               >= xcst_out_om.start_date_active --�K�p�J�n��
     AND  xoha_out_om.schedule_ship_date               <= xcst_out_om.end_date_active   --�K�p�I����
     --�󕥐���擾�i�Ǌ����_�j
     AND  xoha_out_om.head_sales_branch                 = xcst_out_om_h.party_number(+)
     AND  xoha_out_om.schedule_ship_date               >= xcst_out_om_h.start_date_active(+) --�K�p�J�n��
     AND  xoha_out_om.schedule_ship_date               <= xcst_out_om_h.end_date_active(+)   --�K�p�I����
     --�z����擾
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
--     AND  xoha_out_om.deliver_to_id                     = xpas_out_om.party_site_id
     AND  xoha_out_om.deliver_to                        = xpas_out_om.party_site_number
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
     AND  xoha_out_om.schedule_ship_date               >= xpas_out_om.start_date_active --�K�p�J�n��
     AND  xoha_out_om.schedule_ship_date               <= xpas_out_om.end_date_active   --�K�p�I����
     --�������擾
     AND  xoha_out_om.performance_management_dept       = xlc_out_om.location_code(+)
     AND  xoha_out_om.schedule_ship_date               >= xlc_out_om.start_date_active(+)
     AND  xoha_out_om.schedule_ship_date               <= xlc_out_om.end_date_active(+)
  -- [ �S�D�󒍏o�ח\��  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �T�D�L���o�ח\��
  -------------------------------------------------------------
  SELECT
          xrpm_out_om2.new_div_invent                   AS reason_code            -- ���R�R�[�h
         ,xilv_out_om2.whse_code                        AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_om2.segment1                         AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_om2.description                      AS location               -- �ۊǏꏊ��
         ,xilv_out_om2.short_name                       AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_om2_s.item_id                        AS item_id                -- �i��ID
         ,ximv_out_om2_s.item_no                        AS item_no                -- �i�ڃR�[�h
         ,ximv_out_om2_s.item_name                      AS item_name              -- �i�ږ�
         ,ximv_out_om2_s.item_short_name                AS item_short_name        -- �i�ڗ���
         ,ximv_out_om2_s.num_of_cases                   AS case_content           -- �P�[�X����
         ,ximv_out_om2_s.lot_ctl                        AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_om2.lot_id                            AS lot_id                 -- ���b�gID
         ,ilm_out_om2.lot_no                            AS lot_no                 -- ���b�gNo
         ,ilm_out_om2.attribute1                        AS manufacture_date       -- �����N����
         ,ilm_out_om2.attribute2                        AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_om2.attribute3                        AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xoha_out_om2.request_no                       AS voucher_no             -- �`�[�ԍ�
         ,xola_out_om2.order_line_number                AS line_no                -- �s�ԍ�
         ,xoha_out_om2.delivery_no                      AS delivery_no            -- �z���ԍ�
         ,xoha_out_om2.performance_management_dept      AS loct_code              -- �����R�[�h
         ,xlc_out_om2.location_name                     AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,xoha_out_om2.schedule_ship_date               AS leaving_date           -- ���o�ɓ�_����
         ,xoha_out_om2.schedule_arrival_date            AS arrival_date           -- ���o�ɓ�_����
         ,xoha_out_om2.schedule_ship_date               AS standard_date          -- ����i�����j
         ,xoha_out_om2.vendor_site_code                 AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xvsv_out_om2.vendor_site_name                 AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,CASE WHEN otta_out_om2.order_category_code = 'RETURN' THEN xmld_out_om2.actual_quantity * -1
               ELSE                                                  xmld_out_om2.actual_quantity
          END                                           AS leaving_quantity       -- �o�ɐ�
         ,CASE WHEN otta_out_om2.order_category_code = 'RETURN' THEN xmld_out_om2.actual_quantity * -1
               ELSE                                                  xmld_out_om2.actual_quantity
          END                                           AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_out_om2              -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_om2_s            -- OPM�i�ڏ��VIEW(�o�וi��)
         ,ic_lots_mst                                   ilm_out_om2               -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_om2              -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_order_headers_all_arc                   xoha_out_om2              -- �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_order_lines_all_arc                     xola_out_om2              -- �󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_out_om2              -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,oe_transaction_types_all                      otta_out_om2              -- �󒍃^�C�v
         ,xxskz_item_mst2_v                             ximv_out_om2_r            -- OPM�i�ڏ��VIEW(�˗��i��)
         ,xxskz_vendor_sites_v                          xvsv_out_om2              -- �d����T�C�g���VIEW(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_out_om2               -- �������擾�p
  WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_om2.doc_type                         = 'OMSO'
     AND  xrpm_out_om2.use_div_invent                   = 'Y'
     AND  xrpm_out_om2.shipment_provision_div           = '2'       -- �x���˗�
     --�󒍃^�C�v�̏����i�܂ށF�󕥋敪�A�h�I���}�X�^�̍i���ݏ����j
     AND  otta_out_om2.attribute1                       = '2'       -- �x���˗�
     AND (   xrpm_out_om2.ship_prov_rcv_pay_category    IS NULL
          OR xrpm_out_om2.ship_prov_rcv_pay_category    = otta_out_om2.attribute11
         )
     --�󒍃w�b�_�̏���
     AND  xoha_out_om2.req_status                       = '07'      -- ��̍�
     AND  NVL( xoha_out_om2.actual_confirm_class, 'N' ) = 'N'       -- ���і��v��
     AND  xoha_out_om2.latest_external_flag             = 'Y'       -- ON
     AND  otta_out_om2.transaction_type_id              = xoha_out_om2.order_type_id
     --�󒍖��ׂƂ̌���
     AND  xola_out_om2.delete_flag                      = 'N'       -- OFF
     AND  xoha_out_om2.order_header_id                  = xola_out_om2.order_header_id
     --�ړ����b�g�ڍ׎擾
     AND  xmld_out_om2.document_type_code               = '30'      -- �x���w��
     AND  xmld_out_om2.record_type_code                 = '10'      -- �w��
     AND  xola_out_om2.order_line_id                    = xmld_out_om2.mov_line_id
     --�i�ڃ}�X�^(�o�וi��)�Ƃ̌���
     AND  xola_out_om2.shipping_inventory_item_id       = ximv_out_om2_s.inventory_item_id
     AND  xoha_out_om2.schedule_ship_date              >= ximv_out_om2_s.start_date_active --�K�p�J�n��
     AND  xoha_out_om2.schedule_ship_date              <= ximv_out_om2_s.end_date_active   --�K�p�I����
     AND  NVL( xrpm_out_om2.item_div_origin,'Dummy' )   = DECODE( ximv_out_om2_s.item_class_code,'5','5','Dummy' ) --�U�֌��i�ڋ敪 = �o�וi�ڋ敪
     --�i�ڃ}�X�^(�˗��i��)�Ƃ̌���
     AND  xola_out_om2.request_item_id                  = ximv_out_om2_r.inventory_item_id
     AND  xoha_out_om2.schedule_ship_date              >= ximv_out_om2_r.start_date_active --�K�p�J�n��
     AND  xoha_out_om2.schedule_ship_date              <= ximv_out_om2_r.end_date_active   --�K�p�I����
     AND  NVL( xrpm_out_om2.item_div_ahead ,'Dummy' )   = DECODE( ximv_out_om2_r.item_class_code,'5','5','Dummy' ) --�U�֐�i�ڋ敪 = �˗��i�ڋ敪
     --�i�ڃJ�e�S���������(�o�וi�ځE�˗��i��)��������
     AND  (  (     xola_out_om2.shipping_inventory_item_id = xola_out_om2.request_item_id               -- �i�ڐU�ւł͂Ȃ�
               AND xrpm_out_om2.prod_div_origin            IS NULL
               AND xrpm_out_om2.prod_div_ahead             IS NULL
              )
           OR (    xola_out_om2.shipping_inventory_item_id <> xola_out_om2.request_item_id              -- �i�ڐU��
               AND ximv_out_om2_s.item_class_code          = '5'                                        -- ���i
               AND ximv_out_om2_r.item_class_code          = '5'                                        -- ���i
               AND xrpm_out_om2.prod_div_origin            IS NOT NULL
               AND xrpm_out_om2.prod_div_ahead             IS NOT NULL
              )
           OR (    xola_out_om2.shipping_inventory_item_id <> xola_out_om2.request_item_id              -- �i�ڐU��
               AND ( ximv_out_om2_s.item_class_code <> '5' OR ximv_out_om2_r.item_class_code <> '5' )   -- ���i�ł͂Ȃ�
               AND xrpm_out_om2.prod_div_origin            IS NULL
               AND xrpm_out_om2.prod_div_ahead             IS NULL
              )
          )
     --���b�g���擾
     AND  xmld_out_om2.item_id                          = ilm_out_om2.item_id
     AND  xmld_out_om2.lot_id                           = ilm_out_om2.lot_id
     --�ۊǏꏊ���擾
     AND  xoha_out_om2.deliver_from_id                  = xilv_out_om2.inventory_location_id
     --�󕥐���i�d����T�C�g���j�擾
     AND  xoha_out_om2.vendor_site_id                   = xvsv_out_om2.vendor_site_id
     AND  xoha_out_om2.schedule_ship_date              >= xvsv_out_om2.start_date_active --�K�p�J�n��
     AND  xoha_out_om2.schedule_ship_date              <= xvsv_out_om2.end_date_active   --�K�p�I����
     --�������擾
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xoha_out_om2.performance_management_dept      = xlc_out_om2.location_code(+)
--     AND  xoha_out_om2.schedule_ship_date              >= xlc_out_om2.start_date_active(+)
--     AND  xoha_out_om2.schedule_ship_date              <= xlc_out_om2.end_date_active(+)
     AND  xoha_out_om2.performance_management_dept      = xlc_out_om2.location_code
     AND  xoha_out_om2.schedule_ship_date              >= xlc_out_om2.start_date_active
     AND  xoha_out_om2.schedule_ship_date              <= xlc_out_om2.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �T�D�L���o�ח\��  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �U�D���Y���������\��
  -------------------------------------------------------------
  SELECT
          xrpm_out_pr.new_div_invent                    AS reason_code            -- ���R�R�[�h
         ,xilv_out_pr.whse_code                         AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_pr.segment1                          AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_pr.description                       AS location               -- �ۊǏꏊ��
         ,xilv_out_pr.short_name                        AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_pr.item_id                           AS item_id                -- �i��ID
         ,ximv_out_pr.item_no                           AS item_no                -- �i�ڃR�[�h
         ,ximv_out_pr.item_name                         AS item_name              -- �i�ږ�
         ,ximv_out_pr.item_short_name                   AS item_short_name        -- �i�ڗ���
         ,ximv_out_pr.num_of_cases                      AS case_content           -- �P�[�X����
         ,ximv_out_pr.lot_ctl                           AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_pr.lot_id                             AS lot_id                 -- ���b�gID
         ,ilm_out_pr.lot_no                             AS lot_no                 -- ���b�gNo
         ,ilm_out_pr.attribute1                         AS manufacture_date       -- �����N����
         ,ilm_out_pr.attribute2                         AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_pr.attribute3                         AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,gbh_out_pr.batch_no                           AS voucher_no             -- �`�[�ԍ�
         ,gmd_out_pr.line_no                            AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,gbh_out_pr.attribute2                         AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,gbh_out_pr.plan_start_date                    AS leaving_date           -- ���o�ɓ�_����
         ,gbh_out_pr.plan_start_date                    AS arrival_date           -- ���o�ɓ�_����
         ,gbh_out_pr.plan_start_date                    AS standard_date          -- ����i�����j
         ,grb_out_pr.routing_no                         AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,grt_out_pr.routing_desc                       AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,itp_out_pr.trans_qty * -1                     AS leaving_quantity       -- �o�ɐ�
         ,itp_out_pr.trans_qty * -1                     AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_out_pr               -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_pr               -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_pr                -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_pr               -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_gme_batch_header_arc                    gbh_out_pr                -- ���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
         ,xxcmn_gme_material_details_arc                gmd_out_pr                -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v
         ,gmd_routings_b                                grb_out_pr                -- �H���}�X�^
         ,gmd_routings_tl                               grt_out_pr                -- �H���}�X�^���{��
         ,xxcmn_ic_tran_pnd_arc                         itp_out_pr                -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_pr.doc_type                          = 'PROD'
     AND  xrpm_out_pr.use_div_invent                    = 'Y'
     -- �H���}�X�^�Ƃ̌����i���Y�f�[�^�擾�̏����j
     AND  grb_out_pr.routing_class                      NOT IN ( '61', '62', '70' )  -- �i�ڐU��(70)�A���(61,62) �ȊO
     AND  gbh_out_pr.routing_id                         = grb_out_pr.routing_id
     AND  xrpm_out_pr.routing_class                     = grb_out_pr.routing_class
     -- ���Y�o�b�`�w�b�_�̏���
     AND  gbh_out_pr.batch_status                       IN ( '1', '2' )           -- 1:�ۗ��A2:WIP
     --���Y�����ڍׂ̌���
     AND  gmd_out_pr.line_type                          = -1                      -- -1:����
     AND  gbh_out_pr.batch_id                           = gmd_out_pr.batch_id
     AND  gmd_out_pr.line_type                          = xrpm_out_pr.line_type
     AND (   ( ( gmd_out_pr.attribute5 IS NULL     ) AND ( xrpm_out_pr.hit_in_div IS NULL ) )
          OR ( ( gmd_out_pr.attribute5 IS NOT NULL ) AND ( xrpm_out_pr.hit_in_div = gmd_out_pr.attribute5 ) )
         )
     --�ۗ��݌Ƀg�����U�N�V�����̎擾
     AND  itp_out_pr.delete_mark                        = 0                       -- �L���`�F�b�N(OPM�ۗ��݌�)
     AND  itp_out_pr.completed_ind                      = 0                       -- �������Ă��Ȃ�(�˗\��)
     AND  itp_out_pr.reverse_id                         IS NULL
     AND  itp_out_pr.doc_type                           = xrpm_out_pr.doc_type
     AND  itp_out_pr.line_id                            = gmd_out_pr.material_detail_id
     AND  itp_out_pr.location                           = grb_out_pr.attribute9
     AND  itp_out_pr.item_id                            = gmd_out_pr.item_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  itp_out_pr.item_id                            = ximv_out_pr.item_id
     AND  itp_out_pr.trans_date                        >= ximv_out_pr.start_date_active --�K�p�J�n��
     AND  itp_out_pr.trans_date                        <= ximv_out_pr.end_date_active   --�K�p�I����
     --���b�g���擾
     AND  itp_out_pr.item_id                            = ilm_out_pr.item_id
     AND  itp_out_pr.lot_id                             = ilm_out_pr.lot_id
     --�ۊǏꏊ���擾
     AND  grb_out_pr.attribute9                         = xilv_out_pr.segment1
     --�H���}�X�^���{��擾
     AND  grt_out_pr.language                           = 'JA'
     AND  grb_out_pr.routing_id                         = grt_out_pr.routing_id
  -- [ �U�D���Y���������\��  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �V�D���Y�o�ɗ\�� �i�ڐU�� �i��U��
  -- �y���z�ȉ���SQL�͕ύX����ŏ������x���x���Ȃ�܂�
  -------------------------------------------------------------
  SELECT
          xrpm_out_pr70.new_div_invent                  AS reason_code            -- ���R�R�[�h
         ,xilv_out_pr70.whse_code                       AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_pr70.segment1                        AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_pr70.description                     AS location               -- �ۊǏꏊ��
         ,xilv_out_pr70.short_name                      AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_pr70.item_id                         AS item_id                -- �i��ID
         ,ximv_out_pr70.item_no                         AS item_no                -- �i�ڃR�[�h
         ,ximv_out_pr70.item_name                       AS item_name              -- �i�ږ�
         ,ximv_out_pr70.item_short_name                 AS item_short_name        -- �i�ڗ���
         ,ximv_out_pr70.num_of_cases                    AS case_content           -- �P�[�X����
         ,ximv_out_pr70.lot_ctl                         AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_pr70.lot_id                           AS lot_id                 -- ���b�gID
         ,ilm_out_pr70.lot_no                           AS lot_no                 -- ���b�gNo
         ,ilm_out_pr70.attribute1                       AS manufacture_date       -- �����N����
         ,ilm_out_pr70.attribute2                       AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_pr70.attribute3                       AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,gbh_out_pr70.batch_no                         AS voucher_no             -- �`�[�ԍ�
         ,gmd_out_pr70a.line_no                         AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,gbh_out_pr70.attribute2                       AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,itp_out_pr70.trans_date                       AS leaving_date           -- ���o�ɓ�_����
         ,itp_out_pr70.trans_date                       AS arrival_date           -- ���o�ɓ�_����
         ,itp_out_pr70.trans_date                       AS standard_date          -- ����i�����j
         ,grb_out_pr70.routing_no                       AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,grt_out_pr70.routing_desc                     AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,gmd_out_pr70a.plan_qty                        AS leaving_quantity       -- �o�ɐ�
         ,gmd_out_pr70a.plan_qty                        AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_out_pr70             -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_pr70             -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_pr70              -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_pr70             -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_gme_batch_header_arc                    gbh_out_pr70              -- ���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
         ,xxcmn_gme_material_details_arc                gmd_out_pr70a             -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v(�U�֌�)
         ,xxcmn_gme_material_details_arc                gmd_out_pr70b             -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v(�U�֐�)
         ,gmd_routings_b                                grb_out_pr70              -- �H���}�X�^
         ,gmd_routings_tl                               grt_out_pr70              -- �H���}�X�^���{��
         ,xxcmn_ic_tran_pnd_arc                         itp_out_pr70              -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
         ,xxskz_item_class_v                            xicv_out_pr70b            -- OPM�i�ڃJ�e�S���������VIEW5(�U�֐�)
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_pr70.doc_type                        = 'PROD'
     AND  xrpm_out_pr70.use_div_invent                  = 'Y'
     -- �H���}�X�^�Ƃ̌����i�i�ڐU�փf�[�^�擾�̏����j
     AND  grb_out_pr70.routing_class                    = '70'                    -- �i�ڐU��
     AND  gbh_out_pr70.routing_id                       = grb_out_pr70.routing_id
     AND  xrpm_out_pr70.routing_class                   = grb_out_pr70.routing_class
     --���Y�o�b�`�E���Y�����ڍ�(�U�֌�)�̌�������
     AND  gmd_out_pr70a.line_type                       = -1                      -- �U�֌�
     AND  gbh_out_pr70.batch_id                         = gmd_out_pr70a.batch_id
     AND  xrpm_out_pr70.line_type                       = gmd_out_pr70a.line_type
     --���Y�o�b�`�E���Y�����ڍ�(�U�֐�)�̌�������
     AND  gmd_out_pr70b.line_type                       = 1                       -- �U�֐�
     AND  gbh_out_pr70.batch_id                         = gmd_out_pr70b.batch_id
     AND  gmd_out_pr70a.batch_id                        = gmd_out_pr70b.batch_id  -- ���������xUP�ɗL��
     --�ۗ��݌Ƀg�����U�N�V�����̎擾
     AND  itp_out_pr70.delete_mark                      = 0                       -- �L���`�F�b�N(OPM�ۗ��݌�)
     AND  itp_out_pr70.completed_ind                    = 0                       -- �������Ă��Ȃ�(�˗\��)
     AND  itp_out_pr70.reverse_id                       IS NULL
     AND  itp_out_pr70.lot_id                          <> 0
     AND  itp_out_pr70.doc_type                         = xrpm_out_pr70.doc_type
     AND  itp_out_pr70.doc_id                           = gmd_out_pr70a.batch_id  -- ���������xUP�ɗL��
     AND  itp_out_pr70.doc_line                         = gmd_out_pr70a.line_no   -- ���������xUP�ɗL��
     AND  itp_out_pr70.line_type                        = gmd_out_pr70a.line_type -- ���������xUP�ɗL��
     AND  itp_out_pr70.line_id                          = gmd_out_pr70a.material_detail_id
     AND  itp_out_pr70.item_id                          = ximv_out_pr70.item_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  gmd_out_pr70a.item_id                         = ximv_out_pr70.item_id
     AND  itp_out_pr70.trans_date                      >= ximv_out_pr70.start_date_active --�K�p�J�n��
     AND  itp_out_pr70.trans_date                      <= ximv_out_pr70.end_date_active   --�K�p�I����
     -- OPM�i�ڃJ�e�S���������VIEW5(�U�֐�A�U�֌�)
     AND  gmd_out_pr70b.item_id                         = xicv_out_pr70b.item_id
     AND (    xrpm_out_pr70.item_div_origin             = ximv_out_pr70.item_class_code   -- �U�֌�
          AND xrpm_out_pr70.item_div_ahead              = xicv_out_pr70b.item_class_code  -- �U�֐�
          AND (   ( ximv_out_pr70.item_class_code      <> xicv_out_pr70b.item_class_code )
               OR ( ximv_out_pr70.item_class_code       = xicv_out_pr70b.item_class_code )
              )
         )
     --���b�g���擾
     AND  ximv_out_pr70.item_id                         = ilm_out_pr70.item_id
     AND  itp_out_pr70.lot_id                           = ilm_out_pr70.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  itp_out_pr70.whse_code                        = xilv_out_pr70.whse_code
     AND  itp_out_pr70.location                         = xilv_out_pr70.segment1
     --�H���}�X�^���{��擾
     AND  grt_out_pr70.language                         = 'JA'
     AND  grb_out_pr70.routing_id                       = grt_out_pr70.routing_id
  -- [ �V�D���Y�o�ɗ\�� �i�ڐU�� �i��U��  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �W�D�����݌ɏo�ɗ\��
  -------------------------------------------------------------
  SELECT
          xrpm_out_ad.new_div_invent                    AS reason_code            -- ���R�R�[�h
         ,xilv_out_ad.whse_code                         AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_ad.segment1                          AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_ad.description                       AS location               -- �ۊǏꏊ��
         ,xilv_out_ad.short_name                        AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_ad.item_id                           AS item_id                -- �i��ID
         ,ximv_out_ad.item_no                           AS item_no                -- �i�ڃR�[�h
         ,ximv_out_ad.item_name                         AS item_name              -- �i�ږ�
         ,ximv_out_ad.item_short_name                   AS item_short_name        -- �i�ڗ���
         ,ximv_out_ad.num_of_cases                      AS case_content           -- �P�[�X����
         ,ximv_out_ad.lot_ctl                           AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_ad.lot_id                             AS lot_id                 -- ���b�gID
         ,ilm_out_ad.lot_no                             AS lot_no                 -- ���b�gNo
         ,ilm_out_ad.attribute1                         AS manufacture_date       -- �����N����
         ,ilm_out_ad.attribute2                         AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_ad.attribute3                         AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,pha_out_ad.segment1                           AS voucher_no             -- �`�[�ԍ�
         ,NULL                                          AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,pha_out_ad.attribute10                        AS loct_code              -- �����R�[�h
         ,xlc_out_ad.location_name                      AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' )   AS leaving_date        -- ���o�ɓ�_����
         ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' )   AS arrival_date        -- ���o�ɓ�_����
         ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' )   AS standard_date       -- ����i�����j
         ,xvv_out_ad.segment1                           AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xvv_out_ad.vendor_name                        AS ukebaraisaki_name      -- �󕥐於
         ,'1'                                           AS status                 -- �\����ы敪�i1:�\��j
         ,xilv_out_ad.segment1                          AS deliver_to_no          -- �z����R�[�h
         ,xilv_out_ad.description                       AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,pla_out_ad.quantity                           AS leaving_quantity       -- �o�ɐ�
         ,pla_out_ad.quantity                           AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_out_ad               -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_ad               -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_ad                -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_ad               -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,po_headers_all                                pha_out_ad                -- �����w�b�_
         ,po_lines_all                                  pla_out_ad                -- ��������
         ,xxinv_mov_lot_details                         xmld_out_ad               -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,xxskz_vendors_v                               xvv_out_ad                -- �d������VIEW(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_out_ad                -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_ad.doc_type                          = 'ADJI'
     AND  xrpm_out_ad.reason_code                       = 'X977'                  -- �����݌�
     AND  xrpm_out_ad.rcv_pay_div                       = '-1'                    -- ���o
     AND  xrpm_out_ad.use_div_invent                    = 'Y'
     --�����w�b�_�̏���
     AND  pha_out_ad.attribute11                        = '3'
     AND  pha_out_ad.attribute1                         IN ( '20'                 -- �����쐬��
                                                            ,'25' )               -- �������
     --�������ׂ̌���
     AND  NVL( pla_out_ad.attribute13, 'N' )            <> 'Y'    --������
     AND  NVL( pla_out_ad.cancel_flag, 'N' )            <> 'Y'
     AND  pha_out_ad.po_header_id                       = pla_out_ad.po_header_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  pla_out_ad.item_id                            = ximv_out_ad.inventory_item_id
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) >= ximv_out_ad.start_date_active --�K�p�J�n��
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) <= ximv_out_ad.end_date_active   --�K�p�I����
     --�ړ����b�g�ڍ׎擾
     AND  xmld_out_ad.document_type_code                = '50'                    -- '����'
     AND  xmld_out_ad.record_type_code                  = '10'                    -- '�w��'
     AND  pla_out_ad.po_line_id                         = xmld_out_ad.mov_line_id
     --���b�g���擾
     AND  ximv_out_ad.item_id                           = ilm_out_ad.item_id
     AND  xmld_out_ad.lot_id                            = ilm_out_ad.lot_id
     --�ۊǏꏊ���̎擾
     AND  pla_out_ad.attribute12                        = xilv_out_ad.segment1
     --�d������̎擾
     AND  pha_out_ad.vendor_id                          = xvv_out_ad.vendor_id    -- �d������VIEW
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) >= xvv_out_ad.start_date_active --�K�p�J�n��
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) <= xvv_out_ad.end_date_active   --�K�p�I����
     --�������擾
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  pha_out_ad.attribute10                        = xlc_out_ad.location_code(+)
--     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) >= xlc_out_ad.start_date_active(+)
--     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) <= xlc_out_ad.end_date_active(+)
     AND  pha_out_ad.attribute10                        = xlc_out_ad.location_code
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) >= xlc_out_ad.start_date_active
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) <= xlc_out_ad.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �W�D�����݌ɏo�ɗ\��  END ] --
-- << �o�ɗ\�� END >>
UNION ALL
--����������������������������������������������������������������������
--�� �y���Ɏ��сz                                                     ��
--��    �P�D�����������                                              ��
--��    �Q�D�ړ����Ɏ���(�ϑ�����)                                    ��
--��    �R�D�ړ����Ɏ���(�ϑ��Ȃ�)                                    ��
--��    �S�D���Y���Ɏ���                                              ��
--��    �T�D���Y���Ɏ��� �i�ڐU�� �i��U��                            ��
--��    �U�D���Y���Ɏ��� ���                                         ��
--��    �V�D�q�֕ԕi ���Ɏ���                                         ��
--��    �W�D�݌ɒ��� ���Ɏ���(�����݌�)                             ��
--��    �X�D�݌ɒ��� ���Ɏ���(�O���o����)                             ��
--��  �P�O�D�݌ɒ��� ���Ɏ���(�l������)                               ��
--��  �P�P�D�݌ɒ��� ���Ɏ���(�d����ԕi)                             ��
--��  �P�Q�D�݌ɒ��� ���Ɏ���(��L�ȊO)                               ��
--����������������������������������������������������������������������
  -------------------------------------------------------------
  -- �P�D�����������
  -------------------------------------------------------------
  SELECT
          xrpm_in_po_e.new_div_invent                   AS reason_code            -- ���R�R�[�h
         ,xilv_in_po_e.whse_code                        AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_po_e.segment1                         AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_po_e.description                      AS location               -- �ۊǏꏊ��
         ,xilv_in_po_e.short_name                       AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_po_e.item_id                          AS item_id                -- �i��ID
         ,ximv_in_po_e.item_no                          AS item_no                -- �i�ڃR�[�h
         ,ximv_in_po_e.item_name                        AS item_name              -- �i�ږ�
         ,ximv_in_po_e.item_short_name                  AS item_short_name        -- �i�ڗ���
         ,ximv_in_po_e.num_of_cases                     AS case_content           -- �P�[�X����
         ,ximv_in_po_e.lot_ctl                          AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_po_e.lot_id                            AS lot_id                 -- ���b�gID
         ,ilm_in_po_e.lot_no                            AS lot_no                 -- ���b�gNo
         ,ilm_in_po_e.attribute1                        AS manufacture_date       -- �����N����
         ,ilm_in_po_e.attribute2                        AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_po_e.attribute3                        AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,pha_in_po_e.segment1                          AS voucher_no             -- �`�[�ԍ�
         ,pla_in_po_e.line_num                          AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,xrart_in_po_e.department_code                 AS loct_code              -- �����R�[�h
         ,xlc_in_po_e.location_name                     AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,xrart_in_po_e.txns_date                       AS leaving_date           -- ���o�ɓ�_����
         ,xrart_in_po_e.txns_date                       AS arrival_date           -- ���o�ɓ�_����
         ,xrart_in_po_e.txns_date                       AS standard_date          -- ����i�����j
         ,xvv_in_po_e.segment1                          AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xvv_in_po_e.vendor_name                       AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,xilv_in_po_e.segment1                         AS deliver_to_no          -- �z����R�[�h
         ,xilv_in_po_e.description                      AS deliver_to_name        -- �z���於
         ,xrart_in_po_e.quantity                        AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,xrart_in_po_e.quantity                        AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_po_e              -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_po_e              -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_po_e               -- OPM���b�g�}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_rcv_pay_mst                             xrpm_in_po_e              -- �󕥋敪�A�h�I���}�X�^
         ,po_headers_all                                pha_in_po_e               -- �����w�b�_
         ,po_lines_all                                  pla_in_po_e               -- ��������
         ,xxpo_rcv_and_rtn_txns                         xrart_in_po_e             -- ����ԕi����(�A�h�I��)
         ,xxskz_vendors2_v                              xvv_in_po_e               -- �d������VIEW(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_in_po_e               -- �������擾�p
   WHERE
     -- �󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_po_e.doc_type                         = 'PORC'
     AND  xrpm_in_po_e.source_document_code             = 'PO'
     AND  xrpm_in_po_e.use_div_invent                   = 'Y'
     AND  xrpm_in_po_e.transaction_type                 = 'DELIVER'
     -- �����w�b�_�̏���
     AND  pha_in_po_e.attribute1                        IN ( '25'                 -- �������
                                                           , '30'                 -- ���ʊm���
                                                           , '35' )               -- ���z�m���
     -- �������ׂƂ̌���
     AND  pla_in_po_e.attribute13                       = 'Y'                     -- ������
     AND  pla_in_po_e.cancel_flag                      <> 'Y'                     -- �L�����Z���ȊO
     AND  pha_in_po_e.po_header_id                      = pla_in_po_e.po_header_id
     -- ����ԕi����(�A�h�I��)�Ƃ̌���
     AND  xrart_in_po_e.txns_type                       = '1'                     -- ���
     AND  pha_in_po_e.segment1                          = xrart_in_po_e.source_document_number
     AND  pla_in_po_e.line_num                          = xrart_in_po_e.source_document_line_num
     -- �i�ڃ}�X�^�Ƃ̌���
     AND  xrart_in_po_e.item_id                         = ximv_in_po_e.item_id
     AND  xrart_in_po_e.txns_date                      >= ximv_in_po_e.start_date_active
     AND  xrart_in_po_e.txns_date                      <= ximv_in_po_e.end_date_active
     -- ���b�g���擾
     AND  ximv_in_po_e.item_id                          = ilm_in_po_e.item_id
     AND (   ( ximv_in_po_e.lot_ctl = 1  AND ilm_in_po_e.lot_id = xrart_in_po_e.lot_id )  -- ���b�g�Ǘ��i
          OR ( ximv_in_po_e.lot_ctl = 0  AND ilm_in_po_e.lot_id = 0 )                     -- �񃍃b�g�Ǘ��i
         )
     -- �ۊǏꏊ���擾
     AND  pha_in_po_e.attribute5                        = xilv_in_po_e.segment1
     -- �������擾
     AND  pha_in_po_e.vendor_id                         = xvv_in_po_e.vendor_id
     AND  xrart_in_po_e.txns_date                      >= xvv_in_po_e.start_date_active
     AND  xrart_in_po_e.txns_date                      <= xvv_in_po_e.end_date_active
     -- �������擾
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xrart_in_po_e.department_code                 = xlc_in_po_e.location_code(+)
--     AND  xrart_in_po_e.txns_date                      >= xlc_in_po_e.start_date_active(+)
--     AND  xrart_in_po_e.txns_date                      <= xlc_in_po_e.end_date_active(+)
     AND  xrart_in_po_e.department_code                 = xlc_in_po_e.location_code
     AND  xrart_in_po_e.txns_date                      >= xlc_in_po_e.start_date_active
     AND  xrart_in_po_e.txns_date                      <= xlc_in_po_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �P�D�����������  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �Q�D�ړ����Ɏ���(�ϑ�����)
  -------------------------------------------------------------
  SELECT
          xrpm_in_xf_e.new_div_invent                   AS reason_code            -- ���R�R�[�h
         ,xilv_in_xf_e.whse_code                        AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_xf_e.segment1                         AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_xf_e.description                      AS location               -- �ۊǏꏊ��
         ,xilv_in_xf_e.short_name                       AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_xf_e.item_id                          AS item_id                -- �i��ID
         ,ximv_in_xf_e.item_no                          AS item_no                -- �i�ڃR�[�h
         ,ximv_in_xf_e.item_name                        AS item_name              -- �i�ږ�
         ,ximv_in_xf_e.item_short_name                  AS item_short_name        -- �i�ڗ���
         ,ximv_in_xf_e.num_of_cases                     AS case_content           -- �P�[�X����
         ,ximv_in_xf_e.lot_ctl                          AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_xf_e.lot_id                            AS lot_id                 -- ���b�gID
         ,ilm_in_xf_e.lot_no                            AS lot_no                 -- ���b�gNo
         ,ilm_in_xf_e.attribute1                        AS manufacture_date       -- �����N����
         ,ilm_in_xf_e.attribute2                        AS uniqe_sign             -- �ŗL�L
         ,ilm_in_xf_e.attribute3                        AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xmrih_in_xf_e.mov_num                         AS voucher_no             -- �`�[�ԍ�
         ,xmril_in_xf_e.line_number                     AS line_no                -- �s�ԍ�
         ,xmrih_in_xf_e.delivery_no                     AS delivery_no            -- �z���ԍ�
         ,xmrih_in_xf_e.instruction_post_code           AS loct_code              -- �����R�[�h
         ,xlc_in_xf_e.location_name                     AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,xmrih_in_xf_e.actual_ship_date                AS leaving_date           -- ���o�ɓ�_����
         ,xmrih_in_xf_e.actual_arrival_date             AS arrival_date           -- ���o�ɓ�_����
         ,xmrih_in_xf_e.actual_arrival_date             AS standard_date          -- ����i�����j
         ,xilv_in_xf_e2.segment1                        AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xilv_in_xf_e2.description                     AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,xilv_in_xf_e2.segment1                        AS deliver_to_no          -- �z����R�[�h
         ,xilv_in_xf_e2.description                     AS deliver_to_name        -- �z���於
         ,xmld_in_xf_e.actual_quantity                  AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,xmld_in_xf_e.actual_quantity                  AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_in_xf_e              -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_xf_e              -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_xf_e               -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_xf_e              -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_in_xf_e             -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_req_instr_lines_arc                 xmril_in_xf_e             -- �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_in_xf_e              -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,xxskz_item_locations2_v                       xilv_in_xf_e2             -- OPM�ۊǏꏊ���VIEW2(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_in_xf_e               -- �������擾�p
   WHERE
     -- �󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_xf_e.doc_type                         = 'XFER'                  --  �ړ��ϑ�����
     AND  xrpm_in_xf_e.use_div_invent                   = 'Y'
     AND  xrpm_in_xf_e.rcv_pay_div                      = '1'
     -- �ړ��˗�/�w���w�b�_(�A�h�I��)�̏���
     AND  xmrih_in_xf_e.mov_type                        = '1'                     -- �ϑ�����
     AND  xmrih_in_xf_e.status                          IN ( '06', '05' )         -- 06:���o�ɕ񍐗L�A05:���ɕ񍐗L
     -- �ړ��˗�/�w������(�A�h�I��)�Ƃ̌���
     AND  xmril_in_xf_e.delete_flg                      = 'N'                     -- OFF
     AND  xmrih_in_xf_e.mov_hdr_id                      = xmril_in_xf_e.mov_hdr_id
     -- �ړ����b�g�ڍ�(�A�h�I��)�Ƃ̌���
     AND  xmld_in_xf_e.document_type_code               = '20'                    -- �ړ�
     AND  xmld_in_xf_e.record_type_code                 = '30'                    -- ���Ɏ���
     AND  xmril_in_xf_e.mov_line_id                     = xmld_in_xf_e.mov_line_id
     -- �i�ڃ}�X�^�Ƃ̌���
     AND  xmril_in_xf_e.item_id                         = ximv_in_xf_e.item_id
     AND  xmrih_in_xf_e.actual_arrival_date            >= ximv_in_xf_e.start_date_active
     AND  xmrih_in_xf_e.actual_arrival_date            <= ximv_in_xf_e.end_date_active
     -- ���b�g���擾
     AND  xmril_in_xf_e.item_id                         = ilm_in_xf_e.item_id
     AND  xmld_in_xf_e.lot_id                           = ilm_in_xf_e.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  xmrih_in_xf_e.ship_to_locat_id                = xilv_in_xf_e.inventory_location_id
     -- OPM�ۊǏꏊ���擾2
     AND  xmrih_in_xf_e.shipped_locat_id                = xilv_in_xf_e2.inventory_location_id
     -- �������擾
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xmrih_in_xf_e.instruction_post_code           = xlc_in_xf_e.location_code(+)
--     AND  xmrih_in_xf_e.actual_arrival_date            >= xlc_in_xf_e.start_date_active(+)
--     AND  xmrih_in_xf_e.actual_arrival_date            <= xlc_in_xf_e.end_date_active(+)
     AND  xmrih_in_xf_e.instruction_post_code           = xlc_in_xf_e.location_code
     AND  xmrih_in_xf_e.actual_arrival_date            >= xlc_in_xf_e.start_date_active
     AND  xmrih_in_xf_e.actual_arrival_date            <= xlc_in_xf_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �Q�D�ړ����Ɏ���(�ϑ�����)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �R�D�ړ����Ɏ���(�ϑ��Ȃ�)
  -------------------------------------------------------------
  SELECT
          xrpm_in_tr_e.new_div_invent                   AS reason_code            -- ���R�R�[�h
         ,xilv_in_tr_e.whse_code                        AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_tr_e.segment1                         AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_tr_e.description                      AS location               -- �ۊǏꏊ��
         ,xilv_in_tr_e.short_name                       AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_tr_e.item_id                          AS item_id                -- �i��ID
         ,ximv_in_tr_e.item_no                          AS item_no                -- �i�ڃR�[�h
         ,ximv_in_tr_e.item_name                        AS item_name              -- �i�ږ�
         ,ximv_in_tr_e.item_short_name                  AS item_short_name        -- �i�ڗ���
         ,ximv_in_tr_e.num_of_cases                     AS case_content           -- �P�[�X����
         ,ximv_in_tr_e.lot_ctl                          AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_tr_e.lot_id                            AS lot_id                 -- ���b�gID
         ,ilm_in_tr_e.lot_no                            AS lot_no                 -- ���b�gNo
         ,ilm_in_tr_e.attribute1                        AS manufacture_date       -- �����N����
         ,ilm_in_tr_e.attribute2                        AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_tr_e.attribute3                        AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xmrih_in_tr_e.mov_num                         AS voucher_no             -- �`�[�ԍ�
         ,xmril_in_tr_e.line_number                     AS line_no                -- �s�ԍ�
         ,xmrih_in_tr_e.delivery_no                     AS delivery_no            -- �z���ԍ�
         ,xmrih_in_tr_e.instruction_post_code           AS loct_code              -- �����R�[�h
         ,xlc_in_tr_e.location_name                     AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,xmrih_in_tr_e.actual_ship_date                AS leaving_date           -- ���o�ɓ�_����
         ,xmrih_in_tr_e.actual_arrival_date             AS arrival_date           -- ���o�ɓ�_����
         ,xmrih_in_tr_e.actual_arrival_date             AS standard_date          -- ����i�����j
         ,xilv_in_tr_e2.segment1                        AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xilv_in_tr_e2.description                     AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,xilv_in_tr_e2.segment1                        AS deliver_to_no          -- �z����R�[�h
         ,xilv_in_tr_e2.description                     AS deliver_to_name        -- �z���於
         ,xmld_in_tr_e.actual_quantity                  AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,xmld_in_tr_e.actual_quantity                  AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_in_tr_e              -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_tr_e              -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_tr_e               -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_tr_e              -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_in_tr_e             -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_req_instr_lines_arc                 xmril_in_tr_e             -- �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_in_tr_e              -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,xxskz_item_locations2_v                       xilv_in_tr_e2             -- OPM�ۊǏꏊ���VIEW2(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_in_tr_e               -- �������擾�p
   WHERE
     -- �󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_tr_e.doc_type                         = 'TRNI'                  -- �ړ��ϑ��Ȃ�
     AND  xrpm_in_tr_e.use_div_invent                   = 'Y'
     AND  xrpm_in_tr_e.rcv_pay_div                      = '1'
     -- �ړ��˗�/�w���w�b�_(�A�h�I��)�̏���
     AND  xmrih_in_tr_e.mov_type                        = '2'                     -- �ϑ��Ȃ�
     AND  xmrih_in_tr_e.status                          IN ( '06', '05' )         -- 06:���o�ɕ񍐗L�A05:���ɕ񍐗L
     -- �ړ��˗�/�w������(�A�h�I��)�Ƃ̌���
     AND  xmril_in_tr_e.delete_flg                      = 'N'                     -- OFF
     AND  xmrih_in_tr_e.mov_hdr_id                      = xmril_in_tr_e.mov_hdr_id
     -- �ړ����b�g�ڍ�(�A�h�I��)�Ƃ̌���
     AND  xmld_in_tr_e.document_type_code               = '20'                    -- �ړ�
     AND  xmld_in_tr_e.record_type_code                 = '30'                    -- ���Ɏ���
     AND  xmril_in_tr_e.mov_line_id                     = xmld_in_tr_e.mov_line_id
     -- �i�ڃ}�X�^�Ƃ̌���
     AND  xmril_in_tr_e.item_id                         = ximv_in_tr_e.item_id
     AND  xmrih_in_tr_e.actual_arrival_date            >= ximv_in_tr_e.start_date_active
     AND  xmrih_in_tr_e.actual_arrival_date            <= ximv_in_tr_e.end_date_active
     -- ���b�g���擾
     AND  xmril_in_tr_e.item_id                         = ilm_in_tr_e.item_id
     AND  xmld_in_tr_e.lot_id                           = ilm_in_tr_e.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  xmrih_in_tr_e.ship_to_locat_id                = xilv_in_tr_e.inventory_location_id
     -- OPM�ۊǏꏊ���擾2
     AND  xmrih_in_tr_e.shipped_locat_id                = xilv_in_tr_e2.inventory_location_id
     -- �������擾
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xmrih_in_tr_e.instruction_post_code           = xlc_in_tr_e.location_code(+)
--     AND  xmrih_in_tr_e.actual_arrival_date            >= xlc_in_tr_e.start_date_active(+)
--     AND  xmrih_in_tr_e.actual_arrival_date            <= xlc_in_tr_e.end_date_active(+)
     AND  xmrih_in_tr_e.instruction_post_code           = xlc_in_tr_e.location_code
     AND  xmrih_in_tr_e.actual_arrival_date            >= xlc_in_tr_e.start_date_active
     AND  xmrih_in_tr_e.actual_arrival_date            <= xlc_in_tr_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �R�D�ړ����Ɏ���(�ϑ��Ȃ�)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �S�D���Y���Ɏ���
  -------------------------------------------------------------
  SELECT
          xrpm_in_pr_e.new_div_invent                   AS reason_code            -- ���R�R�[�h
         ,xilv_in_pr_e.whse_code                        AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_pr_e.segment1                         AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_pr_e.description                      AS location               -- �ۊǏꏊ��
         ,xilv_in_pr_e.short_name                       AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_pr_e.item_id                          AS item_id                -- �i��ID
         ,ximv_in_pr_e.item_no                          AS item_no                -- �i�ڃR�[�h
         ,ximv_in_pr_e.item_name                        AS item_name              -- �i�ږ�
         ,ximv_in_pr_e.item_short_name                  AS item_short_name        -- �i�ڗ���
         ,ximv_in_pr_e.num_of_cases                     AS case_content           -- �P�[�X����
         ,ximv_in_pr_e.lot_ctl                          AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_pr_e.lot_id                            AS lot_id                 -- ���b�gID
         ,ilm_in_pr_e.lot_no                            AS lot_no                 -- ���b�gNo
         ,ilm_in_pr_e.attribute1                        AS manufacture_date       -- �����N����
         ,ilm_in_pr_e.attribute2                        AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_pr_e.attribute3                        AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,gbh_in_pr_e.batch_no                          AS voucher_no             -- �`�[�ԍ�
         ,gmd_in_pr_e.line_no                           AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,gbh_in_pr_e.attribute2                        AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,itp_in_pr_e.trans_date                        AS leaving_date           -- ���o�ɓ�_����
         ,itp_in_pr_e.trans_date                        AS arrival_date           -- ���o�ɓ�_����
         ,itp_in_pr_e.trans_date                        AS standard_date          -- ����i�����j
         ,grb_in_pr_e.routing_no                        AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,grt_in_pr_e.routing_desc                      AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,itp_in_pr_e.trans_qty                         AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,itp_in_pr_e.trans_qty                         AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_pr_e              -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_pr_e              -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_pr_e               -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_pr_e              -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_gme_batch_header_arc                    gbh_in_pr_e               -- ���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
         ,xxcmn_gme_material_details_arc                gmd_in_pr_e               -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v
         ,gmd_routings_b                                grb_in_pr_e               -- �H���}�X�^
         ,gmd_routings_tl                               grt_in_pr_e               -- �H���}�X�^���{��
         ,xxcmn_ic_tran_pnd_arc                         itp_in_pr_e               -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
   WHERE
     -- �󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_pr_e.doc_type                         = 'PROD'
     AND  xrpm_in_pr_e.use_div_invent                   = 'Y'
     -- �H���}�X�^�Ƃ̌����i���Y�f�[�^�擾�̏����j
     AND  grb_in_pr_e.routing_class                     NOT IN ( '61', '62', '70' )  -- �i�ڐU��(70)�A���(61,62) �ȊO
     AND  grb_in_pr_e.routing_id                        = gbh_in_pr_e.routing_id
     AND  xrpm_in_pr_e.routing_class                    = grb_in_pr_e.routing_class
     -- ���Y�����ڍׂƂ̌���
     AND  gmd_in_pr_e.line_type                         IN ( 1, 2 )               -- 1:�����i�A2:���Y��
     AND  gbh_in_pr_e.batch_id                          = gmd_in_pr_e.batch_id
     AND  xrpm_in_pr_e.line_type                        = gmd_in_pr_e.line_type
     AND (   ( ( gmd_in_pr_e.attribute5 IS NULL     ) AND ( xrpm_in_pr_e.hit_in_div IS NULL ) )
          OR ( ( gmd_in_pr_e.attribute5 IS NOT NULL ) AND ( xrpm_in_pr_e.hit_in_div = gmd_in_pr_e.attribute5 ) )
         )
     -- OPM�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
     AND  itp_in_pr_e.delete_mark                       = 0                       -- �L���`�F�b�N(OPM�ۗ��݌�)
     AND  itp_in_pr_e.completed_ind                     = 1                       -- ����(�ˎ���)
     AND  itp_in_pr_e.reverse_id                        IS NULL
     AND  itp_in_pr_e.doc_type                          = xrpm_in_pr_e.doc_type
     AND  itp_in_pr_e.line_id                           = gmd_in_pr_e.material_detail_id
     AND  itp_in_pr_e.item_id                           = ximv_in_pr_e.item_id
     -- �i�ڃ}�X�^�Ƃ̌���
     AND  itp_in_pr_e.item_id                           = ximv_in_pr_e.item_id
     AND  itp_in_pr_e.trans_date                       >= ximv_in_pr_e.start_date_active
     AND  itp_in_pr_e.trans_date                       <= ximv_in_pr_e.end_date_active
     -- ���b�g���擾
     AND  ximv_in_pr_e.item_id                          = ilm_in_pr_e.item_id
     AND  itp_in_pr_e.lot_id                            = ilm_in_pr_e.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  grb_in_pr_e.attribute9                        = xilv_in_pr_e.segment1
     -- �H���}�X�^���{��Ƃ̌���(�󕥐於�擾)
     AND  grt_in_pr_e.language                          = 'JA'
     AND  grb_in_pr_e.routing_id                        = grt_in_pr_e.routing_id
  -- [ �S�D���Y���Ɏ���  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �T�D���Y���Ɏ��� �i�ڐU�� �i��U��
  -- �y���z�ȉ���SQL�͕ύX����ŏ������x���x���Ȃ�܂�
  -------------------------------------------------------------
  SELECT
          xrpm_in_pr_e70.new_div_invent                 AS reason_code            -- ���R�R�[�h
         ,xilv_in_pr_e70.whse_code                      AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_pr_e70.segment1                       AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_pr_e70.description                    AS location               -- �ۊǏꏊ��
         ,xilv_in_pr_e70.short_name                     AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_pr_e70.item_id                        AS item_id                -- �i��ID
         ,ximv_in_pr_e70.item_no                        AS item_no                -- �i�ڃR�[�h
         ,ximv_in_pr_e70.item_name                      AS item_name              -- �i�ږ�
         ,ximv_in_pr_e70.item_short_name                AS item_short_name        -- �i�ڗ���
         ,ximv_in_pr_e70.num_of_cases                   AS case_content           -- �P�[�X����
         ,ximv_in_pr_e70.lot_ctl                        AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_pr_e70.lot_id                          AS lot_id                 -- ���b�gID
         ,ilm_in_pr_e70.lot_no                          AS lot_no                 -- ���b�gNo
         ,ilm_in_pr_e70.attribute1                      AS manufacture_date       -- �����N����
         ,ilm_in_pr_e70.attribute2                      AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_pr_e70.attribute3                      AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,gbh_in_pr_e70.batch_no                        AS voucher_no             -- �`�[�ԍ�
         ,gmd_in_pr_e70a.line_no                        AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,gbh_in_pr_e70.attribute2                      AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,itp_in_pr_e70.trans_date                      AS leaving_date           -- ���o�ɓ�_����
         ,itp_in_pr_e70.trans_date                      AS arrival_date           -- ���o�ɓ�_����
         ,itp_in_pr_e70.trans_date                      AS standard_date          -- ����i�����j
         ,grb_in_pr_e70.routing_no                      AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,grt_in_pr_e70.routing_desc                    AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,itp_in_pr_e70.trans_qty                       AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,itp_in_pr_e70.trans_qty                       AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_pr_e70            -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_pr_e70            -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_pr_e70             -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_pr_e70            -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_gme_batch_header_arc                    gbh_in_pr_e70             -- ���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
         ,xxcmn_gme_material_details_arc                gmd_in_pr_e70a            -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v(�U�֐�)
         ,xxcmn_gme_material_details_arc                gmd_in_pr_e70b            -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v(�U�֌�)
         ,gmd_routings_b                                grb_in_pr_e70             -- �H���}�X�^
         ,gmd_routings_tl                               grt_in_pr_e70             -- �H���}�X�^���{��
         ,xxcmn_ic_tran_pnd_arc                         itp_in_pr_e70             -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
         ,xxskz_item_class_v                            xicv_in_pr_e70b           -- OPM�i�ڃJ�e�S���������VIEW5(�U�֌�)
   WHERE
     -- �󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_pr_e70.doc_type                       = 'PROD'
     AND  xrpm_in_pr_e70.use_div_invent                 = 'Y'
     -- �H���}�X�^�Ƃ̌����i�i�ڐU�փf�[�^�擾�̏����j
     AND  grb_in_pr_e70.routing_class                   = '70'                    -- �i�ڐU��
     AND  gbh_in_pr_e70.routing_id                      = grb_in_pr_e70.routing_id
     AND  xrpm_in_pr_e70.routing_class                  = grb_in_pr_e70.routing_class
     -- ���Y�����ڍ�(�U�֐�)�Ƃ̌���
     AND  gmd_in_pr_e70a.line_type                      = 1                       -- �U�֐�
     AND  gbh_in_pr_e70.batch_id                        = gmd_in_pr_e70a.batch_id
     AND  xrpm_in_pr_e70.line_type                      = gmd_in_pr_e70a.line_type
     -- ���Y�����ڍ�(�U�֌�)�Ƃ̌���
     AND  gmd_in_pr_e70b.line_type                      = -1                      -- �U�֌�
     AND  gbh_in_pr_e70.batch_id                        = gmd_in_pr_e70b.batch_id
     AND  gmd_in_pr_e70a.batch_id                       = gmd_in_pr_e70b.batch_id -- ���������xUP�ɗL��
     -- OPM�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
     AND  itp_in_pr_e70.delete_mark                     = 0                       -- �L���`�F�b�N(OPM�ۗ��݌�)
     AND  itp_in_pr_e70.completed_ind                   = 1                       -- ����(�ˎ���)
     AND  itp_in_pr_e70.reverse_id                      IS NULL
     AND  itp_in_pr_e70.lot_id                         <> 0
     AND  itp_in_pr_e70.doc_type                        = xrpm_in_pr_e70.doc_type
     AND  itp_in_pr_e70.doc_id                          = gmd_in_pr_e70a.batch_id  -- ���������xUP�ɗL��
     AND  itp_in_pr_e70.doc_line                        = gmd_in_pr_e70a.line_no   -- ���������xUP�ɗL��
     AND  itp_in_pr_e70.line_type                       = gmd_in_pr_e70a.line_type -- ���������xUP�ɗL��
     AND  itp_in_pr_e70.line_id                         = gmd_in_pr_e70a.material_detail_id
     AND  itp_in_pr_e70.item_id                         = ximv_in_pr_e70.item_id
     -- OPM�i�ڏ��VIEW
     AND  gmd_in_pr_e70a.item_id                        = ximv_in_pr_e70.item_id
     AND  itp_in_pr_e70.trans_date                     >= ximv_in_pr_e70.start_date_active
     AND  itp_in_pr_e70.trans_date                     <= ximv_in_pr_e70.end_date_active
     -- OPM�i�ڃJ�e�S���������VIEW5(�U�֐�A�U�֌�)
     AND  gmd_in_pr_e70b.item_id                        = xicv_in_pr_e70b.item_id
     AND (    xrpm_in_pr_e70.item_div_ahead             = ximv_in_pr_e70.item_class_code   -- �U�֐�
          AND xrpm_in_pr_e70.item_div_origin            = xicv_in_pr_e70b.item_class_code  -- �U�֌�
          AND (   ( ximv_in_pr_e70.item_class_code    <> xicv_in_pr_e70b.item_class_code )
               OR ( ximv_in_pr_e70.item_class_code     = xicv_in_pr_e70b.item_class_code )
              )
         )
     -- OPM���b�g�}�X�^���擾
     AND  ximv_in_pr_e70.item_id                        = ilm_in_pr_e70.item_id
     AND  itp_in_pr_e70.lot_id                          = ilm_in_pr_e70.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  itp_in_pr_e70.whse_code                       = xilv_in_pr_e70.whse_code
     AND  itp_in_pr_e70.location                        = xilv_in_pr_e70.segment1
     -- �H���}�X�^���{��Ƃ̌���(�󕥐於�擾)
     AND  grt_in_pr_e70.language                        = 'JA'
     AND  grb_in_pr_e70.routing_id                      = grt_in_pr_e70.routing_id
  -- [ �T�D���Y���Ɏ��� �i�ڐU�� �i��U��  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �U�D���Y���Ɏ��� ���
  -------------------------------------------------------------
  SELECT
          xrpm_in_pr_e70.new_div_invent                 AS reason_code            -- ���R�R�[�h
         ,xilv_in_pr_e70.whse_code                      AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_pr_e70.segment1                       AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_pr_e70.description                    AS location               -- �ۊǏꏊ��
         ,xilv_in_pr_e70.short_name                     AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_pr_e70.item_id                        AS item_id                -- �i��ID
         ,ximv_in_pr_e70.item_no                        AS item_no                -- �i�ڃR�[�h
         ,ximv_in_pr_e70.item_name                      AS item_name              -- �i�ږ�
         ,ximv_in_pr_e70.item_short_name                AS item_short_name        -- �i�ڗ���
         ,ximv_in_pr_e70.num_of_cases                   AS case_content           -- �P�[�X����
         ,ximv_in_pr_e70.lot_ctl                        AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_pr_e70.lot_id                          AS lot_id                 -- ���b�gID
         ,ilm_in_pr_e70.lot_no                          AS lot_no                 -- ���b�gNo
         ,ilm_in_pr_e70.attribute1                      AS manufacture_date       -- �����N����
         ,ilm_in_pr_e70.attribute2                      AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_pr_e70.attribute3                      AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,gbh_in_pr_e70.batch_no                        AS voucher_no             -- �`�[�ԍ�
         ,gmd_in_pr_e70.line_no                         AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,gbh_in_pr_e70.attribute2                      AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,itp_in_pr_e70.trans_date                      AS leaving_date           -- ���o�ɓ�_����
         ,itp_in_pr_e70.trans_date                      AS arrival_date           -- ���o�ɓ�_����
         ,itp_in_pr_e70.trans_date                      AS standard_date          -- ����i�����j
         ,grb_in_pr_e70.routing_no                      AS ukebaraisaki_code      -- �󕥃R�[�h
         ,grt_in_pr_e70.routing_desc                    AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,itp_in_pr_e70.trans_qty                       AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,itp_in_pr_e70.trans_qty                       AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_pr_e70            -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_pr_e70            -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_pr_e70             -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_pr_e70            -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
--Mod 2013/3/19 V1.1 Start ��̃f�[�^���o�b�N�A�b�v�����܂ł͌��e�[�u���Q��
--         ,xxcmn_gme_batch_header_arc                    gbh_in_pr_e70             -- ���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
--         ,xxcmn_gme_material_details_arc                gmd_in_pr_e70             -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v
         ,gme_batch_header                              gbh_in_pr_e70             -- ���Y�o�b�`
         ,gme_material_details                          gmd_in_pr_e70             -- ���Y�����ڍ�
         ,gmd_routings_b                                grb_in_pr_e70             -- �H���}�X�^
         ,gmd_routings_tl                               grt_in_pr_e70             -- �H���}�X�^���{��
--         ,xxcmn_ic_tran_pnd_arc                         itp_in_pr_e70             -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
         ,ic_tran_pnd                                   itp_in_pr_e70             -- OPM�ۗ��݌Ƀg�����U�N�V����
--Mod 2013/3/19 V1.1 End
   WHERE
     -- �󕥋敪�A�h�I���}�X�^�̏���
          xrpm_in_pr_e70.doc_type                       = 'PROD'
     AND  xrpm_in_pr_e70.use_div_invent                 = 'Y'
     -- �H���}�X�^�Ƃ̌����i��̃f�[�^�擾�̏����j
     AND  grb_in_pr_e70.routing_class                   IN ( '61', '62' )         -- ���
     AND  gbh_in_pr_e70.routing_id                      = grb_in_pr_e70.routing_id
     AND  xrpm_in_pr_e70.routing_class                  = grb_in_pr_e70.routing_class
     -- ���Y�����ڍׂƂ̌���
     AND  gmd_in_pr_e70.line_type                       = 1                       -- �����i
     AND  gbh_in_pr_e70.batch_id                        = gmd_in_pr_e70.batch_id
     AND  xrpm_in_pr_e70.line_type                      = gmd_in_pr_e70.line_type
     -- OPM�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
     AND  itp_in_pr_e70.delete_mark                     = 0                       -- �L���`�F�b�N(OPM�ۗ��݌�)
     AND  itp_in_pr_e70.completed_ind                   = 1                       -- ����(�ˎ���)
     AND  itp_in_pr_e70.reverse_id                      IS NULL
     AND  itp_in_pr_e70.doc_type                        = xrpm_in_pr_e70.doc_type
     AND  itp_in_pr_e70.line_id                         = gmd_in_pr_e70.material_detail_id
     AND  itp_in_pr_e70.item_id                         = ximv_in_pr_e70.item_id
     -- �i�ڃ}�X�^�Ƃ̌���
     AND  gmd_in_pr_e70.item_id                         = ximv_in_pr_e70.item_id
     AND  itp_in_pr_e70.trans_date                      >= ximv_in_pr_e70.start_date_active
     AND  itp_in_pr_e70.trans_date                      <= ximv_in_pr_e70.end_date_active
     -- OPM���b�g�}�X�^���擾
     AND  ximv_in_pr_e70.item_id                        = ilm_in_pr_e70.item_id
     AND  itp_in_pr_e70.lot_id                          = ilm_in_pr_e70.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  itp_in_pr_e70.whse_code                       = xilv_in_pr_e70.whse_code
     AND  itp_in_pr_e70.location                        = xilv_in_pr_e70.segment1
     -- �H���}�X�^���{��Ƃ̌���(�󕥐於�擾)
     AND  grt_in_pr_e70.language                        = 'JA'
     AND  grb_in_pr_e70.routing_id                      = grt_in_pr_e70.routing_id
  -- [ �U�D���Y���Ɏ��� ���  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �V�D�q�֕ԕi ���Ɏ���
  -------------------------------------------------------------
  SELECT
          xrpm_in_po_e_rma.new_div_invent               AS reason_code            -- ���R�R�[�h
         ,xilv_in_po_e_rma.whse_code                    AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_po_e_rma.segment1                     AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_po_e_rma.description                  AS location               -- �ۊǏꏊ��
         ,xilv_in_po_e_rma.short_name                   AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_po_e_rma.item_id                      AS item_id                -- �i��ID
         ,ximv_in_po_e_rma.item_no                      AS item_no                -- �i�ڃR�[�h
         ,ximv_in_po_e_rma.item_name                    AS item_name              -- �i�ږ�
         ,ximv_in_po_e_rma.item_short_name              AS item_short_name        -- �i�ڗ���
         ,ximv_in_po_e_rma.num_of_cases                 AS case_content           -- �P�[�X����
         ,ximv_in_po_e_rma.lot_ctl                      AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_po_e_rma.lot_id                        AS lot_id                 -- ���b�gID
         ,ilm_in_po_e_rma.lot_no                        AS lot_no                 -- ���b�gNo
         ,ilm_in_po_e_rma.attribute1                    AS manufacture_date       -- �����N����
         ,ilm_in_po_e_rma.attribute2                    AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_po_e_rma.attribute3                    AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xoha_in_po_e_rma.request_no                   AS voucher_no             -- �`�[�ԍ�
         ,xola_in_po_e_rma.order_line_number            AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,xoha_in_po_e_rma.performance_management_dept  AS loct_code              -- �����R�[�h
         ,xlc_in_po_e_rma.location_name                 AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,xoha_in_po_e_rma.shipped_date                 AS leaving_date           -- ���o�ɓ�_����
         ,xoha_in_po_e_rma.arrival_date                 AS arrival_date           -- ���o�ɓ�_����
         ,xoha_in_po_e_rma.arrival_date                 AS standard_date          -- ����i�����j
         ,xoha_in_po_e_rma.customer_code                AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xcst_in_po_e_rma.party_name                   AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,xpas_in_po_e_rma.party_site_number            AS deliver_to_no          -- �z����R�[�h
         ,xpas_in_po_e_rma.party_site_name              AS deliver_to_name        -- �z���於
         ,CASE WHEN otta_in_po_e_rma.order_category_code = 'ORDER' THEN xmld_in_po_e_rma.actual_quantity * -1
               ELSE                                                     xmld_in_po_e_rma.actual_quantity
          END                                           AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,CASE WHEN otta_in_po_e_rma.order_category_code = 'ORDER' THEN xmld_in_po_e_rma.actual_quantity * -1
               ELSE                                                     xmld_in_po_e_rma.actual_quantity
          END                                           AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_in_po_e_rma          -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_po_e_rma          -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_po_e_rma           -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_in_po_e_rma          -- �󕥋敪�A�h�I���}�X�^ <---- �����܂ŋ���
         ,xxcmn_order_headers_all_arc                   xoha_in_po_e_rma          -- �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_order_lines_all_arc                     xola_in_po_e_rma          -- �󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_in_po_e_rma          -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,oe_transaction_types_all                      otta_in_po_e_rma          -- �󒍃^�C�v
         ,xxskz_cust_accounts2_v                        xcst_in_po_e_rma          -- �󕥐�
         ,xxskz_party_sites2_v                          xpas_in_po_e_rma          -- SKYLINK�p����VIEW �z������VIEW2
         ,xxskz_locations2_v                            xlc_in_po_e_rma           -- �������擾�p
   WHERE
     -- �󕥋敪�A�h�I���}�X�^�̏���
         (   (     xrpm_in_po_e_rma.doc_type              = 'OMSO'
              AND  otta_in_po_e_rma.order_category_code   = 'ORDER')
          OR (     xrpm_in_po_e_rma.doc_type              = 'PORC'
              AND  xrpm_in_po_e_rma.source_document_code  = 'RMA'
              AND  otta_in_po_e_rma.order_category_code   = 'RETURN'
             )
         )
     AND  xrpm_in_po_e_rma.use_div_invent               = 'Y'
     AND  xrpm_in_po_e_rma.rcv_pay_div                  = '1'                     -- ���
     -- �󒍃^�C�v�Ƃ̌���
     AND  otta_in_po_e_rma.attribute1                   = '3'                     -- �q�֕ԕi
     AND  otta_in_po_e_rma.attribute1                   = xrpm_in_po_e_rma.shipment_provision_div
     AND  otta_in_po_e_rma.attribute11                  IN ( '03', '04' )
     AND  otta_in_po_e_rma.attribute11                  = xrpm_in_po_e_rma.ship_prov_rcv_pay_category
                                                                                  -- ���󕥋敪�A�h�I���𕡐��ǂ܂Ȃ���
     -- �󒍃w�b�_(�A�h�I��)�Ƃ̌���
     AND  xoha_in_po_e_rma.req_status                   = '04'                    -- �o�׎��ьv���
     AND  xoha_in_po_e_rma.latest_external_flag         = 'Y'                     -- ON
     AND  otta_in_po_e_rma.transaction_type_id          = xoha_in_po_e_rma.order_type_id
     -- �󒍖���(�A�h�I��)�Ƃ̌���
     AND  xola_in_po_e_rma.delete_flag                  = 'N'                     -- OFF
     AND  xoha_in_po_e_rma.order_header_id              = xola_in_po_e_rma.order_header_id
     -- �ړ����b�g�ڍ�(�A�h�I��)�Ƃ̌���
     AND  xmld_in_po_e_rma.document_type_code           = '10'                    -- �o�׈˗�
     AND  xmld_in_po_e_rma.record_type_code             = '20'                    -- �o�Ɏ���
     AND  xola_in_po_e_rma.order_line_id                = xmld_in_po_e_rma.mov_line_id
     -- OPM�i�ڏ��VIEW�擾
     AND  xola_in_po_e_rma.shipping_inventory_item_id   = ximv_in_po_e_rma.inventory_item_id
     AND  xoha_in_po_e_rma.arrival_date                >= ximv_in_po_e_rma.start_date_active
     AND  xoha_in_po_e_rma.arrival_date                <= ximv_in_po_e_rma.end_date_active
     -- OPM���b�g�}�X�^�擾
     AND  ilm_in_po_e_rma.item_id                       = ximv_in_po_e_rma.item_id
     AND  ilm_in_po_e_rma.lot_id                        = xmld_in_po_e_rma.lot_id
     -- OPM�ۊǏꏊ���VIEW�擾
     AND  xoha_in_po_e_rma.deliver_from_id              = xilv_in_po_e_rma.inventory_location_id
     -- �󕥐���擾
     AND  xoha_in_po_e_rma.customer_id                  = xcst_in_po_e_rma.party_id
     AND  xoha_in_po_e_rma.arrival_date                >= xcst_in_po_e_rma.start_date_active --�K�p�J�n��
     AND  xoha_in_po_e_rma.arrival_date                <= xcst_in_po_e_rma.end_date_active   --�K�p�I����
     -- �z����擾
     AND  xoha_in_po_e_rma.result_deliver_to_id         = xpas_in_po_e_rma.party_site_id
     AND  xoha_in_po_e_rma.arrival_date                >= xpas_in_po_e_rma.start_date_active
     AND  xoha_in_po_e_rma.arrival_date                <= xpas_in_po_e_rma.end_date_active
     -- �������擾
     AND  xoha_in_po_e_rma.performance_management_dept  = xlc_in_po_e_rma.location_code(+)
     AND  xoha_in_po_e_rma.arrival_date                >= xlc_in_po_e_rma.start_date_active(+)
     AND  xoha_in_po_e_rma.arrival_date                <= xlc_in_po_e_rma.end_date_active(+)
  -- [ �V�D�q�֕ԕi ���Ɏ���  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �W�D�݌ɒ��� ���Ɏ���(�����݌�)
  --  ��OPM�����݌Ƀg�����U�N�V�����Ńf�[�^��������ׁA�W�v���s��
  -------------------------------------------------------------
  SELECT
          sitc_in_ad_e_x97.reason_code                  AS reason_code            -- ���R�R�[�h
         ,xilv_in_ad_e_x97.whse_code                    AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_ad_e_x97.segment1                     AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_ad_e_x97.description                  AS location               -- �ۊǏꏊ��
         ,xilv_in_ad_e_x97.short_name                   AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_ad_e_x97.item_id                      AS item_id                -- �i��ID
         ,ximv_in_ad_e_x97.item_no                      AS item_no                -- �i�ڃR�[�h
         ,ximv_in_ad_e_x97.item_name                    AS item_name              -- �i�ږ�
         ,ximv_in_ad_e_x97.item_short_name              AS item_short_name        -- �i�ڗ���
         ,ximv_in_ad_e_x97.num_of_cases                 AS case_content           -- �P�[�X����
         ,ximv_in_ad_e_x97.lot_ctl                      AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_ad_e_x97.lot_id                        AS lot_id                 -- ���b�gID
         ,ilm_in_ad_e_x97.lot_no                        AS lot_no                 -- ���b�gNo
         ,ilm_in_ad_e_x97.attribute1                    AS manufacture_date       -- �����N����
         ,ilm_in_ad_e_x97.attribute2                    AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_ad_e_x97.attribute3                    AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,sitc_in_ad_e_x97.journal_no                   AS voucher_no             -- �`�[�ԍ�
         ,NULL                                          AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,NULL                                          AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,sitc_in_ad_e_x97.tran_date                    AS leaving_date           -- ���o�ɓ�_����
         ,sitc_in_ad_e_x97.tran_date                    AS arrival_date           -- ���o�ɓ�_����
         ,sitc_in_ad_e_x97.tran_date                    AS standard_date          -- ����i�����j
         ,sitc_in_ad_e_x97.reason_code                  AS ukebaraisaki_code      -- �󕥐�R�[�h�i���R�R�[�h�j
         ,flv_in_ad_e_x97.meaning                       AS ukebaraisaki_name      -- �󕥐於�i���R�R�[�h���j
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,sitc_in_ad_e_x97.quantity                     AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,sitc_in_ad_e_x97.quantity                     AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_ad_e_x97          -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_ad_e_x97          -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_ad_e_x97           -- OPM���b�g�}�X�^ -- <---- �����܂ŋ���
         ,(  -- �Ώۃf�[�^���W�v
             SELECT
                     xrpm_in_ad_e_x97.new_div_invent    reason_code               -- ���R�R�[�h
                    ,ijm_in_ad_e_x97.journal_no         journal_no                -- �W���[�i��No
                    ,itc_in_ad_e_x97.location           loct_code                 -- �ۊǏꏊ�R�[�h
                    ,itc_in_ad_e_x97.trans_date         tran_date                 -- �����
                    ,itc_in_ad_e_x97.item_id            item_id                   -- �i��ID
                    ,itc_in_ad_e_x97.lot_id             lot_id                    -- ���b�gID
                    ,SUM( itc_in_ad_e_x97.trans_qty )   quantity                  -- ���o�ɐ��i�W�v�l�j
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_in_ad_e_x97          -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_ic_tran_cmp_arc              itc_in_ad_e_x97           -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                    ,ic_jrnl_mst                        ijm_in_ad_e_x97           -- OPM�W���[�i���}�X�^
                    ,ic_adjs_jnl                        iaj_in_ad_e_x97           -- OPM�݌ɒ����W���[�i��
              WHERE
                -- �󕥋敪�A�h�I���}�X�^�̏���
                     xrpm_in_ad_e_x97.doc_type          = 'ADJI'
                AND  xrpm_in_ad_e_x97.reason_code       = 'X977'                  -- �����݌�
                AND  xrpm_in_ad_e_x97.rcv_pay_div       = '1'                     -- ���
                AND  xrpm_in_ad_e_x97.use_div_invent    = 'Y'
                -- OPM�����݌Ƀg�����U�N�V�����Ƃ̌���
                AND  itc_in_ad_e_x97.doc_type           = xrpm_in_ad_e_x97.doc_type
                AND  itc_in_ad_e_x97.reason_code        = xrpm_in_ad_e_x97.reason_code
                AND  SIGN( itc_in_ad_e_x97.trans_qty )  = xrpm_in_ad_e_x97.rcv_pay_div
                -- OPM�݌ɒ����W���[�i���Ƃ̌���
                AND  itc_in_ad_e_x97.doc_type           = iaj_in_ad_e_x97.trans_type
                AND  itc_in_ad_e_x97.doc_id             = iaj_in_ad_e_x97.doc_id   -- OPM�݌ɒ����W���[�i�����o����
                AND  itc_in_ad_e_x97.doc_line           = iaj_in_ad_e_x97.doc_line -- OPM�݌ɒ����W���[�i�����o����
                -- OPM�W���[�i���}�X�^�Ƃ̌���
                AND  ijm_in_ad_e_x97.attribute1         IS NULL                      -- OPM�W���[�i���}�X�^.����ID��NULL
                AND  iaj_in_ad_e_x97.journal_id         = ijm_in_ad_e_x97.journal_id -- OPM�W���[�i���}�X�^���o����
             GROUP BY
                     xrpm_in_ad_e_x97.new_div_invent                              -- ���R�R�[�h
                    ,ijm_in_ad_e_x97.journal_no                                   -- �W���[�i��No
                    ,itc_in_ad_e_x97.location                                     -- �ۊǏꏊ�R�[�h
                    ,itc_in_ad_e_x97.trans_date                                   -- �����
                    ,itc_in_ad_e_x97.item_id                                      -- �i��ID
                    ,itc_in_ad_e_x97.lot_id                                       -- ���b�gID
          )                                             sitc_in_ad_e_x97
         ,fnd_lookup_values                             flv_in_ad_e_x97           -- �N�C�b�N�R�[�h(�󕥐於�擾�p)
   WHERE
     -- OPM�i�ڏ��VIEW�擾
          sitc_in_ad_e_x97.item_id                      = ximv_in_ad_e_x97.item_id
     AND  sitc_in_ad_e_x97.tran_date                   >= ximv_in_ad_e_x97.start_date_active
     AND  sitc_in_ad_e_x97.tran_date                   <= ximv_in_ad_e_x97.end_date_active
     -- OPM���b�g�}�X�^�擾
     AND  sitc_in_ad_e_x97.item_id                      = ilm_in_ad_e_x97.item_id
     AND  sitc_in_ad_e_x97.lot_id                       = ilm_in_ad_e_x97.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  sitc_in_ad_e_x97.loct_code                    = xilv_in_ad_e_x97.segment1
     -- �N�C�b�N�R�[�h(�󕥐於�擾)
     AND  flv_in_ad_e_x97.lookup_type                   = 'XXCMN_NEW_DIVISION'
     AND  flv_in_ad_e_x97.language                      = 'JA'
     AND  flv_in_ad_e_x97.lookup_code                   = sitc_in_ad_e_x97.reason_code
  -- [ �W�D�݌ɒ��� ���Ɏ���(�����݌�)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �X�D�݌ɒ��� ���Ɏ���(�O���o����)
  --  ��OPM�����݌Ƀg�����U�N�V�����Ńf�[�^��������ׁA�W�v���s��
  -------------------------------------------------------------
  SELECT
          sitc_in_ad_e_x97.reason_code                  AS reason_code            -- ���R�R�[�h
         ,xilv_in_ad_e_x97.whse_code                    AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_ad_e_x97.segment1                     AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_ad_e_x97.description                  AS location               -- �ۊǏꏊ��
         ,xilv_in_ad_e_x97.short_name                   AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_ad_e_x97.item_id                      AS item_id                -- �i��ID
         ,ximv_in_ad_e_x97.item_no                      AS item_no                -- �i�ڃR�[�h
         ,ximv_in_ad_e_x97.item_name                    AS item_name              -- �i�ږ�
         ,ximv_in_ad_e_x97.item_short_name              AS item_short_name        -- �i�ڗ���
         ,ximv_in_ad_e_x97.num_of_cases                 AS case_content           -- �P�[�X����
         ,ximv_in_ad_e_x97.lot_ctl                      AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_ad_e_x97.lot_id                        AS lot_id                 -- ���b�gID
         ,ilm_in_ad_e_x97.lot_no                        AS lot_no                 -- ���b�gNo
         ,ilm_in_ad_e_x97.attribute1                    AS manufacture_date       -- �����N����
         ,ilm_in_ad_e_x97.attribute2                    AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_ad_e_x97.attribute3                    AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,sitc_in_ad_e_x97.journal_no                   AS voucher_no             -- �`�[�ԍ�
         ,NULL                                          AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,NULL                                          AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,sitc_in_ad_e_x97.tran_date                    AS leaving_date           -- ���o�ɓ�_����
         ,sitc_in_ad_e_x97.tran_date                    AS arrival_date           -- ���o�ɓ�_����
         ,sitc_in_ad_e_x97.tran_date                    AS standard_date          -- ����i�����j
         ,xvv_in_ad_e_x97.segment1                      AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xvv_in_ad_e_x97.vendor_name                   AS ukebaraisaki_name      -- �󕥐�
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,sitc_in_ad_e_x97.quantity                     AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,sitc_in_ad_e_x97.quantity                     AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_ad_e_x97          -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_ad_e_x97          -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_ad_e_x97           -- OPM���b�g�}�X�^ <---- �����܂ŋ���
         ,(  -- �Ώۃf�[�^���W�v
             SELECT
                     xrpm_in_ad_e_x97.new_div_invent    reason_code               -- ���R�R�[
                    ,ijm_in_ad_e_x97.journal_no         journal_no                -- �W���[�i��No
                    ,itc_in_ad_e_x97.location           loct_code                 -- �ۊǏꏊ�R�[�h
                    ,xvst_in_ad_e_x97.vendor_id         vendor_id                 -- �����ID
                    ,itc_in_ad_e_x97.trans_date         tran_date                 -- �����
                    ,itc_in_ad_e_x97.item_id            item_id                   -- �i��ID
                    ,itc_in_ad_e_x97.lot_id             lot_id                    -- ���b�gID
                    ,SUM( itc_in_ad_e_x97.trans_qty )   quantity                  -- ���o�ɐ��i�W�v�l�j
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_in_ad_e_x97          -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_ic_tran_cmp_arc              itc_in_ad_e_x97           -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                    ,ic_jrnl_mst                        ijm_in_ad_e_x97           -- OPM�W���[�i���}�X�^
                    ,ic_adjs_jnl                        iaj_in_ad_e_x97           -- OPM�݌ɒ����W���[�i��
                    ,xxpo_vendor_supply_txns            xvst_in_ad_e_x97          -- �O���o��������
              WHERE
                -- �󕥋敪�A�h�I���}�X�^�̏���
                     xrpm_in_ad_e_x97.doc_type          = 'ADJI'
                AND  xrpm_in_ad_e_x97.reason_code       = 'X977'                  -- �����݌�
                AND  xrpm_in_ad_e_x97.rcv_pay_div       = '1'                     -- ���
                AND  xrpm_in_ad_e_x97.use_div_invent    = 'Y'
                -- OPM�����݌Ƀg�����U�N�V�����Ƃ̌���
                AND  itc_in_ad_e_x97.doc_type           = xrpm_in_ad_e_x97.doc_type
                AND  itc_in_ad_e_x97.reason_code        = xrpm_in_ad_e_x97.reason_code
                -- OPM�݌ɒ����W���[�i���Ƃ̌���
                AND  itc_in_ad_e_x97.doc_type           = iaj_in_ad_e_x97.trans_type
                AND  itc_in_ad_e_x97.doc_id             = iaj_in_ad_e_x97.doc_id   -- OPM�݌ɒ����W���[�i�����o����
                AND  itc_in_ad_e_x97.doc_line           = iaj_in_ad_e_x97.doc_line -- OPM�݌ɒ����W���[�i�����o����
                -- OPM�W���[�i���}�X�^�Ƃ̌���
                AND  ijm_in_ad_e_x97.attribute1         IS NOT NULL                  -- OPM�W���[�i���}�X�^.����ID��NULL�łȂ�
                AND  iaj_in_ad_e_x97.journal_id         = ijm_in_ad_e_x97.journal_id -- OPM�W���[�i���}�X�^���o����
                -- �O���o�������тƂ̌���
                AND  TO_NUMBER(ijm_in_ad_e_x97.attribute1) = xvst_in_ad_e_x97.txns_id -- ����ID
             GROUP BY
                     xrpm_in_ad_e_x97.new_div_invent                              -- ���R�R�[�h
                    ,ijm_in_ad_e_x97.journal_no                                   -- �W���[�i��No
                    ,itc_in_ad_e_x97.location                                     -- �ۊǏꏊ�R�[�h
                    ,xvst_in_ad_e_x97.vendor_id                                   -- �����ID
                    ,itc_in_ad_e_x97.trans_date                                   -- �����
                    ,itc_in_ad_e_x97.item_id                                      -- �i��ID
                    ,itc_in_ad_e_x97.lot_id                                       -- ���b�gID
          )                                             sitc_in_ad_e_x97
         ,xxskz_vendors2_v                              xvv_in_ad_e_x97           -- �d������(�󕥐於�擾�p)
   WHERE
     -- OPM�i�ڏ��VIEW�擾
          sitc_in_ad_e_x97.item_id                      = ximv_in_ad_e_x97.item_id
     AND  sitc_in_ad_e_x97.tran_date                   >= ximv_in_ad_e_x97.start_date_active
     AND  sitc_in_ad_e_x97.tran_date                   <= ximv_in_ad_e_x97.end_date_active
     -- OPM���b�g�}�X�^�擾
     AND  sitc_in_ad_e_x97.item_id                      = ilm_in_ad_e_x97.item_id
     AND  sitc_in_ad_e_x97.lot_id                       = ilm_in_ad_e_x97.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  sitc_in_ad_e_x97.loct_code                    = xilv_in_ad_e_x97.segment1
     -- �󕥐�擾
     AND  sitc_in_ad_e_x97.vendor_id                    = xvv_in_ad_e_x97.vendor_id
     AND  sitc_in_ad_e_x97.tran_date                   >= xvv_in_ad_e_x97.start_date_active
     AND  sitc_in_ad_e_x97.tran_date                   <= xvv_in_ad_e_x97.end_date_active
  -- [ �X�D�݌ɒ��� ���Ɏ���(�O���o����)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �P�O�D�݌ɒ��� ���Ɏ���(�l������)
  --  ��OPM�����݌Ƀg�����U�N�V�����Ńf�[�^��������ׁA�W�v���s��
  -------------------------------------------------------------
  SELECT
          sitc_in_ad_e_x9.reason_code                   AS reason_code            -- ���R�R�[�h
         ,xilv_in_ad_e_x9.whse_code                     AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_ad_e_x9.segment1                      AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_ad_e_x9.description                   AS location               -- �ۊǏꏊ��
         ,xilv_in_ad_e_x9.short_name                    AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_ad_e_x9.item_id                       AS item_id                -- �i��ID
         ,ximv_in_ad_e_x9.item_no                       AS item_no                -- �i�ڃR�[�h
         ,ximv_in_ad_e_x9.item_name                     AS item_name              -- �i�ږ�
         ,ximv_in_ad_e_x9.item_short_name               AS item_short_name        -- �i�ڗ���
         ,ximv_in_ad_e_x9.num_of_cases                  AS case_content           -- �P�[�X����
         ,ximv_in_ad_e_x9.lot_ctl                       AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_ad_e_x9.lot_id                         AS lot_id                 -- ���b�gID
         ,ilm_in_ad_e_x9.lot_no                         AS lot_no                 -- ���b�gNo
         ,ilm_in_ad_e_x9.attribute1                     AS manufacture_date       -- �����N����
         ,ilm_in_ad_e_x9.attribute2                     AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_ad_e_x9.attribute3                     AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,sitc_in_ad_e_x9.entry_num                     AS voucher_no             -- �`�[�ԍ�
         ,NULL                                          AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,sitc_in_ad_e_x9.dept_code                     AS loct_code              -- �����R�[�h
         ,xlc_in_ad_e_x9.location_name                  AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,sitc_in_ad_e_x9.tran_date                     AS leaving_date           -- ���o�ɓ�_����
         ,sitc_in_ad_e_x9.tran_date                     AS arrival_date           -- ���o�ɓ�_����
         ,sitc_in_ad_e_x9.tran_date                     AS standard_date          -- ����i�����j
         ,sitc_in_ad_e_x9.reason_code                   AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,flv_in_ad_e_x9.meaning                        AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,sitc_in_ad_e_x9.quantity                      AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,sitc_in_ad_e_x9.quantity                      AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_ad_e_x9           -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_ad_e_x9           -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_ad_e_x9            -- OPM���b�g�}�X�^ <---- �����܂ŋ���
         ,(  -- �Ώۃf�[�^���W�v
             SELECT
                     xrpm_in_ad_e_x9.new_div_invent     reason_code               -- ���R�R�[�h
                    ,xnpt_in_ad_e_x9.entry_number       entry_num                 -- �`�[�ԍ�
                    ,itc_in_ad_e_x9.location            loct_code                 -- �ۊǏꏊ�R�[�h
                    ,xnpt_in_ad_e_x9.department_code    dept_code                 -- �����R�[�h
                    ,itc_in_ad_e_x9.trans_date          tran_date                 -- �����
                    ,itc_in_ad_e_x9.item_id             item_id                   -- �i��ID
                    ,itc_in_ad_e_x9.lot_id              lot_id                    -- ���b�gID
                    ,SUM( itc_in_ad_e_x9.trans_qty )    quantity                  -- ���o�ɐ��i�W�v�l�j
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_in_ad_e_x9           -- �󕥋敪�A�h�I���}�X�^
                    ,ic_adjs_jnl                        iaj_in_ad_e_x9            -- OPM�݌ɒ����W���[�i��
                    ,ic_jrnl_mst                        ijm_in_ad_e_x9            -- OPM�W���[�i���}�X�^
                    ,xxcmn_ic_tran_cmp_arc              itc_in_ad_e_x9            -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                    ,xxpo_namaha_prod_txns              xnpt_in_ad_e_x9           -- ���t���сi�A�h�I���j
              WHERE
                -- �󕥋敪�A�h�I���}�X�^�̏���
                     xrpm_in_ad_e_x9.doc_type           = 'ADJI'
                AND  xrpm_in_ad_e_x9.reason_code        = 'X988'                  -- �l������
                AND  xrpm_in_ad_e_x9.rcv_pay_div        = '1'                     -- ���
                AND  xrpm_in_ad_e_x9.use_div_invent     = 'Y'
                -- OPM�����݌Ƀg�����U�N�V�����Ƃ̌���
                AND  itc_in_ad_e_x9.doc_type            = xrpm_in_ad_e_x9.doc_type
                AND  itc_in_ad_e_x9.reason_code         = xrpm_in_ad_e_x9.reason_code
                -- OPM�݌ɒ����W���[�i���Ƃ̌���
                AND  itc_in_ad_e_x9.doc_type            = iaj_in_ad_e_x9.trans_type
                AND  itc_in_ad_e_x9.doc_id              = iaj_in_ad_e_x9.doc_id
                AND  itc_in_ad_e_x9.doc_line            = iaj_in_ad_e_x9.doc_line
                -- OPM�W���[�i���}�X�^�Ƃ̌���
                AND  ijm_in_ad_e_x9.attribute1          IS NOT NULL
                AND  iaj_in_ad_e_x9.journal_id          = ijm_in_ad_e_x9.journal_id
                -- ���t���сi�A�h�I���j�Ƃ̌���
                AND  ijm_in_ad_e_x9.attribute1          = xnpt_in_ad_e_x9.entry_number
             GROUP BY
                     xrpm_in_ad_e_x9.new_div_invent                               -- ���R�R�[�h
                    ,xnpt_in_ad_e_x9.entry_number                                 -- �`�[�ԍ�
                    ,itc_in_ad_e_x9.location                                      -- �ۊǏꏊ�R�[�h
                    ,xnpt_in_ad_e_x9.department_code                              -- �����R�[�h
                    ,itc_in_ad_e_x9.trans_date                                    -- �����
                    ,itc_in_ad_e_x9.item_id                                       -- �i��ID
                    ,itc_in_ad_e_x9.lot_id                                        -- ���b�gID
          )                                             sitc_in_ad_e_x9
         ,fnd_lookup_values                             flv_in_ad_e_x9            -- �N�C�b�N�R�[�h(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_in_ad_e_x9            -- �������擾�p
   WHERE
     -- OPM�i�ڏ��擾
          sitc_in_ad_e_x9.item_id                       = ximv_in_ad_e_x9.item_id
     AND  sitc_in_ad_e_x9.tran_date                    >= ximv_in_ad_e_x9.start_date_active
     AND  sitc_in_ad_e_x9.tran_date                    <= ximv_in_ad_e_x9.end_date_active
     -- OPM���b�g�}�X�^�擾
     AND  sitc_in_ad_e_x9.item_id                       = ilm_in_ad_e_x9.item_id
     AND  sitc_in_ad_e_x9.lot_id                        = ilm_in_ad_e_x9.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  sitc_in_ad_e_x9.loct_code                     = xilv_in_ad_e_x9.segment1
     -- �N�C�b�N�R�[�h(�󕥐於�擾)
     AND  flv_in_ad_e_x9.lookup_type                    = 'XXCMN_NEW_DIVISION'
     AND  flv_in_ad_e_x9.language                       = 'JA'
     AND  flv_in_ad_e_x9.lookup_code                    = sitc_in_ad_e_x9.reason_code
     -- �����R�[�h�擾(SYSDATE�Ō���)
     AND  sitc_in_ad_e_x9.dept_code                     = xlc_in_ad_e_x9.location_code(+)
     AND  sitc_in_ad_e_x9.tran_date                    >= xlc_in_ad_e_x9.start_date_active(+)
     AND  sitc_in_ad_e_x9.tran_date                    <= xlc_in_ad_e_x9.end_date_active(+)
  -- [ �P�O�D�݌ɒ��� ���Ɏ���(�l������)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �P�P�D�݌ɒ��� ���Ɏ���(�d����ԕi)
  --  ��OPM�����݌Ƀg�����U�N�V�����Ńf�[�^��������ׁA�W�v���s��
  -------------------------------------------------------------
  SELECT
          srart_in_ad_e_x2.reason_code                  AS reason_code            -- ���R�R�[�h
         ,xilv_in_ad_e_x2.whse_code                     AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_ad_e_x2.segment1                      AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_ad_e_x2.description                   AS location               -- �ۊǏꏊ��
         ,xilv_in_ad_e_x2.short_name                    AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_ad_e_x2.item_id                       AS item_id                -- �i��ID
         ,ximv_in_ad_e_x2.item_no                       AS item_no                -- �i�ڃR�[�h
         ,ximv_in_ad_e_x2.item_name                     AS item_name              -- �i�ږ�
         ,ximv_in_ad_e_x2.item_short_name               AS item_short_name        -- �i�ڗ���
         ,ximv_in_ad_e_x2.num_of_cases                  AS case_content           -- �P�[�X����
         ,ximv_in_ad_e_x2.lot_ctl                       AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_ad_e_x2.lot_id                         AS lot_id                 -- ���b�gID
         ,ilm_in_ad_e_x2.lot_no                         AS lot_no                 -- ���b�gNo
         ,ilm_in_ad_e_x2.attribute1                     AS manufacture_date       -- �����N����
         ,ilm_in_ad_e_x2.attribute2                     AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_ad_e_x2.attribute3                     AS expiration_date        -- �ܖ����� -- <-- �����܂ŋ���
         ,srart_in_ad_e_x2.rcv_rtn_num                  AS voucher_no             -- �`�[�ԍ�
         ,srart_in_ad_e_x2.line_no                      AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,srart_in_ad_e_x2.dept_code                    AS loct_code              -- �����R�[�h
         ,xlc_in_ad_e_x2.location_name                  AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,srart_in_ad_e_x2.tran_date                    AS leaving_date           -- ���o�ɓ�_����
         ,srart_in_ad_e_x2.tran_date                    AS arrival_date           -- ���o�ɓ�_����
         ,srart_in_ad_e_x2.tran_date                    AS standard_date          -- ����i�����j
         ,xvv_in_ad_e_x2.segment1                       AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xvv_in_ad_e_x2.vendor_name                    AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,xilv_in_ad_e_x2.segment1                      AS deliver_to_no          -- �z����R�[�h
         ,xilv_in_ad_e_x2.description                   AS deliver_to_name        -- �z���於
         ,srart_in_ad_e_x2.quantity                     AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,srart_in_ad_e_x2.quantity                     AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_ad_e_x2           -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_ad_e_x2           -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_ad_e_x2            -- OPM���b�g�}�X�^ -- <---- �����܂ŋ���
         ,(  -- �Ώۃf�[�^���W�v
             SELECT
                     xrpm_in_ad_e_x2.new_div_invent       reason_code             -- ���R�R�[�h
                    ,xrart_in_ad_e_x2.rcv_rtn_number      rcv_rtn_num             -- ����ԕi�ԍ�
                    ,xrart_in_ad_e_x2.rcv_rtn_line_number line_no                 -- �s�ԍ�
                    ,itc_in_ad_e_x2.location              loct_code               -- �ۊǏꏊ�R�[�h
                    ,xrart_in_ad_e_x2.department_code     dept_code               -- �����R�[�h
                    ,xrart_in_ad_e_x2.vendor_id           vendor_id               -- �����ID
                    ,itc_in_ad_e_x2.trans_date            tran_date               -- �����
                    ,itc_in_ad_e_x2.item_id               item_id                 -- �i��ID
                    ,itc_in_ad_e_x2.lot_id                lot_id                  -- ���b�gID
                    ,SUM( itc_in_ad_e_x2.trans_qty )      quantity                -- ���o�ɐ��i�W�v�l�j
               FROM
                     xxcmn_rcv_pay_mst                    xrpm_in_ad_e_x2         -- �󕥋敪�A�h�I���}�X�^
                    ,ic_adjs_jnl                          iaj_in_ad_e_x2          -- OPM�݌ɒ����W���[�i��
                    ,ic_jrnl_mst                          ijm_in_ad_e_x2          -- OPM�W���[�i���}�X�^
                    ,xxcmn_ic_tran_cmp_arc                itc_in_ad_e_x2          -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                    ,xxpo_rcv_and_rtn_txns                xrart_in_ad_e_x2        -- ����ԕi���сi�A�h�I���j
              WHERE
                --�󕥋敪�A�h�I���}�X�^�̏���
                     xrpm_in_ad_e_x2.doc_type           = 'ADJI'
                AND  xrpm_in_ad_e_x2.reason_code        = 'X201'                  -- �d���ԕi�o��
                AND  xrpm_in_ad_e_x2.rcv_pay_div        = '1'                     -- ���
                AND  xrpm_in_ad_e_x2.use_div_invent     = 'Y'
                --�����݌Ƀg�����U�N�V�����̏���
                AND  itc_in_ad_e_x2.doc_type            = xrpm_in_ad_e_x2.doc_type
                AND  itc_in_ad_e_x2.reason_code         = xrpm_in_ad_e_x2.reason_code
                --�݌ɒ����W���[�i���̎擾
                AND  itc_in_ad_e_x2.doc_type            = iaj_in_ad_e_x2.trans_type
                AND  itc_in_ad_e_x2.doc_id              = iaj_in_ad_e_x2.doc_id
                AND  itc_in_ad_e_x2.doc_line            = iaj_in_ad_e_x2.doc_line
                --�W���[�i���}�X�^�̎擾
                AND  ijm_in_ad_e_x2.attribute1          IS NOT NULL
                AND  iaj_in_ad_e_x2.journal_id          = ijm_in_ad_e_x2.journal_id
                --����ԕi���т̎擾
                AND  TO_NUMBER( ijm_in_ad_e_x2.attribute1 ) = xrart_in_ad_e_x2.txns_id
             GROUP BY
                     xrpm_in_ad_e_x2.new_div_invent
                    ,xrart_in_ad_e_x2.rcv_rtn_number, xrart_in_ad_e_x2.rcv_rtn_line_number
                    ,itc_in_ad_e_x2.location, xrart_in_ad_e_x2.department_code
                    ,xrart_in_ad_e_x2.vendor_id, itc_in_ad_e_x2.trans_date
                    ,itc_in_ad_e_x2.item_id, itc_in_ad_e_x2.lot_id
          )                                             srart_in_ad_e_x2
         ,xxskz_vendors_v                               xvv_in_ad_e_x2            -- �d������VIEW
         ,xxskz_locations2_v                            xlc_in_ad_e_x2            -- �������擾�p
   WHERE
     --�i�ڃ}�X�^�Ƃ̌���
          srart_in_ad_e_x2.item_id                      = ximv_in_ad_e_x2.item_id
     AND  srart_in_ad_e_x2.tran_date                   >= ximv_in_ad_e_x2.start_date_active --�K�p�J�n��
     AND  srart_in_ad_e_x2.tran_date                   <= ximv_in_ad_e_x2.end_date_active   --�K�p�I����
     --���b�g���擾
     AND  srart_in_ad_e_x2.item_id                      = ilm_in_ad_e_x2.item_id
     AND  srart_in_ad_e_x2.lot_id                       = ilm_in_ad_e_x2.lot_id
     --�ۊǏꏊ���擾
     AND  srart_in_ad_e_x2.loct_code                    = xilv_in_ad_e_x2.segment1
     --�󕥐�(�d������)�擾
     AND  srart_in_ad_e_x2.vendor_id                    = xvv_in_ad_e_x2.vendor_id
     AND  srart_in_ad_e_x2.tran_date                   >= xvv_in_ad_e_x2.start_date_active --�K�p�J�n��
     AND  srart_in_ad_e_x2.tran_date                   <= xvv_in_ad_e_x2.end_date_active   --�K�p�I����
     --�������擾
     AND  srart_in_ad_e_x2.dept_code                    = xlc_in_ad_e_x2.location_code
     AND  srart_in_ad_e_x2.tran_date                   >= xlc_in_ad_e_x2.start_date_active
     AND  srart_in_ad_e_x2.tran_date                   <= xlc_in_ad_e_x2.end_date_active
  -- [ �P�P�D�݌ɒ��� ���Ɏ���(�d����ԕi)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �P�Q�D�݌ɒ��� ���Ɏ���(��L�ȊO)
  --  ��OPM�����݌Ƀg�����U�N�V�����Ńf�[�^��������ׁA�W�v���s��
  -------------------------------------------------------------
  SELECT
          sitc_in_ad_e_xx.reason_code                   AS reason_code            -- ���R�R�[�h
         ,xilv_in_ad_e_xx.whse_code                     AS whse_code              -- �q�ɃR�[�h
         ,xilv_in_ad_e_xx.segment1                      AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_in_ad_e_xx.description                   AS location               -- �ۊǏꏊ��
         ,xilv_in_ad_e_xx.short_name                    AS location_s_name        -- �ۊǏꏊ����
         ,ximv_in_ad_e_xx.item_id                       AS item_id                -- �i��ID
         ,ximv_in_ad_e_xx.item_no                       AS item_no                -- �i�ڃR�[�h
         ,ximv_in_ad_e_xx.item_name                     AS item_name              -- �i�ږ�
         ,ximv_in_ad_e_xx.item_short_name               AS item_short_name        -- �i�ڗ���
         ,ximv_in_ad_e_xx.num_of_cases                  AS case_content           -- �P�[�X����
         ,ximv_in_ad_e_xx.lot_ctl                       AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_in_ad_e_xx.lot_id                         AS lot_id                 -- ���b�gID
         ,ilm_in_ad_e_xx.lot_no                         AS lot_no                 -- ���b�gNo
         ,ilm_in_ad_e_xx.attribute1                     AS manufacture_date       -- �����N����
         ,ilm_in_ad_e_xx.attribute2                     AS uniqe_sign             -- �ŗL�L��
         ,ilm_in_ad_e_xx.attribute3                     AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,sitc_in_ad_e_xx.journal_no                    AS voucher_no             -- �`�[�ԍ�
         ,NULL                                          AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,NULL                                          AS loct_name              -- ������
         ,'1'                                           AS in_out_kbn             -- ���o�ɋ敪�i1:���Ɂj
         ,sitc_in_ad_e_xx.tran_date                     AS leaving_date           -- ���o�ɓ�_����
         ,sitc_in_ad_e_xx.tran_date                     AS arrival_date           -- ���o�ɓ�_����
         ,sitc_in_ad_e_xx.tran_date                     AS standard_date          -- ����i�����j
         ,sitc_in_ad_e_xx.reason_code                   AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,flv_in_ad_e_xx.meaning                        AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,sitc_in_ad_e_xx.quantity                      AS stock_quantity         -- ���ɐ�
         ,0                                             AS leaving_quantity       -- �o�ɐ�
         ,sitc_in_ad_e_xx.quantity                      AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_in_ad_e_xx           -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_in_ad_e_xx           -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_in_ad_e_xx            -- OPM���b�g�}�X�^ <---- �����܂ŋ���
         ,(  -- �Ώۃf�[�^���W�v
             SELECT
                     xrpm_in_ad_e_xx.new_div_invent     reason_code               -- ���R�R�[�h
                    ,ijm_in_ad_e_xx.journal_no          journal_no                -- �W���[�i��No
                    ,itc_in_ad_e_xx.location            loct_code                 -- �ۊǏꏊ�R�[�h
                    ,itc_in_ad_e_xx.trans_date          tran_date                 -- �����
                    ,itc_in_ad_e_xx.item_id             item_id                   -- �i��ID
                    ,itc_in_ad_e_xx.lot_id              lot_id                    -- ���b�gID
                    ,SUM( itc_in_ad_e_xx.trans_qty )    quantity                  -- ���o�ɐ��i�W�v�l�j
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_in_ad_e_xx           -- �󕥋敪�A�h�I���}�X�^
                    ,ic_adjs_jnl                        iaj_in_ad_e_xx            -- OPM�݌ɒ����W���[�i��
                    ,ic_jrnl_mst                        ijm_in_ad_e_xx            -- OPM�W���[�i���}�X�^
                    ,xxcmn_ic_tran_cmp_arc              itc_in_ad_e_xx            -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
              WHERE
                -- �󕥋敪�A�h�I���}�X�^�̏���
                     xrpm_in_ad_e_xx.doc_type           = 'ADJI'
                AND  xrpm_in_ad_e_xx.reason_code        <> 'X977'                 -- �����݌�
                AND  xrpm_in_ad_e_xx.reason_code        <> 'X988'                 -- �l������
                AND  xrpm_in_ad_e_xx.reason_code        <> 'X123'                 -- �ړ����ђ����i�o�Ɂj
                AND  xrpm_in_ad_e_xx.reason_code        <> 'X201'                 -- �d����ԕi
                AND  xrpm_in_ad_e_xx.rcv_pay_div        = '1'                     -- ���
                AND  xrpm_in_ad_e_xx.use_div_invent     = 'Y'
                -- OPM�����݌Ƀg�����U�N�V�����Ƃ̌���
                AND  itc_in_ad_e_xx.doc_type            = xrpm_in_ad_e_xx.doc_type
                AND  itc_in_ad_e_xx.reason_code         = xrpm_in_ad_e_xx.reason_code
                -- OPM�݌ɒ����W���[�i���Ƃ̌���
                AND  itc_in_ad_e_xx.doc_type            = iaj_in_ad_e_xx.trans_type
                AND  itc_in_ad_e_xx.doc_id              = iaj_in_ad_e_xx.doc_id
                AND  itc_in_ad_e_xx.doc_line            = iaj_in_ad_e_xx.doc_line
                -- OPM�W���[�i���}�X�^�Ƃ̌���
                AND  iaj_in_ad_e_xx.journal_id          = ijm_in_ad_e_xx.journal_id
             GROUP BY
                     xrpm_in_ad_e_xx.new_div_invent                               -- ���R�R�[�h
                    ,ijm_in_ad_e_xx.journal_no                                    -- �W���[�i��No
                    ,itc_in_ad_e_xx.location                                      -- �ۊǏꏊ�R�[�h
                    ,itc_in_ad_e_xx.trans_date                                    -- �����
                    ,itc_in_ad_e_xx.item_id                                       -- �i��ID
                    ,itc_in_ad_e_xx.lot_id                                        -- ���b�gID
          )                                             sitc_in_ad_e_xx
         ,fnd_lookup_values                             flv_in_ad_e_xx            -- �N�C�b�N�R�[�h(�󕥐於�擾�p)
   WHERE
     -- OPM�i�ڏ��擾
          sitc_in_ad_e_xx.item_id                       = ximv_in_ad_e_xx.item_id
     AND  sitc_in_ad_e_xx.tran_date                    >= ximv_in_ad_e_xx.start_date_active
     AND  sitc_in_ad_e_xx.tran_date                    <= ximv_in_ad_e_xx.end_date_active
     -- OPM���b�g�}�X�^�擾
     AND  sitc_in_ad_e_xx.item_id                       = ilm_in_ad_e_xx.item_id
     AND  sitc_in_ad_e_xx.lot_id                        = ilm_in_ad_e_xx.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  sitc_in_ad_e_xx.loct_code                     = xilv_in_ad_e_xx.segment1
     -- �N�C�b�N�R�[�h(�󕥐於�擾)
     AND  flv_in_ad_e_xx.lookup_type                    = 'XXCMN_NEW_DIVISION'
     AND  flv_in_ad_e_xx.language                       = 'JA'
     AND  flv_in_ad_e_xx.lookup_code                    = sitc_in_ad_e_xx.reason_code
  -- [ �P�Q�D�݌ɒ��� ���Ɏ���(��L�ȊO)  END ] --
-- << ���Ɏ��� END >>
UNION ALL
--����������������������������������������������������������������������
--�� �y�o�Ɏ��сz                                                     ��
--��    �P�D�ړ��o�Ɏ���(�ϑ�����)                                    ��
--��    �Q�D�ړ��o�Ɏ���(�ϑ��Ȃ�)                                    ��
--��    �R�D���Y�o�Ɏ���                                              ��
--��    �S�D���Y�o�Ɏ��� �i�ڐU�� �i��U��                            ��
--��    �T�D���Y�o�Ɏ��� ���                                         ��
--��    �U�D�󒍏o�׎���                                              ��
--��    �V�D�L���o�׎���                                              ��
--��    �W�D�݌ɒ��� �o�Ɏ���(�o�� ���{�o�� �p�p�o��)                 ��
--��    �X�D�݌ɒ��� �o�Ɏ���(�����݌�)                             ��
--��  �P�O�D�����݌ɏo�Ɏ���                                        ��
--��  �P�P�D�݌ɒ��� �o�Ɏ���(��L�ȊO)                               ��
--����������������������������������������������������������������������
  -------------------------------------------------------------
  -- �P�D�ړ��o�Ɏ���(�ϑ�����)
  -------------------------------------------------------------
  SELECT
          xrpm_out_xf_e.new_div_invent                  AS reason_code            -- ���R�R�[�h
         ,xilv_out_xf_e.whse_code                       AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_xf_e.segment1                        AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_xf_e.description                     AS location               -- �ۊǏꏊ��
         ,xilv_out_xf_e.short_name                      AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_xf_e.item_id                         AS item_id                -- �i��ID
         ,ximv_out_xf_e.item_no                         AS item_no                -- �i�ڃR�[�h
         ,ximv_out_xf_e.item_name                       AS item_name              -- �i�ږ�
         ,ximv_out_xf_e.item_short_name                 AS item_short_name        -- �i�ڗ���
         ,ximv_out_xf_e.num_of_cases                    AS case_content           -- �P�[�X����
         ,ximv_out_xf_e.lot_ctl                         AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_xf_e.lot_id                           AS lot_id                 -- ���b�gID
         ,ilm_out_xf_e.lot_no                           AS lot_no                 -- ���b�gNo
         ,ilm_out_xf_e.attribute1                       AS manufacture_date       -- �����N����
         ,ilm_out_xf_e.attribute2                       AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_xf_e.attribute3                       AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xmrih_out_xf_e.mov_num                        AS voucher_no             -- �`�[�ԍ�
         ,xmril_out_xf_e.line_number                    AS line_no                -- �s�ԍ�
         ,xmrih_out_xf_e.delivery_no                    AS delivery_no            -- �z���ԍ�
         ,xmrih_out_xf_e.instruction_post_code          AS loct_code              -- �����R�[�h
         ,xlc_out_xf_e.location_name                    AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,xmrih_out_xf_e.actual_ship_date               AS leaving_date           -- ���o�ɓ�_����
         ,xmrih_out_xf_e.actual_arrival_date            AS arrival_date           -- ���o�ɓ�_����
         ,xmrih_out_xf_e.actual_ship_date               AS standard_date          -- ����i�����j
         ,xilv_out_xf_e2.segment1                       AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xilv_out_xf_e2.description                    AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,xilv_out_xf_e2.segment1                       AS deliver_to_no          -- �z����R�[�h
         ,xilv_out_xf_e2.description                    AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,xmld_out_xf_e.actual_quantity                 AS leaving_quantity       -- �o�ɐ�
         ,xmld_out_xf_e.actual_quantity                 AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_out_xf_e             -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_xf_e             -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_xf_e              -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_xf_e             -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_out_xf_e            -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_req_instr_lines_arc                 xmril_out_xf_e            -- �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_out_xf_e             -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,xxskz_item_locations2_v                       xilv_out_xf_e2            -- OPM�ۊǏꏊ���VIEW2(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_out_xf_e              -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_xf_e.doc_type                        = 'XFER'                  -- �ړ��ϑ�����
     AND  xrpm_out_xf_e.use_div_invent                  = 'Y'
     AND  xrpm_out_xf_e.rcv_pay_div                     = '-1'
     --�ړ��˗�/�w���w�b�_�̏���
     AND  xmrih_out_xf_e.mov_type                       = '1'                     -- �ϑ�����
     AND  xmrih_out_xf_e.status                         IN ( '06', '04' )         -- 06:���o�ɕ񍐗L�A04:�o�ɕ񍐗L
     --�ړ��˗�/�w�����ׂƂ̌���
     AND  xmril_out_xf_e.delete_flg                     = 'N'                     -- OFF
     AND  xmrih_out_xf_e.mov_hdr_id                     = xmril_out_xf_e.mov_hdr_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  xmril_out_xf_e.item_id                        = ximv_out_xf_e.item_id
     AND  xmrih_out_xf_e.actual_ship_date              >= ximv_out_xf_e.start_date_active --�K�p�J�n��
     AND  xmrih_out_xf_e.actual_ship_date              <= ximv_out_xf_e.end_date_active   --�K�p�I����
     --�ړ����b�g�ڍ׎擾
     AND  xmld_out_xf_e.document_type_code              = '20'                    -- �ړ�
     AND  xmld_out_xf_e.record_type_code                = '20'                    -- �o�Ɏ���
     AND  xmril_out_xf_e.mov_line_id                    = xmld_out_xf_e.mov_line_id
     --���b�g���擾
     AND  xmril_out_xf_e.item_id                        = ilm_out_xf_e.item_id
     AND  xmld_out_xf_e.lot_id                          = ilm_out_xf_e.lot_id
     --�ۊǏꏊ���擾
     AND  xmrih_out_xf_e.shipped_locat_id               = xilv_out_xf_e.inventory_location_id
     --�󕥐���擾
     AND  xmrih_out_xf_e.ship_to_locat_id               = xilv_out_xf_e2.inventory_location_id
     --�������擾
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xmrih_out_xf_e.instruction_post_code          = xlc_out_xf_e.location_code(+)
--     AND  xmrih_out_xf_e.actual_ship_date              >= xlc_out_xf_e.start_date_active(+)
--     AND  xmrih_out_xf_e.actual_ship_date              <= xlc_out_xf_e.end_date_active(+)
     AND  xmrih_out_xf_e.instruction_post_code          = xlc_out_xf_e.location_code
     AND  xmrih_out_xf_e.actual_ship_date              >= xlc_out_xf_e.start_date_active
     AND  xmrih_out_xf_e.actual_ship_date              <= xlc_out_xf_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �P�D�ړ��o�Ɏ���(�ϑ�����)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �Q�D�ړ��o�Ɏ���(�ϑ��Ȃ�)
  -------------------------------------------------------------
  SELECT
          xrpm_out_tr_e.new_div_invent                  AS reason_code            -- ���R�R�[�h
         ,xilv_out_tr_e.whse_code                       AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_tr_e.segment1                        AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_tr_e.description                     AS location               -- �ۊǏꏊ��
         ,xilv_out_tr_e.short_name                      AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_tr_e.item_id                         AS item_id                -- �i��ID
         ,ximv_out_tr_e.item_no                         AS item_no                -- �i�ڃR�[�h
         ,ximv_out_tr_e.item_name                       AS item_name              -- �i�ږ�
         ,ximv_out_tr_e.item_short_name                 AS item_short_name        -- �i�ڗ���
         ,ximv_out_tr_e.num_of_cases                    AS case_content           -- �P�[�X����
         ,ximv_out_tr_e.lot_ctl                         AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_tr_e.lot_id                           AS lot_id                 -- ���b�gID
         ,ilm_out_tr_e.lot_no                           AS lot_no                 -- ���b�gNo
         ,ilm_out_tr_e.attribute1                       AS manufacture_date       -- �����N����
         ,ilm_out_tr_e.attribute2                       AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_tr_e.attribute3                       AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xmrih_out_tr_e.mov_num                        AS voucher_no             -- �`�[�ԍ�
         ,xmril_out_tr_e.line_number                    AS line_no                -- �s�ԍ�
         ,xmrih_out_tr_e.delivery_no                    AS delivery_no            -- �z���ԍ�
         ,xmrih_out_tr_e.instruction_post_code          AS loct_code              -- �����R�[�h
         ,xlc_out_tr_e.location_name                    AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,xmrih_out_tr_e.actual_ship_date               AS leaving_date           -- ���o�ɓ�_����
         ,xmrih_out_tr_e.actual_arrival_date            AS arrival_date           -- ���o�ɓ�_����
         ,xmrih_out_tr_e.actual_ship_date               AS standard_date          -- ����i�����j
         ,xilv_out_tr_e2.segment1                       AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xilv_out_tr_e2.description                    AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,xilv_out_tr_e2.segment1                       AS deliver_to_no          -- �z����R�[�h
         ,xilv_out_tr_e2.description                    AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,xmld_out_tr_e.actual_quantity                 AS leaving_quantity       -- �o�ɐ�
         ,xmld_out_tr_e.actual_quantity                 AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_out_tr_e             -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_tr_e             -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_tr_e              -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_tr_e             -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_out_tr_e            -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_req_instr_lines_arc                 xmril_out_tr_e            -- �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_out_tr_e             -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,xxskz_item_locations2_v                       xilv_out_tr_e2            -- OPM�ۊǏꏊ���VIEW2(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_out_tr_e              -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_tr_e.doc_type                        = 'TRNI'                  -- �ړ��ϑ��Ȃ�
     AND  xrpm_out_tr_e.use_div_invent                  = 'Y'
     AND  xrpm_out_tr_e.rcv_pay_div                     = '-1'
     --�ړ��˗�/�w���w�b�_�̏���
     AND  xmrih_out_tr_e.mov_type                       = '2'                     -- �ϑ��Ȃ�
     AND  xmrih_out_tr_e.status                         IN ( '06', '04' )         -- 06:���o�ɕ񍐗L�A04:�o�ɕ񍐗L
     --�ړ��˗�/�w�����ׂƂ̌���
     AND  xmril_out_tr_e.delete_flg                     = 'N'                     -- OFF
     AND  xmrih_out_tr_e.mov_hdr_id                     = xmril_out_tr_e.mov_hdr_id
     --�ړ����b�g�ڍ׎擾
     AND  xmld_out_tr_e.document_type_code              = '20'                    -- �ړ�
     AND  xmld_out_tr_e.record_type_code                = '20'                    -- �o�Ɏ���
     AND  xmld_out_tr_e.mov_line_id                     = xmril_out_tr_e.mov_line_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  xmril_out_tr_e.item_id                        = ximv_out_tr_e.item_id
     AND  xmrih_out_tr_e.actual_ship_date              >= ximv_out_tr_e.start_date_active --�K�p�J�n��
     AND  xmrih_out_tr_e.actual_ship_date              <= ximv_out_tr_e.end_date_active   --�K�p�I����
     --���b�g���擾
     AND  xmril_out_tr_e.item_id                        = ilm_out_tr_e.item_id
     AND  xmld_out_tr_e.lot_id                          = ilm_out_tr_e.lot_id
     --�ۊǏꏊ���擾
     AND  xmrih_out_tr_e.shipped_locat_id               = xilv_out_tr_e.inventory_location_id
     --�󕥐���擾
     AND  xmrih_out_tr_e.ship_to_locat_id               = xilv_out_tr_e2.inventory_location_id
     --�������擾
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xmrih_out_tr_e.instruction_post_code          = xlc_out_tr_e.location_code(+)
--     AND  xmrih_out_tr_e.actual_ship_date              >= xlc_out_tr_e.start_date_active(+)
--     AND  xmrih_out_tr_e.actual_ship_date              <= xlc_out_tr_e.end_date_active(+)
     AND  xmrih_out_tr_e.instruction_post_code          = xlc_out_tr_e.location_code
     AND  xmrih_out_tr_e.actual_ship_date              >= xlc_out_tr_e.start_date_active
     AND  xmrih_out_tr_e.actual_ship_date              <= xlc_out_tr_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �Q�D�ړ��o�Ɏ���(�ϑ��Ȃ�)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �R�D���Y�o�Ɏ���
  -------------------------------------------------------------
  SELECT
          xrpm_out_pr_e.new_div_invent                  AS reason_code            -- ���R�R�[�h
         ,xilv_out_pr_e.whse_code                       AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_pr_e.segment1                        AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_pr_e.description                     AS location               -- �ۊǏꏊ��
         ,xilv_out_pr_e.short_name                      AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_pr_e.item_id                         AS item_id                -- �i��ID
         ,ximv_out_pr_e.item_no                         AS item_no                -- �i�ڃR�[�h
         ,ximv_out_pr_e.item_name                       AS item_name              -- �i�ږ�
         ,ximv_out_pr_e.item_short_name                 AS item_short_name        -- �i�ڗ���
         ,ximv_out_pr_e.num_of_cases                    AS case_content           -- �P�[�X����
         ,ximv_out_pr_e.lot_ctl                         AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_pr_e.lot_id                           AS lot_id                 -- ���b�gID
         ,ilm_out_pr_e.lot_no                           AS lot_no                 -- ���b�gNo
         ,ilm_out_pr_e.attribute1                       AS manufacture_date       -- �����N����
         ,ilm_out_pr_e.attribute2                       AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_pr_e.attribute3                       AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,gbh_out_pr_e.batch_no                         AS voucher_no             -- �`�[�ԍ�
         ,gmd_out_pr_e.line_no                          AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,gbh_out_pr_e.attribute2                       AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,itp_out_pr_e.trans_date                       AS leaving_date           -- ���o�ɓ�_����
         ,itp_out_pr_e.trans_date                       AS arrival_date           -- ���o�ɓ�_����
         ,itp_out_pr_e.trans_date                       AS standard_date          -- ����i�����j
         ,grb_out_pr_e.routing_no                       AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,grt_out_pr_e.routing_desc                     AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,itp_out_pr_e.trans_qty * -1                   AS leaving_quantity       -- �o�ɐ�
         ,itp_out_pr_e.trans_qty * -1                   AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_out_pr_e             -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_pr_e             -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_pr_e              -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_pr_e             -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_gme_batch_header_arc                    gbh_out_pr_e              -- ���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
         ,xxcmn_gme_material_details_arc                gmd_out_pr_e              -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v
         ,gmd_routings_b                                grb_out_pr_e              -- �H���}�X�^
         ,gmd_routings_tl                               grt_out_pr_e              -- �H���}�X�^���{��
         ,xxcmn_ic_tran_pnd_arc                         itp_out_pr_e              -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_pr_e.doc_type                        = 'PROD'
     AND  xrpm_out_pr_e.use_div_invent                  = 'Y'
     -- �H���}�X�^�Ƃ̌����i���Y�f�[�^�擾�̏����j
     AND  grb_out_pr_e.routing_class                    NOT IN ( '61', '62', '70' )  -- �i�ڐU��(70)�A���(61,62) �ȊO
     AND  gbh_out_pr_e.routing_id                       = grb_out_pr_e.routing_id
     AND  xrpm_out_pr_e.routing_class                   = grb_out_pr_e.routing_class
     --���Y�����ڍׂ̌���
     AND  gmd_out_pr_e.line_type                        = -1                      -- �����i
     AND  gbh_out_pr_e.batch_id                         = gmd_out_pr_e.batch_id
     AND  gmd_out_pr_e.line_type                        = xrpm_out_pr_e.line_type
     AND (   ( ( gmd_out_pr_e.attribute5 IS NULL     ) AND ( xrpm_out_pr_e.hit_in_div IS NULL ) )
          OR ( ( gmd_out_pr_e.attribute5 IS NOT NULL ) AND ( xrpm_out_pr_e.hit_in_div = gmd_out_pr_e.attribute5 ) )
         )
     --�ۗ��݌Ƀg�����U�N�V�����̎擾
     AND  itp_out_pr_e.delete_mark                      = 0                       -- �L���`�F�b�N(OPM�ۗ��݌�)
     AND  itp_out_pr_e.completed_ind                    = 1                       -- ����(�ˎ���)
     AND  itp_out_pr_e.reverse_id                       IS NULL
     AND  itp_out_pr_e.doc_type                         = xrpm_out_pr_e.doc_type
     AND  itp_out_pr_e.line_id                          = gmd_out_pr_e.material_detail_id
     AND  itp_out_pr_e.item_id                          = gmd_out_pr_e.item_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  itp_out_pr_e.item_id                          = ximv_out_pr_e.item_id
     AND  itp_out_pr_e.trans_date                      >= ximv_out_pr_e.start_date_active --�K�p�J�n��
     AND  itp_out_pr_e.trans_date                      <= ximv_out_pr_e.end_date_active   --�K�p�I����
     --���b�g���擾
     AND  itp_out_pr_e.item_id                          = ilm_out_pr_e.item_id
     AND  itp_out_pr_e.lot_id                           = ilm_out_pr_e.lot_id
     --�ۊǏꏊ���擾
     AND  grb_out_pr_e.attribute9                       = xilv_out_pr_e.segment1
     --�H���}�X�^���{��擾
     AND  grt_out_pr_e.language                         = 'JA'
     AND  grb_out_pr_e.routing_id                       = grt_out_pr_e.routing_id
  -- [ �R�D���Y�o�Ɏ���  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �S�D���Y�o�Ɏ��� �i�ڐU�� �i��U��
  -- �y���z�ȉ���SQL�͕ύX����ŏ������x���x���Ȃ�܂�
  -------------------------------------------------------------
  SELECT
          xrpm_out_pr_e70.new_div_invent                AS reason_code            -- ���R�R�[�h
         ,xilv_out_pr_e70.whse_code                     AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_pr_e70.segment1                      AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_pr_e70.description                   AS location               -- �ۊǏꏊ��
         ,xilv_out_pr_e70.short_name                    AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_pr_e70.item_id                       AS item_id                -- �i��ID
         ,ximv_out_pr_e70.item_no                       AS item_no                -- �i�ڃR�[�h
         ,ximv_out_pr_e70.item_name                     AS item_name              -- �i�ږ�
         ,ximv_out_pr_e70.item_short_name               AS item_short_name        -- �i�ڗ���
         ,ximv_out_pr_e70.num_of_cases                  AS case_content           -- �P�[�X����
         ,ximv_out_pr_e70.lot_ctl                       AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_pr_e70.lot_id                         AS lot_id                 -- ���b�gID
         ,ilm_out_pr_e70.lot_no                         AS lot_no                 -- ���b�gNo
         ,ilm_out_pr_e70.attribute1                     AS manufacture_date       -- �����N����
         ,ilm_out_pr_e70.attribute2                     AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_pr_e70.attribute3                     AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,gbh_out_pr_e70.batch_no                       AS voucher_no             -- �`�[�ԍ�
         ,gmd_out_pr_e70a.line_no                       AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,gbh_out_pr_e70.attribute2                     AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,itp_out_pr_e70.trans_date                     AS leaving_date           -- ���o�ɓ�_����
         ,itp_out_pr_e70.trans_date                     AS arrival_date           -- ���o�ɓ�_����
         ,itp_out_pr_e70.trans_date                     AS standard_date          -- ����i�����j
         ,grb_out_pr_e70.routing_no                     AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,grt_out_pr_e70.routing_desc                   AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,itp_out_pr_e70.trans_qty * -1                 AS leaving_quantity       -- �o�ɐ�
         ,itp_out_pr_e70.trans_qty * -1                 AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_out_pr_e70           -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_pr_e70           -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_pr_e70            -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_pr_e70           -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_gme_batch_header_arc                    gbh_out_pr_e70            -- ���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
         ,xxcmn_gme_material_details_arc                gmd_out_pr_e70a           -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v(�U�֌�)
         ,xxcmn_gme_material_details_arc                gmd_out_pr_e70b           -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v(�U�֐�)
         ,gmd_routings_b                                grb_out_pr_e70            -- �H���}�X�^
         ,gmd_routings_tl                               grt_out_pr_e70            -- �H���}�X�^���{��
         ,xxcmn_ic_tran_pnd_arc                         itp_out_pr_e70            -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
         ,xxskz_item_class_v                            xicv_out_pr_e70b          -- OPM�i�ڃJ�e�S���������VIEW5(�U�֐�)
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_pr_e70.doc_type                      = 'PROD'
     AND  xrpm_out_pr_e70.use_div_invent                = 'Y'
     -- �H���}�X�^�Ƃ̌����i�i�ڐU�փf�[�^�擾�̏����j
     AND  grb_out_pr_e70.routing_class                  = '70'                    -- �i�ڐU��
     AND  gbh_out_pr_e70.routing_id                     = grb_out_pr_e70.routing_id
     AND  xrpm_out_pr_e70.routing_class                 = grb_out_pr_e70.routing_class
     --���Y�o�b�`�E���Y�����ڍ�(�U�֌�)�̌�������
     AND  gmd_out_pr_e70a.line_type                     = -1                      -- �U�֌�
     AND  gbh_out_pr_e70.batch_id                       = gmd_out_pr_e70a.batch_id
     AND  xrpm_out_pr_e70.line_type                     = gmd_out_pr_e70a.line_type
     --���Y�o�b�`�E���Y�����ڍ�(�U�֐�)�̌�������
     AND  gmd_out_pr_e70b.line_type                     = 1                       -- �U�֐�
     AND  gbh_out_pr_e70.batch_id                       = gmd_out_pr_e70b.batch_id
     AND  gmd_out_pr_e70a.batch_id                      = gmd_out_pr_e70b.batch_id -- ���������xUP�ɗL��
     --�ۗ��݌Ƀg�����U�N�V�����̎擾
     AND  itp_out_pr_e70.delete_mark                    = 0                       -- �L���`�F�b�N(OPM�ۗ��݌�)
     AND  itp_out_pr_e70.completed_ind                  = 1                       -- ����(�ˎ���)
     AND  itp_out_pr_e70.reverse_id                     IS NULL
     AND  itp_out_pr_e70.lot_id                        <> 0
     AND  itp_out_pr_e70.doc_type                       = xrpm_out_pr_e70.doc_type
     AND  itp_out_pr_e70.doc_id                         = gmd_out_pr_e70a.batch_id  -- ���������xUP�ɗL��
     AND  itp_out_pr_e70.doc_line                       = gmd_out_pr_e70a.line_no   -- ���������xUP�ɗL��
     AND  itp_out_pr_e70.line_type                      = gmd_out_pr_e70a.line_type -- ���������xUP�ɗL��
     AND  itp_out_pr_e70.line_id                        = gmd_out_pr_e70a.material_detail_id
     AND  itp_out_pr_e70.item_id                        = ximv_out_pr_e70.item_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  gmd_out_pr_e70a.item_id                       = ximv_out_pr_e70.item_id
     AND  itp_out_pr_e70.trans_date                    >= ximv_out_pr_e70.start_date_active --�K�p�J�n��
     AND  itp_out_pr_e70.trans_date                    <= ximv_out_pr_e70.end_date_active   --�K�p�I����
     -- OPM�i�ڃJ�e�S���������VIEW5(�U�֐�A�U�֌�)
     AND  gmd_out_pr_e70b.item_id                       = xicv_out_pr_e70b.item_id
     AND (    xrpm_out_pr_e70.item_div_origin           = ximv_out_pr_e70.item_class_code   -- �U�֌�
          AND xrpm_out_pr_e70.item_div_ahead            = xicv_out_pr_e70b.item_class_code  -- �U�֐�
          AND (   ( ximv_out_pr_e70.item_class_code   <> xicv_out_pr_e70b.item_class_code )
               OR ( ximv_out_pr_e70.item_class_code    = xicv_out_pr_e70b.item_class_code )
              )
         )
     --���b�g���擾
     AND  ximv_out_pr_e70.item_id                       = ilm_out_pr_e70.item_id
     AND  itp_out_pr_e70.lot_id                         = ilm_out_pr_e70.lot_id
     -- OPM�ۊǏꏊ���擾
     AND  itp_out_pr_e70.whse_code                      = xilv_out_pr_e70.whse_code
     AND  itp_out_pr_e70.location                       = xilv_out_pr_e70.segment1
     --�H���}�X�^���{��擾
     AND  grt_out_pr_e70.language                       = 'JA'
     AND  grb_out_pr_e70.routing_id                     = grt_out_pr_e70.routing_id
  -- [ �S�D���Y�o�Ɏ��� �i�ڐU�� �i��U��  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �T�D���Y�o�Ɏ��� ���
  -------------------------------------------------------------
  SELECT
          xrpm_out_pr_e70.new_div_invent                AS reason_code            -- ���R�R�[�h
         ,xilv_out_pr_e70.whse_code                     AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_pr_e70.segment1                      AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_pr_e70.description                   AS location               -- �ۊǏꏊ��
         ,xilv_out_pr_e70.short_name                    AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_pr_e70.item_id                       AS item_id                -- �i��ID
         ,ximv_out_pr_e70.item_no                       AS item_no                -- �i�ڃR�[�h
         ,ximv_out_pr_e70.item_name                     AS item_name              -- �i�ږ�
         ,ximv_out_pr_e70.item_short_name               AS item_short_name        -- �i�ڗ���
         ,ximv_out_pr_e70.num_of_cases                  AS case_content           -- �P�[�X����
         ,ximv_out_pr_e70.lot_ctl                       AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_pr_e70.lot_id                         AS lot_id                 -- ���b�gID
         ,ilm_out_pr_e70.lot_no                         AS lot_no                 -- ���b�gNo
         ,ilm_out_pr_e70.attribute1                     AS manufacture_date       -- �����N����
         ,ilm_out_pr_e70.attribute2                     AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_pr_e70.attribute3                     AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,gbh_out_pr_e70.batch_no                       AS voucher_no             -- �`�[�ԍ�
         ,gmd_out_pr_e70.line_no                        AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,gbh_out_pr_e70.attribute2                     AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,itp_out_pr_e70.trans_date                     AS leaving_date           -- ���o�ɓ�_����
         ,itp_out_pr_e70.trans_date                     AS arrival_date           -- ���o�ɓ�_����
         ,itp_out_pr_e70.trans_date                     AS standard_date          -- ����i�����j
         ,grb_out_pr_e70.routing_no                     AS ukebaraisaki_code      -- �󕥃R�[�h
         ,grt_out_pr_e70.routing_desc                   AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,itp_out_pr_e70.trans_qty * -1                 AS leaving_quantity       -- �o�ɐ�
         ,itp_out_pr_e70.trans_qty * -1                 AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_out_pr_e70           -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_pr_e70           -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_pr_e70            -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_pr_e70           -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
--Mod 2013/3/19 V1.1 Start ��̃f�[�^���o�b�N�A�b�v�����܂ł͌��e�[�u���Q��
--         ,xxcmn_gme_batch_header_arc                    gbh_out_pr_e70            -- ���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
--         ,xxcmn_gme_material_details_arc                gmd_out_pr_e70            -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v
         ,gme_batch_header                              gbh_out_pr_e70            -- ���Y�o�b�`
         ,gme_material_details                          gmd_out_pr_e70            -- ���Y�����ڍ�
         ,gmd_routings_b                                grb_out_pr_e70            -- �H���}�X�^
         ,gmd_routings_tl                               grt_out_pr_e70            -- �H���}�X�^���{��
--         ,xxcmn_ic_tran_pnd_arc                         itp_out_pr_e70            -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
         ,ic_tran_pnd                                   itp_out_pr_e70            -- OPM�ۗ��݌Ƀg�����U�N�V����
--Mod 2013/3/19 V1.1 End
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_pr_e70.doc_type                      = 'PROD'
     AND  xrpm_out_pr_e70.use_div_invent                = 'Y'
     -- �H���}�X�^�Ƃ̌����i��̃f�[�^�擾�̏����j
     AND  grb_out_pr_e70.routing_class                  IN ( '61', '62' )         -- ���
     AND  gbh_out_pr_e70.routing_id                     = grb_out_pr_e70.routing_id
     AND  xrpm_out_pr_e70.routing_class                 = grb_out_pr_e70.routing_class
     --���Y�o�b�`/���Y�����ڍׂ̌���
     AND  gmd_out_pr_e70.line_type                      = -1                      -- �����i
     AND  gbh_out_pr_e70.batch_id                       = gmd_out_pr_e70.batch_id
     AND  xrpm_out_pr_e70.line_type                     = gmd_out_pr_e70.line_type
     --�ۗ��݌Ƀg�����U�N�V�����̎擾
     AND  itp_out_pr_e70.delete_mark                    = 0                       -- �L���`�F�b�N(OPM�ۗ��݌�)
     AND  itp_out_pr_e70.completed_ind                  = 1                       -- ����(�ˎ���)
     AND  itp_out_pr_e70.reverse_id                     IS NULL
     AND  itp_out_pr_e70.doc_type                       = xrpm_out_pr_e70.doc_type
     AND  itp_out_pr_e70.line_id                        = gmd_out_pr_e70.material_detail_id
     AND  itp_out_pr_e70.item_id                        = ximv_out_pr_e70.item_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  gmd_out_pr_e70.item_id                        = ximv_out_pr_e70.item_id
     AND  itp_out_pr_e70.trans_date                    >= ximv_out_pr_e70.start_date_active --�K�p�J�n��
     AND  itp_out_pr_e70.trans_date                    <= ximv_out_pr_e70.end_date_active   --�K�p�I����
     --���b�g���擾
     AND  ximv_out_pr_e70.item_id                       = ilm_out_pr_e70.item_id
     AND  itp_out_pr_e70.lot_id                         = ilm_out_pr_e70.lot_id
     --�ۊǏꏊ���擾
     AND  itp_out_pr_e70.whse_code                      = xilv_out_pr_e70.whse_code
     AND  itp_out_pr_e70.location                       = xilv_out_pr_e70.segment1
     --�H���}�X�^���{��擾
     AND  grt_out_pr_e70.language                       = 'JA'
     AND  grb_out_pr_e70.routing_id                     = grt_out_pr_e70.routing_id
  -- [ �T�D���Y�o�Ɏ��� ���  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �U�D�󒍏o�׎���
  -------------------------------------------------------------
  SELECT
          xrpm_out_om_e.new_div_invent                  AS reason_code            -- ���R�R�[�h
         ,xilv_out_om_e.whse_code                       AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_om_e.segment1                        AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_om_e.description                     AS location               -- �ۊǏꏊ��
         ,xilv_out_om_e.short_name                      AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_om_e_s.item_id                       AS item_id                -- �i��ID
         ,ximv_out_om_e_s.item_no                       AS item_no                -- �i�ڃR�[�h
         ,ximv_out_om_e_s.item_name                     AS item_name              -- �i�ږ�
         ,ximv_out_om_e_s.item_short_name               AS item_short_name        -- �i�ڗ���
         ,ximv_out_om_e_s.num_of_cases                  AS case_content           -- �P�[�X����
         ,ximv_out_om_e_s.lot_ctl                       AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_om_e.lot_id                           AS lot_id                 -- ���b�gID
         ,ilm_out_om_e.lot_no                           AS lot_no                 -- ���b�gNo
         ,ilm_out_om_e.attribute1                       AS manufacture_date       -- �����N����
         ,ilm_out_om_e.attribute2                       AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_om_e.attribute3                       AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xoha_out_om_e.request_no                      AS voucher_no             -- �`�[�ԍ�
         ,xola_out_om_e.order_line_number               AS line_no                -- �s�ԍ�
         ,xoha_out_om_e.delivery_no                     AS delivery_no            -- �z���ԍ�
         ,xoha_out_om_e.performance_management_dept     AS loct_code              -- �����R�[�h
         ,xlc_out_om_e.location_name                    AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,xoha_out_om_e.shipped_date                    AS leaving_date           -- ���o�ɓ�_����
         ,xoha_out_om_e.arrival_date                    AS arrival_date           -- ���o�ɓ�_����
         ,xoha_out_om_e.shipped_date                    AS standard_date          -- ����i�����j
         ,CASE WHEN xcst_out_om_e.customer_class_code = '10' THEN xoha_out_om_e.head_sales_branch  --�ڋq�R�[�h���ڋq�ł���ΊǊ����_��\��
               ELSE                                               xoha_out_om_e.customer_code      --�ڋq�R�[�h�����_�ł���΂��̋��_��\��
          END                                           AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,CASE WHEN xcst_out_om_e.customer_class_code = '10' THEN xcst_out_om_e_h.party_name       --�ڋq�R�[�h���ڋq�ł���ΊǊ����_����\��
               ELSE                                               xcst_out_om_e.party_name         --�ڋq�R�[�h�����_�ł���΂��̋��_����\��
          END                                           AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,xpas_out_om_e.party_site_number               AS deliver_to_no          -- �z����R�[�h
         ,xpas_out_om_e.party_site_name                 AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,xmld_out_om_e.actual_quantity                 AS leaving_quantity       -- �o�ɐ�
         ,xmld_out_om_e.actual_quantity                 AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_out_om_e             -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_om_e_s           -- OPM�i�ڏ��VIEW(�o�וi��)
         ,ic_lots_mst                                   ilm_out_om_e              -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_om_e             -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_order_headers_all_arc                   xoha_out_om_e             -- �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_order_lines_all_arc                     xola_out_om_e             -- �󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_out_om_e             -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,oe_transaction_types_all                      otta_out_om_e             -- �󒍃^�C�v
         ,xxskz_item_mst2_v                             ximv_out_om_e_r           -- OPM�i�ڏ��VIEW(�˗��i��)
         ,xxskz_cust_accounts2_v                        xcst_out_om_e             -- �󕥐�(���_)�擾�p
         ,xxskz_cust_accounts2_v                        xcst_out_om_e_h           -- �󕥐�(�Ǌ����_)�擾�p
         ,xxskz_party_sites2_v                          xpas_out_om_e             -- �z���於�擾�p
         ,xxskz_locations2_v                            xlc_out_om_e              -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���(�󒍃^�C�v����)
          xrpm_out_om_e.doc_type                        = 'OMSO'
     AND  xrpm_out_om_e.use_div_invent                  = 'Y'
     AND  xrpm_out_om_e.stock_adjustment_div            = '1'
     AND  xrpm_out_om_e.shipment_provision_div          = '1'                     -- �o�׈˗�
     --�󒍃^�C�v�̏����i�܂ށF�󕥋敪�A�h�I���}�X�^�̍i���ݏ����j
     AND  otta_out_om_e.attribute1                      = '1'                     -- �o�׈˗�
     AND  otta_out_om_e.order_category_code             = 'ORDER'
     AND  xrpm_out_om_e.stock_adjustment_div            = otta_out_om_e.attribute4
     AND  (   xrpm_out_om_e.ship_prov_rcv_pay_category  IS NULL
           OR xrpm_out_om_e.ship_prov_rcv_pay_category  = otta_out_om_e.attribute11
          )
     --�󒍃w�b�_�̏���
     AND  xoha_out_om_e.req_status                      = '04'                    -- �o�׎��ьv���
     AND  xoha_out_om_e.latest_external_flag            = 'Y'                     -- ON
     AND  otta_out_om_e.transaction_type_id             = xoha_out_om_e.order_type_id
     --�󒍖��ׂƂ̌���
     AND  xola_out_om_e.delete_flag                     = 'N'                     -- �������׈ȊO
     AND  xoha_out_om_e.order_header_id                 = xola_out_om_e.order_header_id
     --�ړ����b�g�ڍ׎擾
     AND  xmld_out_om_e.document_type_code              = '10'                    -- �o�׈˗�
     AND  xmld_out_om_e.record_type_code                = '20'                    -- �o�Ɏ���
     AND  xola_out_om_e.order_line_id                   = xmld_out_om_e.mov_line_id
     --�i�ڃ}�X�^(�o�וi��)�Ƃ̌���
     AND  xmld_out_om_e.item_id                         = ximv_out_om_e_s.item_id
     AND  xoha_out_om_e.shipped_date                   >= ximv_out_om_e_s.start_date_active --�K�p�J�n��
     AND  xoha_out_om_e.shipped_date                   <= ximv_out_om_e_s.end_date_active   --�K�p�I����
     AND  NVL( xrpm_out_om_e.item_div_origin, 'Dummy' ) = DECODE( ximv_out_om_e_s.item_class_code,'5','5','Dummy' ) --�U�֌��i�ڋ敪 = �o�וi�ڋ敪
     --�i�ڃ}�X�^(�˗��i��)�Ƃ̌���
     AND  xola_out_om_e.request_item_id                 = ximv_out_om_e_r.inventory_item_id
     AND  xoha_out_om_e.shipped_date                   >= ximv_out_om_e_r.start_date_active --�K�p�J�n��
     AND  xoha_out_om_e.shipped_date                   <= ximv_out_om_e_r.end_date_active   --�K�p�I����
     AND  NVL( xrpm_out_om_e.item_div_ahead , 'Dummy' ) = DECODE( ximv_out_om_e_r.item_class_code,'5','5','Dummy' ) --�U�֐�i�ڋ敪 = �˗��i�ڋ敪
     --���b�g���擾
     AND  xmld_out_om_e.item_id                         = ilm_out_om_e.item_id
     AND  xmld_out_om_e.lot_id                          = ilm_out_om_e.lot_id
     --�ۊǏꏊ���擾
     AND  xoha_out_om_e.deliver_from_id                 = xilv_out_om_e.inventory_location_id
     --�󕥐���擾�i���_�j
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
--     AND  xoha_out_om_e.customer_id                     = xcst_out_om_e.party_id
     AND  xpas_out_om_e.party_id                        = xcst_out_om_e.party_id
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
     AND  xoha_out_om_e.shipped_date                   >= xcst_out_om_e.start_date_active --�K�p�J�n��
     AND  xoha_out_om_e.shipped_date                   <= xcst_out_om_e.end_date_active   --�K�p�I����
     --�󕥐���擾�i�Ǌ����_�j
     AND  xoha_out_om_e.head_sales_branch               = xcst_out_om_e_h.party_number(+)
     AND  xoha_out_om_e.schedule_ship_date             >= xcst_out_om_e_h.start_date_active(+) --�K�p�J�n��
     AND  xoha_out_om_e.schedule_ship_date             <= xcst_out_om_e_h.end_date_active(+)   --�K�p�I����
     --�z����擾
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
--     AND  xoha_out_om_e.result_deliver_to_id            = xpas_out_om_e.party_site_id
     AND  xoha_out_om_e.result_deliver_to               = xpas_out_om_e.party_site_number
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
     AND  xoha_out_om_e.shipped_date                   >= xpas_out_om_e.start_date_active --�K�p�J�n��
     AND  xoha_out_om_e.shipped_date                   <= xpas_out_om_e.end_date_active   --�K�p�I����
     --�������擾
     AND  xoha_out_om_e.performance_management_dept     = xlc_out_om_e.location_code(+)
     AND  xoha_out_om_e.shipped_date                   >= xlc_out_om_e.start_date_active(+)
     AND  xoha_out_om_e.shipped_date                   <= xlc_out_om_e.end_date_active(+)
  -- [ �U�D�󒍏o�׎���  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �V�D�L���o�׎���
  -------------------------------------------------------------
  SELECT
          xrpm_out_om2_e.new_div_invent                 AS reason_code            -- ���R�R�[�h
         ,xilv_out_om2_e.whse_code                      AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_om2_e.segment1                       AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_om2_e.description                    AS location               -- �ۊǏꏊ��
         ,xilv_out_om2_e.short_name                     AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_om2_e_s.item_id                      AS item_id                -- �i��ID
         ,ximv_out_om2_e_s.item_no                      AS item_no                -- �i�ڃR�[�h
         ,ximv_out_om2_e_s.item_name                    AS item_name              -- �i�ږ�
         ,ximv_out_om2_e_s.item_short_name              AS item_short_name        -- �i�ڗ���
         ,ximv_out_om2_e_s.num_of_cases                 AS case_content           -- �P�[�X����
         ,ximv_out_om2_e_s.lot_ctl                      AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_om2_e.lot_id                          AS lot_id                 -- ���b�gID
         ,ilm_out_om2_e.lot_no                          AS lot_no                 -- ���b�gNo
         ,ilm_out_om2_e.attribute1                      AS manufacture_date       -- �����N����
         ,ilm_out_om2_e.attribute2                      AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_om2_e.attribute3                      AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,xoha_out_om2_e.request_no                     AS voucher_no             -- �`�[�ԍ�
         ,xola_out_om2_e.order_line_number              AS line_no                -- �s�ԍ�
         ,xoha_out_om2_e.delivery_no                    AS delivery_no            -- �z���ԍ�
         ,xoha_out_om2_e.performance_management_dept    AS loct_code              -- �����R�[�h
         ,xlc_out_om2_e.location_name                   AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,xoha_out_om2_e.shipped_date                   AS leaving_date           -- ���o�ɓ�_����
-- *----------* 2009/04/23 M.Nomura update start *----------*
--         ,xoha_out_om2_e.arrival_date                   AS arrival_date           -- ���o�ɓ�_����
         ,NVL(xoha_out_om2_e.arrival_date,
              xoha_out_om2_e.shipped_date)              AS arrival_date           -- ���o�ɓ�_����
-- *----------* 2009/04/23 M.Nomura update end   *----------*
         ,xoha_out_om2_e.shipped_date                   AS standard_date          -- ����i�����j
         ,xoha_out_om2_e.vendor_site_code               AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xvsv_out_om2_e.vendor_site_name               AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,CASE WHEN otta_out_om2_e.order_category_code = 'RETURN' THEN xmld_out_om2_e.actual_quantity * -1
               ELSE                                                    xmld_out_om2_e.actual_quantity
          END                                           AS leaving_quantity       -- �o�ɐ�
         ,CASE WHEN otta_out_om2_e.order_category_code = 'RETURN' THEN xmld_out_om2_e.actual_quantity * -1
               ELSE                                                    xmld_out_om2_e.actual_quantity
          END                                           AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_out_om2_e            -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_om2_e_s          -- OPM�i�ڏ��VIEW(�o�וi��)
         ,ic_lots_mst                                   ilm_out_om2_e             -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_om2_e            -- �󕥋敪�A�h�I���}�X�^ -- <---- �����܂ŋ���
         ,xxcmn_order_headers_all_arc                   xoha_out_om2_e            -- �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_order_lines_all_arc                     xola_out_om2_e            -- �󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_out_om2_e            -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,oe_transaction_types_all                      otta_out_om2_e            -- �󒍃^�C�v
         ,xxskz_item_mst2_v                             ximv_out_om2_e_r          -- OPM�i�ڏ��VIEW(�˗��i��)
         ,xxskz_vendor_sites_v                          xvsv_out_om2_e            -- �d����T�C�g���VIEW(�󕥐於�擾�p)
         ,xxskz_locations2_v                            xlc_out_om2_e             -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���(�󒍃^�C�v����)
         (   (     xrpm_out_om2_e.doc_type              = 'OMSO'
              AND  otta_out_om2_e.order_category_code   = 'ORDER')
          OR (     xrpm_out_om2_e.doc_type              = 'PORC'
              AND  xrpm_out_om2_e.source_document_code  = 'RMA'
              AND  otta_out_om2_e.order_category_code   = 'RETURN'
             )
         )
     AND  xrpm_out_om2_e.use_div_invent                 = 'Y'
     AND  xrpm_out_om2_e.shipment_provision_div         = '2'                     -- �x���˗�
     --�󒍃^�C�v�̏����i�܂ށF�󕥋敪�A�h�I���}�X�^�̍i���ݏ����j
     AND  otta_out_om2_e.attribute1                     = '2'                     -- �x���˗�
     AND (   xrpm_out_om2_e.ship_prov_rcv_pay_category  = otta_out_om2_e.attribute11
          OR xrpm_out_om2_e.ship_prov_rcv_pay_category  IS NULL
         )
     --�󒍃w�b�_�̏���
     AND  xoha_out_om2_e.req_status                     = '08'                    -- �o�׎��ьv���
     AND  xoha_out_om2_e.latest_external_flag           = 'Y'                     -- ON
     AND  otta_out_om2_e.transaction_type_id            = xoha_out_om2_e.order_type_id
     --�󒍖��ׂƂ̌���
     AND  xola_out_om2_e.delete_flag                    = 'N'                     -- OFF
     AND  xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
     --�ړ����b�g�ڍ׎擾
     AND  xmld_out_om2_e.document_type_code             = '30'      -- �x���w��
     AND  xmld_out_om2_e.record_type_code               = '20'      -- �o�Ɏ���
     AND  xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
     --�i�ڃ}�X�^(�o�וi��)�Ƃ̌���
     AND  xmld_out_om2_e.item_id                        = ximv_out_om2_e_s.item_id
     AND  xoha_out_om2_e.shipped_date                  >= ximv_out_om2_e_s.start_date_active --�K�p�J�n��
     AND  xoha_out_om2_e.shipped_date                  <= ximv_out_om2_e_s.end_date_active   --�K�p�I����
     AND  NVL( xrpm_out_om2_e.item_div_origin,'Dummy' ) = DECODE(ximv_out_om2_e_s.item_class_code,'5','5','Dummy') --�U�֌��i�ڋ敪 = �o�וi�ڋ敪
     --�i�ڃ}�X�^(�˗��i��)�Ƃ̌���
     AND  xola_out_om2_e.request_item_id                = ximv_out_om2_e_r.inventory_item_id
     AND  xoha_out_om2_e.shipped_date                  >= ximv_out_om2_e_r.start_date_active --�K�p�J�n��
     AND  xoha_out_om2_e.shipped_date                  <= ximv_out_om2_e_r.end_date_active   --�K�p�I����
     AND  NVL( xrpm_out_om2_e.item_div_ahead ,'Dummy' ) = DECODE(ximv_out_om2_e_r.item_class_code,'5','5','Dummy') --�U�֐�i�ڋ敪 = �˗��i�ڋ敪
     --�i�ڃJ�e�S���E�i�ڃJ�e�S���������(�o�וi��/�˗��i��)�ǉ�����
     AND (   (    xola_out_om2_e.shipping_inventory_item_id = xola_out_om2_e.request_item_id               -- �i�ڐU�ւł͂Ȃ�
              AND xrpm_out_om2_e.prod_div_origin IS NULL  AND  xrpm_out_om2_e.prod_div_ahead IS NULL
             )
          OR (    xola_out_om2_e.shipping_inventory_item_id <> xola_out_om2_e.request_item_id              -- �i�ڐU��
              AND ximv_out_om2_e_s.item_class_code = '5'  AND  ximv_out_om2_e_r.item_class_code = '5'      -- ���i
              AND xrpm_out_om2_e.prod_div_origin IS NOT NULL  AND  xrpm_out_om2_e.prod_div_ahead IS NOT NULL
             )
          OR (    xola_out_om2_e.shipping_inventory_item_id <> xola_out_om2_e.request_item_id              -- �i�ڐU��
              AND ( ximv_out_om2_e_s.item_class_code <> '5'  OR  ximv_out_om2_e_r.item_class_code <> '5')  -- ���i
              AND   xrpm_out_om2_e.prod_div_origin IS NULL  AND  xrpm_out_om2_e.prod_div_ahead IS NULL )
         )
     --���b�g���擾
     AND  xmld_out_om2_e.item_id                        = ilm_out_om2_e.item_id
     AND  xmld_out_om2_e.lot_id                         = ilm_out_om2_e.lot_id
     --�ۊǏꏊ���擾
     AND  xoha_out_om2_e.deliver_from_id                = xilv_out_om2_e.inventory_location_id
     --�󕥐�(�d����T�C�g���)�擾
     AND  xvsv_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
     AND  xoha_out_om2_e.shipped_date                  >= xvsv_out_om2_e.start_date_active --�K�p�J�n��
     AND  xoha_out_om2_e.shipped_date                  <= xvsv_out_om2_e.end_date_active   --�K�p�I����
     --�������擾
-- 2010/01/05 T.Yoshimoto Mod Start E_�{�ғ�#831
--     AND  xoha_out_om2_e.performance_management_dept    = xlc_out_om2_e.location_code(+)
--     AND  xoha_out_om2_e.shipped_date                  >= xlc_out_om2_e.start_date_active(+)
--     AND  xoha_out_om2_e.shipped_date                  <= xlc_out_om2_e.end_date_active(+)
     AND  xoha_out_om2_e.performance_management_dept    = xlc_out_om2_e.location_code
     AND  xoha_out_om2_e.shipped_date                  >= xlc_out_om2_e.start_date_active
     AND  xoha_out_om2_e.shipped_date                  <= xlc_out_om2_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_�{�ғ�#831
  -- [ �V�D�L���o�׎���  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �W�D�݌ɒ��� �o�Ɏ���(�o�� ���{�o�� �p�p�o��)
  -------------------------------------------------------------
  SELECT
          xrpm_out_om3_e.new_div_invent                 AS reason_code            -- ���R�R�[�h
         ,xilv_out_om3_e.whse_code                      AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_om3_e.segment1                       AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_om3_e.description                    AS location               -- �ۊǏꏊ��
         ,xilv_out_om3_e.short_name                     AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_om3_e.item_id                        AS item_id                -- �i��ID
         ,ximv_out_om3_e.item_no                        AS item_no                -- �i�ڃR�[�h
         ,ximv_out_om3_e.item_name                      AS item_name              -- �i�ږ�
         ,ximv_out_om3_e.item_short_name                AS item_short_name        -- �i�ڗ���
         ,ximv_out_om3_e.num_of_cases                   AS case_content           -- �P�[�X����
         ,ximv_out_om3_e.lot_ctl                        AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_om3_e.lot_id                          AS lot_id                 -- ���b�gID
         ,ilm_out_om3_e.lot_no                          AS lot_no                 -- ���b�gNo
         ,ilm_out_om3_e.attribute1                      AS manufacture_date       -- �����N����
         ,ilm_out_om3_e.attribute2                      AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_om3_e.attribute3                      AS expiration_date        -- �ܖ����� -- <--�����܂ŋ���
         ,xoha_out_om3_e.request_no                     AS voucher_no             -- �`�[�ԍ�
         ,xola_out_om3_e.order_line_number              AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,xoha_out_om3_e.performance_management_dept    AS loct_code              -- �����R�[�h
         ,xlc_out_om3_e.location_name                   AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,xoha_out_om3_e.shipped_date                   AS leaving_date           -- ���o�ɓ�_����
         ,xoha_out_om3_e.arrival_date                   AS arrival_date           -- ���o�ɓ�_����
         ,xoha_out_om3_e.shipped_date                   AS standard_date          -- ����i�����j
         ,xoha_out_om3_e.customer_code                  AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xcst_out_om3_e.party_name                     AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,xpas_out_om3_e.party_site_number              AS deliver_to_no          -- �z����R�[�h
         ,xpas_out_om3_e.party_site_name                AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,xmld_out_om3_e.actual_quantity                AS leaving_quantity       -- �o�ɐ�
         ,xmld_out_om3_e.actual_quantity                AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations2_v                       xilv_out_om3_e            -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_om3_e            -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_om3_e             -- OPM���b�g�}�X�^
         ,xxcmn_rcv_pay_mst                             xrpm_out_om3_e            -- �󕥋敪�A�h�I���}�X�^ -- <--�����܂ŋ���
         ,xxcmn_order_headers_all_arc                   xoha_out_om3_e            -- �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_order_lines_all_arc                     xola_out_om3_e            -- �󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
         ,xxcmn_mov_lot_details_arc                     xmld_out_om3_e            -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
         ,oe_transaction_types_all                      otta_out_om3_e            -- �󒍃^�C�v
         ,xxskz_cust_accounts2_v                        xcst_out_om3_e            -- �󕥐�
         ,xxskz_party_sites2_v                          xpas_out_om3_e            -- �z���於�擾�p
         ,xxskz_locations2_v                            xlc_out_om3_e             -- �������擾�p
   WHERE
     --�󕥋敪�A�h�I���}�X�^�̏���
          xrpm_out_om3_e.doc_type                       = 'OMSO'
     AND  xrpm_out_om3_e.use_div_invent                 = 'Y'
     AND  xrpm_out_om3_e.stock_adjustment_div           = '2'
     AND  xrpm_out_om3_e.ship_prov_rcv_pay_category    IN ( '01' , '02' )
     --�󒍃^�C�v�擾
     AND  otta_out_om3_e.attribute1                     = '1'       -- �o�׈˗�
     AND  otta_out_om3_e.order_category_code            = 'ORDER'
     AND  xrpm_out_om3_e.stock_adjustment_div           = otta_out_om3_e.attribute4
     AND  xrpm_out_om3_e.ship_prov_rcv_pay_category     = otta_out_om3_e.attribute11
     --�󒍃w�b�_�̏���
     AND  xoha_out_om3_e.req_status                     = '04'      -- �o�׎��ьv���
     AND  xoha_out_om3_e.latest_external_flag           = 'Y'       -- ON
     AND  otta_out_om3_e.transaction_type_id            = xoha_out_om3_e.order_type_id
     --�󒍖��ׂƂ̌���
     AND  xola_out_om3_e.delete_flag                    = 'N'       -- OFF
     AND  xoha_out_om3_e.order_header_id                = xola_out_om3_e.order_header_id
     --�ړ����b�g�ڍ׎擾
     AND  xmld_out_om3_e.document_type_code             = '10'      -- �o�׈˗�
     AND  xmld_out_om3_e.record_type_code               = '20'      -- �o�Ɏ���
     AND  xola_out_om3_e.order_line_id                  = xmld_out_om3_e.mov_line_id
     --�i�ڃ}�X�^�Ƃ̌���
     AND  xmld_out_om3_e.item_id                        = ximv_out_om3_e.item_id
     AND  xoha_out_om3_e.shipped_date                  >= ximv_out_om3_e.start_date_active --�K�p�J�n��
     AND  xoha_out_om3_e.shipped_date                  <= ximv_out_om3_e.end_date_active   --�K�p�I����
     --���b�g���擾
     AND  xmld_out_om3_e.item_id                        = ilm_out_om3_e.item_id
     AND  xmld_out_om3_e.lot_id                         = ilm_out_om3_e.lot_id
     --�ۊǏꏊ���擾
     AND  xoha_out_om3_e.deliver_from_id                = xilv_out_om3_e.inventory_location_id
     --�󕥐���擾
     AND  xoha_out_om3_e.customer_id                    = xcst_out_om3_e.party_id
     AND  xoha_out_om3_e.shipped_date                  >= xcst_out_om3_e.start_date_active --�K�p�J�n��
     AND  xoha_out_om3_e.shipped_date                  <= xcst_out_om3_e.end_date_active   --�K�p�I����
     --�z����擾
     AND  xoha_out_om3_e.result_deliver_to_id           = xpas_out_om3_e.party_site_id
     AND  xoha_out_om3_e.shipped_date                  >= xpas_out_om3_e.start_date_active --�K�p�J�n��
     AND  xoha_out_om3_e.shipped_date                  <= xpas_out_om3_e.end_date_active   --�K�p�I����
     --�������擾
     AND  xoha_out_om3_e.performance_management_dept    = xlc_out_om3_e.location_code(+)
     AND  xoha_out_om3_e.shipped_date                  >= xlc_out_om3_e.start_date_active(+)
     AND  xoha_out_om3_e.shipped_date                  <= xlc_out_om3_e.end_date_active(+)
  -- [ �W�D�݌ɒ��� �o�Ɏ���(�o�� ���{�o�� �p�p�o��)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �X�D�݌ɒ��� �o�Ɏ���(�����݌�)
  --  ��OPM�����݌Ƀg�����U�N�V�����Ńf�[�^��������ׁA�W�v���s��
  -------------------------------------------------------------
  SELECT
          sitc_out_ad_e_x97.reason_code                 AS reason_code            -- ���R�R�[�h
         ,xilv_out_ad_e_x97.whse_code                   AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_ad_e_x97.segment1                    AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_ad_e_x97.description                 AS location               -- �ۊǏꏊ��
         ,xilv_out_ad_e_x97.short_name                  AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_ad_e_x97.item_id                     AS item_id                -- �i��ID
         ,ximv_out_ad_e_x97.item_no                     AS item_no                -- �i�ڃR�[�h
         ,ximv_out_ad_e_x97.item_name                   AS item_name              -- �i�ږ�
         ,ximv_out_ad_e_x97.item_short_name             AS item_short_name        -- �i�ڗ���
         ,ximv_out_ad_e_x97.num_of_cases                AS case_content           -- �P�[�X����
         ,ximv_out_ad_e_x97.lot_ctl                     AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_ad_e_x97.lot_id                       AS lot_id                 -- ���b�gID
         ,ilm_out_ad_e_x97.lot_no                       AS lot_no                 -- ���b�gNo
         ,ilm_out_ad_e_x97.attribute1                   AS manufacture_date       -- �����N����
         ,ilm_out_ad_e_x97.attribute2                   AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_ad_e_x97.attribute3                   AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,sitc_out_ad_e_x97.journal_no                  AS voucher_no             -- �`�[�ԍ�
         ,NULL                                          AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,NULL                                          AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,sitc_out_ad_e_x97.tran_date                   AS leaving_date           -- ���o�ɓ�_����
         ,sitc_out_ad_e_x97.tran_date                   AS arrival_date           -- ���o�ɓ�_����
         ,sitc_out_ad_e_x97.tran_date                   AS standard_date          -- ����i�����j
         ,sitc_out_ad_e_x97.reason_code                 AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,flv_out_ad_e_x97.meaning                      AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h
         ,NULL                                          AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,sitc_out_ad_e_x97.quantity * -1               AS leaving_quantity       -- �o�ɐ�
         ,sitc_out_ad_e_x97.quantity * -1               AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_out_ad_e_x97         -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_ad_e_x97         -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_ad_e_x97          -- OPM���b�g�}�X�^ -- <---- �����܂ŋ���
         ,(  -- �Ώۃf�[�^���W�v
             SELECT
                     xrpm_out_ad_e_x97.new_div_invent   reason_code               -- ���R�R�[�h
                    ,ijm_out_ad_e_x97.journal_no        journal_no                -- �W���[�i��No
                    ,itc_out_ad_e_x97.location          loct_code                 -- �ۊǏꏊ�R�[�h
                    ,itc_out_ad_e_x97.trans_date        tran_date                 -- �����
                    ,itc_out_ad_e_x97.item_id           item_id                   -- �i��ID
                    ,itc_out_ad_e_x97.lot_id            lot_id                    -- ���b�gID
                    ,SUM( itc_out_ad_e_x97.trans_qty )  quantity                  -- ���o�ɐ��i�W�v�l�j
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_out_ad_e_x97         -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_ic_tran_cmp_arc              itc_out_ad_e_x97          -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                    ,ic_jrnl_mst                        ijm_out_ad_e_x97          -- OPM�W���[�i���}�X�^
                    ,ic_adjs_jnl                        iaj_out_ad_e_x97          -- OPM�݌ɒ����W���[�i��
              WHERE
                --�󕥋敪�A�h�I���}�X�^�̏���
                     xrpm_out_ad_e_x97.doc_type         = 'ADJI'
                AND  xrpm_out_ad_e_x97.reason_code      = 'X977'                  -- �����݌�
                AND  xrpm_out_ad_e_x97.rcv_pay_div      = '-1'                    -- ���o
                AND  xrpm_out_ad_e_x97.use_div_invent   = 'Y'
                --�����݌Ƀg�����U�N�V�����̏���
                AND  itc_out_ad_e_x97.doc_type          = xrpm_out_ad_e_x97.doc_type
                AND  itc_out_ad_e_x97.reason_code       = xrpm_out_ad_e_x97.reason_code
                AND  SIGN( itc_out_ad_e_x97.trans_qty ) = xrpm_out_ad_e_x97.rcv_pay_div
                --�݌ɒ����W���[�i���̎擾
                AND  itc_out_ad_e_x97.doc_type          = iaj_out_ad_e_x97.trans_type
                AND  itc_out_ad_e_x97.doc_id            = iaj_out_ad_e_x97.doc_id     -- OPM�݌ɒ����W���[�i�����o����
                AND  itc_out_ad_e_x97.doc_line          = iaj_out_ad_e_x97.doc_line   -- OPM�݌ɒ����W���[�i�����o����
                --�W���[�i���}�X�^�̎擾
                AND  ijm_out_ad_e_x97.attribute1        IS NULL                       -- OPM�W���[�i���}�X�^.����ID��NULL
                AND  ijm_out_ad_e_x97.journal_id        = iaj_out_ad_e_x97.journal_id -- OPM�W���[�i���}�X�^���o����
             GROUP BY
                     xrpm_out_ad_e_x97.new_div_invent                             -- ���R�R�[�h
                    ,ijm_out_ad_e_x97.journal_no                                  -- �W���[�i��No
                    ,itc_out_ad_e_x97.location                                    -- �ۊǏꏊ�R�[�h
                    ,itc_out_ad_e_x97.trans_date                                  -- �����
                    ,itc_out_ad_e_x97.item_id                                     -- �i��ID
                    ,itc_out_ad_e_x97.lot_id                                      -- ���b�gID
          )                                             sitc_out_ad_e_x97
         ,fnd_lookup_values                             flv_out_ad_e_x97          -- �N�C�b�N�R�[�h(�󕥐於�擾�p)
   WHERE
     --�i�ڃ}�X�^(�o�וi��)�Ƃ̌���
          sitc_out_ad_e_x97.item_id                     = ximv_out_ad_e_x97.item_id
     AND  sitc_out_ad_e_x97.tran_date                  >= ximv_out_ad_e_x97.start_date_active --�K�p�J�n��
     AND  sitc_out_ad_e_x97.tran_date                  <= ximv_out_ad_e_x97.end_date_active   --�K�p�I����
     --���b�g���擾
     AND  sitc_out_ad_e_x97.item_id                     = ilm_out_ad_e_x97.item_id
     AND  sitc_out_ad_e_x97.lot_id                      = ilm_out_ad_e_x97.lot_id
     --�ۊǏꏊ���擾
     AND  sitc_out_ad_e_x97.loct_code                   = xilv_out_ad_e_x97.segment1
     --�󕥐���擾
     AND  flv_out_ad_e_x97.lookup_type                  = 'XXCMN_NEW_DIVISION'
     AND  flv_out_ad_e_x97.language                     = 'JA'
     AND  flv_out_ad_e_x97.lookup_code                  = sitc_out_ad_e_x97.reason_code
  -- [ �X�D�݌ɒ��� �o�Ɏ���(�����݌�)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �P�O�D�����݌ɏo�Ɏ���
  --  ��OPM�����݌Ƀg�����U�N�V�����Ńf�[�^��������ׁA�W�v���s��
  -------------------------------------------------------------
  SELECT
          sitc_out_ad_e_x97.reason_code                 AS reason_code            -- ���R�R�[�h
         ,xilv_out_ad_e_x97.whse_code                   AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_ad_e_x97.segment1                    AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_ad_e_x97.description                 AS location               -- �ۊǏꏊ��
         ,xilv_out_ad_e_x97.short_name                  AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_ad_e_x97.item_id                     AS item_id                -- �i��ID
         ,ximv_out_ad_e_x97.item_no                     AS item_no                -- �i�ڃR�[�h
         ,ximv_out_ad_e_x97.item_name                   AS item_name              -- �i�ږ�
         ,ximv_out_ad_e_x97.item_short_name             AS item_short_name        -- �i�ڗ���
         ,ximv_out_ad_e_x97.num_of_cases                AS case_content           -- �P�[�X����
         ,ximv_out_ad_e_x97.lot_ctl                     AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_ad_e_x97.lot_id                       AS lot_id                 -- ���b�gID
         ,ilm_out_ad_e_x97.lot_no                       AS lot_no                 -- ���b�gNo
         ,ilm_out_ad_e_x97.attribute1                   AS manufacture_date       -- �����N����
         ,ilm_out_ad_e_x97.attribute2                   AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_ad_e_x97.attribute3                   AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,sitc_out_ad_e_x97.rcv_rtn_num                 AS voucher_no             -- �`�[�ԍ�
         ,sitc_out_ad_e_x97.line_no                     AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,sitc_out_ad_e_x97.dept_code                   AS loct_code              -- �����R�[�h
         ,xlc_out_ad_e_x97.location_name                AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,sitc_out_ad_e_x97.tran_date                   AS leaving_date           -- ���o�ɓ�_����
         ,sitc_out_ad_e_x97.tran_date                   AS arrival_date           -- ���o�ɓ�_����
         ,sitc_out_ad_e_x97.tran_date                   AS standard_date          -- ����i�����j
         ,xvv_out_ad_e_x97.segment1                     AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,xvv_out_ad_e_x97.vendor_name                  AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,xilv_out_ad_e_x97.segment1                    AS deliver_to_no          -- �z����R�[�h
         ,xilv_out_ad_e_x97.description                 AS deliver_to_name        -- �z���於
         ,0                                             AS stock_quantity         -- ���ɐ�
         ,sitc_out_ad_e_x97.quantity * -1               AS leaving_quantity       -- �o�ɐ�
         ,sitc_out_ad_e_x97.quantity * -1               AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_out_ad_e_x97         -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_ad_e_x97         -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_ad_e_x97          -- OPM���b�g�}�X�^
         ,(  -- �Ώۃf�[�^���W�v
             SELECT
                     xrpm_out_ad_e_x97.new_div_invent       reason_code           -- ���R�R�[�h
                    ,xrart_out_ad_e_x97.rcv_rtn_number      rcv_rtn_num           -- ����ԕi�ԍ�
                    ,xrart_out_ad_e_x97.rcv_rtn_line_number line_no               -- �s�ԍ�
                    ,itc_out_ad_e_x97.location              loct_code             -- �ۊǏꏊ�R�[�h
                    ,xrart_out_ad_e_x97.department_code     dept_code             -- �����R�[�h
                    ,xrart_out_ad_e_x97.vendor_id           vendor_id             -- �����ID
                    ,itc_out_ad_e_x97.trans_date            tran_date             -- �����
                    ,itc_out_ad_e_x97.item_id               item_id               -- �i��ID
                    ,itc_out_ad_e_x97.lot_id                lot_id                -- ���b�gID
                    ,SUM( itc_out_ad_e_x97.trans_qty )      quantity              -- ���o�ɐ��i�W�v�l�j
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_out_ad_e_x97         -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_ic_tran_cmp_arc              itc_out_ad_e_x97          -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v -- <---- �����܂ŋ���
                    ,ic_jrnl_mst                        ijm_out_ad_e_x97          -- OPM�W���[�i���}�X�^
                    ,ic_adjs_jnl                        iaj_out_ad_e_x97          -- OPM�݌ɒ����W���[�i��
                    ,xxpo_rcv_and_rtn_txns              xrart_out_ad_e_x97        -- ����ԕi���уA�h�I��
              WHERE
                --�󕥋敪�A�h�I���}�X�^�̏���(�󒍃^�C�v����)
                     xrpm_out_ad_e_x97.doc_type         = 'ADJI'
                AND  xrpm_out_ad_e_x97.reason_code      = 'X977'                  -- �����݌�
                AND  xrpm_out_ad_e_x97.rcv_pay_div      = '-1'                    -- ���o
                AND  xrpm_out_ad_e_x97.use_div_invent   = 'Y'
                --�����݌Ƀg�����U�N�V�����Ƃ̌���
                AND  itc_out_ad_e_x97.doc_type          = xrpm_out_ad_e_x97.doc_type
                AND  itc_out_ad_e_x97.reason_code       = xrpm_out_ad_e_x97.reason_code
                --�݌ɒ����W���[�i���Ƃ̌���
                AND  itc_out_ad_e_x97.doc_type          = iaj_out_ad_e_x97.trans_type
                AND  itc_out_ad_e_x97.doc_id            = iaj_out_ad_e_x97.doc_id       -- OPM�݌ɒ����W���[�i�����o����
                AND  itc_out_ad_e_x97.doc_line          = iaj_out_ad_e_x97.doc_line     -- OPM�݌ɒ����W���[�i�����o����
                --�W���[�i���}�X�^�Ƃ̌���
                AND  ijm_out_ad_e_x97.attribute1        IS NOT NULL                     -- OPM�W���[�i���}�X�^.����ID��NULL�łȂ�
                AND  ijm_out_ad_e_x97.attribute4        IS NULL                         -- (���o�ɏƉ���)
                AND  iaj_out_ad_e_x97.journal_id        = ijm_out_ad_e_x97.journal_id   -- OPM�W���[�i���}�X�^���o����
                --����ԕi���уA�h�I���Ƃ̌���
                AND  TO_NUMBER(ijm_out_ad_e_x97.attribute1)  = xrart_out_ad_e_x97.txns_id    -- ����ID
             GROUP BY
                     xrpm_out_ad_e_x97.new_div_invent                             -- ���R�R�[�h
                    ,xrart_out_ad_e_x97.rcv_rtn_number                            -- ����ԕi�ԍ�
                    ,xrart_out_ad_e_x97.rcv_rtn_line_number                       -- �s�ԍ�
                    ,itc_out_ad_e_x97.location                                    -- �ۊǏꏊ�R�[�h
                    ,xrart_out_ad_e_x97.department_code                           -- �����R�[�h
                    ,xrart_out_ad_e_x97.vendor_id                                 -- �����ID
                    ,itc_out_ad_e_x97.trans_date                                  -- �����
                    ,itc_out_ad_e_x97.item_id                                     -- �i��ID
                    ,itc_out_ad_e_x97.lot_id                                      -- ���b�gID
          )                                             sitc_out_ad_e_x97
         ,xxskz_vendors_v                               xvv_out_ad_e_x97          -- �d������
         ,xxskz_locations2_v                            xlc_out_ad_e_x97          -- �������擾�p
   WHERE
     --�i�ڃ}�X�^�Ƃ̌���
          sitc_out_ad_e_x97.item_id                     = ximv_out_ad_e_x97.item_id
     AND  sitc_out_ad_e_x97.tran_date                  >= ximv_out_ad_e_x97.start_date_active --�K�p�J�n��
     AND  sitc_out_ad_e_x97.tran_date                  <= ximv_out_ad_e_x97.end_date_active   --�K�p�I����
     --���b�g���擾
     AND  sitc_out_ad_e_x97.item_id                     = ilm_out_ad_e_x97.item_id
     AND  sitc_out_ad_e_x97.lot_id                      = ilm_out_ad_e_x97.lot_id
     --�ۊǏꏊ���擾
     AND  sitc_out_ad_e_x97.loct_code                   = xilv_out_ad_e_x97.segment1
     --�󕥐�(�d������)�擾
     AND  sitc_out_ad_e_x97.vendor_id                  = xvv_out_ad_e_x97.vendor_id          -- �d����ID
     AND  sitc_out_ad_e_x97.tran_date                  >= xvv_out_ad_e_x97.start_date_active --�K�p�J�n��
     AND  sitc_out_ad_e_x97.tran_date                  <= xvv_out_ad_e_x97.end_date_active   --�K�p�I����
     --�������擾
     AND  sitc_out_ad_e_x97.dept_code                   = xlc_out_ad_e_x97.location_code
     AND  sitc_out_ad_e_x97.tran_date                  >= xlc_out_ad_e_x97.start_date_active
     AND  sitc_out_ad_e_x97.tran_date                  <= xlc_out_ad_e_x97.end_date_active
  -- [ �P�O�D�����݌ɏo�Ɏ���  END ] --
UNION ALL
  -------------------------------------------------------------
  -- �P�P�D�݌ɒ��� �o�Ɏ���(��L�ȊO)
  --  ��OPM�����݌Ƀg�����U�N�V�����Ńf�[�^��������ׁA�W�v���s��
  -------------------------------------------------------------
  SELECT
          sitc_out_ad_e_xx.reason_code                  AS reason_code            -- ���R�R�[�h
         ,xilv_out_ad_e_xx.whse_code                    AS whse_code              -- �q�ɃR�[�h
         ,xilv_out_ad_e_xx.segment1                     AS location_code          -- �ۊǏꏊ�R�[�h
         ,xilv_out_ad_e_xx.description                  AS location               -- �ۊǏꏊ��
         ,xilv_out_ad_e_xx.short_name                   AS location_s_name        -- �ۊǏꏊ����
         ,ximv_out_ad_e_xx.item_id                      AS item_id                -- �i��ID
         ,ximv_out_ad_e_xx.item_no                      AS item_no                -- �i�ڃR�[�h
         ,ximv_out_ad_e_xx.item_name                    AS item_name              -- �i�ږ�
         ,ximv_out_ad_e_xx.item_short_name              AS item_short_name        -- �i�ڗ���
         ,ximv_out_ad_e_xx.num_of_cases                 AS case_content           -- �P�[�X����
         ,ximv_out_ad_e_xx.lot_ctl                      AS lot_ctl                -- ���b�g�Ǘ��敪
         ,ilm_out_ad_e_xx.lot_id                        AS lot_id                 -- ���b�gID
         ,ilm_out_ad_e_xx.lot_no                        AS lot_no                 -- ���b�gNo
         ,ilm_out_ad_e_xx.attribute1                    AS manufacture_date       -- �����N����
         ,ilm_out_ad_e_xx.attribute2                    AS uniqe_sign             -- �ŗL�L��
         ,ilm_out_ad_e_xx.attribute3                    AS expiration_date        -- �ܖ����� -- <---- �����܂ŋ���
         ,sitc_out_ad_e_xx.journal_no                   AS voucher_no             -- �`�[�ԍ�
         ,NULL                                          AS line_no                -- �s�ԍ�
         ,NULL                                          AS delivery_no            -- �z���ԍ�
         ,NULL                                          AS loct_code              -- �����R�[�h
         ,NULL                                          AS loct_name              -- ������
         ,'2'                                           AS in_out_kbn             -- ���o�ɋ敪�i2:�o�Ɂj
         ,sitc_out_ad_e_xx.tran_date                    AS leaving_date           -- ���o�ɓ�_����
         ,sitc_out_ad_e_xx.tran_date                    AS arrival_date           -- ���o�ɓ�_����
         ,sitc_out_ad_e_xx.tran_date                    AS standard_date          -- ����i�����j
         ,sitc_out_ad_e_xx.reason_code                  AS ukebaraisaki_code      -- �󕥐�R�[�h
         ,flv_out_ad_e_xx.meaning                       AS ukebaraisaki_name      -- �󕥐於
         ,'2'                                           AS status                 -- �\����ы敪�i2:���сj
         ,NULL                                          AS deliver_to_no          -- �z����R�[�h 
         ,NULL                                          AS deliver_to_name        -- �z���於 
         ,0                                             AS stock_quantity         -- ���ɐ� 
         ,sitc_out_ad_e_xx.quantity * -1                AS leaving_quantity       -- �o�ɐ�
         ,sitc_out_ad_e_xx.quantity * -1                AS quantity               -- ���o�ɐ�
    FROM
          xxskz_item_locations_v                        xilv_out_ad_e_xx          -- OPM�ۊǏꏊ���VIEW
         ,xxskz_item_mst2_v                             ximv_out_ad_e_xx          -- OPM�i�ڏ��VIEW
         ,ic_lots_mst                                   ilm_out_ad_e_xx           -- OPM���b�g�}�X�^ -- <---- �����܂ŋ���
         ,(  -- �Ώۃf�[�^���W�v
             SELECT
                     xrpm_out_ad_e_xx.new_div_invent    reason_code               -- ���R�R�[�h
                    ,ijm_out_ad_e_xx.journal_no         journal_no                -- �W���[�i��No
                    ,itc_out_ad_e_xx.location           loct_code                 -- �ۊǏꏊ�R�[�h
                    ,itc_out_ad_e_xx.trans_date         tran_date                 -- �����
                    ,itc_out_ad_e_xx.item_id            item_id                   -- �i��ID
                    ,itc_out_ad_e_xx.lot_id             lot_id                    -- ���b�gID
                    ,SUM( itc_out_ad_e_xx.trans_qty )   quantity                  -- ���o�ɐ��i�W�v�l�j
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_out_ad_e_xx          -- �󕥋敪�A�h�I���}�X�^
                    ,ic_adjs_jnl                        iaj_out_ad_e_xx           -- OPM�݌ɒ����W���[�i��
                    ,ic_jrnl_mst                        ijm_out_ad_e_xx           -- OPM�W���[�i���}�X�^
                    ,xxcmn_ic_tran_cmp_arc              itc_out_ad_e_xx           -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
              WHERE
                --�󕥋敪�A�h�I���}�X�^�̏���
                     xrpm_out_ad_e_xx.doc_type          = 'ADJI'
                AND  xrpm_out_ad_e_xx.reason_code      <> 'X977'                  -- �����݌�
                AND  xrpm_out_ad_e_xx.reason_code      <> 'X123'                  -- �ړ����ђ����i���Ɂj
                AND  xrpm_out_ad_e_xx.rcv_pay_div       = '-1'                    -- ���o
                AND  xrpm_out_ad_e_xx.use_div_invent    = 'Y'
                --�����݌Ƀg�����U�N�V�����̏���
                AND  itc_out_ad_e_xx.doc_type           = xrpm_out_ad_e_xx.doc_type
                AND  itc_out_ad_e_xx.reason_code        = xrpm_out_ad_e_xx.reason_code
                --�݌ɒ����W���[�i���̎擾
                AND  itc_out_ad_e_xx.doc_type           = iaj_out_ad_e_xx.trans_type
                AND  itc_out_ad_e_xx.doc_id             = iaj_out_ad_e_xx.doc_id
                AND  itc_out_ad_e_xx.doc_line           = iaj_out_ad_e_xx.doc_line
                --�W���[�i���}�X�^�̎擾
                AND  iaj_out_ad_e_xx.journal_id         = ijm_out_ad_e_xx.journal_id
             GROUP BY
                     xrpm_out_ad_e_xx.new_div_invent                              -- ���R�R�[�h
                    ,ijm_out_ad_e_xx.journal_no                                   -- �W���[�i��No
                    ,itc_out_ad_e_xx.location                                     -- �ۊǏꏊ�R�[�h
                    ,itc_out_ad_e_xx.trans_date                                   -- �����
                    ,itc_out_ad_e_xx.item_id                                      -- �i��ID
                    ,itc_out_ad_e_xx.lot_id                                       -- ���b�gID
          )                                             sitc_out_ad_e_xx
         ,fnd_lookup_values                             flv_out_ad_e_xx           -- �N�C�b�N�R�[�h(�󕥐於�擾�p)
   WHERE
     --�i�ڃ}�X�^(�o�וi��)�Ƃ̌���
          sitc_out_ad_e_xx.item_id                      = ximv_out_ad_e_xx.item_id
     AND  sitc_out_ad_e_xx.tran_date                   >= ximv_out_ad_e_xx.start_date_active --�K�p�J�n��
     AND  sitc_out_ad_e_xx.tran_date                   <= ximv_out_ad_e_xx.end_date_active   --�K�p�I����
     --���b�g���擾
     AND  sitc_out_ad_e_xx.item_id                      = ilm_out_ad_e_xx.item_id
     AND  sitc_out_ad_e_xx.lot_id                       = ilm_out_ad_e_xx.lot_id
     --�ۊǏꏊ���擾
     AND  sitc_out_ad_e_xx.loct_code                    = xilv_out_ad_e_xx.segment1
     --�󕥐���擾
     AND  flv_out_ad_e_xx.lookup_type                   = 'XXCMN_NEW_DIVISION'
     AND  flv_out_ad_e_xx.language                      = 'JA'
     AND  flv_out_ad_e_xx.lookup_code                   = sitc_out_ad_e_xx.reason_code
  -- [ �P�P�D�݌ɒ��� �o�Ɏ���(��L�ȊO)  END ] --
-- << �o�Ɏ��� END >>
/
COMMENT ON TABLE APPS.XXSKZ_INOUT_TRANS_V IS 'XXSKZ_���o�ɏ��_����VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.reason_code       IS '���R�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.whse_code         IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.location_code     IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.location          IS '�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.location_s_name   IS '�ۊǏꏊ����'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.item_id           IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.item_no           IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.item_name         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.item_short_name   IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.case_content      IS '�P�[�X����'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.lot_ctl           IS '���b�g�Ǘ��敪'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.lot_no            IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.lot_id            IS '���b�gID'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.manufacture_date  IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.uniqe_sign        IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.expiration_date   IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.voucher_no        IS '�`�[�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.line_no           IS '�s�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.delivery_no       IS '�z���ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.loct_code         IS '�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.loct_name         IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.in_out_kbn        IS '���o�ɋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.leaving_date      IS '���o�ɓ�_����'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.arrival_date      IS '���o�ɓ�_����'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.standard_date     IS '���'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.ukebaraisaki_code IS '�󕥐�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.ukebaraisaki_name IS '�󕥐於'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.status            IS '�\����ы敪'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.deliver_to_no     IS '�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.deliver_to_name   IS '�z���於'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.stock_quantity    IS '���ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.leaving_quantity  IS '�o�ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.quantity          IS '���o�ɐ�'
/
