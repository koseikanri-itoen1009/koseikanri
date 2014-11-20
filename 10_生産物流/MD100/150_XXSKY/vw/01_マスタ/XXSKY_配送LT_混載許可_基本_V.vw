CREATE OR REPLACE VIEW APPS.XXSKY_�z��LT_���ڋ���_��{_V
(
 �R�[�h�敪�P
,�R�[�h�敪���P
,���o�ɏꏊ�R�[�h�P
,���o�ɏꏊ���P
,�R�[�h�敪�Q
,�R�[�h�敪���Q
,���o�ɏꏊ�R�[�h�Q
,���o�ɏꏊ���Q
,�z��LT_�K�p�J�n��
,�z��LT_�K�p�I����
,�z�����[�h�^�C��
,�h�����N���Y����LT
,���[�t���Y����LT
,����ύXLT
,�o�ו��@
,�o�ו��@��
,�o�ו��@_�K�p�J�n��
,�o�ו��@_�K�p�I����
,�h�����N�ύڏd��
,���[�t�ύڏd��
,�h�����N�ύڗe��
,���[�t�ύڗe��
,�p���b�g�ő喇��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  XDL.code_class1                     code_class1                   --�R�[�h�敪�P
       ,FLV01.meaning                       code_class_name1              --�R�[�h�敪���P
       ,XDL.entering_despatching_code1      entering_despatching_code1    --���o�ɏꏊ�R�[�h�P
       ,ED01.name                           entering_despatching_name1    --���o�ɏꏊ���P
       ,XDL.code_class2                     code_class2                   --�R�[�h�敪�Q
       ,FLV02.meaning                       code_class_name2              --�R�[�h�敪���Q
       ,XDL.entering_despatching_code2      entering_despatching_code2    --���o�ɏꏊ�R�[�h�Q
       ,ED02.name                           entering_despatching_name2    --���o�ɏꏊ���Q
       ,XDL.start_date_active               start_date_active             --�z��LT_�K�p�J�n��
       ,XDL.end_date_active                 end_date_active               --�z��LT_�K�p�I����
       ,XDL.delivery_lead_time              delivery_lead_time            --�z�����[�h�^�C��
       ,XDL.drink_lead_time_day             drink_lead_time_day           --�h�����N���Y����LT
       ,XDL.leaf_lead_time_day              leaf_lead_time_day            --���[�t���Y����LT
       ,XDL.receipt_change_lead_time_day    receipt_change_lead_time_day  --����ύXLT
       ,XSM.ship_method                     ship_method                   --�o�ו��@
       ,FLV03.meaning                       ship_method_name              --�o�ו��@��
       ,XSM.start_date_active               start_date_active             --�o�ו��@_�K�p�J�n��
       ,XSM.end_date_active                 end_date_active               --�o�ו��@_�K�p�I����
       ,XSM.drink_deadweight                drink_deadweight              --�h�����N�ύڏd��
       ,XSM.leaf_deadweight                 leaf_deadweight               --���[�t�ύڏd��
       ,XSM.drink_loading_capacity          drink_loading_capacity        --�h�����N�ύڗe��
       ,XSM.leaf_loading_capacity           leaf_loading_capacity         --���[�t�ύڗe��
       ,XSM.palette_max_qty                 palette_max_qty               --�p���b�g�ő喇��
       ,FU_CB.user_name                     created_by_name               --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XDL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            creation_date                 --�쐬����
       ,FU_LU.user_name                     last_updated_by_name          --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XDL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            last_update_date              --�X�V����
       ,FU_LL.user_name                     last_update_login_name        --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  xxcmn_delivery_lt               XDL                               --�z��LT�A�h�I���}�X�^
       ,xxcmn_ship_methods              XSM                               --�o�ו��@�A�h�I���}�X�^
       ,(--���o�ɏꏊ���P�擾�p
            --�R�[�h�敪��'1:���_'�̏ꍇ�͋��_�����擾
            SELECT 1                    class                             --1:���_
                  ,party_number         code                              --���_No
                  ,party_name           name                              --���_��
              FROM xxsky_cust_accounts_v                                  --�ڋq����_VIEW
          UNION ALL
            --�R�[�h�敪��'4:�q��'�̏ꍇ��OPM�ۊǑq�ɖ����擾
            SELECT 4                    class                             --4:�q��
                  ,segment1             code                              --�ۊǑq��No
                  ,description          name                              --�ۊǑq�ɖ�
              FROM xxsky_item_locations_v                                 --�ۊǑq��
          UNION ALL
            --�R�[�h�敪��'9:�z����'�̏ꍇ�͔z���於���擾
            SELECT 9                    class                             --9:�z����
                  ,party_site_number    code                              --�z����No
                  ,party_site_name      name                              --�z���於
              FROM xxsky_party_sites_v                                    --�z����VIEW
          UNION ALL
            --�R�[�h�敪��'11:�x����'�̏ꍇ�͎x���於���擾
            SELECT 11                   class                             --11:�x����
                  ,vendor_site_code     code                              --�x����No
                  ,vendor_site_name     name                              --�x���於
              FROM xxsky_vendor_sites_v                                   --�d����T�C�gVIEW
        )                               ED01                              --���o�ɏꏊ�P
       ,(--���o�ɏꏊ���Q�擾�p
            --�R�[�h�敪��'1:���_'�̏ꍇ�͋��_�����擾
            SELECT 1                    class                             --1:���_
                  ,party_number         code                              --���_No
                  ,party_name           name                              --���_��
              FROM xxsky_cust_accounts_v                                  --�ڋq����_VIEW
          UNION ALL
            --�R�[�h�敪��'4:�q��'�̏ꍇ��OPM�ۊǑq�ɖ����擾
            SELECT 4                    class                             --4:�q��
                  ,segment1             code                              --�ۊǑq��No
                  ,description          name                              --�ۊǑq�ɖ�
              FROM xxsky_item_locations_v                                 --�ۊǑq��
          UNION ALL
            --�R�[�h�敪��'9:�z����'�̏ꍇ�͔z���於���擾
            SELECT 9                    class                             --9:�z����
                  ,party_site_number    code                              --�z����No
                  ,party_site_name      name                              --�z���於
              FROM xxsky_party_sites_v                                    --�z����VIEW
          UNION ALL
            --�R�[�h�敪��'11:�x����'�̏ꍇ�͎x���於���擾
            SELECT 11                   class                             --11:�x����
                  ,vendor_site_code     code                              --�x����No
                  ,vendor_site_name     name                              --�x���於
              FROM xxsky_vendor_sites_v                                   --�d����T�C�gVIEW
        )                               ED02                              --���o�ɏꏊ�Q
       ,fnd_lookup_values               FLV01                             --�N�C�b�N�R�[�h(�R�[�h�敪��1)
       ,fnd_lookup_values               FLV02                             --�N�C�b�N�R�[�h(�R�[�h�敪��2)
       ,fnd_lookup_values               FLV03                             --�N�C�b�N�R�[�h(�o�ו��@��)
       ,fnd_user                        FU_CB                             --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                        FU_LU                             --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                        FU_LL                             --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                      FL_LL                             --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE  XDL.consolidated_flag = '1'                                       --���ڋ���
   AND  XDL.code_class1 = XSM.code_class1(+)
   AND  XDL.entering_despatching_code1 = XSM.entering_despatching_code1(+)
   AND  XDL.code_class2 = XSM.code_class2(+)
   AND  XDL.entering_despatching_code2 = XSM.entering_despatching_code2(+)
   AND  XDL.code_class1 = ED01.class(+)
   AND  XDL.entering_despatching_code1 = ED01.code(+)
   AND  XDL.code_class2 = ED02.class(+)
   AND  XDL.entering_despatching_code2 = ED02.code(+)
   --�N�C�b�N�R�[�h�F�R�[�h�敪���P�擾
   AND  FLV01.language(+) = 'JA'
   AND  FLV01.lookup_type(+) = 'XXCMN_D06'
   AND  FLV01.lookup_code(+) = XDL.code_class1
   --�N�C�b�N�R�[�h�F�R�[�h�敪���Q�擾
   AND  FLV02.language(+) = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_D06'
   AND  FLV02.lookup_code(+) = XDL.code_class2
   --�N�C�b�N�R�[�h�F�o�ו��@���擾
   AND  FLV03.language(+) = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV03.lookup_code(+) = XSM.ship_method
   --WHO�J�����擾
   AND  XDL.created_by = FU_CB.user_id(+)
   AND  XDL.last_updated_by = FU_LU.user_id(+)
   AND  XDL.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�z��LT_���ڋ���_��{_V IS 'SKYLINK�p�z��LT�}�X�^_���ڋ��i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�R�[�h�敪�P        IS '�R�[�h�敪�P'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�R�[�h�敪���P      IS '�R�[�h�敪���P'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.���o�ɏꏊ�R�[�h�P  IS '���o�ɏꏊ�R�[�h�P'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.���o�ɏꏊ���P      IS '���o�ɏꏊ���P'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�R�[�h�敪�Q        IS '�R�[�h�敪�Q'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�R�[�h�敪���Q      IS '�R�[�h�敪���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.���o�ɏꏊ�R�[�h�Q  IS '���o�ɏꏊ�R�[�h�Q'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.���o�ɏꏊ���Q      IS '���o�ɏꏊ���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�z��LT_�K�p�J�n��   IS '�z��LT_�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�z��LT_�K�p�I����   IS '�z��LT_�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�z�����[�h�^�C��    IS '�z�����[�h�^�C��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�h�����N���Y����LT  IS '�h�����N���Y����LT'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.���[�t���Y����LT    IS '���[�t���Y����LT'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.����ύXLT          IS '����ύXLT'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�o�ו��@            IS '�o�ו��@'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�o�ו��@��          IS '�o�ו��@��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�o�ו��@_�K�p�J�n�� IS '�o�ו��@_�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�o�ו��@_�K�p�I���� IS '�o�ו��@_�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�h�����N�ύڏd��    IS '�h�����N�ύڏd��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.���[�t�ύڏd��      IS '���[�t�ύڏd��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�h�����N�ύڗe��    IS '�h�����N�ύڗe��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.���[�t�ύڗe��      IS '���[�t�ύڗe��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�p���b�g�ő喇��    IS '�p���b�g�ő喇��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�쐬��              IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�쐬��              IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�ŏI�X�V��          IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�ŏI�X�V��          IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�z��LT_���ڋ���_��{_V.�ŏI�X�V���O�C��    IS '�ŏI�X�V���O�C��'
/
