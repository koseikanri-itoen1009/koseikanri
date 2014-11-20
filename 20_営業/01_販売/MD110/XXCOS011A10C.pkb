create or replace PACKAGE BODY XXCOS011A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A10C (body)
 * Description      : ���ɗ\��f�[�^�̒��o���s��
 * MD.050           : ���ɗ\��f�[�^���o (MD050_COS_011_A10)
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0,A-1)
 *  get_req_order_data     �ړ��I�[�_�[��񒊏o (A-2)
 *  chk_edi_stc_data       ���ɗ\�葶�݃`�F�b�N (A-3)
 *  ins_edi_stc_line       ���ɗ\�薾�׍쐬 (A-4,A-5)
 *  ins_edi_stc_header     ���ɗ\��w�b�_�[�쐬 (A-5)
 *  chk_item_status        �i�ڃX�e�[�^�X�`�F�b�N (A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.0   K.Kiriu         �V�K�쐬
 *  2009/03/13    1.1   N.Maeda         �y��QNo.T1_0021�zMin-Max�v��ō쐬�̈ړ��I�[�_�[�f�[�^�Ή�
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
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  --���b�N�G���[
  no_target_expt EXCEPTION; --�����ΏۂȂ�
  item_chk_expt  EXCEPTION; --�ڋq�󒍉\�i�ڈȊO
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCOS011A10C'; -- �p�b�P�[�W��
--
  cv_application     CONSTANT VARCHAR2(5)   := 'XXCOS';        -- �A�v���P�[�V������
  -- �v���t�@�C��
  cv_prf_orga_code   CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:�݌ɑg�D�R�[�h
  cv_prf_case_uom    CONSTANT VARCHAR2(50)  := 'XXCOS1_CASE_UOM_CODE';      -- XXCOS:�P�[�X�P�ʃR�[�h
  cv_prf_ball_uom    CONSTANT VARCHAR2(50)  := 'XXCOS1_BALL_UOM_CODE';      -- XXCOS:�{�[���P�ʃR�[�h

  -- ���b�Z�[�W�R�[�h
  cv_msg_param       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12552';  -- �p�����[�^�[�o��
  cv_msg_param_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';  -- �p�����[�^�[�K�{�G���[
  cv_msg_prf_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- �v���t�@�C���擾�G���[
  cv_msg_orga_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12551';  -- �݌ɑg�DID�擾�G���[
  cv_msg_orga_tkn    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00048';  -- �݌ɑg�D�v���t�@�C����
  cv_msg_table_tkn1  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12553';  -- �ړ��I�[�_�[�w�b�_
  cv_msg_table_tkn2  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12554';  -- ���ɗ\��w�b�_
  cv_msg_table_tkn3  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12558';  -- ���ɗ\�薾��
  cv_msg_lock_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ���b�N�G���[
  cv_msg_no_target   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- �Ώۃf�[�^�Ȃ�
  cv_msg_uom_tkn1    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00057';  -- �P�[�X�P�ʃv���t�@�C����
  cv_msg_uom_tkn2    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00059';  -- �{�[���P�ʃv���t�@�C����
  cv_msg_param_tkn1  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12555';  -- ������ۊǏꏊ
  cv_msg_param_tkn2  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12556';  -- EDI�`�F�[���X�R�[�h
  cv_msg_param_tkn3  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12557';  -- �ړ��I�[�_�[�ԍ�
  cv_msg_ins_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';  -- �f�[�^�o�^�G���[
  cv_msg_del_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00012';  -- �f�[�^�폜�G���[
  cv_msg_cust_o_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12559';  -- �ڋq�󒍉\�i�ȊO�G���[
  -- �g�[�N���R�[�h
  cv_tkn_pram1       CONSTANT VARCHAR2(6)   := 'PARAM1';            -- �p�����[�^�[�P
  cv_tkn_pram2       CONSTANT VARCHAR2(6)   := 'PARAM2';            -- �p�����[�^�[�Q
  cv_tkn_pram3       CONSTANT VARCHAR2(6)   := 'PARAM3';            -- �p�����[�^�[�R
  cv_tkn_in_param    CONSTANT VARCHAR2(8)   := 'IN_PARAM';          -- �p�����[�^����
  cv_tkn_prf         CONSTANT VARCHAR2(7)   := 'PROFILE';           -- �v���t�@�C������
  cv_tkn_orga        CONSTANT VARCHAR2(8)   := 'ORG_CODE';          -- �݌ɑg�D�R�[�h
  cv_tkn_table       CONSTANT VARCHAR2(5)   := 'TABLE';             -- �e�[�u����
  cv_tkn_key         CONSTANT VARCHAR2(8)   := 'KEY_DATA';          -- �L�[�f�[�^
  cv_tkn_item        CONSTANT VARCHAR2(9)   := 'ITEM_CODE';         -- �i���R�[�h
  -- �f�[�^�擾�p�Œ�l
  cn_status_cancel   CONSTANT NUMBER        := 6;                   -- �ړ��I�[�_�[�X�e�[�^�X(���)
  cv_cust_status     CONSTANT VARCHAR2(2)   := '90';                -- �ڋq�X�e�[�^�X(���~���ٍ�)
  cv_cust_code_cust  CONSTANT VARCHAR2(2)   := '10';                -- �ڋq�敪(�ڋq)
  cv_cust_code_chain CONSTANT VARCHAR2(2)   := '18';                -- �ڋq�敪(�`�F�[���X)
  -- ���̑��Œ�l
  cn_0               CONSTANT NUMBER        := 0;                   -- �Œ�l:0
  cn_1               CONSTANT NUMBER        := 1;                   -- �Œ�l:1
  cv_n               CONSTANT VARCHAR2(1)   := 'N';                 -- �Œ�l:N
  cv_status          CONSTANT VARCHAR2(1)   := 'A';                 -- �ڋq�}�X�^�X�e�[�^�X
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_orga_id         NUMBER;      -- �݌ɑg�DID
  gv_case_uom_code   VARCHAR2(6); -- �P�[�X�P��
  gv_ball_uom_code   VARCHAR2(6); -- �{�[���P��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��RECORD�^�錾
  -- ===============================
  --�ړ��I�[�_�[�f�[�^���R�[�h�^
  TYPE g_req_order_data_rtype IS RECORD(
    header_id             mtl_txn_request_headers.header_id%TYPE,
    request_number        mtl_txn_request_headers.request_number%TYPE,
    to_subinventory_code  mtl_txn_request_headers.to_subinventory_code%TYPE,
    h_organization_id     mtl_txn_request_headers.organization_id%TYPE,
    account_number        hz_cust_accounts.account_number%TYPE,
    chain_store_code      xxcmm_cust_accounts.chain_store_code%TYPE,
    line_id               mtl_txn_request_lines.line_id%TYPE,
    line_number           mtl_txn_request_lines.line_number%TYPE,
    inventory_item_id     mtl_txn_request_lines.inventory_item_id%TYPE,
    l_organization_id     mtl_txn_request_lines.organization_id%TYPE,
    case_qty              xxcos_edi_stc_lines.case_qty%TYPE,
    indv_qty              xxcos_edi_stc_lines.indv_qty%TYPE
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  --�ړ��I�[�_�[�f�[�^ �e�[�u���^
  TYPE g_req_order_data_ttype IS TABLE OF g_req_order_data_rtype INDEX BY BINARY_INTEGER;
  gt_req_order_date  g_req_order_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0,A-1)
   ***********************************************************************************/
  PROCEDURE init(
    it_to_s_code        IN  mtl_txn_request_headers.to_subinventory_code%TYPE,  --   ������ۊǏꏊ
    it_edi_c_code       IN  xxcmm_cust_accounts.chain_store_code%TYPE,          --   EDI�`�F�[���X�R�[�h
    it_request_number   IN  mtl_txn_request_headers.request_number%TYPE,        --   �ړ��I�[�_�[�ԍ�
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_param_msg VARCHAR2(5000);  --�p�����[�^�[�o�͗p
    lv_err_msg   VARCHAR2(5000);  --�v���t�@�C���G���[�o�͗p(�v���t�@�C���͎擾�G���[���Ƃɏo�͂����)
    lv_orga_code VARCHAR2(10);    --�݌ɑg�D�R�[�h
    lv_tkn_name  VARCHAR2(50);    --�g�[�N���擾�p
    ln_err_chk   NUMBER(1);       --�v���t�@�C���G���[�`�F�b�N�p
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
    --�p�����[�^�[�̏o��
    --==============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���b�Z�[�W�擾
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --�A�v���P�[�V����
                     ,iv_name         => cv_msg_param       --�p�����[�^�[�o��
                     ,iv_token_name1  => cv_tkn_pram1       --�g�[�N���R�[�h�P
                     ,iv_token_value1 => it_to_s_code       --������ۊǏꏊ
                     ,iv_token_name2  => cv_tkn_pram2       --�g�[�N���R�[�h�Q
                     ,iv_token_value2 => it_edi_c_code      --EDI�`�F�[���X�R�[�h
                     ,iv_token_name3  => cv_tkn_pram3       --�g�[�N���R�[�h�R
                     ,iv_token_value3 => it_request_number  --�ړ��I�[�_�[�ԍ�
                    );
    --���b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_param_msg
    );
    --���O�ɏo��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==============================================================
    --�p�����[�^�[�̕K�{�`�F�b�N
    --==============================================================
    -- ������ۊǏꏊ
    IF ( it_to_s_code IS NULL ) THEN
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_param_tkn1  --������ۊǏꏊ
                     );
    -- EDI�`�F�[���X�R�[�h
    ELSIF ( it_edi_c_code IS NULL ) THEN
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_param_tkn2  --EDI�`�F�[���X�R�[�h
                     );
    -- �ړ��I�[�_�[�ԍ�
    ELSIF ( it_request_number IS NULL ) THEN
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_param_tkn3  --�ړ��I�[�_�[�ԍ�
                     );
    END IF;
    --���b�Z�[�W�ݒ�
    IF ( it_to_s_code IS NULL )
      OR ( it_edi_c_code IS NULL )
      OR ( it_request_number IS NULL )
    THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application   --�A�v���P�[�V����
                     ,iv_name         => cv_msg_param_err --�p�����[�^�[�K�{�G���[
                     ,iv_token_name1  => cv_tkn_in_param  --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_tkn_name      --�p�����[�^��
                   );
      RAISE global_api_others_expt;
    END IF;
    --==============================================================
    --�v���t�@�C���̎擾
    --==============================================================
    ln_err_chk       := 0;  --�G���[�`�F�b�N�p�ϐ��̏�����
    --�݌ɑg�D���̎擾
    lv_orga_code     := FND_PROFILE.VALUE( cv_prf_orga_code );  --�݌ɑg�D�R�[�h
    gv_case_uom_code := FND_PROFILE.VALUE( cv_prf_case_uom );   --�P�[�X�P��
    gv_ball_uom_code := FND_PROFILE.VALUE( cv_prf_ball_uom );   --�{�[���P��
--
    --�݌ɃR�[�h�擾�`�F�b�N
    IF ( lv_orga_code IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_orga_tkn    --�݌ɑg�D�R�[�h
                     );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application  --�A�v���P�[�V����
                     ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_tkn_name     --�v���t�@�C����
                   );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --�G���[�L��
    END IF;
    --�P�[�X�P�ʎ擾�`�F�b�N
    IF ( gv_case_uom_code IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_uom_tkn1    --�P�[�X�P�ʃv���t�@�C����
                     );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application --�A�v���P�[�V����
                     ,iv_name         => cv_msg_prf_err --�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_prf     --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_tkn_name    --�v���t�@�C����
                   );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --�G���[�L��
    END IF;
    --�擾�`�F�b�N
    IF ( gv_ball_uom_code IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_uom_tkn2    --�{�[���P�ʃv���t�@�C����
                     );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application --�A�v���P�[�V����
                     ,iv_name         => cv_msg_prf_err --�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_prf     --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_tkn_name    --�v���t�@�C����
                   );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --�G���[�L��
    END IF;
    --�v���t�@�C���擾�̂��Âꂩ�ŃG���[�̏ꍇ
    IF ( ln_err_chk = 1 ) THEN
      RAISE global_api_others_expt;
    END IF;
    --==============================================================
    --�݌ɑg�DID�̎擾
    --==============================================================
    gn_orga_id := xxcoi_common_pkg.get_organization_id( lv_orga_code );
    --�擾�`�F�b�N
    IF ( gn_orga_id  IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application   --�A�v���P�[�V����
                     ,iv_name         => cv_msg_orga_err  --�݌ɑg�DID�擾�G���[
                     ,iv_token_name1  => cv_tkn_orga      --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_orga_code     --�݌ɑg�D�R�[�h
                   );
      RAISE global_api_others_expt;
    END IF;
--
  EXCEPTION
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
   * Procedure Name   : get_req_order_data
   * Description      : �ړ��I�[�_�[��񒊏o(A-2)
   ***********************************************************************************/
  PROCEDURE get_req_order_data(
    it_to_s_code        IN  mtl_txn_request_headers.to_subinventory_code%TYPE,  --   ������ۊǏꏊ
    it_edi_c_code       IN  xxcmm_cust_accounts.chain_store_code%TYPE,          --   EDI�`�F�[���X�R�[�h
    it_request_number   IN  mtl_txn_request_headers.request_number%TYPE,        --   �ړ��I�[�_�[�ԍ�
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_req_order_data'; -- �v���O������
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
    lv_table_name  VARCHAR2(50);  --�e�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    --�ړ��I�[�_�[
    CURSOR req_order_cur
    IS
      SELECT  mtrh.header_id             header_id             --�ړ��I�[�_�[�w�b�_ID
             ,mtrh.request_number        request_number        --�ړ��I�[�_�[�ԍ�
             ,mtrh.to_subinventory_code  to_subinventory_code  --������ۊǏꏊ
             ,mtrh.organization_id       organization_id       --�g�DID
             ,hca2.account_number        account_number        --�ڋq�R�[�h
             ,hca2.chain_store_code      chain_store_code      --EDI�`�F�[���X�R�[�h
             ,mtrl.line_id               line_id               --�ړ��I�[�_�[����ID
             ,mtrl.line_number           line_number           --���׍sNo
             ,mtrl.inventory_item_id     inventory_item_id     --�i��ID
             ,mtrl.organization_id       organization_id       --�g�DID
             ,DECODE( mtrl.uom_code
                     ,gv_case_uom_code, mtrl.quantity      --�P�[�X�P�ʂ̏ꍇ�͐���
                     ,cn_0                                 --����ȊO��0
              )                          case_qty              --�P�[�X����
             ,DECODE( mtrl.uom_code
                     ,gv_case_uom_code, cn_0               --�P�[�X�P�ʂ̏ꍇ��0
                     ,gv_ball_uom_code, NVL(
                                              ( SELECT  xsib.bowl_inc_num
                                                FROM    mtl_system_items_b   msib
                                                       ,xxcmm_system_items_b xsib
                                                WHERE   xsib.item_code         = msib.segment1
                                                AND     msib.inventory_item_id = mtrl.inventory_item_id
                                                AND     msib.organization_id   = mtrl.organization_id
                                              )
                                             ,cn_1
                                           ) * mtrl.quantity  --�{�[���P�ʂ̏ꍇ�̓{�[������*����
                     ,mtrl.quantity                           --����ȊO�͐���
              )                          indv_qty              --�o������
      FROM    mtl_txn_request_headers mtrh  --�ړ��I�[�_�[�w�b�_
             ,mtl_txn_request_lines   mtrl  --�ړ��I�[�_�[����
             ,( SELECT  hca.account_number     account_number     --�ڋq�R�[�h
                       ,xca.ship_storage_code  ship_storage_code  --�o�׌��ۊǏꏊ(EDI)
                       ,xca.chain_store_code   chain_store_code   --�`�F�[���X�R�[�h(EDI)
                FROM    hz_cust_accounts    hca  --�ڋq
                       ,xxcmm_cust_accounts xca  --�ڋq�ǉ����
                       ,hz_parties          hp   --�p�[�e�B
                WHERE   hca.customer_class_code =  cv_cust_code_cust   --�ڋq�敪(�ڋq)
                AND     hca.status              =  cv_status           --�X�e�[�^�X(A)
                AND     hca.cust_account_id     =  xca.customer_id
                AND     xca.ship_storage_code   =  it_to_s_code
                AND     hca.party_id            =  hp.party_id
                AND     hp.duns_number_c        <> cv_cust_status      --�ڋq�X�e�[�^�X(���~���ٍψȊO)
              )                       hca1   --�ڋq
             ,( SELECT  xca.chain_store_code  chain_store_code    --�`�F�[���X�R�[�h(EDI)
                       ,hca.account_number    account_number      --�ڋq�R�[�h
                FROM    hz_cust_accounts    hca  --�ڋq
                       ,xxcmm_cust_accounts xca  --�ڋq�ǉ����
                WHERE   hca.customer_class_code =  cv_cust_code_chain  --�ڋq�敪(�`�F�[���X)
                AND     hca.cust_account_id     =  xca.customer_id
                AND     hca.status              =  cv_status           --�X�e�[�^�X(A)
              )                       hca2   --�ڋq(�`�F�[���X)
      WHERE   mtrl.line_status          <> cn_status_cancel        --���׃X�e�[�^�X(����ȊO)
      AND     mtrh.header_id            =  mtrl.header_id          --����(�ړ�H = �ړ�L)
      AND     hca1.chain_store_code     =  hca2.chain_store_code   --����(�ڋq = �`�F�[���X)
      AND     hca1.chain_store_code     =  it_edi_c_code           --EDI�`�F�[���X�R�[�h
      AND     mtrh.to_subinventory_code =  hca1.ship_storage_code  --����(�ړ�H = �ڋq)
      AND     NVL( mtrh.attribute1 , cv_n ) =  cv_n                    --EDI���M�ς݃t���O(�����M)
      AND     mtrh.header_status        <> cn_status_cancel        --�w�b�_�X�e�[�^�X(����ȊO)
      AND     mtrh.organization_id      =  gn_orga_id              --�g�DID
      AND     mtrh.to_subinventory_code =  it_to_s_code            --������ۊǏꏊ
      AND     mtrh.request_number       =  it_request_number       --�ړ��I�[�_�[�ԍ�
      AND     hca1.account_number =
               ( SELECT  MAX(hca.account_number)
                 FROM    hz_cust_accounts    hca  --�ڋq
                        ,xxcmm_cust_accounts xca  --�ڋq�ǉ����
                        ,hz_parties          hp   --�p�[�e�B
                 WHERE   hp.duns_number_c        <> cv_cust_status
                 AND     hca.party_id            =  hp.party_id
                 AND     hca.customer_class_code =  cv_cust_code_cust
                 AND     hca.status              =  cv_status
                 AND     xca.customer_id         =  hca.cust_account_id
                 AND     xca.ship_storage_code   =  mtrh.to_subinventory_code
                 AND     xca.chain_store_code    =  hca2.chain_store_code
               )    --�ڋq�������������1���ɍi��
      FOR UPDATE OF
        mtrh.header_id
       ,mtrl.line_id NOWAIT
      ;
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
    OPEN req_order_cur;
    FETCH req_order_cur BULK COLLECT INTO gt_req_order_date;
    --�Ώی����擾
    gn_target_cnt := req_order_cur%ROWCOUNT;
    CLOSE req_order_cur;
--
  EXCEPTION
--
    WHEN lock_expt THEN                           --*** ���b�N�G���[ ***
      --�J�[�\���N���[�Y
      IF ( req_order_cur%ISOPEN ) THEN
        CLOSE req_order_cur;
      END IF;
      --�g�[�N���擾
      lv_table_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     --�A�v���P�[�V����
                         ,iv_name         => cv_msg_table_tkn1  --�ړ��I�[�_�[�w�b�_
                       );
      --���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --�A�v���P�[�V����
                     ,iv_name         => cv_msg_lock_err    --���b�N�G���[
                     ,iv_token_name1  => cv_tkn_table       --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_table_name      --�ړ��I�[�_�[�w�b�_
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SQLERRM;
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
  END get_req_order_data;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_edi_stc_data
   * Description      : ���ɗ\�葶�݃`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_edi_stc_data(
    it_request_number    IN  mtl_txn_request_headers.request_number%TYPE,  --�ړ��I�[�_�[�ԍ�
    ot_edi_sts_header_id OUT xxcos_edi_stc_headers.header_id%TYPE,         --���ɗ\��w�b�_ID
    ov_errbuf            OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_edi_stc_data'; -- �v���O������
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
    ln_data_cnt    NUMBER;        --���o�����擾�p
    lv_table_name  VARCHAR2(50);  --�e�[�u����(�g�[�N���擾�p)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    --���ɗ\��
    CURSOR edi_sts_cur
    IS
      SELECT xesh.header_id  header_id
      FROM   xxcos_edi_stc_headers xesh
            ,xxcos_edi_stc_lines   xesl
      WHERE  xesh.move_order_num   = it_request_number
      AND    xesh.organization_id  = gn_orga_id
      AND    xesh.header_id        = xesl.header_id
      FOR UPDATE OF  xesh.header_id
                    ,xesl.line_id
      NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���ETABLE�^ ***
    TYPE g_edi_sts_data_ttype IS TABLE OF xxcos_edi_stc_headers.header_id%TYPE INDEX BY PLS_INTEGER;   -- ���b�N�p
    gt_edi_sts_data g_edi_sts_data_ttype;
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
    --������
    ln_data_cnt := 0;
    --���ɗ\��f�[�^���b�N
    OPEN edi_sts_cur;
    FETCH edi_sts_cur BULK COLLECT INTO gt_edi_sts_data;
    ln_data_cnt := edi_sts_cur%ROWCOUNT;
    CLOSE edi_sts_cur;
    --�f�[�^�̑��݃`�F�b�N
    IF ( ln_data_cnt <> 0 ) THEN
      --���ɗ\��w�b�_ID�Z�b�g
      ot_edi_sts_header_id := gt_edi_sts_data(1);
    END IF;
--
    --���ɗ\��f�[�^�����݂���ꍇ
    IF ( ot_edi_sts_header_id IS NOT NULL ) THEN
      BEGIN
        --���ɗ\�薾�ׂ̍폜
        DELETE FROM xxcos_edi_stc_lines xesl
        WHERE  xesl.header_id = ot_edi_sts_header_id
        ;
      EXCEPTION
      -- *** DELETE OTHERS��O ***
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     --�A�v���P�[�V����
                          ,iv_name         => cv_msg_table_tkn3  --���ɗ\�薾��
                         );
        --���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     --�A�v���P�[�V����
                      ,iv_name         => cv_msg_del_err     --�f�[�^�폜�G���['
                      ,iv_token_name1  => cv_tkn_table       --�g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_table_name      --���ɗ\�薾��
                      ,iv_token_name2  => cv_tkn_key         --�g�[�N���R�[�h�Q
                      ,iv_token_value2 => it_request_number  --�ړ��I�[�_�[�ԍ�
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;

    END IF;
--
  EXCEPTION
--
    WHEN lock_expt THEN                           --*** ���b�N�G���[ ***
      --�J�[�\���N���[�Y
      IF ( edi_sts_cur%ISOPEN ) THEN
        CLOSE edi_sts_cur;
      END IF;
      --�g�[�N���擾
      lv_table_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     --�A�v���P�[�V����
                         ,iv_name         => cv_msg_table_tkn2  --���ɗ\��w�b�_
                       );
      --���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --�A�v���P�[�V����
                     ,iv_name         => cv_msg_lock_err    --���b�N�G���[
                     ,iv_token_name1  => cv_tkn_table       --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_table_name      --���ɗ\��w�b�_
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SQLERRM;
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
  END chk_edi_stc_data;
--
--
  /**********************************************************************************
   * Procedure Name   : 
   
   * Description      : ���ɗ\�薾�׍쐬(A-4,A-5)
   ***********************************************************************************/
  PROCEDURE ins_edi_stc_line(
    it_edi_stc_line    IN  xxcos_edi_stc_lines%ROWTYPE,                  --1.���ɗ\�薾��
    it_request_number  IN  mtl_txn_request_headers.request_number%TYPE,  --2.�ړ��I�[�_�[�ԍ�
    ov_errbuf          OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_edi_stc_line'; -- �v���O������
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
    lv_tkn_name  VARCHAR2(50);    --�g�[�N���擾�p
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
    BEGIN
      --���ɗ\�薾�׃f�[�^�}������
      INSERT INTO xxcos_edi_stc_lines(
         line_id                 --����ID
        ,header_id               --�w�b�_ID
        ,move_order_line_id      --�ړ��I�[�_�[����ID
        ,move_order_header_id    --�ړ��I�[�_�[�w�b�_ID
        ,organization_id         --�g�DID
        ,inventory_item_id       --�i��ID
        ,case_qty                --�P�[�X��
        ,indv_qty                --�o����
        ,created_by              --�쐬��
        ,creation_date           --�쐬��
        ,last_updated_by         --�ŏI�X�V��
        ,last_update_date        --�ŏI�X�V��
        ,last_update_login       --�ŏI�X�V���O�C��
        ,request_id              --�v��ID
        ,program_application_id  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id              --�R���J�����g�E�v���O����ID
        ,program_update_date     --�v���O�����X�V��
      )VALUES(
         xxcos_edi_stc_lines_s01.NEXTVAL       --����ID
        ,it_edi_stc_line.header_id             --�w�b�_ID
        ,it_edi_stc_line.move_order_line_id    --�ړ��I�[�_�[����ID
        ,it_edi_stc_line.move_order_header_id  --�ړ��I�[�_�[�w�b�_ID
        ,it_edi_stc_line.organization_id       --�g�DID
        ,it_edi_stc_line.inventory_item_id     --�i��ID
        ,it_edi_stc_line.case_qty              --�P�[�X��
        ,it_edi_stc_line.indv_qty              --�o����
        ,cn_created_by                         --�쐬��
        ,cd_creation_date                      --�쐬��
        ,cn_last_updated_by                    --�ŏI�X�V��
        ,cd_last_update_date                   --�ŏI�X�V��
        ,cn_last_update_login                  --�ŏI�X�V���O�C��
        ,cn_request_id                         --�v��ID
        ,cn_program_application_id             --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id                         --�R���J�����g�E�v���O����ID
        ,cd_program_update_date                --�v���O�����X�V��
       );
--
      --���폈�������擾
      gn_normal_cnt := gn_normal_cnt + 1;
    EXCEPTION
      -- *** INESRT OTHERS��O ***
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_tkn_name := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --�A�v���P�[�V����
                        ,iv_name         => cv_msg_table_tkn3  --���ɗ\�薾��
                       );
        --���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     --�A�v���P�[�V����
                      ,iv_name         => cv_msg_ins_err     --�f�[�^�o�^�G���['
                      ,iv_token_name1  => cv_tkn_table       --�g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_name        --���ɗ\�薾��
                      ,iv_token_name2  => cv_tkn_key         --�g�[�N���R�[�h�Q
                      ,iv_token_value2 => it_request_number  --�ړ��I�[�_�[�ԍ�
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
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
  END ins_edi_stc_line;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_edi_stc_header
   * Description      : ���ɗ\��w�b�_�쐬(A-5)
   ***********************************************************************************/
  PROCEDURE ins_edi_stc_header(
    it_edi_stc_header IN  xxcos_edi_stc_headers%ROWTYPE,        --���ɗ\��w�b�_�[
    ot_header_id      OUT xxcos_edi_stc_headers.header_id%TYPE, --���ɗ\��w�b�_�[ID
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_edi_stc_header'; -- �v���O������
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
    lv_tkn_name  VARCHAR2(50);    --�g�[�N���擾�p
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
    -- �V�[�P���X�擾
    SELECT xxcos_edi_stc_headers_s01.NEXTVAL
    INTO   ot_header_id
    FROM   DUAL;
--
    BEGIN
      --���ɗ\��w�b�_�f�[�^�}������
      INSERT INTO xxcos_edi_stc_headers(
         header_id                    --�w�b�_ID
        ,move_order_header_id         --�ړ��I�[�_�[�w�b�_ID
        ,move_order_num               --�ړ��I�[�_�[�ԍ�
        ,to_subinventory_code         --������ۊǏꏊ
        ,customer_code                --�ڋq�R�[�h
        ,edi_chain_code               --EDI�`�F�[���X�R�[�h
        ,shop_code                    --�X�R�[�h
        ,center_code                  --�Z���^�[�R�[�h
        ,invoice_number               --�`�[�ԍ�
        ,other_party_department_code  --����敔��R�[�h
        ,schedule_shipping_date       --�o�ח\���
        ,schedule_arrival_date        --���ɗ\���
        ,rcpt_possible_date           --����\��
        ,inspect_schedule_date        --���i�\���
        ,invoice_class                --�`�[�敪
        ,classification_class         --���ދ敪
        ,whse_class                   --�q�ɋ敪
        ,regular_ar_sale_class        --��ԓ����敪
        ,opportunity_code             --�փR�[�h
        ,fix_flag                     --�m��t���O
        ,edi_send_date                --EDI���M����
        ,edi_send_flag                --EDI���M�ς݃t���O
        ,prev_edi_send_date           --�O��EDI���M����
        ,prev_edi_send_request_id     --�O��EDI���M�v��ID
        ,organization_id              --�g�DID
        ,created_by                   --�쐬��
        ,creation_date                --�쐬��
        ,last_updated_by              --�ŏI�X�V��
        ,last_update_date             --�ŏI�X�V��
        ,last_update_login            --�ŏI�X�V���O�C��
        ,request_id                   --�v��ID
        ,program_application_id       --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                   --�R���J�����g�E�v���O����ID
        ,program_update_date          --�v���O�����X�V��
      )VALUES(
         ot_header_id                                   --�w�b�_ID
        ,it_edi_stc_header.move_order_header_id         --�ړ��I�[�_�[�w�b�_ID
        ,it_edi_stc_header.move_order_num               --�ړ��I�[�_�[�ԍ�
        ,it_edi_stc_header.to_subinventory_code         --������ۊǏꏊ
        ,it_edi_stc_header.customer_code                --�ڋq�R�[�h
        ,it_edi_stc_header.edi_chain_code               --EDI�`�F�[���X�R�[�h
        ,it_edi_stc_header.shop_code                    --�X�R�[�h
        ,it_edi_stc_header.center_code                  --�Z���^�[�R�[�h
        ,it_edi_stc_header.invoice_number               --�`�[�ԍ�
        ,it_edi_stc_header.other_party_department_code  --����敔��R�[�h
        ,it_edi_stc_header.schedule_shipping_date       --�o�ח\���
        ,it_edi_stc_header.schedule_arrival_date        --���ɗ\���
        ,it_edi_stc_header.rcpt_possible_date           --����\��
        ,it_edi_stc_header.inspect_schedule_date        --���i�\���
        ,it_edi_stc_header.invoice_class                --�`�[�敪
        ,it_edi_stc_header.classification_class         --���ދ敪
        ,it_edi_stc_header.whse_class                   --�q�ɋ敪
        ,it_edi_stc_header.regular_ar_sale_class        --��ԓ����敪
        ,it_edi_stc_header.opportunity_code             --�փR�[�h
        ,it_edi_stc_header.fix_flag                     --�m��t���O
        ,it_edi_stc_header.edi_send_date                --EDI���M����
        ,it_edi_stc_header.edi_send_flag                --EDI���M�ς݃t���O
        ,it_edi_stc_header.prev_edi_send_date           --�O��EDI���M����
        ,it_edi_stc_header.prev_edi_send_request_id     --�O��EDI���M�v��ID
        ,it_edi_stc_header.organization_id              --�g�DID
        ,cn_created_by                                  --�쐬��
        ,cd_creation_date                               --�쐬��
        ,cn_last_updated_by                             --�ŏI�X�V��
        ,cd_last_update_date                            --�ŏI�X�V��
        ,cn_last_update_login                           --�ŏI�X�V���O�C��
        ,cn_request_id                                  --�v��ID
        ,cn_program_application_id                      --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id                                  --�R���J�����g�E�v���O����ID
        ,cd_program_update_date                         --�v���O�����X�V��
       );
    EXCEPTION
      -- *** INESRT OTHERS��O ***
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_tkn_name := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --�A�v���P�[�V����
                        ,iv_name         => cv_msg_table_tkn2  --���ɗ\��w�b�_
                       );
        --���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application                    --�A�v���P�[�V����
                      ,iv_name         => cv_msg_ins_err                    --�f�[�^�o�^�G���['
                      ,iv_token_name1  => cv_tkn_table                      --�g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_name                       --���ɗ\��w�b�_
                      ,iv_token_name2  => cv_tkn_key                        --�g�[�N���R�[�h�Q
                      ,iv_token_value2 => it_edi_stc_header.move_order_num  --�ړ��I�[�_�[�ԍ�
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
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
  END ins_edi_stc_header;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_item_status
   * Description      : �i�ڃX�e�[�^�X�`�F�b�N(A-7)
   ***********************************************************************************/
  PROCEDURE chk_item_status(
    it_inventory_item_id   IN  mtl_txn_request_lines.inventory_item_id%TYPE,  -- 1.�i��ID
    ov_chk_status          OUT VARCHAR2,                                      -- 2.�`�F�b�N�X�e�[�^�X
    ov_errbuf              OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item_status'; -- �v���O������
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
    lv_err_msg                  VARCHAR2(5000);                                       --���b�Z�[�W�o�͗p
    lt_cust_order_enabled_flag  mtl_system_items_b.customer_order_enabled_flag%TYPE;  --�ڋq�󒍉\�t���O
    lt_segment1                 mtl_system_items_b.segment1%TYPE;                     --�i���R�[�h
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
    ov_retcode    := cv_status_normal;
    ov_chk_status := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�ڋq�󒍉\�t���O�̎擾
    SELECT   msib.customer_order_enabled_flag  --�ڋq�󒍉\�t���O
            ,msib.segment1                     --�i���R�[�h
    INTO     lt_cust_order_enabled_flag
            ,lt_segment1
    FROM     mtl_system_items_b  msib
    WHERE    msib.inventory_item_id  = it_inventory_item_id
    AND      msib.organization_id    = gn_orga_id
    ;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --�ڋq�󒍉\�i�ȊO�̕i�ڂ̏ꍇ(�i�ڃX�e�[�^�X30��40�̂�Y�ƂȂ��Ă���)
    IF ( lt_cust_order_enabled_flag = cv_n ) THEN
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_cust_o_err  --�ڋq�󒍉\�i�ȊO�G���[
                       ,iv_token_name1  => cv_tkn_item        --�g�[�N���R�[�h�P
                       ,iv_token_value1 => lt_segment1        --�i���R�[�h
                      );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        --�`�F�b�N�X�e�[�^�X�ύX(�`�F�b�N�G���[)
        ov_chk_status := cv_status_error;
    END IF;
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
  END chk_item_status;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_to_s_code      IN  VARCHAR2,     --   1.������ۊǏꏊ
    iv_edi_c_code     IN  VARCHAR2,     --   2.EDI�`�F�[���X�R�[�h
    iv_request_number IN  VARCHAR2,     --   3.�ړ��I�[�_�[�ԍ�
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_no_target_msg      VARCHAR2(5000);                        --�ΏۂȂ����b�Z�[�W�擾�p
    lv_item_s_chk_retcode VARCHAR2(1);                           --�i�ڃX�e�[�^�X�`�F�b�N�̖߂�l�i�[�p
    lv_item_stauts_chk    VARCHAR2(1);                           --�i�ڃX�e�[�^�X�`�F�b�N�̏�������p
    lt_edi_stc_header_id  xxcos_edi_stc_headers.header_id%TYPE;  --���ɗ\��w�b�_ID�擾�p(�����p)
    lt_header_id          xxcos_edi_stc_headers.header_id%TYPE;  --���ɗ\��w�b�_ID�擾�p(�쐬�p)
--
    -- *** ���[�J���E���R�[�h ***
    lt_edi_stc_line       xxcos_edi_stc_lines%ROWTYPE;
    lt_edi_stc_header     xxcos_edi_stc_headers%ROWTYPE;
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
    -- ���[�J���ϐ��̏�����
    lv_item_stauts_chk := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-0,A-1)
    -- ===============================
    init(
      iv_to_s_code,      -- ������ۊǏꏊ
      iv_edi_c_code,     -- EDI�`�F�[���X�R�[�h
      iv_request_number, -- �ړ��I�[�_�[�ԍ�
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- �ړ��I�[�_�[��񒊏o(A-2)
    -- ===============================
    get_req_order_data(
      iv_to_s_code,      -- ������ۊǏꏊ
      iv_edi_c_code,     -- EDI�`�F�[���X�R�[�h
      iv_request_number, -- �ړ��I�[�_�[�ԍ�
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --�����Ώ۔���
    IF ( gn_target_cnt <> 0 ) THEN
--
      <<item_chk_loop>>
      FOR i IN 1.. gn_target_cnt  LOOP
        -- ===============================
        -- �i�ڃX�e�[�^�X�`�F�b�N(A-7)
        -- ===============================
        chk_item_status(
          gt_req_order_date(i).inventory_item_id,            --�i��ID(IN)
          lv_item_s_chk_retcode,                             --�i�ڃX�e�[�^�X(OUT)
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --�����Ώ۔���(��O)
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        --�����Ώ۔���(�i�ڃX�e�[�^�X)
        IF ( lv_item_s_chk_retcode <> cv_status_normal ) THEN
          lv_item_stauts_chk := cv_status_error;
        END IF;
      END LOOP item_chk_loop;
      --�����Ώ۔���(�i�ڃX�e�[�^�X)
      IF ( lv_item_stauts_chk <> cv_status_normal ) THEN
        --�ړ��I�[�_�[����1���ł��G���[������ꍇ
        RAISE item_chk_expt;
      END IF;
--
      <<req_order_loop>>
      FOR i IN 1.. gn_target_cnt  LOOP
        --�ŏ���1���̂�
        IF ( i = 1 ) THEN
          -- ===============================
          -- ���ɗ\�葶�݃`�F�b�N(A-3)
          -- ===============================
          chk_edi_stc_data(
            gt_req_order_date(i).request_number,  -- �ړ��I�[�_�[�ԍ�(IN)
            lt_edi_stc_header_id,                 -- ���ɗ\��w�b�_ID(OUT)
            lv_errbuf,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                           -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         IF (lv_retcode <> cv_status_normal) THEN
           RAISE global_process_expt;
         END IF;
        END IF;
--
        --���ɗ\�薾�׋��ʍ��ڕҏW
        lt_edi_stc_line.move_order_line_id   := gt_req_order_date(i).line_id;
        lt_edi_stc_line.move_order_header_id := gt_req_order_date(i).header_id;
        lt_edi_stc_line.organization_id      := gt_req_order_date(i).l_organization_id;
        lt_edi_stc_line.inventory_item_id    := gt_req_order_date(i).inventory_item_id;
        lt_edi_stc_line.case_qty             := gt_req_order_date(i).case_qty;
        lt_edi_stc_line.indv_qty             := gt_req_order_date(i).indv_qty;
--
        --���ɗ\��w�b�_�Ƀf�[�^������ꍇ
        IF ( lt_edi_stc_header_id IS NOT NULL ) THEN
          -- ===============================
          -- ���ɗ\��X�V(A-4)
          -- ===============================
          --���ɗ\�薾�׃f�[�^�ҏW
          lt_edi_stc_line.header_id := lt_edi_stc_header_id;
          --���ɗ\�薾�׍쐬
          ins_edi_stc_line(
            lt_edi_stc_line,                      -- ���ɗ\�薾��(IN)
            gt_req_order_date(i).request_number,  -- �ړ��I�[�_�[�ԍ�(IN)
            lv_errbuf,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                           -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        --���ɗ\��w�b�_�Ƀf�[�^���Ȃ��ꍇ
        ELSE
          -- ===============================
          -- ���ɗ\��o�^(A-5)
          -- ===============================
          --�ŏ���1���̂�
          IF ( i = 1 ) THEN
            --���ɗ\��w�b�_�f�[�^�ҏW
            lt_edi_stc_header.move_order_header_id        := gt_req_order_date(i).header_id;
            lt_edi_stc_header.move_order_num              := gt_req_order_date(i).request_number;
            lt_edi_stc_header.to_subinventory_code        := gt_req_order_date(i).to_subinventory_code;
            lt_edi_stc_header.customer_code               := gt_req_order_date(i).account_number;
            lt_edi_stc_header.edi_chain_code              := gt_req_order_date(i).chain_store_code;
            lt_edi_stc_header.shop_code                   := NULL;
            lt_edi_stc_header.center_code                 := NULL;
            lt_edi_stc_header.invoice_number              := NULL;
            lt_edi_stc_header.other_party_department_code := NULL;
            lt_edi_stc_header.schedule_shipping_date      := NULL;
            lt_edi_stc_header.schedule_arrival_date       := NULL;
            lt_edi_stc_header.rcpt_possible_date          := NULL;
            lt_edi_stc_header.inspect_schedule_date       := NULL;
            lt_edi_stc_header.invoice_class               := NULL;
            lt_edi_stc_header.classification_class        := NULL;
            lt_edi_stc_header.whse_class                  := NULL;
            lt_edi_stc_header.regular_ar_sale_class       := NULL;
            lt_edi_stc_header.opportunity_code            := NULL;
            lt_edi_stc_header.fix_flag                    := cv_n;
            lt_edi_stc_header.edi_send_date               := NULL;
            lt_edi_stc_header.edi_send_flag               := cv_n;
            lt_edi_stc_header.prev_edi_send_date          := NULL;
            lt_edi_stc_header.prev_edi_send_request_id    := NULL;
            lt_edi_stc_header.organization_id             := gt_req_order_date(i).h_organization_id;
            --���ɗ\��w�b�_�쐬
            ins_edi_stc_header(
              lt_edi_stc_header,  -- ���ɗ\��w�b�_(IN)
              lt_header_id,       -- �쐬�������ɗ\��w�b�_ID(OUT)
              lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          --���ɗ\�薾�׃f�[�^�ҏW
          lt_edi_stc_line.header_id := lt_header_id;
          --���ɗ\�薾�׍쐬
          ins_edi_stc_line(
            lt_edi_stc_line,                      -- ���ɗ\�薾��(IN)
            gt_req_order_date(i).request_number,  -- �ړ��I�[�_�[�ԍ�(IN)
            lv_errbuf,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                           -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END LOOP req_order_loop;
    --�����ΏۂȂ�
    ELSE
      --���b�Z�[�W�擾
      lv_no_target_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     --�A�v���P�[�V����
                           ,iv_name         => cv_msg_no_target   --�p�����[�^�[�o��(�����ΏۂȂ�)
                          );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_no_target_msg
      );
    END IF;
--
  EXCEPTION
    -- *** �󒍉\�i�ڈȊO�G���[ ****
    WHEN item_chk_expt THEN
      ov_retcode := cv_status_error;
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
    errbuf             OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode            OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_to_s_code       IN  VARCHAR2,      --   1.������ۊǏꏊ
    iv_edi_c_code      IN  VARCHAR2,      --   2.EDI�`�F�[���X�R�[�h
    iv_request_number  IN  VARCHAR2       --   3.�ړ��I�[�_�[�ԍ�
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
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_to_s_code       -- ������ۊǏꏊ
      ,iv_edi_c_code      -- EDI�`�F�[���X�R�[�h
      ,iv_request_number  -- �ړ��I�[�_�[�ԍ�
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
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
END XXCOS011A10C;
/