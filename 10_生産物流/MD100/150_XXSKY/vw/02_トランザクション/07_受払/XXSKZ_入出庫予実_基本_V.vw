/*************************************************************************
 * 
 * View  Name      : XXSKZ_���o�ɗ\��_��{_V
 * Description     : XXSKZ_���o�ɗ\��_��{_V
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK ����    ����쐬
 *  2013/08/09    1.1   SCSK �n��    E_�{�ғ�_10839
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_���o�ɗ\��_��{_V
(
 ���`�R�[�h
,���`
,�`�[�ԍ�
,�s�ԍ�
,���R�R�[�h
,���R�R�[�h��
,�q�ɃR�[�h
,�ۊǏꏊ�R�[�h
,�ۊǏꏊ��
,�ۊǏꏊ����
,�����R�[�h
,������
,���i�敪�R�[�h
,���i�敪��
,�i�ڋ敪�R�[�h
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���b�gNo
,�����N����
,�ŗL�L��
,�ܖ�����
,�P�[�X����
,���o�ɋ敪
,���o�ɓ�_����
,���o�ɓ�_����
,�󕥐�R�[�h
,�󕥐於
,�\����ы敪
,�z����R�[�h
,�z���於
,���ɐ�
,�o�ɐ�
,���o�ɋ��z
,����ŋ��z
,�z���ԍ�
)
AS
SELECT
        IWM.attribute1                                          AS cust_stc_whse          --���`�R�[�h
       ,FLV01.meaning                                           AS cust_stc_whse_name     --���`
       ,XIOT.voucher_no                                         AS voucher_no             --�`�[�ԍ�
       ,XIOT.line_no                                            AS line_no                --�s�ԍ�
       ,XIOT.reason_code                                        AS reason_code            --���R�R�[�h
       ,FLV02.meaning                                           AS reason_code_name       --���R�R�[�h��
       ,XIOT.whse_code                                          AS whse_code              --�q�ɃR�[�h
       ,XIOT.location_code                                      AS location_code          --�ۊǏꏊ�R�[�h
       ,XIOT.location                                           AS location               --�ۊǏꏊ��
       ,XIOT.location_s_name                                    AS location_s_name        --�ۊǏꏊ����
       ,XIOT.loct_code                                          AS loct_code              --�����R�[�h
       ,XIOT.loct_name                                          AS loct_name              --������
       ,XPCV.prod_class_code                                    AS prod_class_code        --���i�敪�R�[�h
       ,XPCV.prod_class_name                                    AS prod_class_name        --���i�敪��
       ,XICV.item_class_code                                    AS item_class_code        --�i�ڋ敪�R�[�h
       ,XICV.item_class_name                                    AS item_class_name        --�i�ڋ敪��
       ,XCCV.crowd_code                                         AS crowd_code             --�Q�R�[�h
       ,XIOT.item_no                                            AS item_no                --�i�ڃR�[�h
       ,XIOT.item_name                                          AS item_name              --�i�ږ�
       ,XIOT.item_short_name                                    AS item_short_name        --�i�ڗ���
        --���b�g���͔񃍃b�g�Ǘ��i�̏ꍇ�\�����Ȃ�
       ,NVL( DECODE( XIOT.lot_no, 'DEFAULTLOT', '0', XIOT.lot_no ), '0' )
                                                                AS lot_no                 --���b�gNo('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN XIOT.lot_ctl = 1 THEN XIOT.manufacture_date  --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                         --�񃍃b�g�Ǘ��i ��NULL
        END                                                     AS manufacture_date       --�����N����
       ,CASE WHEN XIOT.lot_ctl = 1 THEN XIOT.uniqe_sign        --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                         --�񃍃b�g�Ǘ��i ��NULL
        END                                                     AS uniqe_sign             --�ŗL�L��
       ,CASE WHEN XIOT.lot_ctl = 1 THEN XIOT.expiration_date   --���b�g�Ǘ��i   ���ܖ�����
             ELSE NULL                                         --�񃍃b�g�Ǘ��i ��NULL
        END                                                     AS expiration_date        --�ܖ�����
       ,XIOT.case_content                                       AS case_content           --�P�[�X����
       ,CASE WHEN XIOT.in_out_kbn = 1 THEN '����'              --���o�ɋ敪�R�[�h��1:����
             WHEN XIOT.in_out_kbn = 2 THEN '�o��'              --���o�ɋ敪�R�[�h��2:�o��
        END                                                     AS in_out_kbn_name        --���o�ɋ敪
       ,XIOT.leaving_date                                       AS leaving_date           --���o�ɓ�_����
       ,XIOT.arrival_date                                       AS arrival_date           --���o�ɓ�_����
       ,XIOT.ukebaraisaki_code                                  AS ukebaraisaki_code      --�󕥐�R�[�h
       ,XIOT.ukebaraisaki_name                                  AS ukebaraisaki_name      --�󕥐於
       ,CASE WHEN XIOT.status = '1' THEN '�\��'                --�\����ы敪�R�[�h��1:�\��
             WHEN XIOT.status = '2' THEN '����'                --�\����ы敪�R�[�h��2:����
        END                                                     AS yojitu_kbn_name        --�\����ы敪
       ,XIOT.deliver_to_no                                      AS deliver_to_no          --�z����R�[�h
       ,XIOT.deliver_to_name                                    AS deliver_to_name        --�z���於
       ,ROUND( NVL( XIOT.stock_quantity  , 0 ), 3 )             AS stock_quantity         --���ɐ�
       ,ROUND( NVL( XIOT.leaving_quantity, 0 ), 3 )             AS leaving_quantity       --�o�ɐ�
       ,CASE WHEN XIOT.in_out_kbn = 1 THEN
                  ROUND( NVL( TO_NUMBER( ILM.attribute7 ) * ROUND( XIOT.stock_quantity  ) , 0 ) )
             WHEN XIOT.in_out_kbn = 2 THEN
                  ROUND( NVL( TO_NUMBER( ILM.attribute7 ) * ROUND( XIOT.leaving_quantity) , 0 ) )
        END                                                     AS price                  --���o�ɋ��z(�݌ɒP���~����)
       ,CASE WHEN XIOT.in_out_kbn = 1 THEN
                  ROUND( NVL( ROUND( TO_NUMBER( ILM.attribute7 ) * ROUND( XIOT.stock_quantity   ) ) * ( TO_NUMBER(FLV03.lookup_code) * 0.01 ) , 0 ) )
             WHEN XIOT.in_out_kbn = 2 THEN
                  ROUND( NVL( ROUND( TO_NUMBER( ILM.attribute7 ) * ROUND( XIOT.leaving_quantity ) ) * ( TO_NUMBER(FLV03.lookup_code) * 0.01 ) , 0 ) )
        END                                                     AS price                  --����Ŋz(���o�ɋ��z�~����ŗ�)
       ,XIOT.delivery_no                                        AS delivery_no            --�z���ԍ�
  FROM
        xxskz_inout_yj_trans_v        XIOT    --���o�ɗ\���i����VIEW�j
       ,ic_lots_mst                   ILM     --OPM���b�g�}�X�^
       ,xxskz_prod_class_v            XPCV    --���i�敪�擾�p
       ,xxskz_item_class_v            XICV    --�i�ڋ敪�擾�p
       ,xxskz_crowd_code_v            XCCV    --�Q�R�[�h�擾�p
       ,ic_whse_mst                   IWM     --�q�Ƀ}�X�^
       ,fnd_lookup_values             FLV01   --���`�擾�p
       ,fnd_lookup_values             FLV02   --���R�R�[�h���擾�p
       ,fnd_lookup_values             FLV03   --����ŗ��擾�p
-- 2013/08/09 R.Watanabe Mod Start E_�{�ғ�_10839
--  ��������ԕi�̏ꍇ�͕ԕi�������̔[����������ŗ��K�p����Ƃ���B
       ,(SELECT XRRT2.rcv_rtn_number             AS rcv_rtn_number      --����ԕi�ԍ�
               ,XRRT2.rcv_rtn_line_number        AS rcv_rtn_line_number --�s�ԍ�
               ,CASE WHEN XRRT2.txns_type = '2' THEN 
                       FND_DATE.STRING_TO_DATE(PHA2.attribute4, 'YYYY/MM/DD')  --�������[����
                     ELSE
                       TRUNC(XRRT2.txns_date)      --����������A�ԕi�����
                END                              AS txns_date 
         FROM   xxpo_rcv_and_rtn_txns  XRRT2 
               ,po_headers_all         PHA2 
         WHERE  XRRT2.source_document_number = PHA2.segment1(+) 
         AND    XRRT2.txns_type in ('2','3') --��������ԕi�A�������ԕi
         )                       XRRT     -- �ԕi�������f�[�^���
-- 2013/08/09 R.Watanabe Mod End E_�{�ғ�_10839
 WHERE
   --���b�g���擾
        XIOT.item_id = ILM.item_id(+)
   AND  XIOT.lot_id  = ILM.lot_id(+)
   --���i�敪�擾
   AND  XIOT.item_id = XPCV.item_id(+)
   --�i�ڋ敪�擾
   AND  XIOT.item_id = XICV.item_id(+)
   --�Q�R�[�h�擾
   AND  XIOT.item_id = XCCV.item_id(+)
   --�q�ɏ��擾
   AND  XIOT.whse_code = IWM.whse_code(+)
   --�y�N�C�b�N�R�[�h�z���`�擾
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXCMN_INV_CTRL'
   AND  FLV01.lookup_code(+) = IWM.attribute1
   --�y�N�C�b�N�R�[�h�z���R�R�[�h���擾
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_NEW_DIVISION'
   AND  FLV02.lookup_code(+) = XIOT.reason_code
   --�y�N�C�b�N�R�[�h�z����ŗ��擾����
-- 2013/08/09 R.Watanabe Mod Start E_�{�ғ�_10839
--   AND  FLV03.language(+)    = 'JA'
--   AND  FLV03.lookup_type(+) = 'XXCMN_CONSUMPTION_TAX_RATE'
   AND  FLV03.language       = 'JA'
   AND  FLV03.lookup_type    = 'XXCMN_CONSUMPTION_TAX_RATE'
-- 2013/08/09 R.Watanabe Mod End E_�{�ғ�_10839
-- 2013/08/09 R.Watanabe Add Start E_�{�ғ�_10839
-- �A�d����ԕi�̏ꍇ�ԕi���̔����[�����i����ԕi���уA�h�I���̌������ԍ�����擾�A�Q�ƃe�[�u���̒ǉ��j
--   ������ԕi���уA�h�I��.���ы敪��3�F�����Ȃ��d����ԕi�̏ꍇ�͕ԕi����̎������Ƃ��Đŗ��擾����
   AND  XIOT.voucher_no      = XRRT.rcv_rtn_number(+)      --����ԕi�ԍ�
   AND  XIOT.line_no         = XRRT.rcv_rtn_line_number(+) --�s�ԍ�
-- 2013/08/09 R.Watanabe Add End E_�{�ғ�_10839   
--
-- 2013/08/09 R.Watanabe Mod Start E_�{�ғ�_10839
--  ����������ŗ��K�p����Ƃ���B�������A�d����ԕi�̏ꍇ�ŁA���ы敪��2�̏ꍇ�͌������̔[�����Ƃ���
--   AND  NVL( FLV03.start_date_active(+), TO_DATE('19000101', 'YYYYMMDD') ) <= XIOT.standard_date
--   AND  NVL( FLV03.end_date_active(+)  , TO_DATE('99991231', 'YYYYMMDD') ) >= XIOT.standard_date
   AND  NVL( FLV03.start_date_active, TO_DATE('19000101', 'YYYYMMDD') ) <= 
        CASE WHEN XIOT.reason_code = '202' --202:�d����ԕi
          THEN NVL(XRRT.txns_date,XIOT.arrival_date)
        ELSE XIOT.arrival_date END
   AND  NVL( FLV03.end_date_active  , TO_DATE('99991231', 'YYYYMMDD') ) >= 
        CASE WHEN XIOT.reason_code = '202' --202:�d����ԕi
          THEN NVL(XRRT.txns_date,XIOT.arrival_date)
        ELSE XIOT.arrival_date END
-- 2013/08/09 R.Watanabe Mod End E_�{�ғ�_10839
/
COMMENT ON TABLE APPS.XXSKZ_���o�ɗ\��_��{_V IS 'XXSKZ_���o�ɗ\�� (��{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���`�R�[�h     IS '���`�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���`           IS '���`'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�`�[�ԍ�       IS '�`�[�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�s�ԍ�         IS '�s�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���R�R�[�h     IS '���R�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���R�R�[�h��   IS '���R�R�[�h��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�q�ɃR�[�h     IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�ۊǏꏊ�R�[�h IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�ۊǏꏊ��     IS '�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�ۊǏꏊ����   IS '�ۊǏꏊ����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�����R�[�h     IS '�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.������         IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���i�敪�R�[�h IS '���i�敪�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���i�敪��     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�i�ڋ敪�R�[�h IS '�i�ڋ敪�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�i�ڋ敪��     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�Q�R�[�h       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�i�ڃR�[�h     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�i�ږ�         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�i�ڗ���       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���b�gNo       IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�����N����     IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�ŗL�L��       IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�ܖ�����       IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�P�[�X����     IS '�P�[�X����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���o�ɋ敪     IS '���o�ɋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���o�ɓ�_����  IS '���o�ɓ�_����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���o�ɓ�_����  IS '���o�ɓ�_����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�󕥐�R�[�h   IS '�󕥐�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�󕥐於       IS '�󕥐於'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�\����ы敪   IS '�\����ы敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�z����R�[�h   IS '�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�z���於       IS '�z���於'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���ɐ�         IS '���ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�o�ɐ�         IS '�o�ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.���o�ɋ��z     IS '���o�ɋ��z'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.����ŋ��z     IS '����ŋ��z'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɗ\��_��{_V.�z���ԍ�       IS '�z���ԍ�'
/
