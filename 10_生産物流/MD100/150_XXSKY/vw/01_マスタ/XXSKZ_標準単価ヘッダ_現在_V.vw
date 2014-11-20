/*************************************************************************
 * 
 * View  Name      : XXSKZ_�W���P���w�b�__����_V
 * Description     : XXSKZ_�W���P���w�b�__����_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�W���P���w�b�__����_V
(
 ���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�t�уR�[�h
,�����R�[�h
,����於
,�H��R�[�h
,�H�ꖼ
,�x����R�[�h
,�x���於
,�ŗL�L��
,�v�Z�敪
,�v�Z�敪��
,�K�p�J�n��
,�K�p�I����
,���󍇌v
,�ύX�����t���O
,�E�v
,�w�b�_ID
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  XPCV.prod_class_code         --���i�敪
       ,XPCV.prod_class_name         --���i�敪��
       ,XICV.item_class_code         --�i�ڋ敪
       ,XICV.item_class_name         --�i�ڋ敪��
       ,XCCV.crowd_code              --�Q�R�[�h
       ,XPH.item_code                --�i�ڃR�[�h
       ,XIMV.item_name               --�i�ږ�
       ,XIMV.item_short_name         --�i�ڗ���
       ,XPH.futai_code               --�t�уR�[�h
       ,XPH.vendor_code              --�����R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVV_T.vendor_name            --����於
       ,(SELECT XVV_T.vendor_name
         FROM xxskz_vendors_v XVV_T  --�d������VIEW(����於�擾�p)
         WHERE XPH.vendor_id = XVV_T.vendor_id
        ) XVV_T_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XPH.factory_code             --�H��R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVSV.vendor_site_name        --�H�ꖼ
       ,(SELECT XVSV.vendor_site_name
         FROM xxskz_vendor_sites_v XVSV   --�d����T�C�g���VIEW
         WHERE XPH.factory_id = XVSV.vendor_site_id
        ) XVSV_vendor_site_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XPH.supply_to_code           --�x����R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVV_S.vendor_name            --�x���於
       ,(SELECT XVV_S.vendor_name
         FROM xxskz_vendors_v XVV_S  --�d������VIEW(�x���於�擾�p)
         WHERE XPH.supply_to_id = XVV_S.vendor_id
        ) XVV_S_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XPH.koyu_code                --�ŗL�L��
       ,XPH.calculate_type           --�v�Z�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV01.meaning
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01  --�N�C�b�N�R�[�h(�v�Z�敪��)
         WHERE FLV01.language    = 'JA'                    --����
           AND FLV01.lookup_type = 'XXWIP_CALCULATE_TYPE'  --�N�C�b�N�R�[�h�^�C�v
           AND FLV01.lookup_code = XPH.calculate_type      --�N�C�b�N�R�[�h
        ) calculate_type_name          --�v�Z�敪��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XPH.start_date_active        --�K�p�J�n��
       ,XPH.end_date_active          --�K�p�I����
       ,XPH.total_amount             --���󍇌v
       ,XPH.record_change_flg        --�ύX�����t���O
       ,XPH.description              --�E�v
       ,XPH.price_header_id          --�w�b�_ID
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_CB.user_name              --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE XPH.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XPH.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                     --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name              --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE XPH.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XPH.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                     --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name              --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
             ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE XPH.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  xxpo_price_headers    XPH    --�d���^�W���P���w�b�_�A�h�I��
       ,xxskz_prod_class_v    XPCV   --SKYLINK�p ���i�敪�擾VIEW
       ,xxskz_item_class_v    XICV   --SKYLINK�p �i�ڋ敪�擾VIEW
       ,xxskz_crowd_code_v    XCCV   --SKYLINK�p �S�R�[�h�擾VIEW
       ,xxskz_item_mst_v      XIMV   --OPM�i�ڏ��VIEW
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,xxsky_vendors_v       XVV_T  --�d������VIEW(����於�擾�p)
       --,xxsky_vendor_sites_v  XVSV   --�d����T�C�g���VIEW
       --,xxsky_vendors_v       XVV_S  --�d������VIEW(�x���於�擾�p)
       --,fnd_lookup_values     FLV01  --�N�C�b�N�R�[�h(�v�Z�敪��)
       --,fnd_user              FU_CB  --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       --,fnd_user              FU_LU  --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       --,fnd_user              FU_LL  --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       --,fnd_logins            FL_LL  --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  XPH.price_type   = '2' --�W��
   AND  XPH.item_id      = XPCV.item_id(+)
   AND  XPH.item_id      = XICV.item_id(+)
   AND  XPH.item_id      = XCCV.item_id(+)
   AND  XPH.item_id      = XIMV.item_id(+)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  XPH.vendor_id    = XVV_T.vendor_id(+)
   --AND  XPH.factory_id   = XVSV.vendor_site_id(+)
   --AND  XPH.supply_to_id = XVV_S.vendor_id(+)
   --AND  FLV01.language(+)    = 'JA'                    --����
   --AND  FLV01.lookup_type(+) = 'XXWIP_CALCULATE_TYPE'  --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV01.lookup_code(+) = XPH.calculate_type      --�N�C�b�N�R�[�h
   --AND  XPH.created_by        = FU_CB.user_id(+)
   --AND  XPH.last_updated_by   = FU_LU.user_id(+)
   --AND  XPH.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
   AND  XPH.start_date_active <= TRUNC(SYSDATE)
   AND  XPH.end_date_active   >= TRUNC(SYSDATE)
/
COMMENT ON TABLE APPS.XXSKZ_�W���P���w�b�__����_V IS 'SKYLINK�p�W���P���w�b�_�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�i�ڋ敪                       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�i�ڋ敪��                     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�Q�R�[�h                       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�i�ڃR�[�h                     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�i�ږ�                         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�i�ڗ���                       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�t�уR�[�h                     IS '�t�уR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�����R�[�h                   IS '�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.����於                       IS '����於'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�H��R�[�h                     IS '�H��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�H�ꖼ                         IS '�H�ꖼ'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�x����R�[�h                   IS '�x����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�x���於                       IS '�x���於'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�ŗL�L��                       IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�v�Z�敪                       IS '�v�Z�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�v�Z�敪��                     IS '�v�Z�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�K�p�J�n��                     IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�K�p�I����                     IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.���󍇌v                       IS '���󍇌v'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�ύX�����t���O                 IS '�ύX�����t���O'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�E�v                           IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�w�b�_ID                       IS '�w�b�_ID'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�W���P���w�b�__����_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
