CREATE OR REPLACE PACKAGE BODY XXCOI002A01R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI002A01R(body)
 * Description      : �q�֓`�[
 * MD.050           : �q�֓`�[ MD050_COI_002_A01
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_base_code          �o�͋��_�擾���� (A-2)
 *  get_transaction_data   ���ގ���f�[�^���o���� (A-3)
 *  ins_rep_table_data     �q�֓`�[���[���[�N�e�[�u���f�[�^�o�^���� (A-4)
 *  start_svf              SVF�N������ (A-5)
 *  del_rep_table_data     �q�֓`�[���[���[�N�e�[�u���f�[�^�폜���� (A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/12    1.0   K.Nakamura       �V�K�쐬
 *  2009/05/13    1.1   H.Sasaki         [T1_0774]�`�[�ԍ��̌������C��
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt                      EXCEPTION; -- ���b�N�擾�G���[
  no_data_expt                   EXCEPTION; -- �擾����0����O
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ���b�N�擾��O
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(15)  := 'XXCOI002A01R'; -- �p�b�P�[�W��
  cv_application_short_name      CONSTANT VARCHAR2(15)  := 'XXCOI';        -- �A�v���P�[�V�����Z�k��
  -- �Q�ƃ^�C�v
  cv_voucher_inout_div           CONSTANT VARCHAR2(30)  := 'XXCOI1_VOUCHER_IN_OUT_DIV'; -- �q�֓`�[���o�ɋ敪
  -- ���b�Z�[�W
  cv_para_inout_type_msg         CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10163';  -- �p�����[�^ ���o�ɋ敪�l���b�Z�[�W
  cv_para_date_from_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10164';  -- �p�����[�^ ���t�iFrom�j�l���b�Z�[�W
  cv_para_date_to_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10165';  -- �p�����[�^ ���t�iTo�j�l���b�Z�[�W
  cv_para_base_code_from_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10166';  -- �p�����[�^ �o�Ɍ����_�l���b�Z�[�W
  cv_para_base_code_to_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10167';  -- �p�����[�^ ���ɐ拒�_�l���b�Z�[�W
  cv_org_code_get_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005';  -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_org_id_get_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006';  -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_inout_type_get_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10171';  -- ���o�ɋ敪���e�擾�G���[���b�Z�[�W
  cv_dept_code_get_err           CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10254';  -- �������_�R�[�h�擾�G���[���b�Z�[�W
  cv_date_over_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10047';  -- ���t���̓G���[�i�������j���b�Z�[�W
  cv_date_reverse_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10048';  -- ���t���̓G���[�i���t�t�]�j�G���[���b�Z�[�W
  cv_tran_type_name_get_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00022';  -- ����^�C�v���擾�G���[���b�Z�[�W
  cv_tran_type_id_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10300';  -- ����^�C�vID�擾�G���[���b�Z�[�W
  cv_api_err_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00010';  -- API�G���[���b�Z�[�W
  cv_table_lock_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10049';  -- ���b�N�擾�G���[���b�Z�[�W(�q�֓`�[���[���[�N�e�[�u��)
-- == 2009/05/13 V1.1 Added START ===============================================================
  cv_msg_code_xxcoi_10381        CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10381';  -- �`�[���}�X�N�擾�G���[���b�Z�[�W
-- == 2009/05/13 V1.1 Added END   ===============================================================
  -- �g�[�N��
  cv_tkn_para_inout_type         CONSTANT VARCHAR2(20)  := 'P_INOUT_TYPE';         -- �p�����[�^ ���o�ɋ敪
  cv_tkn_para_date_from          CONSTANT VARCHAR2(20)  := 'P_DATE_FROM';          -- �p�����[�^ ���t�iFrom�j
  cv_tkn_para_date_to            CONSTANT VARCHAR2(20)  := 'P_DATE_TO';            -- �p�����[�^ ���t�iTo�j
  cv_tkn_para_base_code_from     CONSTANT VARCHAR2(20)  := 'P_BASE_CODE_FROM';     -- �p�����[�^ �o�Ɍ����_�R�[�h
  cv_tkn_para_base_code_to       CONSTANT VARCHAR2(20)  := 'P_BASE_CODE_TO';       -- �p�����[�^ ���ɐ拒�_�R�[�h
  cv_tkn_pro                     CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- �v���t�@�C����
  cv_tkn_org_code                CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- �݌ɑg�D�R�[�h
  cv_tkn_lookup_type             CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';          -- �Q�ƃ^�C�v
  cv_tkn_lookup_code             CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';          -- �Q�ƃR�[�h
  cv_tkn_api_name                CONSTANT VARCHAR2(20)  := 'API_NAME';             -- API��
  cv_tkn_tran_type               CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- ����^�C�v
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �o�͋��_���i�[�p���R�[�h�i�[�p
  TYPE gr_kyoten_rec IS RECORD(
      base_code                  hz_cust_accounts.account_number%TYPE
  );
--
  TYPE gt_kyoten_ttype IS TABLE OF gr_kyoten_rec INDEX BY BINARY_INTEGER;
--
  -- ���ގ�����i�[�p���R�[�h�i�[�p
  TYPE gr_mmt_info_rec IS RECORD(
      transaction_date           mtl_material_transactions.transaction_date%TYPE     -- �`�[���t
    , transaction_set_id         VARCHAR2(15)                                        -- �`�[No
    , transaction_quantity       mtl_material_transactions.transaction_quantity%TYPE -- �������
    , kyoten_from_code           hz_cust_accounts.account_number%TYPE                -- �o�Ɍ����_�R�[�h
    , kyoten_to_code             VARCHAR2(240)                                       -- ���ɐ拒�_�R�[�h
    , kyoten_from_name           hz_cust_accounts.account_name%TYPE                  -- �o�Ɍ����_����
    , kyoten_to_name             VARCHAR2(240)                                       -- ���ɐ拒�_����
    , item_code                  mtl_system_items_b.segment1%TYPE                    -- ���i�R�[�h
    , item_name                  xxcmn_item_mst_b.item_short_name%TYPE               -- ���i��
    , title                      fnd_lookup_values.description%TYPE                  -- �^�C�g��
  );
--
  TYPE gt_mmt_info_ttype IS TABLE OF gr_mmt_info_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �N���p�����[�^
  gv_para_org_code               VARCHAR2(100); -- �݌ɑg�D
  gv_para_inout_div              VARCHAR2(100); -- ���o�ɋ敪
  gv_para_date_from              VARCHAR2(100); -- ���t�iFrom�j
  gv_para_date_to                VARCHAR2(100); -- ���t�iTo�j
  gv_para_kyoten_from            VARCHAR2(100); -- �o�Ɍ����_
  gv_para_kyoten_to              VARCHAR2(100); -- ���ɐ拒�_
  --
  gv_date                        VARCHAR2(100); -- SYSDATE(������)
  -- �����ϊ���
  gd_para_date_from2             DATE; -- ���t�iFrom�j
  gd_para_date_to2               DATE; -- ���t�iTo�j
  --
  gt_org_id                      mtl_parameters.organization_id%TYPE;            -- �݌ɑg�DID
  gt_tran_type_factory_change    mtl_transaction_types.transaction_type_id%TYPE; -- ����^�C�vID �H��q��
  gt_tran_type_factory_change_b  mtl_transaction_types.transaction_type_id%TYPE; -- ����^�C�vID �H��q�֐U��
  gt_tran_type_factory_return    mtl_transaction_types.transaction_type_id%TYPE; -- ����^�C�vID �H��ԕi
  gt_tran_type_factory_return_b  mtl_transaction_types.transaction_type_id%TYPE; -- ����^�C�vID �H��ԕi�U��
  gt_tran_type_kuragae           mtl_transaction_types.transaction_type_id%TYPE; -- ����^�C�vID �q��
  gv_login_kyoten                VARCHAR2(100);                                  -- ���O�C�����[�U�[�̋��_�R�[�h
  -- �J�E���^
  gn_kyoten_loop_cnt             NUMBER; -- ���_�R�[�h���[�v�J�E���^
  gn_mmt_info_loop_cnt           NUMBER; -- ���ގ����񃋁[�v�J�E���^
  gn_kyoten_cnt                  NUMBER; -- ���_�R�[�h����
  gn_mmt_info_cnt                NUMBER; -- ���ގ����񌏐�
  -- PL/SQL�\
  gt_kyoten_tab                  gt_kyoten_ttype;
  gt_mmt_info_tab                gt_mmt_info_ttype;
-- == 2009/05/13 V1.1 Added START ===============================================================
  gn_slip_number_mask            NUMBER;        -- �`�[���}�X�N(990000000000)
-- == 2009/05/13 V1.1 Added END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
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
    -- �v���t�@�C�� �݌ɑg�D�R�[�h
    cv_prf_org_code                CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
-- == 2009/05/13 V1.1 Added START ===============================================================
    cv_prf_slip_number_mask        CONSTANT VARCHAR2(30) := 'XXCOI1_SLIP_NUMBER_MASK';
-- == 2009/05/13 V1.1 Added END   ===============================================================
    -- �Q�ƃ^�C�v ���[�U�[��`����^�C�v����
    cv_tran_type                   CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME';
    -- �Q�ƃR�[�h
    cv_tran_type_factory_change    CONSTANT VARCHAR2(3)  := '110'; -- ����^�C�v �R�[�h �H��q��
    cv_tran_type_factory_change_b  CONSTANT VARCHAR2(3)  := '120'; -- ����^�C�v �R�[�h �H��q�֐U��
    cv_tran_type_factory_return    CONSTANT VARCHAR2(3)  := '90';  -- ����^�C�v �R�[�h �H��ԕi
    cv_tran_type_factory_return_b  CONSTANT VARCHAR2(3)  := '100'; -- ����^�C�v �R�[�h �H��ԕi�U��
    cv_tran_type_kuragae           CONSTANT VARCHAR2(3)  := '20';  -- ����^�C�v �R�[�h �q��
--
    -- *** ���[�J���ϐ� ***
    lt_org_code                    mtl_parameters.organization_code%TYPE;            -- �݌ɑg�D�R�[�h
    lt_tran_type_factory_change    mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �H��q��
    lt_tran_type_factory_change_b  mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �H��q�֐U��
    lt_tran_type_factory_return    mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �H��ԕi
    lt_tran_type_factory_return_b  mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �H��ԕi�U��
    lt_tran_type_kuragae           mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �q��
    lv_voucher_inout_div           VARCHAR(10); -- ���o�ɋ敪���e �S�� �H��q�� �H��ԕi ���_�ԑq��
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
    -- ===============================
    -- �v���t�@�C���擾�F�݌ɑg�D�R�[�h
    -- ===============================
    lt_org_code := fnd_profile.value( cv_prf_org_code );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ�A�܂��̓p�����[�^.�݌ɑg�D�R�[�h�Ƒ��Ⴗ��ꍇ
    IF ( lt_org_code IS NULL ) OR ( lt_org_code <> gv_para_org_code )THEN
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
                     , iv_name         => cv_tran_type_name_get_err_msg
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
                     , iv_name         => cv_tran_type_id_get_err_msg
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
                     , iv_name         => cv_tran_type_name_get_err_msg
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
                     , iv_name         => cv_tran_type_id_get_err_msg
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
                     , iv_name         => cv_tran_type_name_get_err_msg
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
                     , iv_name         => cv_tran_type_id_get_err_msg
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
                     , iv_name         => cv_tran_type_name_get_err_msg
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
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_return_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i�q�ցj
    -- ===============================
    lt_tran_type_kuragae := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_kuragae );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i�q�ցj
    -- ===============================
    gt_tran_type_kuragae := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_kuragae );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �p�����[�^.���o�ɋ敪���e�擾
    -- ===============================
    lv_voucher_inout_div := xxcoi_common_pkg.get_meaning( cv_voucher_inout_div, gv_para_inout_div );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lv_voucher_inout_div IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_inout_type_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_voucher_inout_div
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => gv_para_inout_div
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �p�����[�^.�o�Ɍ����_��NULL�̏ꍇ
    IF ( gv_para_kyoten_from IS NULL ) THEN
      -- ===============================
      -- ���O�C�����[�U�̏������_���擾
      -- ===============================
      xxcoi_common_pkg.get_belonging_base(
          in_user_id     => cn_created_by    -- ���[�U�[ID
        , id_target_date => cd_creation_date -- �Ώۓ�
        , ov_base_code   => gv_login_kyoten  -- ���_�R�[�h
        , ov_errbuf      => lv_errbuf        -- �G���[�E���b�Z�[�W
        , ov_retcode     => lv_retcode       -- ���^�[���E�R�[�h
        , ov_errmsg      => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- ���^�[���E�R�[�h������ȊO�̏ꍇ
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_dept_code_get_err
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- SYSDATE�擾(������)
    -- ===============================
    gv_date := TO_CHAR( cd_creation_date, 'YYYY/MM/DD' );
--
    -- �p�����[�^.���t�iTo�j��NULL�̏ꍇ
    IF ( gv_para_date_to IS NULL ) THEN
      -- ===============================
      -- �p�����[�^���e�擾�F���t�iTo�j
      -- ===============================
      gv_para_date_to := gv_date;
    END IF;
--
    -- ===============================
    -- �p�����[�^���e�`�F�b�N�F������
    -- ===============================
    -- �p�����[�^.���t�iFrom�j�^�iTo�j���V�X�e�����t���傫���ꍇ
    IF ( gv_para_date_from > gv_date ) OR ( gv_para_date_to > gv_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_date_over_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �p�����[�^���e�`�F�b�N�F���t�t�]
    -- ===============================
    -- �p�����[�^.���t�iFrom�j�^�iTo�j���t�]���Ă���ꍇ
    IF ( gv_para_date_from > gv_para_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_date_reverse_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ���t����(YYYYMMDD)�ϊ�
    -- ===============================
    gd_para_date_from2 := TO_DATE( TO_CHAR( TO_DATE( gv_para_date_from , 'YYYY/MM/DD' ), 'YYYYMMDD'), 'YYYYMMDD' );
    gd_para_date_to2   := TO_DATE( TO_CHAR( TO_DATE( gv_para_date_to , 'YYYY/MM/DD' ), 'YYYYMMDD'), 'YYYYMMDD' );
--
    --==============================================================
    --�R���J�����g�p�����[�^���O�o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_para_inout_type_msg
                    , iv_token_name1  => cv_tkn_para_inout_type
                    , iv_token_value1 => gv_para_inout_div
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_para_date_from_msg
                    , iv_token_name1  => cv_tkn_para_date_from
                    , iv_token_value1 => gv_para_date_from
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_para_date_to_msg
                    , iv_token_name1  => cv_tkn_para_date_to
                    , iv_token_value1 => gv_para_date_to
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_para_base_code_from_msg
                    , iv_token_name1  => cv_tkn_para_base_code_from
                    , iv_token_value1 => gv_para_kyoten_from
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_para_base_code_to_msg
                    , iv_token_name1  => cv_tkn_para_base_code_to
                    , iv_token_value1 => gv_para_kyoten_to
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
-- == 2009/05/13 V1.1 Added START ===============================================================
    -- ===============================
    -- �`�[���}�X�N�擾
    -- ===============================
    gn_slip_number_mask  :=  TO_NUMBER(fnd_profile.value( cv_prf_slip_number_mask ));
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ�A�܂��̓p�����[�^.�݌ɑg�D�R�[�h�Ƒ��Ⴗ��ꍇ
    IF (gn_slip_number_mask IS NULL) THEN
      -- �`�[���}�X�N�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_code_xxcoi_10381
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_slip_number_mask
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- == 2009/05/13 V1.1 Added END   ===============================================================
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_base_code
   * Description      : �o�͋��_�擾���� (A-2)
   ***********************************************************************************/
  PROCEDURE get_base_code(
    ov_errbuf       OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_code'; -- �v���O������
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
    -- �o�͋��_���擾
    CURSOR info_kyoten_cur
    IS
      SELECT xbiv.base_code       AS base_code      -- ���_�R�[�h
      FROM   xxcoi_base_info_v    xbiv              -- ���_���r���[
      WHERE  xbiv.focus_base_code = gv_login_kyoten -- �i�����_�R�[�h = ���O�C�����[�U�[�̏������_�R�[�h
      ORDER BY xbiv.base_code
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
    OPEN info_kyoten_cur;
--
    -- ���R�[�h�Ǎ�
    FETCH info_kyoten_cur BULK COLLECT INTO gt_kyoten_tab;
--
    -- �o�͋��_���J�E���g�Z�b�g
    gn_kyoten_cnt := gt_kyoten_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE info_kyoten_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_kyoten_cur%ISOPEN ) THEN
        CLOSE info_kyoten_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_kyoten_cur%ISOPEN ) THEN
        CLOSE info_kyoten_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_kyoten_cur%ISOPEN ) THEN
        CLOSE info_kyoten_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_base_code;
--
  /**********************************************************************************
   * Procedure Name   : get_transaction_data
   * Description      : ���ގ���f�[�^���o���� (A-3)
   ***********************************************************************************/
  PROCEDURE get_transaction_data(
    gn_kyoten_loop_cnt IN NUMBER,     -- ���_�R�[�h���[�v�J�E���^
    ov_errbuf          OUT VARCHAR2,  -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode         OUT VARCHAR2,  -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg          OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_transaction_data'; -- �v���O������
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
    cv_inout_div_all              CONSTANT VARCHAR2(1)  := '0';                   -- ���o�ɋ敪 �S��
    cv_inout_div_factory_change   CONSTANT VARCHAR2(1)  := '1';                   -- ���o�ɋ敪 �H��q��
    cv_inout_div_factory_return   CONSTANT VARCHAR2(1)  := '2';                   -- ���o�ɋ敪 �H��ԕi
    cv_inout_div_kuragae          CONSTANT VARCHAR2(1)  := '3';                   -- ���o�ɋ敪 ���_�ԑq��
    cv_customer_div               CONSTANT VARCHAR2(1)  := '1';                   -- �ڋq�敪 ���_
    cv_flag                       CONSTANT VARCHAR2(1)  := 'Y';                   -- �g�p�\�t���O 'Y'
    cv_mfg_fctory_cd              CONSTANT VARCHAR2(30) := 'XXCOI_MFG_FCTORY_CD'; -- �H��ԕi�q�֐�R�[�h
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ގ����񒊏o
    CURSOR info_transaction_cur
    IS
      SELECT
             mmt.transaction_date                       AS transaction_date                 -- �`�[���t
           , mmt.attribute1                             AS transaction_set_id               -- �`�[No(���_�ԑq��)
           , ( SUM( mmt.transaction_quantity ) * (-1) ) AS transaction_quantity             -- �������
           , hca1.account_number                        AS kyoten_from_code                 -- �o�Ɍ����_�R�[�h
           , hca2.account_number                        AS kyoten_to_code                   -- ���ɐ拒�_�R�[�h(���_�ԑq��)
           , SUBSTRB( hca1.account_name, 1, 8 )         AS kyoten_from_name                 -- �o�Ɍ����_����(����)
           , SUBSTRB( hca2.account_name, 1, 8 )         AS kyoten_to_name                   -- ���ɐ拒�_����(����)
           , msib.segment1                              AS item_code                        -- ���i�R�[�h
           , xim.item_short_name                        AS item_name                        -- ���i��(����)
           , flv.description                            AS title                            -- �^�C�g��
      FROM 
             mtl_material_transactions mmt                                                  -- ���ގ��
           , fnd_lookup_values         flv                                                  -- �N�C�b�N�R�[�h�}�X�^
           , mtl_secondary_inventories msi1                                                 -- �ۊǏꏊ�}�X�^1
           , mtl_secondary_inventories msi2                                                 -- �ۊǏꏊ�}�X�^2
           , hz_cust_accounts          hca1                                                 -- �ڋq�}�X�^1
           , hz_cust_accounts          hca2                                                 -- �ڋq�}�X�^2
           , mtl_system_items_b        msib                                                 -- Disc�i�ڃ}�X�^
           , ic_item_mst_b             iim                                                  -- OPM�i�ڃ}�X�^
           , xxcmn_item_mst_b          xim                                                  -- OPM�i�ڃA�h�I��
      WHERE 
           ( gv_para_inout_div              IN ( cv_inout_div_all                           -- �p�����[�^.���o�ɋ敪��'�S��'
                                               , cv_inout_div_kuragae )                                      -- �܂���'���_�ԑq��'
      AND    mmt.transaction_type_id        = gt_tran_type_kuragae                          -- ����^�C�vID��'�q��'
      AND    flv.lookup_code                = cv_inout_div_kuragae                          -- �Q�ƃR�[�h��'���_�ԑq��'
      AND    flv.lookup_type                = cv_voucher_inout_div                          -- �Q�ƃ^�C�v
      AND    flv.enabled_flag               = cv_flag                                       -- �g�p�\�t���O
      AND    TRUNC( cd_creation_date ) BETWEEN TRUNC( flv.start_date_active )               -- �K�p�J�n��
      AND    TRUNC( NVL( flv.end_date_active, cd_creation_date ) )                          -- �I����
      AND    flv.language                   = USERENV( 'LANG' ) )                           -- ����
      AND    TRUNC( mmt.transaction_date ) >= gd_para_date_from2                            -- �p�����[�^.�����(From)
      AND    TRUNC( mmt.transaction_date ) <= gd_para_date_to2                              -- �p�����[�^.�����(To)
      AND    hca1.account_number            = gt_kyoten_tab( gn_kyoten_loop_cnt ).base_code -- �p�����[�^.�o�Ɍ����_
      AND    hca1.account_number            = msi1.attribute7                               -- �ڋq�R�[�h
      AND    hca1.customer_class_code       = cv_customer_div                               -- �ڋq�敪
      AND    mmt.subinventory_code          = msi1.secondary_inventory_name                 -- �ۊǏꏊ�R�[�h
      AND    hca2.account_number            = NVL( gv_para_kyoten_to, hca2.account_number ) -- �p�����[�^.���ɐ拒�_
      AND    hca2.account_number            = msi2.attribute7                               -- �ڋq�R�[�h
      AND    hca2.customer_class_code       = cv_customer_div                               -- �ڋq�敪
      AND    mmt.transfer_subinventory      = msi2.secondary_inventory_name                 -- �]����ۊǏꏊ�R�[�h
      AND    msib.organization_id           = gt_org_id                                     -- �݌ɑg�DID
      AND    msib.inventory_item_id         = mmt.inventory_item_id                         -- �i��ID
      AND    iim.item_no                    = msib.segment1                                 -- �i���R�[�h
      AND    xim.item_id                    = iim.item_id                                   -- �i��ID
      AND    TRUNC( mmt.transaction_date ) BETWEEN TRUNC( xim.start_date_active )           -- �K�p�J�n��
      AND    TRUNC( NVL( xim.end_date_active, mmt.transaction_date ) )                      -- �I����
      AND    xim.active_flag                = cv_flag                                       -- �g�p�\�t���O
      GROUP BY
             mmt.transaction_date                                                           -- �`�[���t
           , mmt.attribute1                                                                 -- �`�[No(���_�ԑq��)
           , hca1.account_number                                                            -- �o�Ɍ����_�R�[�h
           , hca2.account_number                                                            -- ���ɐ拒�_�R�[�h(���_�ԑq��)
           , hca1.account_name                                                              -- �o�Ɍ����_����(����)
           , hca2.account_name                                                              -- ���ɐ拒�_����(����)
           , msib.segment1                                                                  -- ���i�R�[�h
           , xim.item_short_name                                                            -- ���i��(����)
           , flv.description                                                                -- �^�C�g��
      UNION
      SELECT 
             mmt.transaction_date                       AS transaction_date                 -- �`�[���t
-- == 2009/05/13 V1.1 Modified START ===============================================================
--           , TO_CHAR( mmt.transaction_set_id )          AS transaction_set_id               -- �`�[No(�H��q�ցE�H��ԕi)
           , TO_CHAR(gn_slip_number_mask + mmt.transaction_set_id)
                                                        AS transaction_set_id               -- �`�[No(�H��q�ցE�H��ԕi)
-- == 2009/05/13 V1.1 Modified END   ===============================================================
           , ( SUM( mmt.transaction_quantity ) * (-1) ) AS transaction_quantity             -- �������
           , hca.account_number                         AS kyoten_from_code                 -- �o�Ɍ����_�R�[�h
           , mmt.attribute2                             AS kyoten_to_code                   -- ���ɐ拒�_�R�[�h(�H��q�ցE�H��ԕi)
           , SUBSTRB( hca.account_name, 1, 8 )          AS kyoten_from_name                 -- �o�Ɍ����_����(����)
           , SUBSTRB( flv2.description, 1, 8 )          AS kyoten_to_name                   -- ���ɐ拒�_����(����)
           , msib.segment1                              AS item_code                        -- ���i�R�[�h
           , xim.item_short_name                        AS item_name                        -- ���i��(����)
           , flv.description                            AS title                            -- �^�C�g��
      FROM 
             mtl_material_transactions  mmt                                                 -- ���ގ��
           , fnd_lookup_values          flv                                                 -- �N�C�b�N�R�[�h�}�X�^
           , fnd_lookup_values          flv2                                                -- �N�C�b�N�R�[�h�}�X�^
           , mtl_secondary_inventories  msi                                                 -- �ۊǏꏊ�}�X�^
           , hz_cust_accounts           hca                                                 -- �ڋq�}�X�^
           , mtl_system_items_b         msib                                                -- Disc�i�ڃ}�X�^
           , ic_item_mst_b              iim                                                 -- OPM�i�ڃ}�X�^
           , xxcmn_item_mst_b           xim                                                 -- OPM�i�ڃA�h�I��
      WHERE 
         (
           ( gv_para_inout_div              IN ( cv_inout_div_all                           -- �p�����[�^.���o�ɋ敪��'�S��'
                                               , cv_inout_div_factory_change )                               -- �܂���'�H��q��'
      AND    mmt.transaction_type_id        IN ( gt_tran_type_factory_change                -- ����^�C�vID��'�H��q��'
                                               , gt_tran_type_factory_change_b )                    -- �܂���'�H��q�֐U��'
      AND    flv.lookup_code                = cv_inout_div_factory_change                   -- �Q�ƃR�[�h��'�H��q��'
      AND    flv.lookup_type                = cv_voucher_inout_div                          -- �Q�ƃ^�C�v
      AND    flv.enabled_flag               = cv_flag                                       -- �g�p�\�t���O
      AND    TRUNC( cd_creation_date ) BETWEEN TRUNC( flv.start_date_active )               -- �K�p�J�n��
      AND    TRUNC( NVL( flv.end_date_active, cd_creation_date ) )                          -- �I����
      AND    flv.language                   = USERENV( 'LANG' )                             -- ����
           )
      OR   ( gv_para_inout_div              IN ( cv_inout_div_all                           -- �p�����[�^.���o�ɋ敪��'�S��'
                                               , cv_inout_div_factory_return )                               -- �܂���'�H��ԕi'
      AND    mmt.transaction_type_id        IN ( gt_tran_type_factory_return                -- ����^�C�vID��'�H��ԕi'
                                               , gt_tran_type_factory_return_b )            -- ����^�C�vID��'�H��ԕi�U��'
      AND    flv.lookup_code                = cv_inout_div_factory_return                   -- �Q�ƃR�[�h
      AND    flv.lookup_type                = cv_voucher_inout_div                          -- �Q�ƃ^�C�v
      AND    flv.enabled_flag               = cv_flag                                       -- �g�p�\�t���O
      AND    TRUNC( cd_creation_date ) BETWEEN TRUNC( flv.start_date_active )               -- �K�p�J�n��
      AND    TRUNC( NVL( flv.end_date_active, cd_creation_date ) )                          -- �I����
      AND    flv.language                   = USERENV( 'LANG' )                             -- ����
           )
         )
      AND    TRUNC( mmt.transaction_date ) >= gd_para_date_from2                            -- �p�����[�^.�����
      AND    TRUNC( mmt.transaction_date ) <= gd_para_date_to2                              -- �p�����[�^.�����
      AND    hca.account_number             = gt_kyoten_tab( gn_kyoten_loop_cnt ).base_code -- �p�����[�^.�o�Ɍ����_
      AND    hca.account_number             = msi.attribute7                                -- �ڋq�R�[�h
      AND    hca.customer_class_code        = cv_customer_div                               -- �ڋq�敪
      AND    mmt.subinventory_code          = msi.secondary_inventory_name                  -- �ۊǏꏊ�R�[�h
      AND    msib.organization_id           = gt_org_id                                     -- �݌ɑg�DID
      AND    msib.inventory_item_id         = mmt.inventory_item_id                         -- �i��ID
      AND    iim.item_no                    = msib.segment1                                 -- �i���R�[�h
      AND    xim.item_id                    = iim.item_id                                   -- �i��ID
      AND    TRUNC( mmt.transaction_date ) BETWEEN TRUNC( xim.start_date_active )           -- �K�p�J�n��
      AND    TRUNC( NVL( xim.end_date_active, mmt.transaction_date ) )                      -- �I����
      AND    xim.active_flag                = cv_flag                                       -- �g�p�\�t���O
      AND    flv2.lookup_type               = cv_mfg_fctory_cd                              -- �Q�ƃ^�C�v
      AND    flv2.lookup_code               = mmt.attribute2                                -- �Q�ƃR�[�h
      AND    flv2.enabled_flag              = cv_flag                                       -- �g�p�\�t���O
      AND    TRUNC( cd_creation_date ) BETWEEN TRUNC( flv2.start_date_active )              -- �K�p�J�n��
      AND    TRUNC( NVL( flv2.end_date_active, cd_creation_date ) )                         -- �I����
      AND    flv2.language                  = USERENV( 'LANG' )                             -- ����
      GROUP BY
             mmt.transaction_date                                                           -- �`�[���t
           , mmt.transaction_set_id                                                         -- �`�[No(�H��q�ցE�H��ԕi)
           , hca.account_number                                                             -- �o�Ɍ����_�R�[�h
           , mmt.attribute2                                                                 -- ���ɐ拒�_�R�[�h(�H��q�ցE�H��ԕi)
           , hca.account_name                                                               -- �o�Ɍ����_����(����)
           , flv2.description                                                               -- ���ɐ拒�_����(����)
           , msib.segment1                                                                  -- ���i�R�[�h
           , xim.item_short_name                                                            -- ���i��(����)
           , flv.description                                                                -- �^�C�g��
      ORDER BY 
             title                                                                          -- �^�C�g��
           , transaction_set_id                                                             -- �`�[No
           , transaction_date                                                               -- �����
           , kyoten_from_code                                                               -- �o�Ɍ����_�R�[�h
           , kyoten_to_code                                                                 -- ���ɐ拒�_�R�[�h
           , item_code                                                                      -- ���i�R�[�h
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
    -- �J�E���^������
    gn_mmt_info_cnt := 0;
--
    -- �J�[�\���I�[�v��
    OPEN info_transaction_cur;
--
    -- ���R�[�h�Ǎ�
    FETCH info_transaction_cur BULK COLLECT INTO gt_mmt_info_tab;
--
    -- ���ގ�����J�E���g�Z�b�g
    gn_mmt_info_cnt := gt_mmt_info_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE info_transaction_cur;
--
    -- �Ώۏ�������
    gn_target_cnt := gn_target_cnt + gn_mmt_info_cnt;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_transaction_cur%ISOPEN ) THEN
        CLOSE info_transaction_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_transaction_cur%ISOPEN ) THEN
        CLOSE info_transaction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( info_transaction_cur%ISOPEN ) THEN
        CLOSE info_transaction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_transaction_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_rep_table_data
   * Description      : �q�֓`�[���[���[�N�e�[�u���f�[�^�o�^���� (A-4)
   ***********************************************************************************/
  PROCEDURE ins_rep_table_data(
    gn_mmt_info_loop_cnt IN NUMBER,     -- ���ގ����񃋁[�v�J�E���^
    ov_errbuf            OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_rep_table_data'; -- �v���O������
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
    -- �q�֓`�[���[���[�N�e�[�u���f�[�^�o�^����
    INSERT INTO xxcoi_rep_kuragae_slip(
        kuragae_slip_id                                                         -- �q�֓`�[ID
      , report_id                                                               -- ���[ID
      , title                                                                   -- �^�C�g��
      , transaction_date                                                        -- �����
      , slip_num                                                                -- �`�[No
      , item_code                                                               -- ���i�R�[�h
      , item_name                                                               -- ���i��
      , subinventory_code_from                                                  -- �o�Ɍ��ۊǏꏊ�R�[�h
      , subinventory_name_from                                                  -- �o�Ɍ��ۊǏꏊ����
      , subinventory_code_to                                                    -- ���ɐ�ۊǏꏊ�R�[�h
      , subinventory_name_to                                                    -- ���ɐ�ۊǏꏊ����
      , trn_qty                                                                 -- ����
      , created_by                                                              -- �쐬��
      , creation_date                                                           -- �쐬��
      , last_updated_by                                                         -- �ŏI�X�V��
      , last_update_date                                                        -- �ŏI�X�V��
      , last_update_login                                                       -- �ŏI�X�V���[�U
      , request_id                                                              -- �v��ID
      , program_application_id                                                  -- �v���O�����A�v���P�[�V����ID
      , program_id                                                              -- �v���O����ID
      , program_update_date                                                     -- �v���O�����X�V��
    )
    VALUES(
        xxcoi_rep_kuragae_slip_s01.NEXTVAL                                      -- �q�֓`�[ID(�V�[�P���X)
      , cv_pkg_name                                                             -- ���[ID
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).title                           -- �^�C�g��
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).transaction_date                -- �`�[���t
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).transaction_set_id              -- �`�[No
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).item_code                       -- ���i�R�[�h
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).item_name                       -- ���i��
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).kyoten_from_code                -- �o�Ɍ����_�R�[�h
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).kyoten_from_name                -- �o�Ɍ����_����
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).kyoten_to_code                  -- ���ɐ拒�_�R�[�h
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).kyoten_to_name                  -- ���ɐ拒�_����
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).transaction_quantity            -- �������
      , cn_created_by                                                           -- �쐬��
      , cd_creation_date                                                        -- �쐬��
      , cn_last_updated_by                                                      -- �ŏI�X�V��
      , cd_last_update_date                                                     -- �ŏI�X�V��
      , cn_last_update_login                                                    -- �ŏI�X�V���[�U
      , cn_request_id                                                           -- �v��ID
      , cn_program_application_id                                               -- �v���O�����A�v���P�[�V����ID
      , cn_program_id                                                           -- �v���O����ID
      , cd_program_update_date                                                  -- �v���O�����X�V��
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
  END ins_rep_table_data;
--
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF�N������ (A-5)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf     OUT VARCHAR2,  -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,  -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_svf'; -- �v���O������
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
    cv_frm_name   CONSTANT VARCHAR2(20) := 'XXCOI002A01S.xml';  -- �t�H�[���l���t�@�C����
    cv_vrq_name   CONSTANT VARCHAR2(20) := 'XXCOI002A01S.vrq';  -- �N�G���[�l���t�@�C����
    cv_out_div    CONSTANT VARCHAR2(20) := '1';   -- �o�͋敪
    cv_svf        CONSTANT VARCHAR2(20) := 'SVF'; -- ���b�Z�[�W�o�͗p
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
    -- ���t�����ϊ�
    ld_date := TO_CHAR( cd_creation_date, 'YYYYMMDD' );
--
    -- �o�̓t�@�C����
    lv_file_name := cv_pkg_name || ld_date || cn_request_id;
--
    -- SVF���ʊ֐��N��
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_retcode      => lv_retcode           -- ���^�[���R�[�h
      , ov_errbuf       => lv_errbuf            -- �G���[���b�Z�[�W
      , ov_errmsg       => lv_errmsg            -- ���[�U�[�E�G���[���b�Z�[�W
      , iv_conc_name    => cv_pkg_name          -- �R���J�����g��
      , iv_file_name    => lv_file_name         -- �o�̓t�@�C����
      , iv_file_id      => cv_pkg_name          -- ���[ID
      , iv_output_mode  => cv_out_div           -- �o�͋敪
      , iv_frm_file     => cv_frm_name          -- �t�H�[���l���t�@�C����
      , iv_vrq_file     => cv_vrq_name          -- �N�G���[�l���t�@�C����
      , iv_org_id       => fnd_global.org_id    -- ORG_ID
      , iv_user_name    => fnd_global.user_name -- ���O�C���E���[�U��
      , iv_resp_name    => fnd_global.resp_name -- ���O�C���E���[�U�̐E�Ӗ�
      , iv_doc_name     => NULL                 -- ������
      , iv_printer_name => NULL                 -- �v�����^��
      , iv_request_id   => cn_request_id        -- �v��ID
      , iv_nodata_msg   => NULL                 -- �f�[�^�Ȃ����b�Z�[�W
    );
    -- ���ʊ֐��̃��^�[���R�[�h������ȊO�̏ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_api_err_msg
                     , iv_token_name1  => cv_tkn_api_name
                     , iv_token_value1 => cv_svf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END start_svf;
--
  /**********************************************************************************
   * Procedure Name   : del_rep_table_data
   * Description      : �q�֓`�[���[���[�N�e�[�u���f�[�^�폜���� (A-6)
   ***********************************************************************************/
  PROCEDURE del_rep_table_data(
    ov_errbuf     OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT  VARCHAR2,  -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
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
    -- ���ގ�����b�N
    CURSOR del_xrs_tbl_cur
    IS
      SELECT 'X'                    AS request_id  -- �v��ID
      FROM   xxcoi_rep_kuragae_slip xrk            -- �q�֓`�[���[���[�N�e�[�u��
      WHERE  xrk.request_id = cn_request_id        -- �v��ID
      FOR UPDATE OF xrk.request_id NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    del_xrs_tbl_rec  del_xrs_tbl_cur%ROWTYPE;
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
    OPEN del_xrs_tbl_cur;
--
    <<del_xrs_tbl_cur_loop>>
    LOOP
      -- ���R�[�h�Ǎ�
      FETCH del_xrs_tbl_cur INTO del_xrs_tbl_rec;
      EXIT WHEN del_xrs_tbl_cur%NOTFOUND;
--
      -- �q�֓`�[���[���[�N�e�[�u���̍폜
      DELETE
      FROM   xxcoi_rep_kuragae_slip xrk     -- �q�֓`�[���[���[�N�e�[�u��
      WHERE  xrk.request_id = cn_request_id -- �v��ID
      ;
--
    END LOOP del_xrs_tbl_cur_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE del_xrs_tbl_cur;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( del_xrs_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrs_tbl_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_table_lock_err_msg
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
      IF ( del_xrs_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrs_tbl_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( del_xrs_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrs_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( del_xrs_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrs_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_rep_table_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_org_code     IN  VARCHAR2,  --  1.�݌ɑg�D
    iv_inout_div    IN  VARCHAR2,  --  2.���o�ɋ敪
    iv_date_from    IN  VARCHAR2,  --  3.���t�iFrom�j
    iv_date_to      IN  VARCHAR2,  --  4.���t�iTo�j
    iv_kyoten_from  IN  VARCHAR2,  --  5.�o�Ɍ����_
    iv_kyoten_to    IN  VARCHAR2,  --  6.���ɐ拒�_
    ov_errbuf       OUT VARCHAR2,  --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,  --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)  --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_target_cnt       := 0;    -- �Ώی���
    gn_normal_cnt       := 0;    -- ��������
    gn_error_cnt        := 0;    -- �G���[����
    gn_warn_cnt         := 0;    -- �X�L�b�v����
    gv_para_org_code    := NULL; -- ���̓p�����[�^.�݌ɑg�D
    gv_para_inout_div   := NULL; -- ���̓p�����[�^.���o�ɋ敪
    gv_para_date_from   := NULL; -- ���̓p�����[�^.���t�iFrom�j
    gv_para_date_to     := NULL; -- ���̓p�����[�^.���t�iTo�j
    gv_para_kyoten_from := NULL; -- ���̓p�����[�^.�o�Ɍ����_
    gv_para_kyoten_to   := NULL; -- ���̓p�����[�^.���ɐ拒�_
    gn_kyoten_cnt       := 0;    -- ���_�R�[�h�J�E���^
    gn_mmt_info_cnt     := 0;    -- ���ގ�����J�E���^
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ���̓p�����[�^���O���[�o���ϐ��փZ�b�g
    gv_para_org_code    := iv_org_code;                   -- �݌ɑg�D
    gv_para_inout_div   := iv_inout_div;                  -- ���o�ɋ敪
    gv_para_date_from   := SUBSTRB( iv_date_from, 1, 10); -- ���t�iFrom�j
    gv_para_date_to     := SUBSTRB( iv_date_to, 1, 10);   -- ���t�iTo�j
    gv_para_kyoten_from := iv_kyoten_from;                -- �o�Ɍ����_
    gv_para_kyoten_to   := iv_kyoten_to;                  -- ���ɐ拒�_
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �p�����[�^.�o�Ɍ����_��NULL�̏ꍇ
    IF ( gv_para_kyoten_from IS NULL ) THEN
      -- ===============================
      -- �o�͋��_�擾���� (A-2)
      -- ===============================
      get_base_code(
          ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    ELSE
      -- �o�͋��_���Z�b�g
      gn_kyoten_cnt := 1;
    END IF;
--
    -- �o�͋��_��1���ȏ゠��ꍇ
    IF ( gn_kyoten_cnt > 0 ) THEN
--
      -- �o�͋��_�P�ʃ��[�v�J�n
      <<gn_kyoten_cnt_loop>>
      FOR gn_kyoten_loop_cnt IN 1 .. gn_kyoten_cnt LOOP
--
        -- �o�͋��_���Z�b�g
        IF ( gv_para_kyoten_from IS NOT NULL ) THEN
          gt_kyoten_tab( gn_kyoten_loop_cnt ).base_code := gv_para_kyoten_from;
        END IF;
--
        -- ===============================
        -- ���ގ���f�[�^���o���� (A-3)
        -- ===============================
        get_transaction_data(
            gn_kyoten_loop_cnt => gn_kyoten_loop_cnt -- ���_�R�[�h���[�v�J�E���^
          , ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ���ގ���f�[�^��1���ȏ�擾�ł����ꍇ
        IF ( gn_mmt_info_cnt > 0 ) THEN
--
          -- ���ގ�����P�ʃ��[�v�J�n
          <<gn_mmt_info_cnt_loop>>
          FOR gn_mmt_info_loop_cnt IN 1 .. gn_mmt_info_cnt LOOP
            -- ===============================
            -- �q�֓`�[���[���[�N�e�[�u���f�[�^�o�^���� (A-4)
            -- ===============================
            ins_rep_table_data(
                gn_mmt_info_loop_cnt => gn_mmt_info_loop_cnt -- ���ގ����񃋁[�v�J�E���^
              , ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
              , ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
              , ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          END LOOP gn_mmt_info_cnt_loop;
--
        END IF;
--
      END LOOP gn_kyoten_cnt_loop;
--
    END IF;
--
    -- �R�~�b�g
    COMMIT;
--
    -- ==============================================
    -- SVF�N������ (A-5)
    -- ==============================================
    start_svf(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- �q�֓`�[���[���[�N�e�[�u���f�[�^�폜���� (A-6)
    -- ==============================================
    del_rep_table_data(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
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
    errbuf          OUT VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_org_code     IN  VARCHAR2,      -- 1.�݌ɑg�D
    iv_inout_div    IN  VARCHAR2,      -- 2.���o�ɋ敪
    iv_date_from    IN  VARCHAR2,      -- 3.���t�iFrom�j
    iv_date_to      IN  VARCHAR2,      -- 4.���t�iTo�j
    iv_kyoten_from  IN  VARCHAR2,      -- 5.�o�Ɍ����_
    iv_dummy        IN  VARCHAR2,      -- ���͐���p�_�~�[�l
    iv_kyoten_to    IN  VARCHAR2       -- 6.���ɐ拒�_
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    --
    cv_log             CONSTANT VARCHAR2(10)  := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W���O�o��
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
       iv_which   => cv_log
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
        iv_org_code    => iv_org_code     -- 1.�݌ɑg�D(��\��)
      , iv_inout_div   => iv_inout_div    -- 2.���o�ɋ敪
      , iv_date_from   => iv_date_from    -- 3.���t�iFrom�j
      , iv_date_to     => iv_date_to      -- 4.���t�iTo�j
      , iv_kyoten_from => iv_kyoten_from  -- 5.�o�Ɍ����_
      , iv_kyoten_to   => iv_kyoten_to    -- 6.���ɐ拒�_
      , ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
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
    -- �I���X�e�[�^�X�u�G���[�v�̏ꍇ�A�Ώی����E���팏���E�X�L�b�v�����̏������ƃG���[�����̃Z�b�g
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    -- �I���X�e�[�^�X�u����v�̏ꍇ�A�Ώی����𐬌������ɃZ�b�g
    ELSIF ( lv_retcode = cv_status_normal ) THEN
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
    -- �X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
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
END XXCOI002A01R;
/
