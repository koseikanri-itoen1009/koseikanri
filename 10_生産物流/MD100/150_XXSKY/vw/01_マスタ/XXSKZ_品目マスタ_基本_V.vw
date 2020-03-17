/*************************************************************************
 * 
 * View  Name      : XXSKZ_�i�ڃ}�X�^_��{_V
 * Description     : XXSKZ_�i�ڃ}�X�^_��{_V
 * MD.070          : 
 * Version         : 1.5
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai ����쐬
 *  2017/06/07    1.2   SCSK K.Kiiru E_�{�ғ�_14244
 *  2018/10/29    1.3   SCSK N.Koyama E_�{�ғ�_15277
 *  2019/07/02    1.4   SCSK N.Abe   E_�{�ғ�_15625
 *  2020/02/27    1.5   SCSK Y.Sasaki E_�{�ғ�_16213
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�i�ڃ}�X�^_��{_V
(
 �i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�i�ڃJ�i��
,�K�p�J�n��
,�K�p�I����
,�K�p�σt���O
,�����t���O
,�����t���O��
,�P��
,���b�g�Ǘ��敪
,���b�g�Ǘ��敪��
,�q�ɕi�ڃR�[�h
,�q�ɕi�ږ�
,�q�ɕi�ڗ���
,��_�Q�R�[�h
,�V_�Q�R�[�h
,�Q�R�[�h�K�p�J�n��
,��_�艿
,�V_�艿
,�艿�K�p�J�n��
,��_�c�ƌ���
,�V_�c�ƌ���
,�c�ƌ����K�p�J�n��
,����Ώۋ敪
,����Ώۋ敪��
,���������J�n��
,JAN����
,ITF�R�[�h
,�P�[�X����
,NET
,�d�ʗe�ϋ敪
,�d�ʗe�ϋ敪��
,�d��
,�e��
,�d���敪
,�d���敪��
,�o�׋敪
,�o�׋敪��
,�����Ǘ��敪
,�����Ǘ��敪��
,�d���P�����o���^�C�v
,�d���P�����o���^�C�v��
,��\����
,���o�Ɋ��Z�P��
,�����L���敪
,�����L���敪��
,����LT
,�����
,�����\�����
,�}�X�^��M����
,�������b�g�̔ԗL��
,�e�i�ڃR�[�h
,�e�i�ږ�
,�e�i�ڗ���
,�p�~�敪
,�p�~�敪��
,�p�~_�������~��
,�^���
,�^��ʖ�
,���i����
,���i���ޖ�
,���i���
,���i��ʖ�
,�ܖ�����
-- 2017/06/07 K.Kiriu Add Start E_�{�ғ�_14244
,�ܖ�����_��
,�\���敪
,�\���敪��
-- 2017/06/07 K.Kiriu Add End   E_�{�ғ�_14244
,�[������
,�H��Q�R�[�h
,�W������
,�o�ג�~��
,���敪
,���敪��
,�������
,�ܖ����ԋ敪
,�ܖ����ԋ敪��
,�e��敪
,�e��敪��
,�P�ʋ敪
,�P�ʋ敪��
,�I���敪
,�I���敪��
,�g���[�X�敪
,�g���[�X�敪��
,�o�ד���
,�z��
,�p���b�g����ő�i��
,�p���b�g�i
,�P�[�X�d�ʗe��
,�����g�p��
-- 2012/08/29 T.Makuta Add Start E_�{�ғ�_09591
,�N�x����
,�N�x��������
-- 2012/08/29 T.Makuta Add End   E_�{�ғ�_09591
-- 2018/10/29 N.Koyama Add Start E_�{�ғ�_15277
,���b�g�t�]�敪
,���b�g�t�]�敪����
-- 2018/10/29 N.Koyama Add End   E_�{�ғ�_15277
-- 2020/02/27 Y.Sasaki Add Start E_�{�ғ�_16213
,�Y�n����
,�Y�n��������
,��������
,������������
,�N�x
,�L�@
-- 2020/02/27 Y.Sasaki Add End E_�{�ғ�_16213
-- 2019/07/02 N.Abe Add Start E_�{�ғ�_15625
,�i�ڃX�e�[�^�X
,�i�ڃX�e�[�^�X����
,�i�ڏڍ׃X�e�[�^�X
,�i�ڏڍ׃X�e�[�^�X����
,���l
-- 2019/07/02 N.Abe Add End   E_�{�ғ�_15625
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  IIMB.item_no                  item_no                     --�i�ڃR�[�h
       ,XIMB.item_name                item_name                   --�i�ږ�
       ,XIMB.item_short_name          item_short_name             --�i�ڗ���
       ,XIMB.item_name_alt            item_name_alt               --�i�ڃJ�i��
       ,XIMB.start_date_active        start_date_active           --�K�p�J�n��
       ,XIMB.end_date_active          end_date_active             --�K�p�I����
       ,XIMB.active_flag              active_flag                 --�K�p�σt���O
       ,IIMB.inactive_ind             inactive_ind                --�����t���O
       ,CASE WHEN NVL( IIMB.inactive_ind, '0' ) = '0' THEN '�L��' ELSE '����'
        END                           inactive_ind_name           --�����t���O��
       ,IIMB.item_um                  item_um                     --�P��
       ,IIMB.lot_ctl                  lot_ctl                     --���b�g�Ǘ��敪
       ,DECODE(IIMB.lot_ctl, 1, '�L��', '����')
                                      lot_ctl_name                --���b�g�Ǘ��敪��
       ,IIMB2.item_no                 whse_item_no                --�q�ɕi�ڃR�[�h
       ,XIMB2.item_name               whse_item_name              --�q�ɕi�ږ�
       ,XIMB2.item_short_name         whse_item_short_name        --�q�ɕi�ڗ���
       ,IIMB.attribute1               old_crowd_code              --���E�Q�R�[�h
       ,IIMB.attribute2               new_crowd_code              --�V�E�Q�R�[�h
       ,IIMB.attribute3               crowd_code_s_date           --�Q�R�[�h�K�p�J�n��
       ,NVL( TO_NUMBER( IIMB.attribute4 ), 0 )
                                      old_fixed_price             --���E�艿
       ,NVL( TO_NUMBER( IIMB.attribute5 ), 0 )
                                      new_fixed_price             --�V�E�艿
       ,IIMB.attribute6               fixed_price_s_date          --�艿�K�p�J�n��
       ,NVL( TO_NUMBER( IIMB.attribute7 ), 0 )
                                      old_buss_cost               --���E�c�ƌ���
       ,NVL( TO_NUMBER( IIMB.attribute8 ), 0 )
                                      new_buss_cost               --�V�E�c�ƌ���
       ,IIMB.attribute9               buss_cost_s_date            --�c�ƌ����K�p�J�n��
       ,IIMB.attribute26              sales_target_class          --����Ώۋ敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV01.meaning                 sales_target_class_name     --����Ώۋ敪��
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01                               --�N�C�b�N�R�[�h(����Ώۋ敪��)
         WHERE FLV01.language    = 'JA'                               --����
           AND FLV01.lookup_type = 'XXCMN_SALES_TARGET_CLASS'         --�N�C�b�N�R�[�h�^�C�v
           AND FLV01.lookup_code = IIMB.attribute26                   --�N�C�b�N�R�[�h
        ) sales_target_class_name
       ,IIMB.attribute13              sale_s_date                 --�����i�����j�J�n��
       ,IIMB.attribute21              jan_code                    --JAN�R�[�h
       ,IIMB.attribute22              itf_code                    --ITF�R�[�h
       ,NVL( TO_NUMBER( IIMB.attribute11 ), 0 )
                                      in_case_amount              --�P�[�X����
       ,NVL( TO_NUMBER( IIMB.attribute12 ), 0 )
                                      net                         --NET
       ,IIMB.attribute10              weight_capacity_class       --�d�ʗe�ϋ敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV02.meaning                 weight_capacity_class_name  --�d�ʗe�ϋ敪��
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02                               --�N�C�b�N�R�[�h(�d�ʗe�ϋ敪��)
         WHERE FLV02.language    = 'JA'                               --����
           AND FLV02.lookup_type = 'XXCMN_WEIGHT_CAPACITY_CLASS'      --�N�C�b�N�R�[�h�^�C�v
           AND FLV02.lookup_code = IIMB.attribute10                   --�N�C�b�N�R�[�h
        ) weight_capacity_class_name
       ,NVL( TO_NUMBER( IIMB.attribute25 ), 0 )
                                      weight                      --�d��
       ,NVL( TO_NUMBER( IIMB.attribute16 ), 0 )
                                      capacity                    --�e��
       ,IIMB.attribute28              destination_div             --�d���敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV03.meaning                 destination_div_name        --�d���敪��
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03                               --�N�C�b�N�R�[�h(�d���敪��)
         WHERE FLV03.language    = 'JA'                                  --����
           AND FLV03.lookup_type = 'XXCMN_DESTINATION_DIV'            --�N�C�b�N�R�[�h�^�C�v
           AND FLV03.lookup_code = IIMB.attribute28                   --�N�C�b�N�R�[�h
        ) destination_div_name
       ,IIMB.attribute18              shipping_class              --�o�׋敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV04.meaning                 shipping_class_name         --�o�׋敪��
       ,(SELECT FLV04.meaning
         FROM fnd_lookup_values FLV04                               --�N�C�b�N�R�[�h(�o�׋敪��)
         WHERE FLV04.language    = 'JA'                                  --����
           AND FLV04.lookup_type = 'XXCMN_SHIPPING_CLASS'             --�N�C�b�N�R�[�h�^�C�v
           AND FLV04.lookup_code = IIMB.attribute18                   --�N�C�b�N�R�[�h
        ) shipping_class_name
       ,IIMB.attribute15              cost_management             --�����Ǘ��敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV05.meaning                 cost_management_name        --�����Ǘ��敪��
       ,(SELECT FLV05.meaning
         FROM fnd_lookup_values FLV05                               --�N�C�b�N�R�[�h(�����Ǘ��敪��)
         WHERE FLV05.language    = 'JA'                                  --����
           AND FLV05.lookup_type ='XXCMN_COST_MANAGEMENT'             --�N�C�b�N�R�[�h�^�C�v
           AND FLV05.lookup_code = IIMB.attribute15                   --�N�C�b�N�R�[�h
        ) cost_management_name
       ,IIMB.attribute20              vendor_price_deri_day       --�d���P�����o���^�C�v
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV06.meaning                 vendor_price_deri_day_name  --�d���P�����o���^�C�v��
       ,(SELECT FLV06.meaning
         FROM fnd_lookup_values FLV06                               --�N�C�b�N�R�[�h(�d���P�����o���^�C�v��)
         WHERE FLV06.language    = 'JA'                                  --����
           AND FLV06.lookup_type = 'XXCMN_VENDOR_PRICE_DERI_DAY_TY'   --�N�C�b�N�R�[�h�^�C�v
           AND FLV06.lookup_code = IIMB.attribute20                   --�N�C�b�N�R�[�h
        ) vendor_price_deri_day_name
       ,NVL( TO_NUMBER( IIMB.attribute17 ), 0 )
                                      representative_amount       --��\����
       ,IIMB.attribute24              inout_conversion_uom        --���o�Ɋ��Z�P��
       ,IIMB.attribute23              need_test                   --�����L���敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV07.meaning                 need_test_name              --�����L���敪��
       ,(SELECT FLV07.meaning
         FROM fnd_lookup_values FLV07                               --�N�C�b�N�R�[�h(�����L���敪��)
         WHERE FLV07.language    = 'JA'                                  --����
           AND FLV07.lookup_type = 'XXCMN_NEED_TEST'                  --�N�C�b�N�R�[�h�^�C�v
           AND FLV07.lookup_code = IIMB.attribute23                   --�N�C�b�N�R�[�h
        ) need_test_name
       ,NVL( TO_NUMBER( IIMB.attribute14 ), 0 )
                                      inspection_lt               --����L/T
       ,NVL( TO_NUMBER( IIMB.attribute27 ), 0 )
                                      judge_Times                 --�����
       ,NVL( TO_NUMBER( IIMB.attribute29 ), 0 )
                                      order_possible_times        --�����\�����
       ,IIMB.attribute30              reception_date              --�}�X�^��M����
       ,DECODE(IIMB.autolot_active_indicator, 1, '����', '�L��')
                                      autolot_active_indicator    --�������b�g�̔ԗL��
       ,IIMB3.item_no                 parent_item_no              --�e�i�ڃR�[�h
       ,XIMB3.item_name               parent_item_name            --�e�i�ږ�
       ,XIMB3.item_short_name         parent_item_short_name      --�e�i�ڗ���
       ,XIMB.obsolete_class           obsolete_class              --�p�~�敪
       ,DECODE(XIMB.obsolete_class, 1, '�p�~', '�戵��')
                                      obsolete_class_name         --�p�~�敪��
       ,XIMB.obsolete_date            obsolete_date               --�p�~���i�������~���j
       ,XIMB.model_type               model_type                  --�^���
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV08.meaning                 model_type_name             --�^��ʖ�
       ,(SELECT FLV08.meaning
         FROM fnd_lookup_values FLV08                               --�N�C�b�N�R�[�h(�^��ʖ�)
         WHERE FLV08.language    = 'JA'                                  --����
           AND FLV08.lookup_type = 'XXCMN_D01'                        --�N�C�b�N�R�[�h�^�C�v
           AND FLV08.lookup_code = XIMB.model_type                    --�N�C�b�N�R�[�h
        ) model_type_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XIMB.product_class            product_class               --���i����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV09.meaning                 product_class_name          --���i���ޖ�
       ,(SELECT FLV09.meaning
         FROM fnd_lookup_values FLV09                               --�N�C�b�N�R�[�h(���i���ޖ�)
         WHERE FLV09.language    = 'JA'                                  --����
           AND FLV09.lookup_type = 'XXCMN_D02'                        --�N�C�b�N�R�[�h�^�C�v
           AND FLV09.lookup_code = XIMB.product_class                 --�N�C�b�N�R�[�h
        ) product_class_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XIMB.product_type             product_type                --���i���
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV10.meaning                 product_type_name           --���i��ʖ�
       ,(SELECT FLV10.meaning
         FROM fnd_lookup_values FLV10                               --�N�C�b�N�R�[�h(���i��ʖ�)
         WHERE FLV10.language    = 'JA'                                  --����
           AND FLV10.lookup_type = 'XXCMN_D03'                        --�N�C�b�N�R�[�h�^�C�v
           AND FLV10.lookup_code = XIMB.product_type                  --�N�C�b�N�R�[�h
        ) product_type_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XIMB.expiration_day           expiration_day              --�ܖ�����
-- 2017/06/07 K.Kiriu Add Start E_�{�ғ�_14244
       ,XIMB.expiration_month         expiration_month            --�ܖ����ԁi���j
       ,XIMB.expiration_type          expiration_type             --�\���敪
       ,(SELECT FLV18.meaning meaning
         FROM fnd_lookup_values FLV18                             --�N�C�b�N�R�[�h(�\���敪��)
         WHERE FLV18.language    = 'JA'                           --����
           AND FLV18.lookup_type = 'XXCMN_EXPIRATION_TYPE'        --�N�C�b�N�R�[�h�^�C�v
           AND FLV18.lookup_code = XIMB.expiration_type           --�N�C�b�N�R�[�h
        ) expiration_type_name
-- 2017/06/07 K.Kiriu Add End   E_�{�ғ�_14244
       ,XIMB.delivery_lead_time       delivery_lead_time          --�[������
       ,XIMB.whse_county_code         whse_county_code            --�H��Q�R�[�h
       ,XIMB.standard_yield           standard_yield              --�W���ۗ�
       ,XIMB.shipping_end_date        shipping_end_date           --�o�ג�~��
       ,XIMB.rate_class               rate_class                  --���敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV11.meaning                 rate_class_name             --���敪��
       ,(SELECT FLV11.meaning
         FROM fnd_lookup_values FLV11                               --�N�C�b�N�R�[�h(���敪��)
         WHERE FLV11.language    = 'JA'                                  --����
           AND FLV11.lookup_type = 'XXCMN_RATE'                       --�N�C�b�N�R�[�h�^�C�v
           AND FLV11.lookup_code = XIMB.rate_class                    --�N�C�b�N�R�[�h
        ) rate_class_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XIMB.shelf_life               shelf_life                  --�������
       ,XIMB.shelf_life_class         shelf_life_class            --�ܖ����ԋ敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV12.meaning                 shelf_life_class_name       --�ܖ����ԋ敪��
       ,(SELECT FLV12.meaning
         FROM fnd_lookup_values FLV12                               --�N�C�b�N�R�[�h(�ܖ����ԋ敪��)
         WHERE FLV12.language    = 'JA'                                  --����
           AND FLV12.lookup_type = 'XXCMN_SHELF_LIFE_CLASS'           --�N�C�b�N�R�[�h�^�C�v
           AND FLV12.lookup_code = XIMB.shelf_life_class              --�N�C�b�N�R�[�h
        ) shelf_life_class_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XIMB.bottle_class             bottle_class                --�e��敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV13.meaning                 bottle_class_name           --�e��敪��
       ,(SELECT FLV13.meaning
         FROM fnd_lookup_values FLV13                               --�N�C�b�N�R�[�h(�e��敪��)
         WHERE FLV13.language    = 'JA'                                  --����
           AND FLV13.lookup_type = 'XXCMN_BOTTLE_CLASS'               --�N�C�b�N�R�[�h�^�C�v
           AND FLV13.lookup_code = XIMB.bottle_class                  --�N�C�b�N�R�[�h
        ) bottle_class_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XIMB.uom_class                uom_class                   --�P�ʋ敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV14.meaning                 uom_class_name              --�P�ʋ敪��
       ,(SELECT FLV14.meaning
         FROM fnd_lookup_values FLV14                               --�N�C�b�N�R�[�h(�P�ʋ敪��)
         WHERE FLV14.language    = 'JA'                                  --����
           AND FLV14.lookup_type = 'XXCMN_UOM_CLASS'                  --�N�C�b�N�R�[�h�^�C�v
           AND FLV14.lookup_code = XIMB.uom_class                     --�N�C�b�N�R�[�h
        ) uom_class_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XIMB.inventory_chk_class      inventory_chk_class         --�I���敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV15.meaning                 inventory_chk_class_name    --�I���敪��
       ,(SELECT FLV15.meaning
         FROM fnd_lookup_values FLV15                               --�N�C�b�N�R�[�h(�I���敪��)
         WHERE FLV15.language    = 'JA'                                  --����
           AND FLV15.lookup_type = 'XXCMN_INVENTORY_CHK_CLASS'        --�N�C�b�N�R�[�h�^�C�v
           AND FLV15.lookup_code = XIMB.inventory_chk_class           --�N�C�b�N�R�[�h
        ) inventory_chk_class_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XIMB.trace_class              trace_class                 --�g���[�X�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV16.meaning                 trace_class_name            --�g���[�X�敪��
       ,(SELECT FLV16.meaning
         FROM fnd_lookup_values FLV16                               --�N�C�b�N�R�[�h(�g���[�X�敪��)
         WHERE FLV16.language    = 'JA'                                  --����
           AND FLV16.lookup_type = 'XXCMN_TRACE_CLASS'                --�N�C�b�N�R�[�h�^�C�v
           AND FLV16.lookup_code = XIMB.trace_class                   --�N�C�b�N�R�[�h
        ) trace_class_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XIMB.shipping_cs_unit_qty     shipping_cs_unit_qty        --�o�ד���
       ,XIMB.palette_max_cs_qty       palette_max_cs_qty          --�z��
       ,XIMB.palette_max_step_qty     palette_max_step_qty        --�p���b�g����ő�i��
       ,XIMB.palette_step_qty         palette_step_qty            --�p���b�g�i
       ,XIMB.cs_weigth_or_capacity    cs_weigth_or_capacity       --�P�[�X�d�ʗe��
       ,XIMB.raw_material_consumption raw_material_consumption    --�����g�p��
-- 2012/08/29 T.Makuta Add Start E_�{�ғ�_09591
       ,IIMB.attribute19             freshness_condition          --�N�x����
       ,(SELECT FLV17.meaning
         FROM fnd_lookup_values FLV17                             --�N�C�b�N�R�[�h(�N�x��������)
         WHERE FLV17.language    = 'JA'                           --����
           AND FLV17.lookup_type = 'XXCMN_FRESHNESS_CONDITION'    --�N�C�b�N�R�[�h�^�C�v
           AND FLV17.lookup_code = IIMB.attribute19               --�N�C�b�N�R�[�h
       ) freshness_condition_name
-- 2012/08/29 T.Makuta Add End   E_�{�ғ�_09591
-- 2018/10/29 N.Koyama Add Start E_�{�ғ�_15277
       ,XIMB.lot_reversal_type              lot_reversal_type     --���b�g�t�]�敪
       ,(SELECT FLV19.meaning
         FROM fnd_lookup_values FLV19                             --�N�C�b�N�R�[�h(���b�g�t�]�敪����)
         WHERE FLV19.language    = 'JA'                           --����
           AND FLV19.lookup_type = 'XXCMN_LOT_REVERSAL_TYPE'      --�N�C�b�N�R�[�h�^�C�v
           AND FLV19.lookup_code = XIMB.lot_reversal_type         --�N�C�b�N�R�[�h
       ) lot_reversal_name
-- 2018/10/29 N.Koyama Add End  E_�{�ғ�_15277
-- 2020/02/27 Y.Sasaki Add Start E_�{�ғ�_16213
       ,XIMB.origin_restriction             origin_restriction    --�Y�n����
       ,(SELECT FLV22.meaning
         FROM fnd_lookup_values FLV22                             --�N�C�b�N�R�[�h(�Y�n)
         WHERE FLV22.language    = 'JA'                           --����
           AND FLV22.lookup_type = 'XXCMN_L07'                    --�N�C�b�N�R�[�h�^�C�v
           AND FLV22.lookup_code = XIMB.origin_restriction        --�N�C�b�N�R�[�h
       ) origin_restriction_name
       ,XIMB.tea_period_restriction         tea_period_restriction  --��������
       ,(SELECT FLV23.meaning
         FROM fnd_lookup_values FLV23                             --�N�C�b�N�R�[�h(�����敪)
         WHERE FLV23.language    = 'JA'                           --����
           AND FLV23.lookup_type = 'XXCMN_L06'                    --�N�C�b�N�R�[�h�^�C�v
           AND FLV23.lookup_code = XIMB.tea_period_restriction    --�N�C�b�N�R�[�h
       ) tea_period_restriction_name
       ,XIMB.product_year                                         --�N�x
       ,XIMB.organic                                              --�L�@
-- 2020/02/27 Y.Sasaki Add End E_�{�ғ�_16213
-- 2019/07/02 N.Abe Add Start E_�{�ғ�_15625
       ,XSIB.item_status         --�i�ڃX�e�[�^�X
       ,(SELECT FLV20.meaning
         FROM fnd_lookup_values FLV20                             --�N�C�b�N�R�[�h(�i�ڃX�e�[�^�X����)
         WHERE FLV20.language    = 'JA'                           --����
           AND FLV20.lookup_type = 'XXCMM_ITM_STATUS'             --�N�C�b�N�R�[�h�^�C�v
           AND FLV20.lookup_code = XSIB.item_status               --�N�C�b�N�R�[�h
       ) item_status_name
       ,XSIB.item_dtl_status  --�i�ڏڍ׃X�e�[�^�X
       ,(SELECT FLV21.meaning
         FROM fnd_lookup_values FLV21                             --�N�C�b�N�R�[�h(�i�ڏڍ׃X�e�[�^�X����)
         WHERE FLV21.language    = 'JA'                           --����
           AND FLV21.lookup_type = 'XXCMM_ITM_DTL_STATUS'         --�N�C�b�N�R�[�h�^�C�v
           AND FLV21.lookup_code = XSIB.item_dtl_status               --�N�C�b�N�R�[�h
       ) item_detail_status_name
       ,XSIB.remarks             --���l
-- 2019/07/02 N.Abe Add End   E_�{�ғ�_15625
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_CB.user_name               created_by_name             --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE XIMB.created_by = FU_CB.user_id
        ) created_by_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XIMB.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                      creation_date               --�쐬����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name               last_updated_by_name        --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE XIMB.last_updated_by = FU_LU.user_id
        ) last_updated_by_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XIMB.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                      last_update_date            --�X�V����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name               last_update_login_name      --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE XIMB.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) last_update_login_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  ic_item_mst_b         IIMB                                --OPM�i�ڃ}�X�^
       ,xxcmn_item_mst_b      XIMB                                --�i�ڃ}�X�^�A�h�I��
       ,ic_item_mst_b         IIMB2                               --OPM�i�ڃ}�X�^     (�q�ɕi�ڎ擾�p)
       ,xxcmn_item_mst_b      XIMB2                               --�i�ڃ}�X�^�A�h�I��(�q�ɕi�ڎ擾�p)
       ,ic_item_mst_b         IIMB3                               --OPM�i�ڃ}�X�^     (�e�i�ڎ擾�p)
       ,xxcmn_item_mst_b      XIMB3                               --�i�ڃ}�X�^�A�h�I��(�e�i�ڎ擾�p)
-- 2019/07/02 N.Abe Add Start E_�{�ғ�_15625
       ,xxcmm_system_items_b  XSIB                                --Disc�i�ڃA�h�I���}�X�^
-- 2019/07/02 N.Abe Add End   E_�{�ғ�_15625
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,fnd_lookup_values     FLV01                               --�N�C�b�N�R�[�h(����Ώۋ敪��)
       --,fnd_lookup_values     FLV02                               --�N�C�b�N�R�[�h(�d�ʗe�ϋ敪��)
       --,fnd_lookup_values     FLV03                               --�N�C�b�N�R�[�h(�d���敪��)
       --,fnd_lookup_values     FLV04                               --�N�C�b�N�R�[�h(�o�׋敪��)
       --,fnd_lookup_values     FLV05                               --�N�C�b�N�R�[�h(�����Ǘ��敪��)
       --,fnd_lookup_values     FLV06                               --�N�C�b�N�R�[�h(�d���P�����o���^�C�v��)
       --,fnd_lookup_values     FLV07                               --�N�C�b�N�R�[�h(�����L���敪��)
       --,fnd_lookup_values     FLV08                               --�N�C�b�N�R�[�h(�^��ʖ�)
       --,fnd_lookup_values     FLV09                               --�N�C�b�N�R�[�h(���i���ޖ�)
       --,fnd_lookup_values     FLV10                               --�N�C�b�N�R�[�h(���i��ʖ�)
       --,fnd_lookup_values     FLV11                               --�N�C�b�N�R�[�h(���敪��)
       --,fnd_lookup_values     FLV12                               --�N�C�b�N�R�[�h(�ܖ����ԋ敪��)
       --,fnd_lookup_values     FLV13                               --�N�C�b�N�R�[�h(�e��敪��)
       --,fnd_lookup_values     FLV14                               --�N�C�b�N�R�[�h(�P�ʋ敪��)
       --,fnd_lookup_values     FLV15                               --�N�C�b�N�R�[�h(�I���敪��)
       --,fnd_lookup_values     FLV16                               --�N�C�b�N�R�[�h(�g���[�X�敪��)
       --,fnd_user              FU_CB                               --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       --,fnd_user              FU_LU                               --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       --,fnd_user              FU_LL                               --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       --,fnd_logins            FL_LL                               --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  IIMB.item_id = XIMB.item_id
   AND  IIMB.whse_item_id = IIMB2.item_id(+)                      --�q�ɕi��
   AND  IIMB.whse_item_id = XIMB2.item_id(+)                      --�q�ɕi��
   AND  XIMB2.start_date_active <= TRUNC(SYSDATE)                 --�K�p�J�n��
   AND  XIMB2.end_date_active   >= TRUNC(SYSDATE)                 --�K�p�I����
   AND  XIMB.parent_item_id = IIMB3.item_id(+)                    --�e�i��
   AND  XIMB.parent_item_id = XIMB3.item_id(+)                    --�e�i��
   AND  XIMB3.start_date_active <= TRUNC(SYSDATE)                 --�K�p�J�n��
   AND  XIMB3.end_date_active   >= TRUNC(SYSDATE)                 --�K�p�I����
-- 2019/07/02 N.Abe Add Start E_�{�ғ�_15625
   AND  IIMB.item_no = XSIB.item_code(+)                          --�i�ڃR�[�h
-- 2019/07/02 N.Abe Add End   E_�{�ғ�_15625
   --�N�C�b�N�R�[�h�F����Ώۋ敪���擾
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  FLV01.language(+) = 'JA'                                  --����
   --AND  FLV01.lookup_type(+) = 'XXCMN_SALES_TARGET_CLASS'         --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV01.lookup_code(+) = IIMB.attribute26                   --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�d�ʗe�ϋ敪���擾
   --AND  FLV02.language(+) = 'JA'                                  --����
   --AND  FLV02.lookup_type(+) = 'XXCMN_WEIGHT_CAPACITY_CLASS'      --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV02.lookup_code(+) = IIMB.attribute10                   --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�d���敪���擾
   --AND  FLV03.language(+) = 'JA'                                  --����
   --AND  FLV03.lookup_type(+) = 'XXCMN_DESTINATION_DIV'            --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV03.lookup_code(+) = IIMB.attribute28                   --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�o�׋敪���擾
   --AND  FLV04.language(+) = 'JA'                                  --����
   --AND  FLV04.lookup_type(+) = 'XXCMN_SHIPPING_CLASS'             --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV04.lookup_code(+) = IIMB.attribute18                   --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�����Ǘ��敪���擾
   --AND  FLV05.language(+) = 'JA'                                  --����
   --AND  FLV05.lookup_type(+) ='XXCMN_COST_MANAGEMENT'             --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV05.lookup_code(+) = IIMB.attribute15                   --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�d���P�����o���^�C�v���擾
   --AND  FLV06.language(+) = 'JA'                                  --����
   --AND  FLV06.lookup_type(+) = 'XXCMN_VENDOR_PRICE_DERI_DAY_TY'   --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV06.lookup_code(+) = IIMB.attribute20                   --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�����L���敪���擾
   --AND  FLV07.language(+) = 'JA'                                  --����
   --AND  FLV07.lookup_type(+) = 'XXCMN_NEED_TEST'                  --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV07.lookup_code(+) = IIMB.attribute23                   --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�^��ʖ��擾
   --AND  FLV08.language(+) = 'JA'                                  --����
   --AND  FLV08.lookup_type(+) = 'XXCMN_D01'                        --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV08.lookup_code(+) = XIMB.model_type                    --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F���i���ޖ��擾
   --AND  FLV09.language(+) = 'JA'                                  --����
   --AND  FLV09.lookup_type(+) = 'XXCMN_D02'                        --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV09.lookup_code(+) = XIMB.product_class                 --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F���i��ʖ��擾
   --AND  FLV10.language(+) = 'JA'                                  --����
   --AND  FLV10.lookup_type(+) = 'XXCMN_D03'                        --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV10.lookup_code(+) = XIMB.product_type                  --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F���敪���擾
   --AND  FLV11.language(+) = 'JA'                                  --����
   --AND  FLV11.lookup_type(+) = 'XXCMN_RATE'                       --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV11.lookup_code(+) = XIMB.rate_class                    --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�ܖ����ԋ敪���擾
   --AND  FLV12.language(+) = 'JA'                                  --����
   --AND  FLV12.lookup_type(+) = 'XXCMN_SHELF_LIFE_CLASS'           --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV12.lookup_code(+) = XIMB.shelf_life_class              --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�e��敪���擾
   --AND  FLV13.language(+) = 'JA'                                  --����
   --AND  FLV13.lookup_type(+) = 'XXCMN_BOTTLE_CLASS'               --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV13.lookup_code(+) = XIMB.bottle_class                  --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�P�ʋ敪���擾
   --AND  FLV14.language(+) = 'JA'                                  --����
   --AND  FLV14.lookup_type(+) = 'XXCMN_UOM_CLASS'                  --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV14.lookup_code(+) = XIMB.uom_class                     --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�I���敪���擾
   --AND  FLV15.language(+) = 'JA'                                  --����
   --AND  FLV15.lookup_type(+) = 'XXCMN_INVENTORY_CHK_CLASS'        --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV15.lookup_code(+) = XIMB.inventory_chk_class           --�N�C�b�N�R�[�h
   --�N�C�b�N�R�[�h�F�g���[�X�敪���擾
   --AND  FLV16.language(+) = 'JA'                                  --����
   --AND  FLV16.lookup_type(+) = 'XXCMN_TRACE_CLASS'                --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV16.lookup_code(+) = XIMB.trace_class                   --�N�C�b�N�R�[�h
   --WHO�J�����擾
   --AND  XIMB.created_by = FU_CB.user_id(+)
   --AND  XIMB.last_updated_by = FU_LU.user_id(+)
   --AND  XIMB.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKZ_�i�ڃ}�X�^_��{_V IS 'SKYLINK�p�i�ڃ}�X�^�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�i�ڃR�[�h             IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�i�ږ�                 IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�i�ڗ���               IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�i�ڃJ�i��             IS '�i�ڃJ�i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�K�p�J�n��             IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�K�p�I����             IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�K�p�σt���O           IS '�K�p�σt���O'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�����t���O             IS '�����t���O'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�����t���O��           IS '�����t���O��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�P��                   IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���b�g�Ǘ��敪         IS '���b�g�Ǘ��敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���b�g�Ǘ��敪��       IS '���b�g�Ǘ��敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�q�ɕi�ڃR�[�h         IS '�q�ɕi�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�q�ɕi�ږ�             IS '�q�ɕi�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�q�ɕi�ڗ���           IS '�q�ɕi�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.��_�Q�R�[�h            IS '��_�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�V_�Q�R�[�h            IS '�V_�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�Q�R�[�h�K�p�J�n��     IS '�Q�R�[�h�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.��_�艿                IS '��_�艿'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�V_�艿                IS '�V_�艿'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�艿�K�p�J�n��         IS '�艿�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.��_�c�ƌ���            IS '��_�c�ƌ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�V_�c�ƌ���            IS '�V_�c�ƌ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�c�ƌ����K�p�J�n��     IS '�c�ƌ����K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.����Ώۋ敪           IS '����Ώۋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.����Ώۋ敪��         IS '����Ώۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���������J�n��         IS '���������J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.JAN����                IS 'JAN����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.ITF�R�[�h              IS 'ITF�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�P�[�X����             IS '�P�[�X����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.NET                    IS 'NET'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�d�ʗe�ϋ敪           IS '�d�ʗe�ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�d�ʗe�ϋ敪��         IS '�d�ʗe�ϋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�d��                   IS '�d��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�e��                   IS '�e��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�d���敪               IS '�d���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�d���敪��             IS '�d���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�o�׋敪               IS '�o�׋敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�o�׋敪��             IS '�o�׋敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�����Ǘ��敪           IS '�����Ǘ��敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�����Ǘ��敪��         IS '�����Ǘ��敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�d���P�����o���^�C�v   IS '�d���P�����o���^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�d���P�����o���^�C�v�� IS '�d���P�����o���^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.��\����               IS '��\����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���o�Ɋ��Z�P��         IS '���o�Ɋ��Z�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�����L���敪           IS '�����L���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�����L���敪��         IS '�����L���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.����LT                 IS '����LT'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�����               IS '�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�����\�����       IS '�����\�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�}�X�^��M����         IS '�}�X�^��M����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�������b�g�̔ԗL��     IS '�������b�g�̔ԗL��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�e�i�ڃR�[�h           IS '�e�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�e�i�ږ�               IS '�e�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�e�i�ڗ���             IS '�e�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�p�~�敪               IS '�p�~�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�p�~�敪��             IS '�p�~�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�p�~_�������~��        IS '�p�~_�������~��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�^���                 IS '�^���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�^��ʖ�               IS '�^��ʖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���i����               IS '���i����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���i���ޖ�             IS '���i���ޖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���i���               IS '���i���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���i��ʖ�             IS '���i��ʖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�ܖ�����               IS '�ܖ�����'
/
-- 2017/06/07 K.Kiriu Add Start E_�{�ғ�_14244
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�ܖ�����_��            IS '�ܖ�����_��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�\���敪               IS '�\���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�\���敪��             IS '�\���敪��'
/
-- 2017/06/07 K.Kiriu Add End   E_�{�ғ�_14244
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�[������               IS '�[������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�H��Q�R�[�h           IS '�H��Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�W������               IS '�W������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�o�ג�~��             IS '�o�ג�~��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���敪                 IS '���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���敪��               IS '���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�������               IS '�������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�ܖ����ԋ敪           IS '�ܖ����ԋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�ܖ����ԋ敪��         IS '�ܖ����ԋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�e��敪               IS '�e��敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�e��敪��             IS '�e��敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�P�ʋ敪               IS '�P�ʋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�P�ʋ敪��             IS '�P�ʋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�I���敪               IS '�I���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�I���敪��             IS '�I���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�g���[�X�敪           IS '�g���[�X�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�g���[�X�敪��         IS '�g���[�X�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�o�ד���               IS '�o�ד���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�z��                   IS '�z��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�p���b�g����ő�i��   IS '�p���b�g����ő�i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�p���b�g�i             IS '�p���b�g�i'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�P�[�X�d�ʗe��         IS '�P�[�X�d�ʗe��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�����g�p��             IS '�����g�p��'
/
-- 2012/08/29 T.Makuta Add Start E_�{�ғ�_09591
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�N�x����               IS '�N�x����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�N�x��������           IS '�N�x��������'
/
-- 2012/08/29 T.Makuta Add End   E_�{�ғ�_09591
-- 2018/10/29 N.Koyama Add Start E_�{�ғ�_15277
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���b�g�t�]�敪         IS '���b�g�t�]�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���b�g�t�]�敪����     IS '���b�g�t�]�敪����'
/
-- 2018/10/29 N.Koyama Add End   E_�{�ғ�_15277
-- 2020/02/27 Y.Sasaki Add Start E_�{�ғ�_16213
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�Y�n����               IS '�Y�n����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�Y�n��������           IS '�Y�n��������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.��������               IS '��������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.������������           IS '������������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�N�x                   IS '�N�x'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�L�@                   IS '�L�@'
/
-- 2020/02/27 Y.Sasaki Add End E_�{�ғ�_16213
-- 2019/07/02 N.Abe Add Start E_�{�ғ�_15625
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�i�ڃX�e�[�^�X         IS '�i�ڃX�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�i�ڃX�e�[�^�X����     IS '�i�ڃX�e�[�^�X����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�i�ڏڍ׃X�e�[�^�X     IS '�i�ڏڍ׃X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�i�ڏڍ׃X�e�[�^�X���� IS '�i�ڏڍ׃X�e�[�^�X����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.���l                   IS '���l'
/
-- 2019/07/02 N.Abe Add End   E_�{�ғ�_15625
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�쐬��                 IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�쐬��                 IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�ŏI�X�V��             IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�ŏI�X�V��             IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�ڃ}�X�^_��{_V.�ŏI�X�V���O�C��       IS '�ŏI�X�V���O�C��'
/
