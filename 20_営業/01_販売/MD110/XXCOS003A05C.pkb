CREATE OR REPLACE PACKAGE BODY XXCOS003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A05C(body)
 * Description      : �P���}�X�^IF�o�́i�t�@�C���쐬�j
 * MD.050           : �P���}�X�^IF�o�́i�t�@�C���쐬�j MD050_COS_003_A05
 * Version          : 1.4
 *
 * Program List     
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  proc_break_process     �󒍃w�b�_���ID�u���C�N��̏����i�t�@�C���o�́A�X�e�[�^�X�X�V�j
 *  proc_main_loop         ���[�v�� A-2�f�[�^���o
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05   1.0    K.Okaguchi       �V�K�쐬
 *  2009/01/17   1.1    K.Okaguchi       [��QCOS_124] �t�@�C���o�͕ҏW�̃o�O���C��
 *  2009/02/24   1.2    T.Nakamura       [��QCOS_130] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/04/15   1.3    N.Maeda          [ST��QNo.T1_0067�Ή�] �t�@�C���o�͎���CHAR�^VARCHAR�^�ȊO�ւ̢"��t���̍폜
 *  2009/04/22   1.4    N.Maeda          [ST��QNo.T1_0754�Ή�]�t�@�C���o�͎��̢"��t���C��
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
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER DEFAULT 0;                    -- �Ώی���
  gn_normal_cnt    NUMBER DEFAULT 0;                    -- ���팏��
  gn_error_cnt     NUMBER DEFAULT 0;                    -- �G���[����
  gn_warn_cnt      NUMBER DEFAULT 0;                    -- �X�L�b�v����
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
  global_data_check_expt    EXCEPTION;     -- �f�[�^�`�F�b�N���̃G���[
  file_open_expt            EXCEPTION;     -- �t�@�C���I�[�v���G���[
  update_expt               EXCEPTION;     -- �X�V�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A05C'; -- �p�b�P�[�W��
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- �A�v���P�[�V������
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_delimit              CONSTANT VARCHAR2(1)  := ',';            -- ��؂蕶��
  cv_quot                 CONSTANT VARCHAR2(1)  := '"';            -- �R�[�e�[�V����
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_brank                CONSTANT VARCHAR2(1)  := ' ';
  cv_minus                CONSTANT VARCHAR2(1)  := '-';
  cv_flag_off             CONSTANT VARCHAR2(1)  := 'N';
  cv_tkn_lock             CONSTANT VARCHAR2(20) := 'TABLE';               -- ���b�N�G���[
  cv_flag_on              CONSTANT VARCHAR2(1)  := 'Y';
  cv_tkn_filename         CONSTANT VARCHAR2(20) := 'FILE_NAME';
  cn_lock_error_code      CONSTANT NUMBER       := -54;
  cv_msg_lock             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    --���b�N�擾�G���[
  cv_msg_pro              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    --�v���t�@�C���擾�G���[
  cv_msg_file_open        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00009';    --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_update_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    --�f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_filename         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00044';    --�t�@�C�����i�^�C�g���j
  cv_tkn_dir_path         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10662';    -- HHT�A�E�g�o�E���h�p�f�B���N�g���p�X
  cv_tkn_tm_filename      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10851';    -- �P���}�X�^�t�@�C����
  cv_tkn_tm_w_tbl         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10852';    -- �P���}�X�^���[�N�e�[�u��  
  cv_tkn_cust_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10853';    -- �ڋq�R�[�h
  cv_tkn_item_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10854';    -- �i���R�[�h
  cv_no_parameter         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- �p�����[�^�Ȃ�
  cv_prf_dir_path         CONSTANT VARCHAR2(50) := 'XXCOS1_OUTBOUND_HHT_DIR';      -- HHT�A�E�g�o�E���h�p�f�B���N�g���p�X
  cv_prf_tm_filename      CONSTANT VARCHAR2(50) := 'XXCOS1_UNIT_PRICE_M_FILE_NAME';-- �P���}�X�^�t�@�C����
  cv_tkn_profile          CONSTANT VARCHAR2(20) := 'PROFILE';                -- �v���t�@�C����
  cv_tkn_file_name        CONSTANT VARCHAR2(20) := 'FILE_NAME';              -- �t�@�C����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_key_info                 fnd_new_messages.message_text%TYPE   ;--���b�Z�[�W�o�͗p�L�[���
  gv_msg_tkn_dir_path         fnd_new_messages.message_text%TYPE   ;--'HHT�A�E�g�o�E���h�p�f�B���N�g���p�X'
  gv_msg_tkn_tm_filename      fnd_new_messages.message_text%TYPE   ;--'�P���}�X�^�t�@�C����'��
  gv_msg_tkn_tm_w_tbl         fnd_new_messages.message_text%TYPE   ;--'�P���}�X�^���[�N�e�[�u��'��
  gv_msg_tkn_cust_code        fnd_new_messages.message_text%TYPE   ;--'�ڋq�R�[�h'��
  gv_msg_tkn_item_code        fnd_new_messages.message_text%TYPE   ;--'�i���R�[�h'��
  gv_tm_file_data             VARCHAR2(2000);
  gd_process_date             DATE;
--
--�J�[�\��
  CURSOR main_cur
  IS
    SELECT 
           xupw.customer_number          customer_number            --�ڋq�R�[�h
         , xupw.item_code                item_code                  --�i���R�[�h
         , xupw.nml_prev_unit_price      nml_prev_unit_price        --�ʏ�@�O��@�P���@
         , xupw.nml_prev_dlv_date        nml_prev_dlv_date          --�ʏ�@�O��@�[�i�N�����@
         , xupw.nml_prev_qty             nml_prev_qty               --�ʏ�@�O��@���ʁ@
         , xupw.nml_bef_prev_dlv_date    nml_bef_prev_dlv_date      --�ʏ�@�O�X��@�[�i�N�����@
         , xupw.nml_bef_prev_qty         nml_bef_prev_qty           --�ʏ�@�O�X��@���ʁ@
         , xupw.sls_prev_unit_price      sls_prev_unit_price        --�����@�O��@�P���@
         , xupw.sls_prev_dlv_date        sls_prev_dlv_date          --�����@�O��@�[�i�N�����@
         , xupw.sls_prev_qty             sls_prev_qty               --�����@�O��@���ʁ@
         , xupw.sls_bef_prev_dlv_date    sls_bef_prev_dlv_date      --�����@�O�X��@�[�i�N�����@
         , xupw.sls_bef_prev_qty         sls_bef_prev_qty           --�����@�O�X��@���ʁ@
    FROM   xxcos_unit_price_mst_work     xupw                       --�P���}�X�^���[�N�e�[�u��
    WHERE 
          xupw.file_output_flag           =  cv_flag_off            --���o��
    ORDER BY 
          xupw.customer_number 
        , xupw.item_code
    FOR UPDATE NOWAIT
    ;
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  g_tm_handle       UTL_FILE.FILE_TYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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

    -- *** ���[�J���ϐ� ***
--
    lv_dir_path                 VARCHAR2(100);                -- HHT�A�E�g�o�E���h�p�f�B���N�g���p�X
    lv_tm_filename              VARCHAR2(100);                -- �P���}�X�^�t�@�C����

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

-- 2009/02/24 T.Nakamura Ver.1.2 add start
    --��s
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --==============================================================
    -- �u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_no_parameter
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --��s
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
                     

    --==============================================================
    -- �}���`�o�C�g�̌Œ�l�����b�Z�[�W���擾
    --==============================================================
    gv_msg_tkn_dir_path         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_dir_path
                                                           );
    gv_msg_tkn_tm_filename      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_tm_filename
                                                           );
    gv_msg_tkn_tm_w_tbl         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_tm_w_tbl
                                                           );
    gv_msg_tkn_cust_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_cust_code
                                                           );
    gv_msg_tkn_item_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_item_code
                                                           );
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:HHT�A�E�g�o�E���h�p�f�B���N�g���p�X)
    --==============================================================
    lv_dir_path := FND_PROFILE.VALUE(cv_prf_dir_path);
    
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF (lv_dir_path IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_dir_path
                                           );

      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�P���}�X�^�t�@�C����)
    --==============================================================
    lv_tm_filename := FND_PROFILE.VALUE(cv_prf_tm_filename);
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF (lv_tm_filename IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_tm_filename
                                           );

      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- �t�@�C�����̃��O�o��
    --==============================================================
    --�P���}�X�^�t�@�C����
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                          ,iv_name         => cv_msg_filename
                                          ,iv_token_name1  => cv_tkn_filename
                                          ,iv_token_value1 => lv_tm_filename
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
                     
    --��s
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );

    --==============================================================
    -- �P���}�X�^�t�@�C���@�t�@�C���I�[�v��
    --==============================================================
    BEGIN
      g_tm_handle := UTL_FILE.FOPEN(lv_dir_path
                                  , lv_tm_filename
                                  , 'w');
    EXCEPTION
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_file_open
                                            , cv_tkn_file_name
                                            , lv_tm_filename);
        RAISE file_open_expt;
    END;
    
    --==============================================================
    -- �Ɩ����t�擾����N�O���擾
    --==============================================================
    gd_process_date := ADD_MONTHS(xxccp_common_pkg2.get_process_date,-12);
