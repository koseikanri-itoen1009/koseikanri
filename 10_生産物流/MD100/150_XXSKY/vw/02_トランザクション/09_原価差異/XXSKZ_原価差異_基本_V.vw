/*************************************************************************
 * 
 * View  Name      : XXSKZ_��������_��{_V
 * Description     : XXSKZ_��������_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_��������_��{_V
(
 �Ώ۔N��
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�����R�[�h
,����於
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���
,��ږ���
,����
,���ږ���
,���Ԑ���
,���ԃP�[�X����
,���ԋ��z
,�W�����z
)
AS
SELECT
        XRART.txns_date_ym                                            -- �Ώ۔N��
       ,XPCV.prod_class_code                                          -- ���i�敪
       ,XPCV.prod_class_name                                          -- ���i�敪��
       ,XICV.item_class_code                                          -- �i�ڋ敪
       ,XICV.item_class_name                                          -- �i�ڋ敪��
       ,XCCV.crowd_code                                               -- �Q�R�[�h
       ,XVV.segment1                                                  -- �����R�[�h
       ,XVV.vendor_name                                               -- ����於
       ,XIMV.item_no                                                  -- �i�ڃR�[�h
       ,XIMV.item_name                                                -- �i�ږ�
       ,XIMV.item_short_name                                          -- �i�ڗ���
       ,SMPR.expense_type                                             -- ���
       ,FLV01.meaning                                                 -- ��ږ���
       ,SMPR.expense_d_type                                           -- ����
       ,FLV02.meaning                                                 -- ���ږ���
       ,NVL( XRART.sum_quantity  , 0 )                                -- ���Ԑ���
       ,NVL( XRART.sum_quantity / XIMV.num_of_cases, 0 )              -- ���ԃP�[�X����
       ,NVL( SMPR.sum_month_kin  , 0 )                                -- ���ԋ��z
       ,NVL( SMPR.sum_hyoujun_kin, 0 )                                -- �W�����z
  FROM
        (  -- ==============================================================================
           -- �@�Ώ۔N���A�i��ID�A�����ID�ŏW�v�������Ԑ��ʃf�[�^
           -- ==============================================================================
           SELECT  TO_CHAR(txns_date, 'YYYYMM')       txns_date_ym    -- �Ώ۔N��
                  ,item_id                            item_id         -- �i��ID
                  ,vendor_id                          vendor_id       -- �����ID
                  ,SUM( CASE WHEN txns_type IN ('2','3') THEN quantity * -1  -- �ԕi�̓}�C�i�X�v��
                             ELSE                             quantity
                        END
                   )                                  sum_quantity    -- ���Ԑ���
             FROM  xxpo_rcv_and_rtn_txns                              -- ����ԕi���уA�h�I��
           GROUP BY TO_CHAR(txns_date, 'YYYYMM')
                   ,item_id
                   ,vendor_id
        )  XRART
       ,(  -- ==============================================================================
           -- �A�Ώ۔N���A�i��ID�A�����ID�A��ځA���ڂŏW�v�������ԋ��z�{�W�����z�f�[�^
           -- ==============================================================================
           SELECT  PRICE.txns_date_ym                               txns_date_ym    -- �Ώ۔N��
                  ,PRICE.item_id                                    item_id         -- �i��ID
                  ,PRICE.vendor_id                                  vendor_id       -- �����ID
                  ,PRICE.expense_type                               expense_type    -- ���
                  ,PRICE.expense_d_type                             expense_d_type  -- ����
                  ,SUM( PRICE.month_kin   )                         sum_month_kin   -- ���ԋ��z
                  ,SUM( PRICE.hyoujun_kin )                         sum_hyoujun_kin -- �W�����z
             FROM  (  -------------------------------------------------------------------------------
                      -- �Ώ۔N���A�i��ID�A�����ID�A��ځA���ڂŏW�v�������ԋ��z�W�v�f�[�^�y���̂P�z
                      --   ����������E��������ԕi�̏ꍇ�͔����w�b�_�̍��ڂŎd���P���w�b�_�ƌ�������
                      -------------------------------------------------------------------------------
                      SELECT  TO_CHAR( XRARTS.txns_date, 'YYYYMM' )  txns_date_ym    -- �Ώ۔N��
                             ,XRARTS.item_id                         item_id         -- �i��ID
                             ,XRARTS.vendor_id                       vendor_id       -- �����ID
                             ,XPLS.expense_item_type                 expense_type    -- ���
                             ,XPLS.expense_item_detail_type          expense_d_type  -- ����
                             ,ROUND( SUM( CASE WHEN txns_type = '2' THEN (XRARTS.quantity * XPLS.unit_price) * -1
                                               ELSE                       XRARTS.quantity * XPLS.unit_price
                                          END )
                                   )                                 month_kin       -- ���ԋ��z
                             ,0                                      hyoujun_kin     -- �W�����z
                        FROM  xxpo_rcv_and_rtn_txns                  XRARTS          -- ����ԕi���уA�h�I��
                             ,po_headers_all                         PHA             -- �����w�b�_
                             ,po_lines_all                           PLA             -- ��������
                             ,xxpo_price_headers                     XPHS            -- �d��/�W���P���w�b�_�i�d���j
                             ,xxpo_price_lines                       XPLS            -- �d��/�W���P�����ׁi�d���j
                       WHERE
                         -- ����������������ԕi�f�[�^�̒��o����
                              XRARTS.txns_type IN ( '1', '2' )
                         -- �����f�[�^�Ƃ̌���
                         AND  NVL( PLA.attribute13, 'N' )  = 'Y'                     --������
                         AND  NVL( PLA.cancel_flag, 'N' ) <> 'Y'                     --�L�����Z���ȊO
                         AND  PHA.po_header_id = PLA.po_header_id
                         AND  XRARTS.source_document_number = PHA.segment1
                         AND  XRARTS.source_document_line_num = PLA.line_num
                         -- �d���P���w�b�_�Ƃ̌����i�i�ځA�����A�t�сA�H��P�ʂŎd���P�����擾�j
                         AND  XRARTS.item_id = XPHS.item_id                          -- �i��
                         AND  PLA.attribute3 = XPHS.futai_code                       -- �t��(�������ׂ̂��̂Ō���)
                         AND  XRARTS.vendor_id = XPHS.vendor_id                      -- �����
                         AND  PLA.attribute2 = XPHS.factory_code                     -- �H��(�������ׂ̂��̂Ō���)
                         AND  XRARTS.txns_date >= XPHS.start_date_active
                         AND  XRARTS.txns_date <= XPHS.end_date_active
                         -- �d���P�����ׂƂ̌���
                         AND  XPHS.price_type = '1'                                  -- �}�X�^�敪�F�d���P��
                         AND  XPHS.price_header_id = XPLS.price_header_id
                      GROUP BY TO_CHAR( XRARTS.txns_date, 'YYYYMM' )
                              ,XRARTS.item_id
                              ,XRARTS.vendor_id
                              ,XPLS.expense_item_type
                              ,XPLS.expense_item_detail_type
                    UNION ALL
                      -------------------------------------------------------------------------------
                      -- �Ώ۔N���A�i��ID�A�����ID�A��ځA���ڂŏW�v�������ԋ��z�W�v�f�[�^�y���̂Q�z
                      --   �������Ȃ��ԕi�̏ꍇ�͎���ԕi�A�h�I���̍��ڂŎd���P���w�b�_�ƌ�������
                      -------------------------------------------------------------------------------
                      SELECT  TO_CHAR( XRARTS.txns_date, 'YYYYMM' )  txns_date_ym    -- �Ώ۔N��
                             ,XRARTS.item_id                         item_id         -- �i��ID
                             ,XRARTS.vendor_id                       vendor_id       -- �����ID
                             ,XPLS.expense_item_type                 expense_type    -- ���
                             ,XPLS.expense_item_detail_type          expense_d_type  -- ����
                             ,ROUND( SUM( (XRARTS.quantity * XPLS.unit_price) * -1 ) )
                                                                     month_kin       -- ���ԋ��z
                             ,0                                      hyoujun_kin     -- �W�����z
                        FROM  xxpo_rcv_and_rtn_txns                  XRARTS          -- ����ԕi���уA�h�I��
                             ,xxpo_price_headers                     XPHS            -- �d��/�W���P���w�b�_�i�d���j
                             ,xxpo_price_lines                       XPLS            -- �d��/�W���P�����ׁi�d���j
                       WHERE
                         -- �����Ȃ�����ԕi�f�[�^�̒��o����
                              XRARTS.txns_type = '3'
                         -- �d���P���w�b�_�Ƃ̌����i�i�ځA�����A�t�сA�H��P�ʂŎd���P�����擾�j
                         AND  XRARTS.item_id = XPHS.item_id                          -- �i��
                         AND  XRARTS.futai_code = XPHS.futai_code                    -- �t��
                         AND  XRARTS.vendor_id = XPHS.vendor_id                      -- �����
                         AND  XRARTS.factory_id = XPHS.factory_id                    -- �H��
                         AND  XRARTS.txns_date >= XPHS.start_date_active
                         AND  XRARTS.txns_date <= XPHS.end_date_active
                         -- �d���P�����ׂƂ̌���
                         AND  XPHS.price_type = '1'                                  -- �}�X�^�敪�F�d���P��
                         AND  XPHS.price_header_id = XPLS.price_header_id
                      GROUP BY TO_CHAR( XRARTS.txns_date, 'YYYYMM' )
                              ,XRARTS.item_id
                              ,XRARTS.vendor_id
                              ,XPLS.expense_item_type
                              ,XPLS.expense_item_detail_type
                    UNION ALL
                      -------------------------------------------------------------------------------
                      -- �Ώ۔N���A�i��ID�A�����ID�A��ځA���ڂŏW�v�����W�����z�W�v�f�[�^
                      -------------------------------------------------------------------------------
                      SELECT  TO_CHAR( XRARTS.txns_date, 'YYYYMM' )  txns_date_ym    -- �Ώ۔N��
                             ,XRARTS.item_id                         item_id         -- �i��ID
                             ,XRARTS.vendor_id                       vendor_id       -- �����ID
                             ,XPLS.expense_item_type                 expense_type    -- ���
                             ,XPLS.expense_item_detail_type          expense_d_type  -- ����
                             ,0                                      month_kin       -- ���ԋ��z
                             ,ROUND( SUM( CASE WHEN txns_type IN ('2','3') THEN (XRARTS.quantity * XPLS.unit_price) * -1
                                               ELSE                              XRARTS.quantity * XPLS.unit_price
                                          END )
                                   )                                 hyoujun_kin     -- �W�����z
                        FROM  xxpo_rcv_and_rtn_txns                  XRARTS          -- ����ԕi���уA�h�I��
                             ,xxpo_price_headers                     XPHS            -- �d��/�W���P���w�b�_�i�W���j
                             ,xxpo_price_lines                       XPLS            -- �d��/�W���P�����ׁi�W���j
                       WHERE
                         -- �W���P���w�b�_�Ƃ̌����i�i�ڒP�ʂŕW���P�����擾�j
                              XRARTS.item_id = XPHS.item_id                          -- �i��
                         AND  XRARTS.txns_date >= XPHS.start_date_active
                         AND  XRARTS.txns_date <= XPHS.end_date_active
                         -- �W���P�����ׂƂ̌���
                         AND  XPHS.price_type = '2'                                  -- �}�X�^�敪�F�W���P��
                         AND  XPHS.price_header_id = XPLS.price_header_id
                      GROUP BY TO_CHAR( XRARTS.txns_date, 'YYYYMM' )
                              ,XRARTS.item_id
                              ,XRARTS.vendor_id
                              ,XPLS.expense_item_type
                              ,XPLS.expense_item_detail_type
                   )  PRICE
           GROUP BY PRICE.txns_date_ym
                   ,PRICE.item_id
                   ,PRICE.vendor_id
                   ,PRICE.expense_type
                   ,PRICE.expense_d_type
        )  SMPR
       ,xxskz_prod_class_v    XPCV                             -- ���i�敪�擾�p
       ,xxskz_item_class_v    XICV                             -- �i�ڋ敪�擾�p
       ,xxskz_crowd_code_v    XCCV                             -- �Q�R�[�h
       ,xxskz_item_mst2_v     XIMV                             -- �i�ږ��擾�p
       ,xxskz_vendors2_v      XVV                              -- ����於�擾�p
       ,fnd_lookup_values     FLV01                            -- ��ږ��̎擾�p
       ,fnd_lookup_values     FLV02                            -- ���ږ��̎擾�p
 WHERE
   -- �@�ƇA�̌���
        XRART.txns_date_ym = SMPR.txns_date_ym
   AND  XRART.item_id      = SMPR.item_id
   AND  XRART.vendor_id    = SMPR.vendor_id
   -- �x����ԕi�Ƃ̏W�v�ɂ�茎�Ԑ��ʂ��[���ƂȂ����f�[�^�͏o�͂��Ȃ�
   AND  XRART.sum_quantity <> 0
   -- ���i�敪���擾
   AND  XRART.item_id = XPCV.item_id(+)
   -- �i�ڋ敪���擾
   AND  XRART.item_id = XICV.item_id(+)
   -- �Q�R�[�h�擾
   AND  XRART.item_id = XCCV.item_id(+)
   -- �i�ڏ��擾
   AND  XRART.item_id = XIMV.item_id(+)
   AND  TRUNC( LAST_DAY( TO_DATE( XRART.txns_date_ym || '01', 'YYYYMMDD' ) ) ) >= XIMV.start_date_active
   AND  TRUNC( LAST_DAY( TO_DATE( XRART.txns_date_ym || '01', 'YYYYMMDD' ) ) ) <= XIMV.end_date_active
   -- ����於�擾
   AND  XRART.vendor_id = XVV.vendor_id(+)
   AND  TRUNC( LAST_DAY( TO_DATE( XRART.txns_date_ym || '01', 'YYYYMMDD' ) ) ) >= XVV.start_date_active
   AND  TRUNC( LAST_DAY( TO_DATE( XRART.txns_date_ym || '01', 'YYYYMMDD' ) ) ) <= XVV.end_date_active
   -- ��ږ��̎擾
   AND  FLV01.language(+)    = 'JA'                                  --����
   AND  FLV01.lookup_type(+) = 'XXPO_EXPENSE_ITEM_TYPE'              --�N�C�b�N�R�[�h�^�C�v
   AND  SMPR.expense_type    = FLV01.attribute1(+)                   --�N�C�b�N�R�[�h
   -- ���ږ��̎擾
   AND  FLV02.language(+)    = 'JA'                                  --����
   AND  FLV02.lookup_type(+) = 'XXPO_EXPENSE_ITEM_DETAIL_TYPE'       --�N�C�b�N�R�[�h�^�C�v
   AND  SMPR.expense_d_type  = FLV02.attribute1(+)                   --�N�C�b�N�R�[�h
/
COMMENT ON TABLE APPS.XXSKZ_��������_��{_V IS 'SKYLINK�p�������ي�{VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.�Ώ۔N��       IS '�Ώ۔N��'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.���i�敪       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.���i�敪��     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.�i�ڋ敪       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.�i�ڋ敪��     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.�Q�R�[�h       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.�����R�[�h   IS '�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.����於       IS '����於'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.�i�ڃR�[�h     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.�i�ږ�         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.�i�ڗ���       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.���           IS '���'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.��ږ���       IS '��ږ���'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.����           IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.���ږ���       IS '���ږ���'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.���Ԑ���       IS '���Ԑ���'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.���ԃP�[�X���� IS '���ԃP�[�X����'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.���ԋ��z       IS '���ԋ��z'
/
COMMENT ON COLUMN APPS.XXSKZ_��������_��{_V.�W�����z       IS '�W�����z'
/