CREATE OR REPLACE VIEW APPS.XXSKY_�t�H�[�~����_����_V
(
 �t�H�[�~�����ԍ�
,�t�H�[�~��������
,�t�H�[�~�������̂Q
,�t�H�[�~�����E�v
,�t�H�[�~�����E�v�Q
,�o�[�W����
,�X�P�[�����O��
,�X�e�[�^�X
,�X�e�[�^�X��
,������
,������_�P��
,���e��
,���e��_�P��
,���x
,�H��ŗL�L��
,���񐶎Y��
,�p�b�J�[
,�p�b�J�[��
,���Y�H��
,���Y�H�ꖼ
,�U�֔����i
,�U�֔����i��
,��������v��
,��������v�ۖ�
,�����v�Z�v��
,�����v�Z�v�ۖ�
,�I�����C���t���O
,�I�����C���t���O��
,���׃^�C�v
,���׃^�C�v��
,���הԍ�
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,����
,�P��
,�����^�C�v
,�����^�C�v��
,���[�J�[
,���[�J�[��
,�z����
,��{����g�p��
,��{����g�p��_�P��
,��P��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  FFMB.formula_no                 --�t�H�[�~�����ԍ�
       ,FFMT.formula_desc1              --�t�H�[�~��������
       ,FFMT.formula_desc2              --�t�H�[�~�������̂Q
       ,FFMT.formula_desc1              --�t�H�[�~�����E�v
       ,FFMT.formula_desc2              --�t�H�[�~�����E�v�Q
       ,FFMB.formula_vers               --�o�[�W����
       ,FFMB.scale_type                 --�X�P�[�����O��
       ,FFMB.formula_status             --�X�e�[�^�X
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,GQST.meaning                    --�X�e�[�^�X��
       ,(SELECT GQST.meaning
         FROM gmd_qc_status_tl        GQST    --
         WHERE GQST.status_code = FFMB.formula_status
         AND   GQST.language    = 'JA'
         AND   GQST.entity_type = 'S'
        ) GQST_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,NVL( TO_NUMBER( FFMB.attribute1 ), 0 )
                                        --������
       ,FFMB.attribute2                 --������_�P��
       ,NVL( TO_NUMBER( FFMB.attribute3 ), 0 )
                                        --���e��
       ,FFMB.attribute4                 --���e��_�P��
       ,NVL( TO_NUMBER( FFMB.attribute5 ), 0 )
                                        --���x
       ,FFMB.attribute6                 --�H��ŗL�L��
       ,FFMB.attribute7                 --���񐶎Y��
       ,FFMB.attribute8                 --�p�b�J�[
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVV01.vendor_name               --�p�b�J�[��
       ,(SELECT XVV01.vendor_name
         FROM xxsky_vendors_v XVV01   --�d������VIEW(�p�b�J�[��)
         WHERE XVV01.segment1 = FFMB.attribute8
        ) XVV01_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,FFMB.attribute9                 --���Y�H��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVSV.vendor_site_name           --���Y�H�ꖼ
       ,(SELECT XVSV.vendor_site_name
         FROM xxsky_vendor_sites_v XVSV    --�d����T�C�g���VIEW
         WHERE XVSV.vendor_site_code = FFMB.attribute9
        ) XVSV_vendor_site_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,FFMB.attribute10                --�U�֔����i
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XIMV01.item_name                --�U�֔����i��
       ,(SELECT XIMV01.item_name
         FROM xxsky_item_mst_v XIMV01  --�i�ڏ��VIEW(�U�֔����i��)
         WHERE XIMV01.item_no = FFMB.attribute10
        ) XIMV01_item_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,FFMB.attribute11                --��������v��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV01.meaning
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01   --�N�C�b�N�R�[�h(��������v�ۖ�)
         WHERE FLV01.language    = 'JA'
         AND   FLV01.lookup_type = 'XXCMN_MATER_ANALY'
         AND   FLV01.lookup_code = FFMB.attribute11
        ) gen_bunkai_youhi                --��������v�ۖ�
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,FFMB.attribute12                --�����v�Z�v��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV02.meaning
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02   --�N�C�b�N�R�[�h(�����v�Z�v�ۖ�)
         WHERE FLV02.language    = 'JA'
         AND   FLV02.lookup_type = 'XXCMN_YIELD_COUNT'
         AND   FLV02.lookup_code = FFMB.attribute12
        ) budomari_keisan_youhi           --�����v�Z�v�ۖ�
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,FFMB.attribute13                --�I�����C���t���O
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV03.meaning
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03   --�N�C�b�N�R�[�h(�I�����C���t���O��)
         WHERE FLV03.language    = 'JA'
         AND   FLV03.lookup_type = 'XXCMN_ONLINE_FLAG'
         AND   FLV03.lookup_code = FFMB.attribute13
        ) online_flag                     --�I�����C���t���O��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,FMD.line_type                   --���׃^�C�v
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV04.meaning
       ,(SELECT FLV04.meaning
         FROM fnd_lookup_values FLV04   --�N�C�b�N�R�[�h(���׃^�C�v��)
         WHERE FLV04.language    = 'JA'
         AND   FLV04.lookup_type = 'GMD_FORMULA_ITEM_TYPE'
         AND   FLV04.lookup_code = FMD.line_type
        ) line_type_name                  --���׃^�C�v��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,FMD.line_no                     --���הԍ�
       ,XIMV02.item_no                  --�i�ڃR�[�h
       ,XIMV02.item_name                --�i�ږ�
       ,XIMV02.item_short_name          --�i�ڗ���
       ,XPCV.prod_class_code            --���i�敪
       ,XPCV.prod_class_name            --���i�敪��
       ,XICV.item_class_code            --�i�ڋ敪
       ,XICV.item_class_name            --�i�ڋ敪��
       ,XCCV.crowd_code                 --�Q�R�[�h
       ,FMD.qty                         --����
       ,FMD.item_um                     --�P��
       ,FMD.release_type                --�����^�C�v
       ,DECODE(FMD.release_type, 0, '����', 1, '�蓮')    --�����^�C�v��
       ,FMD.attribute1                  --���[�J�[
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVV02.vendor_name               --���[�J�[��
       ,(SELECT XVV02.vendor_name
         FROM xxsky_vendors_v XVV02   --�d������VIEW(���[�J�[��)
         WHERE XVV02.segment1 = FMD.attribute1
        ) XVV02_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,NVL( TO_NUMBER( FMD.attribute2 ), 0 )
                                        --�z����
       ,NVL( TO_NUMBER( FMD.attribute3 ), 0 )
                                        --��{����g�p��
       ,FMD.attribute4                  --��{����g�p��_�P��
       ,NVL(TO_NUMBER(FMD.attribute5), 0)
                                        --��P��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_CB.user_name                 --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE FFMB.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( FFMB.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name                 --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE FFMB.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( FFMB.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name                 --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE FFMB.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  fm_form_mst_b           FFMB    --�t�H�[�~�����}�X�^
       ,fm_form_mst_tl          FFMT    --�t�H�[�~�����}�X�^(����)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,gmd_qc_status_tl        GQST    --
       --,xxsky_vendors_v         XVV01   --�d������VIEW(�p�b�J�[��)
       --,xxsky_vendor_sites_v    XVSV    --�d����T�C�g���VIEW
       --,xxsky_item_mst_v        XIMV01  --�i�ڏ��VIEW(�U�֔����i��)
       --,fnd_lookup_values       FLV01   --�N�C�b�N�R�[�h(��������v�ۖ�)
       --,fnd_lookup_values       FLV02   --�N�C�b�N�R�[�h(�����v�Z�v�ۖ�)
       --,fnd_lookup_values       FLV03   --�N�C�b�N�R�[�h(�I�����C���t���O��)
       --,fnd_lookup_values       FLV04   --�N�C�b�N�R�[�h(���׃^�C�v��)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
       ,fm_matl_dtl             FMD     --�t�H�[�~�����}�X�^����
       ,xxsky_item_mst_v        XIMV02  --�i�ڏ��VIEW(���וi�ږ�)
       ,xxsky_prod_class_v      XPCV    --���i�敪���VIEW
       ,xxsky_item_class_v      XICV    --�i�ڋ敪���VIEW
       ,xxsky_crowd_code_v      XCCV    --�S�R�[�h���VIEW
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,xxsky_vendors_v         XVV02   --�d������VIEW(���[�J�[��)
       --,fnd_user                FU_CB   --���[�U�[�}�X�^(created_by���̎擾�p)
       --,fnd_user                FU_LU   --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       --,fnd_user                FU_LL   --���[�U�[�}�X�^(last_update_login���̎擾�p)
       --,fnd_logins              FL_LL   --���O�C���}�X�^(last_update_login���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
WHERE   SUBSTRB( FFMB.formula_no, 8, 3 ) <> '-9-'        --�w�i�ڐU�ցx�ΏۊO
  AND   FFMB.delete_mark         = 0
  AND   FFMB.formula_id          = FMD.formula_id
  AND   FFMT.formula_id(+)       = FFMB.formula_id
  AND   FFMT.language(+)         = 'JA'
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
  --AND   GQST.status_code(+)      = FFMB.formula_status
  --AND   GQST.language(+)         = 'JA'
  --AND   GQST.entity_type(+)      = 'S'
  --AND   XVV01.segment1(+)        = FFMB.attribute8
  --AND   XVSV.vendor_site_code(+) = FFMB.attribute9
  --AND   XIMV01.item_no(+)        = FFMB.attribute10
  --AND   XIMV02.item_id(+)        = FMD.item_id
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
  AND   XIMV02.item_id        = FMD.item_id
  AND   XPCV.item_id(+)          = FMD.item_id
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
  --AND   XICV.item_id(+)          = FMD.item_id
  --AND   XCCV.item_id(+)          = FMD.item_id
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
  AND   XPCV.item_id             = XICV.item_id
  AND   XPCV.item_id             = XCCV.item_id
  AND   XICV.item_id             = XCCV.item_id
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
  --AND   XVV02.segment1(+)        = FMD.attribute1
  --AND   FLV01.language(+)        = 'JA'
  --AND   FLV01.lookup_type(+)     = 'XXCMN_MATER_ANALY'
  --AND   FLV01.lookup_code(+)     = FFMB.attribute11
  --AND   FLV02.language(+)        = 'JA'
  --AND   FLV02.lookup_type(+)     = 'XXCMN_YIELD_COUNT'
  --AND   FLV02.lookup_code(+)     = FFMB.attribute12
  --AND   FLV03.language(+)        = 'JA'
  --AND   FLV03.lookup_type(+)     = 'XXCMN_ONLINE_FLAG'
  --AND   FLV03.lookup_code(+)     = FFMB.attribute13
  --AND   FLV04.language(+)        = 'JA'
  --AND   FLV04.lookup_type(+)     = 'GMD_FORMULA_ITEM_TYPE'
  --AND   FLV04.lookup_code(+)     = FMD.line_type
  --AND   FFMB.created_by          = FU_CB.user_id(+)
  --AND   FFMB.last_updated_by     = FU_LU.user_id(+)
  --AND   FFMB.last_update_login   = FL_LL.login_id(+)
  --AND   FL_LL.user_id            = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKY_�t�H�[�~����_����_V IS 'SKYLINK�p�t�H�[�~�����}�X�^�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�t�H�[�~�����ԍ�               IS '�t�H�[�~�����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�t�H�[�~��������               IS '�t�H�[�~��������'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�t�H�[�~�������̂Q             IS '�t�H�[�~�������̂Q'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�t�H�[�~�����E�v               IS '�t�H�[�~�����E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�t�H�[�~�����E�v�Q             IS '�t�H�[�~�����E�v�Q'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�o�[�W����                     IS '�o�[�W����'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�X�P�[�����O��                 IS '�X�P�[�����O��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�X�e�[�^�X                     IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�X�e�[�^�X��                   IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.������                         IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.������_�P��                    IS '������_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���e��                         IS '���e��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���e��_�P��                    IS '���e��_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���x                           IS '���x'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�H��ŗL�L��                   IS '�H��ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���񐶎Y��                     IS '���񐶎Y��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�p�b�J�[                       IS '�p�b�J�['
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�p�b�J�[��                     IS '�p�b�J�[��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���Y�H��                       IS '���Y�H��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���Y�H�ꖼ                     IS '���Y�H�ꖼ'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�U�֔����i                     IS '�U�֔����i'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�U�֔����i��                   IS '�U�֔����i��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.��������v��                   IS '��������v��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.��������v�ۖ�                 IS '��������v�ۖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�����v�Z�v��                   IS '�����v�Z�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�����v�Z�v�ۖ�                 IS '�����v�Z�v�ۖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�I�����C���t���O               IS '�I�����C���t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�I�����C���t���O��             IS '�I�����C���t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���׃^�C�v                     IS '���׃^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���׃^�C�v��                   IS '���׃^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���הԍ�                       IS '���הԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�i�ڃR�[�h                     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�i�ږ�                         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�i�ڗ���                       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�i�ڋ敪                       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�i�ڋ敪��                     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�Q�R�[�h                       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.����                           IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�P��                           IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�����^�C�v                     IS '�����^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�����^�C�v��                   IS '�����^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���[�J�[                       IS '���[�J�['
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.���[�J�[��                     IS '���[�J�[��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�z����                         IS '�z����'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.��{����g�p��                 IS '��{����g�p��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.��{����g�p��_�P��            IS '��{����g�p��_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.��P��                       IS '��P��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�t�H�[�~����_����_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
