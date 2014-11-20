CREATE OR REPLACE VIEW APPS.XXSKY_�d����T�C�g_����_V
(
 �d����R�[�h
,�d���於
,�d����T�C�g�R�[�h
,�d����T�C�g��
,�d����T�C�g����
,�d����T�C�g�J�i��
,�K�p�J�n��
,�K�p�I����
,�X�֔ԍ�
,�Z���P
,�Z���Q
,�d�b�ԍ�
,FAX�ԍ�
,�����݌ɓ��ɐ�
,�����݌ɓ��ɐ於
,�����[����
,�����[���於
,���l
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  
        XVV.segment1                     --�d����R�[�h
       ,XVV.vendor_name                  --�d���於
       ,PVSA.vendor_site_code            --�d����T�C�g�R�[�h
       ,XVSA.vendor_site_name            --�d����T�C�g��
       ,XVSA.vendor_site_short_name      --�d����T�C�g����
       ,XVSA.vendor_site_name_alt        --�d����T�C�g�J�i��
       ,XVSA.start_date_active           --�K�p�J�n��
       ,XVSA.end_date_active             --�K�p�I����
       ,XVSA.zip                         --�X�֔ԍ�
       ,XVSA.address_line1               --�Z���P
       ,XVSA.address_line2               --�Z���Q
       ,XVSA.phone                       --�d�b�ԍ�
       ,XVSA.fax                         --FAX�ԍ�
       ,PVSA.attribute1                  --�����݌ɓ��ɐ�
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XILV01.description               --�����݌ɓ��ɐ於
       ,(SELECT XILV01.description
         FROM xxsky_item_locations_v XILV01   --OPM�ۊǏꏊ���VIEW(�����݌ɓ��ɐ於)
         WHERE PVSA.attribute1 = XILV01.segment1
        ) XILV01_description
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,PVSA.attribute2                  --�����[����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XILV02.description               --�����[���於
       ,(SELECT XILV02.description
         FROM xxsky_item_locations_v XILV02   --OPM�ۊǏꏊ���VIEW(�����[���於)
         WHERE PVSA.attribute2 = XILV02.segment1
        ) XILV02_description
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,PVSA.attribute4                  --���l
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_CB.user_name                  --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE XVSA.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XVSA.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name                  --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE XVSA.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XVSA.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name                  --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE XVSA.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  xxcmn_vendor_sites_all  XVSA     --�d����T�C�g�A�h�I��
       ,po_vendor_sites_all     PVSA     --�d����T�C�g
       ,xxsky_vendors_v         XVV      --�d������VIEW
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,xxsky_item_locations_v  XILV01   --OPM�ۊǏꏊ���VIEW(�����݌ɓ��ɐ於)
       --,xxsky_item_locations_v  XILV02   --OPM�ۊǏꏊ���VIEW(�����[���於)
       --,fnd_user                FU_CB    --���[�U�[�}�X�^(created_by���̎擾�p)
       --,fnd_user                FU_LU    --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       --,fnd_user                FU_LL    --���[�U�[�}�X�^(last_update_login���̎擾�p)
       --,fnd_logins              FL_LL    --���O�C���}�X�^(last_update_login���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  XVSA.vendor_id         = PVSA.vendor_id
   AND  XVSA.vendor_site_id    = PVSA.vendor_site_id
   AND  PVSA.org_id            = FND_PROFILE.VALUE('ORG_ID')
   AND  PVSA.inactive_date     IS NULL
   AND  XVSA.start_date_active <= TRUNC(SYSDATE)
   AND  XVSA.end_date_active   >= TRUNC(SYSDATE)
   AND  XVSA.vendor_id         = XVV.vendor_id(+)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  PVSA.attribute1        = XILV01.segment1(+)
   --AND  PVSA.attribute2        = XILV02.segment1(+)
   --AND  XVSA.created_by        = FU_CB.user_id(+)
   --AND  XVSA.last_updated_by   = FU_LU.user_id(+)
   --AND  XVSA.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id          = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKY_�d����T�C�g_����_V IS 'SKYLINK�p�d����T�C�g�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�d����R�[�h       IS '�d����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�d���於           IS '�d���於'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�d����T�C�g�R�[�h IS '�d����T�C�g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�d����T�C�g��     IS '�d����T�C�g��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�d����T�C�g����   IS '�d����T�C�g����'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�d����T�C�g�J�i�� IS '�d����T�C�g�J�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�K�p�J�n��         IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�K�p�I����         IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�X�֔ԍ�           IS '�X�֔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�Z���P             IS '�Z���P'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�Z���Q             IS '�Z���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�d�b�ԍ�           IS '�d�b�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.FAX�ԍ�            IS 'FAX�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�����݌ɓ��ɐ�   IS '�����݌ɓ��ɐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�����݌ɓ��ɐ於 IS '�����݌ɓ��ɐ於'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�����[����         IS '�����[����'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�����[���於       IS '�����[���於'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.���l               IS '���l'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����T�C�g_����_V.�ŏI�X�V���O�C��   IS '�ŏI�X�V���O�C��'
/
