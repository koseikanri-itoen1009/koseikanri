create or replace PACKAGE BODY XXCOI009A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A04R(body)
 * Description      : ���o�ɃW���[�i���`�F�b�N���X�g
 * MD.050           : ���o�ɃW���[�i���`�F�b�N���X�g MD050_COI_009_A04
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_work               ���[�N�e�[�u���f�[�^�폜(A-8)
 *  svf_request            SVF�N��(A-7)
 *  upd_hht_data           �o�̓t���O�X�V(A-6)
 *  ins_work_zero          ���[�N�e�[�u���f�[�^�o�^(0��)(A-5)
 *  ins_work               ���[�N�e�[�u���f�[�^�o�^(A-4)
 *  get_hht_data           HHT���o�Ƀf�[�^�擾(A-3)
 *  get_base_data          ���_���擾����(A-2)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05    1.0   SCS.Tsuboi       �V�K�쐬
 *  2009/04/02    1.1   H.Sasaki         [T1_0002]VD�a����̌ڋq�R�[�h�o��
 *  2009/05/15    1.2   H.Sasaki         [T1_0785]���[�o�͂̃\�[�g���ڂ̐ݒ�l��ύX
 *  2009/06/03    1.3   H.Sasaki         [T1_1202]�ۊǏꏊ�}�X�^�̌��������ɍ݌ɑg�DID��ǉ�
 *  2009/06/15    1.4   H.Sasaki         [I_E_453][T1_1090]HHT���o�Ɏ擾�f�[�^��ύX
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
  lock_expt                 EXCEPTION;    -- ���b�N�擾�G���[
  get_no_data_expt          EXCEPTION;    -- �擾�f�[�^0��
  svf_request_err_expt      EXCEPTION;    -- SVF�N��API�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCOI009A04R';   -- �p�b�P�[�W��
  cv_app_name          CONSTANT VARCHAR2(5)   := 'XXCOI';          -- �A�v���P�[�V�����Z�k��
  cv_0                 CONSTANT VARCHAR2(1)   := '0';              -- �萔
  cv_1                 CONSTANT VARCHAR2(1)   := '1';              -- �萔
  cv_2                 CONSTANT VARCHAR2(1)   := '2';              -- �萔
  cv_3                 CONSTANT VARCHAR2(1)   := '3';              -- �萔
  cv_log               CONSTANT VARCHAR2(3)   := 'LOG';            -- �R���J�����g�w�b�_�o�͐�
  cv_yes               CONSTANT VARCHAR2(3)   := 'Y';              -- �萔Y
  cv_no                CONSTANT VARCHAR2(3)   := 'N';              -- �萔N
--
  -- ���b�Z�[�W
  cv_msg_xxcoi00005  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';   -- �݌ɑg�D�R�[�h�擾�G���[
  cv_msg_xxcoi00006  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';   -- �݌ɑg�DID�擾�G���[
  cv_msg_xxcoi00008  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 0�����b�Z�[�W
  cv_msg_xxcoi10004  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10004';   -- ���b�N�擾�G���[���b�Z�[�W(HHT���o�Ɉꎞ�\)
  cv_msg_xxcoi00010  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00010';   -- API�G���[
  cv_msg_xxcoi00011  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011';   -- �Ɩ����t�擾�G���[
  cv_msg_xxcoi10005  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10005';   -- ���b�N�擾�G���[���b�Z�[�W(���o�ɼެ��ْ��[���[�N�e�[�u��)
  cv_msg_xxcoi10092  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10092';   -- �������_�擾�G���[
  cv_msg_xxcoi10067  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10067';   -- �p�����[�^.�N�������b�Z�[�W
  cv_msg_xxcoi10307  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10307';   -- �p�����[�^.�o�͋敪���b�Z�[�W
  cv_msg_xxcoi10308  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10308';   -- �p�����[�^.���_���b�Z�[�W
  cv_msg_xxcoi10309  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10309';   -- �p�����[�^.���o�ɋt�]�f�[�^�敪���b�Z�[�W
  cv_msg_xxcoi10310  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10310';   -- �p�����[�^.�`�[�敪���b�Z�[�W
  cv_msg_xxcoi10311  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10311';   -- �p�����[�^�o�͋敪���擾�G���[
  cv_msg_xxcoi10312  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10312';   -- �p�����[�^�`�[�敪���擾�G���[
  cv_msg_xxcoi10313  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10313';   -- �p�����[�^���o�ɋt�]�f�[�^�敪���擾�G���[
--
  -- �g�[�N����
  cv_token_pro                CONSTANT VARCHAR2(30) := 'PRO_TOK';
  cv_token_org_code           CONSTANT VARCHAR2(30) := 'ORG_CODE_TOK';
  cv_token_output_kbn         CONSTANT VARCHAR2(30) := 'P_OUTPUT_KBN';
  cv_token_invoice_kbn        CONSTANT VARCHAR2(30) := 'P_INVOICE_KBN';
  cv_token_date               CONSTANT VARCHAR2(30) := 'P_DATE';
  cv_token_base_code          CONSTANT VARCHAR2(30) := 'P_BASE_CODE';
  cv_token_reverse_kbn        CONSTANT VARCHAR2(30) := 'P_REVERSE_KBN';
  cv_token_location_code      CONSTANT VARCHAR2(20) := 'LOCATION_CODE';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE gr_param_rec  IS RECORD(
      output_kbn        VARCHAR2(1)       -- 01 : �o�͋敪      (�K�{)
     ,invoice_kbn       VARCHAR2(2)       -- 02 : �`�[�敪      (�C��)
     ,target_date       VARCHAR2(20)      -- 03 : �N����        (�K�{)
     ,out_base_code     VARCHAR2(4)       -- 04 : ���_          (�C��)
     ,reverse_kbn       VARCHAR2(1)       -- 05 : ���o�ɋt�]�f�[�^�o�͋敪 (�K�{)
     ,output_dpt        VARCHAR2(1)       -- 06 : ���[�o�͏ꏊ  (�K�{)
    );
--
  -- ���_���i�[�p���R�[�h�ϐ�
  TYPE gr_base_num_rec IS RECORD
    (
      hca_cust_num                   hz_cust_accounts.account_number%TYPE    -- ���_�R�[�h
    );
--
  --  ���_���i�[�p�e�[�u��
  TYPE gt_base_num_ttype IS TABLE OF gr_base_num_rec INDEX BY BINARY_INTEGER;
--
  -- HHT���i�[�p���R�[�h�ϐ�
  TYPE gr_hht_info_rec IS RECORD(
      transaction_id             xxcoi_hht_inv_transactions.transaction_id%TYPE      -- HHT���o�Ƀe�[�u��ID
    , interface_id               xxcoi_hht_inv_transactions.interface_id%TYPE        -- �C���^�[�t�F�[�X
    , outside_base_code          xxcoi_hht_inv_transactions.outside_base_code%TYPE   -- �o�ɋ��_�R�[�h
    , outside_base_name          hz_cust_accounts.account_name%TYPE                  -- �o�ɋ��_��
    , outside_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE -- �o�ɑ��ۊǏꏊ�R�[�h
    , outside_subinv_name        mtl_secondary_inventories.description%TYPE          -- �o�ɑ��ۊǏꏊ��
    , invoice_type               xxcoi_hht_inv_transactions.invoice_type%TYPE        -- �`�[�敪
    , invoice_type_name          fnd_lookup_values.meaning%TYPE                      -- �`�[�敪��
    , inside_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE  -- ���ɑ��ۊǏꏊ�R�[�h
    , inside_subinv_name         mtl_secondary_inventories.description%TYPE          -- ���ɑ��ۊǏꏊ�R�[�h
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE           -- ���i�R�[�h
    , item_name                  xxcmn_item_mst_b.item_short_name%TYPE               -- ���i��
    , case_quantity              xxcoi_hht_inv_transactions.case_quantity%TYPE       -- �P�[�X��
    , case_in_quantity           xxcoi_hht_inv_transactions.case_in_quantity%TYPE    -- �P�[�X����
    , quantity                   xxcoi_hht_inv_transactions.quantity%TYPE            -- �{��
    , total_quantity             xxcoi_hht_inv_transactions.total_quantity%TYPE      -- ����
    , invoice_no                 xxcoi_hht_inv_transactions.invoice_no%TYPE          -- �`�[No
  );
--
  --  HHT���i�[�p�e�[�u��
  TYPE gt_hht_info_ttype IS TABLE OF gr_hht_info_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date           DATE;                                             -- �Ɩ����t
  gv_base_code              hz_cust_accounts.account_number%TYPE;             -- ���_�R�[�h
  gv_output_kbn_name        fnd_lookup_values.meaning%TYPE;                   -- �o�͋敪
  gv_out_base_name          hz_cust_accounts.account_name%TYPE;               -- �o�͋��_��
  -- �J�E���^
  gn_base_cnt               NUMBER;                                           -- ���_�R�[�h����
  gn_base_loop_cnt          NUMBER;                                           -- ���_�R�[�h���[�v�J�E���^
  gn_hht_info_cnt           NUMBER;                                           -- HHT���o�ɏ�񌏐�
  gn_hht_info_loop_cnt      NUMBER;                                           -- HHT���o�ɏ�񃋁[�v�J�E���^
  gn_organization_id        mtl_parameters.organization_id%TYPE;              -- �݌ɑg�DID
  --
  gr_param                  gr_param_rec;
  gt_base_num_tab           gt_base_num_ttype;
  gt_hht_info_tab           gt_hht_info_ttype;
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-8)
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
    -- ���[�N�e�[�u�����b�N
    CURSOR del_xrj_tbl_cur
    IS
      SELECT 'X'
      FROM   xxcoi_rep_shipstore_jour_list xrj     -- ���o�ɃW���[�i���`�F�b�N���X�g���[���[�N�e�[�u��
      WHERE  xrj.request_id = cn_request_id        -- �v��ID
      FOR UPDATE OF xrj.request_id NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    del_xrj_tbl_rec  del_xrj_tbl_cur%ROWTYPE;
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
    -- �J�[�\���I�[�v��
    OPEN del_xrj_tbl_cur;
--
    <<del_xrj_tbl_cur_loop>>
    LOOP
      -- ���R�[�h�Ǎ�
      FETCH del_xrj_tbl_cur INTO del_xrj_tbl_rec;
      EXIT WHEN del_xrj_tbl_cur%NOTFOUND;
--
      -- ���o�ɃW���[�i���`�F�b�N���X�g���[���[�N�e�[�u���̍폜
      DELETE
      FROM   xxcoi_rep_shipstore_jour_list xrj        -- ���o�ɃW���[�i���`�F�b�N���X�g���[���[�N�e�[�u��
      WHERE  xrj.request_id = cn_request_id           -- �v��ID
      ;
--
    END LOOP del_xrj_tbl_cur_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE del_xrj_tbl_cur;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( del_xrj_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrj_tbl_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                      , iv_name         => cv_msg_xxcoi10005
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( del_xrj_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrj_tbl_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( del_xrj_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrj_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( del_xrj_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrj_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_work;
--
  /**********************************************************************************
   * Procedure Name   : svf_request
   * Description      : SVF�N��(A-7)
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
    cv_output_mode  CONSTANT VARCHAR2(1)  := '1';                    -- �o�͋敪(PDF�o��)
    cv_frm_file     CONSTANT VARCHAR2(30) := 'XXCOI009A04S.xml';     -- �t�H�[���l���t�@�C����
    cv_vrq_file     CONSTANT VARCHAR2(30) := 'XXCOI009A04S.vrq';     -- �N�G���[�l���t�@�C����
    cv_api_name     CONSTANT VARCHAR2(7)  := 'SVF�N��';              -- SVF�N��API��
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
   * Procedure Name   : upd_hht_data
   * Description      : �o�̓t���O�X�V(A-6)
   ***********************************************************************************/
  PROCEDURE upd_hht_data(
    gn_hht_info_loop_cnt   IN NUMBER,        -- HHT���o�Ƀf�[�^��񃋁[�v�J�E���^
    ov_errbuf              OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_hht_data'; -- �v���O������
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
    lv_transaction_id      xxcoi_hht_inv_transactions.transaction_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- HHT���o�Ɉꎞ�\�e�[�u�����b�N
    CURSOR upd_hht_tbl_cur
    IS
      SELECT 'X'                       AS output_flag                                   -- �o�͋敪
      FROM   xxcoi_hht_inv_transactions xhit                                            -- HHT���o�Ɉꎞ�\
      WHERE  xhit.transaction_id = gt_hht_info_tab( gn_hht_info_loop_cnt ).transaction_id
      FOR UPDATE OF xhit.output_flag NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    upd_hht_tbl_rec  upd_hht_tbl_cur%ROWTYPE;
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
    -- �J�[�\���I�[�v��
    OPEN upd_hht_tbl_cur;
--
    -- ���R�[�h�Ǎ�
    FETCH upd_hht_tbl_cur INTO upd_hht_tbl_rec;
--
    --HHT���o�Ɉꎞ�\�̍X�V
    UPDATE xxcoi_hht_inv_transactions xhit
    SET    xhit.output_flag = cv_yes
         , xhit.last_updated_by        = cn_last_updated_by                             -- �ŏI�X�V��
         , xhit.last_update_date       = cd_last_update_date                            -- �ŏI�X�V��
         , xhit.last_update_login      = cn_last_update_login                           -- �ŏI�X�V���[�U
         , xhit.request_id             = cn_request_id                                  -- �v��ID
         , xhit.program_application_id = cn_program_application_id                      -- �v���O�����A�v���P�[�V����ID
         , xhit.program_id             = cn_program_id                                  -- �v���O����ID
         , xhit.program_update_date    = cd_program_update_date                         -- �v���O�����X�V��
    WHERE  xhit.transaction_id  = gt_hht_info_tab( gn_hht_info_loop_cnt ).transaction_id
    ;
--
    -- �J�[�\���N���[�Y
    CLOSE upd_hht_tbl_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( upd_hht_tbl_cur%ISOPEN ) THEN
        CLOSE upd_hht_tbl_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                      , iv_name         => cv_msg_xxcoi10004
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( upd_hht_tbl_cur%ISOPEN ) THEN
        CLOSE upd_hht_tbl_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( upd_hht_tbl_cur%ISOPEN ) THEN
        CLOSE upd_hht_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( upd_hht_tbl_cur%ISOPEN ) THEN
        CLOSE upd_hht_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_hht_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_zero
   * Description      : ���[�N�e�[�u���f�[�^�o�^(0��)(A-5)
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
    INSERT INTO xxcoi_rep_shipstore_jour_list(
        interface_id
       ,target_term
       ,output_kbn
       ,outside_base_code
       ,outside_base_name
       ,outside_subinv_code
       ,outside_subinv_name
       ,invoice_type
       ,invoice_type_name
       ,inside_subinv_code
       ,inside_subinv_name
       ,item_code
       ,item_name
       ,case_quantity
       ,case_in_quantity
       ,quantity
       ,total_quantity
       ,invoice_no
       ,nodata_msg
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
        NULL
       ,SUBSTRB(gr_param.target_date,1,10)       -- �Ώۊ���
       ,gv_output_kbn_name                       -- �o�͋敪
       ,gr_param.out_base_code                   -- ���_�R�[�h
       ,SUBSTRB(gv_out_base_name,1,8)            -- ���_��
       ,NULL                                     -- �o�ɑ��ۊǏꏊ�R�[�h
       ,NULL                                     -- �o�ɑ��ۊǏꏊ��
       ,NULL                                     -- �`�[�敪
       ,NULL                                     -- �`�[�敪��
       ,NULL                                     -- �o�ɑ��ۊǏꏊ�R�[�h
       ,NULL                                     -- �o�ɑ��ۊǏꏊ��
       ,NULL                                     -- ���i�R�[�h
       ,NULL                                     -- ���i��
       ,NULL                                     -- �P�[�X��
       ,NULL                                     -- ����
       ,NULL                                     -- �{��
       ,NULL                                     -- ���v����
       ,NULL                                     -- �`�[No
       ,iv_nodata_msg                            -- 0�����b�Z�[�W
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
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-4)
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
    --���o�ɃW���[�i���`�F�b�N���X�g���[���[�N�e�[�u���o�^����
    INSERT INTO xxcoi_rep_shipstore_jour_list(
        interface_id
       ,target_term                 -- 1
       ,output_kbn                  -- 2
       ,outside_base_code           -- 3
       ,outside_base_name           -- 4
       ,outside_subinv_code         -- 5
       ,outside_subinv_name         -- 6
       ,invoice_type                -- 7
       ,invoice_type_name           -- 8
       ,inside_subinv_code          -- 9
       ,inside_subinv_name          -- 0
       ,item_code                   -- 1
       ,item_name                   -- 2
       ,case_quantity               -- 3
       ,case_in_quantity            -- 4
       ,quantity                    -- 5
       ,total_quantity              -- 6
       ,invoice_no                  -- 7
       ,nodata_msg                  -- 8
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
-- == 2009/05/15 V1.2 Modified START ===============================================================
--        gt_hht_info_tab( gn_hht_info_loop_cnt ).interface_id
        gt_hht_info_tab( gn_hht_info_loop_cnt ).transaction_id                      -- �C���^�[�t�F�[�XID
-- == 2009/05/15 V1.2 Modified END   ===============================================================
       ,SUBSTR(gr_param.target_date,1,10)                                           -- 1�Ώۊ���
       ,gv_output_kbn_name                                                          -- 2�o�͋敪
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_base_code                   -- 3���_�R�[�h
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_base_name                   -- 4���_��
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_subinv_code                 -- 5�o�ɑ��ۊǏꏊ�R�[�h
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_subinv_name                 -- 6�o�ɑ��ۊǏꏊ��
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).invoice_type                        -- 7�`�[�敪
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).invoice_type_name                   -- 8�`�[�敪��
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_subinv_code                  -- 9�o�ɑ��ۊǏꏊ�R�[�h
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_subinv_name                  -- 0�o�ɑ��ۊǏꏊ��
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).item_code                           -- 1���i�R�[�h
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).item_name                           -- 2���i��
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).case_quantity                       -- 3�P�[�X��
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).case_in_quantity                    -- 4����
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).quantity                            -- 5�{��
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).total_quantity                      -- 6���v����
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).invoice_no                          -- 7�`�[No
       ,NULL                                                                        -- 80�����b�Z�[�W
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
  END ins_work;
--
  /**********************************************************************************
   * Procedure Name   : get_hht_data�i���[�v���j
   * Description      : HHT���o�Ƀf�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_hht_data(
    gn_base_loop_cnt IN NUMBER,       --   �J�E���g
    ov_errbuf        OUT VARCHAR2,    --   �G���[�E���b�Z�[�W                --# �Œ� #
    ov_retcode       OUT VARCHAR2,    --   ���^�[���E�R�[�h                  --# �Œ� #
    ov_errmsg        OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hht_data'; -- �v���O������
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
    cv_99                         CONSTANT VARCHAR2(2)  := '99';
-- == 2009/04/02 V1.1 Added START ===============================================================
    -- ���R�[�h���
    cv_record_type_30             CONSTANT VARCHAR2(2)  :=  '30';
-- == 2009/04/02 V1.1 Added END   ===============================================================
--
    -- �Q�ƃ^�C�v
-- == 2009/06/15 V1.4 Modified START ===============================================================
--    cv_invoice_type               CONSTANT VARCHAR2(30)  := 'XXCOI1_INVOICE_KBN';        -- �`�[�敪
    cv_invoice_type               CONSTANT VARCHAR2(30)  := 'XXCOI1_HHT_EBS_CONVERT_TABLE';        -- �`�[�敪
-- == 2009/06/15 V1.4 Modified END   ===============================================================
--
    -- �Q�ƃR�[�h
--
    -- *** ���[�J���ϐ� ***
    ln_cnt                         NUMBER       DEFAULT  0;          -- ���[�v�J�E���^
    lv_zero_message                VARCHAR2(30) DEFAULT  NULL;       -- �[�������b�Z�[�W
    ln_sql_cnt                     NUMBER       DEFAULT  0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- HHT���o�Ƀf�[�^
    CURSOR info_hht_cur
    IS
-- == 2009/06/15 V1.4 Modified START ===============================================================
--    SELECT  xhit.transaction_id             transaction_id              -- HHT���o�Ɉꎞ�\ID
--           ,xhit.interface_id               interface_id                -- �C���^�[�t�F�[�XID
--           ,xhit.outside_base_code          out_base_code               -- �o�ɋ��_�R�[�h
--           ,SUBSTRB(hca.account_name,1,8)   out_base_name               -- �o�ɋ��_��
--           ,xhit.outside_subinv_code        outside_subinv_code         -- �o�ɑ��ۊǏꏊ�R�[�h
--           ,msi1.description                outside_subinv_name         -- �o�ɋ��ۊǏꏊ��
--           ,xhit.invoice_type               invoice_type                -- �`�[�敪
--           ,flv.meaning                     invoice_name                -- �`�[�敪��
--           ,xhit.inside_subinv_code         inside_subinv_code          -- ���ɑ��ۊǏꏊ�R�[�h
--           ,msi2.description                inside_subinv_name          -- ���ɋ��ۊǏꏊ��
--           ,xhit.item_code                  item_code                   -- �i�ڃR�[�h
--           ,ximb.item_short_name            item_short_name             -- ����
--           ,xhit.case_quantity              case_quantity               -- �P�[�X��
--           ,xhit.case_in_quantity           case_in_quantity            -- �P�[�X����
--           ,xhit.quantity                   quantity                    -- �{��
--           ,xhit.total_quantity             total_quantity              -- ����
---- == 2009/04/02 V1.1 Modified START ===============================================================
----           ,xhit.invoice_no                invoice_no                 -- �`�[No
--           ,CASE  WHEN  xhit.record_type = cv_record_type_30  THEN
--                    NVL(xhit.inside_cust_code, xhit.invoice_no)
--                  ELSE
--                    NVL(xhit.inside_code, xhit.invoice_no)
--            END                             invoice_no                  -- �`�[��
---- == 2009/04/02 V1.1 Modified END   ===============================================================
--    FROM    xxcoi_hht_inv_transactions xhit                           -- HHT���o�Ɉꎞ�\
--           ,hz_cust_accounts           hca                            -- �ڋq�}�X�^
--           ,mtl_secondary_inventories  msi1                           -- �ۊǏꏊ�}�X�^1
--           ,mtl_secondary_inventories  msi2                           -- �ۊǏꏊ�}�X�^2
--           ,mtl_system_items_b         msib                           -- �i�ڃ}�X�^
--           ,ic_item_mst_b              iimb                           -- OPM�i�ڃ}�X�^
--           ,xxcmn_item_mst_b           ximb                           -- OPM�i�ڃA�h�I���}�X�^
--           ,fnd_lookup_values          flv                            -- �N�C�b�N�R�[�h�}�X�^
--    WHERE  xhit.output_flag                         =  gr_param.output_kbn
--      AND  xhit.invoice_type                        =  NVL(gr_param.invoice_kbn,xhit.invoice_type)
--      AND  TO_CHAR(xhit.invoice_date,'YYYY/MM/DD')  =  SUBSTR(gr_param.target_date,1,10)
--      AND  xhit.outside_base_code                   =  gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
--      AND  ( ( ( gr_param.reverse_kbn = cv_1 ) AND (xhit.total_quantity < 0 ) )
--           OR ( ( gr_param.reverse_kbn = cv_0 ) AND (xhit.total_quantity > 0 ) ) )
--      AND  hca.account_number                       =  xhit.outside_base_code
--      AND  hca.customer_class_code                  =  cv_1
--      AND  xhit.outside_subinv_code                 =  msi1.secondary_inventory_name
--      AND  xhit.inside_subinv_code                  =  msi2.secondary_inventory_name(+)
---- == 2009/06/03 V1.3 Added START ===============================================================
--      AND  msi1.organization_id                     =  gn_organization_id
--      AND  msi2.organization_id(+)                  =  gn_organization_id
---- == 2009/06/03 V1.3 Added END   ===============================================================
--      AND  msib.segment1                            =  xhit.item_code
--      AND  msib.organization_id                     =  gn_organization_id
--      AND  msib.segment1                            =  iimb.item_no
--      AND  iimb.item_id                             =  ximb.item_id(+)
--      AND  flv.lookup_type                          =  cv_invoice_type
--      AND  flv.lookup_code                          =  xhit.invoice_type
--      AND  flv.enabled_flag                         =  cv_yes
--      AND  flv.language                             =  USERENV( 'LANG' )
--   ORDER BY xhit.interface_id
--      ;
      SELECT  xhit.transaction_id             transaction_id              -- HHT���o�Ɉꎞ�\ID
             ,xhit.interface_id               interface_id                -- �C���^�[�t�F�[�XID
             ,xhit.outside_base_code          out_base_code               -- �o�ɋ��_�R�[�h
             ,SUBSTRB(hca1.account_name,1,8)  out_base_name               -- �o�ɋ��_��
            ,xhit.outside_code                outside_subinv_code         -- �o�ɑ��ۊǏꏊ�R�[�h
            ,SUBSTRB(DECODE(outside_cust_code, NULL, msi1.description
                                             , hca1.account_name
                     ), 1, 50
             )                                outside_subinv_name         -- �o�ɋ��ۊǏꏊ��
             ,flv.attribute11                 invoice_type                -- �`�[�敪
             ,flv.meaning                     invoice_name                -- �`�[�敪��
             ,xhit.inside_code                inside_subinv_code          -- ���ɑ��ۊǏꏊ�R�[�h
             ,SUBSTRB(DECODE(inside_cust_code, NULL, msi2.description
                                                   , hca2.account_name
                      ), 1, 50
              )                               inside_subinv_name          -- ���ɋ��ۊǏꏊ��
             ,xhit.item_code                  item_code                   -- �i�ڃR�[�h
             ,ximb.item_short_name            item_short_name             -- ����
             ,xhit.case_quantity              case_quantity               -- �P�[�X��
             ,xhit.case_in_quantity           case_in_quantity            -- �P�[�X����
             ,xhit.quantity                   quantity                    -- �{��
             ,xhit.total_quantity             total_quantity              -- ����
             ,xhit.invoice_no                 invoice_no                  -- �`�[��
      FROM    xxcoi_hht_inv_transactions      xhit                        -- HHT���o�Ɉꎞ�\
             ,hz_cust_accounts                hca1                        -- �ڋq�}�X�^�i�o�Ɂj
             ,hz_cust_accounts                hca2                        -- �ڋq�}�X�^�i���Ɂj
             ,mtl_secondary_inventories       msi1                        -- �ۊǏꏊ�}�X�^1
             ,mtl_secondary_inventories       msi2                        -- �ۊǏꏊ�}�X�^2
             ,mtl_system_items_b              msib                        -- �i�ڃ}�X�^
             ,ic_item_mst_b                   iimb                        -- OPM�i�ڃ}�X�^
             ,xxcmn_item_mst_b                ximb                        -- OPM�i�ڃA�h�I���}�X�^
             ,fnd_lookup_values               flv                         -- �N�C�b�N�R�[�h�}�X�^
      WHERE   xhit.output_flag                          =   gr_param.output_kbn
      AND     TO_CHAR(xhit.invoice_date, 'YYYY/MM/DD')  =   SUBSTR(gr_param.target_date, 1, 10)
      AND     xhit.outside_base_code                    =   gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
      AND     ((    (gr_param.reverse_kbn   =   cv_1)
                AND (xhit.total_quantity    <   0)
               )
               OR
               (    (gr_param.reverse_kbn   = cv_0)
                AND (xhit.total_quantity    > 0)
               )
              )
      AND     xhit.outside_base_code                    =   hca1.account_number
      AND     cv_1                                      =   hca1.customer_class_code
      AND     xhit.inside_base_code                     =   hca2.account_number(+)
      AND     cv_1                                      =   hca2.customer_class_code(+)
      AND     xhit.outside_subinv_code                  =   msi1.secondary_inventory_name
      AND     xhit.inside_subinv_code                   =   msi2.secondary_inventory_name(+)
      AND     msi1.organization_id                      =   gn_organization_id
      AND     msi2.organization_id(+)                   =   gn_organization_id
      AND     msib.segment1                             =   xhit.item_code
      AND     msib.organization_id                      =   gn_organization_id
      AND     msib.segment1                             =   iimb.item_no
      AND     iimb.item_id                              =   ximb.item_id(+)
      AND     xhit.record_type                          =   flv.attribute1
      AND     xhit.invoice_type                         =   flv.attribute2
      AND     NVL(xhit.department_flag, cv_99)          =   flv.attribute3
      AND     flv.lookup_type                           =   cv_invoice_type
      AND     flv.language                              =   USERENV('LANG')
      AND     flv.enabled_flag                          =   cv_yes
      AND     flv.attribute11                           =   NVL(gr_param.invoice_kbn, flv.attribute11)
      ORDER BY xhit.interface_id;
-- == 2009/06/15 V1.4 Modified END   ===============================================================
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
    OPEN info_hht_cur;
--
    -- ���R�[�h�Ǎ�
    FETCH info_hht_cur BULK COLLECT INTO gt_hht_info_tab;
--
    -- HHT���o�ɏ��J�E���g�Z�b�g
    gn_hht_info_cnt := gt_hht_info_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE info_hht_cur;
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
      IF ( info_hht_cur%ISOPEN ) THEN
        CLOSE info_hht_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur%ISOPEN ) THEN
        CLOSE info_hht_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur%ISOPEN ) THEN
        CLOSE info_hht_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_hht_cur%ISOPEN ) THEN
        CLOSE info_hht_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_hht_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : ���_���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_data'; -- �v���O������
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
    -- ���_���(�Ǘ������_)
    CURSOR info_base1_cur
    IS
      SELECT hca.account_number       account_num           -- �ڋq�R�[�h
      FROM   hz_cust_accounts         hca                   -- �ڋq�}�X�^
            ,xxcmm_cust_accounts      xca                   -- �ڋq�ǉ����A�h�I���}�X�^
      WHERE  hca.cust_account_id      = xca.customer_id
        AND  hca.customer_class_code  = cv_1
        AND  hca.account_number       = NVL( gr_param.out_base_code, hca.account_number )
        AND  xca.management_base_code = gv_base_code
      ORDER BY hca.account_number
    ;
--
    -- ���_���(���_)
    CURSOR info_base2_cur
    IS
      SELECT  hca.account_number      account_num           -- �ڋq�R�[�h
        FROM  hz_cust_accounts        hca                   -- �ڋq�}�X�^
       WHERE  hca.customer_class_code = cv_1
         AND  hca.account_number      = NVL( gr_param.out_base_code, hca.account_number )
       ORDER BY hca.account_number
    ;
--
    -- *** ���[�J���E���R�[�h ***
    lr_info_base1_rec   info_base1_cur%ROWTYPE;
    lr_info_base2_rec   info_base2_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ǘ������_�ŋN���̎�
    IF ( gr_param.output_dpt = cv_2 ) THEN
      OPEN info_base1_cur;
--
      -- ���R�[�h�ǂݍ���
      FETCH info_base1_cur BULK COLLECT INTO gt_base_num_tab;
      -- ���_�R�[�h����
      gn_base_cnt := gt_base_num_tab.COUNT;
      -- �J�[�\���N���[�Y
      CLOSE info_base1_cur;
--
    -- ���_�E���i���ŋN���̎�
    ELSIF ( ( gr_param.output_dpt = cv_1 ) OR ( gr_param.output_dpt = cv_3 ) ) THEN
      OPEN info_base2_cur;
      -- ���R�[�h�ǂݍ���
      FETCH info_base2_cur BULK COLLECT INTO gt_base_num_tab;
      -- ���_�R�[�h����
      gn_base_cnt := gt_base_num_tab.COUNT;
      -- �J�[�\���N���[�Y
      CLOSE info_base2_cur;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_base_data;
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
    cv_profile_name    CONSTANT VARCHAR2(24)   := 'XXCOI1_ORGANIZATION_CODE';        -- �v���t�@�C����(�݌ɑg�D�R�[�h)
    cv_output_kbn      CONSTANT VARCHAR2(30)   := 'XXCOI1_OUTPUT_KBN';               -- �Q�ƃ^�C�v(�o�͋敪)
    cv_reverse_kbn     CONSTANT VARCHAR2(30)   := 'XXCOI1_REVERSE_DATA_OUTPUT_KBN';  -- �Q�ƃ^�C�v(���o�ɋt�]�f�[�^�o�͋敪)
-- == 2009/06/15 V1.4 Modified START ===============================================================
--    cv_invoice_type    CONSTANT VARCHAR2(30)   := 'XXCOI1_INVOICE_KBN';              -- �Q�ƃ^�C�v(�`�[�敪)
    cv_invoice_type    CONSTANT VARCHAR2(30)   := 'XXCOI1_HHT_EBS_CONVERT_TABLE';    -- �Q�ƃ^�C�v(�`�[�敪)
-- == 2009/06/15 V1.4 Modified END   ===============================================================
--
    -- *** ���[�J���ϐ� ***
    lv_organization_code mtl_parameters.organization_code%TYPE;  -- �݌ɑg�D�R�[�h
    lv_invoice_type_name fnd_lookup_values.meaning%TYPE ;        -- �`�[�敪
    lv_reverse_kbn_name  fnd_lookup_values.meaning%TYPE;         -- ���o�ɋt�]�f�[�^�o�͋敪
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
    -- �Ɩ����t�擾(���ʊ֐�)
    -- =====================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gd_process_date IS NULL ) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00011
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- �v���t�@�C���l�擾(�݌ɑg�D�R�[�h)
    -- =====================================
    lv_organization_code := FND_PROFILE.VALUE(cv_profile_name);
    IF ( lv_organization_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00005
                     ,iv_token_name1  => cv_token_pro
                     ,iv_token_value1 => cv_profile_name
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
                     ,iv_name         => cv_msg_xxcoi00006
                     ,iv_token_name1  => cv_token_org_code
                     ,iv_token_value1 => lv_organization_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- �������_�擾
    -- =====================================
    gv_base_code := xxcoi_common_pkg.get_base_code(
                        in_user_id     => cn_created_by     -- ���[�U�[ID
                       ,id_target_date => gd_process_date); -- �Ώۓ�
    IF ( gv_base_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10092);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �R���J�����g���̓p�����[�^�o��
    --==============================================================
    -- �p�����[�^.�o�͋敪
    -- �o�͋敪���擾
    gv_output_kbn_name := xxcoi_common_pkg.get_meaning(cv_output_kbn,gr_param.output_kbn);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( gv_output_kbn_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10311
                    ,iv_token_name1  =>  cv_token_output_kbn
                    ,iv_token_value1 =>  gr_param.output_kbn
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �p�����[�^�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10308
                    ,iv_token_name1  =>  cv_token_output_kbn
                    ,iv_token_value1 =>  gv_output_kbn_name
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- �p�����[�^.�`�[�敪
    -- �`�[�敪���擾
    IF ( gr_param.invoice_kbn IS NOT NULL ) THEN
-- == 2009/06/15 V1.4 Modified START ===============================================================
--     lv_invoice_type_name := xxcoi_common_pkg.get_meaning(cv_invoice_type, gr_param.invoice_kbn);
--      --
--      -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
--      IF ( lv_invoice_type_name IS NULL ) THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  =>  cv_app_name
--                      ,iv_name         =>  cv_msg_xxcoi10312
--                      ,iv_token_name1  =>  cv_token_invoice_kbn
--                      ,iv_token_value1 =>  gr_param.invoice_kbn
--                      );
--        lv_errbuf := lv_errmsg;
--        RAISE global_api_expt;
--      END IF;
--
      BEGIN
        SELECT  flv.meaning
        INTO    lv_invoice_type_name
        FROM    fnd_lookup_values     flv
        WHERE   flv.lookup_type   =   cv_invoice_type
        AND     flv.attribute11   =   gr_param.invoice_kbn
        AND     flv.language      =   USERENV('LANG')
        AND     flv.enabled_flag  =   cv_yes
        AND     SYSDATE   BETWEEN   NVL(flv.start_date_active, SYSDATE)
                          AND       NVL(flv.end_date_active, SYSDATE);
        --
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  =>  cv_app_name
                        ,iv_name         =>  cv_msg_xxcoi10312
                        ,iv_token_name1  =>  cv_token_invoice_kbn
                        ,iv_token_value1 =>  gr_param.invoice_kbn
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
-- == 2009/06/15 V1.4 Modified END   ===============================================================
    ELSE
      lv_invoice_type_name := gr_param.invoice_kbn;
    END IF;
--
    -- �p�����[�^�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10310
                    ,iv_token_name1  =>  cv_token_invoice_kbn
                    ,iv_token_value1 =>  lv_invoice_type_name
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- �p�����[�^.�N����
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10067
                    ,iv_token_name1  =>  cv_token_date
                    ,iv_token_value1 =>  SUBSTR(gr_param.target_date,1,10)
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- �p�����[�^.���_
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10307
                    ,iv_token_name1  =>  cv_token_base_code
                    ,iv_token_value1 =>  gr_param.out_base_code
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- �p�����[�^.���o�ɋt�]�f�[�^�o�͋敪
    -- ���o�ɋt�]�f�[�^�o�͋敪���擾
    lv_reverse_kbn_name := xxcoi_common_pkg.get_meaning(cv_reverse_kbn,gr_param.reverse_kbn);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_reverse_kbn_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10313
                    ,iv_token_name1  =>  cv_token_reverse_kbn
                    ,iv_token_value1 =>  gr_param.reverse_kbn
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �p�����[�^�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10309
                    ,iv_token_name1  =>  cv_token_reverse_kbn
                    ,iv_token_value1 =>  lv_reverse_kbn_name
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
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
    iv_output_kbn        IN  VARCHAR2,         --   1.�o�͋敪
    iv_invoice_kbn       IN  VARCHAR2,         --   2.�`�[�敪
    iv_target_date       IN  VARCHAR2,         --   3.�N����
    iv_out_base_code     IN  VARCHAR2,         --   4.���_
    iv_reverse_kbn       IN  VARCHAR2,         --   5.���o�ɋt�]�f�[�^�o�͋敪
    iv_output_dpt        IN  VARCHAR2,         --   6.���[�o�͏ꏊ
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
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    -- �p�����[�^�l�̊i�[
    -- =====================================================
    gr_param.output_kbn        := iv_output_kbn;         -- 01 : �o�͋敪    (�K�{)
    gr_param.invoice_kbn       := iv_invoice_kbn;        -- 02 : �`�[�敪    (�C��)
    gr_param.target_date       := iv_target_date;        -- 03 : �N����      (�K�{)
    gr_param.out_base_code     := iv_out_base_code;      -- 04 : ���_        (�C��)
    gr_param.reverse_kbn       := iv_reverse_kbn;        -- 05 : ���o�ɋt�]�f�[�^�o�͋敪 (�K�{)
    gr_param.output_dpt        := iv_output_dpt;         -- 06 : �o�͏ꏊ    (�K�{)
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
    -- =====================================================
    -- ���_���擾����(A-2)
    -- =====================================================
    get_base_data(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���_��񂪂P���ȏ�擾�o�����ꍇ
    IF ( gn_base_cnt > 0 ) THEN
--
      -- ���_�P�ʃ��[�v�J�n
      <<gt_param_tab_loop>>
      FOR gn_base_loop_cnt IN 1 .. gn_base_cnt LOOP
--
        -- =====================================================
        -- HHT���o�Ƀf�[�^�擾(A-3)
        -- =====================================================
        get_hht_data(
            gn_base_loop_cnt
          , lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          -- �G���[����
          RAISE global_process_expt ;
        END IF;
--
        -- HHT���o�Ƀf�[�^��1���ȏ�擾�ł����ꍇ
        IF ( gn_hht_info_cnt > 0 ) THEN
--
          -- HHT���o�Ƀf�[�^���[�v�J�n
          <<gn_hht_info_cnt_loop>>
          FOR gn_hht_info_loop_cnt IN 1 .. gn_hht_info_cnt LOOP
--
            -- =============================
            -- ���[�N�e�[�u���f�[�^�o�^(A-4)
            -- =============================
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
--
            -- �p�����[�^.�o�̓t���O��"���o��"�̏ꍇ�̂�
            IF ( gr_param.output_kbn = cv_no ) THEN
              -- =============================
              -- �o�̓t���O�X�V(A-5)
              -- =============================
              upd_hht_data(
                  gn_hht_info_loop_cnt => gn_hht_info_loop_cnt -- HHT���o�Ƀf�[�^���[�v�J�E���^
                , ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
                , ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
                , ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
--
          END LOOP gn_hht_info_cnt_loop;
--
        END IF;
--
      END LOOP gt_param_tab_loop;
    END IF;
--
    -- �o�͑Ώی�����0���̏ꍇ�A���[�N�e�[�u���Ƀp�����[�^���݂̂�o�^
    IF (gn_target_cnt = 0) THEN
--
      -- 0�����b�Z�[�W�̎擾
      lv_nodata_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_xxcoi00008
                         );
--
      -- ==============================================
      --  ���[�N�e�[�u���f�[�^�o�^(A-5)
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
    -- SVF�N��(A-5)
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
    -- ���[�N�e�[�u���f�[�^�폜(A-6)
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
    iv_output_kbn        IN  VARCHAR2,      --   1.����^�C�v
    iv_invoice_kbn       IN  VARCHAR2,      --   2.�`�[�敪
    iv_target_date       IN  VARCHAR2,      --   3.�N����
    iv_out_base_code     IN  VARCHAR2,      --   4.�o�ɋ��_
    iv_reverse_kbn       IN  VARCHAR2,      --   5.���o�ɋt�]�f�[�^�o�͋敪
    iv_output_dpt        IN  VARCHAR2)      --   5.���[�o�͏ꏊ
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
       iv_output_kbn        --   1.�o�͋敪
      ,iv_invoice_kbn       --   2.�`�[�敪
      ,iv_target_date       --   3.��
      ,iv_out_base_code     --   4.�o�ɋ��_
      ,iv_reverse_kbn       --   5.���o�ɋt�]�f�[�^�o�͋敪
      ,iv_output_dpt        --   6.���[�o�͏ꏊ
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
END XXCOI009A04R;
/
