CREATE OR REPLACE VIEW APPS.XXSKY_�d���L�����E����_��{_V
(
 �N��
,���ъǗ�����
,���ъǗ�������
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�����
,����於
,�d�����z
,�L�����z_����
,�L�����z_����
,�L�����z_���v
,�x�����z
)
AS
SELECT
        XRO.yyyymm                                          yyyymm              --�N��
       ,XRO.department_code                                 department_code     --���ъǗ�����
       ,XLV.location_name                                   location_name       --���ъǗ�������
       ,XRO.prod_class_code                                 prod_class_code     --���i�敪
       ,XRO.prod_class_name                                 prod_class_name     --���i�敪��
       ,XRO.item_class_code                                 item_class_code     --�i�ڋ敪
       ,XRO.item_class_name                                 item_class_name     --�i�ڋ敪��
       ,XRO.vendor_code                                     vendor_code         --�����
       ,XVV.vendor_name                                     vendor_name         --����於
       ,SUM( NVL( XRO.rcv_price    , 0 ) )                  rcv_price           --�d�����z
       ,SUM( NVL( XRO.pay_price_gen, 0 ) )                  pay_price_gen       --�L�����z_����
       ,SUM( NVL( XRO.pay_price_szi, 0 ) )                  pay_price_szi       --�L�����z_����
       ,SUM( NVL( XRO.pay_price_gen, 0 ) + NVL( XRO.pay_price_szi, 0 ) )
                                                            pay_price_total     --�L�����z_���v�i�L�����z_���� �{ �L�����z_���ށj
       ,SUM( NVL( XRO.rcv_price    , 0 )
              - ( NVL( XRO.pay_price_gen, 0 ) + NVL( XRO.pay_price_szi, 0 ) ) )
                                                            sihr_price          --�x�����z�i�d�����z �| �L�����z_���v�j
  FROM
       ( --����{�d���ԕi�{�L���x���̎��уf�[�^��UNION ALL�Ŏ擾
          -------------------------------------------------------------------
          -- �����E����f�[�^
          -------------------------------------------------------------------
          SELECT
                  TO_CHAR( txns_date, 'YYYYMM' )            yyyymm              --�N��
                 ,XRART.department_code                     department_code     --�����R�[�h
                 ,XRART.vendor_code                         vendor_code         --�����R�[�h
                 ,PRODC.prod_class_code                     prod_class_code     --���i�敪
                 ,PRODC.prod_class_name                     prod_class_name     --���i�敪��
                 ,ITEMC.item_class_code                     item_class_code     --�i�ڋ敪
                 ,ITEMC.item_class_name                     item_class_name     --�i�ڋ敪��
                 ,ROUND( PLA.unit_price * XRART.quantity )  rcv_price           --�d�����z �i���P���͔������ׂ̂��̂��g�p�j
                 ,0                                         pay_price_gen       --�L�����z_����
                 ,0                                         pay_price_szi       --�L�����z_����
            FROM
                  xxpo_rcv_and_rtn_txns                     XRART               --����ԕi���уA�h�I��
                 ,po_headers_all                            PHA                 --�����w�b�_
                 ,po_lines_all                              PLA                 --��������
                 ,xxsky_prod_class_v                        PRODC               --���i�敪�擾�p
                 ,xxsky_item_class_v                        ITEMC               --�i�ڋ敪�擾�p
           WHERE
             --��������f�[�^�̒��o
                  XRART.txns_type                           = '1'               --'1:�������'
             AND  XRART.quantity                           <> 0
             --�����f�[�^�Ƃ̌���
             AND  NVL( PLA.cancel_flag, 'N' )              <> 'Y'               --�L�����Z���ȊO
             AND  NVL( PLA.attribute13, 'N' )               = 'Y'               --������
             AND  XRART.source_document_number              = PHA.segment1
             AND  XRART.source_document_line_num            = PLA.line_num
             AND  PHA.po_header_id                          = PLA.po_header_id
             --�i�ڃJ�e�S�����擾
-- 2010/01/08 T.Yoshimoto Mod Start E_�{�ғ�#716
             --AND  XRART.item_id                             = PRODC.item_id(+)  --���i�敪���擾
             --AND  XRART.item_id                             = ITEMC.item_id(+)  --�i�ڋ敪���擾
             AND  XRART.item_id                             = PRODC.item_id     --���i�敪���擾
             AND  XRART.item_id                             = ITEMC.item_id     --�i�ڋ敪���擾
             AND  PRODC.item_id                             = ITEMC.item_id
-- 2010/01/08 T.Yoshimoto Mod End E_�{�ғ�#716
          --[ �����E����f�[�^  END ]--
        UNION ALL
          -------------------------------------------------------------------
          -- ��������ԕi�f�[�^�i�d�����z�̓}�C�i�X�l�ƂȂ�j
          -------------------------------------------------------------------
          SELECT
                  TO_CHAR( txns_date, 'YYYYMM' )            yyyymm              --�N��
                 ,XRART.department_code                     department_code     --�����R�[�h
                 ,XRART.vendor_code                         vendor_code         --�����R�[�h
                 ,PRODC.prod_class_code                     prod_class_code     --���i�敪
                 ,PRODC.prod_class_name                     prod_class_name     --���i�敪��
                 ,ITEMC.item_class_code                     item_class_code     --�i�ڋ敪
                 ,ITEMC.item_class_name                     item_class_name     --�i�ڋ敪��
                 ,ROUND( ( XRART.unit_price * XRART.quantity ) * -1 )
                                                            rcv_price           --�d�����z �i���P���͎���ԕi�A�h�I���̂��̂��g�p�j
                 ,0                                         pay_price_gen       --�L�����z_����
                 ,0                                         pay_price_szi       --�L�����z_����
            FROM
                  xxpo_rcv_and_rtn_txns                     XRART               --����ԕi���уA�h�I��
                 ,po_headers_all                            PHA                 --�����w�b�_
                 ,po_lines_all                              PLA                 --��������
                 ,xxsky_prod_class_v                        PRODC               --���i�敪�擾�p
                 ,xxsky_item_class_v                        ITEMC               --�i�ڋ敪�擾�p
           WHERE
             --��������ԕi�f�[�^�̒��o
                  XRART.txns_type                           = '2'               --'2:��������ԕi'
             AND  XRART.quantity                           <> 0
             --�����f�[�^�Ƃ̌���
             AND  NVL( PLA.cancel_flag, 'N' )              <> 'Y'               --�L�����Z���ȊO
             AND  NVL( PLA.attribute13, 'N' )               = 'Y'               --������
             AND  XRART.source_document_number              = PHA.segment1
             AND  XRART.source_document_line_num            = PLA.line_num
             AND  PHA.po_header_id                          = PLA.po_header_id
             --�i�ڃJ�e�S�����擾
-- 2010/01/08 T.Yoshimoto Mod Start E_�{�ғ�#716
             --AND  XRART.item_id                             = PRODC.item_id(+)  --���i�敪���擾
             --AND  XRART.item_id                             = ITEMC.item_id(+)  --�i�ڋ敪���擾
             AND  XRART.item_id                             = PRODC.item_id     --���i�敪���擾
             AND  XRART.item_id                             = ITEMC.item_id     --�i�ڋ敪���擾
             AND  PRODC.item_id                             = ITEMC.item_id
-- 2010/01/08 T.Yoshimoto Mod End E_�{�ғ�#716
          --[ ��������ԕi�f�[�^  END ]--
        UNION ALL
          -------------------------------------------------------------------
          -- ���������ԕi�f�[�^�i�d�����z�̓}�C�i�X�l�ƂȂ�j
          -------------------------------------------------------------------
          SELECT
                  TO_CHAR( txns_date, 'YYYYMM' )            yyyymm              --�N��
                 ,XRART.department_code                     department_code     --�����R�[�h
                 ,XRART.vendor_code                         vendor_code         --�����R�[�h
                 ,PRODC.prod_class_code                     prod_class_code     --���i�敪
                 ,PRODC.prod_class_name                     prod_class_name     --���i�敪��
                 ,ITEMC.item_class_code                     item_class_code     --�i�ڋ敪
                 ,ITEMC.item_class_name                     item_class_name     --�i�ڋ敪��
                 ,ROUND( ( XRART.unit_price * XRART.quantity ) * -1 )
                                                            rcv_price           --�d�����z �i���P���͎���ԕi�A�h�I���̂��̂��g�p�j
                 ,0                                         pay_price_gen       --�L�����z_����
                 ,0                                         pay_price_szi       --�L�����z_����
            FROM
                  xxpo_rcv_and_rtn_txns                     XRART               --����ԕi���уA�h�I��
                 ,xxsky_prod_class_v                        PRODC               --���i�敪�擾�p
                 ,xxsky_item_class_v                        ITEMC               --�i�ڋ敪�擾�p
           WHERE
             --���������ԕi�f�[�^�̒��o
                  XRART.txns_type                           = '3'               --'3:���������ԕi'
             AND  XRART.quantity                           <> 0
             --�i�ڃJ�e�S�����擾
-- 2010/01/08 T.Yoshimoto Mod Start E_�{�ғ�#716
             --AND  XRART.item_id                             = PRODC.item_id(+)  --���i�敪���擾
             --AND  XRART.item_id                             = ITEMC.item_id(+)  --�i�ڋ敪���擾
             AND  XRART.item_id                             = PRODC.item_id     --���i�敪���擾
             AND  XRART.item_id                             = ITEMC.item_id     --�i�ڋ敪���擾
             AND  PRODC.item_id                             = ITEMC.item_id
-- 2010/01/08 T.Yoshimoto Mod End E_�{�ғ�#716
          --[ ���������ԕi�f�[�^  END ]--
        UNION ALL
          -------------------------------------------------------------------
          -- �L���x���f�[�^�i����<���ވȊO> or ���� �̋��z�y�P���~���ʁz���擾����j
          -------------------------------------------------------------------
          SELECT
-- 2010/01/08 T.Yoshimoto Mod Start E_�{�ғ�#716
                  --TO_CHAR( NVL( XOHA.arrival_date, XOHA.shipped_date ), 'YYYYMM' )
                  TO_CHAR( XOHA.arrival_date, 'YYYYMM' )
-- 2010/01/08 T.Yoshimoto Mod End E_�{�ғ�#716
                                                            yyyymm              --�N���i���ד���NULL���͏o�ד��j
                 ,XOHA.performance_management_dept          department_code     --���ъǗ�����
                 ,XOHA.vendor_code                          vendor_code         --�����R�[�h
                 ,PRODC.prod_class_code                     prod_class_code     --���i�敪
                 ,PRODC.prod_class_name                     prod_class_name     --���i�敪��
                 ,ITEMC.item_class_code                     item_class_code     --�i�ڋ敪
                 ,ITEMC.item_class_name                     item_class_name     --�i�ڋ敪��
                 ,0                                         rcv_price           --�d�����z
                  --�L�����z�i����<���ވȊO>�j
                 ,CASE WHEN NVL( ITEMC.item_class_code, '1' ) <> '2' THEN           --�i�ڋ敪��'2:����'�ȊO�̏ꍇ
                    ROUND( ( XOLA.unit_price * XMLD.actual_quantity )
                             * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )  --�w�x���ԕi�x�̏ꍇ�̓}�C�i�X�l
                         )
                  END                                       pay_price_gen       --�L�����z_����
                  --�L�����z�i���ށj
                 ,CASE WHEN NVL( ITEMC.item_class_code, '1' )  = '2' THEN           --�i�ڋ敪��'2:����'�̏ꍇ
                    ROUND( ( XOLA.unit_price * XMLD.actual_quantity )
                             * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )  --�w�x���ԕi�x�̏ꍇ�̓}�C�i�X�l
                         )
                  END                                       pay_price_szi       --�L�����z_����
            FROM
                  xxwsh_order_headers_all                   XOHA                --�󒍃w�b�_
                 ,xxwsh_order_lines_all                     XOLA                --�󒍖���
                 ,oe_transaction_types_all                  OTTA                --�󒍃^�C�v�}�X�^
                 ,xxinv_mov_lot_details                     XMLD                --�ړ����b�g�ڍ�
                 ,xxsky_prod_class_v                        PRODC               --���i�敪�擾�p
                 ,xxsky_item_class_v                        ITEMC               --�i�ڋ敪�擾�p
           WHERE
             --�󒍃^�C�v�}�X�^�̏���
                  OTTA.attribute1                           = '2'               --'2:�x��'
             --�󒍃w�b�_�̏���
             AND  XOHA.req_status                           = '08'              --���ьv���
             AND  NVL( XOHA.latest_external_flag, 'N' )     = 'Y'               --�ŐV�t���O'Y'�̂�
             AND  OTTA.transaction_type_id                  = XOHA.order_type_id
             --�󒍖��ׂƂ̌���
             AND  NVL( XOLA.delete_flag, 'N' )             <> 'Y'               --�������׈ȊO
             AND  XOHA.order_header_id                      = XOLA.order_header_id
             --�ړ����b�g�ڍ׏��Ƃ̌����i���z�̎l�̌ܓ��������s���̂̓��b�g���גP�ʁj
             AND  XMLD.actual_quantity                     <> 0
             AND  XMLD.document_type_code                   = '30'              --�x���x��
             AND  XMLD.record_type_code                     = '20'              --�o�Ɏ���
             AND  XOLA.order_line_id                        = XMLD.mov_line_id
             --�i�ڃJ�e�S�����擾
-- 2010/01/08 T.Yoshimoto Mod Start E_�{�ғ�#716
             --AND  XMLD.item_id                              = PRODC.item_id(+)  --���i�敪���擾
             --AND  XMLD.item_id                              = ITEMC.item_id(+)  --�i�ڋ敪���擾
             AND  XMLD.item_id                              = PRODC.item_id     --���i�敪���擾
             AND  XMLD.item_id                              = ITEMC.item_id     --�i�ڋ敪���擾
             AND  PRODC.item_id                             = ITEMC.item_id
-- 2010/01/08 T.Yoshimoto Mod End E_�{�ғ�#716
-- 2010/01/08 T.Yoshimoto Add Start E_�{�ғ�#716
             AND  XOHA.arrival_date IS NOT NULL
-- 2010/01/08 T.Yoshimoto Add End E_�{�ғ�#716
          --[ �L���x���f�[�^  END ]--
       )                      XRO
       ,xxsky_locations2_v    XLV                           --�������擾�p
       ,xxsky_vendors2_v      XVV                           --����於�擾�p
 WHERE
   --�x����ԕi�f�[�^�Ƃ̏W�v�ɂ��S�Ă̏W�v���ڂ��[���ƂȂ����f�[�^�͏o�͂��Ȃ�
       (     XRO.rcv_price     <> 0
         OR  XRO.pay_price_gen <> 0
         OR  XRO.pay_price_szi <> 0
       )
   --�������擾
   AND  XRO.department_code = XLV.location_code(+)
   AND  LAST_DAY( TO_DATE( XRO.yyyymm || '01', 'YYYYMMDD' ) ) >= XLV.start_date_active(+)  --�N�������t�Ō���
   AND  LAST_DAY( TO_DATE( XRO.yyyymm || '01', 'YYYYMMDD' ) ) <= XLV.end_date_active(+)    --�N�������t�Ō���
   --����於�擾
   AND  XRO.vendor_code = XVV.segment1(+)
   AND  LAST_DAY( TO_DATE( XRO.yyyymm || '01', 'YYYYMMDD' ) ) >= XVV.start_date_active(+)  --�N�������t�Ō���
   AND  LAST_DAY( TO_DATE( XRO.yyyymm || '01', 'YYYYMMDD' ) ) <= XVV.end_date_active(+)    --�N�������t�Ō���
GROUP BY  XRO.yyyymm
         ,XRO.department_code
         ,XLV.location_name
         ,XRO.vendor_code
         ,XVV.vendor_name
         ,XRO.prod_class_code
         ,XRO.prod_class_name
         ,XRO.item_class_code
         ,XRO.item_class_name
/
COMMENT ON TABLE APPS.XXSKY_�d���L�����E����_��{_V IS 'SKYLINK�p�d���L�����E���׊�{VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.�N��           IS '�N��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.���ъǗ�����   IS '���ъǗ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.���ъǗ������� IS '���ъǗ�������'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.���i�敪       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.���i�敪��     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.�i�ڋ敪       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.�i�ڋ敪��     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.�����         IS '�����'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.����於       IS '����於'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.�d�����z       IS '�d�����z'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.�L�����z_����  IS '�L�����z_����'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.�L�����z_����  IS '�L�����z_����'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.�L�����z_���v  IS '�L�����z_���v'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����E����_��{_V.�x�����z       IS '�x�����z'
/
