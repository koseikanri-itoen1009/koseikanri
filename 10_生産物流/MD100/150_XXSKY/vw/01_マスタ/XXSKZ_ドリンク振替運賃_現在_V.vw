/*************************************************************************
 * 
 * View  Name      : XXSKZ_�h�����N�U�։^��_����_V
 * Description     : XXSKZ_�h�����N�U�։^��_����_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�h�����N�U�։^��_����_V
(
 ���i����
,���i���ޖ�
,�z���敪
,�z���敪��
,���_�啪��
,���_�啪�ޖ�
,�K�p�J�n��
,�K�p�I����
,�ݒ�P��
,�y�i���e�B�P��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  
        XDTDC.godds_classification          --���i����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV01.meaning                       --���i���ޖ�
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01  --�N�C�b�N�R�[�h(���i���ޖ�)
         WHERE FLV01.language   = 'JA'                        --����
         AND  FLV01.lookup_type = 'XXCMN_D02'                 --�N�C�b�N�R�[�h�^�C�v
         AND  FLV01.lookup_code = XDTDC.godds_classification  --�N�C�b�N�R�[�h
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDTDC.dellivary_classe              --�z���敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV02.meaning                       --�z���敪��
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02  --�N�C�b�N�R�[�h(�z���敪��)
         WHERE FLV02.language   = 'JA'
         AND  FLV02.lookup_type = 'XXCMN_SHIP_METHOD'
         AND  FLV02.lookup_code = XDTDC.dellivary_classe
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDTDC.foothold_macrotaxonomy        --���_�啪��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV03.meaning                       --���_�啪�ޖ�
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03  --�N�C�b�N�R�[�h(�z���敪��)
         WHERE FLV03.language   = 'JA'
         AND  FLV03.lookup_type = 'XXWIP_BASE_MAJOR_DIVISION'
         AND  FLV03.lookup_code = XDTDC.foothold_macrotaxonomy
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDTDC.start_date_active             --�K�p�J�n��
       ,XDTDC.end_date_active               --�K�p�I����
       ,XDTDC.setting_amount                --�ݒ�P��
       ,XDTDC.penalty_amount                --�y�i���e�B�P��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_CB.user_name                     --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE XDTDC.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XDTDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name                     --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE XDTDC.last_updated_by   = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XDTDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name                     --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE XDTDC.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id           = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  xxwip_drink_trans_deli_chrgs XDTDC  --�h�����N�U�։^���A�h�I���}�X�^
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,fnd_user                     FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
       --,fnd_user                     FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       --,fnd_user                     FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
       --,fnd_logins                   FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
       --,fnd_lookup_values            FLV01  --�N�C�b�N�R�[�h(���i���ޖ�)
       --,fnd_lookup_values            FLV02  --�N�C�b�N�R�[�h(�z���敪��)
       --,fnd_lookup_values            FLV03  --�N�C�b�N�R�[�h(���_�啪�ޖ�)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  XDTDC.start_date_active <= TRUNC(SYSDATE)
   AND  XDTDC.end_date_active   >= TRUNC(SYSDATE)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  XDTDC.created_by        = FU_CB.user_id(+)
   --AND  XDTDC.last_updated_by   = FU_LU.user_id(+)
   --AND  XDTDC.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id           = FU_LL.user_id(+)
   --AND  FLV01.language(+)    = 'JA'                        --����
   --AND  FLV01.lookup_type(+) = 'XXCMN_D02'                 --�N�C�b�N�R�[�h�^�C�v
   --AND  FLV01.lookup_code(+) = XDTDC.godds_classification  --�N�C�b�N�R�[�h
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   --AND  FLV02.lookup_code(+) = XDTDC.dellivary_classe
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXWIP_BASE_MAJOR_DIVISION'
   --AND  FLV03.lookup_code(+) = XDTDC.foothold_macrotaxonomy
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/  
COMMENT ON TABLE APPS.XXSKZ_�h�����N�U�։^��_����_V IS 'SKYLINK�p�h�����N�U�։^���i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.���i����                       IS '���i����'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.���i���ޖ�                     IS '���i���ޖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.�z���敪                       IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.�z���敪��                     IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.���_�啪��                     IS '���_�啪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.���_�啪�ޖ�                   IS '���_�啪�ޖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.�K�p�J�n��                     IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.�K�p�I����                     IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.�ݒ�P��                       IS '�ݒ�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.�y�i���e�B�P��                 IS '�y�i���e�B�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�h�����N�U�։^��_����_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
