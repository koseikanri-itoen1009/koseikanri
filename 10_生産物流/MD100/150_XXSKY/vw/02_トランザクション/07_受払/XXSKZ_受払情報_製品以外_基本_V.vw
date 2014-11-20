/*************************************************************************
 * 
 * View  Name      : XXSKZ_�󕥏��_���i�ȊO_��{_V
 * Description     : XXSKZ_�󕥏��_���i�ȊO_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V
(
 �N��
,���i�敪
,���i�敪��
,�q�ɃR�[�h
,�q�ɖ�
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ���
,�i�ڗ���
,����݌�
,����݌ɃP�[�X
,����݌ɋ��z
,�������_�d��
,�������_�d���P�[�X
,������z_�d��
,�������_�Đ�
,�������_�Đ��P�[�X
,������z_�Đ�
,�������_���g
,�������_���g�P�[�X
,������z_���g
,�������_�Đ����g
,�������_�Đ����g�P�[�X
,������z_�Đ����g
,�������_���i���
,�������_���i���P�[�X
,������z_���i���
,�������_����_�����i���
,�������_����_�����i���P�[�X
,������z_����_�����i���
,�������_�l��
,�������_�l���P�[�X
,������z_�l��
,�������_�i��ړ�
,�������_�i��ړ��P�[�X
,������z_�i��ړ�
,�������_�q�Ɉړ�
,�������_�q�Ɉړ��P�[�X
,������z_�q�Ɉړ�
,�������_���̑�
,�������_���̑��P�[�X
,������z_���̑�
,���o����_�Đ�
,���o����_�Đ��P�[�X
,���o���z_�Đ�
,���o����_�u�����h���g
,���o����_�u�����h���g�P�[�X
,���o���z_�u�����h���g
,���o����_�Đ����g
,���o����_�Đ����g�P�[�X
,���o���z_�Đ����g
,���o����_�
,���o����_��P�[�X
,���o���z_�
,���o����_�Z�b�g
,���o����_�Z�b�g�P�[�X
,���o���z_�Z�b�g
,���o����_����
,���o����_����P�[�X
,���o���z_����
,���o����_�L��
,���o����_�L���P�[�X
,���o���z_�L��
,���o����_���_
,���o����_���_�P�[�X
,���o���z_���_
,���o����_�U�֏o��
,���o����_�U�֏o�ɃP�[�X
,���o���z_�U�֏o��
,���o����_���i��
,���o����_���i�փP�[�X
,���o���z_���i��
,���o����_����_�����i��
,���o����_����_�����i�փP�[�X
,���o���z_����_�����i��
,���o����_�]��
,���o����_�]���P�[�X
,���o���z_�]��
,���o����_�p�p
,���o����_�p�p�P�[�X
,���o���z_�p�p
,���o����_���{
,���o����_���{�P�[�X
,���o���z_���{
,���o����_�������o
,���o����_�������o�P�[�X
,���o���z_�������o
,���o����_�o�����o
,���o����_�o�����o�P�[�X
,���o���z_�o�����o
,���o����_�i��ړ�
,���o����_�i��ړ��P�[�X
,���o���z_�i��ړ�
,���o����_�q�Ɉړ�
,���o����_�q�Ɉړ��P�[�X
,���o���z_�q�Ɉړ�
,���o����_���̑�
,���o����_���̑��P�[�X
,���o���z_���̑�
,���o����_�I������
,���o����_�I�����ՃP�[�X
,���o���z_�I������
)
AS
SELECT
        SUHM.yyyymm                                    yyyymm                             --�N��
       ,PRODC.prod_class_code                          prod_class_code                    --���i�敪
       ,PRODC.prod_class_name                          prod_class_name                    --���i�敪��
       ,SUHM.whse_code                                 whse_code                          --�q�ɃR�[�h
       ,IWM.whse_name                                  whse_name                          --�q�ɖ�
       ,ITEMC.item_class_code                          item_class_code                    --�i�ڋ敪
       ,ITEMC.item_class_name                          item_class_name                    --�i�ڋ敪��
       ,CROWD.crowd_code                               crowd_code                         --�Q�R�[�h
       ,SUHM.item_code                                 item_code                          --�i�ڃR�[�h
       ,SUHM.item_name                                 item_name                          --�i�ږ���
       ,SUHM.item_s_name                               item_s_name                        --�i�ڗ���
        --0.����݌�
       ,NVL( SUHM.trans_qty_gessyuzaiko         , 0 )  trans_qty_gessyuzaiko              --����݌�
       ,NVL( SUHM.trans_qty_gessyuzaiko_cs      , 0 )  trans_qty_gessyuzaiko_cs           --����݌ɃP�[�X
       ,NVL( SUHM.price_gessyuzaiko             , 0 )  price_gessyuzaiko                  --����݌ɋ��z
        --1.���_�d��
       ,NVL( SUHM.trans_qty_uke_shiire          , 0 )  trans_qty_uke_shiire               --�������_�d��
       ,NVL( SUHM.trans_qty_uke_shiire_cs       , 0 )  trans_qty_uke_shiire_cs            --�������_�d���P�[�X
       ,NVL( SUHM.price_uke_shiire              , 0 )  price_uke_shiire                   --������z_�d��
        --2.���_�Đ�
       ,NVL( SUHM.trans_qty_uke_saisei          , 0 )  trans_qty_uke_saisei               --�������_�Đ�
       ,NVL( SUHM.trans_qty_uke_saisei_cs       , 0 )  trans_qty_uke_saisei_cs            --�������_�Đ��P�[�X
       ,NVL( SUHM.price_uke_saisei              , 0 )  price_uke_saisei                   --������z_�Đ�
        --3.���_���g
       ,NVL( SUHM.trans_qty_uke_gougumi         , 0 )  trans_qty_uke_gougumi              --�������_���g
       ,NVL( SUHM.trans_qty_uke_gougumi_cs      , 0 )  trans_qty_uke_gougumi_cs           --�������_���g�P�[�X
       ,NVL( SUHM.price_uke_gougumi             , 0 )  price_uke_gougumi                  --������z_���g
        --4.���_�Đ����g
       ,NVL( SUHM.trans_qty_uke_saigougumi      , 0 )  trans_qty_uke_saigougumi           --�������_�Đ����g
       ,NVL( SUHM.trans_qty_uke_saigougumi_cs   , 0 )  trans_qty_uke_saigougumi_cs        --�������_�Đ����g�P�[�X
       ,NVL( SUHM.price_uke_saigougumi          , 0 )  price_uke_saigougumi               --������z_�Đ����g
        --5.���_���i���
       ,NVL( SUHM.trans_qty_uke_seihinyori      , 0 )  trans_qty_uke_seihinyori           --�������_���i���
       ,NVL( SUHM.trans_qty_uke_seihinyori_cs   , 0 )  trans_qty_uke_seihinyori_cs        --�������_���i���P�[�X
       ,NVL( SUHM.price_uke_seihinyori          , 0 )  price_uke_seihinyori               --������z_���i���
        --6.���_����_�����i���
       ,NVL( SUHM.trans_qty_uke_genhanseihin    , 0 )  trans_qty_uke_genhanseihin         --�������_����_�����i���
       ,NVL( SUHM.trans_qty_uke_genhanseihin_cs , 0 )  trans_qty_uke_genhanseihin_cs      --�������_����_�����i���P�[�X
       ,NVL( SUHM.price_uke_genhanseihin        , 0 )  price_uke_genhanseihin             --������z_����_�����i���
        --20.���_�l��
       ,NVL( SUHM.trans_qty_uke_hamaoka         , 0 )  trans_qty_uke_hamaoka              --�������_�l��
       ,NVL( SUHM.trans_qty_uke_hamaoka_cs      , 0 )  trans_qty_uke_hamaoka_cs           --�������_�l���P�[�X
       ,NVL( SUHM.price_uke_hamaoka             , 0 )  price_uke_hamaoka                  --������z_�l��
        --21.���_�i��ړ�
       ,NVL( SUHM.trans_qty_uke_hinsyuido       , 0 )  trans_qty_uke_hinsyuido            --�������_�i��ړ�
       ,NVL( SUHM.trans_qty_uke_hinsyuido_cs    , 0 )  trans_qty_uke_hinsyuido_cs         --�������_�i��ړ��P�[�X
       ,NVL( SUHM.price_uke_hinsyuido           , 0 )  price_uke_hinsyuido                --������z_�i��ړ�
        --22.���_�q�Ɉړ�
       ,NVL( SUHM.trans_qty_uke_soukoido        , 0 )  trans_qty_uke_soukoido             --�������_�q�Ɉړ�
       ,NVL( SUHM.trans_qty_uke_soukoido_cs     , 0 )  trans_qty_uke_soukoido_cs          --�������_�q�Ɉړ��P�[�X
       ,NVL( SUHM.price_uke_soukoido            , 0 )  price_uke_soukoido                 --������z_�q�Ɉړ�
        --23.���_���̑�
       ,NVL( SUHM.trans_qty_uke_sonota          , 0 )  trans_qty_uke_sonota               --�������_���̑�
       ,NVL( SUHM.trans_qty_uke_sonota_cs       , 0 )  trans_qty_uke_sonota_cs            --�������_���̑��P�[�X
       ,NVL( SUHM.price_uke_sonota              , 0 )  price_uke_sonota                   --������z_���̑�
        --8.���o_�Đ�
       ,NVL( SUHM.trans_qty_hara_saisei         , 0 )  trans_qty_hara_saisei              --���o����_�Đ�
       ,NVL( SUHM.trans_qty_hara_saisei_cs      , 0 )  trans_qty_hara_saisei_cs           --���o����_�Đ��P�[�X
       ,NVL( SUHM.price_hara_saisei             , 0 )  price_hara_saisei                  --���o���z_�Đ�
        --9.���o_�u�����h���g
       ,NVL( SUHM.trans_qty_hara_brendgougumi   , 0 )  trans_qty_hara_brendgougumi        --���o����_�u�����h���g
       ,NVL( SUHM.trans_qty_hara_brendgougumi_cs, 0 )  trans_qty_hara_brendgougumi_cs     --���o����_�u�����h���g�P�[�X
       ,NVL( SUHM.price_hara_brendgougumi       , 0 )  price_hara_brendgougumi            --���o���z_�u�����h���g
        --10.���o_�Đ����g
       ,NVL( SUHM.trans_qty_hara_saigougumi     , 0 )  trans_qty_hara_saigougumi          --���o����_�Đ����g
       ,NVL( SUHM.trans_qty_hara_saigougumi_cs  , 0 )  trans_qty_hara_saigougumi_cs       --���o����_�Đ����g�P�[�X
       ,NVL( SUHM.price_hara_saigougumi         , 0 )  price_hara_saigougumi              --���o���z_�Đ����g
        --11.���o_�
       ,NVL( SUHM.trans_qty_hara_housou         , 0 )  trans_qty_hara_housou              --���o����_�
       ,NVL( SUHM.trans_qty_hara_housou_cs      , 0 )  trans_qty_hara_housou_cs           --���o����_��P�[�X
       ,NVL( SUHM.price_hara_housou             , 0 )  price_hara_housou                  --���o���z_�
        --12.���o_�Z�b�g
       ,NVL( SUHM.trans_qty_hara_set            , 0 )  trans_qty_hara_set                 --���o����_�Z�b�g
       ,NVL( SUHM.trans_qty_hara_set_cs         , 0 )  trans_qty_hara_set_cs              --���o����_�Z�b�g�P�[�X
       ,NVL( SUHM.price_hara_set                , 0 )  price_hara_set                     --���o���z_�Z�b�g
        --13.���o_����
       ,NVL( SUHM.trans_qty_hara_okinawa        , 0 )  trans_qty_hara_okinawa             --���o����_����
       ,NVL( SUHM.trans_qty_hara_okinawa_cs     , 0 )  trans_qty_hara_okinawa_cs          --���o����_����P�[�X
       ,NVL( SUHM.price_hara_okinawa            , 0 )  price_hara_okinawa                 --���o���z_����
        --14.���o_�L��
       ,NVL( SUHM.trans_qty_hara_yusyou         , 0 )  trans_qty_hara_yusyou              --���o����_�L��
       ,NVL( SUHM.trans_qty_hara_yusyou_cs      , 0 )  trans_qty_hara_yusyou_cs           --���o����_�L���P�[�X
       ,NVL( SUHM.price_hara_yusyou             , 0 )  price_hara_yusyou                  --���o���z_�L��
        --15.���o_���_
       ,NVL( SUHM.trans_qty_hara_kyoten         , 0 )  trans_qty_hara_kyoten              --���o����_���_
       ,NVL( SUHM.trans_qty_hara_kyoten_cs      , 0 )  trans_qty_hara_kyoten_cs           --���o����_���_�P�[�X
       ,NVL( SUHM.price_hara_kyoten             , 0 )  price_hara_kyoten                  --���o���z_���_
        --16.���o_�U�֏o��
       ,NVL( SUHM.trans_qty_hara_furisyukko     , 0 )  trans_qty_hara_furisyukko          --���o����_�U�֏o��
       ,NVL( SUHM.trans_qty_hara_furisyukko_cs  , 0 )  trans_qty_hara_furisyukko_cs       --���o����_�U�֏o�ɃP�[�X
       ,NVL( SUHM.price_hara_furisyukko         , 0 )  price_hara_furisyukko              --���o���z_�U�֏o��
        --17.���o_���i��
       ,NVL( SUHM.trans_qty_hara_seihinhe       , 0 )  trans_qty_hara_seihinhe            --���o����_���i��
       ,NVL( SUHM.trans_qty_hara_seihinhe_cs    , 0 )  trans_qty_hara_seihinhe_cs         --���o����_���i�փP�[�X
       ,NVL( SUHM.price_hara_seihinhe           , 0 )  price_hara_seihinhe                --���o���z_���i��
        --18.���o_����_�����i��
       ,NVL( SUHM.trans_qty_hara_genhanseihin   , 0 )  trans_qty_hara_genhanseihin        --���o����_����_�����i��
       ,NVL( SUHM.trans_qty_hara_genhanseihin_cs, 0 )  trans_qty_hara_genhanseihin_cs     --���o����_����_�����i�փP�[�X
       ,NVL( SUHM.price_hara_genhanseihinhe     , 0 )  price_hara_genhanseihinhe          --���o���z_����_�����i��
        --24.���o_�]��
       ,NVL( SUHM.trans_qty_hara_tenbai         , 0 )  trans_qty_hara_tenbai              --���o����_�]��
       ,NVL( SUHM.trans_qty_hara_tenbai_cs      , 0 )  trans_qty_hara_tenbai_cs           --���o����_�]���P�[�X
       ,NVL( SUHM.price_hara_tenbai             , 0 )  price_hara_tenbai                  --���o���z_�]��
        --25.���o_�p�p
       ,NVL( SUHM.trans_qty_hara_haikyaku       , 0 )  trans_qty_hara_haikyaku            --���o����_�p�p
       ,NVL( SUHM.trans_qty_hara_haikyaku_cs    , 0 )  trans_qty_hara_haikyaku_cs         --���o����_�p�p�P�[�X
       ,NVL( SUHM.price_hara_haikyaku           , 0 )  price_hara_haikyaku                --���o���z_�p�p
        --26.���o_���{
       ,NVL( SUHM.trans_qty_hara_mihon          , 0 )  trans_qty_hara_mihon               --���o����_���{
       ,NVL( SUHM.trans_qty_hara_mihon_cs       , 0 )  trans_qty_hara_mihon_cs            --���o����_���{�P�[�X
       ,NVL( SUHM.price_hara_mihon              , 0 )  price_hara_mihon                   --���o���z_���{
        --27.���o_�������o
       ,NVL( SUHM.trans_qty_hara_soumu          , 0 )  trans_qty_hara_soumu               --���o����_�������o
       ,NVL( SUHM.trans_qty_hara_soumu_cs       , 0 )  trans_qty_hara_soumu_cs            --���o����_�������o�P�[�X
       ,NVL( SUHM.price_hara_soumu              , 0 )  price_hara_soumu                   --���o���z_�������o
        --28.���o_�o�����o
       ,NVL( SUHM.trans_qty_hara_keiri          , 0 )  trans_qty_hara_keiri               --���o����_�o�����o
       ,NVL( SUHM.trans_qty_hara_keiri_cs       , 0 )  trans_qty_hara_keiri_cs            --���o����_�o�����o�P�[�X
       ,NVL( SUHM.price_hara_keiri              , 0 )  price_hara_keiri                   --���o���z_�o�����o
        --29.���o_�i��ړ�
       ,NVL( SUHM.trans_qty_hara_hinsyuido      , 0 )  trans_qty_hara_hinsyuido           --���o����_�i��ړ�
       ,NVL( SUHM.trans_qty_hara_hinsyuido_cs   , 0 )  trans_qty_hara_hinsyuido_cs        --���o����_�i��ړ��P�[�X
       ,NVL( SUHM.price_hara_hinsyuido          , 0 )  price_hara_hinsyuido               --���o���z_�i��ړ�
        --30.���o_�q�Ɉړ�
       ,NVL( SUHM.trans_qty_hara_soukoido       , 0 )  trans_qty_hara_soukoido            --���o����_�q�Ɉړ�
       ,NVL( SUHM.trans_qty_hara_soukoido_cs    , 0 )  trans_qty_hara_soukoido_cs         --���o����_�q�Ɉړ��P�[�X
       ,NVL( SUHM.price_hara_soukoido           , 0 )  price_hara_soukoido                --���o���z_�q�Ɉړ�
        --31.���o_���̑�
       ,NVL( SUHM.trans_qty_hara_sonota         , 0 )  trans_qty_hara_sonota              --���o����_���̑�
       ,NVL( SUHM.trans_qty_hara_sonota_cs      , 0 )  trans_qty_hara_sonota_cs           --���o����_���̑��P�[�X
       ,NVL( SUHM.price_hara_sonota             , 0 )  price_hara_sonota                  --���o���z_���̑�
        --32.���o_�I������
       ,NVL( SUHM.trans_qty_hara_genmou         , 0 )  trans_qty_hara_genmou              --���o����_�I������
       ,NVL( SUHM.trans_qty_hara_genmou_cs      , 0 )  trans_qty_hara_genmou_cs           --���o����_�I�����ՃP�[�X
       ,NVL( SUHM.price_hara_genmou             , 0 )  price_hara_genmou                  --���o���z_�I������
  FROM (
         --**********************************************************************************************
         -- �y�N���z�y�q�Ɂz�y�i�ځz�P�ʂɏW�v������������擾  START
         --**********************************************************************************************
         SELECT
                 TO_CHAR( UHM.trans_date, 'YYYYMM' )   yyyymm                        --�N��
                ,UHM.whse_code                         whse_code                     --�q�ɃR�[�h
                ,UHM.item_id                           item_id                       --�i��ID
                ,ITEM.item_no                          item_code                     --�i�ڃR�[�h
                ,ITEM.item_name                        item_name                     --�i�ږ���
                ,ITEM.item_short_name                  item_s_name                   --�i�ڗ���
                 --0.����݌�
                ,SUM( CASE WHEN UHM.column_no =  0 THEN UHM.trans_qty                     END ) trans_qty_gessyuzaiko          --����݌�
                ,SUM( CASE WHEN UHM.column_no =  0 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_gessyuzaiko_cs       --����݌ɃP�[�X��
                ,SUM( CASE WHEN UHM.column_no =  0 THEN
                                --------------------------------------------------------------------------------------------------
                                -- �y���z�v�Z�z �����גP�ʂŎl�̌ܓ�����K�v������                                              --
                                --     �@ �����Ǘ��敪��'1:�W��' �Ȃ�                                   �y�W�������~���ʁz      --
                                --     �A �����Ǘ��敪��'0:����' ���� ���b�g�Ǘ��Ǘ��敪��'0:����' �Ȃ� �y�W�������~���ʁz      --
                                --     �B �����Ǘ��敪��'0:����' ���� ���b�g�Ǘ��Ǘ��敪��'1:�L��' �Ȃ� �y���b�g�ʌ����~���ʁz  --
                                --------------------------------------------------------------------------------------------------
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )         --�@
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )   --�A
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )        --�B
                                          END
                                END
                      END )                                                                     price_gessyuzaiko              --����݌ɋ��z
                 --1.�������_�d��
                ,SUM( CASE WHEN UHM.column_no =  1 THEN UHM.trans_qty                     END ) trans_qty_uke_shiire           --�������_�d��
                ,SUM( CASE WHEN UHM.column_no =  1 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_shiire_cs        --�������_�d���P�[�X��
                ,SUM( CASE WHEN UHM.column_no =  1 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_shiire               --������z_�d��
                 --2.�������_�Đ�
                ,SUM( CASE WHEN UHM.column_no =  2 THEN UHM.trans_qty                     END ) trans_qty_uke_saisei           --�������_�Đ�
                ,SUM( CASE WHEN UHM.column_no =  2 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_saisei_cs        --�������_�Đ��P�[�X��
                ,SUM( CASE WHEN UHM.column_no =  2 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_saisei               --������z_�Đ�
                 --3.�������_���g
                ,SUM( CASE WHEN UHM.column_no =  3 THEN UHM.trans_qty                     END ) trans_qty_uke_gougumi          --�������_���g
                ,SUM( CASE WHEN UHM.column_no =  3 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_gougumi_cs       --�������_���g�P�[�X��
                ,SUM( CASE WHEN UHM.column_no =  3 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_gougumi              --������z_���g
                 --4.�������_�Đ����g
                ,SUM( CASE WHEN UHM.column_no =  4 THEN UHM.trans_qty                     END ) trans_qty_uke_saigougumi       --�������_�Đ����g
                ,SUM( CASE WHEN UHM.column_no =  4 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_saigougumi_cs    --�������_�Đ����g�P�[�X��
                ,SUM( CASE WHEN UHM.column_no =  4 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_saigougumi           --������z_�Đ����g
                 --5.�������_���i���
                ,SUM( CASE WHEN UHM.column_no =  5 THEN UHM.trans_qty                     END ) trans_qty_uke_seihinyori       --�������_���i���
                ,SUM( CASE WHEN UHM.column_no =  5 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_seihinyori_cs    --�������_���i���P�[�X��
                ,SUM( CASE WHEN UHM.column_no =  5 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_seihinyori           --������z_���i���
                 --6.�������_����_�����i���
                ,SUM( CASE WHEN UHM.column_no =  6 THEN UHM.trans_qty                     END ) trans_qty_uke_genhanseihin     --�������_����_�����i���
                ,SUM( CASE WHEN UHM.column_no =  6 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_genhanseihin_cs  --�������_����_�����i���P�[�X��
                ,SUM( CASE WHEN UHM.column_no =  6 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_genhanseihin         --������z_����_�����i���
                 --20.�������_�l��
                ,SUM( CASE WHEN UHM.column_no = 20 THEN UHM.trans_qty                     END ) trans_qty_uke_hamaoka          --�������_�l��
                ,SUM( CASE WHEN UHM.column_no = 20 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_hamaoka_cs       --�������_�l���P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 20 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_hamaoka              --������z_�l��
                 --21.�������_�i��ړ�
                ,SUM( CASE WHEN UHM.column_no = 21 THEN UHM.trans_qty                     END ) trans_qty_uke_hinsyuido        --�������_�i��ړ�
                ,SUM( CASE WHEN UHM.column_no = 21 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_hinsyuido_cs     --�������_�i��ړ��P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 21 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_hinsyuido            --������z_�i��ړ�
                 --22.�������_�q�Ɉړ�
                ,SUM( CASE WHEN UHM.column_no = 22 THEN UHM.trans_qty                     END ) trans_qty_uke_soukoido         --�������_�q�Ɉړ�
                ,SUM( CASE WHEN UHM.column_no = 22 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_soukoido_cs      --�������_�q�Ɉړ��P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 22 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_soukoido             --������z_�q�Ɉړ�
                 --23.�������_���̑�
                ,SUM( CASE WHEN UHM.column_no = 23 THEN UHM.trans_qty                     END ) trans_qty_uke_sonota           --�������_���̑�
                ,SUM( CASE WHEN UHM.column_no = 23 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_sonota_cs        --�������_���̑��P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 23 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_sonota               --������z_���̑�
                 --8.���o����_�Đ�
                ,SUM( CASE WHEN UHM.column_no =  8 THEN UHM.trans_qty                     END ) trans_qty_hara_saisei          --���o����_�Đ�
                ,SUM( CASE WHEN UHM.column_no =  8 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_saisei_cs       --���o����_�Đ��P�[�X��
                ,SUM( CASE WHEN UHM.column_no =  8 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_saisei              --���o���z_�Đ�
                 --9.���o����_�u�����h���g
                ,SUM( CASE WHEN UHM.column_no =  9 THEN UHM.trans_qty                     END ) trans_qty_hara_brendgougumi    --���o����_�u�����h���g
                ,SUM( CASE WHEN UHM.column_no =  9 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_brendgougumi_cs --���o����_�u�����h���g�P�[�X��
                ,SUM( CASE WHEN UHM.column_no =  9 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_brendgougumi        --���o���z_�u�����h���g
                 --10.���o����_�Đ����g
                ,SUM( CASE WHEN UHM.column_no = 10 THEN UHM.trans_qty                     END ) trans_qty_hara_saigougumi      --���o����_�Đ����g
                ,SUM( CASE WHEN UHM.column_no = 10 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_saigougumi_cs   --���o����_�Đ����g�P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 10 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_saigougumi          --���o���z_�Đ����g
                 --11.���o����_�
                ,SUM( CASE WHEN UHM.column_no = 11 THEN UHM.trans_qty                     END ) trans_qty_hara_housou          --���o����_�
                ,SUM( CASE WHEN UHM.column_no = 11 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_housou_cs       --���o����_��P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 11 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_housou              --���o���z_�
                 --12.���o����_�Z�b�g
                ,SUM( CASE WHEN UHM.column_no = 12 THEN UHM.trans_qty                     END ) trans_qty_hara_set             --���o����_�Z�b�g
                ,SUM( CASE WHEN UHM.column_no = 12 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_set_cs          --���o����_�Z�b�g�P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 12 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_set                 --���o���z_�Z�b�g
                 --13.���o����_����
                ,SUM( CASE WHEN UHM.column_no = 13 THEN UHM.trans_qty                     END ) trans_qty_hara_okinawa         --���o����_����
                ,SUM( CASE WHEN UHM.column_no = 13 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_okinawa_cs      --���o����_����P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 13 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_okinawa             --���o���z_����
                 --14.���o����_�L��
                ,SUM( CASE WHEN UHM.column_no = 14 THEN UHM.trans_qty                     END ) trans_qty_hara_yusyou          --���o����_�L��
                ,SUM( CASE WHEN UHM.column_no = 14 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_yusyou_cs       --���o����_�L���P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 14 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_yusyou              --���o���z_�L��
                 --15.���o����_���_
                ,SUM( CASE WHEN UHM.column_no = 15 THEN UHM.trans_qty                     END ) trans_qty_hara_kyoten          --���o����_���_
                ,SUM( CASE WHEN UHM.column_no = 15 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_kyoten_cs       --���o����_���_�P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 15 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_kyoten              --���o���z_���_
                 --16.���o����_�U�֏o��
                ,SUM( CASE WHEN UHM.column_no = 16 THEN UHM.trans_qty                     END ) trans_qty_hara_furisyukko      --���o����_�U�֏o��
                ,SUM( CASE WHEN UHM.column_no = 16 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_furisyukko_cs   --���o����_�U�֏o�ɃP�[�X��
                ,SUM( CASE WHEN UHM.column_no = 16 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_furisyukko          --���o���z_�U�֏o��
                 --17.���o����_���i��
                ,SUM( CASE WHEN UHM.column_no = 17 THEN UHM.trans_qty                     END ) trans_qty_hara_seihinhe        --���o����_���i��
                ,SUM( CASE WHEN UHM.column_no = 17 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_seihinhe_cs     --���o����_���i�փP�[�X��
                ,SUM( CASE WHEN UHM.column_no = 17 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_seihinhe            --���o���z_���i��
                 --18.���o����_����_�����i��
                ,SUM( CASE WHEN UHM.column_no = 18 THEN UHM.trans_qty                     END ) trans_qty_hara_genhanseihin    --���o����_����_�����i��
                ,SUM( CASE WHEN UHM.column_no = 18 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_genhanseihin_cs --���o����_����_�����i�փP�[�X��
                ,SUM( CASE WHEN UHM.column_no = 18 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_genhanseihinhe      --���o���z_����_�����i��
                 --24.���o����_�]��
                ,SUM( CASE WHEN UHM.column_no = 24 THEN UHM.trans_qty                     END ) trans_qty_hara_tenbai          --���o����_�]��
                ,SUM( CASE WHEN UHM.column_no = 24 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_tenbai_cs       --���o����_�]���P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 24 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_tenbai              --���o���z_�]��
                 --25.���o����_�p�p
                ,SUM( CASE WHEN UHM.column_no = 25 THEN UHM.trans_qty                     END ) trans_qty_hara_haikyaku        --���o����_�p�p
                ,SUM( CASE WHEN UHM.column_no = 25 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_haikyaku_cs     --���o����_�p�p�P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 25 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_haikyaku            --���o���z_�p�p
                 --26.���o����_���{
                ,SUM( CASE WHEN UHM.column_no = 26 THEN UHM.trans_qty                     END ) trans_qty_hara_mihon           --���o����_���{
                ,SUM( CASE WHEN UHM.column_no = 26 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_mihon_cs        --���o����_���{�P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 26 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_mihon               --���o���z_���{
                 --27.���o����_�������o
                ,SUM( CASE WHEN UHM.column_no = 27 THEN UHM.trans_qty                     END ) trans_qty_hara_soumu           --���o����_�������o
                ,SUM( CASE WHEN UHM.column_no = 27 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_soumu_cs        --���o����_�������o�P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 27 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_soumu               --���o���z_�������o
                 --28.���o����_�o�����o
                ,SUM( CASE WHEN UHM.column_no = 28 THEN UHM.trans_qty                     END ) trans_qty_hara_keiri           --���o����_�o�����o
                ,SUM( CASE WHEN UHM.column_no = 28 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_keiri_cs        --���o����_�o�����o�P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 28 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_keiri               --���o���z_�o�����o
                 --29.���o����_�i��ړ�
                ,SUM( CASE WHEN UHM.column_no = 29 THEN UHM.trans_qty                     END ) trans_qty_hara_hinsyuido       --���o����_�i��ړ�
                ,SUM( CASE WHEN UHM.column_no = 29 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_hinsyuido_cs    --���o����_�i��ړ��P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 29 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_hinsyuido           --���o���z_�i��ړ�
                 --30.���o����_�q�Ɉړ�
                ,SUM( CASE WHEN UHM.column_no = 30 THEN UHM.trans_qty                     END ) trans_qty_hara_soukoido        --���o����_�q�Ɉړ�
                ,SUM( CASE WHEN UHM.column_no = 30 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_soukoido_cs     --���o����_�q�Ɉړ��P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 30 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_soukoido            --���o���z_�q�Ɉړ�
                 --31.���o����_���̑�
                ,SUM( CASE WHEN UHM.column_no = 31 THEN UHM.trans_qty                     END ) trans_qty_hara_sonota          --���o����_���̑�
                ,SUM( CASE WHEN UHM.column_no = 31 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_sonota_cs       --���o����_���̑��P�[�X��
                ,SUM( CASE WHEN UHM.column_no = 31 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_sonota              --���o���z_���̑�
                 --32.���o����_�I������
                ,SUM( CASE WHEN UHM.column_no = 32 THEN UHM.trans_qty                     END ) trans_qty_hara_genmou          --���o����_�I������
                ,SUM( CASE WHEN UHM.column_no = 32 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_genmou_cs       --���o����_�I�����ՃP�[�X
                ,SUM( CASE WHEN UHM.column_no = 32 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_genmou              --���o���z_�I������
           FROM
                 xxskz_uh_materials_v                  UHM                 --SKYLINK�p����VIEW �󕥏��_���i�ȊOVIEW
                ,xxskz_item_mst2_v                     ITEM                --SKYLINK�p����VIEW OPM�i�ڏ��VIEW
                ,ic_item_mst_b                         ITMB                --�i�ڃ}�X�^(��������b�g�Ǘ��敪�擾�p)
                ,xxcmn_lot_cost                        LCST                --���b�g�ʌ����A�h�I���e�[�u��
               ,(  -------------------------------------------------
                   -- �i�ڕʕW�������擾�p�̕��₢���킹
                   -------------------------------------------------
                   SELECT
                           CMPD.item_id                item_id             --�i��ID
                          ,CLDD.start_date             start_date_active   --�L���J�n��
                          ,CLDD.end_date               end_date_active     --�L���I����
                          ,SUM( CMPD.cmpnt_cost )      stnd_unit_price     --�W������
                     FROM
                           cm_cmpt_dtl                 CMPD                --�i�ڌ����}�X�^
                          ,cm_cmpt_mst_b               CMPM                --�R���|�[�l���g
                          ,cm_cldr_dtl                 CLDD                --�����J�����_����
                    WHERE
                           CMPD.whse_code              = '000'             --�q�ɃR�[�h(�����q��)
                      AND  CMPD.cost_mthd_code         = 'STDU'            --�������@�R�[�h
                      AND  CMPD.cost_analysis_code     = '0000'            --���̓R�[�h
                      AND  CMPD.cost_level             = 0                 --�R�X�g���x��
                      AND  CMPD.rollover_ind           = 0                 --�m��t���O
                      AND  CMPD.delete_mark            = 0                 --�폜�t���O
                      AND  CMPD.cost_cmpntcls_id       = CMPM.cost_cmpntcls_id
                      AND  CMPD.calendar_code          = CLDD.calendar_code
                      AND  CMPD.period_code            = CLDD.period_code
                    GROUP BY
                           CMPD.item_id
                          ,CLDD.start_date
                          ,CLDD.end_date
                )                                      GPRC                --�i�ڕʕW���������
          WHERE
            --�i�ڏ��擾
                 UHM.item_id                  = ITEM.item_id(+)
            AND  TRUNC( UHM.trans_date )     >= ITEM.start_date_active(+)
            AND  TRUNC( UHM.trans_date )     <= ITEM.end_date_active(+)
            --��������b�g�Ǘ��敪�擾
            AND  UHM.item_id                  = ITMB.item_id(+)
            --���b�g�������擾
            AND  UHM.item_id                  = LCST.item_id(+)
            AND  UHM.lot_id                   = LCST.lot_id(+)
            --�W���P�����擾
            AND  UHM.item_id                  = GPRC.item_id(+)
            AND  TRUNC( UHM.trans_date )     >= TRUNC( GPRC.start_date_active(+) )  --EBS�W���e�[�u���Ȃ̂Ŏ����b�����݂���
            AND  TRUNC( UHM.trans_date )     <= TRUNC( GPRC.end_date_active(+)   )  --EBS�W���e�[�u���Ȃ̂Ŏ����b�����݂���
         GROUP BY
                 TO_CHAR( UHM.trans_date, 'YYYYMM' )
                ,UHM.whse_code
                ,UHM.item_id
                ,ITEM.item_no
                ,ITEM.item_name
                ,ITEM.item_short_name
         --**********************************************************************************************
         -- �y�N���z�y�q�Ɂz�y�i�ځz�P�ʂɏW�v������������擾  END
         --**********************************************************************************************
       )                                SUHM           --�W�v��_���i�ȊO���
       ,ic_whse_mst                     IWM            --�q�Ƀ}�X�^
       ,xxskz_prod_class_v              PRODC          --SKYLINK�p ���i�敪�擾VIEW
       ,xxskz_item_class_v              ITEMC          --SKYLINK�p �i�ڋ敪�擾VIEW
       ,xxskz_crowd_code_v              CROWD          --SKYLINK�p �Q�R�[�h�擾VIEW
 WHERE
   --�S���ڂ̐��ʂ��[���̏ꍇ�͏o�͂��Ȃ�
       (    SUHM.trans_qty_gessyuzaiko       <> 0       --0.����݌�
         OR SUHM.trans_qty_uke_shiire        <> 0       --1.���_�d��
         OR SUHM.trans_qty_uke_saisei        <> 0       --2.���_�Đ�
         OR SUHM.trans_qty_uke_gougumi       <> 0       --3.���_���g
         OR SUHM.trans_qty_uke_saigougumi    <> 0       --4.���_�Đ����g
         OR SUHM.trans_qty_uke_seihinyori    <> 0       --5.���_���i���
         OR SUHM.trans_qty_uke_genhanseihin  <> 0       --6.���_����_�����i���
         OR SUHM.trans_qty_uke_hamaoka       <> 0       --20.���_�l��
         OR SUHM.trans_qty_uke_hinsyuido     <> 0       --21.���_�i��ړ�
         OR SUHM.trans_qty_uke_soukoido      <> 0       --22.���_�q�Ɉړ�
         OR SUHM.trans_qty_uke_sonota        <> 0       --23.���_���̑�
         OR SUHM.trans_qty_hara_saisei       <> 0       --8.���o_�Đ�
         OR SUHM.trans_qty_hara_brendgougumi <> 0       --9.���o_�u�����h���g
         OR SUHM.trans_qty_hara_saigougumi   <> 0       --10.���o_�Đ����g
         OR SUHM.trans_qty_hara_housou       <> 0       --11.���o_�
         OR SUHM.trans_qty_hara_set          <> 0       --12.���o_�Z�b�g
         OR SUHM.trans_qty_hara_okinawa      <> 0       --13.���o_����
         OR SUHM.trans_qty_hara_yusyou       <> 0       --14.���o_�L��
         OR SUHM.trans_qty_hara_kyoten       <> 0       --15.���o_���_
         OR SUHM.trans_qty_hara_furisyukko   <> 0       --16.���o_�U�֏o��
         OR SUHM.trans_qty_hara_seihinhe     <> 0       --17.���o_���i��
         OR SUHM.trans_qty_hara_genhanseihin <> 0       --18.���o_����_�����i��
         OR SUHM.trans_qty_hara_tenbai       <> 0       --24.���o_�]��
         OR SUHM.trans_qty_hara_haikyaku     <> 0       --25.���o_�p�p
         OR SUHM.trans_qty_hara_mihon        <> 0       --26.���o_���{
         OR SUHM.trans_qty_hara_soumu        <> 0       --27.���o_�������o
         OR SUHM.trans_qty_hara_keiri        <> 0       --28.���o_�o�����o
         OR SUHM.trans_qty_hara_hinsyuido    <> 0       --29.���o_�i��ړ�
         OR SUHM.trans_qty_hara_soukoido     <> 0       --30.���o_�q�Ɉړ�
         OR SUHM.trans_qty_hara_sonota       <> 0       --31.���o_���̑�
         OR SUHM.trans_qty_hara_genmou       <> 0       --32.���o_�I������
       )
   --�q�ɖ��擾
   AND  SUHM.whse_code   = IWM.whse_code(+)
-- 2010/03/10 M.Miyagawa Add Start
   AND  IWM.attribute1 = '0' -- 0: �ɓ����݌ɊǗ��q��
-- 2010/03/10 M.Miyagawa Add End
   --�i�ڃJ�e�S�����擾
   AND  SUHM.item_id     = PRODC.item_id(+)  --���i�敪
   AND  SUHM.item_id     = ITEMC.item_id(+)  --�i�ڋ敪
   AND  SUHM.item_id     = CROWD.item_id(+)  --�Q�R�[�h
/
COMMENT ON TABLE APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V IS 'SKYLINK�p�󕥏�񐻕i�ȊO�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�N��                           IS '�N��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�q�ɃR�[�h                     IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�q�ɖ�                         IS '�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�i�ڋ敪                       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�i�ڋ敪��                     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�Q�R�[�h                       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�i�ڃR�[�h                     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�i�ږ���                       IS '�i�ږ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�i�ڗ���                       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.����݌�                       IS '����݌�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.����݌ɃP�[�X                 IS '����݌ɃP�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.����݌ɋ��z                   IS '����݌ɋ��z'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�d��                  IS '�������_�d��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�d���P�[�X            IS '�������_�d���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.������z_�d��                  IS '������z_�d��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�Đ�                  IS '�������_�Đ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�Đ��P�[�X            IS '�������_�Đ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.������z_�Đ�                  IS '������z_�Đ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_���g                  IS '�������_���g'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_���g�P�[�X            IS '�������_���g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.������z_���g                  IS '������z_���g'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�Đ����g              IS '�������_�Đ����g'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�Đ����g�P�[�X        IS '�������_�Đ����g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.������z_�Đ����g              IS '������z_�Đ����g'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_���i���              IS '�������_���i���'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_���i���P�[�X        IS '�������_���i���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.������z_���i���              IS '������z_���i���'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_����_�����i���       IS '�������_����_�����i���'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_����_�����i���P�[�X IS '�������_����_�����i���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.������z_����_�����i���       IS '������z_����_�����i���'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�l��                  IS '�������_�l��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�l���P�[�X            IS '�������_�l���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.������z_�l��                  IS '������z_�l��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�i��ړ�              IS '�������_�i��ړ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�i��ړ��P�[�X        IS '�������_�i��ړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.������z_�i��ړ�              IS '������z_�i��ړ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�q�Ɉړ�              IS '�������_�q�Ɉړ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_�q�Ɉړ��P�[�X        IS '�������_�q�Ɉړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.������z_�q�Ɉړ�              IS '������z_�q�Ɉړ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_���̑�                IS '�������_���̑�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.�������_���̑��P�[�X          IS '�������_���̑��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.������z_���̑�                IS '������z_���̑�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�Đ�                  IS '���o����_�Đ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�Đ��P�[�X            IS '���o����_�Đ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�Đ�                  IS '���o���z_�Đ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�u�����h���g          IS '���o����_�u�����h���g'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�u�����h���g�P�[�X    IS '���o����_�u�����h���g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�u�����h���g          IS '���o���z_�u�����h���g'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�Đ����g              IS '���o����_�Đ����g'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�Đ����g�P�[�X        IS '���o����_�Đ����g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�Đ����g              IS '���o���z_�Đ����g'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�                  IS '���o����_�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_��P�[�X            IS '���o����_��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�                  IS '���o���z_�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�Z�b�g                IS '���o����_�Z�b�g'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�Z�b�g�P�[�X          IS '���o����_�Z�b�g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�Z�b�g                IS '���o���z_�Z�b�g'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_����                  IS '���o����_����'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_����P�[�X            IS '���o����_����P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_����                  IS '���o���z_����'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�L��                  IS '���o����_�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�L���P�[�X            IS '���o����_�L���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�L��                  IS '���o���z_�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_���_                  IS '���o����_���_'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_���_�P�[�X            IS '���o����_���_�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_���_                  IS '���o���z_���_'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�U�֏o��              IS '���o����_�U�֏o��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�U�֏o�ɃP�[�X        IS '���o����_�U�֏o�ɃP�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�U�֏o��              IS '���o���z_�U�֏o��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_���i��                IS '���o����_���i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_���i�փP�[�X          IS '���o����_���i�փP�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_���i��                IS '���o���z_���i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_����_�����i��         IS '���o����_����_�����i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_����_�����i�փP�[�X   IS '���o����_����_�����i�փP�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_����_�����i��         IS '���o���z_����_�����i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�]��                  IS '���o����_�]��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�]���P�[�X            IS '���o����_�]���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�]��                  IS '���o���z_�]��'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�p�p                  IS '���o����_�p�p'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�p�p�P�[�X            IS '���o����_�p�p�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�p�p                  IS '���o���z_�p�p'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_���{                  IS '���o����_���{'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_���{�P�[�X            IS '���o����_���{�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_���{                  IS '���o���z_���{'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�������o              IS '���o����_�������o'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�������o�P�[�X        IS '���o����_�������o�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�������o              IS '���o���z_�������o'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�o�����o              IS '���o����_�o�����o'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�o�����o�P�[�X        IS '���o����_�o�����o�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�o�����o              IS '���o���z_�o�����o'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�i��ړ�              IS '���o����_�i��ړ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�i��ړ��P�[�X        IS '���o����_�i��ړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�i��ړ�              IS '���o���z_�i��ړ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�q�Ɉړ�              IS '���o����_�q�Ɉړ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�q�Ɉړ��P�[�X        IS '���o����_�q�Ɉړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�q�Ɉړ�              IS '���o���z_�q�Ɉړ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_���̑�                IS '���o����_���̑�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_���̑��P�[�X          IS '���o����_���̑��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_���̑�                IS '���o���z_���̑�'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�I������              IS '���o����_�I������'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o����_�I�����ՃP�[�X        IS '���o����_�I�����ՃP�[�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�󕥏��_���i�ȊO_��{_V.���o���z_�I������              IS '���o���z_�I������'
/
