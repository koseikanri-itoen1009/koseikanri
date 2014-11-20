CREATE OR REPLACE VIEW APPS.XXSKY_���i�\_����_V
(
 ���i�\��
,�d����R�[�h
,�d���於
,�d���旪��
,�K�p�J�n��
,�K�p�I����
,�ʉ�
,�ʉݖ�
,�ۂߏ�����
,�L���t���O
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,����_�K�p�J�n��
,����_�K�p�I����
,�P��
,��P��
,�K�p���@
,�K�p���@��
,�l
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        QLHT.name                        --���i�\��
       ,QLHT.name                        --�d����R�[�h
       ,VNDR.vendor_name                 --�d���於
       ,VNDR.vendor_short_name           --�d���旪��
       ,QLHB.start_date_active           --�K�p�J�n��
       ,QLHB.end_date_active             --�K�p�I����
       ,QLHB.currency_code               --�ʉ�
       ,FCT.name                         --�ʉݖ�
       ,QLHB.rounding_factor             --�ۂߏ�����
       ,QLHB.active_flag                 --�L���t���O
       ,XPCV.prod_class_code             --���i�敪
       ,XPCV.prod_class_name             --���i�敪��
       ,XICV.item_class_code             --�i�ڋ敪
       ,XICV.item_class_name             --�i�ڋ敪��
       ,XCCV.crowd_code                  --�Q�R�[�h
       ,XIMV.item_no                     --�i�ڃR�[�h
       ,XIMV.item_name                   --�i�ږ�
       ,XIMV.item_short_name             --�i�ڗ���
       ,QLL.start_date_active            --����_�K�p�J�n��
       ,QLL.end_date_active              --����_�K�p�I����
       ,QPA.product_uom_code             --�P��
       ,QLL.primary_uom_flag             --��P��
       ,QLL.arithmetic_operator          --�K�p���@
       ,FLV01.meaning                    --�K�p���@��
       ,QLL.operand                      --�l
       ,FU_CB.user_name                  --�쐬��
       ,TO_CHAR( QLL.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�쐬��
       ,FU_LU.user_name                  --�ŏI�X�V��
       ,TO_CHAR( QLL.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�ŏI�X�V��
       ,FU_LL.user_name                  --�ŏI�X�V���O�C��
  FROM
        qp_list_headers_b       QLHB     --���i�\�w�b�_
       ,qp_list_lines           QLL      --���i�\����
       ,qp_pricing_attributes   QPA      --���i�\�P�ʃ}�X�^
       ,qp_list_headers_tl      QLHT     --���i�\��
       ,xxsky_vendors_v         VNDR     --�d����}�X�^(���ݓ��t�����p)
       ,fnd_currencies_tl       FCT      --���i�\�ʉ݃}�X�^
       ,xxsky_item_mst_v        XIMV     --OPM�i�ڏ��VIEW(�i��)
       ,xxsky_prod_class_v      XPCV     --OPM�i�ڋ敪VIEW(���i�敪)
       ,xxsky_item_class_v      XICV     --OPM�i�ڋ敪VIEW(�i�ڋ敪)
       ,xxsky_crowd_code_v      XCCV     --OPM�i�ڋ敪VIEW(�Q�R�[�h)
       ,fnd_user                FU_CB    --���[�U�[�}�X�^(created_by���̎擾�p)
       ,fnd_user                FU_LU    --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       ,fnd_user                FU_LL    --���[�U�[�}�X�^(last_update_login���̎擾�p)
       ,fnd_logins              FL_LL    --���O�C���}�X�^(last_update_login���̎擾�p)
       ,fnd_lookup_values       FLV01    --�N�C�b�N�R�[�h(�K�p���@��)
 WHERE
   --���i�\���擾
        QLHB.active_flag <> 'N'
   AND  (  QLHB.start_date_active IS NULL
        OR QLHB.start_date_active <= TRUNC(SYSDATE) )
   AND  (  QLHB.end_date_active IS NULL
        OR QLHB.end_date_active >= TRUNC(SYSDATE) )
   AND  QLHB.list_header_id = QLL.list_header_id
   --���i�\�P�ʃ}�X�^���擾
   AND  QPA.product_attribute_context = 'ITEM'             --���i�R���e�L�X�g���uItem�v
   AND  QPA.product_attribute = 'PRICING_ATTRIBUTE1'       --���i�������u�i�ڔԍ��v
   AND  QLL.list_line_id = QPA.list_line_id
   --���i�\��(�d����R�[�h)�擾
   AND  QLHT.language(+) = 'JA'	
   AND  QLHB.list_header_id = QLHT.list_header_id(+)
   --�d���於�擾
   AND  QLHT.name = VNDR.segment1(+)
   --���i�\�ʉݏ��擾
   AND  FCT.language(+) = 'JA'
   AND  FCT.currency_code(+) = QLHB.currency_code
   --�i�ڏ��擾
   AND  QPA.product_attr_value = XIMV.inventory_item_id(+)
   --�i�ڃJ�e�S�����擾
   AND  XIMV.item_id = XPCV.item_id(+)
   AND  XIMV.item_id = XICV.item_id(+)
   AND  XIMV.item_id = XCCV.item_id(+)
   --WHO�J�������擾
   AND  QLL.created_by        = FU_CB.user_id(+)
   AND  QLL.last_updated_by   = FU_LU.user_id(+)
   AND  QLL.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id        = FU_LL.user_id(+)
   --�y�N�C�b�N�R�[�h�z�K�p���@���擾
   AND  FLV01.language(+)    = 'JA'                        --����
   AND  FLV01.lookup_type(+) = 'ARITHMETIC_OPERATOR'       --�N�C�b�N�R�[�h�^�C�v
   AND  FLV01.lookup_code(+) = QLL.ARITHMETIC_OPERATOR     --�N�C�b�N�R�[�h
/
COMMENT ON TABLE APPS.XXSKY_���i�\_����_V IS 'SKYLINK�p���i�\�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.���i�\��         IS '���i�\��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�d����R�[�h     IS '�d����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�d���於         IS '�d���於'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�d���旪��       IS '�d���旪��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�K�p�J�n��       IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�K�p�I����       IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�ʉ�             IS '�ʉ�'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�ʉݖ�           IS '�ʉݖ�'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�ۂߏ�����       IS '�ۂߏ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�L���t���O       IS '�L���t���O'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.���i�敪         IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.���i�敪��       IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�i�ڋ敪         IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�i�ڋ敪��       IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�Q�R�[�h         IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�i�ڃR�[�h       IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�i�ږ�           IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�i�ڗ���         IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.����_�K�p�J�n��  IS '����_�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.����_�K�p�I����  IS '����_�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�P��             IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.��P��         IS '��P��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�K�p���@         IS '�K�p���@'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�K�p���@��       IS '�K�p���@��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�l               IS '�l'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���i�\_����_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/