CREATE OR REPLACE VIEW APPS.XXSKY_�d����}�X�^_��{_V
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
       ,XLV.location_name                --������
       ,XV.terms_date                    --�x�������ݒ��
       ,XV.payment_to                    --�x����
       ,XVV01.vendor_name                --�x���於
       ,XV.mediation                     --������
       ,XVV02.vendor_name                --�����Җ�
       ,PV.customer_num                  --�ڋq�R�[�h
       ,XCAV.party_name                  --�ڋq��
       ,PV.attribute3                    --���Y���я����^�C�v
       ,FLV01.meaning                    --���Y���я����^�C�v��
       ,PV.attribute5                    --�d����敪
       ,FLV02.meaning                    --�d����敪��
       ,PV.attribute2                    --��\�H��
       ,XVSV.vendor_site_name            --��\�H�ꖼ
       ,PV.attribute4                    --��\�[����
       ,XILV.description                 --��\�[���於
       ,PV.attribute7                    --�x�����i�\
       ,PV.attribute8                    --�֘A�����
       ,XVV03.vendor_name                --�֘A����於
       ,PV.attribute6                    --���l
       ,FU_CB.user_name                  --�쐬��
       ,TO_CHAR( XV.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�쐬��
       ,FU_LU.user_name                  --�ŏI�X�V��
       ,TO_CHAR( XV.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�ŏI�X�V��
       ,FU_LL.user_name                  --�ŏI�X�V���O�C��
  FROM  xxcmn_vendors           XV       --�d����A�h�I��
       ,po_vendors              PV       --�d����}�X�^
       ,xxsky_locations_v       XLV      --���Ə����VIEW
       ,xxsky_vendors_v         XVV01    --�d������VIEW(�x���於)
       ,xxsky_vendors_v         XVV02    --�d������VIEW(�����Җ�)
       ,xxsky_vendors_v         XVV03    --�d������VIEW(����於)
       ,xxsky_cust_accounts_v   XCAV     --�ڋq���VIEW(�ڋq��)
       ,xxsky_vendor_sites_v    XVSV     --�d����T�C�g���VIEW(��\�H�ꖼ)
       ,xxsky_item_locations_v  XILV     --OPM�ۊǏꏊ���VIEW(��\�[����)
       ,fnd_user                FU_CB    --���[�U�[�}�X�^(created_by���̎擾�p)
       ,fnd_user                FU_LU    --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       ,fnd_user                FU_LL    --���[�U�[�}�X�^(last_update_login���̎擾�p)
       ,fnd_logins              FL_LL    --���O�C���}�X�^(last_update_login���̎擾�p)
       ,fnd_lookup_values       FLV01    --�N�C�b�N�R�[�h(���Y���я����^�C�v��)
       ,fnd_lookup_values       FLV02    --�N�C�b�N�R�[�h(�d����敪��)
 WHERE  XV.vendor_id         = PV.vendor_id
   AND  PV.end_date_active   IS NULL
   AND  XV.department        = XLV.location_code(+)
   AND  XV.payment_to        = XVV01.segment1(+)
   AND  XV.mediation         = XVV02.segment1(+)  
   AND  PV.customer_num      = XCAV.party_number(+)
   AND  PV.vendor_id         = XVSV.vendor_id(+)
   AND  PV.attribute2        = XVSV.vendor_site_code(+)
   AND  PV.attribute4        = XILV.segment1(+)
   AND  PV.attribute8        = XVV03.segment1(+)
   AND  XV.created_by        = FU_CB.user_id(+)
   AND  XV.last_updated_by   = FU_LU.user_id(+)
   AND  XV.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id        = FU_LL.user_id(+)
   AND  FLV01.language(+)    = 'JA'                        --����
   AND  FLV01.lookup_type(+) = 'XXCMN_PURCHASING_FLAG'     --�N�C�b�N�R�[�h�^�C�v
   AND  FLV01.lookup_code(+) = PV.attribute3               --�N�C�b�N�R�[�h
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_VENDOR_CLASS'
   AND  FLV02.lookup_code(+) = PV.attribute5
/
COMMENT ON TABLE APPS.XXSKY_�d����}�X�^_��{_V IS 'SKYLINK�p�d����}�X�^�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�d����R�[�h         IS '�d����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�d���於             IS '�d���於'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�d���旪��           IS '�d���旪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�d����J�i��         IS '�d����J�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�K�p�J�n��           IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�K�p�I����           IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�X�֔ԍ�             IS '�X�֔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�Z���P               IS '�Z���P'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�Z���Q               IS '�Z���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�d�b�ԍ�             IS '�d�b�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.FAX�ԍ�              IS 'FAX�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.����                 IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.������               IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�x�������ݒ��       IS '�x�������ݒ��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�x����               IS '�x����'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�x���於             IS '�x���於'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.������               IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�����Җ�             IS '�����Җ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�ڋq�R�[�h           IS '�ڋq�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�ڋq��               IS '�ڋq��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.���Y���я����^�C�v   IS '���Y���я����^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.���Y���я����^�C�v�� IS '���Y���я����^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�d����敪           IS '�d����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�d����敪��         IS '�d����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.��\�H��             IS '��\�H��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.��\�H�ꖼ           IS '��\�H�ꖼ'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.��\�[����           IS '��\�[����'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.��\�[���於         IS '��\�[���於'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�x�����i�\           IS '�x�����i�\'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�֘A�����           IS '�֘A�����'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�֘A����於         IS '�֘A����於'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.���l                 IS '���l'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�쐬��               IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�쐬��               IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�ŏI�X�V��           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�ŏI�X�V��           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d����}�X�^_��{_V.�ŏI�X�V���O�C��     IS '�ŏI�X�V���O�C��'
/