CREATE OR REPLACE VIEW APPS.XXSKY_��_���i_��{2_V
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
,�������_�
,�������_��P�[�X
,������z_�
,�������_�Z�b�g
,�������_�Z�b�g�P�[�X
,������z_�Z�b�g
,�������_����
,�������_����P�[�X
,������z_����
,�������_�U�֓���
,�������_�U�֓��ɃP�[�X
,������z_�U�֓���
,�������_�Ήc�P
,�������_�Ήc�P�P�[�X
,������z_�Ήc�P
,�������_�Ήc�Q
,�������_�Ήc�Q�P�[�X
,������z_�Ήc�Q
,�������_�h�����N�M�t�g
,�������_�h�����N�M�t�g�P�[�X
,������z_�h�����N�M�t�g
,�������_�q��
,�������_�q�փP�[�X
,������z_�q��
,�������_�ԕi
,�������_�ԕi�P�[�X
,������z_�ԕi
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
,���o����_�Z�b�g
,���o����_�Z�b�g�P�[�X
,���o���z_�Z�b�g
,���o����_�ԕi������
,���o����_�ԕi�����փP�[�X
,���o���z_�ԕi������
,���o����_��̔����i��
,���o����_��̔����i�փP�[�X
,���o���z_��̔����i��
,���o����_�L��
,���o����_�L���P�[�X
,���o���z_�L��
,���o����_�U�֗L��
,���o����_�U�֗L���P�[�X
,���o���z_�U�֗L��
,���o����_���_
,���o����_���_�P�[�X
,���o���z_���_
,���o����_�h�����N�M�t�g
,���o����_�h�����N�M�t�g�P�[�X
,���o���z_�h�����N�M�t�g
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
        SUHG.yyyymm                                    yyyymm                        --�N��
       ,PRODC.prod_class_code                          prod_class_code               --���i�敪
       ,PRODC.prod_class_name                          prod_class_name               --���i�敪��
       ,SUHG.whse_code                                 whse_code                     --�q�ɃR�[�h
       ,IWM.whse_name                                  whse_name                     --�q�ɖ�
       ,ITEMC.item_class_code                          item_class_code               --�i�ڋ敪
       ,ITEMC.item_class_name                          item_class_name               --�i�ڋ敪��
       ,CROWD.crowd_code                               crowd_code                    --�Q�R�[�h
       ,SUHG.item_code                                 item_code                     --�i�ڃR�[�h
       ,SUHG.item_name                                 item_name                     --�i�ږ���
       ,SUHG.item_s_name                               item_s_name                   --�i�ڗ���
        --0.����݌�
       ,NVL( SUHG.trans_qty_gessyuzaiko      , 0 )     trans_qty_gessyuzaiko         --����݌�
       ,NVL( SUHG.trans_qty_gessyuzaiko_cs   , 0 )     trans_qty_gessyuzaiko_cs      --����݌ɃP�[�X
       ,NVL( SUHG.price_gessyuzaiko          , 0 )     price_gessyuzaiko             --����݌ɋ��z
        --1.���_�d��
       ,NVL( SUHG.trans_qty_uke_shiire       , 0 )     trans_qty_uke_shiire          --�������_�d��
       ,NVL( SUHG.trans_qty_uke_shiire_cs    , 0 )     trans_qty_uke_shiire_cs       --�������_�d���P�[�X��
       ,NVL( SUHG.price_uke_shiire           , 0 )     price_uke_shiire              --������z_�d��
        --2.���_�
       ,NVL( SUHG.trans_qty_uke_housou       , 0 )     trans_qty_uke_housou          --�������_�
       ,NVL( SUHG.trans_qty_uke_housou_cs    , 0 )     trans_qty_uke_housou_cs       --�������_��P�[�X��
       ,NVL( SUHG.price_uke_housou           , 0 )     price_uke_housou              --������z_�
        --3.���_�Z�b�g
       ,NVL( SUHG.trans_qty_uke_set          , 0 )     trans_qty_uke_set             --�������_�Z�b�g
       ,NVL( SUHG.trans_qty_uke_set_cs       , 0 )     trans_qty_uke_set_cs          --�������_�Z�b�g�P�[�X
       ,NVL( SUHG.price_uke_set              , 0 )     price_uke_set                 --������z_�Z�b�g
        --4.���_����
       ,NVL( SUHG.trans_qty_uke_okinawa      , 0 )     trans_qty_uke_okinawa         --�������_����
       ,NVL( SUHG.trans_qty_uke_okinawa_cs   , 0 )     trans_qty_uke_okinawa_cs      --�������_����P�[�X
       ,NVL( SUHG.price_uke_okinawa          , 0 )     price_uke_okinawa             --������z_����
        --5.���_�U�֓���
       ,NVL( SUHG.trans_qty_uke_furikaein    , 0 )     trans_qty_uke_furikaein       --�������_�U�֓���
       ,NVL( SUHG.trans_qty_uke_furikaein_cs , 0 )     trans_qty_uke_furikaein_cs    --�������_�U�֓��ɃP�[�X
       ,NVL( SUHG.price_uke_furikaein        , 0 )     price_uke_furikaein           --������z_�U�֓���
        --6.���_�Ήc�P
       ,NVL( SUHG.trans_qty_uke_ryokuei1     , 0 )     trans_qty_uke_ryokuei1        --�������_�Ήc�P
       ,NVL( SUHG.trans_qty_uke_ryokuei1_cs  , 0 )     trans_qty_uke_ryokuei1_cs     --�������_�Ήc�P�P�[�X
       ,NVL( SUHG.price_uke_ryokuei1         , 0 )     price_uke_ryokuei1            --������z_�Ήc�P
        --7.���_�Ήc�Q
       ,NVL( SUHG.trans_qty_uke_ryokuei2     , 0 )     trans_qty_uke_ryokuei2        --�������_�Ήc�Q
       ,NVL( SUHG.trans_qty_uke_ryokuei2_cs  , 0 )     trans_qty_uke_ryokuei2_cs     --�������_�Ήc�Q�P�[�X
       ,NVL( SUHG.price_uke_ryokuei2         , 0 )     price_uke_ryokuei2            --������z_�Ήc�Q
        --8.���_�h�����N�M�t�g
       ,NVL( SUHG.trans_qty_uke_drinkgift    , 0 )     trans_qty_uke_drinkgift       --�������_�h�����N�M�t�g
       ,NVL( SUHG.trans_qty_uke_drinkgift_cs , 0 )     trans_qty_uke_drinkgift_cs    --�������_�h�����N�M�t�g�P�[�X
       ,NVL( SUHG.price_uke_drinkgift        , 0 )     price_uke_drinkgift           --������z_�h�����N�M�t�g
        --9.���_�q��
       ,NVL( SUHG.trans_qty_uke_kuragae      , 0 )     trans_qty_uke_kuragae         --�������_�q��
       ,NVL( SUHG.trans_qty_uke_kuragae_cs   , 0 )     trans_qty_uke_kuragae_cs      --�������_�q�փP�[�X
       ,NVL( SUHG.price_uke_kuragae          , 0 )     price_uke_kuragae             --������z_�q��
        --10.���_�ԕi
       ,NVL( SUHG.trans_qty_uke_henpin       , 0 )     trans_qty_uke_henpin          --�������_�ԕi
       ,NVL( SUHG.trans_qty_uke_henpin_cs    , 0 )     trans_qty_uke_henpin_cs       --�������_�ԕi�P�[�X
       ,NVL( SUHG.price_uke_henpin           , 0 )     price_uke_henpin              --������z_�ԕi
        --20.���_�l��
       ,NVL( SUHG.trans_qty_uke_hamaoka      , 0 )     trans_qty_uke_hamaoka         --�������_�l��
       ,NVL( SUHG.trans_qty_uke_hamaoka_cs   , 0 )     trans_qty_uke_hamaoka_cs      --�������_�l���P�[�X
       ,NVL( SUHG.price_uke_hamaoka          , 0 )     price_uke_hamaoka             --������z_�l��
        --21.���_�i��ړ�
       ,NVL( SUHG.trans_qty_uke_hinsyuido    , 0 )     trans_qty_uke_hinsyuido       --�������_�i��ړ�
       ,NVL( SUHG.trans_qty_uke_hinsyuido_cs , 0 )     trans_qty_uke_hinsyuido_cs    --�������_�i��ړ��P�[�X
       ,NVL( SUHG.price_uke_hinsyuido        , 0 )     price_uke_hinsyuido           --������z_�i��ړ�
        --22.���_�q�Ɉړ�
       ,NVL( SUHG.trans_qty_uke_soukoido     , 0 )     trans_qty_uke_soukoido        --�������_�q�Ɉړ�
       ,NVL( SUHG.trans_qty_uke_soukoido_cs  , 0 )     trans_qty_uke_soukoido_cs     --�������_�q�Ɉړ��P�[�X
       ,NVL( SUHG.price_uke_soukoido         , 0 )     price_uke_soukoido            --������z_�q�Ɉړ�
        --23.���_���̑�
       ,NVL( SUHG.trans_qty_uke_sonota       , 0 )     trans_qty_uke_sonota          --�������_���̑�
       ,NVL( SUHG.trans_qty_uke_sonota_cs    , 0 )     trans_qty_uke_sonota_cs       --�������_���̑��P�[�X
       ,NVL( SUHG.price_uke_sonota           , 0 )     price_uke_sonota              --������z_���̑�
        --12.���o_�Z�b�g
       ,NVL( SUHG.trans_qty_hara_set         , 0 )     trans_qty_hara_set            --���o����_�Z�b�g
       ,NVL( SUHG.trans_qty_hara_set_cs      , 0 )     trans_qty_hara_set_cs         --���o����_�Z�b�g�P�[�X
       ,NVL( SUHG.price_hara_set             , 0 )     price_hara_set                --���o���z_�Z�b�g
        --13.���o_�ԕi������
       ,NVL( SUHG.trans_qty_hara_hengen      , 0 )     trans_qty_hara_hengen         --���o����_�ԕi������
       ,NVL( SUHG.trans_qty_hara_hengen_cs   , 0 )     trans_qty_hara_hengen_cs      --���o����_�ԕi�����փP�[�X
       ,NVL( SUHG.price_hara_hengen          , 0 )     price_hara_hengen             --���o���z_�ԕi������
        --14.���o_��̔����i��
       ,NVL( SUHG.trans_qty_hara_kaihan      , 0 )     trans_qty_hara_kaihan         --���o����_��̔����i��
       ,NVL( SUHG.trans_qty_hara_kaihan_cs   , 0 )     trans_qty_hara_kaihan_cs      --���o����_��̔����i�փP�[�X
       ,NVL( SUHG.price_hara_kaihan          , 0 )     price_hara_kaihan             --���o���z_��̔����i��
        --15.���o_�L��
       ,NVL( SUHG.trans_qty_hara_yusyou      , 0 )     trans_qty_hara_yusyou         --���o����_�L��
       ,NVL( SUHG.trans_qty_hara_yusyou_cs   , 0 )     trans_qty_hara_yusyou_cs      --���o����_�L���P�[�X
       ,NVL( SUHG.price_hara_yusyou          , 0 )     price_hara_yusyou             --���o���z_�L��
        --16.���o_�U�֗L��
       ,NVL( SUHG.trans_qty_hara_furikae     , 0 )     trans_qty_hara_furikae        --���o����_�U�֗L��
       ,NVL( SUHG.trans_qty_hara_furikae_cs  , 0 )     trans_qty_hara_furikae_cs     --���o����_�U�֗L���P�[�X
       ,NVL( SUHG.price_hara_furikae         , 0 )     price_hara_furikae            --���o���z_�U�֗L��
        --17.���o_���_
       ,NVL( SUHG.trans_qty_hara_kyoten      , 0 )     trans_qty_hara_kyoten         --���o����_���_
       ,NVL( SUHG.trans_qty_hara_kyoten_cs   , 0 )     trans_qty_hara_kyoten_cs      --���o����_���_�P�[�X
       ,NVL( SUHG.price_hara_kyoten          , 0 )     price_hara_kyoten             --���o���z_���_
        --18.���o_�h�����N�M�t�g
       ,NVL( SUHG.trans_qty_hara_drinkgift   , 0 )     trans_qty_hara_drinkgift      --���o����_�h�����N�M�t�g
       ,NVL( SUHG.trans_qty_hara_drinkgift_cs, 0 )     trans_qty_hara_drinkgift_cs   --���o����_�h�����N�M�t�g�P�[�X
       ,NVL( SUHG.price_hara_drinkgift       , 0 )     price_hara_drinkgift          --���o���z_�h�����N�M�t�g
        --24.���o_�]��
       ,NVL( SUHG.trans_qty_hara_tenbai      , 0 )     trans_qty_hara_tenbai         --���o����_�]��
       ,NVL( SUHG.trans_qty_hara_tenbai_cs   , 0 )     trans_qty_hara_tenbai_cs      --���o����_�]���P�[�X
       ,NVL( SUHG.price_hara_tenbai          , 0 )     price_hara_tenbai             --���o���z_�]��
        --25.���o_�p�p
       ,NVL( SUHG.trans_qty_hara_haikyaku    , 0 )     trans_qty_hara_haikyaku       --���o����_�p�p
       ,NVL( SUHG.trans_qty_hara_haikyaku_cs , 0 )     trans_qty_hara_haikyaku_cs    --���o����_�p�p�P�[�X
       ,NVL( SUHG.price_hara_haikyaku        , 0 )     price_hara_haikyaku           --���o���z_�p�p
        --26.���o_���{
       ,NVL( SUHG.trans_qty_hara_mihon       , 0 )     trans_qty_hara_mihon          --���o����_���{
       ,NVL( SUHG.trans_qty_hara_mihon_cs    , 0 )     trans_qty_hara_mihon_cs       --���o����_���{�P�[�X
       ,NVL( SUHG.price_hara_mihon           , 0 )     price_hara_mihon              --���o���z_���{
        --27.���o_�������o
       ,NVL( SUHG.trans_qty_hara_soumu       , 0 )     trans_qty_hara_soumu          --���o����_�������o
       ,NVL( SUHG.trans_qty_hara_soumu_cs    , 0 )     trans_qty_hara_soumu_cs       --���o����_�������o�P�[�X
       ,NVL( SUHG.price_hara_soumu           , 0 )     price_hara_soumu              --���o���z_�������o
        --28.���o_�o�����o
       ,NVL( SUHG.trans_qty_hara_keiri       , 0 )     trans_qty_hara_keiri          --���o����_�o�����o
       ,NVL( SUHG.trans_qty_hara_keiri_cs    , 0 )     trans_qty_hara_keiri_cs       --���o����_�o�����o�P�[�X
       ,NVL( SUHG.price_hara_keiri           , 0 )     price_hara_keiri              --���o���z_�o�����o
        --29.���o_�i��ړ�
       ,NVL( SUHG.trans_qty_hara_hinsyuido   , 0 )     trans_qty_hara_hinsyuido      --���o����_�i��ړ�
       ,NVL( SUHG.trans_qty_hara_hinsyuido_cs, 0 )     trans_qty_hara_hinsyuido_cs   --���o����_�i��ړ��P�[�X
       ,NVL( SUHG.price_hara_hinsyuido       , 0 )     price_hara_hinsyuido          --���o���z_�i��ړ�
        --30.���o_�q�Ɉړ�
       ,NVL( SUHG.trans_qty_hara_soukoido    , 0 )     trans_qty_hara_soukoido       --���o����_�q�Ɉړ�
       ,NVL( SUHG.trans_qty_hara_soukoido_cs , 0 )     trans_qty_hara_soukoido_cs    --���o����_�q�Ɉړ��P�[�X
       ,NVL( SUHG.price_hara_soukoido        , 0 )     price_hara_soukoido           --���o���z_�q�Ɉړ�
        --31.���o_���̑�
       ,NVL( SUHG.trans_qty_hara_sonota      , 0 )     trans_qty_hara_sonota         --���o����_���̑�
       ,NVL( SUHG.trans_qty_hara_sonota_cs   , 0 )     trans_qty_hara_sonota_cs      --���o����_���̑��P�[�X
       ,NVL( SUHG.price_hara_sonota          , 0 )     price_hara_sonota             --���o���z_���̑�
        --32.���o_�I������
       ,NVL( SUHG.trans_qty_hara_genmou      , 0 )     trans_qty_hara_genmou         --���o����_�I������
       ,NVL( SUHG.trans_qty_hara_genmou_cs   , 0 )     trans_qty_hara_genmou_cs      --���o����_�I�����ՃP�[�X
       ,NVL( SUHG.price_hara_genmou          , 0 )     price_hara_genmou             --���o���z_�I������
  FROM (
         --**********************************************************************************************
         -- �y�N���z�y�q�Ɂz�y�i�ځz�P�ʂɏW�v������������擾  START
         --**********************************************************************************************
         SELECT
                 TO_CHAR( UHG.trans_date, 'YYYYMM' )   yyyymm                        --�N��
                ,UHG.whse_code                         whse_code                     --�q�ɃR�[�h
                ,UHG.item_id                           item_id                       --�i��ID
                ,ITEM.item_no                          item_code                     --�i�ڃR�[�h
                ,ITEM.item_name                        item_name                     --�i�ږ���
                ,ITEM.item_short_name                  item_s_name                   --�i�ڗ���
                 --0.����݌�
                ,SUM( CASE WHEN UHG.column_no =  0 THEN UHG.trans_qty                     END ) trans_qty_gessyuzaiko       --����݌�
                ,SUM( CASE WHEN UHG.column_no =  0 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_gessyuzaiko_cs    --����݌ɃP�[�X��
                ,SUM( CASE WHEN UHG.column_no =  0 THEN
                                --------------------------------------------------------------------------------------------------
                                -- �y���z�v�Z�z �����גP�ʂŎl�̌ܓ�����K�v������                                              --
                                --     �@ �����Ǘ��敪��'1:�W��' �Ȃ�                                   �y�W�������~���ʁz      --
                                --     �A �����Ǘ��敪��'0:����' ���� ���b�g�Ǘ��Ǘ��敪��'0:����' �Ȃ� �y�W�������~���ʁz      --
                                --     �B �����Ǘ��敪��'0:����' ���� ���b�g�Ǘ��Ǘ��敪��'1:�L��' �Ȃ� �y���b�g�ʌ����~���ʁz  --
                                --------------------------------------------------------------------------------------------------
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )         --�@
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )   --�A
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )        --�B
                                          END
                                END
                      END )                                                                     price_gessyuzaiko           --����݌ɋ��z
                 --1.���_�d��
                ,SUM( CASE WHEN UHG.column_no =  1 THEN UHG.trans_qty                     END ) trans_qty_uke_shiire        --�������_�d��
                ,SUM( CASE WHEN UHG.column_no =  1 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_shiire_cs     --�������_�d���P�[�X��
                ,SUM( CASE WHEN UHG.column_no =  1 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_shiire            --������z_�d��
                 --2.���_�
                ,SUM( CASE WHEN UHG.column_no =  2 THEN UHG.trans_qty                     END ) trans_qty_uke_housou        --�������_�
                ,SUM( CASE WHEN UHG.column_no =  2 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_housou_cs     --�������_��P�[�X��
                ,SUM( CASE WHEN UHG.column_no =  2 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_housou            --������z_�
                 --3.���_�Z�b�g
                ,SUM( CASE WHEN UHG.column_no =  3 THEN UHG.trans_qty                     END ) trans_qty_uke_set           --�������_�Z�b�g
                ,SUM( CASE WHEN UHG.column_no =  3 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_set_cs        --�������_�Z�b�g�P�[�X��
                ,SUM( CASE WHEN UHG.column_no =  3 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_set               --������z_�Z�b�g
                 --4.���_����
                ,SUM( CASE WHEN UHG.column_no =  4 THEN UHG.trans_qty                     END ) trans_qty_uke_okinawa       --�������_����
                ,SUM( CASE WHEN UHG.column_no =  4 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_okinawa_cs    --�������_����P�[�X��
                ,SUM( CASE WHEN UHG.column_no =  4 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_okinawa           --������z_����
                 --5.���_�U�֓���
                ,SUM( CASE WHEN UHG.column_no =  5 THEN UHG.trans_qty                     END ) trans_qty_uke_furikaein     --�������_�U�֓���
                ,SUM( CASE WHEN UHG.column_no =  5 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_furikaein_cs  --�������_�U�֓��ɃP�[�X��
                ,SUM( CASE WHEN UHG.column_no =  5 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_furikaein         --������z_�U�֓���
                 --6.���_�Ήc�P
                ,SUM( CASE WHEN UHG.column_no =  6 THEN UHG.trans_qty                     END ) trans_qty_uke_ryokuei1      --�������_�Ήc�P
                ,SUM( CASE WHEN UHG.column_no =  6 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_ryokuei1_cs   --�������_�Ήc�P�P�[�X��
                ,SUM( CASE WHEN UHG.column_no =  6 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_ryokuei1          --������z_�Ήc�P
                 --7.���_�Ήc�Q
                ,SUM( CASE WHEN UHG.column_no =  7 THEN UHG.trans_qty                     END ) trans_qty_uke_ryokuei2      --�������_�Ήc�Q
                ,SUM( CASE WHEN UHG.column_no =  7 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_ryokuei2_cs   --�������_�Ήc�Q�P�[�X��
                ,SUM( CASE WHEN UHG.column_no =  7 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_ryokuei2          --������z_�Ήc�Q
                 --8.���_�h�����N�M�t�g
                ,SUM( CASE WHEN UHG.column_no =  8 THEN UHG.trans_qty                     END ) trans_qty_uke_drinkgift     --�������_�h�����N�M�t�g
                ,SUM( CASE WHEN UHG.column_no =  8 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_drinkgift_cs  --�������_�h�����N�M�t�g�P�[�X��
                ,SUM( CASE WHEN UHG.column_no =  8 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_drinkgift         --������z_�h�����N�M�t�g
                 --9.���_�q��
                ,SUM( CASE WHEN UHG.column_no =  9 THEN UHG.trans_qty                     END ) trans_qty_uke_kuragae       --�������_�q��
                ,SUM( CASE WHEN UHG.column_no =  9 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_kuragae_cs    --�������_�q�փP�[�X��
                ,SUM( CASE WHEN UHG.column_no =  9 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_kuragae           --������z_�q��
                 --10.���_�ԕi
                ,SUM( CASE WHEN UHG.column_no = 10 THEN UHG.trans_qty                     END ) trans_qty_uke_henpin        --�������_�ԕi
                ,SUM( CASE WHEN UHG.column_no = 10 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_henpin_cs     --�������_�ԕi�P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 10 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_henpin            --������z_�ԕi
                 --20.���_�l��
                ,SUM( CASE WHEN UHG.column_no = 20 THEN UHG.trans_qty                     END ) trans_qty_uke_hamaoka       --�������_�l��
                ,SUM( CASE WHEN UHG.column_no = 20 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_hamaoka_cs    --�������_�l���P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 20 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_hamaoka           --������z_�l��
                 --21.���_�i��ړ�
                ,SUM( CASE WHEN UHG.column_no = 21 THEN UHG.trans_qty                     END ) trans_qty_uke_hinsyuido     --�������_�i��ړ�
                ,SUM( CASE WHEN UHG.column_no = 21 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_hinsyuido_cs  --�������_�i��ړ��P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 21 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_hinsyuido         --������z_�i��ړ�
                 --22.���_�q�Ɉړ�
                ,SUM( CASE WHEN UHG.column_no = 22 THEN UHG.trans_qty                     END ) trans_qty_uke_soukoido      --�������_�q�Ɉړ�
                ,SUM( CASE WHEN UHG.column_no = 22 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_soukoido_cs   --�������_�q�Ɉړ��P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 22 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_soukoido          --������z_�q�Ɉړ�
                 --23.���_���̑�
                ,SUM( CASE WHEN UHG.column_no = 23 THEN UHG.trans_qty                     END ) trans_qty_uke_sonota        --�������_���̑�
                ,SUM( CASE WHEN UHG.column_no = 23 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_sonota_cs     --�������_���̑��P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 23 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_sonota            --������z_���̑�
                 --12.���o_�Z�b�g
                ,SUM( CASE WHEN UHG.column_no = 12 THEN UHG.trans_qty                     END ) trans_qty_hara_set          --���o����_�Z�b�g
                ,SUM( CASE WHEN UHG.column_no = 12 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_set_cs       --���o����_�Z�b�g�P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 12 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_set              --���o���z_�Z�b�g
                 --13.���o_�ԕi������
                ,SUM( CASE WHEN UHG.column_no = 13 THEN UHG.trans_qty                     END ) trans_qty_hara_hengen       --���o����_�ԕi������
                ,SUM( CASE WHEN UHG.column_no = 13 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_hengen_cs    --���o����_�ԕi�����փP�[�X��
                ,SUM( CASE WHEN UHG.column_no = 13 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_hengen           --���o���z_�ԕi������
                 --14.���o_��̔����i��
                ,SUM( CASE WHEN UHG.column_no = 14 THEN UHG.trans_qty                     END ) trans_qty_hara_kaihan       --���o����_��̔����i��
                ,SUM( CASE WHEN UHG.column_no = 14 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_kaihan_cs    --���o����_��̔����i�փP�[�X��
                ,SUM( CASE WHEN UHG.column_no = 14 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_kaihan           --���o���z_��̔����i��
                 --15.���o_�L��
                ,SUM( CASE WHEN UHG.column_no = 15 THEN UHG.trans_qty                     END ) trans_qty_hara_yusyou       --���o����_�L��
                ,SUM( CASE WHEN UHG.column_no = 15 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_yusyou_cs    --���o����_�L���P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 15 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_yusyou           --���o���z_�L��
                 --16.���o_�U�֗L��
                ,SUM( CASE WHEN UHG.column_no = 16 THEN UHG.trans_qty                     END ) trans_qty_hara_furikae      --���o����_�U�֗L��
                ,SUM( CASE WHEN UHG.column_no = 16 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_furikae_cs   --���o����_�U�֗L���P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 16 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_furikae          --���o���z_�U�֗L��
                 --17.���o_���_
                ,SUM( CASE WHEN UHG.column_no = 17 THEN UHG.trans_qty                     END ) trans_qty_hara_kyoten       --���o����_���_
                ,SUM( CASE WHEN UHG.column_no = 17 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_kyoten_cs    --���o����_���_�P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 17 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_kyoten           --���o���z_���_
                 --18.���o_�h�����N�M�t�g
                ,SUM( CASE WHEN UHG.column_no = 18 THEN UHG.trans_qty                     END ) trans_qty_hara_drinkgift    --���o����_�h�����N�M�t�g
                ,SUM( CASE WHEN UHG.column_no = 18 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_drinkgift_cs --���o����_�h�����N�M�t�g�P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 18 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_drinkgift        --���o���z_�h�����N�M�t�g
                 --24.���o_�]��
                ,SUM( CASE WHEN UHG.column_no = 24 THEN UHG.trans_qty                     END ) trans_qty_hara_tenbai       --���o����_�]��
                ,SUM( CASE WHEN UHG.column_no = 24 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_tenbai_cs    --���o����_�]���P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 24 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_tenbai           --���o���z_�]��
                 --25.���o_�p�p
                ,SUM( CASE WHEN UHG.column_no = 25 THEN UHG.trans_qty                     END ) trans_qty_hara_haikyaku     --���o����_�p�p
                ,SUM( CASE WHEN UHG.column_no = 25 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_haikyaku_cs  --���o����_�p�p�P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 25 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_haikyaku         --���o���z_�p�p
                 --26.���o_���{
                ,SUM( CASE WHEN UHG.column_no = 26 THEN UHG.trans_qty                     END ) trans_qty_hara_mihon        --���o����_���{
                ,SUM( CASE WHEN UHG.column_no = 26 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_mihon_cs     --���o����_���{�P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 26 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_mihon            --���o���z_���{
                 --27.���o_�������o
                ,SUM( CASE WHEN UHG.column_no = 27 THEN UHG.trans_qty                     END ) trans_qty_hara_soumu        --���o����_�������o
                ,SUM( CASE WHEN UHG.column_no = 27 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_soumu_cs     --���o����_�������o�P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 27 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_soumu            --���o���z_�������o
                 --28.���o_�o�����o
                ,SUM( CASE WHEN UHG.column_no = 28 THEN UHG.trans_qty                     END ) trans_qty_hara_keiri        --���o����_�o�����o
                ,SUM( CASE WHEN UHG.column_no = 28 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_keiri_cs     --���o����_�o�����o�P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 28 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_keiri            --���o���z_�o�����o
                 --29.���o_�i��ړ�
                ,SUM( CASE WHEN UHG.column_no = 29 THEN UHG.trans_qty                     END ) trans_qty_hara_hinsyuido    --���o����_�i��ړ�
                ,SUM( CASE WHEN UHG.column_no = 29 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_hinsyuido_cs --���o����_�i��ړ��P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 29 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_hinsyuido        --���o���z_�i��ړ�
                 --30.���o_�q�Ɉړ�
                ,SUM( CASE WHEN UHG.column_no = 30 THEN UHG.trans_qty                     END ) trans_qty_hara_soukoido     --���o����_�q�Ɉړ�
                ,SUM( CASE WHEN UHG.column_no = 30 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_soukoido_cs  --���o����_�q�Ɉړ��P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 30 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_soukoido         --���o���z_�q�Ɉړ�
                 --31.���o_���̑�
                ,SUM( CASE WHEN UHG.column_no = 31 THEN UHG.trans_qty                     END ) trans_qty_hara_sonota       --���o����_���̑�
                ,SUM( CASE WHEN UHG.column_no = 31 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_sonota_cs    --���o����_���̑��P�[�X��
                ,SUM( CASE WHEN UHG.column_no = 31 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_sonota           --���o���z_���̑�
                 --32.���o_�I������
                ,SUM( CASE WHEN UHG.column_no = 32 THEN UHG.trans_qty                     END ) trans_qty_hara_genmou       --���o����_�I������
                ,SUM( CASE WHEN UHG.column_no = 32 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_genmou_cs    --���o����_�I�����ՃP�[�X
                ,SUM( CASE WHEN UHG.column_no = 32 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHG.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHG.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_genmou           --���o���z_�I������
           FROM
                 xxsky_uh_goods2_v                     UHG                 --SKYLINK�p����VIEW �󕥏��_���iVIEW2
                ,xxsky_item_mst2_v                     ITEM                --SKYLINK�p����VIEW OPM�i�ڏ��VIEW
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
-- 2009/11/12 Add Start
                           -- �i�ڋ敪
                          ,gmi_item_categories    gic_h
                          ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
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
-- 2009/11/12 Add Start
                      AND  mcb_h.segment1 = '5'
                      AND  gic_h.category_id           = mcb_h.category_id
                      AND  gic_h.category_set_id       = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
                      AND  CMPD.item_id                = gic_h.item_id
-- 2009/11/12 Add End
                    GROUP BY
                           CMPD.item_id
                          ,CLDD.start_date
                          ,CLDD.end_date
                )                                      GPRC                --�i�ڕʕW���������
          WHERE
            --�i�ڏ��擾
-- 2009/11/12 Mod Start
            --     UHG.item_id                  = ITEM.item_id(+)
            --AND  TRUNC( UHG.trans_date )     >= ITEM.start_date_active(+)
            --AND  TRUNC( UHG.trans_date )     <= ITEM.end_date_active(+)
                 UHG.item_id                  = ITEM.item_id
            AND  TRUNC( UHG.trans_date )     >= ITEM.start_date_active
            AND  TRUNC( UHG.trans_date )     <= ITEM.end_date_active
-- 2009/11/12 Mod End
            --��������b�g�Ǘ��敪�擾
-- 2009/11/12 Mod Start
            --AND  UHG.item_id                  = ITMB.item_id(+)
            AND  UHG.item_id                  = ITMB.item_id
-- 2009/11/12 Mod Start
            --���b�g�������擾
            AND  UHG.item_id                  = LCST.item_id(+)
            AND  UHG.lot_id                   = LCST.lot_id(+)
            --�W���P�����擾
            AND  UHG.item_id                  = GPRC.item_id(+)
            AND  TRUNC( UHG.trans_date )     >= TRUNC( GPRC.start_date_active(+) )  --EBS�W���e�[�u���Ȃ̂Ŏ����b�����݂���
            AND  TRUNC( UHG.trans_date )     <= TRUNC( GPRC.end_date_active(+)   )  --EBS�W���e�[�u���Ȃ̂Ŏ����b�����݂���
         GROUP BY
                 TO_CHAR( UHG.trans_date, 'YYYYMM' )
                ,UHG.whse_code
                ,UHG.item_id
                ,ITEM.item_no
                ,ITEM.item_name
                ,ITEM.item_short_name
         --**********************************************************************************************
         -- �y�N���z�y�q�Ɂz�y�i�ځz�P�ʂɏW�v������������擾  END
         --**********************************************************************************************
       )                                SUHG           --�W�v��_���i���
       ,ic_whse_mst                     IWM            --�q�Ƀ}�X�^
       ,xxsky_prod_class_v              PRODC          --SKYLINK�p ���i�敪�擾VIEW
       ,xxsky_item_class_v              ITEMC          --SKYLINK�p �i�ڋ敪�擾VIEW
       ,xxsky_crowd_code_v              CROWD          --SKYLINK�p �Q�R�[�h�擾VIEW
 WHERE
   --�S���ڂ̐��ʂ��[���̏ꍇ�͏o�͂��Ȃ�
       (    SUHG.trans_qty_gessyuzaiko      <> 0       --0.����݌�
         OR SUHG.trans_qty_uke_shiire       <> 0       --1.���_�d��
         OR SUHG.trans_qty_uke_housou       <> 0       --2.���_�
         OR SUHG.trans_qty_uke_set          <> 0       --3.���_�Z�b�g
         OR SUHG.trans_qty_uke_okinawa      <> 0       --4.���_����
         OR SUHG.trans_qty_uke_furikaein    <> 0       --5.���_�U�֓���
         OR SUHG.trans_qty_uke_ryokuei1     <> 0       --6.���_�Ήc�P
         OR SUHG.trans_qty_uke_ryokuei2     <> 0       --7.���_�Ήc�Q
         OR SUHG.trans_qty_uke_drinkgift    <> 0       --8.���_�h�����N�M�t�g
         OR SUHG.trans_qty_uke_kuragae      <> 0       --9.���_�q��
         OR SUHG.trans_qty_uke_henpin       <> 0       --10.���_�ԕi
         OR SUHG.trans_qty_uke_hamaoka      <> 0       --20.���_�l��
         OR SUHG.trans_qty_uke_hinsyuido    <> 0       --21.���_�i��ړ�
         OR SUHG.trans_qty_uke_soukoido     <> 0       --22.���_�q�Ɉړ�
         OR SUHG.trans_qty_uke_sonota       <> 0       --23.���_���̑�
         OR SUHG.trans_qty_hara_set         <> 0       --12.���o_�Z�b�g
         OR SUHG.trans_qty_hara_hengen      <> 0       --13.���o_�ԕi������
         OR SUHG.trans_qty_hara_kaihan      <> 0       --14.���o_��̔����i��
         OR SUHG.trans_qty_hara_yusyou      <> 0       --15.���o_�L��
         OR SUHG.trans_qty_hara_furikae     <> 0       --16.���o_�U�֗L��
         OR SUHG.trans_qty_hara_kyoten      <> 0       --17.���o_���_
         OR SUHG.trans_qty_hara_drinkgift   <> 0       --18.���o_�h�����N�M�t�g
         OR SUHG.trans_qty_hara_tenbai      <> 0       --24.���o_�]��
         OR SUHG.trans_qty_hara_haikyaku    <> 0       --25.���o_�p�p
         OR SUHG.trans_qty_hara_mihon       <> 0       --26.���o_���{
         OR SUHG.trans_qty_hara_soumu       <> 0       --27.���o_�������o
         OR SUHG.trans_qty_hara_keiri       <> 0       --28.���o_�o�����o
         OR SUHG.trans_qty_hara_hinsyuido   <> 0       --29.���o_�i��ړ�
         OR SUHG.trans_qty_hara_soukoido    <> 0       --30.���o_�q�Ɉړ�
         OR SUHG.trans_qty_hara_sonota      <> 0       --31.���o_���̑�
         OR SUHG.trans_qty_hara_genmou      <> 0       --32.���o_�I������
       )
   --�q�ɖ��擾
-- 2009/11/12 Mod Start
   --AND  SUHG.whse_code   = IWM.whse_code(+)
   AND  SUHG.whse_code   = IWM.whse_code
-- 2009/11/12 Mod End
   --�i�ڃJ�e�S�����擾
-- 2009/11/12 Mod Start
   --AND  SUHG.item_id     = PRODC.item_id(+)  --���i�敪
   --AND  SUHG.item_id     = ITEMC.item_id(+)  --�i�ڋ敪
   --AND  SUHG.item_id     = CROWD.item_id(+)  --�Q�R�[�h
   AND  SUHG.item_id     = PRODC.item_id  --���i�敪
   AND  PRODC.item_id     = ITEMC.item_id  --�i�ڋ敪
   AND  PRODC.item_id     = CROWD.item_id  --�Q�R�[�h
   AND  ITEMC.item_id     = CROWD.item_id
-- 2009/11/12 Mod End
/
COMMENT ON TABLE APPS.XXSKY_��_���i_��{2_V IS 'SKYLINK�p�󕥏�񐻕i�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�N��                          IS '�N��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���i�敪                      IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���i�敪��                    IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�q�ɃR�[�h                    IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�q�ɖ�                        IS '�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�i�ڋ敪                      IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�i�ڋ敪��                    IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�Q�R�[�h                      IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�i�ڃR�[�h                    IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�i�ږ���                      IS '�i�ږ���'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�i�ڗ���                      IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.����݌�                      IS '����݌�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.����݌ɃP�[�X                IS '����݌ɃP�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.����݌ɋ��z                  IS '����݌ɋ��z'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�d��                 IS '�������_�d��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�d���P�[�X           IS '�������_�d���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�d��                 IS '������z_�d��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�                 IS '�������_�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_��P�[�X           IS '�������_��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�                 IS '������z_�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�Z�b�g               IS '�������_�Z�b�g'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�Z�b�g�P�[�X         IS '�������_�Z�b�g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�Z�b�g               IS '������z_�Z�b�g'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_����                 IS '�������_����'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_����P�[�X           IS '�������_����P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_����                 IS '������z_����'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�U�֓���             IS '�������_�U�֓���'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�U�֓��ɃP�[�X       IS '�������_�U�֓��ɃP�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�U�֓���             IS '������z_�U�֓���'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�Ήc�P               IS '�������_�Ήc�P'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�Ήc�P�P�[�X         IS '�������_�Ήc�P�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�Ήc�P               IS '������z_�Ήc�P'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�Ήc�Q               IS '�������_�Ήc�Q'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�Ήc�Q�P�[�X         IS '�������_�Ήc�Q�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�Ήc�Q               IS '������z_�Ήc�Q'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�h�����N�M�t�g       IS '�������_�h�����N�M�t�g'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�h�����N�M�t�g�P�[�X IS '�������_�h�����N�M�t�g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�h�����N�M�t�g       IS '������z_�h�����N�M�t�g'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�q��                 IS '�������_�q��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�q�փP�[�X           IS '�������_�q�փP�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�q��                 IS '������z_�q��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�ԕi                 IS '�������_�ԕi'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�ԕi�P�[�X           IS '�������_�ԕi�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�ԕi                 IS '������z_�ԕi'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�l��                 IS '�������_�l��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�l���P�[�X           IS '�������_�l���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�l��                 IS '������z_�l��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�i��ړ�             IS '�������_�i��ړ�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�i��ړ��P�[�X       IS '�������_�i��ړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�i��ړ�             IS '������z_�i��ړ�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�q�Ɉړ�             IS '�������_�q�Ɉړ�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_�q�Ɉړ��P�[�X       IS '�������_�q�Ɉړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_�q�Ɉړ�             IS '������z_�q�Ɉړ�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_���̑�               IS '�������_���̑�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.�������_���̑��P�[�X         IS '�������_���̑��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.������z_���̑�               IS '������z_���̑�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�Z�b�g               IS '���o����_�Z�b�g'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�Z�b�g�P�[�X         IS '���o����_�Z�b�g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�Z�b�g               IS '���o���z_�Z�b�g'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�ԕi������           IS '���o����_�ԕi������'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�ԕi�����փP�[�X     IS '���o����_�ԕi�����փP�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�ԕi������           IS '���o���z_�ԕi������'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_��̔����i��         IS '���o����_��̔����i��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_��̔����i�փP�[�X   IS '���o����_��̔����i�փP�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_��̔����i��         IS '���o���z_��̔����i��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�L��                 IS '���o����_�L��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�L���P�[�X           IS '���o����_�L���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�L��                 IS '���o���z_�L��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�U�֗L��             IS '���o����_�U�֗L��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�U�֗L���P�[�X       IS '���o����_�U�֗L���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�U�֗L��             IS '���o���z_�U�֗L��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_���_                 IS '���o����_���_'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_���_�P�[�X           IS '���o����_���_�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_���_                 IS '���o���z_���_'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�h�����N�M�t�g       IS '���o����_�h�����N�M�t�g'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�h�����N�M�t�g�P�[�X IS '���o����_�h�����N�M�t�g�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�h�����N�M�t�g       IS '���o���z_�h�����N�M�t�g'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�]��                 IS '���o����_�]��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�]���P�[�X           IS '���o����_�]���P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�]��                 IS '���o���z_�]��'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�p�p                 IS '���o����_�p�p'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�p�p�P�[�X           IS '���o����_�p�p�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�p�p                 IS '���o���z_�p�p'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_���{                 IS '���o����_���{'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_���{�P�[�X           IS '���o����_���{�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_���{                 IS '���o���z_���{'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�������o             IS '���o����_�������o'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�������o�P�[�X       IS '���o����_�������o�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�������o             IS '���o���z_�������o'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�o�����o             IS '���o����_�o�����o'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�o�����o�P�[�X       IS '���o����_�o�����o�P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�o�����o             IS '���o���z_�o�����o'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�i��ړ�             IS '���o����_�i��ړ�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�i��ړ��P�[�X       IS '���o����_�i��ړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�i��ړ�             IS '���o���z_�i��ړ�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�q�Ɉړ�             IS '���o����_�q�Ɉړ�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�q�Ɉړ��P�[�X       IS '���o����_�q�Ɉړ��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�q�Ɉړ�             IS '���o���z_�q�Ɉړ�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_���̑�               IS '���o����_���̑�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_���̑��P�[�X         IS '���o����_���̑��P�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_���̑�               IS '���o���z_���̑�'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�I������             IS '���o����_�I������'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o����_�I�����ՃP�[�X       IS '���o����_�I�����ՃP�[�X'
/
COMMENT ON COLUMN APPS.XXSKY_��_���i_��{2_V.���o���z_�I������             IS '���o���z_�I������'
/
