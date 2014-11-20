CREATE OR REPLACE VIEW APPS.XXSKY_���Ə��}�X�^_��{_V
(
 ���Ə��R�[�h
,���Ə���
,���Ə�����
,���Ə��J�i��
,�K�p�J�n��
,�K�p�I����
,�X�֔ԍ�
,�Z��
,�d�b�ԍ�
,FAX�ԍ�
,�{���R�[�h
,������
,�g�p�p�r
,�g�p�p�r��
,�o�׊Ǘ����敪
,�o�׊Ǘ����敪��
,�w���S���t���O
,�w���S���t���O��
,�o�גS���t���O
,�o�גS���t���O��
,�S���E�ӂP
,�S���E�ӂQ
,�S���E�ӂR
,�S���E�ӂS
,�S���E�ӂT
,�S���E�ӂU
,�S���E�ӂV
,�S���E�ӂW
,�S���E�ӂX
,�S���E�ӂP�O
,�e���Ə��R�[�h
,�e���Ə���
,�����_�o�׈˗��쐬�ۋ敪
,�����_�o�׈˗��쐬�ۋ敪��
,�n��R�[�h
,�n�於
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  HLA.location_code              --���Ə��R�[�h
       ,XLA.location_name              --���Ə���
       ,XLA.location_short_name        --���Ə�����
       ,XLA.location_name_alt          --���Ə��J�i��
       ,XLA.start_date_active          --�K�p�J�n��
       ,XLA.end_date_active            --�K�p�I����
       ,XLA.zip                        --�X�֔ԍ�
       ,XLA.address_line1              --�Z��
       ,XLA.phone                      --�d�b�ԍ�
       ,XLA.fax                        --FAX�ԍ�
       ,XLA.division_code              --�{���R�[�h
       ,HLA.inactive_date              --������
       ,HLA.attribute_category         --�g�p�p�r
       ,DECODE(HLA.attribute_category, 'DEPT','����', 'WHS','�q��' )  --�g�p�p�r��
       ,HLA.attribute1                 --�o�׊Ǘ����敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV02.meaning                  --�o�׊Ǘ����敪��
       ,(SELECT FLV02.meaning
           FROM fnd_lookup_values FLV02    --�N�C�b�N�R�[�h(�o�׊Ǘ����敪��)
          WHERE FLV02.language    = 'JA'
           AND  FLV02.lookup_type = 'XXCMN_SHIPMENT_MANAGEMENT'
           AND  FLV02.lookup_code = HLA.attribute1
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,HLA.attribute3                 --�w���S���t���O
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV03.meaning                  --�w���S���t���O��
       ,(SELECT FLV03.meaning
           FROM fnd_lookup_values FLV03    --�N�C�b�N�R�[�h(�w���S���t���O��)
          WHERE FLV03.language    = 'JA'
            AND FLV03.lookup_type = 'XXCMN_PURCHASING_FLAG'
            AND FLV03.lookup_code = HLA.attribute3
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,HLA.attribute4                 --�o�גS���t���O
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV04.meaning                  --�o�גS���t���O��
       ,(SELECT FLV04.meaning
           FROM fnd_lookup_values FLV04    --�N�C�b�N�R�[�h(�o�גS���t���O��)
          WHERE FLV04.language    = 'JA'
            AND FLV04.lookup_type = 'XXCMN_SHIPPING_FLAG'
            AND FLV04.lookup_code = HLA.attribute4
        ) FLV04_meaning
       --,RES01.responsibility_name      --�S���E�ӂP
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
               ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute5)  = FR.responsibility_id
        ) RES01_responsibility_name
       --,RES02.responsibility_name      --�S���E�ӂQ
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
               ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute6)  = FR.responsibility_id
        ) RES02_responsibility_name
       --,RES03.responsibility_name      --�S���E�ӂR
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
               ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute7)  = FR.responsibility_id
        )  RES03_responsibility_name
       --,RES04.responsibility_name      --�S���E�ӂS
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
               ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute8)  = FR.responsibility_id
        )  RES04_responsibility_name
       --,RES05.responsibility_name      --�S���E�ӂT
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
               ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute9)  = FR.responsibility_id
        )  RES05_responsibility_name
       --,RES06.responsibility_name      --�S���E�ӂU
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
               ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute10) = FR.responsibility_id
        )  RES06_responsibility_name
       --,RES07.responsibility_name      --�S���E�ӂV
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
               ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute11) = FR.responsibility_id
        )  RES07_responsibility_name
       --,RES08.responsibility_name      --�S���E�ӂW
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
               ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute12) = FR.responsibility_id
        )  RES08_responsibility_name
       --,RES09.responsibility_name      --�S���E�ӂX
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
               ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute13) = FR.responsibility_id
        )  RES09_responsibility_name
       --,RES10.responsibility_name      --�S���E�ӂP�O
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
               ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute14) = FR.responsibility_id
        )  RES10_responsibility_name
       ,XLV.location_code              --�e���Ə��R�[�h
       ,XLV.location_name              --�e���Ə���
       ,HLA.attribute18                --�����_�o�׈˗��쐬�ۋ敪
       --,FLV05.meaning                  --�����_�o�׈˗��쐬�ۋ敪��
       ,(SELECT FLV05.meaning
           FROM fnd_lookup_values FLV05    --�N�C�b�N�R�[�h(�����_�o�׈˗��쐬�ۋ敪��)
          WHERE FLV05.language    = 'JA'
            AND FLV05.lookup_type = 'XXCMN_INCLUDE_EXCLUDE'
            AND FLV05.lookup_code = HLA.attribute18
        ) FLV05_meaning
       ,HLA.attribute20                --�n��R�[�h
       --,FLV06.meaning                  --�n�於
       ,(SELECT FLV06.meaning
           FROM fnd_lookup_values FLV06    --�N�C�b�N�R�[�h(�n�於)
          WHERE FLV06.language    = 'JA'
            AND FLV06.lookup_type = 'XXCMN_AREA'
            AND FLV06.lookup_code = HLA.attribute20
        ) FLV06_meaning
       --,FU_CB.user_name                --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE XLA.created_by = FU_CB.user_id
        ) FU_CB_user_name
       ,TO_CHAR( XLA.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                       --�쐬��
       --,FU_LU.user_name                --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE XLA.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
       ,TO_CHAR( XLA.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                       --�ŏI�X�V��
       --,FU_LL.user_name                --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE XLA.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  xxcmn_locations_all XLA        --���Ə��A�h�I��
       ,hr_locations_all    HLA        --���Ə��}�X�^
       ,xxsky_locations_v   XLV        --SKYLINK�p����VIEW ���Ə����VIEW
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
       --        ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES01                                 --�S���E��1���擾�p
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
       --        ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES02                                 --�S���E��2���擾�p
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
       --        ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES03                                 --�S���E��3���擾�p
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
       --        ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES04                                 --�S���E��4���擾�p
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
       --        ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES05                                 --�S���E��5���擾�p
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
       --        ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES06                                 --�S���E��6���擾�p
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
       --        ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES07                                 --�S���E��7���擾�p
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
       --        ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES08                                 --�S���E��8���擾�p
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
       --        ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES09                                 --�S���E��9���擾�p
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --�E�Ӄ}�X�^(���{��)
       --        ,fnd_application         FA       --�A�v���P�[�V�����}�X�^
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES10                                 --�S���E��10���擾�p
       --,fnd_lookup_values               FLV02    --�N�C�b�N�R�[�h(�o�׊Ǘ����敪��)
       --,fnd_lookup_values               FLV03    --�N�C�b�N�R�[�h(�w���S���t���O��)
       --,fnd_lookup_values               FLV04    --�N�C�b�N�R�[�h(�o�גS���t���O��)
       --,fnd_lookup_values               FLV05    --�N�C�b�N�R�[�h(�����_�o�׈˗��쐬�ۋ敪��)
       --,fnd_lookup_values               FLV06    --�N�C�b�N�R�[�h(�n�於)
       --,fnd_user                        FU_CB    --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       --,fnd_user                        FU_LU    --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       --,fnd_user                        FU_LL    --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       --,fnd_logins                      FL_LL    --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  XLA.location_id = HLA.location_id
   AND  TO_NUMBER(HLA.attribute17) = XLV.location_id(+)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  TO_NUMBER(HLA.attribute5)  = RES01.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute6)  = RES02.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute7)  = RES03.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute8)  = RES04.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute9)  = RES05.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute10) = RES06.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute11) = RES07.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute12) = RES08.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute13) = RES09.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute14) = RES10.responsibility_id(+)
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_SHIPMENT_MANAGEMENT'
   --AND  FLV02.lookup_code(+) = HLA.attribute1
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXCMN_PURCHASING_FLAG'
   --AND  FLV03.lookup_code(+) = HLA.attribute3
   --AND  FLV04.language(+)    = 'JA'
   --AND  FLV04.lookup_type(+) = 'XXCMN_SHIPPING_FLAG'
   --AND  FLV04.lookup_code(+) = HLA.attribute4
   --AND  FLV05.language(+)    = 'JA'
   --AND  FLV05.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   --AND  FLV05.lookup_code(+) = HLA.attribute18
   --AND  FLV06.language(+)    = 'JA'
   --AND  FLV06.lookup_type(+) = 'XXCMN_AREA'
   --AND  FLV06.lookup_code(+) = HLA.attribute20
   --AND  XLA.created_by         = FU_CB.user_id(+)
   --AND  XLA.last_updated_by    = FU_LU.user_id(+)
   --AND  XLA.last_update_login  = FL_LL.login_id(+)
   --AND  FL_LL.user_id          = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
   AND  HLA.inactive_date IS NULL
