CREATE OR REPLACE VIEW APPS.XXSKY_���o�ɏ��_����_V
(
 �N��
,���o�ɋ敪
,�\����ы敪
,���R�R�[�h
,���R�R�[�h��
,���i�敪�R�[�h
,���i�敪��
,�i�ڋ敪�R�[�h
,�i�ڋ敪��
,���O�敪�R�[�h
,���O�敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�P�[�X����
,���`�R�[�h
,���`
,�q�ɃR�[�h
,�ۊǏꏊ�R�[�h
,�ۊǏꏊ��
,�ۊǏꏊ����
,�󕥐�R�[�h
,�󕥐於
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
SELECT  --Add 2014/12/02 E_�{�ғ�_12685 PT�Ή� Start
        /*+ OPTIMIZER_FEATURES_ENABLE('10.2.0.3') */
        --Add 2014/12/02 E_�{�ғ�_12685 PT�Ή� End
        SIOT.yyyymm                    AS yyyymm                   --�N��
       ,CASE WHEN SIOT.in_out_kbn = 1 THEN '����'    --���o�ɋ敪�R�[�h��1:����
             WHEN SIOT.in_out_kbn = 2 THEN '�o��'    --���o�ɋ敪�R�[�h��2:�o��
             ELSE SIOT.in_out_kbn
        END                            AS in_out_kbn_name          --���o�ɋ敪
       ,CASE WHEN SIOT.status = 1 THEN '�\��'        --�\����ы敪�R�[�h��1:����
             WHEN SIOT.status = 2 THEN '����'        --�\����ы敪�R�[�h��2:�o��
             ELSE SIOT.status
        END                            AS status_name              --�\����ы敪
       ,SIOT.reason_code               AS reason_code              --���R�R�[�h
       ,FLV01.meaning                  AS reason_code_name         --���R�R�[�h��
       ,XPCV.prod_class_code           AS prod_class_code          --���i�敪�R�[�h
       ,XPCV.prod_class_name           AS prod_class_name          --���i�敪��
       ,XICV.item_class_code           AS item_class_code          --�i�ڋ敪�R�[�h
       ,XICV.item_class_name           AS item_class_name          --�i�ڋ敪��
       ,XIOCV.inout_class_code         AS inout_class_code         --���O�敪�R�[�h
       ,XIOCV.inout_class_name         AS inout_class_name         --���O�敪��
       ,XCCV.crowd_code                AS crowd_code               --�Q�R�[�h
       ,SIOT.item_no                   AS item_no                  --�i�ڃR�[�h
       ,SIOT.item_name                 AS item_name                --�i�ږ�
       ,SIOT.item_short_name           AS item_short_name          --�i�ڗ���
       ,SIOT.case_content              AS case_content             --�P�[�X����
       ,IWM.attribute1                 AS cust_stc_whse            --���`�R�[�h
       ,FLV02.meaning                  AS cust_stc_whse_name       --���`
       ,SIOT.whse_code                 AS whse_code                --�q�ɃR�[�h
       ,SIOT.location_code             AS location_code            --�ۊǏꏊ�R�[�h
       ,SIOT.location                  AS location                 --�ۊǏꏊ��
       ,SIOT.location_s_name           AS location_s_name          --�ۊǏꏊ����
       ,SIOT.ukebaraisaki_code         AS ukebaraisaki_code        --�󕥐�R�[�h
       ,SIOT.ukebaraisaki_name         AS ukebaraisaki_name        --�󕥐於
       ,NVL( SIOT.qty_01dy, 0 )        AS qty_01dy                 --���ʂP��
       ,NVL( SIOT.qty_02dy, 0 )        AS qty_02dy                 --���ʂQ��
       ,NVL( SIOT.qty_03dy, 0 )        AS qty_03dy                 --���ʂR��
       ,NVL( SIOT.qty_04dy, 0 )        AS qty_04dy                 --���ʂS��
       ,NVL( SIOT.qty_05dy, 0 )        AS qty_05dy                 --���ʂT��
       ,NVL( SIOT.qty_06dy, 0 )        AS qty_06dy                 --���ʂU��
       ,NVL( SIOT.qty_07dy, 0 )        AS qty_07dy                 --���ʂV��
       ,NVL( SIOT.qty_08dy, 0 )        AS qty_08dy                 --���ʂW��
       ,NVL( SIOT.qty_09dy, 0 )        AS qty_09dy                 --���ʂX��
       ,NVL( SIOT.qty_10dy, 0 )        AS qty_10dy                 --���ʂP�O��
       ,NVL( SIOT.qty_11dy, 0 )        AS qty_11dy                 --���ʂP�P��
       ,NVL( SIOT.qty_12dy, 0 )        AS qty_12dy                 --���ʂP�Q��
       ,NVL( SIOT.qty_13dy, 0 )        AS qty_13dy                 --���ʂP�R��
       ,NVL( SIOT.qty_14dy, 0 )        AS qty_14dy                 --���ʂP�S��
       ,NVL( SIOT.qty_15dy, 0 )        AS qty_15dy                 --���ʂP�T��
       ,NVL( SIOT.qty_16dy, 0 )        AS qty_16dy                 --���ʂP�U��
       ,NVL( SIOT.qty_17dy, 0 )        AS qty_17dy                 --���ʂP�V��
       ,NVL( SIOT.qty_18dy, 0 )        AS qty_18dy                 --���ʂP�W��
       ,NVL( SIOT.qty_19dy, 0 )        AS qty_19dy                 --���ʂP�X��
       ,NVL( SIOT.qty_20dy, 0 )        AS qty_20dy                 --���ʂQ�O��
       ,NVL( SIOT.qty_21dy, 0 )        AS qty_21dy                 --���ʂQ�P��
       ,NVL( SIOT.qty_22dy, 0 )        AS qty_22dy                 --���ʂQ�Q��
       ,NVL( SIOT.qty_23dy, 0 )        AS qty_23dy                 --���ʂQ�R��
       ,NVL( SIOT.qty_24dy, 0 )        AS qty_24dy                 --���ʂQ�S��
       ,NVL( SIOT.qty_25dy, 0 )        AS qty_25dy                 --���ʂQ�T��
       ,NVL( SIOT.qty_26dy, 0 )        AS qty_26dy                 --���ʂQ�U��
       ,NVL( SIOT.qty_27dy, 0 )        AS qty_27dy                 --���ʂQ�V��
       ,NVL( SIOT.qty_28dy, 0 )        AS qty_28dy                 --���ʂQ�W��
       ,NVL( SIOT.qty_29dy, 0 )        AS qty_29dy                 --���ʂQ�X��
       ,NVL( SIOT.qty_30dy, 0 )        AS qty_30dy                 --���ʂR�O��
       ,NVL( SIOT.qty_31dy, 0 )        AS qty_31dy                 --���ʂR�P��
  FROM  ( --���ʏW�v�݂̂��s��
          SELECT  TO_CHAR( XIOT.arrival_date, 'YYYYMM' )           AS yyyymm                 --�N��
                 ,XIOT.in_out_kbn                                  AS in_out_kbn             --���o�ɋ敪
                 ,XIOT.status                                      AS status                 --�\����ы敪
                 ,XIOT.reason_code                                 AS reason_code            --���R�R�[�h
                 ,XIOT.item_id                                     AS item_id                --�i��ID
                 ,XIOT.item_no                                     AS item_no                --�i�ڃR�[�h
                 ,XIOT.item_name                                   AS item_name              --�i�ږ�
                 ,XIOT.item_short_name                             AS item_short_name        --�i�ڗ���
                 ,XIOT.case_content                                AS case_content           --�P�[�X����
                 ,XIOT.whse_code                                   AS whse_code              --�q�ɃR�[�h
                 ,XIOT.location_code                               AS location_code          --�ۊǏꏊ�R�[�h
                 ,XIOT.location                                    AS location               --�ۊǏꏊ��
                 ,XIOT.location_s_name                             AS location_s_name        --�ۊǏꏊ����
                 ,XIOT.ukebaraisaki_code                           AS ukebaraisaki_code      --�󕥐�R�[�h
                 ,XIOT.ukebaraisaki_name                           AS ukebaraisaki_name      --�󕥐於
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '01' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_01dy  --���ʂP��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '02' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_02dy  --���ʂQ��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '03' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_03dy  --���ʂR��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '04' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_04dy  --���ʂS��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '05' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_05dy  --���ʂT��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '06' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_06dy  --���ʂU��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '07' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_07dy  --���ʂV��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '08' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_08dy  --���ʂW��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '09' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_09dy  --���ʂX��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '10' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_10dy  --���ʂP�O��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '11' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_11dy  --���ʂP�P��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '12' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_12dy  --���ʂP�Q��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '13' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_13dy  --���ʂP�R��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '14' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_14dy  --���ʂP�S��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '15' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_15dy  --���ʂP�T��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '16' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_16dy  --���ʂP�U��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '17' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_17dy  --���ʂP�V��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '18' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_18dy  --���ʂP�W��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '19' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_19dy  --���ʂP�X��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '20' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_20dy  --���ʂQ�O��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '21' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_21dy  --���ʂQ�P��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '22' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_22dy  --���ʂQ�Q��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '23' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_23dy  --���ʂQ�R��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '24' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_24dy  --���ʂQ�S��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '25' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_25dy  --���ʂQ�T��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '26' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_26dy  --���ʂQ�U��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '27' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_27dy  --���ʂQ�V��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '28' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_28dy  --���ʂQ�W��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '29' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_29dy  --���ʂQ�X��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '30' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_30dy  --���ʂR�O��
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '31' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_31dy  --���ʂR�P��
            FROM  xxsky_inout_trans_v        XIOT    --���o�ɏ��i����VIEW�j
          GROUP BY TO_CHAR( XIOT.arrival_date, 'YYYYMM' )    --�N��
                  ,XIOT.in_out_kbn                           --���o�ɋ敪
                  ,XIOT.status                               --�\����ы敪
                  ,XIOT.reason_code                          --���R�R�[�h
                  ,XIOT.item_id                              --�i��ID
                  ,XIOT.item_no                              --�i�ڃR�[�h
                  ,XIOT.item_name                            --�i�ږ�
                  ,XIOT.item_short_name                      --�i�ڗ���
                  ,XIOT.case_content                         --�P�[�X����
                  ,XIOT.whse_code                            --�q�ɃR�[�h
                  ,XIOT.location_code                        --�ۊǏꏊ�R�[�h
                  ,XIOT.location                             --�ۊǏꏊ��
                  ,XIOT.location_s_name                      --�ۊǏꏊ����
                  ,XIOT.ukebaraisaki_code                    --�󕥐�R�[�h
                  ,XIOT.ukebaraisaki_name                    --�󕥐於
        )  SIOT
       ,xxsky_prod_class_v            XPCV    --���i�敪�擾�p
       ,xxsky_item_class_v            XICV    --�i�ڋ敪�擾�p
       ,xxsky_inout_class_v           XIOCV   --���O�敪�擾�p
       ,xxsky_crowd_code_v            XCCV    --�Q�R�[�h�擾�p
       ,ic_whse_mst                   IWM     --�q�Ƀ}�X�^
       ,fnd_lookup_values             FLV01   --���R�R�[�h���擾�p
       ,fnd_lookup_values             FLV02   --���`�擾�p
 WHERE
   --���i�敪�擾
        SIOT.item_id = XPCV.item_id(+)
   --�i�ڋ敪�擾
   AND  SIOT.item_id = XICV.item_id(+)
   --���O�敪�擾
   AND  SIOT.item_id = XIOCV.item_id(+)
   --�Q�R�[�h�擾
   AND  SIOT.item_id = XCCV.item_id(+)
   --�q�ɏ��擾
   AND  SIOT.whse_code = IWM.whse_code(+)
   --�y�N�C�b�N�R�[�h�z���R�R�[�h���擾
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXCMN_NEW_DIVISION'
   AND  FLV01.lookup_code(+) = SIOT.reason_code
   --�y�N�C�b�N�R�[�h�z���`�擾
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_INV_CTRL'
   AND  FLV02.lookup_code(+) = IWM.attribute1
/
COMMENT ON TABLE APPS.XXSKY_���o�ɏ��_����_V IS 'SKYLINK�p ���o�ɏ��i���ʁjVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�N��           IS '�N��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���o�ɋ敪     IS '���o�ɋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�\����ы敪   IS '�\����ы敪'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���R�R�[�h     IS '���R�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���R�R�[�h��   IS '���R�R�[�h��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���i�敪�R�[�h IS '���i�敪�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���i�敪��     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�i�ڋ敪�R�[�h IS '�i�ڋ敪�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�i�ڋ敪��     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���O�敪�R�[�h IS '���O�敪�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���O�敪��     IS '���O�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�Q�R�[�h       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�i�ڃR�[�h     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�i�ږ�         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�i�ڗ���       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�P�[�X����     IS '�P�[�X����'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���`�R�[�h     IS '���`�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���`           IS '���`'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�q�ɃR�[�h     IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�ۊǏꏊ�R�[�h IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�ۊǏꏊ��     IS '�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�ۊǏꏊ����   IS '�ۊǏꏊ����'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�󕥐�R�[�h   IS '�󕥐�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.�󕥐於       IS '�󕥐於'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂP��       IS '���ʂP��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂQ��       IS '���ʂQ��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂR��       IS '���ʂR��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂS��       IS '���ʂS��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂT��       IS '���ʂT��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂU��       IS '���ʂU��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂV��       IS '���ʂV��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂW��       IS '���ʂW��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂX��       IS '���ʂX��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂP�O��     IS '���ʂP�O��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂP�P��     IS '���ʂP�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂP�Q��     IS '���ʂP�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂP�R��     IS '���ʂP�R��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂP�S��     IS '���ʂP�S��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂP�T��     IS '���ʂP�T��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂP�U��     IS '���ʂP�U��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂP�V��     IS '���ʂP�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂP�W��     IS '���ʂP�W��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂP�X��     IS '���ʂP�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂQ�O��     IS '���ʂQ�O��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂQ�P��     IS '���ʂQ�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂQ�Q��     IS '���ʂQ�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂQ�R��     IS '���ʂQ�R��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂQ�S��     IS '���ʂQ�S��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂQ�T��     IS '���ʂQ�T��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂQ�U��     IS '���ʂQ�U��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂQ�V��     IS '���ʂQ�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂQ�W��     IS '���ʂQ�W��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂQ�X��     IS '���ʂQ�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂR�O��     IS '���ʂR�O��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɏ��_����_V.���ʂR�P��     IS '���ʂR�P��'
/
