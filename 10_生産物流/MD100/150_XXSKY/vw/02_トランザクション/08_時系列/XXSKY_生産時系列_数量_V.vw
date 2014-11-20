CREATE OR REPLACE VIEW APPS.XXSKY_���Y���n��_����_V
(
 �N�x
,���ъǗ�����
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�`�[�敪
,�H��
,�H������
,�H���E�v
,��������_�T��
,���Y������_�T��
,�ō�����_�T��
,�o��������_�T��
,���ސ���_�T��
,�Ǝҕs�ǐ���_�T��
,�����s�ǐ���_�T��
,��������_�U��
,���Y������_�U��
,�ō�����_�U��
,�o��������_�U��
,���ސ���_�U��
,�Ǝҕs�ǐ���_�U��
,�����s�ǐ���_�U��
,��������_�V��
,���Y������_�V��
,�ō�����_�V��
,�o��������_�V��
,���ސ���_�V��
,�Ǝҕs�ǐ���_�V��
,�����s�ǐ���_�V��
,��������_�W��
,���Y������_�W��
,�ō�����_�W��
,�o��������_�W��
,���ސ���_�W��
,�Ǝҕs�ǐ���_�W��
,�����s�ǐ���_�W��
,��������_�X��
,���Y������_�X��
,�ō�����_�X��
,�o��������_�X��
,���ސ���_�X��
,�Ǝҕs�ǐ���_�X��
,�����s�ǐ���_�X��
,��������_�P�O��
,���Y������_�P�O��
,�ō�����_�P�O��
,�o��������_�P�O��
,���ސ���_�P�O��
,�Ǝҕs�ǐ���_�P�O��
,�����s�ǐ���_�P�O��
,��������_�P�P��
,���Y������_�P�P��
,�ō�����_�P�P��
,�o��������_�P�P��
,���ސ���_�P�P��
,�Ǝҕs�ǐ���_�P�P��
,�����s�ǐ���_�P�P��
,��������_�P�Q��
,���Y������_�P�Q��
,�ō�����_�P�Q��
,�o��������_�P�Q��
,���ސ���_�P�Q��
,�Ǝҕs�ǐ���_�P�Q��
,�����s�ǐ���_�P�Q��
,��������_�P��
,���Y������_�P��
,�ō�����_�P��
,�o��������_�P��
,���ސ���_�P��
,�Ǝҕs�ǐ���_�P��
,�����s�ǐ���_�P��
,��������_�Q��
,���Y������_�Q��
,�ō�����_�Q��
,�o��������_�Q��
,���ސ���_�Q��
,�Ǝҕs�ǐ���_�Q��
,�����s�ǐ���_�Q��
,��������_�R��
,���Y������_�R��
,�ō�����_�R��
,�o��������_�R��
,���ސ���_�R��
,�Ǝҕs�ǐ���_�R��
,�����s�ǐ���_�R��
,��������_�S��
,���Y������_�S��
,�ō�����_�S��
,�o��������_�S��
,���ސ���_�S��
,�Ǝҕs�ǐ���_�S��
,�����s�ǐ���_�S��
)
AS
SELECT  SMMR.year                          year               --�N�x
       ,SMMR.pm_dept                       pm_dept            --���ъǗ�����
       ,PRODC.prod_class_code              prod_class_code    --���i�敪
       ,PRODC.prod_class_name              prod_class_name    --���i�敪��
       ,ITEMC.item_class_code              item_class_code    --�i�ڋ敪
       ,ITEMC.item_class_name              item_class_name    --�i�ڋ敪��
       ,CROWD.crowd_code                   crowd_code         --�Q�R�[�h
       ,ITEM.item_no                       item_code          --�i�ڃR�[�h
       ,ITEM.item_name                     item_name          --�i�ږ�
       ,ITEM.item_short_name               item_s_name        --�i�ڗ���
       ,SMMR.slip_cls                      slip_cls           --�`�[�敪
       ,SMMR.rtng_no                       rtng_no            --�H��
       ,GRTT.routing_desc                  rtng_name          --�H������
       ,GRTT.routing_desc                  rtng_desc          --�H���E�v
        --�T��
       ,NVL( SMMR.invest_qty_5th  , 0 )    invest_qty_5th     --��������_�T��
       ,NVL( SMMR.product_qty_5th , 0 )    product_qty_5th    --���Y������_�T��
       ,NVL( SMMR.into_qty_5th    , 0 )    into_qty_5th       --�ō�����_�T��
       ,NVL( SMMR.output_qty_5th  , 0 )    output_qty_5th     --�o��������_�T��
       ,NVL( SMMR.mtrl_qty_5th    , 0 )    mtrl_qty_5th       --���ސ���_�T��
       ,NVL( SMMR.mfg_qty_5th     , 0 )    mfg_qty_5th        --�Ǝҕs�ǐ���_�T��
       ,NVL( SMMR.prod_qty_5th    , 0 )    prod_qty_5th       --�����s�ǐ���_�T��
        --�U��
       ,NVL( SMMR.invest_qty_6th  , 0 )    invest_qty_6th     --��������_�U��
       ,NVL( SMMR.product_qty_6th , 0 )    product_qty_6th    --���Y������_�U��
       ,NVL( SMMR.into_qty_6th    , 0 )    into_qty_6th       --�ō�����_�U��
       ,NVL( SMMR.output_qty_6th  , 0 )    output_qty_6th     --�o��������_�U��
       ,NVL( SMMR.mtrl_qty_6th    , 0 )    mtrl_qty_6th       --���ސ���_�U��
       ,NVL( SMMR.mfg_qty_6th     , 0 )    mfg_qty_6th        --�Ǝҕs�ǐ���_�U��
       ,NVL( SMMR.prod_qty_6th    , 0 )    prod_qty_6th       --�����s�ǐ���_�U��
        --�V��
       ,NVL( SMMR.invest_qty_7th  , 0 )    invest_qty_7th     --��������_�V��
       ,NVL( SMMR.product_qty_7th , 0 )    product_qty_7th    --���Y������_�V��
       ,NVL( SMMR.into_qty_7th    , 0 )    into_qty_7th       --�ō�����_�V��
       ,NVL( SMMR.output_qty_7th  , 0 )    output_qty_7th     --�o��������_�V��
       ,NVL( SMMR.mtrl_qty_7th    , 0 )    mtrl_qty_7th       --���ސ���_�V��
       ,NVL( SMMR.mfg_qty_7th     , 0 )    mfg_qty_7th        --�Ǝҕs�ǐ���_�V��
       ,NVL( SMMR.prod_qty_7th    , 0 )    prod_qty_7th       --�����s�ǐ���_�V��
        --�W��
       ,NVL( SMMR.invest_qty_8th  , 0 )    invest_qty_8th     --��������_�W��
       ,NVL( SMMR.product_qty_8th , 0 )    product_qty_8th    --���Y������_�W��
       ,NVL( SMMR.into_qty_8th    , 0 )    into_qty_8th       --�ō�����_�W��
       ,NVL( SMMR.output_qty_8th  , 0 )    output_qty_8th     --�o��������_�W��
       ,NVL( SMMR.mtrl_qty_8th    , 0 )    mtrl_qty_8th       --���ސ���_�W��
       ,NVL( SMMR.mfg_qty_8th     , 0 )    mfg_qty_8th        --�Ǝҕs�ǐ���_�W��
       ,NVL( SMMR.prod_qty_8th    , 0 )    prod_qty_8th       --�����s�ǐ���_�W��
        --�X��
       ,NVL( SMMR.invest_qty_9th  , 0 )    invest_qty_9th     --��������_�X��
       ,NVL( SMMR.product_qty_9th , 0 )    product_qty_9th    --���Y������_�X��
       ,NVL( SMMR.into_qty_9th    , 0 )    into_qty_9th       --�ō�����_�X��
       ,NVL( SMMR.output_qty_9th  , 0 )    output_qty_9th     --�o��������_�X��
       ,NVL( SMMR.mtrl_qty_9th    , 0 )    mtrl_qty_9th       --���ސ���_�X��
       ,NVL( SMMR.mfg_qty_9th     , 0 )    mfg_qty_9th        --�Ǝҕs�ǐ���_�X��
       ,NVL( SMMR.prod_qty_9th    , 0 )    prod_qty_9th       --�����s�ǐ���_�X��
        --�P�O��
       ,NVL( SMMR.invest_qty_10th , 0 )    invest_qty_10th    --��������_�P�O��
       ,NVL( SMMR.product_qty_10th, 0 )    product_qty_10th   --���Y������_�P�O��
       ,NVL( SMMR.into_qty_10th   , 0 )    into_qty_10th      --�ō�����_�P�O��
       ,NVL( SMMR.output_qty_10th , 0 )    output_qty_10th    --�o��������_�P�O��
       ,NVL( SMMR.mtrl_qty_10th   , 0 )    mtrl_qty_10th      --���ސ���_�P�O��
       ,NVL( SMMR.mfg_qty_10th    , 0 )    mfg_qty_10th       --�Ǝҕs�ǐ���_�P�O��
       ,NVL( SMMR.prod_qty_10th   , 0 )    prod_qty_10th      --�����s�ǐ���_�P�O��
        --�P�P��
       ,NVL( SMMR.invest_qty_11th , 0 )    invest_qty_11th    --��������_�P�P��
       ,NVL( SMMR.product_qty_11th, 0 )    product_qty_11th   --���Y������_�P�P��
       ,NVL( SMMR.into_qty_11th   , 0 )    into_qty_11th      --�ō�����_�P�P��
       ,NVL( SMMR.output_qty_11th , 0 )    output_qty_11th    --�o��������_�P�P��
       ,NVL( SMMR.mtrl_qty_11th   , 0 )    mtrl_qty_11th      --���ސ���_�P�P��
       ,NVL( SMMR.mfg_qty_11th    , 0 )    mfg_qty_11th       --�Ǝҕs�ǐ���_�P�P��
       ,NVL( SMMR.prod_qty_11th   , 0 )    prod_qty_11th      --�����s�ǐ���_�P�P��
        --�P�Q��
       ,NVL( SMMR.invest_qty_12th , 0 )    invest_qty_12th    --��������_�P�Q��
       ,NVL( SMMR.product_qty_12th, 0 )    product_qty_12th   --���Y������_�P�Q��
       ,NVL( SMMR.into_qty_12th   , 0 )    into_qty_12th      --�ō�����_�P�Q��
       ,NVL( SMMR.output_qty_12th , 0 )    output_qty_12th    --�o��������_�P�Q��
       ,NVL( SMMR.mtrl_qty_12th   , 0 )    mtrl_qty_12th      --���ސ���_�P�Q��
       ,NVL( SMMR.mfg_qty_12th    , 0 )    mfg_qty_12th       --�Ǝҕs�ǐ���_�P�Q��
       ,NVL( SMMR.prod_qty_12th   , 0 )    prod_qty_12th      --�����s�ǐ���_�P�Q��
        --�P��
       ,NVL( SMMR.invest_qty_1th  , 0 )    invest_qty_1th     --��������_�P��
       ,NVL( SMMR.product_qty_1th , 0 )    product_qty_1th    --���Y������_�P��
       ,NVL( SMMR.into_qty_1th    , 0 )    into_qty_1th       --�ō�����_�P��
       ,NVL( SMMR.output_qty_1th  , 0 )    output_qty_1th     --�o��������_�P��
       ,NVL( SMMR.mtrl_qty_1th    , 0 )    mtrl_qty_1th       --���ސ���_�P��
       ,NVL( SMMR.mfg_qty_1th     , 0 )    mfg_qty_1th        --�Ǝҕs�ǐ���_�P��
       ,NVL( SMMR.prod_qty_1th    , 0 )    prod_qty_1th       --�����s�ǐ���_�P��
        --�Q��
       ,NVL( SMMR.invest_qty_2th  , 0 )    invest_qty_2th     --��������_�Q��
       ,NVL( SMMR.product_qty_2th , 0 )    product_qty_2th    --���Y������_�Q��
       ,NVL( SMMR.into_qty_2th    , 0 )    into_qty_2th       --�ō�����_�Q��
       ,NVL( SMMR.output_qty_2th  , 0 )    output_qty_2th     --�o��������_�Q��
       ,NVL( SMMR.mtrl_qty_2th    , 0 )    mtrl_qty_2th       --���ސ���_�Q��
       ,NVL( SMMR.mfg_qty_2th     , 0 )    mfg_qty_2th        --�Ǝҕs�ǐ���_�Q��
       ,NVL( SMMR.prod_qty_2th    , 0 )    prod_qty_2th       --�����s�ǐ���_�Q��
        --�R��
       ,NVL( SMMR.invest_qty_3th  , 0 )    invest_qty_3th     --��������_�R��
       ,NVL( SMMR.product_qty_3th , 0 )    product_qty_3th    --���Y������_�R��
       ,NVL( SMMR.into_qty_3th    , 0 )    into_qty_3th       --�ō�����_�R��
       ,NVL( SMMR.output_qty_3th  , 0 )    output_qty_3th     --�o��������_�R��
       ,NVL( SMMR.mtrl_qty_3th    , 0 )    mtrl_qty_3th       --���ސ���_�R��
       ,NVL( SMMR.mfg_qty_3th     , 0 )    mfg_qty_3th        --�Ǝҕs�ǐ���_�R��
       ,NVL( SMMR.prod_qty_3th    , 0 )    prod_qty_3th       --�����s�ǐ���_�R��
        --�S��
       ,NVL( SMMR.invest_qty_4th  , 0 )    invest_qty_4th     --��������_�S��
       ,NVL( SMMR.product_qty_4th , 0 )    product_qty_4th    --���Y������_�S��
       ,NVL( SMMR.into_qty_4th    , 0 )    into_qty_4th       --�ō�����_�S��
       ,NVL( SMMR.output_qty_4th  , 0 )    output_qty_4th     --�o��������_�S��
       ,NVL( SMMR.mtrl_qty_4th    , 0 )    mtrl_qty_4th       --���ސ���_�S��
       ,NVL( SMMR.mfg_qty_4th     , 0 )    mfg_qty_4th        --�Ǝҕs�ǐ���_�S��
       ,NVL( SMMR.prod_qty_4th    , 0 )    prod_qty_4th       --�����s�ǐ���_�S��
  FROM  (  --�N�x�A�����A�`�[�敪�A�H���ԍ��A�����i_�i�ڂ̒P�ʂŏW�v�����f�[�^
           SELECT  ICD.fiscal_year    year          --�N�x(���ъ�������ϊ�)
                  ,MTRL.pm_dept       pm_dept       --���ъǗ�����
                  ,MTRL.slip_cls      slip_cls      --�`�[�敪
                  ,MTRL.rtng_id       rtng_id       --�H��ID
                  ,MTRL.rtng_no       rtng_no       --�H���ԍ�
                  ,MTRL.cp_item_id    cp_item_id    --�����i_�i��ID
                   --�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.invest_qty  END ) invest_qty_5th    --��������_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.product_qty END ) product_qty_5th   --���Y������_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.into_qty    END ) into_qty_5th      --�ō�����_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.output_qty  END ) output_qty_5th    --�o��������_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.mtrl_qty    END ) mtrl_qty_5th      --���ސ���_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.mfg_qty     END ) mfg_qty_5th       --�Ǝҕs�ǐ���_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.prod_qty    END ) prod_qty_5th      --�����s�ǐ���_�T��
                   --�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.invest_qty  END ) invest_qty_6th    --��������_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.product_qty END ) product_qty_6th   --���Y������_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.into_qty    END ) into_qty_6th      --�ō�����_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.output_qty  END ) output_qty_6th    --�o��������_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.mtrl_qty    END ) mtrl_qty_6th      --���ސ���_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.mfg_qty     END ) mfg_qty_6th       --�Ǝҕs�ǐ���_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.prod_qty    END ) prod_qty_6th      --�����s�ǐ���_�U��
                   --�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.invest_qty  END ) invest_qty_7th    --��������_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.product_qty END ) product_qty_7th   --���Y������_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.into_qty    END ) into_qty_7th      --�ō�����_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.output_qty  END ) output_qty_7th    --�o��������_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.mtrl_qty    END ) mtrl_qty_7th      --���ސ���_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.mfg_qty     END ) mfg_qty_7th       --�Ǝҕs�ǐ���_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.prod_qty    END ) prod_qty_7th      --�����s�ǐ���_�V��
                   --�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.invest_qty  END ) invest_qty_8th    --��������_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.product_qty END ) product_qty_8th   --���Y������_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.into_qty    END ) into_qty_8th      --�ō�����_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.output_qty  END ) output_qty_8th    --�o��������_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.mtrl_qty    END ) mtrl_qty_8th      --���ސ���_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.mfg_qty     END ) mfg_qty_8th       --�Ǝҕs�ǐ���_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.prod_qty    END ) prod_qty_8th      --�����s�ǐ���_�W��
                   --�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.invest_qty  END ) invest_qty_9th    --��������_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.product_qty END ) product_qty_9th   --���Y������_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.into_qty    END ) into_qty_9th      --�ō�����_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.output_qty  END ) output_qty_9th    --�o��������_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.mtrl_qty    END ) mtrl_qty_9th      --���ސ���_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.mfg_qty     END ) mfg_qty_9th       --�Ǝҕs�ǐ���_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.prod_qty    END ) prod_qty_9th      --�����s�ǐ���_�X��
                   --�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.invest_qty  END ) invest_qty_10th   --��������_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.product_qty END ) product_qty_10th  --���Y������_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.into_qty    END ) into_qty_10th     --�ō�����_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.output_qty  END ) output_qty_10th   --�o��������_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.mtrl_qty    END ) mtrl_qty_10th     --���ސ���_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.mfg_qty     END ) mfg_qty_10th      --�Ǝҕs�ǐ���_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.prod_qty    END ) prod_qty_10th     --�����s�ǐ���_�P�O��
                   --�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.invest_qty  END ) invest_qty_11th   --��������_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.product_qty END ) product_qty_11th  --���Y������_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.into_qty    END ) into_qty_11th     --�ō�����_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.output_qty  END ) output_qty_11th   --�o��������_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.mtrl_qty    END ) mtrl_qty_11th     --���ސ���_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.mfg_qty     END ) mfg_qty_11th      --�Ǝҕs�ǐ���_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.prod_qty    END ) prod_qty_11th     --�����s�ǐ���_�P�P��
                   --�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.invest_qty  END ) invest_qty_12th   --��������_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.product_qty END ) product_qty_12th  --���Y������_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.into_qty    END ) into_qty_12th     --�ō�����_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.output_qty  END ) output_qty_12th   --�o��������_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.mtrl_qty    END ) mtrl_qty_12th     --���ސ���_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.mfg_qty     END ) mfg_qty_12th      --�Ǝҕs�ǐ���_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.prod_qty    END ) prod_qty_12th     --�����s�ǐ���_�P�Q��
                   --�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.invest_qty  END ) invest_qty_1th    --��������_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.product_qty END ) product_qty_1th   --���Y������_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.into_qty    END ) into_qty_1th      --�ō�����_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.output_qty  END ) output_qty_1th    --�o��������_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.mtrl_qty    END ) mtrl_qty_1th      --���ސ���_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.mfg_qty     END ) mfg_qty_1th       --�Ǝҕs�ǐ���_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.prod_qty    END ) prod_qty_1th      --�����s�ǐ���_�P��
                   --�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.invest_qty  END ) invest_qty_2th    --��������_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.product_qty END ) product_qty_2th   --���Y������_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.into_qty    END ) into_qty_2th      --�ō�����_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.output_qty  END ) output_qty_2th    --�o��������_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.mtrl_qty    END ) mtrl_qty_2th      --���ސ���_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.mfg_qty     END ) mfg_qty_2th       --�Ǝҕs�ǐ���_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.prod_qty    END ) prod_qty_2th      --�����s�ǐ���_�Q��
                   --�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.invest_qty  END ) invest_qty_3th    --��������_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.product_qty END ) product_qty_3th   --���Y������_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.into_qty    END ) into_qty_3th      --�ō�����_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.output_qty  END ) output_qty_3th    --�o��������_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.mtrl_qty    END ) mtrl_qty_3th      --���ސ���_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.mfg_qty     END ) mfg_qty_3th       --�Ǝҕs�ǐ���_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.prod_qty    END ) prod_qty_3th      --�����s�ǐ���_�R��
                   --�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.invest_qty  END ) invest_qty_4th    --��������_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.product_qty END ) product_qty_4th   --���Y������_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.into_qty    END ) into_qty_4th      --�ō�����_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.output_qty  END ) output_qty_4th    --�o��������_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.mtrl_qty    END ) mtrl_qty_4th      --���ސ���_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.mfg_qty     END ) mfg_qty_4th       --�Ǝҕs�ǐ���_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.prod_qty    END ) prod_qty_4th      --�����s�ǐ���_�S��
             FROM  ( --�W�v�Ώۃf�[�^���w�����i�x�A�w�����x�A�w���Y���x�ʂŎ擾
                      --================================================
                      -- �����i�f�[�^
                      --================================================
                      SELECT  GBH.batch_no             batch_no      --�o�b�`No(�f�o�b�O�p)
                             ,TO_DATE( GMD.attribute11, 'YYYY/MM/DD' )
                                                       act_date      --�����i_���Y��
                             ,GBH.attribute2           pm_dept       --���ъǗ�����
                             ,GBH.attribute1           slip_cls      --�`�[�敪
                             ,GBH.routing_id           rtng_id       --�H��ID
                             ,GRB.routing_no           rtng_no       --�H���ԍ�
                             ,GMD.item_id              cp_item_id    --�����i_�i��ID
                             ,GMD.item_id              item_id       --�i��ID
                             ,ITP.lot_id               lot_id        --���b�gID
                             ,0                        invest_qty    --��������
                             ,0                        product_qty   --���Y������
                             ,0                        into_qty      --�ō�����
                             ,ITP.trans_qty            output_qty    --�o��������
                             ,0                        mtrl_qty      --���ސ���
                             ,0                        mfg_qty       --�Ǝҕs�ǐ���
                             ,0                        prod_qty      --�����s�ǐ���
                        FROM  gme_batch_header         GBH           --���Y�o�b�`
                             ,gmd_routings_b           GRB           --�H���}�X�^
                             ,gme_material_details     GMD           --�����ڍ�
                             ,ic_tran_pnd              ITP           --�ۗ��݌Ƀg�����U�N�V����
                       WHERE  GBH.batch_type           = 0
                         AND  GBH.attribute4          <> '-1'        --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
                         --�H���ԍ��̎擾�Ɛ��Y�f�[�^���o�ׂ̈̕t������
                         AND  GRB.routing_class        NOT IN ( '61', '62', '70' )  -- �i�ڐU��(70)�A���(61,62) �ȊO
                         AND  GBH.routing_id           = GRB.routing_id
                         --�����ڍ׃f�[�^�w�����i�x�Ƃ̌���
                         AND  GMD.line_type            = '1'         --�y�����i�z
                         AND  GBH.batch_id             = GMD.batch_id
                         --�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
                         AND  ITP.trans_qty           <> 0
                         AND  ITP.doc_type             = 'PROD'
                         AND  ITP.delete_mark          = 0
                         AND  ITP.completed_ind        = 1           --����(�ˎ���)
                         AND  ITP.reverse_id           IS NULL
                         AND  ITP.lot_id              <> 0           --�w���ށx�͗L�蓾�Ȃ�
                         AND  GMD.material_detail_id   = ITP.line_id
                         AND  GMD.item_id              = ITP.item_id
                      -- [ �����i�f�[�^ END ] --
                     UNION ALL
                      --================================================
                      -- �����f�[�^
                      --================================================
                      SELECT  GBH.batch_no             batch_no      --�o�b�`No(�f�o�b�O�p)
                             ,TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' )
                                                       act_date      --�����i_���Y��
                             ,GBH.attribute2           pm_dept       --���ъǗ�����
                             ,GBH.attribute1           slip_cls      --�`�[�敪
                             ,GBH.routing_id           rtng_id       --�H��ID
                             ,GRB.routing_no           rtng_no       --�H���ԍ�
                             ,GMDF.item_id             cp_item_id    --�����i_�i��ID
                             ,GMD.item_id              item_id       --�i��ID
                             ,XMD.lot_id               lot_id        --���b�gID
                              --------------
                              -- ����     --
                              --------------
                             ,CASE WHEN NVL( GMD.attribute5, 'N' ) <> 'Y' THEN           --������ō��敪�w�����x
-- 2009/10/15 H.Itou Mod Start �{�ԏ�Q#1667
--                                CASE WHEN NVL( ITEMC.item_class_code, '1' ) <> '2' THEN  --�i�ڋ敪�w���ށx�ȊO
                                CASE WHEN NVL( MCB.segment1, '1' ) <> '2' THEN  --�i�ڋ敪�w���ށx�ȊO
-- 2009/10/15 H.Itou Mod End
                                  XMD.invested_qty - XMD.return_qty
                              END END                  invest_qty    --��������
                              -- ���� END --
                             ,0                        product_qty   --���Y������
                              --------------
                              -- �ō�     --
                              --------------
                             ,CASE WHEN NVL( GMD.attribute5, 'N' ) = 'Y' THEN            --������ō��敪�w�ō��x
                                XMD.invested_qty - XMD.return_qty
                              END                      into_qty      --�ō�����
                              -- ���� END --
                             ,0                        output_qty    --�o��������
                              --------------
                              -- ����     --
                              --------------
                             ,CASE WHEN NVL( GMD.attribute5, 'N' ) <> 'Y' THEN           --������ō��敪�w�����x
-- 2009/10/15 H.Itou Mod Start �{�ԏ�Q#1667
--                                CASE WHEN NVL( ITEMC.item_class_code, '1' ) = '2' THEN   --�i�ڋ敪�w���ށx
                                CASE WHEN NVL( MCB.segment1, '1' ) = '2' THEN   --�i�ڋ敪�w���ށx
-- 2009/10/15 H.Itou Mod End
                                  XMD.invested_qty - XMD.return_qty - ( XMD.mtl_prod_qty + XMD.mtl_mfg_qty )
                              END END                  mtrl_qty      --���ސ��ʁi���� - �s�ǐ��ʁj
                              -- ���� END --
                              ----------------
                              -- ���̑�     --
                              ----------------
                             ,XMD.mtl_mfg_qty          mfg_qty       --�Ǝҕs�ǐ���
                             ,XMD.mtl_prod_qty         prod_qty      --�����s�ǐ���
                              -- ���̑� END --
                        FROM  gme_batch_header         GBH           --���Y�o�b�`
                             ,gmd_routings_b           GRB           --�H���}�X�^
                             ,gme_material_details     GMD           --�����ڍ�
                             ,xxwip_material_detail    XMD           --�����ڍ׃A�h�I��
-- 2009/10/15 H.Itou Mod Start �{�ԏ�Q#1667
--                             ,xxsky_item_class_v       ITEMC         --�i�ڋ敪�擾�p
                             ,gmi_item_categories      GIC           -- �i�ڃJ�e�S������
                             ,mtl_categories_b         MCB           -- �i�ڃJ�e�S��
-- 2009/10/15 H.Itou Mod End
                             ,gme_material_details     GMDF          --�����ڍ�(�����i���擾�p)
                             ,ic_tran_pnd              ITPF          --�ۗ��݌Ƀg�����U�N�V����(�����i���擾�p)
                       WHERE  GBH.batch_type           = 0
                         AND  GBH.attribute4          <> '-1'        --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
                         --�H���ԍ��̎擾�Ɛ��Y�f�[�^���o�ׂ̈̕t������
                         AND  GRB.routing_class        NOT IN ( '61', '62', '70' )  --�i�ڐU��(70)�A���(61,62) �ȊO
                         AND  GBH.routing_id           = GRB.routing_id
                         --�����ڍ׃f�[�^�w�����x�Ƃ̌���
                         AND  GMD.line_type            = '-1'        --�y�����z
                         AND  GBH.batch_id             = GMD.batch_id
                         --�i�ڋ敪�擾
-- 2009/10/15 H.Itou Mod Start �{�ԏ�Q#1667
--                         AND  GMD.item_id              = ITEMC.item_id
                         AND  GMD.item_id              = GIC.item_id
                         AND  GIC.category_set_id      = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
                         AND  GIC.category_id          = MCB.category_id
                         AND  XMD.item_id              = GIC.item_id
-- 2009/10/15 H.Itou Mod End
                         --�����ڍ׃A�h�I���Ƃ̌���
                         AND  XMD.plan_type            = '4'         --����
                         AND  (    XMD.invested_qty   <> 0
                                OR XMD.return_qty     <> 0
                                OR XMD.mtl_mfg_qty    <> 0
                                OR XMD.mtl_prod_qty   <> 0
                              )
                         AND  GMD.batch_id             = XMD.batch_id
                         AND  GMD.material_detail_id   = XMD.material_detail_id
                         --�����i�f�[�^�Ƃ̌���
                         AND  GMDF.line_type           = '1'         --�y�����i�z
                         AND  GBH.batch_id             = GMDF.batch_id
                         --�����i�f�[�^���������Ă��邩���`�F�b�N
                         AND  ITPF.doc_type            = 'PROD'
                         AND  ITPF.delete_mark         = 0
                         AND  ITPF.completed_ind       = 1           --����(�ˎ���)
                         AND  ITPF.reverse_id          IS NULL
                         AND  ITPF.lot_id             <> 0           --�w���ށx�͗L�蓾�Ȃ�
                         AND  GMDF.material_detail_id  = ITPF.line_id
                         AND  GMDF.item_id             = ITPF.item_id
                      -- [ �����f�[�^ END ] --
                     UNION ALL
                      --================================================
                      -- ���Y���f�[�^
                      --================================================
                      SELECT  GBH.batch_no             batch_no      --�o�b�`No(�f�o�b�O�p)
                             ,TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' )
                                                       act_date      --�����i_���Y��
                             ,GBH.attribute2           pm_dept       --���ъǗ�����
                             ,GBH.attribute1           slip_cls      --�`�[�敪
                             ,GBH.routing_id           rtng_id       --�H��ID
                             ,GRB.routing_no           rtng_no       --�H���ԍ�
                             ,GMDF.item_id             cp_item_id    --�����i_�i��ID
                             ,GMD.item_id              item_id       --�i��ID
                             ,ITP.lot_id               lot_id        --���b�gID
                             ,0                        invest_qty    --��������
                             ,ITP.trans_qty            product_qty   --���Y������
                             ,0                        into_qty      --�ō�����
                             ,0                        output_qty    --�o��������
                             ,0                        mtrl_qty      --���ސ���
                             ,0                        mfg_qty       --�Ǝҕs�ǐ���
                             ,0                        prod_qty      --�����s�ǐ���
                        FROM  gme_batch_header         GBH           --���Y�o�b�`
                             ,gmd_routings_b           GRB           --�H���}�X�^
                             ,gme_material_details     GMD           --�����ڍ�
                             ,ic_tran_pnd              ITP           --�ۗ��݌Ƀg�����U�N�V����
                             ,gme_material_details     GMDF          --�����ڍ�(�����i���擾�p)
                             ,ic_tran_pnd              ITPF          --�ۗ��݌Ƀg�����U�N�V����(�����i���擾�p)
                       WHERE  GBH.batch_type           = 0
                         AND  GBH.attribute4          <> '-1'        --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
                         --�H���ԍ��̎擾�Ɛ��Y�f�[�^���o�ׂ̈̕t������
                         AND  GRB.routing_class        NOT IN ( '61', '62', '70' )  --�i�ڐU��(70)�A���(61,62) �ȊO
                         AND  GBH.routing_id           = GRB.routing_id
                         --�����ڍ׃f�[�^�w���Y���x�Ƃ̌���
                         AND  GMD.line_type            = '2'         --�y���Y���z
                         AND  GBH.batch_id             = GMD.batch_id
                         --�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
                         AND  ITP.trans_qty           <> 0
                         AND  ITP.doc_type             = 'PROD'
                         AND  ITP.delete_mark          = 0
                         AND  ITP.completed_ind        = 1           --����(�ˎ���)
                         AND  ITP.reverse_id           IS NULL
                         AND  ITP.lot_id              <> 0           --�w���ށx�͗L�蓾�Ȃ�
                         AND  GMD.material_detail_id   = ITP.line_id
                         AND  GMD.item_id              = ITP.item_id
                         --�����i�f�[�^�Ƃ̌���
                         AND  GMDF.line_type           = '1'         --�y�����i�z
                         AND  GBH.batch_id             = GMDF.batch_id
                         --�����i�f�[�^���������Ă��邩���`�F�b�N
                         AND  ITPF.doc_type            = 'PROD'
                         AND  ITPF.delete_mark         = 0
                         AND  ITPF.completed_ind       = 1           --����(�ˎ���)
                         AND  ITPF.reverse_id          IS NULL
                         AND  ITPF.lot_id             <> 0           --�w���ށx�͗L�蓾�Ȃ�
                         AND  GMDF.material_detail_id  = ITPF.line_id
                         AND  GMDF.item_id             = ITPF.item_id
                      -- [ ���Y���f�[�^ END ] --
                   )                MTRL          --���Y�f�[�^
                  ,ic_cldr_dtl      ICD           --�݌ɃJ�����_
            WHERE
              --�݌ɃJ�����_�Ƃ̌��� �� �N���P�ʂɕ�����
                   ICD.orgn_code         = 'ITOE'  
              AND  TO_CHAR( MTRL.act_date, 'YYYYMM' ) = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
           GROUP BY
                   ICD.fiscal_year  --�N�x(���ъ�������ϊ�)
                  ,MTRL.pm_dept     --���ъǗ�����
                  ,MTRL.slip_cls    --�`�[�敪
                  ,MTRL.rtng_id     --�H��ID
                  ,MTRL.rtng_no     --�H���ԍ�
                  ,MTRL.cp_item_id  --�����i_�i��ID
        )  SMMR
       ,xxsky_item_mst_v         ITEM    --�i�ږ��擾�p�iSYSDATE�ŗL���f�[�^�𒊏o�j
       ,xxsky_prod_class_v       PRODC   --���i�敪�擾�p
       ,xxsky_item_class_v       ITEMC   --�i�ڋ敪�擾�p
       ,xxsky_crowd_code_v       CROWD   --�Q�R�[�h�擾�p
       ,gmd_routings_tl          GRTT    --�H���}�X�^(���{��)
 WHERE
   --�i�ږ�(�����i)�擾
        SMMR.cp_item_id = ITEM.item_id(+)
   --�i�ڃJ�e�S����(�����i)�擾
   AND  SMMR.cp_item_id = PRODC.item_id(+)
   AND  SMMR.cp_item_id = ITEMC.item_id(+)
   AND  SMMR.cp_item_id = CROWD.item_id(+)
   --�H���E�v�擾
   AND  GRTT.language(+) = 'JA'
   AND  SMMR.rtng_id = GRTT.routing_id(+)
/
COMMENT ON TABLE APPS.XXSKY_���Y���n��_����_V IS 'SKYLINK�p ���Y���n��i���ʁjVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�N�x                IS '�N�x'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ъǗ�����        IS '���ъǗ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���i�敪            IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���i�敪��          IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�i�ڋ敪            IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�i�ڋ敪��          IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Q�R�[�h            IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�i�ڃR�[�h          IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�i�ږ�              IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�i�ڗ���            IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�`�[�敪            IS '�`�[�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�H��                IS '�H��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�H������            IS '�H������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�H���E�v            IS '�H���E�v'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�T��       IS '��������_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�T��     IS '���Y������_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�T��       IS '�ō�����_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�T��     IS '�o��������_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�T��       IS '���ސ���_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�T��   IS '�Ǝҕs�ǐ���_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�T��   IS '�����s�ǐ���_�T��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�U��       IS '��������_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�U��     IS '���Y������_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�U��       IS '�ō�����_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�U��     IS '�o��������_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�U��       IS '���ސ���_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�U��   IS '�Ǝҕs�ǐ���_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�U��   IS '�����s�ǐ���_�U��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�V��       IS '��������_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�V��     IS '���Y������_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�V��       IS '�ō�����_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�V��     IS '�o��������_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�V��       IS '���ސ���_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�V��   IS '�Ǝҕs�ǐ���_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�V��   IS '�����s�ǐ���_�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�W��       IS '��������_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�W��     IS '���Y������_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�W��       IS '�ō�����_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�W��     IS '�o��������_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�W��       IS '���ސ���_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�W��   IS '�Ǝҕs�ǐ���_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�W��   IS '�����s�ǐ���_�W��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�X��       IS '��������_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�X��     IS '���Y������_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�X��       IS '�ō�����_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�X��     IS '�o��������_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�X��       IS '���ސ���_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�X��   IS '�Ǝҕs�ǐ���_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�X��   IS '�����s�ǐ���_�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�P�O��     IS '��������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�P�O��   IS '���Y������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�P�O��     IS '�ō�����_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�P�O��   IS '�o��������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�P�O��     IS '���ސ���_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�P�O�� IS '�Ǝҕs�ǐ���_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�P�O�� IS '�����s�ǐ���_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�P�P��     IS '��������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�P�P��   IS '���Y������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�P�P��     IS '�ō�����_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�P�P��   IS '�o��������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�P�P��     IS '���ސ���_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�P�P�� IS '�Ǝҕs�ǐ���_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�P�P�� IS '�����s�ǐ���_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�P�Q��     IS '��������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�P�Q��   IS '���Y������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�P�Q��     IS '�ō�����_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�P�Q��   IS '�o��������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�P�Q��     IS '���ސ���_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�P�Q�� IS '�Ǝҕs�ǐ���_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�P�Q�� IS '�����s�ǐ���_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�P��       IS '��������_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�P��     IS '���Y������_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�P��       IS '�ō�����_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�P��     IS '�o��������_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�P��       IS '���ސ���_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�P��   IS '�Ǝҕs�ǐ���_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�P��   IS '�����s�ǐ���_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�Q��       IS '��������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�Q��     IS '���Y������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�Q��       IS '�ō�����_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�Q��     IS '�o��������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�Q��       IS '���ސ���_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�Q��   IS '�Ǝҕs�ǐ���_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�Q��   IS '�����s�ǐ���_�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�R��       IS '��������_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�R��     IS '���Y������_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�R��       IS '�ō�����_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�R��     IS '�o��������_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�R��       IS '���ސ���_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�R��   IS '�Ǝҕs�ǐ���_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�R��   IS '�����s�ǐ���_�R��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.��������_�S��       IS '��������_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���Y������_�S��     IS '���Y������_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�ō�����_�S��       IS '�ō�����_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�o��������_�S��     IS '�o��������_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.���ސ���_�S��       IS '���ސ���_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�Ǝҕs�ǐ���_�S��   IS '�Ǝҕs�ǐ���_�S��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y���n��_����_V.�����s�ǐ���_�S��   IS '�����s�ǐ���_�S��'
/
