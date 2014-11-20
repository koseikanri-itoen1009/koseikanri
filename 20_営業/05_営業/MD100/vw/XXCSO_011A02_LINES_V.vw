/*************************************************************************
 * 
 * VIEW Name       : XXCSO_011A02_LINES_V
 * Description     : CSO_011_A02_��ƈ˗��^�����˗�������ʖ��׃r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/12/22    1.0  T.Maruyama    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_011a02_lines_v
(
seq_no,
slip_no,
slip_branch_no,
line_number,
job_kbn,
install_code1,
install_code2,
work_hope_date,
work_hope_time_kbn,
work_hope_time,
current_install_name,
new_install_name,
withdrawal_process_kbn,
actual_work_date,
actual_work_time1,
actual_work_time2,
completion_kbn,
delete_flag,
completion_plan_date,
completion_date,
disposal_approval_date,
withdrawal_date,
delivery_date,
last_disposal_end_date,
fwd_root_company_code,
fwd_root_location_code,
fwd_distination_company_code,
fwd_distination_location_code,
creation_employee_number,
creation_section_name,
creation_program_id,
update_employee_number,
update_section_name,
update_program_id,
creation_date_time,
update_date_time,
po_number,
po_line_number,
po_distribution_number,
po_req_number,
line_num,
account_number1,
account_number2,
safe_setting_standard,
install1_processed_flag,
install2_processed_flag,
suspend_processed_flag,
install1_processed_date,
install2_processed_date,
vdms_interface_flag,
vdms_interface_date,
install1_process_no_target_flg,
install2_process_no_target_flg,
created_by,
creation_date,
last_updated_by,
last_update_date,
last_update_login,
request_id,
program_application_id,
program_id,
program_update_date,
infos_interface_flag,
infos_interface_date,
completion_kbn_nm
)
AS
SELECT
seq_no                              -- �V�[�P���X�ԍ�
,slip_no                            -- �`�[No.
,slip_branch_no                     -- �`�[�}��
,line_number                        -- �s�ԍ�
,job_kbn                            -- ��Ƌ敪
,install_code1                      -- �����R�[�h�P�i�ݒu�p�j
,install_code2                      -- �����R�[�h�Q�i���g�p�j
,work_hope_date                     -- ��Ɗ�]��/�����]��
,work_hope_time_kbn                 -- ��Ɗ�]���ԋ敪
,work_hope_time                     -- ��Ɗ�]����
,current_install_name               -- ���ݒu�於
,new_install_name                   -- �V�ݒu�於
,withdrawal_process_kbn             -- ���g�@�����敪
,actual_work_date                   -- ����Ɠ�
,actual_work_time1                  -- ����Ǝ��ԂP
,actual_work_time2                  -- ����Ǝ��ԂQ
,completion_kbn                     -- �����敪
,delete_flag                        -- �폜�t���O
,completion_plan_date               -- �����\���/�C�������\���
,completion_date                    -- ������/�C��������
,disposal_approval_date             -- �p�����ٓ�
,withdrawal_date                    -- �������/�����
,delivery_date                      -- ��t��
,last_disposal_end_date             -- �ŏI�����I���N����
,fwd_root_company_code              -- �i�]�����j��ЃR�[�h
,fwd_root_location_code             -- �i�]�����j���Ə��R�[�h
,fwd_distination_company_code       -- �i�]����j��ЃR�[�h
,fwd_distination_location_code      -- �i�]����j���Ə��R�[�h
,creation_employee_number           -- �쐬�S���҃R�[�h
,creation_section_name              -- �쐬�����R�[�h
,creation_program_id                -- �쐬�v���O�����h�c
,update_employee_number             -- �X�V�S���҃R�[�h
,update_section_name                -- �X�V�����R�[�h
,update_program_id                  -- �X�V�v���O�����h�c
,creation_date_time                 -- �쐬���������b
,update_date_time                   -- �X�V���������b
,po_number                          -- �����ԍ�
,po_line_number                     -- �������הԍ�
,po_distribution_number             -- ���������ԍ�
,po_req_number                      -- �����˗��ԍ�
,line_num                           -- �����˗����הԍ�
,account_number1                    -- �ڋq�R�[�h�P�i�V�ݒu��j
,account_number2                    -- �ڋq�R�[�h�Q�i���ݒu��j
,safe_setting_standard              -- ���S�ݒu�
,install1_processed_flag            -- �����P�����σt���O
,install2_processed_flag            -- �����Q�����σt���O
,suspend_processed_flag             -- �x�~�����σt���O
,install1_processed_date            -- �����P�����ϓ�
,install2_processed_date            -- �����Q�����ϓ�
,vdms_interface_flag                -- ���̋@S�A�g�t���O
,vdms_interface_date                -- ���̋@S�A�g��
,DECODE(install_code1
        ,NULL
        ,NULL
        ,install1_process_no_target_flg
       )install1_process_no_target_flg       -- �����P��ƈ˗������ΏۊO�t���O
,DECODE(install_code2
        ,NULL
        ,NULL
        ,install2_process_no_target_flg
       )install2_process_no_target_flg     -- �����Q��ƈ˗������ΏۊO�t���O
,created_by                         -- �쐬��
,creation_date                      -- �쐬��
,last_updated_by                    -- �ŏI�X�V��
,last_update_date                   -- �ŏI�X�V��
,last_update_login                  -- �ŏI�X�V���O�C��
,request_id                         -- �v��ID
,program_application_id             -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
,program_id                         -- �R���J�����g�E�v���O����ID
,program_update_date                -- �v���O�����X�V��
,infos_interface_flag               -- ���n�A�g�σt���O
,infos_interface_date               -- ���n�A�g��
,DECODE(completion_kbn
       ,1,'����','���~') completion_kbn_nm   -- ��Ƌ敪���e
FROM  xxcso_in_work_data   xiwd     -- ��ƃf�[�^
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_011A02_LINES_V IS 'CSO_011_A02_���׃r���[';