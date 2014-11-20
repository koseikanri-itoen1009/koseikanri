CREATE OR REPLACE VIEW APPS.XXSKY_���_IF_��{_V
(
 SEQ�ԍ�
,�X�V�敪
,�X�V�敪��
,���_�R�[�h
,���_��
,���_����
,���_�J�i��
,�Z��
,�X�֔ԍ�
,�X�֔ԍ��Q
,�d�b�ԍ�
,FAX�ԍ�
,��_�{���R�[�h
,�V_�{���R�[�h
,�{��_�K�p�J�n��
,���_���їL���敪
,���_���їL���敪��
,�o�ɊǗ����敪
,�o�ɊǗ����敪��
,�{��_�n�於
,�q�֑Ώۉۋ敪
,�q�֑Ώۉۋ敪��
,�[���L���敪
,�[���L���敪��
,�\��
)
AS
SELECT 
        XPI.seq_number                      --SEQ�ԍ�
       ,XPI.proc_code                       --�X�V�敪
       ,CASE XPI.proc_code                  --�X�V�敪��
            WHEN    1   THEN    '�o�^'
            WHEN    2   THEN    '�X�V'
            WHEN    3   THEN    '�폜'
        END                     proc_name
       ,XPI.base_code                       --���_�R�[�h
       ,XPI.party_name                      --���_��
       ,XPI.party_short_name                --���_����
       ,XPI.party_name_alt                  --���_�J�i��
       ,XPI.address                         --�Z��
       ,XPI.ZIP                             --�X�֔ԍ�
       ,XPI.ZIP2                            --�X�֔ԍ��Q
       ,XPI.phone                           --�d�b�ԍ�
       ,XPI.fax                             --FAX�ԍ�
       ,XPI.old_division_code               --��_�{���R�[�h
       ,XPI.new_division_code               --�V_�{���R�[�h
       ,XPI.division_start_date             --�{��_�K�p�J�n��
       ,XPI.location_rel_code               --���_���їL���敪
       ,FLV01.meaning                       --���_���їL���敪��
       ,XPI.ship_mng_code                   --�o�ɊǗ����敪
       ,FLV02.meaning                       --�o�ɊǗ����敪��
       ,XPI.district_code                   --�{��_�n�於
       ,XPI.warehouse_code                  --�q�֑Ώۉۋ敪
       ,FLV03.meaning                       --�q�֑Ώۉۋ敪��
       ,XPI.terminal_code                   --�[���L���敪
       ,CASE XPI.terminal_code              --�[���L���敪��
            WHEN    '0' THEN    '��'
            WHEN    '1' THEN    '�L'
        END                 terminal_name
       ,XPI.spare                           --�\��
  FROM  xxcmn_party_if      XPI             --���_�C���^�t�F�[�X
       ,fnd_lookup_values   FLV01           --���_���їL���敪���擾�p
       ,fnd_lookup_values   FLV02           --�o�ɊǗ����敪���擾�p
       ,fnd_lookup_values   FLV03           --�q�֑Ώۉۋ敪���擾�p
 WHERE
   --���_���їL���敪���擾����
        FLV01.language(+)       = 'JA'
   AND  FLV01.lookup_type(+)    = 'XXCMN_BASE_RESULTS_CLASS'
   AND  FLV01.lookup_code(+)    = XPI.location_rel_code
   --�o�ɊǗ����敪���擾����
   AND  FLV02.language(+)       = 'JA'
   AND  FLV02.lookup_type(+)    = 'XXCMN_SHIPMENT_MANAGEMENT'
   AND  FLV02.lookup_code(+)    = XPI.ship_mng_code
   --�q�֑Ώۉۋ敪���擾����
   AND  FLV03.language(+)       = 'JA'
   AND  FLV03.lookup_type(+)    = 'XXCMN_INV_OBJEC_CLASS'
   AND  FLV03.lookup_code(+)    = XPI.warehouse_code
/
COMMENT ON TABLE APPS.XXSKY_���_IF_��{_V                       IS 'SKYLINK�p���_IF�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.SEQ�ԍ�              IS 'SEQ�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�X�V�敪             IS '�X�V�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�X�V�敪��           IS '�X�V�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.���_�R�[�h           IS '���_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.���_��               IS '���_��'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.���_����             IS '���_����'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.���_�J�i��           IS '���_�J�i��'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�Z��                 IS '�Z��'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�X�֔ԍ�             IS '�X�֔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�X�֔ԍ��Q           IS '�X�֔ԍ��Q'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�d�b�ԍ�             IS '�d�b�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.FAX�ԍ�              IS 'FAX�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.��_�{���R�[�h        IS '��_�{���R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�V_�{���R�[�h        IS '�V_�{���R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�{��_�K�p�J�n��      IS '�{��_�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.���_���їL���敪     IS '���_���їL���敪'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.���_���їL���敪��   IS '���_���їL���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�o�ɊǗ����敪       IS '�o�ɊǗ����敪'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�o�ɊǗ����敪��     IS '�o�ɊǗ����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�{��_�n�於          IS '�{��_�n�於'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�q�֑Ώۉۋ敪     IS '�q�֑Ώۉۋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�q�֑Ώۉۋ敪��   IS '�q�֑Ώۉۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�[���L���敪         IS '�[���L���敪'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�[���L���敪��       IS '�[���L���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���_IF_��{_V.�\��                 IS '�\��'
/