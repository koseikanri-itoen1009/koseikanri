CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A06C(body)
 * Description      : �c�ƈ��Ǘ��t�@�C����HHT�ɑ��M���邽�߂� 
 *                    CSV�t�@�C�����쐬���܂��B
 * MD.050           : MD050_CSO_014_A06_HHT-EBS�C���^�[�t�F�[�X�F
 *                    (OUT)�c�ƈ��Ǘ��t�@�C��
 * Version          : 1.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_profile_info       �v���t�@�C���l�擾 (A-2)
 *  open_csv_file          CSV�t�@�C���I�[�v�� (A-3)
 *  get_sum_cnt_data       CSV�t�@�C���ɏo�͂���֘A���擾 (A-5)
 *  get_prsncd_data        �c�ƈ��Ǘ��f�[�^�𒊏o (A-6)
 *  create_csv_rec         CSV�t�@�C���o�� (A-7) 
 *  close_csv_file         CSV�t�@�C���N���[�Y (A-8) 
 *  get_sum_sls_tgt_data   ����ڕW�f�[�^��������(A-9)
 *  ins_work_results       ���уf�[�^���[�N�e�[�u���i�[(A-11)
 *  submain                ���C�������v���V�[�W��
 *                           ���\�[�X�f�[�^�擾 (A-4)
 *                           ����ڕW�f�[�^�擾�����i���т���j(A-10)
 *                           ����ڕW�f�[�^�擾�����i�ڕW�̂݁j(A-12)
 *                           �����\���p�ڕW�f�[�^�擾����(A-13)
 *                           ����ڕW�f�[�^CSV�o�͏���(A-14)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-15)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-28    1.0   Seirin.Kin        �V�K�쐬
 *  2009-02-19    1.1   K.Sai             ���r���[���ʔ��f
 *  2009-03-17    1.1   M.Maruyama        ���ѐU�ւ̏W�v�ǉ��ύX�ɂ��f�[�^�擾VIEW��
 *                                        ������уr���[����A�c�ƈ��p�������VIEW�֏C��
 *  2009-03-18    1.1   M.Maruyama        DEBUGLOG���b�Z�[�W�C��
 *  2009-05-01    1.2   Tomoko.Mori       T1_0897�Ή�
 *  2009-05-20    1.3   K.Satomura        T1_1082�Ή�
 *  2009-05-28    1.4   K.Satomura        T1_1236�Ή�
 *  2009-06-03    1.5   K.Satomura        T1_1304�Ή�
 *  2009-06-09    1.6   K.Satomura        T1_1304�Ή�(�ďC��)
 *  2009-10-19    1.7   K.Kubo            T4_00046�Ή�
 *  2009-11-23    1.8   T.Maruyama        E_�{��_00331�Ή��i����������т��c�Ɛ��ѕ\�Ɠ��l
 *                                        ���ьv��҃x�[�X�Ƃ���j
 *  2010-08-26    1.9   K.Kiriu           E_�{��_04153�Ή��iPT�Ή�)
 *  2013-05-13    1.10  K.Kiriu           E_�{��_10735�Ή�(�c�ƈ��ʌ��ʃm���}����)
 *  2013-06-18    1.11  T.Ishiwata        E_�{��_10837�Ή�(���[���z�M�@�\�Ή�)
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
  gn_target_cnt2   NUMBER;                    -- �Ώی���(����ڕW)
  gn_normal_cnt2   NUMBER;                    -- ���팏��(����ڕW)
  gn_warn_cnt2     NUMBER;                    -- �X�L�b�v����(����ڕW)
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
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
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A06C';   -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';          -- �A�v���P�[�V�����Z�k��
  cv_duty_cd             CONSTANT VARCHAR2(30)  := '010';            -- �E���R�[�h010(�Œ�)
  cv_duty_cd_vl          CONSTANT VARCHAR2(30)  := '���[�g�Z�[���X';   -- �E���R�[�h010(�Œ�)
  /* 2009.10.19 K.Kubo T4_00046�Ή� START */
  cv_duty_cd_050         CONSTANT VARCHAR2(30)  := '050';                -- �E���R�[�h050(�Œ�)
  cv_duty_cd_050_vl      CONSTANT VARCHAR2(30)  := '���X�A�S�ݓX�̔�'; -- �E���R�[�h050(�Œ�)
  /* 2009.10.19 K.Kubo T4_00046�Ή� END */
  cv_object_cd           CONSTANT VARCHAR2(30)  := 'PARTY';          -- �\�[�X�R�[�h(�Œ�)
  cv_delete_flag         CONSTANT VARCHAR2(1)   := 'N';              -- �^�X�N�폜�t���O
  cv_owner_type_code     CONSTANT VARCHAR2(30)  := 'RS_EMPLOYEE';    -- �^�X�N�I�[�i�[�^�C�v
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
  cv_yes                 CONSTANT VARCHAR2(1)   := 'Y';
  cv_no                  CONSTANT VARCHAR2(1)   := 'N';
  cv_app_name_cmm        CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_app_name_ccp        CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- �Q�ƃ^�C�v
  ct_item_group_summary  CONSTANT  fnd_lookup_values_vl.lookup_type%TYPE := 'XXCMM1_ITEM_GROUP_SUMMARY';  --���i�ʔ���W�v�}�X�^
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSV�t�@�C���I�[�v���G���[
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSV�t�@�C���N���[�Y�G���[
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSV�t�@�C���c���G���[
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00141';  -- �f�[�^���o�G���[
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00144';  -- CSV�t�@�C���o�̓G���[
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �C���^�t�@�[�X�t�@�C����
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSV�t�@�C���o��0���G���[
  /* 2009.05.28 K.Satomura T1_1236�Ή� START */
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00572';  -- ���\�[�X�O���[�v�L���G���[
  /* 2009.05.28 K.Satomura T1_1236�Ή� END */
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';  -- �e�[�u���폜�G���[
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00649';  -- �e�[�u���}���G���[
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00054';  -- �l�擾�G���[
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾
  cv_tkn_number_15    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00054';  -- �f�[�^�擾�G���[
--
  --���̈惁�b�Z�[�W
  cv_tkn_number_cmm_01  CONSTANT VARCHAR2(100) := 'APP-XXCMM1-00602';  -- �ڕW�Ǘ����ڃR�[�h
  cv_tkn_number_cmm_02  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10114';  -- ���p���l�`�F�b�N
--
  --�g�[�N���l
  cv_tkn_value_01     CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00650';  -- ����ڕW���[�N�e�[�u��
  cv_tkn_value_02     CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00651';  -- �ғ����J�����_
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--
  -- �g�[�N���R�[�h
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_prof_nm          CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_loc          CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_csv_fnm          CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_duty_cd          CONSTANT VARCHAR2(20) := 'DUTY_CODE';
  cv_tkn_loc_cd           CONSTANT VARCHAR2(20) := 'LOCATION_CODE';
  cv_tkn_sales_cd         CONSTANT VARCHAR2(20) := 'SALES_CODE';
  cv_tkn_sales_nm         CONSTANT VARCHAR2(20) := 'SALES_NAME';
  cv_tkn_ymd              CONSTANT VARCHAR2(20) := 'YEAR_MONTH_DAY';
  cv_tkn_tbl              CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_cnt              CONSTANT VARCHAR2(20) := 'COUNT';
  /* 2009.05.28 K.Satomura T1_1236�Ή� START */
  cv_tkn_emp_num          CONSTANT VARCHAR2(20) := 'EMPLOYEE_NUMBER';
  cv_tkn_emp_name         CONSTANT VARCHAR2(20) := 'EMPLOYEE__NAME';
  /* 2009.05.28 K.Satomura T1_1236�Ή� END */
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cb_false                CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�A�N���[�YID >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := '�t�@�C���o�͐� : ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '�t�@�C���� : ';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := '�N���[�YID : ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< �N�x�擾���� >>';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := '�t�@�C�����N���[�Y���܂���';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '���[���o�b�N�����܂���';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '�Ɩ��������t:';
  cv_debug_msg9           CONSTANT VARCHAR2(200) := '<<�t�@�C�����I�[�v�����܂����B>>';
  cv_debug_msg10          CONSTANT VARCHAR2(200) := '���R�[�h�����݂��Ȃ����ߔ̔����т�0���Z�b�g���܂����B';
  cv_debug_msg11          CONSTANT VARCHAR2(200) := '���R�[�h�����݂��Ȃ����ߖK����т�0���Z�b�g���܂����B'; 
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_sum        CONSTANT VARCHAR2(200) := '�̔����сF';
  cv_debug_msg_cnt        CONSTANT VARCHAR2(200) := '�K����сF';
  cv_debug_base_code      CONSTANT VARCHAR2(200) := '���_�R�[�h�F';
  cv_debug_em_num         CONSTANT VARCHAR2(200) := '�c�ƈ��R�[�h�F';
  cv_debug_sls_amt        CONSTANT VARCHAR2(200) := '�����c�ƈ��m���}���z�F';
  cv_debug_vis_amt        CONSTANT VARCHAR2(200) := '�����K��m���}�F';
  cv_debug_msg12          CONSTANT VARCHAR2(200) := '���R�[�h�����݂��Ȃ����ߓ����c�ƈ��m���}���z�ƖK��m���}��0���Z�b�g���܂����B';
  cv_debug_msg13          CONSTANT VARCHAR2(200) := '���R�[�h�����݂��Ȃ����ߗ����c�ƈ��m���}���z�ƖK��m���}��0���Z�b�g���܂����B';
  cv_debug_sls_amtnext    CONSTANT VARCHAR2(200) :=  '�����c�ƈ��m���}���z�F';
  cv_debug_vis_amtnext    CONSTANT VARCHAR2(200) := '�����K��m���}�F';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< ��O��������CSV�t�@�C�����N���[�Y���܂��� >>';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< �J�[�\�����I�[�v�����܂��� >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< �J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< ��O�������ŃJ�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others��O';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
  cv_debug_msg14          CONSTANT VARCHAR2(200) := '����ڕW�f�[�^�쐬�����J�n';
  cv_debug_msg15          CONSTANT VARCHAR2(200) := '����ڕW�f�[�^�쐬�����I��';
  cv_debug_msg16          CONSTANT VARCHAR2(200) := '���ю擾����';
  cv_debug_msg17          CONSTANT VARCHAR2(200) := '�ڕW�̂ݎ擾����';
  cv_debug_msg18          CONSTANT VARCHAR2(200) := '�����\���p�ڕW�̎擾����';
  cv_debug_msg19          CONSTANT VARCHAR2(200) := '�b�r�u�o�͏���';
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���E�n���h���̐錾
  gf_file_hand       UTL_FILE.FILE_TYPE;
--
  gv_closed_id           VARCHAR2(10);        -- �N���[�YID
  gd_process_date        DATE;                -- �Ɩ�������
  gd_process_date_next   DATE;                -- �Ɩ�����������
  /* 2009.10.19 K.Kubo T4_00046�Ή� START */
  gv_duty_cd             VARCHAR2(30);        -- �E���R�[�h
  gv_duty_cd_vl          VARCHAR2(30);        -- �E���R�[�h��
  /* 2009.10.19 K.Kubo T4_00046�Ή� END */
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
  gv_err_tkn_val_01      VARCHAR2(100);       -- ����ڕW���[�N�e�[�u��
  gv_keeping_month       VARCHAR2(6);         -- �c�Ɛ��ѕ\�̕ێ�����(YYYYMM�`��)
  gv_log_control_flag    VARCHAR2(1);         -- �I�����̃��O����p
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �擾���i�[���R�[�h�^��`
--
  -- �c�ƈ��Ǘ�(�t�@�C��)��񃏁[�N�e�[�u���f�[�^
  TYPE g_prsncd_data_rtype IS RECORD(
    base_code           xxcso_sls_prsn_mnthly_plns.base_code%TYPE,                 -- ���_�b�c
    employee_number     xxcso_sls_prsn_mnthly_plns.employee_number%TYPE,           -- �c�ƈ��b�c
    pure_amount_sum     xxcos_sales_exp_headers.pure_amount_sum%TYPE,              -- �̔����ы��z
    sls_amt             xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_total_amt%TYPE,  -- �����c�ƈ��m���}���z
    sls_next_amt        xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_total_amt%TYPE,  -- �����c�ƈ��m���}���z
    vis_amt             xxcso_sls_prsn_mnthly_plns.vis_prsn_total_amt%TYPE,        -- �����K��m���}
    vis_next_amt        xxcso_sls_prsn_mnthly_plns.vis_prsn_total_amt%TYPE,        -- �����K��m���}
    person_id           xxcso_resources_v.person_id%TYPE,                          -- �]�ƈ�ID
    resource_id         xxcso_resources_v.resource_id%TYPE,                        -- ���\�[�XID
    full_name           xxcso_resources_v.full_name%TYPE,                          -- �c�ƈ�����
    prsn_total_cnt      NUMBER(10)                                                 -- �����K�����
  );
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
  -- �c�ƈ�����ڕW�̓����f�[�^
  TYPE g_date_cnt_rtype IS RECORD(
    actual_day_cnt      NUMBER,                                                    -- ��������
    passed_day_cnt      NUMBER                                                     -- �o�ߓ���
  );
  -- ����ڕW���[�N�e�[�u��
  TYPE g_sales_target_rtype IS RECORD(
    base_code               xxcso_wk_sales_target.base_code%TYPE,                  --���_�R�[�h
    employee_code           xxcso_wk_sales_target.employee_code%TYPE,              --�c�ƈ��R�[�h
    sale_amount_month_sum   xxcso_wk_sales_target.sale_amount_month_sum%TYPE,      --���ы��z
    target_amount           xxcso_wk_sales_target.target_amount%TYPE,              --�ڕW���z
    target_management_code  xxcso_wk_sales_target.target_management_code%TYPE,     --�ڕW�Ǘ����ڃR�[�h
    target_month            xxcso_wk_sales_target.target_month%TYPE,               --�N��
    actual_day_cnt          xxcso_wk_sales_target.actual_day_cnt%TYPE,             --��������
    passed_day_cnt          xxcso_wk_sales_target.passed_day_cnt%TYPE              --�o�ߓ���
  );
--
  --�e�[�u���^��`
  TYPE g_date_cnt_ttype IS TABLE OF g_date_cnt_rtype INDEX BY VARCHAR2(6);
  g_date_cnt_tab        g_date_cnt_ttype;
  /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';              -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_appl_short_name      CONSTANT VARCHAR2(10)      := 'XXCCP';             -- �A�v���P�[�V�����Z�k��
    cv_tkn_number_17        CONSTANT VARCHAR2(100)     := 'APP-XXCCP1-90008';  -- �R���J�����g���̓e�[�^�Ȃ�
    -- *** ���[�J���ϐ� ***
    ld_process_date DATE;             -- �Ɩ��������t�i�[�p
    lv_noprm_msg    VARCHAR2(4000);   -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================================
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o�� 
    -- =======================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name --       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_17            -- ���b�Z�[�W�R�[�h
                      );
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => ''           || CHR(10) ||     -- ��s�̑}��
                lv_noprm_msg || CHR(10) ||
                 ''                            -- ��s�̑}��
    );
--
    -- ===========================
    -- �Ɩ��������t�擾���� 
    -- ===========================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
  -- *** DEBUG_LOG ***
    fnd_file.put_line(
      which  => FND_FILE.LOG,
      buff   => cv_prg_name || cv_msg_part ||
                cv_debug_msg8 || ld_process_date || CHR(10) ||
                ''
    );
--
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (ld_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_01         --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- �Ɩ��������t��ݒ�
    gd_process_date        := ld_process_date;
    -- �Ɩ�������������ݒ�
    gd_process_date_next   := gd_process_date+1;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l�擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_csv_dir        OUT NOCOPY VARCHAR2  -- CSV�t�@�C���o�͐�
   ,ov_csv_nm         OUT NOCOPY VARCHAR2  -- CSV�t�@�C����
   ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
   ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
   ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_profile_info';     -- �v���O������
  --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  -- ===============================
  -- ���[�U�[�錾��
  -- ===============================
  -- *** ���[�J���萔 ***
  -- �v���t�@�C����
    cv_csv_dir        CONSTANT VARCHAR2(30)   := 'XXCSO1_HHT_OUT_CSV_DIR';
  -- XXCSO:HHT�A�g�pCSV�t�@�C���o�͐�
    cv_csv_sls_mng    CONSTANT VARCHAR2(30)   := 'XXCSO1_HHT_OUT_CSV_SALES_MNG';
  -- XXCSO:HHT�A�g�pCSV�t�@�C����(�c�ƈ��Ǘ��t�@�C��)
    cv_closed_id      CONSTANT VARCHAR2(30)   := 'XXCSO1_TASK_STATUS_CLOSED_ID';
  -- XXCSO:�^�X�N�X�e�[�^�X(�N���[�Y)ID    
--
  -- *** ���[�J���ϐ� ***    
    lv_csv_dir        VARCHAR2(2000);   -- CSV�t�@�C���o�͐�
    lv_csv_nm         VARCHAR2(2000);   -- CSV�t�@�C����
    lv_closed_id      VARCHAR2(2000);   -- �N���[�Y�̃^�X�N�X�e�[�^�XID(�Œ�)
    lv_msg            VARCHAR2(4000);   -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_tkn_value      VARCHAR2(1000);   -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p  
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================
    -- �ϐ����������� 
    -- ====================
    lv_tkn_value := NULL;
--
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    FND_PROFILE.GET(
                    cv_csv_dir
                   ,lv_csv_dir
                   ); -- CSV�t�@�C���o�͐�
    FND_PROFILE.GET(
                    cv_csv_sls_mng
                   ,lv_csv_nm
                   ); -- CSV�t�@�C����
    FND_PROFILE.GET(
                    cv_closed_id
                   ,gv_closed_id
                    ); --�N���[�Y�̃^�X�N�X�e�[�^�XID(�Œ�)
--
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || lv_csv_dir || CHR(10) ||
                 cv_debug_msg3  || lv_csv_nm  || CHR(10) ||
                 cv_debug_msg4  || gv_closed_id || CHR(10) ||
                 ''
    );
--  
    -- �擾����CSV�t�@�C���������b�Z�[�W�o�͂���
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_08      --���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_csv_fnm        --�g�[�N���R�[�h1
                ,iv_token_value1 => lv_csv_nm             --�g�[�N���l1
              );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                   -- ��s�̑}��
    );
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- CSV�t�@�C���o�͐�擾���s��
    IF (lv_csv_dir IS NULL) THEN
      lv_tkn_value := cv_csv_dir;
    -- CSV�t�@�C�����擾���s��
    ELSIF (lv_csv_nm IS NULL) THEN
      lv_tkn_value := cv_csv_sls_mng;
    -- �N���[�Y�̃^�X�N�X�e�[�^�XID�擾���s��
    ELSIF (gv_closed_id IS NULL) THEN
      lv_tkn_value := cv_closed_id;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF lv_tkn_value IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02             -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm               -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                 -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;  
--
    -- �擾�����v���t�@�C���l��OUT�p�����[�^�ɐݒ�
    ov_csv_dir        :=  lv_csv_dir;          -- CSV�t�@�C���o�͐�
    ov_csv_nm         :=  lv_csv_nm;           -- CSV�t�@�C����
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : CSV�t�@�C���I�[�v�� (A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     iv_csv_dir        IN  VARCHAR2  -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2  -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_w            CONSTANT VARCHAR2(1) := 'w';
--
    -- *** ���[�J���ϐ� ***
    -- �t�@�C�����݃`�F�b�N�߂�l�p
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N 
    -- ========================
--
    -- CSV�t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(
       location    => iv_csv_dir              -- CSV�t�@�C���i�[��f�B���N�g
      ,filename    => iv_csv_nm               -- CSV�t�@�C����(�c�ƈ��Ǘ��t�@�C��)  
      ,fexists     => lb_retcd                -- �߂�l�F�uTRUE�vOR�uFALSE�v
      ,file_length => ln_file_size            -- �߂�l�F�t�@�C���T�C�Y
      ,block_size  => ln_block_size           -- �߂�l�F�t�@�C���̃u���b�N�T�C�Y
    );
--
    -- ���łɃt�@�C�������݂����ꍇ
    IF (lb_retcd = cb_true ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_05             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_csv_loc               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => iv_csv_dir                   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_csv_fnm               -- �g�[�N���R�[�h1
                     ,iv_token_value2 => iv_csv_nm                    -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_err_expt;
    END IF;
--
    -- ========================
    -- CSV�t�@�C���I�[�v�� 
    -- ========================
    BEGIN
      -- �t�@�C���I�[�v��
      gf_file_hand := UTL_FILE.FOPEN(
                         location   => iv_csv_dir     -- CSV�t�@�C���i�[��f�B���N�g
                        ,filename   => iv_csv_nm      -- CSV�t�@�C����(�c�ƈ��Ǘ��t�@�C��) 
                        ,open_mode  => cv_w           -- �I�[�v�����[�h�i�������݁j
                      );
      -- *** DEBUG_LOG ***
      -- �t�@�C���I�[�v���������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg9   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH         OR     -- �t�@�C���p�X�s���G���[
           UTL_FILE.INVALID_MODE         OR     -- open_mode�p�����[�^�s���G���[
           UTL_FILE.INVALID_OPERATION    OR     -- �I�[�v���s�\�G���[
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE�l�����G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_03     --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc       --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir           --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --�g�[�N���R�[�h1
                      ,iv_token_value2 => iv_csv_nm            --�g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err1 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err2 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : get_sum_cnt_data
   * Description      : CSV�t�@�C���ɏo�͂���֘A���擾 (A-5)
  ***********************************************************************************/
  PROCEDURE get_sum_cnt_data(
     io_prsncd_data_rec   IN OUT NOCOPY g_prsncd_data_rtype   -- �o�͂���֘A���i�[
    ,ov_errbuf               OUT NOCOPY VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode              OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg               OUT NOCOPY VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_sum_cnt_data';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    cv_table_name_xrcv     CONSTANT VARCHAR2(100) := '�c�ƈ��S���ڋq�r���[';     -- �c�ƈ��S���ڋq�r���[��
    cv_table_name_xseh     CONSTANT VARCHAR2(100) := '�̔����уw�b�_�e�[�u��';   -- �̔����уw�b�_�e�[�u����
    cv_table_name_jtb      CONSTANT VARCHAR2(100) := '�^�X�N�e�[�u��';           -- �^�X�N�e�[�u��
    /* 2009.11.23 T.Maruyama E_�{��_00331�Ή� START */
    ct_prof_electric_fee_item_cd
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
    /* 2009.11.23 T.Maruyama E_�{��_00331�Ή� END */    
    -- *** ���[�J���ϐ� ***
--
    lt_pure_amount_sum     xxcos_sales_exp_headers.pure_amount_sum%TYPE;     -- �̔����ы��z
    lt_resource_id         xxcso_resources_v.resource_id%TYPE;               -- ���\�[�XID
    lt_prsn_total_cnt      NUMBER(10);                                       -- �����K�����
    lt_process_back_date   DATE;                                             -- �Ɩ��������O��
    ld_process_date_next01 DATE;                                             -- �Ɩ������������N���̏���
    ln__closed_id          NUMBER;                                           -- �N���[�YID���^�ω�
--
    -- *** ���[�J���E���R�[�h ***
    l_prsncd_data_rec  g_prsncd_data_rtype; 
-- IN�p�����[�^.�o�͂���e�[�^�����[�N�e�[�u���f�[�^�i�[
    -- *** ���[�J���E��O ***
    error_expt      EXCEPTION;            -- �f�[�^���o�G���[��O
-- 
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- IN�p�����[�^�����R�[�h�ϐ��ɑ��
    l_prsncd_data_rec      := io_prsncd_data_rec;
    -- A-4�Œ��o�e�[�^�����[�N�e�[�u�����o�f�[�^�����[�J���ϐ��ɑ��
    lt_pure_amount_sum     := 0;                                -- �̔����ы��z 
    lt_prsn_total_cnt      := 0;                                -- �����K�����
    lt_resource_id         := io_prsncd_data_rec.resource_id;   -- ���\�[�XID
    /* 2009.11.23 T.Maruyama E_�{��_00331�Ή� START */    
--    lt_process_back_date   := gd_process_date - 1;              -- �Ɩ��������O��
--    ld_process_date_next01 := TO_DATE(TO_CHAR(gd_process_date_next, 'YYYYMM') || '01', 'YYYY/MM/DD'); 
    lt_process_back_date   := gd_process_date;                  -- �Ɩ��������i�������܂Łj
    ld_process_date_next01 := TO_DATE(TO_CHAR(gd_process_date_next, 'YYYYMM') || '01', 'YYYYMMDD'); 
    /* 2009.11.23 T.Maruyama E_�{��_00331�Ή� END */    
    ln__closed_id          := TO_NUMBER(gv_closed_id);
--
    -- �̔�����グ�r���[�A�ڋq�}�X�^�r���[����̔����ы��z�𒊏o����
    BEGIN
      /* 2009.11.23 T.Maruyama E_�{��_00331�Ή� START */
--      SELECT  ROUND(SUM(sfpv.pure_amount)/1000) pure_amount_sum  -- �̔����ы��z(��~�P�ʂɎ擾)
--        INTO  lt_pure_amount_sum                                 -- �̔����ы��z
--        FROM  xxcso_sales_for_sls_prsn_v sfpv                    -- �c�ƈ��p������уr���[
--             ,xxcso_resource_custs_v xrcv                        -- �c�ƈ��S���ڋq�r���[
--       WHERE  sfpv.account_number   = xrcv.account_number
--         AND  xrcv.employee_number  = l_prsncd_data_rec.employee_number
--         AND  gd_process_date_next BETWEEN TRUNC(xrcv.start_date_active) 
--                AND TRUNC(NVL(xrcv.end_date_active,gd_process_date_next))
--         AND  TRUNC(sfpv.delivery_date) BETWEEN ld_process_date_next01
--                AND lt_process_back_date;

        --�̔����уe�[�u���̐��ьv��҂����Y�c�ƈ��̃f�[�^�𒊏o����B
        SELECT ROUND(sum(sael.pure_amount) /1000) pure_amount_sum  -- �̔����ы��z(��~�P�ʂɎ擾)
        INTO   lt_pure_amount_sum
        FROM  xxcos_sales_exp_headers       saeh,
              xxcos_sales_exp_lines         sael
        WHERE sael.sales_exp_header_id      =       saeh.sales_exp_header_id
        AND   sael.item_code                <>      FND_PROFILE.VALUE( ct_prof_electric_fee_item_cd ) --����Ɋ܂܂Ȃ�
        AND   saeh.sales_base_code       = l_prsncd_data_rec.base_code       --���_CD
        AND   saeh.results_employee_code = l_prsncd_data_rec.employee_number --���ьv��ҁF�]�ƈ�CD
        AND   saeh.delivery_date BETWEEN ld_process_date_next01
                                     AND lt_process_back_date
        ;
      /* 2009.11.23 T.Maruyama E_�{��_00331�Ή� END */
--
      --IN���R�[�h�Ɋi�[
      IF (lt_pure_amount_sum IS NULL) THEN
        lt_pure_amount_sum := 0;
      END IF;
--
      io_prsncd_data_rec.pure_amount_sum := lt_pure_amount_sum;
--
      -- *** DEBUG_LOG ***
      -- �̔����т����O�ɏo��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_sum   || lt_pure_amount_sum || CHR(10) || ''
      );
--
    --���R�[�h���݃`�F�b�N
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_pure_amount_sum := 0;  -- ���R�[�h���Ȃ��ꍇ�O��������
        io_prsncd_data_rec.pure_amount_sum := lt_pure_amount_sum;
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_debug_msg10 || CHR(10) ||
                   ''
        );
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06                     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���l1
                       ,iv_token_value1 => cv_table_name_xseh || '�A' || cv_table_name_xrcv  -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                        --�g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
                       ,iv_token_name3  => cv_tkn_duty_cd                       -- �g�[�N���R�[�h3
                       /* 2009.10.19 K.Kubo T4_00046�Ή� START */
                       --,iv_token_value3 => cv_duty_cd                           -- �E���R�[�h
                       ,iv_token_value3 => gv_duty_cd                           -- �E���R�[�h
                       /* 2009.10.19 K.Kubo T4_00046�Ή� END */
                       ,iv_token_name4  => cv_tkn_ymd                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(gd_process_date,'YYYYMMDD')  -- �Ɩ�������
                       ,iv_token_name5  => cv_tkn_loc_cd                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_prsncd_data_rec.base_code         -- A-4�Œ��o�������_�R�[�h
                       ,iv_token_name6  => cv_tkn_sales_cd                      -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_prsncd_data_rec.employee_number   -- A-4�Œ��o�����c�ƈ��R�[�h
                       ,iv_token_name7  => cv_tkn_sales_nm                      -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_prsncd_data_rec.full_name         -- �c�ƈ�����
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE error_expt;
    END;
--
    -- �����K����уf�[�^���擾
    BEGIN
     SELECT  COUNT(*) prsn_total_cnt  -- �����K�����
       INTO  lt_prsn_total_cnt        -- �����K�����
       FROM  jtf_tasks_b jtb          -- �^�X�N�e�[�u��
      WHERE  jtb.source_object_type_code = cv_object_cd
        AND  jtb.task_status_id          = ln__closed_id
        AND  jtb.deleted_flag            = cv_delete_flag
        AND  TRUNC(jtb.actual_end_date) BETWEEN ld_process_date_next01
               AND lt_process_back_date
        AND  jtb.owner_type_code         = cv_owner_type_code
        AND  jtb.owner_id                = lt_resource_id;
--
      --�����K����уf�[�^����IN���R�[�h�Ɋi�[
      io_prsncd_data_rec.prsn_total_cnt  := lt_prsn_total_cnt;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_cnt   || lt_prsn_total_cnt || CHR(10) ||
                   ''
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06                     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���l1
                       ,iv_token_value1 => cv_table_name_jtb                    -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                        --�g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
                       ,iv_token_name3  => cv_tkn_duty_cd                       -- �g�[�N���R�[�h3
                       /* 2009.10.19 K.Kubo T4_00046�Ή� START */
                       --,iv_token_value3 => cv_duty_cd                           -- �E���R�[�h
                       ,iv_token_value3 => gv_duty_cd                           -- �E���R�[�h
                       /* 2009.10.19 K.Kubo T4_00046�Ή� END */
                       ,iv_token_name4  => cv_tkn_ymd                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(gd_process_date,'YYYYMMDD')  -- �Ɩ�������
                       ,iv_token_name5  => cv_tkn_loc_cd                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_prsncd_data_rec.base_code         -- A-4�Œ��o�������_�R�[�h
                       ,iv_token_name6  => cv_tkn_sales_cd                      -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_prsncd_data_rec.employee_number   -- A-4�Œ��o�����c�ƈ��R�[�h
                       ,iv_token_name7  => cv_tkn_sales_nm                      -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_prsncd_data_rec.full_name         -- �c�ƈ�����
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE error_expt;
    END;
    
--
  EXCEPTION
    -- *** �f�[�^���o���̗�O�n���h�� ***
    WHEN error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;  
--#####################################  �Œ蕔 START ##########################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sum_cnt_data;

 /**********************************************************************************
   * Procedure Name   : get_prsncd_data
   * Description      : �c�ƈ��Ǘ��f�[�^�𒊏o (A-6)
   ***********************************************************************************/
  PROCEDURE get_prsncd_data(
     io_prsncd_data_rec   IN OUT NOCOPY g_prsncd_data_rtype -- �o�͂���֘A���i�[
    ,ov_errbuf               OUT NOCOPY VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode              OUT NOCOPY VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg               OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_prsncd_data';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_table_name_xdmp   CONSTANT VARCHAR2(100) := '���_�ʌ��ʌv��e�[�u��';       -- ���_�ʌ��ʌv��e�[�u����
    cv_table_name_xspmp  CONSTANT VARCHAR2(100) := '�c�ƈ��ʌ��ʌv��e�[�u��';     -- �c�ƈ��ʌ��ʌv��e�[�u��
--  
    -- *** ���[�J���ϐ� ***
    lt_sls_amt             xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_total_amt%TYPE;   -- �����c�ƈ��m���}���z
    lt_sls_next_amt        xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_total_amt%TYPE;   -- �����c�ƈ��m���}���z
    lt_vis_amt             xxcso_sls_prsn_mnthly_plns.vis_prsn_total_amt%TYPE;         -- �����K��m���}
    lt_vis_next_amt        xxcso_sls_prsn_mnthly_plns.vis_prsn_total_amt%TYPE;         -- �����K��m���}
    lt_year                xxcso_dept_monthly_plans.fiscal_year%TYPE;                  -- �N�x�i�[
    lt_year_next           xxcso_dept_monthly_plans.fiscal_year%TYPE;                  -- �N�x�i�[
    lt_employee_number     xxcso_sls_prsn_mnthly_plns.employee_number%TYPE;            -- �c�ƈ��R�[�h
    lv_year_month          VARCHAR2(6);                                                -- �N��
    lv_year_month_next     VARCHAR2(6);                                                -- �N��
    lt_base_code           xxcso_sls_prsn_mnthly_plns.base_code%TYPE;                  -- ���_�R�[�h
--    
    -- *** ���[�J���E���R�[�h ***
    l_prsncd_data_rec  g_prsncd_data_rtype; 
-- IN�p�����[�^.�o�͂���e�[�^�����[�N�e�[�u���f�[�^�i�[
    -- *** ���[�J���E��O ***
    warning_expt      EXCEPTION;            -- NOFOUND�x����O
-- 
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- IN�p�����[�^�����R�[�h�ϐ��ɑ��
    l_prsncd_data_rec  := io_prsncd_data_rec;
    -- �Ɩ������������̔N�����Z�b�g
    lv_year_month      := TO_CHAR(gd_process_date_next,'YYYYMM');
    lv_year_month_next := TO_CHAR(ADD_MONTHS(gd_process_date_next,1),'YYYYMM');
    -- �Ɩ������������̔N�x�擾
    lt_year            := TO_CHAR(xxcso_util_common_pkg.get_business_year(lv_year_month));
    lt_year_next       := TO_CHAR(xxcso_util_common_pkg.get_business_year(lv_year_month_next));
--  
    -- �����c�ƈ��ʌ��ʌv��e�[�^�𒊏o����
    BEGIN
      SELECT xspmp.base_code base_code                               -- ���_�R�[�h
            ,xspmp.employee_number employee_number                   -- �c�ƈ��R�[�h
            ,DECODE(xdmp.sales_plan_rel_div
              ,'1', xspmp.tgt_sales_prsn_total_amt
              ,'2', xspmp.bsc_sls_prsn_total_amt) sls_prsn_total_amt -- �����c�ƈ��m���}���z
            ,xspmp.vis_prsn_total_amt vis_prsn_total_amt             -- �����K��m���}
      INTO   lt_base_code                                            -- ���_�R�[�h
            ,lt_employee_number                                      -- �c�ƈ��R�[�h
            ,lt_sls_amt                                              -- �����c�ƈ��m���}���z
            ,lt_vis_amt                                              -- �����K��m���}
      FROM   xxcso_dept_monthly_plans xdmp                           -- ���_�ʌ��ʌv��e�[�u��
            ,xxcso_sls_prsn_mnthly_plns xspmp                        -- �c�ƈ��ʌ��ʌv��e�[�u��
      WHERE  xdmp.base_code         = xspmp.base_code 
        AND  xdmp.year_month        = xspmp.year_month
        AND  xdmp.fiscal_year       = lt_year
        AND  xspmp.base_code        = io_prsncd_data_rec.base_code
        AND  xspmp.employee_number  = io_prsncd_data_rec.employee_number
        AND  xspmp.year_month       = lv_year_month;
--
      --OUT���R�[�h�Ɋi�[
      io_prsncd_data_rec.sls_amt   := lt_sls_amt;
      io_prsncd_data_rec.vis_amt   := lt_vis_amt;
      -- *** DEBUG_LOG ***
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name || CHR(10) ||
                   cv_debug_base_code || lt_base_code ||
                   cv_debug_em_num    || lt_employee_number ||
                   cv_debug_sls_amt   || lt_sls_amt ||
                   cv_debug_vis_amt   || lt_vis_amt || CHR(10) ||
                   ''
      );
--    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- ���R�[�h���Ȃ��ꍇ�O��������
        io_prsncd_data_rec.sls_amt := 0;
        io_prsncd_data_rec.vis_amt := 0;
--
        fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
        );
--
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_06                      -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���l1
                         ,iv_token_value1 => cv_table_name_xdmp || '�A' || cv_table_name_xspmp 
                           -- �G���[�����̃e�[�u����
                         ,iv_token_name2  => cv_tkn_duty_cd                        -- �g�[�N���R�[�h2
                         /* 2009.10.19 K.Kubo T4_00046�Ή� START */
                         --,iv_token_value2 => cv_duty_cd || cv_duty_cd_vl           -- �E���R�[�h 
                         ,iv_token_value2 => gv_duty_cd || gv_duty_cd_vl           -- �E���R�[�h 
                         /* 2009.10.19 K.Kubo T4_00046�Ή� END */
                         ,iv_token_name3  => cv_tkn_ymd                            -- �g�[�N���R�[�h3
                         ,iv_token_value3 => TO_CHAR(gd_process_date,'YYYYMMDD' )  -- �Ɩ�������
                         ,iv_token_name4  => cv_tkn_sales_cd                       -- �g�[�N���R�[�h4
                         ,iv_token_value4 => io_prsncd_data_rec.base_code          -- A-4�Œ��o�������_�R�[�h
                         ,iv_token_name5  => cv_tkn_sales_cd                       -- �g�[�N���R�[�h5
                         ,iv_token_value5 => io_prsncd_data_rec.employee_number    -- A-4�Œ��o�����c�ƈ��R�[�h
                         ,iv_token_name6  => cv_tkn_sales_nm                       -- �g�[�N���R�[�h6
                         ,iv_token_value6 => io_prsncd_data_rec.full_name          -- �c�ƈ�����
                         ,iv_token_name7  => cv_tkn_errmsg                         -- �g�[�N���R�[�h7
                         ,iv_token_value7 => SQLERRM                               -- SQL�G���[���b�Z�[�W
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
    END;
-- 
    -- �����c�ƈ��ʌ��ʌv��e�[�^�𒊏o����
    BEGIN 
     SELECT  xspmp.base_code                                -- ���_�R�[�h
            ,xspmp.employee_number                          -- �c�ƈ��R�[�h
            ,DECODE(xdmp.sales_plan_rel_div
            ,'1', xspmp.tgt_sales_prsn_total_amt
            ,'2' , xspmp.bsc_sls_prsn_total_amt) sls_prsn_total_amt -- �����c�ƈ��m���}���z
            ,xspmp.vis_prsn_total_amt                       -- �����K��m���}
       INTO  lt_base_code                                   -- ���_�R�[�h
            ,lt_employee_number                             -- �c�ƈ��R�[�h
            ,lt_sls_next_amt                                -- �����c�ƈ��m���}���z
            ,lt_vis_next_amt                                -- �����K��m���}
       FROM  xxcso_dept_monthly_plans xdmp                  -- ���_�ʌ��ʌv��e�[�u��
            ,xxcso_sls_prsn_mnthly_plns xspmp               -- �c�ƈ��ʌ��ʌv��e�[�u��
      WHERE  xdmp.base_code         = xspmp.base_code 
        AND  xdmp.year_month        = xspmp.year_month
        AND  xdmp.fiscal_year       = lt_year_next
        AND  xspmp.base_code        = io_prsncd_data_rec.base_code
        AND  xspmp.employee_number  = io_prsncd_data_rec.employee_number
        AND  xspmp.year_month       = lv_year_month_next;
--
      --OUT���R�[�h�Ɋi�[
      io_prsncd_data_rec.sls_next_amt    := lt_sls_next_amt;
      io_prsncd_data_rec.vis_next_amt    := lt_vis_next_amt;
      -- *** DEBUG_LOG ***
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name || CHR(10) ||
                   cv_debug_base_code || lt_base_code ||
                   cv_debug_em_num    || lt_employee_number ||
                   cv_debug_sls_amtnext   || lt_sls_next_amt ||
                   cv_debug_vis_amtnext   || lt_vis_next_amt || CHR(10) ||
                   ''
      );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- ���R�[�h���Ȃ��ꍇ�O�������� 
        io_prsncd_data_rec.sls_next_amt    := 0;
        io_prsncd_data_rec.vis_next_amt    := 0;
--
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_debug_msg13 || CHR(10) ||
                   ''
        );
--
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_06               -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_tbl                     -- �g�[�N���l1
                         ,iv_token_value1 => cv_table_name_xdmp || '�A' || cv_table_name_xspmp 
                           -- �G���[�����̃e�[�u����
                         ,iv_token_name2  => cv_tkn_duty_cd                 -- �g�[�N���R�[�h2
                         /* 2009.10.19 K.Kubo T4_00046�Ή� START */
                         --,iv_token_value2 => cv_duty_cd || cv_duty_cd_vl    -- �E���R�[�h                       
                         ,iv_token_value2 => gv_duty_cd || gv_duty_cd_vl    -- �E���R�[�h                       
                         /* 2009.10.19 K.Kubo T4_00046�Ή� END */
                         ,iv_token_name3  => cv_tkn_ymd                     -- �g�[�N���R�[�h3
                         ,iv_token_value3 => TO_CHAR(gd_process_date,'YYYYMMDD')   -- �Ɩ�������
                         ,iv_token_name4  => cv_tkn_sales_cd                -- �g�[�N���R�[�h4
                         ,iv_token_value4 => io_prsncd_data_rec.base_code   -- A-4�Œ��o�������_�R�[�h
                         ,iv_token_name5  => cv_tkn_sales_cd                -- �g�[�N���R�[�h5
                         ,iv_token_value5 => io_prsncd_data_rec.employee_number    -- A-4�Œ��o�����c�ƈ��R�[�h
                         ,iv_token_name6  => cv_tkn_sales_nm                -- �g�[�N���R�[�h6
                         ,iv_token_value6 => io_prsncd_data_rec.full_name   -- �c�ƈ�����
                         ,iv_token_name7  => cv_tkn_errmsg                  -- �g�[�N���R�[�h7
                         ,iv_token_value7 => SQLERRM                        -- SQL�G���[���b�Z�[�W
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
      END;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_prsncd_data;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSV�t�@�C���o�� (A-7)
  ***********************************************************************************/
  PROCEDURE create_csv_rec(
     ir_prsncd_data_rec  IN g_prsncd_data_rtype    -- �c�ƈ��ʌv�撊�o�f�[�^
    ,ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'create_csv_rec';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_sep_com       CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot     CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ���[�J���ϐ� ***
    lv_data          VARCHAR2(4000);  -- �ҏW�f�[�^�i�[
--
    -- *** ���[�J���E���R�[�h ***
    l_prsncd_data_rec g_prsncd_data_rtype; -- IN�p�����[�^.�c�ƈ��ʌv�撊�o�f�[�^�i�[
    -- *** ���[�J����O ***
    file_put_line_expt   EXCEPTION;    -- �f�[�^�o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����R�[�h�ϐ��Ɋi�[
    l_prsncd_data_rec := ir_prsncd_data_rec; -- �c�ƈ��ʌv�撊�o�f�[�^
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN 
--
      -- �f�[�^�쐬
      lv_data := cv_sep_wquot || l_prsncd_data_rec.base_code || cv_sep_wquot    -- ���_�R�[�h
        || cv_sep_com || cv_sep_wquot || l_prsncd_data_rec.employee_number || cv_sep_wquot  -- �c�ƈ��R�[�h
        || cv_sep_com || l_prsncd_data_rec.pure_amount_sum                      -- �����̔����ы��z
        || cv_sep_com || l_prsncd_data_rec.sls_amt                              -- �����c�ƈ��m���}���z
        || cv_sep_com || l_prsncd_data_rec.sls_next_amt                         -- �����c�ƈ��m���}���z
        || cv_sep_com || l_prsncd_data_rec.prsn_total_cnt                       -- �����K�����
        || cv_sep_com || l_prsncd_data_rec.vis_amt                              -- �����K��m���}
        || cv_sep_com || l_prsncd_data_rec.vis_next_amt ;                       -- �����K��m���}
--
      -- �f�[�^�o��
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand
       ,buffer => lv_data
      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- �t�@�C���E�n���h�������G���[
           UTL_FILE.INVALID_OPERATION  OR     -- �I�[�v���s�\�G���[
           UTL_FILE.WRITE_ERROR  THEN         -- �����ݑ��쒆�I�y���[�e�B���O�G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                          --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07                     --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_duty_cd                       -- �g�[�N���R�[�h1
                       /* 2009.10.19 K.Kubo T4_00046�Ή� START */
                       --,iv_token_value1 => cv_duty_cd                           -- �E���R�[�h
                       ,iv_token_value1 => gv_duty_cd                           -- �E���R�[�h
                       /* 2009.10.19 K.Kubo T4_00046�Ή� END */
                       ,iv_token_name2  => cv_tkn_ymd                           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(gd_process_date,'YYYYMMDD' ) -- �Ɩ�������
                       ,iv_token_name3  => cv_tkn_loc_cd                      -- �g�[�N���R�[�h3
                       ,iv_token_value3 => ir_prsncd_data_rec.base_code         -- A-4�Œ��o�������_�R�[�h
                       ,iv_token_name4  => cv_tkn_sales_cd                      -- �g�[�N���R�[�h4
                       ,iv_token_value4 => ir_prsncd_data_rec.employee_number   -- A-4�Œ��o�����c�ƈ��R�[�h
                       ,iv_token_name5  => cv_tkn_sales_nm                      -- �g�[�N���R�[�h5
                       ,iv_token_value5 => ir_prsncd_data_rec.full_name         -- �c�ƈ�����
                       ,iv_token_name6  => cv_tkn_errmsg                        -- �g�[�N���R�[�h6
                       ,iv_token_value6 => SQLERRM                              -- SQL�G���[���b�Z�[�W
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_put_line_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSV�t�@�C���N���[�Y���� (A-8)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================
    -- CSV�t�@�C���N���[�Y 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_04             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h1
                      ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END close_csv_file;
--
/* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
  /**********************************************************************************
   * Procedure Name   : get_sum_sls_tgt_data
   * Description      : ����ڕW�f�[�^�������� (A-9)
   ***********************************************************************************/
  PROCEDURE get_sum_sls_tgt_data(
     ov_errbuf         OUT  NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT  NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT  NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sum_sls_tgt_data';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --���b�Z�[�W�p
    cv_paren1           CONSTANT VARCHAR2(2)  := '( ';    -- ���J�b�R
    cv_paren2           CONSTANT VARCHAR2(2)  := ' )';    -- �E�J�b�R
    -- XXCOS:�c�Ɛ��яW����ۑ�����
    ct_prof_002a03_keeping_period
      CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_002A03_KEEPING_PERIOD';
    -- XXCOS:�J�����_�R�[�h
    ct_prof_bus_cal_code
      CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BUSINESS_CALENDAR_CODE';
    -- *** ���[�J���ϐ� ***
    lv_token_value    VARCHAR2(100);                                       --�g�[�N���l�擾�p
    ln_keeping_period NUMBER;                                              --�c�Ɛ��яW����ۑ�����
    lt_bus_cla_code   fnd_profile_option_values.profile_option_value%TYPE; --�J�����_�R�[�h
    lv_chk_err_flag   VARCHAR2(1);                                         --�`�F�b�N�G���[�t���O
    ld_first_date     DATE;
    ld_end_date       DATE;
    lv_month          VARCHAR2(6);
    -- *** ���[�J���J�[�\�� ***
    --�Q�ƃ^�C�v���ڃ`�F�b�N�p�J�[�\��
    CURSOR chk_lookup_cur
    IS
      SELECT   SUBSTRB( flv.lookup_code, 1,9 )  target_management_code -- �ڕW�Ǘ����ڃR�[�h
      FROM     fnd_lookup_values_vl flv
      WHERE    flv.lookup_type         =  ct_item_group_summary  -- ���i�ʔ���W�v�}�X�^
      AND      flv.attribute3          =  cv_yes                 -- ���i�ʔ���W�v�}�X�^�̑��M�f�[�^
      AND      flv.enabled_flag        =  cv_yes                 -- �L���Ȃ��̂̂�
      AND      flv.start_date_active  <= gd_process_date
      AND      (
                 ( flv.end_date_active IS NULL )
                 OR
                 ( LAST_DAY( ADD_MONTHS( flv.end_date_active, 1 ) ) >= gd_process_date )
               )
    ;
    TYPE g_chk_lookup_ttype IS TABLE OF chk_lookup_cur%ROWTYPE INDEX BY PLS_INTEGER;
    g_chk_lookup_tab  g_chk_lookup_ttype;
    -- *** ���[�J����O ***
    lookup_chk_exp    EXCEPTION;
    sls_tgt_data_exp  EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ----------------------------------------------------------------------
    --�G���[�������̃g�[�N���l�擾
    ----------------------------------------------------------------------
    --����ڕW���[�N�e�[�u��
    gv_err_tkn_val_01 :=  xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_value_01      -- ���b�Z�[�W�R�[�h
                          );
    ----------------------------------------------------------------------
    --����ڕW���[�N�e�[�u���̃g�����P�[�g
    ----------------------------------------------------------------------
    BEGIN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcso.xxcso_wk_sales_target';
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_11       -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_tbl             -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_err_tkn_val_01      -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmsg          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                -- �g�[�N���l2
                     );
        RAISE sls_tgt_data_exp;
    END;
--
    ----------------------------------------------------------------------
    --�Q�ƃ^�C�v�i���i�ʔ���W�v�}�X�^�j�̍��ڃ`�F�b�N
    ----------------------------------------------------------------------
    --������
    lv_chk_err_flag := cv_no;
    --�f�[�^�擾
    OPEN  chk_lookup_cur;
    FETCH chk_lookup_cur BULK COLLECT INTO g_chk_lookup_tab;
    CLOSE chk_lookup_cur;
--
    --�`�F�b�N
    <<chk_loop>>
    FOR i IN 1..g_chk_lookup_tab.COUNT LOOP
--
      --�ڕW�Ǘ����ڃR�[�h(���p�p��)
      IF ( xxccp_common_pkg.chk_number( g_chk_lookup_tab(i).target_management_code ) = FALSE ) THEN
        --�G���[�t���O���X�V
        lv_chk_err_flag := cv_yes;
        --�g�[�N���l�擾
        lv_token_value := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name_cmm        -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_cmm_01   -- ���b�Z�[�W�R�[�h
                          );
        --���b�Z�[�W����
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_ccp        -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_cmm_02   -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_item            -- �g�[�N���R�[�h1
                      ,iv_token_value1 => lv_token_value
                                          || cv_paren1 || g_chk_lookup_tab(i).target_management_code || cv_paren2 -- �g�[�N���l1
                     );
        --���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT --�o��
          ,buff   => lv_errmsg       --���[�U�[�E�G���[���b�Z�[�W
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG    --���O
          ,buff => lv_errmsg         --�G���[���b�Z�[�W
        );
        --�x���J�E���g
        gn_warn_cnt2 := gn_warn_cnt2 + 1;
      END IF;
--
    END LOOP chk_loop;
--
    --�z��폜
    g_chk_lookup_tab.DELETE;
--
    --�Q�ƃ^�C�v�̃`�F�b�NNG�̏ꍇ�A�����I��
    IF ( lv_chk_err_flag = cv_yes ) THEN
      RAISE lookup_chk_exp;
    END IF;
--
    ----------------------------------------------------------------------
    --�v���t�@�C���̎擾
    ----------------------------------------------------------------------
    --�c�Ɛ��ѕ\�ێ�����
    ln_keeping_period := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_002a03_keeping_period ) );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( ln_keeping_period IS NULL ) THEN
      --���b�Z�[�W����
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_14              -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm                -- �g�[�N���R�[�h1
                    ,iv_token_value1 => ct_prof_002a03_keeping_period -- �g�[�N���l1
                   );
      RAISE sls_tgt_data_exp;
    END IF;
    --�c�Ɛ��ѕ\��ێ����Ă���ŏ������擾
    gv_keeping_month  := TO_CHAR( LAST_DAY( ADD_MONTHS( gd_process_date, ln_keeping_period * -1 ) ) + 1, 'YYYYMM');
    --�J�����_�R�[�h
    lt_bus_cla_code   := FND_PROFILE.VALUE( ct_prof_bus_cal_code );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lt_bus_cla_code IS NULL ) THEN
      --���b�Z�[�W����
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_14              -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm                -- �g�[�N���R�[�h1
                    ,iv_token_value1 => ct_prof_bus_cal_code          -- �g�[�N���l1
                   );
      RAISE sls_tgt_data_exp;
    END IF;
--
    ----------------------------------------------------------------------
    --���������ƌo�ߓ������擾�i�c�Ɛ��ѕ\�ێ����ԕ��j
    ----------------------------------------------------------------------
    --�����̖ڕW���M�Ώۓ��̏ꍇ�A���������擾
    IF ( gd_process_date = LAST_DAY( gd_process_date ) ) THEN
      --�����̎擾�ݒ�
      ld_first_date     := TRUNC( gd_process_date + 1, 'MM' );  --����1��
      ln_keeping_period := ln_keeping_period + 1;               --�c�Ɛ��ѕ\�ێ����� + 1(������)
    ELSE
      --�����̎擾�ݒ�
      ld_first_date     := TRUNC( gd_process_date, 'MM' );      --����1��
    END IF;
--
    ld_end_date         := LAST_DAY( ld_first_date );           --��L�����ꂩ�̍ŏI��
    lv_month            := TO_CHAR( ld_first_date, 'YYYYMM' );  --�z��Y����
--
    <<day_cnt_loop>>
    FOR i IN 1..ln_keeping_period LOOP
--
      BEGIN
        SELECT  SUM(CASE
                      WHEN  cal.seq_num IS NOT NULL
                      THEN  1
                      ELSE  0
                    END)                    AS  actual_day_cnt,
                SUM(CASE 
                      WHEN  cal.seq_num IS NOT NULL
                      AND   cal.calendar_date <= gd_process_date
                      THEN  1
                      ELSE  0
                    END)                    AS  passed_day_cnt
        INTO    g_date_cnt_tab(lv_month).actual_day_cnt
               ,g_date_cnt_tab(lv_month).passed_day_cnt
        FROM    bom_calendar_dates  cal
        WHERE   cal.calendar_code       =       lt_bus_cla_code
        AND     cal.calendar_date       BETWEEN ld_first_date
                                        AND     ld_end_date
        ;
        --�擾�ݒ�̑O���ȑO
        ld_first_date  := ADD_MONTHS( ld_first_date, -1 );
        ld_end_date    := LAST_DAY( ld_first_date );
        lv_month       := TO_CHAR( ld_first_date, 'YYYYMM' );
--
      EXCEPTION
        WHEN OTHERS THEN
           --�g�[�N���l�擾
          lv_token_value := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name_cmm        -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => cv_tkn_value_02        -- ���b�Z�[�W�R�[�h
                            );
          --���b�Z�[�W����
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_15  -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_item       -- �g�[�N���R�[�h1
                        ,iv_token_value1 => lv_token_value    -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_err_msg    -- �g�[�N���R�[�h2
                        ,iv_token_value2 => SQLERRM           -- �g�[�N���l2
                       );
          RAISE sls_tgt_data_exp;
      END;
--
    END LOOP day_cnt_loop;
--
  EXCEPTION
--
    -- *** �Q�ƃ^�C�v�`�F�b�N�G���[ *** --
    WHEN lookup_chk_exp THEN
--
      --�I�������O�o��
      gv_log_control_flag := 'N';
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
--
    -- *** �f�[�^�擾�G���[ *** --
    WHEN sls_tgt_data_exp THEN
--
      --�x���J�E���g
      gn_warn_cnt2 := 1;
      --�I�������O�o��
      gv_log_control_flag := 'Y';
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,4000);
      ov_retcode   := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      --�x���J�E���g
      gn_warn_cnt2 := 1;
      --�I�������O�o��
      gv_log_control_flag := 'Y';
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode   := cv_status_warn;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      --�x���J�E���g
      gn_warn_cnt2 := 1;
      --�I�������O�o��
      gv_log_control_flag := 'Y';
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode   := cv_status_warn;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      --�x���J�E���g
      gn_warn_cnt2 := 1;
      --�I�������O�o��
      gv_log_control_flag := 'Y';
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_warn;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sum_sls_tgt_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_results
   * Description      : ���уf�[�^���[�N�e�[�u���i�[ (A-11)
   ***********************************************************************************/
  PROCEDURE ins_work_results(
     i_sales_target_rec  IN  g_sales_target_rtype        -- ����ڕW���[�N�e�[�u��
    ,ov_errbuf           OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work_results';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_msg_tkn_value1 VARCHAR2(100);
    lv_msg_tkn_value2 VARCHAR2(100);
    -- *** ���[�J����O ***
    work_results_ins_exp EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------
    -- ���[�N�e�[�u���i�[
    ------------------------------
    BEGIN
      INSERT INTO xxcso_wk_sales_target(
         base_code              --���_�R�[�h
        ,employee_code          --�c�ƈ��R�[�h
        ,sale_amount_month_sum  --���ы��z
        ,target_amount          --�ڕW���z
        ,target_management_code --�ڕW�Ǘ����ڃR�[�h
        ,target_month           --�N��
        ,actual_day_cnt         --��������
        ,passed_day_cnt         --�o�ߓ���
        ,created_by             --�쐬��
        ,creation_date          --�쐬��
        ,last_updated_by        --�ŏI�X�V��
        ,last_update_date       --�ŏI�X�V��
        ,last_update_login      --�ŏI�X�V���O�C��
        ,request_id             --�v��ID
        ,program_application_id --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id             --�R���J�����g�E�v���O����ID
        ,program_update_date    --�v���O�����X�V��
      ) VALUES (
         i_sales_target_rec.base_code               --���_�R�[�h
        ,i_sales_target_rec.employee_code           --�c�ƈ��R�[�h
        ,i_sales_target_rec.sale_amount_month_sum   --���ы��z
        ,i_sales_target_rec.target_amount           --�ڕW���z
        ,i_sales_target_rec.target_management_code  --�ڕW�Ǘ����ڃR�[�h
        ,i_sales_target_rec.target_month            --�N��
        ,i_sales_target_rec.actual_day_cnt          --��������
        ,i_sales_target_rec.passed_day_cnt          --�o�ߓ���
        ,cn_created_by                              --�쐬��
        ,cd_creation_date                           --�쐬��
        ,cn_last_updated_by                         --�ŏI�X�V��
        ,cd_last_update_date                        --�ŏI�X�V��
        ,cn_last_update_login                       --�ŏI�X�V���O�C��
        ,cn_request_id                              --�v��ID
        ,cn_program_application_id                  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id                              --�R���J�����g�E�v���O����ID
        ,cd_program_update_date                     --�v���O�����X�V��
      );
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W����
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_12         --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_tbl               --�g�[�N���R�[�h1
                      ,iv_token_value1 => gv_err_tkn_val_01        --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmsg            --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                  --�g�[�N���l2
                     );
        RAISE work_results_ins_exp;
    END;
--
  EXCEPTION
--
    WHEN work_results_ins_exp THEN
--
      --�x���J�E���g
      gn_warn_cnt2 := 1;
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,4000);
      ov_retcode   := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      --�x���J�E���g
      gn_warn_cnt2 := 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_warn;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      --�x���J�E���g
      gn_warn_cnt2 := 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_warn;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      --�x���J�E���g
      gn_warn_cnt2 := 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_warn;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_work_results;
--
/* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� START */
    -- *** ���[�J���萔 ***
    ct_prof_electric_fee_item_cd
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
    /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� END */
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
    ct_base_code
    CONSTANT  xxcso_wk_sales_target.base_code%TYPE         := '0';
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
    -- *** ���[�J���ϐ� ***
    -- OUT�p�����[�^�i�[�p
    lv_csv_dir           VARCHAR2(2000); -- CSV�t�@�C���o�͐�
    lv_csv_nm            VARCHAR2(2000); -- CSV�t�@�C����
    lb_fopn_retcd        BOOLEAN;        -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lv_err_rec_info      VARCHAR2(5000); -- �f�[�^���ړ��e���b�Z�[�W�o�͗p
    lv_process_date_next VARCHAR2(150);  -- �f�[�^���ړ��e���b�Z�[�W�o�͗p 
    /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� START */
    -- �J�[�\�������p
    lt_elextric_item_cd    xxcos_sales_exp_lines.item_code%TYPE; -- �ϓ��d�C��i�ڃR�[�h(�v���t�@�C���l)�i�[�p
    ln_closed_id           NUMBER;                               -- �N���[�YID�i�[�p
    ld_process_date_next01 DATE;                                 -- �Ɩ��������̌������i�[�p
    /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� END */
    
--
-- *** ���[�J���E�J�[�\�� ***
    -- �c�ƈ��R�[�h�A���_�R�[�h�A���\�[�XID�̎擾���s���J�[�\���̒�`
    CURSOR xrv_v_cur
    IS
      SELECT xrv.employee_number  employee_number  -- �c�ƈ��R�[�h
             /* 2009.05.20 K.Satomura T1_1082�Ή� START */
              --(CASE WHEN xrv.issue_date <= lv_process_date_next THEN
              --        xrv.work_dept_code_new
              --      WHEN lv_process_date_next < xrv.issue_date THEN
              --        xrv.work_dept_code_old
              --      END
              -- ) work_base_code                      -- ���_�R�[�h
             ,xxcso_util_common_pkg.get_rs_base_code(
                 xrv.resource_id
                ,gd_process_date_next
             ) work_base_code                        -- ���_�R�[�h
             /* 2009.05.20 K.Satomura T1_1082�Ή� END */
             ,xrv.resource_id resource_id            -- ���\�[�XID
             ,xrv.full_name full_name                -- �c�ƈ����� 
             /* 2009.10.19 K.Kubo T4_00046�Ή� START */
             ,(CASE WHEN  (xrv.issue_date          <= lv_process_date_next
                         AND TRIM(xrv.duty_code_new) IN (cv_duty_cd, cv_duty_cd_050))
                    THEN
                      TRIM(xrv.duty_code_new)
                    WHEN  (lv_process_date_next    <  xrv.issue_date
                         AND TRIM(xrv.duty_code_old) IN (cv_duty_cd, cv_duty_cd_050))
                    THEN
                      TRIM(xrv.duty_code_old)
                    ELSE
                      NULL
                    END
              ) duty_code                            -- �Ɩ��R�[�h
             /* 2009.10.19 K.Kubo T4_00046�Ή� END */
             /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� START */
             ,NVL(se_amt.pure_amount_sum ,0)     pure_amount_sum
             ,NVL(jtb_cnt.prsn_total_cnt ,0)     prsn_total_cnt
             /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� END */
      FROM   xxcso_resources_v  xrv                  -- ���\�[�X�}�X�^�r���[
            /* 2009.06.03 K.Satomura T1_1304�Ή� START */
            ,(
               SELECT per.person_id                 person_id
                     ,MAX(per.effective_start_date) max_effective_start_date
               FROM   per_people_f per
                     /* 2009.06.03 K.Satomura T1_1304�Ή�(�ďC��) START */
                     ,per_assignments_f paf
                     /* 2009.06.03 K.Satomura T1_1304�Ή�(�ďC��) END */
               WHERE  per.effective_start_date <= gd_process_date_next
               /* 2009.06.03 K.Satomura T1_1304�Ή�(�ďC��) START */
               AND    per.person_id            =  paf.person_id
               AND    per.effective_start_date =  paf.effective_start_date
               /* 2009.06.03 K.Satomura T1_1304�Ή�(�ďC��) END */
               GROUP BY per.person_id
             ) ppf
            /* 2009.06.03 K.Satomura T1_1304�Ή� END */
      /* 2009.10.19 K.Kubo T4_00046�Ή� START */
      --  WHERE  (
      --               xrv.issue_date          <= lv_process_date_next
      --           AND TRIM(xrv.duty_code_new) =  cv_duty_cd
      --           OR  lv_process_date_next    <  xrv.issue_date
      --           AND TRIM(xrv.duty_code_old) =  cv_duty_cd
      --         )
            /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� START */
            ,(
              SELECT /*+
                       USE_NL(saeh sael)
                       INDEX(saeh xxcos_sales_exp_headers_n11)
                     */
                     saeh.sales_base_code        sales_base_code
                    ,saeh.results_employee_code  results_employee_code
                    ,ROUND(SUM(sael.pure_amount) /1000) pure_amount_sum   -- �̔����ы��z(��~�P�ʂɎ擾)
              FROM   xxcos_sales_exp_headers  saeh,
                     xxcos_sales_exp_lines    sael
              WHERE  sael.sales_exp_header_id      =  saeh.sales_exp_header_id
              AND    sael.item_code                <> lt_elextric_item_cd -- �ϓ��d�C��(�v���t�@�C��)
              AND    saeh.delivery_date BETWEEN ld_process_date_next01
                                            AND gd_process_date
              GROUP BY
                     saeh.sales_base_code
                    ,saeh.results_employee_code
             ) se_amt
            ,(
              SELECT /*+
                       INDEX(jtb xxcso_jtf_tasks_b_n20)
                     */
                     jtb.owner_id  owner_id
                    ,COUNT(1)      prsn_total_cnt  -- �����K�����
              FROM   jtf_tasks_b  jtb
              WHERE  jtb.source_object_type_code = cv_object_cd        -- �\�[�X�R�[�h:'PARTY'
              AND    jtb.task_status_id          = ln_closed_id        -- �N���[�YID(�v���t�@�C��)
              AND    jtb.deleted_flag            = cv_delete_flag      -- ���폜
              AND    TRUNC(jtb.actual_end_date) BETWEEN ld_process_date_next01
                                                    AND gd_process_date
              AND    jtb.owner_type_code         = cv_owner_type_code  -- �I�[�i�[�^�C�v:'RS_EMPLOYEE'
              GROUP BY
                     jtb.owner_id
             ) jtb_cnt
             /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� END */
      WHERE  (
                (xrv.issue_date          <= lv_process_date_next
               AND TRIM(xrv.duty_code_new) IN (cv_duty_cd, cv_duty_cd_050))  -- �E�� 010�F���[�g�Z�[���X��050�F���S�ݓX�̔�
             OR (lv_process_date_next    <  xrv.issue_date
               AND TRIM(xrv.duty_code_old) IN (cv_duty_cd, cv_duty_cd_050))  -- �E�� 010�F���[�g�Z�[���X��050�F���S�ݓX�̔�
             )
      /* 2009.10.19 K.Kubo T4_00046�Ή� END */
      /* 2009.06.03 K.Satomura T1_1304�Ή� START */
      --  AND gd_process_date_next BETWEEN TRUNC(xrv.start_date)
      --        AND TRUNC(NVL(xrv.end_date, gd_process_date_next)) 
      --  AND gd_process_date_next BETWEEN TRUNC(xrv.employee_start_date)
      --        AND TRUNC(NVL(xrv.employee_end_date,gd_process_date_next))
      --  AND gd_process_date_next BETWEEN TRUNC(xrv.assign_start_date)
      --        AND TRUNC(NVL(xrv.assign_end_date,gd_process_date_next))
      --  AND gd_process_date_next BETWEEN TRUNC(xrv.resource_start_date) 
      --        AND TRUNC(NVL(xrv.resource_end_date, gd_process_date_next));
      AND    ppf.person_id = xrv.person_id
      -- ���[�U�[�F�]�ƈ��ŐV���R�[�h�ɕR�Â�
      AND    ppf.max_effective_start_date BETWEEN TRUNC(xrv.start_date)
      AND    TRUNC(NVL(xrv.end_date, ppf.max_effective_start_date)) -- NVL��MAX�J�n��
      -- �]�ƈ��F���\�[�X�ɕR�Â��ŐV���R�[�h�j
      AND    ppf.max_effective_start_date BETWEEN TRUNC(xrv.employee_start_date)
      AND    TRUNC(NVL(xrv.employee_end_date,ppf.max_effective_start_date)) -- NVL��MAX�J�n��
      -- �A�T�C�����g�F�]�ƈ��ŐV���R�[�h�ɕR�Â�
      AND    ppf.max_effective_start_date BETWEEN TRUNC(xrv.assign_start_date)
      AND    TRUNC(NVL(xrv.assign_end_date,ppf.max_effective_start_date)) -- NVL��MAX�J�n��
        -- ���\�[�X�F�i�Ɩ��������{�P�j���_�ŗL���i�L�����f�̓��\�[�X�̂݁B�j
      AND    gd_process_date_next BETWEEN TRUNC(xrv.resource_start_date) -- ����ŗL�����f����B
      AND    TRUNC(NVL(xrv.resource_end_date, gd_process_date_next))
      /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� START */
      AND    se_amt.results_employee_code(+) = xrv.employee_number
      AND    se_amt.sales_base_code(+)       = xxcso_util_common_pkg.get_rs_base_code(
                                                 xrv.resource_id
                                                ,gd_process_date_next)
      AND    jtb_cnt.owner_id(+)             = xrv.resource_id
      /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� END */
      ;
      /* 2009.06.03 K.Satomura T1_1304�Ή� END */
--
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
    -- �����̖ڕW�f�[�^(1����HHT�ŕ\������)�̎擾���s���J�[�\���̒�`
    CURSOR target_start_cur
    IS
      SELECT /*+
               LEADING(flv)
               USE_NL(flv xstm)
               INDEX(xstm xxcso_sales_target_mst_pk)
             */
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD START */
--              ct_base_code                                      base_code              --���_�R�[�h
              xstm.base_code                                    base_code              --���_�R�[�h
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD END   */
             ,xstm.employee_code                                employee_code          --�c�ƈ��R�[�h
             ,0                                                 sale_amount_month_sum  --���ы��z
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD START */
--             ,ROUND( NVL( xstm.target_amount,0 ) / 1000 )       target_amount          --�ڕW���z
             ,NVL( xstm.target_amount,0 )                       target_amount          --�ڕW���z
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD END   */
             ,xstm.target_management_code                       target_management_code --�ڕW�Ǘ����ڃR�[�h
             ,xstm.target_month                                 target_month           --�N��
             ,''                                                actual_day_cnt         --��������
             ,''                                                passed_day_cnt         --�o�ߓ���
      FROM   xxcso_sales_target_mst  xstm  --����ڕW�}�X�^
            ,fnd_lookup_values_vl    flv   --���i�ʔ���W�v�}�X�^(���M)
      WHERE  flv.lookup_type                               = ct_item_group_summary      --XXCMM1_ITEM_GROUP_SUMMARY
      AND    flv.enabled_flag                              = cv_yes                     --�L���̂�
      AND    flv.attribute3                                = cv_yes                     --���i�ʔ���W�v�}�X�^�̑��M�f�[�^
      AND    SUBSTRB(flv.lookup_code, 1, 9)                = xstm.target_management_code
      AND    ( TO_DATE( xstm.target_month, 'YYYYMM' ) -1 ) = gd_process_date            --�Ɩ����t���ڕW�N���̑O��
      AND    (
               ( flv.end_date_active IS NULL )
               OR
               ( TO_CHAR( flv.end_date_active, 'YYYYMM') >= xstm.target_month )
             )                                                               --�W�v���Ԃ��I�����Ă��Ȃ�
      ;
    -- ����ڕW�f�[�^�����Ŏ��т����݂���ꍇ�̎擾���s���J�[�\���̒�`
    CURSOR sales_exist_cur
    IS
      SELECT /*+
               LEADING(sum_d)
             */ 
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD START */
--              ct_base_code                                          base_code              --���_(����)�R�[�h
              sum_d.base_code                                       base_code              --���_(����)�R�[�h
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD END   */
             ,sum_d.employee_code                                   employee_code          --�c�ƈ��R�[�h
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD START */
--             ,ROUND( NVL(sum_d.sale_amount_month_sum, 0 ) /1000 )   sale_amount_month_sum  --���ы��z
--             ,ROUND( NVL( xstm.target_amount, 0 ) /1000 )           target_amount          --�ڕW���z
             ,NVL( sum_d.sale_amount_month_sum, 0 )                sale_amount_month_sum  --���ы��z
             ,NVL( xstm.target_amount, 0 )                         target_amount          --�ڕW���z
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD END   */
             ,SUBSTRB(flv.lookup_code, 1, 9)                        target_management_code --�ڕW�Ǘ����ڃR�[�h(���v�s)
             ,sum_d.target_month                                    target_month           --�Ώ۔N��(YYYYMM�`��)
             ,NULL                                                  actual_day_cnt         --��������
             ,NULL                                                  passed_day_cnt         --�o�ߓ���
      FROM    ( SELECT /*+
                         LEADING(flv)
                         USE_NL(flv xrbsgs)
                       */
                       flv.attribute2                      sum_code                --���v�敪
                      ,TO_CHAR(xrbsgs.dlv_date, 'YYYYMM')  target_month            --�Ώ۔N��
                      ,xrbsgs.results_employee_code        employee_code           --�c�ƈ��R�[�h
                      ,SUM(xrbsgs.sale_amount)             sale_amount_month_sum   --���ʏ�������z���v
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� ADD START */
                      ,xrbsgs.sale_base_code               base_code               --���_�R�[�h
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� ADD END   */
                FROM   fnd_lookup_values_vl        flv     --���i�ʔ���W�v�}�X�^(�W��)
                      ,xxcos_rep_bus_s_group_sum   xrbsgs  --�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u��
                WHERE  flv.lookup_type         =  ct_item_group_summary      --XXCMM1_ITEM_GROUP_SUMMARY
                AND    flv.enabled_flag        =  cv_yes                     --�L���̂�
                AND    flv.attribute3          =  cv_no                      --���i�ʔ���W�v�}�X�^�̏W��f�[�^
                AND    flv.start_date_active   <= gd_process_date            --���i�ʔ���W�v�}�X�^�̗L���J�n�����Ɩ����t�ȑO
                AND    (
                         ( flv.end_date_active IS NULL )
                         OR
                         ( LAST_DAY( ADD_MONTHS( flv.end_date_active, 1 ) ) >= gd_process_date )
                       )                                                     --�W�v�Ώۊ��Ԃ̗�������(�N���[�Y���錎�̖���)�܂ŏW�v
                AND    flv.attribute1          =  xrbsgs.policy_group_code
                AND    xrbsgs.dlv_date         >= flv.start_date_active                       --�[�i�������i�ʔ���W�v�}�X�^�̗L���J�n���ȍ~
                AND    xrbsgs.dlv_date         <= NVL(flv.end_date_active, gd_process_date )  --�[�i�������i�ʔ���W�v�}�X�^�̗L���I�����ȑO
                GROUP BY
                       flv.attribute2                      --���v�敪
                      ,TO_CHAR(xrbsgs.dlv_date, 'YYYYMM')  --�[�i��(���P��)
                      ,xrbsgs.results_employee_code        --���ьv��҃R�[�h
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� ADD START */
                      ,xrbsgs.sale_base_code               --���_�R�[�h
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� ADD END   */
              ) sum_d                             --�c�ƈ��ʔ���T�}��
             ,fnd_lookup_values_vl        flv     --���i�ʔ���W�v�}�X�^(���M)
             ,xxcso_sales_target_mst      xstm    --����ڕW�}�X�^
      WHERE   flv.lookup_type                        = ct_item_group_summary      --XXCMM1_ITEM_GROUP_SUMMARY
      AND     flv.enabled_flag                       = cv_yes                     --�L���̂�
      AND     flv.attribute3                         = cv_yes                     --���i�ʔ���W�v�}�X�^�̑��M�f�[�^
      AND     SUBSTRB(flv.lookup_code, 1, 9)         = sum_d.sum_code
      AND     sum_d.sum_code                         = xstm.target_management_code(+)
      AND     sum_d.employee_code                    = xstm.employee_code(+)
      AND     sum_d.target_month                     = xstm.target_month(+)
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� ADD START */
      AND     sum_d.base_code                        = xstm.base_code(+)
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� ADD END */
      ;
--
    -- ����ڕW�f�[�^�����Ŏ��т����݂��Ȃ��ꍇ�ɖڕW�̂�(����������)�̎擾���s���J�[�\���̒�`
    CURSOR target_only_cur
    IS
      SELECT  /*+ 
                LEADING(flv) 
                USE_NL(flv xstm)
                INDEX(xstm xxcso_sales_target_mst_pk)
              */
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD START */
--              ct_base_code                                  base_code              --���_�R�[�h
              xstm.base_code                                base_code              --���_�R�[�h
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD END   */
             ,xstm.employee_code                            employee_code          --�c�ƈ��R�[�h
             ,0                                             sale_amount_month_sum  --���ы��z
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD START */
--             ,ROUND( NVL( xstm.target_amount, 0 ) / 1000 )  target_amount          --�ڕW���z
             ,NVL( xstm.target_amount, 0 )                  target_amount          --�ڕW���z
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD END   */
             ,xstm.target_management_code                   target_management_code --�ڕW�Ǘ����ڃR�[�h
             ,xstm.target_month                             target_month           --�N��
             ,''                                            actual_day_cnt         --��������
             ,''                                            passed_day_cnt         --�o�ߓ���
      FROM    xxcso_sales_target_mst xstm --����ڕW�}�X�^
             ,fnd_lookup_values_vl   flv  --���i�ʔ���W�v�}�X�^
      WHERE   flv.lookup_type         = ct_item_group_summary 
      AND     flv.enabled_flag        = cv_yes  --�L���̂�
      AND     flv.attribute3          = cv_yes  --���v�s
      AND     SUBSTRB(flv.lookup_code, 1, 9)    = xstm.target_management_code
      AND     xstm.target_month                >= gv_keeping_month                     --�ڕW�̑Ώۊ��ԂɎ��т��ێ�����Ă���(�ߋ���ΏۂƂ��Ȃ�)
      AND     xstm.target_month                <= TO_CHAR( gd_process_date, 'YYYYMM')  --�ڕW�̑Ώۊ��ԂɋƖ����t���������Ă���(������ΏۂƂ��Ȃ�)
      AND     xstm.target_month                >= TO_CHAR( flv.start_date_active, 'YYYYMM') --�W�v���Ԃ̊J�n�ȍ~�Ŏ擾
      AND     (
                ( flv.end_date_active IS NULL )
                OR
                (
                  ( LAST_DAY( ADD_MONTHS( flv.end_date_active, 1 ) ) >= gd_process_date )
                  AND
                  ( TO_CHAR( flv.end_date_active, 'YYYYMM') >= xstm.target_month )
                )
              )                                                                        --�W�v�Ώۊ��Ԃ��I����A���������܂ł͑Ώ�(�A���A���ԏI����̖ڕW�͑ΏۂƂ��Ȃ�)
      AND     NOT EXISTS (
                SELECT 1
                FROM   xxcso_wk_sales_target xwst  --����ڕW���[�N�e�[�u��
                WHERE  xwst.target_management_code = xstm.target_management_code
                AND    xwst.employee_code          = xstm.employee_code
                AND    xwst.target_month           = xstm.target_month
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� ADD START */
                AND    xwst.base_code              = xstm.base_code
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� ADD END */
                AND    rownum                      = 1
              )  --�c�ƈ��̖ڕW�͑��݂��邪�Ώۂ̌��̎��т͑��݂��Ȃ�
      ;
--
    -- ����ڕW�f�[�^CSV�o�͂��s���J�[�\���̒�`
    CURSOR sales_target_out_cur
    IS
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD START */
--      SELECT  xwst.base_code                   base_code               --���_�R�[�h
      SELECT  ct_base_code                      base_code               --���_�R�[�h
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD END   */
             ,xwst.employee_code               employee_code           --�c�ƈ��R�[�h
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD START */
--             ,xwst.sale_amount_month_sum       sale_amount_month_sum   --���ы��z
--             ,xwst.target_amount               target_amount           --�ڕW���z
             ,ROUND( SUM( xwst.sale_amount_month_sum ) / 1000 )
                                                 sale_amount_month_sum   --���ы��z(�T�}����Ɏl�̌ܓ�)
             ,ROUND( SUM( xwst.target_amount         ) / 1000 )
                                                 target_amount           --�ڕW���z(�T�}����Ɏl�̌ܓ�)
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� MOD END   */
             ,xwst.target_management_code      target_management_code  --�ڕW�Ǘ����ڃR�[�h
             ,SUBSTRB(xwst.target_month, 3, 4) target_month            --�N��(YYMM�`���Ƃ���)
             ,xwst.actual_day_cnt              actual_day_cnt          --��������
             ,xwst.passed_day_cnt              passed_day_cnt          --�o�ߓ���
             ,xwst.target_month                output_month            --CSV�o�̓G���[���̃��b�Z�[�W�Ɏg�p
      FROM   xxcso_wk_sales_target xwst  --����ڕW���[�N�e�[�u��
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� ADDD START */
      GROUP BY
             xwst.employee_code           --�c�ƈ��R�[�h
            ,xwst.target_management_code  --�ڕW�Ǘ����ڃR�[�h
            ,xwst.target_month            --�N��
            ,xwst.actual_day_cnt          --��������
            ,xwst.passed_day_cnt          --�o�ߓ���
/* 2013.06.18 T.Ishiwata E_�{�ғ�_10873�Ή� ADD END   */
      ;
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
    -- *** ���[�J���E���R�[�h ***
    l_xrv_v_cur_rec       xrv_v_cur%ROWTYPE;
    l_prsncd_data_rec     g_prsncd_data_rtype;
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
    l_output_cur_rec      sales_target_out_cur%ROWTYPE;
    l_sum_cur_rec         g_sales_target_rtype;
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
    -- *** ���[�J����O ***
    no_data_expt               EXCEPTION;
    error_skip_data_expt       EXCEPTION;
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
    sales_target_process_expt  EXCEPTION;
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
    gn_target_cnt2 := 0;
    gn_normal_cnt2 := 0;
    gn_warn_cnt2   := 0;
    gv_log_control_flag := 'N';
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--
  -- ========================================
  -- A-1.�������� 
  -- ========================================
    init(
      ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  -- ========================================
  -- A-2.�v���t�@�C���l�擾 
  -- ========================================
    get_profile_info(
       ov_csv_dir     => lv_csv_dir     -- CSV�t�@�C���o�͐�
      ,ov_csv_nm      => lv_csv_nm      -- CSV�t�@�C����
      ,ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode     => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg      => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-3.CSV�t�@�C���I�[�v��
    -- =================================================
    open_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSV�t�@�C���o�͐�
      ,iv_csv_nm    => lv_csv_nm    -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-4.���\�[�X�f�[�^�擾
    -- =================================================
    lv_process_date_next  := TO_CHAR(gd_process_date_next, 'YYYYMMDD');
    /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� START */
    ln_closed_id           := TO_NUMBER(gv_closed_id);
    lt_elextric_item_cd    := FND_PROFILE.VALUE(ct_prof_electric_fee_item_cd);
    ld_process_date_next01 := TO_DATE(TO_CHAR(gd_process_date_next, 'YYYYMM') || '01', 'YYYYMMDD');
    /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� END */
--
    --�J�[�\���I�[�v��
    OPEN xrv_v_cur;
--
    <<get_data_loop>>
    LOOP 
      BEGIN
        FETCH xrv_v_cur INTO l_xrv_v_cur_rec;
--
        --�����Ώی����i�[
        gn_target_cnt := xrv_v_cur%ROWCOUNT;
--
        
        EXIT WHEN xrv_v_cur%NOTFOUND
          OR  xrv_v_cur%ROWCOUNT = 0;
        -- ���R�[�h�ϐ�������
        l_prsncd_data_rec := NULL;
        -- �擾�f�[�^���i�[
        l_prsncd_data_rec.employee_number   := l_xrv_v_cur_rec.employee_number;
        l_prsncd_data_rec.base_code         := l_xrv_v_cur_rec.work_base_code;
        l_prsncd_data_rec.resource_id       := l_xrv_v_cur_rec.resource_id;
        l_prsncd_data_rec.full_name         := l_xrv_v_cur_rec.full_name;
        /* 2009.10.19 K.Kubo T4_00046�Ή� START */
        /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� START */
        l_prsncd_data_rec.pure_amount_sum   := l_xrv_v_cur_rec.pure_amount_sum;
        l_prsncd_data_rec.prsn_total_cnt    := l_xrv_v_cur_rec.prsn_total_cnt;
        /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� END */
        --�E���R�[�h
        gv_duty_cd                          := l_xrv_v_cur_rec.duty_code;
        --�E���R�[�h��
        IF (gv_duty_cd = cv_duty_cd ) THEN
          gv_duty_cd_vl                     := cv_duty_cd_vl;      -- ���[�g�Z�[���X
        ELSIF (gv_duty_cd = cv_duty_cd_050 ) THEN
          gv_duty_cd_vl                     := cv_duty_cd_050_vl;  -- ���X�A�S�ݓX�̔�
        ELSE
          gv_duty_cd_vl                     := NULL;
        END IF;
        /* 2009.10.19 K.Kubo T4_00046�Ή� END */
        -- ���o�������ڂ��J���}��؂�ŕ����A�����ă��O�ɏo�͂���p
        lv_err_rec_info := l_prsncd_data_rec.employee_number||','
                        || l_prsncd_data_rec.base_code ||','
                        || l_prsncd_data_rec.resource_id||','
                        || l_prsncd_data_rec.full_name;
        fnd_file.put_line(
            which  => FND_FILE.LOG,
            buff   => lv_err_rec_info
          );
--
        /* 2009.05.28 K.Satomura T1_1236�Ή� START */
        IF (l_prsncd_data_rec.base_code IS NULL) THEN
          -- ���_�R�[�h��NULL�̏ꍇ�i���\�[�X�O���[�v���ݒ肳��Ă��Ȃ��ꍇ�j
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                       -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_10                  -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_emp_num                    -- �g�[�N���R�[�h1
                         ,iv_token_value1 => l_prsncd_data_rec.employee_number -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_emp_name                   -- �g�[�N���R�[�h2
                         ,iv_token_value2 => l_prsncd_data_rec.full_name       -- �g�[�N���l2
                       );
          --
          lv_errbuf := lv_errmsg;
          RAISE error_skip_data_expt;
          --
        END IF;
        --
        /* 2009.05.28 K.Satomura T1_1236�Ή� END */
        /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� START */
        -- =================================================
        -- A-5.CSV�t�@�C���ɏo�͂���֘A���擾
        -- =================================================
        --get_sum_cnt_data(
        --   io_prsncd_data_rec => l_prsncd_data_rec   -- �c�ƈ��Ǘ�(�t�@�C��)��񃏁[�N�e�[�u���f�[�^
        --  ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
        --  ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
        --  ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        --);
        --IF (lv_retcode = cv_status_error) THEN
        --  RAISE global_process_expt;
        --END IF;
        -- �̔����ъz�����O�ɏo��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_sum   || TO_CHAR(l_prsncd_data_rec.pure_amount_sum)
        );
        -- �����K����ь��������O�ɏo��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_cnt   || TO_CHAR(l_prsncd_data_rec.prsn_total_cnt) || CHR(10)
        );
        /* 2010.08.26 K.Kiriu E_�{��_04153�Ή� END */
--        
       -- =====================================================
        -- A-6.�c�ƈ��Ǘ��f�[�^�𒊏o 
        -- =================================================
        get_prsncd_data(
           io_prsncd_data_rec => l_prsncd_data_rec         -- �c�ƈ��Ǘ�(�t�@�C��)��񃏁[�N�e�[�u���f�[�^
          ,ov_errbuf          => lv_errbuf                 -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode         => lv_retcode                -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg          => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
        -- =====================================================
        -- A-7.CSV�t�@�C���o�� 
        -- =================================================
        create_csv_rec(
           ir_prsncd_data_rec => l_prsncd_data_rec   -- �c�ƈ��Ǘ�(�t�@�C��)��񃏁[�N�e�[�u���f�[�^
          ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
--
        gn_normal_cnt   := gn_normal_cnt + 1;    -- ����Ώی���
--
      EXCEPTION
        WHEN error_skip_data_expt THEN
          -- �G���[�����J�E���g
          gn_error_cnt := gn_error_cnt + 1;
          -- �G���[�o��
          fnd_file.put_line(
          which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
          );
          -- �G���[���O�i�f�[�^���{�G���[���b�Z�[�W�j
          fnd_file.put_line(
            which  => FND_FILE.LOG
            ,buff   => lv_err_rec_info || ',' || lv_errbuf || CHR(10) ||
            ''
            );
          ov_retcode := cv_status_warn;
      END;
    END LOOP get_data_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE xrv_v_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- �����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_09             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE no_data_expt;
    END IF;
--
/* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
    -- ����ڕW�f�[�^�����J�n�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg14 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    -- =================================================
    -- A-9.����ڕW�f�[�^��������
    -- =================================================
    get_sum_sls_tgt_data(
       ov_errbuf          => lv_errbuf   -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode         => lv_retcode  -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg          => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sales_target_process_expt;
    END IF;
--
    -- ���ю擾�����J�n�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg16 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    -- =================================================
    -- A-10.����ڕW�f�[�^�擾�����i���т���j
    -- =================================================
    --�J�[�\���I�[�v��
    OPEN sales_exist_cur;
--
    <<get_sales_exista_loop>>
    LOOP 
      BEGIN
        FETCH sales_exist_cur INTO l_sum_cur_rec;
        EXIT WHEN sales_exist_cur%NOTFOUND;
--
        -- ���ғ������E�o�ߓ����̕ҏW
        l_sum_cur_rec.actual_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).actual_day_cnt;
        l_sum_cur_rec.passed_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).passed_day_cnt;
--
      EXCEPTION
        WHEN OTHERS THEN
          --���b�Z�[�W����
          lv_errmsg := SQLERRM;
          --�x���J�E���g
          gn_warn_cnt2 := 1;
          --�I�������O�o��
          gv_log_control_flag := 'Y';
          RAISE sales_target_process_expt;
      END;
--
      --------------------------------------
      -- A-11.���уf�[�^���[�N�e�[�u���i�[
      --------------------------------------
      ins_work_results(
         i_sales_target_rec => l_sum_cur_rec  -- ����ڕW���[�N�e�[�u��
        ,ov_errbuf          => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode         => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg          => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        --�I�������O�o��
        gv_log_control_flag := 'Y';
        RAISE sales_target_process_expt;
      END IF;
--
    END LOOP get_sales_exista_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE sales_exist_cur;
--
    -- �ڕW�̂ݎ擾�擾�����J�n�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg17 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    -- =================================================
    -- A-12.����ڕW�f�[�^�擾�����i�ڕW�̂݁j
    -- =================================================
    --������
    l_sum_cur_rec := NULL;
    --�J�[�\���I�[�v��
    OPEN target_only_cur;
--
    <<get_target_only_loop>>
    LOOP 
      BEGIN
        FETCH target_only_cur INTO l_sum_cur_rec;
        EXIT WHEN target_only_cur%NOTFOUND;
--
        -- ���ғ������E�o�ߓ����̕ҏW
        l_sum_cur_rec.actual_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).actual_day_cnt;
        l_sum_cur_rec.passed_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).passed_day_cnt;
--
      EXCEPTION
        WHEN OTHERS THEN
          --���b�Z�[�W����
          lv_errmsg := SQLERRM;
          --�x���J�E���g
          gn_warn_cnt2 := 1;
          --�I�������O�o��
          gv_log_control_flag := 'Y';
          RAISE sales_target_process_expt;
      END;
--
      --------------------------------------
      -- A-11.���уf�[�^���[�N�e�[�u���i�[
      --------------------------------------
      ins_work_results(
         i_sales_target_rec => l_sum_cur_rec  -- ����ڕW���[�N�e�[�u��
        ,ov_errbuf          => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode         => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg          => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        --�I�������O�o��
        gv_log_control_flag := 'Y';
        RAISE sales_target_process_expt;
      END IF;
--
    END LOOP get_target_only_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE target_only_cur;
--
    -- �����\���p�ڕW�̎擾�擾�����J�n�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg18 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    -- =================================================
    -- A-13.�����\���p�ڕW�f�[�^�擾����
    -- =================================================
    --������
    l_sum_cur_rec := NULL;
    --�J�[�\���I�[�v��
    OPEN target_start_cur;
--
    <<get_target_start_loop>>
    LOOP 
      BEGIN
        FETCH target_start_cur INTO l_sum_cur_rec;
        EXIT WHEN target_start_cur%NOTFOUND;
--
        -- ���ғ������E�o�ߓ����̕ҏW
        l_sum_cur_rec.actual_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).actual_day_cnt;
        l_sum_cur_rec.passed_day_cnt := g_date_cnt_tab(l_sum_cur_rec.target_month).passed_day_cnt;
--
      EXCEPTION
        WHEN OTHERS THEN
          --���b�Z�[�W����
          lv_errmsg := SQLERRM;
          --�x���J�E���g
          gn_warn_cnt2 := 1;
          --�I�������O�o��
          gv_log_control_flag := 'Y';
          RAISE sales_target_process_expt;
      END;
--
      --------------------------------------
      -- A-11.���уf�[�^���[�N�e�[�u���i�[
      --------------------------------------
      ins_work_results(
         i_sales_target_rec => l_sum_cur_rec  -- ����ڕW���[�N�e�[�u��
        ,ov_errbuf          => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode         => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg          => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE sales_target_process_expt;
      END IF;
--
    END LOOP get_target_start_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE target_start_cur;
--
    -- CSV�o�͏����J�n�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg19 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    --------------------------------------
    -- A-14.����ڕW�f�[�^CSV�o�͏���
    --------------------------------------
    --������
    l_prsncd_data_rec := NULL;
    --�J�[�\���I�[�v��
    OPEN sales_target_out_cur;
--
    <<sales_target_out_loop>>
    LOOP
      BEGIN
        FETCH sales_target_out_cur INTO l_output_cur_rec;
        EXIT WHEN sales_target_out_cur%NOTFOUND;
--
        --������
        l_prsncd_data_rec := NULL;
        --�Ώی����J�E���g
        gn_target_cnt2    := gn_target_cnt2 + 1;
--
        --CSV�t�@�C���o�͗p�ϐ��ɍ��ڂ��Z�b�g
        l_prsncd_data_rec.base_code        := l_output_cur_rec.base_code;                       --"0"(���_�i����j�R�[�h)
        l_prsncd_data_rec.employee_number  := l_output_cur_rec.employee_code;                   --�c�ƈ��R�[�h(�c�ƈ��R�[�h)
        l_prsncd_data_rec.pure_amount_sum  := l_output_cur_rec.sale_amount_month_sum;           --���ы��z(�����c�ƈ����ьv)
        l_prsncd_data_rec.sls_amt          := l_output_cur_rec.target_amount;                   --�ڕW���z(�����c�ƈ��m���}���z)
        l_prsncd_data_rec.sls_next_amt     := l_output_cur_rec.target_management_code;          --�ڕW�Ǘ����ڃR�[�h(�����c�ƈ��m���}���z)
        l_prsncd_data_rec.prsn_total_cnt   := l_output_cur_rec.target_month;                    --�N��(�����K�����)
        l_prsncd_data_rec.vis_amt          := l_output_cur_rec.actual_day_cnt;                  --��������(�����K��m���})
        l_prsncd_data_rec.vis_next_amt     := l_output_cur_rec.passed_day_cnt;                  --�o�ߓ���(�����K��m���})
        --�G���[���o�ׂ͂̈̃��b�Z�[�W�p���ڐݒ�
        gv_duty_cd                         := TO_CHAR(l_output_cur_rec.target_management_code);  --�ڕW�Ǘ����ڃR�[�h
        l_prsncd_data_rec.full_name        := l_output_cur_rec.output_month;                     --�Ώ۔N��
--
      EXCEPTION
        WHEN OTHERS THEN
          --���b�Z�[�W����
          lv_errmsg := SQLERRM;
          --�x���J�E���g
          gn_warn_cnt2 := 1;
          --�I�������O�o��
          gv_log_control_flag := 'Y';
          RAISE sales_target_process_expt;
      END;

      -- =================================================
      -- A-7.CSV�t�@�C���o�� 
      -- =================================================
      create_csv_rec(
         ir_prsncd_data_rec => l_prsncd_data_rec   -- ����ڕW���[�N�e�[�u���f�[�^
        ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      --���팏���J�E���g
      gn_normal_cnt2 := gn_normal_cnt2 + 1;
--
    END LOOP sales_target_out_loop;
--
    -- ����ڕW�f�[�^�����I�������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg15 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
                 ''
    );
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END */
--
  -- =====================================================
  -- A-8.CSV�t�@�C���N���[�Y
  -- =================================================
    close_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSV�t�@�C���o�͐�
      ,iv_csv_nm    => lv_csv_nm    -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^0����O�n���h�� ***
    WHEN no_data_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xrv_v_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xrv_v_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
    -- *** �c�ƈ��ʔ���ڕW������O�n���h�� ***
    WHEN sales_target_process_expt THEN
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_warn;
--
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xrv_v_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xrv_v_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xrv_v_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xrv_v_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xrv_v_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xrv_v_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2 )  --   ���^�[���E�R�[�h    --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� MOD START */
    cv_target_rec_msg2 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00652'; -- ����ڕW�����Ώی������b�Z�[�W
    cv_suc_rec_msg2    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00653'; -- ����ڕW���������������b�Z�[�W
    cv_warn_rec_msg2   CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00654'; -- ����ڕW�����x���������b�Z�[�W
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� MOD END   */
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� MOD START */
--    IF (lv_retcode = cv_status_error) THEN
    IF ( 
         ( lv_retcode = cv_status_error )
         OR
         ( gv_log_control_flag = 'Y' )
       ) THEN
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� MOD END */
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-15.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��(����ڕW�f�[�^����)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_target_rec_msg2
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt2)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���������o��(����ڕW�f�[�^����)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_suc_rec_msg2
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt2)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�x�������o��(����ڕW�f�[�^����)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_warn_rec_msg2
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt2)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD START */
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    /* 2013.05.13 K.Kiriu E_�{�ғ�_10735�Ή� ADD END   */
--
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;  
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg7 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO014A06C;
/
