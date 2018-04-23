CREATE OR REPLACE VIEW APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V
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
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,SOMT.orgn_name                  --�v�����g��
       ,(SELECT SOMT.orgn_name
         FROM sy_orgn_mst_tl SOMT   --�v�����g
         WHERE IWM.orgn_code = SOMT.orgn_code
         AND  SOMT.language  = 'JA'
        ) SOMT_orgn_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,HAOU.date_from                  --�g�D�L���J�n��
       ,HAOU.date_to                    --�g�D�L���I����
       ,IWM.attribute1                  --�����݌ɊǗ��Ώ�
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV01.meaning                   --�����݌ɊǗ��Ώۖ�
       ,(SELECT FLV01.meaning
         FROM  fnd_lookup_values FLV01                           --�N�C�b�N�R�[�h(�����݌ɊǗ��Ώۖ�)
         WHERE  FLV01.language     = 'JA'                        --����
         AND  FLV01.lookup_type    = 'XXCMN_INV_CTRL'            --�N�C�b�N�R�[�h�^�C�v
         AND  FLV01.lookup_code    = IWM.attribute1              --�N�C�b�N�R�[�h
        ) FLV01_meaning                       --�����݌ɊǗ��Ώۖ�
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.segment1                    --�ۊǑq�ɃR�[�h
       ,MIL.description                 --�ۊǑq�ɖ�
       ,MIL.attribute12                 --�ۊǑq�ɗ���
       ,MIL.disable_date                --�ۊǑq�ɖ�����
       ,MIL.subinventory_code           --�ۊǏꏊ�R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,IWM02.whse_name                 --�ۊǏꏊ��
       ,(SELECT IWM02.whse_name
         FROM ic_whse_mst IWM02  --OPM�q�Ƀ}�X�^(�ۊǏꏊ)
         WHERE MIL.subinventory_code = IWM02.whse_code
        ) IWM02_whse_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute9                  --���O�q�ɋ敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV02.meaning                   --���O�q�ɋ敪��
       ,(SELECT FLV02.meaning 
         FROM fnd_lookup_values FLV02  --�N�C�b�N�R�[�h(���O�q�ɋ敪��)
         WHERE  FLV02.language  = 'JA'
         AND  FLV02.lookup_type = 'XXCMN_LOCT_IN_OUT'
         AND  FLV02.lookup_code = MIL.attribute9
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute6                  --�����u���b�N
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV03.meaning                   --�����u���b�N��
       ,(SELECT FLV03.meaning 
         FROM fnd_lookup_values FLV03  --�N�C�b�N�R�[�h(�����u���b�N��)
         WHERE FLV03.language   = 'JA'
         AND  FLV03.lookup_type = 'XXCMN_D12'
         AND  FLV03.lookup_code = MIL.attribute6
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute5                  --��\�q��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XILV01.description              --��\�q�ɖ�
       ,(SELECT XILV01.description
         FROM xxsky_item_locations_v XILV01 --OPM�ۊǏꏊ���VIEW(��\�q�ɖ�)
         WHERE MIL.attribute5 = XILV01.segment1
        ) XILV01_description
       --,XILV01.short_name               --��\�q�ɗ���
       ,(SELECT XILV01.short_name
         FROM xxsky_item_locations_v XILV01 --OPM�ۊǏꏊ���VIEW(��\�q�ɖ�)
         WHERE MIL.attribute5 = XILV01.segment1
        ) XILV01_short_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute7                  --��\�^�����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XCV.party_name                  --��\�^����Ж�
       ,(SELECT XCV.party_name
         FROM xxsky_carriers_v XCV    --�^���Ǝҏ��VIEW
         WHERE MIL.attribute7 = XCV.freight_code
        ) XCV_party_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,DECODE(MIL.ATTRIBUTE2, NULL, '0', '1')
        attribute2                      --�d�n�r�Ǘ��敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV04.meaning                   --�d�n�r�Ǘ��敪��
       ,(SELECT FLV04.meaning 
         FROM fnd_lookup_values FLV04  --�N�C�b�N�R�[�h(�d�n�r�Ǘ��敪��)
         WHERE FLV04.language   = 'JA'
         AND  FLV04.lookup_type = 'XXCMN_MANAGE_EOS'
         AND  FLV04.lookup_code = DECODE(MIL.ATTRIBUTE2, NULL, '0', '1')
        ) FLV04_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute2                  --�d�n�r����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XILV02.description              --�d�n�r���於
       ,(SELECT XILV02.description
         FROM xxsky_item_locations_v XILV02 --OPM�ۊǏꏊ���VIEW(�d�n�r���於)
         WHERE MIL.attribute2 = XILV02.segment1
        ) XILV02_description
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute3                  --�q�ɊǗ�����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XLV.location_name               --�q�ɊǗ�������
       ,(SELECT XLV.location_name
         FROM xxsky_locations_v XLV    --���Ə����VIEW(�q�ɊǗ�����)
         WHERE MIL.attribute3 = XLV.location_code
        ) XLV_location_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute8                  --��v�ۊǑq�ɃR�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XILV03.description              --��v�ۊǑq�ɖ�
       ,(SELECT XILV03.description
         FROM xxsky_item_locations_v XILV03 --OPM�ۊǏꏊ���VIEW(��v�ۊǑq��)
         WHERE MIL.attribute8 = XILV03.segment1
        ) XILV03_description
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute13                 --�d����R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVV.vendor_name                 --�d���於
       ,(SELECT XVV.vendor_name
         FROM xxsky_vendors_v XVV    --�d������VIEW(�d����)
         WHERE MIL.attribute13 = XVV.segment1
        ) XVV_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute1                  --�d����T�C�g�R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XVSV.vendor_site_name           --�d����T�C�g��
       ,(SELECT XVSV.vendor_site_name
         FROM xxsky_vendor_sites_v XVSV   --�d����T�C�g���VIEW(�d����T�C�g��)
         WHERE MIL.attribute1 =  XVSV.vendor_site_code
        ) XVSV_vendor_site_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute10                 --�h�����N��J�����_
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,MSH01.calendar_desc             --�h�����N��J�����_��
       ,(SELECT MSH01.calendar_desc
         FROM mr_shcl_hdr MSH01  --��J�����_(�h�����N)
         WHERE MIL.attribute10 = MSH01.calendar_no
        ) MSH01_calendar_desc
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute14                 --���[�t��J�����_
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,MSH02.calendar_desc             --���[�t��J�����_��
       ,(SELECT MSH02.calendar_desc
         FROM mr_shcl_hdr MSH02  --��J�����_(���[�t)
         WHERE MIL.attribute14 = MSH02.calendar_no
        ) MSH02_calendar_desc
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute4                  --�o�׈����Ώۃt���O
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV05.meaning                   --�o�׈����Ώۃt���O��
       ,(SELECT FLV05.meaning 
         FROM fnd_lookup_values FLV05  --�N�C�b�N�R�[�h(�o�׈����Ώۃt���O��)
         WHERE FLV05.language   = 'JA'
         AND  FLV05.lookup_type = 'XXCMN_ATP_FLAG'
         AND  FLV05.lookup_code = MIL.attribute4
        ) FLV05_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute11                 --�c�{�P�q�Ƀt���O
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV06.meaning                   --�c�{�P�q�Ƀt���O��
       ,(SELECT FLV06.meaning 
         FROM fnd_lookup_values FLV06  --�N�C�b�N�R�[�h(�c�{�P�q�Ƀt���O��)
         WHERE FLV06.language   = 'JA'
         AND  FLV06.lookup_type = 'XXCMN_D+1_LOCT_FLAG'
         AND  FLV06.lookup_code = MIL.attribute11
        ) FLV06_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,MIL.attribute15                 --�����q�ɋ敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV07.meaning                   --�����q�ɋ敪��
       ,(SELECT FLV07.meaning 
         FROM fnd_lookup_values FLV07  --�N�C�b�N�R�[�h(�����q�ɋ敪��)
         WHERE FLV07.language   = 'JA'
         AND  FLV07.lookup_type = 'XXCMN_DROP_SHIP_LOCT_CLASS'
         AND  FLV07.lookup_code = MIL.attribute15
        ) FLV07_meaning
       --,FU_CB.user_name                  --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
         WHERE MIL.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( MIL.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name                  --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
         WHERE MIL.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( MIL.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name                  --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user   FU_LL  --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
             ,fnd_logins FL_LL  --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
         WHERE MIL.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  ic_whse_mst               IWM    --OPM�q�Ƀ}�X�^
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,ic_whse_mst               IWM02  --OPM�q�Ƀ}�X�^(�ۊǏꏊ)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
       ,hr_all_organization_units HAOU   --�q��
       ,mtl_item_locations        MIL    --�q��
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,sy_orgn_mst_tl            SOMT   --�v�����g
       --,xxsky_item_locations_v    XILV01 --OPM�ۊǏꏊ���VIEW(��\�q�ɖ�)
       --,xxsky_item_locations_v    XILV02 --OPM�ۊǏꏊ���VIEW(�d�n�r���於)
       --,xxsky_item_locations_v    XILV03 --OPM�ۊǏꏊ���VIEW(��v�ۊǑq��)
       --,xxsky_carriers_v          XCV    --�^���Ǝҏ��VIEW
       --,xxsky_locations_v         XLV    --���Ə����VIEW(�q�ɊǗ�����)
       --,xxsky_vendors_v           XVV    --�d������VIEW(�d����)
       --,xxsky_vendor_sites_v      XVSV   --�d����T�C�g���VIEW(�d����T�C�g��)
       --,mr_shcl_hdr               MSH01  --��J�����_(�h�����N)
       --,mr_shcl_hdr               MSH02  --��J�����_(���[�t)
       --,fnd_user                  FU_CB  --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       --,fnd_user                  FU_LU  --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       --,fnd_user                  FU_LL  --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       --,fnd_logins                FL_LL  --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       --,fnd_lookup_values         FLV01  --�N�C�b�N�R�[�h(�����݌ɊǗ��Ώۖ�)
       --,fnd_lookup_values         FLV02  --�N�C�b�N�R�[�h(���O�q�ɋ敪��)
       --,fnd_lookup_values         FLV03  --�N�C�b�N�R�[�h(�����u���b�N��)
       --,fnd_lookup_values         FLV04  --�N�C�b�N�R�[�h(�d�n�r�Ǘ��敪��)
       --,fnd_lookup_values         FLV05  --�N�C�b�N�R�[�h(�o�׈����Ώۃt���O��)
       --,fnd_lookup_values         FLV06  --�N�C�b�N�R�[�h(�c�{�P�q�Ƀt���O��)
       --,fnd_lookup_values         FLV07  --�N�C�b�N�R�[�h(�����q�ɋ敪��)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  HAOU.date_from <= TRUNC(SYSDATE)
   AND ( HAOU.date_to IS NULL
         OR HAOU.date_to >= TRUNC(SYSDATE) )
-- [E_�{�ғ�_14953] SCSK Y.Sekine Del Start
--   AND  MIL.disable_date IS NULL
-- [E_�{�ғ�_14953] SCSK Y.Sekine Del End
   AND  IWM.mtl_organization_id = HAOU.organization_id
   AND  HAOU.organization_id = MIL.organization_id
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  IWM.orgn_code = SOMT.orgn_code(+)
   --AND  SOMT.language(+) = 'JA'
   --AND  MIL.subinventory_code = IWM02.whse_code(+)
   --AND  MIL.attribute5 = XILV01.segment1(+)
   --AND  MIL.attribute7 = XCV.freight_code(+)
   --AND  MIL.attribute2 = XILV02.segment1(+)
   --AND  MIL.attribute3 = XLV.location_code(+)
   --AND  MIL.attribute8 = XILV03.segment1(+)
   --AND  MIL.attribute13 = XVV.segment1(+)
   --AND  MIL.attribute1 =  XVSV.vendor_site_code(+)
   --AND  MIL.attribute10 = MSH01.calendar_no(+)
   --AND  MIL.attribute14 = MSH02.calendar_no(+)
   --AND  MIL.created_by        = FU_CB.user_id(+)
   --AND  MIL.last_updated_by   = FU_LU.user_id(+)
   --AND  MIL.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
   --AND  FLV01.language(+)    = 'JA'                        --����
   --AND  FLV01.lookup_type(+) = 'XXCMN_INV_CTRL'            --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV01.lookup_code(+) = IWM.attribute1              --�N�C�b�N�R�[�h
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_LOCT_IN_OUT'
   --AND  FLV02.lookup_code(+) = MIL.attribute9
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXCMN_D12'
   --AND  FLV03.lookup_code(+) = MIL.attribute6
   --AND  FLV04.language(+)    = 'JA'
   --AND  FLV04.lookup_type(+) = 'XXCMN_MANAGE_EOS'
   --AND  FLV04.lookup_code(+) = DECODE(MIL.ATTRIBUTE2, NULL, '0', '1')
   --AND  FLV05.language(+)    = 'JA'
   --AND  FLV05.lookup_type(+) = 'XXCMN_ATP_FLAG'
   --AND  FLV05.lookup_code(+) = MIL.attribute4
   --AND  FLV06.language(+)    = 'JA'
   --AND  FLV06.lookup_type(+) = 'XXCMN_D+1_LOCT_FLAG'
   --AND  FLV06.lookup_code(+) = MIL.attribute11
   --AND  FLV07.language(+)    = 'JA'
   --AND  FLV07.lookup_type(+) = 'XXCMN_DROP_SHIP_LOCT_CLASS'
   --AND  FLV07.lookup_code(+) = MIL.attribute15
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V IS 'SKYLINK�pOPM�ۊǏꏊ�}�X�^�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�q�ɃR�[�h                IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�q�ɖ�                    IS '�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�v�����g�R�[�h            IS '�v�����g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�v�����g��                IS '�v�����g��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�g�D�L���J�n��            IS '�g�D�L���J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�g�D�L���I����            IS '�g�D�L���I����'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�����݌ɊǗ��Ώ�        IS '�����݌ɊǗ��Ώ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�����݌ɊǗ��Ώۖ�      IS '�����݌ɊǗ��Ώۖ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�ۊǑq�ɃR�[�h            IS '�ۊǑq�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�ۊǑq�ɖ�                IS '�ۊǑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�ۊǑq�ɗ���              IS '�ۊǑq�ɗ���'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�ۊǑq�ɖ�����            IS '�ۊǑq�ɖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�ۊǏꏊ�R�[�h            IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�ۊǏꏊ��                IS '�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.���O�q�ɋ敪              IS '���O�q�ɋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.���O�q�ɋ敪��            IS '���O�q�ɋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�����u���b�N              IS '�����u���b�N'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�����u���b�N��            IS '�����u���b�N��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.��\�q��                  IS '��\�q��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.��\�q�ɖ�                IS '��\�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.��\�q�ɗ���              IS '��\�q�ɗ���'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.��\�^�����              IS '��\�^�����'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.��\�^����Ж�            IS '��\�^����Ж�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�d�n�r�Ǘ��敪            IS '�d�n�r�Ǘ��敪'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�d�n�r�Ǘ��敪��          IS '�d�n�r�Ǘ��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�d�n�r����                IS '�d�n�r����'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�d�n�r���於              IS '�d�n�r���於'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�q�ɊǗ�����              IS '�q�ɊǗ�����'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�q�ɊǗ�������            IS '�q�ɊǗ�������'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.��v�ۊǑq�ɃR�[�h        IS '��v�ۊǑq�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.��v�ۊǑq�ɖ�            IS '��v�ۊǑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�d����R�[�h              IS '�d����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�d���於                  IS '�d���於'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�d����T�C�g�R�[�h        IS '�d����T�C�g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�d����T�C�g��            IS '�d����T�C�g��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�h�����N��J�����_      IS '�h�����N��J�����_'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�h�����N��J�����_��    IS '�h�����N��J�����_��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.���[�t��J�����_        IS '���[�t��J�����_'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.���[�t��J�����_��      IS '���[�t��J�����_��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�o�׈����Ώۃt���O        IS '�o�׈����Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�o�׈����Ώۃt���O��      IS '�o�׈����Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�c_�P�q�Ƀt���O           IS '�c�{�P�q�Ƀt���O'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�c_�P�q�Ƀt���O��         IS '�c�{�P�q�Ƀt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�����q�ɋ敪              IS '�����q�ɋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�����q�ɋ敪��            IS '�����q�ɋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�쐬��                    IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�쐬��                    IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�ŏI�X�V��                IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�ŏI�X�V��                IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_OPM�ۊǏꏊ�}�X�^_����_V.�ŏI�X�V���O�C��          IS '�ŏI�X�V���O�C��'
/