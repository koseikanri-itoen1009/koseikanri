CREATE OR REPLACE VIEW APPS.XXSKY_�o�׎��n��_��{_V
(
 �N�x
,����
,������
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
,�o�בq��
,�o�בq�ɖ�
,�o�ב���_�T��
,�o�ב���_�U��
,�o�ב���_�V��
,�o�ב���_�W��
,�o�ב���_�X��
,�o�ב���_�P�O��
,�o�ב���_�P�P��
,�o�ב���_�P�Q��
,�o�ב���_�P��
,�o�ב���_�Q��
,�o�ב���_�R��
,�o�ב���_�S��
)
AS
SELECT  SMSP.year                     year             --�N�x
       ,SMSP.pm_dept                  pm_dept          --����
       ,LOCT.location_name            pm_dept_name     --������
       ,SMSP.hs_branch                hs_branch        --���_
       ,BRCH.party_name               hs_branch_name   --���_��
       ,PRODC.prod_class_code         prod_class_code  --���i�敪
       ,PRODC.prod_class_name         prod_class_name  --���i�敪��
       ,ITEMC.item_class_code         item_class_code  --�i�ڋ敪
       ,ITEMC.item_class_name         item_class_name  --�i�ڋ敪��
       ,CROWD.crowd_code              crowd_code       --�Q�R�[�h
       ,SMSP.item_code                item_code        --�i��
       ,ITEM.item_name                item_name        --�i�ږ�
       ,ITEM.item_short_name          item_s_name      --�i�ڗ���
       ,SMSP.dlvr_from                dlvr_from        --�o�בq��
       ,ITMLC.description             dlvr_from_name   --�o�בq�ɖ�
       ,NVL( SMSP.ship_qty_5th , 0 )  ship_qty_5th     --�o�ב���_�T��
       ,NVL( SMSP.ship_qty_6th , 0 )  ship_qty_6th     --�o�ב���_�U��
       ,NVL( SMSP.ship_qty_7th , 0 )  ship_qty_7th     --�o�ב���_�V��
       ,NVL( SMSP.ship_qty_8th , 0 )  ship_qty_8th     --�o�ב���_�W��
       ,NVL( SMSP.ship_qty_9th , 0 )  ship_qty_9th     --�o�ב���_�X��
       ,NVL( SMSP.ship_qty_10th, 0 )  ship_qty_10th    --�o�ב���_�P�O��
       ,NVL( SMSP.ship_qty_11th, 0 )  ship_qty_11th    --�o�ב���_�P�P��
       ,NVL( SMSP.ship_qty_12th, 0 )  ship_qty_12th    --�o�ב���_�P�Q��
       ,NVL( SMSP.ship_qty_1th , 0 )  ship_qty_1th     --�o�ב���_�P��
       ,NVL( SMSP.ship_qty_2th , 0 )  ship_qty_2th     --�o�ב���_�Q��
       ,NVL( SMSP.ship_qty_3th , 0 )  ship_qty_3th     --�o�ב���_�R��
       ,NVL( SMSP.ship_qty_4th , 0 )  ship_qty_4th     --�o�ב���_�S��
  FROM  (  --�N�x�A�����A���_�A�o�וi�ځA�q�ɒP�ʂŏW�v�����i���x�W�v�����ɂ����j�o�א��ʏW�v�f�[�^
           SELECT  ICD.fiscal_year                                                  year           --�N�x
                  ,XOHA.performance_management_dept                                 pm_dept        --����
                  ,XOHA.head_sales_branch                                           hs_branch      --���_
                  ,XOLA.request_item_code                                           item_code      --�˗��i��
                  ,XOHA.deliver_from                                                dlvr_from      --�o�׌��ۊǑq��
                   --�o�ב����T���`�S��
                  ,SUM( CASE WHEN ICD.period =  1 THEN XOLA.shipped_quantity END )  ship_qty_5th   --�o�ב���_�T��
                  ,SUM( CASE WHEN ICD.period =  2 THEN XOLA.shipped_quantity END )  ship_qty_6th   --�o�ב���_�U��
                  ,SUM( CASE WHEN ICD.period =  3 THEN XOLA.shipped_quantity END )  ship_qty_7th   --�o�ב���_�V��
                  ,SUM( CASE WHEN ICD.period =  4 THEN XOLA.shipped_quantity END )  ship_qty_8th   --�o�ב���_�W��
                  ,SUM( CASE WHEN ICD.period =  5 THEN XOLA.shipped_quantity END )  ship_qty_9th   --�o�ב���_�X��
                  ,SUM( CASE WHEN ICD.period =  6 THEN XOLA.shipped_quantity END )  ship_qty_10th  --�o�ב���_�P�O��
                  ,SUM( CASE WHEN ICD.period =  7 THEN XOLA.shipped_quantity END )  ship_qty_11th  --�o�ב���_�P�P��
                  ,SUM( CASE WHEN ICD.period =  8 THEN XOLA.shipped_quantity END )  ship_qty_12th  --�o�ב���_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  9 THEN XOLA.shipped_quantity END )  ship_qty_1th   --�o�ב���_�P��
                  ,SUM( CASE WHEN ICD.period = 10 THEN XOLA.shipped_quantity END )  ship_qty_2th   --�o�ב���_�Q��
                  ,SUM( CASE WHEN ICD.period = 11 THEN XOLA.shipped_quantity END )  ship_qty_3th   --�o�ב���_�R��
                  ,SUM( CASE WHEN ICD.period = 12 THEN XOLA.shipped_quantity END )  ship_qty_4th   --�o�ב���_�S��
             FROM  ic_cldr_dtl                  ICD     --�݌ɃJ�����_
                  ,xxwsh_order_headers_all      XOHA    --�󒍃w�b�_
                  ,xxwsh_order_lines_all        XOLA    --�󒍖���
                  ,oe_transaction_types_all     OTTA    --�󒍃^�C�v�}�X�^
            WHERE
              --�o�׃f�[�^���o����
                   OTTA.attribute1 = '1'                                      --�o��
              AND  OTTA.attribute4 = '1'                                      --�ʏ�o��(���{�A�p��������)
              AND  OTTA.order_category_code = 'ORDER'
              AND  XOHA.req_status = '04'                                     --���ьv���
              AND  XOHA.latest_external_flag = 'Y'
              AND  XOHA.order_type_id = OTTA.transaction_type_id
              --���׃f�[�^���o����
              AND  XOLA.shipped_quantity <> 0
              AND  NVL( XOLA.delete_flag, 'N' ) <> 'Y'                        --�������׈ȊO
              AND  XOHA.order_header_id = XOLA.order_header_id
              --�݌ɃJ�����_�Ƃ̌�������
              AND  ICD.orgn_code = 'ITOE'
              AND  TO_CHAR( NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ), 'YYYYMM' ) = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
            GROUP BY ICD.fiscal_year
                    ,XOHA.performance_management_dept
                    ,XOHA.head_sales_branch
                    ,XOLA.request_item_code
                    ,XOHA.deliver_from
         )  SMSP                          --�o�א��ʌ����W�v
        ,xxsky_locations_v        LOCT    --�������擾�p�iSYSDATE�ŗL���f�[�^�𒊏o�j
        ,xxsky_cust_accounts_v    BRCH    --���_���擾�p�iSYSDATE�ŗL���f�[�^�𒊏o�j
        ,xxsky_item_mst_v         ITEM    --�i�ږ��擾�p�iSYSDATE�ŗL���f�[�^�𒊏o�j
        ,xxsky_prod_class_v       PRODC   --���i�敪�擾�p
        ,xxsky_item_class_v       ITEMC   --�i�ڋ敪�擾�p
        ,xxsky_crowd_code_v       CROWD   --�Q�R�[�h�擾�p
        ,xxsky_item_locations_v   ITMLC   --�ۊǑq�ɖ��擾�p
 WHERE
   --�������擾
        SMSP.pm_dept   = LOCT.location_code(+)
   --���_���擾
   AND  SMSP.hs_branch = BRCH.party_number(+)
   --�i�ږ��擾
   AND  SMSP.item_code = ITEM.item_no(+)
   --�i�ڃJ�e�S�����擾
   AND  ITEM.item_id   = PRODC.item_id(+)
   AND  ITEM.item_id   = ITEMC.item_id(+)
   AND  ITEM.item_id   = CROWD.item_id(+)
   --�o�׌��ۊǑq�ɖ��擾
   AND  SMSP.dlvr_from = ITMLC.segment1(+)
/
COMMENT ON TABLE APPS.XXSKY_�o�׎��n��_��{_V IS 'SKYLINK�p �o�׎��n��i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�N�x IS '�N�x'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.���� IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.���_ IS '���_'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.���_�� IS '���_��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�i�� IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�i�ږ� IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�i�ڗ��� IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�בq�� IS '�o�בq��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�בq�ɖ� IS '�o�בq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�T�� IS '�o�ב���_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�U�� IS '�o�ב���_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�V�� IS '�o�ב���_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�W�� IS '�o�ב���_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�X�� IS '�o�ב���_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�P�O�� IS '�o�ב���_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�P�P�� IS '�o�ב���_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�P�Q�� IS '�o�ב���_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�P�� IS '�o�ב���_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�Q�� IS '�o�ב���_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�R�� IS '�o�ב���_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׎��n��_��{_V.�o�ב���_�S�� IS '�o�ב���_�S��'
/
