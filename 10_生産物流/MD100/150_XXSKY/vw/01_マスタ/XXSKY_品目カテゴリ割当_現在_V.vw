CREATE OR REPLACE VIEW APPS.XXSKY_�i�ڃJ�e�S������_����_V
(
 �i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�i�ڃJ�i��
,�K�p�J�n��
,�K�p�I����
,�Q�R�[�h
,����Q�R�[�h
,�}�[�P�p�Q�R�[�h
,�o�����p�Q�R�[�h
,���i���i�敪
,���i���i�敪��
,���i�敪
,���i�敪��
,�{�Џ��i�敪
,�{�Џ��i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�i���敪
,�i���敪��
,�o�����敪
,�o�����敪��
,���O�敪
,���O�敪��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  IIMB.item_no                  item_no                 --�i�ڃR�[�h
       ,XIMB.item_name                item_name               --�i�ږ�
       ,XIMB.item_short_name          item_short_name         --�i�ڗ���
       ,XIMB.item_name_alt            item_name_alt           --�i�ڃJ�i��
       ,XIMB.start_date_active        start_date_active       --�K�p�J�n��
       ,XIMB.end_date_active          end_date_active         --�K�p�I����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,IC01.crowd_code               crowd_code              --�Q�R�[�h
       ,( SELECT MCB.segment1                                 --�Q�R�[�h
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '�Q�R�[�h'
            AND  XIMB.item_id = GIC.item_id
        )  crowd_code
       --,IC02.crowd_s_code             crowd_s_code            --����Q�R�[�h
       ,( SELECT MCB.segment1                                 --����Q�R�[�h
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '����Q�R�[�h'
            AND  XIMB.item_id = GIC.item_id
        )  crowd_s_code
       --,IC03.crowd_m_code             crowd_m_code            --�}�[�P�p�Q�R�[�h
       ,( SELECT MCB.segment1                                 --�}�[�P�p�Q�R�[�h
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '�}�[�P�p�Q�R�[�h'
            AND  XIMB.item_id = GIC.item_id
        )  crowd_m_code
       --,IC04.crowd_k_code             crowd_k_code            --�o�����p�Q�R�[�h
       ,( SELECT MCB.segment1                                 --�o�����p�Q�R�[�h
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '�o�����p�Q�R�[�h'
            AND  XIMB.item_id = GIC.item_id
        )  crowd_k_code
       --,IC05.prod_item_class          prod_item_class         --���i���i�敪
       ,( SELECT MCB.segment1                                 --���i���i�敪
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '���i���i�敪'
            AND  XIMB.item_id = GIC.item_id
        )  prod_item_class
       --,IC05.prod_item_class_name     prod_item_class_name    --���i���i�敪��
       ,( SELECT MCT.description                              --���i���i�敪��
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '���i���i�敪'
            AND  XIMB.item_id = GIC.item_id
        )  prod_item_class_name
       --,IC06.prod_class               prod_class              --���i�敪
       ,( SELECT MCB.segment1                                 --���i�敪
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '���i�敪'
            AND  XIMB.item_id = GIC.item_id
        )  prod_class
       --,IC06.prod_class_name          prod_class_name         --���i�敪��
       ,( SELECT MCT.description                              --���i�敪��
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '���i�敪'
            AND  XIMB.item_id = GIC.item_id
        )  prod_class_name
       --,IC07.prod_class_h             prod_class_h            --�{�Џ��i�敪
       ,( SELECT MCB.segment1                                 --�{�Џ��i�敪
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '�{�Џ��i�敪'
            AND  XIMB.item_id = GIC.item_id
        )  prod_class_h
       --,IC07.prod_class_h_name        prod_class_h_name       --�{�Џ��i�敪��
       ,( SELECT MCT.description                              --�{�Џ��i�敪��
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '�{�Џ��i�敪'
            AND  XIMB.item_id = GIC.item_id
        )  prod_class_h_name
       --,IC08.item_class               item_class              --�i�ڋ敪
       ,( SELECT MCB.segment1                                 --�i�ڋ敪
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '�i�ڋ敪'
            AND  XIMB.item_id = GIC.item_id
        )  item_class
       --,IC08.item_class_name          item_class_name         --�i�ڋ敪��
       ,( SELECT MCT.description                              --�i�ڋ敪��
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '�i�ڋ敪'
            AND  XIMB.item_id = GIC.item_id
        )  item_class_name
       --,IC09.quality_class            quality_class           --�i���敪
       ,( SELECT MCB.segment1                                 --�i���敪
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '�i���敪'
            AND  XIMB.item_id = GIC.item_id
        )  quality_class
       --,IC09.quality_class_name       quality_class_name      --�i���敪��
       ,( SELECT MCT.description                              --�i���敪��
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '�i���敪'
            AND  XIMB.item_id = GIC.item_id
        )  quality_class_name
       --,IC10.b_tea_class              b_tea_class             --�o�����敪
       ,( SELECT MCB.segment1                                 --�o�����敪
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '�o�����敪'
            AND  XIMB.item_id = GIC.item_id
        )  b_tea_class
       --,IC10.b_tea_class_name         b_tea_class_name        --�o�����敪��
       ,( SELECT MCT.description                              --�o�����敪��
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '�o�����敪'
            AND  XIMB.item_id = GIC.item_id
        )  b_tea_class_name
       --,IC11.in_out_class             in_out_class            --���O�敪
       ,( SELECT MCB.segment1                                 --���O�敪
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '���O�敪'
            AND  XIMB.item_id = GIC.item_id
        )  in_out_class
       --,IC11.in_out_class_name        in_out_class_name       --���O�敪��
       ,( SELECT MCT.description                              --���O�敪��
           FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
                ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
                ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
                ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '���O�敪'
            AND  XIMB.item_id = GIC.item_id
        )  in_out_class_name
       --,FU_CB.user_name               created_by_name         --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE XIMB.created_by = FU_CB.user_id
        ) created_by_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XIMB.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                      creation_date           --�쐬����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name               last_updated_by_name    --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE XIMB.last_updated_by = FU_LU.user_id
        ) last_updated_by_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XIMB.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                      last_update_date        --�X�V����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name               last_update_login_name  --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE XIMB.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) last_update_login_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  ic_item_mst_b                 IIMB                    --OPM�i�ڃ}�X�^
       ,xxcmn_item_mst_b              XIMB                    --�i�ڃ}�X�^�A�h�I��
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
        --�Q�R�[�h
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          crowd_code             --�Q�R�[�h
       --    FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
       --         ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
       --         ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '�Q�R�[�h'
       -- )  IC01
        --����Q�R�[�h
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          crowd_s_code           --����Q�R�[�h
       --    FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
       --         ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
       --         ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '����Q�R�[�h'
       -- )  IC02
        --�}�[�P�p�Q�R�[�h
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          crowd_m_code           --�}�[�P�p�Q�R�[�h
       --    FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
       --         ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
       --         ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '�}�[�P�p�Q�R�[�h'
       -- )  IC03
        --�o�����p�Q�R�[�h
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          crowd_k_code           --�o�����p�Q�R�[�h
       --    FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
       --         ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
       --         ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '�o�����p�Q�R�[�h'
       -- )  IC04
        --���i���i�敪
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          prod_item_class        --���i���i�敪
       --         ,MCT.description       prod_item_class_name   --���i���i�敪��
       --    FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
       --         ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
       --         ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
       --         ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '���i���i�敪'
       -- )  IC05
        --���i�敪
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          prod_class             --���i�敪
       --         ,MCT.description       prod_class_name        --���i�敪��
       --    FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
       --         ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
       --         ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
       --         ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '���i�敪'
       -- )  IC06
        --�{�Џ��i�敪
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          prod_class_h           --�{�Џ��i�敪
       --         ,MCT.description       prod_class_h_name      --�{�Џ��i�敪��
       --    FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
       --         ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
       --         ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
       --         ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '�{�Џ��i�敪'
       -- )  IC07
        --�i�ڋ敪
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          item_class             --�i�ڋ敪
       --         ,MCT.description       item_class_name        --�i�ڋ敪��
       --    FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
       --         ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
       --         ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
       --         ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '�i�ڋ敪'
       -- )  IC08
        --�i���敪
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          quality_class          --�i���敪
       --         ,MCT.description       quality_class_name     --�i���敪��
       --    FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
       --         ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
       --         ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
       --         ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '�i���敪'
       -- )  IC09
        --�o�����敪
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          b_tea_class            --�o�����敪
       --         ,MCT.description       b_tea_class_name       --�o�����敪��
       --    FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
       --         ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
       --         ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
       --         ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '�o�����敪'
       -- )  IC10
        --���O�敪
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          in_out_class           --���O�敪
       --         ,MCT.description       in_out_class_name      --���O�敪��
       --    FROM  gmi_item_categories    GIC                   --OPM�i�ڃJ�e�S������
       --         ,mtl_categories_b       MCB                   --�i�ڃJ�e�S���}�X�^
       --         ,mtl_categories_tl      MCT                   --�i�ڃJ�e�S���}�X�^���{��
       --         ,mtl_category_sets_tl   MCS                   --�i�ڃJ�e�S���Z�b�g���{��
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '���O�敪'
       -- )  IC11
       --,fnd_user                    FU_CB                     --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       --,fnd_user                    FU_LU                     --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       --,fnd_user                    FU_LL                     --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       --,fnd_logins                  FL_LL                     --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  IIMB.inactive_ind <> '1'
   AND  XIMB.obsolete_class <> '1'
   AND  XIMB.start_date_active <= TRUNC(SYSDATE)
   AND  XIMB.end_date_active   >= TRUNC(SYSDATE)
   AND  IIMB.item_id = XIMB.item_id
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  XIMB.item_id = IC01.item_id(+)
   --AND  XIMB.item_id = IC02.item_id(+)
   --AND  XIMB.item_id = IC03.item_id(+)
   --AND  XIMB.item_id = IC04.item_id(+)
   --AND  XIMB.item_id = IC05.item_id(+)
   --AND  XIMB.item_id = IC06.item_id(+)
   --AND  XIMB.item_id = IC07.item_id(+)
   --AND  XIMB.item_id = IC08.item_id(+)
   --AND  XIMB.item_id = IC09.item_id(+)
   --AND  XIMB.item_id = IC10.item_id(+)
   --AND  XIMB.item_id = IC11.item_id(+)
   --WHO�J�����擾
   --AND  XIMB.created_by = FU_CB.user_id(+)
   --AND  XIMB.last_updated_by = FU_LU.user_id(+)
   --AND  XIMB.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKY_�i�ڃJ�e�S������_����_V IS 'SKYLINK�p�i�ڃJ�e�S�������i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�i�ڃR�[�h        IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�i�ږ�            IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�i�ڗ���          IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�i�ڃJ�i��        IS '�i�ڃJ�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�K�p�J�n��        IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�K�p�I����        IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�Q�R�[�h          IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.����Q�R�[�h      IS '����Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�}�[�P�p�Q�R�[�h  IS '�}�[�P�p�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�o�����p�Q�R�[�h  IS '�o�����p�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.���i���i�敪      IS '���i���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.���i���i�敪��    IS '���i���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.���i�敪          IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.���i�敪��        IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�{�Џ��i�敪      IS '�{�Џ��i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�{�Џ��i�敪��    IS '�{�Џ��i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�i�ڋ敪          IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�i�ڋ敪��        IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�i���敪          IS '�i���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�i���敪��        IS '�i���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�o�����敪        IS '�o�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�o�����敪��      IS '�o�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.���O�敪          IS '���O�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.���O�敪��        IS '���O�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�쐬��            IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�쐬��            IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�ŏI�X�V��        IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�ŏI�X�V��        IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڃJ�e�S������_����_V.�ŏI�X�V���O�C��  IS '�ŏI�X�V���O�C��'
/
