CREATE OR REPLACE VIEW APPS.XXSKY_�d���L�����n��_����_V
(
 �N�x
,����
,������
,�����
,����於
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�d���`��
,�d���`�Ԗ�
,�d������_�T��
,�L������_�T��
,�d������_�U��
,�L������_�U��
,�d������_�V��
,�L������_�V��
,�d������_�W��
,�L������_�W��
,�d������_�X��
,�L������_�X��
,�d������_�P�O��
,�L������_�P�O��
,�d������_�P�P��
,�L������_�P�P��
,�d������_�P�Q��
,�L������_�P�Q��
,�d������_�P��
,�L������_�P��
,�d������_�Q��
,�L������_�Q��
,�d������_�R��
,�L������_�R��
,�d������_�S��
,�L������_�S��
)
AS
SELECT  SMRP.year                         year                   --�N�x
       ,SMRP.dept_code                    dept_code              --�����R�[�h
       ,LOCT.location_name                dept_name              --������
       ,VNDR.segment1                     vndr_code              --�����R�[�h
       ,VNDR.vendor_name                  vndr_name              --����於
       ,PRODC.prod_class_code             prod_class_code        --���i�敪
       ,PRODC.prod_class_name             prod_class_name        --���i�敪��
       ,ITEMC.item_class_code             item_class_code        --�i�ڋ敪
       ,ITEMC.item_class_name             item_class_name        --�i�ڋ敪��
       ,CROWD.crowd_code                  crowd_code             --�Q�R�[�h
       ,SMRP.item_code                    item_code              --�i��
       ,ITEM.item_name                    item_name              --�i�ږ�
       ,ITEM.item_short_name              item_s_name            --�i�ڗ���
       ,SMRP.rcv_class                    rcv_class              --�d���`��
       ,FLV03.meaning                     rcv_name               --�d���`�Ԗ�
       ,NVL( SMRP.rcv_qty_5th , 0 )       rcv_qty_5th            --�d������_�T��
       ,NVL( SMRP.pay_qty_5th , 0 )       pay_qty_5th            --�L������_�T��
       ,NVL( SMRP.rcv_qty_6th , 0 )       rcv_qty_6th            --�d������_�U��
       ,NVL( SMRP.pay_qty_6th , 0 )       pay_qty_6th            --�L������_�U��
       ,NVL( SMRP.rcv_qty_7th , 0 )       rcv_qty_7th            --�d������_�V��
       ,NVL( SMRP.pay_qty_7th , 0 )       pay_qty_7th            --�L������_�V��
       ,NVL( SMRP.rcv_qty_8th , 0 )       rcv_qty_8th            --�d������_�W��
       ,NVL( SMRP.pay_qty_8th , 0 )       pay_qty_8th            --�L������_�W��
       ,NVL( SMRP.rcv_qty_9th , 0 )       rcv_qty_9th            --�d������_�X��
       ,NVL( SMRP.pay_qty_9th , 0 )       pay_qty_9th            --�L������_�X��
       ,NVL( SMRP.rcv_qty_10th, 0 )       rcv_qty_10th           --�d������_�P�O��
       ,NVL( SMRP.pay_qty_10th, 0 )       pay_qty_10th           --�L������_�P�O��
       ,NVL( SMRP.rcv_qty_11th, 0 )       rcv_qty_11th           --�d������_�P�P��
       ,NVL( SMRP.pay_qty_11th, 0 )       pay_qty_11th           --�L������_�P�P��
       ,NVL( SMRP.rcv_qty_12th, 0 )       rcv_qty_12th           --�d������_�P�Q��
       ,NVL( SMRP.pay_qty_12th, 0 )       pay_qty_12th           --�L������_�P�Q��
       ,NVL( SMRP.rcv_qty_1th , 0 )       rcv_qty_1th            --�d������_�P��
       ,NVL( SMRP.pay_qty_1th , 0 )       pay_qty_1th            --�L������_�P��
       ,NVL( SMRP.rcv_qty_2th , 0 )       rcv_qty_2th            --�d������_�Q��
       ,NVL( SMRP.pay_qty_2th , 0 )       pay_qty_2th            --�L������_�Q��
       ,NVL( SMRP.rcv_qty_3th , 0 )       rcv_qty_3th            --�d������_�R��
       ,NVL( SMRP.pay_qty_3th , 0 )       pay_qty_3th            --�L������_�R��
       ,NVL( SMRP.rcv_qty_4th , 0 )       rcv_qty_4th            --�d������_�S��
       ,NVL( SMRP.pay_qty_4th , 0 )       pay_qty_4th            --�L������_�S��
  FROM  (  --�N�x�A�����A�����A�i�ځA�d���`�ԒP�ʂŏW�v�����i���x�W�v�����ɂ����j�d���L���W�v�f�[�^
           SELECT  ICD.fiscal_year                                            year             --�N�x
                  ,RVPY.dept_code                                             dept_code        --�����R�[�h
                  ,RVPY.vendor_id                                             vendor_id        --�����ID
                  ,RVPY.item_code                                             item_code        --�i��
                  ,RVPY.rcv_class                                             rcv_class        --�d���`��
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.rcv_qty    END )  rcv_qty_5th      --�d������_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.pay_qty    END )  pay_qty_5th      --�L������_�T��
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.rcv_qty    END )  rcv_qty_6th      --�d������_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.pay_qty    END )  pay_qty_6th      --�L������_�U��
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.rcv_qty    END )  rcv_qty_7th      --�d������_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.pay_qty    END )  pay_qty_7th      --�L������_�V��
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.rcv_qty    END )  rcv_qty_8th      --�d������_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.pay_qty    END )  pay_qty_8th      --�L������_�W��
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.rcv_qty    END )  rcv_qty_9th      --�d������_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.pay_qty    END )  pay_qty_9th      --�L������_�X��
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.rcv_qty    END )  rcv_qty_10th     --�d������_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.pay_qty    END )  pay_qty_10th     --�L������_�P�O��
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.rcv_qty    END )  rcv_qty_11th     --�d������_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.pay_qty    END )  pay_qty_11th     --�L������_�P�P��
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.rcv_qty    END )  rcv_qty_12th     --�d������_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.pay_qty    END )  pay_qty_12th     --�L������_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.rcv_qty    END )  rcv_qty_1th      --�d������_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.pay_qty    END )  pay_qty_1th      --�L������_�P��
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.rcv_qty    END )  rcv_qty_2th      --�d������_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.pay_qty    END )  pay_qty_2th      --�L������_�Q��
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.rcv_qty    END )  rcv_qty_3th      --�d������_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.pay_qty    END )  pay_qty_3th      --�L������_�R��
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.rcv_qty    END )  rcv_qty_4th      --�d������_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.pay_qty    END )  pay_qty_4th      --�L������_�S��
             FROM  ( --����{�d���ԕi�{�L���x���̎��уf�[�^��UNION ALL�Ŏ擾
                      ----------------------------------------------
                      -- ��������f�[�^
                      ----------------------------------------------
                      SELECT  XRRT.txns_date                    tran_date       --�Ώۓ�(�����)
                             ,XRRT.department_code              dept_code       --�����R�[�h
                             ,XRRT.vendor_id                    vendor_id       --�����ID
                             ,XRRT.item_code                    item_code       --�i��
                             ,ILTM.attribute9                   rcv_class       --�d���`��
                             ,XRRT.quantity                     rcv_qty         --�d������
                             ,0                                 pay_qty         --�L������
                        FROM  xxpo_rcv_and_rtn_txns             XRRT            --����ԕi����
                             ,po_headers_all                    PHA             --�����w�b�_
                             ,po_lines_all                      PLA             --��������
                             ,ic_lots_mst                       ILTM            --���b�g���擾�p
                       WHERE
                         --��������f�[�^�̒��o
                              XRRT.txns_type = '1'
                         AND  XRRT.quantity <> 0
                         --�������׃f�[�^�擾
                         AND  NVL( PLA.attribute13, 'N' )  = 'Y'                --������
                         AND  NVL( PLA.cancel_flag, 'N' ) <> 'Y'                --�L�����Z���ȊO
                         AND  PHA.po_header_id = PLA.po_header_id
                         AND  XRRT.source_document_number = PHA.segment1
                         AND  XRRT.source_document_line_num = PLA.line_num
                         --���b�g���擾
                         AND  XRRT.item_id = ILTM.item_id(+)
                         AND  XRRT.lot_id = ILTM.lot_id(+)
                      -- [ ��������f�[�^ END ] --
                    UNION ALL
                      ----------------------------------------------
                      -- ��������ԕi�f�[�^
                      ----------------------------------------------
                      SELECT  XRRT.txns_date                    tran_date       --�Ώۓ�(�����)
                             ,XRRT.department_code              dept_code       --�����R�[�h
                             ,XRRT.vendor_id                    vendor_id       --�����ID
                             ,XRRT.item_code                    item_code       --�i��
                             ,ILTM.attribute9                   rcv_class       --�d���`��
                              --�ȉ��̍��ڂ́w�ԕi�x�Ȃ̂Ń}�C�i�X�Ōv�シ��
                             ,XRRT.quantity * -1                rcv_qty         --�d������
                             ,0                                 pay_qty         --�L������
                        FROM  xxpo_rcv_and_rtn_txns             XRRT            --����ԕi����
                             ,po_headers_all                    PHA             --�����w�b�_
                             ,po_lines_all                      PLA             --��������
                             ,ic_lots_mst                       ILTM            --���b�g���擾�p
                       WHERE
                         --��������ԕi�f�[�^�̒��o
                              XRRT.txns_type = '2'
                         AND  XRRT.quantity <> 0
                         --�������׃f�[�^�擾
                         AND  NVL( PLA.attribute13, 'N' )  = 'Y'                --������
                         AND  NVL( PLA.cancel_flag, 'N' ) <> 'Y'                --�L�����Z���ȊO
                         AND  PHA.po_header_id = PLA.po_header_id
                         AND  XRRT.source_document_number = PHA.segment1
                         AND  XRRT.source_document_line_num = PLA.line_num
                         --���b�g���擾
                         AND  XRRT.item_id = ILTM.item_id(+)
                         AND  XRRT.lot_id = ILTM.lot_id(+)
                      -- [ ��������ԕi�f�[�^ END ] --
                    UNION ALL
                      ----------------------------------------------
                      -- ���������ԕi�f�[�^
                      ----------------------------------------------
                      SELECT  XRRT.txns_date                    tran_date       --�Ώۓ�(�����)
                             ,XRRT.department_code              dept_code       --�����R�[�h
                             ,XRRT.vendor_id                    vendor_id       --�����ID
                             ,XRRT.item_code                    item_code       --�i��
                             ,ILTM.attribute9                   rcv_class       --�d���`��
                              --�ȉ��̍��ڂ́w�ԕi�x�Ȃ̂Ń}�C�i�X�Ōv�シ��
                             ,XRRT.quantity * -1                rcv_qty         --�d������
                             ,0                                 pay_qty         --�L������
                        FROM  xxpo_rcv_and_rtn_txns             XRRT            --����ԕi����
                             ,ic_lots_mst                       ILTM            --���b�g���擾�p
                       WHERE
                         --���������ԕi�f�[�^�̒��o
                              XRRT.txns_type = '3'
                         AND  XRRT.quantity <> 0
                         --���b�g���擾
                         AND  XRRT.item_id = ILTM.item_id(+)
                         AND  XRRT.lot_id = ILTM.lot_id(+)
                      -- [ ���������ԕi�f�[�^ END ] --
                    UNION ALL
                      ----------------------------------------------
                      -- �L���x���f�[�^
                      ----------------------------------------------
                      SELECT  NVL( XOHA.arrival_date, XOHA.shipped_date )
                                                                tran_date       --�Ώۓ�(���ד�)
                             ,XOHA.performance_management_dept  dept_code       --�����R�[�h
                             ,XOHA.vendor_id                    vendor_id       --�����ID
                             ,XOLA.shipping_item_code           item_code       --�i��
                             ,ILTM.attribute9                   rcv_class       --�d���`��
                             ,0                                 rcv_qty         --�d������
                             ,XMLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                                                                pay_qty         --�L�����ʁi�w�x���ԕi�x�̏ꍇ�̓}�C�i�X�l�ƂȂ�j
                        FROM  xxwsh_order_headers_all           XOHA            --�󒍃w�b�_
                             ,xxwsh_order_lines_all             XOLA            --�󒍖���
                             ,oe_transaction_types_all          OTTA            --�󒍃^�C�v�}�X�^
                             ,xxinv_mov_lot_details             XMLD            --�ړ����b�g�ڍ�
                             ,ic_lots_mst                       ILTM            --���b�g���擾�p
                       WHERE
                         --�x���f�[�^�擾����
                              OTTA.attribute1 = '2'                             --�x��
                         AND  XOHA.req_status = '08'                            --���ьv���
                         AND  XOHA.latest_external_flag = 'Y'                   --�ŐV�t���O:ON
                         AND  XOHA.order_type_id = OTTA.transaction_type_id
                         --�x�����׏��擾
                         AND  NVL( XOLA.delete_flag, 'N' ) <> 'Y'               --�������׈ȊO
                         AND  XOHA.order_header_id = XOLA.order_header_id
                         --�ړ����b�g�ڍ׏��擾
                         AND  XMLD.actual_quantity <> 0
                         AND  XMLD.document_type_code = '30'                    --�x���x��
                         AND  XMLD.record_type_code = '20'                      --�o�Ɏ���
                         AND  XOLA.order_line_id = XMLD.mov_line_id
                         --���b�g���擾
                         AND  XMLD.item_id = ILTM.item_id(+)
                         AND  XMLD.lot_id = ILTM.lot_id(+)
                      -- [ �L���x���f�[�^ END ] --
                   )  RVPY
                  ,ic_cldr_dtl    ICD    --�݌ɃJ�����_
            WHERE  ICD.orgn_code = 'ITOE'
              AND  TO_CHAR( RVPY.tran_date, 'YYYYMM' ) = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
            GROUP BY ICD.fiscal_year
                    ,RVPY.dept_code
                    ,RVPY.vendor_id
                    ,RVPY.item_code
                    ,RVPY.rcv_class
         )  SMRP
        ,xxsky_locations_v    LOCT    --�������擾�p�iSYSDATE�ŗL���f�[�^�𒊏o�j
        ,xxsky_vendors_v      VNDR    --����於�擾�p�iSYSDATE�ŗL���f�[�^�𒊏o�j
        ,xxsky_item_mst_v     ITEM    --�i�ږ��擾�p�iSYSDATE�ŗL���f�[�^�𒊏o�j
        ,xxsky_prod_class_v   PRODC   --���i�敪�擾�p
        ,xxsky_item_class_v   ITEMC   --�i�ڋ敪�擾�p
        ,xxsky_crowd_code_v   CROWD   --�Q�R�[�h�擾�p
        ,fnd_lookup_values    FLV03   --�d���`�Ԗ��擾�p
 WHERE
   --�d����ԕi��x����ԕi�f�[�^�Ƃ̏W�v�ɂ��S�Ă̏W�v���ʂ��[���ƂȂ����f�[�^�͏o�͂��Ȃ�
       (     SMRP.rcv_qty_5th  <> 0  OR  SMRP.pay_qty_5th  <> 0
         OR  SMRP.rcv_qty_6th  <> 0  OR  SMRP.pay_qty_6th  <> 0
         OR  SMRP.rcv_qty_7th  <> 0  OR  SMRP.pay_qty_7th  <> 0
         OR  SMRP.rcv_qty_8th  <> 0  OR  SMRP.pay_qty_8th  <> 0
         OR  SMRP.rcv_qty_9th  <> 0  OR  SMRP.pay_qty_9th  <> 0
         OR  SMRP.rcv_qty_10th <> 0  OR  SMRP.pay_qty_10th <> 0
         OR  SMRP.rcv_qty_11th <> 0  OR  SMRP.pay_qty_11th <> 0
         OR  SMRP.rcv_qty_12th <> 0  OR  SMRP.pay_qty_12th <> 0
         OR  SMRP.rcv_qty_1th  <> 0  OR  SMRP.pay_qty_1th  <> 0
         OR  SMRP.rcv_qty_2th  <> 0  OR  SMRP.pay_qty_2th  <> 0
         OR  SMRP.rcv_qty_3th  <> 0  OR  SMRP.pay_qty_3th  <> 0
         OR  SMRP.rcv_qty_4th  <> 0  OR  SMRP.pay_qty_4th  <> 0
       )
   --�������擾�iSYSDATE�ŗL���f�[�^�𒊏o�j
   AND  SMRP.dept_code = LOCT.location_code(+)
   --����於�擾�iSYSDATE�ŗL���f�[�^�𒊏o�j
   AND  SMRP.vendor_id = VNDR.vendor_id(+)
   --�i�ږ��擾�iSYSDATE�ŗL���f�[�^�𒊏o�j
   AND  SMRP.item_code = ITEM.item_no(+)
   --�i�ڃJ�e�S�����擾
   AND  ITEM.item_id   = PRODC.item_id(+)
   AND  ITEM.item_id   = ITEMC.item_id(+)
   AND  ITEM.item_id   = CROWD.item_id(+)
   --�d���`�Ԗ��擾
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_L05'
   AND  FLV03.lookup_code(+) = SMRP.rcv_class
/
COMMENT ON TABLE APPS.XXSKY_�d���L�����n��_����_V IS 'SKYLINK�p �d���L�����n��i���ʁjVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�N�x                IS '�N�x'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.����                IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.������              IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�����              IS '�����'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.����於            IS '����於'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.���i�敪            IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.���i�敪��          IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�i�ڋ敪            IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�i�ڋ敪��          IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�Q�R�[�h            IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�i�ڃR�[�h          IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�i�ږ�              IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�i�ڗ���            IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d���`��            IS '�d���`��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d���`�Ԗ�          IS '�d���`�Ԗ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�T��       IS '�d������_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�T��       IS '�L������_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�U��       IS '�d������_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�U��       IS '�L������_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�V��       IS '�d������_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�V��       IS '�L������_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�W��       IS '�d������_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�W��       IS '�L������_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�X��       IS '�d������_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�X��       IS '�L������_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�P�O��     IS '�d������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�P�O��     IS '�L������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�P�P��     IS '�d������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�P�P��     IS '�L������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�P�Q��     IS '�d������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�P�Q��     IS '�L������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�P��       IS '�d������_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�P��       IS '�L������_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�Q��       IS '�d������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�Q��       IS '�L������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�R��       IS '�d������_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�R��       IS '�L������_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�d������_�S��       IS '�d������_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_����_V.�L������_�S��       IS '�L������_�S��'
/
