CREATE OR REPLACE VIEW APPS.XXSKY_�z����}�X�^_��{_V
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
,�z����_�ԍ�
,�z����_����
,�z����_����
,�z����_�J�i��
,�z����_�K�p�J�n��
,�z����_�K�p�I����
,�z����_�X�e�[�^�X
,�z����_�X�e�[�^�X��
,�z����_���_�R�[�h
,�z����_���_��
,�z����_�X�֔ԍ�
,�z����_�Z���P
,�z����_�Z���Q
,�z����_�d�b�ԍ�
,�z����_FAX�ԍ�
,�z����_�N�x����
,�z����_�N�x������
,�z����_�}�X�^��M��
,�z����_���ݒn�X�e�[�^�X
,�z����_���ݒn�X�e�[�^�X��
,�z����_�h�����N��J�����_
,�z����_�h�����N��J�����_��
,�z����_JPR���[�U�R�[�h
,�z����_�s���{���R�[�h
,�z����_�s���{����
,�z����_�ő���Ɏ��q
,�z����_�w�荀�ڋ敪
,�z����_�w�荀�ڋ敪��
,�z����_�t�ыƖ����t�g�敪
,�z����_�t�ыƖ����t�g�敪��
,�z����_�t�ыƖ���p�`�[�敪
,�z����_�t�ыƖ���p�`�[�敪��
,�z����_�t�ыƖ��p���b�g�ϑ�
,�z����_�t�ыƖ��p���b�g�ϑ֖�
,�z����_�t�ыƖ��ב��敪
,�z����_�t�ыƖ��ב��敪��
,�z����_�t�ыƖ��p���b�g�J�S
,�z����_�t�ыƖ��p���b�g�J�S��
,�z����_���[���敪
,�z����_���[���敪��
,�z����_�i�ϗA���ۋ敪
,�z����_�i�ϗA���ۋ敪��
,�z����_�ʍs���؋敪
,�z����_�ʍs���؋敪��
,�z����_���ꋖ�؋敪
,�z����_���ꋖ�؋敪��
,�z����_���q�w��敪
,�z����_���q�w��敪��
,�z����_�[�i���A���敪
,�z����_�[�i���A���敪��
,�z����_���[�t��J�����_
,�z����_���[�t��J�����_��
,�z����_��t���O
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
       ,HCA.attribute12                  --�ڋq���__���~�q�\���t���O
       ,FLV12.meaning                    --�ڋq���__���~�q�\���t���O��
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
       ,HL.province                      --�z����_�ԍ�
       ,XPS.party_site_name              --�z����_����
       ,XPS.party_site_short_name        --�z����_����
       ,XPS.party_site_name_alt          --�z����_�J�i��
       ,XPS.start_date_active            --�z����_�K�p�J�n��
       ,XPS.end_date_active              --�z����_�K�p�I����
       ,HPS.status                       --�z����_�X�e�[�^�X
       ,DECODE(HPS.status, 'A', '�L��', 'I', '����')
        status_name                      --�z����_�X�e�[�^�X��
       ,XPS.base_code                    --�z����_���_�R�[�h
       ,XCAV03.party_name                --�z����_���_��
       ,XPS.zip                          --�z����_�X�֔ԍ�
       ,XPS.address_line1                --�z����_�Z���P
       ,XPS.address_line2                --�z����_�Z���Q
       ,XPS.phone                        --�z����_�d�b�ԍ�
       ,XPS.fax                          --�z����_FAX�ԍ�
       ,XPS.freshness_condition          --�z����_�N�x����
       ,FLV17.meaning                    --�z����_�N�x������
       ,HPS.attribute19                  --�z����_�}�X�^��M��
       ,HCASA.status                     --�z����_���ݒn�X�e�[�^�X
       ,DECODE(HCASA.status, 'A', '�L��', 'I', '����')
        status_name                      --�z����_���ݒn�X�e�[�^�X��
       ,HCASA.attribute1                 --�z����_�h�����N��J�����_
       ,MSH01.calendar_desc              --�z����_�h�����N��J�����_��
       ,HCASA.attribute2                 --�z����_JPR���[�U�R�[�h
       ,HCASA.attribute3                 --�z����_�s���{���R�[�h
       ,FLV18.meaning                    --�z����_�s���{����
       ,HCASA.attribute4                 --�z����_�ő���Ɏ��q
       ,HCASA.attribute5                 --�z����_�w�荀�ڋ敪
       ,FLV19.meaning                    --�z����_�w�荀�ڋ敪��
       ,HCASA.attribute6                 --�z����_�t�ыƖ����t�g�敪
       ,FLV20.meaning                    --�z����_�t�ыƖ����t�g�敪��
       ,HCASA.attribute7                 --�z����_�t�ыƖ���p�`�[�敪
       ,FLV21.meaning                    --�z����_�t�ыƖ���p�`�[�敪��
       ,HCASA.attribute8                 --�z����_�t�ыƖ��p���b�g�ϑ�
       ,FLV22.meaning                    --�z����_�t�ыƖ��p���b�g�ϑ֖�
       ,HCASA.attribute9                 --�z����_�t�ыƖ��ב��敪
       ,FLV23.meaning                    --�z����_�t�ыƖ��ב��敪��
       ,HCASA.attribute10                --�z����_�t�ыƖ��p���b�g�J�S
       ,FLV24.meaning                    --�z����_�t�ыƖ��p���b�g�J�S��
       ,HCASA.attribute11                --�z����_���[���敪
       ,FLV25.meaning                    --�z����_���[���敪��
       ,HCASA.attribute12                --�z����_�i�ϗA���ۋ敪
       ,FLV26.meaning                    --�z����_�i�ϗA���ۋ敪��
       ,HCASA.attribute13                --�z����_�ʍs���؋敪
       ,FLV27.meaning                    --�z����_�ʍs���؋敪��
       ,HCASA.attribute14                --�z����_���ꋖ�؋敪
       ,FLV28.meaning                    --�z����_���ꋖ�؋敪��
       ,HCASA.attribute15                --�z����_���q�w��敪
       ,FLV29.meaning                    --�z����_���q�w��敪��
       ,HCASA.attribute16                --�z����_�[�i���A���敪
       ,FLV30.meaning                    --�z����_�[�i���A���敪��
       ,HCASA.attribute19                --�z����_���[�t��J�����_
       ,MSH02.calendar_desc              --�z����_���[�t��J�����_��
       ,HCSUA.primary_flag               --�z����_��t���O
       ,FU_CB.user_name                  --�쐬��
       ,TO_CHAR( XPS.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --�쐬��
       ,FU_LU.user_name                  --�ŏI�X�V��
       ,TO_CHAR( XPS.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --�ŏI�X�V��
       ,FU_LL.user_name                  --�ŏI�X�V���O�C��
  FROM  xxcmn_parties           XP       --�p�[�e�B�A�h�I���}�X�^
       ,hz_parties              HP       --�p�[�e�B�}�X�^
       ,hz_cust_accounts        HCA      --�ڋq�}�X�^
       ,xxcmn_party_sites       XPS      --�p�[�e�B�T�C�g�A�h�I���}�X�^
       ,hz_party_sites          HPS      --�p�[�e�B�T�C�g�}�X�^
       ,hz_locations            HL       --�ڋq���Ə��}�X�^
       ,hz_cust_acct_sites_all  HCASA    --�ڋq���ݒn�}�X�^
       ,hz_cust_site_uses_all   HCSUA    --�ڋq�g�p�ړI�}�X�^
       ,xxsky_cust_accounts_v   XCAV01   --�ڋq���VIEW(�ڋq_�������㋒�_��)
       ,xxsky_cust_accounts_v   XCAV02   --�ڋq���VIEW(�ڋq_�\�񔄏㋒�_��)
       ,xxsky_cust_accounts_v   XCAV03   --�ڋq���VIEW(�z����_���_��)
       ,mr_shcl_hdr             MSH01    --��J�����_(�z����_�h�����N��J�����_��)
       ,mr_shcl_hdr             MSH02    --��J�����_(�z����_���[�t��J�����_��)
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
       ,fnd_lookup_values       FLV13    --�N�C�b�N�R�[�h(���__�h�����N���_�J�e�S����)
       ,fnd_lookup_values       FLV14    --�N�C�b�N�R�[�h(���__���[�t���_�J�e�S����)
       ,fnd_lookup_values       FLV15    --�N�C�b�N�R�[�h(���__�o�׈˗������쐬�敪��)
       ,fnd_lookup_values       FLV16    --�N�C�b�N�R�[�h(�ڋq_�����敪��)
       ,fnd_lookup_values       FLV17    --�N�C�b�N�R�[�h(�z����_�N�x������)
       ,fnd_lookup_values       FLV18    --�N�C�b�N�R�[�h(�z����_�s���{����)
       ,fnd_lookup_values       FLV19    --�N�C�b�N�R�[�h(�z����_�w�荀�ڋ敪��)
       ,fnd_lookup_values       FLV20    --�N�C�b�N�R�[�h(�z����_�t�ыƖ����t�g�敪��)
       ,fnd_lookup_values       FLV21    --�N�C�b�N�R�[�h(�z����_�t�ыƖ���p�`�[�敪��)
       ,fnd_lookup_values       FLV22    --�N�C�b�N�R�[�h(�z����_�t�ыƖ��p���b�g�ϑ֖�)
       ,fnd_lookup_values       FLV23    --�N�C�b�N�R�[�h(�z����_�t�ыƖ��ב��敪��)
       ,fnd_lookup_values       FLV24    --�N�C�b�N�R�[�h(�z����_�t�ыƖ��p���b�g�J�S��)
       ,fnd_lookup_values       FLV25    --�N�C�b�N�R�[�h(�z����_���[���敪��)
       ,fnd_lookup_values       FLV26    --�N�C�b�N�R�[�h(�z����_�i�ϗA���ۋ敪��)
       ,fnd_lookup_values       FLV27    --�N�C�b�N�R�[�h(�z����_�ʍs���؋敪��)
       ,fnd_lookup_values       FLV28    --�N�C�b�N�R�[�h(�z����_���ꋖ�؋敪��)
       ,fnd_lookup_values       FLV29    --�N�C�b�N�R�[�h(�z����_���q�w��敪��)
       ,fnd_lookup_values       FLV30    --�N�C�b�N�R�[�h(�z����_�[�i���A���敪��)
 WHERE
   --�p�[�e�B�}�X�^�i�ڋq����_���擾�j�Ƃ̌���
        HP.status = 'A'                                    --�X�e�[�^�X�F�L��
   AND  XP.party_id = HP.party_id
   --�ڋq�}�X�^�i�ڋq����_���擾�j�Ƃ̌���
   AND  HCA.status = 'A'                                   --�X�e�[�^�X�F�L��
   AND  XP.party_id = HCA.party_id
   --�p�[�e�B�T�C�g�A�h�I���}�X�^�i�ڋq����_���擾�j�Ƃ̌���
   AND  XP.party_id = XPS.party_id
   --�p�[�e�B�T�C�g�}�X�^�i�z������擾�j�Ƃ̌���
   AND  HPS.status = 'A'                                   --�X�e�[�^�X�F�L��
   AND  XPS.party_site_id = HPS.party_site_id
   --�ڋq���Ə��}�X�^�i�z������擾�j�Ƃ̌���
   AND  XPS.location_id = HL.location_id
   --�ڋq���ݒn�}�X�^�i�z������擾�j�Ƃ̌���
   AND  HCASA.status = 'A'                                 --�X�e�[�^�X�F�L��
   AND  XPS.party_site_id = HCASA.party_site_id
   --�ڋq�g�p�ړI�}�X�^�i�z������擾�j�Ƃ̌���
   AND  HCSUA.status = 'A'                                 --�X�e�[�^�X�F�L��
   AND  HCSUA.site_use_code = 'SHIP_TO'
   AND  HCASA.cust_acct_site_id = HCSUA.cust_acct_site_id
   --�������㋒�_���擾
   AND  HCA.attribute17 = XCAV01.party_number(+)
   --�\�񔄏㋒�_���擾
   AND  HCA.attribute18 = XCAV02.party_number(+)
   --���_���擾
   AND  XPS.base_code = XCAV03.party_number(+)
   --�h�����N��J�����_���擾
   AND  HCASA.attribute1 = MSH01.calendar_no(+)
   --���[�t��J�����_���擾
   AND  HCASA.attribute19 = MSH02.calendar_no(+)
   --WHO�J�������擾
   AND  XPS.created_by        = FU_CB.user_id(+)
   AND  XPS.last_updated_by   = FU_LU.user_id(+)
   AND  XPS.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id        = FU_LL.user_id(+)
   --�敪���擾
   AND  FLV01.language(+)    = 'JA'                        --����
   AND  FLV01.lookup_type(+) = 'CUSTOMER CLASS'            --�N�C�b�N�R�[�h�^�C�v
   AND  FLV01.lookup_code(+) = HCA.customer_class_code     --�N�C�b�N�R�[�h
   --�h�����N�^���U�֊���擾
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV02.lookup_code(+) = XP.drink_transfer_std
   --���[�t�^���U�֊���擾
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV03.lookup_code(+) = XP.leaf_transfer_std
   --�U�փO���[�v���擾
   AND  FLV04.language(+)    = 'JA'
   AND  FLV04.lookup_type(+) = 'XXCMN_D04'
   AND  FLV04.lookup_code(+) = XP.transfer_group
   --�����u���b�N���擾
   AND  FLV05.language(+)    = 'JA'
   AND  FLV05.lookup_type(+) = 'XXCMN_D12'
   AND  FLV05.lookup_code(+) = XP.distribution_block
   --���_�啪�ޖ��擾
   AND  FLV06.language(+)    = 'JA'
   AND  FLV06.lookup_type(+) = 'XXWIP_BASE_MAJOR_DIVISION'
   AND  FLV06.lookup_code(+) = XP.base_major_division
   --���їL���敪���擾
   AND  FLV09.language(+)    = 'JA'
   AND  FLV09.lookup_type(+) = 'XXCMN_BASE_RESULTS_CLASS'
   AND  FLV09.lookup_code(+) = HCA.attribute4
   --�o�׊Ǘ����敪���擾
   AND  FLV10.language(+)    = 'JA'
   AND  FLV10.lookup_type(+) = 'XXCMN_SHIPMENT_MANAGEMENT'
   AND  FLV10.lookup_code(+) = HCA.attribute5
   --�q�֑Ώۉۋ敪���擾
   AND  FLV11.language(+)    = 'JA'
   AND  FLV11.lookup_type(+) = 'XXCMN_INV_OBJEC_CLASS'
   AND  FLV11.lookup_code(+) = HCA.attribute6
   --���~�q�\���t���O���擾
   AND  FLV12.language(+)    = 'JA'
   AND  FLV12.lookup_type(+) = 'XXCMN_CUST_ENABLE_FLAG'
   AND  FLV12.lookup_code(+) = HCA.attribute12
   --�h�����N���_�J�e�S�����擾
   AND  FLV13.language(+)    = 'JA'
   AND  FLV13.lookup_type(+) = 'XXWSH_DRINK_BASE_CATEGORY'
   AND  FLV13.lookup_code(+) = HCA.attribute13
   --���[�t���_�J�e�S�����擾
   AND  FLV14.language(+)    = 'JA'
   AND  FLV14.lookup_type(+) = 'XXWSH_LEAF_BASE_CATEGORY'
   AND  FLV14.lookup_code(+) = HCA.attribute16
   --�o�׈˗������쐬�敪���擾
   AND  FLV15.language(+)    = 'JA'
   AND  FLV15.lookup_type(+) = 'XXCMN_SHIPMENT_AUTO'
   AND  FLV15.lookup_code(+) = HCA.attribute14
   --�����敪���擾
   AND  FLV16.language(+)    = 'JA'
   AND  FLV16.lookup_type(+) = 'XXCMN_DROP_SHIP_DIV'
   AND  FLV16.lookup_code(+) = HCA.attribute15
   --�N�x�������擾
   AND  FLV17.language(+)    = 'JA'
   AND  FLV17.lookup_type(+) = 'XXCMN_FRESHNESS_CONDITION'
   AND  FLV17.lookup_code(+) = XPS.freshness_condition
   --�s���{�����擾
   AND  FLV18.language(+)    = 'JA'
   AND  FLV18.lookup_type(+) = 'XXCMN_AREA_CODE'
   AND  FLV18.lookup_code(+) = HCASA.attribute3
   --�w�荀�ڋ敪���擾
   AND  FLV19.language(+)    = 'JA'
   AND  FLV19.lookup_type(+) = 'XXCMN_SPECIFY_ITEM'
   AND  FLV19.lookup_code(+) = HCASA.attribute5
   --�t�ыƖ����t�g�敪���擾
   AND  FLV20.language(+)    = 'JA'
   AND  FLV20.lookup_type(+) = 'XXCMN_ADD_LIFT_CLASS'
   AND  FLV20.lookup_code(+) = HCASA.attribute6
   --�t�ыƖ���p�`�[�敪���擾
   AND  FLV21.language(+)    = 'JA'
   AND  FLV21.lookup_type(+) = 'XXCMN_ADD_L03'
   AND  FLV21.lookup_code(+) = HCASA.attribute7
   --�t�ыƖ��p���b�g�ϑ֖��擾
   AND  FLV22.language(+)    = 'JA'
   AND  FLV22.lookup_type(+) = 'XXCMN_ADD_PALETTE'
   AND  FLV22.lookup_code(+) = HCASA.attribute8
   --�t�ыƖ��ב��敪���擾
   AND  FLV23.language(+)    = 'JA'
   AND  FLV23.lookup_type(+) = 'XXCMN_ADD_PACK_CLASS'
   AND  FLV23.lookup_code(+) = HCASA.attribute9
   --�t�ыƖ��p���b�g�J�S���擾
   AND  FLV24.language(+)    = 'JA'
   AND  FLV24.lookup_type(+) = 'XXCMN_ADD_PALETTE_BASKET'
   AND  FLV24.lookup_code(+) = HCASA.attribute10
   --���[���敪���擾
   AND  FLV25.language(+)    = 'JA'
   AND  FLV25.lookup_type(+) = 'XXCMN_RULE_CLASS'
   AND  FLV25.lookup_code(+) = HCASA.attribute11
   --�i�ϗA���ۋ敪���擾
   AND  FLV26.language(+)    = 'JA'
   AND  FLV26.lookup_type(+) = 'XXCMN_TRANSPORT_CLASS'
   AND  FLV26.lookup_code(+) = HCASA.attribute12
   --�ʍs���؋敪���擾
   AND  FLV27.language(+)    = 'JA'
   AND  FLV27.lookup_type(+) = 'XXCMN_PERMIT_CLASS'
   AND  FLV27.lookup_code(+) = HCASA.attribute13
   --���ꋖ�؋敪���擾
   AND  FLV28.language(+)    = 'JA'
   AND  FLV28.lookup_type(+) = 'XXCMN_ADMISSION_CLASS'
   AND  FLV28.lookup_code(+) = HCASA.attribute14
   --���q�w��敪���擾
   AND  FLV29.language(+)    = 'JA'
   AND  FLV29.lookup_type(+) = 'XXCMN_VEHICLES_SPECIFY'
   AND  FLV29.lookup_code(+) = HCASA.attribute15
   --�[�i���A���敪���擾
   AND  FLV30.language(+)    = 'JA'
   AND  FLV30.lookup_type(+) = 'XXCMN_DELIVERY_CLASS'
   AND  FLV30.lookup_code(+) = HCASA.attribute16
/
COMMENT ON TABLE APPS.XXSKY_�z����}�X�^_��{_V IS 'SKYLINK�p�z����}�X�^�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�g�D�ԍ�                      IS '�g�D�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�g�D_�X�e�[�^�X               IS '�g�D_�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�g�D_�X�e�[�^�X��             IS '�g�D_�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�}�X�^��M��         IS '�ڋq���__�}�X�^��M��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�ԍ�                 IS '�ڋq���__�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__����                 IS '�ڋq���__����'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__����                 IS '�ڋq���__����'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�J�i��               IS '�ڋq���__�J�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�X�e�[�^�X           IS '�ڋq���__�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�X�e�[�^�X��         IS '�ڋq���__�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�敪                 IS '�ڋq���__�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�敪��               IS '�ڋq���__�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�K�p�J�n��           IS '�ڋq���__�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�K�p�I����           IS '�ڋq���__�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�X�֔ԍ�             IS '�ڋq���__�X�֔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�Z���P               IS '�ڋq���__�Z���P'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�Z���Q               IS '�ڋq���__�Z���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__�d�b�ԍ�             IS '�ڋq���__�d�b�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__FAX�ԍ�              IS '�ڋq���__FAX�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__������                   IS '���__������'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�h�����N�^���U�֊     IS '���__�h�����N�^���U�֊'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�h�����N�^���U�֊��   IS '���__�h�����N�^���U�֊��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__���[�t�^���U�֊       IS '���__���[�t�^���U�֊'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__���[�t�^���U�֊��     IS '���__���[�t�^���U�֊��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�U�փO���[�v             IS '���__�U�փO���[�v'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�U�փO���[�v��           IS '���__�U�փO���[�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�����u���b�N             IS '���__�����u���b�N'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�����u���b�N��           IS '���__�����u���b�N��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__���_�啪��               IS '���__���_�啪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__���_�啪�ޖ�             IS '���__���_�啪�ޖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__���{���R�[�h             IS '���__���{���R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�V�{���R�[�h             IS '���__�V�{���R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�{���K�p�J�n��           IS '���__�{���K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__���їL���敪             IS '���__���їL���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__���їL���敪��           IS '���__���їL���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�o�׊Ǘ����敪           IS '���__�o�׊Ǘ����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�o�׊Ǘ����敪��         IS '���__�o�׊Ǘ����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�q�֑Ώۉۋ敪         IS '���__�q�֑Ώۉۋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�q�֑Ώۉۋ敪��       IS '���__�q�֑Ώۉۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__���~�q�\���t���O     IS '�ڋq���__���~�q�\���t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq���__���~�q�\���t���O��   IS '�ڋq���__���~�q�\���t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�h�����N���_�J�e�S��     IS '���__�h�����N���_�J�e�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�h�����N���_�J�e�S����   IS '���__�h�����N���_�J�e�S����'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__���[�t���_�J�e�S��       IS '���__���[�t���_�J�e�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__���[�t���_�J�e�S����     IS '���__���[�t���_�J�e�S����'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�o�׈˗������쐬�敪     IS '���__�o�׈˗������쐬�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.���__�o�׈˗������쐬�敪��   IS '���__�o�׈˗������쐬�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq_�����敪                 IS '�ڋq_�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq_�����敪��               IS '�ڋq_�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq_�������㋒�_�R�[�h       IS '�ڋq_�������㋒�_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq_�������㋒�_��           IS '�ڋq_�������㋒�_��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq_�\�񔄏㋒�_�R�[�h       IS '�ڋq_�\�񔄏㋒�_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq_�\�񔄏㋒�_��           IS '�ڋq_�\�񔄏㋒�_��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq_����`�F�[���X           IS '�ڋq_����`�F�[���X'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ڋq_����`�F�[���X��         IS '�ڋq_����`�F�[���X��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�ԍ�                   IS '�z����_�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_����                   IS '�z����_����'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_����                   IS '�z����_����'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�J�i��                 IS '�z����_�J�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�K�p�J�n��             IS '�z����_�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�K�p�I����             IS '�z����_�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�X�e�[�^�X             IS '�z����_�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�X�e�[�^�X��           IS '�z����_�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���_�R�[�h             IS '�z����_���_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���_��                 IS '�z����_���_��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�X�֔ԍ�               IS '�z����_�X�֔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�Z���P                 IS '�z����_�Z���P'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�Z���Q                 IS '�z����_�Z���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�d�b�ԍ�               IS '�z����_�d�b�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_FAX�ԍ�                IS '�z����_FAX�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�N�x����               IS '�z����_�N�x����'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�N�x������             IS '�z����_�N�x������'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�}�X�^��M��           IS '�z����_�}�X�^��M��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���ݒn�X�e�[�^�X       IS '�z����_���ݒn�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���ݒn�X�e�[�^�X��     IS '�z����_���ݒn�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�h�����N��J�����_   IS '�z����_�h�����N��J�����_'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�h�����N��J�����_�� IS '�z����_�h�����N��J�����_��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_JPR���[�U�R�[�h        IS '�z����_JPR���[�U�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�s���{���R�[�h         IS '�z����_�s���{���R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�s���{����             IS '�z����_�s���{����'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�ő���Ɏ��q           IS '�z����_�ő���Ɏ��q'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�w�荀�ڋ敪           IS '�z����_�w�荀�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�w�荀�ڋ敪��         IS '�z����_�w�荀�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�t�ыƖ����t�g�敪     IS '�z����_�t�ыƖ����t�g�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�t�ыƖ����t�g�敪��   IS '�z����_�t�ыƖ����t�g�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�t�ыƖ���p�`�[�敪   IS '�z����_�t�ыƖ���p�`�[�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�t�ыƖ���p�`�[�敪�� IS '�z����_�t�ыƖ���p�`�[�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�t�ыƖ��p���b�g�ϑ�   IS '�z����_�t�ыƖ��p���b�g�ϑ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�t�ыƖ��p���b�g�ϑ֖� IS '�z����_�t�ыƖ��p���b�g�ϑ֖�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�t�ыƖ��ב��敪       IS '�z����_�t�ыƖ��ב��敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�t�ыƖ��ב��敪��     IS '�z����_�t�ыƖ��ב��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�t�ыƖ��p���b�g�J�S   IS '�z����_�t�ыƖ��p���b�g�J�S'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�t�ыƖ��p���b�g�J�S�� IS '�z����_�t�ыƖ��p���b�g�J�S��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���[���敪             IS '�z����_���[���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���[���敪��           IS '�z����_���[���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�i�ϗA���ۋ敪       IS '�z����_�i�ϗA���ۋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�i�ϗA���ۋ敪��     IS '�z����_�i�ϗA���ۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�ʍs���؋敪         IS '�z����_�ʍs���؋敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�ʍs���؋敪��       IS '�z����_�ʍs���؋敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���ꋖ�؋敪         IS '�z����_���ꋖ�؋敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���ꋖ�؋敪��       IS '�z����_���ꋖ�؋敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���q�w��敪           IS '�z����_���q�w��敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���q�w��敪��         IS '�z����_���q�w��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�[�i���A���敪         IS '�z����_�[�i���A���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_�[�i���A���敪��       IS '�z����_�[�i���A���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���[�t��J�����_     IS '�z����_���[�t��J�����_'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_���[�t��J�����_��   IS '�z����_���[�t��J�����_��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�z����_��t���O               IS '�z����_��t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�쐬��                        IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�쐬��                        IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ŏI�X�V��                    IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ŏI�X�V��                    IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����}�X�^_��{_V.�ŏI�X�V���O�C��              IS '�ŏI�X�V���O�C��'
/