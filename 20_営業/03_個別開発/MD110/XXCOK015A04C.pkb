CREATE OR REPLACE PACKAGE BODY XXCOK015A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCOK015A04C(body)
 * Description      : �A�b�v���[�h�t�@�C������x���ē����A�̔��񍐏����o��
 * MD.050           : �x���ē����E�̔��񍐏��ꊇ�o�� MD050_COK_015_A04
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �ꊇ�o�͏��(CSV�t�@�C��)�̎捞����
 *  submain              ���C�������v���V�[�W��
 *  init_proc            ��������(A-1)
 *  chk_validate_item    �Ó����`�F�b�N����(A-4)
 *  insert_xbsrw         �x���ē����A�̔��񍐏��o�͑Ώۃ��[�N�o�^(A-5)
 *  chk_dupulicate_bm    �x���ē����̏o�͑Ώۏd���`�F�b�N(A-6)
 *  submit_conc_bm_rep   �x���ē����R���J�����g���s����
 *  submit_conc_bm_rep   �̔��񍐏��R���J�����g���s����
 *  del_file_upload_data �t�@�C���A�b�v���[�h�f�[�^�̍폜(A-8)
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/07/18    1.0   K.Nara           �V�K�쐬
 *  2018/08/07    1.1   K.Nara           E_�{�ғ�_15005 �x���ē����Ɣ̔��񍐏��̔̔����Ԃ����킹��Ή�
 *                                       �i�x���ē����i����j�̈ē������s�N�����A�b�v���[�h�l�{1�����Ƃ���j
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
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
  ------------------------------------------------------------
  -- ���[�U�[��`�O���[�o���萔
  ------------------------------------------------------------
  -- �p�b�P�[�W��`
  cv_pkg_name           CONSTANT VARCHAR2(12) := 'XXCOK015A04C';                 -- �p�b�P�[�W��
  -- �����l
  cn_zero               CONSTANT NUMBER       := 0;                              -- ���l:0
  cn_one                CONSTANT NUMBER       := 1;                              -- ���l:1
  cv_zero               CONSTANT VARCHAR2(1)  := '0';                            -- ����:0
  cv_one                CONSTANT VARCHAR2(1)  := '1';                            -- ����:1
  cv_msg_wq             CONSTANT VARCHAR2(1)  := '"';                            -- �_�u���N�H�[�e�C�V����
  cv_msg_c              CONSTANT VARCHAR2(1)  := ',';                            -- �R���}
  cv_csv_sep            CONSTANT VARCHAR2(1)  := ',';                            -- CSV�Z�p���[�^
  cv_yes                CONSTANT VARCHAR2(1)  := 'Y';                            -- ����:Y
  cv_no                 CONSTANT VARCHAR2(1)  := 'N';                            -- ����:N
  cv_output             CONSTANT VARCHAR2(6)  := 'OUTPUT';                       -- �w�b�_���O�o��
  -- �A�v���P�[�V�����Z�k��
  cv_ap_type_xxccp      CONSTANT VARCHAR2(5)  := 'XXCCP';                        -- ����
  cv_ap_type_xxcok      CONSTANT VARCHAR2(5)  := 'XXCOK';                        -- �ʊJ��
  cv_ap_type_xxcos      CONSTANT VARCHAR2(5)  := 'XXCOS';                        -- �̔�
  -- �X�e�[�^�X�E�R�[�h
  cv_status_check       CONSTANT VARCHAR2(1)  := '9';                            -- �`�F�b�N�G���[:9
  cv_status_lock        CONSTANT VARCHAR2(1)  := '7';                            -- ���b�N�G���[:7
  cv_status_update      CONSTANT VARCHAR2(1)  := '8';                            -- �X�V�G���[:8
  cv_status_insert      CONSTANT VARCHAR2(1)  := '9';                            -- �}���G���[:9
  -- ���ʃ��b�Z�[�W��`
  cv_normal_msg         CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';             -- ����I�����b�Z�[�W
  cv_warn_msg           CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005';             -- �x���I�����b�Z�[�W
  cv_error_msg          CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';             -- �G���[�I�����b�Z�[�W
  cv_mainmsg_90000      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';             -- �Ώی����o��
  cv_mainmsg_90001      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';             -- ���������o��
  cv_mainmsg_90002      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';             -- �G���[�����o��
  cv_mainmsg_90003      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003';             -- �X�L�b�v�����o��
  -- �ʃ��b�Z�[�W��`
  cv_prmmsg_00016       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00016';             -- �t�@�C��ID�p�����[�^
  cv_prmmsg_00017       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00017';             -- �t�@�C���p�^�[���p�����[�^
  cv_errmsg_00028       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';             -- �Ɩ��������t�擾�G���[
  cv_errmsg_00003       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003';             -- �v���t�@�C���擾�G���[
  cv_errmsg_00061       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00061';             -- �t�@�C���A�b�v���[�h���b�N�G���[
  cv_errmsg_00041       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00041';             -- BLOB�f�[�^�ϊ��G���[
  cv_errmsg_00062       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00062';             -- �t�@�C���A�b�v���[�hIF�폜�G���[
  cv_errmsg_00015       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00015';             -- �N�C�b�N�R�[�h�擾�G���[
  cv_errmsg_10547       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10547';             -- ���ڐ�����G���[���b�Z�[�W
  cv_errmsg_10548       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10548';             -- ���ڕs���G���[���b�Z�[�W
  cv_errmsg_10549       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10549';             -- �o�͋敪�w��G���[���b�Z�[�W
  cv_errmsg_10550       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10550';             -- �Ώ۔N�������ݒ�G���[���b�Z�[�W
  cv_errmsg_10551       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10551';             -- �d����A�ڋq���ݒ�G���[���b�Z�[�W
  cv_errmsg_10552       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10552';             -- �x���ē����A�d����l���X�g�G���[
  cv_errmsg_10553       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10553';             -- �x���ē����A�ڋq�}�X�^�G���[
  cv_errmsg_10554       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10554';             -- �̔��񍐏��A�d����l���X�g�G���[
  cv_errmsg_10555       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10555';             -- �̔��񍐏��A�ڋq�l���X�g�G���[
  cv_errmsg_10556       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10556';             -- �x���ē����d���G���[���b�Z�[�W
  cv_errmsg_10557       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10557';             -- �R���J�����g�N���G���[
  cv_errmsg_10558       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10558';             -- �A�b�v���[�h�����ΏۂȂ��G���[
  cv_errmsg_10559       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10559';             -- ���s�R���J�����g���b�Z�[�W
  cv_errmsg_10560       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10560';             -- �R���J�����g���擾�G���[���b�Z�[�W
  -- ���b�Z�[�W�g�[�N����`
  cv_tkn_file_id        CONSTANT VARCHAR2(7)  := 'FILE_ID';                      -- �t�@�C��ID�g�[�N��
  cv_tkn_format         CONSTANT VARCHAR2(6)  := 'FORMAT';                       -- �t�@�C���p�^�[���g�[�N��
  cv_tkn_profile        CONSTANT VARCHAR2(7)  := 'PROFILE';                      -- �v���t�@�C���g�[�N��
  cv_tkn_user_id        CONSTANT VARCHAR2(7)  := 'USER_ID';                      -- ���[�UID�g�[�N��
  cv_tkn_table          CONSTANT VARCHAR2(5)  := 'TABLE';                        -- �e�[�u��
  cv_tkn_record_no      CONSTANT VARCHAR2(20) := 'RECORD_NO';                    -- ���R�[�hNo
  cv_tkn_errmsg         CONSTANT VARCHAR2(20) := 'ERRMSG';                       -- �G���[���e�ڍ�
  cv_tkn_file_name      CONSTANT VARCHAR2(20) := 'FILE_NAME';                    -- �t�@�C������
  cv_tkn_item           CONSTANT VARCHAR2(20) := 'ITEM';                         -- ����
  cv_tkn_output_num     CONSTANT VARCHAR2(20) := 'OUTPUT_NUM';                   -- �o�͔ԍ�
  cv_tkn_target_date    CONSTANT VARCHAR2(20) := 'TARGET_DATE';                  -- �Ώ۔N��
  cv_tkn_row_num        CONSTANT VARCHAR2(7)  := 'ROW_NUM';                      -- �G���[�s�g�[�N��
  cv_tkn_vend_code      CONSTANT VARCHAR2(11) := 'VENDOR_CODE';                  -- �d����R�[�h�g�[�N��
  cv_tkn_cust_code      CONSTANT VARCHAR2(13) := 'CUST_CODE';                    -- �ڋq�R�[�h�g�[�N��
  cv_tkn_conc           CONSTANT VARCHAR2(30) := 'CONC';                         -- �R���J�����g�Z�k��
  cv_tkn_conc_name      CONSTANT VARCHAR2(30) := 'CONC_NAME';                    -- �R���J�����g��
  cv_tkn_concmsg        CONSTANT VARCHAR2(30) := 'CONCMSG';                      -- �R���J�����g���b�Z�[�W
  cv_tkn_request_id     CONSTANT VARCHAR2(30) := 'REQUEST_ID';                   -- �v��ID
  cv_tkn_count          CONSTANT VARCHAR2(5)  := 'COUNT';                        -- �����o�̓g�[�N��
  cv_bm_rep_conc        CONSTANT VARCHAR2(50) := 'XXCOK015A03R3';                -- �x���ē���(���)�R���J�����g
  cv_sales_rep_conc     CONSTANT VARCHAR2(50) := 'XXCOS002A066R';                -- �̔��񍐏��R���J�����g
  cv_manager_flag       CONSTANT VARCHAR2(1)  := 'Y';                            -- �Ǘ��҃t���O
  cv_execute_type_4     CONSTANT VARCHAR2(1)  := '4';                            -- �A�b�v���[�h�N��
  cv_yyyymm             CONSTANT VARCHAR2(6)  := 'YYYYMM';                       -- �Ώ۔N������
  cv_no_bm              CONSTANT VARCHAR2(1)  := '5';                            -- BM�x���敪 5:�x������
  cv_flag_y             CONSTANT VARCHAR2(1)  := 'Y';                            -- 'Y'
--
  cv_file_id_split      CONSTANT VARCHAR2(5) := '360';  --�����o��
  cv_file_id_all        CONSTANT VARCHAR2(5) := '361';  --�ꊇ�o��
  -- �o�͒��[
  cn_bm_rep             CONSTANT NUMBER := 1;  --�x���ē���
  cn_sales_rep          CONSTANT NUMBER := 2;  --�̔��񍐏�
  cn_both_rep           CONSTANT NUMBER := 3;  --����
  ------------------------------------------------------------
  -- ���[�U�[��`�O���[�o���ϐ�
  ------------------------------------------------------------
  gn_item_cnt                 NUMBER := 0;                      -- CSV�K�荀�ڐ�
  -- �`�F�b�N���ڊi�[���R�[�h
  TYPE g_chk_item_rtype IS RECORD(
      meaning           fnd_lookup_values.meaning%TYPE    -- ���ږ���
    , attribute1        fnd_lookup_values.attribute1%TYPE -- ���ڂ̒���
    , attribute2        fnd_lookup_values.attribute2%TYPE -- ���ڂ̒����i�����_�ȉ��j
    , attribute3        fnd_lookup_values.attribute3%TYPE -- �K�{�t���O
    , attribute4        fnd_lookup_values.attribute4%TYPE -- ����
  );
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  g_chk_item_tab              g_chk_item_ttype;                 -- ���ڃ`�F�b�N
  -- �`�F�b�N�σf�[�^�i�[���R�[�h
  TYPE g_check_data_rtype IS RECORD (
    output_num          xxcok_bm_sales_rep_work.output_num%TYPE      -- �o�͔ԍ�
   ,output_rep          xxcok_bm_sales_rep_work.output_rep%TYPE      -- �o�͒��[
   ,target_ym           xxcok_bm_sales_rep_work.target_ym%TYPE       -- �Ώ۔N��
   ,vendor_code         xxcok_bm_sales_rep_work.vendor_code%TYPE     -- �d����R�[�h
   ,customer_code       xxcok_bm_sales_rep_work.customer_code%TYPE   -- �ڋq�R�[�h
  );
  TYPE g_check_data_ttype IS TABLE OF g_check_data_rtype INDEX BY BINARY_INTEGER;
  gt_check_data         g_check_data_ttype;                          -- �`�F�b�N�σf�[�^�ޔ�
  --
  gd_proc_date          DATE           := NULL;            -- �Ɩ��������t
  gt_csv_data           xxcok_common_pkg.g_split_csv_tbl;  -- CSV�����f�[�^�i������؂菈����j
  gt_bm_rep_conc_name       fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;  --�x���ē����R���J�����g��
  gt_sales_rep_conc_name    fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;  --�̔��񍐏��R���J�����g��
  ------------------------------------------------------------
  -- ���[�U�[��`��O
  ------------------------------------------------------------
  -- ��O
  global_lock_expt       EXCEPTION; -- �O���[�o����O
  -- �v���O�}
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : del_file_upload_data
   * Description      : �t�@�C���A�b�v���[�h�f�[�^�̍폜(A-8)
   ***********************************************************************************/
  PROCEDURE del_file_upload_data(
     ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_file_id IN NUMBER    -- �t�@�C��ID
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_file_upload_data'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(2000);  -- ���b�Z�[�W
    lb_retcode BOOLEAN;         -- API���^�[���E���b�Z�[�W�p
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �t�@�C���A�b�v���[�h�폜���b�N�J�[�\����`
    CURSOR file_delete_cur(
       in_file_id IN NUMBER -- �t�@�C��ID
    )
    IS
      SELECT xmf.file_id AS file_id          -- �t�@�C��ID
      FROM   xxccp_mrp_file_ul_interface xmf -- �t�@�C���A�b�v���[�h�e�[�u��
      WHERE  xmf.file_id = in_file_id
      FOR UPDATE NOWAIT;
    --===============================
    -- ���[�J����O
    --===============================
    delete_err_expt EXCEPTION; -- �폜�G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�t�@�C���A�b�v���[�h�폜���b�N����
    -------------------------------------------------
    -- ���b�N����
    OPEN file_delete_cur(
       in_file_id -- �t�@�C��ID
    );
    CLOSE file_delete_cur;
    -------------------------------------------------
    -- 2.�t�@�C���A�b�v���[�h�폜����
    -------------------------------------------------
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmf
      WHERE xmf.file_id = in_file_id;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE delete_err_expt;
    END;
  --
  EXCEPTION
    -- *** ���b�N��O�n���h�� ****
    WHEN global_lock_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00061
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(in_file_id)
                    );    
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͒��[
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �폜��O�n���h�� ***
    WHEN delete_err_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00062
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(in_file_id)
                    );    
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͒��[
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
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
  END del_file_upload_data;
  --
  /**********************************************************************************
   * Procedure Name   : submit_conc_bm_rep
   * Description      : �x���ē����R���J�����g���s����
   ***********************************************************************************/
  PROCEDURE submit_conc_bm_rep(
     ov_errbuf     OUT VARCHAR2           -- �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2           -- ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_output_num IN  NUMBER             -- �o�͔ԍ�
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submit_conc_bm_rep'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    lv_out_msg     VARCHAR2(2000);  -- ���b�Z�[�W
    ln_request_id  NUMBER;
    lb_retcode     BOOLEAN;         -- API���^�[���E���b�Z�[�W�p
    --===============================
    -- ���[�J����O
    --===============================
    submit_conc_expt           EXCEPTION;   -- �R���J�����g���s�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -------------------------------------------------
    -- 1.�u�x���ē�������i���ׁj_�����Z���^�[�v�R���J�����g���s
    -------------------------------------------------
    ln_request_id := fnd_request.submit_request(
      application   => cv_ap_type_xxcok
     ,program       => cv_bm_rep_conc                -- �x���ē�������i���ׁj_�����Z���^�[
     ,description   => NULL
     ,start_time    => NULL
     ,sub_request   => FALSE
     ,argument1     => NULL                          --�⍇�����_
     ,argument2     => NULL                          --�ē������s�N��
     ,argument3     => NULL                          --�x����
     ,argument4     => cn_request_id                 --�v��ID
     ,argument5     => in_output_num                 --�o�͔ԍ�
    );
    -- ����ȊO�̏ꍇ
    IF ( ln_request_id = 0 ) THEN
      RAISE submit_conc_expt;
    END IF;
--
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_errmsg_10559
                    ,iv_token_name1  => cv_tkn_output_num
                    ,iv_token_value1 => TO_CHAR(in_output_num)
                    ,iv_token_name2  => cv_tkn_conc_name
                    ,iv_token_value2 => gt_bm_rep_conc_name
                    ,iv_token_name3  => cv_tkn_request_id
                    ,iv_token_value3 => TO_CHAR(ln_request_id)
                  );    
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͒��[
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_zero          -- ���s
                  );
--
  EXCEPTION
--
    ----------------------------------------------------------
    -- �R���J�����g���s��O�n���h��
    ----------------------------------------------------------
    WHEN submit_conc_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_10557
                      ,iv_token_name1  => cv_tkn_conc             -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => cv_bm_rep_conc          -- �R���J�����g��
                      ,iv_token_name2  => cv_tkn_concmsg          -- �g�[�N���R�[�h�Q
                      ,iv_token_value2 => TO_CHAR(ln_request_id)  -- �߂�l
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT
                      ,iv_message    => lv_out_msg       -- ���b�Z�[�W
                      ,in_new_line   => cn_one           -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
      --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submit_conc_bm_rep;
  --
  /**********************************************************************************
   * Procedure Name   : submit_conc_sales_rep
   * Description      : �̔��񍐏��R���J�����g���s����
   ***********************************************************************************/
  PROCEDURE submit_conc_sales_rep(
     ov_errbuf     OUT VARCHAR2           -- �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2           -- ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_output_num IN  NUMBER             -- �o�͔ԍ�
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submit_conc_sales_rep'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    lv_out_msg     VARCHAR2(2000);  -- ���b�Z�[�W
    ln_request_id  NUMBER;
    lb_retcode     BOOLEAN;         -- API���^�[���E���b�Z�[�W�p
    --===============================
    -- ���[�J����O
    --===============================
    submit_conc_expt           EXCEPTION;   -- �R���J�����g���s�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -------------------------------------------------
    -- 1.�u���̋@�̔��񍐏��A�b�v���[�h�w��v�R���J�����g���s
    -------------------------------------------------
    ln_request_id := fnd_request.submit_request(
      application   => cv_ap_type_xxcos
     ,program       => cv_sales_rep_conc               -- ���̋@�̔��񍐏��A�b�v���[�h�w��
     ,description   => NULL
     ,start_time    => NULL
     ,sub_request   => FALSE
     ,argument1     => cv_manager_flag    -- �Ǘ��҃t���O
     ,argument2     => cv_execute_type_4  -- ���s�敪
     ,argument3     => NULL
     ,argument4     => NULL
     ,argument5     => NULL
     ,argument6     => NULL
     ,argument7     => NULL
     ,argument8     => NULL
     ,argument9     => NULL
     ,argument10    => NULL
     ,argument11    => NULL
     ,argument12    => NULL
     ,argument13    => NULL
     ,argument14    => NULL
     ,argument15    => NULL
     ,argument16    => NULL
     ,argument17    => NULL
     ,argument18    => NULL
     ,argument19    => NULL
     ,argument20    => cn_request_id                 --�v��ID
     ,argument21    => in_output_num                 --�o�͔ԍ�
    );
    -- ����ȊO�̏ꍇ
    IF ( ln_request_id = 0 ) THEN
      RAISE submit_conc_expt;
    END IF;
--
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_errmsg_10559
                    ,iv_token_name1  => cv_tkn_output_num
                    ,iv_token_value1 => TO_CHAR(in_output_num)
                    ,iv_token_name2  => cv_tkn_conc_name
                    ,iv_token_value2 => gt_sales_rep_conc_name
                    ,iv_token_name3  => cv_tkn_request_id
                    ,iv_token_value3 => TO_CHAR(ln_request_id)
                  );    
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͒��[
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_zero          -- ���s
                  );
--
  EXCEPTION
--
    ----------------------------------------------------------
    -- �R���J�����g���s��O�n���h��
    ----------------------------------------------------------
    WHEN submit_conc_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_10557
                      ,iv_token_name1  => cv_tkn_conc             -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => cv_sales_rep_conc       -- �R���J�����g��
                      ,iv_token_name2  => cv_tkn_concmsg          -- �g�[�N���R�[�h�Q
                      ,iv_token_value2 => TO_CHAR(ln_request_id)  -- �߂�l
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT
                      ,iv_message    => lv_out_msg       -- ���b�Z�[�W
                      ,in_new_line   => cn_one           -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
      --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submit_conc_sales_rep;
  --
  /**********************************************************************************
   * Procedure Name   : insert_xbsrw
   * Description      : �x���ē����A�̔��񍐏��o�͑Ώۃ��[�N�o�^(A-5)
   ***********************************************************************************/
  PROCEDURE insert_xbsrw(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xbsrw';     -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ln_line_cnt                    PLS_INTEGER;                                 -- CSV�����s�J�E���^
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �A�b�v���[�h�f�[�^���[�N�o�^
    -- ===============================
    << ins_xbsrw_loop >>
    FOR ln_line_cnt IN 1..gt_check_data.COUNT LOOP
      INSERT INTO xxcok_bm_sales_rep_work (
          OUTPUT_NUM                                --�o�͔ԍ�
        , OUTPUT_REP                                --�o�͒��[
        , TARGET_YM                                 --�Ώ۔N��
        , VENDOR_CODE                               --�d����R�[�h
        , CUSTOMER_CODE                             --�ڋq�R�[�h
        , CREATED_BY                                --�쐬��
        , CREATION_DATE                             --�쐬��
        , LAST_UPDATED_BY                           --�ŏI�X�V��
        , LAST_UPDATE_DATE                          --�ŏI�X�V��
        , LAST_UPDATE_LOGIN                         --�ŏI�X�V���O�C��
        , REQUEST_ID                                --�v��ID
        , PROGRAM_APPLICATION_ID                    --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , PROGRAM_ID                                --�R���J�����g�E�v���O����ID
        , PROGRAM_UPDATE_DATE                       --�v���O�����X�V��
      ) VALUES (
          gt_check_data(ln_line_cnt).output_num     --�o�͔ԍ�
        , DECODE(gt_check_data(ln_line_cnt).output_rep, cn_both_rep, cn_bm_rep, gt_check_data(ln_line_cnt).output_rep)     --�o�͒��[
-- Ver.1.1 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--        , gt_check_data(ln_line_cnt).target_ym      --�Ώ۔N��
        , DECODE(gt_check_data(ln_line_cnt).output_rep, cn_sales_rep, gt_check_data(ln_line_cnt).target_ym
                                                                    , TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE(TO_CHAR(gt_check_data(ln_line_cnt).target_ym), cv_yyyymm), cn_one), cv_yyyymm))
                )  --�Ώ۔N��
-- Ver.1.1 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
        , gt_check_data(ln_line_cnt).vendor_code    --�d����R�[�h
        , gt_check_data(ln_line_cnt).customer_code  --�ڋq�R�[�h
        , cn_created_by                             --�쐬��
        , cd_creation_date                          --�쐬��
        , cn_last_updated_by                        --�ŏI�X�V��
        , cd_last_update_date                       --�ŏI�X�V��
        , cn_last_update_login                      --�ŏI�X�V���O�C��
        , cn_request_id                             --�v��ID
        , cn_program_application_id                 --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , cn_program_id                             --�R���J�����g�E�v���O����ID
        , cd_program_update_date                    --�v���O�����X�V��
      );
      --
      IF gt_check_data(ln_line_cnt).output_rep = cn_both_rep THEN
        INSERT INTO xxcok_bm_sales_rep_work (
            OUTPUT_NUM                                --�o�͔ԍ�
          , OUTPUT_REP                                --�o�͒��[
          , TARGET_YM                                 --�Ώ۔N��
          , VENDOR_CODE                               --�d����R�[�h
          , CUSTOMER_CODE                             --�ڋq�R�[�h
          , CREATED_BY                                --�쐬��
          , CREATION_DATE                             --�쐬��
          , LAST_UPDATED_BY                           --�ŏI�X�V��
          , LAST_UPDATE_DATE                          --�ŏI�X�V��
          , LAST_UPDATE_LOGIN                         --�ŏI�X�V���O�C��
          , REQUEST_ID                                --�v��ID
          , PROGRAM_APPLICATION_ID                    --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , PROGRAM_ID                                --�R���J�����g�E�v���O����ID
          , PROGRAM_UPDATE_DATE                       --�v���O�����X�V��
        ) VALUES (
            gt_check_data(ln_line_cnt).output_num     --�o�͔ԍ�
          , cn_sales_rep                              --�o�͒��[
          , gt_check_data(ln_line_cnt).target_ym      --�Ώ۔N��
          , gt_check_data(ln_line_cnt).vendor_code    --�d����R�[�h
          , gt_check_data(ln_line_cnt).customer_code  --�ڋq�R�[�h
          , cn_created_by                             --�쐬��
          , cd_creation_date                          --�쐬��
          , cn_last_updated_by                        --�ŏI�X�V��
          , cd_last_update_date                       --�ŏI�X�V��
          , cn_last_update_login                      --�ŏI�X�V���O�C��
          , cn_request_id                             --�v��ID
          , cn_program_application_id                 --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , cn_program_id                             --�R���J�����g�E�v���O����ID
          , cd_program_update_date                    --�v���O�����X�V��
        );
      END IF;
      --
    END LOOP ins_xbsrw_loop;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xbsrw;
  --
  /**********************************************************************************
   * Procedure Name   : chk_dupulicate_bm
   * Description      : �x���ē����̏o�͑Ώۏd���`�F�b�N(A-6)
   ***********************************************************************************/
  PROCEDURE chk_dupulicate_bm(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'chk_dupulicate_bm';     -- �v���O������
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �x���ē��� �o�͑Ώۏd���擾�J�[�\����`
    CURSOR dup_chk_cur(
      in_request_id IN NUMBER -- �v��ID
    ) IS
      SELECT xbsrw.output_num          AS output_num
            ,xbsrw.target_ym           AS target_ym
            ,cust_ven.customer_code    AS customer_code
            ,cust_ven.vendor_code      AS vendor_code
            ,COUNT(*)
      FROM xxcok_bm_sales_rep_work xbsrw
          ,( 
             SELECT /*+ INDEX(xca XXCMM_CUST_ACCOUNTS_N02) */
                    xca.customer_code            AS customer_code
                   ,xca.contractor_supplier_code AS vendor_code
             FROM   xxcmm_cust_accounts xca
                   ,xxcok_bm_sales_rep_work xbsrw
             WHERE xbsrw.request_id = in_request_id
             AND   xbsrw.output_rep = cn_bm_rep
             AND   xca.customer_code = NVL(xbsrw.customer_code, xca.customer_code)
             AND   xca.contractor_supplier_code = NVL(xbsrw.vendor_code, xca.contractor_supplier_code)
             UNION 
             SELECT /*+ INDEX(xca XXCMM_CUST_ACCOUNTS_N03) */
                    xca.customer_code         AS customer_code
                   ,xca.bm_pay_supplier_code1 AS vendor_code
             FROM   xxcmm_cust_accounts xca
                   ,xxcok_bm_sales_rep_work xbsrw
             WHERE xbsrw.request_id = in_request_id
             AND   xbsrw.output_rep = cn_bm_rep
             AND   xca.customer_code = NVL(xbsrw.customer_code, xca.customer_code)
             AND   xca.bm_pay_supplier_code1 = NVL(xbsrw.vendor_code, xca.bm_pay_supplier_code1)
             UNION 
             SELECT /*+ INDEX(xca XXCMM_CUST_ACCOUNTS_N04) */
                    xca.customer_code         AS customer_code
                   ,xca.bm_pay_supplier_code2 AS vendor_code
             FROM   xxcmm_cust_accounts xca
                   ,xxcok_bm_sales_rep_work xbsrw
             WHERE xbsrw.request_id = in_request_id
             AND   xbsrw.output_rep = cn_bm_rep
             AND   xca.customer_code = NVL(xbsrw.customer_code, xca.customer_code)
             AND   xca.bm_pay_supplier_code2 = NVL(xbsrw.vendor_code, xca.bm_pay_supplier_code2)
           ) cust_ven
      WHERE xbsrw.request_id = in_request_id
      AND   xbsrw.output_rep = cn_bm_rep
      AND   cust_ven.customer_code = NVL(xbsrw.customer_code, cust_ven.customer_code)
      AND   cust_ven.vendor_code = NVL(xbsrw.vendor_code, cust_ven.vendor_code)
      GROUP BY xbsrw.output_num
              ,xbsrw.target_ym
              ,cust_ven.customer_code
              ,cust_ven.vendor_code
      HAVING COUNT(*) > 1
      ;
    dup_chk_rec        dup_chk_cur%ROWTYPE;
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ln_line_cnt                    PLS_INTEGER;                                 -- CSV�����s�J�E���^
    ln_title                       NUMBER;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    ov_retcode := cv_status_normal;
    --
    --==================================================
    -- �o�͑Ώۂ̏d���擾
    --==================================================
    OPEN dup_chk_cur(
       cn_request_id
    );
    LOOP
      FETCH dup_chk_cur INTO dup_chk_rec;
      EXIT WHEN dup_chk_cur%NOTFOUND;
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok                -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_errmsg_10556                 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_output_num               -- �g�[�N���R�[�h1
                     , iv_token_value1 => TO_CHAR(dup_chk_rec.output_num) -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_target_date              -- �g�[�N���R�[�h1
                     , iv_token_value2 => TO_CHAR(dup_chk_rec.target_ym)  -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_vend_code                -- �g�[�N���R�[�h1
                     , iv_token_value3 => dup_chk_rec.vendor_code         -- �g�[�N���l3
                     , iv_token_name4  => cv_tkn_cust_code                -- �g�[�N���R�[�h1
                     , iv_token_value4 => dup_chk_rec.customer_code       -- �g�[�N���l4
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͒��[
                      ,iv_message    => lv_errmsg       -- ���b�Z�[�W
                      ,in_new_line   => cn_zero         -- ���s
                    );
      gn_error_cnt := gn_error_cnt + 1;
      ov_retcode := cv_status_check;
    END LOOP;
    --
    CLOSE dup_chk_cur;
    --
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_dupulicate_bm;
  --
  /**********************************************************************************
   * Procedure Name   : chk_validate_item�i���[�v���j
   * Description      : �Ó����`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
     ov_errbuf     OUT VARCHAR2                                          -- �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2                                          -- ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_index      IN  PLS_INTEGER                                       -- �s�ԍ�
    ,in_col_cnt    IN  NUMBER                                            -- ���ڐ�
    ,it_csv_data   IN  xxcok_common_pkg.g_split_csv_tbl
    ,ot_segment1   OUT xxcok_bm_sales_rep_work.output_num%TYPE           -- �`�F�b�N�㍀��1�F�o�͔ԍ�
    ,ot_segment2   OUT xxcok_bm_sales_rep_work.output_rep%TYPE           -- �`�F�b�N�㍀��2�F�o�͒��[
    ,ot_segment3   OUT xxcok_bm_sales_rep_work.target_ym%TYPE            -- �`�F�b�N�㍀��3�F�Ώ۔N��
    ,ot_segment4   OUT xxcok_bm_sales_rep_work.vendor_code%TYPE          -- �`�F�b�N�㍀��4�F�d����R�[�h
    ,ot_segment5   OUT xxcok_bm_sales_rep_work.customer_code%TYPE        -- �`�F�b�N�㍀��5�F�ڋq�R�[�h
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_validate_item'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf        VARCHAR2(5000);                                    -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);                                       -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_cnt           NUMBER;                                            -- �J�E���^
    lb_retcode       BOOLEAN;                                           -- API���^�[���E���b�Z�[�W�p
    lb_retbool       BOOLEAN;                                           -- API���^�[���E�`�F�b�N�p
    lv_out_msg       VARCHAR2(2000);                                    -- ���b�Z�[�W
    lv_buf           VARCHAR2(1);
    ld_target_ym     DATE;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    -------------------------------------------------
    -- ���ڐ��`�F�b�N
    -------------------------------------------------
    IF ( gn_item_cnt <> in_col_cnt ) THEN
      -- ���ڐ�����G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_errmsg_10547  -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row_num   -- �g�[�N���R�[�h1
                     , iv_token_value1 => in_index         -- �g�[�N���l1
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͒��[
                      ,iv_message    => lv_errmsg       -- ���b�Z�[�W
                      ,in_new_line   => cn_zero         -- ���s
                    );
      ov_retcode := cv_status_check;
    END IF;
    --
    IF ( ov_retcode = cv_status_check ) THEN
      RETURN;
    END IF;
    -------------------------------------------------
    -- ���ڃ`�F�b�N
    -------------------------------------------------
    -- ���ڃ`�F�b�N���[�v
    << item_check_loop >>
    FOR i IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
      --
      gt_csv_data(i) := TRIM( it_csv_data(i) );
      --
      -- ���ڃ`�F�b�N���ʊ֐�
      xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_chk_item_tab(i).meaning    -- ���ږ���
        , iv_item_value   => gt_csv_data(i)               -- ���ڂ̒l
        , in_item_len     => g_chk_item_tab(i).attribute1 -- ���ڂ̒���
        , in_item_decimal => g_chk_item_tab(i).attribute2 -- ���ڂ̒���(�����_�ȉ�)
        , iv_item_nullflg => g_chk_item_tab(i).attribute3 -- �K�{�t���O
        , iv_item_attr    => g_chk_item_tab(i).attribute4 -- ���ڑ���
        , ov_errbuf       => lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode      => lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg       => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- ���^�[���R�[�h������ȊO�̏ꍇ
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- ���ڕs���G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok            -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_errmsg_10548             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item                 -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_chk_item_tab(i).meaning   -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_record_no            -- �g�[�N���R�[�h2
                       , iv_token_value2 => in_index                    -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_errmsg               -- �g�[�N���R�[�h3
                       , iv_token_value3 => lv_errmsg                   -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_row_num              -- �g�[�N���R�[�h3
                       , iv_token_value4 => in_index                    -- �g�[�N���l3
                     );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͒��[
                        ,iv_message    => lv_errmsg       -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        --
        ov_retcode := cv_status_check;
        --
      END IF;
      --
    END LOOP item_check_loop;
    --
    -- ���ڃ��x���ŃG���[������΁A�ȍ~�̃`�F�b�N�̓X�L�b�v
    IF ( ov_retcode = cv_status_check ) THEN
      RETURN;
    END IF;
    -------------------------------------------------
    -- �o�͔ԍ�
    -------------------------------------------------
    ot_segment1 := TO_NUMBER(gt_csv_data(1));
    -------------------------------------------------
    -- �o�͒��[
    -------------------------------------------------
    --�Ó����`�F�b�N(1,2,3)
    IF gt_csv_data(2) NOT IN (cn_bm_rep, cn_sales_rep, cn_both_rep) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok       -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_errmsg_10549        -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row_num         -- �g�[�N���R�[�h1
                     , iv_token_value1 => in_index               -- �g�[�N���l1
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT          -- �o�͒��[
                      ,iv_message    => lv_errmsg                -- ���b�Z�[�W
                      ,in_new_line   => cn_zero                  -- ���s
                    );
      ov_retcode := cv_status_check;
    ELSE
      ot_segment2 := TO_NUMBER(gt_csv_data(2));
    END IF;
    --
    -------------------------------------------------
    -- �Ώ۔N��
    -------------------------------------------------
    --�Ó����`�F�b�N�iYYYYMM�����j
    BEGIN
      ld_target_ym := TO_DATE(gt_csv_data(3), cv_yyyymm);
      ot_segment3 := TO_NUMBER(TO_CHAR(ld_target_ym, cv_yyyymm));
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok       -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_errmsg_10550        -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_row_num         -- �g�[�N���R�[�h1
                       , iv_token_value1 => in_index               -- �g�[�N���l1
                     );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT          -- �o�͒��[
                        ,iv_message    => lv_errmsg                -- ���b�Z�[�W
                        ,in_new_line   => cn_zero                  -- ���s
                      );
        ov_retcode := cv_status_check;
    END;
    --
    -------------------------------------------------
    -- �d����R�[�h�A�ڋq�R�[�h
    -------------------------------------------------
    -- ����NULL�̓G���[
    IF gt_csv_data(4) IS NULL AND gt_csv_data(5) IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok         -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_errmsg_10551          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row_num           -- �g�[�N���R�[�h1
                     , iv_token_value1 => in_index                 -- �g�[�N���l1
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT            -- �o�͒��[
                      ,iv_message    => lv_errmsg                  -- ���b�Z�[�W
                      ,in_new_line   => cn_zero                    -- ���s
                    );
      ov_retcode := cv_status_check;
    END IF;
    --
    -------------------------------------------------
    -- �l���X�g���݃`�F�b�N
    -------------------------------------------------
    IF gt_csv_data(2) IN (cn_bm_rep, cn_both_rep) AND gt_csv_data(4) IS NOT NULL THEN
      --�x���ē����A�d����l���X�g���݃`�F�b�N
      BEGIN
        SELECT 'x'
        INTO   lv_buf
        FROM  po_vendors          pv
            , po_vendor_sites_all pvsa
        WHERE pv.vendor_id = pvsa.vendor_id
        AND   pvsa.attribute4 <> cv_no_bm
        AND   pvsa.org_id = fnd_global.org_id
        AND   pv.segment1 = gt_csv_data(4)
        AND   ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok       -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_errmsg_10552        -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_row_num         -- �g�[�N���R�[�h1
                         , iv_token_value1 => in_index               -- �g�[�N���l1
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT          -- �o�͒��[
                          ,iv_message    => lv_errmsg                -- ���b�Z�[�W
                          ,in_new_line   => cn_zero                  -- ���s
                        );
          ov_retcode := cv_status_check;
      END;
    END IF;
    --
    IF gt_csv_data(2) IN (cn_bm_rep, cn_both_rep) AND gt_csv_data(5) IS NOT NULL THEN
      --�x���ē����A�̎�����}�X�^���݃`�F�b�N
      BEGIN
        SELECT 'x'
        INTO   lv_buf
        FROM  xxcok_mst_bm_contract xmbc
        WHERE xmbc.calc_target_flag = cv_flag_y
        AND   xmbc.cust_code = gt_csv_data(5)
        AND   ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok       -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_errmsg_10553        -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_row_num         -- �g�[�N���R�[�h1
                         , iv_token_value1 => in_index               -- �g�[�N���l1
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT          -- �o�͒��[
                          ,iv_message    => lv_errmsg                -- ���b�Z�[�W
                          ,in_new_line   => cn_zero                  -- ���s
                        );
          ov_retcode := cv_status_check;
      END;
    END IF;
    --
    IF gt_csv_data(2) IN (cn_sales_rep, cn_both_rep) AND gt_csv_data(4) IS NOT NULL AND gt_csv_data(5) IS NULL THEN
      --�̔��񍐏��A�d����l���X�g���݃`�F�b�N
      BEGIN
        SELECT 'x'
        INTO   lv_buf
        FROM  xxcos_vd_sales_vend_all_v xvsvav
        WHERE xvsvav.vendor_code = gt_csv_data(4)
        AND   ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok       -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_errmsg_10554        -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_row_num         -- �g�[�N���R�[�h1
                         , iv_token_value1 => in_index               -- �g�[�N���l1
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT          -- �o�͒��[
                          ,iv_message    => lv_errmsg                -- ���b�Z�[�W
                          ,in_new_line   => cn_zero                  -- ���s
                        );
          ov_retcode := cv_status_check;
      END;
    END IF;
    --
    IF gt_csv_data(2) IN (cn_sales_rep, cn_both_rep) AND gt_csv_data(5) IS NOT NULL THEN
      --�̔��񍐏��A�ڋq�l���X�g���݃`�F�b�N
      BEGIN
        SELECT 'x'
        INTO   lv_buf
        FROM  xxcos_vd_sales_cust_v xvscv
        WHERE xvscv.customer_code = gt_csv_data(5)
        AND   ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok       -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_errmsg_10555        -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_row_num         -- �g�[�N���R�[�h1
                         , iv_token_value1 => in_index               -- �g�[�N���l1
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT          -- �o�͒��[
                          ,iv_message    => lv_errmsg                -- ���b�Z�[�W
                          ,in_new_line   => cn_zero                  -- ���s
                        );
          ov_retcode := cv_status_check;
      END;
    END IF;
    --�������ݒ�ł��A�G���[�̏ꍇ�͎g�p����Ȃ�
    ot_segment4 := gt_csv_data(4);
    ot_segment5 := gt_csv_data(5);
  --
  EXCEPTION
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END chk_validate_item;
  --
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
     ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_file_id IN  VARCHAR2 -- �t�@�C��ID
    ,iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
    cv_tkn_lookup_value_set   CONSTANT VARCHAR2(20)  := 'LOOKUP_VALUE_SET';         -- �^�C�v
    cv_bm_sales_rep_item      CONSTANT VARCHAR2(30)  := 'XXCOK1_BM_SALES_REP_ITEM'; -- �x���ē����E�̔��񍐏��ꊇ�o�͍��ڃ`�F�b�N
    ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf      VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg     VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode     BOOLEAN;        -- ���b�Z�[�W�߂�l
    lv_conc        VARCHAR2(50);   -- �R���J�����g�Z�k��
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- ���ڃ`�F�b�N�J�[�\��
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning       AS meaning     -- ���ږ���
           , flv.attribute1    AS attribute1  -- ���ڂ̒���
           , flv.attribute2    AS attribute2  -- ���ڂ̒����i�����_�ȉ��j
           , flv.attribute3    AS attribute3  -- �K�{�t���O
           , flv.attribute4    AS attribute4  -- ����
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_bm_sales_rep_item
      AND    gd_proc_date BETWEEN NVL( flv.start_date_active, gd_proc_date )
                              AND NVL( flv.end_date_active, gd_proc_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
    ;
    --===============================
    -- ���[�J����O
    --===============================
    get_date_err_expt           EXCEPTION; -- �Ɩ��������t�擾�G���[
    get_item_chk_lookup_expt    EXCEPTION; -- ���ڃ`�F�b�N�p�N�C�b�N�R�[�h�擾�G���[
    global_api_others_expt      EXCEPTION; -- API�G���[
    get_prof_err_expt           EXCEPTION; -- �v���t�@�C���擾�G���[
    get_conc_name_err_expt      EXCEPTION; -- �R���J�����g���擾�G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    -------------------------------------------------
    -- 1.�R���J�����g���̓p�����[�^���b�Z�[�W�o��
    -------------------------------------------------
    -- �R���J�����g�p�����[�^.�t�@�C��ID���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00016
                    ,iv_token_name1  => cv_tkn_file_id
                    ,iv_token_value1 => TO_CHAR(in_file_id)
                  );
    -- �R���J�����g�p�����[�^.�t�@�C��ID���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͒��[
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_zero         -- ���s
                  );
    -- �R���J�����g�p�����[�^.�t�H�[�}�b�g�p�^�[�����b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00017
                    ,iv_token_name1  => cv_tkn_format
                    ,iv_token_value1 => iv_format
                  );
    -- �R���J�����g�p�����[�^.�t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͒��[
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_one          -- ���s
                  );
    -------------------------------------------------
    -- 2.�Ɩ��������t�擾
    -------------------------------------------------
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    -- NULL�̏ꍇ�̓G���[
    IF ( gd_proc_date IS NULL ) THEN
      RAISE get_date_err_expt;
    END IF;
    --
    -------------------------------------------------
    -- 3.���ڃ`�F�b�N�p��`�擾
    -------------------------------------------------
    --�J�[�\���̃I�[�v��
    OPEN chk_item_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    -- �J�[�\���N���[�Y
    CLOSE chk_item_cur;
    -- �N�C�b�N�R�[�h���擾�ł��Ȃ��ꍇ
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      RAISE get_item_chk_lookup_expt;
    END IF;
    --
    gn_item_cnt := g_chk_item_tab.COUNT;  --���ڐ��擾
--
    -------------------------------------------------
    -- 4.�R���J�����g���擾
    -------------------------------------------------
    BEGIN
      lv_conc := cv_bm_rep_conc;
      SELECT user_concurrent_program_name
      INTO gt_bm_rep_conc_name
      FROM fnd_concurrent_programs_vl
      WHERE concurrent_program_name = lv_conc
      AND   enabled_flag = cv_yes
      ;
      --
      lv_conc := cv_sales_rep_conc;
      SELECT user_concurrent_program_name
      INTO gt_sales_rep_conc_name
      FROM fnd_concurrent_programs_vl
      WHERE concurrent_program_name = lv_conc
      AND   enabled_flag = cv_yes
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_conc_name_err_expt;
    END;
    --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �Ɩ��������t�擾��O�n���h��
    ----------------------------------------------------------
    WHEN get_date_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00028
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͒��[
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ڃ`�F�b�N�p�N�C�b�N�R�[�h�擾��O�n���h��
    ----------------------------------------------------------
    WHEN get_item_chk_lookup_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok          -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_errmsg_00015           -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_lookup_value_set   -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_bm_sales_rep_item      -- �g�[�N���l1
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͒��[
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- �R���J�����g���擾��O�n���h��
    ----------------------------------------------------------
    WHEN get_conc_name_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_10560
                      ,iv_token_name1  => cv_tkn_conc
                      ,iv_token_value1 => lv_conc
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͒��[
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END init_proc;
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    ,iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �����o�͑Ώێ擾�J�[�\����`
    CURSOR split_conc_cur
    IS
      SELECT xbsrw.output_rep AS output_rep
            ,xbsrw.output_num AS output_num
      FROM  xxcok_bm_sales_rep_work xbsrw
      WHERE request_id = cn_request_id
      GROUP BY xbsrw.output_rep
              ,xbsrw.output_num
      ORDER BY output_rep
              ,output_num
      ;
    split_conc_rec        split_conc_cur%ROWTYPE;
    -- �ꊇ�o�͑Ώێ擾�J�[�\����`
    CURSOR lump_conc_cur
    IS
      SELECT xbsrw.output_rep AS output_rep
      FROM  xxcok_bm_sales_rep_work xbsrw
      WHERE request_id = cn_request_id
      GROUP BY xbsrw.output_rep
      ORDER BY output_rep
      ;
    lump_conc_rec        lump_conc_cur%ROWTYPE;
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf                 VARCHAR2(5000);                                    -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                       -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000);                                    -- ���b�Z�[�W
    lb_retcode                BOOLEAN;                                           -- ���b�Z�[�W�߂�l
    lt_file_id                xxccp_mrp_file_ul_interface.file_id%TYPE;          -- �t�@�C��ID
    lt_format                 xxccp_mrp_file_ul_interface.file_format%TYPE;      -- �t�H�[�}�b�g
    -- BLOB�ϊ���f�[�^������ޔ�p
    ln_col_cnt                PLS_INTEGER := 0;                                  -- CSV���ڐ�
    ln_row_cnt                PLS_INTEGER := 1;                                  -- CSV�s��
    ln_line_cnt               PLS_INTEGER := 0;                                  -- CSV�����s�J�E���^
    lt_csv_data               xxcok_common_pkg.g_split_csv_tbl;                  -- CSV�����f�[�^
    lt_file_data              xxccp_common_pkg2.g_file_data_tbl;                 -- BLOB�ϊ���f�[�^�ޔ�(�󔒍s�r����)
    lt_file_data_all          xxccp_common_pkg2.g_file_data_tbl;                 -- BLOB�ϊ���f�[�^�ޔ�(�S�f�[�^)
    --
    lt_output_num             xxcok_bm_sales_rep_work.output_num%TYPE;           -- �`�F�b�N�㍀��1�F�o�͔ԍ�
    lt_output_rep             xxcok_bm_sales_rep_work.output_rep%TYPE;           -- �`�F�b�N�㍀��2�F�o�͒��[
    lt_target_ym              xxcok_bm_sales_rep_work.target_ym%TYPE;            -- �`�F�b�N�㍀��3�F�Ώ۔N��
    lt_vendor_code            xxcok_bm_sales_rep_work.vendor_code%TYPE;          -- �`�F�b�N�㍀��4�F�d����R�[�h
    lt_customer_code          xxcok_bm_sales_rep_work.customer_code%TYPE;        -- �`�F�b�N�㍀��5�F�ڋq�R�[�h
    ln_cnt                    NUMBER;
    --===============================
    -- ���[�J����O
    --===============================
    blob_err_expt    EXCEPTION; -- BLOB�ϊ��G���[
    no_data_err_expt EXCEPTION; -- �A�b�v���[�h�����ΏۂȂ��G���[
    proc_err_expt    EXCEPTION; -- �ďo���v���O�����̃G���[
  --
  BEGIN
  --
    --===============================================
    -- A-0.������
    --===============================================
    ov_retcode := cv_status_normal;
    lt_file_id := TO_NUMBER(TRUNC(iv_file_id));
    lt_format  := iv_format;
    lt_file_data.delete;
    lt_file_data_all.delete;
    --===============================================
    -- A-1.��������
    --===============================================
    --
    init_proc(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,in_file_id => lt_file_id -- �t�@�C��ID
      ,iv_format  => lt_format  -- �t�H�[�}�b�g
    );
    -- �X�e�[�^�X�G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-2.�t�@�C���A�b�v���[�h�f�[�^�擾
    --===============================================
    --
    -- 1.BLOB�f�[�^�ϊ�
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => lt_file_id       -- �t�@�C��ID
      ,ov_file_data => lt_file_data_all -- BLOB�ϊ���f�[�^�ޔ�(��s,���o������)
      ,ov_errbuf    => lv_errbuf        -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode       -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    -- �X�e�[�^�X�G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE blob_err_expt;
    END IF;
    -- �擾�����f�[�^����A�󔒍s(�J���}�݂̂̍s)��r������
    << blob_data_loop >>
    FOR i IN 2..lt_file_data_all.COUNT LOOP
      IF ( LENGTHB( REPLACE( lt_file_data_all(i), ',', '') ) <> cn_zero ) THEN
        ln_line_cnt := ln_line_cnt + cn_one;
        lt_file_data(ln_line_cnt) := lt_file_data_all(i);  --��s,���o�����O����
      END IF;
    END LOOP blob_data_loop;
    -- �ҏW�p�̃e�[�u���폜
    lt_file_data_all.delete;
    -- CSV�����s�J�E���^������
    ln_line_cnt := cn_zero;
    -- �����Ώی�����ޔ�
    gn_target_cnt := lt_file_data.COUNT;
    -- �����Ώۑ��݃`�F�b�N
    IF ( gn_target_cnt <= cn_zero ) THEN
      RAISE no_data_err_expt;
    END IF;
    -- 2.BLOB�ϊ���f�[�^�`�F�b�N���[�v
    << blob_data_check_loop >>
    FOR ln_line_cnt IN 1..lt_file_data.COUNT LOOP  --��s�A���o���Ȃ�
      --===============================================
      -- A-3.�t�@�C���A�b�v���[�h�f�[�^�ϊ�
      --===============================================
      --
      -- 1.CSV�����񕪊�
       xxcok_common_pkg.split_csv_data_p(
         ov_errbuf        => lv_errbuf                 -- �G���[�E���b�Z�[�W
        ,ov_retcode       => lv_retcode                -- ���^�[���E�R�[�h
        ,ov_errmsg        => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,iv_csv_data      => lt_file_data(ln_line_cnt) -- CSV������i�A�b�v���[�h1�s�j
        ,on_csv_col_cnt   => ln_col_cnt                -- CSV���ڐ�
        ,ov_split_csv_tab => lt_csv_data               -- CSV�����f�[�^�i�z��ŕԂ��j
      );
      -- �X�e�[�^�X�G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE proc_err_expt;
      END IF;
      --
      --===============================================
      -- A-4.�Ó����`�F�b�N����
      --===============================================
      chk_validate_item(
           ov_errbuf    => lv_errbuf             -- �G���[�E���b�Z�[�W
          ,ov_retcode   => lv_retcode            -- ���^�[���E�R�[�h
          ,ov_errmsg    => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,in_index     => ln_line_cnt           -- �s�ԍ�
          ,in_col_cnt   => ln_col_cnt            -- CSV���ڐ�
          ,it_csv_data  => lt_csv_data           -- CSV�����f�[�^
          ,ot_segment1  => lt_output_num         -- �`�F�b�N�㍀��1�F�o�͔ԍ�
          ,ot_segment2  => lt_output_rep         -- �`�F�b�N�㍀��2�F�o�͒��[
          ,ot_segment3  => lt_target_ym          -- �`�F�b�N�㍀��3�F�Ώ۔N��
          ,ot_segment4  => lt_vendor_code        -- �`�F�b�N�㍀��4�F�d����R�[�h
          ,ot_segment5  => lt_customer_code      -- �`�F�b�N�㍀��5�F�ڋq�R�[�h
      );
      --
      -- �X�e�[�^�X�G���[����F���펞
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ����f�[�^�ޔ�
        gt_check_data(ln_row_cnt).output_num    := lt_output_num;
        gt_check_data(ln_row_cnt).output_rep    := lt_output_rep;
        gt_check_data(ln_row_cnt).target_ym     := lt_target_ym;
        gt_check_data(ln_row_cnt).vendor_code   := lt_vendor_code;
        gt_check_data(ln_row_cnt).customer_code := lt_customer_code;
        --
        ln_row_cnt := ln_row_cnt + 1;
      -- �X�e�[�^�X�G���[����F�`�F�b�N�G���[��
      ELSIF ( lv_retcode = cv_status_check ) THEN
        -- �G���[�������C���N�������g
        gn_error_cnt := gn_error_cnt + 1;
        ov_retcode := cv_status_check;
      -- �X�e�[�^�X�G���[����F�G���[��
      ELSE
        -- �G���[�I��
        RAISE proc_err_expt;
      END IF;
    --
    END LOOP;
    --
    -- ===============================
    -- A-5.�x���ē����A�̔��񍐏��o�͑Ώۃ��[�N�o�^
    -- ===============================
    IF ( ov_retcode = cv_status_normal ) THEN
      --
      insert_xbsrw(
        ov_errbuf     => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �X�e�[�^�X�G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE proc_err_expt;
      END IF;
      --
    END IF;
    -- ===============================
    -- A-6.�x���ē����̏o�͑Ώۏd���`�F�b�N
    -- ===============================
    IF ( ov_retcode = cv_status_normal ) THEN
      --
      chk_dupulicate_bm(
        ov_errbuf     => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �X�e�[�^�X�G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE proc_err_expt;
      ELSIF ( lv_retcode = cv_status_check ) THEN
        ROLLBACK;  --�o�͑Ώۃ��[�N�o�^�𖳌���
        ov_retcode := cv_status_check;
      END IF;
      --
    END IF;
    --===============================================
    -- A-7.�R���J�����g���s
    --===============================================
    IF ( ov_retcode = cv_status_normal ) THEN
      --
      IF iv_format = cv_file_id_split THEN
        -- ===============================
        -- �����o�͂̃R���J�����g���s
        -- ===============================
        OPEN split_conc_cur;
        LOOP
          FETCH split_conc_cur INTO split_conc_rec;
          EXIT WHEN split_conc_cur%NOTFOUND;
          --
          IF split_conc_rec.output_rep = cn_bm_rep THEN
            --�x���ē����R���J�����g���s
            submit_conc_bm_rep(
              ov_errbuf     => lv_errbuf                          -- �G���[�E���b�Z�[�W
             ,ov_retcode    => lv_retcode                         -- ���^�[���E�R�[�h
             ,ov_errmsg     => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
             ,in_output_num => split_conc_rec.output_num          -- �o�͔ԍ�
            );
          ELSIF split_conc_rec.output_rep = cn_sales_rep THEN
            --�̔��񍐏��R���J�����g���s
            submit_conc_sales_rep(
              ov_errbuf     => lv_errbuf                          -- �G���[�E���b�Z�[�W
             ,ov_retcode    => lv_retcode                         -- ���^�[���E�R�[�h
             ,ov_errmsg     => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
             ,in_output_num => split_conc_rec.output_num          -- �o�͔ԍ�
            );
          END IF;
          -- �X�e�[�^�X�G���[����
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE proc_err_expt;
          END IF;
          --
        END LOOP;
        CLOSE split_conc_cur;
        --
      ELSE
        -- ===============================
        -- �ꊇ�o�͂̃R���J�����g���s
        -- ===============================
        OPEN lump_conc_cur;
        LOOP
          FETCH lump_conc_cur INTO lump_conc_rec;
          EXIT WHEN lump_conc_cur%NOTFOUND;
          --
          IF lump_conc_rec.output_rep = cn_bm_rep THEN
            --�x���ē����R���J�����g���s
            submit_conc_bm_rep(
              ov_errbuf     => lv_errbuf           -- �G���[�E���b�Z�[�W
             ,ov_retcode    => lv_retcode          -- ���^�[���E�R�[�h
             ,ov_errmsg     => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
             ,in_output_num => NULL                -- �o�͔ԍ�
            );
          ELSIF lump_conc_rec.output_rep = cn_sales_rep THEN
            --�̔��񍐏��R���J�����g���s
            submit_conc_sales_rep(
              ov_errbuf     => lv_errbuf           -- �G���[�E���b�Z�[�W
             ,ov_retcode    => lv_retcode          -- ���^�[���E�R�[�h
             ,ov_errmsg     => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
             ,in_output_num => NULL                -- �o�͔ԍ�
            );
          END IF;
          -- �X�e�[�^�X�G���[����
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE proc_err_expt;
          END IF;
          --
        END LOOP;
        CLOSE lump_conc_cur;
        --
      END IF;
      --
    END IF;
    --===============================================
    -- A-8.�t�@�C���A�b�v���[�h�f�[�^�̍폜
    --===============================================
    del_file_upload_data(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
      ,in_file_id => lt_file_id -- �t�@�C��ID
    );
    -- �X�e�[�^�X�G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE proc_err_expt;
    ELSE
      -- �`�F�b�N�G���[�̏ꍇ�A�ُ�I��������̂ł�����COMMIT
      COMMIT;
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- BLOB�ϊ���O�n���h��
    ----------------------------------------------------------
    WHEN blob_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00041
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(lt_file_id)
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͒��[
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- �A�b�v���[�h�����ΏۂȂ���O�n���h��
    ----------------------------------------------------------
    WHEN no_data_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_10558
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͋敪
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- �T�u�v���O������O�n���h��
    ----------------------------------------------------------
    WHEN proc_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END submain;
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
     errbuf     OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,retcode    OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    ,iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000);  -- ���b�Z�[�W
    lv_message_code VARCHAR2(5000);  -- �����I�����b�Z�[�W
    lb_retcode      BOOLEAN;         -- ���b�Z�[�W�߂�l
  --
  BEGIN
  --
    --===============================================
    -- ������
    --===============================================
    lv_out_msg := NULL;
    --===============================================
    -- �R���J�����g�w�b�_�o��
    --===============================================
    --
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͒��[
                    ,iv_message    => NULL            -- ���b�Z�[�W
                    ,in_new_line   => cn_one          -- ���s
                  );
    --
    --===============================================
    -- �T�u���C������
    --===============================================
    --
    submain(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_file_id => iv_file_id -- �t�@�C��ID
      ,iv_format  => iv_format  -- �t�H�[�}�b�g
    );
    --
    IF ( lv_retcode = cv_status_normal ) THEN
      gn_normal_cnt := gn_target_cnt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.LOG    -- �o�͒��[
                      ,iv_message    => lv_errbuf       -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      -- �G���[�����������ݒ�
      gn_normal_cnt := cn_zero; -- ���팏��
      gn_error_cnt  := cn_one;  -- �G���[����
    END IF;
    --
    --===============================================
    -- �I������
    --===============================================
    -------------------------------------------------
    -- 1.�Ώی������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͒��[
                    ,iv_message    => ' '             -- ���b�Z�[�W
                    ,in_new_line   => cn_zero         -- ���s
                  );
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͒��[
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_zero         -- ���s
                  );
    -------------------------------------------------
    -- 2.�����������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͒��[
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_zero         -- ���s
                  );
    -------------------------------------------------
    -- 3.�����������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͒��[
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_one          -- ���s
                  );
    -------------------------------------------------
    -- 4.�I�����b�Z�[�W�o��
    -------------------------------------------------
    -- �I�����b�Z�[�W���f
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    ELSIF ( lv_retcode = cv_status_check ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => lv_message_code
                   );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͒��[
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_zero         -- ���s
                  );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  --
  END main;
  --
END XXCOK015A04C;
/
