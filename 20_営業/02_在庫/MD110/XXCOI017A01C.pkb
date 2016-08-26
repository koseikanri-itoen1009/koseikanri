CREATE OR REPLACE PACKAGE BODY XXCOI017A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOI017A01C(body)
 * Description      : ���b�g�ʓ��o�ɏ������[�N�t���[�`���Ŕz�M���܂��B
 * MD.050           : ���b�g�ʓ��o�ɏ��z�M<MD050_COI_017_A01>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������                              (A-1)
 *  output_data            CSV�o�͏���                           (A-2)
 *  upd_lot_transactions   ���b�g�ʎ�����׍X�V����              (A-3)
 *  submain                ���C�������v���V�[�W��
 *                         �I������                              (A-4)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/08/03    1.0   S.Yamashita      �V�K�쐬
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
  cv_msg_sla                CONSTANT VARCHAR2(3) := '�^';
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
  --*** ���b�N�G���[ ***
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt,-54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI017A01C';              -- �p�b�P�[�W��
  -- �v���t�@�C��
  cv_organization_code  CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:�݌ɑg�D�R�[�h
  -- ���b�Z�[�W�֘A
  cv_app_xxcoi          CONSTANT VARCHAR2(30)  := 'XXCOI';                -- �A�v���P�[�V�����Z�k��(�݌�)
  cv_msg_xxcoi_00005    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-00005';     -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_00006    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-00006';     -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_10039    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10039';     -- ���b�N�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_10711    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10711';     -- ���b�g�ʓ��o�ɏ��z�M�R���J�����g���̓p�����[�^
  cv_msg_xxcoi_10712    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10712';     -- ���b�g�ʎ�����׃e�[�u���X�V�G���[
  cv_msg_xxcoi_10715    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10715';     -- ���t�t�]�G���[
  cv_msg_xxcoi_10716    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10716';     -- �z�M�Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  -- �g�[�N���p���b�Z�[�W
  cv_msg_xxcoi_10713    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10713';     -- �����(From)
  cv_msg_xxcoi_10714    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10714';     -- �����(To)
--
  --�g�[�N��
  cv_tkn_pro_tok         CONSTANT VARCHAR2(100) := 'PRO_TOK';            -- �v���t�@�C��
  cv_tkn_org_code_tok    CONSTANT VARCHAR2(100) := 'ORG_CODE_TOK';       -- �݌ɑg�D�R�[�h
  cv_tkn_p_base_code     CONSTANT VARCHAR2(100) := 'P_BASE_CODE';        -- ���̓p�����[�^�i���_�j
  cv_tkn_p_base_name     CONSTANT VARCHAR2(100) := 'P_BASE_NAME';        -- ���̓p�����[�^�i���_���j
  cv_tkn_p_trx_date_from CONSTANT VARCHAR2(100) := 'P_TRX_DATE_FROM';    -- ���̓p�����[�^�i�����(From)�j
  cv_tkn_p_trx_date_to   CONSTANT VARCHAR2(100) := 'P_TRX_DATE_TO';      -- ���̓p�����[�^�i�����(To)�j
  cv_tkn_item            CONSTANT VARCHAR2(100) := 'ITEM';               -- ���ږ�
  cv_tkn_err_msg         CONSTANT VARCHAR2(100) := 'ERR_MSG';            -- �G���[���e
  cv_tkn_date_from       CONSTANT VARCHAR2(100) := 'DATE_FROM';          -- ���t(From)
  cv_tkn_date_to         CONSTANT VARCHAR2(100) := 'DATE_TO';            -- ���t(To)
--
  -- �Q�ƃ^�C�v
  cv_xxcoi017a01_target_type CONSTANT VARCHAR2(100) := 'XXCOI1_XXCOI017A01_TARGET_TYPE'; -- �Q�ƃ^�C�v:���b�g�ʓ��o�ɏ��z�M_�Ώێ���^�C�v
  -- ����R�[�h
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  --�t�H�[�}�b�g
  cv_fmt_date           CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD';
  cv_fmt_datetime       CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';
  -- �ڋq�֘A
  cv_cust_cls_cd_base   CONSTANT VARCHAR2(1)   := '1';   -- �ڋq�敪:1(���_)
  -- ���̑�
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';   -- �t���O:'Y'
  cv_space              CONSTANT VARCHAR2(1)   := ' ';   -- ���p�X�y�[�X�P��
  cv_separate_code      CONSTANT VARCHAR2(1)   := ',';   -- ��؂蕶���i�J���}�j
  cv_sign_div_0         CONSTANT VARCHAR2(1)   := '0';   -- �����敪:0(�o��)
  cv_sign_div_1         CONSTANT VARCHAR2(1)   := '1';   -- �����敪:1(����)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_organization_code  mtl_parameters.organization_code%TYPE DEFAULT NULL;  -- �݌ɑg�D�R�[�h
  gt_organization_id    mtl_parameters.organization_id%TYPE   DEFAULT NULL;  -- �݌ɑg�DID
  TYPE upd_trx_id_ttype IS TABLE OF xxcoi_lot_transactions.transaction_id%TYPE INDEX BY PLS_INTEGER;
  g_upd_trx_id_tab      upd_trx_id_ttype;               -- ���b�g�ʎ������ID�e�[�u��
--
  -- ===============================
  -- �J�[�\����`
  -- ===============================
  -- ���b�g�ʓ��o�ɏ�񒊏o
  CURSOR g_tran_info_cur (
    iv_p_base_code      xxcoi_hht_inv_transactions.base_code%TYPE -- ���_�R�[�h
   ,id_p_trx_date_from  DATE -- �����(From)
   ,id_p_trx_date_to    DATE -- �����(To)
  )
  IS
    SELECT /*+ INDEX (xlt xxcoi_lot_transactions_n01) 
               LEADING (xlt) */
           xlt.transaction_id          AS transaction_id
          ,xlt.slip_num                AS slip_num
          ,TO_CHAR( xlt.transaction_date, cv_fmt_date ) AS transaction_date
          ,xlt.transaction_type_code   AS transaction_type_code
          ,CASE WHEN ( xlt.summary_qty < 0 ) THEN
             cv_sign_div_0  -- 0:�o��
           ELSE
             cv_sign_div_1  -- 1:����
           END                         AS conf_sign_div
          ,xlt.base_code               AS base_code
          ,xlt.subinventory_code       AS subinventory_code
          ,xlt.transfer_subinventory   AS transfer_subinventory
          ,msib.segment1               AS cild_item_code
          ,xlt.lot                     AS lot
          ,xlt.difference_summary_code AS difference_summary_code
          ,xlt.case_in_qty             AS case_in_qty
          ,xlt.case_qty                AS case_qty
          ,xlt.singly_qty              AS singly_qty
          ,xlt.summary_qty             AS summary_qty
          ,xlt.transaction_uom         AS transaction_uom
    FROM   xxcoi_lot_transactions     xlt   -- ���b�g�ʎ������
          ,mtl_secondary_inventories  msi   -- �ۊǏꏊ�}�X�^
          ,mtl_system_items_b         msib  -- DISC�i�ڃ}�X�^
          ,fnd_lookup_values          flv   -- �Q�ƃ^�C�v
    WHERE  xlt.child_item_id     = msib.inventory_item_id         -- �q�i��ID
    AND    xlt.organization_id   = gt_organization_id             -- �g�DID
    AND    xlt.organization_id   = msib.organization_id           -- �g�DID
    AND    xlt.organization_id   = msi.organization_id            -- �g�DID
    AND    xlt.subinventory_code = msi.secondary_inventory_name   -- �ۊǏꏊ
    AND    xlt.wf_delivery_flag  IS NULL                          -- WF�z�M�σt���O(���z�M)
    AND    flv.lookup_type       = cv_xxcoi017a01_target_type
    AND    flv.lookup_code       = xlt.transaction_type_code      -- �Ώێ���^�C�v
    AND    flv.language          = ct_lang                        -- ����
    AND    flv.enabled_flag      = cv_y                           -- �L���t���O
    AND    xlt.transaction_date  BETWEEN flv.start_date_active
                                   AND NVL(flv.end_date_active, xlt.transaction_date ) -- �L����
    AND    xlt.transaction_date  BETWEEN id_p_trx_date_from AND id_p_trx_date_to  -- �����
    AND    xlt.base_code         = iv_p_base_code                -- ���_
    AND    msi.attribute15       = cv_y                          -- WF�z�M�Ώۃt���O(�z�M�Ώ�)
    ORDER BY
           xlt.slip_num                ASC -- �`�[No
          ,xlt.subinventory_code       ASC -- �ۊǏꏊ�R�[�h
          ,conf_sign_div               ASC -- �����敪
          ,msib.segment1               ASC -- �q�i�ڃR�[�h
          ,xlt.lot                     ASC -- �ܖ�����
          ,xlt.difference_summary_code ASC -- �ŗL�L��
    FOR UPDATE OF
           xlt.transaction_id
    NOWAIT
  ;
  -- ���R�[�h�^
  g_tran_info_rec  g_tran_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code       IN  VARCHAR2  -- 1.���_
   ,id_trx_date_from   IN  DATE      -- 2.�����(From)
   ,id_trx_date_to     IN  DATE      -- 3.�����(To)
   ,ov_errbuf          OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lt_organization_code  mtl_parameters.organization_code%TYPE DEFAULT NULL;  -- �݌ɑg�D�R�[�h
    lt_base_name          hz_parties.party_name%TYPE            DEFAULT NULL;  -- ���_����
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
    -- ������
    lt_organization_code := NULL;
    lt_base_name         := NULL;
--
    --==================================
    -- �݌ɑg�DID�擾
    --==================================
--
    -- �݌ɑg�D�R�[�h�擾
    lt_organization_code := FND_PROFILE.VALUE( cv_organization_code );
--
    IF ( lt_organization_code IS NULL ) THEN
      -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_00005
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �݌ɑg�DID�擾
    gt_organization_id := xxcoi_common_pkg.get_organization_id( lt_organization_code );
--
    IF ( gt_organization_id IS NULL ) THEN
      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_00006
                     ,iv_token_name1  => cv_tkn_org_code_tok
                     ,iv_token_value1 => lt_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ���_���̎擾
    --==================================
    BEGIN
      SELECT hp.party_name AS base_name
      INTO   lt_base_name
      FROM   hz_parties       hp   -- �p�[�e�B
            ,hz_cust_accounts hca  -- �ڋq�}�X�^
      WHERE  hca.customer_class_code = cv_cust_cls_cd_base
      AND    hca.account_number      = iv_base_code
      AND    hp.party_id             = hca.party_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_base_name := NULL;
    END;
--
    --==================================
    -- �p�����[�^�o��
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application        => cv_app_xxcoi
                  ,iv_name               => cv_msg_xxcoi_10711
                  ,iv_token_name1        => cv_tkn_p_base_code
                  ,iv_token_value1       => iv_base_code
                  ,iv_token_name2        => cv_tkn_p_base_name
                  ,iv_token_value2       => lt_base_name
                  ,iv_token_name3        => cv_tkn_p_trx_date_from
                  ,iv_token_value3       => TO_CHAR( id_trx_date_from, cv_fmt_date )
                  ,iv_token_name4        => cv_tkn_p_trx_date_to
                  ,iv_token_value4       => TO_CHAR( id_trx_date_to, cv_fmt_date )
                 );
--
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_errmsg
    );
    --1�s��
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => NULL
    );
--
    --==================================
    -- ���t�t�]�`�F�b�N
    --==================================
    IF ( id_trx_date_from > id_trx_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_app_xxcoi
                    ,iv_name               => cv_msg_xxcoi_10715
                    ,iv_token_name1        => cv_tkn_date_from
                    ,iv_token_value1       => cv_msg_xxcoi_10713
                    ,iv_token_name2        => cv_tkn_date_to
                    ,iv_token_value2       => cv_msg_xxcoi_10714
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
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
   * Procedure Name   : output_data
   * Description      : CSV�o�͏��� (A-2)
   ***********************************************************************************/
  PROCEDURE output_data(
    iv_base_code       IN  VARCHAR2  -- 1.���_
   ,id_trx_date_from   IN  VARCHAR2  -- 2.�����(From)
   ,id_trx_date_to     IN  VARCHAR2  -- 3.�����(To)
   ,ov_errbuf          OUT VARCHAR2  -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT VARCHAR2  -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
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
    -- WF�֘A
    cv_ope_div_13         CONSTANT VARCHAR2(2)   := '13';  -- �����敪:13(���b�g�ʓ��o�ɏ��)
    cv_wf_class_8         CONSTANT VARCHAR2(1)   := '8';   -- �Ώ�:8(���_)
    -- IF����
    cv_coop_name_itoen    CONSTANT VARCHAR2(5)   := 'ITOEN'; -- ��Ж�:ITOEN
    cv_data_type_600      CONSTANT VARCHAR2(3)   := '600';   -- �f�[�^���:600(�o��)
    cv_data_type_610      CONSTANT VARCHAR2(3)   := '610';   -- �f�[�^���:610(����)
    cv_branch_no_10       CONSTANT VARCHAR2(2)   := '10';    -- �`���p�}��:10(�w�b�_)
    cv_branch_no_20       CONSTANT VARCHAR2(2)   := '20';    -- �`���p�}��:20(����)
    cv_data_kbn_0         CONSTANT VARCHAR2(1)   := '0';     -- �f�[�^�敪:0(�ǉ�)
--
    -- *** ���[�J���ϐ� ***
    lr_wf_whs_rec        xxwsh_common3_pkg.wf_whs_rec; -- �t�@�C�����i�[���R�[�h
    lf_file_hand         UTL_FILE.FILE_TYPE;           -- �t�@�C���E�n���h��
    lv_wf_notification   VARCHAR2(100);  -- ����
    lv_file_name         VARCHAR2(150);  -- �t�@�C����
    lv_csv_data          VARCHAR2(4000); -- CSV������
    lv_data_type         VARCHAR2(3);    -- �f�[�^���
    lt_prev_slip_num     xxcoi_lot_transactions.slip_num%TYPE;          -- �O���R�[�h�̓`�[�ԍ�
    lt_subinventory_code xxcoi_lot_transactions.subinventory_code%TYPE; -- �O���R�[�h�̕ۊǏꏊ�R�[�h
    lt_sign_div          xxcoi_lot_transactions.sign_div%TYPE;          -- �O���R�[�h�̕����敪
    ln_loop_cnt          NUMBER;         -- ���[�v�J�E���g
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    lv_csv_data          := NULL;
    lt_prev_slip_num     := NULL;
    lt_subinventory_code := NULL;
    lt_sign_div          := NULL;
    ln_loop_cnt          := 0;
--
    --==================================
    -- ���[�N�t���[���擾
    --==================================
    lv_wf_notification := iv_base_code;        -- ����:�Ώۋ��_
--
    -- ���ʊ֐��u�A�E�g�o�E���h�����擾�֐��v�ďo
    xxwsh_common3_pkg.get_wsh_wf_info(
      iv_wf_ope_div       => cv_ope_div_13        -- �����敪
     ,iv_wf_class         => cv_wf_class_8        -- �Ώ�:'8'(���_(���b�g�ʓ��o�ɏ��z�M))
     ,iv_wf_notification  => lv_wf_notification   -- ����
     ,or_wf_whs_rec       => lr_wf_whs_rec        -- �t�@�C�����
     ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W
     ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h
     ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF
     ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �t�@�C�����ҏW
    --==================================
    lv_file_name := cv_ope_div_13                                     -- �����敪
                    || '-' || lv_wf_notification                      -- ����
                    || '_' || TO_CHAR( SYSDATE, 'YYYYMMDDHH24MISS' )  -- ��������
                    || lr_wf_whs_rec.file_name                        -- �t�@�C����
    ;
--
    -- WF�I�[�i�[���N�����[�U�֕ύX
    lr_wf_whs_rec.wf_owner := fnd_global.user_name;
--
    --==================================
    -- �t�@�C���I�[�v��
    --==================================
    lf_file_hand := UTL_FILE.FOPEN( lr_wf_whs_rec.directory -- �f�B���N�g��
                                   ,lv_file_name            -- �t�@�C����
                                   ,'w' )                   -- ���[�h�i�㏑�j
    ;
--
    --==================================
    -- ���b�g�ʓ��o�ɏ�񒊏o
    --==================================
    <<tran_info_loop>>
    FOR g_tran_info_rec IN g_tran_info_cur ( iv_p_base_code     => iv_base_code      -- ���_�R�[�h
                                            ,id_p_trx_date_from => id_trx_date_from  -- �����(From)
                                            ,id_p_trx_date_to   => id_trx_date_to    -- �����(To)
                                           )
    LOOP
      -- �I������
      EXIT tran_info_loop WHEN g_tran_info_cur%NOTFOUND;
--
      --==================================
      -- ���b�g�ʓ��o�ɏ�� CSV�o��
      --==================================
--
      -- �f�[�^��ʂ̐ݒ�
      IF ( g_tran_info_rec.conf_sign_div = cv_sign_div_0 ) THEN
        -- �o��
        lv_data_type := cv_data_type_600;
        -- ���ʂ��v���X�ɕϊ�
        g_tran_info_rec.case_qty    := g_tran_info_rec.case_qty    * (-1);
        g_tran_info_rec.singly_qty  := g_tran_info_rec.singly_qty  * (-1);
        g_tran_info_rec.summary_qty := g_tran_info_rec.summary_qty * (-1);
      ELSE
        -- ����
        lv_data_type := cv_data_type_610;
      END IF;
--
      -- 1���R�[�h�ڂ̏ꍇ�A
      -- �܂��͑O���R�[�h�ƃL�[���ځi�`�[No�A�ۊǏꏊ�R�[�h�A�����敪�j���قȂ�ꍇ�A
      -- �܂��͓`�[No��NULL(�݌ɒ���)�̏ꍇ
      IF (( lt_prev_slip_num IS NULL )
        OR ( g_tran_info_rec.slip_num          <> lt_prev_slip_num )
        OR ( g_tran_info_rec.subinventory_code <> lt_subinventory_code )
        OR ( g_tran_info_rec.conf_sign_div     <> lt_sign_div )
        OR ( g_tran_info_rec.slip_num IS NULL ))
      THEN
        -- �w�b�_�s
        lv_csv_data := cv_coop_name_itoen                    -- ��Ж�
                    || cv_separate_code
                    || lv_data_type                          -- �f�[�^���
                    || cv_separate_code
                    || cv_branch_no_10                       -- �`���p�}��
                    || cv_separate_code
                    || g_tran_info_rec.slip_num              -- �`�[No
                    || cv_separate_code
                    || g_tran_info_rec.transaction_date      -- �����
                    || cv_separate_code
                    || g_tran_info_rec.transaction_type_code -- ����^�C�v�R�[�h
                    || cv_separate_code
                    || g_tran_info_rec.conf_sign_div         -- �����敪
                    || cv_separate_code
                    || g_tran_info_rec.base_code             -- ���_�R�[�h
                    || cv_separate_code
                    || g_tran_info_rec.subinventory_code     -- �ۊǏꏊ�R�[�h
                    || cv_separate_code
                    || g_tran_info_rec.transfer_subinventory -- �]����ۊǏꏊ�R�[�h
                    || cv_separate_code
                    || '' -- �q�i�ڃR�[�h
                    || cv_separate_code
                    || '' -- �ܖ�����
                    || cv_separate_code
                    || '' -- �ŗL�L��
                    || cv_separate_code
                    || '' -- ����
                    || cv_separate_code
                    || '' -- �P�[�X��
                    || cv_separate_code
                    || '' -- �o����
                    || cv_separate_code
                    || '' -- �������
                    || cv_separate_code
                    || '' -- ��P��
                    || cv_separate_code
                    || '' -- �f�[�^�敪
                    || cv_separate_code
                    || TO_CHAR( SYSDATE, cv_fmt_datetime )   -- �X�V����
        ;
--
        -- �t�@�C���o��
        UTL_FILE.PUT_LINE(
          lf_file_hand
         ,lv_csv_data
        );
--
      END IF;
--
      -- ���׍s
      lv_csv_data := cv_coop_name_itoen                    -- ��Ж�
                  || cv_separate_code
                  || lv_data_type                          -- �f�[�^���
                  || cv_separate_code
                  || cv_branch_no_20                       -- �`���p�}��
                  || cv_separate_code
                  || g_tran_info_rec.slip_num              -- �`�[No
                  || cv_separate_code
                  || '' -- �����
                  || cv_separate_code
                  || '' -- ����^�C�v�R�[�h
                  || cv_separate_code
                  || '' -- �����敪
                  || cv_separate_code
                  || '' -- ���_�R�[�h
                  || cv_separate_code
                  || '' -- �ۊǏꏊ�R�[�h
                  || cv_separate_code
                  || '' -- �]����ۊǏꏊ�R�[�h
                  || cv_separate_code
                  || g_tran_info_rec.cild_item_code          -- �q�i�ڃR�[�h
                  || cv_separate_code
                  || g_tran_info_rec.lot                     -- �ܖ�����
                  || cv_separate_code
                  || g_tran_info_rec.difference_summary_code -- �ŗL�L��
                  || cv_separate_code
                  || g_tran_info_rec.case_in_qty             -- ����
                  || cv_separate_code
                  || g_tran_info_rec.case_qty                -- �P�[�X��
                  || cv_separate_code
                  || g_tran_info_rec.singly_qty              -- �o����
                  || cv_separate_code
                  || g_tran_info_rec.summary_qty             -- �������
                  || cv_separate_code
                  || g_tran_info_rec.transaction_uom         -- ��P��
                  || cv_separate_code
                  || cv_data_kbn_0                           -- �f�[�^�敪
                  || cv_separate_code
                  || TO_CHAR( SYSDATE, cv_fmt_datetime )     -- �X�V����
      ;
--
      -- �t�@�C���o��
      UTL_FILE.PUT_LINE(
        lf_file_hand
       ,lv_csv_data
      );
--
      -- �L�[���ڂ�ێ�
      lt_prev_slip_num     := g_tran_info_rec.slip_num;
      lt_subinventory_code := g_tran_info_rec.subinventory_code;
      lt_sign_div          := g_tran_info_rec.conf_sign_div;
      -- ���ID��ێ�(�t���O�X�V�p)
      g_upd_trx_id_tab(ln_loop_cnt)  := g_tran_info_rec.transaction_id;
--
      -- �����J�E���g
      ln_loop_cnt := ln_loop_cnt + 1;
--
    END LOOP tran_info_loop;
--
    -- �Ώی����J�E���g
    gn_target_cnt := ln_loop_cnt;
--
    --==================================
    -- �t�@�C���N���[�Y
    --==================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- �Ώی��������݂���ꍇ�̓��[�N�t���[�ʒm�����s
    IF ( gn_target_cnt <> 0 ) THEN
      --==================================
      -- ���[�N�t���[�ʒm
      --==================================
      xxwsh_common3_pkg.wf_whs_start(
        ir_wf_whs_rec => lr_wf_whs_rec      -- ���[�N�t���[�֘A���
       ,iv_filename   => lv_file_name       -- �t�@�C����
       ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF ;
    ELSE
      -- �Ώی�����0���̏ꍇ�͌x��
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_10716
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** ���b�N��O�n���h�� ***--
    WHEN global_lock_expt THEN
      -- �t�@�C���N���[�Y
      UTL_FILE.FCLOSE( lf_file_hand );
      -- ���b�Z�[�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_10039
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   #######################################
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_lot_transactions
   * Description      : ���b�g�ʎ�����׍X�V (A-3)
   ***********************************************************************************/
  PROCEDURE upd_lot_transactions(
    ov_errbuf          OUT VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    --==================================
    -- ���b�g�ʎ�����׍X�V
    --==================================
    << update_loop >>
    FOR i IN 0 .. g_upd_trx_id_tab.COUNT -1 LOOP
      BEGIN
        UPDATE  xxcoi_lot_transactions xlt
        SET     xlt.wf_delivery_flag          =   cv_y --WF�z�M�σt���O(�z�M��)
               ,xlt.last_update_date          =   cd_last_update_date
               ,xlt.last_updated_by           =   cn_last_updated_by
               ,xlt.last_update_login         =   cn_last_update_login
               ,xlt.request_id                =   cn_request_id
               ,xlt.program_id                =   cn_program_id
               ,xlt.program_application_id    =   cn_program_application_id
               ,xlt.program_update_date       =   cd_last_update_date
        WHERE   xlt.transaction_id  =  g_upd_trx_id_tab(i)
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- ���b�g�ʎ�����׍X�V�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_xxcoi
                 ,iv_name         => cv_msg_xxcoi_10712
                 ,iv_token_name1  => cv_tkn_err_msg
                 ,iv_token_value1 => SQLERRM
               );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END LOOP update_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_lot_transactions;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   *                    �I������ (A-3)
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code       IN  VARCHAR2    -- 1.���_
   ,id_trx_date_from   IN  DATE        -- 2.�����(From)
   ,id_trx_date_to     IN  DATE        -- 3.�����(To)
   ,ov_errbuf          OUT VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    --  ��������(A-1)
    -- ===============================
    init(
      iv_base_code      =>  iv_base_code      -- 1.���_
     ,id_trx_date_from  =>  id_trx_date_from  -- 2.�����(From)
     ,id_trx_date_to    =>  id_trx_date_to    -- 3.�����(To)
     ,ov_errbuf         =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- CSV�o�͏���(A-2)
    --==================================
    output_data(
      iv_base_code          =>  iv_base_code      -- 1.���_
     ,id_trx_date_from      =>  id_trx_date_from  -- 2.�����(From)
     ,id_trx_date_to        =>  id_trx_date_to    -- 3.�����(To)
     ,ov_errbuf             =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�̏ꍇ
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      -- �x��(�z�M�Ώۃf�[�^�Ȃ�)�̏ꍇ
      ov_retcode := lv_retcode;
    ELSE
      -- ����̏ꍇ
      --==================================
      -- ���b�g�ʎ�����׍X�V����(A-3)
      --==================================
      upd_lot_transactions(
        ov_errbuf             =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
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
    errbuf                OUT VARCHAR2    -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode               OUT VARCHAR2    -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_base_code          IN  VARCHAR2    -- 1.���_
   ,iv_trx_date_from      IN  VARCHAR2    -- 2.�����(From)
   ,iv_trx_date_to        IN  VARCHAR2    -- 3.�����(To)
   
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
       ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
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
        iv_base_code       =>  iv_base_code      -- 1.���_
       ,id_trx_date_from   =>  TO_DATE(iv_trx_date_from, cv_fmt_datetime ) -- 2.�����(From)
       ,id_trx_date_to     =>  TO_DATE(iv_trx_date_to, cv_fmt_datetime )   -- 3.�����(To)
       ,ov_errbuf          =>  lv_errbuf         -- �G���[�E���b�Z�[�W             --# �Œ� #
       ,ov_retcode         =>  lv_retcode        -- ���^�[���E�R�[�h               --# �Œ� #
       ,ov_errmsg          =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- ��������(�G���[)
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      -- ��������(�x��)
      gn_normal_cnt := 0;
      gn_error_cnt  := 0;
    ELSE
      -- ��������(����)
      gn_normal_cnt := gn_target_cnt;
    END IF;
    --
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
    -- ��s���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
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
END XXCOI017A01C;
/
