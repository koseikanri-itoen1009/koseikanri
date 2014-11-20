CREATE OR REPLACE VIEW APPS.XXSKY_�z����IF_��{_V
(
 SEQ�ԍ�
,�X�V�敪
,�X�V�敪��
,���_�R�[�h
,���_��
,�z����R�[�h
,�z���於�P
,�z���於�Q
,�z����Z���P
,�z����Z���Q
,�d�b�ԍ�
,FAX�ԍ�
,�X�֔ԍ�
,�X�֔ԍ��Q
,�ڋq�R�[�h
,�ڋq���P
,�ڋq���Q
,�������㋒�_�R�[�h
,�������㋒�_��
,����_�\�񔄏㋒�_�R�[�h
,����_�\�񔄏㋒�_��
,����`�F�[���X
,����`�F�[���X��
,���~�q�\���t���O
,���~�q�\���t���O��
,�����敪
,�����敪��
)
AS
SELECT 
        XSI.seq_number                              --SEQ�ԍ�
       ,XSI.proc_code                               --�X�V�敪
       ,CASE XSI.proc_code                          --�X�V�敪��
            WHEN    1   THEN    '�o�^'
            WHEN    2   THEN    '�X�V'
            WHEN    3   THEN    '�폜'
        END                     proc_name
       ,XSI.base_code                               --���_�R�[�h
       ,XCAV01.party_name       party_name          --���_��
       ,XSI.ship_to_code                            --�z����R�[�h
       ,XSI.party_site_name1                        --�z���於�P
       ,XSI.party_site_name2                        --�z���於�Q
       ,XSI.party_site_addr1                        --�z����Z���P
       ,XSI.party_site_addr2                        --�z����Z���Q
       ,XSI.phone                                   --�d�b�ԍ�
       ,XSI.fax                                     --FAX�ԍ�
       ,XSI.ZIP                                     --�X�֔ԍ�
       ,XSI.ZIP2                                    --�X�֔ԍ��Q
       ,XSI.party_num                               --�ڋq�R�[�h
       ,XSI.customer_name1                          --�ڋq���P
       ,XSI.customer_name2                          --�ڋq���Q
       ,XSI.sale_base_code                          --�������㋒�_�R�[�h
       ,XCAV02.party_name       sale_base_name      --�������㋒�_��
       ,XSI.res_sale_base_code                      --����_�\�񔄏㋒�_�R�[�h
       ,XCAV03.party_name       res_sale_base_name  --����_�\�񔄏㋒�_��
       ,XSI.chain_store                             --����`�F�[���X
       ,XSI.chain_store_name                        --����`�F�[���X��
       ,XSI.cal_cust_app_flg                        --���~�q�\���t���O
       ,FLV01.meaning                               --���~�q�\���t���O��
       ,XSI.direct_ship_code                        --�����敪
       ,FLV02.meaning                               --�����敪��
  FROM  xxcmn_site_if           XSI                 --�z����C���^�t�F�[�X
       ,xxsky_cust_accounts_v   XCAV01              --SKYLINK�p����VIEW ���_�R�[�h�擾VIEW
       ,xxsky_cust_accounts_v   XCAV02              --SKYLINK�p����VIEW ���_�R�[�h�擾VIEW
       ,xxsky_cust_accounts_v   XCAV03              --SKYLINK�p����VIEW ���_�R�[�h�擾VIEW
       ,fnd_lookup_values       FLV01               --���~�q�\���t���O���擾�p
       ,fnd_lookup_values       FLV02               --�����敪���擾�p
 WHERE
   --���_���擾����
        XCAV01.party_number(+)  = XSI.base_code
   --�������㋒�_���擾����
   AND  XCAV02.party_number(+)  = XSI.sale_base_code
   --����_�\�񔄏㋒�_���擾����
   AND  XCAV03.party_number(+)  = XSI.res_sale_base_code
   --���~�q�\���t���O���擾����
   AND  FLV01.language(+)       = 'JA'
   AND  FLV01.lookup_type(+)    = 'XXCMN_CUST_ENABLE_FLAG'
   AND  FLV01.lookup_code(+)    = XSI.cal_cust_app_flg
   --�����敪���擾����
   AND  FLV02.language(+)       = 'JA'
   AND  FLV02.lookup_type(+)    = 'XXCMN_DROP_SHIP_DIV'
   AND  FLV02.lookup_code(+)    = XSI.direct_ship_code
/
COMMENT ON TABLE APPS.XXSKY_�z����IF_��{_V                             IS 'SKYLINK�p�z����IF�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.SEQ�ԍ�                    IS 'SEQ�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�X�V�敪                   IS '�X�V�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�X�V�敪��                 IS '�X�V�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.���_�R�[�h                 IS '���_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.���_��                     IS '���_��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�z����R�[�h               IS '�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�z���於�P                 IS '�z���於�P'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�z���於�Q                 IS '�z���於�Q'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�z����Z���P               IS '�z����Z���P'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�z����Z���Q               IS '�z����Z���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�d�b�ԍ�                   IS '�d�b�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.FAX�ԍ�                    IS 'FAX�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�X�֔ԍ�                   IS '�X�֔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�X�֔ԍ��Q                 IS '�X�֔ԍ��Q'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�ڋq�R�[�h                 IS '�ڋq�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�ڋq���P                   IS '�ڋq���P'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�ڋq���Q                   IS '�ڋq���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�������㋒�_�R�[�h         IS '�������㋒�_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�������㋒�_��             IS '�������㋒�_��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.����_�\�񔄏㋒�_�R�[�h    IS '����_�\�񔄏㋒�_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.����_�\�񔄏㋒�_��        IS '����_�\�񔄏㋒�_��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.����`�F�[���X             IS '����`�F�[���X'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.����`�F�[���X��           IS '����`�F�[���X��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.���~�q�\���t���O           IS '���~�q�\���t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.���~�q�\���t���O��         IS '���~�q�\���t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�����敪                   IS '�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z����IF_��{_V.�����敪��                 IS '�����敪��'
/