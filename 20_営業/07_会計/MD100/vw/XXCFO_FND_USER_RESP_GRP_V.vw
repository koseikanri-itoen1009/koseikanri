CREATE OR REPLACE FORCE VIEW XXCFO_FND_USER_RESP_GRP_V(
/*************************************************************************
 * 
 * View Name       : XXCFO_FND_USER_RESP_GRP_V
 * Description     : ���[�U�[�E�ӏ��F����r���[
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2009/07/28    1.0  SCS ���c�E�l    ����쐬
 *                                     [��Q0000376]BFA �p�t�H�[�}���X�Ή�
 ************************************************************************/
  "USER_ID",                            -- ���[�U�[ID
  "RESPONSIBILITY_ID",                  -- �E��ID
  "RESPONSIBILITY_APPLICATION_ID",      -- �E�ӃA�v���P�[�V����ID
  "SECURITY_GROUP_ID",                  -- �Z�L�����e�B�O���[�vID
  "START_DATE",                         -- �J�n��
  "END_DATE",                           -- �I����
  "DESCRIPTION",                        -- �E�v
  "CREATED_BY",                         -- �쐬��
  "CREATION_DATE",                      -- �쐬��
  "LAST_UPDATED_BY",                    -- �ŏI�X�V��
  "LAST_UPDATE_DATE",                   -- �ŏI�X�V��
  "LAST_UPDATE_LOGIN"                   -- �ŏI�X�V���O�C��
) AS
    SELECT u.user_id user_id,                                   -- ���[�U�[ID
           wur.role_orig_system_id responsibility_id,           -- ���[���I���W�i���V�X�e��ID
           (SELECT application_id
              FROM fnd_application
             WHERE application_short_name =/* Val between 1st and 2nd separator */
                     REPLACE(
                       SUBSTR(wura.role_name,
                            INSTR(wura.role_name, '|', 1, 1)+1,
                                 ( INSTR(wura.role_name, '|', 1, 2)
                                  -INSTR(wura.role_name, '|', 1, 1)-1)
                            )
                       ,'%col', ':')
           ) responsibility_application_id,                     -- �E�ӃA�v���P�[�V����ID
           (SELECT security_group_id
              FROM fnd_security_groups
             WHERE security_group_key =/* Val after 3rd separator */
                     REPLACE(
                       SUBSTR(wura.role_name,
                              INSTR(wura.role_name, '|', 1, 3)+1
                            )
                       ,'%col', ':')
           ) security_group_id,                                 -- �Z�L�����e�B�O���[�vID
           fnd_date.canonical_to_date('1000/01/01') start_date, -- �J�n��
           to_date(NULL) end_date,                              -- �I����
           to_char(NULL) description,                           -- �E�v
           to_number(NULL) created_by,                          -- �쐬��
           to_date(NULL) creation_date,                         -- �쐬��
           to_number(NULL) last_updated_by,                     -- �ŏI�X�V��
           to_date(NULL) last_update_date,                      -- �ŏI�X�V��
           to_number(NULL) last_update_login                    -- �ŏI�X�V���O�C��
      FROM fnd_user u                                           -- ���[�U�[�}�X�^
           ,wf_user_role_assignments_v wura                     -- ���[�N�t���[���[�U�[���[���A�T�C�����g�r���[
           ,wf_user_roles wur                                   -- ���[�N�t���[���[�U�[���[���r���[
           ,xx03_per_peoples_v xppv2                            -- BFA�]�ƈ��r���[
           ,xx03_flex_value_children_v xfvcv2                   -- BFA�t���b�N�X����e�q�r���[
           ,per_people_f ppf2                                   -- �]�ƈ��}�X�^�r���[
     WHERE wura.user_name = u.user_name
       AND wur.role_orig_system = 'FND_RESP'
       AND wur.partition_id = 2
       AND wura.role_name = wur.role_name
       AND wura.user_name = wur.user_name
       AND xfvcv2.flex_value = ppf2.attribute28
       AND xppv2.attribute30 = xfvcv2.parent_flex_value
       AND xppv2.user_id = XX00_PROFILE_PKG.VALUE('USER_ID')
       AND TRUNC(SYSDATE) BETWEEN xppv2.effective_start_date
                              AND xppv2.effective_end_date
       AND u.employee_id = ppf2.person_id
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.user_id                        IS '���[�U�[ID'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.responsibility_id              IS '�E��ID'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.responsibility_application_id  IS '�E�ӃA�v���P�[�V����ID'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.security_group_id              IS '�Z�L�����e�B�O���[�vID'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.start_date                     IS '�J�n��'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.end_date                       IS '�I����'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.description                    IS '�E�v'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.created_by                     IS '�쐬��'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.creation_date                  IS '�쐬��'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.last_updated_by                IS '�ŏI�X�V��'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.last_update_date               IS '�ŏI�X�V��'
/
COMMENT ON COLUMN  xxcfo_fnd_user_resp_grp_v.last_update_login              IS '�ŏI�X�V���O�C��'
/
COMMENT ON TABLE  xxcfo_fnd_user_resp_grp_v IS '���[�U�[�E�ӏ��F����r���['
/
