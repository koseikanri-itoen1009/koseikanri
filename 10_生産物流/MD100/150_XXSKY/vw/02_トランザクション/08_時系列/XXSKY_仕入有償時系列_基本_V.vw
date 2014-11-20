CREATE OR REPLACE VIEW APPS.XXSKY_�d���L�����n��_��{_V
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
,�d�����z_�T��
,�d�������_�T��
,�L������_�T��
,�L���݌ɋ��z_�T��
,�L�����z_�T��
,�L�������_�T��
,�d������_�U��
,�d�����z_�U��
,�d�������_�U��
,�L������_�U��
,�L���݌ɋ��z_�U��
,�L�����z_�U��
,�L�������_�U��
,�d������_�V��
,�d�����z_�V��
,�d�������_�V��
,�L������_�V��
,�L���݌ɋ��z_�V��
,�L�����z_�V��
,�L�������_�V��
,�d������_�W��
,�d�����z_�W��
,�d�������_�W��
,�L������_�W��
,�L���݌ɋ��z_�W��
,�L�����z_�W��
,�L�������_�W��
,�d������_�X��
,�d�����z_�X��
,�d�������_�X��
,�L������_�X��
,�L���݌ɋ��z_�X��
,�L�����z_�X��
,�L�������_�X��
,�d������_�P�O��
,�d�����z_�P�O��
,�d�������_�P�O��
,�L������_�P�O��
,�L���݌ɋ��z_�P�O��
,�L�����z_�P�O��
,�L�������_�P�O��
,�d������_�P�P��
,�d�����z_�P�P��
,�d�������_�P�P��
,�L������_�P�P��
,�L���݌ɋ��z_�P�P��
,�L�����z_�P�P��
,�L�������_�P�P��
,�d������_�P�Q��
,�d�����z_�P�Q��
,�d�������_�P�Q��
,�L������_�P�Q��
,�L���݌ɋ��z_�P�Q��
,�L�����z_�P�Q��
,�L�������_�P�Q��
,�d������_�P��
,�d�����z_�P��
,�d�������_�P��
,�L������_�P��
,�L���݌ɋ��z_�P��
,�L�����z_�P��
,�L�������_�P��
,�d������_�Q��
,�d�����z_�Q��
,�d�������_�Q��
,�L������_�Q��
,�L���݌ɋ��z_�Q��
,�L�����z_�Q��
,�L�������_�Q��
,�d������_�R��
,�d�����z_�R��
,�d�������_�R��
,�L������_�R��
,�L���݌ɋ��z_�R��
,�L�����z_�R��
,�L�������_�R��
,�d������_�S��
,�d�����z_�S��
,�d�������_�S��
,�L������_�S��
,�L���݌ɋ��z_�S��
,�L�����z_�S��
,�L�������_�S��
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
        --�T���W�v
       ,NVL( SMRP.rcv_qty_5th    , 0 )    rcv_qty_5th            --�d������_�T��
       ,NVL( SMRP.rcv_price_5th  , 0 )    rcv_price_5th          --�d�����z_�T��
       ,NVL( SMRP.rcv_cn_tax_5th , 0 )    rcv_cn_tax_5th         --�d�������_�T��
       ,NVL( SMRP.pay_qty_5th    , 0 )    pay_qty_5th            --�L������_�T��
       ,NVL( SMRP.inv_price_5th  , 0 )    inv_price_5th          --�L���݌ɋ��z_�T��
       ,NVL( SMRP.pay_price_5th  , 0 )    pay_price_5th          --�L�����z_�T��
       ,NVL( SMRP.pay_cn_tax_5th , 0 )    pay_cn_tax_5th         --�L�������_�T��
        --�U���W�v
       ,NVL( SMRP.rcv_qty_6th    , 0 )    rcv_qty_6th            --�d������_�U��
       ,NVL( SMRP.rcv_price_6th  , 0 )    rcv_price_6th          --�d�����z_�U��
       ,NVL( SMRP.rcv_cn_tax_6th , 0 )    rcv_cn_tax_6th         --�d�������_�U��
       ,NVL( SMRP.pay_qty_6th    , 0 )    pay_qty_6th            --�L������_�U��
       ,NVL( SMRP.inv_price_6th  , 0 )    inv_price_6th          --�L���݌ɋ��z_�U��
       ,NVL( SMRP.pay_price_6th  , 0 )    pay_price_6th          --�L�����z_�U��
       ,NVL( SMRP.pay_cn_tax_6th , 0 )    pay_cn_tax_6th         --�L�������_�U��
        --�V���W�v
       ,NVL( SMRP.rcv_qty_7th    , 0 )    rcv_qty_7th            --�d������_�V��
       ,NVL( SMRP.rcv_price_7th  , 0 )    rcv_price_7th          --�d�����z_�V��
       ,NVL( SMRP.rcv_cn_tax_7th , 0 )    rcv_cn_tax_7th         --�d�������_�V��
       ,NVL( SMRP.pay_qty_7th    , 0 )    pay_qty_7th            --�L������_�V��
       ,NVL( SMRP.inv_price_7th  , 0 )    inv_price_7th          --�L���݌ɋ��z_�V��
       ,NVL( SMRP.pay_price_7th  , 0 )    pay_price_7th          --�L�����z_�V��
       ,NVL( SMRP.pay_cn_tax_7th , 0 )    pay_cn_tax_7th         --�L�������_�V��
        --�W���W�v
       ,NVL( SMRP.rcv_qty_8th    , 0 )    rcv_qty_8th            --�d������_�W��
       ,NVL( SMRP.rcv_price_8th  , 0 )    rcv_price_8th          --�d�����z_�W��
       ,NVL( SMRP.rcv_cn_tax_8th , 0 )    rcv_cn_tax_8th         --�d�������_�W��
       ,NVL( SMRP.pay_qty_8th    , 0 )    pay_qty_8th            --�L������_�W��
       ,NVL( SMRP.inv_price_8th  , 0 )    inv_price_8th          --�L���݌ɋ��z_�W��
       ,NVL( SMRP.pay_price_8th  , 0 )    pay_price_8th          --�L�����z_�W��
       ,NVL( SMRP.pay_cn_tax_8th , 0 )    pay_cn_tax_8th         --�L�������_�W��
        --�X���W�v
       ,NVL( SMRP.rcv_qty_9th    , 0 )    rcv_qty_9th            --�d������_�X��
       ,NVL( SMRP.rcv_price_9th  , 0 )    rcv_price_9th          --�d�����z_�X��
       ,NVL( SMRP.rcv_cn_tax_9th , 0 )    rcv_cn_tax_9th         --�d�������_�X��
       ,NVL( SMRP.pay_qty_9th    , 0 )    pay_qty_9th            --�L������_�X��
       ,NVL( SMRP.inv_price_9th  , 0 )    inv_price_9th          --�L���݌ɋ��z_�X��
       ,NVL( SMRP.pay_price_9th  , 0 )    pay_price_9th          --�L�����z_�X��
       ,NVL( SMRP.pay_cn_tax_9th , 0 )    pay_cn_tax_9th         --�L�������_�X��
        --�P�O���W�v
       ,NVL( SMRP.rcv_qty_10th   , 0 )    rcv_qty_10th           --�d������_�P�O��
       ,NVL( SMRP.rcv_price_10th , 0 )    rcv_price_10th         --�d�����z_�P�O��
       ,NVL( SMRP.rcv_cn_tax_10th, 0 )    rcv_cn_tax_10th        --�d�������_�P�O��
       ,NVL( SMRP.pay_qty_10th   , 0 )    pay_qty_10th           --�L������_�P�O��
       ,NVL( SMRP.inv_price_10th , 0 )    inv_price_10th         --�L���݌ɋ��z_�P�O��
       ,NVL( SMRP.pay_price_10th , 0 )    pay_price_10th         --�L�����z_�P�O��
       ,NVL( SMRP.pay_cn_tax_10th, 0 )    pay_cn_tax_10th        --�L�������_�P�O��
        --�P�P���W�v
       ,NVL( SMRP.rcv_qty_11th   , 0 )    rcv_qty_11th           --�d������_�P�P��
       ,NVL( SMRP.rcv_price_11th , 0 )    rcv_price_11th         --�d�����z_�P�P��
       ,NVL( SMRP.rcv_cn_tax_11th, 0 )    rcv_cn_tax_11th        --�d�������_�P�P��
       ,NVL( SMRP.pay_qty_11th   , 0 )    pay_qty_11th           --�L������_�P�P��
       ,NVL( SMRP.inv_price_11th , 0 )    inv_price_11th         --�L���݌ɋ��z_�P�P��
       ,NVL( SMRP.pay_price_11th , 0 )    pay_price_11th         --�L�����z_�P�P��
       ,NVL( SMRP.pay_cn_tax_11th, 0 )    pay_cn_tax_11th        --�L�������_�P�P��
        --�P�Q���W�v
       ,NVL( SMRP.rcv_qty_12th   , 0 )    rcv_qty_12th           --�d������_�P�Q��
       ,NVL( SMRP.rcv_price_12th , 0 )    rcv_price_12th         --�d�����z_�P�Q��
       ,NVL( SMRP.rcv_cn_tax_12th, 0 )    rcv_cn_tax_12th        --�d�������_�P�Q��
       ,NVL( SMRP.pay_qty_12th   , 0 )    pay_qty_12th           --�L������_�P�Q��
       ,NVL( SMRP.inv_price_12th , 0 )    inv_price_12th         --�L���݌ɋ��z_�P�Q��
       ,NVL( SMRP.pay_price_12th , 0 )    pay_price_12th         --�L�����z_�P�Q��
       ,NVL( SMRP.pay_cn_tax_12th, 0 )    pay_cn_tax_12th        --�L�������_�P�Q��
        --�P���W�v
       ,NVL( SMRP.rcv_qty_1th    , 0 )    rcv_qty_1th            --�d������_�P��
       ,NVL( SMRP.rcv_price_1th  , 0 )    rcv_price_1th          --�d�����z_�P��
       ,NVL( SMRP.rcv_cn_tax_1th , 0 )    rcv_cn_tax_1th         --�d�������_�P��
       ,NVL( SMRP.pay_qty_1th    , 0 )    pay_qty_1th            --�L������_�P��
       ,NVL( SMRP.inv_price_1th  , 0 )    inv_price_1th          --�L���݌ɋ��z_�P��
       ,NVL( SMRP.pay_price_1th  , 0 )    pay_price_1th          --�L�����z_�P��
       ,NVL( SMRP.pay_cn_tax_1th , 0 )    pay_cn_tax_1th         --�L�������_�P��
        --�Q���W�v
       ,NVL( SMRP.rcv_qty_2th    , 0 )    rcv_qty_2th            --�d������_�Q��
       ,NVL( SMRP.rcv_price_2th  , 0 )    rcv_price_2th          --�d�����z_�Q��
       ,NVL( SMRP.rcv_cn_tax_2th , 0 )    rcv_cn_tax_2th         --�d�������_�Q��
       ,NVL( SMRP.pay_qty_2th    , 0 )    pay_qty_2th            --�L������_�Q��
       ,NVL( SMRP.inv_price_2th  , 0 )    inv_price_2th          --�L���݌ɋ��z_�Q��
       ,NVL( SMRP.pay_price_2th  , 0 )    pay_price_2th          --�L�����z_�Q��
       ,NVL( SMRP.pay_cn_tax_2th , 0 )    pay_cn_tax_2th         --�L�������_�Q��
        --�R���W�v
       ,NVL( SMRP.rcv_qty_3th    , 0 )    rcv_qty_3th            --�d������_�R��
       ,NVL( SMRP.rcv_price_3th  , 0 )    rcv_price_3th          --�d�����z_�R��
       ,NVL( SMRP.rcv_cn_tax_3th , 0 )    rcv_cn_tax_3th         --�d�������_�R��
       ,NVL( SMRP.pay_qty_3th    , 0 )    pay_qty_3th            --�L������_�R��
       ,NVL( SMRP.inv_price_3th  , 0 )    inv_price_3th          --�L���݌ɋ��z_�R��
       ,NVL( SMRP.pay_price_3th  , 0 )    pay_price_3th          --�L�����z_�R��
       ,NVL( SMRP.pay_cn_tax_3th , 0 )    pay_cn_tax_3th         --�L�������_�R��
        --�S���W�v
       ,NVL( SMRP.rcv_qty_4th    , 0 )    rcv_qty_4th            --�d������_�S��
       ,NVL( SMRP.rcv_price_4th  , 0 )    rcv_price_4th          --�d�����z_�S��
       ,NVL( SMRP.rcv_cn_tax_4th , 0 )    rcv_cn_tax_4th         --�d�������_�S��
       ,NVL( SMRP.pay_qty_4th    , 0 )    pay_qty_4th            --�L������_�S��
       ,NVL( SMRP.inv_price_4th  , 0 )    inv_price_4th          --�L���݌ɋ��z_�S��
       ,NVL( SMRP.pay_price_4th  , 0 )    pay_price_4th          --�L�����z_�S��
       ,NVL( SMRP.pay_cn_tax_4th , 0 )    pay_cn_tax_4th         --�L�������_�S��
  FROM  (  --�N�x�A�����A�����A�i�ځA�d���`�ԒP�ʂŏW�v�����i���x�W�v�����ɂ����j�d���L���W�v�f�[�^
           SELECT  ICD.fiscal_year                                            year             --�N�x
                  ,RVPY.dept_code                                             dept_code        --�����R�[�h
                  ,RVPY.vendor_id                                             vendor_id        --�����ID
                  ,RVPY.item_code                                             item_code        --�i��
                  ,RVPY.rcv_class                                             rcv_class        --�d���`��
                   --�T���W�v
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.rcv_qty    END )  rcv_qty_5th      --�d������_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.rcv_price  END )  rcv_price_5th    --�d�����z_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_5th   --�d�������_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.pay_qty    END )  pay_qty_5th      --�L������_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.inv_price  END )  inv_price_5th    --�L���݌ɋ��z_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.pay_price  END )  pay_price_5th    --�L�����z_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.pay_cn_tax END )  pay_cn_tax_5th   --�L�������_�T��
                   --�U���W�v
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.rcv_qty    END )  rcv_qty_6th      --�d������_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.rcv_price  END )  rcv_price_6th    --�d�����z_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_6th   --�d�������_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.pay_qty    END )  pay_qty_6th      --�L������_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.inv_price  END )  inv_price_6th    --�L���݌ɋ��z_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.pay_price  END )  pay_price_6th    --�L�����z_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.pay_cn_tax END )  pay_cn_tax_6th   --�L�������_�U��
                   --�V���W�v
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.rcv_qty    END )  rcv_qty_7th      --�d������_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.rcv_price  END )  rcv_price_7th    --�d�����z_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_7th   --�d�������_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.pay_qty    END )  pay_qty_7th      --�L������_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.inv_price  END )  inv_price_7th    --�L���݌ɋ��z_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.pay_price  END )  pay_price_7th    --�L�����z_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.pay_cn_tax END )  pay_cn_tax_7th   --�L�������_�V��
                   --�W���W�v
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.rcv_qty    END )  rcv_qty_8th      --�d������_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.rcv_price  END )  rcv_price_8th    --�d�����z_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_8th   --�d�������_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.pay_qty    END )  pay_qty_8th      --�L������_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.inv_price  END )  inv_price_8th    --�L���݌ɋ��z_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.pay_price  END )  pay_price_8th    --�L�����z_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.pay_cn_tax END )  pay_cn_tax_8th   --�L�������_�W��
                   --�X���W�v
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.rcv_qty    END )  rcv_qty_9th      --�d������_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.rcv_price  END )  rcv_price_9th    --�d�����z_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_9th   --�d�������_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.pay_qty    END )  pay_qty_9th      --�L������_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.inv_price  END )  inv_price_9th    --�L���݌ɋ��z_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.pay_price  END )  pay_price_9th    --�L�����z_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.pay_cn_tax END )  pay_cn_tax_9th   --�L�������_�X��
                   --�P�O���W�v
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.rcv_qty    END )  rcv_qty_10th     --�d������_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.rcv_price  END )  rcv_price_10th   --�d�����z_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_10th  --�d�������_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.pay_qty    END )  pay_qty_10th     --�L������_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.inv_price  END )  inv_price_10th   --�L���݌ɋ��z_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.pay_price  END )  pay_price_10th   --�L�����z_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.pay_cn_tax END )  pay_cn_tax_10th  --�L�������_�P�O��
                   --�P�P���W�v
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.rcv_qty    END )  rcv_qty_11th     --�d������_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.rcv_price  END )  rcv_price_11th   --�d�����z_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_11th  --�d�������_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.pay_qty    END )  pay_qty_11th     --�L������_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.inv_price  END )  inv_price_11th   --�L���݌ɋ��z_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.pay_price  END )  pay_price_11th   --�L�����z_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.pay_cn_tax END )  pay_cn_tax_11th  --�L�������_�P�P��
                   --�P�Q���W�v
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.rcv_qty    END )  rcv_qty_12th     --�d������_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.rcv_price  END )  rcv_price_12th   --�d�����z_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_12th  --�d�������_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.pay_qty    END )  pay_qty_12th     --�L������_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.inv_price  END )  inv_price_12th   --�L���݌ɋ��z_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.pay_price  END )  pay_price_12th   --�L�����z_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.pay_cn_tax END )  pay_cn_tax_12th  --�L�������_�P�Q��
                   --�P���W�v
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.rcv_qty    END )  rcv_qty_1th      --�d������_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.rcv_price  END )  rcv_price_1th    --�d�����z_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_1th   --�d�������_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.pay_qty    END )  pay_qty_1th      --�L������_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.inv_price  END )  inv_price_1th    --�L���݌ɋ��z_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.pay_price  END )  pay_price_1th    --�L�����z_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.pay_cn_tax END )  pay_cn_tax_1th   --�L�������_�P��
                   --�Q���W�v
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.rcv_qty    END )  rcv_qty_2th      --�d������_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.rcv_price  END )  rcv_price_2th    --�d�����z_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_2th   --�d�������_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.pay_qty    END )  pay_qty_2th      --�L������_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.inv_price  END )  inv_price_2th    --�L���݌ɋ��z_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.pay_price  END )  pay_price_2th    --�L�����z_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.pay_cn_tax END )  pay_cn_tax_2th   --�L�������_�Q��
                   --�R���W�v
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.rcv_qty    END )  rcv_qty_3th      --�d������_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.rcv_price  END )  rcv_price_3th    --�d�����z_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_3th   --�d�������_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.pay_qty    END )  pay_qty_3th      --�L������_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.inv_price  END )  inv_price_3th    --�L���݌ɋ��z_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.pay_price  END )  pay_price_3th    --�L�����z_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.pay_cn_tax END )  pay_cn_tax_3th   --�L�������_�R��
                   --�S���W�v
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.rcv_qty    END )  rcv_qty_4th      --�d������_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.rcv_price  END )  rcv_price_4th    --�d�����z_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_4th   --�d�������_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.pay_qty    END )  pay_qty_4th      --�L������_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.inv_price  END )  inv_price_4th    --�L���݌ɋ��z_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.pay_price  END )  pay_price_4th    --�L�����z_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.pay_cn_tax END )  pay_cn_tax_4th   --�L�������_�S��
             FROM  ( --����{�d���ԕi�{�L���x���̎��уf�[�^��UNION ALL�Ŏ擾
                      ----------------------------------------------
                      -- ��������f�[�^
                      --  �����[�w�d�����ѕ\�x�̏���Ŋz�ƈ�v������ׁA�ۗ��݌Ƀg�����U�N�V�������Q��
                      ----------------------------------------------
                      SELECT  ITP.trans_date                    tran_date       --�Ώۓ�(�����)
                             ,PHA.attribute10                   dept_code       --�����R�[�h
                             ,PHA.vendor_id                     vendor_id       --�����ID
                             ,IIMB.item_no                      item_code       --�i��
                             ,ILTM.attribute9                   rcv_class       --�d���`��
                             ,ITP.trans_qty                     rcv_qty         --�d������
                             ,ROUND( PLA.unit_price * ITP.trans_qty )
                                                                rcv_price       --�d�����z( ���ےP���y���������ׂ̂��̂��g�p�z * ���� )
                             ,ROUND( ROUND( PLA.unit_price * ITP.trans_qty ) * ( TO_NUMBER( FLV01.lookup_code ) * 0.01 ) )
                                                                rcv_cn_tax      --�d�������( �d�����z * (����ŗ�*0.01) )
                             ,0                                 pay_qty         --�L������
                             ,0                                 inv_price       --�L���݌ɋ��z
                             ,0                                 pay_price       --�L�����z
                             ,0                                 pay_cn_tax      --�L�������
                        FROM  ic_tran_pnd                       ITP             --�ۗ��݌Ƀg�����U�N�V����
                             ,rcv_shipment_lines                RSL             --�������
                             ,po_headers_all                    PHA             --�����w�b�_
                             ,po_lines_all                      PLA             --��������
                             ,ic_item_mst_b                     IIMB            --OPM�i�ڃ}�X�^(�i�ڃR�[�h�擾�p)
                             ,ic_lots_mst                       ILTM            --���b�g���擾�p
                             ,fnd_lookup_values                 FLV01           --����ŗ��擾�p
                       WHERE
                         --�ۗ��݌Ƀg�����U�N�V�����f�[�^�擾
                              ITP.doc_type = 'PORC'                             --�w���֘A
                         AND  ITP.completed_ind = 1                             --����
                         AND  ITP.trans_qty <> 0
                         --������׃f�[�^�̎擾
                         AND  RSL.source_document_code = 'PO'
                         AND  ITP.doc_id = RSL.shipment_header_id
                         AND  ITP.doc_line = RSL.line_num
                         --�����������уf�[�^�擾
                         AND  RSL.po_header_id = PHA.po_header_id
                         AND  RSL.po_header_id = PLA.po_header_id
                         AND  RSL.po_line_id = PLA.po_line_id
                         --�i�ڃR�[�h�擾
                         AND  ITP.item_id = IIMB.item_id
                         --���b�g���擾
                         AND  ITP.item_id = ILTM.item_id(+)
                         AND  ITP.lot_id = ILTM.lot_id(+)
                         --����ŗ��擾
                         AND  FLV01.language(+) = 'JA'
                         AND  FLV01.lookup_type(+) = 'XXCMN_CONSUMPTION_TAX_RATE'
                         AND  NVL( FLV01.start_date_active(+), TO_DATE( '19000101', 'YYYYMMDD' ) ) <= ITP.trans_date
                         AND  NVL( FLV01.end_date_active(+)  , TO_DATE( '99991231', 'YYYYMMDD' ) ) >= ITP.trans_date
                      -- [ ��������f�[�^ END ] --
                    UNION ALL
                      ----------------------------------------------
                      -- ��������ԕi����������ԕi�f�[�^
                      --  �����[�w�d�����ѕ\�x�̏���Ŋz�ƈ�v������ׁA�����g�����U�N�V�������Q��
                      --  �� ���l�E���z�̓}�C�i�X�l�ƂȂ�
                      ----------------------------------------------
                      SELECT  ITC.trans_date                    tran_date       --�Ώۓ�(�����)
                             ,XRRT.department_code              dept_code       --�����R�[�h
                             ,XRRT.vendor_id                    vendor_id       --�����ID
                             ,XRRT.item_code                    item_code       --�i��
                             ,ILTM.attribute9                   rcv_class       --�d���`��
                              --�ȉ��̍��ڂ́w�ԕi�x�Ȃ̂Ń}�C�i�X�Ōv�シ��
                             ,ITC.trans_qty                     rcv_qty         --�d������
                             ,ROUND( XRRT.unit_price * ITC.trans_qty )
                                                                rcv_price       --�d�����z( ���ےP���y������A�h�I���̂��̂��g�p�z * ���� )
                             ,ROUND( ROUND( XRRT.unit_price * ITC.trans_qty ) * ( TO_NUMBER( FLV01.lookup_code ) * 0.01 ) )
                                                                rcv_cn_tax      --�d�������( �d�����z * (����ŗ�*0.01) )
                             ,0                                 pay_qty         --�L������
                             ,0                                 inv_price       --�L���݌ɋ��z
                             ,0                                 pay_price       --�L�����z
                             ,0                                 pay_cn_tax      --�L�������
                        FROM  ic_tran_cmp                       ITC             --�����g�����U�N�V����
                             ,ic_adjs_jnl                       IAJ             --�݌ɒ����W���[�i��
                             ,ic_jrnl_mst                       IJM             --�W���[�i���}�X�^
                             ,xxpo_rcv_and_rtn_txns             XRRT            --����ԕi����
                             ,ic_lots_mst                       ILTM            --���b�g���擾�p
                             ,fnd_lookup_values                 FLV01           --����ŗ��擾�p
                       WHERE
                         --�����g�����U�N�V�����f�[�^�擾
                              ITC.doc_type = 'ADJI'                             --�݌ɒ���
                         AND  ITC.reason_code = 'X201'                          --�d����ԕi
                         AND  ITC.trans_qty <> 0
                         --�݌ɒ����W���[�i���f�[�^�̎擾
                         AND  ITC.doc_type = IAJ.trans_type
                         AND  ITC.doc_id = IAJ.doc_id
                         AND  ITC.doc_line = IAJ.doc_line
                         --�W���[�i���}�X�^�f�[�^�̎擾
                         AND  IJM.attribute1 IS NOT NULL
                         AND  IAJ.journal_id = IJM.journal_id
                         --����ԕi���т̎擾
                         AND  TO_NUMBER( IJM.attribute1 ) = XRRT.txns_id        --�������ID
                         --���b�g���擾
                         AND  ITC.item_id = ILTM.item_id(+)
                         AND  ITC.lot_id = ILTM.lot_id(+)
                         --����ŗ��擾
                         AND  FLV01.language(+) = 'JA'
                         AND  FLV01.lookup_type(+) = 'XXCMN_CONSUMPTION_TAX_RATE'
                         AND  NVL( FLV01.start_date_active(+), TO_DATE( '19000101', 'YYYYMMDD' ) ) <= ITC.trans_date
                         AND  NVL( FLV01.end_date_active(+)  , TO_DATE( '99991231', 'YYYYMMDD' ) ) >= ITC.trans_date
                      -- [ ���������ԕi�f�[�^ END ] --
                    UNION ALL
                      ----------------------------------------------
                      -- �L���x���f�[�^
                      ----------------------------------------------
                      SELECT  PAY.tran_date                     tran_date       --�Ώۓ�(���ד�)
                             ,PAY.dept_code                     dept_code       --�����R�[�h
                             ,PAY.vendor_id                     vendor_id       --�����ID
                             ,PAY.item_code                     item_code       --�i��
                             ,ILM.attribute9                    rcv_class       --�d���`��
                             ,0                                 rcv_qty         --�d������
                             ,0                                 rcv_price       --�d�����z
                             ,0                                 rcv_cn_tax      --�d�������
                              --�L������
                             ,PAY.quantity                      pay_qty         --�L������
                              --�L���݌ɋ��z
                             ,ROUND( DECODE( IIM.attribute15, '0', TO_NUMBER( ILM.attribute7 )  --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                            , '1', XPH.total_amount             --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                            , 0 )
                                     * PAY.quantity
                                   )                            inv_price       --�L���݌ɋ��z( �P�� * ���ѐ��� )
                              --�L�����z
                             ,ROUND( PAY.unit_price * PAY.quantity )
                                                                pay_price       --�L�����z( ���ےP�� * �o�א��� )
                              --�L�������
                             ,ROUND( ROUND( PAY.unit_price * PAY.quantity ) * ( TO_NUMBER( FLV02.lookup_code ) * 0.01 ) )
                                                                pay_cn_tax      --�L�������( �L�����z * (����ŗ�*0.01) )
                        FROM  (  --�W���P���}�X�^�Ƃ̊O�������ׁ̈A���₢���킹�Ƃ���
-- 2010/01/08 T.Yoshimoto Mod Start E_�{�ғ�#716
                                 --SELECT  NVL( XOHA.arrival_date, XOHA.shipped_date )
                                   SELECT  XOHA.arrival_date
-- 2010/01/08 T.Yoshimoto Mod End E_�{�ғ�#716
                                                                           tran_date       --�Ώۓ�(���ד�)
                                        ,XOHA.performance_management_dept  dept_code       --�����R�[�h
                                        ,XOHA.vendor_id                    vendor_id       --�����ID
                                        ,XOLA.shipping_item_code           item_code       --�i�ڃR�[�h
                                        ,XOLA.unit_price                   unit_price      --���ےP��
                                        ,XMLD.item_id                      item_id         --�i��ID
                                        ,XMLD.lot_id                       lot_id          --���b�gID
                                        ,XMLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                                                                           quantity        --���ѐ��ʁi�w�x���ԕi�x�̏ꍇ�̓}�C�i�X�l�ƂȂ�j
                                   FROM  xxwsh_order_headers_all           XOHA            --�󒍃w�b�_
                                        ,xxwsh_order_lines_all             XOLA            --�󒍖���
                                        ,oe_transaction_types_all          OTTA            --�󒍃^�C�v�}�X�^
                                        ,xxinv_mov_lot_details             XMLD            --�ړ����b�g�ڍ�
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
-- 2010/01/08 T.Yoshimoto Mod Start E_�{�ғ�#716
                                    AND  XOHA.arrival_date IS NOT NULL
-- 2010/01/08 T.Yoshimoto Mod End E_�{�ғ�#716

                              )                                 PAY             --�x���f�[�^
                             ,ic_item_mst_b                     IIM             --OPM�i�ڃ}�X�^
                             ,ic_lots_mst                       ILM             --���b�g���擾�p
                             ,xxpo_price_headers                XPH             --�d��/�W���P���}�X�^
                             ,fnd_lookup_values                 FLV02           --����ŗ��擾�p
                       WHERE
                         --OPM�i�ڥ���b�g�}�X�^�Ƃ̌���
                              PAY.item_id = IIM.item_id
                         AND  PAY.item_id = ILM.item_id
                         AND  PAY.lot_id = ILM.lot_id
                         --�W���P���}�X�^�Ƃ̌���
                         AND  XPH.price_type(+) = '2'         --�W��
                         AND  PAY.item_id = XPH.item_id(+)
                         AND  PAY.tran_date >= XPH.start_date_active(+)
                         AND  PAY.tran_date <= XPH.end_date_active(+)
                         --����ŗ��擾
                         AND  FLV02.language(+) = 'JA'
                         AND  FLV02.lookup_type(+) = 'XXCMN_CONSUMPTION_TAX_RATE'
                         AND  NVL( FLV02.start_date_active(+), TO_DATE( '19000101', 'YYYYMMDD' ) ) <= PAY.tran_date
                         AND  NVL( FLV02.end_date_active(+)  , TO_DATE( '99991231', 'YYYYMMDD' ) ) >= PAY.tran_date
                      -- [ �L���x���f�[�^ END ] --
                   )                RVPY
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
COMMENT ON TABLE APPS.XXSKY_�d���L�����n��_��{_V IS 'SKYLINK�p �d���L�����n��i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�N�x                IS '�N�x'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.����                IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.������              IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�����              IS '�����'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.����於            IS '����於'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.���i�敪            IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.���i�敪��          IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�i�ڋ敪            IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�i�ڋ敪��          IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�Q�R�[�h            IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�i�ڃR�[�h          IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�i�ږ�              IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�i�ڗ���            IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d���`��            IS '�d���`��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d���`�Ԗ�          IS '�d���`�Ԗ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�T��       IS '�d������_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�T��       IS '�d�����z_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�T��     IS '�d�������_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�T��       IS '�L������_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�T��   IS '�L���݌ɋ��z_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�T��       IS '�L�����z_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�T��     IS '�L�������_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�U��       IS '�d������_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�U��       IS '�d�����z_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�U��     IS '�d�������_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�U��       IS '�L������_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�U��   IS '�L���݌ɋ��z_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�U��       IS '�L�����z_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�U��     IS '�L�������_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�V��       IS '�d������_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�V��       IS '�d�����z_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�V��     IS '�d�������_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�V��       IS '�L������_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�V��   IS '�L���݌ɋ��z_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�V��       IS '�L�����z_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�V��     IS '�L�������_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�W��       IS '�d������_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�W��       IS '�d�����z_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�W��     IS '�d�������_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�W��       IS '�L������_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�W��   IS '�L���݌ɋ��z_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�W��       IS '�L�����z_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�W��     IS '�L�������_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�X��       IS '�d������_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�X��       IS '�d�����z_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�X��     IS '�d�������_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�X��       IS '�L������_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�X��   IS '�L���݌ɋ��z_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�X��       IS '�L�����z_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�X��     IS '�L�������_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�P�O��     IS '�d������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�P�O��     IS '�d�����z_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�P�O��   IS '�d�������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�P�O��     IS '�L������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�P�O�� IS '�L���݌ɋ��z_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�P�O��     IS '�L�����z_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�P�O��   IS '�L�������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�P�P��     IS '�d������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�P�P��     IS '�d�����z_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�P�P��   IS '�d�������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�P�P��     IS '�L������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�P�P�� IS '�L���݌ɋ��z_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�P�P��     IS '�L�����z_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�P�P��   IS '�L�������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�P�Q��     IS '�d������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�P�Q��     IS '�d�����z_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�P�Q��   IS '�d�������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�P�Q��     IS '�L������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�P�Q�� IS '�L���݌ɋ��z_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�P�Q��     IS '�L�����z_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�P�Q��   IS '�L�������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�P��       IS '�d������_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�P��       IS '�d�����z_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�P��     IS '�d�������_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�P��       IS '�L������_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�P��   IS '�L���݌ɋ��z_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�P��       IS '�L�����z_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�P��     IS '�L�������_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�Q��       IS '�d������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�Q��       IS '�d�����z_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�Q��     IS '�d�������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�Q��       IS '�L������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�Q��   IS '�L���݌ɋ��z_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�Q��       IS '�L�����z_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�Q��     IS '�L�������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�R��       IS '�d������_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�R��       IS '�d�����z_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�R��     IS '�d�������_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�R��       IS '�L������_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�R��   IS '�L���݌ɋ��z_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�R��       IS '�L�����z_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�R��     IS '�L�������_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d������_�S��       IS '�d������_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�����z_�S��       IS '�d�����z_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�d�������_�S��     IS '�d�������_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L������_�S��       IS '�L������_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L���݌ɋ��z_�S��   IS '�L���݌ɋ��z_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�����z_�S��       IS '�L�����z_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���L�����n��_��{_V.�L�������_�S��     IS '�L�������_�S��'
/
