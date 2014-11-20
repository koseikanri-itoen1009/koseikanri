CREATE OR REPLACE VIEW APPS.XXSKY_�̔��v�掞�n��_��{_V
(
 �N�x
,����
,���_�R�[�h
,���_��
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�N�ԍ��v�P�[�X��
,�N�ԍ��v�o����
,�N�ԍ��v���z
,�N�Ԋ|��
,�̔��v��P�[�X��_�T��
,�̔��v��o����_�T��
,�̔��v����z_�T��
,�̔��v��|��_�T��
,�̔��v��P�[�X��_�U��
,�̔��v��o����_�U��
,�̔��v����z_�U��
,�̔��v��|��_�U��
,�̔��v��P�[�X��_�V��
,�̔��v��o����_�V��
,�̔��v����z_�V��
,�̔��v��|��_�V��
,�̔��v��P�[�X��_�W��
,�̔��v��o����_�W��
,�̔��v����z_�W��
,�̔��v��|��_�W��
,�̔��v��P�[�X��_�X��
,�̔��v��o����_�X��
,�̔��v����z_�X��
,�̔��v��|��_�X��
,�̔��v��P�[�X��_�P�O��
,�̔��v��o����_�P�O��
,�̔��v����z_�P�O��
,�̔��v��|��_�P�O��
,�̔��v��P�[�X��_�P�P��
,�̔��v��o����_�P�P��
,�̔��v����z_�P�P��
,�̔��v��|��_�P�P��
,�̔��v��P�[�X��_�P�Q��
,�̔��v��o����_�P�Q��
,�̔��v����z_�P�Q��
,�̔��v��|��_�P�Q��
,�̔��v��P�[�X��_�P��
,�̔��v��o����_�P��
,�̔��v����z_�P��
,�̔��v��|��_�P��
,�̔��v��P�[�X��_�Q��
,�̔��v��o����_�Q��
,�̔��v����z_�Q��
,�̔��v��|��_�Q��
,�̔��v��P�[�X��_�R��
,�̔��v��o����_�R��
,�̔��v����z_�R��
,�̔��v��|��_�R��
,�̔��v��P�[�X��_�S��
,�̔��v��o����_�S��
,�̔��v����z_�S��
,�̔��v��|��_�S��
)
AS
SELECT
        SMFC.year                                                     year                --�N�x
       ,SMFC.generation                                               generation          --����
       ,SMFC.hs_branch                                                hs_branch           --���_�R�[�h
       ,BRCH.party_name                                               hs_branch_name      --���_��
       ,PRODC.prod_class_code                                         prod_class_code     --���i�敪
       ,PRODC.prod_class_name                                         prod_class_name     --���i�敪��
       ,ITEMC.item_class_code                                         item_class_code     --�i�ڋ敪
       ,ITEMC.item_class_name                                         item_class_name     --�i�ڋ敪��
       ,CROWD.crowd_code                                              crowd_code          --�Q�R�[�h
       ,ITEM.item_no                                                  item_code           --�i�ڃR�[�h
       ,ITEM.item_name                                                item_name           --�i�ږ�
       ,ITEM.item_short_name                                          item_s_name         --�i�ڗ���
        --=====================
        -- �N��
        --=====================
       ,NVL( TRUNC( SMFC.sum_year_qty / ITEM.num_of_cases ), 0 )      sum_year_cs_qty     --�N�ԍ��v�P�[�X��
       ,NVL( SMFC.sum_year_qty , 0 )                                  sum_year_qty        --�N�ԍ��v�o����
       ,NVL( SMFC.sum_year_amt , 0 )                                  sum_year_amt        --�N�ԍ��v���z
        --�|��  ���p�[�Z���g�P��(�����_��R�ʈȉ��l�̌ܓ�)�ŕ\����
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.sum_year_qty, 0 ) <> 0 THEN  --�[������΍�
                  -- �|�� �� �̔����z���艿���z(�艿�~����)
                  NVL( ROUND( ( SMFC.sum_year_amt / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.sum_year_qty ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           sum_year_rate       --�N�Ԋ|��
        --=====================
        --�T��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_5th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_5th       --�̔��v��P�[�X��_�T��
       ,NVL( SMFC.fc_qty_5th   , 0 )                                  fc_qty_5th          --�̔��v��o����_�T��
       ,NVL( SMFC.fc_amt_5th   , 0 )                                  fc_amt_5th          --�̔��v����z_�T��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_5th , 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_5th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_5th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_5th         --�̔��v��|��_�T��
        --=====================
        --�U��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_6th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_6th       --�̔��v��P�[�X��_�U��
       ,NVL( SMFC.fc_qty_6th   , 0 )                                  fc_qty_6th          --�̔��v��o����_�U��
       ,NVL( SMFC.fc_amt_6th   , 0 )                                  fc_amt_6th          --�̔��v����z_�U��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_6th , 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_6th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_6th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_6th         --�̔��v��|��_�U��
        --=====================
        --�V��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_7th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_7th       --�̔��v��P�[�X��_�V��
       ,NVL( SMFC.fc_qty_7th   , 0 )                                  fc_qty_7th          --�̔��v��o����_�V��
       ,NVL( SMFC.fc_amt_7th   , 0 )                                  fc_amt_7th          --�̔��v����z_�V��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_7th , 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_7th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_7th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_7th         --�̔��v��|��_�V��
        --=====================
        --�W��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_8th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_8th       --�̔��v��P�[�X��_�W��
       ,NVL( SMFC.fc_qty_8th   , 0 )                                  fc_qty_8th          --�̔��v��o����_�W��
       ,NVL( SMFC.fc_amt_8th   , 0 )                                  fc_amt_8th          --�̔��v����z_�W��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_8th , 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_8th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_8th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_8th         --�̔��v��|��_�W��
        --=====================
        --�X��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_9th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_9th       --�̔��v��P�[�X��_�X��
       ,NVL( SMFC.fc_qty_9th   , 0 )                                  fc_qty_9th          --�̔��v��o����_�X��
       ,NVL( SMFC.fc_amt_9th   , 0 )                                  fc_amt_9th          --�̔��v����z_�X��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_9th , 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_9th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_9th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_9th         --�̔��v��|��_�X��
        --=====================
        --�P�O��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_10th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_10th      --�̔��v��P�[�X��_�P�O��
       ,NVL( SMFC.fc_qty_10th  , 0 )                                  fc_qty_10th         --�̔��v��o����_�P�O��
       ,NVL( SMFC.fc_amt_10th  , 0 )                                  fc_amt_10th         --�̔��v����z_�P�O��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_10th, 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_10th / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_10th ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_10th        --�̔��v��|��_�P�O��
        --=====================
        --�P�P��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_11th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_11th      --�̔��v��P�[�X��_�P�P��
       ,NVL( SMFC.fc_qty_11th  , 0 )                                  fc_qty_11th         --�̔��v��o����_�P�P��
       ,NVL( SMFC.fc_amt_11th  , 0 )                                  fc_amt_11th         --�̔��v����z_�P�P��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_11th, 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_11th / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_11th ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_11th        --�̔��v��|��_�P�P��
        --=====================
        --�P�Q��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_12th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_12th      --�̔��v��P�[�X��_�P�Q��
       ,NVL( SMFC.fc_qty_12th  , 0 )                                  fc_qty_12th         --�̔��v��o����_�P�Q��
       ,NVL( SMFC.fc_amt_12th  , 0 )                                  fc_amt_12th         --�̔��v����z_�P�Q��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_12th, 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_12th / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_12th ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_12th        --�̔��v��|��_�P�Q��
        --=====================
        --�P��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_1th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_1th       --�̔��v��P�[�X��_�P��
       ,NVL( SMFC.fc_qty_1th   , 0 )                                  fc_qty_1th          --�̔��v��o����_�P��
       ,NVL( SMFC.fc_amt_1th   , 0 )                                  fc_amt_1th          --�̔��v����z_�P��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_1th , 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_1th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_1th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_1th         --�̔��v��|��_�P��
        --=====================
        --�Q��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_2th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_2th       --�̔��v��P�[�X��_�Q��
       ,NVL( SMFC.fc_qty_2th   , 0 )                                  fc_qty_2th          --�̔��v��o����_�Q��
       ,NVL( SMFC.fc_amt_2th   , 0 )                                  fc_amt_2th          --�̔��v����z_�Q��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_2th , 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_2th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_2th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_2th         --�̔��v��|��_�Q��
        --=====================
        --�R��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_3th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_3th       --�̔��v��P�[�X��_�R��
       ,NVL( SMFC.fc_qty_3th   , 0 )                                  fc_qty_3th          --�̔��v��o����_�R��
       ,NVL( SMFC.fc_amt_3th   , 0 )                                  fc_amt_3th          --�̔��v����z_�R��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_3th , 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_3th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_3th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_3th         --�̔��v��|��_�R��
        --=====================
        --�S��
        --=====================
       ,NVL( TRUNC( SMFC.fc_qty_4th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_4th       --�̔��v��P�[�X��_�S��
       ,NVL( SMFC.fc_qty_4th   , 0 )                                  fc_qty_4th          --�̔��v��o����_�S��
       ,NVL( SMFC.fc_amt_4th   , 0 )                                  fc_amt_4th          --�̔��v����z_�S��
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_4th , 0 ) <> 0 THEN  --�[������΍�
                  NVL( ROUND( ( SMFC.fc_amt_4th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_4th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_4th         --�̔��v��|��_�S��
  FROM
       ( --�N���A����A���_�A�i�ڒP�ʂŏW�v�����̔��v��W�v�f�[�^
          SELECT
                  ICD.fiscal_year                                     year                --�N�x
                 ,MFDN.attribute5                                     generation          --����
                 -- 2009/05/12 T.Yoshimoto Mod Start �{��#1469
                 --,MFDN.attribute3                                     hs_branch           --���_
                 ,MFDT.attribute5                                     hs_branch           --���_
                 -- 2009/05/12 T.Yoshimoto Mod End �{��#1469
                 ,MFDT.inventory_item_id                              inv_item_id         --�i��ID(INV�i��ID)
                  --�N��
                 ,SUM( MFDT.current_forecast_quantity )               sum_year_qty        --�N�ԍ��v����
                 ,SUM( TO_NUMBER( MFDT.attribute2 )   )               sum_year_amt        --�N�ԍ��v���z
                  --�T��
                 ,SUM( CASE WHEN ICD.period =  1 THEN MFDT.current_forecast_quantity END )  fc_qty_5th     --�̔��v��o����_�T��
                 ,SUM( CASE WHEN ICD.period =  1 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_5th     --�̔��v����z_�T��
                  --�U��
                 ,SUM( CASE WHEN ICD.period =  2 THEN MFDT.current_forecast_quantity END )  fc_qty_6th     --�̔��v��o����_�U��
                 ,SUM( CASE WHEN ICD.period =  2 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_6th     --�̔��v����z_�U��
                  --�V��
                 ,SUM( CASE WHEN ICD.period =  3 THEN MFDT.current_forecast_quantity END )  fc_qty_7th     --�̔��v��o����_�V��
                 ,SUM( CASE WHEN ICD.period =  3 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_7th     --�̔��v����z_�V��
                  --�W��
                 ,SUM( CASE WHEN ICD.period =  4 THEN MFDT.current_forecast_quantity END )  fc_qty_8th     --�̔��v��o����_�W��
                 ,SUM( CASE WHEN ICD.period =  4 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_8th     --�̔��v����z_�W��
                  --�X��
                 ,SUM( CASE WHEN ICD.period =  5 THEN MFDT.current_forecast_quantity END )  fc_qty_9th     --�̔��v��o����_�X��
                 ,SUM( CASE WHEN ICD.period =  5 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_9th     --�̔��v����z_�X��
                  --�P�O��
                 ,SUM( CASE WHEN ICD.period =  6 THEN MFDT.current_forecast_quantity END )  fc_qty_10th    --�̔��v��o����_�P�O��
                 ,SUM( CASE WHEN ICD.period =  6 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_10th    --�̔��v����z_�P�O��
                  --�P�P��
                 ,SUM( CASE WHEN ICD.period =  7 THEN MFDT.current_forecast_quantity END )  fc_qty_11th    --�̔��v��o����_�P�P��
                 ,SUM( CASE WHEN ICD.period =  7 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_11th    --�̔��v����z_�P�P��
                  --�P�Q��
                 ,SUM( CASE WHEN ICD.period =  8 THEN MFDT.current_forecast_quantity END )  fc_qty_12th    --�̔��v��o����_�P�Q��
                 ,SUM( CASE WHEN ICD.period =  8 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_12th    --�̔��v����z_�P�Q��
                  --�P��
                 ,SUM( CASE WHEN ICD.period =  9 THEN MFDT.current_forecast_quantity END )  fc_qty_1th     --�̔��v��o����_�P��
                 ,SUM( CASE WHEN ICD.period =  9 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_1th     --�̔��v����z_�P��
                  --�Q��
                 ,SUM( CASE WHEN ICD.period = 10 THEN MFDT.current_forecast_quantity END )  fc_qty_2th     --�̔��v��o����_�Q��
                 ,SUM( CASE WHEN ICD.period = 10 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_2th     --�̔��v����z_�Q��
                  --�R��
                 ,SUM( CASE WHEN ICD.period = 11 THEN MFDT.current_forecast_quantity END )  fc_qty_3th     --�̔��v��o����_�R��
                 ,SUM( CASE WHEN ICD.period = 11 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_3th     --�̔��v����z_�R��
                  --�S��
                 ,SUM( CASE WHEN ICD.period = 12 THEN MFDT.current_forecast_quantity END )  fc_qty_4th     --�̔��v��o����_�S��
                 ,SUM( CASE WHEN ICD.period = 12 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_4th     --�̔��v����z_�S��
            FROM
                  ic_cldr_dtl                               ICD                 --�݌ɃJ�����_
                 ,mrp_forecast_designators                  MFDN                --�t�H�[�L���X�g���e�[�u��
                 ,mrp_forecast_dates                        MFDT                --�t�H�[�L���X�g���t�e�[�u��
           WHERE
             --�̔��v��f�[�^�擾����
                  MFDN.attribute1                           = '05'              --05:�̔��v��
             AND (    MFDT.current_forecast_quantity       <> 0
                   OR TO_NUMBER( MFDT.attribute2 )         <> 0
                 )
             AND  MFDN.organization_id                      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
             AND  MFDN.forecast_designator                  = MFDT.forecast_designator
             AND  MFDN.organization_id                      = MFDT.organization_id
             --�݌ɃJ�����_�Ƃ̌�������
             AND  ICD.orgn_code = 'ITOE'
             AND  TO_CHAR( MFDT.forecast_date, 'YYYYMM' )   = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
          GROUP BY
                  ICD.fiscal_year                           --�N�x
                 ,MFDN.attribute5                           --����
                 -- 2009/05/12 T.Yoshimoto Mod Start �{��#1469
                 --,MFDN.attribute3                           --���_
                 ,MFDT.attribute5                           --���_
                 -- 2009/05/12 T.Yoshimoto Mod End �{��#1469
                 ,MFDT.inventory_item_id                    --�i��ID(INV�i��ID)
       )                           SMFC                     --�̔��v��W�v
       ,xxsky_cust_accounts_v      BRCH                     --���_���擾�p�iSYSDATE�ŗL���f�[�^�𒊏o�j
       ,xxsky_item_mst_v           ITEM                     --�i�ږ��擾�p�iSYSDATE�ŗL���f�[�^�𒊏o�j
       ,xxsky_prod_class_v         PRODC                    --���i�敪�擾�p
       ,xxsky_item_class_v         ITEMC                    --�i�ڋ敪�擾�p
       ,xxsky_crowd_code_v         CROWD                    --�Q�R�[�h�擾�p
       ,ic_item_mst_b              ITEMB                    --�i�ڕʒ艿�擾�p
 WHERE
   --���_���擾�iSYSDATE�ŗL���f�[�^�𒊏o�j
        SMFC.hs_branch             = BRCH.party_number(+)
   --�i�ڏ��擾�iSYSDATE�ŗL���f�[�^�𒊏o�j
   AND  SMFC.inv_item_id           = ITEM.inventory_item_id(+)
   --�i�ڃJ�e�S�����擾
   AND  ITEM.item_id               = PRODC.item_id(+)       --���i�敪
   AND  ITEM.item_id               = ITEMC.item_id(+)       --�i�ڋ敪
   AND  ITEM.item_id               = CROWD.item_id(+)       --�Q�R�[�h
   --�i�ڕʒ艿�擾
   AND  ITEM.item_id               = ITEMB.item_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�̔��v�掞�n��_��{_V IS 'XXSKY_�̔��v�掞�n�� (��{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�N�x                    IS '�N�x'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.����                    IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.���_�R�[�h              IS '���_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.���_��                  IS '���_��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.���i�敪                IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.���i�敪��              IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�i�ڋ敪                IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�i�ڋ敪��              IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�Q�R�[�h                IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�i�ڃR�[�h              IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�i�ږ�                  IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�i�ڗ���                IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�N�ԍ��v�P�[�X��        IS '�N�ԍ��v�P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�N�ԍ��v�o����          IS '�N�ԍ��v�o����'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�N�ԍ��v���z            IS '�N�ԍ��v���z'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�N�Ԋ|��                IS '�N�Ԋ|��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�T��   IS '�̔��v��P�[�X��_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�T��     IS '�̔��v��o����_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�T��       IS '�̔��v����z_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�T��       IS '�̔��v��|��_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�U��   IS '�̔��v��P�[�X��_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�U��     IS '�̔��v��o����_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�U��       IS '�̔��v����z_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�U��       IS '�̔��v��|��_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�V��   IS '�̔��v��P�[�X��_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�V��     IS '�̔��v��o����_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�V��       IS '�̔��v����z_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�V��       IS '�̔��v��|��_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�W��   IS '�̔��v��P�[�X��_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�W��     IS '�̔��v��o����_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�W��       IS '�̔��v����z_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�W��       IS '�̔��v��|��_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�X��   IS '�̔��v��P�[�X��_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�X��     IS '�̔��v��o����_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�X��       IS '�̔��v����z_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�X��       IS '�̔��v��|��_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�P�O�� IS '�̔��v��P�[�X��_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�P�O��   IS '�̔��v��o����_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�P�O��     IS '�̔��v����z_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�P�O��     IS '�̔��v��|��_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�P�P�� IS '�̔��v��P�[�X��_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�P�P��   IS '�̔��v��o����_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�P�P��     IS '�̔��v����z_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�P�P��     IS '�̔��v��|��_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�P�Q�� IS '�̔��v��P�[�X��_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�P�Q��   IS '�̔��v��o����_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�P�Q��     IS '�̔��v����z_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�P�Q��     IS '�̔��v��|��_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�P��   IS '�̔��v��P�[�X��_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�P��     IS '�̔��v��o����_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�P��       IS '�̔��v����z_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�P��       IS '�̔��v��|��_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�Q��   IS '�̔��v��P�[�X��_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�Q��     IS '�̔��v��o����_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�Q��       IS '�̔��v����z_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�Q��       IS '�̔��v��|��_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�R��   IS '�̔��v��P�[�X��_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�R��     IS '�̔��v��o����_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�R��       IS '�̔��v����z_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�R��       IS '�̔��v��|��_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��P�[�X��_�S��   IS '�̔��v��P�[�X��_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��o����_�S��     IS '�̔��v��o����_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v����z_�S��       IS '�̔��v����z_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�̔��v�掞�n��_��{_V.�̔��v��|��_�S��       IS '�̔��v��|��_�S��'
/
