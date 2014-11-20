/*************************************************************************
 * 
 * View  Name      : XXSKZ_���V�s_����_V
 * Description     : XXSKZ_���V�s_����_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_���V�s_����_V
(
 ���V�s�ԍ�
,���V�s����
,���V�s�E�v
,�o�[�W����
,�X�e�[�^�X
,�X�e�[�^�X��
,���L�ґg�D�R�[�h
,���L�ґg�D��
,�쐬�g�D�R�[�h
,�쐬�g�D��
,�t�H�[�~�����ԍ�
,�t�H�[�~��������
,�t�H�[�~�������̂Q
,�t�H�[�~�����E�v
,�t�H�[�~�����E�v�Q
,�H���ԍ�
,�H����
,���B�敪
,���B�敪��
,���x
,�Ǘ��敪
,�Ǘ��敪��
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,���V�s�g�p
,�Ó������[�����t_��
,�Ó������[�����t_��
,�ŏ�����
,�ő吔��
,�W������
,�P��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  GRB.recipe_no                        --���V�s�ԍ�
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,GRT.recipe_description               --���V�s����
       ,(SELECT GRT.recipe_description
         FROM GMD_RECIPES_TL GRT      --���V�s�}�X�^(����)
         WHERE GRT.recipe_id = GRB.recipe_id
         AND   GRT.language  = 'JA'
        ) GRT_recipe_description
       --,GRT.recipe_description               --���V�s�E�v
       ,(SELECT GRT.recipe_description
         FROM GMD_RECIPES_TL GRT      --���V�s�}�X�^(����)
         WHERE GRT.recipe_id = GRB.recipe_id
         AND   GRT.language  = 'JA'
        ) GRT_recipe_description2
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.recipe_version                   --�o�[�W����
       ,GRB.recipe_status                    --�X�e�[�^�X
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,GQST.meaning                         --�X�e�[�^�X��
       ,(SELECT GQST.meaning
         FROM GMD_QC_STATUS_TL GQST     --
         WHERE GQST.status_code = GRB.recipe_status
         AND   GQST.language    = 'JA'
         AND   GQST.entity_type = 'S'
        ) GQST_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.owner_orgn_code                  --���L�ґg�D�R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,SOMT01.orgn_name                     --���L�ґg�D��
       ,(SELECT SOMT01.orgn_name
         FROM SY_ORGN_MST_TL SOMT01   --OPM�v�����g�}�X�^���{��(���L�ґg�D��)
         WHERE SOMT01.orgn_code = GRB.owner_orgn_code
         AND   SOMT01.language  = 'JA'
        ) SOMT01_orgn_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.creation_orgn_code               --�쐬�g�D�R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,SOMT02.orgn_name                     --�쐬�g�D��
       ,(SELECT SOMT02.orgn_name
         FROM SY_ORGN_MST_TL SOMT02   --OPM�v�����g�}�X�^���{��(�쐬�g�D��)
         WHERE SOMT02.orgn_code = GRB.creation_orgn_code
         AND   SOMT02.language  = 'JA'
        ) SOMT02_orgn_name
       --,FFMB.formula_no                      --�t�H�[�~�����ԍ�
       ,(SELECT FFMB.formula_no
         FROM FM_FORM_MST_B FFMB     --�t�H�[�~�����}�X�^
         WHERE FFMB.formula_id = GRB.formula_id
        ) FFMB_formula_no
       --,FFMT.formula_desc1                   --�t�H�[�~��������
       ,(SELECT FFMT.formula_desc1
         FROM FM_FORM_MST_TL FFMT     --�t�H�[�~�����}�X�^(���{��)
         WHERE FFMT.formula_id = GRB.formula_id
         AND   FFMT.language   = 'JA'
        ) FFMT_formula_desc1
       --,FFMT.formula_desc2                   --�t�H�[�~�������̂Q
       ,(SELECT FFMT.formula_desc2
         FROM FM_FORM_MST_TL FFMT     --�t�H�[�~�����}�X�^(���{��)
         WHERE FFMT.formula_id = GRB.formula_id
         AND   FFMT.language   = 'JA'
        ) FFMT_formula_desc2
       --,FFMT.formula_desc1                   --�t�H�[�~�����E�v
       ,(SELECT FFMT.formula_desc1
         FROM FM_FORM_MST_TL FFMT     --�t�H�[�~�����}�X�^(���{��)
         WHERE FFMT.formula_id = GRB.formula_id
         AND   FFMT.language   = 'JA'
        ) FFMT_formula_desc11
       --,FFMT.formula_desc2                   --�t�H�[�~�����E�v�Q
       ,(SELECT FFMT.formula_desc2
         FROM FM_FORM_MST_TL FFMT     --�t�H�[�~�����}�X�^(���{��)
         WHERE FFMT.formula_id = GRB.formula_id
         AND   FFMT.language   = 'JA'
        ) FFMT_formula_desc22
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GROB.routing_no                      --�H���ԍ�
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,GROT.routing_desc                    --�H����
       ,(SELECT GROT.routing_desc
         FROM GMD_ROUTINGS_TL GROT     --�H���}�X�^(���{��)
         WHERE GROT.routing_id = GRB.routing_id
         AND   GROT.language   = 'JA'
        ) GROT_routing_desc
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute1                       --���B�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV01.meaning
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01    --�N�C�b�N�R�[�h(���B�敪��)
         WHERE FLV01.language    = 'JA'
         AND   FLV01.lookup_type = 'XXCMN_K02'
         AND   FLV01.lookup_code = GRB.attribute1
        ) tyoutatsu_kbn                        --���B�敪��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute2                       --���x
       ,GRB.attribute3                       --�Ǘ��敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV02.meaning
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02    --�N�C�b�N�R�[�h(�Ǘ��敪��)
         WHERE FLV02.language    = 'JA'
         AND   FLV02.lookup_type = 'XXCMN_K07'
         AND   FLV02.lookup_code = GRB.attribute3
        ) kanri_kbn                            --�Ǘ��敪��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XIMV.item_no                         --�i�ڃR�[�h
       ,XIMV.item_name                       --�i�ږ�
       ,XIMV.item_short_name                 --�i�ڗ���
       ,XPCV.prod_class_code                 --���i�敪
       ,XPCV.prod_class_name                 --���i�敪��
       ,XICV.item_class_code                 --�i�ڋ敪
       ,XICV.item_class_name                 --�i�ڋ敪��
       ,XCCV.crowd_code                      --�Q�R�[�h
       ,GRVR.recipe_use                      --���V�s�g�p
       ,GRVR.start_date                      --�Ó������[�����t_��
       ,GRVR.end_date                        --�Ó������[�����t_��
       ,GRVR.min_qty                         --�ŏ�����
       ,GRVR.max_qty                         --�ő吔��
       ,GRVR.std_qty                         --�W������
       ,GRVR.item_um                         --�P��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_CB.user_name                      --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE GRB.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( GRB.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                             --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name                      --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE GRB.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( GRB.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                             --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name                      --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE GRB.last_update_login   = FL_LL.login_id
         AND   FL_LL.user_id           = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  GMD_RECIPES_B               GRB      --���V�s�}�X�^
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,GMD_RECIPES_TL              GRT      --���V�s�}�X�^(����)
       --,GMD_QC_STATUS_TL            GQST     --
       --,SY_ORGN_MST_TL              SOMT01   --OPM�v�����g�}�X�^���{��(���L�ґg�D��)
       --,SY_ORGN_MST_TL              SOMT02   --OPM�v�����g�}�X�^���{��(�쐬�g�D��)
       --,FM_FORM_MST_B               FFMB     --�t�H�[�~�����}�X�^
       --,FM_FORM_MST_TL              FFMT     --�t�H�[�~�����}�X�^(���{��)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
       ,GMD_ROUTINGS_B              GROB     --�H���}�X�^
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,GMD_ROUTINGS_TL             GROT     --�H���}�X�^(���{��)
       --,fnd_lookup_values           FLV01    --�N�C�b�N�R�[�h(���B�敪��)
       --,fnd_lookup_values           FLV02    --�N�C�b�N�R�[�h(�Ǘ��敪��)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
       ,XXSKZ_ITEM_MST_V            XIMV     --�i�ڏ��VIEW
       ,XXSKZ_PROD_CLASS_V          XPCV     --���i�敪���VIEW
       ,XXSKZ_ITEM_CLASS_V          XICV     --�i�ڋ敪���VIEW
       ,XXSKZ_CROWD_CODE_V          XCCV     --�S�R�[�h���VIEW
       ,GMD_RECIPE_VALIDITY_RULES   GRVR     --�Ó������[��
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,fnd_user                    FU_CB    --���[�U�[�}�X�^(created_by���̎擾�p)
       --,fnd_user                    FU_LU    --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       --,fnd_user                    FU_LL    --���[�U�[�}�X�^(last_update_login���̎擾�p)
       --,fnd_logins                  FL_LL    --���O�C���}�X�^(last_update_login���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
WHERE   GROB.routing_class     <> '70'       --�w�i�ڐU�ցx�ΏۊO
  AND   GRB.delete_mark         = 0          --�w�폜�t���O�x�� '1:�폜'�ł͂Ȃ�
  AND   GROB.routing_id         = GRB.routing_id
  AND   GRB.recipe_id           = GRVR.recipe_id
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
  --AND   GRT.recipe_id(+)        = GRB.recipe_id
  --AND   GRT.language            = 'JA'
  --AND   GQST.status_code(+)     = GRB.recipe_status
  --AND   GQST.language(+)        = 'JA'
  --AND   GQST.entity_type(+)     = 'S'
  --AND   SOMT01.orgn_code(+)     = GRB.owner_orgn_code
  --AND   SOMT01.language         = 'JA'
  --AND   SOMT02.orgn_code(+)     = GRB.creation_orgn_code
  --AND   SOMT02.language         = 'JA'
  --AND   FFMB.formula_id(+)      = GRB.formula_id
  --AND   FFMT.formula_id(+)      = GRB.formula_id
  --AND   FFMT.language           = 'JA'
  --AND   GROT.routing_id(+)      = GRB.routing_id
  --AND   GROT.language           = 'JA'
  --AND   FLV01.language(+)       = 'JA'
  --AND   FLV01.lookup_type(+)    = 'XXCMN_K02'
  --AND   FLV01.lookup_code(+)    = GRB.attribute1
  --AND   FLV02.language(+)       = 'JA'
  --AND   FLV02.lookup_type(+)    = 'XXCMN_K07'
  --AND   FLV02.lookup_code(+)    = GRB.attribute3
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
  AND   XIMV.item_id(+)         = GRVR.item_id
  AND   XPCV.item_id(+)         = GRVR.item_id
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
  --AND   XICV.item_id(+)         = GRVR.item_id
  --AND   XCCV.item_id(+)         = GRVR.item_id
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
  AND   XICV.item_id            = XPCV.item_id
  AND   XCCV.item_id            = XPCV.item_id
  AND   XICV.item_id            = XCCV.item_id
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
  --AND   GRB.created_by          = FU_CB.user_id(+)
  --AND   GRB.last_updated_by     = FU_LU.user_id(+)
  --AND   GRB.last_update_login   = FL_LL.login_id(+)
  --AND   FL_LL.user_id           = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKZ_���V�s_����_V IS 'SKYLINK�p���V�s�}�X�^�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.���V�s�ԍ�                     IS '���V�s�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.���V�s����                     IS '���V�s����'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.���V�s�E�v                     IS '���V�s�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�o�[�W����                     IS '�o�[�W����'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�X�e�[�^�X                     IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�X�e�[�^�X��                   IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.���L�ґg�D�R�[�h               IS '���L�ґg�D�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.���L�ґg�D��                   IS '���L�ґg�D��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�쐬�g�D�R�[�h                 IS '�쐬�g�D�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�쐬�g�D��                     IS '�쐬�g�D��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�t�H�[�~�����ԍ�               IS '�t�H�[�~�����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�t�H�[�~��������               IS '�t�H�[�~��������'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�t�H�[�~�������̂Q             IS '�t�H�[�~�������̂Q'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�t�H�[�~�����E�v               IS '�t�H�[�~�����E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�t�H�[�~�����E�v�Q             IS '�t�H�[�~�����E�v�Q'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�H���ԍ�                       IS '�H���ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�H����                         IS '�H����'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.���B�敪                       IS '���B�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.���B�敪��                     IS '���B�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.���x                       IS '���x'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�Ǘ��敪                       IS '�Ǘ��敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�Ǘ��敪��                     IS '�Ǘ��敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�i�ڃR�[�h                     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�i�ږ�                         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�i�ڗ���                       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�i�ڋ敪                       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�i�ڋ敪��                     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�Q�R�[�h                       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.���V�s�g�p                     IS '���V�s�g�p'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�Ó������[�����t_��            IS '�Ó������[�����t_��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�Ó������[�����t_��            IS '�Ó������[�����t_��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�ŏ�����                       IS '�ŏ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�ő吔��                       IS '�ő吔��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�W������                       IS '�W������'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�P��                           IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���V�s_����_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
