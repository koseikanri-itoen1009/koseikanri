CREATE OR REPLACE PACKAGE BODY XXCOI002A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI002A02C(body)
 * Description      : �q�ց^�ԕi���̒��o
 * MD.050           : �q�ց^�ԕi���̒��o MD050_COI_002_A02
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_slip_num           �`�[No�擾���� (A-2)
 *  get_kuragae_henpin     �q�ց^�ԕi��񒊏o���� (A-4)
 *  chk_base_code          ���͋��_���݃`�F�b�N���� (A-5)
 *  ins_if_table           �q�֕ԕi�C���^�[�t�F�[�X���e�[�u���f�[�^�o�^���� (A-6)
 *  upd_flag               �H��q�֕ԕi�A�g�t���O�X�V���� (A-7)
 *  submain                ���C�������v���V�[�W��
 *                         �Z�[�u�|�C���g�쐬���� (A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/30    1.0   K.Nakamura       �V�K�쐬
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt                    EXCEPTION; -- ���b�N�擾�G���[
  no_base_code_expt            EXCEPTION; -- ���͋��_���݃G���[
  no_data_expt                 EXCEPTION; -- �擾����0����O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ���b�N�擾��O
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(15)  := 'XXCOI002A02C'; -- �p�b�P�[�W��
  cv_appl_short_name           CONSTANT VARCHAR2(10)  := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_application_short_name    CONSTANT VARCHAR2(10)  := 'XXCOI';        -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W
  cv_no_para_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_org_code_get_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_org_id_get_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_no_data_msg               CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- �Ώۃf�[�^�������b�Z�[�W
  cv_lookup_code_get_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00022'; -- ����^�C�v���擾�G���[���b�Z�[�W
  cv_tran_type_get_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10256'; -- ����^�C�vID�擾�G���[���b�Z�[�W
  cv_no_base_code_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10050'; -- ���͋��_���݃`�F�b�N�G���[���b�Z�[�W
  cv_table_lock_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10054'; -- ���b�N�擾�G���[���b�Z�[�W�i���ގ���e�[�u���j
--
  -- �g�[�N��
  cv_tkn_pro                   CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- �v���t�@�C����
  cv_tkn_org_code              CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- �݌ɑg�D�R�[�h
  cv_tkn_lookup_type           CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';          -- �Q�ƃ^�C�v
  cv_tkn_lookup_code           CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';          -- �Q�ƃR�[�h
  cv_tkn_tran_type             CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- ����^�C�v
  cv_tkn_base_code             CONSTANT VARCHAR2(20)  := 'BASE_CODE1';           -- ���͋��_�R�[�h
  cv_tkn_den_no                CONSTANT VARCHAR2(20)  := 'DEN_NO';               -- �`�[No
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �`�[No��񃌃R�[�h�i�[�p
  TYPE gt_slip_num_ttype IS TABLE OF mtl_material_transactions.transaction_set_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- �q�֕ԕi��񃌃R�[�h�i�[�p
  TYPE gr_kuragae_henpin_rec IS RECORD(
      mmt_transaction_set_id            mtl_material_transactions.transaction_set_id%TYPE   -- �`�[No
    , mmt_transaction_date              mtl_material_transactions.transaction_date%TYPE     -- �����
    , mmt_attribute2                    mtl_material_transactions.attribute2%TYPE           -- �o�בq�ɃR�[�h
    , mmt_attribute3                    mtl_material_transactions.attribute3%TYPE           -- �q�R�[�h
    , mmt_transaction_quantity          mtl_material_transactions.transaction_quantity%TYPE -- �������
    , mtt_attribute1                    mtl_transaction_types.attribute1%TYPE               -- �H��q�֕ԕi���
    , mtt_attribute2                    mtl_transaction_types.attribute2%TYPE               -- ���Y�����`�[���
    , msi_attribute7                    mtl_secondary_inventories.attribute7%TYPE           -- ���͋��_�R�[�h
    , msib_segment1                     mtl_system_items_b.segment1%TYPE                    -- �i�ڃR�[�h
    , iim_attribute                     VARCHAR2(240)                                       -- �Q�R�[�h
    , mmt_rowid                         rowid                                               -- ROWID
  );
  TYPE gt_kuragae_henpin_ttype IS TABLE OF gr_kuragae_henpin_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_org_id                             mtl_parameters.organization_id%TYPE;            -- �݌ɑg�DID
  gt_tran_type_factory_change           mtl_transaction_types.transaction_type_id%TYPE; -- ����^�C�vID �H��q��
  gt_tran_type_factory_change_b         mtl_transaction_types.transaction_type_id%TYPE; -- ����^�C�vID �H��q�֐U��
  gt_tran_type_factory_return           mtl_transaction_types.transaction_type_id%TYPE; -- ����^�C�vID �H��ԕi
  gt_tran_type_factory_return_b         mtl_transaction_types.transaction_type_id%TYPE; -- ����^�C�vID �H��ԕi�U��
  -- �J�E���^
  gn_slip_loop_cnt                      NUMBER; -- �`�[No���[�v�J�E���^
  gn_kuragae_henpin_loop_cnt            NUMBER; -- �q�֕ԕi��񃋁[�v�J�E���^
  gn_kuragae_henpin_cnt                 NUMBER; -- �q�֕ԕi��񌏐�
  gn_kuragae_henpin_all_cnt             NUMBER; -- �q�֕ԕi��񑍌���
  -- PL/SQL�\
  gt_slip_num_tab                       gt_slip_num_ttype;
  gt_kuragae_henpin_tab                 gt_kuragae_henpin_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �v���t�@�C�� �݌ɑg�D�R�[�h
    cv_prf_org_code                     CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
    -- �Q�ƃ^�C�v ���[�U�[��`����^�C�v����
    cv_tran_type                        CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME';
    -- �Q�ƃR�[�h
    cv_tran_type_factory_change         CONSTANT VARCHAR2(3)  := '110'; -- ����^�C�v �R�[�h �H��q��
    cv_tran_type_factory_change_b       CONSTANT VARCHAR2(3)  := '120'; -- ����^�C�v �R�[�h �H��q�֐U��
    cv_tran_type_factory_return         CONSTANT VARCHAR2(3)  := '90';  -- ����^�C�v �R�[�h �H��ԕi
    cv_tran_type_factory_return_b       CONSTANT VARCHAR2(3)  := '100'; -- ����^�C�v �R�[�h �H��ԕi�U��
--
    -- *** ���[�J���ϐ� ***
    lt_org_code                         mtl_parameters.organization_code%TYPE;            -- �݌ɑg�D�R�[�h
    lt_tran_type_factory_change         mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �H��q��
    lt_tran_type_factory_change_b       mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �H��q�֐U��
    lt_tran_type_factory_return         mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �H��ԕi
    lt_tran_type_factory_return_b       mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �H��ԕi�U��
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
    --==============================================================
    -- �R���J�����g���̓p�����[�^�Ȃ����O�o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => cv_no_para_msg
                  );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- ===============================
    -- �v���t�@�C���擾�F�݌ɑg�D�R�[�h
    -- ===============================
    lt_org_code := fnd_profile.value( cv_prf_org_code );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_code_get_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �݌ɑg�DID�擾
    -- ===============================
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_code );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_id_get_err_msg
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => lt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i�H��q�ցj
    -- ===============================
    lt_tran_type_factory_change := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_change );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_factory_change IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_lookup_code_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_change
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i�H��q�ցj
    -- ===============================
    gt_tran_type_factory_change := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_change );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_factory_change IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_change
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i�H��q�֐U�߁j
    -- ===============================
    lt_tran_type_factory_change_b := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_change_b );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_factory_change_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_lookup_code_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_change_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i�H��q�֐U�߁j
    -- ===============================
    gt_tran_type_factory_change_b := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_change_b );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_factory_change_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_change_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i�H��ԕi�j
    -- ===============================
    lt_tran_type_factory_return := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_return );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_factory_return IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_lookup_code_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_return
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i�H��ԕi�j
    -- ===============================
    gt_tran_type_factory_return := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_return );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_factory_return IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_return
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i�H��q�ԕi�U�߁j
    -- ===============================
    lt_tran_type_factory_return_b := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_return_b );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_factory_return_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_lookup_code_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_return_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i�H��q�ԕi�U�߁j
    -- ===============================
    gt_tran_type_factory_return_b := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_return_b );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_factory_return_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_return_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_slip_num
   * Description      : �`�[No�擾���� (A-2)
   ***********************************************************************************/
  PROCEDURE get_slip_num(
    ov_errbuf     OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_slip_num'; -- �v���O������
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
    -- �`�[No�擾
    CURSOR info_slip_cur
    IS
      SELECT DISTINCT mmt.transaction_set_id AS transaction_set_id        -- ����Z�b�gID(�`�[No)
      FROM   mtl_material_transactions       mmt                          -- ���ގ���e�[�u��
      WHERE  mmt.transaction_type_id IN ( gt_tran_type_factory_change     -- ����^�C�vID �H��q��
                                        , gt_tran_type_factory_change_b   -- ����^�C�vID �H��q��
                                        , gt_tran_type_factory_return     -- ����^�C�vID �H��ԕi
                                        , gt_tran_type_factory_return_b ) -- ����^�C�vID �H��ԕi�U��
      AND    mmt.attribute4          IS NULL                              -- �H��q�֕ԕi�A�g�t���O
      ORDER BY mmt.transaction_set_id
    ;
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
    -- �J�[�\���I�[�v��
    OPEN info_slip_cur;
--
    -- ���R�[�h�ǂݍ���
    FETCH info_slip_cur BULK COLLECT INTO gt_slip_num_tab;
--
    -- �`�[No(�Ώی���)�Z�b�g
    gn_target_cnt := gt_slip_num_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE info_slip_cur;
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
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_slip_cur%ISOPEN ) THEN
        CLOSE info_slip_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_slip_cur%ISOPEN ) THEN
        CLOSE info_slip_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_slip_cur%ISOPEN ) THEN
        CLOSE info_slip_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_slip_num;
--
  /**********************************************************************************
   * Procedure Name   : get_kuragae_henpin
   * Description      : �q�ց^�ԕi��񒊏o���� (A-4)
   ***********************************************************************************/
  PROCEDURE get_kuragae_henpin(
    gn_slip_loop_cnt IN   NUMBER,    -- �`�[No���[�v�J�E���^
    ov_errbuf        OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_kuragae_henpin'; -- �v���O������
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
    -- �q�֕ԕi��񒊏o
    CURSOR info_kuragae_henpin_cur
    IS
      SELECT 
             mmt.transaction_set_id    AS mmt_transaction_set_id                        -- ����Z�b�gID
           , mmt.transaction_date      AS mmt_transaction_date                          -- �����
           , mmt.attribute2            AS mmt_attribute2                                -- �o�בq�ɃR�[�h
           , mmt.attribute3            AS mmt_attribute3                                -- �q�R�[�h
           , mmt.transaction_quantity  AS mmt_transaction_quantity                      -- �������
           , mtt.attribute1            AS mtt_attribute1                                -- �H��q�֕ԕi���
           , mtt.attribute2            AS mtt_attribute2                                -- ���Y�����`�[���
           , msi.attribute7            AS msi_attribute7                                -- ���͋��_�R�[�h
           , msib.segment1             AS msib_segment1                                 -- �i�ڃR�[�h
           , CASE WHEN NVL( iim.attribute3, TO_CHAR( mmt.transaction_date, 'YYYY/MM/DD' ) )
               <= TO_CHAR( mmt.transaction_date, 'YYYY/MM/DD' )                         -- �Q�R�[�h�K�p�J�n�� <= �����
               THEN iim.attribute2                                                      -- �Q�R�[�h(�V)
               ELSE iim.attribute1                                                      -- ���Q�R�[�h
               END                     AS iim_attribute                                 -- �Q�R�[�h
           , mmt.rowid                 AS mmt_rowid                                     -- ROWID
      FROM 
             mtl_material_transactions mmt                                              -- ���ގ���e�[�u��
           , mtl_transaction_types     mtt                                              -- ����^�C�v�}�X�^
           , mtl_secondary_inventories msi                                              -- �ۊǏꏊ�}�X�^
           , mtl_system_items_b        msib                                             -- Disc�i�ڃ}�X�^
           , ic_item_mst_b             iim                                              -- OPM�i�ڃ}�X�^
      WHERE 
             mmt.transaction_set_id  = gt_slip_num_tab( gn_slip_loop_cnt )              -- �`�[No
      AND    mmt.attribute4          IS NULL                                            -- �H��q�֕ԕi�A�g�t���O
      AND    mmt.transaction_type_id = mtt.transaction_type_id                          -- ����^�C�vID
      AND    mmt.subinventory_code   = msi.secondary_inventory_name                     -- �ۊǏꏊ�R�[�h
      AND    mmt.inventory_item_id   = msib.inventory_item_id                           -- �i��ID
      AND    msib.organization_id    = gt_org_id                                        -- �݌ɑg�DID
      AND    iim.item_no             = msib.segment1                                    -- �i���R�[�h
    ;
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
    -- �q�֕ԕi��񌏐��̏�����
    gn_kuragae_henpin_cnt := 0;
--
    -- �J�[�\���I�[�v��
    OPEN info_kuragae_henpin_cur;
--
    -- ���R�[�h�Ǎ�
    FETCH info_kuragae_henpin_cur BULK COLLECT INTO gt_kuragae_henpin_tab;
--
    -- �q�֕ԕi��񌏐��Z�b�g
    gn_kuragae_henpin_cnt := gt_kuragae_henpin_tab.COUNT;
--
    -- �q�֕ԕi��񑍌����Z�b�g
    gn_kuragae_henpin_all_cnt := gn_kuragae_henpin_all_cnt + gn_kuragae_henpin_cnt;
--
    -- �J�[�\���N���[�Y
    CLOSE info_kuragae_henpin_cur;
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
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_kuragae_henpin_cur%ISOPEN ) THEN
        CLOSE info_kuragae_henpin_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_kuragae_henpin_cur%ISOPEN ) THEN
        CLOSE info_kuragae_henpin_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_kuragae_henpin_cur%ISOPEN ) THEN
        CLOSE info_kuragae_henpin_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_kuragae_henpin;
--
  /**********************************************************************************
   * Procedure Name   : chk_base_code
   * Description      : ���͋��_���݃`�F�b�N���� (A-5)
   ***********************************************************************************/
  PROCEDURE chk_base_code(
    gn_kuragae_henpin_loop_cnt IN   NUMBER,    -- �q�֕ԕi��񃋁[�v�J�E���^
    ov_errbuf                  OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_base_code'; -- �v���O������
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
    cv_customer_class_code   CONSTANT VARCHAR2(1) := '1'; -- �ڋq�敪 ���_
--
    -- *** ���[�J���ϐ� ***
    ln_cust_cnt              NUMBER; -- �ڋq�R�[�h����
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
    -- �����J�E���^������
    ln_cust_cnt  := 0;
--
    -- ���͋��_�R�[�h�̑��݃`�F�b�N
    SELECT count(1)                                                                                     -- ����
    INTO   ln_cust_cnt
    FROM   hz_cust_accounts hca                                                                         -- �ڋq�}�X�^
    WHERE  hca.account_number      = gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).msi_attribute7 -- �ڋq�R�[�h
    AND    hca.customer_class_code = cv_customer_class_code                                             -- �ڋq�敪
    AND    ROWNUM                  = 1;
--
    -- �J�E���g��0�ł���ꍇ
    IF ( ln_cust_cnt = 0 ) THEN
      RAISE no_base_code_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���_�R�[�h���݃G���[
    WHEN no_base_code_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_no_base_code_err_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).msi_attribute7
                       , iv_token_name2  => cv_tkn_den_no
                       , iv_token_value2 => TO_CHAR( gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_set_id )
                     );
      lv_errbuf   := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  := cv_status_warn;
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --�G���[���b�Z�[�W
      );
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO SAVEPOINT kuragae_point;
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
  END chk_base_code;
--
  /**********************************************************************************
   * Procedure Name   : ins_if_table
   * Description      : �q�֕ԕi�C���^�[�t�F�[�X���e�[�u���f�[�^�o�^���� (A-6)
   ***********************************************************************************/
  PROCEDURE ins_if_table(
    gn_kuragae_henpin_loop_cnt IN   NUMBER,    -- �q�֕ԕi��񃋁[�v�J�E���^
    ov_errbuf                  OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_if_table'; -- �v���O������
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
    cv_rno               CONSTANT VARCHAR2(1) := '0';  -- RNo
    cv_continue          CONSTANT VARCHAR2(2) := '00'; -- �p��
    cv_invoice_class_2   CONSTANT VARCHAR2(1) := '1';  -- �`��2
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
    -- �f�[�^�o�^����
    INSERT INTO xxwsh_reserve_interface(
        reserve_interface_id                         -- �q�֕ԕi�C���^�[�t�F�[�XID
      , data_class                                   -- �f�[�^���
      , r_no                                         -- RNo.
      , continue                                     -- �p��
      , recorded_year                                -- �v��N��
      , input_base_code                              -- ���͋��_�R�[�h
      , receive_base_code                            -- ���苒�_�R�[�h
      , invoice_class_1                              -- �`��P
      , invoice_class_2                              -- �`��Q
      , recorded_date                                -- �v����t�i�����j
      , ship_to_code                                 -- �z����R�[�h
      , customer_code                                -- �ڋq�R�[�h
      , invoice_no                                   -- �`�[No
      , item_code                                    -- �i�ڃR�[�h�G���g��
      , parent_item_code                             -- �i�ڃR�[�h�e
      , crowd_code                                   -- �Q�R�[�h
      , case_amount_of_content                       -- �P�[�X��
      , quantity_in_case                             -- ����
      , quantity                                     -- �{���i�o���j
      , created_by                                   -- �쐬��
      , creation_date                                -- �쐬��
      , last_updated_by                              -- �ŏI�X�V��
      , last_update_date                             -- �ŏI�X�V��
      , last_update_login                            -- �ŏI�X�V���[�U
      , request_id                                   -- �v��ID
      , program_application_id                       -- �v���O�����A�v���P�[�V����ID
      , program_id                                   -- �v���O����ID
      , program_update_date                          -- �v���O�����X�V��
    )
    VALUES(
        xxcoi_xxwsh_reserve_if_s01.NEXTVAL                                                            -- �q�֕ԕi�C���^�[�t�F�[�XID
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mtt_attribute1                            -- �f�[�^���
      , cv_rno                                                                                        -- RNo.
      , cv_continue                                                                                   -- �p��
      , TO_CHAR( gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_date, 'YYYYMM' ) -- �v��N��
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).msi_attribute7                            -- ���͋��_�R�[�h
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_attribute2                            -- ���苒�_�R�[�h
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mtt_attribute2                            -- �`��P
      , cv_invoice_class_2                                                                            -- �`��Q
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_date                      -- �v����t�i�����j
      , NULL                                                                                          -- �z����R�[�h
      , NULL                                                                                          -- �ڋq�R�[�h
      , TO_CHAR( gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_set_id )         -- �`�[No
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_attribute3                            -- �i�ڃR�[�h�G���g��
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).msib_segment1                             -- �i�ڃR�[�h�e
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).iim_attribute                             -- �Q�R�[�h
      , NULL                                                                                          -- �P�[�X��
      , NULL                                                                                          -- ����
      , ( gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_quantity * ( -1 ) )     -- �{���i�o���j
      , cn_created_by                                                                                 -- �쐬��
      , cd_creation_date                                                                              -- �쐬��
      , cn_last_updated_by                                                                            -- �ŏI�X�V��
      , cd_last_update_date                                                                           -- �ŏI�X�V��
      , cn_last_update_login                                                                          -- �ŏI�X�V���[�U
      , cn_request_id                                                                                 -- �v��ID
      , cn_program_application_id                                                                     -- �v���O�����A�v���P�[�V����ID
      , cn_program_id                                                                                 -- �v���O����ID
      , cd_program_update_date                                                                        -- �v���O�����X�V��
    );
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END ins_if_table;
--
  /**********************************************************************************
   * Procedure Name   : upd_flag
   * Description      : �H��q�֕ԕi�A�g�t���O�X�V���� (A-7)
   ***********************************************************************************/
  PROCEDURE upd_flag(
    gn_kuragae_henpin_loop_cnt IN   NUMBER,    -- �q�֕ԕi��񃋁[�v�J�E���^
    ov_errbuf                  OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_flag'; -- �v���O������
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
    cv_kuragae_flg   CONSTANT VARCHAR2(1) := '1';  -- �H��q�֕ԕi�A�g�t���O
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ގ���e�[�u�����b�N
    CURSOR upd_mmt_tbl_cur
    IS
      SELECT 'X'                       AS attribute4                                   -- �H��q�֕ԕi�A�g�t���O
      FROM   mtl_material_transactions mmt                                             -- ���ގ���e�[�u��
      WHERE  mmt.rowid = gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_rowid -- ROWID
      FOR UPDATE OF mmt.attribute4 NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    upd_mmt_tbl_rec  upd_mmt_tbl_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�[�\���I�[�v��
    OPEN upd_mmt_tbl_cur;
--
    -- ���R�[�h�Ǎ�
    FETCH upd_mmt_tbl_cur INTO upd_mmt_tbl_rec;
--
    -- �H��q�֕ԕi�A�g�t���O�̍X�V
    UPDATE mtl_material_transactions  mmt                                                             -- ���ގ���e�[�u��
    SET    mmt.attribute4             = cv_kuragae_flg                                                -- �H��q�֕ԕi�A�g�t���O
         , mmt.last_updated_by        = cn_last_updated_by                                            -- �ŏI�X�V��
         , mmt.last_update_date       = cd_last_update_date                                           -- �ŏI�X�V��
         , mmt.last_update_login      = cn_last_update_login                                          -- �ŏI�X�V���[�U
         , mmt.request_id             = cn_request_id                                                 -- �v��ID
         , mmt.program_application_id = cn_program_application_id                                     -- �v���O�����A�v���P�[�V����ID
         , mmt.program_id             = cn_program_id                                                 -- �v���O����ID
         , mmt.program_update_date    = cd_program_update_date                                        -- �v���O�����X�V��
    WHERE  mmt.rowid                  = gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_rowid -- ROWID
    ;
--
    -- �J�[�\���N���[�Y
    CLOSE upd_mmt_tbl_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( upd_mmt_tbl_cur%ISOPEN ) THEN
        CLOSE upd_mmt_tbl_cur;
      END IF;
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_table_lock_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => TO_CHAR( gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_set_id )
                     );
      lv_errbuf   := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  := cv_status_warn;
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --�G���[���b�Z�[�W
      );
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO SAVEPOINT kuragae_point;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( upd_mmt_tbl_cur%ISOPEN ) THEN
        CLOSE upd_mmt_tbl_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( upd_mmt_tbl_cur%ISOPEN ) THEN
        CLOSE upd_mmt_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( upd_mmt_tbl_cur%ISOPEN ) THEN
        CLOSE upd_mmt_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_flag;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- <�J�[�\����>���R�[�h�^
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt             := 0; -- �Ώی���
    gn_normal_cnt             := 0; -- ��������
    gn_error_cnt              := 0; -- �G���[����
    gn_warn_cnt               := 0; -- �X�L�b�v����
    gn_kuragae_henpin_all_cnt := 0; -- �q�֕ԕi��񑍌���
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �`�[No�擾���� (A-2)
    -- ===============================
    get_slip_num(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �`�[No�擾������0���̏ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
    -- �`�[No�P�ʃ��[�v�J�n
    <<gt_slip_num_tab_loop>>
    FOR gn_slip_loop_cnt IN 1 .. gn_target_cnt LOOP
--
      -- ===============================
      -- �Z�[�u�|�C���g�쐬���� (A-3)
      -- ===============================
      SAVEPOINT kuragae_point;
--
      -- ===============================
      -- �q�ց^�ԕi��񒊏o���� (A-4)
      -- ===============================
      get_kuragae_henpin(
          gn_slip_loop_cnt     -- �`�[No���[�v�J�E���^
        , lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �q�֕ԕi���1���ȏ�擾�o�����ꍇ
      IF ( gn_kuragae_henpin_cnt > 0 ) THEN
--
        -- �q�֕ԕi��񃋁[�v�J�n
        <<gt_kuragae_henpin_tab_loop>>
        FOR gn_kuragae_henpin_loop_cnt IN 1 .. gn_kuragae_henpin_cnt LOOP
--
          -- ====================================
          -- ���͋��_���݃`�F�b�N���� (A-5)
          -- ====================================
          chk_base_code(
              gn_kuragae_henpin_loop_cnt -- �q�֕ԕi��񃋁[�v�J�E���^
            , lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
            , lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
            , lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- �X�L�b�v����
            gn_warn_cnt := gn_warn_cnt + 1;
            -- �q�֕ԕi��񃋁[�v�𔲂���
            EXIT gt_kuragae_henpin_tab_loop;
          END IF;
--
          -- ========================================================
          -- �q�֕ԕi�C���^�[�t�F�[�X���e�[�u���f�[�^�o�^���� (A-6)
          -- ========================================================
          ins_if_table(
              gn_kuragae_henpin_loop_cnt -- �q�֕ԕi��񃋁[�v�J�E���^
            , lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
            , lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
            , lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ====================================
          -- �H��q�֕ԕi�A�g�t���O�X�V���� (A-7)
          -- ====================================
          upd_flag(
              gn_kuragae_henpin_loop_cnt -- �q�֕ԕi��񃋁[�v�J�E���^
            , lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
            , lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
            , lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- �X�L�b�v����
            gn_warn_cnt := gn_warn_cnt + 1;
            -- �q�֕ԕi��񃋁[�v�𔲂���
            EXIT gt_kuragae_henpin_tab_loop;
          END IF;
--
        END LOOP gt_kuragae_henpin_tab_loop;
--
        -- �q�֕ԕi��񂪐���I���̏ꍇ
        IF ( lv_retcode = cv_status_normal ) THEN
          -- ��������
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
--
      END IF;
--
    END LOOP gt_slip_num_tab_loop;
--
    -- �q�֕ԕi��񑍌�����0���̏ꍇ
    IF ( gn_kuragae_henpin_all_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
  EXCEPTION
    -- �擾����0��
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_no_data_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_normal;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --�G���[���b�Z�[�W
      );
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
    errbuf        OUT  VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT  VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
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
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
        lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- �I���X�e�[�^�X�u�G���[�v�̏ꍇ�A�Ώی����E���팏���E�X�L�b�v�����̏������ƃG���[�����̃Z�b�g
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
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
        which  => FND_FILE.OUTPUT
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
        which  => FND_FILE.OUTPUT
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
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- �X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- �X�L�b�v������1���ȏ゠��ꍇ�A�I���X�e�[�^�X�u�x���v�ɂ���
    IF ( gn_warn_cnt > 0 ) THEN
      lv_retcode := cv_status_warn;
    END IF;
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
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
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
END XXCOI002A02C;
/
