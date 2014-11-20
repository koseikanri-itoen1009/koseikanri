/*************************************************************************
 * 
 * View  Name      : XXSKZ_�q�֕ԕi���n��_��{_V
 * Description     : XXSKZ_�q�֕ԕi���n��_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�q�֕ԕi���n��_��{_V
(
 �N�x
,���_
,���_��
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i��
,�i�ږ�
,�i�ڗ���
,���ɑq��
,���ɑq�ɖ�
,�q�֑���_�T��
,�ԕi����_�T��
,�q�֑���_�U��
,�ԕi����_�U��
,�q�֑���_�V��
,�ԕi����_�V��
,�q�֑���_�W��
,�ԕi����_�W��
,�q�֑���_�X��
,�ԕi����_�X��
,�q�֑���_�P�O��
,�ԕi����_�P�O��
,�q�֑���_�P�P��
,�ԕi����_�P�P��
,�q�֑���_�P�Q��
,�ԕi����_�P�Q��
,�q�֑���_�P��
,�ԕi����_�P��
,�q�֑���_�Q��
,�ԕi����_�Q��
,�q�֑���_�R��
,�ԕi����_�R��
,�q�֑���_�S��
,�ԕi����_�S��
)
AS
SELECT  SMKH.year                    year             --�N�x
       ,SMKH.hs_branch               hs_branch        --���_
       ,BRCH.party_name              hs_branch_name   --���_��
       ,PRODC.prod_class_code        prod_class_code  --���i�敪
       ,PRODC.prod_class_name        prod_class_name  --���i�敪��
       ,ITEMC.item_class_code        item_class_code  --�i�ڋ敪
       ,ITEMC.item_class_name        item_class_name  --�i�ڋ敪��
       ,CROWD.crowd_code             crowd_code       --�Q�R�[�h
       ,SMKH.item_code               item_code        --�i��
       ,ITEM.item_name               item_name        --�i�ږ�
       ,ITEM.item_short_name         item_s_name      --�i�ڗ���
       ,SMKH.dlvr_from               dlvr_from        --���ɑq��
       ,ITMLC.description            dlvr_from_name   --���ɑq�ɖ�
       ,NVL( SMKH.kur_qty_5th , 0 )  kur_qty_5th      --�q�֑���_�T��
       ,NVL( SMKH.ret_qty_5th , 0 )  ret_qty_5th      --�ԕi����_�T��
       ,NVL( SMKH.kur_qty_6th , 0 )  kur_qty_6th      --�q�֑���_�U��
       ,NVL( SMKH.ret_qty_6th , 0 )  ret_qty_6th      --�ԕi����_�U��
       ,NVL( SMKH.kur_qty_7th , 0 )  kur_qty_7th      --�q�֑���_�V��
       ,NVL( SMKH.ret_qty_7th , 0 )  ret_qty_7th      --�ԕi����_�V��
       ,NVL( SMKH.kur_qty_8th , 0 )  kur_qty_8th      --�q�֑���_�W��
       ,NVL( SMKH.ret_qty_8th , 0 )  ret_qty_8th      --�ԕi����_�W��
       ,NVL( SMKH.kur_qty_9th , 0 )  kur_qty_9th      --�q�֑���_�X��
       ,NVL( SMKH.ret_qty_9th , 0 )  ret_qty_9th      --�ԕi����_�X��
       ,NVL( SMKH.kur_qty_10th, 0 )  kur_qty_10th     --�q�֑���_�P�O��
       ,NVL( SMKH.ret_qty_10th, 0 )  ret_qty_10th     --�ԕi����_�P�O��
       ,NVL( SMKH.kur_qty_11th, 0 )  kur_qty_11th     --�q�֑���_�P�P��
       ,NVL( SMKH.ret_qty_11th, 0 )  ret_qty_11th     --�ԕi����_�P�P��
       ,NVL( SMKH.kur_qty_12th, 0 )  kur_qty_12th     --�q�֑���_�P�Q��
       ,NVL( SMKH.ret_qty_12th, 0 )  ret_qty_12th     --�ԕi����_�P�Q��
       ,NVL( SMKH.kur_qty_1th , 0 )  kur_qty_1th      --�q�֑���_�P��
       ,NVL( SMKH.ret_qty_1th , 0 )  ret_qty_1th      --�ԕi����_�P��
       ,NVL( SMKH.kur_qty_2th , 0 )  kur_qty_2th      --�q�֑���_�Q��
       ,NVL( SMKH.ret_qty_2th , 0 )  ret_qty_2th      --�ԕi����_�Q��
       ,NVL( SMKH.kur_qty_3th , 0 )  kur_qty_3th      --�q�֑���_�R��
       ,NVL( SMKH.ret_qty_3th , 0 )  ret_qty_3th      --�ԕi����_�R��
       ,NVL( SMKH.kur_qty_4th , 0 )  kur_qty_4th      --�q�֑���_�S��
       ,NVL( SMKH.ret_qty_4th , 0 )  ret_qty_4th      --�ԕi����_�S��
  FROM  (  --�N�x�A���_�A�i�ځA�q�ɒP�ʂŏW�v�����i���x�W�v�����ɂ����j�q�֕ԕi���ʏW�v�f�[�^
           SELECT  ICD.fiscal_year                                          year          --�N�x
                  ,XOHA.head_sales_branch                                   hs_branch     --���_
                  ,XOLA.shipping_item_code                                  item_code     --�o�וi��
                  ,XOHA.deliver_from                                        dlvr_from     --�o�׌��ۊǑq��(���ɑq��)
                   --==================================================================================
                   -- �e���W�v�l
                   --  �E�󒍃^�C�v�}�X�^.ATTRIBUTE11 �́w�q�ցxor�w�ԕi�x�𔻒f
                   --  �E������̃f�[�^(�󒍃^�C�v�}�X�^.ORDER_CATEGORY_CODE = 'ORDER')�̓}�C�i�X�l�ƂȂ�
                   --==================================================================================
                   --�T���W�v
                  ,SUM( CASE WHEN ICD.period =  1 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_5th  --�q�֑���_�T��
                  ,SUM( CASE WHEN ICD.period =  1 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_5th  --�ԕi����_�T��
                   --�U���W�v
                  ,SUM( CASE WHEN ICD.period =  2 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_6th  --�q�֑���_�U��
                  ,SUM( CASE WHEN ICD.period =  2 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_6th  --�ԕi����_�U��
                   --�V���W�v
                  ,SUM( CASE WHEN ICD.period =  3 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_7th  --�q�֑���_�V��
                  ,SUM( CASE WHEN ICD.period =  3 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_7th  --�ԕi����_�V��
                   --�W���W�v
                  ,SUM( CASE WHEN ICD.period =  4 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_8th  --�q�֑���_�W��
                  ,SUM( CASE WHEN ICD.period =  4 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_8th  --�ԕi����_�W��
                   --�X���W�v
                  ,SUM( CASE WHEN ICD.period =  5 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_9th  --�q�֑���_�X��
                  ,SUM( CASE WHEN ICD.period =  5 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_9th  --�ԕi����_�X��
                   --�P�O���W�v
                  ,SUM( CASE WHEN ICD.period =  6 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_10th --�q�֑���_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_10th --�ԕi����_�P�O��
                   --�P�P���W�v
                  ,SUM( CASE WHEN ICD.period =  7 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_11th --�q�֑���_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_11th --�ԕi����_�P�P��
                   --�P�Q���W�v
                  ,SUM( CASE WHEN ICD.period =  8 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_12th --�q�֑���_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_12th --�ԕi����_�P�Q��
                   --�P���W�v
                  ,SUM( CASE WHEN ICD.period =  9 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_1th  --�q�֑���_�P��
                  ,SUM( CASE WHEN ICD.period =  9 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_1th  --�ԕi����_�P��
                   --�Q���W�v
                  ,SUM( CASE WHEN ICD.period = 10 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_2th  --�q�֑���_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_2th  --�ԕi����_�Q��
                   --�R���W�v
                  ,SUM( CASE WHEN ICD.period = 11 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_3th  --�q�֑���_�R��
                  ,SUM( CASE WHEN ICD.period = 11 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_3th  --�ԕi����_�R��
                   --�S���W�v
                  ,SUM( CASE WHEN ICD.period = 12 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_4th  --�q�֑���_�S��
                  ,SUM( CASE WHEN ICD.period = 12 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_4th  --�ԕi����_�S��
             FROM  ic_cldr_dtl                  ICD     --�݌ɃJ�����_
                  ,xxcmn_order_headers_all_arc  XOHA    --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                  ,xxcmn_order_lines_all_arc    XOLA    --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                  ,oe_transaction_types_all     OTTA    --�󒍃^�C�v�}�X�^
            WHERE
              --�q�֕ԕi�f�[�^���o����
                   OTTA.attribute1 = '3'                                       --�q�֕ԕi
              AND  XOHA.req_status = '04'                                      --���ьv���
              AND  XOHA.latest_external_flag = 'Y'
              AND  XOHA.order_type_id = OTTA.transaction_type_id
              --���׃f�[�^���o����
              AND  XOLA.shipped_quantity <> 0
              AND  NVL( XOLA.delete_flag, 'N' ) <> 'Y'                         --�������׈ȊO
              AND  XOHA.order_header_id = XOLA.order_header_id
              --�݌ɃJ�����_�Ƃ̌�������
              AND  ICD.orgn_code = 'ITOE'
              AND  TO_CHAR( NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ), 'YYYYMM' ) = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
           GROUP BY  ICD.fiscal_year            --�N�x
                    ,XOHA.head_sales_branch     --���_
                    ,XOLA.shipping_item_code    --�o�וi��
                    ,XOHA.deliver_from          --�o�׌��ۊǑq��(���ɑq��)
        )  SMKH
        ,xxskz_cust_accounts_v    BRCH    --���_���擾�iSYSDATE�ŗL���f�[�^�𒊏o�j
        ,xxskz_item_mst_v         ITEM    --�i�ږ��擾�p�iSYSDATE�ŗL���f�[�^�𒊏o�j
        ,xxskz_prod_class_v       PRODC   --���i�敪�擾�p
        ,xxskz_item_class_v       ITEMC   --�i�ڋ敪�擾�p
        ,xxskz_crowd_code_v       CROWD   --�Q�R�[�h�擾�p
        ,xxskz_item_locations_v   ITMLC   --�ۊǑq�ɖ��擾�p
 WHERE
   --����f�[�^�Ƃ̏W�v�ɂ��S�Ă̏W�v���ʂ��[���ƂȂ����f�[�^�͏o�͂��Ȃ�
       (     SMKH.kur_qty_5th  <> 0  OR  SMKH.ret_qty_5th  <> 0
         OR  SMKH.kur_qty_6th  <> 0  OR  SMKH.ret_qty_6th  <> 0
         OR  SMKH.kur_qty_7th  <> 0  OR  SMKH.ret_qty_7th  <> 0
         OR  SMKH.kur_qty_8th  <> 0  OR  SMKH.ret_qty_8th  <> 0
         OR  SMKH.kur_qty_9th  <> 0  OR  SMKH.ret_qty_9th  <> 0
         OR  SMKH.kur_qty_10th <> 0  OR  SMKH.ret_qty_10th <> 0
         OR  SMKH.kur_qty_11th <> 0  OR  SMKH.ret_qty_11th <> 0
         OR  SMKH.kur_qty_12th <> 0  OR  SMKH.ret_qty_12th <> 0
         OR  SMKH.kur_qty_1th  <> 0  OR  SMKH.ret_qty_1th  <> 0
         OR  SMKH.kur_qty_2th  <> 0  OR  SMKH.ret_qty_2th  <> 0
         OR  SMKH.kur_qty_3th  <> 0  OR  SMKH.ret_qty_3th  <> 0
         OR  SMKH.kur_qty_4th  <> 0  OR  SMKH.ret_qty_4th  <> 0
       )
   --���_���擾
   AND  SMKH.hs_branch = BRCH.party_number(+)
   --�i�ږ��擾
   AND  SMKH.item_code = ITEM.item_no(+)
   --�i�ڃJ�e�S�����擾
   AND  ITEM.item_id   = PRODC.item_id(+)
   AND  ITEM.item_id   = ITEMC.item_id(+)
   AND  ITEM.item_id   = CROWD.item_id(+)
   --�o�׌��ۊǑq�ɖ��擾
   AND  SMKH.dlvr_from = ITMLC.segment1(+)
/
COMMENT ON TABLE APPS.XXSKZ_�q�֕ԕi���n��_��{_V IS 'SKYLINK�p �q�֕ԕi���n��i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�N�x IS '�N�x'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.���_ IS '���_'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.���_�� IS '���_��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�i�� IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�i�ږ� IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�i�ڗ��� IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.���ɑq�� IS '���ɑq��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.���ɑq�ɖ� IS '���ɑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�T�� IS '�q�֑���_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�T�� IS '�ԕi����_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�U�� IS '�q�֑���_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�U�� IS '�ԕi����_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�V�� IS '�q�֑���_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�V�� IS '�ԕi����_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�W�� IS '�q�֑���_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�W�� IS '�ԕi����_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�X�� IS '�q�֑���_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�X�� IS '�ԕi����_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�P�O�� IS '�q�֑���_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�P�O�� IS '�ԕi����_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�P�P�� IS '�q�֑���_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�P�P�� IS '�ԕi����_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�P�Q�� IS '�q�֑���_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�P�Q�� IS '�ԕi����_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�P�� IS '�q�֑���_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�P�� IS '�ԕi����_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�Q�� IS '�q�֑���_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�Q�� IS '�ԕi����_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�R�� IS '�q�֑���_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�R�� IS '�ԕi����_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�q�֑���_�S�� IS '�q�֑���_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�֕ԕi���n��_��{_V.�ԕi����_�S�� IS '�ԕi����_�S��'
/
