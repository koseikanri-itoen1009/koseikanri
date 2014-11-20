CREATE OR REPLACE VIEW APPS.XXSKY_���b�g�}�X�^_����_V
(
 ���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���b�g�ԍ�
,�����N����
,�ŗL�L��
,�ܖ�����
,�[����_����
,�[����_�ŏI
,�݌ɓ���
,�݌ɒP��
,�����
,����於
,�d���`��
,�d���`�Ԗ�
,�����敪
,�����敪��
,�N�x
,�Y�n
,�Y�n��
,�^�C�v
,�����N�P
,�����N�Q
,�����N�R
,���Y�`�[�敪
,���Y�`�[�敪��
,���C��NO
,�E�v
,���������H��
,�������������b�g�ԍ�
,�����˗�NO
,���b�g�X�e�[�^�X
,���b�g�X�e�[�^�X��
,�쐬�敪
,�쐬�敪��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  XPCV.prod_class_code          --���i�敪
       ,XPCV.prod_class_name          --���i�敪��
       ,XICV.item_class_code          --�i�ڋ敪
       ,XICV.item_class_name          --�i�ڋ敪��
       ,XCCV.crowd_code               --�Q�R�[�h
       ,XIMV.item_no                  --�i�ڃR�[�h
       ,XIMV.item_name                --�i�ږ�
       ,XIMV.item_short_name          --�i�ڗ���
       ,CASE WHEN ILM.lot_id = 0 THEN '0'          --'DEFAULTLOT'��'0'�ɕϊ�
             ELSE                     ILM.lot_no
        END                 lot_no    --���b�g�ԍ�
       ,ILM.attribute1                --�����N����
       ,ILM.attribute2                --�ŗL�L��
       ,ILM.attribute3                --�ܖ�����
       ,ILM.attribute4                --�[����(����)
       ,ILM.attribute5                --�[����(�ŏI)
       ,NVL(TO_NUMBER(ILM.attribute6), 0)
                                      --�݌ɓ���
       ,NVL(TO_NUMBER(ILM.attribute7), 0)
                                      --�݌ɒP��
       ,ILM.attribute8                --�����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVV.vendor_name               --����於
       ,(SELECT XVV.vendor_name
         FROM xxsky_vendors_v XVV     --�d����VIEW
         WHERE  ILM.attribute8 = XVV.segment1
        ) XVV_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,ILM.attribute9                --�d���`��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV01.meaning                 --�d���`�Ԗ�
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01   --�N�C�b�N�R�[�h(�d���`�Ԗ�)
         WHERE FLV01.language    = 'JA'
         AND   FLV01.lookup_type = 'XXCMN_L05'
         AND   FLV01.lookup_code = ILM.attribute9
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,ILM.attribute10               --�����敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV02.meaning                 --�����敪��
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02   --�N�C�b�N�R�[�h(�����敪��)
         WHERE  FLV02.language    = 'JA'
         AND    FLV02.lookup_type = 'XXCMN_L06'
         AND    FLV02.lookup_code = ILM.attribute10
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,ILM.attribute11               --�N�x
       ,ILM.attribute12               --�Y�n
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV03.meaning                 --�Y�n��
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03   --�N�C�b�N�R�[�h(�Y�n��)
         WHERE FLV03.language    = 'JA'
         AND   FLV03.lookup_type = 'XXCMN_L07'
         AND   FLV03.lookup_code = ILM.attribute12
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_NUMBER( ILM.attribute13 )  --�^�C�v
       ,ILM.attribute14               --�����N�P
       ,ILM.attribute15               --�����N�Q
       ,ILM.attribute19               --�����N�R
       ,ILM.attribute16               --���Y�`�[�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV04.meaning                 --���Y�`�[�敪��
       ,(SELECT FLV04.meaning
         FROM fnd_lookup_values FLV04   --�N�C�b�N�R�[�h(���Y�`�[�敪��)
         WHERE FLV04.language    = 'JA'
         AND   FLV04.lookup_type = 'XXCMN_L03'
         AND   FLV04.lookup_code = ILM.attribute16
        ) FLV04_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,ILM.attribute17               --���C��No
       ,ILM.attribute18               --�E�v
       ,ILM.attribute20               --���������H��
       ,ILM.attribute21               --�������������b�g�ԍ�
       ,ILM.attribute22               --�����˗�No
       ,ILM.attribute23               --���b�g�X�e�[�^�X
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV05.meaning                 --���b�g�X�e�[�^�X��
       ,(SELECT FLV05.meaning
         FROM fnd_lookup_values FLV05   --�N�C�b�N�R�[�h(���b�g�X�e�[�^�X��)
         WHERE FLV05.language    = 'JA'
         AND   FLV05.lookup_type = 'XXCMN_LOT_STATUS'
         AND   FLV05.lookup_code = ILM.attribute23
        ) FLV05_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,ILM.attribute24               --�쐬�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV06.meaning                 --�쐬�敪��
       ,(SELECT FLV06.meaning
         FROM fnd_lookup_values FLV06   --�N�C�b�N�R�[�h(�쐬�敪��)
         WHERE FLV06.language    = 'JA'
         AND   FLV06.lookup_type = 'XXCMN_DERIVE_DIV'
         AND   FLV06.lookup_code = ILM.attribute24
        ) FLV06_meaning
       --,FU_CB.user_name               --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE ILM.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( ILM.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                      --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name               --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE ILM.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( ILM.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                      --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name               --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE ILM.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  ic_lots_mst           ILM     --���b�g�}�X�^
       ,xxsky_prod_class_v    XPCV    --SKYLINK�p ���i�敪�擾VIEW
       ,xxsky_item_class_v    XICV    --SKYLINK�p �i�ڋ敪�擾VIEW
       ,xxsky_crowd_code_v    XCCV    --SKYLINK�p �S�R�[�h�擾VIEW
       ,xxsky_item_mst_v      XIMV    --OPM�i�ڏ��VIEW
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,xxsky_vendors_v       XVV     --�d����VIEW
       --,fnd_lookup_values     FLV01   --�N�C�b�N�R�[�h(�d���`�Ԗ�)
       --,fnd_lookup_values     FLV02   --�N�C�b�N�R�[�h(�����敪��)
       --,fnd_lookup_values     FLV03   --�N�C�b�N�R�[�h(�Y�n��)
       --,fnd_lookup_values     FLV04   --�N�C�b�N�R�[�h(���Y�`�[�敪��)
       --,fnd_lookup_values     FLV05   --�N�C�b�N�R�[�h(���b�g�X�e�[�^�X��)
       --,fnd_lookup_values     FLV06   --�N�C�b�N�R�[�h(�쐬�敪��)
       --,fnd_user              FU_CB   --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       --,fnd_user              FU_LU   --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       --,fnd_user              FU_LL   --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       --,fnd_logins            FL_LL   --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  ILM.item_id          = XPCV.item_id(+)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  ILM.item_id          = XICV.item_id(+)
   --AND  ILM.item_id          = XCCV.item_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
   AND  XPCV.item_id         = XICV.item_id
   AND  XPCV.item_id         = XCCV.item_id
   AND  XICV.item_id         = XCCV.item_id
   AND  ILM.item_id          = XIMV.item_id(+)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  ILM.attribute8       = XVV.segment1(+)
   --AND  FLV01.language(+)    = 'JA'
   --AND  FLV01.lookup_type(+) = 'XXCMN_L05'
   --AND  FLV01.lookup_code(+) = ILM.attribute9
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_L06'
   --AND  FLV02.lookup_code(+) = ILM.attribute10
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXCMN_L07'
   --AND  FLV03.lookup_code(+) = ILM.attribute12
   --AND  FLV04.language(+)    = 'JA'
   --AND  FLV04.lookup_type(+) = 'XXCMN_L03'
   --AND  FLV04.lookup_code(+) = ILM.attribute16
   --AND  FLV05.language(+)    = 'JA'
   --AND  FLV05.lookup_type(+) = 'XXCMN_LOT_STATUS'
   --AND  FLV05.lookup_code(+) = ILM.attribute23
   --AND  FLV06.language(+)    = 'JA'
   --AND  FLV06.lookup_type(+) = 'XXCMN_DERIVE_DIV'
   --AND  FLV06.lookup_code(+) = ILM.attribute24
   --AND  ILM.created_by           = FU_CB.user_id(+)
   --AND  ILM.last_updated_by      = FU_LU.user_id(+)
   --AND  ILM.last_update_login    = FL_LL.login_id(+)
   --AND  FL_LL.user_id            = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
   AND  ILM.inactive_ind  = 0
   AND  ILM.delete_mark   = 0
/
COMMENT ON TABLE APPS.XXSKY_���b�g�}�X�^_����_V IS 'SKYLINK�p���b�g�}�X�^�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�i�ڋ敪                       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�i�ڋ敪��                     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�Q�R�[�h                       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�i�ڃR�[�h                     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�i�ږ�                         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�i�ڗ���                       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.���b�g�ԍ�                     IS '���b�g�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�����N����                     IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�ŗL�L��                       IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�ܖ�����                       IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�[����_����                    IS '�[����_����'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�[����_�ŏI                    IS '�[����_�ŏI'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�݌ɓ���                       IS '�݌ɓ���'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�݌ɒP��                       IS '�݌ɒP��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�����                         IS '�����'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.����於                       IS '����於'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�d���`��                       IS '�d���`��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�d���`�Ԗ�                     IS '�d���`�Ԗ�'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�����敪                       IS '�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�����敪��                     IS '�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�N�x                           IS '�N�x'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�Y�n                           IS '�Y�n'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�Y�n��                         IS '�Y�n��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�^�C�v                         IS '�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�����N�P                       IS '�����N�P'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�����N�Q                       IS '�����N�Q'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�����N�R                       IS '�����N�R'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.���Y�`�[�敪                   IS '���Y�`�[�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.���Y�`�[�敪��                 IS '���Y�`�[�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.���C��NO                       IS '���C��No'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�E�v                           IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.���������H��                   IS '���������H��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�������������b�g�ԍ�           IS '�������������b�g�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�����˗�NO                     IS '�����˗�No'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.���b�g�X�e�[�^�X               IS '���b�g�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.���b�g�X�e�[�^�X��             IS '���b�g�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�쐬�敪                       IS '�쐬�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�쐬�敪��                     IS '�쐬�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���b�g�}�X�^_����_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
