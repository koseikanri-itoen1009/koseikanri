CREATE OR REPLACE VIEW APPS.XXSKY_�q�֕ԕiIF_��{_V
(
 �f�[�^���
,RNO
,�v��N��
,���͋��_�R�[�h
,���͋��_��
,���苒�_�R�[�h
,���苒�_��
,�`��
,�`�於
,�v����t_����
,�z����R�[�h
,�z���於
,�ڋq�R�[�h
,�ڋq��
,�`�[NO
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�e�i�ڃR�[�h
,�e�i�ږ�
,�e�i�ڗ���
,�Q�R�[�h
,�P�[�X��
,����
,�o��_�{��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
         XRI.data_class                         --�f�[�^���
        ,XRI.r_no                               --Rno
        ,XRI.recorded_year                      --�v��N��
        ,XRI.input_base_code                    --���͋��_�R�[�h
        ,XCA2V01.party_name                     --���͋��_��
        ,XRI.receive_base_code                  --���苒�_�R�[�h
        ,XCA2V02.party_name                     --���苒�_��
        ,XRI.invoice_class_1                    --�`��
        ,FLV01.meaning                          --�`�於
        ,XRI.recorded_date                      --�v����t_����
        ,XRI.ship_to_code                       --�z����R�[�h
        ,XPS2V.party_site_name                  --�z���於
        ,XRI.customer_code                      --�ڋq�R�[�h
        ,XCA2V03.party_name                     --�ڋq��
        ,XRI.invoice_no                         --�`�[No
        ,XRI.item_code                          --�i�ڃR�[�h
        ,XIM2V01.item_name                      --�i�ږ�
        ,XIM2V01.item_short_name                --�i�ڗ���
        ,XRI.parent_item_code                   --�e�i�ڃR�[�h
        ,XIM2V02.item_name                      --�e�i�ږ�
        ,XIM2V02.item_short_name                --�e�i�ڗ���
        ,XRI.crowd_code                         --�Q�R�[�h
        ,XRI.case_amount_of_content             --�P�[�X��
        ,XRI.quantity_in_case                   --����
        ,XRI.quantity                           --�o��_�{��
        ,FU_CB.user_name                        --�쐬��
        ,TO_CHAR( XRI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --�쐬��
        ,FU_LU.user_name                        --�ŏI�X�V��
        ,TO_CHAR( XRI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --�ŏI�X�V��
        ,FU_LL.user_name                        --�ŏI�X�V���O�C��
FROM
         xxwsh_reserve_interface    XRI         --�q�֕ԕi�C���^�t�F�[�X�e�[�u��(�A�h�I��)
        ,fnd_lookup_values          FLV01       --�N�C�b�N�R�[�h�\(�`�於)
        ,xxsky_party_sites2_v       XPS2V       --SKYLINK�p����VIEW �z������VIEW2(�z���於)
        ,xxsky_cust_accounts2_v     XCA2V01     --SKYLINK�p����VIEW �ڋq���VIEW2(���͋��_��)
        ,xxsky_cust_accounts2_v     XCA2V02     --SKYLINK�p����VIEW �ڋq���VIEW2(���苒�_��)
        ,xxsky_cust_accounts2_v     XCA2V03     --SKYLINK�p����VIEW �ڋq���VIEW2(�ڋq��)
        ,xxsky_item_mst2_v          XIM2V01     --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ږ��A�i�ڗ���)
        ,xxsky_item_mst2_v          XIM2V02     --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�e�i�ږ��A�e�i�ڗ���)
        ,fnd_user                   FU_CB       --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
        ,fnd_user                   FU_LU       --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
        ,fnd_user                   FU_LL       --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
        ,fnd_logins                 FL_LL       --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
        -- ���͋��_��
        XCA2V01.party_number(+)         = XRI.input_base_code
   AND  XCA2V01.start_date_active(+)    <= NVL( XRI.recorded_date, SYSDATE )
   AND  XCA2V01.end_date_active(+)      >= NVL( XRI.recorded_date, SYSDATE )
        -- ���苒�_��
   AND  XCA2V02.party_number(+)         = XRI.receive_base_code
   AND  XCA2V02.start_date_active(+)    <= NVL( XRI.recorded_date, SYSDATE )
   AND  XCA2V02.end_date_active(+)      >= NVL( XRI.recorded_date, SYSDATE )
        -- �`�於
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXWSH_SHIPPING_CLASS'
   AND  FLV01.lookup_code(+)            = XRI.invoice_class_1
        -- �z���於
   AND  XRI.ship_to_code                = XPS2V.party_site_number(+)
   AND  XPS2V.start_date_active(+)      <= NVL( XRI.recorded_date, SYSDATE )
   AND  XPS2V.end_date_active(+)        >= NVL( XRI.recorded_date, SYSDATE )
        -- �ڋq��
   AND  XCA2V03.party_number(+)         = XRI.customer_code
   AND  XCA2V03.start_date_active(+)    <= NVL( XRI.recorded_date, SYSDATE )
   AND  XCA2V03.end_date_active(+)      >= NVL( XRI.recorded_date, SYSDATE )
        -- �i�ږ��A�i�ڗ���
   AND  XIM2V01.item_no(+)              = XRI.item_code
   AND  XIM2V01.start_date_active(+)    <= NVL( XRI.recorded_date, SYSDATE )
   AND  XIM2V01.end_date_active(+)      >= NVL( XRI.recorded_date, SYSDATE )
        -- �e�i�ږ��A�e�i�ڗ���
   AND  XIM2V02.item_no(+)              = XRI.parent_item_code
   AND  XIM2V02.start_date_active(+)    <= NVL( XRI.recorded_date, SYSDATE )
   AND  XIM2V02.end_date_active(+)      >= NVL( XRI.recorded_date, SYSDATE )
        -- ���[�U���Ȃ�
   AND  XRI.created_by                  = FU_CB.user_id(+)
   AND  XRI.last_updated_by             = FU_LU.user_id(+)
   AND  XRI.last_update_login           = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�q�֕ԕiIF_��{_V IS 'SKYLINK�p�q�֕ԕi�C���^�[�t�F�[�X�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�f�[�^���       IS '�f�[�^���'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.RNO              IS 'Rno'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�v��N��         IS '�v��N��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.���͋��_�R�[�h   IS '���͋��_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.���͋��_��       IS '���͋��_��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.���苒�_�R�[�h   IS '���苒�_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.���苒�_��       IS '���苒�_��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�`��             IS '�`��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�`�於           IS '�`�於'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�v����t_����    IS '�v����t_����'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�z����R�[�h     IS '�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�z���於         IS '�z���於'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�ڋq�R�[�h       IS '�ڋq�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�ڋq��           IS '�ڋq��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�`�[NO           IS '�`�[No'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�i�ڃR�[�h       IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�i�ږ�           IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�i�ڗ���         IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�e�i�ڃR�[�h     IS '�e�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�e�i�ږ�         IS '�e�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�e�i�ڗ���       IS '�e�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�Q�R�[�h         IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�P�[�X��         IS '�P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.����             IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�o��_�{��        IS '�o��_�{��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕiIF_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
