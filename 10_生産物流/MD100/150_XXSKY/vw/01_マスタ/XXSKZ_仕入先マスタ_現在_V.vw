/*************************************************************************
 * 
 * View  Name      : XXSKZ_�d����}�X�^_����_V
 * Description     : XXSKZ_�d����}�X�^_����_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�d����}�X�^_����_V
(
 �d����R�[�h
,�d���於
,�d���旪��
,�d����J�i��
,�K�p�J�n��
,�K�p�I����
,�X�֔ԍ�
,�Z���P
,�Z���Q
,�d�b�ԍ�
,FAX�ԍ�
,����
,������
,�x�������ݒ��
,�x����
,�x���於
,������
,�����Җ�
,�ڋq�R�[�h
,�ڋq��
,���Y���я����^�C�v
,���Y���я����^�C�v��
,�d����敪
,�d����敪��
,��\�H��
,��\�H�ꖼ
,��\�[����
,��\�[���於
,�x�����i�\
,�֘A�����
,�֘A����於
,���l
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  
        PV.segment1                      --�d����R�[�h
       ,XV.vendor_name                   --�d���於
       ,XV.vendor_short_name             --�d���旪��
       ,XV.vendor_name_alt               --�d����J�i��
       ,XV.start_date_active             --�K�p�J�n��
       ,XV.end_date_active               --�K�p�I����
       ,XV.zip                           --�X�֔ԍ�
       ,XV.address_line1                 --�Z���P
       ,XV.address_line2                 --�Z���Q
       ,XV.phone                         --�d�b�ԍ�
       ,XV.fax                           --FAX�ԍ�
       ,XV.department                    --����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XLV.location_name                --������
       ,(SELECT XLV.location_name
         FROM xxskz_locations_v XLV      --���Ə����VIEW
         WHERE XV.department = XLV.location_code
        ) XLV_location_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XV.terms_date                    --�x�������ݒ��
       ,XV.payment_to                    --�x����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVV01.vendor_name                --�x���於
       ,(SELECT XVV01.vendor_name
         FROM xxskz_vendors_v XVV01    --�d������VIEW(�x���於)
         WHERE XV.payment_to = XVV01.segment1
        ) XVV01_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XV.mediation                     --������
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVV02.vendor_name                --�����Җ�
       ,(SELECT XVV02.vendor_name
         FROM xxskz_vendors_v XVV02    --�d������VIEW(�����Җ�)
         WHERE XV.mediation = XVV02.segment1
        ) XVV02_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,PV.customer_num                  --�ڋq�R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XCAV.party_name                  --�ڋq��
       ,(SELECT XCAV.party_name
         FROM xxskz_cust_accounts_v XCAV     --�ڋq���VIEW(�ڋq��)
         WHERE PV.customer_num = XCAV.party_number
        ) XCAV_party_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,PV.attribute3                    --���Y���я����^�C�v
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV01.meaning                    --���Y���я����^�C�v��
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01    --�N�C�b�N�R�[�h(���Y���я����^�C�v��)
         WHERE FLV01.language    = 'JA'                        --����
           AND FLV01.lookup_type = 'XXCMN_PURCHASING_FLAG'     --�N�C�b�N�R�[�h�^�C�v
           AND FLV01.lookup_code = PV.attribute3               --�N�C�b�N�R�[�h
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,PV.attribute5                    --�d����敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV02.meaning                    --�d����敪��
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02    --�N�C�b�N�R�[�h(�d����敪��)
         WHERE FLV02.language    = 'JA'
           AND FLV02.lookup_type = 'XXCMN_VENDOR_CLASS'
           AND FLV02.lookup_code = PV.attribute5
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,PV.attribute2                    --��\�H��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVSV.vendor_site_name            --��\�H�ꖼ
       ,(SELECT XVSV.vendor_site_name
         FROM xxskz_vendor_sites_v XVSV     --�d����T�C�g���VIEW(��\�H�ꖼ)
         WHERE PV.vendor_id  = XVSV.vendor_id
           AND PV.attribute2 = XVSV.vendor_site_code
        ) XVSV_vendor_site_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,PV.attribute4                    --��\�[����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XILV.description                 --��\�[���於
       ,(SELECT XILV.description
         FROM xxskz_item_locations_v XILV     --OPM�ۊǏꏊ���VIEW(��\�[����)
         WHERE PV.attribute4 = XILV.segment1
        ) XILV_description
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,PV.attribute7                    --�x�����i�\
       ,PV.attribute8                    --�֘A�����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVV03.vendor_name                --�֘A����於
       ,(SELECT XVV03.vendor_name
         FROM xxskz_vendors_v XVV03    --�d������VIEW(����於)
         WHERE PV.attribute8 = XVV03.segment1
        ) XVV03_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,PV.attribute6                    --���l
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_CB.user_name                  --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE XV.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XV.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name                  --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE XV.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XV.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name                  --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE XV.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  xxcmn_vendors           XV       --�d����A�h�I��
       ,po_vendors              PV       --�d����}�X�^
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,xxskz_locations_v       XLV      --���Ə����VIEW
       --,xxskz_vendors_v         XVV01    --�d������VIEW(�x���於)
       --,xxskz_vendors_v         XVV02    --�d������VIEW(�����Җ�)
       --,xxskz_vendors_v         XVV03    --�d������VIEW(����於)
       --,xxskz_cust_accounts_v   XCAV     --�ڋq���VIEW(�ڋq��)
       --,xxskz_vendor_sites_v    XVSV     --�d����T�C�g���VIEW(��\�H�ꖼ)
       --,xxskz_item_locations_v  XILV     --OPM�ۊǏꏊ���VIEW(��\�[����)
       --,fnd_user                FU_CB    --���[�U�[�}�X�^(created_by���̎擾�p)
       --,fnd_user                FU_LU    --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       --,fnd_user                FU_LL    --���[�U�[�}�X�^(last_update_login���̎擾�p)
       --,fnd_logins              FL_LL    --���O�C���}�X�^(last_update_login���̎擾�p)
       --,fnd_lookup_values       FLV01    --�N�C�b�N�R�[�h(���Y���я����^�C�v��)
       --,fnd_lookup_values       FLV02    --�N�C�b�N�R�[�h(�d����敪��)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  XV.vendor_id         = PV.vendor_id
   AND  PV.end_date_active   IS NULL
   AND  XV.start_date_active <= TRUNC(SYSDATE)
   AND  XV.end_date_active   >= TRUNC(SYSDATE)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  XV.department        = XLV.location_code(+)
   --AND  XV.payment_to        = XVV01.segment1(+)
   --AND  XV.mediation         = XVV02.segment1(+)  
   --AND  PV.customer_num      = XCAV.party_number(+)
   --AND  PV.vendor_id         = XVSV.vendor_id(+)
   --AND  PV.attribute2        = XVSV.vendor_site_code(+)
   --AND  PV.attribute4        = XILV.segment1(+)
   --AND  PV.attribute8        = XVV03.segment1(+)
   --AND  XV.created_by        = FU_CB.user_id(+)
   --AND  XV.last_updated_by   = FU_LU.user_id(+)
   --AND  XV.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id        = FU_LL.user_id(+)
   --AND  FLV01.language(+)    = 'JA'                        --����
   --AND  FLV01.lookup_type(+) = 'XXCMN_PURCHASING_FLAG'     --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV01.lookup_code(+) = PV.attribute3               --�N�C�b�N�R�[�h
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_VENDOR_CLASS'
   --AND  FLV02.lookup_code(+) = PV.attribute5
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKZ_�d����}�X�^_����_V IS 'SKYLINK�p�d����}�X�^�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�d����R�[�h         IS '�d����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�d���於             IS '�d���於'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�d���旪��           IS '�d���旪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�d����J�i��         IS '�d����J�i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�K�p�J�n��           IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�K�p�I����           IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�X�֔ԍ�             IS '�X�֔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�Z���P               IS '�Z���P'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�Z���Q               IS '�Z���Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�d�b�ԍ�             IS '�d�b�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.FAX�ԍ�              IS 'FAX�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.����                 IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.������               IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�x�������ݒ��       IS '�x�������ݒ��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�x����               IS '�x����'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�x���於             IS '�x���於'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.������               IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�����Җ�             IS '�����Җ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�ڋq�R�[�h           IS '�ڋq�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�ڋq��               IS '�ڋq��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.���Y���я����^�C�v   IS '���Y���я����^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.���Y���я����^�C�v�� IS '���Y���я����^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�d����敪           IS '�d����敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�d����敪��         IS '�d����敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.��\�H��             IS '��\�H��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.��\�H�ꖼ           IS '��\�H�ꖼ'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.��\�[����           IS '��\�[����'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.��\�[���於         IS '��\�[���於'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�x�����i�\           IS '�x�����i�\'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�֘A�����           IS '�֘A�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�֘A����於         IS '�֘A����於'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.���l                 IS '���l'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�쐬��               IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�쐬��               IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�ŏI�X�V��           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�ŏI�X�V��           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d����}�X�^_����_V.�ŏI�X�V���O�C��     IS '�ŏI�X�V���O�C��'
/