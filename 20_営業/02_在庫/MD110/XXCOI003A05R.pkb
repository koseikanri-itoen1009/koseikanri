create or replace
PACKAGE BODY XXCOI003A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A05R(body)
 * Description      : ���ɍ��يm�F���X�g
 * MD.050           : ���ɍ��يm�F���X�g MD050_COI_003_A05
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_work               ���[�N�e�[�u���f�[�^�폜(A-10)
 *  svf_request            SVF�N��(A-9)
 *  ins_work_zero          ���[�N�e�[�u���f�[�^�o�^(0��)(A-8)
 *  ins_work               ���[�N�e�[�u���f�[�^�o�^(A-3,A-5,A-7)
 *  get_hht_data_c         ���ٗL��HHT���o�Ƀf�[�^�擾(A-6)
 *  get_hht_data_b         ���قȂ�HHT���o�Ƀf�[�^�擾(A-4)
 *  get_hht_data_a         ���ٗL��HHT���o�Ƀf�[�^�擾(A-2)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   SCS.Tsuboi       �V�K�쐬
 *  2009/08/06    1.1   N.Abe            [0000945]�p�t�H�[�}���X���P
 *  2009/08/18    1.2   N.Abe            [0001090]�o�͌����̏C��
 *  2009/12/25    1.3   N.Abe            [E_�{�ғ�_00222]�ڋq���̎擾���@�C��
 *                                       [E_�{�ғ�_00610]�p�t�H�[�}���X���P
 *  2010/11/29    1.4   H.Sasaki         [E_�{�ғ�_05338]�p�t�H�[�}���X���P
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
  get_name_expt             EXCEPTION;    -- ���̎擾�G���[
  get_output_standard_expt  EXCEPTION;    -- �o�͊�擾I�G���[
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--  lock_expt                 EXCEPTION;    -- ���b�N�擾�G���[
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
  get_no_data_expt          EXCEPTION;    -- �擾�f�[�^0��
  svf_request_err_expt      EXCEPTION;    -- SVF�N��API�G���[
--
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--  PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ���b�N�擾��O
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCOI003A05R';   -- �p�b�P�[�W��
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCOI';          -- �A�v���P�[�V�����Z�k��
  cv_log                  CONSTANT VARCHAR2(3)   := 'LOG';            -- �R���J�����g�w�b�_�o�͐�
  cv_subinv_a             CONSTANT VARCHAR2(1)   := 'A';              -- �o�ɑ��ۊǏꏊ�敪(A:�q��)    
  cv_flg_o                CONSTANT VARCHAR2(1)   := 'O';              -- ���ɍ��يm�F���X�g�敪(O:�S�ݓX�t���O('1','2','3'))   
  cv_flg_i                CONSTANT VARCHAR2(1)   := 'I';              -- ���ɍ��يm�F���X�g�敪(O:�S�ݓX�t���O(A,B,'4'))    
  cn_status               CONSTANT NUMBER        :=  1;               -- �����σX�e�[�^�X(1:��)    
  cv_standard             CONSTANT VARCHAR2(1)   := '0';              -- �o�͊(0)    
  cv_customer_class_code  CONSTANT VARCHAR2(1)   := '1';              -- �ڋq�敪(1�F���_)
--
  -- ���b�Z�[�W
  cv_msg_xxcoi_00008  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 0�����b�Z�[�W
  cv_msg_xxcoi_00005  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';   -- �݌ɑg�D�R�[�h�擾�G���[
  cv_msg_xxcoi_00006  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';   -- �݌ɑg�DID�擾�G���[
  cv_msg_xxcoi_00009  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00009';   -- ���_���擾�G���[
  cv_msg_xxcoi_00010  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00010';   -- API�G���[���b�Z�[�W
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--  cv_msg_xxcoi_10007  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10007';   -- ���b�N�擾�G���[(���ɍ��يm�F���X�g)
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
  cv_msg_xxcoi_10021  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10021';   -- �o�͊���擾�G���[
  cv_msg_xxcoi_10317  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10317';   -- �o�͏������擾�G���[
  cv_msg_xxcoi_10158  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10158';   -- �p�����[�^.���_���b�Z�[�W
  cv_msg_xxcoi_10159  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10159';   -- �p�����[�^.�o�͊���b�Z�[�W
  cv_msg_xxcoi_10160  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10160';   -- �p�����[�^.�o�͏������b�Z�[�W
  cv_msg_xxcoi_10355  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10355';   -- �p�����[�^.�Ώ۔N�����b�Z�[�W
--
  -- �g�[�N����
  cv_token_pro                CONSTANT VARCHAR2(30) := 'PRO_TOK';
  cv_token_org_code           CONSTANT VARCHAR2(30) := 'ORG_CODE_TOK';
  cv_token_dept_code          CONSTANT VARCHAR2(30) := 'DEPT_CODE_TOK';
  cv_token_lookup_type        CONSTANT VARCHAR2(30) := 'LOOKUP_TYPE_TOK';
  cv_token_lookup_code        CONSTANT VARCHAR2(30) := 'LOOKUP_CODE_TOK';
  cv_token_target_date        CONSTANT VARCHAR2(30) := 'P_TARGET_DATE';
  cv_token_base               CONSTANT VARCHAR2(30) := 'P_BASE';
  cv_token_standard           CONSTANT VARCHAR2(30) := 'P_STANDARD';
  cv_token_term               CONSTANT VARCHAR2(30) := 'P_TERM';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE gr_param_rec  IS RECORD(
      target_date       VARCHAR2(7)       -- 01 : �Ώ۔N��  (�K�{)
     ,base_code         VARCHAR2(4)       -- 02 : ���_      (�K�{)
     ,output_standard   VARCHAR2(1)       -- 03 : �o�͊  (�K�{)
     ,output_term       VARCHAR2(1)       -- 04 : �o�͏���  (�K�{)
    );
--
  -- HHT���i�[�p���R�[�h�ϐ�
  TYPE gr_hht_info_rec IS RECORD(
      outside_code              VARCHAR2(13)                                     -- �o�ɑ��R�[�h
    , outside_location_code     VARCHAR2(13)                                     -- �o�ɑ��R�[�h
-- == 2009/08/18 V1.2 Modified START ===============================================================
--    , outside_location_name     VARCHAR2(40)                                     -- �o�ɏꏊ��
-- == 2009/12/25 V1.3 Modified START ===============================================================
--    , outside_location_name     VARCHAR2(240)                                    -- �o�ɏꏊ��
    , outside_location_name     VARCHAR2(360)                                    -- �o�ɏꏊ��
-- == 2009/12/25 V1.3 Modified END   ===============================================================
-- == 2009/08/18 V1.2 Modified END   ===============================================================
    , invoice_date               xxcoi_hht_inv_transactions.invoice_date%TYPE    -- �`�[���t
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE       -- ���i�R�[�h
    , item_name                  xxcmn_item_mst_b.item_short_name%TYPE           -- ���i��
    , outside_qty                NUMBER                                          -- �o�ɑ�����
    , inside_qty                 NUMBER                                          -- ���ɑ�����
    , inside_code                VARCHAR2(13)                                     -- �o�ɑ��R�[�h
    , inside_location_code       VARCHAR2(13)                                    -- ���ɑ��R�[�h
-- == 2009/08/18 V1.2 Modified START ===============================================================
--    , inside_location_name       VARCHAR2(40)                                    -- ���ɏꏊ��
-- == 2009/12/25 V1.3 Modified START ===============================================================
--    , inside_location_name       VARCHAR2(240)                                    -- ���ɏꏊ��
    , inside_location_name       VARCHAR2(360)                                    -- ���ɏꏊ��
-- == 2009/12/25 V1.3 Modified END   ===============================================================
-- == 2009/08/18 V1.2 Modified END   ===============================================================
  );
--
  --  HHT���i�[�p�e�[�u��
  TYPE gt_hht_info_ttype IS TABLE OF gr_hht_info_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_organization_id        mtl_parameters.organization_id%TYPE;              -- �݌ɑg�DID
  gv_base_name              hz_cust_accounts.account_name%TYPE;               -- ���_����(����)
  gv_output_standard_name   fnd_lookup_values.meaning%TYPE;                   -- �o�͊��
  gv_output_term_name       fnd_lookup_values.meaning%TYPE;                   -- �o�͏�����
  -- �J�E���^
  gn_base_cnt               NUMBER;                                           -- ���_�R�[�h����
  gn_base_loop_cnt          NUMBER;                                           -- ���_�R�[�h���[�v�J�E���^
  gn_hht_info_cnt           NUMBER;                                           -- HHT���o�ɏ�񌏐�
  gn_hht_info_loop_cnt      NUMBER;                                           -- HHT���o�ɏ�񃋁[�v�J�E���^
  -- 
  gd_target_date_start      DATE;                                             -- �Ώ۔N����1��
  gd_target_date_end        DATE;                                             -- �Ώ۔N���̌������@
  --
  gr_param                  gr_param_rec;
  gt_hht_info_tab           gt_hht_info_ttype;
-- == 2010/11/29 V1.4 Added START ===============================================================
  gt_base_code              xxcoi_hht_inv_transactions.base_code%TYPE;        --  ���_�R�[�h
  gn_ins_cnt                NUMBER;                                           --  ���[���[�N�}������
-- == 2010/11/29 V1.4 Added END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-10)
   ***********************************************************************************/
  PROCEDURE del_work(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_work'; -- �v���O������
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
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--    -- ���[�N�e�[�u�����b�N
--    CURSOR del_xsbl_tbl_cur
--    IS
--      SELECT 'X'
--      FROM   xxcoi_rep_stock_balance_list xsbl        -- ���ɍ��يm�F���X�g���[���[�N�e�[�u��
--      WHERE  xsbl.request_id = cn_request_id      -- �v��ID
--      FOR UPDATE OF xsbl.request_id NOWAIT
--    ;
----
--    -- *** ���[�J���E���R�[�h ***
--    del_xsbl_tbl_rec  del_xsbl_tbl_cur%ROWTYPE;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
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
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--    -- �J�[�\���I�[�v��
--    OPEN del_xsbl_tbl_cur;
----
--    <<del_xsbl_tbl_cur_loop>>
--    LOOP
--      -- ���R�[�h�Ǎ�
--      FETCH del_xsbl_tbl_cur INTO del_xsbl_tbl_rec;
--      EXIT WHEN del_xsbl_tbl_cur%NOTFOUND;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
--
      -- ���ɍ��يm�F���X�g���[���[�N�e�[�u���̍폜
      DELETE
      FROM   xxcoi_rep_stock_balance_list xsbl    -- ���ɍ��يm�F���X�g���[���[�N�e�[�u��
      WHERE  xsbl.request_id = cn_request_id      -- �v��ID
      ;
--
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--    END LOOP del_xrj_tbl_cur_loop;
----
--    -- �J�[�\���N���[�Y
--    CLOSE del_xsbl_tbl_cur;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--    -- ���b�N�擾�G���[
--    WHEN lock_expt THEN
--      -- �J�[�\����OPEN���Ă���ꍇ
--      IF ( del_xsbl_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xsbl_tbl_cur;
--      END IF;
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_app_name
--                      , iv_name         => cv_msg_xxcoi_10007
--                    );
--      lv_errbuf  := lv_errmsg;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--      -- �J�[�\����OPEN���Ă���ꍇ
--      IF ( del_xsbl_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xsbl_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--      -- �J�[�\����OPEN���Ă���ꍇ
--      IF ( del_xsbl_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xsbl_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--      -- �J�[�\����OPEN���Ă���ꍇ
--      IF ( del_xsbl_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xsbl_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_work;
--  
  /**********************************************************************************
   * Procedure Name   : svf_request
   * Description      : SVF�N��(A-10)
   ***********************************************************************************/
  PROCEDURE svf_request(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'svf_request'; -- �v���O������
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
    cv_output_mode  CONSTANT VARCHAR2(1) := '1';                    -- �o�͋敪(PDF�o��)
    cv_frm_file     CONSTANT VARCHAR2(30) := 'XXCOI003A05S.xml';     -- �t�H�[���l���t�@�C����
    cv_vrq_file     CONSTANT VARCHAR2(30) := 'XXCOI003A05S.vrq';     -- �N�G���[�l���t�@�C����
    cv_api_name     CONSTANT VARCHAR2(7) := 'SVF�N��';              -- SVF�N��API��
--
    -- �G���[�R�[�h
    cv_msg_xxcoi00010  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00010';   -- API�G���[
--
    -- �g�[�N����
    cv_token_name_1  CONSTANT VARCHAR2(30) := 'API_NAME';
--
    -- *** ���[�J���ϐ� ***
    ld_date       VARCHAR2(8);   -- ���t
    lv_file_name  VARCHAR2(100); -- �o�̓t�@�C����
--
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
--
    -- ���t�����ϊ�
    ld_date := TO_CHAR( cd_creation_date, 'YYYYMMDD' );
--
    -- �o�̓t�@�C����
    lv_file_name := cv_pkg_name || ld_date || TO_CHAR(cn_request_id);
--
    --SVF�N������
      xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode      => lv_retcode             -- ���^�[���R�[�h
     ,ov_errbuf       => lv_errbuf              -- �G���[���b�Z�[�W
     ,ov_errmsg       => lv_errmsg              -- ���[�U�[�E�G���[���b�Z�[�W
     ,iv_conc_name    => cv_pkg_name            -- �R���J�����g��
     ,iv_file_name    => lv_file_name           -- �o�̓t�@�C����
     ,iv_file_id      => cv_pkg_name            -- ���[ID
     ,iv_output_mode  => cv_output_mode         -- �o�͋敪
     ,iv_frm_file     => cv_frm_file            -- �t�H�[���l���t�@�C����
     ,iv_vrq_file     => cv_vrq_file            -- �N�G���[�l���t�@�C����
     ,iv_org_id       => fnd_global.org_id      -- ORG_ID
     ,iv_user_name    => fnd_global.user_name   -- ���O�C���E���[�U��
     ,iv_resp_name    => fnd_global.resp_name   -- ���O�C���E���[�U�̐E�Ӗ�
     ,iv_doc_name     => NULL                   -- ������
     ,iv_printer_name => NULL                   -- �v�����^��
     ,iv_request_id   => cn_request_id          -- �v��ID
     ,iv_nodata_msg   => NULL                   -- �f�[�^�Ȃ����b�Z�[�W
    );
--
    --==============================================================
    --�G���[���b�Z�[�W�o��
    --==============================================================
    IF lv_retcode <> cv_status_normal THEN
      RAISE svf_request_err_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** SVF�N��API�G���[ ***
    WHEN svf_request_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                    , iv_name         => cv_msg_xxcoi00010
                    , iv_token_name1  => cv_token_name_1
                    , iv_token_value1 => cv_api_name
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END svf_request;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_zero
   * Description      : ���[�N�e�[�u���f�[�^�o�^(0��)(A-8)
   ***********************************************************************************/
  PROCEDURE ins_work_zero(
    iv_nodata_msg              IN  VARCHAR2,     -- �[�������b�Z�[�W 
    ov_errbuf                  OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work_zero'; -- �v���O������
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
    --���o�ɃW���[�i���`�F�b�N���X�g���[���[�N�e�[�u���o�^����
    INSERT INTO xxcoi_rep_stock_balance_list(
        stock_balance_list_id
       ,target_term
       ,base_code 
       ,base_name
       ,output_standard_code 
       ,output_standard_name
       ,outside_location_code
       ,outside_location_name
       ,invoice_date 
       ,item_code
       ,item_name
       ,outside_qty
       ,inside_qty
       ,inside_location_code
       ,inside_location_name
       ,no_data_msg
       --WHO�J����
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
     )VALUES(
        xxcoi_rep_stock_balance_S01.NEXTVAL                                         -- ���ɍ��يm�F���X�gID(�V�[�P���X)
       ,gr_param.target_date                                                        -- �Ώ۔N��
       ,gr_param.base_code                                                          -- ���_�R�[�h
       ,gv_base_name                                                                -- ���_��
       ,gr_param.output_standard                                                    -- �o�͊�R�[�h
       ,gv_output_standard_name                                                     -- �o�͊��
       ,NULL                                                                        -- �o�ɏꏊ
       ,NULL                                                                        -- �o�ɏꏊ��
       ,NULL                                                                        -- �`�[���t
       ,NULL                                                                        -- ���i�R�[�h
       ,NULL                                                                        -- ���i��
       ,NULL                                                                        -- �o�ɐ���
       ,NULL                                                                        -- ���ɐ���
       ,NULL                                                                        -- ���ɏꏊ
       ,NULL                                                                        -- ���ɏꏊ��
       ,iv_nodata_msg                                                               -- 0�����b�Z�[�W
       --WHO�J����
       ,cn_created_by
       ,cd_creation_date
       ,cn_last_updated_by
       ,cd_last_update_date
       ,cn_last_update_login
       ,cn_request_id
       ,cn_program_application_id
       ,cn_program_id
       ,cd_program_update_date
      );
--      
    -- �R�~�b�g
    COMMIT;
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
  END ins_work_zero;
--
   /**********************************************************************************
   * Procedure Name   : ins_work
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-3,A-5,A-7)
   ***********************************************************************************/
  PROCEDURE ins_work(
    gn_hht_info_loop_cnt       IN NUMBER,        -- HHT���o�Ƀf�[�^��񃋁[�v�J�E���^
    ov_errbuf                  OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work'; -- �v���O������
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
    --���ɍ��يm�F���X�g���[���[�N�e�[�u���o�^����
    INSERT INTO xxcoi_rep_stock_balance_list(
        stock_balance_list_id
       ,target_term
       ,base_code 
       ,base_name
       ,output_standard_code 
       ,output_standard_name
       ,outside_location_code
       ,outside_location_name
       ,invoice_date 
       ,item_code
       ,item_name
       ,outside_qty
       ,inside_qty
       ,inside_location_code
       ,inside_location_name
       ,no_data_msg
       --WHO�J����
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
     )VALUES(
        xxcoi_rep_stock_balance_s01.NEXTVAL                                         -- ���ɍ��يm�F���X�gID(�V�[�P���X)
       ,gr_param.target_date                                                        -- �Ώ۔N��
       ,gr_param.base_code                                                          -- ���_�R�[�h
       ,gv_base_name                                                                -- ���_��
       ,gr_param.output_standard                                                    -- �o�͊�R�[�h
       ,gv_output_standard_name                                                     -- �o�͊��
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_location_code               -- �o�ɏꏊ
-- == 2009/08/18 V1.2 Modified START ===============================================================
--       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_location_name               -- �o�ɏꏊ��
       ,SUBSTRB(gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_location_name, 1, 40) -- �o�ɏꏊ��
-- == 2009/08/18 V1.2 Modified END   ===============================================================
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).invoice_date                        -- �`�[���t
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).item_code                           -- ���i�R�[�h
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).item_name                           -- ���i��
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_qty                         -- �o�ɐ���
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_qty                          -- ���ɐ���
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_location_code                -- ���ɏꏊ
-- == 2009/08/18 V1.2 Modified START ===============================================================
--       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_location_name                -- ���ɏꏊ��
       ,SUBSTRB(gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_location_name, 1, 40)  -- ���ɏꏊ��
-- == 2009/08/18 V1.2 Modified END   ===============================================================
       ,NULL                                                               -- 0�����b�Z�[�W
       --WHO�J����
       ,cn_created_by
       ,cd_creation_date
       ,cn_last_updated_by
       ,cd_last_update_date
       ,cn_last_update_login
       ,cn_request_id
       ,cn_program_application_id
       ,cn_program_id
       ,cd_program_update_date
      );
--      
    -- �R�~�b�g
    COMMIT;
-- == 2010/11/29 V1.4 Added START ===============================================================
    --  ���[���[�N�}������
    gn_ins_cnt :=  gn_ins_cnt + 1;
-- == 2010/11/29 V1.4 Added END   ===============================================================
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
  END ins_work;
--
  /**********************************************************************************
   * Procedure Name   : get_hht_dat_c(���[�v��)
   * Description      : ���ٗL��HHT���o�Ƀf�[�^�擾(A-6)
   ***********************************************************************************/
  PROCEDURE get_hht_data_c(
    ov_errbuf        OUT VARCHAR2,    --   �G���[�E���b�Z�[�W                --# �Œ� #
    ov_retcode       OUT VARCHAR2,    --   ���^�[���E�R�[�h                  --# �Œ� #
    ov_errmsg        OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hht_data_c'; -- �v���O������
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
    -- �Q�ƃ^�C�v
--
    -- �Q�ƃR�[�h
--   
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���ٗL��HHT���o�Ƀf�[�^
    CURSOR info_hht_cur_c
    IS
      SELECT
         NULL
        ,CASE hht.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  hht.base_code||' '||hht.outside_code
            ELSE hht.outside_code
            END AS outside_code
        ,CASE hht.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  msi1.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--            ELSE hca1.account_name
            ELSE hp1.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
            END AS outside_name
        ,hht.invoice_date                                        AS invoice_date
        ,hht.item_code                                           AS item_code
        ,ximb.item_short_name                                    AS item_name
        ,NVL( hht.outside_sum_qty,0 )                            AS outside_qty
        ,NVL( hht.inside_sum_qty,0 )                             AS inside_qty
        ,NULL
        ,CASE hht.inside_subinv_code_conv_div
           WHEN cv_subinv_a THEN  hht.base_code||' '||hht.inside_code
           ELSE hht.inside_code
           END AS inside_code
        ,CASE hht.inside_subinv_code_conv_div
           WHEN cv_subinv_a THEN  msi2.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--           ELSE hca2.account_name
           ELSE hp2.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
           END AS inside_name
      FROM
        (
         -- ���ٗL�����
         SELECT
              hht2.base_code                                     AS base_code
             ,hht2.outside_base_code                             AS outside_base_code
             ,hht2.outside_code                                  AS outside_code
             ,hht2.outside_subinv_code                           AS outside_subinv_code 
             ,hht2.outside_cust_code                             AS outside_cust_code
             ,hht2.outside_subinv_code_conv_div                  AS outside_subinv_code_conv_div
             ,hht2.item_code                                     AS item_code
             ,hht2.invoice_date                                  AS invoice_date
             ,SUM(hht2.out_quantity)                             AS outside_sum_qty
             ,SUM(hht2.in_quantity)                              AS inside_sum_qty
             ,hht2.inside_base_code                              AS inside_base_code
             ,hht2.inside_code                                   AS inside_code
             ,hht2.inside_subinv_code                            AS inside_subinv_code
             ,hht2.inside_cust_code                              AS inside_cust_code
             ,hht2.inside_subinv_code_conv_div                   AS inside_subinv_code_conv_div
         FROM
           (
            SELECT 
                xhit.base_code                                   AS base_code
               ,xhit.outside_base_code                           AS outside_base_code
               ,xhit.outside_code                                AS outside_code
               ,xhit.outside_subinv_code                         AS outside_subinv_code
               ,xhit.outside_cust_code                           AS outside_cust_code 
               ,xhit.outside_subinv_code_conv_div                AS outside_subinv_code_conv_div
               ,xhit.item_code                                   AS item_code
               ,xhit.invoice_date                                AS invoice_date
               ,CASE xhit.stock_balance_list_div
                WHEN cv_flg_o THEN NVL(xhit.total_quantity,0 )
                ELSE 0
                END  AS out_quantity
               ,CASE xhit.stock_balance_list_div
                WHEN cv_flg_i THEN NVL(xhit.total_quantity,0 )
                ELSE 0
                END  AS in_quantity
               ,xhit.inside_base_code                            AS inside_base_code
               ,xhit.inside_code                                 AS inside_code
               ,xhit.inside_subinv_code                          AS inside_subinv_code
               ,xhit.inside_cust_code                            AS inside_cust_code
               ,xhit.inside_subinv_code_conv_div                 AS inside_subinv_code_conv_div
               ,xhit.stock_balance_list_div                      AS stock_balance_list_div
           FROM xxcoi_hht_inv_transactions xhit
          WHERE xhit.stock_balance_list_div IN (cv_flg_o,cv_flg_i)
            AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
            AND xhit.status = cn_status
-- == 2010/11/29 V1.4 Added START ===============================================================
            AND xhit.base_code    =   gt_base_code
-- == 2010/11/29 V1.4 Added END   ===============================================================
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
         ) hht2
         GROUP BY 
               hht2.base_code   
              ,hht2.outside_base_code   
              ,hht2.outside_code
              ,hht2.outside_subinv_code
              ,hht2.outside_cust_code
              ,hht2.item_code
              ,hht2.outside_subinv_code_conv_div
              ,hht2.invoice_date  
              ,hht2.inside_base_code
              ,hht2.inside_code
              ,hht2.inside_subinv_code
              ,hht2.inside_cust_code
              ,hht2.inside_subinv_code_conv_div
        ) hht                                                        -- ���ق�����
      ,ic_item_mst_b              iimb                               -- OPM�i�ڃ}�X�^
      ,xxcmn_item_mst_b           ximb                               -- OPM�i�ڃ}�X�^�A�h�I��
      ,mtl_secondary_inventories  msi1                               -- �o�ɑ��ۊǏꏊ�}�X�^
      ,mtl_secondary_inventories  msi2                               -- ���ɑ��ۊǏꏊ�}�X�^
      ,hz_cust_accounts           hca1                               -- �o�ɑ��ڋq�A�J�E���g
      ,hz_cust_accounts           hca2                               -- ���ɑ��ڋq�A�J�E���g
-- == 2009/12/25 V1.3 Added START ===============================================================
      ,hz_parties                 hp1                                -- ���ɑ��p�[�e�B�}�X�^
      ,hz_parties                 hp2                                -- �o�ɑ��p�[�e�B�}�X�^
-- == 2009/12/25 V1.3 Added END   ===============================================================
    WHERE  
          hht.outside_subinv_code = msi1.secondary_inventory_name
      AND msi1.organization_id    = gn_organization_id
      AND hht.inside_subinv_code  = msi2.secondary_inventory_name
      AND msi2.organization_id    = gn_organization_id
      AND hht.outside_cust_code   = hca1.account_number(+)
      AND hht.inside_cust_code    = hca2.account_number(+)
-- == 2009/12/25 V1.3 Added START ===============================================================
      AND hca1.party_id           = hp1.party_id(+)
      AND hca2.party_id           = hp2.party_id(+)
-- == 2009/12/25 V1.3 Added END   ===============================================================
      AND item_code               = iimb.item_no
      AND iimb.item_id            = ximb.item_id
      AND (hht.invoice_date BETWEEN ximb.start_date_active AND ximb.end_date_active)
    ORDER BY 
          DECODE(gr_param.output_standard,cv_standard,hht.inside_code,hht.outside_code)
         ,hht.invoice_date
         ,hht.item_code 
    ;    
--
    -- ���[�J���E���R�[�h
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
    -- HHT���o�ɏ�񌏐�������
    gn_hht_info_cnt := 0;
--
    -- �J�[�\���I�[�v��
    OPEN info_hht_cur_c;
--
    -- ���R�[�h�Ǎ�
    FETCH info_hht_cur_c BULK COLLECT INTO gt_hht_info_tab;
--
    -- HHT���o�ɏ��J�E���g�Z�b�g
    gn_hht_info_cnt := gt_hht_info_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE info_hht_cur_c;
--
    -- �Ώۏ�������
    gn_target_cnt := gn_target_cnt + gn_hht_info_cnt;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_c%ISOPEN ) THEN
        CLOSE info_hht_cur_c;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_c%ISOPEN ) THEN
        CLOSE info_hht_cur_c;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_c%ISOPEN ) THEN
        CLOSE info_hht_cur_c;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_c%ISOPEN ) THEN
        CLOSE info_hht_cur_c;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_hht_data_c;
--
  /**********************************************************************************
   * Procedure Name   : get_hht_dat_b(���[�v��)
   * Description      : ���ٖ���HHT���o�Ƀf�[�^�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_hht_data_b(
    ov_errbuf        OUT VARCHAR2,    --   �G���[�E���b�Z�[�W                --# �Œ� #
    ov_retcode       OUT VARCHAR2,    --   ���^�[���E�R�[�h                  --# �Œ� #
    ov_errmsg        OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hht_data_b'; -- �v���O������
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
    -- �Q�ƃ^�C�v
--
    -- �Q�ƃR�[�h
--   
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���ٖ���HHT���o�Ƀf�[�^
    CURSOR info_hht_cur_b
    IS
      SELECT
         NULL
        ,CASE outside.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  outside.base_code||' '||outside.outside_code
            ELSE outside.outside_code
            END AS outside_code
        ,CASE outside.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  msi1.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--            ELSE hca1.account_name
            ELSE hp1.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
            END AS outside_name
        ,outside.invoice_date                                    AS invoice_date
        ,outside.item_code                                       AS item_code
        ,ximb.item_short_name                                    AS item_name
        ,NVL( outside.sum_quantity,0 )                           AS outside_qty
        ,NVL( inside.sum_quantity,0 )                            AS inside_qty
        ,NULL
        ,CASE inside.inside_subinv_code_conv_div
            WHEN cv_subinv_a THEN inside.base_code||' '||inside.inside_code
            ELSE inside.inside_code
            END AS inside_code
        ,CASE inside.inside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  msi2.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--            ELSE hca2.account_name
            ELSE hp2.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
            END AS inside_name
      FROM
        (
         -- �o�ɑ����
         SELECT 
              xhit.base_code                                     AS base_code 
             ,xhit.outside_base_code                             AS outside_base_code
             ,xhit.outside_code                                  AS outside_code
             ,xhit.outside_subinv_code                           AS outside_subinv_code
             ,xhit.outside_cust_code                             AS outside_cust_code
             ,xhit.outside_subinv_code_conv_div                  AS outside_subinv_code_conv_div
             ,xhit.item_code                                     AS item_code 
             ,xhit.invoice_date                                  AS invoice_date
             ,SUM( NVL(xhit.total_quantity,0 ) )                 AS sum_quantity
             ,xhit.inside_base_code                              AS inside_base_code
             ,xhit.inside_code                                   AS inside_code
             ,xhit.inside_subinv_code                            AS inside_subinv_code
             ,xhit.inside_cust_code                              AS inside_cust_code
             ,xhit.inside_subinv_code_conv_div                   AS inside_subinv_code_conv_div
         FROM xxcoi_hht_inv_transactions xhit
        WHERE xhit.stock_balance_list_div = cv_flg_o
          AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
          AND  xhit.status = cn_status
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
        GROUP BY
              xhit.base_code
             ,xhit.outside_base_code
             ,xhit.outside_code
             ,xhit.outside_subinv_code
             ,xhit.outside_cust_code
             ,xhit.outside_subinv_code_conv_div
             ,xhit.item_code
             ,xhit.invoice_date
             ,xhit.inside_base_code
             ,xhit.inside_code
             ,xhit.inside_subinv_code
             ,xhit.inside_cust_code
             ,xhit.inside_subinv_code_conv_div ) outside ,     -- �o�ɑ����C�����C���r���[
       -- ���ɑ����
       (SELECT
              xhit.base_code                                     AS base_code
             ,xhit.outside_base_code                             AS outside_base_code
             ,xhit.outside_code                                  AS outside_code
             ,xhit.outside_subinv_code                           AS outside_subinv_code
             ,xhit.outside_cust_code                             AS outside_cust_code
             ,xhit.outside_subinv_code_conv_div                  AS outside_subinv_code_conv_div
             ,xhit.item_code                                     AS item_code
             ,xhit.invoice_date                                  AS invoice_date
             ,SUM( nvl(xhit.total_quantity,0 ) )                 AS sum_quantity
             ,xhit.inside_base_code                              AS inside_base_code 
             ,xhit.inside_code                                   AS inside_code  
             ,xhit.inside_subinv_code                            AS inside_subinv_code
             ,xhit.inside_cust_code                              AS inside_cust_code
             ,xhit.inside_subinv_code_conv_div                   AS inside_subinv_code_conv_div
         FROM xxcoi_hht_inv_transactions xhit
        WHERE xhit.stock_balance_list_div = cv_flg_i
         AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
          AND  xhit.status = cn_status
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
       GROUP BY
             xhit.base_code
            ,xhit.outside_base_code
            ,xhit.outside_code
            ,xhit.outside_subinv_code
            ,xhit.outside_cust_code
            ,xhit.outside_subinv_code_conv_div
            ,xhit.item_code
            ,xhit.invoice_date
            ,xhit.inside_base_code
            ,xhit.inside_code
            ,xhit.inside_subinv_code
            ,xhit.inside_cust_code
            ,xhit.inside_subinv_code_conv_div ) inside                -- ���ɑ����C�����C���r���[ 
         ,ic_item_mst_b              iimb                             -- OPM�i�ڃ}�X�^
         ,xxcmn_item_mst_b           ximb                             -- OPM�i�ڃ}�X�^�A�h�I��
         ,mtl_secondary_inventories  msi1                             -- �o�ɑ��ۊǏꏊ�}�X�^
         ,mtl_secondary_inventories  msi2                             -- ���ɑ��ۊǏꏊ�}�X�^
         ,hz_cust_accounts           hca1                             -- �o�ɑ��ڋq�A�J�E���g
         ,hz_cust_accounts           hca2                             -- ���ɑ��ڋq�A�J�E���g
-- == 2009/12/25 V1.3 Added START ===============================================================
         ,hz_parties                 hp1                              -- ���ɑ��p�[�e�B�}�X�^
         ,hz_parties                 hp2                              -- �o�ɑ��p�[�e�B�}�X�^
-- == 2009/12/25 V1.3 Added END   ===============================================================
      WHERE outside.outside_base_code            = inside.outside_base_code
        AND outside.outside_code                 = inside.outside_code
        AND outside.invoice_date                 = inside.invoice_date
        AND outside.item_code                    = inside.item_code
        AND outside.inside_base_code             = inside.inside_base_code
        AND outside.inside_code                  = inside.inside_code
        AND outside.sum_quantity                 = inside.sum_quantity
        AND outside.item_code                    = iimb.item_no
        AND iimb.item_id                         = ximb.item_id
        AND (outside.invoice_date BETWEEN ximb.start_date_active AND ximb.end_date_active)
        AND outside.outside_subinv_code          = msi1.secondary_inventory_name
        AND msi1.organization_id                 = gn_organization_id
        AND outside.outside_cust_code            = hca1.account_number(+)
        AND inside.inside_subinv_code            = msi2.secondary_inventory_name
        AND msi2.organization_id                 = gn_organization_id
        AND inside.inside_cust_code              = hca2.account_number(+)
-- == 2009/12/25 V1.3 Added START ===============================================================
        AND hca1.party_id                        = hp1.party_id(+)
        AND hca2.party_id                        = hp2.party_id(+)
-- == 2009/12/25 V1.3 Added END   ===============================================================
      ORDER BY 
          DECODE(gr_param.output_standard,cv_standard,inside.inside_code,outside.outside_code)
         ,outside.invoice_date
         ,outside.item_code 
    ;    
--
    -- ���[�J���E���R�[�h
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
    -- ���ٖ���HHT���o�ɏ�񌏐�������
    gn_hht_info_cnt := 0;
--
    -- �J�[�\���I�[�v��
    OPEN info_hht_cur_b;
--
    -- ���R�[�h�Ǎ�
    FETCH info_hht_cur_b BULK COLLECT INTO gt_hht_info_tab;
--
    -- HHT���o�ɏ��J�E���g�Z�b�g
    gn_hht_info_cnt := gt_hht_info_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE info_hht_cur_b;
--
    -- �Ώۏ�������
    gn_target_cnt := gn_target_cnt + gn_hht_info_cnt;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_b%ISOPEN ) THEN
        CLOSE info_hht_cur_b;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_b%ISOPEN ) THEN
        CLOSE info_hht_cur_b;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_b%ISOPEN ) THEN
        CLOSE info_hht_cur_b;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_b%ISOPEN ) THEN
        CLOSE info_hht_cur_b;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_hht_data_b;
--
  /**********************************************************************************
   * Procedure Name   : get_hht_dat_a(���[�v��)
   * Description      : ���ٗL��HHT���o�Ƀf�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_hht_data_a(
    ov_errbuf        OUT VARCHAR2,    --   �G���[�E���b�Z�[�W                --# �Œ� #
    ov_retcode       OUT VARCHAR2,    --   ���^�[���E�R�[�h                  --# �Œ� #
    ov_errmsg        OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hht_data_a'; -- �v���O������
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
    -- �Q�ƃ^�C�v
--
    -- �Q�ƃR�[�h
--   
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���ٗL��HHT���o�Ƀf�[�^
    CURSOR info_hht_cur_a
    IS
      SELECT
         NULL
        ,CASE hht.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  hht.base_code||' '||hht.outside_code
            ELSE hht.outside_code
            END AS outside_code
        ,CASE hht.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  msi1.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--            ELSE hca1.account_name
            ELSE hp1.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
            END AS outside_name
        ,hht.invoice_date                                        AS invoice_date
        ,hht.item_code                                           AS item_code
        ,ximb.item_short_name                                    AS item_name
        ,NVL( hht.outside_sum_qty,0 )                            AS outside_qty
        ,NVL( hht.inside_sum_qty,0 )                             AS inside_qty
        ,NULL
        ,CASE hht.inside_subinv_code_conv_div
           WHEN cv_subinv_a THEN  hht.base_code||' '||hht.inside_code
           ELSE hht.inside_code
           END AS inside_code
        ,CASE hht.inside_subinv_code_conv_div
           WHEN cv_subinv_a THEN  msi2.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--           ELSE hca2.account_name
           ELSE hp2.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
           END AS inside_name
      FROM
        (
         -- ���ٗL�����
         SELECT
              hht2.base_code                                     AS base_code
             ,hht2.outside_base_code                             AS outside_base_code
             ,hht2.outside_code                                  AS outside_code
             ,hht2.outside_subinv_code                           AS outside_subinv_code 
             ,hht2.outside_cust_code                             AS outside_cust_code
             ,hht2.outside_subinv_code_conv_div                  AS outside_subinv_code_conv_div
             ,hht2.item_code                                     AS item_code
             ,hht2.invoice_date                                  AS invoice_date
             ,SUM(hht2.out_quantity)                             AS outside_sum_qty
             ,SUM(hht2.in_quantity)                              AS inside_sum_qty
             ,hht2.inside_base_code                              AS inside_base_code
             ,hht2.inside_code                                   AS inside_code
             ,hht2.inside_subinv_code                            AS inside_subinv_code
             ,hht2.inside_cust_code                              AS inside_cust_code
             ,hht2.inside_subinv_code_conv_div                   AS inside_subinv_code_conv_div
         FROM
           (
            SELECT 
                xhit.base_code                                   AS base_code
               ,xhit.outside_base_code                           AS outside_base_code
               ,xhit.outside_code                                AS outside_code
               ,xhit.outside_subinv_code                         AS outside_subinv_code
               ,xhit.outside_cust_code                           AS outside_cust_code 
               ,xhit.outside_subinv_code_conv_div                AS outside_subinv_code_conv_div
               ,xhit.item_code                                   AS item_code
               ,xhit.invoice_date                                AS invoice_date
               ,CASE xhit.stock_balance_list_div
                WHEN cv_flg_o THEN NVL(xhit.total_quantity,0 )
                ELSE 0
                END  AS out_quantity
               ,CASE xhit.stock_balance_list_div
                WHEN cv_flg_i THEN NVL(xhit.total_quantity,0 )
                ELSE 0
                END  AS in_quantity
               ,xhit.inside_base_code                            AS inside_base_code
               ,xhit.inside_code                                 AS inside_code
               ,xhit.inside_subinv_code                          AS inside_subinv_code
               ,xhit.inside_cust_code                            AS inside_cust_code
               ,xhit.inside_subinv_code_conv_div                 AS inside_subinv_code_conv_div
               ,xhit.stock_balance_list_div                      AS stock_balance_list_div
           FROM xxcoi_hht_inv_transactions xhit
          WHERE xhit.stock_balance_list_div IN (cv_flg_o,cv_flg_i)
            AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
            AND xhit.status = cn_status
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
         ) hht2
         GROUP BY 
               hht2.base_code   
              ,hht2.outside_base_code   
              ,hht2.outside_code
              ,hht2.outside_subinv_code
              ,hht2.outside_cust_code
              ,hht2.item_code
              ,hht2.outside_subinv_code_conv_div
              ,hht2.invoice_date  
              ,hht2.inside_base_code
              ,hht2.inside_code
              ,hht2.inside_subinv_code
              ,hht2.inside_cust_code
              ,hht2.inside_subinv_code_conv_div
         MINUS
         SELECT
              outside.base_code                                  AS base_code
             ,outside.outside_base_code                          AS outside_base_code
             ,outside.outside_code                               AS outside_code
             ,outside.outside_subinv_code                        AS outside_subinv_code
             ,outside.outside_cust_code                          AS outside_cust_code
             ,outside.outside_subinv_code_conv_div               AS outside_subinv_code_conv_di
             ,outside.item_code                                  AS item_code
             ,outside.invoice_date                               AS invoice_date
             ,outside.sum_quantity                               AS sum_quantity
             ,inside.sum_quantity                                AS sum_quantity
             ,outside.inside_base_code                           AS inside_base_code
             ,outside.inside_code                                AS inside_code
             ,outside.inside_subinv_code                         AS inside_subinv_code
             ,outside.inside_cust_code                           AS inside_cust_code
             ,outside.inside_subinv_code_conv_div                AS inside_subinv_code_conv_div
         FROM
           -- �o�ɑ����
           (
            SELECT 
                xhit.base_code                                   AS base_code
               ,xhit.outside_base_code                           AS outside_base_code
               ,xhit.outside_code                                AS outside_code
               ,xhit.outside_subinv_code                         AS outside_subinv_code
               ,xhit.outside_cust_code                           AS outside_cust_code
               ,xhit.outside_subinv_code_conv_div                AS outside_subinv_code_conv_div
               ,xhit.item_code                                   AS item_code
               ,xhit.invoice_date                                AS invoice_date
               ,SUM(NVL(xhit.total_quantity,0))                  AS sum_quantity
               ,xhit.inside_base_code                            AS inside_base_code
               ,xhit.inside_code                                 AS inside_code
               ,xhit.inside_subinv_code                          AS inside_subinv_code
               ,xhit.inside_cust_code                            AS inside_cust_code
               ,xhit.inside_subinv_code_conv_div                 AS inside_subinv_code_conv_div
               ,xhit.stock_balance_list_div                      AS stock_balance_list_div
           FROM xxcoi_hht_inv_transactions xhit
          WHERE xhit.stock_balance_list_div = cv_flg_o
            AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
            AND  xhit.status = 1
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
         GROUP BY
               xhit.base_code
              ,xhit.outside_base_code
              ,xhit.outside_code
              ,xhit.outside_subinv_code
              ,xhit.outside_cust_code
              ,xhit.outside_subinv_code_conv_div
              ,xhit.item_code
              ,xhit.invoice_date
              ,xhit.inside_base_code
              ,xhit.inside_code
              ,xhit.inside_subinv_code
              ,xhit.inside_cust_code
              ,xhit.inside_subinv_code_conv_div
              ,xhit.stock_balance_list_div ) outside,     
           -- ���ɑ����
          (
           SELECT
               xhit.base_code                                    AS base_code
              ,xhit.outside_base_code                            AS outside_base_code
              ,xhit.outside_code                                 AS outside_code
              ,xhit.outside_subinv_code                          AS outside_subinv_code
              ,xhit.outside_cust_code                            AS outside_cust_code
              ,xhit.outside_subinv_code_conv_div                 AS outside_subinv_code_conv_div
              ,xhit.item_code                                    AS item_code
              ,xhit.invoice_date                                 AS invoice_date
              ,SUM(nvl(xhit.total_quantity,0))                   AS sum_quantity
              ,xhit.inside_base_code                             AS inside_base_code
              ,xhit.inside_code                                  AS inside_code
              ,xhit.inside_subinv_code                           AS inside_subinv_code
              ,xhit.inside_cust_code                             AS inside_cust_code
              ,xhit.inside_subinv_code_conv_div                  AS inside_subinv_code_conv_div
              ,xhit.stock_balance_list_div                       AS stock_balance_list_div
          FROM xxcoi_hht_inv_transactions xhit
         WHERE xhit.stock_balance_list_div = cv_flg_i
           AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
           AND  xhit.status = 1
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
        GROUP BY
              xhit.base_code
             ,xhit.outside_base_code
             ,xhit.outside_code
             ,xhit.outside_subinv_code
             ,xhit.outside_cust_code
             ,xhit.outside_subinv_code_conv_div
             ,xhit.item_code
             ,xhit.invoice_date
             ,xhit.inside_base_code
             ,xhit.inside_code
             ,xhit.inside_subinv_code
             ,xhit.inside_cust_code
             ,xhit.inside_subinv_code_conv_div
             ,xhit.stock_balance_list_div ) inside                
      WHERE outside.outside_base_code            = inside.outside_base_code
        AND outside.outside_code                 = inside.outside_code
        AND outside.invoice_date                 = inside.invoice_date
        AND outside.item_code                    = inside.item_code
        AND outside.inside_base_code             = inside.inside_base_code
        AND outside.inside_code                  = inside.inside_code
        AND outside.sum_quantity                 = inside.sum_quantity
        ) hht                                                        -- ���ق�����
      ,ic_item_mst_b              iimb                               -- OPM�i�ڃ}�X�^
      ,xxcmn_item_mst_b           ximb                               -- OPM�i�ڃ}�X�^�A�h�I��
      ,mtl_secondary_inventories  msi1                               -- �o�ɑ��ۊǏꏊ�}�X�^
      ,mtl_secondary_inventories  msi2                               -- ���ɑ��ۊǏꏊ�}�X�^
      ,hz_cust_accounts           hca1                               -- �o�ɑ��ڋq�A�J�E���g
      ,hz_cust_accounts           hca2                               -- ���ɑ��ڋq�A�J�E���g
-- == 2009/12/25 V1.3 Added START ===============================================================
      ,hz_parties                 hp1                                -- ���ɑ��p�[�e�B�}�X�^
      ,hz_parties                 hp2                                -- �o�ɑ��p�[�e�B�}�X�^
-- == 2009/12/25 V1.3 Added END   ===============================================================
    WHERE  
          hht.outside_subinv_code = msi1.secondary_inventory_name
      AND msi1.organization_id    = gn_organization_id
      AND hht.inside_subinv_code  = msi2.secondary_inventory_name
      AND msi2.organization_id    = gn_organization_id
      AND hht.outside_cust_code   = hca1.account_number(+)
      AND hht.inside_cust_code    = hca2.account_number(+)
-- == 2009/12/25 V1.3 Added START ===============================================================
      AND hca1.party_id           = hp1.party_id(+)
      AND hca2.party_id           = hp2.party_id(+)
-- == 2009/12/25 V1.3 Added END   ===============================================================
      AND item_code               = iimb.item_no
      AND iimb.item_id            = ximb.item_id
      AND (hht.invoice_date BETWEEN ximb.start_date_active AND ximb.end_date_active)
    ORDER BY 
          DECODE(gr_param.output_standard,cv_standard,hht.inside_code,hht.outside_code)
         ,hht.invoice_date
         ,hht.item_code 
    ;    
--
    -- ���[�J���E���R�[�h
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
    -- ���ٗL��HHT���o�ɏ�񌏐�������
    gn_hht_info_cnt := 0;
--
    -- �J�[�\���I�[�v��
    OPEN info_hht_cur_a;
--
    -- ���R�[�h�Ǎ�
    FETCH info_hht_cur_a BULK COLLECT INTO gt_hht_info_tab;
--
    -- HHT���o�ɏ��J�E���g�Z�b�g
    gn_hht_info_cnt := gt_hht_info_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE info_hht_cur_a;
--
    -- �Ώۏ�������
    gn_target_cnt := gn_target_cnt + gn_hht_info_cnt;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_a%ISOPEN ) THEN
        CLOSE info_hht_cur_a;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_a%ISOPEN ) THEN
        CLOSE info_hht_cur_a;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_a%ISOPEN ) THEN
        CLOSE info_hht_cur_a;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur_a%ISOPEN ) THEN
        CLOSE info_hht_cur_a;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_hht_data_a;
--
    /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)  := 'init';                      -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �萔
    cv_profile_name     CONSTANT VARCHAR2(30)   := 'XXCOI1_ORGANIZATION_CODE';        -- �v���t�@�C����(�݌ɑg�D�R�[�h)
    cv_output_standard  CONSTANT VARCHAR2(30)   := 'XXCOI1_OUTPUT_STANDARD';          -- �Q�ƃ^�C�v(�o�͊)
    cv_output_term      CONSTANT VARCHAR2(30)   := 'XXCOI1_OUTPUT_TERM';              -- �Q�ƃ^�C�v(�o�͏���)
--
    -- *** ���[�J���ϐ� ***
    lv_organization_code mtl_parameters.organization_code%TYPE;  -- �݌ɑg�D�R�[�h
--
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
--
    -- =====================================
    -- �v���t�@�C���l�擾(�݌ɑg�D�R�[�h)   
    -- =====================================
    lv_organization_code := FND_PROFILE.VALUE(cv_profile_name);
    IF ( lv_organization_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg( 
                       iv_application  => cv_app_name
                     , iv_name         => cv_msg_xxcoi_00005
                     , iv_token_name1  => cv_token_pro
                     , iv_token_value1 => cv_profile_name
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;         
--
    -- =====================================
    -- �݌ɑg�DID�擾                       
    -- =====================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
    IF ( gn_organization_id IS NULL ) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                       iv_application  => cv_app_name
                     , iv_name         => cv_msg_xxcoi_00006
                     , iv_token_name1  => cv_token_org_code
                     , iv_token_value1 => lv_organization_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;         
--
    -- =====================================
    -- ���_����(��)�擾                       
    -- =====================================
    BEGIN
      SELECT SUBSTRB(hca.account_name,1,8)  account_name
      INTO   gv_base_name
      FROM   hz_cust_accounts hca
      WHERE  hca.account_number = gr_param.base_code
      AND    hca.customer_class_code = cv_customer_class_code ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                       , iv_name         => cv_msg_xxcoi_00009
                       , iv_token_name1  => cv_token_dept_code
                       , iv_token_value1 => gr_param.base_code
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_name_expt;
    END;
--
    -- =====================================
    -- �o�͊���擾                       
    -- =====================================
    gv_output_standard_name := xxcoi_common_pkg.get_meaning(
                                  iv_lookup_type => cv_output_standard
                                , iv_lookup_code => gr_param.output_standard
                              );
    IF (gv_output_standard_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                     , iv_name         => cv_msg_xxcoi_10021
                     , iv_token_name1  => cv_token_lookup_type
                     , iv_token_value1 => cv_output_standard
                     , iv_token_name2  => cv_token_lookup_code
                     , iv_token_value2 => gr_param.output_standard
                   );
      lv_errbuf := lv_errmsg;
      RAISE get_name_expt;
    END IF;
--
    -- =====================================
    -- �o�͏������擾                       
    -- =====================================
    gv_output_term_name := xxcoi_common_pkg.get_meaning(
                                iv_lookup_type => cv_output_term
                              , iv_lookup_code => gr_param.output_term
                            );
    IF (gv_output_term_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                     , iv_name         => cv_msg_xxcoi_10317
                     , iv_token_name1  => cv_token_lookup_type
                     , iv_token_value1 => cv_output_term
                     , iv_token_name2  => cv_token_lookup_code
                     , iv_token_value2 => gr_param.output_term
                   );
      lv_errbuf := lv_errmsg;
      RAISE get_name_expt;
    END IF;
--
    --==============================================================
    -- �R���J�����g���̓p�����[�^�o��
    --==============================================================
    -- �p�����[�^.�Ώ۔N��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_app_name
                    , iv_name         =>  cv_msg_xxcoi_10355
                    , iv_token_name1  =>  cv_token_target_date
                    , iv_token_value1 =>  gr_param.target_date
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- �p�����[�^.���_
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_app_name
                    , iv_name         =>  cv_msg_xxcoi_10158
                    , iv_token_name1  =>  cv_token_base
                    , iv_token_value1 =>  gr_param.base_code
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- �p�����[�^.�o�͊
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_app_name
                    , iv_name         =>  cv_msg_xxcoi_10159
                    , iv_token_name1  =>  cv_token_standard
                    , iv_token_value1 =>  gv_output_standard_name
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- �p�����[�^.�o�͏���
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_app_name
                    , iv_name         =>  cv_msg_xxcoi_10160
                    , iv_token_name1  =>  cv_token_term
                    , iv_token_value1 =>  gv_output_term_name
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
-- == 2010/11/29 V1.4 Added START ===============================================================
    --  �ΏƋ��_�R�[�h�擾
    SELECT  DECODE(xca.dept_hht_div, '1', xca.management_base_code, hca.account_number)
    INTO    gt_base_code
    FROM    hz_cust_accounts      hca
          , xxcmm_cust_accounts   xca
    WHERE   hca.cust_account_id       =   xca.customer_id
    AND     hca.customer_class_code   =   '1'
    AND     hca.account_number        =   gr_param.base_code;
-- == 2010/11/29 V1.4 Added END   ===============================================================
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN get_name_expt THEN                        --*** ���̎擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date       IN  VARCHAR2,         --   1.�Ώ۔N��
    iv_base_code         IN  VARCHAR2,         --   2.���_
    iv_output_standard   IN  VARCHAR2,         --   3.�o�͊
    iv_output_term       IN  VARCHAR2,         --   4.�o�͏���
    ov_errbuf            OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_output_term_0    CONSTANT VARCHAR2(1) := '0';       -- �o�͏���(���ٗL��)
    cv_output_term_1    CONSTANT VARCHAR2(1) := '1';       -- �o�͏���(���ٖ���)
    cv_output_term_2    CONSTANT VARCHAR2(1) := '2';       -- �o�͏���(���ٗL��)
--
    -- *** ���[�J���ϐ� ***
    lv_nodata_msg VARCHAR2(50);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
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
-- == 2010/11/29 V1.4 Added START ===============================================================
    gn_ins_cnt    := 0;
-- == 2010/11/29 V1.4 Added END   ===============================================================
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    -- �p�����[�^�l�̊i�[
    -- =====================================================
    gr_param.target_date       := iv_target_date;        -- 01 : �Ώ۔N��  (�K�{)
    gr_param.base_code         := iv_base_code;          -- 02 : ���_      (�K�{)
    gr_param.output_standard   := iv_output_standard;    -- 03 : �o�͊  (�K�{)
    gr_param.output_term       := iv_output_term;        -- 04 : �o�͏���  (�K�{)
--
    -- =====================================================
    -- �Ώ۔N���̌������ƌ��������i�[
    -- =====================================================
    gd_target_date_start := TO_DATE(gr_param.target_date||'-01','YYYY/MM/DD');
    gd_target_date_end   := LAST_DAY(gd_target_date_start);
--
    -- =====================================================
    -- ��������(A-1)
    -- =====================================================
    init(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
-- == 2010/11/29 V1.4 Modified START ===============================================================
--    -- �o�͏������u���ٗL��v�̏ꍇ
--    IF ( gr_param.output_term = cv_output_term_0 ) THEN
--         -- =====================================================
--         -- ���ٗL��HHT���o�Ƀf�[�^�擾(A-2)
--         -- =====================================================
--         get_hht_data_a(
--            lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
--          , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
--          , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--         );
--         IF ( lv_retcode = cv_status_error ) THEN
--           -- �G���[����
--           RAISE global_process_expt ;
--         END IF;
--    ELSIF
--      -- �o�͏������u���ٖ����v�̏ꍇ
--      ( gr_param.output_term = cv_output_term_1 ) THEN
--         -- =====================================================
--         -- ���ٖ���HHT���o�Ƀf�[�^�擾(A-4)
--         -- =====================================================
--         get_hht_data_b(
--             lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
--           , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
--           , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--         );
--         IF ( lv_retcode = cv_status_error ) THEN
--           -- �G���[����
--           RAISE global_process_expt ;
--         END IF;
--    ELSIF
--      -- �o�͏������u���ٗL���v�̏ꍇ
--      ( gr_param.output_term = cv_output_term_2 ) THEN
--        -- =====================================================
--        -- ���ٗL��HHT���o�Ƀf�[�^�擾(A-6)
--        -- =====================================================
--        get_hht_data_c(
--            lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
--          , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
--          , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          -- �G���[����
--          RAISE global_process_expt ;
--        END IF;
--    END IF;
    -- =====================================================
    -- ���ٗL��HHT���o�Ƀf�[�^�擾(A-6)
    -- =====================================================
    get_hht_data_c(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      -- �G���[����
      RAISE global_process_expt ;
    END IF;
-- == 2010/11/29 V1.4 Modified END   ===============================================================
--
    -- HHT���o�Ƀf�[�^��1���ȏ�擾�ł����ꍇ
    IF ( gn_hht_info_cnt > 0 ) THEN
       lv_nodata_msg := NULL;
--
       -- HHT���o�Ƀf�[�^���[�v�J�n
       <<gn_hht_info_cnt_loop>>
       FOR gn_hht_info_loop_cnt IN 1 .. gn_hht_info_cnt LOOP
--
-- == 2010/11/29 V1.4 Added START ===============================================================
        IF  (     gr_param.output_term = cv_output_term_0
              AND gt_hht_info_tab(gn_hht_info_loop_cnt).outside_qty <> gt_hht_info_tab(gn_hht_info_loop_cnt).inside_qty
            )
            OR
            (     gr_param.output_term = cv_output_term_1
              AND gt_hht_info_tab(gn_hht_info_loop_cnt).outside_qty =  gt_hht_info_tab(gn_hht_info_loop_cnt).inside_qty
            )
            OR
            (gr_param.output_term = cv_output_term_2)
        THEN
          --  �p�����[�^���ق���ŁA���ɐ��ʁA�o�ɐ��ʕs��v�̃f�[�^
          --  �p�����[�^���قȂ��ŁA���ɐ��ʁA�o�ɐ��ʈ�v�̃f�[�^
          --  �p�����[�^���ٗL���ŁA�S�f�[�^
-- == 2010/11/29 V1.4 Added END   ===============================================================
          -- ======================================
          -- ���[�N�e�[�u���f�[�^�o�^(A-3,A-5,A-7)
          -- ======================================
          ins_work(
              gn_hht_info_loop_cnt => gn_hht_info_loop_cnt -- HHT���o�Ƀf�[�^���[�v�J�E���^
            , ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
-- == 2010/11/29 V1.4 Added START ===============================================================
        END IF;
-- == 2010/11/29 V1.4 Added END   ===============================================================
--
       END LOOP gn_hht_info_cnt_loop;
--
    END IF;
--
    -- �o�͑Ώی�����0���̏ꍇ�A���[�N�e�[�u���Ƀp�����[�^���݂̂�o�^
-- == 2010/11/29 V1.4 Modified START ===============================================================
--    IF (gn_target_cnt = 0) THEN
    IF (gn_ins_cnt = 0) THEN
-- == 2010/11/29 V1.4 Modified END   ===============================================================
--
      -- 0�����b�Z�[�W�̎擾
      lv_nodata_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_xxcoi_00008
                         );
--
      -- ==============================================
      --  ���[�N�e�[�u���f�[�^�o�^(0��)(A-8)
      -- ==============================================
      ins_work_zero(
           iv_nodata_msg        => lv_nodata_msg        -- �[�������b�Z�[�W
         , ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
         , ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
         , ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �I���p�����[�^����
      IF ( lv_retcode = cv_status_error ) THEN
        -- �G���[����
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- =====================================================
    -- SVF�N��(A-9)
    -- =====================================================
    svf_request(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- =====================================================
    -- ���[�N�e�[�u���f�[�^�폜(A-10)
    -- =====================================================
    del_work(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;

--
    -- ����I������
    gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
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
    errbuf               OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode              OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_target_date       IN  VARCHAR2,      --   1.�Ώ۔N��
    iv_base_code         IN  VARCHAR2,      --   2.���_
    iv_output_standard   IN  VARCHAR2,      --   3.�o�͊
    iv_output_term       IN  VARCHAR2)      --   4.�o�͏���
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
       iv_which   =>  cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_target_date       --   1.�Ώ۔N��
      ,iv_base_code         --   2.���_
      ,iv_output_standard   --   3.�o�͊
      ,iv_output_term       --   4.�o�͏���
      ,lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- �I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOI003A05R;
/
