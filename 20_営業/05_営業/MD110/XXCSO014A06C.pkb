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
 * Version          : 1.4
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
 *  submain                ���C�������v���V�[�W��
 *                           ���\�[�X�f�[�^�擾 (A-4)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-9)
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
  cv_object_cd           CONSTANT VARCHAR2(30)  := 'PARTY';          -- �\�[�X�R�[�h(�Œ�)
  cv_delete_flag         CONSTANT VARCHAR2(1)   := 'N';              -- �^�X�N�폜�t���O
  cv_owner_type_code     CONSTANT VARCHAR2(30)  := 'RS_EMPLOYEE';    -- �^�X�N�I�[�i�[�^�C�v
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
    lt_process_back_date   := gd_process_date - 1;              -- �Ɩ��������O��
    ld_process_date_next01 := TO_DATE(TO_CHAR(gd_process_date_next, 'YYYYMM') || '01', 'YYYY/MM/DD'); 
    ln__closed_id          := TO_NUMBER(gv_closed_id);
--
    -- �̔�����グ�r���[�A�ڋq�}�X�^�r���[����̔����ы��z�𒊏o����
    BEGIN
      SELECT  ROUND(SUM(sfpv.pure_amount)/1000) pure_amount_sum  -- �̔����ы��z(��~�P�ʂɎ擾)
        INTO  lt_pure_amount_sum                                 -- �̔����ы��z
        FROM  xxcso_sales_for_sls_prsn_v sfpv                    -- �c�ƈ��p������уr���[
             ,xxcso_resource_custs_v xrcv                        -- �c�ƈ��S���ڋq�r���[
       WHERE  sfpv.account_number   = xrcv.account_number
         AND  xrcv.employee_number  = l_prsncd_data_rec.employee_number
         AND  gd_process_date_next BETWEEN TRUNC(xrcv.start_date_active) 
                AND TRUNC(NVL(xrcv.end_date_active,gd_process_date_next))
         AND  TRUNC(sfpv.delivery_date) BETWEEN ld_process_date_next01
                AND lt_process_back_date;
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
                       ,iv_token_value3 => cv_duty_cd                           -- �E���R�[�h
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
                       ,iv_token_value3 => cv_duty_cd                           -- �E���R�[�h
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
                         ,iv_token_value2 => cv_duty_cd || cv_duty_cd_vl           -- �E���R�[�h 
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
                         ,iv_token_value2 => cv_duty_cd || cv_duty_cd_vl    -- �E���R�[�h                       
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
                       ,iv_token_value1 => cv_duty_cd                           -- �E���R�[�h
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
    -- *** ���[�J���ϐ� ***
    -- OUT�p�����[�^�i�[�p
    lv_csv_dir           VARCHAR2(2000); -- CSV�t�@�C���o�͐�
    lv_csv_nm            VARCHAR2(2000); -- CSV�t�@�C����
    lb_fopn_retcd        BOOLEAN;        -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lv_err_rec_info      VARCHAR2(5000); -- �f�[�^���ړ��e���b�Z�[�W�o�͗p
    lv_process_date_next VARCHAR2(150);  -- �f�[�^���ړ��e���b�Z�[�W�o�͗p 
    
--
-- *** ���[�J���E�J�[�\�� ***
    -- �c�ƈ��R�[�h�A���_�R�[�h�A���\�[�XID�̎擾���s���J�[�\���̒�`
    CURSOR xrv_v_cur
    IS
      SELECT  xrv.employee_number  employee_number  -- �c�ƈ��R�[�h
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
      FROM   xxcso_resources_v  xrv                  -- ���\�[�X�}�X�^�r���[
      WHERE (xrv.issue_date <= lv_process_date_next
              AND TRIM(xrv.duty_code_new) = cv_duty_cd
               OR lv_process_date_next    < xrv.issue_date
              AND TRIM(xrv.duty_code_old) = cv_duty_cd)
        AND gd_process_date_next BETWEEN TRUNC(xrv.start_date)
              AND TRUNC(NVL(xrv.end_date, gd_process_date_next)) 
        AND gd_process_date_next BETWEEN TRUNC(xrv.employee_start_date)
              AND TRUNC(NVL(xrv.employee_end_date,gd_process_date_next))
        AND gd_process_date_next BETWEEN TRUNC(xrv.assign_start_date)
              AND TRUNC(NVL(xrv.assign_end_date,gd_process_date_next))
        AND gd_process_date_next BETWEEN TRUNC(xrv.resource_start_date) 
              AND TRUNC(NVL(xrv.resource_end_date, gd_process_date_next));
--
    -- *** ���[�J���E���R�[�h ***
    l_xrv_v_cur_rec       xrv_v_cur%ROWTYPE;
    l_prsncd_data_rec     g_prsncd_data_rtype;
    -- *** ���[�J����O ***
    no_data_expt               EXCEPTION;
    error_skip_data_expt       EXCEPTION;
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
        -- =================================================
        -- A-5.CSV�t�@�C���ɏo�͂���֘A���擾
        -- =================================================
        get_sum_cnt_data(
           io_prsncd_data_rec => l_prsncd_data_rec   -- �c�ƈ��Ǘ�(�t�@�C��)��񃏁[�N�e�[�u���f�[�^
          ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
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
    IF (lv_retcode = cv_status_error) THEN
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
    -- A-9.�I������ 
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
