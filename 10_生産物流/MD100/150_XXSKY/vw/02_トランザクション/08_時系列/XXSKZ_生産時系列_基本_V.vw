/*************************************************************************
 * 
 * View  Name      : XXSKZ_���Y���n��_��{_V
 * Description     : XXSKZ_���Y���n��_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_���Y���n��_��{_V
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
,�������z_�T��
,���Y������_�T��
,���Y�����z_�T��
,�ō�����_�T��
,�ō����z_�T��
,�o��������_�T��
,�o�������z_�T��
,���ސ���_�T��
,���ދ��z_�T��
,�ϑ����H��_�T��
,�Ǝҕs�ǐ���_�T��
,�Ǝҕs�ǋ��z_�T��
,�����s�ǐ���_�T��
,�����s�ǋ��z_�T��
,��������_�U��
,�������z_�U��
,���Y������_�U��
,���Y�����z_�U��
,�ō�����_�U��
,�ō����z_�U��
,�o��������_�U��
,�o�������z_�U��
,���ސ���_�U��
,���ދ��z_�U��
,�ϑ����H��_�U��
,�Ǝҕs�ǐ���_�U��
,�Ǝҕs�ǋ��z_�U��
,�����s�ǐ���_�U��
,�����s�ǋ��z_�U��
,��������_�V��
,�������z_�V��
,���Y������_�V��
,���Y�����z_�V��
,�ō�����_�V��
,�ō����z_�V��
,�o��������_�V��
,�o�������z_�V��
,���ސ���_�V��
,���ދ��z_�V��
,�ϑ����H��_�V��
,�Ǝҕs�ǐ���_�V��
,�Ǝҕs�ǋ��z_�V��
,�����s�ǐ���_�V��
,�����s�ǋ��z_�V��
,��������_�W��
,�������z_�W��
,���Y������_�W��
,���Y�����z_�W��
,�ō�����_�W��
,�ō����z_�W��
,�o��������_�W��
,�o�������z_�W��
,���ސ���_�W��
,���ދ��z_�W��
,�ϑ����H��_�W��
,�Ǝҕs�ǐ���_�W��
,�Ǝҕs�ǋ��z_�W��
,�����s�ǐ���_�W��
,�����s�ǋ��z_�W��
,��������_�X��
,�������z_�X��
,���Y������_�X��
,���Y�����z_�X��
,�ō�����_�X��
,�ō����z_�X��
,�o��������_�X��
,�o�������z_�X��
,���ސ���_�X��
,���ދ��z_�X��
,�ϑ����H��_�X��
,�Ǝҕs�ǐ���_�X��
,�Ǝҕs�ǋ��z_�X��
,�����s�ǐ���_�X��
,�����s�ǋ��z_�X��
,��������_�P�O��
,�������z_�P�O��
,���Y������_�P�O��
,���Y�����z_�P�O��
,�ō�����_�P�O��
,�ō����z_�P�O��
,�o��������_�P�O��
,�o�������z_�P�O��
,���ސ���_�P�O��
,���ދ��z_�P�O��
,�ϑ����H��_�P�O��
,�Ǝҕs�ǐ���_�P�O��
,�Ǝҕs�ǋ��z_�P�O��
,�����s�ǐ���_�P�O��
,�����s�ǋ��z_�P�O��
,��������_�P�P��
,�������z_�P�P��
,���Y������_�P�P��
,���Y�����z_�P�P��
,�ō�����_�P�P��
,�ō����z_�P�P��
,�o��������_�P�P��
,�o�������z_�P�P��
,���ސ���_�P�P��
,���ދ��z_�P�P��
,�ϑ����H��_�P�P��
,�Ǝҕs�ǐ���_�P�P��
,�Ǝҕs�ǋ��z_�P�P��
,�����s�ǐ���_�P�P��
,�����s�ǋ��z_�P�P��
,��������_�P�Q��
,�������z_�P�Q��
,���Y������_�P�Q��
,���Y�����z_�P�Q��
,�ō�����_�P�Q��
,�ō����z_�P�Q��
,�o��������_�P�Q��
,�o�������z_�P�Q��
,���ސ���_�P�Q��
,���ދ��z_�P�Q��
,�ϑ����H��_�P�Q��
,�Ǝҕs�ǐ���_�P�Q��
,�Ǝҕs�ǋ��z_�P�Q��
,�����s�ǐ���_�P�Q��
,�����s�ǋ��z_�P�Q��
,��������_�P��
,�������z_�P��
,���Y������_�P��
,���Y�����z_�P��
,�ō�����_�P��
,�ō����z_�P��
,�o��������_�P��
,�o�������z_�P��
,���ސ���_�P��
,���ދ��z_�P��
,�ϑ����H��_�P��
,�Ǝҕs�ǐ���_�P��
,�Ǝҕs�ǋ��z_�P��
,�����s�ǐ���_�P��
,�����s�ǋ��z_�P��
,��������_�Q��
,�������z_�Q��
,���Y������_�Q��
,���Y�����z_�Q��
,�ō�����_�Q��
,�ō����z_�Q��
,�o��������_�Q��
,�o�������z_�Q��
,���ސ���_�Q��
,���ދ��z_�Q��
,�ϑ����H��_�Q��
,�Ǝҕs�ǐ���_�Q��
,�Ǝҕs�ǋ��z_�Q��
,�����s�ǐ���_�Q��
,�����s�ǋ��z_�Q��
,��������_�R��
,�������z_�R��
,���Y������_�R��
,���Y�����z_�R��
,�ō�����_�R��
,�ō����z_�R��
,�o��������_�R��
,�o�������z_�R��
,���ސ���_�R��
,���ދ��z_�R��
,�ϑ����H��_�R��
,�Ǝҕs�ǐ���_�R��
,�Ǝҕs�ǋ��z_�R��
,�����s�ǐ���_�R��
,�����s�ǋ��z_�R��
,��������_�S��
,�������z_�S��
,���Y������_�S��
,���Y�����z_�S��
,�ō�����_�S��
,�ō����z_�S��
,�o��������_�S��
,�o�������z_�S��
,���ސ���_�S��
,���ދ��z_�S��
,�ϑ����H��_�S��
,�Ǝҕs�ǐ���_�S��
,�Ǝҕs�ǋ��z_�S��
,�����s�ǐ���_�S��
,�����s�ǋ��z_�S��
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
       ,NVL( SMMR.invest_amt_5th  , 0 )    invest_amt_5th     --�������z_�T��
       ,NVL( SMMR.product_qty_5th , 0 )    product_qty_5th    --���Y������_�T��
       ,NVL( SMMR.product_amt_5th , 0 )    product_amt_5th    --���Y�����z_�T��
       ,NVL( SMMR.into_qty_5th    , 0 )    into_qty_5th       --�ō�����_�T��
       ,NVL( SMMR.into_amt_5th    , 0 )    into_amt_5th       --�ō����z_�T��
       ,NVL( SMMR.output_qty_5th  , 0 )    output_qty_5th     --�o��������_�T��
       ,NVL( SMMR.output_amt_5th  , 0 )    output_amt_5th     --�o�������z_�T��
       ,NVL( SMMR.mtrl_qty_5th    , 0 )    mtrl_qty_5th       --���ސ���_�T��
       ,NVL( SMMR.mtrl_amt_5th    , 0 )    mtrl_amt_5th       --���ދ��z_�T��
       ,NVL( SMMR.process_amt_5th , 0 )    process_amt_5th    --�ϑ����H��_�T��
       ,NVL( SMMR.mfg_qty_5th     , 0 )    mfg_qty_5th        --�Ǝҕs�ǐ���_�T��
       ,NVL( SMMR.mfg_amt_5th     , 0 )    mfg_amt_5th        --�Ǝҕs�ǋ��z_�T��
       ,NVL( SMMR.prod_qty_5th    , 0 )    prod_qty_5th       --�����s�ǐ���_�T��
       ,NVL( SMMR.prod_amt_5th    , 0 )    prod_amt_5th       --�����s�ǋ��z_�T��
        --�U��
       ,NVL( SMMR.invest_qty_6th  , 0 )    invest_qty_6th     --��������_�U��
       ,NVL( SMMR.invest_amt_6th  , 0 )    invest_amt_6th     --�������z_�U��
       ,NVL( SMMR.product_qty_6th , 0 )    product_qty_6th    --���Y������_�U��
       ,NVL( SMMR.product_amt_6th , 0 )    product_amt_6th    --���Y�����z_�U��
       ,NVL( SMMR.into_qty_6th    , 0 )    into_qty_6th       --�ō�����_�U��
       ,NVL( SMMR.into_amt_6th    , 0 )    into_amt_6th       --�ō����z_�U��
       ,NVL( SMMR.output_qty_6th  , 0 )    output_qty_6th     --�o��������_�U��
       ,NVL( SMMR.output_amt_6th  , 0 )    output_amt_6th     --�o�������z_�U��
       ,NVL( SMMR.mtrl_qty_6th    , 0 )    mtrl_qty_6th       --���ސ���_�U��
       ,NVL( SMMR.mtrl_amt_6th    , 0 )    mtrl_amt_6th       --���ދ��z_�U��
       ,NVL( SMMR.process_amt_6th , 0 )    process_amt_6th    --�ϑ����H��_�U��
       ,NVL( SMMR.mfg_qty_6th     , 0 )    mfg_qty_6th        --�Ǝҕs�ǐ���_�U��
       ,NVL( SMMR.mfg_amt_6th     , 0 )    mfg_amt_6th        --�Ǝҕs�ǋ��z_�U��
       ,NVL( SMMR.prod_qty_6th    , 0 )    prod_qty_6th       --�����s�ǐ���_�U��
       ,NVL( SMMR.prod_amt_6th    , 0 )    prod_amt_6th       --�����s�ǋ��z_�U��
        --�V��
       ,NVL( SMMR.invest_qty_7th  , 0 )    invest_qty_7th     --��������_�V��
       ,NVL( SMMR.invest_amt_7th  , 0 )    invest_amt_7th     --�������z_�V��
       ,NVL( SMMR.product_qty_7th , 0 )    product_qty_7th    --���Y������_�V��
       ,NVL( SMMR.product_amt_7th , 0 )    product_amt_7th    --���Y�����z_�V��
       ,NVL( SMMR.into_qty_7th    , 0 )    into_qty_7th       --�ō�����_�V��
       ,NVL( SMMR.into_amt_7th    , 0 )    into_amt_7th       --�ō����z_�V��
       ,NVL( SMMR.output_qty_7th  , 0 )    output_qty_7th     --�o��������_�V��
       ,NVL( SMMR.output_amt_7th  , 0 )    output_amt_7th     --�o�������z_�V��
       ,NVL( SMMR.mtrl_qty_7th    , 0 )    mtrl_qty_7th       --���ސ���_�V��
       ,NVL( SMMR.mtrl_amt_7th    , 0 )    mtrl_amt_7th       --���ދ��z_�V��
       ,NVL( SMMR.process_amt_7th , 0 )    process_amt_7th    --�ϑ����H��_�V��
       ,NVL( SMMR.mfg_qty_7th     , 0 )    mfg_qty_7th        --�Ǝҕs�ǐ���_�V��
       ,NVL( SMMR.mfg_amt_7th     , 0 )    mfg_amt_7th        --�Ǝҕs�ǋ��z_�V��
       ,NVL( SMMR.prod_qty_7th    , 0 )    prod_qty_7th       --�����s�ǐ���_�V��
       ,NVL( SMMR.prod_amt_7th    , 0 )    prod_amt_7th       --�����s�ǋ��z_�V��
        --�W��
       ,NVL( SMMR.invest_qty_8th  , 0 )    invest_qty_8th     --��������_�W��
       ,NVL( SMMR.invest_amt_8th  , 0 )    invest_amt_8th     --�������z_�W��
       ,NVL( SMMR.product_qty_8th , 0 )    product_qty_8th    --���Y������_�W��
       ,NVL( SMMR.product_amt_8th , 0 )    product_amt_8th    --���Y�����z_�W��
       ,NVL( SMMR.into_qty_8th    , 0 )    into_qty_8th       --�ō�����_�W��
       ,NVL( SMMR.into_amt_8th    , 0 )    into_amt_8th       --�ō����z_�W��
       ,NVL( SMMR.output_qty_8th  , 0 )    output_qty_8th     --�o��������_�W��
       ,NVL( SMMR.output_amt_8th  , 0 )    output_amt_8th     --�o�������z_�W��
       ,NVL( SMMR.mtrl_qty_8th    , 0 )    mtrl_qty_8th       --���ސ���_�W��
       ,NVL( SMMR.mtrl_amt_8th    , 0 )    mtrl_amt_8th       --���ދ��z_�W��
       ,NVL( SMMR.process_amt_8th , 0 )    process_amt_8th    --�ϑ����H��_�W��
       ,NVL( SMMR.mfg_qty_8th     , 0 )    mfg_qty_8th        --�Ǝҕs�ǐ���_�W��
       ,NVL( SMMR.mfg_amt_8th     , 0 )    mfg_amt_8th        --�Ǝҕs�ǋ��z_�W��
       ,NVL( SMMR.prod_qty_8th    , 0 )    prod_qty_8th       --�����s�ǐ���_�W��
       ,NVL( SMMR.prod_amt_8th    , 0 )    prod_amt_8th       --�����s�ǋ��z_�W��
        --�X��
       ,NVL( SMMR.invest_qty_9th  , 0 )    invest_qty_9th     --��������_�X��
       ,NVL( SMMR.invest_amt_9th  , 0 )    invest_amt_9th     --�������z_�X��
       ,NVL( SMMR.product_qty_9th , 0 )    product_qty_9th    --���Y������_�X��
       ,NVL( SMMR.product_amt_9th , 0 )    product_amt_9th    --���Y�����z_�X��
       ,NVL( SMMR.into_qty_9th    , 0 )    into_qty_9th       --�ō�����_�X��
       ,NVL( SMMR.into_amt_9th    , 0 )    into_amt_9th       --�ō����z_�X��
       ,NVL( SMMR.output_qty_9th  , 0 )    output_qty_9th     --�o��������_�X��
       ,NVL( SMMR.output_amt_9th  , 0 )    output_amt_9th     --�o�������z_�X��
       ,NVL( SMMR.mtrl_qty_9th    , 0 )    mtrl_qty_9th       --���ސ���_�X��
       ,NVL( SMMR.mtrl_amt_9th    , 0 )    mtrl_amt_9th       --���ދ��z_�X��
       ,NVL( SMMR.process_amt_9th , 0 )    process_amt_9th    --�ϑ����H��_�X��
       ,NVL( SMMR.mfg_qty_9th     , 0 )    mfg_qty_9th        --�Ǝҕs�ǐ���_�X��
       ,NVL( SMMR.mfg_amt_9th     , 0 )    mfg_amt_9th        --�Ǝҕs�ǋ��z_�X��
       ,NVL( SMMR.prod_qty_9th    , 0 )    prod_qty_9th       --�����s�ǐ���_�X��
       ,NVL( SMMR.prod_amt_9th    , 0 )    prod_amt_9th       --�����s�ǋ��z_�X��
        --�P�O��
       ,NVL( SMMR.invest_qty_10th , 0 )    invest_qty_10th    --��������_�P�O��
       ,NVL( SMMR.invest_amt_10th , 0 )    invest_amt_10th    --�������z_�P�O��
       ,NVL( SMMR.product_qty_10th, 0 )    product_qty_10th   --���Y������_�P�O��
       ,NVL( SMMR.product_amt_10th, 0 )    product_amt_10th   --���Y�����z_�P�O��
       ,NVL( SMMR.into_qty_10th   , 0 )    into_qty_10th      --�ō�����_�P�O��
       ,NVL( SMMR.into_amt_10th   , 0 )    into_amt_10th      --�ō����z_�P�O��
       ,NVL( SMMR.output_qty_10th , 0 )    output_qty_10th    --�o��������_�P�O��
       ,NVL( SMMR.output_amt_10th , 0 )    output_amt_10th    --�o�������z_�P�O��
       ,NVL( SMMR.mtrl_qty_10th   , 0 )    mtrl_qty_10th      --���ސ���_�P�O��
       ,NVL( SMMR.mtrl_amt_10th   , 0 )    mtrl_amt_10th      --���ދ��z_�P�O��
       ,NVL( SMMR.process_amt_10th, 0 )    process_amt_10th   --�ϑ����H��_�P�O��
       ,NVL( SMMR.mfg_qty_10th    , 0 )    mfg_qty_10th       --�Ǝҕs�ǐ���_�P�O��
       ,NVL( SMMR.mfg_amt_10th    , 0 )    mfg_amt_10th       --�Ǝҕs�ǋ��z_�P�O��
       ,NVL( SMMR.prod_qty_10th   , 0 )    prod_qty_10th      --�����s�ǐ���_�P�O��
       ,NVL( SMMR.prod_amt_10th   , 0 )    prod_amt_10th      --�����s�ǋ��z_�P�O��
        --�P�P��
       ,NVL( SMMR.invest_qty_11th , 0 )    invest_qty_11th    --��������_�P�P��
       ,NVL( SMMR.invest_amt_11th , 0 )    invest_amt_11th    --�������z_�P�P��
       ,NVL( SMMR.product_qty_11th, 0 )    product_qty_11th   --���Y������_�P�P��
       ,NVL( SMMR.product_amt_11th, 0 )    product_amt_11th   --���Y�����z_�P�P��
       ,NVL( SMMR.into_qty_11th   , 0 )    into_qty_11th      --�ō�����_�P�P��
       ,NVL( SMMR.into_amt_11th   , 0 )    into_amt_11th      --�ō����z_�P�P��
       ,NVL( SMMR.output_qty_11th , 0 )    output_qty_11th    --�o��������_�P�P��
       ,NVL( SMMR.output_amt_11th , 0 )    output_amt_11th    --�o�������z_�P�P��
       ,NVL( SMMR.mtrl_qty_11th   , 0 )    mtrl_qty_11th      --���ސ���_�P�P��
       ,NVL( SMMR.mtrl_amt_11th   , 0 )    mtrl_amt_11th      --���ދ��z_�P�P��
       ,NVL( SMMR.process_amt_11th, 0 )    process_amt_11th   --�ϑ����H��_�P�P��
       ,NVL( SMMR.mfg_qty_11th    , 0 )    mfg_qty_11th       --�Ǝҕs�ǐ���_�P�P��
       ,NVL( SMMR.mfg_amt_11th    , 0 )    mfg_amt_11th       --�Ǝҕs�ǋ��z_�P�P��
       ,NVL( SMMR.prod_qty_11th   , 0 )    prod_qty_11th      --�����s�ǐ���_�P�P��
       ,NVL( SMMR.prod_amt_11th   , 0 )    prod_amt_11th      --�����s�ǋ��z_�P�P��
        --�P�Q��
       ,NVL( SMMR.invest_qty_12th , 0 )    invest_qty_12th    --��������_�P�Q��
       ,NVL( SMMR.invest_amt_12th , 0 )    invest_amt_12th    --�������z_�P�Q��
       ,NVL( SMMR.product_qty_12th, 0 )    product_qty_12th   --���Y������_�P�Q��
       ,NVL( SMMR.product_amt_12th, 0 )    product_amt_12th   --���Y�����z_�P�Q��
       ,NVL( SMMR.into_qty_12th   , 0 )    into_qty_12th      --�ō�����_�P�Q��
       ,NVL( SMMR.into_amt_12th   , 0 )    into_amt_12th      --�ō����z_�P�Q��
       ,NVL( SMMR.output_qty_12th , 0 )    output_qty_12th    --�o��������_�P�Q��
       ,NVL( SMMR.output_amt_12th , 0 )    output_amt_12th    --�o�������z_�P�Q��
       ,NVL( SMMR.mtrl_qty_12th   , 0 )    mtrl_qty_12th      --���ސ���_�P�Q��
       ,NVL( SMMR.mtrl_amt_12th   , 0 )    mtrl_amt_12th      --���ދ��z_�P�Q��
       ,NVL( SMMR.process_amt_12th, 0 )    process_amt_12th   --�ϑ����H��_�P�Q��
       ,NVL( SMMR.mfg_qty_12th    , 0 )    mfg_qty_12th       --�Ǝҕs�ǐ���_�P�Q��
       ,NVL( SMMR.mfg_amt_12th    , 0 )    mfg_amt_12th       --�Ǝҕs�ǋ��z_�P�Q��
       ,NVL( SMMR.prod_qty_12th   , 0 )    prod_qty_12th      --�����s�ǐ���_�P�Q��
       ,NVL( SMMR.prod_amt_12th   , 0 )    prod_amt_12th      --�����s�ǋ��z_�P�Q��
        --�P��
       ,NVL( SMMR.invest_qty_1th  , 0 )    invest_qty_1th     --��������_�P��
       ,NVL( SMMR.invest_amt_1th  , 0 )    invest_amt_1th     --�������z_�P��
       ,NVL( SMMR.product_qty_1th , 0 )    product_qty_1th    --���Y������_�P��
       ,NVL( SMMR.product_amt_1th , 0 )    product_amt_1th    --���Y�����z_�P��
       ,NVL( SMMR.into_qty_1th    , 0 )    into_qty_1th       --�ō�����_�P��
       ,NVL( SMMR.into_amt_1th    , 0 )    into_amt_1th       --�ō����z_�P��
       ,NVL( SMMR.output_qty_1th  , 0 )    output_qty_1th     --�o��������_�P��
       ,NVL( SMMR.output_amt_1th  , 0 )    output_amt_1th     --�o�������z_�P��
       ,NVL( SMMR.mtrl_qty_1th    , 0 )    mtrl_qty_1th       --���ސ���_�P��
       ,NVL( SMMR.mtrl_amt_1th    , 0 )    mtrl_amt_1th       --���ދ��z_�P��
       ,NVL( SMMR.process_amt_1th , 0 )    process_amt_1th    --�ϑ����H��_�P��
       ,NVL( SMMR.mfg_qty_1th     , 0 )    mfg_qty_1th        --�Ǝҕs�ǐ���_�P��
       ,NVL( SMMR.mfg_amt_1th     , 0 )    mfg_amt_1th        --�Ǝҕs�ǋ��z_�P��
       ,NVL( SMMR.prod_qty_1th    , 0 )    prod_qty_1th       --�����s�ǐ���_�P��
       ,NVL( SMMR.prod_amt_1th    , 0 )    prod_amt_1th       --�����s�ǋ��z_�P��
        --�Q��
       ,NVL( SMMR.invest_qty_2th  , 0 )    invest_qty_2th     --��������_�Q��
       ,NVL( SMMR.invest_amt_2th  , 0 )    invest_amt_2th     --�������z_�Q��
       ,NVL( SMMR.product_qty_2th , 0 )    product_qty_2th    --���Y������_�Q��
       ,NVL( SMMR.product_amt_2th , 0 )    product_amt_2th    --���Y�����z_�Q��
       ,NVL( SMMR.into_qty_2th    , 0 )    into_qty_2th       --�ō�����_�Q��
       ,NVL( SMMR.into_amt_2th    , 0 )    into_amt_2th       --�ō����z_�Q��
       ,NVL( SMMR.output_qty_2th  , 0 )    output_qty_2th     --�o��������_�Q��
       ,NVL( SMMR.output_amt_2th  , 0 )    output_amt_2th     --�o�������z_�Q��
       ,NVL( SMMR.mtrl_qty_2th    , 0 )    mtrl_qty_2th       --���ސ���_�Q��
       ,NVL( SMMR.mtrl_amt_2th    , 0 )    mtrl_amt_2th       --���ދ��z_�Q��
       ,NVL( SMMR.process_amt_2th , 0 )    process_amt_2th    --�ϑ����H��_�Q��
       ,NVL( SMMR.mfg_qty_2th     , 0 )    mfg_qty_2th        --�Ǝҕs�ǐ���_�Q��
       ,NVL( SMMR.mfg_amt_2th     , 0 )    mfg_amt_2th        --�Ǝҕs�ǋ��z_�Q��
       ,NVL( SMMR.prod_qty_2th    , 0 )    prod_qty_2th       --�����s�ǐ���_�Q��
       ,NVL( SMMR.prod_amt_2th    , 0 )    prod_amt_2th       --�����s�ǋ��z_�Q��
        --�R��
       ,NVL( SMMR.invest_qty_3th  , 0 )    invest_qty_3th     --��������_�R��
       ,NVL( SMMR.invest_amt_3th  , 0 )    invest_amt_3th     --�������z_�R��
       ,NVL( SMMR.product_qty_3th , 0 )    product_qty_3th    --���Y������_�R��
       ,NVL( SMMR.product_amt_3th , 0 )    product_amt_3th    --���Y�����z_�R��
       ,NVL( SMMR.into_qty_3th    , 0 )    into_qty_3th       --�ō�����_�R��
       ,NVL( SMMR.into_amt_3th    , 0 )    into_amt_3th       --�ō����z_�R��
       ,NVL( SMMR.output_qty_3th  , 0 )    output_qty_3th     --�o��������_�R��
       ,NVL( SMMR.output_amt_3th  , 0 )    output_amt_3th     --�o�������z_�R��
       ,NVL( SMMR.mtrl_qty_3th    , 0 )    mtrl_qty_3th       --���ސ���_�R��
       ,NVL( SMMR.mtrl_amt_3th    , 0 )    mtrl_amt_3th       --���ދ��z_�R��
       ,NVL( SMMR.process_amt_3th , 0 )    process_amt_3th    --�ϑ����H��_�R��
       ,NVL( SMMR.mfg_qty_3th     , 0 )    mfg_qty_3th        --�Ǝҕs�ǐ���_�R��
       ,NVL( SMMR.mfg_amt_3th     , 0 )    mfg_amt_3th        --�Ǝҕs�ǋ��z_�R��
       ,NVL( SMMR.prod_qty_3th    , 0 )    prod_qty_3th       --�����s�ǐ���_�R��
       ,NVL( SMMR.prod_amt_3th    , 0 )    prod_amt_3th       --�����s�ǋ��z_�R��
        --�S��
       ,NVL( SMMR.invest_qty_4th  , 0 )    invest_qty_4th     --��������_�S��
       ,NVL( SMMR.invest_amt_4th  , 0 )    invest_amt_4th     --�������z_�S��
       ,NVL( SMMR.product_qty_4th , 0 )    product_qty_4th    --���Y������_�S��
       ,NVL( SMMR.product_amt_4th , 0 )    product_amt_4th    --���Y�����z_�S��
       ,NVL( SMMR.into_qty_4th    , 0 )    into_qty_4th       --�ō�����_�S��
       ,NVL( SMMR.into_amt_4th    , 0 )    into_amt_4th       --�ō����z_�S��
       ,NVL( SMMR.output_qty_4th  , 0 )    output_qty_4th     --�o��������_�S��
       ,NVL( SMMR.output_amt_4th  , 0 )    output_amt_4th     --�o�������z_�S��
       ,NVL( SMMR.mtrl_qty_4th    , 0 )    mtrl_qty_4th       --���ސ���_�S��
       ,NVL( SMMR.mtrl_amt_4th    , 0 )    mtrl_amt_4th       --���ދ��z_�S��
       ,NVL( SMMR.process_amt_4th , 0 )    process_amt_4th    --�ϑ����H��_�S��
       ,NVL( SMMR.mfg_qty_4th     , 0 )    mfg_qty_4th        --�Ǝҕs�ǐ���_�S��
       ,NVL( SMMR.mfg_amt_4th     , 0 )    mfg_amt_4th        --�Ǝҕs�ǋ��z_�S��
       ,NVL( SMMR.prod_qty_4th    , 0 )    prod_qty_4th       --�����s�ǐ���_�S��
       ,NVL( SMMR.prod_amt_4th    , 0 )    prod_amt_4th       --�����s�ǋ��z_�S��
  FROM  (  --�N�x�A�����A�`�[�敪�A�H���ԍ��A�����i_�i�ڂ̒P�ʂŏW�v�����f�[�^
           SELECT  ICD.fiscal_year    year          --�N�x(���ъ�������ϊ�)
                  ,MTRL.pm_dept       pm_dept       --���ъǗ�����
                  ,MTRL.slip_cls      slip_cls      --�`�[�敪
                  ,MTRL.rtng_id       rtng_id       --�H��ID
                  ,MTRL.rtng_no       rtng_no       --�H���ԍ�
                  ,MTRL.cp_item_id    cp_item_id    --�����i_�i��ID
                   --�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.invest_qty  END ) invest_qty_5th    --��������_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.invest_amt  END ) invest_amt_5th    --�������z_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.product_qty END ) product_qty_5th   --���Y������_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.product_amt END ) product_amt_5th   --���Y�����z_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.into_qty    END ) into_qty_5th      --�ō�����_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.into_amt    END ) into_amt_5th      --�ō����z_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.output_qty  END ) output_qty_5th    --�o��������_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.output_amt  END ) output_amt_5th    --�o�������z_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.mtrl_qty    END ) mtrl_qty_5th      --���ސ���_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.mtrl_amt    END ) mtrl_amt_5th      --���ދ��z_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.process_amt END ) process_amt_5th   --�ϑ����H��_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.mfg_qty     END ) mfg_qty_5th       --�Ǝҕs�ǐ���_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.mfg_amt     END ) mfg_amt_5th       --�Ǝҕs�ǋ��z_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.prod_qty    END ) prod_qty_5th      --�����s�ǐ���_�T��
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.prod_amt    END ) prod_amt_5th      --�����s�ǋ��z_�T��
                   --�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.invest_qty  END ) invest_qty_6th    --��������_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.invest_amt  END ) invest_amt_6th    --�������z_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.product_qty END ) product_qty_6th   --���Y������_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.product_amt END ) product_amt_6th   --���Y�����z_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.into_qty    END ) into_qty_6th      --�ō�����_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.into_amt    END ) into_amt_6th      --�ō����z_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.output_qty  END ) output_qty_6th    --�o��������_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.output_amt  END ) output_amt_6th    --�o�������z_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.mtrl_qty    END ) mtrl_qty_6th      --���ސ���_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.mtrl_amt    END ) mtrl_amt_6th      --���ދ��z_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.process_amt END ) process_amt_6th   --�ϑ����H��_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.mfg_qty     END ) mfg_qty_6th       --�Ǝҕs�ǐ���_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.mfg_amt     END ) mfg_amt_6th       --�Ǝҕs�ǋ��z_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.prod_qty    END ) prod_qty_6th      --�����s�ǐ���_�U��
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.prod_amt    END ) prod_amt_6th      --�����s�ǋ��z_�U��
                   --�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.invest_qty  END ) invest_qty_7th    --��������_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.invest_amt  END ) invest_amt_7th    --�������z_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.product_qty END ) product_qty_7th   --���Y������_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.product_amt END ) product_amt_7th   --���Y�����z_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.into_qty    END ) into_qty_7th      --�ō�����_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.into_amt    END ) into_amt_7th      --�ō����z_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.output_qty  END ) output_qty_7th    --�o��������_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.output_amt  END ) output_amt_7th    --�o�������z_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.mtrl_qty    END ) mtrl_qty_7th      --���ސ���_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.mtrl_amt    END ) mtrl_amt_7th      --���ދ��z_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.process_amt END ) process_amt_7th   --�ϑ����H��_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.mfg_qty     END ) mfg_qty_7th       --�Ǝҕs�ǐ���_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.mfg_amt     END ) mfg_amt_7th       --�Ǝҕs�ǋ��z_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.prod_qty    END ) prod_qty_7th      --�����s�ǐ���_�V��
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.prod_amt    END ) prod_amt_7th      --�����s�ǋ��z_�V��
                   --�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.invest_qty  END ) invest_qty_8th    --��������_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.invest_amt  END ) invest_amt_8th    --�������z_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.product_qty END ) product_qty_8th   --���Y������_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.product_amt END ) product_amt_8th   --���Y�����z_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.into_qty    END ) into_qty_8th      --�ō�����_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.into_amt    END ) into_amt_8th      --�ō����z_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.output_qty  END ) output_qty_8th    --�o��������_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.output_amt  END ) output_amt_8th    --�o�������z_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.mtrl_qty    END ) mtrl_qty_8th      --���ސ���_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.mtrl_amt    END ) mtrl_amt_8th      --���ދ��z_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.process_amt END ) process_amt_8th   --�ϑ����H��_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.mfg_qty     END ) mfg_qty_8th       --�Ǝҕs�ǐ���_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.mfg_amt     END ) mfg_amt_8th       --�Ǝҕs�ǋ��z_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.prod_qty    END ) prod_qty_8th      --�����s�ǐ���_�W��
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.prod_amt    END ) prod_amt_8th      --�����s�ǋ��z_�W��
                   --�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.invest_qty  END ) invest_qty_9th    --��������_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.invest_amt  END ) invest_amt_9th    --�������z_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.product_qty END ) product_qty_9th   --���Y������_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.product_amt END ) product_amt_9th   --���Y�����z_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.into_qty    END ) into_qty_9th      --�ō�����_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.into_amt    END ) into_amt_9th      --�ō����z_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.output_qty  END ) output_qty_9th    --�o��������_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.output_amt  END ) output_amt_9th    --�o�������z_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.mtrl_qty    END ) mtrl_qty_9th      --���ސ���_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.mtrl_amt    END ) mtrl_amt_9th      --���ދ��z_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.process_amt END ) process_amt_9th   --�ϑ����H��_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.mfg_qty     END ) mfg_qty_9th       --�Ǝҕs�ǐ���_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.mfg_amt     END ) mfg_amt_9th       --�Ǝҕs�ǋ��z_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.prod_qty    END ) prod_qty_9th      --�����s�ǐ���_�X��
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.prod_amt    END ) prod_amt_9th      --�����s�ǋ��z_�X��
                   --�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.invest_qty  END ) invest_qty_10th   --��������_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.invest_amt  END ) invest_amt_10th   --�������z_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.product_qty END ) product_qty_10th  --���Y������_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.product_amt END ) product_amt_10th  --���Y�����z_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.into_qty    END ) into_qty_10th     --�ō�����_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.into_amt    END ) into_amt_10th     --�ō����z_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.output_qty  END ) output_qty_10th   --�o��������_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.output_amt  END ) output_amt_10th   --�o�������z_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.mtrl_qty    END ) mtrl_qty_10th     --���ސ���_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.mtrl_amt    END ) mtrl_amt_10th     --���ދ��z_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.process_amt END ) process_amt_10th  --�ϑ����H��_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.mfg_qty     END ) mfg_qty_10th      --�Ǝҕs�ǐ���_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.mfg_amt     END ) mfg_amt_10th      --�Ǝҕs�ǋ��z_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.prod_qty    END ) prod_qty_10th     --�����s�ǐ���_�P�O��
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.prod_amt    END ) prod_amt_10th     --�����s�ǋ��z_�P�O��
                   --�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.invest_qty  END ) invest_qty_11th   --��������_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.invest_amt  END ) invest_amt_11th   --�������z_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.product_qty END ) product_qty_11th  --���Y������_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.product_amt END ) product_amt_11th  --���Y�����z_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.into_qty    END ) into_qty_11th     --�ō�����_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.into_amt    END ) into_amt_11th     --�ō����z_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.output_qty  END ) output_qty_11th   --�o��������_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.output_amt  END ) output_amt_11th   --�o�������z_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.mtrl_qty    END ) mtrl_qty_11th     --���ސ���_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.mtrl_amt    END ) mtrl_amt_11th     --���ދ��z_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.process_amt END ) process_amt_11th  --�ϑ����H��_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.mfg_qty     END ) mfg_qty_11th      --�Ǝҕs�ǐ���_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.mfg_amt     END ) mfg_amt_11th      --�Ǝҕs�ǋ��z_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.prod_qty    END ) prod_qty_11th     --�����s�ǐ���_�P�P��
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.prod_amt    END ) prod_amt_11th     --�����s�ǋ��z_�P�P��
                   --�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.invest_qty  END ) invest_qty_12th   --��������_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.invest_amt  END ) invest_amt_12th   --�������z_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.product_qty END ) product_qty_12th  --���Y������_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.product_amt END ) product_amt_12th  --���Y�����z_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.into_qty    END ) into_qty_12th     --�ō�����_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.into_amt    END ) into_amt_12th     --�ō����z_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.output_qty  END ) output_qty_12th   --�o��������_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.output_amt  END ) output_amt_12th   --�o�������z_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.mtrl_qty    END ) mtrl_qty_12th     --���ސ���_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.mtrl_amt    END ) mtrl_amt_12th     --���ދ��z_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.process_amt END ) process_amt_12th  --�ϑ����H��_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.mfg_qty     END ) mfg_qty_12th      --�Ǝҕs�ǐ���_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.mfg_amt     END ) mfg_amt_12th      --�Ǝҕs�ǋ��z_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.prod_qty    END ) prod_qty_12th     --�����s�ǐ���_�P�Q��
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.prod_amt    END ) prod_amt_12th     --�����s�ǋ��z_�P�Q��
                   --�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.invest_qty  END ) invest_qty_1th    --��������_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.invest_amt  END ) invest_amt_1th    --�������z_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.product_qty END ) product_qty_1th   --���Y������_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.product_amt END ) product_amt_1th   --���Y�����z_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.into_qty    END ) into_qty_1th      --�ō�����_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.into_amt    END ) into_amt_1th      --�ō����z_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.output_qty  END ) output_qty_1th    --�o��������_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.output_amt  END ) output_amt_1th    --�o�������z_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.mtrl_qty    END ) mtrl_qty_1th      --���ސ���_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.mtrl_amt    END ) mtrl_amt_1th      --���ދ��z_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.process_amt END ) process_amt_1th   --�ϑ����H��_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.mfg_qty     END ) mfg_qty_1th       --�Ǝҕs�ǐ���_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.mfg_amt     END ) mfg_amt_1th       --�Ǝҕs�ǋ��z_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.prod_qty    END ) prod_qty_1th      --�����s�ǐ���_�P��
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.prod_amt    END ) prod_amt_1th      --�����s�ǋ��z_�P��
                   --�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.invest_qty  END ) invest_qty_2th    --��������_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.invest_amt  END ) invest_amt_2th    --�������z_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.product_qty END ) product_qty_2th   --���Y������_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.product_amt END ) product_amt_2th   --���Y�����z_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.into_qty    END ) into_qty_2th      --�ō�����_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.into_amt    END ) into_amt_2th      --�ō����z_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.output_qty  END ) output_qty_2th    --�o��������_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.output_amt  END ) output_amt_2th    --�o�������z_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.mtrl_qty    END ) mtrl_qty_2th      --���ސ���_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.mtrl_amt    END ) mtrl_amt_2th      --���ދ��z_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.process_amt END ) process_amt_2th   --�ϑ����H��_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.mfg_qty     END ) mfg_qty_2th       --�Ǝҕs�ǐ���_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.mfg_amt     END ) mfg_amt_2th       --�Ǝҕs�ǋ��z_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.prod_qty    END ) prod_qty_2th      --�����s�ǐ���_�Q��
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.prod_amt    END ) prod_amt_2th      --�����s�ǋ��z_�Q��
                   --�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.invest_qty  END ) invest_qty_3th    --��������_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.invest_amt  END ) invest_amt_3th    --�������z_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.product_qty END ) product_qty_3th   --���Y������_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.product_amt END ) product_amt_3th   --���Y�����z_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.into_qty    END ) into_qty_3th      --�ō�����_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.into_amt    END ) into_amt_3th      --�ō����z_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.output_qty  END ) output_qty_3th    --�o��������_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.output_amt  END ) output_amt_3th    --�o�������z_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.mtrl_qty    END ) mtrl_qty_3th      --���ސ���_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.mtrl_amt    END ) mtrl_amt_3th      --���ދ��z_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.process_amt END ) process_amt_3th   --�ϑ����H��_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.mfg_qty     END ) mfg_qty_3th       --�Ǝҕs�ǐ���_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.mfg_amt     END ) mfg_amt_3th       --�Ǝҕs�ǋ��z_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.prod_qty    END ) prod_qty_3th      --�����s�ǐ���_�R��
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.prod_amt    END ) prod_amt_3th      --�����s�ǋ��z_�R��
                   --�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.invest_qty  END ) invest_qty_4th    --��������_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.invest_amt  END ) invest_amt_4th    --�������z_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.product_qty END ) product_qty_4th   --���Y������_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.product_amt END ) product_amt_4th   --���Y�����z_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.into_qty    END ) into_qty_4th      --�ō�����_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.into_amt    END ) into_amt_4th      --�ō����z_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.output_qty  END ) output_qty_4th    --�o��������_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.output_amt  END ) output_amt_4th    --�o�������z_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.mtrl_qty    END ) mtrl_qty_4th      --���ސ���_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.mtrl_amt    END ) mtrl_amt_4th      --���ދ��z_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.process_amt END ) process_amt_4th   --�ϑ����H��_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.mfg_qty     END ) mfg_qty_4th       --�Ǝҕs�ǐ���_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.mfg_amt     END ) mfg_amt_4th       --�Ǝҕs�ǋ��z_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.prod_qty    END ) prod_qty_4th      --�����s�ǐ���_�S��
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.prod_amt    END ) prod_amt_4th      --�����s�ǋ��z_�S��
             FROM  ( --�W�v�Ώۃf�[�^���w�����i�x�A�w�����x�A�w���Y���x�ʂŎ擾
                      --================================================
                      -- �����i�f�[�^
                      --================================================
                      SELECT  GBH.batch_no             batch_no      --�o�b�`No(�f�o�b�O�p)
                             ,TO_DATE( GMD.attribute11 )
                                                       act_date      --�����i_���Y��
                             ,GBH.attribute2           pm_dept       --���ъǗ�����
                             ,GBH.attribute1           slip_cls      --�`�[�敪
                             ,GBH.ROUTING_ID           rtng_id       --�H��ID
                             ,GRB.routing_no           rtng_no       --�H���ԍ�
                             ,GMD.ITEM_ID              cp_item_id    --�����i_�i��ID
                             ,GMD.item_id              item_id       --�����i_�i��ID(�f�o�b�O�p)
                             ,ITP.LOT_ID               lot_id        --�����i_���b�gID(�f�o�b�O�p)
                             ,0                        invest_qty    --��������
                             ,0                        invest_amt    --�������z�i�P���~�݌ɐ��ʁj
                             ,0                        product_qty   --���Y������
                             ,0                        product_amt   --���Y�����z�i�P���~�݌ɐ��ʁj
                             ,0                        into_qty      --�ō�����
                             ,0                        into_amt      --�ō����z�i�P���~�݌ɐ��ʁj
                             ,ITP.trans_qty            output_qty    --�o��������
                             ,0                        output_amt    --�o�������z
                             ,0                        mtrl_qty      --���ސ���
                             ,0                        mtrl_amt      --���ދ��z�i�P���~�݌ɐ��ʁj
                             ,TO_NUMBER( GMD.attribute15 )
                                                       process_amt   --�ϑ����H��
                             ,0                        mfg_qty       --�Ǝҕs�ǐ���
                             ,0                        mfg_amt       --�Ǝҕs�ǋ��z�i�P���~�Ǝҕs�ǐ��ʁj
                             ,0                        prod_qty      --�����s�ǐ���
                             ,0                        prod_amt      --�����s�ǋ��z�i�P���~�����s�ǐ��ʁj
                        FROM  XXCMN_GME_BATCH_HEADER_ARC      GBH    --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                             ,GMD_ROUTINGS_B                  GRB
                             ,XXCMN_GME_MATERIAL_DETAILS_ARC  GMD   --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                             ,XXCMN_IC_TRAN_PND_ARC           ITP   --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                       WHERE  GBH.batch_type           = 0
                         AND  GBH.attribute4          <> '-1'       --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
                         --�H���ԍ��̎擾�Ɛ��Y�f�[�^���o�ׂ̈̕t������
                         AND  GRB.routing_class        NOT IN ( '61', '62', '70' )  --�i�ڐU��(70)�A���(61,62) �ȊO
                         AND  GBH.routing_id           = GRB.routing_id
                         --�����ڍ׃f�[�^�w�����i�x�Ƃ̌���
                         AND  GMD.line_type            = '1'           --�y�����i�z
                         AND  GBH.batch_id             = GMD.batch_id
                         --�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
                         AND  ITP.trans_qty           <> 0
                         AND  ITP.doc_type             = 'PROD'
                         AND  ITP.delete_mark          = 0
                         AND  ITP.completed_ind        = 1             --����(�ˎ���)
                         AND  ITP.reverse_id           IS NULL
                         AND  ITP.lot_id              <> 0             --�w���ށx�͗L�蓾�Ȃ�
                         AND  GMD.material_detail_id   = ITP.line_id
                         AND  GMD .item_id             = ITP.item_id
                      -- [ �����i�f�[�^ END ] --
                     UNION ALL
                      --================================================
                      -- �����f�[�^
                      --================================================
                      SELECT  SGMD.batch_no            batch_no      --�o�b�`No(�f�o�b�O�p)
                             ,SGMD.act_date            act_date      --�����i_���Y��
                             ,SGMD.pm_dept             pm_dept       --���ъǗ�����
                             ,SGMD.slip_cls            slip_cls      --�`�[�敪
                             ,SGMD.rtng_id             rtng_id       --�H��ID
                             ,SGMD.rtng_no             rtng_no       --�H���ԍ�
                             ,SGMD.cp_item_id          cp_item_id    --�����i_�i��ID
                             ,SGMD.item_id             item_id       --����_�i��ID(�f�o�b�O�p)
                             ,ILM.lot_id               lot_id        --����_���b�gID(�f�o�b�O�p)
                              -- --- ���� START ---------------------------------------------------------------------------
                             ,CASE WHEN SGMD.invest_type <> 'Y' THEN                     --������ō��敪�w�����x
                                CASE WHEN NVL( ITEMC.item_class_code, '1' ) <> '2' THEN  --�i�ڋ敪�w���ށx�ȊO
                                  XMD.invested_qty - XMD.return_qty
                              END END                  invest_qty    --��������
                              -- 
                             ,CASE WHEN SGMD.invest_type <> 'Y' THEN                     --������ō��敪�w�����x
                                CASE WHEN NVL( ITEMC.item_class_code, '1' ) <> '2' THEN  --�i�ڋ敪�w���ށx�ȊO
                                  ROUND( DECODE( IIM.attribute15, '0', TO_NUMBER( ILM.attribute7 )  --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                                , '1', XPH.total_amount             --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                     , 0 )
                                                       * ( XMD.invested_qty - XMD.return_qty ) )
                              END END                  invest_amt    --�������z�i�P���~�݌ɐ��ʁj
                              -- --- ���� END   ---------------------------------------------------------------------------
                             ,0                        product_qty   --���Y������
                             ,0                        product_amt   --���Y�����z�i�P���~�݌ɐ��ʁj
                              -- --- �ō� START ---------------------------------------------------------------------------
                             ,CASE WHEN SGMD.invest_type  = 'Y' THEN                     --������ō��敪�w�ō��x
                                XMD.invested_qty - XMD.return_qty
                              END                      into_qty      --�ō�����
                              -- 
                             ,CASE WHEN SGMD.invest_type  = 'Y' THEN                     --������ō��敪�w�ō��x
                                ROUND( DECODE( IIM.attribute15, '0', TO_NUMBER( ILM.attribute7 )    --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                              , '1', XPH.total_amount               --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                   , 0 )
                                                     * ( XMD.invested_qty - XMD.return_qty ) )
                              END                      into_amt      --�ō����z�i�P���~�݌ɐ��ʁj
                              -- --- �ō� END   ---------------------------------------------------------------------------
                              -- --- �o���� START -------------------------------------------------------------------------
                             ,0                        output_qty    --�o��������
                              --
                             ,CASE WHEN NVL( ITEMC.item_class_code, '1' ) <> '2' THEN  --�i�ڋ敪�w���ށx�ȊO
                                ROUND( DECODE( IIM.attribute15, '0', TO_NUMBER( ILM.attribute7 )    --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                              , '1', XPH.total_amount               --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                   , 0 )
                                                     * ( XMD.invested_qty - XMD.return_qty ) )
                              END                      output_amt    --�o�������z�i�������z�{�ō����z�|���Y�����z�j
                              -- --- �o���� END   -------------------------------------------------------------------------
                              -- --- ���� START ---------------------------------------------------------------------------
                             ,CASE WHEN SGMD.invest_type <> 'Y' THEN                     --������ō��敪�w�����x
                                CASE WHEN NVL( ITEMC.item_class_code, '1' ) = '2' THEN   --�i�ڋ敪�w���ށx
                                  XMD.invested_qty - XMD.return_qty - ( XMD.mtl_prod_qty + XMD.mtl_mfg_qty )
                              END END                  mtrl_qty      --���ސ��ʁi���� - �s�ǐ��ʁj
                              -- 
                             ,CASE WHEN SGMD.invest_type <> 'Y' THEN                     --������ō��敪�w�����x
                                CASE WHEN NVL( ITEMC.item_class_code, '1' ) = '2' THEN   --�i�ڋ敪�w���ށx
                                  ROUND( DECODE( IIM.attribute15, '0', TO_NUMBER( ILM.attribute7 )  --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                                , '1', XPH.total_amount             --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                     , 0 )
                                                       * ( XMD.invested_qty - XMD.return_qty - ( XMD.mtl_prod_qty + XMD.mtl_mfg_qty ) ) )
                              END END                  mtrl_amt      --���ދ��z�i�P���~�݌ɐ��ʁj
                              -- --- ���� END   ---------------------------------------------------------------------------
                             ,0                        process_amt   --�ϑ����H��
                              -- --- ���ށi�Ǝҕs�ǁj START ---------------------------------------------------------------
                             ,XMD.mtl_mfg_qty          mfg_qty       --�Ǝҕs�ǐ���
                              -- 
                             ,ROUND( DECODE( IIM.attribute15, '0', TO_NUMBER( ILM.attribute7 )  --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                            , '1', XPH.total_amount             --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                 , 0 )
                                                       * XMD.mtl_mfg_qty )
                                                       mfg_amt       --�Ǝҕs�ǋ��z�i�P���~�Ǝҕs�ǐ��ʁj
                              -- --- ���ށi�Ǝҕs�ǁj END   ---------------------------------------------------------------
                              -- --- ���ށi�����s�ǁj START ---------------------------------------------------------------
                             ,XMD.mtl_prod_qty         prod_qty      --�����s�ǐ���
                              -- 
                             ,ROUND( DECODE( IIM.attribute15, '0', TO_NUMBER( ILM.attribute7 )  --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                            , '1', XPH.total_amount             --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                 , 0 )
                                                       * XMD.mtl_prod_qty )
                                                       prod_amt      --�����s�ǋ��z�i�P���~�����s�ǐ��ʁj
                              -- --- ���ށi�����s�ǁj END   ---------------------------------------------------------------
                        FROM  (  --�W���P���}�X�^�Ƃ̊O�������ׁ̈A���₢���킹�Ƃ���
                                 SELECT  GBH.batch_id                batch_id        --�o�b�`ID
                                        ,GBH.batch_no                batch_no        --�o�b�`No
                                        ,GBH.attribute2              pm_dept         --���ъǗ�����
                                        ,GBH.attribute1              slip_cls        --�`�[�敪
                                        ,GBH.routing_id              rtng_id         --�H��ID
                                        ,GRB.routing_no               rtng_no         --�H���ԍ�
                                        ,GMD.material_detail_id      mtrl_detail_id  --����ID
                                        ,GMDF.item_id                cp_item_id      --�����i_�i��ID
                                        ,GMD.item_id                 item_id         --�i��ID
                                        ,NVL( GMD.attribute5, 'N' )  invest_type     --������ō��敪
                                        ,TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' )
                                                                     act_date         --�����i_���Y��
                                   FROM  xxcmn_gme_batch_header_arc            GBH   --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                                        ,gmd_routings_b                        GRB
                                        ,xxcmn_gme_material_details_arc        GMD   --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                                        ,xxcmn_gme_material_details_arc        GMDF  --���Y�����ڍׁi�W���j�o�b�N�A�b�v(�����i���擾�p)
                                        ,xxcmn_ic_tran_pnd_arc                 ITPF  --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v(�����i���擾�p)
                                  WHERE  GBH.batch_type              = 0
                                    AND  GBH.attribute4             <> '-1'          --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
                                    --�H���ԍ��̎擾�Ɛ��Y�f�[�^���o�ׂ̈̕t������
                                    AND  GRB.routing_class           NOT IN ( '61', '62', '70' )  --�i�ڐU��(70)�A���(61,62) �ȊO
                                    AND  GBH.routing_id              = GRB.routing_id
                                    --�����ڍ׃f�[�^�w�����x�Ƃ̌���
                                    AND  GMD.line_type               = '-1'          --�y�����z
                                    AND  GBH.batch_id                = GMD.batch_id
                                    --�����i�f�[�^�Ƃ̌���
                                    AND  GMDF.line_type              = '1'           --�y�����i�z
                                    AND  GBH.batch_id                = GMDF.batch_id
                                    --�����i�f�[�^���������Ă��邩���`�F�b�N
                                    AND  ITPF.doc_type               = 'PROD'
                                    AND  ITPF.delete_mark            = 0
                                    AND  ITPF.completed_ind          = 1           --����(�ˎ���)
                                    AND  ITPF.reverse_id             IS NULL
                                    AND  ITPF.lot_id                <> 0           --�w���ށx�͗L�蓾�Ȃ�
                                    AND  GMDF.material_detail_id     = ITPF.line_id
                                    AND  GMDF.item_id                = ITPF.item_id
                              )                          SGMD          --�����f�[�^
                             ,xxcmn_material_detail_arc  XMD           --���Y�����ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,ic_item_mst_b              IIM           --OPM�i�ڃ}�X�^
                             ,ic_lots_mst                ILM           --OPM���b�g�}�X�^
                             ,xxpo_price_headers         XPH           --�d��/�W���P���}�X�^
                             ,xxskz_item_class_v         ITEMC         --�i�ڋ敪�擾�p
                       WHERE
                         --�i�ڋ敪�擾
                              SGMD.item_id             = ITEMC.item_id
                         --�����ڍ׃A�h�I���Ƃ̌���
                         AND  XMD.plan_type            = '4'         --����
                         AND  (    XMD.invested_qty   <> 0
                                OR XMD.return_qty     <> 0
                                OR XMD.mtl_mfg_qty    <> 0
                                OR XMD.mtl_prod_qty   <> 0
                              )
                         AND  SGMD.batch_id            = XMD.batch_id
                         AND  SGMD.mtrl_detail_id      = XMD.material_detail_id
                         --OPM�i�ڥ���b�g�}�X�^�Ƃ̌���
                         AND  XMD.item_id              = IIM.item_id
                         AND  XMD.item_id              = ILM.item_id
                         AND  XMD.lot_id               = ILM.lot_id
                         --�W���P���}�X�^�Ƃ̌���
                         AND  XPH.price_type(+)        = '2'         --�W��
                         AND  SGMD.item_id             = XPH.item_id(+)
                         AND  SGMD.act_date           >= XPH.start_date_active(+)
                         AND  SGMD.act_date           <= XPH.end_date_active(+)
                      -- [ �����f�[�^ END ] --
                     UNION ALL
                      --================================================
                      -- ���Y���f�[�^
                      --================================================
                      SELECT  SGMD.batch_no            batch_no      --�o�b�`No(�f�o�b�O�p)
                             ,SGMD.act_date            act_date      --�����i_���Y��
                             ,SGMD.pm_dept             pm_dept       --���ъǗ�����
                             ,SGMD.slip_cls            slip_cls      --�`�[�敪
                             ,SGMD.rtng_id             rtng_id       --�H��ID
                             ,SGMD.rtng_no             rtng_no       --�H���ԍ�
                             ,SGMD.cp_item_id          cp_item_id    --�����i_�i��ID
                             ,SGMD.item_id             item_id       --���Y��_�i��ID(�f�o�b�O�p)
                             ,SGMD.lot_id              lot_id        --���Y��_���b�gID(�f�o�b�O�p)
                             ,0                        invest_qty    --��������
                             ,0                        invest_amt    --�������z�i�P���~�݌ɐ��ʁj
                             ,SGMD.quantity            product_qty   --���Y������
                             ,ROUND( DECODE( IIM.attribute15, '0', TO_NUMBER( ILM.attribute7 )  --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                            , '1', XPH.total_amount             --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                 , 0 )
                                                       * SGMD.quantity )
                                                       product_amt   --���Y�����z�i�P���~�݌ɐ��ʁj
                             ,0                        into_qty      --�ō�����
                             ,0                        into_amt      --�ō����z�i�P���~�݌ɐ��ʁj
                             ,0                        output_qty    --�o��������
                             ,ROUND( DECODE( IIM.attribute15, '0', TO_NUMBER( ILM.attribute7 )  --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                            , '1', XPH.total_amount             --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                 , 0 )
                                                       * SGMD.quantity * -1 )
                                                       output_amt    --�o�������z�i�������z�{�ō����z�|���Y�����z�j
                             ,0                        mtrl_qty      --���ސ���
                             ,0                        mtrl_amt      --���ދ��z�i�P���~�݌ɐ��ʁj
                             ,0                        process_amt   --�ϑ����H��
                             ,0                        mfg_qty       --�Ǝҕs�ǐ���
                             ,0                        mfg_amt       --�Ǝҕs�ǋ��z�i�P���~�Ǝҕs�ǐ��ʁj
                             ,0                        prod_qty      --�����s�ǐ���
                             ,0                        prod_amt      --�����s�ǋ��z�i�P���~�����s�ǐ��ʁj
                        FROM  (  --�W���P���}�X�^�Ƃ̊O�������ׁ̈A���₢���킹�Ƃ���
                                 SELECT  GBH.batch_id                batch_id        --�o�b�`ID
                                        ,GBH.batch_no                batch_no        --�o�b�`No
                                        ,GBH.attribute2              pm_dept         --���ъǗ�����
                                        ,GBH.attribute1              slip_cls        --�`�[�敪
                                        ,GBH.routing_id              rtng_id         --�H��ID
                                        ,GRB.routing_no              rtng_no         --�H���ԍ�
                                        ,GMDF.item_id                cp_item_id      --�����i_�i��ID
                                        ,GMD.item_id                 item_id         --�i��ID
                                        ,ITP.lot_id                  lot_id          --���b�gID
                                        ,TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' )
                                                                     act_date        --�����i_���Y��
                                        ,ITP.trans_qty               quantity        --����
                                   FROM  xxcmn_gme_batch_header_arc            GBH   --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                                        ,gmd_routings_b                        GRB
                                        ,xxcmn_gme_material_details_arc        GMD   --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                                        ,xxcmn_ic_tran_pnd_arc                 ITP   --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                                        ,xxcmn_gme_material_details_arc        GMDF  --���Y�����ڍׁi�W���j�o�b�N�A�b�v(�����i���擾�p)
                                        ,xxcmn_ic_tran_pnd_arc                 ITPF  --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v(�����i���擾�p)
                                  WHERE  GBH.batch_type              = 0
                                    AND  GBH.attribute4             <> '-1'          --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
                                    --�H���ԍ��̎擾�Ɛ��Y�f�[�^���o�ׂ̈̕t������
                                    AND  GRB.routing_class           NOT IN ( '61', '62', '70' )  --�i�ڐU��(70)�A���(61,62) �ȊO
                                    AND  GBH.routing_id              = GRB.routing_id
                                    --�����ڍ׃f�[�^�w���Y���x�Ƃ̌���
                                    AND  GMD.line_type               = '2'           --�y���Y���z
                                    AND  GBH.batch_id                = GMD.batch_id
                                    --�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
                                    AND  ITP.trans_qty              <> 0
                                    AND  ITP.doc_type                = 'PROD'
                                    AND  ITP.delete_mark             = 0
                                    AND  ITP.completed_ind           = 1             --����(�ˎ���)
                                    AND  ITP.reverse_id              IS NULL
                                    AND  ITP.lot_id                 <> 0             --�w���ށx�͗L�蓾�Ȃ�
                                    AND  GMD.material_detail_id      = ITP.line_id
                                    AND  GMD.item_id                 = ITP.item_id
                                    --�����i�f�[�^�Ƃ̌���
                                    AND  GMDF.line_type              = '1'           --�y�����i�z
                                    AND  GBH.batch_id                = GMDF.batch_id
                                    --�����i�f�[�^���������Ă��邩���`�F�b�N
                                    AND  ITPF.doc_type               = 'PROD'
                                    AND  ITPF.delete_mark            = 0
                                    AND  ITPF.completed_ind          = 1           --����(�ˎ���)
                                    AND  ITPF.reverse_id             IS NULL
                                    AND  ITPF.lot_id                <> 0           --�w���ށx�͗L�蓾�Ȃ�
                                    AND  GMDF.material_detail_id     = ITPF.line_id
                                    AND  GMDF.item_id                = ITPF.item_id
                              )                        SGMD          --���Y���f�[�^
                             ,ic_item_mst_b            IIM           --OPM�i�ڃ}�X�^
                             ,ic_lots_mst              ILM           --OPM���b�g�}�X�^
                             ,xxpo_price_headers       XPH           --�d��/�W���P���}�X�^
                       WHERE
                         --OPM�i�ڥ���b�g�}�X�^�Ƃ̌���
                              SGMD.item_id             = IIM.item_id
                         AND  SGMD.item_id             = ILM.item_id
                         AND  SGMD.lot_id              = ILM.lot_id
                         --�W���P���}�X�^�Ƃ̌���
                         AND  XPH.price_type(+)        = '2'         --�W��
                         AND  SGMD.item_id             = XPH.item_id(+)
                         AND  SGMD.act_date           >= XPH.start_date_active(+)
                         AND  SGMD.act_date           <= XPH.end_date_active(+)
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
       ,xxskz_item_mst_v           ITEM    --�i�ږ��擾�p�iSYSDATE�ŗL���f�[�^�𒊏o�j
       ,xxskz_prod_class_v         PRODC   --���i�敪�擾�p
       ,xxskz_item_class_v         ITEMC   --�i�ڋ敪�擾�p
       ,xxskz_crowd_code_v         CROWD   --�Q�R�[�h�擾�p
       ,gmd_routings_tl            GRTT    --�H���}�X�^(���{��)
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
COMMENT ON TABLE APPS.XXSKZ_���Y���n��_��{_V IS 'SKYLINK�p ���Y���n��i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�N�x                IS '�N�x'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ъǗ�����        IS '���ъǗ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���i�敪            IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���i�敪��          IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�i�ڋ敪            IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�i�ڋ敪��          IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Q�R�[�h            IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�i�ڃR�[�h          IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�i�ږ�              IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�i�ڗ���            IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�`�[�敪            IS '�`�[�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�H��                IS '�H��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�H������            IS '�H������'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�H���E�v            IS '�H���E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�T��       IS '��������_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�T��       IS '�������z_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�T��     IS '���Y������_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�T��     IS '���Y�����z_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�T��       IS '�ō�����_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�T��       IS '�ō����z_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�T��     IS '�o��������_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�T��     IS '�o�������z_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�T��       IS '���ސ���_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�T��       IS '���ދ��z_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�T��     IS '�ϑ����H��_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�T��   IS '�Ǝҕs�ǐ���_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�T��   IS '�Ǝҕs�ǋ��z_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�T��   IS '�����s�ǐ���_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�T��   IS '�����s�ǋ��z_�T��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�U��       IS '��������_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�U��       IS '�������z_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�U��     IS '���Y������_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�U��     IS '���Y�����z_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�U��       IS '�ō�����_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�U��       IS '�ō����z_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�U��     IS '�o��������_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�U��     IS '�o�������z_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�U��       IS '���ސ���_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�U��       IS '���ދ��z_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�U��     IS '�ϑ����H��_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�U��   IS '�Ǝҕs�ǐ���_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�U��   IS '�Ǝҕs�ǋ��z_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�U��   IS '�����s�ǐ���_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�U��   IS '�����s�ǋ��z_�U��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�V��       IS '��������_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�V��       IS '�������z_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�V��     IS '���Y������_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�V��     IS '���Y�����z_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�V��       IS '�ō�����_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�V��       IS '�ō����z_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�V��     IS '�o��������_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�V��     IS '�o�������z_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�V��       IS '���ސ���_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�V��       IS '���ދ��z_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�V��     IS '�ϑ����H��_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�V��   IS '�Ǝҕs�ǐ���_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�V��   IS '�Ǝҕs�ǋ��z_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�V��   IS '�����s�ǐ���_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�V��   IS '�����s�ǋ��z_�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�W��       IS '��������_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�W��       IS '�������z_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�W��     IS '���Y������_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�W��     IS '���Y�����z_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�W��       IS '�ō�����_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�W��       IS '�ō����z_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�W��     IS '�o��������_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�W��     IS '�o�������z_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�W��       IS '���ސ���_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�W��       IS '���ދ��z_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�W��     IS '�ϑ����H��_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�W��   IS '�Ǝҕs�ǐ���_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�W��   IS '�Ǝҕs�ǋ��z_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�W��   IS '�����s�ǐ���_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�W��   IS '�����s�ǋ��z_�W��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�X��       IS '��������_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�X��       IS '�������z_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�X��     IS '���Y������_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�X��     IS '���Y�����z_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�X��       IS '�ō�����_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�X��       IS '�ō����z_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�X��     IS '�o��������_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�X��     IS '�o�������z_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�X��       IS '���ސ���_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�X��       IS '���ދ��z_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�X��     IS '�ϑ����H��_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�X��   IS '�Ǝҕs�ǐ���_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�X��   IS '�Ǝҕs�ǋ��z_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�X��   IS '�����s�ǐ���_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�X��   IS '�����s�ǋ��z_�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�P�O��     IS '��������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�P�O��     IS '�������z_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�P�O��   IS '���Y������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�P�O��   IS '���Y�����z_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�P�O��     IS '�ō�����_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�P�O��     IS '�ō����z_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�P�O��   IS '�o��������_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�P�O��   IS '�o�������z_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�P�O��     IS '���ސ���_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�P�O��     IS '���ދ��z_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�P�O��   IS '�ϑ����H��_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�P�O�� IS '�Ǝҕs�ǐ���_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�P�O�� IS '�Ǝҕs�ǋ��z_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�P�O�� IS '�����s�ǐ���_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�P�O�� IS '�����s�ǋ��z_�P�O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�P�P��     IS '��������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�P�P��     IS '�������z_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�P�P��   IS '���Y������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�P�P��   IS '���Y�����z_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�P�P��     IS '�ō�����_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�P�P��     IS '�ō����z_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�P�P��   IS '�o��������_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�P�P��   IS '�o�������z_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�P�P��     IS '���ސ���_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�P�P��     IS '���ދ��z_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�P�P��   IS '�ϑ����H��_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�P�P�� IS '�Ǝҕs�ǐ���_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�P�P�� IS '�Ǝҕs�ǋ��z_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�P�P�� IS '�����s�ǐ���_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�P�P�� IS '�����s�ǋ��z_�P�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�P�Q��     IS '��������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�P�Q��     IS '�������z_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�P�Q��   IS '���Y������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�P�Q��   IS '���Y�����z_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�P�Q��     IS '�ō�����_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�P�Q��     IS '�ō����z_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�P�Q��   IS '�o��������_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�P�Q��   IS '�o�������z_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�P�Q��     IS '���ސ���_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�P�Q��     IS '���ދ��z_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�P�Q��   IS '�ϑ����H��_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�P�Q�� IS '�Ǝҕs�ǐ���_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�P�Q�� IS '�Ǝҕs�ǋ��z_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�P�Q�� IS '�����s�ǐ���_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�P�Q�� IS '�����s�ǋ��z_�P�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�P��       IS '��������_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�P��       IS '�������z_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�P��     IS '���Y������_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�P��     IS '���Y�����z_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�P��       IS '�ō�����_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�P��       IS '�ō����z_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�P��     IS '�o��������_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�P��     IS '�o�������z_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�P��       IS '���ސ���_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�P��       IS '���ދ��z_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�P��     IS '�ϑ����H��_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�P��   IS '�Ǝҕs�ǐ���_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�P��   IS '�Ǝҕs�ǋ��z_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�P��   IS '�����s�ǐ���_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�P��   IS '�����s�ǋ��z_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�Q��       IS '��������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�Q��       IS '�������z_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�Q��     IS '���Y������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�Q��     IS '���Y�����z_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�Q��       IS '�ō�����_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�Q��       IS '�ō����z_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�Q��     IS '�o��������_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�Q��     IS '�o�������z_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�Q��       IS '���ސ���_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�Q��       IS '���ދ��z_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�Q��     IS '�ϑ����H��_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�Q��   IS '�Ǝҕs�ǐ���_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�Q��   IS '�Ǝҕs�ǋ��z_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�Q��   IS '�����s�ǐ���_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�Q��   IS '�����s�ǋ��z_�Q��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�R��       IS '��������_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�R��       IS '�������z_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�R��     IS '���Y������_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�R��     IS '���Y�����z_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�R��       IS '�ō�����_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�R��       IS '�ō����z_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�R��     IS '�o��������_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�R��     IS '�o�������z_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�R��       IS '���ސ���_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�R��       IS '���ދ��z_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�R��     IS '�ϑ����H��_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�R��   IS '�Ǝҕs�ǐ���_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�R��   IS '�Ǝҕs�ǋ��z_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�R��   IS '�����s�ǐ���_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�R��   IS '�����s�ǋ��z_�R��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.��������_�S��       IS '��������_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�������z_�S��       IS '�������z_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y������_�S��     IS '���Y������_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���Y�����z_�S��     IS '���Y�����z_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō�����_�S��       IS '�ō�����_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ō����z_�S��       IS '�ō����z_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o��������_�S��     IS '�o��������_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�o�������z_�S��     IS '�o�������z_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ސ���_�S��       IS '���ސ���_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.���ދ��z_�S��       IS '���ދ��z_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�ϑ����H��_�S��     IS '�ϑ����H��_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǐ���_�S��   IS '�Ǝҕs�ǐ���_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�Ǝҕs�ǋ��z_�S��   IS '�Ǝҕs�ǋ��z_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǐ���_�S��   IS '�����s�ǐ���_�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y���n��_��{_V.�����s�ǋ��z_�S��   IS '�����s�ǋ��z_�S��'
/
