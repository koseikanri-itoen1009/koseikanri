create or replace
PACKAGE BODY XXCOI009A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A03R(body)
 * Description      : �H����ɖ��׃��X�g
 * MD.050           : �H����ɖ��׃��X�g MD050_COI_009_A03
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_work               ���[�N�e�[�u���f�[�^�폜(A-6)
 *  svf_request            SVF�N��(A-5)
 *  ins_work               ���[�N�e�[�u���f�[�^�o�^(A-4)
 *  get_kojo_data          �H����ɖ��׏��擾����(A-3)
 *  get_base_data          ���_���擾����(A-2)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/31    1.0   K.Tsuboi         �V�K�쐬
 *  2009/03/02    1.1   K.Tsuboi         [��Q�ԍ�028]�i�ڃR�[�h�ɑΉ����闪�̂��\������Ȃ��_�ɂ��ďC��
 *                                       [��Q�ԍ�029]�W�������z�Ɏ�����ʁ~�W�������̌v�Z�l��ݒ肷��
 *  2009/04/22    1.2   T.Nakamura       [��QT1_0491]���ޕi�ڂ̂ݒ��o�ΏۂƂȂ����^�C�v��ύX
 *  2009/05/21    1.3   T.Nakamura       [��QT1_1111]����^�C�v�̍i���������獫��ޗ������U�ցA����ޗ������U�֐U�߂����O
 *  2009/07/22    1.4   N.Abe            [��Q0000785]���[�t���ޕi�����i�A���i���o���̏��O�����ɒǉ�
 *  2009/08/05    1.5   H.Sasaki         [��Q0000926]�i�ڃJ�e�S���̈󎚐���̂��߂̏C��
 *  2009/09/08    1.6   H.Sasaki         [��Q0001266]OPM�i�ڃA�h�I���̔ŊǗ��Ή�
 *  2009/10/22    1.7   H.Sasaki         [��QE_T4_00057]���ޕi�ڂ̎擾���@�ύX
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
  get_no_data_expt          EXCEPTION;    -- �Ώۃf�[�^0��
  svf_request_err_expt      EXCEPTION;    -- SVF�N��API�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOI009A03R';   -- �p�b�P�[�W��
  cv_app_name      CONSTANT VARCHAR2(5)   := 'XXCOI';          -- �A�v���P�[�V�����Z�k��
  cv_0             CONSTANT VARCHAR2(1)   := '0';              -- �萔
  cv_1             CONSTANT VARCHAR2(1)   := '1';              -- �萔
  cv_2             CONSTANT VARCHAR2(1)   := '2';              -- �萔
  cv_3             CONSTANT VARCHAR2(1)   := '3';              -- �萔
  cv_4             CONSTANT VARCHAR2(1)   := '4';              -- �萔
  cv_log               CONSTANT VARCHAR2(3)   := 'LOG';            -- �R���J�����g�w�b�_�o�͐�
--
  -- ���b�Z�[�W
  cv_msg_xxcoi00008  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 0�����b�Z�[�W
  cv_msg_xxcoi10003  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10003';   -- ���t���̓G���[
  cv_msg_xxcoi00005  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';   -- �݌ɑg�D�R�[�h�擾�G���[
  cv_msg_xxcoi00006  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';   -- �݌ɑg�DID�擾�G���[
  cv_msg_xxcoi00011  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011';   -- �Ɩ����t�擾�G���[
  cv_msg_xxcoi10022  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00022';   -- ����^�C�v���擾�G���[
  cv_msg_xxcoi10012  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00012';   -- ����^�C�v�擾�G���[
  cv_msg_xxcoi10069  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10069';   -- ���t�͈�(�N��)�G���[
  cv_msg_xxcoi10092  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10092';   -- �������_�擾�G���[
  cv_msg_xxcoi10081  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10081';   -- �p�����[�^.�N�����b�Z�[�W
  cv_msg_xxcoi10082  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10082';   -- �p�����[�^.���ɋ��_���b�Z�[�W
  cv_msg_xxcoi10083  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10083';   -- �p�����[�^.�i�ڃJ�e�S�����b�Z�[�W
  cv_msg_xxcoi10285  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10285';   -- �W�������擾���s�G���[
--
  -- �g�[�N����
  cv_token_pro       CONSTANT VARCHAR2(30) := 'PRO_TOK';
  cv_token_org_code  CONSTANT VARCHAR2(30) := 'ORG_CODE_TOK';
  cv_token_date      CONSTANT VARCHAR2(30) := 'P_DATE';
  cv_token_base_code CONSTANT VARCHAR2(30) := 'P_BASE_CODE';
  cv_token_item_ctg  CONSTANT VARCHAR2(30) := 'P_ITEM_CTG';
  cv_tkn_lookup_type CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';            -- �Q�ƃ^�C�v
  cv_tkn_lookup_code CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';            -- �Q�ƃR�[�h
  cv_tkn_tran_type   CONSTANT VARCHAR2(20) := 'TRANSACTION_TYPE_TOK';   -- ����^�C�v
  cv_tkn_item_code   CONSTANT VARCHAR2(20) := 'ITEM_CODE';
--
    -- �J�e�S���Z�b�g��
  cv_category_hinmoku  CONSTANT VARCHAR2(8)   := '�i�ڋ敪';
  cv_category_seishou  CONSTANT VARCHAR2(12)  := '���i���i�敪';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE gr_param_rec  IS RECORD(
      year_month        VARCHAR2(7)       -- 01 : �����N��    �i�K�{)
     ,in_kyoten         VARCHAR2(4)       -- 02 : ���ɋ��_    �i�C��)
     ,item_ctg          VARCHAR2(1)       -- 03 : �J�e�S���R�[�h(�C��)
     ,output_dpt        VARCHAR2(1)       -- 04 : ���[�o�͏ꏊ(�C��)
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
  -- �H����ɏ��i�[�p���R�[�h�ϐ�
  TYPE gr_kojo_nyuko_rec IS RECORD
    (
      msi_attribute7                mtl_secondary_inventories.attribute7%TYPE            -- ���ɋ��_�R�[�h
     ,hca_account_number            hz_cust_accounts.account_number%TYPE                -- ���ɋ��_��
     ,mmt_inventory_item_id         mtl_material_transactions.inventory_item_id%TYPE     -- �i��ID
     ,mmt_transaction_quantity      mtl_material_transactions.transaction_quantity%TYPE  -- �������
     ,mmt_transaction_date          mtl_material_transactions.transaction_date%TYPE      -- �����
     ,msib_segment1                 mtl_system_items_b.segment1%TYPE                     -- �i�ږ�
     ,ximb_item_short_name          xxcmn_item_mst_b.item_short_name%TYPE                -- �i�ڗ���
--     ,                              --�i�ڃJ�e�S���R�[�h
--
    );
  --  �H����ɏ��i�[�p�e�[�u��
  TYPE gt_kojo_nyuko_ttype IS TABLE OF gr_kojo_nyuko_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date           DATE;                                           -- �Ɩ����t
  gv_base_code              hz_cust_accounts.account_number%TYPE;           -- ���_�R�[�h
  -- �J�E���^
  gn_base_cnt               NUMBER;                                         -- ���_�R�[�h����
  gn_base_loop_cnt          NUMBER;                                         -- ���_�R�[�h���[�v�J�E���^
  gn_kojo_nyuko_cnt         NUMBER;                                         -- �H����ɏ�񌏐�
  gn_kojo_nyuko_loop_cnt    NUMBER;                                         -- �H����ɏ�񃋁[�v�J�E���^
  gn_organization_id        mtl_parameters.organization_id%TYPE;            -- �݌ɑg�DID
  --
  gr_param                  gr_param_rec;
  gt_base_num_tab           gt_base_num_ttype;
  gt_kojo_nyuko_tab         gt_kojo_nyuko_ttype;
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-6)
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
    DELETE xxcoi_rep_factory_store_list xrw
    WHERE  xrw.request_id = cn_request_id
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
   * Description      : SVF�N��(A-5)
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
    cv_frm_file     CONSTANT VARCHAR2(30) := 'XXCOI009A03S.xml';   -- �t�H�[���l���t�@�C����
    cv_vrq_file     CONSTANT VARCHAR2(30) := 'XXCOI009A03S.vrq';   -- �N�G���[�l���t�@�C����
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
      ov_retcode      => lv_retcode            -- ���^�[���R�[�h
     ,ov_errbuf       => lv_errbuf             -- �G���[���b�Z�[�W
     ,ov_errmsg       => lv_errmsg             -- ���[�U�[�E�G���[���b�Z�[�W
     ,iv_conc_name    => cv_pkg_name           -- �R���J�����g��
     ,iv_file_name    => lv_file_name          -- �o�̓t�@�C����
     ,iv_file_id      => cv_pkg_name           -- ���[ID
     ,iv_output_mode  => cv_output_mode        -- �o�͋敪
     ,iv_frm_file     => cv_frm_file           -- �t�H�[���l���t�@�C����
     ,iv_vrq_file     => cv_vrq_file           -- �N�G���[�l���t�@�C����
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => fnd_global.user_name  -- ���O�C���E���[�U��
     ,iv_resp_name    => fnd_global.resp_name  -- ���O�C���E���[�U�̐E�Ӗ�
     ,iv_doc_name     => NULL                  -- ������
     ,iv_printer_name => NULL                  -- �v�����^��
     ,iv_request_id   => cn_request_id         -- �v��ID
     ,iv_nodata_msg   => NULL                  -- �f�[�^�Ȃ����b�Z�[�W
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
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_work(
    iv_store_base_code    IN mtl_secondary_inventories.attribute1%TYPE,
    iv_store_base_name    IN hz_cust_accounts.account_name%TYPE,
    iv_item_ctg           IN mtl_categories_b.segment1%TYPE,
    iv_item_code          IN mtl_system_items_b.segment1%TYPE,
    iv_item_name          IN xxcmn_item_mst_b.item_short_name%TYPE,
    in_trn_qty            IN mtl_material_transactions.transaction_quantity%TYPE,
    in_stand_cost         IN NUMBER,
    iv_prm_flg            IN VARCHAR2,
    iv_nodata_msg         IN VARCHAR2,
    ov_errbuf            OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    INSERT INTO xxcoi_rep_factory_store_list(
       target_term
      ,store_base_code
      ,store_base_name
      ,item_ctg
      ,item_code
      ,item_name
      ,trn_qty
      ,stand_cost
      ,prm_flg
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
       gr_param.year_month                       -- �Ώ۔N��
      ,iv_store_base_code                        -- ���ɋ��_
      ,iv_store_base_name                        -- ���ɋ��_��
      ,iv_item_ctg                               -- �i�ڃJ�e�S���R�[�h
      ,iv_item_code                              -- ���i
      ,iv_item_name                              -- ����
      ,in_trn_qty                                -- �������
      ,in_stand_cost                             -- �����z
      ,iv_prm_flg                                -- �p�����[�^�t���O
      ,iv_nodata_msg                             -- 0�����b�Z�[�W
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
   * Procedure Name   : get_kojo_data�i���[�v���j
   * Description      : �H����ɖ��׏��(A-3)
   ***********************************************************************************/
  PROCEDURE get_kojo_data(
    gn_base_loop_cnt IN NUMBER,       --   �J�E���g
    ov_errbuf        OUT VARCHAR2,    --   �G���[�E���b�Z�[�W                --# �Œ� #
    ov_retcode       OUT VARCHAR2,    --   ���^�[���E�R�[�h                  --# �Œ� #
    ov_errmsg        OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fact_data'; -- �v���O������
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
    -- ���[�U�[��`����^�C�v����
    cv_tran_type                   CONSTANT VARCHAR2(30)  := 'XXCOI1_TRANSACTION_TYPE_NAME';
--
    -- �Q�ƃR�[�h
    cv_tran_type_factory_store     CONSTANT VARCHAR2(3)   := '150';  -- ����^�C�v�R�[�h �H�����
    cv_tran_type_factory_store_b   CONSTANT VARCHAR2(3)   := '160';  -- ����^�C�v�R�[�h �H����ɐU��
-- == 2009/04/22 V1.2 Added START ===============================================================
    cv_tran_type_packing_temp      CONSTANT VARCHAR2(3)   := '250';  -- ����^�C�v�R�[�h ����ޗ��ꎞ���
    cv_tran_type_packing_temp_b    CONSTANT VARCHAR2(3)   := '260';  -- ����^�C�v�R�[�h ����ޗ��ꎞ����U��
-- == 2009/05/21 V1.3 Deleted START =============================================================
--    cv_tran_type_packing_cost      CONSTANT VARCHAR2(3)   := '270';  -- ����^�C�v�R�[�h ����ޗ������U��
--    cv_tran_type_packing_cost_b    CONSTANT VARCHAR2(3)   := '280';  -- ����^�C�v�R�[�h ����ޗ������U�֐U��
-- == 2009/05/21 V1.3 Deleted END   =============================================================
-- == 2009/04/22 V1.2 Added END   ===============================================================
--
    -- *** ���[�J���ϐ� ***
    lv_tran_type_factory_store     mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� �H�����
    ln_tran_type_factory_store     mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID �H�����
    lv_tran_type_factory_store_b   mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� �H����ɐU��
    ln_tran_type_factory_store_b   mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID �H����ɐU��
    lv_base_code                   hz_cust_accounts.account_number%TYPE DEFAULT  NULL; -- ���ɋ��_�R�[�h���ʗp
    lv_item_code                   mtl_system_items_b.segment1%TYPE DEFAULT  NULL;     -- ���i�R�[�h���ʗp
    lv_item_short_name             xxcmn_item_mst_b.item_short_name%TYPE DEFAULT  NULL; -- ���i���̕ێ��p
    lv_item_category               mtl_categories_b.segment1%TYPE DEFAULT  NULL;        -- �J�e�S���R�[�h�ێ��p
    ln_tran_qty                    mtl_material_transactions.transaction_quantity%TYPE DEFAULT  0; -- �������
    lv_cmpnt_cost                  VARCHAR2(30) DEFAULT  NULL;                                       -- �W������
    ln_cmpnt_cost_sum              NUMBER       DEFAULT  0;                                       -- �W������
    ln_cnt                         NUMBER       DEFAULT  0;          -- ���[�v�J�E���^
    lv_zero_message                VARCHAR2(30) DEFAULT  NULL;       -- �[�������b�Z�[�W
    ln_sql_cnt                     NUMBER       DEFAULT  0;
    ln_cmpnt_cost                  NUMBER       DEFAULT  0;                                       -- �W������
-- == 2009/04/22 V1.2 Added START ===============================================================
    lv_tran_type_packing_temp      mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� ����ޗ��ꎞ���
    ln_tran_type_packing_temp      mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID ����ޗ��ꎞ���
    lv_tran_type_packing_temp_b    mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� ����ޗ��ꎞ����U��
    ln_tran_type_packing_temp_b    mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID ����ޗ��ꎞ����U��
-- == 2009/05/21 V1.3 Deleted START =============================================================
--    lv_tran_type_packing_cost      mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� ����ޗ������U��
--    ln_tran_type_packing_cost      mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID ����ޗ������U��
--    lv_tran_type_packing_cost_b    mtl_transaction_types.transaction_type_name%TYPE;   -- ����^�C�v�� ����ޗ������U�֐U��
--    ln_tran_type_packing_cost_b    mtl_transaction_types.transaction_type_id%TYPE;     -- ����^�C�vID ����ޗ������U�֐U��
-- == 2009/05/21 V1.3 Deleted END   =============================================================
-- == 2009/04/22 V1.2 Added END   ===============================================================
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �H����ɖ��׏��
-- == 2009/04/22 V1.2 Moded START ===============================================================
--    CURSOR info_fact_cur(tran_type1 NUMBER,tran_type2 NUMBER)
    CURSOR info_fact_cur(
               tran_type1 NUMBER
             , tran_type2 NUMBER
             , tran_type3 NUMBER
             , tran_type4 NUMBER
-- == 2009/05/21 V1.3 Deleted START =============================================================
--             , tran_type5 NUMBER
--             , tran_type6 NUMBER
-- == 2009/05/21 V1.3 Deleted END   =============================================================
           )
-- == 2009/04/22 V1.2 Moded END   ===============================================================
    IS
      SELECT  msi.attribute7                in_base_code                   -- ���ɋ��_
             ,SUBSTRB(hca.account_name,1,8) account_name                   -- ���ɋ��_��
             ,mmt.inventory_item_id         inventory_item_id              -- �i��ID
             ,mmt.transaction_quantity      transaction_qty                -- �������
             ,mmt.transaction_date          transaction_date               -- �����
             ,msib.segment1                 item_no                        -- �i�ڃR�[�h
             ,ximb.item_short_name          item_short_name                -- ����
             ,cat.item_category             item_category                  -- �i�ڃJ�e�S���R�[�h
      FROM    mtl_secondary_inventories     msi                            -- �ۊǏꏊ�}�X�^
             ,hz_cust_accounts              hca                            -- �ڋq�}�X�^
             ,mtl_material_transactions     mmt                            -- ���ގ��
             ,mtl_system_items_b            msib                           -- �i�ڃ}�X�^
             ,ic_item_mst_b                 iimb                           -- OPM�i�ڃ}�X�^
             ,xxcmn_item_mst_b              ximb                           -- OPM�i�ڃA�h�I���}�X�^
             ,( 
-- == 2009/10/22 V1.7 Modified START ===============================================================
--               SELECT msib.segment1          item_no                    -- �i�ڃR�[�h
--                      ,decode(mcb.segment1,cv_2,cv_3 )   item_category  -- �i�ڃJ�e�S���R�[�h
--               FROM   mtl_system_items_b     msib                  -- �i�ڃ}�X�^
--                     ,mtl_category_sets_b    mcsb                  -- �i�ڃJ�e�S���Z�b�g
--                     ,mtl_category_sets_tl   mcst                  -- �i�ڃJ�e�S���Z�b�g���{��
--                     ,mtl_categories_b       mcb                   -- �i�ڃJ�e�S���}�X�^
--                     ,mtl_item_categories    mic                   -- �i�ڃJ�e�S������
--               WHERE  msib.inventory_item_id =  mic.inventory_item_id
--                 AND  mcb.category_id        =  mic.category_id
--                 AND  mcsb.category_set_id   =  mic.category_set_id
--                 AND  mcb.structure_id       =  mcsb.structure_id
--                 AND  mcst.category_set_id   =  mcsb.category_set_id
--                 AND  mcst.language          =  USERENV( 'LANG' )
--                 AND  mcst.category_set_name =  cv_category_hinmoku
--                 AND  mcb.segment1           =  cv_2
--                 AND  mic.organization_id    =  gn_organization_id
--                 AND  msib.organization_id   =   mic.organization_id
               SELECT msib.segment1                       item_no         -- �i�ڃR�[�h
                     ,cv_3                                item_category   -- �i�ڃJ�e�S���R�[�h
               FROM   mtl_system_items_b      msib                        -- �i�ڃ}�X�^
               WHERE  msib.organization_id    =   gn_organization_id
               AND    (   msib.segment1 LIKE '5%'
                       OR msib.segment1 LIKE '6%'
                      )
-- == 2009/10/22 V1.7 Modified END   ===============================================================
             UNION
               SELECT msib.segment1          item_no               -- �i�ڃR�[�h
                     ,mcb.segment1           item_category         -- �i�ڃJ�e�S���R�[�h
               FROM   mtl_system_items_b     msib                  -- �i�ڃ}�X�^
                     ,mtl_category_sets_b    mcsb                  -- �i�ڃJ�e�S���Z�b�g
                     ,mtl_category_sets_tl   mcst                  -- �i�ڃJ�e�S���Z�b�g���{��
                     ,mtl_categories_b       mcb                   -- �i�ڃJ�e�S���}�X�^
                     ,mtl_item_categories    mic                   -- �i�ڃJ�e�S������
               WHERE  msib.inventory_item_id =  mic.inventory_item_id
                 AND  mcb.category_id        =  mic.category_id
                 AND  mcsb.category_set_id   =  mic.category_set_id
                 AND  mcb.structure_id       =  mcsb.structure_id
                 AND  mcst.category_set_id   =  mcsb.category_set_id
                 AND  mcst.language          =  USERENV( 'LANG' )
                 AND  mcst.category_set_name =  cv_category_seishou
                 AND  mic.organization_id    =  gn_organization_id
                 AND  msib.organization_id   =   mic.organization_id
-- == 2009/04/22 V1.2 Added START ===============================================================
                 AND NOT EXISTS( SELECT '1'
                                 FROM   mtl_system_items_b     msib2
                                 WHERE  msib.inventory_item_id =  msib2.inventory_item_id
                                 AND    msib.organization_id   =  msib2.organization_id
-- == 2009/07/22 V1.4 Moded START ===============================================================
--                                 AND    msib2.segment1         LIKE  '6%'
                                 AND    (msib2.segment1         LIKE  '6%'
                                   OR    msib2.segment1         LIKE  '5%'
                                        )
-- == 2009/07/22 V1.4 Moded END   ===============================================================
                               )
-- == 2009/04/22 V1.2 Added END   ===============================================================
               ) cat
      WHERE  TO_CHAR ( mmt.transaction_date, 'YYYYMM' ) = gr_param.year_month
-- == 2009/04/22 V1.2 Moded START ===============================================================
--        AND  mmt.transaction_type_id IN (tran_type1, tran_type2)
-- == 2009/05/21 V1.3 Moded START ===============================================================
        AND ( ( cat.item_category       IN (cv_1, cv_2)
            AND mmt.transaction_type_id IN (tran_type1, tran_type2) )
          OR  ( cat.item_category       =   cv_3
--            AND mmt.transaction_type_id IN (tran_type3, tran_type4, tran_type5, tran_type6) ) )
            AND mmt.transaction_type_id IN (tran_type3, tran_type4) ) )
-- == 2009/05/21 V1.3 Moded END   ===============================================================
-- == 2009/04/22 V1.2 Moded END   ===============================================================
        AND  mmt.subinventory_code               =  msi.secondary_inventory_name
        AND  msi.attribute7                      =  gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
        AND  hca.account_number                  =  msi.attribute7
        AND  hca.customer_class_code             =  cv_1
        AND  msib.inventory_item_id              =  mmt.inventory_item_id
        AND  msib.organization_id                =  gn_organization_id
        AND  cat.item_no                         =  msib.segment1
        AND  cat.item_category                   =  NVL ( gr_param.item_ctg,cat.item_category )
        AND  msib.segment1                       =  iimb.item_no
        AND  iimb.item_id                        =  ximb.item_id
-- == 2009/09/08 V1.6 Added START ===============================================================
        AND  mmt.transaction_date BETWEEN ximb.start_date_active
                                  AND     NVL(ximb.end_date_active, mmt.transaction_date)
-- == 2009/09/08 V1.6 Added END   ===============================================================
      ORDER BY msi.attribute7
              ,cat.item_category
              ,msib.segment1
      ;
--
    -- ���[�J���E���R�[�h
    lr_info_fact_rec info_fact_cur%ROWTYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- ����^�C�v���擾�F�H�����
    -- ===============================
    lv_tran_type_factory_store := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_factory_store);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_tran_type_factory_store IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10022
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => cv_tran_type_factory_store
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�F�H�����
    -- ===============================
    ln_tran_type_factory_store := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_factory_store);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( ln_tran_type_factory_store IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10012
                     ,iv_token_name1  => cv_tkn_tran_type
                     ,iv_token_value1 => lv_tran_type_factory_store
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�F�H����ɐU��
    -- ===============================
    lv_tran_type_factory_store_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_factory_store_b);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_tran_type_factory_store_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10022
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => cv_tran_type_factory_store_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�F�H����ɐU��
    -- ===============================
    ln_tran_type_factory_store_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_factory_store_b);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( ln_tran_type_factory_store_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10012
                     ,iv_token_name1  => cv_tkn_tran_type
                     ,iv_token_value1 => lv_tran_type_factory_store_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- == 2009/04/22 V1.2 Added START ===============================================================
    -- ===============================
    -- ����^�C�v���擾�F����ޗ��ꎞ���
    -- ===============================
    lv_tran_type_packing_temp := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_packing_temp);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_tran_type_packing_temp IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10022
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => cv_tran_type_packing_temp
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�F����ޗ��ꎞ���
    -- ===============================
    ln_tran_type_packing_temp := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_packing_temp);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( ln_tran_type_packing_temp IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10012
                     ,iv_token_name1  => cv_tkn_tran_type
                     ,iv_token_value1 => lv_tran_type_packing_temp
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�F����ޗ��ꎞ����U��
    -- ===============================
    lv_tran_type_packing_temp_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_packing_temp_b);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( lv_tran_type_packing_temp_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10022
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => cv_tran_type_packing_temp_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�F����ޗ��ꎞ����U��
    -- ===============================
    ln_tran_type_packing_temp_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_packing_temp_b);
    --
    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
    IF ( ln_tran_type_packing_temp_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10012
                     ,iv_token_name1  => cv_tkn_tran_type
                     ,iv_token_value1 => lv_tran_type_packing_temp_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- == 2009/05/21 V1.3 Deleted START =============================================================
--    -- ===============================
--    -- ����^�C�v���擾�F����ޗ������U��
--    -- ===============================
--    lv_tran_type_packing_cost := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_packing_cost);
--    --
--    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
--    IF ( lv_tran_type_packing_cost IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name
--                     ,iv_name         => cv_msg_xxcoi10022
--                     ,iv_token_name1  => cv_tkn_lookup_type
--                     ,iv_token_value1 => cv_tran_type
--                     ,iv_token_name2  => cv_tkn_lookup_code
--                     ,iv_token_value2 => cv_tran_type_packing_cost
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    -- ===============================
--    -- ����^�C�vID�擾�F����ޗ������U��
--    -- ===============================
--    ln_tran_type_packing_cost := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_packing_cost);
--    --
--    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
--    IF ( ln_tran_type_packing_cost IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name
--                     ,iv_name         => cv_msg_xxcoi10012
--                     ,iv_token_name1  => cv_tkn_tran_type
--                     ,iv_token_value1 => lv_tran_type_packing_cost
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    -- ===============================
--    -- ����^�C�v���擾�F����ޗ������U�֐U��
--    -- ===============================
--    lv_tran_type_packing_cost_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_packing_cost_b);
--    --
--    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
--    IF ( lv_tran_type_packing_cost_b IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name
--                     ,iv_name         => cv_msg_xxcoi10022
--                     ,iv_token_name1  => cv_tkn_lookup_type
--                     ,iv_token_value1 => cv_tran_type
--                     ,iv_token_name2  => cv_tkn_lookup_code
--                     ,iv_token_value2 => cv_tran_type_packing_cost_b
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    -- ===============================
--    -- ����^�C�vID�擾�F����ޗ������U�֐U��
--    -- ===============================
--    ln_tran_type_packing_cost_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_packing_cost_b);
--    --
--    -- ���^�[���R�[�h��NULL�̏ꍇ�̓G���[
--    IF ( ln_tran_type_packing_cost_b IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name
--                     ,iv_name         => cv_msg_xxcoi10012
--                     ,iv_token_name1  => cv_tkn_tran_type
--                     ,iv_token_value1 => lv_tran_type_packing_cost_b
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
-- == 2009/05/21 V1.3 Deleted END   =============================================================
-- == 2009/04/22 V1.2 Added END   ===============================================================
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �J�[�\���I�[�v��
-- == 2009/04/22 V1.2 Moded START ===============================================================
--    OPEN  info_fact_cur(ln_tran_type_factory_store,ln_tran_type_factory_store_b);
    OPEN  info_fact_cur(
              tran_type1 => ln_tran_type_factory_store
            , tran_type2 => ln_tran_type_factory_store_b
            , tran_type3 => ln_tran_type_packing_temp
            , tran_type4 => ln_tran_type_packing_temp_b
-- == 2009/05/21 V1.3 Deleted START =============================================================
--            , tran_type5 => ln_tran_type_packing_cost
--            , tran_type6 => ln_tran_type_packing_cost_b
-- == 2009/05/21 V1.3 Deleted END   =============================================================
          );
-- == 2009/04/22 V1.2 Moded END   ===============================================================
    --
    <<ins_work_loop>>
    LOOP
    FETCH info_fact_cur INTO lr_info_fact_rec;
    EXIT WHEN info_fact_cur%NOTFOUND;
--
    -- �Ώی����J�E���g
      ln_sql_cnt := ln_sql_cnt + 1;
      gn_target_cnt :=  gn_target_cnt + 1;
--
      -- ==============================================
      --  �W�������擾
      -- ==============================================
      xxcoi_common_pkg.get_cmpnt_cost(in_item_id     => lr_info_fact_rec.inventory_item_id   -- �i��ID
                                     ,in_org_id      => gn_organization_id                   -- �݌ɑg�DID
                                     ,id_period_date => lr_info_fact_rec.transaction_date    -- �����
                                     ,ov_cmpnt_cost  => lv_cmpnt_cost                        -- �W������
                                     ,ov_retcode     => lv_retcode                           -- ���^�[���R�[�h
                                     ,ov_errbuf      => lv_errbuf                            -- �G���[���b�Z�[�W
                                     ,ov_errmsg      => lv_errmsg);                          -- �G���[���b�Z�[�W
      IF (lv_retcode <> cv_status_normal) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10285
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- �����z�v�Z
      ln_cmpnt_cost := NVL(TO_NUMBER(lv_cmpnt_cost),0) * lr_info_fact_rec.transaction_qty;
--
      -- �ŏ��̃��R�[�h�̏ꍇ�A���f�[�^��ݒ�
      IF ln_sql_cnt = 1 THEN
        -- ���i�R�[�h�ݒ�
        lv_item_code := lr_info_fact_rec.item_no;
      END IF;
--
      -- ���i�R�[�h���O���R�[�h�ƈႤ�ꍇ,���[�N�e�[�u���ɓo�^
      IF ( lv_item_code = lr_info_fact_rec.item_no ) THEN
--
        -- ���ʉ��Z
        ln_tran_qty := ln_tran_qty + lr_info_fact_rec.transaction_qty;
        -- �W���������Z
        ln_cmpnt_cost_sum := ln_cmpnt_cost_sum + ln_cmpnt_cost;
        -- ���i�R�[�h�ݒ�
        lv_item_code := lr_info_fact_rec.item_no;
        -- ���i���̐ݒ�
        lv_item_short_name := lr_info_fact_rec.item_short_name;
        -- �J�e�S���ݒ�
        lv_item_category := lr_info_fact_rec.item_category;
--
      ELSIF ( lv_item_code <> lr_info_fact_rec.item_no ) THEN
--
        -- ==============================================
        --  ���[�N�e�[�u���f�[�^�o�^(A-4)
        -- ==============================================
        ins_work(
            lr_info_fact_rec.in_base_code                        -- ���ɋ��_
           ,lr_info_fact_rec.account_name                        -- ���ɋ��_��
           ,lv_item_category                                     -- �i�ڃJ�e�S���R�[�h
           ,lv_item_code                                         -- ���i
           ,lv_item_short_name                                   -- ����
           ,ln_tran_qty                                          -- �������
           ,ln_cmpnt_cost_sum                                    -- �����z
-- == 2009/08/05 V1.5 Modified START ===============================================================
--           ,cv_1                                                 -- �p�����[�^�t���O
           ,CASE  WHEN  gr_param.item_ctg IS NULL THEN cv_1
                  ELSE  cv_2
            END
-- == 2009/08/05 V1.5 Modified END   ===============================================================
           ,NULL
           ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error )
         OR ( lv_retcode = cv_status_warn ) THEN
          RAISE global_process_expt ;
        END IF;
--
        -- ���ʐݒ�
        ln_tran_qty := lr_info_fact_rec.transaction_qty;
        -- �W�������ݒ�
        ln_cmpnt_cost_sum := ln_cmpnt_cost;
        -- ���i�R�[�h�ݒ�
        lv_item_code := lr_info_fact_rec.item_no;
        -- ���i���̐ݒ�
        lv_item_short_name := lr_info_fact_rec.item_short_name;
        -- �J�e�S���ݒ�
        lv_item_category := lr_info_fact_rec.item_category;
--
      END IF;
--
    END LOOP ins_work_loop;
--
    -- �ŏI���R�[�h�̏ꍇ������œo�^
    IF ln_sql_cnt > 0 THEN
        -- ==============================================
        --  ���[�N�e�[�u���f�[�^�o�^(A-4)
        -- ==============================================
        ins_work(
            lr_info_fact_rec.in_base_code                        -- ���ɋ��_
           ,lr_info_fact_rec.account_name                        -- ���ɋ��_��
           ,lv_item_category                                     -- �i�ڃJ�e�S���R�[�h
           ,lv_item_code                                         -- ���i
           ,lv_item_short_name                                   -- ����
           ,ln_tran_qty                                          -- �������
           ,ln_cmpnt_cost_sum                                    -- �����z
-- == 2009/08/05 V1.5 Modified START ===============================================================
--           ,cv_1                                                 -- �p�����[�^�t���O
           ,CASE  WHEN  gr_param.item_ctg IS NULL THEN cv_1
                  ELSE  cv_2
            END
-- == 2009/08/05 V1.5 Modified END   ===============================================================
           ,NULL
           ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error )
         OR ( lv_retcode = cv_status_warn ) THEN
          RAISE global_process_expt ;
        END IF;
--
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE info_fact_cur;
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
      IF ( info_fact_cur%ISOPEN ) THEN
        CLOSE info_fact_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_fact_cur%ISOPEN ) THEN
        CLOSE info_fact_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_fact_cur%ISOPEN ) THEN
        CLOSE info_fact_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_fact_cur%ISOPEN ) THEN
        CLOSE info_fact_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_kojo_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : ���_���擾(A-2)
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
    -- ���_���(���X)
    CURSOR info_base1_cur
    IS
      SELECT hca.account_number account_num                         -- �ڋq�R�[�h
      FROM   hz_cust_accounts hca                                   -- �ڋq�}�X�^
            ,xxcmm_cust_accounts xca                                                    -- �ڋq�ǉ����A�h�I���}�X�^
      WHERE  hca.cust_account_id = xca.customer_id
        AND  hca.customer_class_code = cv_1
        AND  hca.account_number = NVL( gr_param.in_kyoten,hca.account_number )
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
         AND  hca.account_number = NVL( gr_param.in_kyoten,hca.account_number )
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
    -- ���X�ŋN���̎�
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
    -- ���i���ŋN���̎�
    ELSIF ( gr_param.output_dpt = cv_3 ) THEN
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
    cv_01              CONSTANT VARCHAR2(2)    := '01';                        -- �Ó����`�F�b�N�p(1��)
    cv_12              CONSTANT VARCHAR2(2)    := '12';                        -- �Ó����`�F�b�N�p(12��)
    cv_profile_name    CONSTANT VARCHAR2(24)   := 'XXCOI1_ORGANIZATION_CODE';  -- �v���t�@�C����(�݌ɑg�D�R�[�h)
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
    -- �p�����[�^�Ó����`�F�b�N(�N��)
    -- =====================================
    IF ( ( SUBSTRB(gr_param.year_month,5,6) < cv_01 ) OR ( SUBSTRB ( gr_param.year_month,5,6 ) > cv_12 ) ) THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10069
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_value_expt;
    ELSIF ( TO_CHAR( ( gd_process_date ), 'YYYYMM' ) < gr_param.year_month ) THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10003
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_value_expt;
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
    -- �p�����[�^.�N��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application =>  cv_app_name
                    ,iv_name        =>  cv_msg_xxcoi10081
                    ,iv_token_name1  => cv_token_date
                    ,iv_token_value1 => gr_param.year_month
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- �p�����[�^.���ɋ��_
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application =>  cv_app_name
                    ,iv_name        =>  cv_msg_xxcoi10082
                    ,iv_token_name1  => cv_token_base_code
                    ,iv_token_value1 => gr_param.in_kyoten
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- �p�����[�^.�J�e�S��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application =>  cv_app_name
                    ,iv_name        =>  cv_msg_xxcoi10083
                    ,iv_token_name1  => cv_token_item_ctg
                    ,iv_token_value1 => gr_param.item_ctg
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
    iv_year_month  IN  VARCHAR2,     --   1.�N��
    iv_in_kyoten   IN  VARCHAR2,     --   2.���ɋ��_
    iv_item_ctgr   IN  VARCHAR2,     --   3.�i�ڃJ�e�S��
    iv_output_dpt  IN  VARCHAR2,     --   4.���[�o�͏ꏊ
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gr_param.year_month    := SUBSTRB(iv_year_month,1,4)
                            ||SUBSTRB(iv_year_month,6,7);
                                                   -- 01 : �����N��      (�K�{)
    gr_param.in_kyoten     := iv_in_kyoten;        -- 02 : ���ɋ��_     �i�C��)
    gr_param.item_ctg      := iv_item_ctgr;        -- 03 : �J�e�S���R�[�h(�C��)
    gr_param.output_dpt    := iv_output_dpt;       -- 04 : �o�͏ꏊ(�C��)
--
    -- =====================================================
    -- ��������(A-1)
    -- =====================================================
    init(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF ( lv_retcode = cv_status_error )
     OR ( lv_retcode = cv_status_warn ) THEN
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
    IF ( lv_retcode = cv_status_error )
     OR ( lv_retcode = cv_status_warn ) THEN
      RAISE global_process_expt ;
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
         -- �H����ɖ��׏��擾����(A-3)
         -- =====================================================
         get_kojo_data(
             gn_base_loop_cnt
            ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         );
         IF ( lv_retcode = cv_status_error )
          OR ( lv_retcode = cv_status_warn ) THEN
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
          NULL                                                 -- ���ɋ��_
         ,NULL                                                 -- ���ɋ��_��
         ,NULL                                                 -- �i�ڃJ�e�S���R�[�h
         ,NULL                                                 -- ���i
         ,NULL                                                 -- ����
         ,NULL                                                 -- �������
         ,NULL                                                 -- �����z
         ,cv_0                                                 -- �p�����[�^�t���O
         ,lv_nodata_msg                                        -- 0�����b�Z�[�W
         ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error)
       OR (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt ;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_year_month IN  VARCHAR2,      --   1.�N��
    iv_in_kyoten  IN  VARCHAR2,      --   2.���ɋ��_
    iv_item_ctgr  IN  VARCHAR2,      --   3.�i�ڃJ�e�S��
    iv_output_dpt  IN  VARCHAR2      --   4.���[�o�͏ꏊ
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
       iv_year_month   --   1.�N��
      ,iv_in_kyoten    --   2.���ɋ��_
      ,iv_item_ctgr    --   3.�i�ڃJ�e�S��
      ,iv_output_dpt   --   4.���[�o�͏ꏊ
      ,lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --�G���[���b�Z�[�W
    );
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
END XXCOI009A03R;
/