--
  EXCEPTION
    WHEN file_open_expt THEN
      ov_errbuf := ov_errbuf || ov_errmsg;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
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
   * Procedure Name   : proc_main_loop�i���[�v���j
   * Description      : A-2�f�[�^���o
   ***********************************************************************************/
  PROCEDURE proc_main_loop(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_main_loop'; -- ���C�����[�v����
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_message_code          VARCHAR2(20);
    lv_nml_prev_unit_price   VARCHAR2(7);--�ʏ�O��P��
    lv_nml_prev_qty_sign     VARCHAR2(1);--�ʏ�O�񐔗ʃT�C��
    lv_nml_prev_qty          VARCHAR2(5);--�ʏ�O�񐔗�
    lv_nml_prev_dlv_date     VARCHAR2(8);--�ʏ�O��[�i�N����
    lv_nml_bef_prev_qty_sign VARCHAR2(1);--�ʏ�O�X�񐔗ʃT�C��
    lv_nml_bef_prev_qty      VARCHAR2(5);--�ʏ�O�X�񐔗�
    lv_nml_bef_prev_dlv_date VARCHAR2(8);--�ʏ�O�X��[�i�N����
    lv_sls_prev_unit_price   VARCHAR2(7);--�����O��P��
    lv_sls_prev_qty_sign     VARCHAR2(1);--�����O�񐔗ʃT�C��
    lv_sls_prev_qty          VARCHAR2(5);--�����O�񐔗�
    lv_sls_prev_dlv_date     VARCHAR2(8);--�����O��[�i�N����
    lv_sls_bef_prev_qty_sign VARCHAR2(1);--�����O�X�񐔗ʃT�C��
    lv_sls_bef_prev_qty      VARCHAR2(5);--�����O�X�񐔗�
    lv_sls_bef_prev_dlv_date VARCHAR2(8);--�����O�X��[�i�N����
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    <<main_loop>>
    FOR main_rec in main_cur LOOP
      -- ===============================
      -- A-3 �P���}�X�^�t�@�C���o��
      -- ===============================
  --�f�[�^�ҏW
     --�ʏ�@�O��@���ʃT�C��
      IF (main_rec.nml_prev_qty < 0) THEN
        lv_nml_prev_qty_sign := cv_minus;
        lv_nml_prev_qty      := TO_CHAR(main_rec.nml_prev_qty * -1);
      ELSE
        lv_nml_prev_qty_sign := cv_brank;
        lv_nml_prev_qty      := TO_CHAR(main_rec.nml_prev_qty);
      END IF;
     --�ʏ�@�O�X��@���ʃT�C��
      IF (main_rec.nml_bef_prev_qty < 0) THEN
        lv_nml_bef_prev_qty_sign := cv_minus;
        lv_nml_bef_prev_qty      := TO_CHAR(main_rec.nml_bef_prev_qty * -1);
      ELSE
        lv_nml_bef_prev_qty_sign := cv_brank;
        lv_nml_bef_prev_qty      := TO_CHAR(main_rec.nml_bef_prev_qty);
      END IF;
     --�����@�O��@���ʃT�C��
      IF (main_rec.sls_prev_qty < 0) THEN
        lv_sls_prev_qty_sign := cv_minus;
        lv_sls_prev_qty      := TO_CHAR(main_rec.sls_prev_qty * -1);
      ELSE
        lv_sls_prev_qty_sign := cv_brank;        
        lv_sls_prev_qty      := TO_CHAR(main_rec.sls_prev_qty);
      END IF;
     --�����@�O�X��@���ʃT�C��
      IF (main_rec.sls_bef_prev_qty < 0) THEN
        lv_sls_bef_prev_qty_sign := cv_minus;
        lv_sls_bef_prev_qty      := TO_CHAR(main_rec.sls_bef_prev_qty * -1);
      ELSE
        lv_sls_bef_prev_qty_sign := cv_brank;        
        lv_sls_bef_prev_qty      := TO_CHAR(main_rec.sls_bef_prev_qty);
      END IF;
     --�ʏ�@�O��@�[�i�N�������������i�o�b�`���t�j����N���߂��Ă���ꍇ�͐ݒ���s���܂���B
      IF gd_process_date > main_rec.nml_prev_dlv_date THEN
        lv_nml_prev_unit_price := NULL;--�ʏ�O��P��
        lv_nml_prev_qty_sign   := NULL;--�ʏ�O�񐔗ʃT�C��
        lv_nml_prev_qty        := NULL;--�ʏ�O�񐔗�
        lv_nml_prev_dlv_date   := NULL;--�ʏ�O��[�i�N����
      ELSE
        lv_nml_prev_unit_price := TO_CHAR(main_rec.nml_prev_unit_price); --�ʏ�O��P��
        lv_nml_prev_dlv_date   := TO_CHAR(main_rec.nml_prev_dlv_date ,'YYYYMMDD');   --�ʏ�O��[�i�N����
    
      END IF;
     --�ʏ�@�O�X��@�[�i�N�������������i�o�b�`���t�j����N���߂��Ă���ꍇ�͐ݒ���s���܂���B
      IF (gd_process_date > main_rec.nml_bef_prev_dlv_date) THEN
        lv_nml_bef_prev_qty_sign := NULL;--�ʏ�O�X�񐔗ʃT�C��
        lv_nml_bef_prev_qty      := NULL;--�ʏ�O�X�񐔗�
        lv_nml_bef_prev_dlv_date := NULL;--�ʏ�O�X��[�i�N����
      ELSE
        lv_nml_bef_prev_dlv_date := TO_CHAR(main_rec.nml_bef_prev_dlv_date ,'YYYYMMDD') ;--�ʏ�O�X��[�i�N����
      END IF;

     --�����@�O��@�[�i�N�������������i�o�b�`���t�j����N���߂��Ă���ꍇ�͐ݒ���s���܂���B
      IF (gd_process_date > main_rec.sls_prev_dlv_date) THEN
        lv_sls_prev_unit_price := NULL;--�����O��P��
        lv_sls_prev_qty_sign   := NULL;--�����O�񐔗ʃT�C��
        lv_sls_prev_qty        := NULL;--�����O�񐔗�
        lv_sls_prev_dlv_date   := NULL;--�����O��[�i�N����
      ELSE
      
        lv_sls_prev_unit_price := TO_CHAR(main_rec.sls_prev_unit_price);--�����O��P��
        lv_sls_prev_dlv_date   := TO_CHAR(main_rec.sls_prev_dlv_date ,'YYYYMMDD');--�����O��[�i�N����
      END IF;
     --�����@�O�X��@�[�i�N�������������i�o�b�`���t�j����N���߂��Ă���ꍇ�͐ݒ���s���܂���B
      IF (gd_process_date > main_rec.sls_bef_prev_dlv_date) THEN
        lv_sls_bef_prev_qty_sign := NULL;--�����O�X�񐔗ʃT�C��
        lv_sls_bef_prev_qty      := NULL;--�����O�X�񐔗�
        lv_sls_bef_prev_dlv_date := NULL;--�����O�X��[�i�N����
      ELSE
        lv_sls_bef_prev_dlv_date := TO_CHAR(main_rec.sls_bef_prev_dlv_date ,'YYYYMMDD');--�����O�X��[�i�N����
      END IF;

      IF lv_nml_prev_dlv_date     IS NULL AND
         lv_nml_bef_prev_dlv_date IS NULL AND
         lv_sls_prev_dlv_date     IS NULL AND
         lv_sls_bef_prev_dlv_date IS NULL 
      THEN
        NULL;
      ELSE
        gn_target_cnt := gn_target_cnt + 1;
        SELECT             cv_quot || main_rec.customer_number || cv_quot -- �ڋq�R�[�h
          || cv_delimit || cv_quot || main_rec.item_code       || cv_quot -- �i���R�[�h
          || cv_delimit || lv_nml_prev_unit_price                         -- �ʏ�O��P��
          || cv_delimit || lv_nml_prev_dlv_date                           -- �ʏ�O��[�i�N����
          || cv_delimit || cv_quot || lv_nml_prev_qty_sign     || cv_quot -- �ʏ�O�񐔗ʃT�C��
          || cv_delimit || lv_nml_prev_qty                                -- �ʏ�O�񐔗�
          || cv_delimit || lv_nml_bef_prev_dlv_date                       -- �ʏ�O�X��[�i�N����
          || cv_delimit || cv_quot || lv_nml_bef_prev_qty_sign || cv_quot -- �ʏ�O�X�񐔗ʃT�C��
          || cv_delimit || lv_nml_bef_prev_qty                            -- �ʏ�O�X�񐔗�
          || cv_delimit || lv_sls_prev_unit_price                         -- �����O��P��
          || cv_delimit || lv_sls_prev_dlv_date                           -- �����O��[�i�N����
          || cv_delimit || cv_quot || lv_sls_prev_qty_sign     || cv_quot -- �����O�񐔗ʃT�C��
          || cv_delimit || lv_sls_prev_qty                                -- �����O�񐔗�
          || cv_delimit || lv_sls_bef_prev_dlv_date                       -- �����O�X��[�i�N����
          || cv_delimit || cv_quot || lv_sls_bef_prev_qty_sign || cv_quot -- �����O�X�񐔗ʃT�C��
          || cv_delimit || lv_sls_bef_prev_qty                            -- �����O�X�񐔗�
          || cv_delimit                                                   -- �l���P���@�O��
          || cv_delimit || cv_quot || TO_CHAR(SYSDATE , 'YYYY/MM/DD HH24:MI:SS') || cv_quot     -- ��������
        INTO gv_tm_file_data
        FROM DUAL
        ;
        UTL_FILE.PUT_LINE(g_tm_handle
                         ,gv_tm_file_data
                         );
        gn_normal_cnt := gn_normal_cnt + 1;
        
      -- ===============================
      -- A-4 �P���}�X�^���[�N�e�[�u���X�e�[�^�X�X�V
      -- ===============================
        BEGIN
          UPDATE xxcos_unit_price_mst_work
          SET    file_output_flag           = cv_flag_on
                ,last_updated_by            = cn_last_updated_by       
                ,last_update_date           = cd_last_update_date      
                ,last_update_login          = cn_last_update_login     
                ,request_id                 = cn_request_id            
                ,program_application_id     = cn_program_application_id
                ,program_id                 = cn_program_id            
                ,program_update_date        = cd_program_update_date   
          WHERE  CURRENT OF main_cur
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                -- �G���[�E���b�Z�[�W
                                            ,ov_retcode     => lv_retcode               -- ���^�[���E�R�[�h
                                            ,ov_errmsg      => lv_errmsg                --���[�U�[�E�G���[�E���b�Z�[�W
                                            ,ov_key_info    => gv_key_info              --�L�[���
                                            ,iv_item_name1  => gv_msg_tkn_cust_code     --���ږ���1
                                            ,iv_data_value1 => main_rec.customer_number --�f�[�^�̒l1
                                            ,iv_item_name2  => gv_msg_tkn_item_code     --���ږ���2
                                            ,iv_data_value2 => main_rec.item_code       --�f�[�^�̒l2                                            
                                            );
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_update_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_tm_w_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            ov_errbuf := ov_errbuf || CHR(10) || ov_errmsg;  
            RAISE update_expt;
        END;
      END IF;
    END LOOP main_loop;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN update_expt THEN
      ov_retcode := cv_status_error;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      IF (SQLCODE = cn_lock_error_code) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_lock
                                            , cv_tkn_lock
                                            , gv_msg_tkn_tm_w_tbl
                                             );
      END IF;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_main_loop;

--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
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
    -- ===============================
    -- Loop1 ���C���@A-2�f�[�^���o
    -- ===============================

    proc_main_loop(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );

    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSE
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
    END IF;
--
  EXCEPTION
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
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
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
    -- A-1�D��������
    -- ===============================================
    init(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================================
      -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
      -- ===============================================
      submain(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
       --�t�@�C���̃N���[�Y
      UTL_FILE.FCLOSE(g_tm_handle);
    END IF;

--
    -- ===============================================
    -- A-5�D�I������
    -- ===============================================
    --�G���[�o��
    IF (lv_retcode != cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
-- 2009/02/24 T.Nakamura Ver.1.2 mod start
--    END IF;
--    --��s�}��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
-- 2009/02/24 T.Nakamura Ver.1.2 mod end
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
END XXCOS003A05C;
/
