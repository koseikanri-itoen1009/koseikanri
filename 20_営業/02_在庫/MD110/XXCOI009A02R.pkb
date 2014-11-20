create or replace
PACKAGE BODY XXCOI009A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A02R(body)
 * Description      : �q�֏o�ɖ��׃��X�g
 * MD.050           : �q�֏o�ɖ��׃��X�g MD050_COI_009_A02
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_work               ���[�N�e�[�u���f�[�^�폜(A-11)
 *  svf_request            SVF�N��(A-10)
 *  ins_work               ���[�N�e�[�u���f�[�^�o�^(A-9)
 *  get_div_cost           �^����Z�o����(A-8)
 *  get_drink_data         �h�����N�U�։^���A�h�I���}�X�^��񒊏o����(A-7)
 *  get_customer_data      �ڋq�}�X�^��񒊏o����(A-6)
 *  get_cs_data            ����(C/S)�Z�o����(A-5)
 *  get_item_data          �i�ڃ}�X�^��񒊏o����(A-4)
 *  get_kuragae_data       �q�֏o�ɖ��׃f�[�^�擾(A-3)
 *  get_base_data          ���_���擾����(A-2)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05    1.0   K.Tsuboi         �V�K�쐬
 *  2009/02/23    1.1   K.Tsuboi         [��QCOI_025] �c�ƌ����z�̕������]�\���Ή�
 *  2009/02/26    1.2   K.Tsuboi         [��QCOI_027] �H��q��,�H��ԕi�̏o�ɋ��_�������w�肷��悤�C��
 *  2009/03/02    1.3   K.Tsuboi         [��QCOI_030] �c�ƌ����z�Ɏ������*�c�ƌ����̒l��ݒ�
 *  2009/04/30    1.4   T.Nakamura       �ŏI�s�Ƀo�b�N�X���b�V����ǉ�
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
  get_value_expt            EXCEPTION;    -- �l�擾�G���[
  lock_expt                 EXCEPTION;    -- ���b�N�擾�G���[
  get_no_data_expt          EXCEPTION;    -- �擾�f�[�^0��
  svf_request_err_expt      EXCEPTION;    -- SVF�N��API�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCOI009A02R';   -- �p�b�P�[�W��
  cv_app_name          CONSTANT VARCHAR2(5)   := 'XXCOI';          -- �A�v���P�[�V�����Z�k��
  cv_0                 CONSTANT VARCHAR2(1)   := '0';              -- �萔
  cv_1                 CONSTANT VARCHAR2(1)   := '1';              -- �萔
  cv_2                 CONSTANT VARCHAR2(1)   := '2';              -- �萔
  cv_3                 CONSTANT VARCHAR2(1)   := '3';              -- �萔
  cv_31                CONSTANT VARCHAR2(2)   := '31';             -- �萔
  cv_dellivary_classe  CONSTANT VARCHAR2(2)   := '41';             -- ��^��
  cn_baracya_type      CONSTANT VARCHAR2(1)   := '1';              -- �o�����敪
  cv_office_item_drink CONSTANT VARCHAR2(1)   := '2';              -- �h�����N
  cv_log               CONSTANT VARCHAR2(3)   := 'LOG';            -- �R���J�����g�w�b�_�o�͐�
--
  -- ���b�Z�[�W
  cv_msg_xxcoi00008  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 0�����b�Z�[�W
  cv_msg_xxcoi10003  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10003';   -- ���t���̓G���[
  cv_msg_xxcoi00005  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';   -- �݌ɑg�D�R�[�h�擾�G���[
  cv_msg_xxcoi00006  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';   -- �݌ɑg�DID�擾�G���[
  cv_msg_xxcoi00011  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011';   -- �Ɩ����t�擾�G���[
  cv_msg_xxcoi00022  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00022';   -- ����^�C�v���擾�G���[
  cv_msg_xxcoi00012  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00012';   -- ����^�C�v�擾�G���[
  cv_msg_xxcoi00030  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00030';   -- �}�X�^�g�D�R�[�h�擾�G���[
  cv_msg_xxcoi00031  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00031';   -- �}�X�^�g�DID�擾�G���[
  cv_msg_xxcoi10069  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10069';   -- ���t�͈�(�N��)�G���[
  cv_msg_xxcoi10070  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10070';   -- ���t�͈�(��)�G���[
  cv_msg_xxcoi10092  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10092';   -- �������_�擾�G���[
  cv_msg_xxcoi10066  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10066';   -- �p�����[�^.����^�C�v���b�Z�[�W
  cv_msg_xxcoi10067  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10067';   -- �p�����[�^.�N�������b�Z�[�W
  cv_msg_xxcoi10068  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10068';   -- �p�����[�^.�o�ɋ��_���b�Z�[�W
  cv_msg_xxcoi10011  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10011';   -- �i�ڃ}�X�^��񖢎擾�G���[
  cv_msg_xxcoi10012  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10012';   -- �i�ڃ}�X�^��񕡐����G���[
  cv_msg_xxcoi10013  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10013';   -- �ڋq�}�X�^��񖢎擾�G���[
  cv_msg_xxcoi10014  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10014';   -- �ڋq�}�X�^��񕡐����G���[
  cv_msg_xxcoi10016  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10016';   -- �ݒ�P�����擾�G���[
  cv_msg_xxcoi10017  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10017';   -- �ݒ�P���������G���[
  cv_msg_xxcoi10292  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10292';   -- �P�[�X�����擾�G���[
  cv_msg_xxcoi10293  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10293';   -- �c�ƌ����擾���s�G���[
--
  -- �g�[�N����
  cv_token_pro                CONSTANT VARCHAR2(30) := 'PRO_TOK';
  cv_token_org_code           CONSTANT VARCHAR2(30) := 'ORG_CODE_TOK';
  cv_token_mst_org_code       CONSTANT VARCHAR2(30) := 'MST_ORG_CODE_TOK';
  cv_token_transaction_type   CONSTANT VARCHAR2(30) := 'P_TRAN_TYPE';
  cv_token_date               CONSTANT VARCHAR2(30) := 'P_DATE';
  cv_token_base_code          CONSTANT VARCHAR2(30) := 'P_BASE_CODE';
  cv_token_lookup_type        CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';            -- �Q�ƃ^�C�v
  cv_token_lookup_code        CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';            -- �Q�ƃR�[�h
  cv_token_tran_type          CONSTANT VARCHAR2(20) := 'TRANSACTION_TYPE_TOK';   -- ����^�C�v
  cv_token_item_code          CONSTANT VARCHAR2(20) := 'ITEM_CODE';              -- �i�ڃR�[�h
  cv_token_product_class      CONSTANT VARCHAR2(20) := 'PRODUCT_CLASS';          -- ���_����
  cv_token_location_code      CONSTANT VARCHAR2(20) := 'LOCATION_CODE';          -- ���_�R�[�h
  cv_token_base_major         CONSTANT VARCHAR2(20) := 'BASE_MAJOR_DIVISION';    -- ���_�啪��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE gr_param_rec  IS RECORD(
      transaction_type  VARCHAR2(3)       -- 01 : ����^�C�v    (�C��)
     ,year_month        VARCHAR2(7)       -- 01 : �����N��      (�K�{)
     ,a_day             VARCHAR2(2)       -- 02 : ������        (�C��)
     ,out_kyoten        VARCHAR2(4)       -- 03 : �o�ɋ��_      (�C��)
     ,output_dpt        VARCHAR2(1)       -- 04 : ���[�o�͏ꏊ  (�K�{)
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date           DATE;                                             -- �Ɩ����t
  gv_base_code              hz_cust_accounts.account_number%TYPE;             -- ���_�R�[�h
  -- �J�E���^
  gn_base_cnt               NUMBER;                                           -- ���_�R�[�h����
  gn_base_loop_cnt          NUMBER;                                           -- ���_�R�[�h���[�v�J�E���^
  gn_kuragae_cnt            NUMBER;                                           -- �q�֏o�ɏ�񌏐�
  gn_kuragae_loop_cnt       NUMBER;                                           -- �q�֏o�ɏ�񃋁[�v�J�E���^
  gn_organization_id        mtl_parameters.organization_id%TYPE;              -- �݌ɑg�DID
  gn_mst_organization_id    mtl_parameters.organization_id%TYPE;              -- �}�X�^�g�DID
  gv_item_div_h             VARCHAR2(20);                                     -- �{�Џ��i�敪��
  gv_transaction_type_name  mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v��
  -- 
  gr_param                  gr_param_rec;
  gt_base_num_tab           gt_base_num_ttype;
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-11)
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
    --���[�p���[�N�e�[�u������폜
    DELETE xxcoi_rep_kuragae_ship_list xrk
    WHERE  xrk.request_id = cn_request_id
    ;
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
    cv_output_mode  CONSTANT VARCHAR2(1)  := '1';                    -- �o�͋敪(PDF�o��)
    cv_frm_file     CONSTANT VARCHAR2(30) := 'XXCOI009A02S.xml';     -- �t�H�[���l���t�@�C����
    cv_vrq_file     CONSTANT VARCHAR2(30) := 'XXCOI009A02S.vrq';     -- �N�G���[�l���t�@�C����
    cv_api_name     CONSTANT VARCHAR2(7)  := 'SVF�N��';              -- SVF�N��API��
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
     ,iv_file_name    => cv_frm_file            -- �o�̓t�@�C����
     ,iv_file_id      => cv_pkg_name            -- ���[ID
     ,iv_output_mode  => cv_output_mode         -- �o�͋敪
     ,iv_frm_file     => cv_frm_file            -- �t�H�[���l���t�@�C����
     ,iv_vrq_file     => cv_vrq_file            -- �N�G���[�l���t�@�C����
     ,iv_org_id       => fnd_global.org_id      -- ORG_ID
     ,iv_user_name    => cn_created_by          -- ���O�C���E���[�U��
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
   * Procedure Name   : ins_work
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-9)
   ***********************************************************************************/
  PROCEDURE ins_work(
    it_out_base_code           IN hz_cust_accounts.account_number%TYPE,                -- �o�ɋ��_
    it_out_base_name           IN hz_cust_accounts.account_name%TYPE,                  -- �o�ɋ��_��
    it_transaction_type_id     IN mtl_material_transactions.transaction_id%TYPE,       -- ����^�C�vID
    it_transaction_type_name   IN mtl_transaction_types.transaction_type_name%TYPE,    -- ����^�C�v��
    it_transaction_type_id_sub IN mtl_material_transactions.transaction_id%TYPE,       -- ����^�C�v�T�uID
    it_in_base_code            IN hz_cust_accounts.account_number%TYPE,                -- ���ɋ��_
    it_in_base_name            IN hz_cust_accounts.account_name%TYPE,                  -- ���ɋ��_��
    it_transaction_date        IN mtl_material_transactions.transaction_date%TYPE,     -- �����
    it_item_code               IN mtl_system_items_b.segment1%TYPE,                    -- ���i
    it_item_name               IN xxcmn_item_mst_b.item_short_name%TYPE,               -- ���i��
    it_slip_no                 IN mtl_material_transactions.attribute1%TYPE,           -- �`�[No                  
    it_transaction_qty         IN mtl_material_transactions.transaction_quantity%TYPE, -- �������
    iv_trading_cost            IN NUMBER,                  -- �c�ƌ����z
    iv_dlv_cost                IN NUMBER,                  -- �U�։^����
    iv_nodata_msg              IN VARCHAR2,               -- �O�����b�Z�[�W
    ov_errbuf                  OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --�H����ɖ��׃��X�g���[���[�N�e�[�u���o�^����
    INSERT INTO xxcoi_rep_kuragae_ship_list(
       target_term
      ,ship_base_code
      ,ship_base_name
      ,transaction_type_id
      ,transaction_type_name
      ,transaction_type_id_sub
      ,store_base_code
      ,store_base_name
      ,transaction_date
      ,item_code
      ,item_name
      ,slip_no
      ,transaction_qty
      ,trading_cost
      ,dlv_cost
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
       gr_param.year_month||gr_param.a_day          -- �Ώ۔N����
      ,it_out_base_code                             -- �o�ɋ��_
      ,it_out_base_name                             -- �o�ɋ��_��
      ,it_transaction_type_id                       -- ����^�C�vID
      ,it_transaction_type_name                     -- ����^�C�v��
      ,it_transaction_type_id_sub                   -- ����^�C�v�T�uID
      ,it_in_base_code                              -- ���ɋ��_
      ,it_in_base_name                              -- ���ɋ��_��
      ,TO_CHAR(it_transaction_date,'YYYYMMDD')      -- �����
      ,it_item_code                                 -- ���i
      ,it_item_name                                 -- ���i��
      ,it_slip_no                                   -- �`�[No
      ,it_transaction_qty                           -- �������
      ,iv_trading_cost                              -- �c�ƌ����z
      ,iv_dlv_cost                                  -- �U�։^����
      ,iv_nodata_msg                                -- �O�����b�Z�[�W
      --WHO�J����
      ,cn_created_by
      ,sysdate
      ,cn_last_updated_by
      ,sysdate
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,sysdate
     );
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
   * Procedure Name   : get_div_cost
   * Description      : �^����\�Z���z�Z�o����(A-8)
   ***********************************************************************************/
  PROCEDURE get_div_cost(
     in_cs_qty               IN  NUMBER                                            -- ���ʁiCS�j
    ,it_set_unit_price       IN  xxwip_drink_trans_deli_chrgs.setting_amount%TYPE  -- �ݒ�P��
    ,on_dlv_cost_budget_amt  OUT NUMBER                                            -- �^����\�Z���z
    ,ov_errbuf               OUT VARCHAR2                                          -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2                                          -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_div_cost'; -- �v���O������
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
    -- �^����\�Z���z�Z�o
    on_dlv_cost_budget_amt := in_cs_qty * it_set_unit_price;
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
  END get_div_cost;
--
  /**********************************************************************************
   * Procedure Name   : get_drink_data
   * Description      : �h�����N�U�։^���A�h�I���}�X�^��񒊏o����(A-7)
   ***********************************************************************************/
  PROCEDURE get_drink_data(
     it_transaction_date     IN  mtl_material_transactions.transaction_date%TYPE    -- �����
    ,it_base_code            IN  hz_cust_accounts.account_number%TYPE               -- ���_�R�[�h
    ,it_product_class        IN  xxcmn_item_mst_b.product_class%TYPE                -- ���i����
    ,it_base_major_division  IN  xxcmn_parties.base_major_division%TYPE             -- ���_�啪��
    ,ot_set_unit_price       OUT xxwip_drink_trans_deli_chrgs.setting_amount%TYPE   -- �ݒ�P��
    ,ov_errbuf               OUT VARCHAR2                                           -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2                                           -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2                                           -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_mst_info'; -- �v���O������
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
    -- �h�����N�U�։^���A�h�I���}�X�^���擾
    SELECT xdtd.setting_amount  setting_amount    -- �ݒ�P��
    INTO   ot_set_unit_price
    FROM   xxwip_drink_trans_deli_chrgs xdtd
    WHERE  xdtd.godds_classification   = TO_CHAR( it_product_class )
    AND    xdtd.foothold_macrotaxonomy = it_base_major_division
    AND    xdtd.dellivary_classe       = cv_dellivary_classe
    AND    it_transaction_date BETWEEN xdtd.start_date_active AND NVL( xdtd.end_date_active, SYSDATE )
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** �h�����N�U�։^���A�h�I���}�X�^���擾��O�n���h�� ****
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_xxcoi10016
                      ,iv_token_name1  => cv_token_product_class
                      ,iv_token_value1 => TO_CHAR( it_product_class )
                      ,iv_token_name2  => cv_token_base_major
                      ,iv_token_value2 => it_base_major_division
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    WHEN TOO_MANY_ROWS THEN
      -- *** �h�����N�U�։^���A�h�I���}�X�^��񕡐�����O�n���h�� ****
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_xxcoi10017
                      ,iv_token_name1  => cv_token_product_class
                      ,iv_token_value1 => TO_CHAR( it_product_class )
                      ,iv_token_name2  => cv_token_base_major
                      ,iv_token_value2 => it_base_major_division
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_drink_data;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_mst_info
   * Description      : �ڋq�}�X�^��񒊏o����(A-6)
   ***********************************************************************************/
  PROCEDURE get_cust_mst_info(
     it_base_code            IN  hz_cust_accounts.account_number%TYPE      -- ���_�R�[�h
    ,ot_base_major_division  OUT xxcmn_parties.base_major_division%TYPE    -- ���_�啪��
    ,ov_errbuf               OUT VARCHAR2                                  -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2                                  -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_mst_info'; -- �v���O������
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
    lv_base_major_division    xxcmn_parties.base_major_division%TYPE;
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
    -- �ڋq�}�X�^���擾
    SELECT xp.base_major_division  base_major_division   -- ���_�啪��
    INTO   ot_base_major_division
    FROM   hz_parties        hp       -- �p�[�e�B�}�X�^
          ,xxcmn_parties     xp       -- �p�[�e�B�A�h�I���}�X�^
          ,hz_cust_accounts  hca      -- �ڋq�}�X�^
    WHERE xp.party_id             = hp.party_id
    AND   hp.party_id             = hca.party_id
    AND   hca.account_number      = it_base_code
    AND   hca.customer_class_code = cv_1
    AND   ROWNUM                  = 1
    ;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN NO_DATA_FOUND THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_xxcoi10014
                      ,iv_token_name1  => cv_token_location_code
                      ,iv_token_value1 => it_base_code
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_cust_mst_info;
--
  /**********************************************************************************
   * Procedure Name   : get_cs_data
   * Description      : ����(C/S)�Z�o����(A-5)
   ***********************************************************************************/
  PROCEDURE get_cs_data(
     it_transaction_qty        IN  mtl_material_transactions.transaction_quantity%TYPE  -- ����
    ,it_godds_classification   IN  ic_item_mst_b.attribute11%TYPE                       -- �P�[�X����
    ,on_cs_qty                 OUT NUMBER                                               -- ���ʁiCS�j
    ,ov_errbuf                 OUT VARCHAR2                                             -- �G���[�E���b�Z�[�W
    ,ov_retcode                OUT VARCHAR2                                             -- ���^�[���E�R�[�h
    ,ov_errmsg                 OUT VARCHAR2                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cs_data'; -- �v���O������
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

    -- ���ʁiCS�j�Z�o
    on_cs_qty := ROUND( it_transaction_qty / TO_NUMBER( it_godds_classification ) );
--
  EXCEPTION
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_cs_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item_data
   * Description      : �i�ڃ}�X�^��񒊏o����(A-4)
   ***********************************************************************************/
  PROCEDURE get_item_data(
     it_item_no                IN  mtl_system_items_b.segment1%TYPE        -- ���i�R�[�h
    ,ot_product_class          OUT xxcmn_item_mst_b.product_class%TYPE     -- ���i����
    ,ot_godds_classification   OUT ic_item_mst_b.attribute11%TYPE          -- �P�[�X����
    ,ot_baracha_div            OUT xxcmm_system_items_b.baracha_div%TYPE   -- �o�����敪
    ,ot_office_item_type       OUT mtl_categories_b.segment1%TYPE          -- �{�Џ��i�敪
    ,ov_errbuf                 OUT VARCHAR2                                -- �G���[�E���b�Z�[�W
    ,ov_retcode                OUT VARCHAR2                                -- ���^�[���E�R�[�h
    ,ov_errmsg                 OUT VARCHAR2                                -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_data'; -- �v���O������
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
    -- ===============================
    -- �i�ڃ}�X�^���擾
    -- ===============================
    -- 
    SELECT ximb.product_class   AS product_class         -- ���i����
          ,iimb.attribute11     AS godds_classification  -- �P�[�X����
          ,xsib.baracha_div     AS baracha_div           -- �o�����敪
          ,mcb.segment1         AS item_div_h            -- �{�Џ��i�敪
    INTO   ot_product_class
          ,ot_godds_classification
          ,ot_baracha_div
          ,ot_office_item_type
    FROM   mtl_system_items_b      msib     -- �i�ڃ}�X�^
          ,ic_item_mst_b           iimb     -- OPM�i�ڃ}�X�^
          ,mtl_category_sets_b     mcsb     -- �i�ڃJ�e�S���Z�b�g
          ,mtl_category_sets_tl    mcst     -- �i�ڃJ�e�S���Z�b�g���{��
          ,mtl_categories_b        mcb      -- �i�ڃJ�e�S���}�X�^
          ,mtl_item_categories     mic      -- �i�ڃJ�e�S������
          ,xxcmm_system_items_b    xsib     -- �i�ڃA�h�I���}�X�^
          ,xxcmn_item_mst_b        ximb     -- OPM�i�ڃA�h�I���}�X�^
    WHERE  msib.segment1                = iimb.item_no
    AND    iimb.item_id                 = ximb.item_id
    AND    msib.segment1                = xsib.item_code
    AND    msib.inventory_item_id       = mic.inventory_item_id
    AND    msib.organization_id         = mic.organization_id
    AND    mic.category_id              = mcb.category_id
    AND    mcb.structure_id             = mcsb.structure_id
    AND    mic.category_set_id          = mcsb.category_set_id
    AND    mcst.category_set_id         = mcsb.category_set_id
    AND    msib.segment1                = it_item_no
    AND    mcst.language                = USERENV( 'LANG' )
    AND    mcst.category_set_name       = gv_item_div_h
    AND    msib.organization_id         = gn_organization_id
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** �i�ڃ}�X�^���擾��O�n���h�� ****
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_xxcoi10012
                      ,iv_token_name1  => cv_token_item_code
                      ,iv_token_value1 => it_item_no
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_item_data;
--
  /**********************************************************************************
   * Procedure Name   : get_kuragae_data�i���[�v���j
   * Description      : �q�֏o�ɖ��׃f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_kuragae_data(
    gn_base_loop_cnt IN NUMBER,       --   �J�E���g
    ov_errbuf        OUT VARCHAR2,    --   �G���[�E���b�Z�[�W                --# �Œ� #
    ov_retcode       OUT VARCHAR2,    --   ���^�[���E�R�[�h                  --# �Œ� #
    ov_errmsg        OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_kuragae_data'; -- �v���O������
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
    cn_ido_order                   CONSTANT NUMBER   := 64;                           -- ����^�C�v �ړ��I�[�_�[�ړ�
    cv_flag                        CONSTANT VARCHAR2(1)  := 'Y';                      -- �g�p�\�t���O 'Y'
--
    -- �Q�ƃ^�C�v
    -- ���[�U�[��`����^�C�v����
    cv_tran_type                   CONSTANT VARCHAR2(30)  := 'XXCOI1_TRANSACTION_TYPE_NAME';
    -- �H��ԕi�q�֐�R�[�h
    cv_mfg_fctory_cd              CONSTANT VARCHAR2(30) := 'XXCOI_MFG_FCTORY_CD'; 
--
    -- �Q�ƃR�[�h
    cv_tran_type_kuragae           CONSTANT VARCHAR2(2)   := '20';   -- ����^�C�v�R�[�h �q��
    cv_tran_type_kojo_henpin       CONSTANT VARCHAR2(2)   := '90';   -- ����^�C�v�R�[�h �H��ԕi
    cv_tran_type_kojo_henpin_b     CONSTANT VARCHAR2(3)   := '100';  -- ����^�C�v�R�[�h �H��ԕi�U��
    cv_tran_type_kojo_kuragae      CONSTANT VARCHAR2(3)   := '110';  -- ����^�C�v�R�[�h �H��q��
    cv_tran_type_kojo_kuragae_b    CONSTANT VARCHAR2(3)   := '120';  -- ����^�C�v�R�[�h �H��q�֐U��
    cv_tran_type_haikyaku          CONSTANT VARCHAR2(3)   := '130';  -- ����^�C�v�R�[�h �p�p
    cv_tran_type_haikyaku_b        CONSTANT VARCHAR2(3)   := '140';  -- ����^�C�v�R�[�h �p�p�U��
--   
    -- *** ���[�J���ϐ� ***
    lv_tran_type_kuragae           mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� �q��
    ln_tran_type_kuragae           mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID �q��
    lv_tran_type_kojo_henpin       mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� �H��ԕi
    ln_tran_type_kojo_henpin       mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID �H��ԕi
    lv_tran_type_kojo_henpin_b     mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� �H��ԕi�U��
    ln_tran_type_kojo_henpin_b     mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID �H��ԕi�U��
    lv_tran_type_kojo_kuragae      mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� �H��q��
    ln_tran_type_kojo_kuragae      mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID �H��q��
    lv_tran_type_kojo_kuragae_b    mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� �H��q�֐U��
    ln_tran_type_kojo_kuragae_b    mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID �H��q�֐U��
    lv_tran_type_haikyaku          mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� �p�p
    ln_tran_type_haikyaku          mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID �p�p
    lv_tran_type_haikyaku_b        mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� �p�p�U��
    ln_tran_type_haikyaku_b        mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID �p�p�U��
    lv_product_class               xxcmn_item_mst_b.product_class%TYPE;                -- ���i����                      
    lv_godds_classification        ic_item_mst_b.attribute11%TYPE;                     -- �P�[�X����
    lv_baracha_div                 xxcmm_system_items_b.baracha_div%TYPE;              -- �o�����敪
    lv_office_item_type            mtl_categories_b.segment1%TYPE;                     -- �{�Џ��i�敪
    lv_base_major_division         xxcmn_parties.base_major_division%TYPE;             -- ���_�啪��
    ln_cs_qty                      NUMBER;   
    ln_set_unit_price              xxwip_drink_trans_deli_chrgs.setting_amount%TYPE;   -- �ݒ�P��
    ln_dlv_cost_budget_amt         NUMBER;                                             -- �^����
    lv_discrete_cost               xxcmm_system_items_b_hst.discrete_cost%TYPE;        -- �c�ƌ���                     
    ln_discrete_cost               NUMBER;                                             -- �c�ƌ���(�^�ϊ�) 
    ln_cnt                         NUMBER       DEFAULT  0;          -- ���[�v�J�E���^
    lv_zero_message                VARCHAR2(30) DEFAULT  NULL;       -- �[�������b�Z�[�W
    ln_sql_cnt                     NUMBER       DEFAULT  0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �q�֏o�ɖ��׏��
    CURSOR info_kuragae_cur(ln_kojo_henpin            NUMBER
                           ,ln_kojo_henpin_b          NUMBER 
                           ,ln_kojo_kuragae           NUMBER
                           ,ln_kojo_kuragae_b         NUMBER
                           ,ln_haikyaku               NUMBER
                           ,ln_haikyaku_b             NUMBER
                           ,ln_kuragae                NUMBER
                           ,cn_ido_order              NUMBER
                           ,lv_tran_type_kojo_henpin  VARCHAR2
                           ,lv_tran_type_kojo_kuragae VARCHAR2
                           ,lv_tran_type_haikyaku     VARCHAR2)
    IS
      -- �q�ցE�ړ��I�[�_�[
      SELECT  mmt.transaction_id
             ,mmt.transaction_type_id        transaction_type_id        -- ����^�C�vID
             ,mmt.transaction_type_id        transaction_type_id_sub    -- ����^�C�vID�T�u
             ,mtt.transaction_type_name      transaction_type_name      -- ����^�C�v��
             ,msi1.attribute7                out_base_code              -- �o�ɋ��_ 
             ,SUBSTRB(hca1.account_name,1,8) out_base_name              -- �o�ɋ��_��
             ,msi2.attribute7                in_base_code               -- ���ɋ��_ 
             ,SUBSTRB(hca2.account_name,1,8) in_base_name               -- ���ɋ��_��
             ,mmt.transaction_date           transaction_date           -- �����
             ,mmt.attribute1                 slip_no                    -- �`�[No
             ,mmt.inventory_item_id          inventory_item_id          -- �i��ID
             ,msib.segment1                  item_no                    -- �i�ڃR�[�h
             ,ximb.item_short_name           item_short_name            -- ����
             ,mmt.transaction_quantity       transaction_qty            -- �������
      FROM    mtl_material_transactions mmt                             -- ���ގ��
             ,mtl_transaction_types      mtt                            -- ����^�C�v�}�X�^
             ,mtl_secondary_inventories  msi1                            -- �ۊǏꏊ�}�X�^1
             ,mtl_secondary_inventories  msi2                            -- �ۊǏꏊ�}�X�^2
             ,hz_cust_accounts           hca1                           -- �ڋq�}�X�^�P
             ,hz_cust_accounts           hca2                           -- �ڋq�}�X�^�Q
             ,mtl_system_items_b         msib                           -- �i�ڃ}�X�^
             ,ic_item_mst_b              iimb                           -- OPM�i�ڃ}�X�^  
             ,xxcmn_item_mst_b           ximb                           -- OPM�i�ڃA�h�I���}�X�^
      WHERE   mmt.transaction_type_id            =  mtt.transaction_type_id
        AND  ( ( ( gr_param.transaction_type = ln_kuragae ) AND
               ( mmt.transaction_type_id  = ln_kuragae ) )
          OR ( ( gr_param.transaction_type = cn_ido_order ) AND
               ( mmt.transaction_type_id  = cn_ido_order ) )
          OR ( ( gr_param.transaction_type IS NULL ) AND
               ( mmt.transaction_type_id  = ln_kuragae) ) )
        AND  ( ( ( gr_param.a_day IS NULL ) AND 
               ( TO_CHAR ( mmt.transaction_date, 'YYYYMM' ) = gr_param.year_month ) )
          OR ( ( gr_param.a_day IS NOT NULL ) AND 
               ( TO_CHAR ( mmt.transaction_date, 'YYYYMMDD' ) = gr_param.year_month||gr_param.a_day ) ) )
        AND  mmt.subinventory_code               =  msi1.secondary_inventory_name
        AND  mmt.transfer_subinventory           =  msi2.secondary_inventory_name
        AND  msi1.attribute7                     =  gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
        AND  hca1.account_number                 =  msi1.attribute7
        AND  hca1.customer_class_code            =  cv_1
        AND  hca2.account_number                 =  msi2.attribute7
        AND  hca2.customer_class_code            =  cv_1
        AND  msib.inventory_item_id              =  mmt.inventory_item_id
        AND  msib.organization_id                =  gn_organization_id
        AND  msib.segment1                       =  iimb.item_no
        AND  iimb.item_id                        =  ximb.item_id
      UNION
      --�p�p
      SELECT  mmt.transaction_id
             ,DECODE(mmt.transaction_type_id,ln_haikyaku_b,ln_haikyaku
                     ,mmt.transaction_type_id ) transaction_type_id      -- ����^�C�vID
             ,mmt.transaction_type_id         transaction_type_id_sub    -- ����^�C�vID�T�u
             ,DECODE(mmt.transaction_type_id,ln_haikyaku
                    ,mtt.transaction_type_name,lv_tran_type_haikyaku)
                     transaction_type_name                               -- ����^�C�v��
             ,msi.attribute7                  out_base_code              -- �o�ɋ��_ 
             ,SUBSTRB(hca.account_name,1,8)   out_base_name              -- �o�ɋ��_��
             ,NULL                            in_base_code               -- ���ɋ��_ 
             ,NULL                            in_base_name               -- ���ɋ��_��
             ,mmt.transaction_date            transaction_date           -- �����
             ,mmt.attribute1                 slip_no                     -- �`�[No
             ,mmt.inventory_item_id           inventory_item_id          -- �i��ID
             ,msib.segment1                   item_no                    -- �i�ڃR�[�h
             ,ximb.item_short_name            item_short_name            -- ����
             ,mmt.transaction_quantity        transaction_qty            -- �������
      FROM    mtl_material_transactions  mmt                            -- ���ގ��
             ,mtl_transaction_types      mtt                            -- ����^�C�v�}�X�^
             ,mtl_secondary_inventories  msi                            -- �ۊǏꏊ�}�X�^
             ,hz_cust_accounts           hca                            -- �ڋq�}�X�^�P
             ,mtl_system_items_b         msib                           -- �i�ڃ}�X�^
             ,ic_item_mst_b              iimb                           -- OPM�i�ڃ}�X�^  
             ,xxcmn_item_mst_b           ximb                           -- OPM�i�ڃA�h�I���}�X�^
      WHERE  mmt.transaction_type_id             =  mtt.transaction_type_id
        AND  ( ( ( gr_param.transaction_type = ln_haikyaku ) AND 
               ( mmt.transaction_type_id IN (ln_haikyaku,ln_haikyaku_b) ) )
          OR ( ( gr_param.transaction_type IS NULL ) AND
               ( mmt.transaction_type_id IN (ln_haikyaku,ln_haikyaku_b) ) ) )
        AND  ( ( ( gr_param.a_day IS NULL ) AND 
               ( TO_CHAR ( mmt.transaction_date, 'YYYYMM' ) = gr_param.year_month ) )
          OR ( ( gr_param.a_day IS NOT NULL ) AND 
               ( TO_CHAR ( mmt.transaction_date, 'YYYYMMDD' ) = gr_param.year_month||gr_param.a_day ) ) )
        AND  mmt.subinventory_code               =  msi.secondary_inventory_name
        AND  msi.attribute7                      =  gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
        AND  hca.account_number                  =  msi.attribute7
        AND  hca.customer_class_code             =  cv_1
        AND  msib.inventory_item_id              =  mmt.inventory_item_id
        AND  msib.organization_id                =  gn_organization_id
        AND  msib.segment1                       =  iimb.item_no
        AND  iimb.item_id                        =  ximb.item_id
      UNION
      --�H��q��,�H��ԕi
      SELECT  mmt.transaction_id
             ,DECODE(mmt.transaction_type_id,ln_kojo_henpin_b,ln_kojo_henpin,
                     ln_kojo_kuragae_b,ln_kojo_kuragae,
                     mmt.transaction_type_id) transaction_type_id       -- ����^�C�vID
             ,mmt.transaction_type_id        transaction_type_id_sub    -- ����^�C�vID�T�u
             ,DECODE(mmt.transaction_type_id,
                     ln_kojo_henpin,transaction_type_name,
                     ln_kojo_henpin_b,lv_tran_type_kojo_henpin,
                     ln_kojo_kuragae,transaction_type_name,
                     ln_kojo_kuragae_b,lv_tran_type_kojo_kuragae)
                     transaction_type_name                              -- ����^�C�v��
             ,msi.attribute7                 out_base_code              -- �o�ɋ��_ 
             ,SUBSTRB(hca.account_name,1,8)  out_base_name              -- �o�ɋ��_��
             ,mmt.attribute2                 in_base_code               -- ���ɋ��_(�H��) 
             ,SUBSTRB(flv.description,1,8)   in_base_name               -- ���ɋ��_��
             ,mmt.transaction_date           transaction_date           -- �����
             ,mmt.attribute1                 slip_no                    -- �`�[No
             ,mmt.inventory_item_id          inventory_item_id          -- �i��ID
             ,msib.segment1                  item_no                    -- �i�ڃR�[�h
             ,ximb.item_short_name           item_short_name            -- ����
             ,mmt.transaction_quantity       transaction_qty            -- �������
      FROM    mtl_material_transactions  mmt                            -- ���ގ��
             ,mtl_transaction_types      mtt                            -- ����^�C�v�}�X�^
             ,mtl_secondary_inventories  msi                            -- �ۊǏꏊ�}�X�^
             ,fnd_lookup_values          flv                            -- �N�C�b�N�R�[�h�}�X�^
             ,hz_cust_accounts           hca                            -- �ڋq�}�X�^
             ,mtl_system_items_b         msib                           -- �i�ڃ}�X�^
             ,ic_item_mst_b              iimb                           -- OPM�i�ڃ}�X�^  
             ,xxcmn_item_mst_b           ximb                           -- OPM�i�ڃA�h�I���}�X�^
      WHERE  mmt.transaction_type_id             =  mtt.transaction_type_id
        AND  ( ( ( gr_param.transaction_type = ln_kojo_henpin ) AND 
               ( mmt.transaction_type_id IN (ln_kojo_henpin,ln_kojo_henpin_b) ) )
          OR ( ( gr_param.transaction_type = ln_kojo_kuragae ) AND 
               ( mmt.transaction_type_id IN (ln_kojo_kuragae,ln_kojo_kuragae_b) ) )
          OR ( ( gr_param.transaction_type IS NULL ) AND
               ( mmt.transaction_type_id IN (ln_kojo_henpin,ln_kojo_henpin_b,ln_kojo_kuragae,ln_kojo_kuragae_b) ) ) )
        AND  ( ( ( gr_param.a_day IS NULL ) AND 
               ( TO_CHAR ( mmt.transaction_date, 'YYYYMM' ) = gr_param.year_month ) )
          OR ( ( gr_param.a_day IS NOT NULL ) AND 
               ( TO_CHAR ( mmt.transaction_date, 'YYYYMMDD' ) = gr_param.year_month||gr_param.a_day ) ) )
        AND  mmt.subinventory_code               =  msi.secondary_inventory_name
        AND  msi.attribute7                      =  gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
        AND  hca.account_number                  =  msi.attribute7
        AND  hca.customer_class_code             =  cv_1
        AND  flv.lookup_type                     =  cv_mfg_fctory_cd
        AND  flv.lookup_code                     =  mmt.attribute2
        AND  flv.enabled_flag                    =  cv_flag
        AND  flv.language                        =  USERENV( 'LANG' )   
        AND  msib.inventory_item_id              =  mmt.inventory_item_id
        AND  msib.organization_id                =  gn_organization_id
        AND  msib.segment1                       =  iimb.item_no
        AND  iimb.item_id                        =  ximb.item_id
        ORDER BY out_base_code
                ,in_base_code
                ,transaction_date
                ,slip_no
                ,inventory_item_id
                ,transaction_type_id
      ;    
--
    -- ���[�J���E���R�[�h
    lr_info_kuragae_rec info_kuragae_cur%ROWTYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- ����^�C�v���擾�F�q��
    -- ===============================
    lv_tran_type_kuragae := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_kuragae);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_tran_type_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�F�q��
    -- ===============================
    ln_tran_type_kuragae := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_kuragae);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( ln_tran_type_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�F�H��ԕi
    -- ===============================
    lv_tran_type_kojo_henpin := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_kojo_henpin);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_tran_type_kojo_henpin IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_kojo_henpin
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�F�H��ԕi
    -- ===============================
    ln_tran_type_kojo_henpin := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_kojo_henpin);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( ln_tran_type_kojo_henpin IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_kojo_henpin
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�F�H��ԕi�U��
    -- ===============================
    lv_tran_type_kojo_henpin_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_kojo_henpin_b);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_tran_type_kojo_henpin_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_kojo_henpin_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�F�H��ԕi�U��
    -- ===============================
    ln_tran_type_kojo_henpin_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_kojo_henpin_b);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( ln_tran_type_kojo_henpin_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_kojo_henpin_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�F�H��q��
    -- ===============================
    lv_tran_type_kojo_kuragae := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_kojo_kuragae);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_tran_type_kojo_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_kojo_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�F�H��q��
    -- ===============================
    ln_tran_type_kojo_kuragae := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_kojo_kuragae);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( ln_tran_type_kojo_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_kojo_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�F�H��q�֐U��
    -- ===============================
    lv_tran_type_kojo_kuragae_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_kojo_kuragae_b);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_tran_type_kojo_kuragae_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_kojo_kuragae_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�F�H��q�֐U��
    -- ===============================
    ln_tran_type_kojo_kuragae_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_kojo_kuragae_b);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( ln_tran_type_kojo_kuragae_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_kojo_kuragae_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�F�p�p
    -- ===============================
    lv_tran_type_haikyaku := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_haikyaku);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_tran_type_haikyaku IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_haikyaku
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�F�p�p
    -- ===============================
    ln_tran_type_haikyaku := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_haikyaku);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( ln_tran_type_haikyaku IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_haikyaku
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�F�p�p�U��
    -- ===============================
    lv_tran_type_haikyaku_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_haikyaku_b);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_tran_type_haikyaku_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_haikyaku_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�F�p�p�U��
    -- ===============================
    ln_tran_type_haikyaku_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_haikyaku_b);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( ln_tran_type_haikyaku_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_haikyaku_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �q�֏o�ɏ�񌏐�������
    gn_kuragae_cnt := 0;
--
    -- �J�[�\���I�[�v��
    OPEN  info_kuragae_cur(ln_tran_type_kojo_henpin
                          ,ln_tran_type_kojo_henpin_b
                          ,ln_tran_type_kojo_kuragae
                          ,ln_tran_type_kojo_kuragae_b
                          ,ln_tran_type_haikyaku
                          ,ln_tran_type_haikyaku_b
                          ,ln_tran_type_kuragae
                          ,cn_ido_order
                          ,lv_tran_type_kojo_henpin
                          ,lv_tran_type_kojo_kuragae
                          ,lv_tran_type_haikyaku);
    --
    <<ins_work_loop>>
    LOOP
    FETCH info_kuragae_cur INTO lr_info_kuragae_rec;
    EXIT WHEN info_kuragae_cur%NOTFOUND;
--
    -- �Ώی����J�E���g
    gn_target_cnt :=  gn_target_cnt + 1;
    -- �^�������
    ln_dlv_cost_budget_amt := 0;
    -- �c�ƌ���������
    ln_discrete_cost := 0;
--
      -- ==============================================
      --  �c�ƌ����擾
      -- ==============================================
      xxcoi_common_pkg.get_discrete_cost(in_item_id       => lr_info_kuragae_rec.inventory_item_id   -- �i��ID
                                        ,in_org_id        => gn_mst_organization_id                  -- �݌ɑg�DID
                                        ,id_target_date   => lr_info_kuragae_rec.transaction_date    -- �����
                                        ,ov_discrete_cost => lv_discrete_cost                        -- �c�ƌ���
                                        ,ov_retcode       => lv_retcode                              -- ���^�[���R�[�h
                                        ,ov_errbuf        => lv_errbuf                               -- �G���[���b�Z�[�W
                                        ,ov_errmsg        => lv_errmsg);                             -- �G���[���b�Z�[�W

      IF (lv_retcode <> cv_status_normal) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10293
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- �c�ƌ����z�̕����ϊ�
      ln_discrete_cost := TO_NUMBER(lv_discrete_cost)*lr_info_kuragae_rec.transaction_qty;
--
      -- =====================================================
      -- �i�ڃ}�X�^��񒊏o����(A-4)
      -- =====================================================
      get_item_data(
         it_item_no                 =>  lr_info_kuragae_rec.item_no -- ���i�R�[�h
        ,ot_product_class           =>  lv_product_class            -- ���i����
        ,ot_godds_classification    =>  lv_godds_classification     -- �P�[�X����
        ,ot_baracha_div             =>  lv_baracha_div              -- �o�����敪
        ,ot_office_item_type        =>  lv_office_item_type         -- �{�Џ��i�敪
        ,ov_errbuf                  =>  lv_errbuf                   -- �G���[�E���b�Z�[�W
        ,ov_retcode                 =>  lv_retcode                  -- ���^�[���E�R�[�h
        ,ov_errmsg                  =>  lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �o�����敪1:�o�����܂��́A�{�Џ��i�敪'2'�h�����N�ȊO�̏ꍇ�͎����R�[�h
      IF(  ( lv_baracha_div      =  cn_baracya_type      )
        OR( lv_office_item_type <> cv_office_item_drink ) ) THEN
        -- �X�L�b�v����
        gn_warn_cnt   := gn_warn_cnt + 1;
      ELSE
        -- �P�[�X�������擾
        IF( ( lv_godds_classification IS NULL )
          OR( lv_godds_classification = 0 ) )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_xxcoi10292
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        -- �������s
        -- ================================================
        -- ����(C/S)�Z�o����(A-5)
        -- ================================================
        get_cs_data(
           it_transaction_qty           =>  lr_info_kuragae_rec.transaction_qty  -- ����
          ,it_godds_classification      =>  lv_godds_classification              -- �P�[�X����
          ,on_cs_qty                    =>  ln_cs_qty                            -- ���ʁiCS�j
          ,ov_errbuf                    =>  lv_errbuf                            -- �G���[�E���b�Z�[�W
          ,ov_retcode                   =>  lv_retcode                           -- ���^�[���E�R�[�h
          ,ov_errmsg                    =>  lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        --�ڋq�}�X�^��񒊏o����(A-6)
        -- ================================================
        get_cust_mst_info(
           it_base_code              =>   lr_info_kuragae_rec.out_base_code -- ���_�R�[�h
          ,ot_base_major_division    =>   lv_base_major_division            -- ���_�啪��
          ,ov_errbuf                 =>   lv_errbuf                         -- �G���[�E���b�Z�[�W
          ,ov_retcode                =>   lv_retcode                        -- ���^�[���E�R�[�h
          ,ov_errmsg                 =>   lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- �h�����N�U�։^���A�h�I���}�X�^��񒊏o����(A-7)
        -- ================================================
        get_drink_data(
           it_transaction_date          =>   lr_info_kuragae_rec.transaction_date  -- �����
          ,it_base_code                 =>   lr_info_kuragae_rec.out_base_code     -- �o�ɋ��_�R�[�h
          ,it_product_class             =>   lv_product_class                      -- ���i����
          ,it_base_major_division       =>   lv_base_major_division                -- ���_�啪��
          ,ot_set_unit_price            =>   ln_set_unit_price                     -- �ݒ�P��
          ,ov_errbuf                    =>   lv_errbuf                     -- �G���[�E���b�Z�[�W
          ,ov_retcode                   =>   lv_retcode                    -- ���^�[���E�R�[�h
          ,ov_errmsg                    =>   lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- �^����Z�o����(A-8)
        -- ================================================
        get_div_cost(
           in_cs_qty                    =>   ln_cs_qty                -- ���ʁiCS�j
          ,it_set_unit_price            =>   ln_set_unit_price        -- �ݒ�P��
          ,on_dlv_cost_budget_amt       =>   ln_dlv_cost_budget_amt   -- �^����\�Z���z
          ,ov_errbuf                    =>   lv_errbuf                -- �G���[�E���b�Z�[�W
          ,ov_retcode                   =>   lv_retcode               -- ���^�[���E�R�[�h
          ,ov_errmsg                    =>   lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;

      -- ==============================================
      --  ���[�N�e�[�u���f�[�^�o�^(A-9)
      -- ==============================================
      ins_work(
          lr_info_kuragae_rec.out_base_code             -- �o�ɋ��_
         ,lr_info_kuragae_rec.out_base_name             -- �o�ɋ��_��
         ,lr_info_kuragae_rec.transaction_type_id       -- ����^�C�vID
         ,lr_info_kuragae_rec.transaction_type_name     -- ����^�C�v��
         ,lr_info_kuragae_rec.transaction_type_id_sub   -- ����^�C�v�T�uID
         ,lr_info_kuragae_rec.in_base_code              -- ���ɋ��_
         ,lr_info_kuragae_rec.in_base_name              -- ���ɋ��_��
         ,lr_info_kuragae_rec.transaction_date          -- �����
         ,lr_info_kuragae_rec.item_no                   -- ���i
         ,lr_info_kuragae_rec.item_short_name           -- ����
         ,lr_info_kuragae_rec.slip_no                   -- �`�[No
         ,NVL(lr_info_kuragae_rec.transaction_qty,0)*-1 -- �������
         ,ln_discrete_cost*-1                           -- �c�ƌ����z
         ,NVL(ln_dlv_cost_budget_amt,0)*-1              -- �U�։^����
         ,NULL                                          -- �O�����b�Z�[�W
         ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt ;
      END IF;
--
    END LOOP;
--    
    -- �J�[�\���N���[�Y
    CLOSE info_kuragae_cur;
--
    -- �R�~�b�g����
    COMMIT;
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
      IF ( info_kuragae_cur%ISOPEN ) THEN
        CLOSE info_kuragae_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_kuragae_cur%ISOPEN ) THEN
        CLOSE info_kuragae_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_kuragae_cur%ISOPEN ) THEN
        CLOSE info_kuragae_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_kuragae_cur%ISOPEN ) THEN
        CLOSE info_kuragae_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_kuragae_data;
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
      SELECT hca.account_number account_num                         -- �ڋq�R�[�h
      FROM   hz_cust_accounts hca                                   -- �ڋq�}�X�^
            ,xxcmm_cust_accounts xca                                -- �ڋq�ǉ����A�h�I���}�X�^
      WHERE  hca.cust_account_id = xca.customer_id
        AND  hca.customer_class_code = cv_1
        AND  hca.account_number = NVL( gr_param.out_kyoten,hca.account_number )
        AND  xca.management_base_code = gv_base_code
      ORDER BY hca.account_number
    ;
--    
    -- ���_���(���i��)
    CURSOR info_base2_cur
    IS
      SELECT  hca.account_number account_num                         -- �ڋq�R�[�h
        FROM  hz_cust_accounts hca                                   -- �ڋq�}�X�^
       WHERE  hca.customer_class_code = cv_1
         AND  hca.account_number = NVL( gr_param.out_kyoten,hca.account_number )
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
    cv_01              CONSTANT VARCHAR2(2)    := '01';                           -- �Ó����`�F�b�N�p(1��)
    cv_12              CONSTANT VARCHAR2(2)    := '12';                           -- �Ó����`�F�b�N�p(12��)
    cv_mstorg_code     CONSTANT VARCHAR2(30)   := 'XXCOI1_MST_ORGANIZATION_CODE'; -- �v���t�@�C����(�}�X�^�g�D�R�[�h)
    cv_profile_name    CONSTANT VARCHAR2(24)   := 'XXCOI1_ORGANIZATION_CODE';     -- �v���t�@�C����(�݌ɑg�D�R�[�h)
    cv_item_div_h      CONSTANT VARCHAR2(30)   := 'XXCOS1_ITEM_DIV_H';            -- XXCOS:�{�Џ��i�敪
--
    -- *** ���[�J���ϐ� ***
    lv_organization_code mtl_parameters.organization_code%TYPE;      -- �݌ɑg�D�R�[�h
    lv_mst_organization_code mtl_parameters.organization_code%TYPE;  -- �}�X�^�g�D�R�[�h
    ld_date            DATE;
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
    -- �p�����[�^�Ó����`�F�b�N(��)   
    -- =====================================
    -- �p�����[�^.����NULL�łȂ��ꍇ
    IF gr_param.a_day IS NOT NULL THEN
      --
      IF ( ( gr_param.a_day < cv_01 ) OR ( gr_param.a_day  > cv_31 ) ) THEN
          
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10070
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_value_expt;
      ELSE 
        -- �p�����[�^.����1����������A�O��0��t��
        IF length(gr_param.a_day) = 1 THEN
          gr_param.a_day := cv_0||gr_param.a_day; 
        END IF;
        -- 
      -- �p�����[�^.�N���ƃp�����[�^.�������������t�̑Ó����`�F�b�N���s��
      ld_date := TO_DATE((gr_param.year_month||gr_param.a_day),'YYYYMMDD');      
      --
      -- �p�����[�^.�N���ƃp�����[�^.�����������A�Ɩ����t�Ɣ�r
        IF ( TO_CHAR( ( gd_process_date ), 'YYYYMMDD' ) < 
            ( gr_param.year_month||gr_param.a_day ) ) THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcoi10003
                      );
          lv_errbuf := lv_errmsg;
          RAISE get_value_expt;
        END IF;
      END IF;
    END IF;
--    
    -- �p�����[�^.����NULL�̏ꍇ
    IF gr_param.a_day IS NULL THEN
      -- �p�����[�^.�N���ƋƖ����t(�N��)���r
      IF ( TO_CHAR( ( gd_process_date ), 'YYYYMM' ) < ( gr_param.year_month ) ) THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10003
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_value_expt;
      END IF;
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
    -- �v���t�@�C���l�擾(�}�X�^�g�D�R�[�h)   
    -- =====================================
    lv_mst_organization_code := FND_PROFILE.VALUE(cv_mstorg_code);
    IF ( lv_mst_organization_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00030
                     ,iv_token_name1  => cv_token_pro
                     ,iv_token_value1 => cv_mstorg_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;         
--
    -- =====================================
    -- �}�X�^�i�ڑg�DID�擾                       
    -- =====================================
    gn_mst_organization_id := xxcoi_common_pkg.get_organization_id(lv_mst_organization_code);
    IF ( gn_mst_organization_id IS NULL ) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00031
                     ,iv_token_name1  => cv_token_mst_org_code
                     ,iv_token_value1 => lv_mst_organization_code
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
    -- =====================================
    -- �{�Џ��i�敪���擾                       
    -- =====================================
    gv_item_div_h := FND_PROFILE.VALUE( cv_item_div_h );
    IF ( gv_item_div_h IS NULL ) THEN
      -- �G���[���b�Z�[�W
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10092);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;    


    --==============================================================
    -- �R���J�����g���̓p�����[�^�o��
    --==============================================================
    -- �p�����[�^.����^�C�v
    IF( gr_param.transaction_type IS NOT NULL ) THEN
      SELECT transaction_type_name
      INTO   gv_transaction_type_name
      FROM   mtl_transaction_types
      WHERE  transaction_type_id = gr_param.transaction_type;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10066
                    ,iv_token_name1  => cv_token_transaction_type
                    ,iv_token_value1 => gv_transaction_type_name
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
                    ,iv_token_name1  => cv_token_date
                    ,iv_token_value1 => gr_param.year_month||gr_param.a_day
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- �p�����[�^.�o�ɋ��_
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10068
                    ,iv_token_name1  => cv_token_base_code
                    ,iv_token_value1 => gr_param.out_kyoten
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
    --*** �l�G���[ ***
    WHEN get_value_expt THEN                                                    
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_transaction_type  IN  VARCHAR2,         --   1.����^�C�v
    iv_year_month        IN  VARCHAR2,         --   2.�N��
    iv_day               IN  VARCHAR2,         --   3.��
    iv_out_kyoten        IN  VARCHAR2,         --   4.�o�ɋ��_
    iv_output_dpt        IN  VARCHAR2,         --   5.���[�o�͏ꏊ
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

    gr_param.transaction_type  := TO_NUMBER(iv_transaction_type); -- 01 : ����^�C�v    (�C��)
    gr_param.year_month        := SUBSTRB(iv_year_month,1,4)
                                  ||SUBSTRB(iv_year_month,6,7);  -- 02 : �����N��      (�K�{)
    gr_param.a_day             := iv_day;                        -- 03 : ������        (�C��)
    gr_param.out_kyoten        := iv_out_kyoten;                 -- 04 : �o�ɋ��_     �i�C��)
    gr_param.output_dpt        := iv_output_dpt;                 -- 05 : �o�͏ꏊ      (�K�{)
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
         -- �q�֏o�ɖ��׃f�[�^�擾(A-3)
         -- =====================================================
         get_kuragae_data(
             gn_base_loop_cnt
            ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         );
         IF ( lv_retcode = cv_status_error ) THEN
           -- �G���[����
           RAISE global_process_expt ;
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
      --  ���[�N�e�[�u���f�[�^�o�^(A-4)
      -- ==============================================
      ins_work(
          NULL                                      -- �o�ɋ��_
         ,NULL                                      -- �o�ɋ��_��
         ,NULL                                      -- ����^�C�vID
         ,gv_transaction_type_name                  -- ����^�C�v��
         ,NULL                                      -- ����^�C�v�T�uID
         ,NULL                                      -- ���ɋ��_
         ,NULL                                      -- ���ɋ��_��
         ,NULL                                      -- �����
         ,NULL                                      -- ���i
         ,NULL                                      -- ���i��
         ,NULL                                      -- �`�[No
         ,NULL                                      -- �������
         ,NULL                                      -- �c�ƌ����z
         ,NULL                                      -- �U�։^����
         ,lv_nodata_msg                             -- 0�����b�Z�[�W
         ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    iv_transaction_type  IN  VARCHAR2,      --   1.����^�C�v
    iv_year_month        IN  VARCHAR2,      --   2.�N��
    iv_day               IN  VARCHAR2,      --   3.��
    iv_out_kyoten        IN  VARCHAR2,      --   4.�o�ɋ��_
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
       iv_transaction_type  --   1.����^�C�v
      ,iv_year_month        --   2.�N��
      ,iv_day               --   3.��
      ,iv_out_kyoten        --   4.�o�ɋ��_
      ,iv_output_dpt        --   5.���[�o�͏ꏊ
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
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
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
END XXCOI009A02R;
/
