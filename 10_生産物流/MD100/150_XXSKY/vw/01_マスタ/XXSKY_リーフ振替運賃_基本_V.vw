CREATE OR REPLACE VIEW APPS.XXSKY_���[�t�U�։^��_��{_V
(
 �K�p�J�n��
,�K�p�I����
,�֐ݒ���z
,������P
,�ݒ���z�P
,������Q
,�ݒ���z�Q
,������R
,�ݒ���z�R
,������S
,�ݒ���z�S
,������T
,�ݒ���z�T
,������U
,�ݒ���z�U
,������V
,�ݒ���z�V
,������W
,�ݒ���z�W
,������X
,�ݒ���z�X
,������P�O
,�ݒ���z�P�O
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  
        XLTDC.start_date_active           --�K�p�J�n��
       ,XLTDC.end_date_active             --�K�p�I����
       ,XLTDC.setting_amount              --�֐ݒ���z
       ,XLTDC.upper_limit_number1         --�����1
       ,XLTDC.setting_amount1             --�ݒ���z1
       ,XLTDC.upper_limit_number2         --�����2
       ,XLTDC.setting_amount2             --�ݒ���z2
       ,XLTDC.upper_limit_number3         --�����3
       ,XLTDC.setting_amount3             --�ݒ���z3
       ,XLTDC.upper_limit_number4         --�����4
       ,XLTDC.setting_amount4             --�ݒ���z4
       ,XLTDC.upper_limit_number5         --�����5
       ,XLTDC.setting_amount5             --�ݒ���z5
       ,XLTDC.upper_limit_number6         --�����6
       ,XLTDC.setting_amount6             --�ݒ���z6
       ,XLTDC.upper_limit_number7         --�����7
       ,XLTDC.setting_amount7             --�ݒ���z7
       ,XLTDC.upper_limit_number8         --�����8
       ,XLTDC.setting_amount8             --�ݒ���z8
       ,XLTDC.upper_limit_number9         --�����9
       ,XLTDC.setting_amount9             --�ݒ���z9
       ,XLTDC.upper_limit_number10        --�����10
       ,XLTDC.setting_amount10            --�ݒ���z10
       ,FU_CB.user_name                   --�쐬��
       ,TO_CHAR( XLTDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                          --�쐬��
       ,FU_LU.user_name                   --�ŏI�X�V��
       ,TO_CHAR( XLTDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                          --�ŏI�X�V��
       ,FU_LL.user_name                   --�ŏI�X�V���O�C��
  FROM  xxwip_leaf_trans_deli_chrgs XLTDC --���[�t�U�։^���A�h�I���}�X�^
       ,fnd_user                    FU_CB --���[�U�[�}�X�^(created_by���̎擾�p)
       ,fnd_user                    FU_LU --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       ,fnd_user                    FU_LL --���[�U�[�}�X�^(last_update_login���̎擾�p)
       ,fnd_logins                  FL_LL --���O�C���}�X�^(last_update_login���̎擾�p)
 WHERE  XLTDC.created_by        = FU_CB.user_id(+)
   AND  XLTDC.last_updated_by   = FU_LU.user_id(+)
   AND  XLTDC.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id           = FU_LL.user_id(+)
/

COMMENT ON TABLE APPS.XXSKY_���[�t�U�։^��_��{_V IS 'SKYLINK�p���[�t�U�։^���i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�K�p�J�n��                 IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�K�p�I����                 IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�֐ݒ���z                 IS '�֐ݒ���z'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.������P                 IS '������P'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ݒ���z�P                 IS '�ݒ���z�P'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.������Q                 IS '������Q'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ݒ���z�Q                 IS '�ݒ���z�Q'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.������R                 IS '������R'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ݒ���z�R                 IS '�ݒ���z�R'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.������S                 IS '������S'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ݒ���z�S                 IS '�ݒ���z�S'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.������T                 IS '������T'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ݒ���z�T                 IS '�ݒ���z�T'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.������U                 IS '������U'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ݒ���z�U                 IS '�ݒ���z�U'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.������V                 IS '������V'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ݒ���z�V                 IS '�ݒ���z�V'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.������W                 IS '������W'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ݒ���z�W                 IS '�ݒ���z�W'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.������X                 IS '������X'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ݒ���z�X                 IS '�ݒ���z�X'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.������P�O               IS '������P�O'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ݒ���z�P�O               IS '�ݒ���z�P�O'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�쐬��                     IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�쐬��                     IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ŏI�X�V��                 IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ŏI�X�V��                 IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���[�t�U�։^��_��{_V.�ŏI�X�V���O�C��           IS '�ŏI�X�V���O�C��'
/
