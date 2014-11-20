CREATE OR REPLACE VIEW APPS.XXSKY_�ڋq���_�}�X�^_��{_V
(
 �g�D�ԍ�
,�g�D_�X�e�[�^�X
,�g�D_�X�e�[�^�X��
,�ڋq���__�}�X�^��M��
,�ڋq���__�ԍ�
,�ڋq���__����
,�ڋq���__����
,�ڋq���__�J�i��
,�ڋq���__�X�e�[�^�X
,�ڋq���__�X�e�[�^�X��
,�ڋq���__�敪
,�ڋq���__�敪��
,�ڋq���__�K�p�J�n��
,�ڋq���__�K�p�I����
,�ڋq���__�X�֔ԍ�
,�ڋq���__�Z���P
,�ڋq���__�Z���Q
,�ڋq���__�d�b�ԍ�
,�ڋq���__FAX�ԍ�
,���__������
,���__�h�����N�^���U�֊
,���__�h�����N�^���U�֊��
,���__���[�t�^���U�֊
,���__���[�t�^���U�֊��
,���__�U�փO���[�v
,���__�U�փO���[�v��
,���__�����u���b�N
,���__�����u���b�N��
,���__���_�啪��
,���__���_�啪�ޖ�
,���__���{���R�[�h
,���__�V�{���R�[�h
,���__�{���K�p�J�n��
,���__���їL���敪
,���__���їL���敪��
,���__�o�׊Ǘ����敪
,���__�o�׊Ǘ����敪��
,���__�q�֑Ώۉۋ敪
,���__�q�֑Ώۉۋ敪��
,�ڋq���__���~�q�\���t���O
,�ڋq���__���~�q�\���t���O��
,���__�h�����N���_�J�e�S��
,���__�h�����N���_�J�e�S����
,���__���[�t���_�J�e�S��
,���__���[�t���_�J�e�S����
,���__�o�׈˗������쐬�敪
,���__�o�׈˗������쐬�敪��
,�ڋq_�����敪
,�ڋq_�����敪��
,�ڋq_�������㋒�_�R�[�h
,�ڋq_�������㋒�_��
,�ڋq_�\�񔄏㋒�_�R�[�h
,�ڋq_�\�񔄏㋒�_��
,�ڋq_����`�F�[���X
,�ڋq_����`�F�[���X��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        HP.party_number                  --�g�D�ԍ�
       ,HP.status                        --�g�D_�X�e�[�^�X
       ,DECODE(HP.status, 'A', '�L��', 'I', '����')
        status_name                      --�g�D_�X�e�[�^�X��
       ,HP.attribute24                   --�ڋq���__�}�X�^��M��
       ,HCA.account_number               --�ڋq���__�ԍ�
       ,XP.party_name                    --�ڋq���__����
       ,XP.party_short_name              --�ڋq���__����
       ,XP.party_name_alt                --�ڋq���__�J�i��
       ,HCA.status                       --�ڋq���__�X�e�[�^�X
       ,DECODE(HCA.status, 'A', '�L��', 'I', '����')
        status_name                      --�ڋq���__�X�e�[�^�X��
       ,HCA.customer_class_code          --�ڋq���__�敪
       ,FLV01.meaning                    --�ڋq���__�敪��
       ,XP.start_date_active             --�ڋq���__�K�p�J�n��
       ,XP.end_date_active               --�ڋq���__�K�p�I����
       ,XP.zip                           --�ڋq���__�X�֔ԍ�
       ,XP.address_line1                 --�ڋq���__�Z���P
       ,XP.address_line2                 --�ڋq���__�Z���Q
       ,XP.phone                         --�ڋq���__�d�b�ԍ�
       ,XP.fax                           --�ڋq���__FAX�ԍ�
       ,XP.reserve_order                 --���__������
       ,XP.drink_transfer_std            --���__�h�����N�^���U�֊
       ,FLV02.meaning                    --���__�h�����N�^���U�֊��
       ,XP.leaf_transfer_std             --���__���[�t�^���U�֊
       ,FLV03.meaning                    --���__���[�t�^���U�֊��
       ,XP.transfer_group                --���__�U�փO���[�v
       ,FLV04.meaning                    --���__�U�փO���[�v��
       ,XP.distribution_block            --���__�����u���b�N
       ,FLV05.meaning                    --���__�����u���b�N��
       ,XP.base_major_division           --���__���_�啪��
       ,FLV06.meaning                    --���__���_�啪�ޖ�
       ,HCA.attribute1                   --���__���{���R�[�h
       ,HCA.attribute2                   --���__�V�{���R�[�h
       ,HCA.attribute3                   --���__�{���K�p�J�n��
       ,HCA.attribute4                   --���__���їL���敪
       ,FLV09.meaning                    --���__���їL���敪��
       ,HCA.attribute5                   --���__�o�׊Ǘ����敪
       ,FLV10.meaning                    --���__�o�׊Ǘ����敪��
       ,HCA.attribute6                   --���__�q�֑Ώۉۋ敪
       ,FLV11.meaning                    --���__�q�֑Ώۉۋ敪��
-- 2009/10/27 Y.Kawano Mod Start �{��#1675
--       ,HCA.attribute12                  --�ڋq���__���~�q�\���t���O
       ,CASE hca.customer_class_code
        WHEN '1' THEN
          CASE hp.duns_number_c
          WHEN '30' THEN '0'
          WHEN '40' THEN '0'
          WHEN '99' THEN '0'
          ELSE '2'
          END
        WHEN '10' THEN
          CASE hp.duns_number_c
          WHEN '30' THEN '0'
          WHEN '40' THEN '0'
          ELSE '2'
          END
        END cust_enable_flag               --�ڋq���__���~�q�\���t���O
--       ,FLV12.meaning                    --�ڋq���__���~�q�\���t���O��
       ,CASE hca.customer_class_code
        WHEN '1'  THEN FLV12.meaning
        WHEN '10' THEN FLV122.meaning
        END meaning                      --�ڋq���__���~�q�\���t���O��
-- 2009/10/27 Y.Kawano Mod End �{��#1675
       ,HCA.attribute13                  --���__�h�����N���_�J�e�S��
       ,FLV13.meaning                    --���__�h�����N���_�J�e�S����
       ,HCA.attribute16                  --���__���[�t���_�J�e�S��
       ,FLV14.meaning                    --���__���[�t���_�J�e�S����
       ,HCA.attribute14                  --���__�o�׈˗������쐬�敪
       ,FLV15.meaning                    --���__�o�׈˗������쐬�敪��
       ,HCA.attribute15                  --�ڋq_�����敪
       ,FLV16.meaning                    --�ڋq_�����敪��
       ,HCA.attribute17                  --�ڋq_�������㋒�_�R�[�h
       ,XCAV01.party_name                --�ڋq_�������㋒�_��
       ,HCA.attribute18                  --�ڋq_�\�񔄏㋒�_�R�[�h
       ,XCAV02.party_name                --�ڋq_�\�񔄏㋒�_��
       ,HCA.attribute19                  --�ڋq_����`�F�[���X
       ,HCA.attribute20                  --�ڋq_����`�F�[���X��
       ,FU_CB.user_name                  --�쐬��
       ,TO_CHAR( XP.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --�쐬��
       ,FU_LU.user_name                  --�ŏI�X�V��
       ,TO_CHAR( XP.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --�ŏI�X�V��
       ,FU_LL.user_name                  --�ŏI�X�V���O�C��
  FROM  xxcmn_parties           XP       --�p�[�e�B�A�h�I���}�X�^
       ,hz_parties              HP       --�p�[�e�B�}�X�^
       ,hz_cust_accounts        HCA      --�ڋq�}�X�^
       ,xxsky_cust_accounts_v   XCAV01   --�ڋq���VIEW(�ڋq_�������㋒�_��)
       ,xxsky_cust_accounts_v   XCAV02   --�ڋq���VIEW(�ڋq_�\�񔄏㋒�_��)
       ,fnd_user                FU_CB    --���[�U�[�}�X�^(created_by���̎擾�p)
       ,fnd_user                FU_LU    --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       ,fnd_user                FU_LL    --���[�U�[�}�X�^(last_update_login���̎擾�p)
       ,fnd_logins              FL_LL    --���O�C���}�X�^(last_update_login���̎擾�p)
       ,fnd_lookup_values       FLV01    --�N�C�b�N�R�[�h(�ڋq���__�敪��)
       ,fnd_lookup_values       FLV02    --�N�C�b�N�R�[�h(���__�h�����N�^���U�֊��)
       ,fnd_lookup_values       FLV03    --�N�C�b�N�R�[�h(���__���[�t�^���U�֊��)
       ,fnd_lookup_values       FLV04    --�N�C�b�N�R�[�h(���__�U�փO���[�v��)
       ,fnd_lookup_values       FLV05    --�N�C�b�N�R�[�h(���__�����u���b�N��)
       ,fnd_lookup_values       FLV06    --�N�C�b�N�R�[�h(���__���_�啪�ޖ�)
       ,fnd_lookup_values       FLV09    --�N�C�b�N�R�[�h(���__���їL���敪��)
       ,fnd_lookup_values       FLV10    --�N�C�b�N�R�[�h(���__�o�׊Ǘ����敪��)
       ,fnd_lookup_values       FLV11    --�N�C�b�N�R�[�h(���__�q�֑Ώۉۋ敪��)
       ,fnd_lookup_values       FLV12    --�N�C�b�N�R�[�h(�ڋq���__���~�q�\���t���O��)
-- 2009/10/27 Y.Kawano Mod Start �{��#1675
       ,fnd_lookup_values       FLV122   --�N�C�b�N�R�[�h(�ڋq���__���~�q�\���t���O��)
-- 2009/10/27 Y.Kawano Mod End   �{��#1675
       ,fnd_lookup_values       FLV13    --�N�C�b�N�R�[�h(���__�h�����N���_�J�e�S����)
       ,fnd_lookup_values       FLV14    --�N�C�b�N�R�[�h(���__���[�t���_�J�e�S����)
       ,fnd_lookup_values       FLV15    --�N�C�b�N�R�[�h(���__�o�׈˗������쐬�敪��)
       ,fnd_lookup_values       FLV16    --�N�C�b�N�R�[�h(�ڋq_�����敪��)
 WHERE  HP.status = 'A'                                    --�X�e�[�^�X�F�L��
   AND  XP.party_id = HP.party_id
-- 2009/10/02 DEL START
--   AND  HCA.status = 'A'                                   --�X�e�[�^�X�F�L��
-- 2009/10/02 DEL END
-- 2009/03/30 H.Iida Add Start �{�ԏ�Q#1346
   AND  HCA.customer_class_code IN ('1', '10')
-- 2009/03/30 H.Iida Add End
   AND  XP.party_id = HCA.party_id
   AND  HCA.attribute17 = XCAV01.party_number(+)
   AND  HCA.attribute18 = XCAV02.party_number(+)
   AND  XP.created_by        = FU_CB.user_id(+)
   AND  XP.last_updated_by   = FU_LU.user_id(+)
   AND  XP.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id        = FU_LL.user_id(+)
   AND  FLV01.language(+)    = 'JA'                        --����
   AND  FLV01.lookup_type(+) = 'CUSTOMER CLASS'            --�N�C�b�N�R�[�h�^�C�v
   AND  FLV01.lookup_code(+) = HCA.customer_class_code     --�N�C�b�N�R�[�h
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV02.lookup_code(+) = XP.drink_transfer_std
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV03.lookup_code(+) = XP.leaf_transfer_std
   AND  FLV04.language(+)    = 'JA'
   AND  FLV04.lookup_type(+) = 'XXCMN_D04'
   AND  FLV04.lookup_code(+) = XP.transfer_group
   AND  FLV05.language(+)    = 'JA'
   AND  FLV05.lookup_type(+) = 'XXCMN_D12'
   AND  FLV05.lookup_code(+) = XP.distribution_block
   AND  FLV06.language(+)    = 'JA'
   AND  FLV06.lookup_type(+) = 'XXWIP_BASE_MAJOR_DIVISION'
   AND  FLV06.lookup_code(+) = XP.base_major_division
   AND  FLV09.language(+)    = 'JA'
   AND  FLV09.lookup_type(+) = 'XXCMN_BASE_RESULTS_CLASS'
   AND  FLV09.lookup_code(+) = HCA.attribute4
   AND  FLV10.language(+)    = 'JA'
   AND  FLV10.lookup_type(+) = 'XXCMN_SHIPMENT_MANAGEMENT'
   AND  FLV10.lookup_code(+) = HCA.attribute5
   AND  FLV11.language(+)    = 'JA'
   AND  FLV11.lookup_type(+) = 'XXCMN_INV_OBJEC_CLASS'
   AND  FLV11.lookup_code(+) = HCA.attribute6
   AND  FLV12.language(+)    = 'JA'
   AND  FLV12.lookup_type(+) = 'XXCMN_CUST_ENABLE_FLAG'
-- 2009/10/27 Y.Kawano Mod Start �{��#1675
--   AND  FLV12.lookup_code(+) = HCA.attribute12
   AND  FLV12.lookup_code(+) = DECODE(HP.duns_number_c,'30','0','40','0','99','0','2')
   AND  FLV122.language(+)    = 'JA'
   AND  FLV122.lookup_type(+) = 'XXCMN_CUST_ENABLE_FLAG'
   AND  FLV122.lookup_code(+) = DECODE(HP.duns_number_c,'30','0','40','0','2')
-- 2009/10/27 Y.Kawano Mod End �{��#1675
   AND  FLV13.language(+)    = 'JA'
   AND  FLV13.lookup_type(+) = 'XXWSH_DRINK_BASE_CATEGORY'
   AND  FLV13.lookup_code(+) = HCA.attribute13
   AND  FLV14.language(+)    = 'JA'
   AND  FLV14.lookup_type(+) = 'XXWSH_LEAF_BASE_CATEGORY'
   AND  FLV14.lookup_code(+) = HCA.attribute16
   AND  FLV15.language(+)    = 'JA'
   AND  FLV15.lookup_type(+) = 'XXCMN_SHIPMENT_AUTO'
   AND  FLV15.lookup_code(+) = HCA.attribute14
   AND  FLV16.language(+)    = 'JA'
   AND  FLV16.lookup_type(+) = 'XXCMN_DROP_SHIP_DIV'
   AND  FLV16.lookup_code(+) = HCA.attribute15
/
COMMENT ON TABLE APPS.XXSKY_�ڋq���_�}�X�^_��{_V IS 'SKYLINK�p�ڋq���_�}�X�^�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�g�D�ԍ� IS '�g�D�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�g�D_�X�e�[�^�X IS '�g�D_�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�g�D_�X�e�[�^�X�� IS '�g�D_�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�}�X�^��M�� IS '�ڋq���__�}�X�^��M��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�ԍ� IS '�ڋq���__�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__���� IS '�ڋq���__����'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__���� IS '�ڋq���__����'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�J�i�� IS '�ڋq���__�J�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�X�e�[�^�X IS '�ڋq���__�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�X�e�[�^�X�� IS '�ڋq���__�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�敪 IS '�ڋq���__�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�敪�� IS '�ڋq���__�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�K�p�J�n�� IS '�ڋq���__�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�K�p�I���� IS '�ڋq���__�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�X�֔ԍ� IS '�ڋq���__�X�֔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�Z���P IS '�ڋq���__�Z���P'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�Z���Q IS '�ڋq���__�Z���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__�d�b�ԍ� IS '�ڋq���__�d�b�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__FAX�ԍ� IS '�ڋq���__FAX�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__������ IS '���__������'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�h�����N�^���U�֊ IS '���__�h�����N�^���U�֊'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�h�����N�^���U�֊�� IS '���__�h�����N�^���U�֊��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__���[�t�^���U�֊ IS '���__���[�t�^���U�֊'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__���[�t�^���U�֊�� IS '���__���[�t�^���U�֊��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�U�փO���[�v IS '���__�U�փO���[�v'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�U�փO���[�v�� IS '���__�U�փO���[�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�����u���b�N IS '���__�����u���b�N'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�����u���b�N�� IS '���__�����u���b�N��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__���_�啪�� IS '���__���_�啪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__���_�啪�ޖ� IS '���__���_�啪�ޖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__���{���R�[�h IS '���__���{���R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�V�{���R�[�h IS '���__�V�{���R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�{���K�p�J�n�� IS '���__�{���K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__���їL���敪 IS '���__���їL���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__���їL���敪�� IS '���__���їL���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�o�׊Ǘ����敪 IS '���__�o�׊Ǘ����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�o�׊Ǘ����敪�� IS '���__�o�׊Ǘ����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�q�֑Ώۉۋ敪 IS '���__�q�֑Ώۉۋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�q�֑Ώۉۋ敪�� IS '���__�q�֑Ώۉۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__���~�q�\���t���O IS '�ڋq���__���~�q�\���t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq���__���~�q�\���t���O�� IS '�ڋq���__���~�q�\���t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�h�����N���_�J�e�S�� IS '���__�h�����N���_�J�e�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�h�����N���_�J�e�S���� IS '���__�h�����N���_�J�e�S����'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__���[�t���_�J�e�S�� IS '���__���[�t���_�J�e�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__���[�t���_�J�e�S���� IS '���__���[�t���_�J�e�S����'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�o�׈˗������쐬�敪 IS '���__�o�׈˗������쐬�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.���__�o�׈˗������쐬�敪�� IS '���__�o�׈˗������쐬�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq_�����敪 IS '�ڋq_�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq_�����敪�� IS '�ڋq_�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq_�������㋒�_�R�[�h IS '�ڋq_�������㋒�_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq_�������㋒�_�� IS '�ڋq_�������㋒�_��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq_�\�񔄏㋒�_�R�[�h IS '�ڋq_�\�񔄏㋒�_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq_�\�񔄏㋒�_�� IS '�ڋq_�\�񔄏㋒�_��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq_����`�F�[���X IS '�ڋq_����`�F�[���X'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ڋq_����`�F�[���X�� IS '�ڋq_����`�F�[���X��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�ڋq���_�}�X�^_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
