CREATE OR REPLACE PACKAGE BODY XXCOS016A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS016A03C(body)
 * Description      : �l���V�X�e�������A�̔����яܗ^�f�[�^(I/F)�쐬����
 * MD.050           : A03_�l���V�X�e�������̔����уf�[�^�̍쐬�i�����E�ܗ^�j COS_016_A03
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0)
 *  pra_chk                �p�����[�^�`�F�b�N(A-1)
 *  get_common_data        ���ʃf�[�^�擾(A-2)
 *  lock_table             ���b�N�e�[�u��(A-3)
 *  delete_table           �e�[�u���f�[�^�폜(A-3)
 *  get_sales_results_data �����̔����яW�v����(A-5)
 *  get_noruma_data        �����m���}�W�v����(A-6)
 *  get_point_data         �����l���|�C���g�W�v����(A-7)
 *  get_vender_data        �����l���x���_�[�W�v����(A-8)
 *  get_visit_data         �����K�⌏���W�v����(A-9)
 *  set_insert_data        �����E�ܗ^���ԃe�[�u���o�^����(A-10)
 *  small_group_total      ���O���[�v�W�v����(A-11)
 *  base_total             ���_�W�v����(A-12)
 *  area_total             �n��W�v����(A-13)
 *  div_total              �{���W�v����(A-14)
 *  sum_total              �S�ЏW�v����(A-15)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/20    1.0   T.kitajima       �V�K�쐬
 *  2009/02/05    1.1   T.kitajima       [COS_031]�A�g���ڂ̖{���R�[�h��6���Ή�
 *  2009/02/17    1.2   T.kitajima       get_msg�̃p�b�P�[�W���C��
 *  2009/02/24    1.3   T.kitajima       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/02/26    1.4   T.kitajima       �]�ƈ��r���[�̓K�p�������ݒ�
 *
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
  -- ���[�U�[��`��O
  -- ===============================
--
  global_chk_make_date_expt EXCEPTION;  --
  global_get_per_date_expt  EXCEPTION;  --
  global_lock_expt          EXCEPTION;  --���b�N
  global_delete_expt        EXCEPTION;  --�폜
  global_select_expt        EXCEPTION;  --���o
  global_common_expt        EXCEPTION;  --����
  global_insert_expt        EXCEPTION;  --�o�^
  global_update_expt        EXCEPTION;  --�X�V
  global_no_data_expt       EXCEPTION;  --�Ώۃf�[�^�O���G���[
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS016A03C';       -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  cv_current_appl_short_nm           fnd_application.application_short_name%TYPE
                                     :=  'XXCOS';                    --�̕��Z�k�A�v����
  --�̕����b�Z�[�W
  cv_msg_table_lock_err     CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00001';   --�e�[�u�����b�N�G���[���b�Z�[�W
  cv_msg_insert_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00010';   --�f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_get_update_err     CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00011';   --�f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_get_delete_err     CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00012';   --�f�[�^�폜�G���[���b�Z�[�W
  cv_msg_select_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00013';   --�f�[�^�擾�G���[���b�Z�[�W
  cv_msg_nodata_err         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00018';   --����0���p���b�Z�[�W
  cv_msg_chk_make_date_err  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13451';   --�쐬�N���̌^�Ⴂ���b�Z�[�W
  cv_msg_get_per_date_err   CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13452';   --��v���Ԏ擾�G���[
  cv_msg_pram_date          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13453';   --�p�����[�^���b�Z�[�W
  cv_msg_mem1_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13454';   --���ю҃R�[�h
  cv_msg_mem2_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13455';   --�{���R�[�h
  cv_msg_mem3_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13456';   --�G���A�R�[�h
  cv_msg_mem4_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13457';   --���_�R�[�h
  cv_msg_mem5_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13458';   --���O���[�v�R�[�h
  cv_msg_mem6_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13459';   --�̔����уe�[�u��
  cv_msg_mem7_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13460';   --�c�ƈ��ʌ��ʌv��Ǘ��e�[�u��
  cv_msg_mem8_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13461';   --�V�K�l���|�C���g�ڋq�ʗ����e�[�u��
  cv_msg_mem9_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13462';   --�ڋq�}�X�^�e�[�u��
  cv_msg_mem10_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13463';   --�c�Ɛ��ѕ\ ������яW�v�e�[�u��
  cv_msg_mem11_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13464';   --�c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u��
  cv_msg_mem12_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13465';   --�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u��
  cv_msg_mem13_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13466';   --�c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u��
  cv_msg_mem14_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13467';   --�l���V�X�e�������̔����сi�����j�e�[�u��
  cv_msg_mem15_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13468';   --�l���V�X�e�������̔����сi�ܗ^�j�e�[�u��
  cv_msg_mem16_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13469';   --�]�ƈ�view
  --�g�[�N��
  cv_tkn_table              CONSTANT VARCHAR2(10)  :=  'TABLE_NAME';       --�e�[�u������
  cb_tkn_table_on           CONSTANT VARCHAR2(10)  :=  'TABLE';            --�e�[�u������
  cv_tkn_key_data           CONSTANT VARCHAR2(10)  :=  'KEY_DATA';         --�L�[�f�[�^
  cv_tkn_parm_data          CONSTANT VARCHAR2(10)  :=  'PARAME1';          --�p�����[�^1
  --���b�Z�[�W�p������
  cv_str_result_cd          CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem1_data
                                                      ); --���ю҃R�[�h
  cv_str_div_nm             CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem2_data
                                                      ); --�{���R�[�h
  cv_str_area_nm            CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem3_data
                                                      ); --�G���A�R�[�h
  cv_str_base_nm            CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem4_data
                                                      ); --���_�R�[�h
  cv_str_group_nm           CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem5_data
                                                      ); --���O���[�v�R�[�h
  cv_str_sales_tbl          CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem6_data
                                                      ); --�̔����уe�[�u��
  cv_str_noruma_tbl         CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem7_data
                                                      ); --�c�ƈ��ʌ��ʌv��Ǘ��e�[�u��
  cv_str_point_tbl          CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem8_data
                                                      ); --�V�K�l���|�C���g�ڋq�ʗ����e�[�u��
  cv_str_customer_tbl       CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem9_data
                                                      ); --�ڋq�}�X�^�e�[�u��
  cv_str_bus_sales_tbl      CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem10_data
                                                      ); --�c�Ɛ��ѕ\ ������яW�v�e�[�u��
  cv_str_bus_new_tbl        CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem11_data
                                                      ); --�c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u��
  cv_str_bus_Pol_tbl        CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem12_data
                                                      ); --�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u��
  cv_str_bus_count_tbl      CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem13_data
                                                      ); --�c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u��
  cv_month_tbl              CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem14_data
                                                      ); --�l���V�X�e�������̔����сi�����j�e�[�u��
  cv_bonus_tbl              CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem15_data
                                                      ); --�l���V�X�e�������̔����сi�ܗ^�j�e�[�u��
  cv_employee_view          CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem16_data
                                                      ); --�]�ƈ�VIEW
  cv_format_yyyymm          CONSTANT VARCHAR2(7)   := 'YYYY/MM';                         -- ���t�t�H�[�}�b�g YYYY/MM
  cv_format_yyyymmdd        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                      -- ���t�t�H�[�}�b�g YYYY/MM/DD
  cv_month_tbl_name         CONSTANT VARCHAR2(36)  := 'XXCOS.XXCOS_FOR_ADPS_MONTHLY_IF';
  cv_bonus_tbl_name         CONSTANT VARCHAR2(36)  := 'XXCOS.XXCOS_FOR_ADPS_BONUS_IF';
  cv_sla                    CONSTANT VARCHAR2(1)   := '/';                               -- �X���b�V��
  cv_01                     CONSTANT VARCHAR2(2)   := '01';                              -- 01
  cn_1                      CONSTANT NUMBER        := 1;                                 -- 1
  cn_counter_class_4        CONSTANT NUMBER        := 4;                                 -- ���K�⌏��
  cn_counter_class_7        CONSTANT NUMBER        := 7;                                 -- �V�K����
  cn_counter_class_8        CONSTANT NUMBER        := 8;                                 -- �V�K�x���_�[����
  cn_number_class_9         CONSTANT NUMBER        := 9;                                 -- �V�K/�Y��|�C���g
  cn_number_class_11        CONSTANT NUMBER        := 11;                                -- ���i�|�C���g
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  /**********************************************************************************
   * Procedure Name   : is_date
   * Description      : ���t�`�F�b�N�p(A-1)
   ***********************************************************************************/
  PROCEDURE is_date(
    iv_date     IN OUT       VARCHAR2,     -- ���t
    iv_format   IN           VARCHAR2,     -- �t�H�[�}�b�g
    ov_errbuf   OUT NOCOPY   VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY   VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY   VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_date'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    ld_Date     DATE;  --�ϊ��p�ϐ�
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
   ld_Date := TO_DATE(iv_date, iv_format, q'{NLS_CALENDAR = 'GREGORIAN'}' );
   IF ( ld_Date IS NULL ) THEN
     RAISE global_api_others_expt;
   END IF;
--
   iv_date := TO_CHAR( ld_Date,iv_format );
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END is_date;
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_make_date  IN         VARCHAR2,     --   1.�쐬�N��
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
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
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --�p�����[�^���b�Z�[�W
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_current_appl_short_nm
                    ,iv_name         => cv_msg_pram_date
                    ,iv_token_name1  => cv_tkn_parm_data
                    ,iv_token_value1 => iv_make_date
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
  EXCEPTION
--##################  �Œ� EXCEPTION START ##########################################
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--##################      �Œ蕔   END     ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : pra_chk
   * Description      : �p���[���[�^�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE pra_chk(
    iv_make_date  IN OUT        VARCHAR2,     --   1.�쐬�N��
    ov_errbuf     OUT    NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pra_chk'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
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
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --1.�쐬�N���̓��̓`�F�b�N���s���܂��B
    --==============================================================
    IF ( iv_make_date IS NULL ) THEN
      -- �쐬�N����NULL�̏ꍇ�V�X�e�����t�̑O�����w�肷��B
      iv_make_date := TO_CHAR( ADD_MONTHS( SYSDATE,-1 ),cv_format_yyyymm );
        
    END IF;
    --==============================================================
    --2.�쐬�N�����͌`���̃`�F�b�N���s���܂��B
    --==============================================================
    is_date( iv_make_date
            ,cv_format_yyyymm
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
           );
    IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_chk_make_date_expt;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �쐬�N���̌^�Ⴂ���b�Z�[�W��O�n���h�� ***
    WHEN global_chk_make_date_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_chk_make_date_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;

--#################################  �Œ��O������ START   ###################################
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pra_chk;
--
  /**********************************************************************************
   * Procedure Name   : get_common_data
   * Description      : ���ʃf�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_common_data(
    id_base_date  IN         DATE,         --   �쐬�N��
    od_start_date OUT NOCOPY DATE,         --   ��v�J�n��
    od_ebd_date   OUT NOCOPY DATE,         --   ��v�I����
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_common_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info VARCHAR2(5000);  --key���
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================
    -- 1.��v����
    --==============================================
    --
    XXCOS_COMMON_PKG.get_period_year(
       id_base_date   -- �쐬�N��
      ,od_start_date  -- ��v�J�n��
      ,od_ebd_date    -- ��v�I����
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_get_per_date_expt;
    END IF;
    
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ��v���Ԏ擾�G���[��O�n���h�� ***
    WHEN global_get_per_date_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_get_per_date_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_common_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_table
   * Description      : �e�[�u���f�[�^�폜(A-3)
   ***********************************************************************************/
  PROCEDURE delete_table(
    iv_tabel_name IN         VARCHAR2,     --   �e�[�u����
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_table'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info VARCHAR2(5000);  --key���
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================
    -- �e�[�u���̍폜���s���܂��B
    --==============================================
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || iv_tabel_name;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  END delete_table;
--
  /**********************************************************************************
   * Procedure Name   : lock_table
   * Description      : �e�[�u�����b�N(A-3)
   ***********************************************************************************/
  PROCEDURE lock_table(
    iv_tabel_name IN         VARCHAR2,     --   �e�[�u����
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_table'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info VARCHAR2(5000);  --key���
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================
    -- �e�[�u���̃��b�N���s���܂��B
    --==============================================
    EXECUTE IMMEDIATE 'LOCK TABLE ' || iv_tabel_name || ' IN SHARE UPDATE MODE NOWAIT';
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END lock_table;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_results_data
   * Description      : �����̔����яW�v����(A-5)
   ***********************************************************************************/
  PROCEDURE get_sales_results_data(
    iv_person_code  IN          VARCHAR2,                                      --�]�ƈ��R�[�h
    iv_base_code    IN          VARCHAR2,                                      --���_�R�[�h
    id_this_date    IN          DATE,                                          --����1��
    id_next_date    IN          DATE,                                          --��������
    it_xxcos_for_adps_monthly_if IN OUT xxcos_for_adps_monthly_if%ROWTYPE,     --�����f�[�^
    it_xxcos_for_adps_bonus_if   IN OUT xxcos_for_adps_bonus_if%ROWTYPE,       --�ܗ^�f�[�^
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_results_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info     VARCHAR2(5000);  --key���
    ln_sales_money  NUMBER;          --������z
    ln_new_sales    NUMBER;          --�V�K�v������
    ln_gross_margin NUMBER;          --�v��e��
    lv_table_nm     VARCHAR2(50);    -- �e�[�u����
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================
    -- 1.������z���擾���܂��B
    -- 3.�v��e�����擾���܂��B
    --==============================================
    --
    BEGIN
      SELECT ROUND( NVL( SUM( sale_amount ),0 )/1000 ),
             NVL( SUM( sale_amount-business_cost ),0 )
      INTO   it_xxcos_for_adps_monthly_if.p_sale_amount,
             it_xxcos_for_adps_bonus_if.p_sale_gross
      FROM   xxcos_rep_bus_s_group_sum
      WHERE  results_employee_code = iv_person_code
        AND  sale_base_code        = iv_base_code
        AND  dlv_date BETWEEN id_this_date AND id_next_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        xxcos_common_pkg.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                      ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                      ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                      ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                      ,iv_item_name1  =>  cv_str_result_cd
                                      ,iv_item_name2  =>  cv_str_base_nm
                                      ,iv_data_value1 =>  iv_person_code
                                      ,iv_data_value2 =>  iv_base_code
                                     );
        IF ( lv_retcode = cv_status_normal ) THEN
          lv_table_nm := cv_str_bus_Pol_tbl;
          RAISE global_select_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
    END;
    --==============================================
    -- 2.�V�K�v��������擾���܂��B
    --==============================================
    BEGIN
      SELECT ROUND( NVL( SUM( sale_amount ),0 )/1000 )
      INTO it_xxcos_for_adps_monthly_if.p_new_contribution_sale
      FROM xxcos_rep_bus_newcust_sum
      WHERE results_employee_code = iv_person_code
        AND sale_base_code        = iv_base_code
        AND dlv_date BETWEEN id_this_date AND id_next_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        XXCOS_COMMON_PKG.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                      ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                      ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                      ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                      ,iv_item_name1  =>  cv_str_result_cd
                                      ,iv_item_name2  =>  cv_str_base_nm
                                      ,iv_data_value1 =>  iv_person_code
                                      ,iv_data_value2 =>  iv_base_code
                                     );
        IF ( lv_retcode = cv_status_normal ) THEN
          lv_table_nm := cv_str_bus_new_tbl;
          RAISE global_select_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
    END;
    --==============================================
    -- 4.�v�㗘�v���擾���܂��B
    --==============================================
    NULL;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_select_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_select_data_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sales_results_data;
--
  /**********************************************************************************
   * Procedure Name   : get_noruma_data
   * Description      : �����m���}�W�v����(A-6)
   ***********************************************************************************/
  PROCEDURE get_noruma_data(
    iv_person_code               IN            VARCHAR2,                   --�]�ƈ��R�[�h
    iv_base_code                 IN            VARCHAR2,                   --���_�R�[�h
    it_xxcos_for_adps_monthly_if IN OUT xxcos_for_adps_monthly_if%ROWTYPE, --�f�[�^
    ov_errbuf                    OUT    NOCOPY VARCHAR2,                   --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                   OUT    NOCOPY VARCHAR2,                   --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                    OUT    NOCOPY VARCHAR2)                   --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_noruma_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info     VARCHAR2(5000);  --key���
    ln_sales_money  NUMBER;          --������z
    ln_new_sales    NUMBER;          --�V�K�v������
    ln_gross_margin NUMBER;          --�v��e��
    ln_cnt          NUMBER;          --�J�E���g
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================
    -- 1.����m���}���z���擾���܂��B
    --==============================================
    BEGIN
      SELECT NVL( bsc_sls_prsn_total_amt,0 )
      INTO   it_xxcos_for_adps_monthly_if.p_sale_norma
      FROM   xxcso_sls_prsn_mnthly_plns
      WHERE  employee_number = iv_person_code
        AND  base_code       = iv_base_code
        AND  year_month      = it_xxcos_for_adps_monthly_if.results_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_monthly_if.p_sale_norma := 0;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_noruma_data;
--
  /**********************************************************************************
   * Procedure Name   : get_point_data
   * Description      : �����l���|�C���g�W�v����(A-7)
   ***********************************************************************************/
  PROCEDURE get_point_data(
    iv_person_code               IN            VARCHAR2,                   --�]�ƈ��R�[�h
    iv_base_code                 IN            VARCHAR2,                   --���_�R�[�h
    id_this_date                 IN            DATE,                       --����1��
    id_next_date                 IN            DATE,                       --��������
    it_xxcos_for_adps_monthly_if IN OUT xxcos_for_adps_monthly_if%ROWTYPE, --�f�[�^
    ov_errbuf                    OUT    NOCOPY VARCHAR2,                   --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                   OUT    NOCOPY VARCHAR2,                   --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                    OUT    NOCOPY VARCHAR2)                   --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_point_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_point_1_id          CONSTANT NUMBER      := 1; -- �V�K�|�C���g
    cv_point_0_id          CONSTANT NUMBER      := 0; -- ���i�|�C���g
    cv_evaluation_0_id     CONSTANT VARCHAR2(1) := 0; -- �]���B��
    -- *** ���[�J���ϐ� ***
--
    lv_key_info     VARCHAR2(5000);  --key���
    ln_sales_money  NUMBER;          --������z
    ln_new_sales    NUMBER;          --�V�K�v������
    ln_gross_margin NUMBER;          --�v��e��
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================
    -- 1.�V�K�|�C���g���擾���܂��B
    --==============================================
    --
    BEGIN
      SELECT rbcs.counter
        INTO it_xxcos_for_adps_monthly_if.p_new_point
        FROM xxcos_rep_bus_count_sum rbcs
       WHERE rbcs.target_date   = it_xxcos_for_adps_monthly_if.results_date
         AND rbcs.base_code     = iv_base_code
         AND rbcs.employee_num  = iv_person_code
         AND rbcs.counter_class = cn_number_class_9
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_monthly_if.p_new_point := 0;
    END;
--
    --==============================================
    -- 2.���i�|�C���g���擾���܂��B
    --==============================================
    BEGIN
      SELECT rbcs.counter
        INTO it_xxcos_for_adps_monthly_if.p_position_point
        FROM xxcos_rep_bus_count_sum rbcs
       WHERE rbcs.target_date   = it_xxcos_for_adps_monthly_if.results_date
         AND rbcs.base_code     = iv_base_code
         AND rbcs.employee_num  = iv_person_code
         AND rbcs.counter_class = cn_number_class_11
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_monthly_if.p_position_point := 0;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_point_data;
--
  /**********************************************************************************
   * Procedure Name   : get_vender_data
   * Description      : �����l���x���_�[�W�v����(A-8)
   ***********************************************************************************/
  PROCEDURE get_vender_data(
    iv_person_code               IN     VARCHAR2,                          --�]�ƈ��R�[�h
    iv_base_code                 IN     VARCHAR2,                          --���_�R�[�h
    it_xxcos_for_adps_monthly_if IN OUT xxcos_for_adps_monthly_if%ROWTYPE, --�f�[�^
    ov_errbuf                    OUT    VARCHAR2,                          --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                   OUT    VARCHAR2,                          --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                    OUT    VARCHAR2)                          --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_vender_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info     VARCHAR2(5000);  --key���
    ln_sales_money  NUMBER;          --������z
    ln_new_sales    NUMBER;          --�V�K�v������
    ln_gross_margin NUMBER;          --�v��e��
    ln_cnt          NUMBER;          --�J�E���g
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================
    -- 1.�V�K�������擾���܂��B
    --==============================================
    BEGIN
      SELECT NVL( COUNTER,0 )
      INTO it_xxcos_for_adps_monthly_if.p_new_count_sum
      FROM xxcos_rep_bus_count_sum
      WHERE employee_num  = iv_person_code
        AND base_code     = iv_base_code
        AND target_date   = it_xxcos_for_adps_monthly_if.results_date
        AND counter_class = cn_counter_class_7
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_monthly_if.p_new_count_sum := 0;
    END;
    --==============================================
    -- 2.�V�K�x���_�[�������擾���܂��B
    --==============================================
    BEGIN
      SELECT NVL( COUNTER,0 )
      INTO it_xxcos_for_adps_monthly_if.p_new_count_vd
      FROM xxcos_rep_bus_count_sum
      WHERE employee_num  = iv_person_code
        AND base_code     = iv_base_code
        AND target_date   = it_xxcos_for_adps_monthly_if.results_date
        AND counter_class = cn_counter_class_8
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_monthly_if.p_new_count_vd := 0;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_vender_data;
--
  /**********************************************************************************
   * Procedure Name   : get_visit_data
   * Description      : �����K�⌏���W�v����(A-9)
   ***********************************************************************************/
  PROCEDURE get_visit_data(
    iv_person_code             IN     VARCHAR2,                        --�]�ƈ��R�[�h
    iv_base_code               IN     VARCHAR2,                        --���_�R�[�h
    it_xxcos_for_adps_bonus_if IN OUT xxcos_for_adps_bonus_if%ROWTYPE, --�ܗ^�f�[�^
    ov_errbuf                  OUT    VARCHAR2,                        --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT    VARCHAR2,                        --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT    VARCHAR2)                        --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_visit_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info     VARCHAR2(5000);  --key���
    ln_sales_money  NUMBER;          --������z
    ln_new_sales    NUMBER;          --�V�K�v������
    ln_gross_margin NUMBER;          --�v��e��
    ln_cnt          NUMBER;          --�J�E���g
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================
    -- 1.�����̖K�⌏�����W�v���܂��B
    --==============================================
    --
    BEGIN
      SELECT NVL( COUNTER,0 )
      INTO it_xxcos_for_adps_bonus_if.p_visit_count
      FROM xxcos_rep_bus_count_sum
      WHERE employee_num  = iv_person_code
        AND base_code     = iv_base_code
        AND target_date   = it_xxcos_for_adps_bonus_if.results_date
        AND counter_class = cn_counter_class_4
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_bonus_if.p_visit_count := 0;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : set_insert_data
   * Description      : �����̔����яW�v����(A-10)
   ***********************************************************************************/
  PROCEDURE set_insert_data(
    it_xxcos_for_adps_monthly_if IN OUT xxcos_for_adps_monthly_if%ROWTYPE, --�����f�[�^
    it_xxcos_for_adps_bonus_if   IN OUT xxcos_for_adps_bonus_if%ROWTYPE,   --�ܗ^�f�[�^
    ov_errbuf                    OUT    NOCOPY VARCHAR2,                   --�G���[�E���b�Z�[�W        -# �Œ� #
    ov_retcode                   OUT    NOCOPY VARCHAR2,                   --���^�[���E�R�[�h          -# �Œ� #
    ov_errmsg                    OUT    NOCOPY VARCHAR2)                   --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_insert_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info     VARCHAR2(5000);  --key���
    ln_sales_money  NUMBER;          --������z
    ln_new_sales    NUMBER;          --�V�K�v������
    ln_gross_margin NUMBER;          --�v��e��
    lv_table_nm     VARCHAR2(50);    -- �e�[�u����
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================
    -- 1.�l���V�X�e�������̔����сi�����j�e�[�u����o�^���܂��B
    --==============================================
    BEGIN
      INSERT INTO xxcos_for_adps_monthly_if
        (
          record_id,
          employee_code,
          results_date,
          group_code,
          base_code,
          area_code,
          division_code,
          p_sale_norma,
          p_sale_amount,
          p_sale_achievement_rate,
          p_new_contribution_sale,
          p_new_norma,
          p_new_achievement_rate,
          p_new_count_sum,
          p_new_count_vd,
          p_position_point,
          p_new_point,
          g_sale_norma,
          g_sale_amount,
          g_sale_achievement_rate,
          g_new_contribution_sale,
          g_new_norma,
          g_new_achievement_rate,
          g_new_count_sum,
          g_new_count_vd,
          g_position_point,
          g_new_point,
          b_sale_norma,
          b_sale_amount,
          b_sale_achievement_rate,
          b_new_contribution_sale,
          b_new_norma,
          b_new_achievement_rate,
          b_new_count_sum,
          b_new_count_vd,
          b_position_point,
          b_new_point,
          a_sale_norma,
          a_sale_amount,
          a_sale_achievement_rate,
          a_new_contribution_sale,
          a_new_norma,
          a_new_achievement_rate,
          a_new_count_sum,
          a_new_count_vd,
          a_position_point,
          a_new_point,
          d_sale_norma,
          d_sale_amount,
          d_sale_achievement_rate,
          d_new_contribution_sale,
          d_new_norma,
          d_new_achievement_rate,
          d_new_count_sum,
          d_new_count_vd,
          d_position_point,
          d_new_point,
          s_sale_norma,
          s_sale_amount,
          s_sale_achievement_rate,
          s_new_contribution_sale,
          s_new_norma,
          s_new_achievement_rate,
          s_new_count_sum,
          s_new_count_vd,
          s_position_point,
          s_new_point,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          last_update_login,
          request_id,
          program_application_id,
          program_id,
          program_update_date
        )
      VALUES
        (
          xxcos_for_adps_monthly_if_s01.nextval,                   -- ���R�[�hID
          it_xxcos_for_adps_monthly_if.employee_code,              -- �]�ƈ��R�[�h
          it_xxcos_for_adps_monthly_if.results_date,               -- �N��
          it_xxcos_for_adps_monthly_if.group_code,                 -- ���O���[�v�R�[�h
          it_xxcos_for_adps_monthly_if.base_code,                  -- ���_����
          it_xxcos_for_adps_monthly_if.area_code,                  -- �n��R�[�h
          it_xxcos_for_adps_monthly_if.division_code,              -- �{������
          it_xxcos_for_adps_monthly_if.p_sale_norma,               -- �������
          it_xxcos_for_adps_monthly_if.p_sale_amount,              -- ������z
          it_xxcos_for_adps_monthly_if.p_sale_achievement_rate,    -- ����B����
          it_xxcos_for_adps_monthly_if.p_new_contribution_sale,    -- �V�K�v������
          it_xxcos_for_adps_monthly_if.p_new_norma,                -- �V�K���
          it_xxcos_for_adps_monthly_if.p_new_achievement_rate,     -- �V�K�B����
          it_xxcos_for_adps_monthly_if.p_new_count_sum,            -- �V�K�������v
          it_xxcos_for_adps_monthly_if.p_new_count_vd,             -- �V�K��������ް
          it_xxcos_for_adps_monthly_if.p_position_point,           -- ���iPOINT
          it_xxcos_for_adps_monthly_if.p_new_point,                -- �V�KPOINT
          it_xxcos_for_adps_monthly_if.g_sale_norma,               -- ���������
          it_xxcos_for_adps_monthly_if.g_sale_amount,              -- ��������z
          it_xxcos_for_adps_monthly_if.g_sale_achievement_rate,    -- ������B����
          it_xxcos_for_adps_monthly_if.g_new_contribution_sale,    -- ���V�K�v������
          it_xxcos_for_adps_monthly_if.g_new_norma,                -- ���V�K���
          it_xxcos_for_adps_monthly_if.g_new_achievement_rate,     -- ���V�K�B����
          it_xxcos_for_adps_monthly_if.g_new_count_sum,            -- ���V�K�������v
          it_xxcos_for_adps_monthly_if.g_new_count_vd,             -- ���V�K��������ް
          it_xxcos_for_adps_monthly_if.g_position_point,           -- �����iPOINT
          it_xxcos_for_adps_monthly_if.g_new_point,                -- ���V�KPOINT
          it_xxcos_for_adps_monthly_if.b_sale_norma,               -- ���������
          it_xxcos_for_adps_monthly_if.b_sale_amount,              -- ��������z
          it_xxcos_for_adps_monthly_if.b_sale_achievement_rate,    -- ������B����
          it_xxcos_for_adps_monthly_if.b_new_contribution_sale,    -- ���V�K�v������
          it_xxcos_for_adps_monthly_if.b_new_norma,                -- ���V�K�B����
          it_xxcos_for_adps_monthly_if.b_new_achievement_rate,     -- ���V�K���
          it_xxcos_for_adps_monthly_if.b_new_count_sum,            -- ���V�K�������v
          it_xxcos_for_adps_monthly_if.b_new_count_vd,             -- ���V�K��������ް
          it_xxcos_for_adps_monthly_if.b_position_point,           -- �����iPOINT
          it_xxcos_for_adps_monthly_if.b_new_point,                -- ���V�KPOINT
          it_xxcos_for_adps_monthly_if.a_sale_norma,               -- �n�������
          it_xxcos_for_adps_monthly_if.a_sale_amount,              -- �n������z
          it_xxcos_for_adps_monthly_if.a_sale_achievement_rate,    -- �n����B����
          it_xxcos_for_adps_monthly_if.a_new_contribution_sale,    -- �n�V�K�v������
          it_xxcos_for_adps_monthly_if.a_new_norma,                -- �n�V�K�B����
          it_xxcos_for_adps_monthly_if.a_new_achievement_rate,     -- �n�V�K���
          it_xxcos_for_adps_monthly_if.a_new_count_sum,            -- �n�V�K�������v
          it_xxcos_for_adps_monthly_if.a_new_count_vd,             -- �n�V�K��������ް
          it_xxcos_for_adps_monthly_if.a_position_point,           -- �n���iPOINT
          it_xxcos_for_adps_monthly_if.a_new_point,                -- �n�V�KPOINT
          it_xxcos_for_adps_monthly_if.d_sale_norma,               -- �{�������
          it_xxcos_for_adps_monthly_if.d_sale_amount,              -- �{������z
          it_xxcos_for_adps_monthly_if.d_sale_achievement_rate,    -- �{����B����
          it_xxcos_for_adps_monthly_if.d_new_contribution_sale,    -- �{�V�K�v������
          it_xxcos_for_adps_monthly_if.d_new_norma,                -- �{�V�K�B����
          it_xxcos_for_adps_monthly_if.d_new_achievement_rate,     -- �{�V�K���
          it_xxcos_for_adps_monthly_if.d_new_count_sum,            -- �{�V�K�������v
          it_xxcos_for_adps_monthly_if.d_new_count_vd,             -- �{�V�K��������ް
          it_xxcos_for_adps_monthly_if.d_position_point,           -- �{���iPOINT
          it_xxcos_for_adps_monthly_if.d_new_point,                -- �{�V�KPOINT
          it_xxcos_for_adps_monthly_if.s_sale_norma,               -- �S�������
          it_xxcos_for_adps_monthly_if.s_sale_amount,              -- �S������z
          it_xxcos_for_adps_monthly_if.s_sale_achievement_rate,    -- �S����B����
          it_xxcos_for_adps_monthly_if.s_new_contribution_sale,    -- �S�V�K�v������
          it_xxcos_for_adps_monthly_if.s_new_norma,                -- �S�V�K�B����
          it_xxcos_for_adps_monthly_if.s_new_achievement_rate,     -- �S�V�K���
          it_xxcos_for_adps_monthly_if.s_new_count_sum,            -- �S�V�K�������v
          it_xxcos_for_adps_monthly_if.s_new_count_vd,             -- �S�V�K��������ް
          it_xxcos_for_adps_monthly_if.s_position_point,           -- �S���iPOINT
          it_xxcos_for_adps_monthly_if.s_new_point,                -- �S�V�KPOINT
          cn_created_by,                                           -- �쐬��
          cd_creation_date,                                        -- �쐬��
          cn_last_updated_by,                                      -- �ŏI�X�V��
          cd_last_update_date,                                     -- �ŏI�X�V��
          cn_last_update_login,                                    -- �ŏI�X�V���O�C��
          cn_request_id,                                           -- �v��ID
          cn_program_application_id,                               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id,                                           -- �R���J�����g�E�v���O����ID
          cd_program_update_date                                   -- �v���O�����X�V��
        );
    EXCEPTION
      WHEN OTHERS THEN
        XXCOS_COMMON_PKG.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                      ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                      ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                      ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                      ,iv_item_name1  =>  cv_str_result_cd
                                      ,iv_item_name2  =>  cv_str_base_nm
                                      ,iv_data_value1 =>  it_xxcos_for_adps_monthly_if.employee_code
                                      ,iv_data_value2 =>  it_xxcos_for_adps_monthly_if.base_code
                                     );
        IF ( lv_retcode = cv_status_normal ) THEN
          lv_table_nm := cv_month_tbl;
          RAISE global_insert_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
    END;
    --==============================================
    -- 2. �l���V�X�e�������̔����сi�ܗ^�j�e�[�u����o�^���܂��B
    --==============================================
    BEGIN
      INSERT INTO xxcos_for_adps_bonus_if
        (
          record_id,
          employee_code,
          results_date,
          group_code,
          base_code,
          area_code,
          division_code,
          p_sale_gross,
          p_current_profit,
          p_visit_count,
          g_sale_gross,
          g_current_profit,
          g_visit_count,
          b_sale_gross,
          b_current_profit,
          b_visit_count,
          a_sale_gross,
          a_current_profit,
          a_visit_count,
          d_sale_gross,
          d_current_profit,
          d_visit_count,
          s_sale_gross,
          s_current_profit,
          s_visit_count,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          last_update_login,
          request_id,
          program_application_id,
          program_id,
          program_update_date
        )
      VALUES
        (
          xxcos_for_adps_monthly_if_s01.nextval,                   -- ���R�[�hID
          it_xxcos_for_adps_bonus_if.employee_code,                -- �]�ƈ��R�[�h
          it_xxcos_for_adps_bonus_if.results_date,                 -- �N��
          it_xxcos_for_adps_bonus_if.group_code,                   -- ���O���[�v�R�[�h
          it_xxcos_for_adps_bonus_if.base_code,                    -- ���_����
          it_xxcos_for_adps_bonus_if.area_code,                    -- �n��R�[�h
          it_xxcos_for_adps_bonus_if.division_code,                -- �{������
          it_xxcos_for_adps_bonus_if.p_sale_gross,                 -- ����e��
          it_xxcos_for_adps_bonus_if.p_current_profit,             -- �o�험�v
          it_xxcos_for_adps_bonus_if.p_visit_count,                -- �K�⌏��
          it_xxcos_for_adps_bonus_if.g_sale_gross,                 -- ������e��
          it_xxcos_for_adps_bonus_if.g_current_profit,             -- ���o�험�v
          it_xxcos_for_adps_bonus_if.g_visit_count,                -- ���K�⌏��
          it_xxcos_for_adps_bonus_if.b_sale_gross,                 -- ������e��
          it_xxcos_for_adps_bonus_if.b_current_profit,             -- ���o�험�v
          it_xxcos_for_adps_bonus_if.b_visit_count,                -- ���K�⌏��
          it_xxcos_for_adps_bonus_if.a_sale_gross,                 -- �n����e��
          it_xxcos_for_adps_bonus_if.a_current_profit,             -- �n�o�험�v
          it_xxcos_for_adps_bonus_if.a_visit_count,                -- �n�K�⌏��
          it_xxcos_for_adps_bonus_if.d_sale_gross,                 -- �{����e��
          it_xxcos_for_adps_bonus_if.d_current_profit,             -- �{�o�험�v
          it_xxcos_for_adps_bonus_if.d_visit_count,                -- �{�K�⌏��
          it_xxcos_for_adps_bonus_if.s_sale_gross,                 -- �S����e��
          it_xxcos_for_adps_bonus_if.s_current_profit,             -- �S�o�험�v
          it_xxcos_for_adps_bonus_if.s_visit_count,                -- �S�K�⌏��
          cn_created_by,                                           -- �쐬��
          cd_creation_date,                                        -- �쐬��
          cn_last_updated_by,                                      -- �ŏI�X�V��
          cd_last_update_date,                                     -- �ŏI�X�V��
          cn_last_update_login,                                    -- �ŏI�X�V���O�C��
          cn_request_id,                                           -- �v��ID
          cn_program_application_id,                               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id,                                           -- �R���J�����g�E�v���O����ID
          cd_program_update_date                                   -- �v���O�����X�V��
        );
    EXCEPTION
      WHEN OTHERS THEN
        XXCOS_COMMON_PKG.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                      ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                      ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                      ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                      ,iv_item_name1  =>  cv_str_result_cd
                                      ,iv_item_name2  =>  cv_str_base_nm
                                      ,iv_data_value1 =>  it_xxcos_for_adps_bonus_if.employee_code
                                      ,iv_data_value2 =>  it_xxcos_for_adps_bonus_if.base_code
                                     );
        IF ( lv_retcode = cv_status_normal ) THEN
          lv_table_nm :=cv_bonus_tbl;
          RAISE global_insert_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --�o�^��O
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_insert_data_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_insert_data;
--
  /**********************************************************************************
   * Procedure Name   : small_group_total
   * Description      : ���O���[�v�W�v����(A-11)
   ***********************************************************************************/
  PROCEDURE small_group_total(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'small_group_total'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info     VARCHAR2(5000);  --key���
    ln_sales_money  NUMBER;          --������z
    ln_new_sales    NUMBER;          --�V�K�v������
    ln_gross_margin NUMBER;          --�v��e��
    lv_table_nm     VARCHAR2(50);    -- �e�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
    --==============================================
    -- 1.�����e�[�u���̏��O���[�v���W�v���܂��B
    --==============================================
    CURSOR month_data_cur
    IS
      SELECT base_code                                             as base_code,
             group_code                                            as group_code,
             SUM( p_sale_norma )                                   as sale_norma,
             SUM( p_sale_amount )                                  as sale_amount,
             CASE SUM( p_sale_norma )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_sale_amount ) / SUM( p_sale_norma ) * 100 ,1 )   
             END                                                   as sale_rate,
             SUM( p_new_contribution_sale )                        as new_contribution_sale,
             SUM( p_new_norma )                                    as new_norma,
             CASE SUM( p_position_point )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_new_point ) / SUM( p_position_point ) * 100 ,1 )
             END                                                   as new_point_rate,
             SUM( p_new_count_sum )                                as new_count_sum,
             SUM( p_new_count_vd )                                 as new_count_vd,
             SUM( p_position_point )                               as position_point,
             SUM( p_new_point )                                    as new_point
      FROM xxcos_for_adps_monthly_if
      WHERE group_code IS NOT NULL
      GROUP BY base_code,group_code
      ;
    --==============================================
    -- 3.�ܗ^�e�[�u���̏��O���[�v���W�v���܂��B
    --==============================================
    CURSOR bonus_data_cur
    IS
      SELECT base_code                                             as base_code,
             group_code                                            as group_code,
             SUM( p_sale_gross )                                   as sale_gross,
             SUM( p_current_profit )                               as current_profit,
             SUM( p_visit_count )                                  as visit_count
      FROM xxcos_for_adps_bonus_if
      WHERE group_code IS NOT NULL
      GROUP BY base_code,group_code
      ;
    -- *** ���[�J���E���R�[�h ***
--
    l_month_data_rec               month_data_cur%ROWTYPE;
    l_bonus_data_rec               bonus_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --2.�����e�[�u���̏��O���[�v�W�v���ʂ��X�V���܂��B
    --==============================================================
    <<for_month_loop>>
    FOR l_month_data_rec IN month_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_monthly_if
        SET g_sale_norma            = l_month_data_rec.sale_norma,
            g_sale_amount           = l_month_data_rec.sale_amount,
            g_sale_achievement_rate = l_month_data_rec.sale_rate,
            g_new_contribution_sale = l_month_data_rec.new_contribution_sale,
            g_new_norma             = l_month_data_rec.new_norma,
            g_new_achievement_rate  = l_month_data_rec.new_point_rate,
            g_new_count_sum         = l_month_data_rec.new_count_sum,
            g_new_count_vd          = l_month_data_rec.new_count_vd,
            g_position_point        = l_month_data_rec.position_point,
            g_new_point             = l_month_data_rec.new_point
        WHERE base_code  = l_month_data_rec.base_code
          AND group_code = l_month_data_rec.group_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  cv_str_base_nm
                                        ,iv_item_name2  =>  cv_str_group_nm
                                        ,iv_data_value1 =>  l_month_data_rec.base_code
                                        ,iv_data_value2 =>  l_month_data_rec.group_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm := cv_month_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_month_loop;
--  --==============================================================
    --4.�ܗ^�e�[�u���̏��O���[�v�W�v���ʂ��X�V���܂��B
    --==============================================================
    <<for_bonus_loop>>
    FOR l_bonus_data_rec IN bonus_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_bonus_if
        SET g_sale_gross            = l_bonus_data_rec.sale_gross,
            g_current_profit        = l_bonus_data_rec.current_profit,
            g_visit_count           = l_bonus_data_rec.visit_count
        WHERE base_code  = l_bonus_data_rec.base_code
          AND group_code = l_bonus_data_rec.group_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  cv_str_base_nm
                                        ,iv_item_name2  =>  cv_str_group_nm
                                        ,iv_data_value1 =>  l_bonus_data_rec.base_code
                                        ,iv_data_value2 =>  l_bonus_data_rec.group_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm := cv_bonus_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_bonus_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- �X�V��O
    WHEN global_update_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_get_update_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END small_group_total;
--
  /**********************************************************************************
   * Procedure Name   : base_total
   * Description      : ���_�W�v����(A-12)
   ***********************************************************************************/
  PROCEDURE base_total(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'base_total'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info     VARCHAR2(5000);  --key���
    ln_sales_money  NUMBER;          --������z
    ln_new_sales    NUMBER;          --�V�K�v������
    ln_gross_margin NUMBER;          --�v��e��
    lv_table_nm     VARCHAR2(50);    -- �e�[�u����
    -- *** ���[�J���E�J�[�\�� ***
--
    --==============================================
    -- 1.�����e�[�u���̋��_���W�v���܂��B
    --==============================================
    CURSOR month_data_cur
    IS
      SELECT base_code                                             as base_code,
             SUM( p_sale_norma )                                   as sale_norma,
             SUM( p_sale_amount )                                  as sale_amount,
             CASE SUM( p_sale_norma )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_sale_amount )/SUM( p_sale_norma )*100,1 )   
             END                                                   as sale_rate,
             SUM( p_new_contribution_sale )                        as new_contribution_sale,
             SUM( p_new_norma )                                    as new_norma,
             CASE SUM( p_position_point )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_new_point )/SUM( p_position_point )*100,1 )
             END                                                   as new_point_rate,
             SUM( p_new_count_sum )                                as new_count_sum,
             SUM( p_new_count_vd )                                 as new_count_vd,
             SUM( p_position_point )                               as position_point,
             SUM( p_new_point )                                    as new_point
      FROM xxcos_for_adps_monthly_if
      GROUP BY base_code
      ;
    --==============================================
    -- 4.�ܗ^�e�[�u���̋��_���W�v���܂��B
    --==============================================
    CURSOR bonus_data_cur
    IS
      SELECT base_code                                             as base_code,
             SUM( p_sale_gross )                                   as sale_gross,
             SUM( p_current_profit )                               as current_profit,
             SUM( p_visit_count )                                  as visit_count
      FROM xxcos_for_adps_bonus_if
      GROUP BY base_code
      ;
    -- *** ���[�J���E���R�[�h ***
    l_month_data_rec               month_data_cur%ROWTYPE;
    l_bonus_data_rec               bonus_data_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --����
    <<for_month_loop>>
    FOR l_month_data_rec IN month_data_cur LOOP
      BEGIN
        --==============================================================
        --2.�����e�[�u���̋��_�W�v���ʂ��X�V���܂��B
        --==============================================================
        UPDATE xxcos_for_adps_monthly_if
        SET b_sale_norma            = l_month_data_rec.sale_norma,
            b_sale_amount           = l_month_data_rec.sale_amount,
            b_sale_achievement_rate = l_month_data_rec.sale_rate,
            b_new_contribution_sale = l_month_data_rec.new_contribution_sale,
            b_new_norma             = l_month_data_rec.new_norma,
            b_new_achievement_rate  = l_month_data_rec.new_point_rate,
            b_new_count_sum         = l_month_data_rec.new_count_sum,
            b_new_count_vd          = l_month_data_rec.new_count_vd,
            b_position_point        = l_month_data_rec.position_point,
            b_new_point             = l_month_data_rec.new_point
        WHERE base_code  = l_month_data_rec.base_code
        ;
        --�ۗ�
        --==============================================================
        --3.�����e�[�u���̋��_�W�v���ʂ����O���[�v�ɍX�V���܂��B
        --==============================================================
--        UPDATE xxcos_for_adps_monthly_if
--        SET g_sale_norma            = l_month_data_rec.sale_norma,
--            g_sale_amount           = l_month_data_rec.sale_amount,
--            g_sale_achievement_rate = l_month_data_rec.sale_rate,
--            g_new_contribution_sale = l_month_data_rec.new_contribution_sale,
--            g_new_norma             = l_month_data_rec.new_norma,
--            g_new_achievement_rate  = l_month_data_rec.new_point_rate,
--            g_new_count_sum         = l_month_data_rec.new_count_sum,
--            g_new_count_vd          = l_month_data_rec.new_count_vd,
--            g_position_point        = l_month_data_rec.position_point,
--            g_new_point             = l_month_data_rec.new_point
--        WHERE base_code  = l_month_data_rec.base_code
--          AND group_code IS NULL
--        ;
      EXCEPTION
        WHEN OTHERS THEN
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_month_data_rec.base_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm := cv_month_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_month_loop;
    --�ܗ^
    <<for_bonus_loop>>
    FOR l_bonus_data_rec IN bonus_data_cur LOOP
      BEGIN
        --==============================================================
        --5.�ܗ^�e�[�u���̋��_�W�v���ʂ��X�V���܂��B
        --==============================================================
        UPDATE xxcos_for_adps_bonus_if
        SET b_sale_gross            = l_bonus_data_rec.sale_gross,
            b_current_profit        = l_bonus_data_rec.current_profit,
            b_visit_count           = l_bonus_data_rec.visit_count
        WHERE base_code  = l_bonus_data_rec.base_code
        ;
        --�ۗ�
        --==============================================================
        --6.�ܗ^�e�[�u���̋��_�W�v���ʂ����O���[�v�ɍX�V���܂��B
        --==============================================================
--        UPDATE xxcos_for_adps_bonus_if
--        SET g_sale_gross            = l_bonus_data_rec.sale_gross,
--            g_current_profit        = l_bonus_data_rec.current_profit,
--            g_visit_count           = l_bonus_data_rec.visit_count
--        WHERE base_code  = l_bonus_data_rec.base_code
--          AND group_code IS NULL
--        ;
      EXCEPTION
        WHEN OTHERS THEN
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_bonus_data_rec.base_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm :=cv_bonus_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_bonus_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- �X�V��O
    WHEN global_update_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_get_update_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END base_total;
--
  /**********************************************************************************
   * Procedure Name   : area_total
   * Description      : �n��W�v����(A-13)
   ***********************************************************************************/
  PROCEDURE area_total(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'area_total'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info     VARCHAR2(5000);  --key���
    ln_sales_money  NUMBER;          --������z
    ln_new_sales    NUMBER;          --�V�K�v������
    ln_gross_margin NUMBER;          --�v��e��
    lv_table_nm     VARCHAR2(50);    -- �e�[�u����
    -- *** ���[�J���E�J�[�\�� ***
--
    --==============================================
    -- 1.�����e�[�u���̒n����W�v���܂��B
    --==============================================
    CURSOR month_data_cur
    IS
      SELECT area_code                                             as area_code,
             SUM( p_sale_norma )                                   as sale_norma,
             SUM( p_sale_amount )                                  as sale_amount,
             CASE SUM( p_sale_norma )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_sale_amount )/SUM( p_sale_norma )*100,1 )   
             END                                                   as sale_rate,
             SUM( p_new_contribution_sale )                        as new_contribution_sale,
             SUM( p_new_norma )                                    as new_norma,
             CASE SUM(p_position_point)
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_new_point )/SUM( p_position_point )*100,1 )
             END                                                   as new_point_rate,
             SUM( p_new_count_sum )                                as new_count_sum,
             SUM( p_new_count_vd )                                 as new_count_vd,
             SUM( p_position_point )                               as position_point,
             SUM( p_new_point )                                    as new_point
      FROM xxcos_for_adps_monthly_if
      GROUP BY area_code
      ;
--
    --==============================================
    -- 3.�ܗ^�e�[�u���̒n����W�v���܂��B
    --==============================================
    CURSOR bonus_data_cur
    IS
      SELECT area_code                                             as area_code,
             SUM( p_sale_gross )                                   as sale_gross,
             SUM( p_current_profit )                               as current_profit,
             SUM( p_visit_count )                                  as visit_count
      FROM xxcos_for_adps_bonus_if
      GROUP BY area_code
      ;
    l_month_data_rec               month_data_cur%ROWTYPE;
    l_bonus_data_rec               bonus_data_cur%ROWTYPE;
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --2.�����e�[�u���̒n��W�v���ʂ��X�V���܂��B
    --==============================================================
    <<for_month_loop>>
    FOR l_month_data_rec IN month_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_monthly_if
        SET a_sale_norma            = l_month_data_rec.sale_norma,
            a_sale_amount           = l_month_data_rec.sale_amount,
            a_sale_achievement_rate = l_month_data_rec.sale_rate,
            a_new_contribution_sale = l_month_data_rec.new_contribution_sale,
            a_new_norma             = l_month_data_rec.new_norma,
            a_new_achievement_rate  = l_month_data_rec.new_point_rate,
            a_new_count_sum         = l_month_data_rec.new_count_sum,
            a_new_count_vd          = l_month_data_rec.new_count_vd,
            a_position_point        = l_month_data_rec.position_point,
            a_new_point             = l_month_data_rec.new_point
        WHERE area_code  = l_month_data_rec.area_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  cv_str_area_nm
                                        ,iv_data_value1 =>  l_month_data_rec.area_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm := cv_month_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_month_loop;
--
    --==============================================================
    --4.�ܗ^�e�[�u���̒n��W�v���ʂ��X�V���܂��B
    --==============================================================
    <<for_bonus_loop>>
    FOR l_bonus_data_rec IN bonus_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_bonus_if
        SET a_sale_gross            = l_bonus_data_rec.sale_gross,
            a_current_profit        = l_bonus_data_rec.current_profit,
            a_visit_count           = l_bonus_data_rec.visit_count
        WHERE area_code  = l_bonus_data_rec.area_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  cv_str_area_nm
                                        ,iv_data_value1 =>  l_bonus_data_rec.area_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm :=cv_bonus_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_bonus_loop;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- �X�V��O
    WHEN global_update_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_get_update_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END area_total;
--
  /**********************************************************************************
   * Procedure Name   : div_total
   * Description      : �{���W�v����(A-14)
   ***********************************************************************************/
  PROCEDURE div_total(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'div_total'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info     VARCHAR2(5000);  --key���
    ln_sales_money  NUMBER;          --������z
    ln_new_sales    NUMBER;          --�V�K�v������
    ln_gross_margin NUMBER;          --�v��e��
    lv_table_nm     VARCHAR2(50);    -- �e�[�u����
    -- *** ���[�J���E�J�[�\�� ***
--
    --==============================================
    -- 1.�����e�[�u���̖{�����W�v���܂��B
    --==============================================
    CURSOR month_data_cur
    IS
      SELECT division_code                                         as division_code,
             SUM( p_sale_norma )                                   as sale_norma,
             SUM( p_sale_amount )                                  as sale_amount,
             CASE SUM( p_sale_norma )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_sale_amount )/SUM( p_sale_norma )*100,1 )   
             END                                                   as sale_rate,
             SUM( p_new_contribution_sale )                        as new_contribution_sale,
             SUM( p_new_norma )                                    as new_norma,
             CASE SUM( p_position_point )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_new_point )/SUM( p_position_point )*100,1 )
             END                                                   as new_point_rate,
             SUM( p_new_count_sum )                                as new_count_sum,
             SUM( p_new_count_vd )                                 as new_count_vd,
             SUM( p_position_point )                               as position_point,
             SUM( p_new_point )                                    as new_point
      FROM xxcos_for_adps_monthly_if
      GROUP BY division_code
      ;
--
    --==============================================
    -- 3.�ܗ^�e�[�u���̖{�����W�v���܂��B
    --==============================================
    CURSOR bonus_data_cur
    IS
      SELECT division_code                                       as division_code,
             SUM(p_sale_gross)                                   as sale_gross,
             SUM(p_current_profit)                               as current_profit,
             SUM(p_visit_count)                                  as visit_count
      FROM xxcos_for_adps_bonus_if
      GROUP BY division_code
      ;
--
    l_month_data_rec               month_data_cur%ROWTYPE;
    l_bonus_data_rec               bonus_data_cur%ROWTYPE;
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --2.�����e�[�u���̖{���W�v���ʂ��X�V���܂��B
    --==============================================================
    <<for_month_loop>>
    FOR l_month_data_rec IN month_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_monthly_if
        SET d_sale_norma            = l_month_data_rec.sale_norma,
            d_sale_amount           = l_month_data_rec.sale_amount,
            d_sale_achievement_rate = l_month_data_rec.sale_rate,
            d_new_contribution_sale = l_month_data_rec.new_contribution_sale,
            d_new_norma             = l_month_data_rec.new_norma,
            d_new_achievement_rate  = l_month_data_rec.new_point_rate,
            d_new_count_sum         = l_month_data_rec.new_count_sum,
            d_new_count_vd          = l_month_data_rec.new_count_vd,
            d_position_point        = l_month_data_rec.position_point,
            d_new_point             = l_month_data_rec.new_point
        WHERE division_code  = l_month_data_rec.division_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
        XXCOS_COMMON_PKG.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                      ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                      ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                      ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                      ,iv_item_name1  =>  cv_str_div_nm
                                      ,iv_data_value1 =>  l_month_data_rec.division_code
                                     );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm :=cv_month_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_month_loop;
    --==============================================================
    --4.�ܗ^�e�[�u���̖{���W�v���ʂ��X�V���܂��B
    --==============================================================
    <<for_bonus_loop>>
    FOR l_bonus_data_rec IN bonus_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_bonus_if
        SET d_sale_gross            = l_bonus_data_rec.sale_gross,
            d_current_profit        = l_bonus_data_rec.current_profit,
            d_visit_count           = l_bonus_data_rec.visit_count
        WHERE division_code         = l_bonus_data_rec.division_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
        XXCOS_COMMON_PKG.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                      ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                      ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                      ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                      ,iv_item_name1  =>  cv_str_div_nm
                                      ,iv_data_value1 =>  l_bonus_data_rec.division_code
                                     );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm :=cv_bonus_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_bonus_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- �X�V��O
    WHEN global_update_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_get_update_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END div_total;
--
  /**********************************************************************************
   * Procedure Name   : sum_total
   * Description      : �S�ЏW�v����(A-15)
   ***********************************************************************************/
  PROCEDURE sum_total(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sum_total'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
    lv_key_info     VARCHAR2(5000);  --key���
    ln_sales_money  NUMBER;          --������z
    ln_new_sales    NUMBER;          --�V�K�v������
    ln_gross_margin NUMBER;          --�v��e��
    lv_table_nm     VARCHAR2(50);    -- �e�[�u����
    -- *** ���[�J���E�J�[�\�� ***
--
    --==============================================
    -- 1.�����e�[�u���̑S�Ђ��W�v���܂��B
    --==============================================
    CURSOR month_data_cur
    IS
      SELECT SUM( p_sale_norma )                                   as sale_norma,
             SUM( p_sale_amount )                                  as sale_amount,
             CASE SUM( p_sale_norma )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_sale_amount )/SUM( p_sale_norma )*100,1 )   
             END                                                   as sale_rate,
             SUM( p_new_contribution_sale )                        as new_contribution_sale,
             SUM( p_new_norma )                                    as new_norma,
             CASE SUM( p_position_point )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_new_point )/SUM( p_position_point )*100,1 )
             END                                                   as new_point_rate,
             SUM( p_new_count_sum )                                as new_count_sum,
             SUM( p_new_count_vd )                                 as new_count_vd,
             SUM( p_position_point )                               as position_point,
             SUM( p_new_point )                                    as new_point
      FROM xxcos_for_adps_monthly_if
      ;
--
    --==============================================
    -- 3.�ܗ^�e�[�u���̑S�Ђ��W�v���܂��B
    --==============================================
    CURSOR bonus_data_cur
    IS
      SELECT SUM( p_sale_gross )                                   as sale_gross,
             SUM( p_current_profit )                               as current_profit,
             SUM( p_visit_count )                                  as visit_count
      FROM xxcos_for_adps_bonus_if
      ;
--
    l_month_data_rec               month_data_cur%ROWTYPE;
    l_bonus_data_rec               bonus_data_cur%ROWTYPE;
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --2.�����e�[�u���̑S�ЏW�v���ʂ��X�V���܂��B
    --==============================================================
    <<for_month_loop>>
    FOR l_month_data_rec IN month_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_monthly_if
        SET s_sale_norma            = l_month_data_rec.sale_norma,
            s_sale_amount           = l_month_data_rec.sale_amount,
            s_sale_achievement_rate = l_month_data_rec.sale_rate,
            s_new_contribution_sale = l_month_data_rec.new_contribution_sale,
            s_new_norma             = l_month_data_rec.new_norma,
            s_new_achievement_rate  = l_month_data_rec.new_point_rate,
            s_new_count_sum         = l_month_data_rec.new_count_sum,
            s_new_count_vd          = l_month_data_rec.new_count_vd,
            s_position_point        = l_month_data_rec.position_point,
            s_new_point             = l_month_data_rec.new_point
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_table_nm :=cv_bonus_tbl;
          RAISE global_update_expt;
      END;
    END LOOP for_month_loop;
    --==============================================================
    --4.�ܗ^�e�[�u���̑S�ЏW�v���ʂ��X�V���܂��B
    --==============================================================
    <<for_bonus_loop>>
    FOR l_bonus_data_rec IN bonus_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_bonus_if
        SET s_sale_gross            = l_bonus_data_rec.sale_gross,
            s_current_profit        = l_bonus_data_rec.current_profit,
            s_visit_count           = l_bonus_data_rec.visit_count
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_table_nm :=cv_bonus_tbl;
          RAISE global_update_expt;
      END;
    END LOOP for_bonus_loop;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- �X�V��O
    WHEN global_update_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_get_update_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END sum_total;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_make_date  IN  VARCHAR2,     --   1.�쐬�N��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���^   ***
    -- *** ���[�J���萔 ***
--
    ci_bulk_size CONSTANT PLS_INTEGER := 10;
    -- *** ���[�J���ϐ� ***
--
    lv_key_info                  VARCHAR2(5000);                      -- key���
    lv_make_date                 VARCHAR2(7);                         -- �쐬�����t
    ld_start_date                DATE;                                -- ��v�J�n��
    ld_end_date                  DATE;                                -- ��v�I����
    ld_month_first_date          DATE;                                -- �����J�n��
    ld_month_next_date           DATE;                                -- �����I����
    ln_err_flg                   NUMBER;                              -- ���[�J���G���[�t���O
    lv_table_nm                  VARCHAR2(50) := cv_employee_view;    -- �e�[�u����
    ln_snq_no                    NUMBER;                              -- �V�[�P���XNO
    lv_group_cd                  VARCHAR2(2);                         -- �O���[�v
    lv_base_cd                   VARCHAR2(4);                         -- ���_�R�[�h
    lv_area_cd                   VARCHAR2(3);                         -- �G���A�R�[�h
    lv_div_cd                    VARCHAR2(4);                         -- �{���R�[�h
--
    lt_xxcos_for_adps_monthly_if xxcos_for_adps_monthly_if%ROWTYPE;
    lt_xxcos_for_adps_bonus_if   xxcos_for_adps_bonus_if%ROWTYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- A-4 �Ώۏ]�ƈ��擾����
    CURSOR data_cur
    IS
      SELECT division_code           as div_cd,             --�{���R�[�h
             area_code               as area,               --�n��R�[�h
             base_code               as base,               --���_�R�[�h
             group_cd                as group_cd,           --�O���[�v�R�[�h
             employee_number         as code,               --�]�ƈ��R�[�h
             ori_division_code       as ori_division_code   --�I���W�i���{���R�[�h
      FROM XXCOS_EMPLOYEE_V
      WHERE (announcement_start_day <= ld_month_next_date
        AND  announcement_end_day   >= ld_month_first_date)
        AND ld_month_next_date BETWEEN add_on_start_date AND add_on_end_date
        AND ld_month_next_date BETWEEN effective_start_date AND effective_end_date
        AND ld_month_next_date BETWEEN asaiment_start_date AND asaiment_end_date
      ;
    TYPE t_datacur IS TABLE OF data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_data_rec        t_datacur;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    lv_make_date := iv_make_date;
--
    -- ===============================
    -- A-0.��������
    -- ===============================
    init(
       lv_make_date   -- 1.�쐬�N��
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
--
    -- ===============================
    -- A-1.�p�����[�^�`�F�b�N
    -- ===============================
    pra_chk(
       lv_make_date   -- 1.�쐬�N��
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
--
    --�����J�n�I����
    ld_month_first_date := TO_DATE(lv_make_date || cv_sla || cv_01,cv_format_yyyymmdd);
    ld_month_next_date  := ADD_MONTHS(ld_month_first_date,cn_1) -1;
--
    -- ===============================
    -- A-2. ���ʃf�[�^�擾
    -- ===============================
    get_common_data(
       ld_month_first_date   -- �쐬�N��
      ,ld_start_date         -- ��v�J�n��
      ,ld_end_date           -- ��v�I����
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
--
    -- ===============================
    -- A-3. �����E�ܗ^���ԃe�[�u������������
    -- ===============================
    -- ===============================
    -- 1.�l���V�X�e�������̔����сi�����j�e�[�u���̍폜���s���܂��B
    -- ===============================
    --�e�[�u�����b�N
    lock_table(
       cv_month_tbl_name -- �e�[�u����
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
       lv_errmsg := xxccp_common_pkg.get_msg( cv_current_appl_short_nm
                                             ,cv_msg_table_lock_err
                                             ,cb_tkn_table_on
                                             ,cv_month_tbl);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    --�e�[�u���f�[�^�폜
    delete_table(
       cv_month_tbl_name -- �e�[�u����
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
       lv_errmsg := xxccp_common_pkg.get_msg( cv_current_appl_short_nm
                                             ,cv_msg_get_delete_err
                                             ,cv_tkn_table
                                             ,cv_month_tbl);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 2.�l���V�X�e�������̔����сi�ܗ^�j�e�[�u���̍폜���s���܂��B
    -- ===============================
    --�e�[�u�����b�N
    lock_table(
       cv_bonus_tbl_name -- �e�[�u����
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
       lv_errmsg := xxccp_common_pkg.get_msg( cv_current_appl_short_nm
                                             ,cv_msg_table_lock_err
                                             ,cb_tkn_table_on
                                             ,cv_bonus_tbl_name);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    --�e�[�u���f�[�^�폜
    delete_table(
       cv_bonus_tbl_name -- �e�[�u����
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
       lv_errmsg := xxccp_common_pkg.get_msg( cv_current_appl_short_nm
                                             ,cv_msg_get_delete_err
                                             ,cv_tkn_table
                                             ,cv_bonus_tbl);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <�������A���[�v����> (�������ʂɂ���Č㑱�����𐧌䂷��ꍇ)
    -- ===============================
   -- ===============================
    -- A-4. �Ώۏ]�ƈ��擾����
    -- ===============================
    OPEN data_cur;
    LOOP
      FETCH data_cur BULK COLLECT INTO l_data_rec;
      --���R�[�h0���̏ꍇ�͔�����B
      EXIT WHEN l_data_rec.COUNT = 0;
      --���R�[�h����
      FOR i in 1 .. l_data_rec.COUNT
      LOOP
        lt_xxcos_for_adps_monthly_if := NULL;
        lt_xxcos_for_adps_bonus_if   := NULL;
        
        --�l�ݒ�
        --����
        lt_xxcos_for_adps_monthly_if.employee_code  := LPAD(l_data_rec(i).code,6,0);               -- �]�ƈ��R�[�h
        lt_xxcos_for_adps_monthly_if.results_date   := REPLACE(lv_make_date, cv_sla, '');          -- �N��
        lt_xxcos_for_adps_monthly_if.group_code     := l_data_rec(i).group_cd;                     -- ���O���[�v�R�[�h
        lt_xxcos_for_adps_monthly_if.base_code      := l_data_rec(i).base;                         -- ���_�R�[�h
        lt_xxcos_for_adps_monthly_if.area_code      := l_data_rec(i).area;                         -- �n��R�[�h
        lt_xxcos_for_adps_monthly_if.division_code  := l_data_rec(i).ori_division_code;            -- �{���R�[�h
        --�ܗ^
        lt_xxcos_for_adps_bonus_if.employee_code    := LPAD(l_data_rec(i).code,6,0);               -- �]�ƈ��R�[�h
        lt_xxcos_for_adps_bonus_if.results_date     := REPLACE(lv_make_date, cv_sla, '');          -- �N��
        lt_xxcos_for_adps_bonus_if.group_code       := l_data_rec(i).group_cd;                     -- ���O���[�v�R�[�h
        lt_xxcos_for_adps_bonus_if.base_code        := l_data_rec(i).base;                         -- ���_�R�[�h
        lt_xxcos_for_adps_bonus_if.area_code        := l_data_rec(i).area;                         -- �n��R�[�h
        lt_xxcos_for_adps_bonus_if.division_code    := l_data_rec(i).ori_division_code;            -- �{���R�[�h
        -- ===============================
        -- A-5. �����̔����яW�v����
        -- ===============================
        get_sales_results_data(
           l_data_rec(i).code           -- �]�ƈ��R�[�h
          ,l_data_rec(i).base           -- ���_�R�[�h
          ,ld_month_first_date          -- ����1��
          ,ld_month_next_date           -- ��������
          ,lt_xxcos_for_adps_monthly_if -- �����e�[�u��
          ,lt_xxcos_for_adps_bonus_if   -- �ܗ^�f�[�^
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          RAISE global_common_expt;
        END IF;
--
        -- ===============================
        -- A-6�D�����m���}�W�v����
        -- ===============================
        get_noruma_data(
           l_data_rec(i).code           -- �]�ƈ��R�[�h
          ,l_data_rec(i).base           -- ���_�R�[�h
          ,lt_xxcos_for_adps_monthly_if -- �e�[�u��
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  cv_str_result_cd
                                        ,iv_item_name2  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_data_rec(i).code
                                        ,iv_data_value2 =>  l_data_rec(i).base
                                       );
          lv_table_nm := cv_str_noruma_tbl;
          IF ( lv_retcode = cv_status_normal ) THEN
            RAISE global_select_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- A-7�D�����l���|�C���g�W�v����
        -- ===============================
        get_point_data(
           l_data_rec(i).code           -- �]�ƈ��R�[�h
          ,l_data_rec(i).base           -- ���_�R�[�h
          ,ld_month_first_date          -- ����1��
          ,ld_month_next_date           -- ��������
          ,lt_xxcos_for_adps_monthly_if -- �e�[�u��
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  cv_str_result_cd
                                        ,iv_item_name2  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_data_rec(i).code
                                        ,iv_data_value2 =>  l_data_rec(i).base
                                       );
          lv_table_nm := cv_str_point_tbl;
          IF ( lv_retcode = cv_status_normal ) THEN
            RAISE global_select_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- A-8�D�����l���x���_�[�W�v����
        -- ===============================
        get_vender_data(
           l_data_rec(i).code              -- �]�ƈ��R�[�h
          ,l_data_rec(i).base              -- ���_�R�[�h
          ,lt_xxcos_for_adps_monthly_if -- �e�[�u��
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  cv_str_result_cd
                                        ,iv_item_name2  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_data_rec(i).code
                                        ,iv_data_value2 =>  l_data_rec(i).base
                                       );
          lv_table_nm := cv_str_bus_count_tbl;
          IF ( lv_retcode = cv_status_normal ) THEN
            RAISE global_select_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- A-9�D�����K�⌏���W�v����
        -- ===============================
        get_visit_data(
           l_data_rec(i).code              -- �]�ƈ��R�[�h
          ,l_data_rec(i).base              -- ���_�R�[�h
          ,lt_xxcos_for_adps_bonus_if   -- �e�[�u��
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  cv_str_result_cd
                                        ,iv_item_name2  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_data_rec(i).code
                                        ,iv_data_value2 =>  l_data_rec(i).base
                                       );
          lv_table_nm := cv_str_bus_count_tbl;
          IF ( lv_retcode = cv_status_normal ) THEN
            RAISE global_select_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- A-10�D�����E�ܗ^���ԃe�[�u���o�^����
        -- ===============================
        --����B����
        IF ( lt_xxcos_for_adps_monthly_if.p_sale_norma = 0 ) 
          OR ( lt_xxcos_for_adps_monthly_if.p_sale_amount = 0 )
        THEN
          lt_xxcos_for_adps_monthly_if.p_sale_achievement_rate := 0;
        ELSE
          lt_xxcos_for_adps_monthly_if.p_sale_achievement_rate := 
            ROUND(lt_xxcos_for_adps_monthly_if.p_sale_amount / lt_xxcos_for_adps_monthly_if.p_sale_norma * 100,1);
        END IF;
--
        --�V�K�B����
        IF ( lt_xxcos_for_adps_monthly_if.p_position_point = 0 ) 
          OR ( lt_xxcos_for_adps_monthly_if.p_new_point = 0 )
        THEN
          lt_xxcos_for_adps_monthly_if.p_new_achievement_rate := 0;
        ELSE
          lt_xxcos_for_adps_monthly_if.p_new_achievement_rate  := 
            ROUND(lt_xxcos_for_adps_monthly_if.p_new_point / lt_xxcos_for_adps_monthly_if.p_position_point * 100,1);
        END IF;
--
        set_insert_data(
           lt_xxcos_for_adps_monthly_if -- �����e�[�u��
          ,lt_xxcos_for_adps_bonus_if   -- �ܗ^�f�[�^
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          RAISE global_common_expt;
        END IF;
        gn_target_cnt := gn_target_cnt + 1;
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP;
    END LOOP;
    CLOSE data_cur;
--
    --�]�ƈ�0��
    IF gn_target_cnt = 0 THEN
       RAISE global_no_data_expt;
    END IF;
    -- ===============================
    -- A-11�D���O���[�v�W�v����
    -- ===============================
    small_group_total(
       lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-12�D���_�W�v����
    -- ===============================
    base_total(
       lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-13�D�n��W�v����
    -- ===============================
    area_total(
       lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_common_expt;
      END IF;
--
    -- ===============================
    -- A-14�D�{���W�v����
    -- ===============================
    div_total(
       lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_common_expt;
      END IF;
--
    -- ===============================
    -- A-15�D�S�ЏW�v����
    -- ===============================
    sum_total(
         lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_common_expt;
      END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
    -- ���o��O
    WHEN global_select_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_select_data_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
    -- *** �Ώۃf�[�^�O���G���[ ***
    WHEN global_no_data_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_nodata_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_common_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
--    ��IN �����Ұ�������ꍇ�͓K�X�ҏW���ĉ������B
    iv_make_date  IN  VARCHAR2       --   1.�쐬�N��
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
    
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
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
       iv_make_date   -- 1.�쐬�N��
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode != cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    errbuf  := lv_errbuf;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
END XXCOS016A03C;
/
