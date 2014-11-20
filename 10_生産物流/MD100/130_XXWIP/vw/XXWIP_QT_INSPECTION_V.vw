CREATE OR REPLACE VIEW apps.xxwip_qt_inspection_v
(
  row_id
, qt_inspect_req_no               -- �����˗�No
, vendor_line                     -- �d����R�[�h/���C��No
, vendor_line_name                -- �d����/���C������
, item_id                         -- �i��ID
, item_no                         -- �i�ڃR�[�h
, item_name                       -- �i�ږ���
, lot_id                          -- ���b�gID
, lot_no                          -- ���b�gNo
, product_date                    -- ������
, unique_sign                     -- �ŗL�L��
, use_by_date                     -- �ܖ�����
, qt_effect1                      -- ���ʂP
, qt_effect1_desc                 -- ���ʂP����
, inspect_due_date1               -- �����\����P
, test_date1                      -- �������P
, qt_effect2                      -- ���ʂQ
, qt_effect2_desc                 -- ���ʂQ����
, inspect_due_date2               -- �����\����Q
, test_date2                      -- �������Q
, qt_effect3                      -- ���ʂR
, qt_effect3_desc                 -- ���ʂR����
, inspect_due_date3               -- �����\����R
, test_date3                      -- �������R
, remarks_column                  -- ���l
, qty                             -- ����
, inspection_times                -- ������
, order_times                     -- ������
, inspect_period                  -- ��������
, inspect_class                   -- �������
, prod_dely_date                  -- ���Y/�[����
, division                        -- �敪
, batch_po_id                     -- �ԍ�
, created_by                      -- �쐬��
, creation_date                   -- �쐬��
, last_updated_by                 -- �ŏI�X�V��
, last_update_date                -- �ŏI�X�V��
, last_update_login               -- �ŏI�X�V���O�C��
, request_id                      -- �v��ID
, program_application_id          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
, program_id                      -- �R���J�����g�E�v���O����ID
, program_update_date             -- �v���O�����X�V��
, lot_last_update_date            -- ���b�g�}�X�^�ŏI�X�V��
)
AS
  SELECT
    xqi.rowid                           row_id
  , xqi.qt_inspect_req_no               qt_inspect_req_no               -- �����˗�No
  , xqi.vendor_line                     vendor_line                     -- �d����R�[�h/���C��No
  , grv.attribute1                      vendor_line_name                -- �d����/���C������
  , xqi.item_id                         item_id                         -- �i��ID
  , xim2v.item_no                       item_no                         -- �i�ڃR�[�h
  , xim2v.item_short_name               item_name                       -- �i�ږ���
  , xqi.lot_id                          lot_id                          -- ���b�gID
  , ilm.lot_no                          lot_no                          -- ���b�gNo
-- 2008/07/24 H.Itou MOD START
--  , xqi.product_date                    product_date                    -- ������
--  , xqi.unique_sign                     unique_sign                     -- �ŗL�L��
--  , xqi.use_by_date                     use_by_date                     -- �ܖ�����
  , FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                        product_date                    -- ������
  , ilm.attribute2                      unique_sign                     -- �ŗL�L��
  , FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                        use_by_date                     -- �ܖ�����
-- 2008/07/24 H.Itou MOD END
  , xqi.qt_effect1                      qt_effect1                      -- ���ʂP
  , xlvv1.meaning                       qt_effect1_desc                 -- ���ʂP����
  , xqi.inspect_due_date1               inspect_due_date1               -- �����\����P
  , xqi.test_date1                      test_date1                      -- �������P
  , xqi.qt_effect2                      qt_effect2                      -- ���ʂQ
  , xlvv2.meaning                       qt_effect2_desc                 -- ���ʂQ����
  , xqi.inspect_due_date2               inspect_due_date2               -- �����\����Q
  , xqi.test_date2                      test_date2                      -- �������Q
  , xqi.qt_effect3                      qt_effect3                      -- ���ʂR
  , xlvv3.meaning                       qt_effect3_desc                 -- ���ʂR����
  , xqi.inspect_due_date3               inspect_due_date3               -- �����\����R
  , xqi.test_date3                      test_date3                      -- �������R
  , ilm.attribute18                     remarks_column                  -- ���l
  , xqi.qty                             qty                             -- ����
  , xim2v.judge_times                   inspection_times                -- ������
  , xim2v.order_judge_times             order_times                     -- ������
  , xqi.inspect_period                  inspect_period                  -- ��������
  , xqi.inspect_class                   inspect_class                   -- �������
  , xqi.prod_dely_date                  prod_dely_date                  -- ���Y/�[����
  , xqi.division                        division                        -- �敪
  , xqi.batch_po_id                     batch_po_id                     -- �ԍ�
  , xqi.created_by                      created_by                      -- �쐬��
  , xqi.creation_date                   creation_date                   -- �쐬��
  , xqi.last_updated_by                 last_updated_by                 -- �ŏI�X�V��
  , xqi.last_update_date                last_update_date                -- �ŏI�X�V��
  , xqi.last_update_login               last_update_login               -- �ŏI�X�V���O�C��
  , xqi.request_id                      request_id                      -- �v��ID
  , xqi.program_application_id          program_application_id          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  , xqi.program_id                      program_id                      -- �R���J�����g�E�v���O����ID
  , xqi.program_update_date             program_update_date             -- �v���O�����X�V��
  , ilm.last_update_date                lot_last_update_date            -- ���b�g�}�X�^�ŏI�X�V��
  FROM
    xxcmn_lookup_values_v           xlvv1
  , xxcmn_lookup_values_v           xlvv2
  , xxcmn_lookup_values_v           xlvv3
  , gmd_routings_vl                 grv     -- �H��VIEW
  , xxcmn_item_mst2_v               xim2v   -- �i��
  , ic_lots_mst                     ilm     -- ���b�g
  , xxwip_qt_inspection             xqi     -- �i�������˗�
  WHERE xlvv1.lookup_code (+)        = xqi.qt_effect1 
    AND xlvv1.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND xlvv2.lookup_code (+)        = xqi.qt_effect2
    AND xlvv2.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND xlvv3.lookup_code (+)        = xqi.qt_effect3
    AND xlvv3.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND grv.routing_no (+)           = xqi.vendor_line
    AND xim2v.item_id                = xqi.item_id
-- 2008/07/24 H.Itou MOD START
--    AND xim2v.start_date_active      <= TRUNC( xqi.product_date )
--    AND xim2v.end_date_active        >= TRUNC( xqi.product_date )
    AND xim2v.start_date_active      <= TRUNC( NVL( xqi.product_date, SYSDATE ) )
    AND xim2v.end_date_active        >= TRUNC( NVL( xqi.product_date, SYSDATE ) )
-- 2008/07/24 H.Itou MOD END
    AND ilm.lot_id                   = xqi.lot_id
    AND xqi.inspect_class            = '1'
--
  UNION ALL
--
  SELECT
    xqi.rowid                           row_id
  , xqi.qt_inspect_req_no               qt_inspect_req_no               -- �����˗�No
  , xqi.vendor_line                     vendor_line                     -- �d����R�[�h/���C��No
  , xv.vendor_short_name                vendor_line_name                -- �d����/���C������
  , xqi.item_id                         item_id                         -- �i��ID
  , xim2v.item_no                       item_no                         -- �i�ڃR�[�h
  , xim2v.item_short_name               item_name                       -- �i�ږ���
  , xqi.lot_id                          lot_id                          -- ���b�gID
  , ilm.lot_no                          lot_no                          -- ���b�gNo
-- 2008/07/24 H.Itou MOD START
--  , xqi.product_date                    product_date                    -- ������
--  , xqi.unique_sign                     unique_sign                     -- �ŗL�L��
--  , xqi.use_by_date                     use_by_date                     -- �ܖ�����
  , FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                        product_date                    -- ������
  , ilm.attribute2                      unique_sign                     -- �ŗL�L��
  , FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                        use_by_date                     -- �ܖ�����
-- 2008/07/24 H.Itou MOD END
  , xqi.qt_effect1                      qt_effect1                      -- ���ʂP
  , xlvv1.meaning                       qt_effect1_desc                 -- ���ʂP����
  , xqi.inspect_due_date1               inspect_due_date1               -- �����\����P
  , xqi.test_date1                      test_date1                      -- �������P
  , xqi.qt_effect2                      qt_effect2                      -- ���ʂQ
  , xlvv2.meaning                       qt_effect2_desc                 -- ���ʂQ����
  , xqi.inspect_due_date2               inspect_due_date2               -- �����\����Q
  , xqi.test_date2                      test_date2                      -- �������Q
  , xqi.qt_effect3                      qt_effect3                      -- ���ʂR
  , xlvv3.meaning                       qt_effect3_desc                 -- ���ʂR����
  , xqi.inspect_due_date3               inspect_due_date3               -- �����\����R
  , xqi.test_date3                      test_date3                      -- �������R
  , ilm.attribute18                     remarks_column                  -- ���l
  , xqi.qty                             qty                             -- ����
  , xim2v.judge_times                   inspection_times                -- ������
  , xim2v.order_judge_times             order_times                     -- ������
  , xqi.inspect_period                  inspect_period                  -- ��������
  , xqi.inspect_class                   inspect_class                   -- �������
  , xqi.prod_dely_date                  prod_dely_date                  -- ���Y/�[����
  , xqi.division                        division                        -- �敪
  , xqi.batch_po_id                     batch_po_id                     -- �ԍ�
  , xqi.created_by                      created_by                      -- �쐬��
  , xqi.creation_date                   creation_date                   -- �쐬��
  , xqi.last_updated_by                 last_updated_by                 -- �ŏI�X�V��
  , xqi.last_update_date                last_update_date                -- �ŏI�X�V��
  , xqi.last_update_login               last_update_login               -- �ŏI�X�V���O�C��
  , xqi.request_id                      request_id                      -- �v��ID
  , xqi.program_application_id          program_application_id          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  , xqi.program_id                      program_id                      -- �R���J�����g�E�v���O����ID
  , xqi.program_update_date             program_update_date             -- �v���O�����X�V��
  , ilm.last_update_date                lot_last_update_date            -- ���b�g�}�X�^�ŏI�X�V��
  FROM
    xxcmn_lookup_values_v           xlvv1
  , xxcmn_lookup_values_v           xlvv2
  , xxcmn_lookup_values_v           xlvv3
  , xxcmn_vendors                   xv      -- �d����A�h�I���}�X�^
  , xxcmn_vendors2_v                xv2v    -- �d����}�X�^VIEW
  , xxcmn_item_mst2_v               xim2v   -- �i��
  , ic_lots_mst                     ilm     -- ���b�g
  , xxwip_qt_inspection             xqi     -- �i�������˗�
  WHERE xlvv1.lookup_code (+)        = xqi.qt_effect1 
    AND xlvv1.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND xlvv2.lookup_code (+)        = xqi.qt_effect2
    AND xlvv2.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND xlvv3.lookup_code (+)        = xqi.qt_effect3
    AND xlvv3.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND xv.vendor_id (+)             = xv2v.vendor_id
    AND (
             ( xv.vendor_id IS NULL )
          OR ( xv.start_date_active = (
                 SELECT MAX( xv2.start_date_active )
                 FROM xxcmn_vendors  xv2
                 WHERE xv2.vendor_id (+) = xv2v.vendor_id
               )
             )
        )
    AND xv2v.segment1 (+)            = xqi.vendor_line
-- �ύX START 2008/04/25 Oikawa
-- 2008/07/24 H.Itou MOD START
--    AND xv2v.start_date_active (+)   <= TRUNC( xqi.product_date )
--    AND xv2v.end_date_active (+)     >= TRUNC( xqi.product_date )
    AND xv2v.start_date_active (+)   <= TRUNC( NVL( xqi.product_date, SYSDATE ) )
    AND xv2v.end_date_active (+)     >= TRUNC( NVL( xqi.product_date, SYSDATE ) )
-- 2008/07/24 H.Itou MOD END
--    AND xv2v.start_date_active       <= TRUNC( xqi.product_date )
--    AND xv2v.end_date_active         >= TRUNC( xqi.product_date )
-- �ύX END
    AND xim2v.item_id                = xqi.item_id
-- 2008/07/24 H.Itou MOD START
--    AND xim2v.start_date_active      <= TRUNC( xqi.product_date )
--    AND xim2v.end_date_active        >= TRUNC( xqi.product_date )
    AND xim2v.start_date_active      <= TRUNC( NVL( xqi.product_date, SYSDATE ) )
    AND xim2v.end_date_active        >= TRUNC( NVL( xqi.product_date, SYSDATE ) )
-- 2008/07/24 H.Itou MOD END
    AND ilm.lot_id                   = xqi.lot_id
    AND xqi.inspect_class            = '2'
/
