CREATE OR REPLACE PACKAGE BODY XXCOI004A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI004A04R(body)
 * Description      : VD�@���݌ɕ\
 * MD.050           : MD050_COI_004_A04
 * Version          : 1.2
 *
 * Program List
 * ------------------------ --------------------------------------------------------
 *  Name                     Description
 * ------------------------ --------------------------------------------------------
 *  del_rep_table_data       ���[�N�e�[�u���f�[�^�폜(A-9)
 *  exec_svf_conc            SVF�R���J�����g�N��(A-5)
 *  ins_vd_inv_wk            ���[�N�e�[�u���f�[�^�o�^��(A-7)
 *  init                     ��������(A-2)
 *  chk_param                �p�����[�^�K�{�`�F�b�N(A-1)
 *  submain                  ���C�������v���V�[�W��
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   H.Wada           �V�K�쐬
 *  2009/03/05    1.1   H.Wada           ��Q�ԍ� #032
 *                                         �E�擾����0�������C��
 *                                         �ESVF���ʊ֐��ďo�O�R�~�b�g�����ǉ�
 *  2009/05/19    1.2   T.Nakamura       [T1_0980]���[�N�e�[�u���f�[�^�o�^���ڂɏo�͊��Ԃ�ǉ�
 *                                       [T1_0991]VD�@���݌ɕ\��H/C�ɏo�͂���l��ύX
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
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
--  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
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
  lock_expt                   EXCEPTION;   -- ���b�N�擾�G���[
  no_data_expt                EXCEPTION;   -- �擾����0����O
  exec_svfapi_expt            EXCEPTION;   -- SVF���[���ʊ֐��G���[
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 ); -- ���b�N�擾��O
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(15) := 'XXCOI004A04R';
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)  := 'XXCOI';
  -- ���b�Z�[�W
  cv_msg_coi_00008            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008'; -- 0�����b�Z�[�W
  cv_msg_coi_00010            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00010'; -- API�G���[���b�Z�[�W
  cv_msg_coi_10304            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10304'; -- ���̓p�����[�^�K�{�`�F�b�N�G���[(�o�͋��_)
  cv_msg_coi_10305            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10305'; -- ���̓p�����[�^�K�{�`�F�b�N�G���[(�o�͊���)
  cv_msg_coi_10306            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10306'; -- ���̓p�����[�^�K�{�`�F�b�N�G���[(�o�͑Ώ�)
  cv_msg_coi_10150            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10150'; -- �p�����[�^�o�͋��_���b�Z�[�W
  cv_msg_coi_10151            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10151'; -- �p�����[�^�o�͊��ԃ��b�Z�[�W
  cv_msg_coi_10152            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10152'; -- �p�����[�^�o�͑Ώۃ��b�Z�[�W
  cv_msg_coi_10153            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10153'; -- �p�����[�^�c�ƈ����b�Z�[�W
  cv_msg_coi_10154            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10154'; -- �p�����[�^�ڋq���b�Z�[�W
  cv_msg_coi_10155            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10155'; -- ���b�N�擾�G���[���b�Z�[�W
-- == 2009/05/19 V1.2 Added START ==================================================================
  cv_msg_coi_10383            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10383'; -- �o�͊��ԓ��e�擾�G���[���b�Z�[�W
  cv_log                      CONSTANT VARCHAR2(3)  := 'LOG';              -- �R���J�����g�w�b�_�o�͐�
-- == 2009/05/19 V1.2 Added END   ==================================================================
  -- �g�[�N��
  cv_tkn_name_p_base          CONSTANT VARCHAR2(6)  := 'P_BASE';
  cv_tkn_name_p_term          CONSTANT VARCHAR2(6)  := 'P_TERM';
  cv_tkn_name_p_subject       CONSTANT VARCHAR2(9)  := 'P_SUBJECT';
  cv_tkn_name_p_num           CONSTANT VARCHAR2(5)  := 'P_NUM';
  cv_tkn_name_p_employee      CONSTANT VARCHAR2(10) := 'P_EMPLOYEE';
  cv_tkn_name_p_customer      CONSTANT VARCHAR2(10) := 'P_CUSTOMER';
  cv_tkn_api_name             CONSTANT VARCHAR2(8)  := 'API_NAME';
  cv_val_submit_svf_request   CONSTANT VARCHAR2(18) := 'SUBMIT_SVF_REQUEST';
-- == 2009/05/19 V1.2 Added START ==================================================================
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';            -- �Q�ƃ^�C�v
  cv_tkn_lookup_code          CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';            -- �Q�ƃR�[�h
-- == 2009/05/19 V1.2 Added END   ==================================================================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- VD�@���݌ɕ\�i�[�p���R�[�h�ϐ�
  TYPE vd_inv_wk_rec IS TABLE OF VARCHAR2(360) INDEX BY BINARY_INTEGER;
  -- VD�@���݌ɕ\�i�[�p�e�[�u���ϐ�
  TYPE vd_inv_wk_ttype IS TABLE OF vd_inv_wk_rec INDEX BY BINARY_INTEGER;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���̓p�����[�^
  gv_output_base              VARCHAR2(5);                           --  1.�o�͋��_
  gv_output_period            VARCHAR2(1);                           --  2.�o�͊���
  gv_output_target            VARCHAR2(1);                           --  3.�o�͑Ώ�
  gv_sales_staff_1            VARCHAR2(10);                          --  4.�c�ƈ�1
  gv_sales_staff_2            VARCHAR2(10);                          --  5.�c�ƈ�2
  gv_sales_staff_3            VARCHAR2(10);                          --  6.�c�ƈ�3
  gv_sales_staff_4            VARCHAR2(10);                          --  7.�c�ƈ�4
  gv_sales_staff_5            VARCHAR2(10);                          --  8.�c�ƈ�5
  gv_sales_staff_6            VARCHAR2(10);                          --  9.�c�ƈ�6
  gv_customer_1               VARCHAR2(9);                           -- 10.�ڋq1
  gv_customer_2               VARCHAR2(9);                           -- 11.�ڋq2
  gv_customer_3               VARCHAR2(9);                           -- 12.�ڋq3
  gv_customer_4               VARCHAR2(9);                           -- 13.�ڋq4
  gv_customer_5               VARCHAR2(9);                           -- 14.�ڋq5
  gv_customer_6               VARCHAR2(9);                           -- 15.�ڋq6
  gv_customer_7               VARCHAR2(9);                           -- 16.�ڋq7
  gv_customer_8               VARCHAR2(9);                           -- 17.�ڋq8
  gv_customer_9               VARCHAR2(9);                           -- 18.�ڋq9
  gv_customer_10              VARCHAR2(9);                           -- 19.�ڋq10
  gv_customer_11              VARCHAR2(9);                           -- 20.�ڋq11
  gv_customer_12              VARCHAR2(9);                           -- 21.�ڋq12
-- == 2009/05/19 V1.2 Added START ==================================================================
  gv_output_period_meaning    VARCHAR2(4);                           -- �o�͊��ԓ��e
-- == 2009/05/19 V1.2 Added END   ==================================================================
--
  gt_vd_inv_wk_tab   vd_inv_wk_ttype;   -- VD�@���݌ɕ\���[�N�e�[�u���i�[�p
--
  /**********************************************************************************
   * Procedure Name   : del_rep_table_data
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-9)
   ***********************************************************************************/
  PROCEDURE del_rep_table_data(
    ov_errbuf     OUT VARCHAR2,  -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,  -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_table_data'; -- �v���O������
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
    CURSOR get_vd_inv_wk_cur
    IS
      SELECT 'X'
      FROM   xxcoi_rep_vd_inventory   xrvi
      WHERE  xrvi.request_id = cn_request_id
      FOR UPDATE OF xrvi.request_id NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    get_vd_inv_wk_rec  get_vd_inv_wk_cur%ROWTYPE;
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
    --==============================================================
    --VD�@���݌ɕ\���[�N�e�[�u�����b�N�擾
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN get_vd_inv_wk_cur;
    FETCH get_vd_inv_wk_cur INTO get_vd_inv_wk_rec;
    CLOSE get_vd_inv_wk_cur;
--
  --==============================================================
  --VD�@���݌ɕ\���[�N�e�[�u���폜
  --==============================================================
    DELETE FROM xxcoi_rep_vd_inventory xrbi
    WHERE xrbi.request_id = cn_request_id;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN                          --*** ���[�N�e�[�u�����b�N�擾�G���[ ***
      IF (get_vd_inv_wk_cur%ISOPEN) THEN
        CLOSE get_vd_inv_wk_cur;
      END IF;
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10155);
      lv_errbuf := lv_errmsg;
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END del_rep_table_data;
--
  /**********************************************************************************
   * Procedure Name   : exec_svf_conc
   * Description      : SVF�R���J�����g�N��(A-5)
   ***********************************************************************************/
  PROCEDURE exec_svf_conc(
     ov_errbuf     OUT VARCHAR2                                    -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2                                    -- 2.���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2                                    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ,iv_zero_msg   IN  VARCHAR2                                    -- 4.0�����b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_svf_conc'; -- �v���O������
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
    cv_output_mode       CONSTANT VARCHAR2(1)  := '1';  
    cv_frm_nm            CONSTANT VARCHAR2(16) := 'XXCOI004A04S.xml';   -- �t�H�[���p�V�K�t�@�C����
    cv_vrq_nm            CONSTANT VARCHAR2(16) := 'XXCOI004A04S.vrq';   -- �N�G���[�l���t�@�C����
    cv_format_date_ymd   CONSTANT VARCHAR2(8)  := 'YYYYMMDD';           -- ���t�t�H�[�}�b�g�i�N�����j
--
    -- *** ���[�J���ϐ� ***
    lv_svf_file_name   VARCHAR2(50);
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
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR ( cd_creation_date, cv_format_date_ymd )
                     || TO_CHAR ( cn_request_id );
--
    --==============================================================
    --SVF���[���ʊ֐�(SVF�R���J�����g�̋N��)
    --==============================================================
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_retcode      => lv_retcode                                  -- ���^�[���R�[�h
      ,ov_errbuf       => lv_errbuf                                   -- �G���[���b�Z�[�W
      ,ov_errmsg       => lv_errmsg                                   -- ���[�U�[�E�G���[���b�Z�[�W
      ,iv_conc_name    => cv_pkg_name                                 -- �R���J�����g��
      ,iv_file_name    => lv_svf_file_name                            -- �o�̓t�@�C����
      ,iv_file_id      => cv_pkg_name                                 -- ���[ID
      ,iv_output_mode  => cv_output_mode                              -- �o�͋敪
      ,iv_frm_file     => cv_frm_nm                                   -- �t�H�[���l���t�@�C����
      ,iv_vrq_file     => cv_vrq_nm                                   -- �N�G���[�l���t�@�C����
      ,iv_org_id       => fnd_global.org_id                           -- ORG_ID
      ,iv_user_name    => fnd_global.user_name                        -- ���O�C���E���[�U��
      ,iv_resp_name    => fnd_global.resp_name                        -- ���O�C���E���[�U�̐E�Ӗ�
      ,iv_doc_name     => NULL                                        -- ������
      ,iv_printer_name => NULL                                        -- �v�����^��
      ,iv_request_id   => cn_request_id                               -- �v��ID
      ,iv_nodata_msg   => iv_zero_msg                                 -- �f�[�^�Ȃ����b�Z�[�W
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode <> cv_status_normal) THEN
      -- API�G���[���b�Z�[�W�̎擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00010
                     ,iv_token_name1  => cv_tkn_api_name
                     ,iv_token_value1 => cv_val_submit_svf_request
                   );
      lv_errbuf := lv_errmsg;
      RAISE exec_svfapi_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN exec_svfapi_expt THEN                           --*** SVF���[���ʊ֐��G���[ ***
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
  END exec_svf_conc;
--
  /**********************************************************************************
   * Procedure Name   : ins_vd_inv_wk
   * Description      : ���[�N�e�[�u���f�[�^�o�^��(A-7)
   ***********************************************************************************/
  PROCEDURE ins_vd_inv_wk(
    ov_errbuf            OUT VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode           OUT VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg            OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   ,ir_coi_vd_inv_wk_rec IN  vd_inv_wk_rec) -- VD�@���݌ɕ\�i�[�p���R�[�h�ϐ�
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_vd_inv_wk'; -- �v���O������
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
    INSERT INTO xxcoi_rep_vd_inventory(
      vd_inv_wk_id                                          --   1.�x���_�@���݌ɕ\���[�NID
     ,base_code                                             --   2.���_�R�[�h
     ,base_name                                             --   3.���_��
     ,customer_code                                         --   4.�ڋq�R�[�h
     ,customer_name                                         --   5.�ڋq��
     ,model_code                                            --   6.�@��R�[�h
     ,sele_qnt                                              --   7.�Z����
     ,charge_business_member_code                           --   8.�c�ƒS���҃R�[�h
     ,charge_business_member_name                           --   9.�c�ƒS���Җ�
-- == 2009/05/19 V1.2 Added START ==================================================================
     ,output_period                                         --  �o�͊���
-- == 2009/05/19 V1.2 Added END   ==================================================================
     ,column_no1                                            --  10.�R������1
     ,column_no2                                            --  11.�R������2
     ,column_no3                                            --  12.�R������3
     ,column_no4                                            --  13.�R������4
     ,column_no5                                            --  14.�R������5
     ,column_no6                                            --  15.�R������6
     ,column_no7                                            --  16.�R������7
     ,column_no8                                            --  17.�R������8
     ,column_no9                                            --  18.�R������9
     ,column_no10                                           --  19.�R������10
     ,column_no11                                           --  20.�R������11
     ,column_no12                                           --  21.�R������12
     ,column_no13                                           --  22.�R������13
     ,column_no14                                           --  23.�R������14
     ,column_no15                                           --  24.�R������15
     ,column_no16                                           --  25.�R������16
     ,column_no17                                           --  26.�R������17
     ,column_no18                                           --  27.�R������18
     ,column_no19                                           --  28.�R������19
     ,column_no20                                           --  29.�R������20
     ,column_no21                                           --  30.�R������21
     ,column_no22                                           --  31.�R������22
     ,column_no23                                           --  32.�R������23
     ,column_no24                                           --  33.�R������24
     ,column_no25                                           --  34.�R������25
     ,column_no26                                           --  35.�R������26
     ,column_no27                                           --  36.�R������27
     ,column_no28                                           --  37.�R������28
     ,column_no29                                           --  38.�R������29
     ,column_no30                                           --  39.�R������30
     ,column_no31                                           --  40.�R������31
     ,column_no32                                           --  41.�R������32
     ,column_no33                                           --  42.�R������33
     ,column_no34                                           --  43.�R������34
     ,column_no35                                           --  44.�R������35
     ,column_no36                                           --  45.�R������36
     ,column_no37                                           --  46.�R������37
     ,column_no38                                           --  47.�R������38
     ,column_no39                                           --  48.�R������39
     ,column_no40                                           --  49.�R������40
     ,column_no41                                           --  50.�R������41
     ,column_no42                                           --  51.�R������42
     ,column_no43                                           --  52.�R������43
     ,column_no44                                           --  53.�R������44
     ,column_no45                                           --  54.�R������45
     ,column_no46                                           --  55.�R������46
     ,column_no47                                           --  56.�R������47
     ,column_no48                                           --  57.�R������48
     ,column_no49                                           --  58.�R������49
     ,column_no50                                           --  59.�R������50
     ,column_no51                                           --  60.�R������51
     ,column_no52                                           --  61.�R������52
     ,column_no53                                           --  62.�R������53
     ,column_no54                                           --  63.�R������54
     ,column_no55                                           --  64.�R������55
     ,column_no56                                           --  65.�R������56
     ,item_code1                                            --  66.�i�ڃR�[�h1
     ,item_code2                                            --  67.�i�ڃR�[�h2
     ,item_code3                                            --  68.�i�ڃR�[�h3
     ,item_code4                                            --  69.�i�ڃR�[�h4
     ,item_code5                                            --  70.�i�ڃR�[�h5
     ,item_code6                                            --  71.�i�ڃR�[�h6
     ,item_code7                                            --  72.�i�ڃR�[�h7
     ,item_code8                                            --  73.�i�ڃR�[�h8
     ,item_code9                                            --  74.�i�ڃR�[�h9
     ,item_code10                                           --  75.�i�ڃR�[�h10
     ,item_code11                                           --  76.�i�ڃR�[�h11
     ,item_code12                                           --  77.�i�ڃR�[�h12
     ,item_code13                                           --  78.�i�ڃR�[�h13
     ,item_code14                                           --  79.�i�ڃR�[�h14
     ,item_code15                                           --  80.�i�ڃR�[�h15
     ,item_code16                                           --  81.�i�ڃR�[�h16
     ,item_code17                                           --  82.�i�ڃR�[�h17
     ,item_code18                                           --  83.�i�ڃR�[�h18
     ,item_code19                                           --  84.�i�ڃR�[�h19
     ,item_code20                                           --  85.�i�ڃR�[�h20
     ,item_code21                                           --  86.�i�ڃR�[�h21
     ,item_code22                                           --  87.�i�ڃR�[�h22
     ,item_code23                                           --  88.�i�ڃR�[�h23
     ,item_code24                                           --  89.�i�ڃR�[�h24
     ,item_code25                                           --  90.�i�ڃR�[�h25
     ,item_code26                                           --  91.�i�ڃR�[�h26
     ,item_code27                                           --  92.�i�ڃR�[�h27
     ,item_code28                                           --  93.�i�ڃR�[�h28
     ,item_code29                                           --  94.�i�ڃR�[�h29
     ,item_code30                                           --  95.�i�ڃR�[�h30
     ,item_code31                                           --  96.�i�ڃR�[�h31
     ,item_code32                                           --  97.�i�ڃR�[�h32
     ,item_code33                                           --  98.�i�ڃR�[�h33
     ,item_code34                                           --  99.�i�ڃR�[�h34
     ,item_code35                                           -- 100.�i�ڃR�[�h35
     ,item_code36                                           -- 101.�i�ڃR�[�h36
     ,item_code37                                           -- 102.�i�ڃR�[�h37
     ,item_code38                                           -- 103.�i�ڃR�[�h38
     ,item_code39                                           -- 104.�i�ڃR�[�h39
     ,item_code40                                           -- 105.�i�ڃR�[�h40
     ,item_code41                                           -- 106.�i�ڃR�[�h41
     ,item_code42                                           -- 107.�i�ڃR�[�h42
     ,item_code43                                           -- 108.�i�ڃR�[�h43
     ,item_code44                                           -- 109.�i�ڃR�[�h44
     ,item_code45                                           -- 110.�i�ڃR�[�h45
     ,item_code46                                           -- 111.�i�ڃR�[�h46
     ,item_code47                                           -- 112.�i�ڃR�[�h47
     ,item_code48                                           -- 113.�i�ڃR�[�h48
     ,item_code49                                           -- 114.�i�ڃR�[�h49
     ,item_code50                                           -- 115.�i�ڃR�[�h50
     ,item_code51                                           -- 116.�i�ڃR�[�h51
     ,item_code52                                           -- 117.�i�ڃR�[�h52
     ,item_code53                                           -- 118.�i�ڃR�[�h53
     ,item_code54                                           -- 119.�i�ڃR�[�h54
     ,item_code55                                           -- 120.�i�ڃR�[�h55
     ,item_code56                                           -- 121.�i�ڃR�[�h56
     ,item_name1                                            -- 122.�i�ږ�1
     ,item_name2                                            -- 123.�i�ږ�2
     ,item_name3                                            -- 124.�i�ږ�3
     ,item_name4                                            -- 125.�i�ږ�4
     ,item_name5                                            -- 126.�i�ږ�5
     ,item_name6                                            -- 127.�i�ږ�6
     ,item_name7                                            -- 128.�i�ږ�7
     ,item_name8                                            -- 129.�i�ږ�8
     ,item_name9                                            -- 130.�i�ږ�9
     ,item_name10                                           -- 131.�i�ږ�10
     ,item_name11                                           -- 132.�i�ږ�11
     ,item_name12                                           -- 133.�i�ږ�12
     ,item_name13                                           -- 134.�i�ږ�13
     ,item_name14                                           -- 135.�i�ږ�14
     ,item_name15                                           -- 136.�i�ږ�15
     ,item_name16                                           -- 137.�i�ږ�16
     ,item_name17                                           -- 138.�i�ږ�17
     ,item_name18                                           -- 139.�i�ږ�18
     ,item_name19                                           -- 140.�i�ږ�19
     ,item_name20                                           -- 141.�i�ږ�20
     ,item_name21                                           -- 142.�i�ږ�21
     ,item_name22                                           -- 143.�i�ږ�22
     ,item_name23                                           -- 144.�i�ږ�23
     ,item_name24                                           -- 145.�i�ږ�24
     ,item_name25                                           -- 146.�i�ږ�25
     ,item_name26                                           -- 147.�i�ږ�26
     ,item_name27                                           -- 148.�i�ږ�27
     ,item_name28                                           -- 149.�i�ږ�28
     ,item_name29                                           -- 150.�i�ږ�29
     ,item_name30                                           -- 151.�i�ږ�30
     ,item_name31                                           -- 152.�i�ږ�31
     ,item_name32                                           -- 153.�i�ږ�32
     ,item_name33                                           -- 154.�i�ږ�33
     ,item_name34                                           -- 155.�i�ږ�34
     ,item_name35                                           -- 156.�i�ږ�35
     ,item_name36                                           -- 157.�i�ږ�36
     ,item_name37                                           -- 158.�i�ږ�37
     ,item_name38                                           -- 159.�i�ږ�38
     ,item_name39                                           -- 160.�i�ږ�39
     ,item_name40                                           -- 161.�i�ږ�40
     ,item_name41                                           -- 162.�i�ږ�41
     ,item_name42                                           -- 163.�i�ږ�42
     ,item_name43                                           -- 164.�i�ږ�43
     ,item_name44                                           -- 165.�i�ږ�44
     ,item_name45                                           -- 166.�i�ږ�45
     ,item_name46                                           -- 167.�i�ږ�46
     ,item_name47                                           -- 168.�i�ږ�47
     ,item_name48                                           -- 169.�i�ږ�48
     ,item_name49                                           -- 170.�i�ږ�49
     ,item_name50                                           -- 171.�i�ږ�50
     ,item_name51                                           -- 172.�i�ږ�51
     ,item_name52                                           -- 173.�i�ږ�52
     ,item_name53                                           -- 174.�i�ږ�53
     ,item_name54                                           -- 175.�i�ږ�54
     ,item_name55                                           -- 176.�i�ږ�55
     ,item_name56                                           -- 177.�i�ږ�56
     ,price1                                                -- 178.�P��1
     ,price2                                                -- 179.�P��2
     ,price3                                                -- 180.�P��3
     ,price4                                                -- 181.�P��4
     ,price5                                                -- 182.�P��5
     ,price6                                                -- 183.�P��6
     ,price7                                                -- 184.�P��7
     ,price8                                                -- 185.�P��8
     ,price9                                                -- 186.�P��9
     ,price10                                               -- 187.�P��10
     ,price11                                               -- 188.�P��11
     ,price12                                               -- 189.�P��12
     ,price13                                               -- 190.�P��13
     ,price14                                               -- 191.�P��14
     ,price15                                               -- 192.�P��15
     ,price16                                               -- 193.�P��16
     ,price17                                               -- 194.�P��17
     ,price18                                               -- 195.�P��18
     ,price19                                               -- 196.�P��19
     ,price20                                               -- 197.�P��20
     ,price21                                               -- 198.�P��21
     ,price22                                               -- 199.�P��22
     ,price23                                               -- 200.�P��23
     ,price24                                               -- 201.�P��24
     ,price25                                               -- 202.�P��25
     ,price26                                               -- 203.�P��26
     ,price27                                               -- 204.�P��27
     ,price28                                               -- 205.�P��28
     ,price29                                               -- 206.�P��29
     ,price30                                               -- 207.�P��30
     ,price31                                               -- 208.�P��31
     ,price32                                               -- 209.�P��32
     ,price33                                               -- 210.�P��33
     ,price34                                               -- 211.�P��34
     ,price35                                               -- 212.�P��35
     ,price36                                               -- 213.�P��36
     ,price37                                               -- 214.�P��37
     ,price38                                               -- 215.�P��38
     ,price39                                               -- 216.�P��39
     ,price40                                               -- 217.�P��40
     ,price41                                               -- 218.�P��41
     ,price42                                               -- 219.�P��42
     ,price43                                               -- 220.�P��43
     ,price44                                               -- 221.�P��44
     ,price45                                               -- 222.�P��45
     ,price46                                               -- 223.�P��46
     ,price47                                               -- 224.�P��47
     ,price48                                               -- 225.�P��48
     ,price49                                               -- 226.�P��49
     ,price50                                               -- 227.�P��50
     ,price51                                               -- 228.�P��51
     ,price52                                               -- 229.�P��52
     ,price53                                               -- 230.�P��53
     ,price54                                               -- 231.�P��54
     ,price55                                               -- 232.�P��55
     ,price56                                               -- 233.�P��56
     ,hot_cold1                                             -- 234.H/C1
     ,hot_cold2                                             -- 235.H/C2
     ,hot_cold3                                             -- 236.H/C3
     ,hot_cold4                                             -- 237.H/C4
     ,hot_cold5                                             -- 238.H/C5
     ,hot_cold6                                             -- 239.H/C6
     ,hot_cold7                                             -- 240.H/C7
     ,hot_cold8                                             -- 241.H/C8
     ,hot_cold9                                             -- 242.H/C9
     ,hot_cold10                                            -- 243.H/C10
     ,hot_cold11                                            -- 244.H/C11
     ,hot_cold12                                            -- 245.H/C12
     ,hot_cold13                                            -- 246.H/C13
     ,hot_cold14                                            -- 247.H/C14
     ,hot_cold15                                            -- 248.H/C15
     ,hot_cold16                                            -- 249.H/C16
     ,hot_cold17                                            -- 250.H/C17
     ,hot_cold18                                            -- 251.H/C18
     ,hot_cold19                                            -- 252.H/C19
     ,hot_cold20                                            -- 253.H/C20
     ,hot_cold21                                            -- 254.H/C21
     ,hot_cold22                                            -- 255.H/C22
     ,hot_cold23                                            -- 256.H/C23
     ,hot_cold24                                            -- 257.H/C24
     ,hot_cold25                                            -- 258.H/C25
     ,hot_cold26                                            -- 259.H/C26
     ,hot_cold27                                            -- 260.H/C27
     ,hot_cold28                                            -- 261.H/C28
     ,hot_cold29                                            -- 262.H/C29
     ,hot_cold30                                            -- 263.H/C30
     ,hot_cold31                                            -- 264.H/C31
     ,hot_cold32                                            -- 265.H/C32
     ,hot_cold33                                            -- 266.H/C33
     ,hot_cold34                                            -- 267.H/C34
     ,hot_cold35                                            -- 268.H/C35
     ,hot_cold36                                            -- 269.H/C36
     ,hot_cold37                                            -- 270.H/C37
     ,hot_cold38                                            -- 271.H/C38
     ,hot_cold39                                            -- 272.H/C39
     ,hot_cold40                                            -- 273.H/C40
     ,hot_cold41                                            -- 274.H/C41
     ,hot_cold42                                            -- 275.H/C42
     ,hot_cold43                                            -- 276.H/C43
     ,hot_cold44                                            -- 277.H/C44
     ,hot_cold45                                            -- 278.H/C45
     ,hot_cold46                                            -- 279.H/C46
     ,hot_cold47                                            -- 280.H/C47
     ,hot_cold48                                            -- 281.H/C48
     ,hot_cold49                                            -- 282.H/C49
     ,hot_cold50                                            -- 283.H/C50
     ,hot_cold51                                            -- 284.H/C51
     ,hot_cold52                                            -- 285.H/C52
     ,hot_cold53                                            -- 286.H/C53
     ,hot_cold54                                            -- 287.H/C54
     ,hot_cold55                                            -- 288.H/C55
     ,hot_cold56                                            -- 289.H/C56
     ,inventory_quantity1                                   -- 290.����1
     ,inventory_quantity2                                   -- 291.����2
     ,inventory_quantity3                                   -- 292.����3
     ,inventory_quantity4                                   -- 293.����4
     ,inventory_quantity5                                   -- 294.����5
     ,inventory_quantity6                                   -- 295.����6
     ,inventory_quantity7                                   -- 296.����7
     ,inventory_quantity8                                   -- 297.����8
     ,inventory_quantity9                                   -- 298.����9
     ,inventory_quantity10                                  -- 299.����10
     ,inventory_quantity11                                  -- 300.����11
     ,inventory_quantity12                                  -- 301.����12
     ,inventory_quantity13                                  -- 302.����13
     ,inventory_quantity14                                  -- 303.����14
     ,inventory_quantity15                                  -- 304.����15
     ,inventory_quantity16                                  -- 305.����16
     ,inventory_quantity17                                  -- 306.����17
     ,inventory_quantity18                                  -- 307.����18
     ,inventory_quantity19                                  -- 308.����19
     ,inventory_quantity20                                  -- 309.����20
     ,inventory_quantity21                                  -- 310.����21
     ,inventory_quantity22                                  -- 311.����22
     ,inventory_quantity23                                  -- 312.����23
     ,inventory_quantity24                                  -- 313.����24
     ,inventory_quantity25                                  -- 314.����25
     ,inventory_quantity26                                  -- 315.����26
     ,inventory_quantity27                                  -- 316.����27
     ,inventory_quantity28                                  -- 317.����28
     ,inventory_quantity29                                  -- 318.����29
     ,inventory_quantity30                                  -- 319.����30
     ,inventory_quantity31                                  -- 320.����31
     ,inventory_quantity32                                  -- 321.����32
     ,inventory_quantity33                                  -- 322.����33
     ,inventory_quantity34                                  -- 323.����34
     ,inventory_quantity35                                  -- 324.����35
     ,inventory_quantity36                                  -- 325.����36
     ,inventory_quantity37                                  -- 326.����37
     ,inventory_quantity38                                  -- 327.����38
     ,inventory_quantity39                                  -- 328.����39
     ,inventory_quantity40                                  -- 329.����40
     ,inventory_quantity41                                  -- 330.����41
     ,inventory_quantity42                                  -- 331.����42
     ,inventory_quantity43                                  -- 332.����43
     ,inventory_quantity44                                  -- 333.����44
     ,inventory_quantity45                                  -- 334.����45
     ,inventory_quantity46                                  -- 335.����46
     ,inventory_quantity47                                  -- 336.����47
     ,inventory_quantity48                                  -- 337.����48
     ,inventory_quantity49                                  -- 338.����49
     ,inventory_quantity50                                  -- 339.����50
     ,inventory_quantity51                                  -- 340.����51
     ,inventory_quantity52                                  -- 341.����52
     ,inventory_quantity53                                  -- 342.����53
     ,inventory_quantity54                                  -- 343.����54
     ,inventory_quantity55                                  -- 344.����55
     ,inventory_quantity56                                  -- 345.����56
     ,created_by                                            -- 346.�쐬��
     ,creation_date                                         -- 347.�쐬��
     ,last_updated_by                                       -- 348.�ŏI�X�V��
     ,last_update_date                                      -- 349.�ŏI�X�V��
     ,last_update_login                                     -- 350.�ŏI�X�V���[�U
     ,request_id                                            -- 351.�v��ID
     ,program_application_id                                -- 352.�v���O�����A�v���P�[�V����ID
     ,program_id                                            -- 353.�v���O����ID
     ,program_update_date                                   -- 354.�v���O�����X�V��
    )
    VALUES(
      TO_NUMBER(ir_coi_vd_inv_wk_rec(1))                    --   1.�x���_�@���݌ɕ\���[�NID
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(2), 1, 4)                --   2.���_�R�[�h
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(3), 1, 240)              --   3.���_��
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(4), 1, 30)               --   4.�ڋq�R�[�h
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(5), 1, 240)              --   5.�ڋq��
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(6), 1, 25)               --   6.�@��R�[�h
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(7))                    --   7.�Z����
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(8), 1, 30)               --   8.�c�ƒS���҃R�[�h
     ,ir_coi_vd_inv_wk_rec(9)                               --   9.�c�ƒS���Җ�
-- == 2009/05/19 V1.2 Added START ==================================================================
     ,gv_output_period_meaning                              --  �o�͊���
-- == 2009/05/19 V1.2 Added END   ==================================================================
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(10))                   --  10.�R������1
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(11))                   --  11.�R������2
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(12))                   --  12.�R������3
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(13))                   --  13.�R������4
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(14))                   --  14.�R������5
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(15))                   --  15.�R������6
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(16))                   --  16.�R������7
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(17))                   --  17.�R������8
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(18))                   --  18.�R������9
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(19))                   --  19.�R������10
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(20))                   --  20.�R������11
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(21))                   --  21.�R������12
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(22))                   --  22.�R������13
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(23))                   --  23.�R������14
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(24))                   --  24.�R������15
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(25))                   --  25.�R������16
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(26))                   --  26.�R������17
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(27))                   --  27.�R������18
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(28))                   --  28.�R������19
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(29))                   --  29.�R������20
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(30))                   --  30.�R������21
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(31))                   --  31.�R������22
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(32))                   --  32.�R������23
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(33))                   --  33.�R������24
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(34))                   --  34.�R������25
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(35))                   --  35.�R������26
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(36))                   --  36.�R������27
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(37))                   --  37.�R������28
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(38))                   --  38.�R������29
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(39))                   --  39.�R������30
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(40))                   --  40.�R������31
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(41))                   --  41.�R������32
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(42))                   --  42.�R������33
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(43))                   --  43.�R������34
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(44))                   --  44.�R������35
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(45))                   --  45.�R������36
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(46))                   --  46.�R������37
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(47))                   --  47.�R������38
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(48))                   --  48.�R������39
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(49))                   --  49.�R������40
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(50))                   --  50.�R������41
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(51))                   --  51.�R������42
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(52))                   --  52.�R������43
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(53))                   --  53.�R������44
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(54))                   --  54.�R������45
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(55))                   --  55.�R������46
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(56))                   --  56.�R������47
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(57))                   --  57.�R������48
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(58))                   --  58.�R������49
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(59))                   --  59.�R������50
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(60))                   --  60.�R������51
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(61))                   --  61.�R������52
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(62))                   --  62.�R������53
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(63))                   --  63.�R������54
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(64))                   --  64.�R������55
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(65))                   --  65.�R������56
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(66), 1, 7)               --  66.�i�ڃR�[�h1
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(67), 1, 7)               --  67.�i�ڃR�[�h2
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(68), 1, 7)               --  68.�i�ڃR�[�h3
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(69), 1, 7)               --  69.�i�ڃR�[�h4
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(70), 1, 7)               --  70.�i�ڃR�[�h5
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(71), 1, 7)               --  71.�i�ڃR�[�h6
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(72), 1, 7)               --  72.�i�ڃR�[�h7
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(73), 1, 7)               --  73.�i�ڃR�[�h8
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(74), 1, 7)               --  74.�i�ڃR�[�h9
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(75), 1, 7)               --  75.�i�ڃR�[�h10
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(76), 1, 7)               --  76.�i�ڃR�[�h11
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(77), 1, 7)               --  77.�i�ڃR�[�h12
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(78), 1, 7)               --  78.�i�ڃR�[�h13
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(79), 1, 7)               --  79.�i�ڃR�[�h14
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(80), 1, 7)               --  80.�i�ڃR�[�h15
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(81), 1, 7)               --  81.�i�ڃR�[�h16
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(82), 1, 7)               --  82.�i�ڃR�[�h17
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(83), 1, 7)               --  83.�i�ڃR�[�h18
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(84), 1, 7)               --  84.�i�ڃR�[�h19
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(85), 1, 7)               --  85.�i�ڃR�[�h20
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(86), 1, 7)               --  86.�i�ڃR�[�h21
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(87), 1, 7)               --  87.�i�ڃR�[�h22
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(88), 1, 7)               --  88.�i�ڃR�[�h23
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(89), 1, 7)               --  89.�i�ڃR�[�h24
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(90), 1, 7)               --  90.�i�ڃR�[�h25
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(91), 1, 7)               --  91.�i�ڃR�[�h26
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(92), 1, 7)               --  92.�i�ڃR�[�h27
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(93), 1, 7)               --  93.�i�ڃR�[�h28
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(94), 1, 7)               --  94.�i�ڃR�[�h29
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(95), 1, 7)               --  95.�i�ڃR�[�h30
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(96), 1, 7)               --  96.�i�ڃR�[�h31
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(97), 1, 7)               --  97.�i�ڃR�[�h32
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(98), 1, 7)               --  98.�i�ڃR�[�h33
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(99), 1, 7)               --  99.�i�ڃR�[�h34
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(100), 1, 7)              -- 100.�i�ڃR�[�h35
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(101), 1, 7)              -- 101.�i�ڃR�[�h36
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(102), 1, 7)              -- 102.�i�ڃR�[�h37
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(103), 1, 7)              -- 103.�i�ڃR�[�h38
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(104), 1, 7)              -- 104.�i�ڃR�[�h39
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(105), 1, 7)              -- 105.�i�ڃR�[�h40
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(106), 1, 7)              -- 106.�i�ڃR�[�h41
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(107), 1, 7)              -- 107.�i�ڃR�[�h42
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(108), 1, 7)              -- 108.�i�ڃR�[�h43
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(109), 1, 7)              -- 109.�i�ڃR�[�h44
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(110), 1, 7)              -- 110.�i�ڃR�[�h45
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(111), 1, 7)              -- 111.�i�ڃR�[�h46
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(112), 1, 7)              -- 112.�i�ڃR�[�h47
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(113), 1, 7)              -- 113.�i�ڃR�[�h48
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(114), 1, 7)              -- 114.�i�ڃR�[�h49
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(115), 1, 7)              -- 115.�i�ڃR�[�h50
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(116), 1, 7)              -- 116.�i�ڃR�[�h51
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(117), 1, 7)              -- 117.�i�ڃR�[�h52
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(118), 1, 7)              -- 118.�i�ڃR�[�h53
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(119), 1, 7)              -- 119.�i�ڃR�[�h54
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(120), 1, 7)              -- 120.�i�ڃR�[�h55
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(121), 1, 7)              -- 121.�i�ڃR�[�h56
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(122), 1, 20)             -- 122.�i�ږ�1
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(123), 1, 20)             -- 123.�i�ږ�2
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(124), 1, 20)             -- 124.�i�ږ�3
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(125), 1, 20)             -- 125.�i�ږ�4
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(126), 1, 20)             -- 126.�i�ږ�5
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(127), 1, 20)             -- 127.�i�ږ�6
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(128), 1, 20)             -- 128.�i�ږ�7
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(129), 1, 20)             -- 129.�i�ږ�8
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(130), 1, 20)             -- 130.�i�ږ�9
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(131), 1, 20)             -- 131.�i�ږ�10
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(132), 1, 20)             -- 132.�i�ږ�11
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(133), 1, 20)             -- 133.�i�ږ�12
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(134), 1, 20)             -- 134.�i�ږ�13
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(135), 1, 20)             -- 135.�i�ږ�14
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(136), 1, 20)             -- 136.�i�ږ�15
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(137), 1, 20)             -- 137.�i�ږ�16
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(138), 1, 20)             -- 138.�i�ږ�17
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(139), 1, 20)             -- 139.�i�ږ�18
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(140), 1, 20)             -- 140.�i�ږ�19
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(141), 1, 20)             -- 141.�i�ږ�20
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(142), 1, 20)             -- 142.�i�ږ�21
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(143), 1, 20)             -- 143.�i�ږ�22
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(144), 1, 20)             -- 144.�i�ږ�23
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(145), 1, 20)             -- 145.�i�ږ�24
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(146), 1, 20)             -- 146.�i�ږ�25
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(147), 1, 20)             -- 147.�i�ږ�26
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(148), 1, 20)             -- 148.�i�ږ�27
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(149), 1, 20)             -- 149.�i�ږ�28
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(150), 1, 20)             -- 150.�i�ږ�29
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(151), 1, 20)             -- 151.�i�ږ�30
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(152), 1, 20)             -- 152.�i�ږ�31
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(153), 1, 20)             -- 153.�i�ږ�32
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(154), 1, 20)             -- 154.�i�ږ�33
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(155), 1, 20)             -- 155.�i�ږ�34
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(156), 1, 20)             -- 156.�i�ږ�35
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(157), 1, 20)             -- 157.�i�ږ�36
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(158), 1, 20)             -- 158.�i�ږ�37
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(159), 1, 20)             -- 159.�i�ږ�38
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(160), 1, 20)             -- 160.�i�ږ�39
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(161), 1, 20)             -- 161.�i�ږ�40
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(162), 1, 20)             -- 162.�i�ږ�41
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(163), 1, 20)             -- 163.�i�ږ�42
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(164), 1, 20)             -- 164.�i�ږ�43
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(165), 1, 20)             -- 165.�i�ږ�44
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(166), 1, 20)             -- 166.�i�ږ�45
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(167), 1, 20)             -- 167.�i�ږ�46
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(168), 1, 20)             -- 168.�i�ږ�47
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(169), 1, 20)             -- 169.�i�ږ�48
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(170), 1, 20)             -- 170.�i�ږ�49
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(171), 1, 20)             -- 171.�i�ږ�50
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(172), 1, 20)             -- 172.�i�ږ�51
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(173), 1, 20)             -- 173.�i�ږ�52
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(174), 1, 20)             -- 174.�i�ږ�53
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(175), 1, 20)             -- 175.�i�ږ�54
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(176), 1, 20)             -- 176.�i�ږ�55
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(177), 1, 20)             -- 177.�i�ږ�56
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(178))                  -- 178.�P��1
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(179))                  -- 179.�P��2
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(180))                  -- 180.�P��3
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(181))                  -- 181.�P��4
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(182))                  -- 182.�P��5
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(183))                  -- 183.�P��6
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(184))                  -- 184.�P��7
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(185))                  -- 185.�P��8
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(186))                  -- 186.�P��9
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(187))                  -- 187.�P��10
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(188))                  -- 188.�P��11
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(189))                  -- 189.�P��12
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(190))                  -- 190.�P��13
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(191))                  -- 191.�P��14
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(192))                  -- 192.�P��15
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(193))                  -- 193.�P��16
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(194))                  -- 194.�P��17
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(195))                  -- 195.�P��18
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(196))                  -- 196.�P��19
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(197))                  -- 197.�P��20
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(198))                  -- 198.�P��21
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(199))                  -- 199.�P��22
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(200))                  -- 200.�P��23
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(201))                  -- 201.�P��24
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(202))                  -- 202.�P��25
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(203))                  -- 203.�P��26
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(204))                  -- 204.�P��27
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(205))                  -- 205.�P��28
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(206))                  -- 206.�P��29
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(207))                  -- 207.�P��30
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(208))                  -- 208.�P��31
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(209))                  -- 209.�P��32
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(210))                  -- 210.�P��33
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(211))                  -- 211.�P��34
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(212))                  -- 212.�P��35
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(213))                  -- 213.�P��36
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(214))                  -- 214.�P��37
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(215))                  -- 215.�P��38
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(216))                  -- 216.�P��39
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(217))                  -- 217.�P��40
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(218))                  -- 218.�P��41
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(219))                  -- 219.�P��42
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(220))                  -- 220.�P��43
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(221))                  -- 221.�P��44
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(222))                  -- 222.�P��45
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(223))                  -- 223.�P��46
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(224))                  -- 224.�P��47
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(225))                  -- 225.�P��48
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(226))                  -- 226.�P��49
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(227))                  -- 227.�P��50
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(228))                  -- 228.�P��51
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(229))                  -- 229.�P��52
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(230))                  -- 230.�P��53
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(231))                  -- 231.�P��54
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(232))                  -- 232.�P��55
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(233))                  -- 233.�P��56
-- == 2009/05/19 V1.2 Modified START ===============================================================
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(234), 1, 1)              -- 234.H/C1
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(235), 1, 1)              -- 235.H/C2
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(236), 1, 1)              -- 236.H/C3
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(237), 1, 1)              -- 237.H/C4
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(238), 1, 1)              -- 238.H/C5
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(239), 1, 1)              -- 239.H/C6
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(240), 1, 1)              -- 240.H/C7
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(241), 1, 1)              -- 241.H/C8
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(242), 1, 1)              -- 242.H/C9
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(243), 1, 1)              -- 243.H/C10
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(244), 1, 1)              -- 244.H/C11
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(245), 1, 1)              -- 245.H/C12
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(246), 1, 1)              -- 246.H/C13
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(247), 1, 1)              -- 247.H/C14
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(248), 1, 1)              -- 248.H/C15
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(249), 1, 1)              -- 249.H/C16
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(250), 1, 1)              -- 250.H/C17
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(251), 1, 1)              -- 251.H/C18
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(252), 1, 1)              -- 252.H/C19
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(253), 1, 1)              -- 253.H/C20
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(254), 1, 1)              -- 254.H/C21
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(255), 1, 1)              -- 255.H/C22
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(256), 1, 1)              -- 256.H/C23
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(257), 1, 1)              -- 257.H/C24
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(258), 1, 1)              -- 258.H/C25
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(259), 1, 1)              -- 259.H/C26
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(260), 1, 1)              -- 260.H/C27
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(261), 1, 1)              -- 261.H/C28
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(262), 1, 1)              -- 262.H/C29
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(263), 1, 1)              -- 263.H/C30
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(264), 1, 1)              -- 264.H/C31
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(265), 1, 1)              -- 265.H/C32
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(266), 1, 1)              -- 266.H/C33
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(267), 1, 1)              -- 267.H/C34
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(268), 1, 1)              -- 268.H/C35
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(269), 1, 1)              -- 269.H/C36
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(270), 1, 1)              -- 270.H/C37
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(271), 1, 1)              -- 271.H/C38
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(272), 1, 1)              -- 272.H/C39
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(273), 1, 1)              -- 273.H/C40
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(274), 1, 1)              -- 274.H/C41
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(275), 1, 1)              -- 275.H/C42
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(276), 1, 1)              -- 276.H/C43
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(277), 1, 1)              -- 277.H/C44
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(278), 1, 1)              -- 278.H/C45
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(279), 1, 1)              -- 279.H/C46
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(280), 1, 1)              -- 280.H/C47
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(281), 1, 1)              -- 281.H/C48
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(282), 1, 1)              -- 282.H/C49
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(283), 1, 1)              -- 283.H/C50
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(284), 1, 1)              -- 284.H/C51
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(285), 1, 1)              -- 285.H/C52
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(286), 1, 1)              -- 286.H/C53
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(287), 1, 1)              -- 287.H/C54
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(288), 1, 1)              -- 288.H/C55
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(289), 1, 1)              -- 289.H/C56
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(234), 1, 1), '3', 'H', '1', 'C', '')  -- 234.H/C1
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(235), 1, 1), '3', 'H', '1', 'C', '')  -- 235.H/C2
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(236), 1, 1), '3', 'H', '1', 'C', '')  -- 236.H/C3
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(237), 1, 1), '3', 'H', '1', 'C', '')  -- 237.H/C4
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(238), 1, 1), '3', 'H', '1', 'C', '')  -- 238.H/C5
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(239), 1, 1), '3', 'H', '1', 'C', '')  -- 239.H/C6
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(240), 1, 1), '3', 'H', '1', 'C', '')  -- 240.H/C7
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(241), 1, 1), '3', 'H', '1', 'C', '')  -- 241.H/C8
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(242), 1, 1), '3', 'H', '1', 'C', '')  -- 242.H/C9
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(243), 1, 1), '3', 'H', '1', 'C', '')  -- 243.H/C10
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(244), 1, 1), '3', 'H', '1', 'C', '')  -- 244.H/C11
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(245), 1, 1), '3', 'H', '1', 'C', '')  -- 245.H/C12
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(246), 1, 1), '3', 'H', '1', 'C', '')  -- 246.H/C13
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(247), 1, 1), '3', 'H', '1', 'C', '')  -- 247.H/C14
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(248), 1, 1), '3', 'H', '1', 'C', '')  -- 248.H/C15
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(249), 1, 1), '3', 'H', '1', 'C', '')  -- 249.H/C16
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(250), 1, 1), '3', 'H', '1', 'C', '')  -- 250.H/C17
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(251), 1, 1), '3', 'H', '1', 'C', '')  -- 251.H/C18
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(252), 1, 1), '3', 'H', '1', 'C', '')  -- 252.H/C19
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(253), 1, 1), '3', 'H', '1', 'C', '')  -- 253.H/C20
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(254), 1, 1), '3', 'H', '1', 'C', '')  -- 254.H/C21
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(255), 1, 1), '3', 'H', '1', 'C', '')  -- 255.H/C22
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(256), 1, 1), '3', 'H', '1', 'C', '')  -- 256.H/C23
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(257), 1, 1), '3', 'H', '1', 'C', '')  -- 257.H/C24
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(258), 1, 1), '3', 'H', '1', 'C', '')  -- 258.H/C25
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(259), 1, 1), '3', 'H', '1', 'C', '')  -- 259.H/C26
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(260), 1, 1), '3', 'H', '1', 'C', '')  -- 260.H/C27
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(261), 1, 1), '3', 'H', '1', 'C', '')  -- 261.H/C28
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(262), 1, 1), '3', 'H', '1', 'C', '')  -- 262.H/C29
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(263), 1, 1), '3', 'H', '1', 'C', '')  -- 263.H/C30
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(264), 1, 1), '3', 'H', '1', 'C', '')  -- 264.H/C31
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(265), 1, 1), '3', 'H', '1', 'C', '')  -- 265.H/C32
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(266), 1, 1), '3', 'H', '1', 'C', '')  -- 266.H/C33
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(267), 1, 1), '3', 'H', '1', 'C', '')  -- 267.H/C34
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(268), 1, 1), '3', 'H', '1', 'C', '')  -- 268.H/C35
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(269), 1, 1), '3', 'H', '1', 'C', '')  -- 269.H/C36
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(270), 1, 1), '3', 'H', '1', 'C', '')  -- 270.H/C37
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(271), 1, 1), '3', 'H', '1', 'C', '')  -- 271.H/C38
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(272), 1, 1), '3', 'H', '1', 'C', '')  -- 272.H/C39
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(273), 1, 1), '3', 'H', '1', 'C', '')  -- 273.H/C40
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(274), 1, 1), '3', 'H', '1', 'C', '')  -- 274.H/C41
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(275), 1, 1), '3', 'H', '1', 'C', '')  -- 275.H/C42
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(276), 1, 1), '3', 'H', '1', 'C', '')  -- 276.H/C43
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(277), 1, 1), '3', 'H', '1', 'C', '')  -- 277.H/C44
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(278), 1, 1), '3', 'H', '1', 'C', '')  -- 278.H/C45
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(279), 1, 1), '3', 'H', '1', 'C', '')  -- 279.H/C46
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(280), 1, 1), '3', 'H', '1', 'C', '')  -- 280.H/C47
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(281), 1, 1), '3', 'H', '1', 'C', '')  -- 281.H/C48
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(282), 1, 1), '3', 'H', '1', 'C', '')  -- 282.H/C49
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(283), 1, 1), '3', 'H', '1', 'C', '')  -- 283.H/C50
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(284), 1, 1), '3', 'H', '1', 'C', '')  -- 284.H/C51
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(285), 1, 1), '3', 'H', '1', 'C', '')  -- 285.H/C52
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(286), 1, 1), '3', 'H', '1', 'C', '')  -- 286.H/C53
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(287), 1, 1), '3', 'H', '1', 'C', '')  -- 287.H/C54
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(288), 1, 1), '3', 'H', '1', 'C', '')  -- 288.H/C55
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(289), 1, 1), '3', 'H', '1', 'C', '')  -- 289.H/C56
-- == 2009/05/19 V1.2 Modified END   ===============================================================
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(290))                  -- 290.����1
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(291))                  -- 291.����2
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(292))                  -- 292.����3
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(293))                  -- 293.����4
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(294))                  -- 294.����5
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(295))                  -- 295.����6
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(296))                  -- 296.����7
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(297))                  -- 297.����8
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(298))                  -- 298.����9
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(299))                  -- 299.����10
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(300))                  -- 300.����11
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(301))                  -- 301.����12
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(302))                  -- 302.����13
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(303))                  -- 303.����14
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(304))                  -- 304.����15
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(305))                  -- 305.����16
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(306))                  -- 306.����17
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(307))                  -- 307.����18
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(308))                  -- 308.����19
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(309))                  -- 309.����20
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(310))                  -- 310.����21
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(311))                  -- 311.����22
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(312))                  -- 312.����23
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(313))                  -- 313.����24
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(314))                  -- 314.����25
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(315))                  -- 315.����26
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(316))                  -- 316.����27
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(317))                  -- 317.����28
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(318))                  -- 318.����29
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(319))                  -- 319.����30
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(320))                  -- 320.����31
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(321))                  -- 321.����32
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(322))                  -- 322.����33
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(323))                  -- 323.����34
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(324))                  -- 324.����35
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(325))                  -- 325.����36
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(326))                  -- 326.����37
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(327))                  -- 327.����38
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(328))                  -- 328.����39
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(329))                  -- 329.����40
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(330))                  -- 330.����41
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(331))                  -- 331.����42
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(332))                  -- 332.����43
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(333))                  -- 333.����44
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(334))                  -- 334.����45
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(335))                  -- 335.����46
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(336))                  -- 336.����47
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(337))                  -- 337.����48
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(338))                  -- 338.����49
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(339))                  -- 339.����50
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(340))                  -- 340.����51
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(341))                  -- 341.����52
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(342))                  -- 342.����53
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(343))                  -- 343.����54
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(344))                  -- 344.����55
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(345))                  -- 345.����56
     ,cn_created_by                                         -- 346.�쐬��
     ,cd_creation_date                                      -- 347.�쐬��
     ,cn_last_updated_by                                    -- 348.�ŏI�X�V��
     ,cd_last_update_date                                   -- 349.�ŏI�X�V��
     ,cn_last_update_login                                  -- 350.�ŏI�X�V���[�U
     ,cn_request_id                                         -- 351.�v��ID
     ,cn_program_application_id                             -- 352.�v���O�����A�v���P�[�V����ID
     ,cn_program_id                                         -- 353.�v���O����ID
     ,cd_program_update_date                                -- 354.�v���O�����X�V��
    );
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_vd_inv_wk;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-2)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
-- == 2009/05/19 V1.2 Added START ==================================================================
    cv_lookup_type          CONSTANT VARCHAR2(30) := 'XXCOI1_VD_OUTPUT_PERIOD';  -- �Q�ƃ^�C�v
