CREATE OR REPLACE VIEW APPS.XXSKY_�h�����N�U�։^��_����_V
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
       ,FLV01.meaning                       --���i���ޖ�
       ,XDTDC.dellivary_classe              --�z���敪
       ,FLV02.meaning                       --�z���敪��
       ,XDTDC.foothold_macrotaxonomy        --���_�啪��
       ,FLV03.meaning                       --���_�啪�ޖ�
       ,XDTDC.start_date_active             --�K�p�J�n��
       ,XDTDC.end_date_active               --�K�p�I����
       ,XDTDC.setting_amount                --�ݒ�P��
       ,XDTDC.penalty_amount                --�y�i���e�B�P��
       ,FU_CB.user_name                     --�쐬��
       ,TO_CHAR( XDTDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�쐬��
       ,FU_LU.user_name                     --�ŏI�X�V��
       ,TO_CHAR( XDTDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�ŏI�X�V��
       ,FU_LL.user_name                     --�ŏI�X�V���O�C��
  FROM  xxwip_drink_trans_deli_chrgs XDTDC  --�h�����N�U�։^���A�h�I���}�X�^
       ,fnd_user                     FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
       ,fnd_user                     FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       ,fnd_user                     FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
       ,fnd_logins                   FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
       ,fnd_lookup_values            FLV01  --�N�C�b�N�R�[�h(���i���ޖ�)
       ,fnd_lookup_values            FLV02  --�N�C�b�N�R�[�h(�z���敪��)
       ,fnd_lookup_values            FLV03  --�N�C�b�N�R�[�h(���_�啪�ޖ�)
 WHERE  XDTDC.start_date_active <= TRUNC(SYSDATE)
   AND  XDTDC.end_date_active   >= TRUNC(SYSDATE)
   AND  XDTDC.created_by        = FU_CB.user_id(+)
   AND  XDTDC.last_updated_by   = FU_LU.user_id(+)
   AND  XDTDC.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id           = FU_LL.user_id(+)
   AND  FLV01.language(+)    = 'JA'                        --����
   AND  FLV01.lookup_type(+) = 'XXCMN_D02'                 --�N�C�b�N�R�[�h�^�C�v
   AND  FLV01.lookup_code(+) = XDTDC.godds_classification  --�N�C�b�N�R�[�h
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV02.lookup_code(+) = XDTDC.dellivary_classe
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXWIP_BASE_MAJOR_DIVISION'
   AND  FLV03.lookup_code(+) = XDTDC.foothold_macrotaxonomy
/

COMMENT ON TABLE APPS.XXSKY_�h�����N�U�։^��_����_V IS 'SKYLINK�p�h�����N�U�։^���i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.���i����                       IS '���i����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.���i���ޖ�                     IS '���i���ޖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.�z���敪                       IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.�z���敪��                     IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.���_�啪��                     IS '���_�啪��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.���_�啪�ޖ�                   IS '���_�啪�ޖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.�K�p�J�n��                     IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.�K�p�I����                     IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.�ݒ�P��                       IS '�ݒ�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.�y�i���e�B�P��                 IS '�y�i���e�B�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�U�։^��_����_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
