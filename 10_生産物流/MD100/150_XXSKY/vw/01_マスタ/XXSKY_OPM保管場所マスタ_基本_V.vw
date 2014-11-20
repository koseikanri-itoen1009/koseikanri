CREATE OR REPLACE VIEW APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V
(
 �q�ɃR�[�h
,�q�ɖ�
,�v�����g�R�[�h
,�v�����g��
,�g�D�L���J�n��
,�g�D�L���I����
,�����݌ɊǗ��Ώ�
,�����݌ɊǗ��Ώۖ�
,�ۊǑq�ɃR�[�h
,�ۊǑq�ɖ�
,�ۊǑq�ɗ���
,�ۊǑq�ɖ�����
,�ۊǏꏊ�R�[�h
,�ۊǏꏊ��
,���O�q�ɋ敪
,���O�q�ɋ敪��
,�����u���b�N
,�����u���b�N��
,��\�q��
,��\�q�ɖ�
,��\�q�ɗ���
,��\�^�����
,��\�^����Ж�
,�d�n�r�Ǘ��敪
,�d�n�r�Ǘ��敪��
,�d�n�r����
,�d�n�r���於
,�q�ɊǗ�����
,�q�ɊǗ�������
,��v�ۊǑq�ɃR�[�h
,��v�ۊǑq�ɖ�
,�d����R�[�h
,�d���於
,�d����T�C�g�R�[�h
,�d����T�C�g��
,�h�����N��J�����_
,�h�����N��J�����_��
,���[�t��J�����_
,���[�t��J�����_��
,�o�׈����Ώۃt���O
,�o�׈����Ώۃt���O��
,�c_�P�q�Ƀt���O
,�c_�P�q�Ƀt���O��
,�����q�ɋ敪
,�����q�ɋ敪��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  
        IWM.whse_code                   --�q�ɃR�[�h
       ,IWM.whse_name                   --�q�ɖ�
       ,IWM.orgn_code                   --�v�����g�R�[�h
       ,SOMT.orgn_name                  --�v�����g��
       ,HAOU.date_from                  --�g�D�L���J�n��
       ,HAOU.date_to                    --�g�D�L���I����
       ,IWM.attribute1                  --�����݌ɊǗ��Ώ�
       ,FLV01.meaning                   --�����݌ɊǗ��Ώۖ�
       ,MIL.segment1                    --�ۊǑq�ɃR�[�h
       ,MIL.description                 --�ۊǑq�ɖ�
       ,MIL.attribute12                 --�ۊǑq�ɗ���
       ,MIL.disable_date                --�ۊǑq�ɖ�����
       ,MIL.subinventory_code           --�ۊǏꏊ�R�[�h
       ,IWM02.whse_name                 --�ۊǏꏊ��
       ,MIL.attribute9                  --���O�q�ɋ敪
       ,FLV02.meaning                   --���O�q�ɋ敪��
       ,MIL.attribute6                  --�����u���b�N
       ,FLV03.meaning                   --�����u���b�N��
       ,MIL.attribute5                  --��\�q��
       ,XILV01.description              --��\�q�ɖ�
       ,XILV01.short_name               --��\�q�ɗ���
       ,MIL.attribute7                  --��\�^�����
       ,XCV.party_name                  --��\�^����Ж�
       ,DECODE(MIL.ATTRIBUTE2, NULL, '0', '1')
        attribute2                      --�d�n�r�Ǘ��敪
       ,FLV04.meaning                   --�d�n�r�Ǘ��敪��
       ,MIL.attribute2                  --�d�n�r����
       ,XILV02.description              --�d�n�r���於
       ,MIL.attribute3                  --�q�ɊǗ�����
       ,XLV.location_name               --�q�ɊǗ�������
       ,MIL.attribute8                  --��v�ۊǑq�ɃR�[�h
       ,XILV03.description              --��v�ۊǑq�ɖ�
       ,MIL.attribute13                 --�d����R�[�h
       ,XVV.vendor_name                 --�d���於
       ,MIL.attribute1                  --�d����T�C�g�R�[�h
       ,XVSV.vendor_site_name           --�d����T�C�g��
       ,MIL.attribute10                 --�h�����N��J�����_
       ,MSH01.calendar_desc             --�h�����N��J�����_��
       ,MIL.attribute14                 --���[�t��J�����_
       ,MSH02.calendar_desc             --���[�t��J�����_��
       ,MIL.attribute4                  --�o�׈����Ώۃt���O
       ,FLV05.meaning                   --�o�׈����Ώۃt���O��
       ,MIL.attribute11                 --�c�{�P�q�Ƀt���O
       ,FLV06.meaning                   --�c�{�P�q�Ƀt���O��
       ,MIL.attribute15                 --�����q�ɋ敪
       ,FLV07.meaning                   --�����q�ɋ敪��
       ,FU_CB.user_name                  --�쐬��
       ,TO_CHAR( MIL.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�쐬��
       ,FU_LU.user_name                  --�ŏI�X�V��
       ,TO_CHAR( MIL.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�ŏI�X�V��
       ,FU_LL.user_name                  --�ŏI�X�V���O�C��
  FROM  ic_whse_mst               IWM    --OPM�q�Ƀ}�X�^
       ,ic_whse_mst               IWM02  --OPM�q�Ƀ}�X�^(�ۊǏꏊ)
       ,hr_all_organization_units HAOU   --�q��
       ,mtl_item_locations        MIL    --�q��
       ,sy_orgn_mst_tl            SOMT   --�v�����g
       ,xxsky_item_locations_v    XILV01 --OPM�ۊǏꏊ���VIEW(��\�q�ɖ�)
       ,xxsky_item_locations_v    XILV02 --OPM�ۊǏꏊ���VIEW(�d�n�r���於)
       ,xxsky_item_locations_v    XILV03 --OPM�ۊǏꏊ���VIEW(��v�ۊǑq��)
       ,xxsky_carriers_v          XCV    --�^���Ǝҏ��VIEW
       ,xxsky_locations_v         XLV    --���Ə����VIEW(�q�ɊǗ�����)
       ,xxsky_vendors_v           XVV    --�d������VIEW(�d����)
       ,xxsky_vendor_sites_v      XVSV   --�d����T�C�g���VIEW(�d����T�C�g��)
       ,mr_shcl_hdr               MSH01  --��J�����_(�h�����N)
       ,mr_shcl_hdr               MSH02  --��J�����_(���[�t)
       ,fnd_user                  FU_CB  --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                  FU_LU  --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                  FU_LL  --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                FL_LL  --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_lookup_values         FLV01  --�N�C�b�N�R�[�h(�����݌ɊǗ��Ώۖ�)
       ,fnd_lookup_values         FLV02  --�N�C�b�N�R�[�h(���O�q�ɋ敪��)
       ,fnd_lookup_values         FLV03  --�N�C�b�N�R�[�h(�����u���b�N��)
       ,fnd_lookup_values         FLV04  --�N�C�b�N�R�[�h(�d�n�r�Ǘ��敪��)
       ,fnd_lookup_values         FLV05  --�N�C�b�N�R�[�h(�o�׈����Ώۃt���O��)
       ,fnd_lookup_values         FLV06  --�N�C�b�N�R�[�h(�c�{�P�q�Ƀt���O��)
       ,fnd_lookup_values         FLV07  --�N�C�b�N�R�[�h(�����q�ɋ敪��)
 WHERE  IWM.mtl_organization_id = HAOU.organization_id
   AND  HAOU.organization_id = MIL.organization_id
   AND  MIL.disable_date IS NULL
   AND  IWM.orgn_code = SOMT.orgn_code(+)
   AND  SOMT.language(+) = 'JA'
   AND  MIL.subinventory_code = IWM02.whse_code(+)
   AND  MIL.attribute5 = XILV01.segment1(+)
   AND  MIL.attribute7 = XCV.freight_code(+)
   AND  MIL.attribute2 = XILV02.segment1(+)
   AND  MIL.attribute3 = XLV.location_code(+)
   AND  MIL.attribute8 = XILV03.segment1(+)
   AND  MIL.attribute13 = XVV.segment1(+)
   AND  MIL.attribute1 =  XVSV.vendor_site_code(+)
   AND  MIL.attribute10 = MSH01.calendar_no(+)
   AND  MIL.attribute14 = MSH02.calendar_no(+)
   AND  MIL.created_by        = FU_CB.user_id(+)
   AND  MIL.last_updated_by   = FU_LU.user_id(+)
   AND  MIL.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id         = FU_LL.user_id(+)
   AND  FLV01.language(+)    = 'JA'                        --����
   AND  FLV01.lookup_type(+) = 'XXCMN_INV_CTRL'            --�N�C�b�N�R�[�h�^�C�v
   AND  FLV01.lookup_code(+) = IWM.attribute1              --�N�C�b�N�R�[�h
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_LOCT_IN_OUT'
   AND  FLV02.lookup_code(+) = MIL.attribute9
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_D12'
   AND  FLV03.lookup_code(+) = MIL.attribute6
   AND  FLV04.language(+)    = 'JA'
   AND  FLV04.lookup_type(+) = 'XXCMN_MANAGE_EOS'
   AND  FLV04.lookup_code(+) = DECODE(MIL.ATTRIBUTE2, NULL, '0', '1')
   AND  FLV05.language(+)    = 'JA'
   AND  FLV05.lookup_type(+) = 'XXCMN_ATP_FLAG'
   AND  FLV05.lookup_code(+) = MIL.attribute4
   AND  FLV06.language(+)    = 'JA'
   AND  FLV06.lookup_type(+) = 'XXCMN_D+1_LOCT_FLAG'
   AND  FLV06.lookup_code(+) = MIL.attribute11
   AND  FLV07.language(+)    = 'JA'
   AND  FLV07.lookup_type(+) = 'XXCMN_DROP_SHIP_LOCT_CLASS'
   AND  FLV07.lookup_code(+) = MIL.attribute15
/
COMMENT ON TABLE APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V IS 'SKYLINK�pOPM�ۊǏꏊ�}�X�^�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�q�ɃR�[�h                IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�q�ɖ�                    IS '�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�v�����g�R�[�h            IS '�v�����g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�v�����g��                IS '�v�����g��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�g�D�L���J�n��            IS '�g�D�L���J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�g�D�L���I����            IS '�g�D�L���I����'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�����݌ɊǗ��Ώ�        IS '�����݌ɊǗ��Ώ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�����݌ɊǗ��Ώۖ�      IS '�����݌ɊǗ��Ώۖ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�ۊǑq�ɃR�[�h            IS '�ۊǑq�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�ۊǑq�ɖ�                IS '�ۊǑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�ۊǑq�ɗ���              IS '�ۊǑq�ɗ���'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�ۊǑq�ɖ�����            IS '�ۊǑq�ɖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�ۊǏꏊ�R�[�h            IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�ۊǏꏊ��                IS '�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.���O�q�ɋ敪              IS '���O�q�ɋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.���O�q�ɋ敪��            IS '���O�q�ɋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�����u���b�N              IS '�����u���b�N'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�����u���b�N��            IS '�����u���b�N��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.��\�q��                  IS '��\�q��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.��\�q�ɖ�                IS '��\�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.��\�q�ɗ���              IS '��\�q�ɗ���'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.��\�^�����              IS '��\�^�����'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.��\�^����Ж�            IS '��\�^����Ж�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�d�n�r�Ǘ��敪            IS '�d�n�r�Ǘ��敪'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�d�n�r�Ǘ��敪��          IS '�d�n�r�Ǘ��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�d�n�r����                IS '�d�n�r����'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�d�n�r���於              IS '�d�n�r���於'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�q�ɊǗ�����              IS '�q�ɊǗ�����'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�q�ɊǗ�������            IS '�q�ɊǗ�������'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.��v�ۊǑq�ɃR�[�h        IS '��v�ۊǑq�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.��v�ۊǑq�ɖ�            IS '��v�ۊǑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�d����R�[�h              IS '�d����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�d���於                  IS '�d���於'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�d����T�C�g�R�[�h        IS '�d����T�C�g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�d����T�C�g��            IS '�d����T�C�g��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�h�����N��J�����_      IS '�h�����N��J�����_'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�h�����N��J�����_��    IS '�h�����N��J�����_��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.���[�t��J�����_        IS '���[�t��J�����_'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.���[�t��J�����_��      IS '���[�t��J�����_��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�o�׈����Ώۃt���O        IS '�o�׈����Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�o�׈����Ώۃt���O��      IS '�o�׈����Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�c_�P�q�Ƀt���O           IS '�c�{�P�q�Ƀt���O'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�c_�P�q�Ƀt���O��         IS '�c�{�P�q�Ƀt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�����q�ɋ敪              IS '�����q�ɋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�����q�ɋ敪��            IS '�����q�ɋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�쐬��                    IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�쐬��                    IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�ŏI�X�V��                IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�ŏI�X�V��                IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_��{_V.�ŏI�X�V���O�C��          IS '�ŏI�X�V���O�C��'
/