-- == 2009/05/19 V1.2 Added END   ==================================================================
--
    -- *** ���[�J���ϐ� ***
    lv_param_msg   VARCHAR2(5000);
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
    -- SYSDATE�AWHO�J�����擾(�w�b�_�[�ɂĎ擾�ς�)
--
    --==============================================================
    --�p�����[�^�E���O�o��
    --==============================================================
    -- �o�͋��_
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10150
                     ,iv_token_name1  => cv_tkn_name_p_base
                     ,iv_token_value1 => gv_output_base);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �o�͊���
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10151
                     ,iv_token_name1  => cv_tkn_name_p_term
                     ,iv_token_value1 => gv_output_period);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �o�͑Ώ�
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10152
                     ,iv_token_name1  => cv_tkn_name_p_subject
                     ,iv_token_value1 => gv_output_target);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �c�ƈ�1
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '1'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_1);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �c�ƈ�2
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '2'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_2);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �c�ƈ�3
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '3'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_3);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �c�ƈ�4
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '4'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_4);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �c�ƈ�5
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '5'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_5);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �c�ƈ�6
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '6'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_6);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq1
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '1'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_1);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq2
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '2'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_2);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq3
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '3'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_3);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq4
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '4'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_4);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq5
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '5'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_5);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq6
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '6'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_6);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq7
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '7'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_7);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq8
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '8'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_8);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq9
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '9'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_9);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq10
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '10'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_10);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq11
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '11'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_11);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- �ڋq12
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '12'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_12);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
-- == 2009/05/19 V1.2 Added START ==================================================================
    -- ===============================
    -- �o�͊��ԓ��e�擾
    -- ===============================
    gv_output_period_meaning := xxcoi_common_pkg.get_meaning(cv_lookup_type, gv_output_period);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( gv_output_period_meaning IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10383
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_lookup_type
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => gv_output_period
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- == 2009/05/19 V1.2 Added END   ==================================================================
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : �p�����[�^�K�{�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE chk_param(
    ov_errbuf  OUT VARCHAR2  --   �G���[�E���b�Z�[�W
   ,ov_retcode OUT VARCHAR2  --   ���^�[���E�R�[�h
   ,ov_errmsg  OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- �v���O������
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
    -- �o�͋��_��NULL�̏ꍇ
    IF (gv_output_base IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10304);
      RAISE global_api_expt;
    END IF;
--
    -- �o�͊��Ԃ�NULL�̏ꍇ
    IF (gv_output_period IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10305);
      RAISE global_api_expt;
    END IF;
--
    -- �o�͑Ώۂ�NULL�̏ꍇ
    IF (gv_output_target IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10306);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2    --    �G���[�E�o�b�t�@
   ,ov_retcode OUT VARCHAR2    --    ���^�[���E�R�[�h
   ,ov_errmsg  OUT VARCHAR2)   --    �G���[�E���b�Z�[�W
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
    cv_0               CONSTANT VARCHAR2(1) := '0';
    cv_1               CONSTANT VARCHAR2(1) := '1';
    -- *** ���[�J���ϐ� ***
    ln_vd_inv_wk_id    NUMBER;         -- �x���_�@���݌ɕ\���[�NID
    ln_cust_loop_cnt   NUMBER;         -- �ڋq���[�v�J�E���^�[
    ln_column_cnt      NUMBER;         -- �R�����񐔃J�E���^�[
    ln_rack_cnt        NUMBER;         -- ���b�N���J�E���^�[
    lv_is_next_rec_flg VARCHAR2(1);    -- �����R�[�h���݃t���O(����:N�A�L��:Y)
    lv_zero_message    VARCHAR2(1000); -- 0�����b�Z�[�W
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �ڋq��񒊏o�J�[�\��
    CURSOR get_customer_info_cur(
      lv_output_base     VARCHAR2    --  1.�o�͋��_
     ,lv_output_period   VARCHAR2    --  2.�o�͊���
     ,lv_output_target   VARCHAR2    --  3.�o�͑Ώ�
     ,lv_sales_staff_1   VARCHAR2    --  4.�c�ƈ�1
     ,lv_sales_staff_2   VARCHAR2    --  5.�c�ƈ�2
     ,lv_sales_staff_3   VARCHAR2    --  6.�c�ƈ�3
     ,lv_sales_staff_4   VARCHAR2    --  7.�c�ƈ�4
     ,lv_sales_staff_5   VARCHAR2    --  8.�c�ƈ�5
     ,lv_sales_staff_6   VARCHAR2    --  9.�c�ƈ�6
     ,lv_customer_1      VARCHAR2    -- 10.�ڋq1
     ,lv_customer_2      VARCHAR2    -- 11.�ڋq2
     ,lv_customer_3      VARCHAR2    -- 12.�ڋq3
     ,lv_customer_4      VARCHAR2    -- 13.�ڋq4
     ,lv_customer_5      VARCHAR2    -- 14.�ڋq5
     ,lv_customer_6      VARCHAR2    -- 15.�ڋq6
     ,lv_customer_7      VARCHAR2    -- 16.�ڋq7
     ,lv_customer_8      VARCHAR2    -- 17.�ڋq8
     ,lv_customer_9      VARCHAR2    -- 18.�ڋq9
     ,lv_customer_10     VARCHAR2    -- 19.�ڋq10
     ,lv_customer_11     VARCHAR2    -- 20.�ڋq11
     ,lv_customer_12     VARCHAR2)   -- 21.�ڋq12
    IS
    SELECT hca1.cust_account_id              AS customer_id                        --  1.�ڋqID
          ,DECODE(lv_output_period
            ,cv_0 ,xca1.sale_base_code
            ,cv_1 ,xca1.past_sale_base_code) AS base_code                          --  2.���_�R�[�h
          ,hca2.account_name                 AS base_name                          --  3.���_��
          ,hca1.account_number               AS customer_code                      --  4.�ڋq�R�[�h
          ,hca1.account_name                 AS customer_name                      --  5.�ڋq��
          ,punv.un_number                    AS model_code                         --  6.�@��R�[�h
          ,TO_NUMBER(punv.attribute8)        AS sele_quantity                      --  7.�Z����
          ,xmvc1.rack_quantity               AS rack_quantity                      --  8.���b�N��
          ,jrre.source_number                AS charge_business_member_code        --  9.�S���c�ƈ��R�[�h
          ,jrre.source_name                  AS charge_business_member_name        -- 10.�S���c�ƈ���
    FROM   xxcoi_mst_vd_column                  xmvc1                         --  1.VD�R�����}�X�^
          ,hz_cust_accounts                     hca1                          --  2.�ڋq�A�J�E���g
          ,xxcmm_cust_accounts                  xca1                          --  3.�ڋq�ǉ����
          ,hz_parties                           hp1                           --  4.�p�[�e�B�}�X�^
          ,hz_cust_accounts                     hca2                          --  5.�ڋq�A�J�E���g(���_)
          ,hz_parties                           hp2                           --  6.�p�[�e�B�}�X�^(���_)
          ,csi_item_instances                   cii                           --  7.�����}�X�^
          ,po_un_numbers_vl                     punv                          --  8.�@��}�X�^
          ,hz_organization_profiles             hop                           --  9.�g�D�v���t�@�C���}�X�^
          ,ego_resource_agv                     era                           -- 10.���\�[�X�r���[
          ,jtf_rs_resource_extns                jrre                          -- 11.���\�[�X
          ,(SELECT DISTINCT hca3.cust_account_id   AS cust_account_id
            FROM   hz_cust_accounts      hca3  --  �ڋq�A�J�E���g
            WHERE  EXISTS (
              SELECT 'X'
              FROM   xxcoi_mst_vd_column    xmvc2
              WHERE  hca3.cust_account_id = xmvc2.customer_id 
              AND    (lv_output_target = cv_1
                   OR lv_output_target = cv_0
                   AND NOT EXISTS (
                     SELECT 'X'
                     FROM   xxcoi_mst_vd_column  xmvc3   -- VD�R�����}�X�^
                     WHERE  xmvc3.vd_column_mst_id    = xmvc2.vd_column_mst_id
                     AND    xmvc3.customer_id         = xmvc2.customer_id  
                     AND    NVL(xmvc3.item_id, -1)    = NVL(xmvc3.last_month_item_id, -1)
                     AND    xmvc3.inventory_quantity  = xmvc3.last_month_inventory_quantity
                     AND    NVL(xmvc3.price, -1)      = NVL(xmvc3.last_month_price, -1)
                     AND    NVL(xmvc3.hot_cold, cv_0) = NVL(xmvc3.last_month_hot_cold, cv_0)))))  sub_quary -- 12.�T�u�N�G���[
    WHERE  sub_quary.cust_account_id            = xmvc1.customer_id
    AND    xmvc1.column_no                      = 1
    AND    xmvc1.customer_id                    = hca1.cust_account_id
    AND    hp1.party_id                         = hca1.party_id
    AND    hca1.cust_account_id                 = xca1.customer_id
    AND    hp1.duns_number_c                    IN (30, 40, 50, 80)
    AND    hp2.party_id                         = hca2.party_id
    AND    hca1.cust_account_id                 = cii.owner_party_account_id
    AND    cii.instance_status_id               <> 1
    AND    cii.attribute1                       = punv.un_number
    AND    punv.attribute8                      IS NOT NULL
    AND    punv.attribute8                      <> 0
    AND    ((lv_output_period  = cv_0 AND hca2.account_number = xca1.sale_base_code)
           OR(lv_output_period = cv_1 AND hca2.account_number = xca1.past_sale_base_code))
    AND    lv_output_base                       = hca2.account_number
    AND    hp1.party_id                         = hca1.party_id
    AND    hca1.party_id                        = hop.party_id
    AND    hop.organization_profile_id          = era.organization_profile_id(+)
    AND    TRUNC(hop.effective_start_date) <= TRUNC(xxccp_common_pkg2.get_process_date)
    AND    TRUNC(NVL(hop.effective_end_date, xxccp_common_pkg2.get_process_date)) >= TRUNC(xxccp_common_pkg2.get_process_date)
    AND    TRUNC(NVL(era.resource_s_date, xxccp_common_pkg2.get_process_date)) <= TRUNC(xxccp_common_pkg2.get_process_date)
    AND    TRUNC(NVL(era.resource_e_date, xxccp_common_pkg2.get_process_date)) >= TRUNC(xxccp_common_pkg2.get_process_date)
    AND    era.resource_no                      = jrre.source_number(+)
    AND    ((  lv_sales_staff_1 IS NULL
           AND lv_sales_staff_2 IS NULL
           AND lv_sales_staff_3 IS NULL
           AND lv_sales_staff_4 IS NULL
           AND lv_sales_staff_5 IS NULL
           AND lv_sales_staff_6 IS NULL
           AND lv_customer_1    IS NULL
           AND lv_customer_2    IS NULL
           AND lv_customer_3    IS NULL
           AND lv_customer_4    IS NULL
           AND lv_customer_5    IS NULL
           AND lv_customer_6    IS NULL
           AND lv_customer_7    IS NULL
           AND lv_customer_8    IS NULL
           AND lv_customer_9    IS NULL
           AND lv_customer_10   IS NULL
           AND lv_customer_11   IS NULL
           AND lv_customer_12   IS NULL)
           OR
           (  NVL(lv_sales_staff_1, '#') = jrre.source_number
           OR NVL(lv_sales_staff_2, '#') = jrre.source_number
           OR NVL(lv_sales_staff_3, '#') = jrre.source_number
           OR NVL(lv_sales_staff_4, '#') = jrre.source_number
           OR NVL(lv_sales_staff_5, '#') = jrre.source_number
           OR NVL(lv_sales_staff_6, '#') = jrre.source_number
           OR NVL(lv_customer_1,    '#') = hca1.account_number
           OR NVL(lv_customer_2,    '#') = hca1.account_number
           OR NVL(lv_customer_3,    '#') = hca1.account_number
           OR NVL(lv_customer_4,    '#') = hca1.account_number
           OR NVL(lv_customer_5,    '#') = hca1.account_number
           OR NVL(lv_customer_6,    '#') = hca1.account_number
           OR NVL(lv_customer_7,    '#') = hca1.account_number
           OR NVL(lv_customer_8,    '#') = hca1.account_number
           OR NVL(lv_customer_9,    '#') = hca1.account_number
           OR NVL(lv_customer_10,   '#') = hca1.account_number
           OR NVL(lv_customer_11,   '#') = hca1.account_number
           OR NVL(lv_customer_12,   '#') = hca1.account_number))
    ORDER BY customer_code;
--
    -- �R������񒊏o�J�[�\��
    CURSOR get_column_info_cur(
      lv_output_period   VARCHAR2    --  1.�o�͊���
     ,lv_customer_id     VARCHAR2)   --  2.�ڋqID
    IS
    SELECT xmvc.column_no                                                           AS column_no     -- 1.�R������
          ,sub_query.item_code                                                      AS item_code     -- 2.�i�ڃR�[�h
          ,sub_query.short_name                                                     AS item_name     -- 3.�i�ږ�(����)
          ,DECODE(lv_output_period
            ,'0' ,xmvc.price ,'1' ,xmvc.last_month_price)                           AS price         -- 4.�P��
          ,DECODE(lv_output_period
            ,'0' ,xmvc.hot_cold ,'1' ,xmvc.last_month_hot_cold)                     AS hot_cold      -- 5.H/C
          ,DECODE(lv_output_period
            ,'0' ,xmvc.inventory_quantity ,'1' ,xmvc.last_month_inventory_quantity) AS inventory_qnt -- 6.��݌ɐ�
    FROM   xxcoi_mst_vd_column                                                      xmvc        -- 1.VD�R�����}�X�^
         ,(SELECT msib.segment1          AS item_code  -- 1.�i�ڃR�[�h
                 ,ximb.item_short_name   AS short_name -- 2.�i�ږ�(����)
                 ,msib.inventory_item_id AS item_id    -- 3.�i��ID
           FROM   mtl_system_items_b     msib   -- 1.DISC�i�ڃ}�X�^
                 ,ic_item_mst_b          iimb   -- 2.OPM�i�ڃ}�X�^
                 ,xxcmn_item_mst_b       ximb   -- 3.OPOM�i�ڃ}�X�^
                 ,xxcmm_system_items_b   xsib   -- 4.DISC�i�ڃA�h�I��
           WHERE  msib.segment1        = iimb.item_no
           AND    msib.organization_id = xxcoi_common_pkg.get_organization_id('S01')
           AND    iimb.item_id         = ximb.item_id
           AND    iimb.item_id         = xsib.item_id 
           AND    iimb.attribute26 = '1')                                           sub_query   -- 2.�i�ڏ��T�u�N�G���[
    WHERE  xmvc.customer_id  = lv_customer_id
    AND    sub_query.item_id = CASE lv_output_period
                                 WHEN '0' THEN xmvc.item_id
                                 WHEN '1' THEN xmvc.last_month_item_id
                               END
    ORDER BY xmvc.column_no;
--
    -- ===============================
    -- ���[�J���E���R�[�h
    -- ===============================
    get_customer_info_rec   get_customer_info_cur%ROWTYPE;   -- �ڋq��񒊏o���R�[�h
    get_column_info_rec     get_column_info_cur%ROWTYPE;     -- �R������񒊏o���R�[�h
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
    gn_target_cnt       := 0;
    gn_normal_cnt       := 0;
    gn_error_cnt        := 0;
    -- ���[�J���ϐ��̏�����
    ln_cust_loop_cnt    := 0;    -- �ڋq���[�v�J�E���^�[
    ln_column_cnt       := 0;    -- �R�����񐔃J�E���^�[
    ln_rack_cnt         := 0;    -- ���b�N���J�E���^�[
    gt_vd_inv_wk_tab.DELETE;
    lv_zero_message     := NULL; -- 0�����b�Z�[�W
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �p�����[�^�K�{�`�F�b�N(A-1)
    -- ===============================
    chk_param(
      ov_errbuf  => lv_errbuf     --    �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode    --    ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg);   --    ���[�U�[�E�G���[�E���b�Z�[�W
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��������(A-2)
    -- ===============================
    init(
      ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg); -- ���[�U�[�E�G���[�E���b�Z�[�W
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �ڋq���擾(A-3)
    -- ===============================
    OPEN get_customer_info_cur(
           gv_output_base
          ,gv_output_period
          ,gv_output_target
          ,gv_sales_staff_1
          ,gv_sales_staff_2
          ,gv_sales_staff_3
          ,gv_sales_staff_4
          ,gv_sales_staff_5
          ,gv_sales_staff_6
          ,gv_customer_1
          ,gv_customer_2
          ,gv_customer_3
          ,gv_customer_4
          ,gv_customer_5
          ,gv_customer_6
          ,gv_customer_7
          ,gv_customer_8
          ,gv_customer_9
          ,gv_customer_10
          ,gv_customer_11
          ,gv_customer_12);
--
    <<get_customer_info_loop>>
    LOOP
      FETCH get_customer_info_cur INTO get_customer_info_rec;
      EXIT WHEN get_customer_info_cur%NOTFOUND;
--
      -- �ڋq���[�v�J�E���^�[�̃J�E���g�A�b�v
      ln_cust_loop_cnt := ln_cust_loop_cnt + 1;
      -- �����R�[�h���݃t���O�̏�����
      lv_is_next_rec_flg  := 'N';
--
      -- �J�����̏�����
      FOR ln_test_cnt IN 1 .. 345 LOOP
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(ln_test_cnt) := NULL;
      END LOOP;
--
      -- �V�[�P���X�ԍ��擾
      SELECT xxcoi.xxcoi_rep_vd_inventory_s01.NEXTVAL
      INTO   ln_vd_inv_wk_id
      FROM   dual;
--
      -- �w�b�_�[����WHO�J���������e�[�u���ϐ��Ɋi�[
      gt_vd_inv_wk_tab(ln_cust_loop_cnt)(1) := ln_vd_inv_wk_id;                         -- �x���_�@���݌ɕ\���[�NID
      gt_vd_inv_wk_tab(ln_cust_loop_cnt)(2) := get_customer_info_rec.base_code;         -- ���_�R�[�h
      gt_vd_inv_wk_tab(ln_cust_loop_cnt)(3) := get_customer_info_rec.base_name;         -- ���_��
      gt_vd_inv_wk_tab(ln_cust_loop_cnt)(4) := get_customer_info_rec.customer_code;     -- �ڋq�R�[�h
      gt_vd_inv_wk_tab(ln_cust_loop_cnt)(5) := get_customer_info_rec.customer_name;     -- �ڋq��
      gt_vd_inv_wk_tab(ln_cust_loop_cnt)(6) := get_customer_info_rec.model_code;        -- �@��R�[�h
      gt_vd_inv_wk_tab(ln_cust_loop_cnt)(7) := get_customer_info_rec.sele_quantity;     -- �Z����
      gt_vd_inv_wk_tab(ln_cust_loop_cnt)(8) := get_customer_info_rec.charge_business_member_code; -- �c�ƒS���҃R�[�h
      gt_vd_inv_wk_tab(ln_cust_loop_cnt)(9) := get_customer_info_rec.charge_business_member_name; -- �c�ƒS���Җ�
      -- ===============================
      -- �J�E���^�[������(A-4)
      -- ===============================
      ln_column_cnt := 1;   -- �R�����񐔃J�E���^�[
      ln_rack_cnt   := 0;   -- ���b�N���J�E���^�[
      -- ===============================
      -- �R�������擾(A-5)
      -- ===============================
      OPEN get_column_info_cur(
             gv_output_period
            ,get_customer_info_rec.customer_id);
--
      <<get_column_info_loop>>
      LOOP
        FETCH get_column_info_cur INTO get_column_info_rec;
        EXIT WHEN get_column_info_cur%NOTFOUND;
--
        -- �����R�[�h���݃t���O��'Y'�̏ꍇ
        IF (lv_is_next_rec_flg = 'Y') THEN
          -- �ڋq���[�v�J�E���^�[�̃J�E���g�A�b�v
          ln_cust_loop_cnt := ln_cust_loop_cnt + 1;
--
          -- �J�����̏�����
          FOR ln_test_cnt IN 1 .. 345 LOOP
            gt_vd_inv_wk_tab(ln_cust_loop_cnt)(ln_test_cnt) := NULL;
          END LOOP;
          -- �V�[�P���X�ԍ��擾
          SELECT xxcoi.xxcoi_rep_vd_inventory_s01.NEXTVAL
          INTO   ln_vd_inv_wk_id
          FROM   dual;
--
          -- �w�b�_�[����WHO�J���������e�[�u���ϐ��Ɋi�[
          -- �x���_�@���݌ɕ\���[�NID
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(1) := ln_vd_inv_wk_id;
          -- ���_�R�[�h
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(2) := get_customer_info_rec.base_code;
          -- ���_��
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(3) := get_customer_info_rec.base_name;
          -- �ڋq�R�[�h
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(4) := get_customer_info_rec.customer_code;
          -- �ڋq��
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(5) := get_customer_info_rec.customer_name;
          -- �@��R�[�h
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(6) := get_customer_info_rec.model_code;
          -- �Z����
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(7) := get_customer_info_rec.sele_quantity;
          -- �c�ƒS���҃R�[�h
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(8) := get_customer_info_rec.charge_business_member_code;
          -- �c�ƒS���Җ�
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(9) := get_customer_info_rec.charge_business_member_name;
          -- ===============================
          -- �J�E���^�[������(A-4)
          -- ===============================
          ln_column_cnt := 1;   -- �R�����񐔃J�E���^�[
          -- �����R�[�h���݃t���O�������l�ɍĐݒ�
          lv_is_next_rec_flg := 'N';
        END IF;
--
        -- ====================================
        -- PL/SQL�\���[�N�e�[�u���ϐ��ݒ�(A-6)
        -- ====================================
        -- �擾�����f�[�^��PL/SQL�\���[�N�e�[�u���ϐ��ɃZ�b�g
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(9   + ln_column_cnt) := get_column_info_rec.column_no;     -- �R������
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(65  + ln_column_cnt) := get_column_info_rec.item_code;     -- �i�ڃR�[�h
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(121 + ln_column_cnt) := get_column_info_rec.item_name;     -- �i�ږ�
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(177 + ln_column_cnt) := get_column_info_rec.price;         -- �P��
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(233 + ln_column_cnt) := get_column_info_rec.hot_cold;      -- HOT/COLD
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(289 + ln_column_cnt) := get_column_info_rec.inventory_qnt; -- ��݌�
--
        -- �R�����񐔃J�E���^�[���J�E���g�A�b�v
        ln_column_cnt := ln_column_cnt + 1;
        -- ���b�N���J�E���^�[�ɃR�����񐔃J�E���^�[��8�̗]���ݒ�
        ln_rack_cnt := MOD(ln_column_cnt, 8);
        -- ���b�N���J�E���^�[���擾�������b�N���̏ꍇ
        IF (ln_rack_cnt > get_customer_info_rec.rack_quantity) THEN
          -- �R�����񐔃J�E���^�[���X�̏ꍇ
          IF (ln_column_cnt < 9) THEN
            ln_column_cnt := 9;
          -- �X���R�����񐔃J�E���^�[���P�V�̏ꍇ
          ELSIF ((9 < ln_column_cnt) AND (ln_column_cnt < 17)) THEN
            ln_column_cnt := 17;
          -- �P�V���R�����񐔃J�E���^�[���Q�T�̏ꍇ
          ELSIF ((17 < ln_column_cnt) AND (ln_column_cnt < 25)) THEN
            ln_column_cnt := 25;
          -- �Q�T���R�����񐔃J�E���^�[���R�R�̏ꍇ
          ELSIF ((25 < ln_column_cnt) AND (ln_column_cnt < 33)) THEN
            ln_column_cnt := 33;
          -- �R�R���R�����񐔃J�E���^�[���S�P�̏ꍇ
          ELSIF ((33 < ln_column_cnt) AND (ln_column_cnt < 41)) THEN
            ln_column_cnt := 41;
          -- �S�P���R�����񐔃J�E���^�[���S�X�̏ꍇ
          ELSIF ((41 < ln_column_cnt) AND (ln_column_cnt < 49)) THEN
            ln_column_cnt := 49;
          -- �S�X���R�����񐔃J�E���^�[���T�V�̏ꍇ
          ELSIF (49 < ln_column_cnt) THEN
            -- �����R�[�h���݃t���O��ݒ�
            lv_is_next_rec_flg := 'Y';
          END IF;
        END IF;
      END LOOP get_column_info_loop;
      CLOSE get_column_info_cur;
    END LOOP get_customer_info_loop;
    CLOSE get_customer_info_cur;
--
    -- �Ώی����̐ݒ�
    gn_target_cnt := ln_cust_loop_cnt;
--
    -- �ڋq��1�������݂��Ȃ��ꍇ
    IF (ln_cust_loop_cnt = 0) THEN
      -- 0���o�̓��b�Z�[�W
      lv_zero_message := xxccp_common_pkg.get_msg(
                            iv_application => cv_msg_kbn_coi
                          , iv_name        => cv_msg_coi_00008);
-- del 2009/03/05 1.1 H.Wada #032 ��
--      -- �V�[�P���X�ԍ��擾
--      SELECT xxcoi.xxcoi_rep_vd_inventory_s01.NEXTVAL
--      INTO   ln_vd_inv_wk_id
--      FROM   dual;
--
--      -- �w�b�_�[����WHO�J���������e�[�u���ϐ��Ɋi�[
--      gt_vd_inv_wk_tab(1)(1) := ln_vd_inv_wk_id; -- �x���_�@���݌ɕ\���[�NID
--      gt_vd_inv_wk_tab(1)(2) := NULL;            -- ���_�R�[�h
--      gt_vd_inv_wk_tab(1)(3) := NULL;            -- ���_��
--      gt_vd_inv_wk_tab(1)(4) := NULL;            -- �ڋq�R�[�h
--      gt_vd_inv_wk_tab(1)(5) := NULL;            -- �ڋq��
--      gt_vd_inv_wk_tab(1)(6) := NULL;            -- �@��R�[�h
--      gt_vd_inv_wk_tab(1)(7) := NULL;            -- �Z����
--      gt_vd_inv_wk_tab(1)(8) := NULL;            -- �c�ƒS���҃R�[�h
--      gt_vd_inv_wk_tab(1)(9) := NULL;            -- �c�ƒS���Җ�
--
--      <<null_set_loop>>
--      FOR ln_vd_inv_wk_column_cnt IN 1 .. 336 LOOP
--        gt_vd_inv_wk_tab(1)(9 + ln_vd_inv_wk_column_cnt) := NULL; -- �R�������A�i�ڃR�[�h�A�i�ږ��A�P���AH/C�A����
--      END LOOP null_set_loop;
--    END IF;
--
--    <<coi_vd_inv_wk_loop>>
--    FOR ln_vd_inv_wk_cnt IN gt_vd_inv_wk_tab.FIRST .. gt_vd_inv_wk_tab.LAST LOOP
--      -- ====================================
--      -- ���[�N�e�[�u���f�[�^�o�^(A-7)
--      -- ====================================
--      ins_vd_inv_wk(
--        ov_errbuf            => lv_errbuf                             -- �G���[�E���b�Z�[�W
--       ,ov_retcode           => lv_retcode                            -- ���^�[���E�R�[�h
--       ,ov_errmsg            => lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
--       ,ir_coi_vd_inv_wk_rec => gt_vd_inv_wk_tab(ln_vd_inv_wk_cnt)); -- VD�@���݌ɕ\�i�[�p���R�[�h�ϐ�
--      IF (lv_retcode = cv_status_error) THEN
--        RAISE global_process_expt;
--      END IF;
--    END LOOP coi_vd_inv_wk_loop;
--
-- del 2009/03/05 1.1 H.Wada #032 ��
-- add 2009/03/05 1.1 H.Wada #032 ��
    -- �ڋq��1���ȏ㑶�݂���ꍇ
    ELSE
      <<coi_vd_inv_wk_loop>>
      FOR ln_vd_inv_wk_cnt IN gt_vd_inv_wk_tab.FIRST .. gt_vd_inv_wk_tab.LAST LOOP
        -- ====================================
        -- ���[�N�e�[�u���f�[�^�o�^(A-7)
        -- ====================================
        ins_vd_inv_wk(
          ov_errbuf            => lv_errbuf                             -- �G���[�E���b�Z�[�W
         ,ov_retcode           => lv_retcode                            -- ���^�[���E�R�[�h
         ,ov_errmsg            => lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
         ,ir_coi_vd_inv_wk_rec => gt_vd_inv_wk_tab(ln_vd_inv_wk_cnt)); -- VD�@���݌ɕ\�i�[�p���R�[�h�ϐ�
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP coi_vd_inv_wk_loop;
--
      -- �R�~�b�g����
      COMMIT;
--
    END IF;
--
-- add 2009/03/05 1.1 H.Wada #032 ��
--
    -- ==============================================
    -- SVF�N�� (A-8)
    -- ==============================================
    exec_svf_conc(
       ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ,iv_zero_msg => lv_zero_message  -- 0�����b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- ���[�N�e�[�u���f�[�^�폜(A-9)
    -- ==============================================
    del_rep_table_data(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf           OUT VARCHAR2             --   �G���[�E���b�Z�[�W
   ,retcode          OUT VARCHAR2             --   ���^�[���E�R�[�h
   ,iv_output_base   IN  VARCHAR2             --  1.�o�͋��_
   ,iv_output_period IN  VARCHAR2 DEFAULT '0' --  2.�o�͊���
   ,iv_output_target IN  VARCHAR2             --  3.�o�͑Ώ�
   ,iv_sales_staff_1 IN  VARCHAR2             --  4.�c�ƈ�1
   ,iv_sales_staff_2 IN  VARCHAR2             --  5.�c�ƈ�2
   ,iv_sales_staff_3 IN  VARCHAR2             --  6.�c�ƈ�3
   ,iv_sales_staff_4 IN  VARCHAR2             --  7.�c�ƈ�4
   ,iv_sales_staff_5 IN  VARCHAR2             --  8.�c�ƈ�5
   ,iv_sales_staff_6 IN  VARCHAR2             --  9.�c�ƈ�6
   ,iv_customer_1    IN  VARCHAR2             -- 10.�ڋq1
   ,iv_customer_2    IN  VARCHAR2             -- 11.�ڋq2
   ,iv_customer_3    IN  VARCHAR2             -- 12.�ڋq3
   ,iv_customer_4    IN  VARCHAR2             -- 13.�ڋq4
   ,iv_customer_5    IN  VARCHAR2             -- 14.�ڋq5
   ,iv_customer_6    IN  VARCHAR2             -- 15.�ڋq6
   ,iv_customer_7    IN  VARCHAR2             -- 16.�ڋq7
   ,iv_customer_8    IN  VARCHAR2             -- 17.�ڋq8
   ,iv_customer_9    IN  VARCHAR2             -- 18.�ڋq9
   ,iv_customer_10   IN  VARCHAR2             -- 19.�ڋq10
   ,iv_customer_11   IN  VARCHAR2             -- 20.�ڋq11
   ,iv_customer_12   IN  VARCHAR2)            -- 21.�ڋq12
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
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
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
--###########################  �Œ蕔 END   #############################
--
  BEGIN
--
--###########################  �Œ蕔 START #############################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
-- == 2009/05/19 V1.2 Modified START ==================================================================
--       ov_retcode => lv_retcode
--      ,ov_errbuf  => lv_errbuf
--      ,ov_errmsg  => lv_errmsg);
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg);
-- == 2009/05/19 V1.2 Modified END   ==================================================================
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
    -- ���̓p�����[�^���O���[�o���ϐ��ɐݒ�
    gv_output_base   := iv_output_base;
    gv_output_period := iv_output_period;
    gv_output_target := iv_output_target;
    gv_sales_staff_1 := iv_sales_staff_1;
    gv_sales_staff_2 := iv_sales_staff_2;
    gv_sales_staff_3 := iv_sales_staff_3;
    gv_sales_staff_4 := iv_sales_staff_4;
    gv_sales_staff_5 := iv_sales_staff_5;
    gv_sales_staff_6 := iv_sales_staff_6;
    gv_customer_1    := iv_customer_1;
    gv_customer_2    := iv_customer_2;
    gv_customer_3    := iv_customer_3;
    gv_customer_4    := iv_customer_4;
    gv_customer_5    := iv_customer_5;
    gv_customer_6    := iv_customer_6;
    gv_customer_7    := iv_customer_7;
    gv_customer_8    := iv_customer_8;
    gv_customer_9    := iv_customer_9;
    gv_customer_10   := iv_customer_10;
    gv_customer_11   := iv_customer_11;
    gv_customer_12   := iv_customer_12;
--
    -- *** submain�Ăяo�� ***
    submain(
      ov_errbuf  => lv_errbuf    --    �G���[�E�o�b�t�@
     ,ov_retcode => lv_retcode   --    ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg);  --    �G���[�E���b�Z�[�W
--
    -- �G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    -- ��s�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    -- �G���[�̏ꍇ�A�Ώی����Ɛ��팏���̏������ƃG���[�����̃Z�b�g
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_error_cnt  := 1;
    -- ����̏ꍇ�A�Ώی����Ɠ��l�̌����𐬌��������Z�b�g
    ELSE
      gn_normal_cnt := gn_target_cnt;
    END IF;
--
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
      ,  buff   => ''
    );
--
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
--    ELSIF( lv_retcode = cv_status_warn ) THEN
--      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCOI004A04R;
/
