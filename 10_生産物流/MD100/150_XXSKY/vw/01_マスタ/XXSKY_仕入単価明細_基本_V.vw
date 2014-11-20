CREATE OR REPLACE VIEW APPS.XXSKY_�d���P������_��{_V
(
 ���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,����i�ڃR�[�h
,����i�ږ�
,����i�ڗ���
,�t�уR�[�h
,���[�J�[�R�[�h
,���[�J�[��
,��ڋ敪
,��ڋ敪��
,���ڋ敪
,���ڋ敪��
,����
,���ʒP��
,�P��
,�P���P��
,������
,�d���P��
,���Z�敪
,���Z�敪��
,�����P��
,�w�b�_ID
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  XPCV.prod_class_code          --���i�敪
       ,XPCV.prod_class_name          --���i�敪��
       ,XICV.item_class_code          --�i�ڋ敪
       ,XICV.item_class_name          --�i�ڋ敪��
       ,XCCV.crowd_code               --�Q�R�[�h
       ,XPL.item_code                 --����i�ڃR�[�h
       ,XIMV.item_name                --����i�ږ�
       ,XIMV.item_short_name          --����i�ڗ���
       ,XPL.futai_code                --�t�уR�[�h
       ,XPL.maker_code                --���[�J�[�R�[�h
       ,XVV.vendor_name               --���[�J�[��
       ,XPL.expense_item_type         --��ڋ敪
       ,FLV01.meaning
        e_item_type_name              --��ڋ敪��
       ,XPL.expense_item_detail_type  --���ڋ敪
       ,FLV02.meaning
        e_item_detail_name            --���ڋ敪��
       ,XPL.quantity                  --����
       ,XPL.quantity_uom              --���ʒP��
       ,XPL.unit_price                --�P��
       ,XPL.unit_price_uom            --�P���P��
       ,XPL.yield_pct                 --������
       ,XPL.purchase_unit_price       --�d���P��
       ,XPL.computation_type          --���Z�敪
       ,FLV03.meaning
        computation_type_name         --���Z�敪��
       ,XPL.real_unit_price           --�����P��
       ,XPL.price_header_id           --�w�b�_ID
       ,FU_CB.user_name               --�쐬��
       ,TO_CHAR( XPL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                      --�쐬��
       ,FU_LU.user_name               --�ŏI�X�V��
       ,TO_CHAR( XPL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                      --�ŏI�X�V��
       ,FU_LL.user_name               --�ŏI�X�V���O�C��
  FROM  xxpo_price_lines    XPL       --�d���^�W���P�����׃A�h�I��
       ,xxpo_price_headers  XPH       --�d���^�W���P���w�b�_�A�h�I��
       ,xxsky_prod_class_v  XPCV      --SKYLINK�p ���i�敪�擾VIEW
       ,xxsky_item_class_v  XICV      --SKYLINK�p �i�ڋ敪�擾VIEW
       ,xxsky_crowd_code_v  XCCV      --SKYLINK�p �S�R�[�h�擾VIEW
       ,xxsky_item_mst_v    XIMV      --OPM�i�ڏ��VIEW
       ,xxsky_vendors_v     XVV       --�d������VIEW
       ,fnd_lookup_values   FLV01     --�N�C�b�N�R�[�h(��ڋ敪��)
       ,fnd_lookup_values   FLV02     --�N�C�b�N�R�[�h(���ڋ敪��)
       ,fnd_lookup_values   FLV03     --�N�C�b�N�R�[�h(���Z�敪��)
       ,fnd_user            FU_CB     --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user            FU_LU     --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user            FU_LL     --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins          FL_LL     --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE  XPH.price_type      = '1'     --�d��
   AND  XPH.price_header_id = XPL.price_header_id
   AND  XPL.item_id      = XPCV.item_id(+)
   AND  XPL.item_id      = XICV.item_id(+)
   AND  XPL.item_id      = XCCV.item_id(+)
   AND  XPL.item_id      = XIMV.item_id(+)
   AND  XPL.maker_id     = XVV.vendor_id(+)
   AND  FLV01.language(+)    = 'JA'                      --����
   AND  FLV01.lookup_type(+) = 'XXPO_EXPENSE_ITEM_TYPE'  --�N�C�b�N�R�[�h�^�C�v
   AND  FLV01.attribute1(+)  = XPL.expense_item_type     --�N�C�b�N�R�[�h
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXPO_EXPENSE_ITEM_DETAIL_TYPE'
   AND  FLV02.attribute1(+)  = XPL.expense_item_detail_type
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXPO_COMPUTATION_TYPE'
   AND  FLV03.lookup_code(+) = XPL.computation_type
   AND  XPL.created_by        = FU_CB.user_id(+)
   AND  XPL.last_updated_by   = FU_LU.user_id(+)
   AND  XPL.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id         = FU_LL.user_id(+)

/

COMMENT ON TABLE APPS.XXSKY_�d���P������_��{_V IS 'SKYLINK�p�d���P�����ׁi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�i�ڋ敪                       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�i�ڋ敪��                     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�Q�R�[�h                       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.����i�ڃR�[�h                 IS '����i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.����i�ږ�                     IS '����i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.����i�ڗ���                   IS '����i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�t�уR�[�h                     IS '�t�уR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.���[�J�[�R�[�h                 IS '���[�J�[�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.���[�J�[��                     IS '���[�J�[��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.��ڋ敪                       IS '��ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.��ڋ敪��                     IS '��ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.���ڋ敪                       IS '���ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.���ڋ敪��                     IS '���ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.����                           IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.���ʒP��                       IS '���ʒP��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�P��                           IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�P���P��                       IS '�P���P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.������                         IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�d���P��                       IS '�d���P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.���Z�敪                       IS '���Z�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.���Z�敪��                     IS '���Z�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�����P��                       IS '�����P��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�w�b�_ID                       IS '�w�b�_ID'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�d���P������_��{_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
