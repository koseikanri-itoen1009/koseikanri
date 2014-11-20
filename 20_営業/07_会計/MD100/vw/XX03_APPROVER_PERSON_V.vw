CREATE OR REPLACE FORCE VIEW XX03_APPROVER_PERSON_V(
/*************************************************************************
 * 
 * View Name       : XX03_APPROVER_PERSON_V
 * Description     : BFA���F�҃r���[
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2009/07/28    1.0  SCS ���c�E�l    ����C��
 *                                     [��Q0000376]BFA �p�t�H�[�}���X�Ή�
 ************************************************************************/
  "PERSON_ID",                          -- �]�ƈ�ID
  "EFFECTIVE_START_DATE",               -- �L���J�n��
  "EFFECTIVE_END_DATE",                 -- �L���I����
  "ATTRIBUTE28",                        -- ��������
  "EMPLOYEE_DISP",                      -- �]�ƈ��\��
  "USER_ID",                            -- ���[�U�[ID
  "RESPONSIBILITY_ID",                  -- �E��ID
  "PROFILE_NAME_ORG",                   -- �v���t�@�C����_�g�D
  "PROFILE_VAL_ORG",                    -- �v���t�@�C���l_�g�D
  "PROFILE_NAME_AUTH",                  -- �v���t�@�C����_������͌���
  "PROFILE_VAL_AUTH",                   -- �v���t�@�C���l_������͌���
  "PROFILE_NAME_DEP",                   -- �v���t�@�C����_���右�F�\���W���[��
  "PROFILE_VAL_DEP",                    -- �v���t�@�C���l_���右�F�\���W���[��
  "PROFILE_NAME_ACC",                   -- �v���t�@�C����_�o�����F�\���W���[��
  "PROFILE_VAL_ACC",                    -- �v���t�@�C���l_�o�����F�\���W���[��
  "R_START_DATE",                       -- ���[�U�[�E��_�J�n��
  "R_END_DATE",                         -- ���[�U�[�E��_�I����
  "U_START_DATE",                       -- ���[�U�[_�J�n��
  "U_END_DATE",                         -- ���[�U�[_�I����
  "LAST_UPDATE_DATE",                   -- �]�ƈ�_�ŏI�X�V��
  "LAST_UPDATED_BY",                    -- �]�ƈ�_�ŏI�X�V��
  "CREATION_DATE",                      -- �]�ƈ�_�쐬��
  "CREATED_BY",                         -- �]�ƈ�_�쐬��
  "LAST_UPDATE_LOGIN"                   -- �]�ƈ�_�ŏI�X�V���O�C��
) AS 
    SELECT ppf.person_id                                                            -- �]�ƈ�ID
           ,ppf.effective_start_date                                                -- �L���J�n��
           ,ppf.effective_end_date                                                  -- �L���I����
           ,ppf.attribute28                                                         -- ��������
           ,ppf.employee_number ||
              XX00_PROFILE_PKG.VALUE('xx03_text_delimiter') ||
              ppf.per_information18 ||
              ' ' ||
              ppf.per_information19 as employee_disp                                -- �]�ƈ��\��
           ,fu.user_id                                                              -- ���[�U�[ID
           ,xfurv.responsibility_id                                                 -- �E��ID
           ,fpo1.user_profile_option_name  profile_name_org                         -- �v���t�@�C����_�g�D
           ,fpo1.profile_option_value      profile_val_org                          -- �v���t�@�C���l_�g�D
           ,fpo2.user_profile_option_name  profile_name_auth                        -- �v���t�@�C����_������͌���
           ,fpo2.profile_option_value      profile_val_auth                         -- �v���t�@�C���l_������͌���
           ,fpo3.user_profile_option_name         profile_name_dep                  -- �v���t�@�C����_���右�F�\���W���[��
           ,NVL(fpo3.profile_option_value,'ALL')  profile_val_dep                   -- �v���t�@�C���l_���右�F�\���W���[��
           ,fpo4.user_profile_option_name         profile_name_acc                  -- �v���t�@�C����_�o�����F�\���W���[��
           ,NVL(fpo4.profile_option_value,'ALL')  profile_val_acc                   -- �v���t�@�C���l_�o�����F�\���W���[��
           ,xfurv.start_date                                         r_start_date   -- ���[�U�[�E��_�J�n��
           ,NVL(xfurv.end_date, TO_DATE('4712/12/31','YYYY/MM/DD'))  r_end_date     -- ���[�U�[�E��_�I����
           ,fu.start_date                                           u_start_date    -- ���[�U�[_�J�n��
           ,NVL(fu.end_date  , TO_DATE('4712/12/31','YYYY/MM/DD'))  u_end_date      -- ���[�U�[_�I����
           ,ppf.last_update_date                                                    -- �]�ƈ�_�ŏI�X�V��
           ,ppf.last_updated_by                                                     -- �]�ƈ�_�ŏI�X�V��
           ,ppf.creation_date                                                       -- �]�ƈ�_�쐬��
           ,ppf.created_by                                                          -- �]�ƈ�_�쐬��
           ,ppf.last_update_login                                                   -- �]�ƈ�_�ŏI�X�V���O�C��
      FROM   per_people_f          ppf                                          -- �]�ƈ��}�X�^�r���[
            ,fnd_user              fu                                           -- ���[�U�[�}�X�^
            ,xxcfo_fnd_user_resp_grp_v  xfurv                                   -- ���[�U�[�E�ӏ��F����r���[
            ,(SELECT fpov.level_value_application_id
                    ,fpov.level_value
                    ,fpov.profile_option_value
                    ,fpovl.user_profile_option_name
              FROM   fnd_profile_option_values  fpov
                    ,fnd_profile_options_vl     fpovl
              WHERE  fpovl.application_id       = fpov.application_id
                AND  fpovl.profile_option_id    = fpov.profile_option_id
                AND  fpovl.profile_option_name  = 'ORG_ID'
              )                    fpo1                                         -- �v���t�@�C���i�g�D�j
            ,(SELECT fpov.level_value_application_id
                    ,fpov.level_value
                    ,fpov.profile_option_value
                    ,fpovl.user_profile_option_name
              FROM   fnd_profile_option_values  fpov
                    ,fnd_profile_options_vl     fpovl
              WHERE  fpovl.application_id       = fpov.application_id
                AND  fpovl.profile_option_id    = fpov.profile_option_id
                AND  fpovl.profile_option_name  = 'XX03_SLIP_AUTHORITIES'
              )                    fpo2                                         -- �v���t�@�C���i������͌����j
            ,(SELECT fpov.level_value_application_id
                    ,fpov.level_value
                    ,fpov.profile_option_value
                    ,fpovl.user_profile_option_name
              FROM   fnd_profile_option_values  fpov
                    ,fnd_profile_options_vl     fpovl
              WHERE  fpovl.application_id       = fpov.application_id
                AND  fpovl.profile_option_id    = fpov.profile_option_id
                AND  fpovl.profile_option_name  = 'XX03_SLIP_DEP_APPROVE_MODULE'
              )                    fpo3                                         -- �v���t�@�C���i���右�F�\���W���[���j
            ,(SELECT fpov.level_value_application_id
                    ,fpov.level_value
                    ,fpov.profile_option_value
                    ,fpovl.user_profile_option_name
              FROM   fnd_profile_option_values  fpov
                    ,fnd_profile_options_vl     fpovl
              WHERE  fpovl.application_id       = fpov.application_id
                AND  fpovl.profile_option_id    = fpov.profile_option_id
                AND  fpovl.profile_option_name  = 'XX03_SLIP_ACC_APPROVE_MODULE'
              )                    fpo4                                         -- �v���t�@�C���i�o�����F�\���W���[���j
      WHERE  ppf.current_employee_flag           = 'Y'
        AND  fu.employee_id                      = ppf.person_id
        AND  xfurv.user_id                       = fu.user_id
        AND  fpo1.level_value_application_id     = xfurv.responsibility_application_id
        AND  fpo1.level_value                    = xfurv.responsibility_id
        AND  fpo1.profile_option_value           = XX00_PROFILE_PKG.VALUE('ORG_ID')
        AND  fpo2.level_value_application_id     = xfurv.responsibility_application_id
        AND  fpo2.level_value                    = xfurv.responsibility_id
        AND  fpo2.profile_option_value           BETWEEN '1' AND '9'
        AND  fpo3.level_value_application_id (+) = xfurv.responsibility_application_id
        AND  fpo3.level_value                (+) = xfurv.responsibility_id
        AND  fpo4.level_value_application_id (+) = xfurv.responsibility_application_id
        AND  fpo4.level_value                (+) = xfurv.responsibility_id
/
COMMENT ON COLUMN  xx03_approver_person_v.person_id                     IS '�]�ƈ�ID'
/
COMMENT ON COLUMN  xx03_approver_person_v.effective_start_date          IS '�L���J�n��'
/
COMMENT ON COLUMN  xx03_approver_person_v.effective_end_date            IS '�L���I����'
/
COMMENT ON COLUMN  xx03_approver_person_v.attribute28                   IS '��������'
/
COMMENT ON COLUMN  xx03_approver_person_v.employee_disp                 IS '�]�ƈ��\��'
/
COMMENT ON COLUMN  xx03_approver_person_v.user_id                       IS '���[�U�[ID'
/
COMMENT ON COLUMN  xx03_approver_person_v.responsibility_id             IS '�E��ID'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_name_org              IS '�v���t�@�C����_�g�D'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_val_org               IS '�v���t�@�C���l_�g�D'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_name_auth             IS '�v���t�@�C����_������͌���'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_val_auth              IS '�v���t�@�C���l_������͌���'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_name_dep              IS '�v���t�@�C����_���右�F�\���W���[��'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_val_dep               IS '�v���t�@�C���l_���右�F�\���W���[��'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_name_acc              IS '�v���t�@�C����_�o�����F�\���W���[��'
/
COMMENT ON COLUMN  xx03_approver_person_v.profile_val_acc               IS '�v���t�@�C���l_�o�����F�\���W���[��'
/
COMMENT ON COLUMN  xx03_approver_person_v.r_start_date                  IS '���[�U�[�E��_�J�n��'
/
COMMENT ON COLUMN  xx03_approver_person_v.r_end_date                    IS '���[�U�[�E��_�I����'
/
COMMENT ON COLUMN  xx03_approver_person_v.u_start_date                  IS '���[�U�[_�J�n��'
/
COMMENT ON COLUMN  xx03_approver_person_v.u_end_date                    IS '���[�U�[_�I����'
/
COMMENT ON COLUMN  xx03_approver_person_v.last_update_date              IS '�]�ƈ�_�ŏI�X�V��'
/
COMMENT ON COLUMN  xx03_approver_person_v.last_updated_by               IS '�]�ƈ�_�ŏI�X�V��'
/
COMMENT ON COLUMN  xx03_approver_person_v.creation_date                 IS '�]�ƈ�_�쐬��'
/
COMMENT ON COLUMN  xx03_approver_person_v.created_by                    IS '�]�ƈ�_�쐬��'
/
COMMENT ON COLUMN  xx03_approver_person_v.last_update_login             IS '�]�ƈ�_�ŏI�X�V���O�C��'
/
COMMENT ON TABLE  xx03_approver_person_v IS 'BFA���F�҃r���['
/
