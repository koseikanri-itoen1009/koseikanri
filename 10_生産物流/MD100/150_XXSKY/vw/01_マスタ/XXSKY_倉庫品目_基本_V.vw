CREATE OR REPLACE VIEW APPS.XXSKY_�q�ɕi��_��{_V
(
 ���q�ɃR�[�h
,���q�ɖ�
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,��\�q�ɃR�[�h
,��\�q�ɖ�
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  XFIL.item_location_code         --���q�ɃR�[�h
       ,XILV1.description               --���q�ɖ�
       ,XPCV.prod_class_code            --���i�敪
       ,XPCV.prod_class_name            --���i�敪��
       ,XICV.item_class_code            --�i�ڋ敪
       ,XICV.item_class_name            --�i�ڋ敪��
       ,XCCV.crowd_code                 --�Q�R�[�h
       ,XFIL.item_code                  --�i�ڃR�[�h
       ,XIMV.item_name                  --�i�ږ�
       ,XIMV.item_short_name            --�i�ڗ���
       ,XFIL.frq_item_location_code     --��\�q�ɃR�[�h
       ,XILV2.description               --��\�q�ɖ�
       ,FU_CB.user_name                 --�쐬��
       ,TO_CHAR( XFIL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --�쐬��
       ,FU_LU.user_name                 --�ŏI�X�V��
       ,TO_CHAR( XFIL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --�ŏI�X�V��
       ,FU_LL.user_name                 --�ŏI�X�V���O�C��
  FROM  xxwsh_frq_item_locations XFIL   --�q�ɕi�ڃA�h�I���}�X�^
       ,xxsky_item_locations_v   XILV1  --OPM�ۊǏꏊ���VIEW(���q�ɖ��p)
       ,xxsky_item_locations_v   XILV2  --OPM�ۊǏꏊ���VIEW(��\�q�ɖ��p)
       ,xxsky_prod_class_v       XPCV   --SKYLINK�p ���i�敪�擾VIEW
       ,xxsky_item_class_v       XICV   --SKYLINK�p �i�ڋ敪�擾VIEW
       ,xxsky_crowd_code_v       XCCV   --SKYLINK�p �S�R�[�h�擾VIEW
       ,xxsky_item_mst_v         XIMV   --OPM�i�ڏ��VIEW
       ,fnd_user                 FU_CB  --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                 FU_LU  --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                 FU_LL  --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins               FL_LL  --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE  XFIL.item_id              = XPCV.item_id(+)
   AND  XFIL.item_id              = XICV.item_id(+)
   AND  XFIL.item_id              = XCCV.item_id(+)
   AND  XFIL.item_id              = XIMV.item_id(+)
   AND  XFIL.item_location_id     = XILV1.inventory_location_id(+)
   AND  XFIL.frq_item_location_id = XILV2.inventory_location_id(+)
   AND  XFIL.created_by           = FU_CB.user_id(+)
   AND  XFIL.last_updated_by      = FU_LU.user_id(+)
   AND  XFIL.last_update_login    = FL_LL.login_id(+)
   AND  FL_LL.user_id             = FU_LL.user_id(+)

/

COMMENT ON TABLE APPS.XXSKY_�q�ɕi��_��{_V IS 'SKYLINK�p�q�ɕi�ځi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.���q�ɃR�[�h                   IS '���q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.���q�ɖ�                       IS '���q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.�i�ڋ敪                       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.�i�ڋ敪��                     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.�Q�R�[�h                       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.�i�ڃR�[�h                     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.�i�ږ�                         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.�i�ڗ���                       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.��\�q�ɃR�[�h                 IS '��\�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.��\�q�ɖ�                     IS '��\�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�ɕi��_��{_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
