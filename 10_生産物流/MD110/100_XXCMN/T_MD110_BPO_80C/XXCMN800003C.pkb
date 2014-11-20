CREATE OR REPLACE PACKAGE BODY xxcmn800003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN800003C(body)
 * Description      : �]�ƈ��}�X�^�C���^�t�F�[�X
 * MD.050           : �}�X�^�C���^�t�F�[�X T_MD050_BPO_800
 * MD.070           : �]�ƈ��C���^�t�F�[�X T_MD070_BPO_80C
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_profile            �v���t�@�C���擾�v���V�[�W��
 *  get_per_person_types   �p�[�\���^�C�v�擾�v���V�[�W��
 *  set_if_lock            �C���^�t�F�[�X�e�[�u���ɑ΂��郍�b�N�擾�v���V�[�W��
 *  set_error_status       �G���[������������Ԃɂ���v���V�[�W��
 *  set_warn_status        �x��������������Ԃɂ���v���V�[�W��
 *  init_status            �X�e�[�^�X�������v���V�[�W��
 *  is_file_status_nomal   �t�@�C�����x���Ő��킩�󋵂��m�F����t�@���N�V����
 *  init_row_status        �s���x���X�e�[�^�X�������v���V�[�W��
 *  is_row_status_nomal    �s���x���Ő��킩�󋵂��m�F����t�@���N�V����
 *  is_row_status_warn     �s���x���Ōx�����󋵂��m�F����t�@���N�V����
 *  set_line_lock          �s�P�ʂ̃��b�N���s���v���V�[�W��
 *  get_xxcmn_emp_if       �Ј��C���^�t�F�[�X�̈ȑO�̌����擾���s���v���V�[�W��
 *  get_per_all_people_f   �]�ƈ�ID���擾�����݃`�F�b�N���s���v���V�[�W��
 *  get_fnd_user           ���[�U�[ID���擾�����݃`�F�b�N���s���v���V�[�W��
 *  get_fnd_responsibility �E�Ӄ}�X�^�̎擾���s���v���V�[�W��
 *  get_per_ass_all_f      �]�ƈ������}�X�^�̑��݃`�F�b�N���s���v���V�[�W��
 *  get_po_agents          �w���S���}�X�^�̑��݃`�F�b�N���s���v���V�[�W��
 *  get_wsh_grants         �o�׃��[���}�X�^�̑��݃`�F�b�N���s���v���V�[�W��
 *  get_application        �A�v���P�[�V�����V���[�g���̎擾���s���v���V�[�W��
 *  add_report             ���|�[�g�p�f�[�^��ݒ肷��v���V�[�W��
 *  disp_report            ���|�[�g�p�f�[�^���o�͂���v���V�[�W��
 *  delete_emp_if          �Ј��C���^�t�F�[�X�̃f�[�^���폜����v���V�[�W��
 *  get_fnd_user_resp_all  ���[�U�[�E�Ӄ}�X�^�̎擾���s���v���V�[�W��
 *  exists_fnd_respons     �E�Ӄ}�X�^���݃`�F�b�N���s���v���V�[�W��
 *  exists_fnd_user_resp   ���[�U�E�Ӄ}�X�^���݃`�F�b�N���s���v���V�[�W��
 *  exists_fnd_user_all    ���[�U�E�Ӄ}�X�^�̑��݃`�F�b�N���s���܂��B
 *  check_insert           �o�^�p�f�[�^���`�F�b�N����v���V�[�W��
 *  check_update           �X�V�p�f�[�^���`�F�b�N����v���V�[�W��
 *  check_delete           �폜�p�f�[�^���`�F�b�N����v���V�[�W��
 *  check_proc_code        ����Ώۂ̃��R�[�h�ł��邱�Ƃ��`�F�b�N����v���V�[�W��
 *  get_location_new       �V�K�o�^���ɒS�����_���擾�����݃`�F�b�N���s���v���V�[�W��
 *  get_location_mod       �ύX�E�폜���ɒS�����_���擾�����݃`�F�b�N���s���v���V�[�W��
 *  get_service_id         �T�[�r�X����ID�̎擾���s���v���V�[�W��
 *  wsh_grants_proc        �o�׃��[���}�X�^�̓o�^�E�폜�������s���v���V�[�W��
 *  po_agents_proc         �w���S���}�X�^�̓o�^�E�폜�������s���v���V�[�W��
 *  set_assignment         ���[�U�E�Ӄ}�X�^�̓o�^�������s���v���V�[�W��
 *  update_resp_all_f      ���[�U�[�E�Ӄ}�X�^�̍X�V�������s���v���V�[�W��
 *  delete_group_all       ���[�U�[�E�Ӄ}�X�^�̃f�[�^�𖳌�������v���V�[�W��
 *  insert_proc            ���[�U�[�o�^���i�[�������s���v���V�[�W��
 *  update_proc            ���[�U�[�X�V���i�[�������s���v���V�[�W��
 *  delete_proc            ���[�U�[�폜���i�[�������s���v���V�[�W��
 *  init_proc              �����������s���v���V�[�W��
 *  submain                �Ј��C���^�t�F�[�X�̃f�[�^���e�}�X�^�֔��f����v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/10/29    1.0   Oracle �ۉ� ���� ����쐬
 *  2008/05/19    1.1   Oracle �R�� ��_ �ύX�v��No54�Ή�
 *  2008/05/27    1.2   Oracle �ۉ� ���� �����ύX�v��No122�Ή�
 *  2008/07/07    1.3   Oracle �R�� ��_ I_S_192�Ή�,�����ύX�v��No43�Ή�
 *  2008/10/06    1.4   Oracle �Ŗ� ���\ ������Q#304�Ή�
 *  2008/11/20    1.5   Oracle �ۉ� ���� I_S_698
 *  2009/03/25    1.6   Oracle �Ŗ� ���\ �{��#1340�Ή�
 *****************************************************************************************/
--
--###############################  �Œ�O���[�o���萔�錾�� START   ###############################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';   --����
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';   --�x��
  gv_status_error  CONSTANT VARCHAR2(1) := '2';   --���s
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';   --�X�e�[�^�X(����)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';   --�X�e�[�^�X(�x��)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';   --�X�e�[�^�X(���s)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_flg_on        CONSTANT VARCHAR2(1) := '1';
--
--#####################################  �Œ蕔 END   #############################################
--
--###############################  �Œ�O���[�o���ϐ��錾�� START   ###############################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);             -- ���s���[�U��
  gv_conc_name     VARCHAR2(30);              -- ���s�R���J�����g��
  gv_conc_status   VARCHAR2(30);              -- ��������
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- ���s����
  gn_warn_cnt      NUMBER;                    -- �x������
  gn_report_cnt    NUMBER;                    -- ���|�[�g����
--
--#####################################  �Œ蕔 END   #############################################
--
--##################################  �Œ苤�ʗ�O�錾�� START   ##################################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--#####################################  �Œ蕔 END   #############################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  check_sub_main_expt         EXCEPTION;     -- �T�u���C���̃G���[
  delete_group_all_expt       EXCEPTION;     -- ���[�U�E�Ӄ}�X�^�폜�G���[
  exists_fnd_respons_expt     EXCEPTION;     -- �E�Ӄ}�X�^���݃`�F�b�N�G���[
  exists_fnd_user_resp_expt   EXCEPTION;     -- ���[�U�[�E�Ӄ}�X�^���݃`�F�b�N�G���[
--
  lock_expt                   EXCEPTION;     -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �C���^�t�F�[�X�f�[�^�̑�����
  gn_proc_insert CONSTANT NUMBER := 1; -- �o�^
  gn_proc_update CONSTANT NUMBER := 2; -- �X�V
  gn_proc_delete CONSTANT NUMBER := 9; -- �폜
  -- �����󋵂�����킷�X�e�[�^�X
  gn_data_status_nomal CONSTANT NUMBER := 0; -- ����
  gn_data_status_error CONSTANT NUMBER := 1; -- ���s
  gn_data_status_warn  CONSTANT NUMBER := 2; -- �x��
--
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'xxcmn800003c'; -- �p�b�P�[�W��
  gv_def_sex           CONSTANT VARCHAR2(1)   := 'M';
  gv_owner             CONSTANT VARCHAR2(4)   := 'CUST';
  gv_msg_kbn           CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_info_category     CONSTANT VARCHAR2(2)   := 'JP';
  gv_emp_if_name       CONSTANT VARCHAR2(100) := 'xxcmn_emp_if';
  gv_user_person_type  CONSTANT per_person_types.user_person_type%TYPE := '�]�ƈ�';
  gv_upd_mode          CONSTANT VARCHAR2(15)  := 'CORRECTION';
--
  --���b�Z�[�W�ԍ�
  gv_msg_80c_001       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00001';  --���[�U�[��
  gv_msg_80c_002       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00002';  --�R���J�����g��
  gv_msg_80c_003       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00003';  --�Z�p���[�^
  gv_msg_80c_004       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005';  --�����f�[�^(���o��)
  gv_msg_80c_005       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006';  --�G���[�f�[�^(���o��)
  gv_msg_80c_006       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007';  --�X�L�b�v�f�[�^(���o��)
  gv_msg_80c_007       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008';  --��������
  gv_msg_80c_008       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009';  --��������
  gv_msg_80c_009       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00010';  --�G���[����
  gv_msg_80c_010       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00011';  --�X�L�b�v����
  gv_msg_80c_011       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00012';  --�����X�e�[�^�X
  gv_msg_80c_012       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';  --�v���t�@�C���擾�G���[
  gv_msg_80c_013       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018';  --API�G���[(�R���J�����g)
  gv_msg_80c_014       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';  --���b�N�G���[
  gv_msg_80c_015       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10020';  --�]�ƈ��ΏۊO���R�[�h
  gv_msg_80c_016       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10021';  --�͈͊O�f�[�^
  gv_msg_80c_017       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10022';  --�e�[�u���폜�G���[
  gv_msg_80c_018       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10023';  --�o�^���̏d���`�F�b�N�G���[
  gv_msg_80c_019       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10024';  --�X�V���̑��݃`�F�b�N�G���[
  gv_msg_80c_020       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10025';  --�폜���̍폜�`�F�b�N�G���[
  gv_msg_80c_021       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10030';  --�R���J�����g��^�G���[
  gv_msg_80c_022       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10118';  --�N������
  gv_msg_80c_023       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10036';  --�f�[�^�擾�G���[�P
--
  --�g�[�N��
  gv_tkn_status        CONSTANT VARCHAR2(15) := 'STATUS';
  gv_tkn_cnt           CONSTANT VARCHAR2(15) := 'CNT';
  gv_tkn_conc          CONSTANT VARCHAR2(15) := 'CONC';
  gv_tkn_user          CONSTANT VARCHAR2(15) := 'USER';
  gv_tkn_ng_profile    CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';
  gv_tkn_ng_user       CONSTANT VARCHAR2(15) := 'NG_USER';
  gv_tkn_ng_tkyoten    CONSTANT VARCHAR2(15) := 'NG_TKYOTEN';
  gv_tkn_api_name      CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_time          CONSTANT VARCHAR2(15) := 'TIME';
--
  --�v���t�@�C��
  gv_prf_max_date      CONSTANT VARCHAR2(15) := 'XXCMN_MAX_DATE';         -- �ő���t
  gv_prf_min_date      CONSTANT VARCHAR2(15) := 'XXCMN_MIN_DATE';         -- �ŏ����t
  gv_prf_role_id       CONSTANT VARCHAR2(15) := 'XXCMN_ROLE_ID';          -- ����ID
  gv_prf_password      CONSTANT VARCHAR2(15) := 'XXCMN_PASS_WORD';        -- �����p�X���[�h
  gv_prf_app_short     CONSTANT VARCHAR2(25) := 'XXCMN_APP_SHORT_NAME';   -- �A�v���P�[�V����ID
  gv_prf_max_date_name CONSTANT VARCHAR2(50) := 'MAX���t';
  gv_prf_min_date_name CONSTANT VARCHAR2(50) := 'MIN���t';
  gv_prf_role_id_name  CONSTANT VARCHAR2(50) := '����ID';
  gv_prf_password_name CONSTANT VARCHAR2(50) := '���[�U�[�����p�X���[�h';
  gv_prf_short_name    CONSTANT VARCHAR2(50) := '�A�v���P�[�V����ID';
--
  -- �g�pDB��
  gv_xxcmn_emp_if_name          CONSTANT VARCHAR2(100) := '�Ј��C���^�t�F�[�X';
--
  -- �Ώ�DB��
  gv_per_all_people_f_name      CONSTANT VARCHAR2(100) := '�]�ƈ��}�X�^';
  gv_per_all_assignments_f_name CONSTANT VARCHAR2(100) := '�]�ƈ������}�X�^';
  gv_fnd_user_name              CONSTANT VARCHAR2(100) := '���[�U�[�}�X�^';
  gv_fnd_user_resp_group_a_name CONSTANT VARCHAR2(100) := '���[�U�[�E�Ӄ}�X�^';
  gv_po_agents_name             CONSTANT VARCHAR2(100) := '�w���S���}�X�^';
  gv_wsh_grants_name            CONSTANT VARCHAR2(100) := '�o�׃��[���}�X�^';
  gv_fnd_user_resp_name         CONSTANT VARCHAR2(100) := '�E�Ӄ}�X�^';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �e�}�X�^�ւ̔��f�����ɕK�v�ȃf�[�^���i�[���郌�R�[�h
  TYPE masters_rec IS RECORD(
    -- �]�ƈ��C���^�t�F�[�X
    seq_num                   xxcmn_emp_if.seq_num%TYPE,            --SEQ�ԍ�
    proc_code                 xxcmn_emp_if.proc_code%TYPE,          --�X�V�敪
    employee_num              xxcmn_emp_if.employee_num%TYPE,       --�c�ƈ��R�[�h
    base_code                 xxcmn_emp_if.base_code%TYPE,          --�S�����_�R�[�h
    user_name                 xxcmn_emp_if.user_name%TYPE,          --����
    user_name_alt             xxcmn_emp_if.user_name_alt%TYPE,      --����(�J�i)
    position_id               xxcmn_emp_if.position_id%TYPE,        --�E��
    qualification_id          xxcmn_emp_if.qualification_id%TYPE,   --���i�|�C���g
    spare                     xxcmn_emp_if.spare%TYPE,              --�\��
    -- ���Ə��}�X�^
    location_id               hr_locations_all.location_id%TYPE,    --���P�[�V����ID
    po_flag                   hr_locations_all.attribute3%TYPE,     --�w���S���t���O
    wsh_flag                  hr_locations_all.attribute4%TYPE,     --�o�גS���t���O
    resp1                     hr_locations_all.attribute5%TYPE,     --�S���E�ӂP
    resp2                     hr_locations_all.attribute6%TYPE,     --�S���E�ӂQ
    resp3                     hr_locations_all.attribute7%TYPE,     --�S���E�ӂR
    resp4                     hr_locations_all.attribute8%TYPE,     --�S���E�ӂS
    resp5                     hr_locations_all.attribute9%TYPE,     --�S���E�ӂT
    resp6                     hr_locations_all.attribute10%TYPE,    --�S���E�ӂU
    resp7                     hr_locations_all.attribute11%TYPE,    --�S���E�ӂV
    resp8                     hr_locations_all.attribute12%TYPE,    --�S���E�ӂW
    resp9                     hr_locations_all.attribute13%TYPE,    --�S���E�ӂX
    resp10                    hr_locations_all.attribute14%TYPE,    --�S���E�ӂP�O
    -- �]�ƈ��}�X�^
    person_id                 per_all_people_f.person_id%TYPE,      --�]�ƈ�ID
    object_version_number     per_all_people_f.object_version_number%TYPE,
    -- �]�ƈ������}�X�^
    ass_object_version_number per_all_assignments_f.object_version_number%TYPE,
    period_of_service_id      per_all_assignments_f.period_of_service_id%TYPE,
    assignment_id             per_all_assignments_f.assignment_id%TYPE,
    -- ���[�U�}�X�^
    user_id                   fnd_user.user_id%TYPE,                --���[�U�[ID
    -- ���݂̃f�[�^�ȑO�ł̌���
    row_ins_cnt               NUMBER,                               -- �o�^����
    row_upd_cnt               NUMBER,                               -- �X�V����
    row_del_cnt               NUMBER                                -- �폜����
  );
--
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl IS TABLE OF masters_rec INDEX BY PLS_INTEGER;
--
  -- �o�͂��郍�O���i�[���郌�R�[�h
  TYPE report_rec IS RECORD(
    seq_num                   xxcmn_emp_if.seq_num%TYPE,            --SEQ�ԍ�
    proc_code                 xxcmn_emp_if.proc_code%TYPE,          --�X�V�敪
    employee_num              xxcmn_emp_if.employee_num%TYPE,       --�]�ƈ��R�[�h
    base_code                 xxcmn_emp_if.base_code%TYPE,          --�S�����_�R�[�h
    user_name                 xxcmn_emp_if.user_name%TYPE,          --����
    user_name_alt             xxcmn_emp_if.user_name_alt%TYPE,      --����(�J�i)
    position_id               xxcmn_emp_if.position_id%TYPE,        --�E��
    qualification_id          xxcmn_emp_if.qualification_id%TYPE,   --���i�|�C���g
    spare                     xxcmn_emp_if.spare%TYPE,              --�\��
    row_level_status          NUMBER,                               -- 0.����,1.���s,2.�x��
    -- ���f��e�[�u���t���O(0:�� 1:��)
    papf_flg                  NUMBER,                               --�]�ƈ��}�X�^
    paaf_flg                  NUMBER,                               --�]�ƈ������}�X�^
    fusr_flg                  NUMBER,                               --���[�U�[�}�X�^
    furg_flg                  NUMBER,                               --���[�U�[�E�Ӄ}�X�^
    pagn_flg                  NUMBER,                               --�w���S���}�X�^
    wshg_flg                  NUMBER,                               --�o�׃��[���}�X�^
--
    message                   VARCHAR2(1000)
  );
--
  -- �o�͂��郌�|�[�g���i�[���錋���z��
  TYPE report_tbl IS TABLE OF report_rec INDEX BY PLS_INTEGER;
--
  -- �����󋵂��Ǘ����郌�R�[�h
  TYPE status_rec IS RECORD(
    file_level_status         NUMBER,                               -- 0.����,1.���s�E�x������
    row_level_status          NUMBER,                               -- 0.����,1.���s,2.�x��
    row_err_message           VARCHAR2(1000)                        -- �G���[���b�Z�[�W
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_min_date        VARCHAR2(10);                                  -- �ŏ����t
  gv_max_date        VARCHAR2(10);                                  -- �ő���t
  gv_role_id         VARCHAR2(1);                                   -- ����ID
  gv_bisiness_grp_id per_person_types.business_group_id%TYPE;       -- �r�W�l�X�O���[�vID
  gv_person_type     per_person_types.person_type_id%TYPE;          -- �p�[�\���^�C�v
  gv_password        fnd_user.encrypted_foundation_password%TYPE;   -- �����p�X���[�h
--
  gv_employee_number per_all_people_f.employee_number%TYPE;         -- �]�ƈ��ԍ�
--
  gv_short_name      VARCHAR2(20);                                  -- �A�v���P�[�V����ID
--
  -- �萔
  gn_created_by               NUMBER;                     -- �쐬��
  gd_creation_date            DATE;                       -- �쐬��
  gd_last_update_date         DATE;                       -- �ŏI�X�V��
  gn_last_update_by           NUMBER;                     -- �ŏI�X�V��
  gn_last_update_login        NUMBER;                     -- �ŏI�X�V���O�C��
  gn_request_id               NUMBER;                     -- �v��ID
  gn_program_application_id   NUMBER;                     -- �v���O�����A�v���P�[�V����ID
  gn_program_id               NUMBER;                     -- �v���O����ID
  gd_program_update_date      DATE;                       -- �v���O�����X�V��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
--
  -- �]�ƈ��}�X�^
  CURSOR gc_ppf_cur
  IS
    SELECT ppf.person_id
    FROM   per_all_people_f ppf
    WHERE  EXISTS (
      SELECT xeif.employee_num
      FROM   xxcmn_emp_if xeif
      WHERE  xeif.employee_num = ppf.employee_number
      AND    ROWNUM = 1)
    FOR UPDATE OF ppf.person_id NOWAIT;
--
  -- �]�ƈ������}�X�^
  CURSOR gc_paf_cur
  IS
    SELECT paf.assignment_id
    FROM   per_all_assignments_f paf
    WHERE  EXISTS (
      SELECT ppf.person_id
      FROM   per_all_people_f ppf
      WHERE  EXISTS (
        SELECT xeif.employee_num
        FROM   xxcmn_emp_if xeif
        WHERE  xeif.employee_num = ppf.employee_number
        AND    ROWNUM = 1)
      AND    ppf.person_id = paf.person_id
      AND    ROWNUM = 1)
    FOR UPDATE OF paf.assignment_id NOWAIT;
--
  -- ���[�U�[�}�X�^
  CURSOR gc_fu_cur
  IS
    SELECT fu.user_id
    FROM   fnd_user fu
    WHERE  EXISTS (
      SELECT ppf.person_id
      FROM   per_all_people_f ppf
      WHERE  EXISTS (
        SELECT xeif.employee_num
        FROM   xxcmn_emp_if xeif
        WHERE  xeif.employee_num = ppf.employee_number
        AND    ROWNUM = 1)
      AND    ppf.person_id = fu.employee_id
      AND    ROWNUM = 1)
    FOR UPDATE OF fu.user_id NOWAIT;
--
  -- ���[�U�[�E�Ӄ}�X�^
  CURSOR gc_fug_cur
  IS
    SELECT fug.user_id
    FROM   fnd_user_resp_groups_all fug
    WHERE  EXISTS (
      SELECT fu.user_id
      FROM   fnd_user fu
      WHERE  EXISTS (
        SELECT ppf.person_id
        FROM   per_all_people_f ppf
        WHERE  EXISTS (
          SELECT xeif.employee_num
          FROM   xxcmn_emp_if xeif
          WHERE  xeif.employee_num = ppf.employee_number
          AND    ROWNUM = 1)
        AND    ppf.person_id = fu.employee_id
        AND    ROWNUM = 1)
      AND    fu.user_id = fug.user_id
      AND    ROWNUM = 1)
    FOR UPDATE OF fug.user_id NOWAIT;
--
  -- �w���S���}�X�^
  CURSOR gc_poa_cur
  IS
    SELECT poa.agent_id
    FROM   po_agents poa
    WHERE  EXISTS (
      SELECT ppf.person_id
      FROM   per_all_people_f ppf
      WHERE  EXISTS (
        SELECT xeif.employee_num
        FROM   xxcmn_emp_if xeif
        WHERE  xeif.employee_num = ppf.employee_number
        AND    ROWNUM = 1)
      AND    ppf.person_id = poa.agent_id
      AND    ROWNUM = 1)
    FOR UPDATE OF poa.agent_id NOWAIT;
--
  -- �o�׃��[���}�X�^
  CURSOR gc_wgs_cur
  IS
    SELECT wgs.grant_id
    FROM   wsh_grants wgs
    WHERE  EXISTS (
      SELECT fu.user_id
      FROM   fnd_user fu
      WHERE  EXISTS (
        SELECT ppf.person_id
        FROM   per_all_people_f ppf
        WHERE  EXISTS (
          SELECT xeif.employee_num
          FROM   xxcmn_emp_if xeif
          WHERE  xeif.employee_num = ppf.employee_number
          AND    ROWNUM = 1)
        AND    ppf.person_id = fu.employee_id
        AND    ROWNUM = 1)
      AND    wgs.user_id = fu.user_id
      AND    ROWNUM = 1)
    FOR UPDATE OF wgs.grant_id NOWAIT;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : �v���t�@�C�����MAX���t,MIN���t���擾���܂��B
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�ő���t�擾
    gv_max_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_max_date),1,10);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_max_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_012,
                                            gv_tkn_ng_profile, gv_prf_max_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�ŏ����t�擾
    gv_min_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_min_date),1,10);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_012,
                                            gv_tkn_ng_profile, gv_prf_min_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --����ID�擾
    gv_role_id := NVL(FND_PROFILE.VALUE(gv_prf_role_id),1);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_role_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_012,
                                            gv_tkn_ng_profile, gv_prf_role_id_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �����p�X���[�h�擾
    gv_password := FND_PROFILE.VALUE(gv_prf_password);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_password IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_012,
                                            gv_tkn_ng_profile, gv_prf_password_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 2008/07/07 Add ��
    -- �A�v���P�[�V����ID�擾
    gv_short_name := FND_PROFILE.VALUE(gv_prf_app_short);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_short_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_012,
                                            gv_tkn_ng_profile, gv_prf_short_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 2008/07/07 Add ��
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_profile;
--
  /***********************************************************************************
   * Procedure Name   : get_per_person_types
   * Description      : �p�[�\���^�C�v�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_per_person_types(
    ov_errbuf    OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode   OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg    OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_per_person_types'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      gv_person_type     := NULL;
      gv_bisiness_grp_id := NULL;
--
      SELECT ppt.person_type_id
            ,ppt.business_group_id
      INTO   gv_person_type
            ,gv_bisiness_grp_id
      FROM   per_person_types ppt
      WHERE  ppt.user_person_type = gv_user_person_type
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_person_type     := NULL;
        gv_bisiness_grp_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_per_person_types;
--
  /***********************************************************************************
   * Procedure Name   : set_if_lock
   * Description      : �Ј��C���^�t�F�[�X�̃e�[�u�����b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE set_if_lock(
    ov_errbuf   OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_if_lock'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd  BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lb_retcd := TRUE;
--
    -- �e�[�u�����b�N����(���ʊ֐�)
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_msg_kbn, gv_emp_if_name);
--
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                            gv_tkn_table, gv_xxcmn_emp_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_if_lock;
--
  /***********************************************************************************
   * Procedure Name   : set_error_status
   * Description      : �G���[������������Ԃɂ��܂��B
   ***********************************************************************************/
  PROCEDURE set_error_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- ������
    iv_message    IN            VARCHAR2,    -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_error_status'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ir_status_rec.file_level_status := gn_data_status_error;
    ir_status_rec.row_level_status  := gn_data_status_error;
    ir_status_rec.row_err_message   := iv_message;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_error_status;
--
  /***********************************************************************************
   * Procedure Name   : set_warn_status
   * Description      : �x��������������Ԃɂ��܂��B
   ***********************************************************************************/
  PROCEDURE set_warn_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- ������
    iv_message    IN            VARCHAR2,    -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_warn_status'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ir_status_rec.row_level_status  := gn_data_status_warn;
    ir_status_rec.row_err_message   := iv_message;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_warn_status;
--
  /***********************************************************************************
   * Procedure Name   : init_status
   * Description      : �X�e�[�^�X�����������܂��B
   ***********************************************************************************/
  PROCEDURE init_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- ������
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_status'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ir_status_rec.file_level_status := gn_data_status_nomal;
    ir_status_rec.row_level_status  := gn_data_status_nomal;
    ir_status_rec.row_err_message   := NULL;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END init_status;
--
--
  /***********************************************************************************
   * Function Name    : is_file_status_nomal
   * Description      : �t�@�C�����x���Ő���ȏ�Ԃł��邩��Ԃ��܂��B
   ***********************************************************************************/
  FUNCTION is_file_status_nomal(
    ir_status_rec  IN status_rec)  -- ������
    RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_file_status_nomal'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd   BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.file_level_status = gn_data_status_nomal) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   #############################################
--
  END is_file_status_nomal;
--
  /***********************************************************************************
   * Procedure Name   : init_row_status
   * Description      : �s���x���̃X�e�[�^�X�����������܂��B
   ***********************************************************************************/
  PROCEDURE init_row_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- ������
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_row_status'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ir_status_rec.row_level_status  := gn_data_status_nomal;
    ir_status_rec.row_err_message   := NULL;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END init_row_status;
--
  /***********************************************************************************
   * Function Name    : is_row_status_nomal
   * Description      : �s���x���Ő���ȏ�Ԃł��邩��Ԃ��܂��B
   ***********************************************************************************/
  FUNCTION is_row_status_nomal(
    ir_status_rec  IN status_rec)  -- ������
    RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_row_status_nomal'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd   BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.row_level_status = gn_data_status_nomal) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   #############################################
--
  END is_row_status_nomal;
--
  /***********************************************************************************
   * Function Name    : is_row_status_warn
   * Description      : �s���x���Ōx����Ԃł��邩��Ԃ��܂��B
   ***********************************************************************************/
  FUNCTION is_row_status_warn(
    ir_status_rec  IN status_rec)  -- ������
    RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_row_status_warn'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd    BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.row_level_status = gn_data_status_warn) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   #############################################
--
  END is_row_status_warn;
--
  /***********************************************************************************
   * Procedure Name   : set_line_lock
   * Description      : �e�[�u���̍s���b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE set_line_lock(
    ir_masters_rec IN  masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_line_lock'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �]�ƈ��}�X�^
    BEGIN
      OPEN gc_ppf_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_per_all_people_f_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �]�ƈ������}�X�^
    BEGIN
      OPEN gc_paf_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_per_all_assignments_f_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ���[�U�[�}�X�^
    BEGIN
      OPEN gc_fu_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_fnd_user_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ���[�U�[�E�Ӄ}�X�^
    BEGIN
      OPEN gc_fug_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_fnd_user_resp_group_a_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �w���S���}�X�^
    BEGIN
      OPEN gc_poa_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_po_agents_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �o�׃��[���}�X�^
    BEGIN
      OPEN gc_wgs_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_wsh_grants_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_line_lock;
--
  /***********************************************************************************
   * Procedure Name   : get_xxcmn_emp_if
   * Description      : �Ј��C���^�t�F�[�X�̉ߋ��̌����擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_xxcmn_emp_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xxcmn_emp_if'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      ir_masters_rec.row_ins_cnt := 0;
      ir_masters_rec.row_upd_cnt := 0;
      ir_masters_rec.row_del_cnt := 0;
--
      -- �Ј��C���^�t�F�[�X
      SELECT SUM(NVL(DECODE(xei.proc_code,gn_proc_insert,1),0)),
             SUM(NVL(DECODE(xei.proc_code,gn_proc_update,1),0)),
             SUM(NVL(DECODE(xei.proc_code,gn_proc_delete,1),0))
      INTO   ir_masters_rec.row_ins_cnt,
             ir_masters_rec.row_upd_cnt,
             ir_masters_rec.row_del_cnt
      FROM   xxcmn_emp_if xei
      WHERE  xei.employee_num = ir_masters_rec.employee_num   -- �]�ƈ��R�[�h������
      AND    xei.base_code = ir_masters_rec.base_code         -- �S�����_�R�[�h������
      AND    xei.seq_num < ir_masters_rec.seq_num             -- SEQ�ԍ����ȑO�̃f�[�^
      GROUP BY xei.employee_num;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_ins_cnt := 0;
        ir_masters_rec.row_upd_cnt := 0;
        ir_masters_rec.row_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_xxcmn_emp_if;
--
  /***********************************************************************************
   * Procedure Name   : get_per_all_people_f
   * Description      : �]�ƈ�ID���擾�����݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_per_all_people_f(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_per_all_people_f'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
-- 
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      -- �]�ƈ��}�X�^
      SELECT papf.person_id,                                       --�]�ƈ�ID
             papf.object_version_number,                           --�o�[�W�����ԍ�
             paaf.object_version_number,                           --�o�[�W�����ԍ�(����)
             paaf.period_of_service_id,
             paaf.assignment_id                                    --�]�ƈ�����ID
      INTO   ir_masters_rec.person_id,
             ir_masters_rec.object_version_number,
             ir_masters_rec.ass_object_version_number,
             ir_masters_rec.period_of_service_id,
             ir_masters_rec.assignment_id
      FROM   per_all_people_f papf                                 -- �]�ƈ��}�X�^
            ,per_all_assignments_f paaf                            -- �]�ƈ������}�X�^
      WHERE  papf.employee_number = ir_masters_rec.employee_num    --�]�ƈ��ԍ�
      AND    papf.person_id = paaf.person_id
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.person_id                 := NULL;
        ir_masters_rec.object_version_number     := NULL;
        ir_masters_rec.ass_object_version_number := NULL;
        ir_masters_rec.period_of_service_id      := NULL;
        ir_masters_rec.assignment_id             := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_per_all_people_f;
--
  /***********************************************************************************
   * Procedure Name   : get_fnd_user
   * Description      : ���[�U�[ID���擾�����݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_fnd_user(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fnd_user'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      -- ���[�U�[�}�X�^
      SELECT fusr.user_id
      INTO   ir_masters_rec.user_id
      FROM   per_all_people_f papf                    -- �]�ƈ��}�X�^
            ,fnd_user fusr                            -- ���[�U�[�}�X�^
      WHERE  papf.person_id       = fusr.employee_id
      AND    papf.employee_number = ir_masters_rec.employee_num
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.user_id := NULL; -- �Y���f�[�^�Ȃ�
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_fnd_user;
--
  /***********************************************************************************
   * Procedure Name   : get_fnd_responsibility
   * Description      : �E�Ӄ}�X�^�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_fnd_responsibility(
    in_resp        IN         VARCHAR2,    -- �S���E��
    ob_retcd       OUT NOCOPY BOOLEAN,     -- ��������
    ov_errbuf      OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fnd_responsibility'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt     NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- �E�Ӄ}�X�^
    SELECT COUNT(fres.application_id)
    INTO   ln_cnt
    FROM   fnd_responsibility fres                    -- �E�Ӄ}�X�^
          ,fnd_application    fapp
    WHERE  fres.application_id         = fapp.application_id
    AND    fres.responsibility_id      = TO_NUMBER(in_resp)
    AND    fapp.application_short_name = gv_short_name
    AND    ROWNUM = 1;
--
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_fnd_responsibility;
--
  /***********************************************************************************
   * Procedure Name   : get_per_ass_all_f
   * Description      : �]�ƈ������}�X�^�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_per_ass_all_f(
    or_masters_rec IN         masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ob_retcd       OUT NOCOPY BOOLEAN,     -- ��������
    ov_errbuf      OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_per_ass_all_f'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt   NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- �]�ƈ������}�X�^
    SELECT COUNT(paf.assignment_id)
    INTO   ln_cnt
    FROM   per_all_people_f ppf                    -- �]�ƈ��}�X�^
          ,per_all_assignments_f paf               -- �]�ƈ������}�X�^
    WHERE  ppf.person_id       = paf.person_id
    AND    ppf.employee_number = or_masters_rec.employee_num
    AND    ROWNUM = 1;
--
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_per_ass_all_f;
--
  /***********************************************************************************
   * Procedure Name   : get_po_agents
   * Description      : �w���S���}�X�^�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_po_agents(
    or_masters_rec IN         masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ob_retcd       OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_po_agents'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt   NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- �w���S���}�X�^
    SELECT COUNT(poa.agent_id)
    INTO   ln_cnt
    FROM   per_all_people_f ppf                   -- �]�ƈ��}�X�^
          ,po_agents poa                          -- �w���S���}�X�^
    WHERE  ppf.person_id       = poa.agent_id
    AND    ppf.employee_number = or_masters_rec.employee_num
    AND    ROWNUM = 1;
--
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_po_agents;
--
  /***********************************************************************************
   * Procedure Name   : get_wsh_grants
   * Description      : �o�׃��[���}�X�^�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_wsh_grants(
    or_masters_rec IN         masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ob_retcd       OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_wsh_grants'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt   NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- �o�׃��[���}�X�^
    SELECT COUNT(wgs.grant_id)
    INTO   ln_cnt
    FROM   per_all_people_f ppf                  -- �]�ƈ��}�X�^
          ,fnd_user fu                           -- ���[�U�[�}�X�^
          ,wsh_grants wgs                        -- �o�׃��[���}�X�^
    WHERE  ppf.person_id       = fu.employee_id
    AND    wgs.user_id         = fu.user_id
    AND    ppf.employee_number = or_masters_rec.employee_num
    AND    ROWNUM = 1;
--
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_wsh_grants;
--
  /***********************************************************************************
   * Procedure Name   : get_application
   * Description      : �E�ӃL�[�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_application(
    iv_resp_id      IN         VARCHAR2,    -- responsibility_id
    ov_resp_key     OUT NOCOPY VARCHAR2,    -- responsibility_key
    ov_app_name     OUT NOCOPY VARCHAR2,    -- application_short_name
    ob_retcd        OUT NOCOPY BOOLEAN,     -- ��������
    ov_errbuf       OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_application'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      ob_retcd := TRUE;
      ov_resp_key := NULL;
      ov_app_name := NULL;
--
      SELECT fres.responsibility_key
            ,fapp.application_short_name
      INTO   ov_resp_key
            ,ov_app_name
      FROM   fnd_responsibility fres                    -- �E�Ӄ}�X�^
            ,fnd_application    fapp
      WHERE  fres.application_id         = fapp.application_id
      AND    fres.responsibility_id      = iv_resp_id
      AND    fapp.application_short_name = gv_short_name
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_application;
--
  /***********************************************************************************
   * Procedure Name   : add_report
   * Description      : ���|�[�g�p�f�[�^��ݒ肵�܂��B
   ***********************************************************************************/
  PROCEDURE add_report(
    ir_status_rec  IN            status_rec,
    ir_masters_rec IN            masters_rec,
    it_report_tbl  IN OUT NOCOPY report_tbl,
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_report'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_report_rec report_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���|�[�g���R�[�h�ɒl��ݒ�
    lr_report_rec.seq_num          := ir_masters_rec.seq_num;
    lr_report_rec.proc_code        := ir_masters_rec.proc_code;
    lr_report_rec.employee_num     := ir_masters_rec.employee_num;
    lr_report_rec.base_code        := ir_masters_rec.base_code;
    lr_report_rec.user_name        := ir_masters_rec.user_name;
    lr_report_rec.user_name_alt    := ir_masters_rec.user_name_alt;
    lr_report_rec.position_id      := ir_masters_rec.position_id;
    lr_report_rec.qualification_id := ir_masters_rec.qualification_id;
    lr_report_rec.spare            := ir_masters_rec.spare;
    lr_report_rec.row_level_status := ir_status_rec.row_level_status;
    lr_report_rec.message          := ir_status_rec.row_err_message;
--
    lr_report_rec.papf_flg         := 0;
    lr_report_rec.paaf_flg         := 0;
    lr_report_rec.fusr_flg         := 0;
    lr_report_rec.furg_flg         := 0;
    lr_report_rec.pagn_flg         := 0;
    lr_report_rec.wshg_flg         := 0;
--
    -- ���|�[�g�e�[�u���ɒǉ�
    it_report_tbl(gn_report_cnt) := lr_report_rec;
    gn_report_cnt := gn_report_cnt + 1;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END add_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : ���|�[�g�p�f�[�^���o�͂��܂��B(C-11)
   ***********************************************************************************/
  PROCEDURE disp_report(
    it_report_tbl  IN         report_tbl,   -- ���b�Z�[�W�e�[�u��
    disp_kbn       IN         NUMBER,       -- �\���Ώۋ敪(0:����,1:�ُ�,2:�x��)
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_report_rec report_rec;
    ln_disp_cnt   NUMBER;
    lv_dspbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- ����
    IF (disp_kbn = gn_data_status_nomal) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_004);
--
    -- �G���[
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_005);
--
    -- �x��
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_006);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �ݒ肳��Ă��郌�|�[�g�̏o��
    <<disp_report_loop>>
    FOR ln_disp_cnt IN 0..gn_report_cnt-1 LOOP
      lr_report_rec := it_report_tbl(ln_disp_cnt);
--
      --���̓f�[�^�̍č\��
      lv_dspbuf := TO_CHAR(lr_report_rec.seq_num)   || gv_msg_pnt ||    --SEQ�ԍ�
                   TO_CHAR(lr_report_rec.proc_code) || gv_msg_pnt ||    --�X�V�敪
                   lr_report_rec.employee_num       || gv_msg_pnt ||    --�c�ƈ��R�[�h
                   lr_report_rec.base_code          || gv_msg_pnt ||    --�S�����_�R�[�h
                   lr_report_rec.user_name          || gv_msg_pnt ||    --����
                   lr_report_rec.user_name_alt      || gv_msg_pnt ||    --����(�J�i)
                   lr_report_rec.position_id        || gv_msg_pnt ||    --�E��
                   lr_report_rec.qualification_id   || gv_msg_pnt ||    --���i�|�C���g
                   lr_report_rec.spare;                                 --�\��
--
      -- �Ώ�
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        -- ����
        IF (disp_kbn = gn_data_status_nomal) THEN
          -- �]�ƈ��}�X�^
          IF (lr_report_rec.papf_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_per_all_people_f_name);
          END IF;
          -- �]�ƈ������}�X�^
          IF (lr_report_rec.paaf_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_per_all_assignments_f_name);
          END IF;
          -- ���[�U�[�}�X�^
          IF (lr_report_rec.fusr_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_fnd_user_name);
          END IF;
          -- ���[�U�[�E�Ӄ}�X�^
          IF (lr_report_rec.furg_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_fnd_user_resp_group_a_name);
          END IF;
          -- �w���S���}�X�^
          IF (lr_report_rec.pagn_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_po_agents_name);
          END IF;
          -- �o�׃��[���}�X�^
          IF (lr_report_rec.wshg_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_wsh_grants_name);
          END IF;
--
        -- ����ȊO
        ELSE
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
      END IF;
--
    END LOOP disp_report_loop;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END disp_report;
--
  /***********************************************************************************
   * Procedure Name   : delete_emp_if
   * Description      : �Ј��C���^�t�F�[�X�̃f�[�^���폜���܂��B(C-11)
   ***********************************************************************************/
  PROCEDURE delete_emp_if(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_emp_if'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd   BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
 --#####################################  �Œ蕔 END   #############################################--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    lb_retcd := TRUE;
--
    -- �f�[�^�폜(���ʊ֐�)
    lb_retcd := xxcmn_common_pkg.del_all_data(gv_msg_kbn, gv_emp_if_name);
--
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_017,
                                            gv_tkn_table, gv_xxcmn_emp_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END delete_emp_if;
--
  /***********************************************************************************
   * Procedure Name   : get_fnd_user_resp_all
   * Description      : ���[�U�[�E�Ӄ}�X�^�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_fnd_user_resp_all(
    in_user_id               IN         NUMBER,
    in_respons_id            IN         NUMBER,
    on_responsibility_app_id OUT        NUMBER,
    on_security_group_id     OUT        NUMBER,
    od_start_date            OUT        DATE,
    ob_retcd                 OUT NOCOPY BOOLEAN,     -- ��������
    ov_errbuf                OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fnd_user_resp_all'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      ob_retcd := TRUE;
--
      -- ���[�U�[�E�Ӄ}�X�^
      SELECT fug.responsibility_application_id,
             fug.security_group_id,
             fug.start_date
      INTO   on_responsibility_app_id,
             on_security_group_id,
             od_start_date
      FROM   fnd_user_resp_groups_all fug                  -- ���[�U�[�E�Ӄ}�X�^
      WHERE  fug.user_id           = in_user_id
      AND    fug.responsibility_id = in_respons_id
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_fnd_user_resp_all;
--
  /***********************************************************************************
   * Procedure Name   : exists_fnd_respons
   * Description      : �E�Ӄ}�X�^���݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE exists_fnd_respons(
    ir_masters_rec IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ob_retcd       OUT    NOCOPY BOOLEAN,      -- ��������
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_fnd_respons'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd     BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    ob_retcd := TRUE;
--
    -- �E�Ӄ}�X�^���݃`�F�b�N
    -- �S���E�ӂP
    IF (ir_masters_rec.resp1 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp1,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ȃ�
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- �S���E�ӂQ
    IF (ir_masters_rec.resp2 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp2,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ȃ�
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- �S���E�ӂR
    IF (ir_masters_rec.resp3 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp3,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ȃ�
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- �S���E�ӂS
    IF (ir_masters_rec.resp4 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp4,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ȃ�
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- �S���E�ӂT
    IF (ir_masters_rec.resp5 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp5,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ȃ�
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- �S���E�ӂU
    IF (ir_masters_rec.resp6 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp6,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ȃ�
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- �S���E�ӂV
    IF (ir_masters_rec.resp7 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp7,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ȃ�
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- �S���E�ӂW
    IF (ir_masters_rec.resp8 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp8,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ȃ�
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- �S���E�ӂX
    IF (ir_masters_rec.resp9 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp9,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ȃ�
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- �S���E�ӂP�O
    IF (ir_masters_rec.resp10 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp10,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ȃ�
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN  exists_fnd_respons_expt THEN
      ob_retcd := FALSE;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END exists_fnd_respons;
--
  /***********************************************************************************
   * Procedure Name   : exists_fnd_user_all
   * Description      : ���[�U�[�E�Ӄ}�X�^�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE exists_fnd_user_all(
    in_user_id    IN         NUMBER,
    in_respons_id IN         NUMBER,
    ob_retcd      OUT NOCOPY BOOLEAN,     -- ��������
    ov_errbuf     OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_fnd_user_all'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt     NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- ���[�U�[�E�Ӄ}�X�^
    SELECT COUNT(furg.responsibility_application_id)
    INTO   ln_cnt
    FROM   fnd_user_resp_groups_all furg                     -- ���[�U�[�E�Ӄ}�X�^
    WHERE  furg.user_id           = in_user_id
    AND    furg.responsibility_id = in_respons_id
    AND    ROWNUM = 1;
--
    -- ���݂��Ȃ�
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END exists_fnd_user_all;
--
  /***********************************************************************************
   * Procedure Name   : exists_fnd_user_resp
   * Description      : ���[�U�[�E�Ӄ}�X�^���݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE exists_fnd_user_resp(
    ir_masters_rec IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ob_retcd       OUT    NOCOPY BOOLEAN,      -- ����
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_fnd_user_resp'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd     BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- ���[�U�[�E�Ӄ}�X�^���݃`�F�b�N
    -- �S���E�ӂP
    IF (ir_masters_rec.resp1 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp1),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- ���݂���
      IF (lb_retcd) THEN
        -- �o�^
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- ���݂��Ȃ�
      ELSE
        -- �o�^�ȊO���ȑO�ɓo�^�f�[�^�����݂��Ă��Ȃ�
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- �S���E�ӂQ
    IF (ir_masters_rec.resp2 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp2),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- ���݂���
      IF (lb_retcd) THEN
        -- �o�^
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- ���݂��Ȃ�
      ELSE
        -- �o�^�ȊO���ȑO�ɓo�^�f�[�^�����݂��Ă��Ȃ�
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- �S���E�ӂR
    IF (ir_masters_rec.resp3 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp3),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- ���݂���
      IF (lb_retcd) THEN
        -- �o�^
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- ���݂��Ȃ�
      ELSE
        -- �o�^�ȊO���ȑO�ɓo�^�f�[�^�����݂��Ă��Ȃ�
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- �S���E�ӂS
    IF (ir_masters_rec.resp4 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp4),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- ���݂���
      IF (lb_retcd) THEN
        -- �o�^
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- ���݂��Ȃ�
      ELSE
        -- �o�^�ȊO���ȑO�ɓo�^�f�[�^�����݂��Ă��Ȃ�
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- �S���E�ӂT
    IF (ir_masters_rec.resp5 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp5),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- ���݂���
      IF (lb_retcd) THEN
        -- �o�^
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- ���݂��Ȃ�
      ELSE
        -- �o�^�ȊO���ȑO�ɓo�^�f�[�^�����݂��Ă��Ȃ�
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- �S���E�ӂU
    IF (ir_masters_rec.resp6 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp6),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- ���݂���
      IF (lb_retcd) THEN
        -- �o�^
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- ���݂��Ȃ�
      ELSE
        -- �o�^�ȊO���ȑO�ɓo�^�f�[�^�����݂��Ă��Ȃ�
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- �S���E�ӂV
    IF (ir_masters_rec.resp7 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp7),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- ���݂���
      IF (lb_retcd) THEN
        -- �o�^
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- ���݂��Ȃ�
      ELSE
        -- �o�^�ȊO���ȑO�ɓo�^�f�[�^�����݂��Ă��Ȃ�
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- �S���E�ӂW
    IF (ir_masters_rec.resp8 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp8),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- ���݂���
      IF (lb_retcd) THEN
        -- �o�^
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- ���݂��Ȃ�
      ELSE
        -- �o�^�ȊO���ȑO�ɓo�^�f�[�^�����݂��Ă��Ȃ�
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- �S���E�ӂX
    IF (ir_masters_rec.resp9 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp9),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- ���݂���
      IF (lb_retcd) THEN
        -- �o�^
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- ���݂��Ȃ�
      ELSE
        -- �o�^�ȊO���ȑO�ɓo�^�f�[�^�����݂��Ă��Ȃ�
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- �S���E�ӂP�O
    IF (ir_masters_rec.resp10 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp10),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- ���݂���
      IF (lb_retcd) THEN
        -- �o�^
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- ���݂��Ȃ�
      ELSE
        -- �o�^�ȊO���ȑO�ɓo�^�f�[�^�����݂��Ă��Ȃ�
            IF ((ir_masters_rec.proc_code <> gn_proc_insert)
            AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN exists_fnd_user_resp_expt THEN
      ob_retcd := FALSE;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END exists_fnd_user_resp;
--
  /***********************************************************************************
   * Procedure Name   : check_insert
   * Description      : �o�^�p�f�[�^�̃`�F�b�N�������s���܂��B(C-4)
   ***********************************************************************************/
  PROCEDURE check_insert(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_insert'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd     BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    IF (is_row_status_nomal(ir_status_rec)) THEN
      -- �]�ƈ����݃`�F�b�N
      get_per_all_people_f(ir_masters_rec,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      -- �]�ƈ��擾�G���[
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                              gv_tkn_ng_user, ir_masters_rec.employee_num,
                                              gv_tkn_table,   gv_per_all_people_f_name);
        RAISE global_api_expt;
      END IF;
--
      -- �]�ƈ������݂���
      IF (ir_masters_rec.person_id IS NOT NULL) THEN
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                                  gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                  gv_tkn_table,   gv_per_all_people_f_name),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      -- ���[�U���݃`�F�b�N
      get_fnd_user(ir_masters_rec,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
      -- ���[�U�擾�G���[
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                              gv_tkn_ng_user, ir_masters_rec.employee_num,
                                              gv_tkn_table,   gv_fnd_user_name);
        RAISE global_api_expt;
      END IF;
--
      -- ���[�U�����݂���
      IF (ir_masters_rec.user_id IS NOT NULL) THEN
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                                  gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                  gv_tkn_table,   gv_fnd_user_name),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      -- �E�Ӄ}�X�^���݃`�F�b�N
      exists_fnd_respons(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
      IF ((lv_retcode = gv_status_error) OR (NOT lb_retcd)) THEN
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                                  gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                  gv_tkn_table,   gv_fnd_user_name),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        IF (NOT lb_retcd) THEN
          NULL;
        ELSE
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_insert;
--
  /***********************************************************************************
   * Procedure Name   : check_update
   * Description      : �X�V�p�f�[�^�̃`�F�b�N�������s���܂��B(C-5)
   ***********************************************************************************/
  PROCEDURE check_update(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_update'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    lb_retcd     BOOLEAN;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
      IF (is_row_status_nomal(ir_status_rec)) THEN
--
        -- �]�ƈ����݃`�F�b�N
        get_per_all_people_f(ir_masters_rec,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
        -- �]�ƈ��擾�G���[
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                gv_tkn_table,   gv_per_all_people_f_name);
          RAISE global_api_expt;
        END IF;
--
        -- �]�ƈ������݂��Ȃ����ȑO�ɓo�^�f�[�^�����݂��Ȃ��ꍇ
        IF ((ir_masters_rec.person_id IS NULL) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
--
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_per_all_people_f_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ���[�U���݃`�F�b�N
        get_fnd_user(ir_masters_rec,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
        -- ���[�U�擾�G���[
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                gv_tkn_table,   gv_fnd_user_name);
          RAISE global_api_expt;
        END IF;
--
        -- ���[�U�����݂��Ȃ����ȑO�ɓo�^�f�[�^�����݂��Ȃ��ꍇ
        IF ((ir_masters_rec.user_id IS NULL) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
--
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_fnd_user_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- �]�ƈ������}�X�^�̑��݃`�F�b�N
        get_per_ass_all_f(ir_masters_rec,
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ���݂��Ȃ� ���� �ȑO�ɓo�^�f�[�^�����݂��Ȃ�
        IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_per_all_assignments_f_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
-- 2009/03/25 v1.6 DELETE START
/*
        -- �w���S���}�X�^���݃`�F�b�N
        IF (ir_masters_rec.po_flag = gv_flg_on) THEN
          get_po_agents(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- ���݂��Ȃ� ���� �ȑO�ɓo�^�f�[�^�����݂��Ȃ�
          IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
            set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                      gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                      gv_tkn_table,   gv_po_agents_name),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
--
        -- �o�׃��[���}�X�^���݃`�F�b�N
        IF (ir_masters_rec.wsh_flag = gv_flg_on) THEN
          get_wsh_grants(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- ���݂��Ȃ� ���� �ȑO�ɓo�^�f�[�^�����݂��Ȃ�
          IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
            set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                      gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                      gv_tkn_table,   gv_wsh_grants_name),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
--
*/
-- 2009/03/25 v1.6 DELETE END
        -- �E�Ӄ}�X�^���݃`�F�b�N
        exists_fnd_respons(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ���݂��Ȃ� ���� �ȑO�ɓo�^�f�[�^�����݂��Ȃ�
        IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_fnd_user_resp_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_update;
--
  /***********************************************************************************
   * Procedure Name   : check_delete
   * Description      : �폜�p�f�[�^�̃`�F�b�N�������s���܂��B(C-6)
   ***********************************************************************************/
  PROCEDURE check_delete(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_delete'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd     BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
      IF (is_row_status_nomal(ir_status_rec)) THEN
--
        -- �]�ƈ����݃`�F�b�N
        get_per_all_people_f(ir_masters_rec,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
        -- �]�ƈ��擾�G���[
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                gv_tkn_table,   gv_per_all_people_f_name);
          RAISE global_api_expt;
        END IF;
--
        -- �]�ƈ������݂��Ȃ����ȑO�ɓo�^�f�[�^�����݂��Ȃ��ꍇ�̓G���[
        IF ((ir_masters_rec.person_id IS NULL) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
--
          set_warn_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_per_all_people_f_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ���[�U���݃`�F�b�N
        get_fnd_user(ir_masters_rec,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
        -- ���[�U�擾�G���[
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                gv_tkn_table,   gv_fnd_user_name);
          RAISE global_api_expt;
        END IF;
--
        -- ���[�U�[�����݂��Ȃ����ȑO�ɓo�^�f�[�^�����݂��Ȃ��ꍇ�̓G���[
        IF ((ir_masters_rec.user_id IS NULL) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
--
          set_warn_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_fnd_user_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- �]�ƈ������}�X�^���݃`�F�b�N
        get_per_ass_all_f(ir_masters_rec,
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ���݂��Ȃ� ���� �ȑO�ɓo�^�f�[�^�����݂��Ȃ�
        IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          set_warn_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table, gv_per_all_assignments_f_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- �w���S���}�X�^���݃`�F�b�N
        IF (ir_masters_rec.po_flag = gv_flg_on) THEN
          get_po_agents(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- ���݂��Ȃ� ���� �ȑO�ɓo�^�f�[�^�����݂��Ȃ�
          IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
            set_warn_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                      gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                      gv_tkn_table,   gv_po_agents_name),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
--
        -- �o�׃��[���}�X�^���݃`�F�b�N
        IF (ir_masters_rec.wsh_flag = gv_flg_on) THEN
          get_wsh_grants(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- ���݂��Ȃ� ���� �ȑO�ɓo�^�f�[�^�����݂��Ȃ�
          IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                     gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                     gv_tkn_table,   gv_wsh_grants_name),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
--
        -- �E�Ӄ}�X�^���݃`�F�b�N
        exists_fnd_respons(ir_masters_rec,
                           lb_retcd,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ���݂��Ȃ� ���� �ȑO�ɓo�^�f�[�^�����݂��Ȃ�
        IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          set_warn_status(ir_status_rec,
                          xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                   gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                   gv_tkn_table,   gv_fnd_user_resp_name),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ���[�U�[�E�Ӄ}�X�^���݃`�F�b�N
        exists_fnd_user_resp(ir_masters_rec,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ���݂��Ȃ� ���� �ȑO�ɓo�^�f�[�^�����݂��Ȃ�
        IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          set_warn_status(ir_status_rec,
                          xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_80c_020,
                                                   gv_tkn_ng_user,ir_masters_rec.employee_num,
                                                   gv_tkn_table,  gv_fnd_user_resp_group_a_name),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_delete;
--
  /***********************************************************************************
   * Procedure Name   : check_proc_code
   * Description      : ����Ώۂ̃f�[�^�ł��邱�Ƃ��m�F���܂��B
   ***********************************************************************************/
  PROCEDURE check_proc_code(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec IN            masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc_code'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�����敪��(�o�^�E�X�V�E�폜)�ȊO
    IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
    AND (ir_masters_rec.proc_code <> gn_proc_update)
    AND (ir_masters_rec.proc_code <> gn_proc_delete)) THEN
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_016,
                                                'VALUE',    TO_CHAR(ir_masters_rec.proc_code)),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_proc_code;
--
  /***********************************************************************************
   * Procedure Name   : get_location_new
   * Description      : �V�K�o�^���ɒS�����_���擾�����݃`�F�b�N���s���܂��B(C-3)
   ***********************************************************************************/
  PROCEDURE get_location_new(
    ir_status_rec  IN OUT NOCOPY status_rec,   -- ������
    ir_masters_rec IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_location_new'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_hla_cur_cnt  NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    CURSOR hla_cur
    IS
      SELECT hla.location_id,                        -- ���P�[�V����ID
             hla.attribute3,                         -- �w���S���t���O
             hla.attribute4,                         -- �o�גS���t���O
             hla.attribute5,                         -- �S���E�ӂP
             hla.attribute6,                         -- �S���E�ӂQ
             hla.attribute7,                         -- �S���E�ӂR
             hla.attribute8,                         -- �S���E�ӂS
             hla.attribute9,                         -- �S���E�ӂT
             hla.attribute10,                        -- �S���E�ӂU
             hla.attribute11,                        -- �S���E�ӂV
             hla.attribute12,                        -- �S���E�ӂW
             hla.attribute13,                        -- �S���E�ӂX
             hla.attribute14                         -- �S���E�ӂP�O
      FROM   hr_locations_all hla                    -- ���Ə��}�X�^
      WHERE  hla.location_code = ir_masters_rec.base_code;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_hla_cur_cnt := 0;
    OPEN hla_cur;
--
    <<hla_cur_loop>>
    LOOP
      FETCH hla_cur
      INTO  ir_masters_rec.location_id,
            ir_masters_rec.po_flag,
            ir_masters_rec.wsh_flag,
            ir_masters_rec.resp1,
            ir_masters_rec.resp2,
            ir_masters_rec.resp3,
            ir_masters_rec.resp4,
            ir_masters_rec.resp5,
            ir_masters_rec.resp6,
            ir_masters_rec.resp7,
            ir_masters_rec.resp8,
            ir_masters_rec.resp9,
            ir_masters_rec.resp10;
      EXIT WHEN hla_cur%NOTFOUND;
--
      ln_hla_cur_cnt := ln_hla_cur_cnt + 1;
    END LOOP hla_cur_loop;
    CLOSE hla_cur;
--
    -- 1���ȊO
    IF (ln_hla_cur_cnt <> 1) THEN
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_015,
                                                gv_tkn_ng_tkyoten, ir_masters_rec.base_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (hla_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE hla_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (hla_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE hla_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (hla_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE hla_cur;
      END IF;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_location_new;
--
  /***********************************************************************************
   * Procedure Name   : get_location_mod
   * Description      : �ύX�E�폜���ɒS�����_���擾�����݃`�F�b�N���s���܂��B(C-3)
   ***********************************************************************************/
  PROCEDURE get_location_mod(
    ir_status_rec  IN OUT NOCOPY status_rec,   -- ������
    ir_masters_rec IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_location_mod'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_hla_cur_cnt  NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    CURSOR hla_cur
    IS
      SELECT hla.location_id,                        -- ���P�[�V����ID
             hla.attribute3,                         -- �w���S���t���O
             hla.attribute4,                         -- �o�גS���t���O
             hla.attribute5,                         -- �S���E�ӂP
             hla.attribute6,                         -- �S���E�ӂQ
             hla.attribute7,                         -- �S���E�ӂR
             hla.attribute8,                         -- �S���E�ӂS
             hla.attribute9,                         -- �S���E�ӂT
             hla.attribute10,                        -- �S���E�ӂU
             hla.attribute11,                        -- �S���E�ӂV
             hla.attribute12,                        -- �S���E�ӂW
             hla.attribute13,                        -- �S���E�ӂX
             hla.attribute14                         -- �S���E�ӂP�O
-- 2008/10/06 v1.4 UPDATE START
/*
      FROM   per_all_people_f ppf,                   -- �]�ƈ��}�X�^
             per_all_assignments_f paf,              -- �]�ƈ������}�X�^
             hr_locations_all hla                    -- ���Ə��}�X�^
      WHERE  hla.location_code   = ir_masters_rec.base_code
      AND    ppf.employee_number = ir_masters_rec.employee_num
      AND    ppf.person_id       = paf.person_id
      AND    hla.location_id     = paf.location_id
      AND    paf.effective_start_date <= SYSDATE
      AND    paf.effective_end_date >= SYSDATE;
*/
      FROM   hr_locations_all hla                    -- ���Ə��}�X�^
      WHERE  hla.location_code   = ir_masters_rec.base_code;
-- 2008/10/06 v1.4 UPDATE END
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_hla_cur_cnt := 0;
    OPEN hla_cur;
--
    <<hla_cur_loop>>
    LOOP
      FETCH hla_cur
      INTO  ir_masters_rec.location_id,
            ir_masters_rec.po_flag,
            ir_masters_rec.wsh_flag,
            ir_masters_rec.resp1,
            ir_masters_rec.resp2,
            ir_masters_rec.resp3,
            ir_masters_rec.resp4,
            ir_masters_rec.resp5,
            ir_masters_rec.resp6,
            ir_masters_rec.resp7,
            ir_masters_rec.resp8,
            ir_masters_rec.resp9,
            ir_masters_rec.resp10;
      EXIT WHEN hla_cur%NOTFOUND;
--
      ln_hla_cur_cnt := ln_hla_cur_cnt + 1;
    END LOOP hla_cur_loop;
    CLOSE hla_cur;
--
    -- 1���ȊO
    IF (ln_hla_cur_cnt <> 1) THEN
      -- �폜�̏ꍇ
      IF (ir_masters_rec.proc_code = gn_proc_delete) THEN
        set_warn_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_015,
                                                  gv_tkn_ng_tkyoten, ir_masters_rec.base_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
      -- �폜�ȊO�̏ꍇ
      ELSE
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_015,
                                                  gv_tkn_ng_tkyoten, ir_masters_rec.base_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
      END IF;
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (hla_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE hla_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (hla_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE hla_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (hla_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE hla_cur;
      END IF;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_location_mod;
--
  /***********************************************************************************
   * Procedure Name   : get_service_id
   * Description      : �T�[�r�X����ID�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_service_id(
    or_masters_tbl  IN OUT NOCOPY masters_rec,
    ov_service_id   OUT    NOCOPY NUMBER,
    ov_ver_num      OUT    NOCOPY NUMBER,
    ob_retcd        OUT    NOCOPY BOOLEAN,     -- ��������
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_service_id'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      ob_retcd      := TRUE;
      ov_service_id := NULL;
      ov_ver_num    := NULL;
--
      SELECT ppos.period_of_service_id
            ,ppos.object_version_number
      INTO   ov_service_id
            ,ov_ver_num
      FROM   per_periods_of_service ppos
            ,per_all_people_f papf                       -- �]�ƈ��}�X�^
      WHERE  ppos.person_id       = papf.person_id
      AND    papf.employee_number = or_masters_tbl.employee_num
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_service_id;
--
  /***********************************************************************************
   * Procedure Name   : wsh_grants_proc
   * Description      : �o�׃��[���}�X�^�̓o�^�E�폜�������s���܂��B
   ***********************************************************************************/
  PROCEDURE wsh_grants_proc(
    in_proc_kbn    IN            NUMBER,      -- �����敪
    or_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wsh_grants_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_grant_id  wsh_grants.grant_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �o�^
    IF (in_proc_kbn = gn_proc_insert) THEN
      -- �o�^����
      INSERT INTO wsh_grants
      (GRANT_ID,
       USER_ID,
       ROLE_ID,
       ORGANIZATION_ID,
       START_DATE,
       END_DATE,
       CREATED_BY,
       CREATION_DATE,
       LAST_UPDATED_BY,
       LAST_UPDATE_DATE,
       LAST_UPDATE_LOGIN
      )
      VALUES (
       wsh_grants_s.NEXTVAL,                      --GRANT_ID
       or_masters_rec.user_id,                    --USER_ID
       TO_NUMBER(gv_role_id),                     --ROLE_ID
       NULL,                                      --ORGANIZATION_ID
       SYSDATE,                                   --START_DATE
       NULL,                                      --END_DATE
       gn_created_by,
       gd_creation_date,
       gn_last_update_by,
       gd_last_update_date,
       gn_last_update_login
      );
--
    -- �폜
    ELSIF (in_proc_kbn = gn_proc_delete) THEN
      -- �폜����
      DELETE wsh_grants
      WHERE  user_id = or_masters_rec.user_id;
    END IF;
--
  EXCEPTION
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END wsh_grants_proc;
--
  /***********************************************************************************
   * Procedure Name   : po_agents_proc
   * Description      : �w���S���}�X�^�̓o�^�E�폜�������s���܂��B
   ***********************************************************************************/
  PROCEDURE po_agents_proc(
    in_proc_kbn    IN            NUMBER,      -- �����敪
    or_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'po_agents_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_rowid                      ROWID;
    lv_api_name                   VARCHAR2(200);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �o�^
    IF (in_proc_kbn = gn_proc_insert) THEN
      BEGIN
        PO_AGENTS_PKG.INSERT_ROW(
          X_ROWID               => lv_rowid
         ,X_AGENT_ID            => or_masters_rec.person_id          -- �]�ƈ�ID
         ,X_LAST_UPDATE_DATE    => gd_last_update_date
         ,X_LAST_UPDATED_BY     => gn_last_update_by
         ,X_LAST_UPDATE_LOGIN   => gn_last_update_login
         ,X_CREATION_DATE       => gd_creation_date
         ,X_CREATED_BY          => gn_last_update_by
         ,X_LOCATION_ID         => NULL
         ,X_CATEGORY_ID         => NULL
         ,X_AUTHORIZATION_LIMIT => NULL
         ,X_START_DATE_ACTIVE   => NULL
         ,X_END_DATE_ACTIVE     => NULL
         ,X_ATTRIBUTE_CATEGORY  => NULL
         ,X_ATTRIBUTE1          => NULL
         ,X_ATTRIBUTE2          => NULL
         ,X_ATTRIBUTE3          => NULL
         ,X_ATTRIBUTE4          => NULL
         ,X_ATTRIBUTE5          => NULL
         ,X_ATTRIBUTE6          => NULL
         ,X_ATTRIBUTE7          => NULL
         ,X_ATTRIBUTE8          => NULL
         ,X_ATTRIBUTE9          => NULL
         ,X_ATTRIBUTE10         => NULL
         ,X_ATTRIBUTE11         => NULL
         ,X_ATTRIBUTE12         => NULL
         ,X_ATTRIBUTE13         => NULL
         ,X_ATTRIBUTE14         => NULL
         ,X_ATTRIBUTE15         => NULL
        );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'PO_AGENTS_PKG.INSERT_ROW';
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                                gv_tkn_api_name, lv_api_name);
          lv_errbuf := lv_errmsg;
          RAISE global_api_others_expt;
      END;
--
    -- �폜
    ELSE
      DELETE po_agents
      WHERE  agent_id = or_masters_rec.person_id;
    END IF;
--
  EXCEPTION
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END po_agents_proc;
--
  /***********************************************************************************
   * Procedure Name   : set_assignment
   * Description      : ���[�U�E�Ӄ}�X�^�̓o�^�������s���܂��B
   ***********************************************************************************/
  PROCEDURE set_assignment(
    in_user_name  IN         VARCHAR2,     -- ���[�U�[����
    in_date       IN         DATE,         -- �Ώۓ��t
    in_resp       IN         VARCHAR2,     -- �ΏېE��
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_assignment'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_api_name   VARCHAR2(200);
    lb_retcd      BOOLEAN;
    lv_resp_key   fnd_responsibility.responsibility_key%TYPE;
    lv_app_name   fnd_application.application_short_name%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �S���E�ӂ���X_RESP_KEY,X_APP_SHORT_NAME���擾����
    get_application(in_resp,
                    lv_resp_key,
                    lv_app_name,
                    lb_retcd,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    BEGIN
--
        -- ���[�U�E�Ӄ}�X�^
        FND_USER_RESP_GROUPS_API.LOAD_ROW(
          X_USER_NAME         => in_user_name
         ,X_RESP_KEY          => lv_resp_key
         ,X_APP_SHORT_NAME    => lv_app_name
         ,X_SECURITY_GROUP    => 'STANDARD'
         ,X_OWNER             => gn_created_by
         ,X_START_DATE        => TO_CHAR(in_date,'YYYY/MM/DD')
         ,X_END_DATE          => NULL
         ,X_DESCRIPTION       => NULL
         ,X_LAST_UPDATE_DATE  => SYSDATE
        );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_RESP_GROUPS_API.LOAD_ROW';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_assignment;
--
  /***********************************************************************************
   * Procedure Name   : update_resp_all_f
   * Description      : ���[�U�E�Ӄ}�X�^�̍X�V�������s���܂��B
   ***********************************************************************************/
  PROCEDURE update_resp_all_f(
    in_user_id     IN          NUMBER,       -- ���[�UID
    in_user_name   IN          VARCHAR2,     -- ���[�U����
    in_respons_id  IN          VARCHAR2,     -- �E��ID
    ov_errbuf      OUT  NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT  NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT  NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_resp_all_f'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_retcd                 NUMBER;
    lb_retst                 BOOLEAN;
    ln_responsibility_id     fnd_user_resp_groups_all.responsibility_id%TYPE;
    ln_responsibility_app_id fnd_user_resp_groups_all.responsibility_application_id%TYPE;
    ln_security_group_id     fnd_user_resp_groups_all.security_group_id%TYPE;
    ld_start_date            fnd_user_resp_groups_all.start_date%TYPE;
    ld_start_date_u          fnd_user_resp_groups_all.start_date%TYPE;
--
    lv_api_name              VARCHAR2(200);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    IF (in_respons_id IS NOT NULL) THEN
      ln_responsibility_id := TO_NUMBER(in_respons_id);
      -- ���[�U�E�Ӄ}�X�^�擾
      get_fnd_user_resp_all(in_user_id,
                            ln_responsibility_id,
                            ln_responsibility_app_id,
                            ln_security_group_id,
                            ld_start_date,
                            lb_retst,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �f�[�^����
      IF (lb_retst = TRUE) THEN
        BEGIN
          FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT(
            USER_ID                       => in_user_id
           ,RESPONSIBILITY_ID             => ln_responsibility_id
           ,RESPONSIBILITY_APPLICATION_ID => ln_responsibility_app_id
           ,SECURITY_GROUP_ID             => ln_security_group_id
           ,START_DATE                    => ld_start_date
           ,END_DATE                      => NULL
           ,DESCRIPTION                   => 'Y'
          );
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_api_name := 'FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT';
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                                  gv_tkn_api_name, lv_api_name);
            lv_errbuf := lv_errmsg;
            RAISE global_api_others_expt;
        END;
--
      -- �f�[�^�Ȃ�
      ELSE
        ld_start_date_u := FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD');
        -- ���[�U�E�Ӄ}�X�^�o�^
        set_assignment(in_user_name,
                       ld_start_date_u,
                       in_respons_id,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END update_resp_all_f;
--
  /***********************************************************************************
   * Procedure Name   : delete_group_all
   * Description      : ���[�U�[�E�Ӄ}�X�^�̃f�[�^�̖��������s���܂��B
   ***********************************************************************************/
  PROCEDURE delete_group_all(
    ir_masters_rec IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_group_all'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_user_id                    fnd_user_resp_groups_all.user_id%TYPE;
    ln_responsibility_id          fnd_user_resp_groups_all.responsibility_id%TYPE;
    ln_responsibility_app_id      fnd_user_resp_groups_all.responsibility_application_id%TYPE;
    ln_security_group_id          fnd_user_resp_groups_all.security_group_id%TYPE;
    ld_start_date                 fnd_user_resp_groups_all.start_date%TYPE;
--
    lv_api_name                   VARCHAR2(200);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR fug_cur
    IS
      SELECT fug.user_id,
             fug.responsibility_id,
             fug.responsibility_application_id,
             fug.security_group_id,
             fug.start_date
      FROM   fnd_user_resp_groups_all fug                      -- ���[�U�[�E�Ӄ}�X�^
      WHERE  fug.user_id = ir_masters_rec.user_id;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    BEGIN
--
      OPEN fug_cur;
--
      <<fug_cur_loop>>
      LOOP
        FETCH fug_cur
        INTO  ln_user_id,
              ln_responsibility_id,
              ln_responsibility_app_id,
              ln_security_group_id,
              ld_start_date;
        EXIT WHEN fug_cur%NOTFOUND;
--
        -- API�N��
        FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT(
            USER_ID                       => ln_user_id
           ,RESPONSIBILITY_ID             => ln_responsibility_id
           ,RESPONSIBILITY_APPLICATION_ID => ln_responsibility_app_id
           ,SECURITY_GROUP_ID             => ln_security_group_id
           ,START_DATE                    => ld_start_date
           ,END_DATE                      => SYSDATE-1
           ,DESCRIPTION                   => 'Y'
        );
--
      END LOOP fug_cur_loop;
      CLOSE fug_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        IF (fug_cur%ISOPEN) THEN
          -- �J�[�\���̃N���[�Y
          CLOSE fug_cur;
        END IF;
        RAISE delete_group_all_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN delete_group_all_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      IF (fug_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE fug_cur;
      END IF;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      IF (fug_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE fug_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      IF (fug_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE fug_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      IF (fug_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE fug_cur;
      END IF;
--
--#####################################  �Œ蕔 END   #############################################
--
  END delete_group_all;
--
  /***********************************************************************************
   * Procedure Name   : insert_proc
   * Description      : ���[�U�[�o�^���i�[�������s���܂��B(C-10)
   ***********************************************************************************/
  PROCEDURE insert_proc(
    ot_report_tbl  IN OUT NOCOPY report_rec,
    or_masters_tbl IN OUT NOCOPY masters_rec,
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_retcd                      NUMBER;
    ld_start_date                 DATE;
--
    -- HR_EMPLOYEE_API.CREATE_EMPLOYEE
    ln_person_id                  NUMBER;
    ln_assignment_id              NUMBER;
    ln_per_object_version_number  NUMBER;
    ln_asg_object_version_number  NUMBER;
    ld_per_effective_start_date   DATE;
    ld_per_effective_end_date     DATE;
    lv_full_name                  per_all_people_f.full_name%type;
    ln_per_comment_id             NUMBER;
    ln_assignment_sequence        NUMBER;
    lv_assignment_number          per_all_assignments_f.assignment_number%type;
    lb_name_combination_warning   BOOLEAN;
    lb_assign_payroll_warning     BOOLEAN;
    lb_orig_hire_warning          BOOLEAN;
--
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_people_group_id            NUMBER;
    ln_special_ceiling_step_id    NUMBER;
    lv_group_name                 VARCHAR2(200);
    lb_org_now_no_manager_warning BOOLEAN;
    lb_other_manager_warning      BOOLEAN;
    lb_spp_delete_warning         BOOLEAN;
    lv_entries_changes_warn       VARCHAR2(200);
    lb_tax_district_changed_warn  BOOLEAN;
--
    -- FND_USER_PKG.CREATEUSERID
    ln_user_id                    fnd_user_resp_groups_all.user_id%TYPE;
--
    lv_api_name                   VARCHAR2(200);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �]�ƈ��}�X�^(API)
    BEGIN
--
      HR_EMPLOYEE_API.CREATE_EMPLOYEE(
        P_VALIDATE                     => FALSE
       ,P_HIRE_DATE                    => SYSDATE
       ,P_BUSINESS_GROUP_ID            => gv_bisiness_grp_id
       ,P_LAST_NAME                    => or_masters_tbl.user_name_alt
       ,P_SEX                          => gv_def_sex
       ,P_PERSON_TYPE_ID               => gv_person_type
       ,P_EMPLOYEE_NUMBER              => or_masters_tbl.employee_num
       ,P_ATTRIBUTE1                   => or_masters_tbl.qualification_id
       ,P_ATTRIBUTE2                   => or_masters_tbl.position_id
       ,P_PER_INFORMATION_CATEGORY     => gv_info_category
       ,P_PER_INFORMATION18            => or_masters_tbl.user_name
       ,P_PERSON_ID                    => ln_person_id                       -- OUT
       ,P_ASSIGNMENT_ID                => ln_assignment_id                   -- OUT
       ,P_PER_OBJECT_VERSION_NUMBER    => ln_per_object_version_number       -- OUT
       ,P_ASG_OBJECT_VERSION_NUMBER    => ln_asg_object_version_number       -- OUT
       ,P_PER_EFFECTIVE_START_DATE     => ld_per_effective_start_date        -- OUT
       ,P_PER_EFFECTIVE_END_DATE       => ld_per_effective_end_date          -- OUT
       ,P_FULL_NAME                    => lv_full_name                       -- OUT
       ,P_PER_COMMENT_ID               => ln_per_comment_id                  -- OUT
       ,P_ASSIGNMENT_SEQUENCE          => ln_assignment_sequence             -- OUT
       ,P_ASSIGNMENT_NUMBER            => lv_assignment_number               -- OUT
       ,P_NAME_COMBINATION_WARNING     => lb_name_combination_warning        -- OUT
       ,P_ASSIGN_PAYROLL_WARNING       => lb_assign_payroll_warning          -- OUT
       ,P_ORIG_HIRE_WARNING            => lb_orig_hire_warning               -- OUT
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EMPLOYEE_API.CREATE_EMPLOYEE';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.papf_flg := 1;
--
    -- �]�ƈ������}�X�^(API)
    BEGIN
       HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
           P_VALIDATE                      => FALSE
          ,P_EFFECTIVE_DATE                => SYSDATE
          ,P_DATETRACK_UPDATE_MODE         => gv_upd_mode
          ,P_ASSIGNMENT_ID                 => ln_assignment_id
          ,P_LOCATION_ID                   => or_masters_tbl.location_id
          ,P_PEOPLE_GROUP_ID               => ln_people_group_id             -- OUT
          ,P_OBJECT_VERSION_NUMBER         => ln_asg_object_version_number   -- OUT
          ,P_SPECIAL_CEILING_STEP_ID       => ln_special_ceiling_step_id     -- OUT
          ,P_GROUP_NAME                    => lv_group_name                  -- OUT
          ,P_EFFECTIVE_START_DATE          => ld_per_effective_start_date    -- OUT
          ,P_EFFECTIVE_END_DATE            => ld_per_effective_end_date      -- OUT
          ,P_ORG_NOW_NO_MANAGER_WARNING    => lb_org_now_no_manager_warning  -- OUT
          ,P_OTHER_MANAGER_WARNING         => lb_other_manager_warning       -- OUT
          ,P_SPP_DELETE_WARNING            => lb_spp_delete_warning          -- OUT
          ,P_ENTRIES_CHANGED_WARNING       => lv_entries_changes_warn        -- OUT
          ,P_TAX_DISTRICT_CHANGED_WARNING  => lb_tax_district_changed_warn   -- OUT
         );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.paaf_flg := 1;
--
    -- ���[�U�}�X�^(API)
    BEGIN
--
      ln_user_id := FND_USER_PKG.CREATEUSERID(
                      X_USER_NAME            => or_masters_tbl.employee_num
                     ,X_OWNER                => gv_owner
                     ,X_UNENCRYPTED_PASSWORD => gv_password
                     ,X_START_DATE           => SYSDATE
                     ,X_LAST_LOGON_DATE      => SYSDATE
                     ,X_DESCRIPTION          => or_masters_tbl.user_name_alt
-- 2008/11/20 ADD START
-- ������
                     ,X_PASSWORD_LIFESPAN_DAYS => 180
-- 2008/11/20 ADD END
                     ,X_EMPLOYEE_ID          => ln_person_id
                    );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_PKG.CREATEUSERID';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.fusr_flg   := 1;
    or_masters_tbl.user_id   := ln_user_id;
    or_masters_tbl.person_id := ln_person_id;
    or_masters_tbl.object_version_number     := ln_per_object_version_number;
    or_masters_tbl.ass_object_version_number := ln_asg_object_version_number;
--
    ld_start_date := FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD');
--
    -- ���[�U�E�Ӄ}�X�^(API)
    -- �S���E�ӂP
    IF (or_masters_tbl.resp1 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp1,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- �S���E�ӂQ
    IF (or_masters_tbl.resp2 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp2,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- �S���E�ӂR
    IF (or_masters_tbl.resp3 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp3,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- �S���E�ӂS
    IF (or_masters_tbl.resp4 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp4,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- �S���E�ӂT
    IF (or_masters_tbl.resp5 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp5,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- �S���E�ӂU
    IF (or_masters_tbl.resp6 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp6,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- �S���E�ӂV
    IF (or_masters_tbl.resp7 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp7,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- �S���E�ӂW
    IF (or_masters_tbl.resp8 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp8,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- �S���E�ӂX
    IF (or_masters_tbl.resp9 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp9,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- �S���E�ӂP�O
    IF (or_masters_tbl.resp10 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp10,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- �w���S���}�X�^(API)
    IF (or_masters_tbl.po_flag = gv_flg_on) THEN
--
      -- �o�^
      po_agents_proc(gn_proc_insert,
                     or_masters_tbl, 
                     lv_errbuf, 
                     lv_retcode, 
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.pagn_flg := 1;
    END IF;
--
    -- �o�׃��[���}�X�^(����)
    IF (or_masters_tbl.wsh_flag = gv_flg_on) THEN
      -- �o�^
      wsh_grants_proc(gn_proc_insert,
                      or_masters_tbl,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.wshg_flg := 1;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END insert_proc;
--
  /***********************************************************************************
   * Procedure Name   : update_proc
   * Description      : ���[�U�[�X�V���i�[�������s���܂��B(C-10)
   ***********************************************************************************/
  PROCEDURE update_proc(
    ot_report_tbl  IN OUT NOCOPY report_rec,
    or_masters_tbl IN OUT NOCOPY masters_rec,
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- HR_PERSON_API.UPDATE_PERSON
    l_effective_start_date        DATE;
    l_effective_end_date          DATE;
    l_full_name                   per_all_people_f.full_name%TYPE;
    l_comment_id                  NUMBER;
    l_name_combination_warning    BOOLEAN;
    l_assign_payroll_warning      BOOLEAN;
    l_orig_hire_warning           BOOLEAN;
    ln_asg_object_version_number  NUMBER;
--
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_assignment_id              NUMBER;
    ln_object_version_number      NUMBER;
    ln_special_ceiling_step_id    NUMBER;
    ln_people_group_id            NUMBER;
    lv_group_name                 VARCHAR2(200);
    ld_effective_start_date       DATE;
    ld_effective_end_date         DATE;
    lb_org_now_no_manager_warning BOOLEAN;
    lb_other_manager_warning      BOOLEAN;
    lb_spp_delete_warning         BOOLEAN;
    lv_entries_changes_warn       VARCHAR2(200);
    lb_tax_district_changed_warn  BOOLEAN;
--
    lv_api_name                   VARCHAR2(200);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �]�ƈ��}�X�^�̌���
    get_per_all_people_f(or_masters_tbl,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    -- �]�ƈ��擾�G���[
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���[�U���݃`�F�b�N
    get_fnd_user(or_masters_tbl,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
    -- ���[�U�擾�G���[
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �]�ƈ��}�X�^(API)
    BEGIN
      HR_PERSON_API.UPDATE_PERSON(
        P_VALIDATE                     => FALSE
       ,P_EFFECTIVE_DATE               => SYSDATE
       ,P_DATETRACK_UPDATE_MODE        => gv_upd_mode
       ,P_PERSON_ID                    => or_masters_tbl.person_id     -- �]�ƈ�ID
       ,P_OBJECT_VERSION_NUMBER        => or_masters_tbl.object_version_number
       ,P_PERSON_TYPE_ID               => gv_person_type
       ,P_EMPLOYEE_NUMBER              => or_masters_tbl.employee_num
       ,P_ATTRIBUTE1                   => or_masters_tbl.qualification_id
       ,P_ATTRIBUTE2                   => or_masters_tbl.position_id
       ,P_LAST_NAME                    => or_masters_tbl.user_name_alt
       ,P_PER_INFORMATION_CATEGORY     => gv_info_category
       ,P_PER_INFORMATION18            => or_masters_tbl.user_name
       ,P_EFFECTIVE_START_DATE         => l_effective_start_date       -- OUT
       ,P_EFFECTIVE_END_DATE           => l_effective_end_date         -- OUT
       ,P_FULL_NAME                    => l_full_name                  -- OUT
       ,P_COMMENT_ID                   => l_comment_id                 -- OUT
       ,P_NAME_COMBINATION_WARNING     => l_name_combination_warning   -- OUT
       ,P_ASSIGN_PAYROLL_WARNING       => l_assign_payroll_warning     -- OUT
       ,P_ORIG_HIRE_WARNING            => l_orig_hire_warning          -- OUT
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_PERSON_API.UPDATE_PERSON';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.papf_flg := 1;
--
    ln_assignment_id := or_masters_tbl.assignment_id;
    ln_object_version_number := or_masters_tbl.ass_object_version_number;
--
    -- �]�ƈ������}�X�^(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
          P_VALIDATE                      => FALSE
         ,P_EFFECTIVE_DATE                => SYSDATE
         ,P_DATETRACK_UPDATE_MODE         => gv_upd_mode
         ,P_ASSIGNMENT_ID                 => ln_assignment_id               -- �]�ƈ�����ID
         ,P_LOCATION_ID                   => or_masters_tbl.location_id     -- �S�����_�R�[�h
         ,P_OBJECT_VERSION_NUMBER         => ln_object_version_number       -- IN/OUT
         ,P_SPECIAL_CEILING_STEP_ID       => ln_special_ceiling_step_id     -- OUT
         ,P_PEOPLE_GROUP_ID               => ln_people_group_id             -- OUT
         ,P_GROUP_NAME                    => lv_group_name                  -- OUT
         ,P_EFFECTIVE_START_DATE          => l_effective_start_date         -- OUT
         ,P_EFFECTIVE_END_DATE            => l_effective_end_date           -- OUT
         ,P_ORG_NOW_NO_MANAGER_WARNING    => lb_org_now_no_manager_warning  -- OUT
         ,P_OTHER_MANAGER_WARNING         => lb_other_manager_warning       -- OUT
         ,P_SPP_DELETE_WARNING            => lb_spp_delete_warning          -- OUT
         ,P_ENTRIES_CHANGED_WARNING       => lv_entries_changes_warn        -- OUT
         ,P_TAX_DISTRICT_CHANGED_WARNING  => lb_tax_district_changed_warn   -- OUT
        );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.paaf_flg := 1;
--
    -- ���[�U�}�X�^(API)
    BEGIN
      FND_USER_PKG.UPDATEUSER(
         X_USER_NAME          => or_masters_tbl.employee_num
        ,X_OWNER              => gv_owner
        ,X_DESCRIPTION        => or_masters_tbl.user_name_alt
        ,X_EMPLOYEE_ID        => or_masters_tbl.person_id
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_PKG.UPDATEUSER';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.fusr_flg := 1;
--
    -- �E�Ӑݒ肠��
    IF ((or_masters_tbl.resp1 IS NOT NULL) OR (or_masters_tbl.resp2 IS NOT NULL)
     OR (or_masters_tbl.resp3 IS NOT NULL) OR (or_masters_tbl.resp4 IS NOT NULL)
     OR (or_masters_tbl.resp5 IS NOT NULL) OR (or_masters_tbl.resp6 IS NOT NULL)
     OR (or_masters_tbl.resp7 IS NOT NULL) OR (or_masters_tbl.resp8 IS NOT NULL)
     OR (or_masters_tbl.resp9 IS NOT NULL) OR (or_masters_tbl.resp10 IS NOT NULL)) THEN
      --���[�U�E�Ӄ}�X�^�̖�����
      delete_group_all(or_masters_tbl, lv_errbuf, lv_retcode, lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ���[�U�E�Ӄ}�X�^�X�V
    IF (or_masters_tbl.resp1 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp1,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ���[�U�E�Ӄ}�X�^�X�V
    IF (or_masters_tbl.resp2 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp2,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ���[�U�E�Ӄ}�X�^�X�V
    IF (or_masters_tbl.resp3 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp3,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ���[�U�E�Ӄ}�X�^�X�V
    IF (or_masters_tbl.resp4 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp4,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ���[�U�E�Ӄ}�X�^�X�V
    IF (or_masters_tbl.resp5 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp5,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ���[�U�E�Ӄ}�X�^�X�V
    IF (or_masters_tbl.resp6 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp6,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ���[�U�E�Ӄ}�X�^�X�V
    IF (or_masters_tbl.resp7 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp7,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ���[�U�E�Ӄ}�X�^�X�V
    IF (or_masters_tbl.resp8 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp8,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ���[�U�E�Ӄ}�X�^�X�V
    IF (or_masters_tbl.resp9 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp9,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ���[�U�E�Ӄ}�X�^�X�V
    IF (or_masters_tbl.resp10 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp10,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- �w���S���}�X�^(����)
-- 2009/03/25 v1.6 DELETE START
--    IF (or_masters_tbl.po_flag = gv_flg_on) THEN
-- 2009/03/25 v1.6 DELETE END
      -- �폜
      po_agents_proc(gn_proc_delete,
                     or_masters_tbl, 
                     lv_errbuf, 
                     lv_retcode, 
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
-- 2009/03/25 v1.6 ADD START
    IF (or_masters_tbl.po_flag = gv_flg_on) THEN
-- 2009/03/25 v1.6 ADD END
      -- �o�^
      po_agents_proc(gn_proc_insert,
                     or_masters_tbl, 
                     lv_errbuf, 
                     lv_retcode, 
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.pagn_flg := 1;
    END IF;
--
    -- �o�׃��[���}�X�^(����)
-- 2009/03/25 v1.6 DELETE START
--    IF (or_masters_tbl.wsh_flag = gv_flg_on) THEN
-- 2009/03/25 v1.6 DELETE END
      -- �폜
      wsh_grants_proc(gn_proc_delete, 
                      or_masters_tbl, 
                      lv_errbuf, 
                      lv_retcode, 
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
-- 2009/03/25 v1.6 ADD START
    IF (or_masters_tbl.wsh_flag = gv_flg_on) THEN
-- 2009/03/25 v1.6 ADD END
      -- �o�^
      wsh_grants_proc(gn_proc_insert, 
                      or_masters_tbl, 
                      lv_errbuf, 
                      lv_retcode, 
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.wshg_flg := 1;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END update_proc;
--
  /***********************************************************************************
   * Procedure Name   : delete_proc
   * Description      : ���[�U�[�폜���i�[�������s���܂��B(C-10)
   ***********************************************************************************/
  PROCEDURE delete_proc(
    ot_report_tbl  IN OUT NOCOPY report_rec,
    or_masters_tbl IN OUT NOCOPY masters_rec,
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    -- HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP
    ln_period_of_service_id    NUMBER;
    ln_object_version_num      NUMBER;
    ld_last_std_process_date   DATE;
    lb_supervisor_warn         BOOLEAN;
    lb_event_warn              BOOLEAN;
    lb_interview_warn          BOOLEAN;
    lb_review_warn             BOOLEAN;
    lb_recruiter_warn          BOOLEAN;
    lb_asg_future_changes_warn BOOLEAN;
    lv_entries_changed_warn    VARCHAR2(200);
    lb_pay_proposal_warn       BOOLEAN;
    lb_dod_warn                BOOLEAN;
--
    lv_api_name                VARCHAR2(200);
    lb_retcd                   BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �]�ƈ��}�X�^�̌���
    get_per_all_people_f(or_masters_tbl,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    -- �]�ƈ��擾�G���[
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���[�U���݃`�F�b�N
    get_fnd_user(or_masters_tbl,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
    -- ���[�U�擾�G���[
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �T�[�r�X����ID�擾
    get_service_id(or_masters_tbl,
                   ln_period_of_service_id,
                   ln_object_version_num,
                   lb_retcd,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
    -- ���[�U�擾�G���[
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    BEGIN
      -- �]�ƈ��}�X�^(API)
      HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP(
        P_VALIDATE                   => FALSE
       ,P_EFFECTIVE_DATE             => SYSDATE-1
       ,P_PERIOD_OF_SERVICE_ID       => ln_period_of_service_id
       ,P_OBJECT_VERSION_NUMBER      => ln_object_version_num
       ,P_ACTUAL_TERMINATION_DATE    => SYSDATE                     -- �ސE��
       ,P_LAST_STANDARD_PROCESS_DATE => SYSDATE                     -- �ŏI���^������
       ,P_LAST_STD_PROCESS_DATE_OUT  => ld_last_std_process_date    -- OUT
       ,P_SUPERVISOR_WARNING         => lb_supervisor_warn          -- OUT
       ,P_EVENT_WARNING              => lb_event_warn               -- OUT
       ,P_INTERVIEW_WARNING          => lb_interview_warn           -- OUT
       ,P_REVIEW_WARNING             => lb_review_warn              -- OUT
       ,P_RECRUITER_WARNING          => lb_recruiter_warn           -- OUT
       ,P_ASG_FUTURE_CHANGES_WARNING => lb_asg_future_changes_warn  -- OUT
       ,P_ENTRIES_CHANGED_WARNING    => lv_entries_changed_warn     -- OUT
       ,P_PAY_PROPOSAL_WARNING       => lb_pay_proposal_warn        -- OUT
       ,P_DOD_WARNING                => lb_dod_warn                 -- OUT
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.papf_flg := 1;
--
    BEGIN
      HR_EX_EMPLOYEE_API.UPDATE_TERM_DETAILS_EMP(
        P_VALIDATE                   => FALSE
       ,P_EFFECTIVE_DATE             => SYSDATE-1
       ,P_PERIOD_OF_SERVICE_ID       => ln_period_of_service_id
       ,P_OBJECT_VERSION_NUMBER      => ln_object_version_num
       ,P_ACCEPTED_TERMINATION_DATE  => SYSDATE                    --- �ސE���F��
       ,P_NOTIFIED_TERMINATION_DATE  => SYSDATE                    --- �ސE�͒�o��
       ,P_PROJECTED_TERMINATION_DATE => SYSDATE                    --- �ސE�\���
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EX_EMPLOYEE_API.UPDATE_TERM_DETAILS_EMP';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.paaf_flg := 1;
--
    -- ���[�U�}�X�^(API)
    BEGIN
      FND_USER_PKG.UPDATEUSER(
         X_USER_NAME            => or_masters_tbl.employee_num
        ,X_OWNER                => gv_owner
        ,X_END_DATE             => SYSDATE-1
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_PKG.UPDATEUSER';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.fusr_flg := 1;
--
    -- ���[�U�E�Ӄ}�X�^(API)
    delete_group_all(or_masters_tbl, 
                     lv_errbuf, 
                     lv_retcode, 
                     lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    ot_report_tbl.furg_flg := 1;
--
    -- �w���S���}�X�^(����)
    IF (or_masters_tbl.po_flag = gv_flg_on) THEN
      -- �폜
      po_agents_proc(gn_proc_delete,
                     or_masters_tbl, 
                     lv_errbuf, 
                     lv_retcode, 
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.pagn_flg := 1;
    END IF;
--
    -- �o�׃��[���}�X�^(����)
    IF (or_masters_tbl.wsh_flag = gv_flg_on) THEN
      -- �폜
      wsh_grants_proc(gn_proc_delete, 
                      or_masters_tbl, 
                      lv_errbuf, 
                      lv_retcode, 
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.wshg_flg := 1;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END delete_proc;
--
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �����������s���܂��B(C-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ir_status_rec IN OUT NOCOPY status_rec,  -- ������
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    -- �v���t�@�C���擾
    -- ===============================
    get_profile(lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �p�[�\���^�C�v�̎擾
    -- ===============================
    get_per_person_types(lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
                         lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
                         lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �Ј��C���^�t�F�[�X���b�N����
    -- ===============================
    set_if_lock(lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �t�@�C�����x���̃X�e�[�^�X��������
    init_status(ir_status_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- WHO�J�����̎擾
    gn_created_by             := FND_GLOBAL.USER_ID;           -- �쐬��
    gd_creation_date          := SYSDATE;                      -- �쐬��
    gn_last_update_by         := FND_GLOBAL.USER_ID;           -- �ŏI�X�V��
    gd_last_update_date       := SYSDATE;                      -- �ŏI�X�V��
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID;          -- �ŏI�X�V���O�C��
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID;   -- �v��ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID;      -- �v���O�����A�v���P�[�V����ID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID;   -- �v���O����ID
    gd_program_update_date    := SYSDATE;                      -- �v���O�����X�V��
--
  EXCEPTION
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END init_proc;
--
  /***********************************************************************************
   * Procedure Name   : submain
   * Description      : �Ј��C���^�t�F�[�X�̃f�[�^���e�}�X�^�֔��f����v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
--
--#####################################  �Œ蕔 END   #############################################
--
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_masters_rec masters_rec; -- �����Ώۃf�[�^�i�[���R�[�h
    lr_status_rec  status_rec;  -- �����󋵊i�[���R�[�h
--
    lt_report_tbl report_tbl;   -- ���|�[�g�o�͌����z��
--
    lt_insert_masters masters_tbl; -- �e�}�X�^�֓o�^����f�[�^
    lt_update_masters masters_tbl; -- �e�}�X�^�֍X�V����f�[�^
    lt_delete_masters masters_tbl; -- �e�}�X�^�֍폜����f�[�^
--
    ln_insert_cnt NUMBER;          -- �o�^����
    ln_update_cnt NUMBER;          -- �X�V����
    ln_delete_cnt NUMBER;          -- �폜����
    ln_exec_cnt   NUMBER;
    ln_log_cnt    NUMBER;
    lb_retcd      BOOLEAN;         -- ��������
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR emp_if_cur
    IS
      SELECT xei.seq_num,
             xei.proc_code,
             xei.employee_num,
             xei.base_code,
             xei.user_name,
             xei.user_name_alt,
             xei.position_id,
             xei.qualification_id,
             xei.spare
      FROM   xxcmn_emp_if xei
      ORDER BY xei.seq_num;
--
    lr_emp_if_rec emp_if_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_report_cnt := 0;
    ln_insert_cnt := 0;
    ln_update_cnt := 0;
    ln_delete_cnt := 0;
--
    -- ===============================
    -- ��������(C-1)
    -- ===============================
    init_proc(lr_status_rec,
              lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �s�P�ʂ̃��b�N���s
    set_line_lock(lr_masters_rec,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- �Ј��C���^�t�F�[�X�捞����(C-2)
    -- ===============================
    OPEN emp_if_cur;
--
    <<emp_if_loop>>
    LOOP
      FETCH emp_if_cur INTO lr_emp_if_rec;
      EXIT WHEN emp_if_cur%NOTFOUND;
      gn_target_cnt := gn_target_cnt + 1; -- ���������J�E���g�A�b�v
--
      -- �s���x���̃X�e�[�^�X��������
      init_row_status(lr_status_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      -- �擾�����l�����R�[�h�ɃR�s�[
      -- �J�[�\�����O���[�o���ɂ��Ȃ����߂Ɋ֐����͂��Ȃ��B
      lr_masters_rec.seq_num          := lr_emp_if_rec.seq_num;
      lr_masters_rec.proc_code        := lr_emp_if_rec.proc_code;
      lr_masters_rec.employee_num     := lr_emp_if_rec.employee_num;
      lr_masters_rec.base_code        := lr_emp_if_rec.base_code;
      lr_masters_rec.user_name        := lr_emp_if_rec.user_name;
      lr_masters_rec.user_name_alt    := lr_emp_if_rec.user_name_alt;
      lr_masters_rec.position_id      := lr_emp_if_rec.position_id;
      lr_masters_rec.qualification_id := lr_emp_if_rec.qualification_id;
      lr_masters_rec.spare            := lr_emp_if_rec.spare;
--
      -- �����̏�����
      lr_masters_rec.row_ins_cnt := 0;
      lr_masters_rec.row_upd_cnt := 0;
      lr_masters_rec.row_del_cnt := 0;
--
      -- �X�V�敪�`�F�b�N
      check_proc_code(lr_status_rec,
                      lr_masters_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      IF (is_row_status_nomal(lr_status_rec)) THEN
        -- �ȑO�̃f�[�^��Ԃ̎擾
        get_xxcmn_emp_if(lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (is_row_status_nomal(lr_status_rec)) THEN
        -- �V�K�o�^��
        IF ((lr_masters_rec.proc_code = gn_proc_insert) 
        -- �X�V�ňȑO�ɐV�K�o�^����
        OR ((lr_masters_rec.proc_code = gn_proc_update) 
        AND (lr_masters_rec.row_ins_cnt <> 0))
        -- �폜�ňȑO�ɐV�K�o�^����
        OR ((lr_masters_rec.proc_code = gn_proc_delete)
        AND (lr_masters_rec.row_ins_cnt <> 0))) THEN
          -- �V�K�o�^���̒S�����_�̎擾(C-3)
          get_location_new(lr_status_rec,
                           lr_masters_rec,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
        ELSE
          -- �X�V�E�폜���̒S�����_�̎擾(C-3)
          get_location_mod(lr_status_rec,
                           lr_masters_rec,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
        END IF;
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      -- �o�^�A�X�V�A�폜�̊e�`�F�b�N�����֐U�蕪��
      -- �G���[�f�[�^�̓`�F�b�N���s��Ȃ��B
      IF (is_row_status_nomal(lr_status_rec)) THEN
--
        -- �o�^
        IF (lr_masters_rec.proc_code = gn_proc_insert) THEN
--
          -- �d���f�[�^�Ȃ�
          IF ((lr_masters_rec.row_ins_cnt = 0)
            AND (lr_masters_rec.row_upd_cnt = 0)
            AND (lr_masters_rec.row_del_cnt = 0)) THEN
--
            -- �o�^�p�`�F�b�N����(C-4)
            check_insert(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              -- �G���[���b�Z�[�W�̓`�F�b�N�������Őݒ�ς�
              RAISE check_sub_main_expt;
            END IF;
--
            IF is_row_status_nomal(lr_status_rec) THEN
              -- �o�^�f�[�^�i�[(C-7)
              lt_insert_masters(ln_insert_cnt) := lr_masters_rec;
              ln_insert_cnt := ln_insert_cnt + 1;
            END IF;
--
          -- �d���f�[�^�����݂���ꍇ�̓G���[
          ELSE
            set_error_status(lr_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                                      gv_tkn_ng_user, lr_masters_rec.employee_num,
                                                      gv_tkn_table,   gv_xxcmn_emp_if_name),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
          END IF;
--
        -- �X�V
        ELSIF (lr_masters_rec.proc_code = gn_proc_update) THEN
--
          -- �ȑO�ɍ폜�f�[�^�Ȃ�
          IF (lr_masters_rec.row_del_cnt = 0) THEN
            -- �X�V�p�`�F�b�N����(C-5)
            check_update(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              -- �G���[���b�Z�[�W�̓`�F�b�N�������Őݒ�ς�
              RAISE check_sub_main_expt;
            END IF;
--
            IF (is_row_status_nomal(lr_status_rec)) THEN
              -- �X�V�f�[�^�i�[(C-8)
              lt_update_masters(ln_update_cnt) := lr_masters_rec;
              ln_update_cnt := ln_update_cnt + 1;
            END IF;
--
          -- �ȑO�ɍ폜�f�[�^�����݂���ꍇ�͌x��
          ELSE
            -- �x����ݒ�
            set_error_status(lr_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                      gv_tkn_ng_user, lr_masters_rec.employee_num,
                                                      gv_tkn_table,   gv_xxcmn_emp_if_name),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
          END IF;
--
        -- �폜
        ELSIF (lr_masters_rec.proc_code = gn_proc_delete) THEN
--
          -- �ȑO�ɍ폜�f�[�^�Ȃ�
          IF (lr_masters_rec.row_del_cnt = 0) THEN
            -- �폜�p�`�F�b�N����(C-6)
            check_delete(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              -- �G���[���b�Z�[�W�̓`�F�b�N�������Őݒ�ς�
              RAISE check_sub_main_expt;
            END IF;
--
            IF (is_row_status_nomal(lr_status_rec)) THEN
              -- �폜�f�[�^�i�[(C-9)
              lt_delete_masters(ln_delete_cnt) := lr_masters_rec;
              ln_delete_cnt := ln_delete_cnt + 1;
            END IF;
--
          -- �ȑO�ɍ폜�f�[�^�����݂���ꍇ�͌x��
          ELSE
            -- �x����ݒ�
            set_warn_status(lr_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                     gv_tkn_ng_user, lr_masters_rec.employee_num,
                                                     gv_tkn_table,   gv_xxcmn_emp_if_name),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
          END IF;
        END IF;
      END IF;
--
      -- ���팏�����J�E���g�A�b�v
      IF (is_row_status_nomal(lr_status_rec)) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
--
      ELSE
        -- �x���������J�E���g�A�b�v
        IF (is_row_status_warn(lr_status_rec)) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
--
        -- �ُ팏�����J�E���g�A�b�v
        ELSE
          gn_error_cnt := gn_error_cnt +1;
        END IF;
      END IF;
--
      -- ���O�o�͗p�f�[�^�̊i�[
      add_report(lr_status_rec, lr_masters_rec, lt_report_tbl,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END LOOP emp_if_loop;
    CLOSE emp_if_cur;
--
    -- �f�[�^�̔��f(�G���[�Ȃ�)
    IF (is_file_status_nomal(lr_status_rec)) THEN
--
      -- �o�^����
      -- �o�^�f�[�^�̔��f(C-10)
      <<insert_proc_loop>>
      FOR ln_exec_cnt IN 0..ln_insert_cnt-1 LOOP
        <<insert_log_loop>>
        FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
          -- �o�^
          IF (lt_report_tbl(ln_log_cnt).proc_code = gn_proc_insert) THEN
            -- SEQ�ԍ�
            IF (lt_report_tbl(ln_log_cnt).seq_num =
                lt_insert_masters(ln_exec_cnt).seq_num) THEN
--
              -- �o�^����
              insert_proc(lt_report_tbl(ln_log_cnt),
                          lt_insert_masters(ln_exec_cnt),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE check_sub_main_expt;
              END IF;
            END IF;
          END IF;
        END LOOP insert_log_loop;
      END LOOP insert_proc_loop;
--
      -- �X�V����
      -- �X�V�f�[�^�̔��f(C-10)
      <<update_proc_loop>>
      FOR ln_exec_cnt IN 0..ln_update_cnt-1 LOOP
        <<update_log_loop>>
        FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
          -- �X�V
          IF (lt_report_tbl(ln_log_cnt).proc_code = gn_proc_update) THEN
            -- SEQ�ԍ�
            IF (lt_report_tbl(ln_log_cnt).seq_num =
                lt_update_masters(ln_exec_cnt).seq_num) THEN
--
              -- �X�V����
              update_proc(lt_report_tbl(ln_log_cnt),
                          lt_update_masters(ln_exec_cnt),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE check_sub_main_expt;
              END IF;
            END IF;
          END IF;
        END LOOP update_log_loop;
      END LOOP update_proc_loop;
--
      -- �폜����
      -- �폜�f�[�^�̔��f(C-10)
      <<delete_proc_loop>>
      FOR ln_exec_cnt IN 0..ln_delete_cnt-1 LOOP
        <<delete_log_loop>>
        FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
          -- �폜
          IF (lt_report_tbl(ln_log_cnt).proc_code = gn_proc_delete) THEN
            -- SEQ�ԍ�
            IF (lt_report_tbl(ln_log_cnt).seq_num =
                lt_delete_masters(ln_exec_cnt).seq_num) THEN
--
              -- �폜����
              delete_proc(lt_report_tbl(ln_log_cnt),
                          lt_delete_masters(ln_exec_cnt),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE check_sub_main_expt;
              END IF;
            END IF;
          END IF;
        END LOOP delete_log_loop;
      END LOOP delete_proc_loop;
    END IF;
--
    IF (gn_normal_cnt > 0) THEN
      -- ���O�o�͏���(����:0)(C-11)
      disp_report(lt_report_tbl, gn_data_status_nomal,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_error_cnt > 0) THEN
      -- ���O�o�͏���(���s:1)(C-11)
      disp_report(lt_report_tbl, gn_data_status_error,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_warn_cnt > 0) THEN
      -- ���O�o�͏���(�x��:2)(C-11)
      disp_report(lt_report_tbl, gn_data_status_warn,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gc_ppf_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_ppf_cur;
    END IF;
    IF (gc_paf_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_paf_cur;
    END IF;
    IF (gc_fu_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_fu_cur;
    END IF;
    IF (gc_fug_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_fug_cur;
    END IF;
    IF (gc_poa_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_poa_cur;
    END IF;
    IF (gc_wgs_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_wgs_cur;
    END IF;
--
    -- ===============================
    -- �Ј��C���^�t�F�[�X�폜����(C-11)
    -- ����I���ُ�I���ɂ�����炸�폜���s��
    -- ===============================
    delete_emp_if(lv_errbuf,lv_retcode,lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- 2008/07/07 Add ��
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_80c_023);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      gn_warn_cnt := gn_warn_cnt + 1;
      ov_retcode := gv_status_warn;
    END IF;
    -- 2008/07/07 Add ��
--
    -- �G���[�A���[�j���O�f�[�^�L��̏ꍇ�̓��[�j���O�I������B
    IF ((gn_error_cnt + gn_warn_cnt) > 0) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      -- �J�[�\�����J���Ă����
      IF (emp_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE emp_if_cur;
      END IF;
      IF (gc_ppf_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_ppf_cur;
      END IF;
      IF (gc_paf_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_paf_cur;
      END IF;
      IF (gc_fu_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_fu_cur;
      END IF;
      IF (gc_fug_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_fug_cur;
      END IF;
      IF (gc_poa_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_poa_cur;
      END IF;
      IF (gc_wgs_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_wgs_cur;
      END IF;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (emp_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE emp_if_cur;
      END IF;
      IF (gc_ppf_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_ppf_cur;
      END IF;
      IF (gc_paf_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_paf_cur;
      END IF;
      IF (gc_fu_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_fu_cur;
      END IF;
      IF (gc_fug_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_fug_cur;
      END IF;
      IF (gc_poa_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_poa_cur;
      END IF;
      IF (gc_wgs_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_wgs_cur;
      END IF;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (emp_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE emp_if_cur;
      END IF;
      IF (gc_ppf_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_ppf_cur;
      END IF;
      IF (gc_paf_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_paf_cur;
      END IF;
      IF (gc_fu_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_fu_cur;
      END IF;
      IF (gc_fug_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_fug_cur;
      END IF;
      IF (gc_poa_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_poa_cur;
      END IF;
      IF (gc_wgs_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_wgs_cur;
      END IF;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (emp_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE emp_if_cur;
      END IF;
      IF (gc_ppf_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_ppf_cur;
      END IF;
      IF (gc_paf_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_paf_cur;
      END IF;
      IF (gc_fu_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_fu_cur;
      END IF;
      IF (gc_fug_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_fug_cur;
      END IF;
      IF (gc_poa_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_poa_cur;
      END IF;
      IF (gc_wgs_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_wgs_cur;
      END IF;
--
--#####################################  �Œ蕔 END   #############################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf   OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode  OUT NOCOPY VARCHAR2)      --   ���^�[���E�R�[�h    --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_msgbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
--
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80c_001,
                                           gv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80c_002,
                                           gv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80c_022,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_003);
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================================
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--#####################################  �Œ蕔 START   ###########################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_021);
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
    END IF;
--
    --�G���[�ȊO�͏o��
    IF (lv_retcode != gv_status_error) THEN
      -- ==================================
      -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
      -- ==================================
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
      --���������o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_007,
                                             gv_tkn_cnt, TO_CHAR(gn_target_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
      --���������o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_008,
                                             gv_tkn_cnt, TO_CHAR(gn_normal_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --�G���[�����o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_009,
                                             gv_tkn_cnt, TO_CHAR(gn_error_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --�x�������o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_010,
                                             gv_tkn_cnt, TO_CHAR(gn_warn_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
    END IF;
--
    --�X�e�[�^�X�ϊ�
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal, gv_sts_cd_normal,
                                            gv_status_warn,   gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_80c_011, 
                                           gv_tkn_status, gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--#####################################  �Œ蕔 END   #############################################
--
END xxcmn800003c;
/