/
COMMENT ON TABLE APPS.XXSKY_���Ə��}�X�^_��{_V IS 'SKYLINK�p���Ə��}�X�^�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.���Ə��R�[�h                  IS '���Ə��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.���Ə���                      IS '���Ə���'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.���Ə�����                    IS '���Ə�����'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.���Ə��J�i��                  IS '���Ə��J�i��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�K�p�J�n��                    IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�K�p�I����                    IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�X�֔ԍ�                      IS '�X�֔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�Z��                          IS '�Z��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�d�b�ԍ�                      IS '�d�b�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.FAX�ԍ�                       IS 'FAX�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�{���R�[�h                    IS '�{���R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.������                        IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�g�p�p�r                      IS '�g�p�p�r'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�g�p�p�r��                    IS '�g�p�p�r��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�o�׊Ǘ����敪                IS '�o�׊Ǘ����敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�o�׊Ǘ����敪��              IS '�o�׊Ǘ����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�w���S���t���O                IS '�w���S���t���O'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�w���S���t���O��              IS '�w���S���t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�o�גS���t���O                IS '�o�גS���t���O'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�o�גS���t���O��              IS '�o�גS���t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�S���E�ӂP                    IS '�S���E�ӂP'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�S���E�ӂQ                    IS '�S���E�ӂQ'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�S���E�ӂR                    IS '�S���E�ӂR'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�S���E�ӂS                    IS '�S���E�ӂS'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�S���E�ӂT                    IS '�S���E�ӂT'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�S���E�ӂU                    IS '�S���E�ӂU'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�S���E�ӂV                    IS '�S���E�ӂV'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�S���E�ӂW                    IS '�S���E�ӂW'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�S���E�ӂX                    IS '�S���E�ӂX'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�S���E�ӂP�O                  IS '�S���E�ӂP�O'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�e���Ə��R�[�h                IS '�e���Ə��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�e���Ə���                    IS '�e���Ə���'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�����_�o�׈˗��쐬�ۋ敪    IS '�����_�o�׈˗��쐬�ۋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�����_�o�׈˗��쐬�ۋ敪��  IS '�����_�o�׈˗��쐬�ۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�n��R�[�h                    IS '�n��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�n�於                        IS '�n�於'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�쐬��                        IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�쐬��                        IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�ŏI�X�V��                    IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�ŏI�X�V��                    IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Ə��}�X�^_��{_V.�ŏI�X�V���O�C��              IS '�ŏI�X�V���O�C��'
/
