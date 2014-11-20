/*************************************************************************
 * 
 * View  Name      : XXSKZ_�q�ɕi��_��{_V
 * Description     : XXSKZ_�q�ɕi��_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�q�ɕi��_��{_V
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
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XILV1.description               --���q�ɖ�
       ,(SELECT XILV1.description
         FROM xxskz_item_locations_v XILV1  --OPM�ۊǏꏊ���VIEW(���q�ɖ��p)
         WHERE XFIL.item_location_id = XILV1.inventory_location_id
        ) XILV1_description
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XPCV.prod_class_code            --���i�敪
       ,XPCV.prod_class_name            --���i�敪��
       ,XICV.item_class_code            --�i�ڋ敪
       ,XICV.item_class_name            --�i�ڋ敪��
       ,XCCV.crowd_code                 --�Q�R�[�h
       ,XFIL.item_code                  --�i�ڃR�[�h
       ,XIMV.item_name                  --�i�ږ�
       ,XIMV.item_short_name            --�i�ڗ���
       ,XFIL.frq_item_location_code     --��\�q�ɃR�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XILV2.description               --��\�q�ɖ�
       ,(SELECT XILV2.description
         FROM xxskz_item_locations_v XILV2  --OPM�ۊǏꏊ���VIEW(��\�q�ɖ��p)
         WHERE XFIL.frq_item_location_id = XILV2.inventory_location_id
        ) XILV2_description
       --,FU_CB.user_name                 --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE XFIL.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XFIL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name                 --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE XFIL.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XFIL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name                 --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE XFIL.last_update_login    = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  xxwsh_frq_item_locations XFIL   --�q�ɕi�ڃA�h�I���}�X�^
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,xxsky_item_locations_v   XILV1  --OPM�ۊǏꏊ���VIEW(���q�ɖ��p)
       --,xxsky_item_locations_v   XILV2  --OPM�ۊǏꏊ���VIEW(��\�q�ɖ��p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
       ,xxskz_prod_class_v       XPCV   --SKYLINK�p ���i�敪�擾VIEW
       ,xxskz_item_class_v       XICV   --SKYLINK�p �i�ڋ敪�擾VIEW
       ,xxskz_crowd_code_v       XCCV   --SKYLINK�p �S�R�[�h�擾VIEW
       ,xxskz_item_mst_v         XIMV   --OPM�i�ڏ��VIEW
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,fnd_user                 FU_CB  --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       --,fnd_user                 FU_LU  --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       --,fnd_user                 FU_LL  --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       --,fnd_logins               FL_LL  --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  XFIL.item_id              = XPCV.item_id(+)
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
   --AND  XFIL.item_id              = XICV.item_id(+)
   --AND  XFIL.item_id              = XCCV.item_id(+)
   AND  XPCV.item_id              = XICV.item_id
   AND  XPCV.item_id              = XCCV.item_id
   AND  XICV.item_id              = XCCV.item_id
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
   AND  XFIL.item_id              = XIMV.item_id(+)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  XFIL.item_location_id     = XILV1.inventory_location_id(+)
   --AND  XFIL.frq_item_location_id = XILV2.inventory_location_id(+)
   --AND  XFIL.created_by           = FU_CB.user_id(+)
   --AND  XFIL.last_updated_by      = FU_LU.user_id(+)
   --AND  XFIL.last_update_login    = FL_LL.login_id(+)
   --AND  FL_LL.user_id             = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKZ_�q�ɕi��_��{_V IS 'SKYLINK�p�q�ɕi�ځi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.���q�ɃR�[�h                   IS '���q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.���q�ɖ�                       IS '���q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.�i�ڋ敪                       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.�i�ڋ敪��                     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.�Q�R�[�h                       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.�i�ڃR�[�h                     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.�i�ږ�                         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.�i�ڗ���                       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.��\�q�ɃR�[�h                 IS '��\�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.��\�q�ɖ�                     IS '��\�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɕi��_��{_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
