CREATE OR REPLACE VIEW APPS.XXSKY_�󕥏��_���i�ȊO_����_V
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
,�������_�d��
,�������_�d���P�[�X
,�������_�Đ�
,�������_�Đ��P�[�X
,�������_���g
,�������_���g�P�[�X
,�������_�Đ����g
,�������_�Đ����g�P�[�X
,�������_���i���
,�������_���i���P�[�X
,�������_����_�����i���
,�������_����_�����i���P�[�X
,�������_�l��
,�������_�l���P�[�X
,�������_�i��ړ�
,�������_�i��ړ��P�[�X
,�������_�q�Ɉړ�
,�������_�q�Ɉړ��P�[�X
,�������_���̑�
,�������_���̑��P�[�X
,���o����_�Đ�
,���o����_�Đ��P�[�X
,���o����_�u�����h���g
,���o����_�u�����h���g�P�[�X
,���o����_�Đ����g
,���o����_�Đ����g�P�[�X
,���o����_�
,���o����_��P�[�X
,���o����_�Z�b�g
,���o����_�Z�b�g�P�[�X
,���o����_����
,���o����_����P�[�X
,���o����_�L��
,���o����_�L���P�[�X
,���o����_���_
,���o����_���_�P�[�X
,���o����_�U�֏o��
,���o����_�U�֏o�ɃP�[�X
,���o����_���i��
,���o����_���i�փP�[�X
,���o����_����_�����i��
,���o����_����_�����i�փP�[�X
,���o����_�]��
,���o����_�]���P�[�X
,���o����_�p�p
,���o����_�p�p�P�[�X
,���o����_���{
,���o����_���{�P�[�X
,���o����_�������o
,���o����_�������o�P�[�X
,���o����_�o�����o
,���o����_�o�����o�P�[�X
,���o����_�i��ړ�
,���o����_�i��ړ��P�[�X
,���o����_�q�Ɉړ�
,���o����_�q�Ɉړ��P�[�X
,���o����_���̑�
,���o����_���̑��P�[�X
,���o����_�I������
,���o����_�I�����ՃP�[�X
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
        --1.���_�d��
       ,NVL( SUHM.trans_qty_uke_shiire          , 0 )  trans_qty_uke_shiire               --�������_�d��
       ,NVL( SUHM.trans_qty_uke_shiire_cs       , 0 )  trans_qty_uke_shiire_cs            --�������_�d���P�[�X
        --2.���_�Đ�
       ,NVL( SUHM.trans_qty_uke_saisei          , 0 )  trans_qty_uke_saisei               --�������_�Đ�
       ,NVL( SUHM.trans_qty_uke_saisei_cs       , 0 )  trans_qty_uke_saisei_cs            --�������_�Đ��P�[�X
        --3.���_���g
       ,NVL( SUHM.trans_qty_uke_gougumi         , 0 )  trans_qty_uke_gougumi              --�������_���g
       ,NVL( SUHM.trans_qty_uke_gougumi_cs      , 0 )  trans_qty_uke_gougumi_cs           --�������_���g�P�[�X
        --4.���_�Đ����g
       ,NVL( SUHM.trans_qty_uke_saigougumi      , 0 )  trans_qty_uke_saigougumi           --�������_�Đ����g
       ,NVL( SUHM.trans_qty_uke_saigougumi_cs   , 0 )  trans_qty_uke_saigougumi_cs        --�������_�Đ����g�P�[�X
        --5.���_���i���
       ,NVL( SUHM.trans_qty_uke_seihinyori      , 0 )  trans_qty_uke_seihinyori           --�������_���i���
       ,NVL( SUHM.trans_qty_uke_seihinyori_cs   , 0 )  trans_qty_uke_seihinyori_cs        --�������_���i���P�[�X
        --6.���_����_�����i���
       ,NVL( SUHM.trans_qty_uke_genhanseihin    , 0 )  trans_qty_uke_genhanseihin         --�������_����_�����i���
       ,NVL( SUHM.trans_qty_uke_genhanseihin_cs , 0 )  trans_qty_uke_genhanseihin_cs      --�������_����_�����i���P�[�X
        --20.���_�l��
       ,NVL( SUHM.trans_qty_uke_hamaoka         , 0 )  trans_qty_uke_hamaoka              --�������_�l��
       ,NVL( SUHM.trans_qty_uke_hamaoka_cs      , 0 )  trans_qty_uke_hamaoka_cs           --�������_�l���P�[�X
        --21.���_�i��ړ�
       ,NVL( SUHM.trans_qty_uke_hinsyuido       , 0 )  trans_qty_uke_hinsyuido            --�������_�i��ړ�
       ,NVL( SUHM.trans_qty_uke_hinsyuido_cs    , 0 )  trans_qty_uke_hinsyuido_cs         --�������_�i��ړ��P�[�X
        --22.���_�q�Ɉړ�
       ,NVL( SUHM.trans_qty_uke_soukoido        , 0 )  trans_qty_uke_soukoido             --�������_�q�Ɉړ�
       ,NVL( SUHM.trans_qty_uke_soukoido_cs     , 0 )  trans_qty_uke_soukoido_cs          --�������_�q�Ɉړ��P�[�X
        --23.���_���̑�
       ,NVL( SUHM.trans_qty_uke_sonota          , 0 )  trans_qty_uke_sonota               --�������_���̑�
       ,NVL( SUHM.trans_qty_uke_sonota_cs       , 0 )  trans_qty_uke_sonota_cs            --�������_���̑��P�[�X
        --8.���o_�Đ�
       ,NVL( SUHM.trans_qty_hara_saisei         , 0 )  trans_qty_hara_saisei              --���o����_�Đ�
       ,NVL( SUHM.trans_qty_hara_saisei_cs      , 0 )  trans_qty_hara_saisei_cs           --���o����_�Đ��P�[�X
        --9.���o_�u�����h���g
       ,NVL( SUHM.trans_qty_hara_brendgougumi   , 0 )  trans_qty_hara_brendgougumi        --���o����_�u�����h���g
       ,NVL( SUHM.trans_qty_hara_brendgougumi_cs, 0 )  trans_qty_hara_brendgougumi_cs     --���o����_�u�����h���g�P�[�X
        --10.���o_�Đ����g
       ,NVL( SUHM.trans_qty_hara_saigougumi     , 0 )  trans_qty_hara_saigougumi          --���o����_�Đ����g
       ,NVL( SUHM.trans_qty_hara_saigougumi_cs  , 0 )  trans_qty_hara_saigougumi_cs       --���o����_�Đ����g�P�[�X
        --11.���o_�
       ,NVL( SUHM.trans_qty_hara_housou         , 0 )  trans_qty_hara_housou              --���o����_�
       ,NVL( SUHM.trans_qty_hara_housou_cs      , 0 )  trans_qty_hara_housou_cs           --���o����_��P�[�X
        --12.���o_�Z�b�g
       ,NVL( SUHM.trans_qty_hara_set            , 0 )  trans_qty_hara_set                 --���o����_�Z�b�g
       ,NVL( SUHM.trans_qty_hara_set_cs         , 0 )  trans_qty_hara_set_cs              --���o����_�Z�b�g�P�[�X
        --13.���o_����
       ,NVL( SUHM.trans_qty_hara_okinawa        , 0 )  trans_qty_hara_okinawa             --���o����_����
       ,NVL( SUHM.trans_qty_hara_okinawa_cs     , 0 )  trans_qty_hara_okinawa_cs          --���o����_����P�[�X
        --14.���o_�L��
       ,NVL( SUHM.trans_qty_hara_yusyou         , 0 )  trans_qty_hara_yusyou              --���o����_�L��
       ,NVL( SUHM.trans_qty_hara_yusyou_cs      , 0 )  trans_qty_hara_yusyou_cs           --���o����_�L���P�[�X
        --15.���o_���_
       ,NVL( SUHM.trans_qty_hara_kyoten         , 0 )  trans_qty_hara_kyoten              --���o����_���_
       ,NVL( SUHM.trans_qty_hara_kyoten_cs      , 0 )  trans_qty_hara_kyoten_cs           --���o����_���_�P�[�X
        --16.���o_�U�֏o��
       ,NVL( SUHM.trans_qty_hara_furisyukko     , 0 )  trans_qty_hara_furisyukko          --���o����_�U�֏o��
       ,NVL( SUHM.trans_qty_hara_furisyukko_cs  , 0 )  trans_qty_hara_furisyukko_cs       --���o����_�U�֏o�ɃP�[�X
        --17.���o_���i��
       ,NVL( SUHM.trans_qty_hara_seihinhe       , 0 )  trans_qty_hara_seihinhe            --���o����_���i��
       ,NVL( SUHM.trans_qty_hara_seihinhe_cs    , 0 )  trans_qty_hara_seihinhe_cs         --���o����_���i�փP�[�X
        --18.���o_����_�����i��
       ,NVL( SUHM.trans_qty_hara_genhanseihin   , 0 )  trans_qty_hara_genhanseihin        --���o����_����_�����i��
       ,NVL( SUHM.trans_qty_hara_genhanseihin_cs, 0 )  trans_qty_hara_genhanseihin_cs     --���o����_����_�����i�փP�[�X
        --24.���o_�]��
       ,NVL( SUHM.trans_qty_hara_tenbai         , 0 )  trans_qty_hara_tenbai              --���o����_�]��
       ,NVL( SUHM.trans_qty_hara_tenbai_cs      , 0 )  trans_qty_hara_tenbai_cs           --���o����_�]���P�[�X
        --25.���o_�p�p
       ,NVL( SUHM.trans_qty_hara_haikyaku       , 0 )  trans_qty_hara_haikyaku            --���o����_�p�p
       ,NVL( SUHM.trans_qty_hara_haikyaku_cs    , 0 )  trans_qty_hara_haikyaku_cs         --���o����_�p�p�P�[�X
        --26.���o_���{
       ,NVL( SUHM.trans_qty_hara_mihon          , 0 )  trans_qty_hara_mihon               --���o����_���{
       ,NVL( SUHM.trans_qty_hara_mihon_cs       , 0 )  trans_qty_hara_mihon_cs            --���o����_���{�P�[�X
        --27.���o_�������o
       ,NVL( SUHM.trans_qty_hara_soumu          , 0 )  trans_qty_hara_soumu               --���o����_�������o
       ,NVL( SUHM.trans_qty_hara_soumu_cs       , 0 )  trans_qty_hara_soumu_cs            --���o����_�������o�P�[�X
        --28.���o_�o�����o
       ,NVL( SUHM.trans_qty_hara_keiri          , 0 )  trans_qty_hara_keiri               --���o����_�o�����o
       ,NVL( SUHM.trans_qty_hara_keiri_cs       , 0 )  trans_qty_hara_keiri_cs            --���o����_�o�����o�P�[�X
        --29.���o_�i��ړ�
       ,NVL( SUHM.trans_qty_hara_hinsyuido      , 0 )  trans_qty_hara_hinsyuido           --���o����_�i��ړ�
       ,NVL( SUHM.trans_qty_hara_hinsyuido_cs   , 0 )  trans_qty_hara_hinsyuido_cs        --���o����_�i��ړ��P�[�X
        --30.���o_�q�Ɉړ�
       ,NVL( SUHM.trans_qty_hara_soukoido       , 0 )  trans_qty_hara_soukoido            --���o����_�q�Ɉړ�
       ,NVL( SUHM.trans_qty_hara_soukoido_cs    , 0 )  trans_qty_hara_soukoido_cs         --���o����_�q�Ɉړ��P�[�X
        --31.���o_���̑�
       ,NVL( SUHM.trans_qty_hara_sonota         , 0 )  trans_qty_hara_sonota              --���o����_���̑�
       ,NVL( SUHM.trans_qty_hara_sonota_cs      , 0 )  trans_qty_hara_sonota_cs           --���o����_���̑��P�[�X
        --32.���o_�I������
       ,NVL( SUHM.trans_qty_hara_genmou         , 0 )  trans_qty_hara_genmou              --���o����_�I������
       ,NVL( SUHM.trans_qty_hara_genmou_cs      , 0 )  trans_qty_hara_genmou_cs           --���o����_�I�����ՃP�[�X
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
                 --1.�������_�d��
                ,SUM( CASE WHEN UHM.column_no =  1 THEN UHM.trans_qty                     END ) trans_qty_uke_shiire           --�������_�d��
                ,SUM( CASE WHEN UHM.column_no =  1 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_shiire_cs        --�������_�d���P�[�X��
                 --2.�������_�Đ�
                ,SUM( CASE WHEN UHM.column_no =  2 THEN UHM.trans_qty                     END ) trans_qty_uke_saisei           --�������_�Đ�
                ,SUM( CASE WHEN UHM.column_no =  2 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_saisei_cs        --�������_�Đ��P�[�X��
                 --3.�������_���g
                ,SUM( CASE WHEN UHM.column_no =  3 THEN UHM.trans_qty                     END ) trans_qty_uke_gougumi          --�������_���g
                ,SUM( CASE WHEN UHM.column_no =  3 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_gougumi_cs       --�������_���g�P�[�X��
                 --4.�������_�Đ����g
                ,SUM( CASE WHEN UHM.column_no =  4 THEN UHM.trans_qty                     END ) trans_qty_uke_saigougumi       --�������_�Đ����g
                ,SUM( CASE WHEN UHM.column_no =  4 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_saigougumi_cs    --�������_�Đ����g�P�[�X��
                 --5.�������_���i���
                ,SUM( CASE WHEN UHM.column_no =  5 THEN UHM.trans_qty                     END ) trans_qty_uke_seihinyori       --�������_���i���
                ,SUM( CASE WHEN UHM.column_no =  5 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_seihinyori_cs    --�������_���i���P�[�X��
                 --6.�������_����_�����i���
                ,SUM( CASE WHEN UHM.column_no =  6 THEN UHM.trans_qty                     END ) trans_qty_uke_genhanseihin     --�������_����_�����i���
                ,SUM( CASE WHEN UHM.column_no =  6 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_genhanseihin_cs  --�������_����_�����i���P�[�X��
                 --20.�������_�l��
                ,SUM( CASE WHEN UHM.column_no = 20 THEN UHM.trans_qty                     END ) trans_qty_uke_hamaoka          --�������_�l��
                ,SUM( CASE WHEN UHM.column_no = 20 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_hamaoka_cs       --�������_�l���P�[�X��
                 --21.�������_�i��ړ�
                ,SUM( CASE WHEN UHM.column_no = 21 THEN UHM.trans_qty                     END ) trans_qty_uke_hinsyuido        --�������_�i��ړ�
                ,SUM( CASE WHEN UHM.column_no = 21 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_hinsyuido_cs     --�������_�i��ړ��P�[�X��
                 --22.�������_�q�Ɉړ�
                ,SUM( CASE WHEN UHM.column_no = 22 THEN UHM.trans_qty                     END ) trans_qty_uke_soukoido         --�������_�q�Ɉړ�
                ,SUM( CASE WHEN UHM.column_no = 22 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_soukoido_cs      --�������_�q�Ɉړ��P�[�X��
                 --23.�������_���̑�
                ,SUM( CASE WHEN UHM.column_no = 23 THEN UHM.trans_qty                     END ) trans_qty_uke_sonota           --�������_���̑�
                ,SUM( CASE WHEN UHM.column_no = 23 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_sonota_cs        --�������_���̑��P�[�X��
                 --8.���o����_�Đ�
                ,SUM( CASE WHEN UHM.column_no =  8 THEN UHM.trans_qty                     END ) trans_qty_hara_saisei          --���o����_�Đ�
                ,SUM( CASE WHEN UHM.column_no =  8 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_saisei_cs       --���o����_�Đ��P�[�X��
                 --9.���o����_�u�����h���g
                ,SUM( CASE WHEN UHM.column_no =  9 THEN UHM.trans_qty                     END ) trans_qty_hara_brendgougumi    --���o����_�u�����h���g
                ,SUM( CASE WHEN UHM.column_no =  9 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_brendgougumi_cs --���o����_�u�����h���g�P�[�X��
                 --10.���o����_�Đ����g
                ,SUM( CASE WHEN UHM.column_no = 10 THEN UHM.trans_qty                     END ) trans_qty_hara_saigougumi      --���o����_�Đ����g
                ,SUM( CASE WHEN UHM.column_no = 10 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_saigougumi_cs   --���o����_�Đ����g�P�[�X��
                 --11.���o����_�
                ,SUM( CASE WHEN UHM.column_no = 11 THEN UHM.trans_qty                     END ) trans_qty_hara_housou          --���o����_�
                ,SUM( CASE WHEN UHM.column_no = 11 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_housou_cs       --���o����_��P�[�X��
                 --12.���o����_�Z�b�g
                ,SUM( CASE WHEN UHM.column_no = 12 THEN UHM.trans_qty                     END ) trans_qty_hara_set             --���o����_�Z�b�g
                ,SUM( CASE WHEN UHM.column_no = 12 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_set_cs          --���o����_�Z�b�g�P�[�X��
                 --13.���o����_����
                ,SUM( CASE WHEN UHM.column_no = 13 THEN UHM.trans_qty                     END ) trans_qty_hara_okinawa         --���o����_����
                ,SUM( CASE WHEN UHM.column_no = 13 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_okinawa_cs      --���o����_����P�[�X��
                 --14.���o����_�L��
                ,SUM( CASE WHEN UHM.column_no = 14 THEN UHM.trans_qty                     END ) trans_qty_hara_yusyou          --���o����_�L��
                ,SUM( CASE WHEN UHM.column_no = 14 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_yusyou_cs       --���o����_�L���P�[�X��
                 --15.���o����_���_
                ,SUM( CASE WHEN UHM.column_no = 15 THEN UHM.trans_qty                     END ) trans_qty_hara_kyoten          --���o����_���_
                ,SUM( CASE WHEN UHM.column_no = 15 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_kyoten_cs       --���o����_���_�P�[�X��
                 --16.���o����_�U�֏o��
                ,SUM( CASE WHEN UHM.column_no = 16 THEN UHM.trans_qty                     END ) trans_qty_hara_furisyukko      --���o����_�U�֏o��
                ,SUM( CASE WHEN UHM.column_no = 16 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_furisyukko_cs   --���o����_�U�֏o�ɃP�[�X��
                 --17.���o����_���i��
                ,SUM( CASE WHEN UHM.column_no = 17 THEN UHM.trans_qty                     END ) trans_qty_hara_seihinhe        --���o����_���i��
                ,SUM( CASE WHEN UHM.column_no = 17 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_seihinhe_cs     --���o����_���i�փP�[�X��
                 --18.���o����_����_�����i��
                ,SUM( CASE WHEN UHM.column_no = 18 THEN UHM.trans_qty                     END ) trans_qty_hara_genhanseihin    --���o����_����_�����i��
                ,SUM( CASE WHEN UHM.column_no = 18 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_genhanseihin_cs --���o����_����_�����i�փP�[�X��
                 --24.���o����_�]��
                ,SUM( CASE WHEN UHM.column_no = 24 THEN UHM.trans_qty                     END ) trans_qty_hara_tenbai          --���o����_�]��
                ,SUM( CASE WHEN UHM.column_no = 24 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_tenbai_cs       --���o����_�]���P�[�X��
                 --25.���o����_�p�p
                ,SUM( CASE WHEN UHM.column_no = 25 THEN UHM.trans_qty                     END ) trans_qty_hara_haikyaku        --���o����_�p�p
                ,SUM( CASE WHEN UHM.column_no = 25 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_haikyaku_cs     --���o����_�p�p�P�[�X��
                 --26.���o����_���{
                ,SUM( CASE WHEN UHM.column_no = 26 THEN UHM.trans_qty                     END ) trans_qty_hara_mihon           --���o����_���{
                ,SUM( CASE WHEN UHM.column_no = 26 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_mihon_cs        --���o����_���{�P�[�X��
                 --27.���o����_�������o
                ,SUM( CASE WHEN UHM.column_no = 27 THEN UHM.trans_qty                     END ) trans_qty_hara_soumu           --���o����_�������o
                ,SUM( CASE WHEN UHM.column_no = 27 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_soumu_cs        --���o����_�������o�P�[�X��
                 --28.���o����_�o�����o
                ,SUM( CASE WHEN UHM.column_no = 28 THEN UHM.trans_qty                     END ) trans_qty_hara_keiri           --���o����_�o�����o
                ,SUM( CASE WHEN UHM.column_no = 28 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_keiri_cs        --���o����_�o�����o�P�[�X��
                 --29.���o����_�i��ړ�
                ,SUM( CASE WHEN UHM.column_no = 29 THEN UHM.trans_qty                     END ) trans_qty_hara_hinsyuido       --���o����_�i��ړ�
                ,SUM( CASE WHEN UHM.column_no = 29 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_hinsyuido_cs    --���o����_�i��ړ��P�[�X��
                 --30.���o����_�q�Ɉړ�
                ,SUM( CASE WHEN UHM.column_no = 30 THEN UHM.trans_qty                     END ) trans_qty_hara_soukoido        --���o����_�q�Ɉړ�
                ,SUM( CASE WHEN UHM.column_no = 30 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_soukoido_cs     --���o����_�q�Ɉړ��P�[�X��
                 --31.���o����_���̑�
                ,SUM( CASE WHEN UHM.column_no = 31 THEN UHM.trans_qty                     END ) trans_qty_hara_sonota          --���o����_���̑�
                ,SUM( CASE WHEN UHM.column_no = 31 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_sonota_cs       --���o����_���̑��P�[�X��
                 --32.���o����_�I������
                ,SUM( CASE WHEN UHM.column_no = 32 THEN UHM.trans_qty                     END ) trans_qty_hara_genmou          --���o����_�I������
                ,SUM( CASE WHEN UHM.column_no = 32 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_genmou_cs       --���o����_�I�����ՃP�[�X
           FROM
                 xxsky_uh_materials_v                  UHM                 --SKYLINK�p����VIEW �󕥏��_���i�ȊOVIEW
                ,xxsky_item_mst2_v                     ITEM                --SKYLINK�p����VIEW OPM�i�ڏ��VIEW
          WHERE
            --�i�ڏ��擾
                 UHM.item_id                  = ITEM.item_id(+)
            AND  TRUNC( UHM.trans_date )     >= ITEM.start_date_active(+)
            AND  TRUNC( UHM.trans_date )     <= ITEM.end_date_active(+)
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
       ,xxsky_prod_class_v              PRODC          --SKYLINK�p ���i�敪�擾VIEW
       ,xxsky_item_class_v              ITEMC          --SKYLINK�p �i�ڋ敪�擾VIEW
       ,xxsky_crowd_code_v              CROWD          --SKYLINK�p �Q�R�[�h�擾VIEW
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
COMMENT ON TABLE APPS.XXSKY_�󕥏��_���i�ȊO_����_V IS 'SKYLINK�p�󕥏�񐻕i�ȊO�i���ʁjVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�N��                           IS '�N��'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�q�ɃR�[�h                     IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�q�ɖ�                         IS '�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�i�ڋ敪                       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�i�ڋ敪��                     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�Q�R�[�h                       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�i�ڃR�[�h                     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�i�ږ���                       IS '�i�ږ���'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�i�ڗ���                       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.����݌�                       IS '����݌�'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.����݌ɃP�[�X                 IS '����݌ɃP�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�d��                  IS '�������_�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�d���P�[�X            IS '�������_�d���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�Đ�                  IS '�������_�Đ�'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�Đ��P�[�X            IS '�������_�Đ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_���g                  IS '�������_���g'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_���g�P�[�X            IS '�������_���g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�Đ����g              IS '�������_�Đ����g'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�Đ����g�P�[�X        IS '�������_�Đ����g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_���i���              IS '�������_���i���'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_���i���P�[�X        IS '�������_���i���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_����_�����i���       IS '�������_����_�����i���'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_����_�����i���P�[�X IS '�������_����_�����i���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�l��                  IS '�������_�l��'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�l���P�[�X            IS '�������_�l���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�i��ړ�              IS '�������_�i��ړ�'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�i��ړ��P�[�X        IS '�������_�i��ړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�q�Ɉړ�              IS '�������_�q�Ɉړ�'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_�q�Ɉړ��P�[�X        IS '�������_�q�Ɉړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_���̑�                IS '�������_���̑�'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.�������_���̑��P�[�X          IS '�������_���̑��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�Đ�                  IS '���o����_�Đ�'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�Đ��P�[�X            IS '���o����_�Đ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�u�����h���g          IS '���o����_�u�����h���g'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�u�����h���g�P�[�X    IS '���o����_�u�����h���g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�Đ����g              IS '���o����_�Đ����g'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�Đ����g�P�[�X        IS '���o����_�Đ����g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�                  IS '���o����_�'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_��P�[�X            IS '���o����_��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�Z�b�g                IS '���o����_�Z�b�g'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�Z�b�g�P�[�X          IS '���o����_�Z�b�g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_����                  IS '���o����_����'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_����P�[�X            IS '���o����_����P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�L��                  IS '���o����_�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�L���P�[�X            IS '���o����_�L���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_���_                  IS '���o����_���_'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_���_�P�[�X            IS '���o����_���_�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�U�֏o��              IS '���o����_�U�֏o��'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�U�֏o�ɃP�[�X        IS '���o����_�U�֏o�ɃP�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_���i��                IS '���o����_���i��'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_���i�փP�[�X          IS '���o����_���i�փP�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_����_�����i��         IS '���o����_����_�����i��'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_����_�����i�փP�[�X   IS '���o����_����_�����i�փP�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�]��                  IS '���o����_�]��'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�]���P�[�X            IS '���o����_�]���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�p�p                  IS '���o����_�p�p'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�p�p�P�[�X            IS '���o����_�p�p�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_���{                  IS '���o����_���{'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_���{�P�[�X            IS '���o����_���{�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�������o              IS '���o����_�������o'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�������o�P�[�X        IS '���o����_�������o�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�o�����o              IS '���o����_�o�����o'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�o�����o�P�[�X        IS '���o����_�o�����o�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�i��ړ�              IS '���o����_�i��ړ�'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�i��ړ��P�[�X        IS '���o����_�i��ړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�q�Ɉړ�              IS '���o����_�q�Ɉړ�'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�q�Ɉړ��P�[�X        IS '���o����_�q�Ɉړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_���̑�                IS '���o����_���̑�'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_���̑��P�[�X          IS '���o����_���̑��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�I������              IS '���o����_�I������'
/
COMMENT ON COLUMN APPS.XXSKY_�󕥏��_���i�ȊO_����_V.���o����_�I�����ՃP�[�X        IS '���o����_�I�����ՃP�[�X'
/
