CREATE OR REPLACE VIEW APPS.XXSKY_����v��_����_V
(
 �N��
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,���O�敪
,���O�敪��
,�i��
,�i�ږ�
,�i�ڗ���
,�o�׌��ۊǑq��
,�o�׌��ۊǑq�ɖ�
,���_
,���_��
,�P�[�X����
,���ʂP��
,���ʂQ��
,���ʂR��
,���ʂS��
,���ʂT��
,���ʂU��
,���ʂV��
,���ʂW��
,���ʂX��
,���ʂP�O��
,���ʂP�P��
,���ʂP�Q��
,���ʂP�R��
,���ʂP�S��
,���ʂP�T��
,���ʂP�U��
,���ʂP�V��
,���ʂP�W��
,���ʂP�X��
,���ʂQ�O��
,���ʂQ�P��
,���ʂQ�Q��
,���ʂQ�R��
,���ʂQ�S��
,���ʂQ�T��
,���ʂQ�U��
,���ʂQ�V��
,���ʂQ�W��
,���ʂQ�X��
,���ʂR�O��
,���ʂR�P��
)
AS
SELECT  SMFC.frct_ym                frct_ym            --�N��
       ,PRODC.prod_class_code       prod_class_code    --���i�敪
       ,PRODC.prod_class_name       prod_class_name    --���i�敪��
       ,ITEMC.item_class_code       item_class_code    --�i�ڋ敪
       ,ITEMC.item_class_name       item_class_name    --�i�ڋ敪��
       ,CROWD.crowd_code            crowd_code         --�Q�R�[�h
       ,INOUT.inout_class_code      inout_class_code   --���O�敪
       ,INOUT.inout_class_name      inout_class_name   --���O�敪�� 
       ,ITEM.item_no                item_code          --�i��
       ,ITEM.item_name              item_name          --�i�ږ�
       ,ITEM.item_short_name        item_s_name        --�i�ڗ���
       ,SMFC.dlvr_from              dlvr_from          --�o�׌��ۊǑq��
       ,ITMLC.description           dlvr_from_name     --�o�׌��ۊǑq�ɖ�
       ,SMFC.branch                 branch             --���_
       ,BRCH.party_name             branch_name        --���_��
       ,ITEM.num_of_cases           incase_qty         --�P�[�X����
       ,NVL( SMFC.fc_qty_01dy, 0 )  fc_qty_01dy        --���ʂP��
       ,NVL( SMFC.fc_qty_02dy, 0 )  fc_qty_02dy        --���ʂQ��
       ,NVL( SMFC.fc_qty_03dy, 0 )  fc_qty_03dy        --���ʂR��
       ,NVL( SMFC.fc_qty_04dy, 0 )  fc_qty_04dy        --���ʂS��
       ,NVL( SMFC.fc_qty_05dy, 0 )  fc_qty_05dy        --���ʂT��
       ,NVL( SMFC.fc_qty_06dy, 0 )  fc_qty_06dy        --���ʂU��
       ,NVL( SMFC.fc_qty_07dy, 0 )  fc_qty_07dy        --���ʂV��
       ,NVL( SMFC.fc_qty_08dy, 0 )  fc_qty_08dy        --���ʂW��
       ,NVL( SMFC.fc_qty_09dy, 0 )  fc_qty_09dy        --���ʂX��
       ,NVL( SMFC.fc_qty_10dy, 0 )  fc_qty_10dy        --���ʂP�O��
       ,NVL( SMFC.fc_qty_11dy, 0 )  fc_qty_11dy        --���ʂP�P��
       ,NVL( SMFC.fc_qty_12dy, 0 )  fc_qty_12dy        --���ʂP�Q��
       ,NVL( SMFC.fc_qty_13dy, 0 )  fc_qty_13dy        --���ʂP�R��
       ,NVL( SMFC.fc_qty_14dy, 0 )  fc_qty_14dy        --���ʂP�S��
       ,NVL( SMFC.fc_qty_15dy, 0 )  fc_qty_15dy        --���ʂP�T��
       ,NVL( SMFC.fc_qty_16dy, 0 )  fc_qty_16dy        --���ʂP�U��
       ,NVL( SMFC.fc_qty_17dy, 0 )  fc_qty_17dy        --���ʂP�V��
       ,NVL( SMFC.fc_qty_18dy, 0 )  fc_qty_18dy        --���ʂP�W��
       ,NVL( SMFC.fc_qty_19dy, 0 )  fc_qty_19dy        --���ʂP�X��
       ,NVL( SMFC.fc_qty_20dy, 0 )  fc_qty_20dy        --���ʂQ�O��
       ,NVL( SMFC.fc_qty_21dy, 0 )  fc_qty_21dy        --���ʂQ�P��
       ,NVL( SMFC.fc_qty_22dy, 0 )  fc_qty_22dy        --���ʂQ�Q��
       ,NVL( SMFC.fc_qty_23dy, 0 )  fc_qty_23dy        --���ʂQ�R��
       ,NVL( SMFC.fc_qty_24dy, 0 )  fc_qty_24dy        --���ʂQ�S��
       ,NVL( SMFC.fc_qty_25dy, 0 )  fc_qty_25dy        --���ʂQ�T��
       ,NVL( SMFC.fc_qty_26dy, 0 )  fc_qty_26dy        --���ʂQ�U��
       ,NVL( SMFC.fc_qty_27dy, 0 )  fc_qty_27dy        --���ʂQ�V��
       ,NVL( SMFC.fc_qty_28dy, 0 )  fc_qty_28dy        --���ʂQ�W��
       ,NVL( SMFC.fc_qty_29dy, 0 )  fc_qty_29dy        --���ʂQ�X��
       ,NVL( SMFC.fc_qty_30dy, 0 )  fc_qty_30dy        --���ʂR�O��
       ,NVL( SMFC.fc_qty_31dy, 0 )  fc_qty_31dy        --���ʂR�P��
  FROM  ( --�N���A�q�ɁA���_�A�i�ڒP�ʂŏW�v�����i���ʂ����ɂ����j�v�搔�ʏW�v�f�[�^
          SELECT  TO_CHAR( MFDT.forecast_date, 'YYYYMM' )                                                              frct_ym      --�\��N��
                 ,MFDN.attribute2                                                                                      dlvr_from    --�o�׌��ۊǑq�ɃR�[�h
                 ,MFDN.attribute3                                                                                      branch       --���_�R�[�h
                 ,MFDT.inventory_item_id                                                                               item_id      --�o�וi��ID
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '01' THEN MFDT.current_forecast_quantity END )  fc_qty_01dy  --���ʂP��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '02' THEN MFDT.current_forecast_quantity END )  fc_qty_02dy  --���ʂQ��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '03' THEN MFDT.current_forecast_quantity END )  fc_qty_03dy  --���ʂR��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '04' THEN MFDT.current_forecast_quantity END )  fc_qty_04dy  --���ʂS��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '05' THEN MFDT.current_forecast_quantity END )  fc_qty_05dy  --���ʂT��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '06' THEN MFDT.current_forecast_quantity END )  fc_qty_06dy  --���ʂU��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '07' THEN MFDT.current_forecast_quantity END )  fc_qty_07dy  --���ʂV��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '08' THEN MFDT.current_forecast_quantity END )  fc_qty_08dy  --���ʂW��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '09' THEN MFDT.current_forecast_quantity END )  fc_qty_09dy  --���ʂX��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '10' THEN MFDT.current_forecast_quantity END )  fc_qty_10dy  --���ʂP�O��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '11' THEN MFDT.current_forecast_quantity END )  fc_qty_11dy  --���ʂP�P��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '12' THEN MFDT.current_forecast_quantity END )  fc_qty_12dy  --���ʂP�Q��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '13' THEN MFDT.current_forecast_quantity END )  fc_qty_13dy  --���ʂP�R��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '14' THEN MFDT.current_forecast_quantity END )  fc_qty_14dy  --���ʂP�S��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '15' THEN MFDT.current_forecast_quantity END )  fc_qty_15dy  --���ʂP�T��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '16' THEN MFDT.current_forecast_quantity END )  fc_qty_16dy  --���ʂP�U��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '17' THEN MFDT.current_forecast_quantity END )  fc_qty_17dy  --���ʂP�V��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '18' THEN MFDT.current_forecast_quantity END )  fc_qty_18dy  --���ʂP�W��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '19' THEN MFDT.current_forecast_quantity END )  fc_qty_19dy  --���ʂP�X��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '20' THEN MFDT.current_forecast_quantity END )  fc_qty_20dy  --���ʂQ�O��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '21' THEN MFDT.current_forecast_quantity END )  fc_qty_21dy  --���ʂQ�P��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '22' THEN MFDT.current_forecast_quantity END )  fc_qty_22dy  --���ʂQ�Q��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '23' THEN MFDT.current_forecast_quantity END )  fc_qty_23dy  --���ʂQ�R��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '24' THEN MFDT.current_forecast_quantity END )  fc_qty_24dy  --���ʂQ�S��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '25' THEN MFDT.current_forecast_quantity END )  fc_qty_25dy  --���ʂQ�T��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '26' THEN MFDT.current_forecast_quantity END )  fc_qty_26dy  --���ʂQ�U��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '27' THEN MFDT.current_forecast_quantity END )  fc_qty_27dy  --���ʂQ�V��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '28' THEN MFDT.current_forecast_quantity END )  fc_qty_28dy  --���ʂQ�W��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '29' THEN MFDT.current_forecast_quantity END )  fc_qty_29dy  --���ʂQ�X��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '30' THEN MFDT.current_forecast_quantity END )  fc_qty_30dy  --���ʂR�O��
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '31' THEN MFDT.current_forecast_quantity END )  fc_qty_31dy  --���ʂR�P��
            FROM  mrp_forecast_designators    MFDN    --�t�H�[�L���X�g���e�[�u��
                 ,mrp_forecast_dates          MFDT    --�t�H�[�L���X�g���t�e�[�u��
           WHERE  MFDN.attribute1 = '01'                                --����v��
             AND  MFDN.organization_id = fnd_profile.VALUE( 'XXCMN_MASTER_ORG_ID' )
             AND  MFDN.forecast_designator = MFDT.forecast_designator
             AND  MFDN.organization_id = MFDT.organization_id
          GROUP BY  TO_CHAR( MFDT.forecast_date, 'YYYYMM' )
                   ,MFDN.attribute2
                   ,MFDN.attribute3
                   ,MFDT.inventory_item_id
        )                       SMFC    --����v����ʏW�v
       ,xxsky_item_mst2_v       ITEM    --�i�ږ��擾�p
       ,xxsky_prod_class_v      PRODC   --���i�敪�擾�p
       ,xxsky_item_class_v      ITEMC   --�i�ڋ敪�擾�p
       ,xxsky_crowd_code_v      CROWD   --�Q�R�[�h�擾�p
       ,xxsky_inout_class_v     INOUT   --���O�敪�擾�p
       ,xxsky_item_locations_v  ITMLC   --�ۊǑq�ɖ��擾�p
       ,xxsky_cust_accounts2_v  BRCH    --���_���擾�p
 WHERE
   --�i�ږ��擾
        SMFC.item_id   = ITEM.inventory_item_id(+)
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) >= ITEM.start_date_active(+)  --�������t�Ō���
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) <= ITEM.end_date_active(+)    --�������t�Ō���
   --�i�ڃJ�e�S�����擾
   AND  ITEM.item_id   = PRODC.item_id(+)
   AND  ITEM.item_id   = ITEMC.item_id(+)
   AND  ITEM.item_id   = CROWD.item_id(+)
   AND  ITEM.item_id   = INOUT.item_id(+)
   --�o�׌��ۊǑq�ɖ��擾
   AND  SMFC.dlvr_from = ITMLC.segment1(+)
   --���_���擾
   AND  SMFC.branch    = BRCH.party_number(+)
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) >= BRCH.start_date_active(+)  --�������t�Ō���
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) <= BRCH.end_date_active(+)    --�������t�Ō���
/
COMMENT ON TABLE APPS.XXSKY_����v��_����_V IS 'SKYLINK�p ����v��i���ʁjVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.�N��             IS '�N��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���i�敪         IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���i�敪��       IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.�i�ڋ敪         IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.�i�ڋ敪��       IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.�Q�R�[�h         IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���O�敪         IS '���O�敪'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���O�敪��       IS '���O�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.�i��             IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.�i�ږ�           IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.�i�ڗ���         IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.�o�׌��ۊǑq��   IS '�o�׌��ۊǑq��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.�o�׌��ۊǑq�ɖ� IS '�o�׌��ۊǑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���_             IS '���_'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���_��           IS '���_��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.�P�[�X����       IS '�P�[�X����'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂP��         IS '���ʂP��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂQ��         IS '���ʂQ��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂR��         IS '���ʂR��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂS��         IS '���ʂS��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂT��         IS '���ʂT��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂU��         IS '���ʂU��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂV��         IS '���ʂV��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂW��         IS '���ʂW��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂX��         IS '���ʂX��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂP�O��       IS '���ʂP�O��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂP�P��       IS '���ʂP�P��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂP�Q��       IS '���ʂP�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂP�R��       IS '���ʂP�R��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂP�S��       IS '���ʂP�S��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂP�T��       IS '���ʂP�T��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂP�U��       IS '���ʂP�U��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂP�V��       IS '���ʂP�V��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂP�W��       IS '���ʂP�W��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂP�X��       IS '���ʂP�X��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂQ�O��       IS '���ʂQ�O��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂQ�P��       IS '���ʂQ�P��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂQ�Q��       IS '���ʂQ�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂQ�R��       IS '���ʂQ�R��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂQ�S��       IS '���ʂQ�S��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂQ�T��       IS '���ʂQ�T��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂQ�U��       IS '���ʂQ�U��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂQ�V��       IS '���ʂQ�V��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂQ�W��       IS '���ʂQ�W��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂQ�X��       IS '���ʂQ�X��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂR�O��       IS '���ʂR�O��'
/
COMMENT ON COLUMN APPS.XXSKY_����v��_����_V.���ʂR�P��       IS '���ʂR�P��'
/
