CREATE OR REPLACE PACKAGE BODY XXCOI003A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A12C(body)
 * Description      : HHT���o�Ƀf�[�^���o
 * MD.050           : HHT���o�Ƀf�[�^���o MD050_COI_003_A12
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_hht_inv_if_data    HHT���o�ɃC���^�[�t�F�[�X���̎擾 (A-2)
 *  chk_hht_inv_if_data    HHT���o��IF�f�[�^�Ó����`�F�b�N(B-3)
 *  cnv_subinv_code        HHT���o��IF�f�[�^�̕ۊǏꏊ�R�[�h�ϊ�(B-4)
 *  insert_hht_inv_tran    HHT���o��IF�̃��R�[�h�ǉ�(B-5)
 *  del_hht_inv_if_data    HHT���o��IF�̃��R�[�h�폜(B-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/16    1.0   H.nakajima       main�V�K�쐬
 *  2009/02/18    1.1   K.Nakamura       [��QCOI_011] ���o�ɃW���[�i�������敪'0'�̏����X�e�[�^�X�Ή�
 *  2009/04/21    1.2   H.Sasaki         [T1_0654]�捞�f�[�^�̑O��X�y�[�X�폜
 *  2009/05/15    1.3   H.Sasaki         [T1_0785]�f�[�^���o�����̕ύX
 *  2009/06/01    1.4   H.Sasaki         [T1_1272]���ɑ��R�[�h�A�o�ɑ��R�[�h�ҏW
 *  2010/01/29    1.5   H.Sasaki         [E_�{�ғ�_01372]�݌ɉ�v���ԃ`�F�b�N�̃G���[�n���h�����O�ύX
 *  2010/03/23    1.6   Y.Goto           [E_�{�ғ�_01943]���_�̗L���`�F�b�N��ǉ�
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt                    EXCEPTION; -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(15)  := 'XXCOI003A12C'; -- �p�b�P�[�W��
  cv_appl_short_name           CONSTANT VARCHAR2(10)  := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_application_short_name    CONSTANT VARCHAR2(10)  := 'XXCOI';        -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W
  cv_no_para_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90008';     -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_org_code_get_err          CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';     -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_org_id_get_err            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';     -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_hht_name_get_err          CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10027';     -- HHT�G���[���X�g���擾�G���[���b�Z�[�W
  cv_no_data_msg               CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';     -- �Ώۃf�[�^�������b�Z�[�W
  cv_msg_process_date_get_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011';     -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_lock_err              CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10170';     -- ���b�N�G���[���b�Z�[�W(HHT���o��IF)
  cv_msg_no_data               CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';     -- �Ώۃf�[�^�������b�Z�[�W
  cv_record_type_is_null_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10172';     -- �K�{���ځi���R�[�h��ʁj�G���[
  cv_invoice_date_is_null_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10173';     -- �K�{���ځi�`�[���t�j�G���[
  cv_base_code_is_null_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10174';     -- �K�{���ځi���_�R�[�h�j�G���[
  cv_outside_code_is_null_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10175';     -- �K�{���ځi�o�ɑ��R�[�h�j�G���[
  cv_inside_code_is_null_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10176';     -- �K�{���ځi���ɑ��R�[�h�j�G���[
  cv_item_code_is_null_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10341';     -- �K�{���ځi�i�ڃR�[�h�j�G���[
  cv_column_no_is_null_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10177';     -- �����t�K�{���ځi�R�������j�G���[
  cv_invoice_type_is_null_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10178';     -- �����t�K�{���ځi�`�[�敪�j�G���[
  cv_employee_num_is_null_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10179';     -- �����t�K�{���ځi�c�ƈ��R�[�h�j�G���[
  cv_record_type_invalid_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10180';     -- �l�i���R�[�h��ʁj�G���[���b�Z�[�W
  cv_invoice_type_invalid_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10181';     -- �l�i�`�[�敪�j�G���[���b�Z�[�W
  cv_dept_flag_invalid_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10182';     -- �l�i�`�[�敪�j�G���[���b�Z�[�W
  cv_hc_div_invalid_err        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10183';     -- �l�iH/C�j�G���[���b�Z�[�W
  cv_quantity_invalid_err      CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10226';     -- ���{�����Z�G���[
  cv_item_code_invalid_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10227';     -- �i�ڑ��݃`�F�b�N�G���[
  cv_item_statu_invalid_err    CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10228';     -- �i�ڃX�e�[�^�X�L���`�F�b�N�G���[
  cv_sales_class_invalid_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10229';     -- �i�ڔ���Ώۋ敪�L���`�F�b�N�G���[
  cv_primary_uom_notfound_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10318';     -- ��P�ʑ��݃`�F�b�N�G���[
  cv_primary_uom_invalid_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10230';     -- ��P�ʗL���`�F�b�N�G���[
  cv_msg_org_acct_period_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00026';     -- �݌ɉ�v���Ԏ擾�`�F�b�N�G���[
  cv_invoice_date_invalid_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10231';     -- �݌ɉ�v���ԃ`�F�b�N�G���[
  cv_inv_status_fix_err        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10224';     -- �I���m��σ`�F�b�N�G���[
  cv_key_info                  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10342';     -- HHT���o�Ƀf�[�^�pKEY���
-- == 2010/03/23 V1.6 Added START ===============================================================
  cv_msg_get_aff_dept_date_err CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10417';     -- AFF����擾�G���[
  cv_aff_dept_inactive_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10418';     -- AFF���喳���G���[
-- == 2010/03/23 V1.6 Added END   ===============================================================
--
  -- �g�[�N��
  cv_tkn_pro                   CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- �v���t�@�C����
  cv_tkn_org_code              CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- TKN�F�݌ɑg�D�R�[�h
  cv_tkn_record_type           CONSTANT VARCHAR2(20)  := 'RECORD_TYPE';          -- TKN�Fں��ގ��
  cv_tkn_invoice_type          CONSTANT VARCHAR2(20)  := 'INVOICE_TYPE';         -- TKN�F�`�[�敪
  cv_tkn_dept_flag             CONSTANT VARCHAR2(20)  := 'DEPT_FLAG';            -- TKN�F�S�ݓX�׸�
  cv_tkn_hc_div                CONSTANT VARCHAR2(20)  := 'HC_DIV';               -- TKN�FHC�敪
  cv_tkn_item_code             CONSTANT VARCHAR2(20)  := 'ITEM_CODE';            -- TKN�F�i�ں���
  cv_tkn_primary_uom           CONSTANT VARCHAR2(20)  := 'PRIMARY_UOM';          -- TKN�F��P��
  cv_tkn_proc_date             CONSTANT VARCHAR2(20)  := 'INVOICE_DATE';         -- TKN�F�`�[���t
  cv_tkn_subinv                CONSTANT VARCHAR2(20)  := 'SUB_INV_CODE';         -- TKN�F�ۊǏꏊ
  cv_tkn_target_date           CONSTANT VARCHAR2(20)  := 'TARGET_DATE';          -- TKN�F�Ώۓ�
  cv_tkn_base_code             CONSTANT VARCHAR2(20)  := 'BASE_CODE';            -- TKN�F���_����
  cv_tkn_column_no             CONSTANT VARCHAR2(20)  := 'COLUMN_NO';            -- TKN�F�R������
  cv_tkn_invoice_no            CONSTANT VARCHAR2(20)  := 'INVOICE_NO';           -- TKN�F�`�[�ԍ�
-- == 2010/03/23 V1.6 Added START ===============================================================
  cv_tkn_slip_num              CONSTANT VARCHAR2(20)  := 'SLIP_NUM';             -- TKN�F�`�[�ԍ�
-- == 2010/03/23 V1.6 Added END   ===============================================================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_hht_inv_rec IS RECORD(
     hht_rowid                 ROWID                                                   -- ROWID
    ,interface_id              xxcoi_in_hht_inv_transactions.interface_id%TYPE         -- �C���^�[�t�F�[�XID
    ,base_code                 xxcoi_in_hht_inv_transactions.base_code%TYPE            -- ���_�R�[�h
    ,record_type               xxcoi_in_hht_inv_transactions.record_type%TYPE          -- ���R�[�h���
    ,employee_num              xxcoi_in_hht_inv_transactions.employee_num%TYPE         -- �c�ƈ��R�[�h
    ,invoice_no                xxcoi_in_hht_inv_transactions.invoice_no%TYPE           -- �`�[��
    ,item_code                 xxcoi_in_hht_inv_transactions.item_code%TYPE            -- �i�ڃR�[�h�i�i���R�[�h�j
    ,case_quantity             xxcoi_in_hht_inv_transactions.case_quantity%TYPE        -- �P�[�X��
    ,case_in_quantity          xxcoi_in_hht_inv_transactions.case_in_quantity%TYPE     -- ����
    ,quantity                  xxcoi_in_hht_inv_transactions.quantity%TYPE             -- �{��
    ,invoice_type              xxcoi_in_hht_inv_transactions.invoice_type%TYPE         -- �`�[�敪
    ,base_delivery_flag        xxcoi_in_hht_inv_transactions.base_delivery_flag%TYPE   -- ���_�ԑq�փt���O
    ,outside_code              xxcoi_in_hht_inv_transactions.outside_code%TYPE         -- �o�ɑ��R�[�h
    ,inside_code               xxcoi_in_hht_inv_transactions.inside_code%TYPE          -- ���ɑ��R�[�h
    ,invoice_date              xxcoi_in_hht_inv_transactions.invoice_date%TYPE         -- �`�[���t
    ,column_no                 xxcoi_in_hht_inv_transactions.column_no%TYPE            -- �R������
    ,unit_price                xxcoi_in_hht_inv_transactions.unit_price%TYPE           -- �P��
    ,hot_cold_div              xxcoi_in_hht_inv_transactions.hot_cold_div%TYPE         -- H/C
    ,department_flag           xxcoi_in_hht_inv_transactions.department_flag%TYPE      -- �S�ݓX�t���O
    ,other_base_code           xxcoi_in_hht_inv_transactions.other_base_code%TYPE      -- �����_�R�[�h
    ,interface_date            xxcoi_in_hht_inv_transactions.interface_date%TYPE       -- ��M����
  );
  --
  TYPE g_hht_inv_rec_type IS TABLE OF g_hht_inv_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_org_id                    mtl_parameters.organization_id%TYPE;                             -- �݌ɑg�DID
  gt_item_id                   mtl_system_items_b.inventory_item_id%TYPE;                       -- �i��ID
  gt_primary_uom_code          mtl_system_items_b.primary_uom_code%TYPE;                        -- ��P�ʃR�[�h
  gt_primary_uom               mtl_system_items_b.primary_unit_of_measure%TYPE;                 -- ��P��
  gd_process_date              DATE;                                                            -- �Ɩ����t
  gt_file_name                 fnd_profile_option_values.profile_option_value%TYPE;             -- HHT�G���[���X�g�t�@�C����
  gt_outside_subinv_code       xxcoi_hht_inv_transactions.outside_subinv_code%TYPE;             -- �o�ɑ��ۊǏꏊ
  gt_inside_subinv_code        xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;              -- ���ɑ��ۊǏꏊ
  gt_outside_base_code         xxcoi_hht_inv_transactions.outside_base_code%TYPE;               -- �o�ɑ����_
  gt_inside_base_code          xxcoi_hht_inv_transactions.inside_base_code%TYPE;                -- ���ɑ����_
  gn_total_quantity            NUMBER;                                                          -- ���{��
  gt_outside_subinv_code_conv  xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE;    -- �o�ɑ��ۊǏꏊ�ϊ��敪
  gt_inside_subinv_code_conv   xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE;     -- ���ɑ��ۊǏꏊ�ϊ��敪
  gt_outside_business_low_type xxcoi_hht_inv_transactions.outside_business_low_type%TYPE;       -- �o�ɑ��ڋq������
  gt_inside_business_low_type  xxcoi_hht_inv_transactions.inside_business_low_type%TYPE;        -- ���ɑ��ڋq������
  gt_outside_cust_code         xxcoi_hht_inv_transactions.outside_cust_code%TYPE;               -- �o�ɑ��ڋq
  gt_inside_cust_code          xxcoi_hht_inv_transactions.inside_cust_code%TYPE;                -- ���ɑ��ڋq
  gt_hht_program_div           xxcoi_hht_inv_transactions.hht_program_div%TYPE;                 -- HHT�v���O���������敪
  gt_item_convert_div          xxcoi_hht_inv_transactions.item_convert_div%TYPE;                -- ���i�U�֋敪
  gt_stock_uncheck_list_div    xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE;          -- ���ɖ��m�F���X�g�Ώۋ敪
  gt_stock_balance_list_div    xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE;          -- ���ɍ��يm�F���X�g�Ώۋ敪
  gt_consume_vd_flag           xxcoi_hht_inv_transactions.consume_vd_flag%TYPE;                 -- ����VD��[�Ώ��׸�
  -- PL/SQL�\
  g_hht_inv_if_tab             g_hht_inv_rec_type;                                      -- HHT���o�Ɉꎞ�\�i�[�p
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT  nocopy VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT  nocopy VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT  nocopy VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_prf_org_code                       CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
    cv_prf_file_name                      CONSTANT VARCHAR2(30) := 'XXCOI1_HHT_ERR_DATA_NAME';
--
    -- *** ���[�J���ϐ� ***
    lt_org_code                       mtl_parameters.organization_code%TYPE;               -- �݌ɑg�D�R�[�h
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
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_code_get_err
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 
    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'lt_org_code = '||lt_org_code);
--
    -- ===============================
    -- �݌ɑg�DID�擾
    -- ===============================
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_code );
    -- ���ʊ֐��̃��^�[���R�[�h��NULL�̏ꍇ
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_id_get_err
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => lt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 
    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'gt_org_id = '||gt_org_id);
--
    -- ===============================
    -- �v���t�@�C���擾�FHHT�G���[���X�g��
    -- ===============================
    gt_file_name := fnd_profile.value( cv_prf_file_name );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_hht_name_get_err
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_file_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 
    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'gt_file_name = '||gt_file_name);
    -- ==============================================================
    -- �Ɩ����t�擾
    -- ==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_process_date_get_err
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 
    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'gd_process_date = '||gd_process_date);
--
  EXCEPTION
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
   * Procedure Name   : get_hht_inv_if_data
   * Description      : HHT���o�ɃC���^�[�t�F�[�X���̎擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_hht_inv_if_data(
      ov_errbuf    OUT nocopy VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT nocopy VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT nocopy VARCHAR2 )    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hht_inv_if_data'; -- �v���O������
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
    -- �ڋq�ڍ����擾
    CURSOR hht_inv_if_cur
    IS
-- == 2009/06/01 V1.4 Modified START ===============================================================
---- == 2009/04/21 V1.2 Modified START ===============================================================
--      SELECT 
----             ROWID                          AS hht_rowid                -- ROWID
----            ,xihit.interface_id             AS interface_id             -- �C���^�[�t�F�[�XID
----            ,xihit.base_code                AS base_code                -- ���_�R�[�h
----            ,xihit.record_type              AS record_type              -- ���R�[�h���
----            ,xihit.employee_num             AS employee_num             -- �c�ƈ��R�[�h
----            ,xihit.invoice_no               AS invoice_no               -- �`�[��
----            ,xihit.item_code                AS item_code                -- �i�ڃR�[�h�i�i���R�[�h�j
----            ,xihit.case_quantity            AS case_quantity            -- �P�[�X��
----            ,xihit.case_in_quantity         AS case_in_quantity         -- ����
----            ,xihit.quantity                 AS quantity                 -- �{��
----            ,xihit.invoice_type             AS invoice_type             -- �`�[�敪
----            ,xihit.base_delivery_flag       AS base_delivery_flag       -- ���_�ԑq�փt���O
----            ,xihit.outside_code             AS outside_code             -- �o�ɑ��R�[�h
----            ,xihit.inside_code              AS inside_code              -- ���ɑ��R�[�h
----            ,xihit.invoice_date             AS invoice_date             -- �`�[���t
----            ,xihit.column_no                AS column_no                -- �R������
----            ,xihit.unit_price               AS unit_price               -- �P��
----            ,xihit.hot_cold_div             AS hot_cold_div             -- h/c
----            ,xihit.department_flag          AS department_flag          -- �S�ݓX�t���O
----            ,xihit.other_base_code          AS other_base_code          -- �����_�R�[�h
----            ,xihit.interface_date           AS interface_date           -- ��M����
----
--             ROWID                          AS hht_rowid                -- ROWID
--            ,xihit.interface_id             AS interface_id             -- �C���^�[�t�F�[�XID
--            ,TRIM(xihit.base_code)          AS base_code                -- ���_�R�[�h
--            ,TRIM(xihit.record_type)        AS record_type              -- ���R�[�h���
--            ,TRIM(xihit.employee_num)       AS employee_num             -- �c�ƈ��R�[�h
--            ,TRIM(xihit.invoice_no)         AS invoice_no               -- �`�[��
--            ,TRIM(xihit.item_code)          AS item_code                -- �i�ڃR�[�h�i�i���R�[�h�j
--            ,xihit.case_quantity            AS case_quantity            -- �P�[�X��
--            ,xihit.case_in_quantity         AS case_in_quantity         -- ����
--            ,xihit.quantity                 AS quantity                 -- �{��
--            ,TRIM(xihit.invoice_type)       AS invoice_type             -- �`�[�敪
--            ,TRIM(xihit.base_delivery_flag) AS base_delivery_flag       -- ���_�ԑq�փt���O
--            ,TRIM(xihit.outside_code)       AS outside_code             -- �o�ɑ��R�[�h
--            ,TRIM(xihit.inside_code)        AS inside_code              -- ���ɑ��R�[�h
--            ,xihit.invoice_date             AS invoice_date             -- �`�[���t
--            ,TRIM(xihit.column_no)          AS column_no                -- �R������
--            ,xihit.unit_price               AS unit_price               -- �P��
--            ,TRIM(xihit.hot_cold_div)       AS hot_cold_div             -- h/c
--            ,TRIM(xihit.department_flag)    AS department_flag          -- �S�ݓX�t���O
--            ,TRIM(xihit.other_base_code)    AS other_base_code          -- �����_�R�[�h
--            ,xihit.interface_date           AS interface_date           -- ��M����
---- == 2009/04/21 V1.2 Modified END   ===============================================================
--      FROM   xxcoi_in_hht_inv_transactions xihit                        -- HHT���o�ɏ��IF
--      WHERE  TRUNC( NVL(xihit.invoice_date , gd_process_date ) ) <= TRUNC( gd_process_date )
---- == 2009/05/15 V1.3 Modified START ===============================================================
----      ORDER BY
----             xihit.base_code
----            ,xihit.record_type
----            ,xihit.invoice_type
----            ,xihit.department_flag
----            ,xihit.invoice_no
----            ,xihit.column_no
----            ,xihit.item_code
--      ORDER BY
--             xihit.interface_id
-- == 2009/05/15 V1.3 Modified END   ===============================================================
      SELECT
             ROWID                          AS hht_rowid                -- ROWID
            ,xihit.interface_id             AS interface_id             -- �C���^�[�t�F�[�XID
            ,TRIM(xihit.base_code)          AS base_code                -- ���_�R�[�h
            ,TRIM(xihit.record_type)        AS record_type              -- ���R�[�h���
            ,TRIM(xihit.employee_num)       AS employee_num             -- �c�ƈ��R�[�h
            ,TRIM(xihit.invoice_no)         AS invoice_no               -- �`�[��
            ,TRIM(xihit.item_code)          AS item_code                -- �i�ڃR�[�h�i�i���R�[�h�j
            ,xihit.case_quantity            AS case_quantity            -- �P�[�X��
            ,xihit.case_in_quantity         AS case_in_quantity         -- ����
            ,xihit.quantity                 AS quantity                 -- �{��
            ,TRIM(xihit.invoice_type)       AS invoice_type             -- �`�[�敪
            ,TRIM(xihit.base_delivery_flag) AS base_delivery_flag       -- ���_�ԑq�փt���O
            ,CASE   TRIM(xihit.record_type)
                WHEN  '20'  THEN          SUBSTRB(TRIM(xihit.outside_code), -5, 5)
                WHEN  '30'  THEN
                  CASE  TRIM(xihit.invoice_type)
                    WHEN  '1'  THEN       SUBSTRB(TRIM(xihit.outside_code), -2, 2)
                    WHEN  '2'  THEN       SUBSTRB(TRIM(xihit.outside_code), -5, 5)
                    WHEN  '3'  THEN
                      CASE  TRIM(xihit.department_flag)
                        WHEN  '7'  THEN   TRIM(xihit.outside_code)
                        WHEN  '8'  THEN   TRIM(xihit.outside_code)
                        ELSE              SUBSTRB(TRIM(xihit.outside_code), -2, 2)
                      END
                    WHEN  '4'  THEN
                      CASE  TRIM(xihit.department_flag)
                        WHEN  '4'  THEN   TRIM(xihit.outside_code)
                        WHEN  '5'  THEN   SUBSTRB(TRIM(xihit.outside_code), -4, 4)
                        ELSE              SUBSTRB(TRIM(xihit.outside_code), -2, 2)
                      END
                    WHEN  '6'  THEN       SUBSTRB(TRIM(xihit.outside_code), -5, 5)
                    WHEN  '9'  THEN       SUBSTRB(TRIM(xihit.outside_code), -2, 2)
                    ELSE                  TRIM(xihit.outside_code)
                  END
                WHEN  '40'  THEN
                  CASE  TRIM(xihit.invoice_type)
                    WHEN  '0'  THEN       SUBSTRB(TRIM(xihit.outside_code), -5, 5)
                    WHEN  '1'  THEN       SUBSTRB(TRIM(xihit.outside_code), -2, 2)
                    ELSE                  TRIM(xihit.outside_code)
                  END
                ELSE                      TRIM(xihit.outside_code)
             END                            AS outside_code             -- �o�ɑ��R�[�h
            ,CASE   TRIM(xihit.record_type)
                WHEN  '30'  THEN
                  CASE  TRIM(xihit.invoice_type)
                    WHEN  '1'  THEN
                      CASE  TRIM(xihit.department_flag)
                        WHEN  '7'  THEN   SUBSTRB(TRIM(xihit.inside_code), -2, 2)
                        WHEN  '8'  THEN   SUBSTRB(TRIM(xihit.inside_code), -2, 2)
                        ELSE              SUBSTRB(TRIM(xihit.inside_code), -5, 5)
                      END
                    WHEN  '2'  THEN       SUBSTRB(TRIM(xihit.inside_code), -2, 2)
                    WHEN  '3'  THEN
                      CASE  TRIM(xihit.department_flag)
                        WHEN  '7'  THEN   TRIM(xihit.inside_code)
                        WHEN  '8'  THEN   TRIM(xihit.inside_code)
                        ELSE              SUBSTRB(TRIM(xihit.inside_code), -2, 2)
                      END
                    WHEN  '4'  THEN       TRIM(xihit.inside_code)
                    WHEN  '5'  THEN
                      CASE  TRIM(xihit.department_flag)
                        WHEN  '3'  THEN   TRIM(xihit.inside_code)
                        WHEN  '6'  THEN   SUBSTRB(TRIM(xihit.inside_code), -4, 4)
                        ELSE              SUBSTRB(TRIM(xihit.inside_code), -2, 2)
                      END
                    WHEN  '6'  THEN       TRIM(xihit.inside_code)
                    WHEN  '7'  THEN       SUBSTRB(TRIM(xihit.inside_code), -5, 5)
                    WHEN  '9'  THEN       SUBSTRB(TRIM(xihit.inside_code), -4, 4)
                    ELSE                  TRIM(xihit.inside_code)
                  END
                ELSE                      TRIM(xihit.inside_code)
             END                            AS inside_code              -- ���ɑ��R�[�h
            ,xihit.invoice_date             AS invoice_date             -- �`�[���t
            ,TRIM(xihit.column_no)          AS column_no                -- �R������
            ,xihit.unit_price               AS unit_price               -- �P��
            ,TRIM(xihit.hot_cold_div)       AS hot_cold_div             -- h/c
            ,TRIM(xihit.department_flag)    AS department_flag          -- �S�ݓX�t���O
            ,TRIM(xihit.other_base_code)    AS other_base_code          -- �����_�R�[�h
            ,xihit.interface_date           AS interface_date           -- ��M����
      FROM   xxcoi_in_hht_inv_transactions xihit                        -- HHT���o�ɏ��IF
      WHERE  TRUNC( NVL(xihit.invoice_date , gd_process_date ) ) <= TRUNC( gd_process_date )
      ORDER BY
             xihit.interface_id
-- == 2009/06/01 V1.4 Modified END   ===============================================================
      FOR UPDATE NOWAIT;
--
    no_data_expt    EXCEPTION;                                          -- �Ώۃf�[�^�Ȃ�
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
    OPEN hht_inv_if_cur;
    --
    FETCH hht_inv_if_cur BULK COLLECT INTO g_hht_inv_if_tab;
    -- �����Ώی����擾
    gn_target_cnt := g_hht_inv_if_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE hht_inv_if_cur;
    -- �����Ώی���0������
    IF ( gn_target_cnt = 0 ) THEN
        RAISE no_data_expt;
    END IF;
--
  EXCEPTION
--
    -- *** ���b�N�G���[�n���h�� ***
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( hht_inv_if_cur%ISOPEN ) THEN
        CLOSE hht_inv_if_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_msg_lock_err
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      -- �X�e�[�^�X���G���[�ɂ���
      ov_retcode := cv_status_error;
    --
    -- *** �Ώۃf�[�^�Ȃ��n���h�� ***
    WHEN no_data_expt THEN
      gv_out_msg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_msg_no_data
                     );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => gv_out_msg
      );
      -- �X�e�[�^�X�𐳏�ɂ���
      ov_retcode := cv_status_normal;
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
  END get_hht_inv_if_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_hht_inv_if_data
   * Description      : HHT���o��IF�f�[�^�Ó����`�F�b�N(B-3)
   ***********************************************************************************/
  PROCEDURE chk_hht_inv_if_data(
    in_work_count IN         NUMBER,       --   TABLE(INDEX)
    ov_errbuf     OUT nocopy VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT nocopy VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT nocopy VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_hht_inv_if_data'; -- �v���O������
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
    cv_record_type_vd       CONSTANT VARCHAR2(2) := '20';                           -- ���R�[�h��ʁFVD����
    cv_record_type_inv      CONSTANT VARCHAR2(2) := '30';                           -- ���R�[�h��ʁF���o��
    cv_record_type_sample   CONSTANT VARCHAR2(2) := '40';                           -- ���R�[�h��ʁF���{
    cv_lookup_record_type   CONSTANT VARCHAR2(23) := 'XXCOI1_HHT_INV_DATA_DIV';     -- LOOKUP_TYPE�F���R�[�h���
    cv_lookup_invoice_type  CONSTANT VARCHAR2(23) := 'XXCOI1_INVOICE_TYPE';         -- LOOKUP_TYPE�F�`�[�敪
    cv_lookup_dept_flag     CONSTANT VARCHAR2(23) := 'XXCOI1_DEPARTMENT_FLAG';      -- LOOKUP_TYPE�F�S�ݓX�׸�
    cv_lookup_hc_div        CONSTANT VARCHAR2(23) := 'XXCOI1_HOT_COLD_DIV';         -- LOOKUP_TYPE�FH/C
    cv_sales_classs_target  CONSTANT VARCHAR2(1)  := '1';                           -- ����Ώۋ敪�F�Ώ�
    cv_item_status_opm      CONSTANT VARCHAR2(10) := 'OPM';                         -- �X�e�[�^�X�FOPM
    cv_item_status_active   CONSTANT VARCHAR2(10) := 'Active';                      -- �X�e�[�^�X�FActive
    cv_flg_y                CONSTANT VARCHAR2(1)  := 'Y';                           -- �׸ޒl�FY
    --
    -- *** ���[�J���ϐ� ***
    --
    lt_lookup_meaning       fnd_lookup_values.meaning%TYPE;                         -- ں��ގ�ʊi�[�ϐ�
    lt_item_status          mtl_system_items_b.inventory_item_status_code%TYPE;     -- �i�ڽð��
    lt_cust_order_flg       mtl_system_items_b.customer_order_enabled_flag%TYPE;    -- �ڋq�󒍉\�׸�
    lt_transaction_enable   mtl_system_items_b.mtl_transactions_enabled_flag%TYPE;  -- ����\�׸�
    lt_stock_enabled_flg    mtl_system_items_b.stock_enabled_flag%TYPE;             -- �݌ɕۗL�\�׸�
    lt_return_enable        mtl_system_items_b.returnable_flag%TYPE;                -- �ԕi�\�׸�
    lt_sales_class          ic_item_mst_b.attribute26%TYPE;                         -- ����Ώۋ敪
    lt_disable_date         mtl_units_of_measure_tl.disable_date%TYPE;              -- �P�ʎ�����
    lb_org_acct_period_flg  BOOLEAN;                                                -- �����݌ɉ�v���ԃI�[�v���t���O
    lv_key_info             VARCHAR2(5000);                                         -- HHT���o�Ƀf�[�^�pKEY���
    --
    -- *** ���[�J���E��O ***
    not_null_expt           EXCEPTION;                                              -- �K�{���ڗ�O
    invalid_value_expt      EXCEPTION;                                              -- �s���l��O
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
    -- -------------------------------
    -- 1.�K�{���ڃ`�F�b�N
    -- -------------------------------
    -- (1).���R�[�h���
    IF ( g_hht_inv_if_tab( in_work_count ).record_type IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_record_type_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    -- (2).�`�[���t
    ELSIF ( g_hht_inv_if_tab( in_work_count ).invoice_date IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_invoice_date_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    -- (3).���_�R�[�h
    ELSIF ( g_hht_inv_if_tab( in_work_count ).base_code IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_base_code_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    -- (4).�o�ɑ��R�[�h
    ELSIF ( g_hht_inv_if_tab( in_work_count ).outside_code IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_outside_code_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    -- (5).���ɑ��R�[�h
    ELSIF ( g_hht_inv_if_tab( in_work_count ).inside_code IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_inside_code_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    -- (6).�i�ڃR�[�h
    ELSIF ( g_hht_inv_if_tab( in_work_count ).item_code IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_item_code_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    END IF;
    -- -------------------------------
    -- 2.�����t�K�{���ڃ`�F�b�N
    -- -------------------------------
    -- (1).�R������
    IF g_hht_inv_if_tab( in_work_count ).record_type = cv_record_type_vd
    AND  g_hht_inv_if_tab( in_work_count ).column_no IS NULL THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_column_no_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    END IF;
    -- (2).�`�[�敪
    IF g_hht_inv_if_tab( in_work_count ).record_type IN( cv_record_type_inv , cv_record_type_sample)
    AND  g_hht_inv_if_tab( in_work_count ).invoice_type IS NULL THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_invoice_type_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    END IF;
    -- (3).�c�ƈ�����
    IF g_hht_inv_if_tab( in_work_count ).record_type = cv_record_type_sample
    AND  g_hht_inv_if_tab( in_work_count ).employee_num IS NULL THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_employee_num_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    END IF;
    -- -------------------------------
    -- 3.���R�[�h��ʂ̒l�͈̓`�F�b�N
    -- -------------------------------
    -- ں��ގ�ʂ�LOOKUP���擾
    lt_lookup_meaning := xxcoi_common_pkg.get_meaning( 
                                          iv_lookup_type => cv_lookup_record_type
                                        , iv_lookup_code => g_hht_inv_if_tab( in_work_count ).record_type 
                                     );
    -- ���ʊ֐��̃��^�[���R�[�h��NULL�̏ꍇ
    IF ( lt_lookup_meaning IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_record_type_invalid_err
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).record_type
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
    -- -------------------------------
    -- 4.�`�[�敪�̒l�͈̓`�F�b�N
    -- -------------------------------
    IF g_hht_inv_if_tab( in_work_count ).invoice_type IS NOT NULL THEN
        -- �`�[�敪��LOOKUP���擾
        lt_lookup_meaning := xxcoi_common_pkg.get_meaning( 
                                              iv_lookup_type => cv_lookup_invoice_type
                                            , iv_lookup_code => g_hht_inv_if_tab( in_work_count ).invoice_type 
                                         );
        -- ���ʊ֐��̃��^�[���R�[�h��NULL�̏ꍇ
        IF ( lt_lookup_meaning IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_invoice_type_invalid_err
                     , iv_token_name1  => cv_tkn_invoice_type
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).invoice_type
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
        --
    END IF;
    -- -------------------------------
    -- 5.�S�ݓX�t���O�̒l�͈̓`�F�b�N
    -- -------------------------------
    IF g_hht_inv_if_tab( in_work_count ).department_flag IS NOT NULL THEN
        -- �S�ݓX�t���O��LOOKUP���擾
        lt_lookup_meaning := xxcoi_common_pkg.get_meaning( 
                                              iv_lookup_type => cv_lookup_dept_flag
                                            , iv_lookup_code => g_hht_inv_if_tab( in_work_count ).department_flag 
                                         );
        -- ���ʊ֐��̃��^�[���R�[�h��NULL�̏ꍇ
        IF ( lt_lookup_meaning IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_dept_flag_invalid_err
                     , iv_token_name1  => cv_tkn_dept_flag
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).department_flag
                   );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
        --
    END IF;
    -- -------------------------------
    -- 6.H/C�̒l�͈̓`�F�b�N
    -- -------------------------------
    IF g_hht_inv_if_tab( in_work_count ).hot_cold_div IS NOT NULL THEN
        -- H/C��LOOKUP���擾
        lt_lookup_meaning := xxcoi_common_pkg.get_meaning( 
                                              iv_lookup_type => cv_lookup_hc_div
                                            , iv_lookup_code => g_hht_inv_if_tab( in_work_count ).hot_cold_div );
        -- ���ʊ֐��̃��^�[���R�[�h��NULL�̏ꍇ
        IF ( lt_lookup_meaning IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_hc_div_invalid_err
                     , iv_token_name1  => cv_tkn_hc_div
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).hot_cold_div
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
        --
    END IF;
    -- -------------------------------
    -- 7.������ʂ̂O�`�F�b�N
    -- -------------------------------
    -- ���{���̎Z�o
    gn_total_quantity := ( NVL( g_hht_inv_if_tab( in_work_count ).case_quantity ,0 )
                             * NVL( g_hht_inv_if_tab( in_work_count ).case_in_quantity,0 ) ) 
                                 + NVL( g_hht_inv_if_tab( in_work_count ).quantity,0 ) ;
    -- ������쐬���Ȃ�VD����͏����i�P���AH/C�X�V�̂݁j
    IF g_hht_inv_if_tab( in_work_count ).record_type != cv_record_type_vd THEN
        -- ���{��0����
        IF gn_total_quantity = 0 THEN
        --
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_quantity_invalid_err
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        --
        END IF;
    --
    END IF;
    -- -------------------------------
    -- 8.�i�ڂ̑Ó����`�F�b�N
    -- -------------------------------
    IF g_hht_inv_if_tab( in_work_count ).item_code IS NOT NULL THEN
        --
        xxcoi_common_pkg.get_item_info2(
            iv_item_code          => g_hht_inv_if_tab( in_work_count ).item_code    -- 1.�i�ڃR�[�h
          , in_org_id             => gt_org_id                                      -- 2.�݌ɑg�DID
          , ov_item_status        => lt_item_status                                 -- 3.�i�ڃX�e�[�^�X
          , ov_cust_order_flg     => lt_cust_order_flg                              -- 4.�ڋq�󒍉\�t���O
          , ov_transaction_enable => lt_transaction_enable                          -- 5.����\
          , ov_stock_enabled_flg  => lt_stock_enabled_flg                           -- 6.�݌ɕۗL�\�t���O
          , ov_return_enable      => lt_return_enable                               -- 7.�ԕi�\
          , ov_sales_class        => lt_sales_class                                 -- 8.����Ώۋ敪
          , ov_primary_unit       => gt_primary_uom                                 -- 9.��P��
          , on_inventory_item_id  => gt_item_id                                     --10.�i��ID
          , ov_primary_uom_code   => gt_primary_uom_code                            --11.��P�ʃR�[�h
          , ov_errbuf             => lv_errbuf                                      --11.�G���[�E���b�Z�[�W
          , ov_retcode            => lv_retcode                                     --12.���^�[���E�R�[�h
          , ov_errmsg             => lv_errmsg                                      --13.���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_item_code_invalid_err
                     , iv_token_name1  => cv_tkn_item_code
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).item_code
                  );
          RAISE invalid_value_expt;
        END IF;
        -- �i�ڃX�e�[�^�X�̃`�F�b�N
        -- �L���łȂ��ꍇ
        IF ( NOT( lt_item_status IN( cv_item_status_opm , cv_item_status_active )
                  AND  lt_cust_order_flg     = cv_flg_y
                  AND  lt_transaction_enable = cv_flg_y
                  AND  lt_stock_enabled_flg  = cv_flg_y
                  AND  lt_return_enable      = cv_flg_y  ) )
        THEN
        --
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_item_statu_invalid_err
                     , iv_token_name1  => cv_tkn_item_code
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).item_code
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        --
        END IF;
        -- ����Ώۋ敪�̃`�F�b�N
        -- NULL �܂��� �ΏۂŖ����ꍇ
        IF ( ( lt_sales_class IS NULL ) OR ( lt_sales_class <> cv_sales_classs_target ) ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_sales_class_invalid_err
                     , iv_token_name1  => cv_tkn_item_code
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).item_code
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
    --
    -- -------------------------------
    -- 9.��P�ʂ̑Ó����`�F�b�N
    -- -------------------------------
        -- ��P�ʂ̖������擾
        xxcoi_common_pkg.get_uom_disable_info(
            iv_unit_code          => gt_primary_uom_code   -- 1.��P��
          , od_disable_date       => lt_disable_date       -- 2.������
          , ov_errbuf             => lv_errbuf             -- 3.�G���[�E���b�Z�[�W
          , ov_retcode            => lv_retcode            -- 4.���^�[���E�R�[�h
          , ov_errmsg             => lv_errmsg             -- 5.���[�U�[�E�G���[�E���b�Z�[�W
        );
        -- ���݃`�F�b�N
        -- ���������擾�ł��Ȃ������ꍇ
        IF ( lv_retcode != cv_status_normal ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_primary_uom_notfound_err
                     , iv_token_name1  => cv_tkn_primary_uom
                     , iv_token_value1 => gt_primary_uom_code
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
        -- �L���`�F�b�N
        -- �L���łȂ��ꍇ
        IF ( TRUNC( NVL( lt_disable_date, SYSDATE + 1 ) ) <= TRUNC( SYSDATE ) ) THEN 
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_primary_uom_invalid_err
                     , iv_token_name1  => cv_tkn_primary_uom
                     , iv_token_value1 => gt_primary_uom_code
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
    --
    END IF;
    -- -------------------------------
    -- 10.�݌ɉ�v���ԃ`�F�b�N
    -- -------------------------------
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                         -- �݌ɑg�DID
      , id_target_date     => g_hht_inv_if_tab( in_work_count ).invoice_date    -- �`�[���t
      , ob_chk_result      => lb_org_acct_period_flg                            -- �`�F�b�N����
      , ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
    );
    -- �݌ɉ�v���ԃX�e�[�^�X�̎擾�Ɏ��s�����ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_org_acct_period_err
                     , iv_token_name1  => cv_tkn_target_date
                     , iv_token_value1 => TO_CHAR( g_hht_inv_if_tab( in_work_count ).invoice_date ,'yyyymmdd' )
                   );
-- == 2010/01/29 V1.5 Modified START ===============================================================
--      RAISE global_api_expt;
      RAISE invalid_value_expt;
-- == 2010/01/29 V1.5 Modified END   ===============================================================
    END IF;
    -- �����݌ɉ�v���Ԃ��N���[�Y�̏ꍇ
    IF ( NOT lb_org_acct_period_flg ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_invoice_date_invalid_err
                     , iv_token_name1  => cv_tkn_proc_date
                     , iv_token_value1 => TO_CHAR( g_hht_inv_if_tab( in_work_count ).invoice_date ,'yyyymmdd' )
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- *** �K�{���ڗ�O�n���h�� ***
    WHEN not_null_expt THEN
        -- KEY���o��
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => g_hht_inv_if_tab( in_work_count ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => g_hht_inv_if_tab( in_work_count ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => g_hht_inv_if_tab( in_work_count ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => g_hht_inv_if_tab( in_work_count ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => g_hht_inv_if_tab( in_work_count ).item_code
                     );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_key_info || lv_errmsg );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => lv_key_info || lv_errbuf );
        --
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
    --
    -- *** �s���l��O�n���h�� ***
    WHEN invalid_value_expt THEN
        -- KEY���o��
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => g_hht_inv_if_tab( in_work_count ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => g_hht_inv_if_tab( in_work_count ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => g_hht_inv_if_tab( in_work_count ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => g_hht_inv_if_tab( in_work_count ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => g_hht_inv_if_tab( in_work_count ).item_code
                     );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_key_info || lv_errmsg );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => lv_key_info || lv_errbuf );
        --
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
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
  END chk_hht_inv_if_data;
--
  /**********************************************************************************
   * Procedure Name   : cnv_subinv_code
   * Description      : HHT���o��IF�f�[�^�̕ۊǏꏊ�R�[�h�ϊ�(B-4)
   ***********************************************************************************/
  PROCEDURE cnv_subinv_code(
    in_work_count IN         NUMBER,       --   TABLE(INDEX)
    ov_errbuf     OUT nocopy VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT nocopy VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT nocopy VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cnv_subinv_code'; -- �v���O������
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
    cv_subinv_div_other         CONSTANT VARCHAR2(1) := '9';                                -- �I���ΏہF9�i�ΏۊO�j
    cv_date_format_yyyymm       CONSTANT VARCHAR2(6) := 'yyyymm';                           -- ���t�����i�N���j
    ct_inventory_status_fix     CONSTANT xxcoi_inv_control.inventory_status%TYPE := '9';    -- �I���X�e�[�^�X�F�m���
    ct_inventory_kbn_month      CONSTANT xxcoi_inv_control.inventory_status%TYPE := '2';    -- �I���敪�F����
    --
    -- *** ���[�J���ϐ� ***
    --
    lt_outside_subinv_div       mtl_secondary_inventories.attribute1%TYPE;                  -- �o�ɑ��ۊǏꏊ�敪
    lt_inside_subinv_div        mtl_secondary_inventories.attribute1%TYPE;                  -- ���ɑ��ۊǏꏊ�敪
    ln_work_count               NUMBER;                                                     -- �I���m��ό���
    lv_key_info                 VARCHAR2(5000);                                             -- HHT���o�Ƀf�[�^�pKEY���
-- == 2010/03/23 V1.6 Added START ===============================================================
    lt_start_date_active    fnd_flex_values.start_date_active%TYPE;                         -- AFF����K�p�J�n��
-- == 2010/03/23 V1.6 Added END   ===============================================================
    --
    -- *** ���[�J���E��O ***
    cnv_subinv_expt             EXCEPTION;                                                  -- �ۊǏꏊ�ϊ���O
    inv_status_fix_expt         EXCEPTION;                                                  -- �I���m��ϗ�O
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
    -- -------------------------------
    -- 1.�ۊǏꏊ�R�[�h�ϊ�
    -- -------------------------------
    xxcoi_common_pkg.convert_subinv_code(
         ov_errbuf                      => lv_errbuf                                            -- 1.�G���[���b�Z�[�W
        ,ov_retcode                     => lv_retcode                                           -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
        ,ov_errmsg                      => lv_errmsg                                            -- 3.���[�U�[�E�G���[���b�Z�[�W
        ,iv_record_type                 => g_hht_inv_if_tab( in_work_count ).record_type        -- 4.���R�[�h���
        ,iv_invoice_type                => g_hht_inv_if_tab( in_work_count ).invoice_type       -- 5.�`�[�敪
        ,iv_department_flag             => g_hht_inv_if_tab( in_work_count ).department_flag    -- 6.�S�ݓX�t���O
        ,iv_base_code                   => g_hht_inv_if_tab( in_work_count ).base_code          -- 7.���_�R�[�h
        ,iv_outside_code                => g_hht_inv_if_tab( in_work_count ).outside_code       -- 8.�o�ɑ��R�[�h
        ,iv_inside_code                 => g_hht_inv_if_tab( in_work_count ).inside_code        -- 9.���ɑ��R�[�h
        ,id_transaction_date            => g_hht_inv_if_tab( in_work_count ).invoice_date       -- 10.�����
        ,in_organization_id             => gt_org_id                                            -- 11.�݌ɑg�DID
        ,iv_hht_form_flag               => NULL                                                 -- 12.HHT������͉�ʃt���O
        ,ov_outside_subinv_code         => gt_outside_subinv_code                               -- 13.�o�ɑ��ۊǏꏊ�R�[�h
        ,ov_inside_subinv_code          => gt_inside_subinv_code                                -- 14.���ɑ��ۊǏꏊ�R�[�h
        ,ov_outside_base_code           => gt_outside_base_code                                 -- 15.�o�ɑ����_�R�[�h
        ,ov_inside_base_code            => gt_inside_base_code                                  -- 16.���ɑ����_�R�[�h
        ,ov_outside_subinv_code_conv    => gt_outside_subinv_code_conv                          -- 17.�o�ɑ��ۊǏꏊ�ϊ��敪
        ,ov_inside_subinv_code_conv     => gt_inside_subinv_code_conv                           -- 18.���ɑ��ۊǏꏊ�ϊ��敪
        ,ov_outside_business_low_type   => gt_outside_business_low_type                         -- 19.�o�ɑ��Ƒԏ�����
        ,ov_inside_business_low_type    => gt_inside_business_low_type                          -- 20.���ɑ��Ƒԏ�����
        ,ov_outside_cust_code           => gt_outside_cust_code                                 -- 21.�o�ɑ��ڋq�R�[�h
        ,ov_inside_cust_code            => gt_inside_cust_code                                  -- 22.���ɑ��ڋq�R�[�h
        ,ov_hht_program_div             => gt_hht_program_div                                   -- 23.���o�ɃW���[�i�������敪
        ,ov_item_convert_div            => gt_item_convert_div                                  -- 24.���i�U�֋敪
        ,ov_stock_uncheck_list_div      => gt_stock_uncheck_list_div                            -- 25.���ɖ��m�F���X�g�Ώۋ敪
        ,ov_stock_balance_list_div      => gt_stock_balance_list_div                            -- 26.���ɍ��يm�F���X�g�Ώۋ敪
        ,ov_consume_vd_flag             => gt_consume_vd_flag                                   -- 27.����VD��[�Ώۃt���O
        ,ov_outside_subinv_div          => lt_outside_subinv_div                                -- 28.�o�ɑ��I���Ώ�
        ,ov_inside_subinv_div           => lt_inside_subinv_div                                 -- 29.���ɑ��I���Ώ�
      );
    --
    IF ( lv_retcode != cv_status_normal ) THEN
        RAISE cnv_subinv_expt;
    END IF;
    -- -------------------------------
    -- 2.�ۊǏꏊ�̒I���ð������
    -- -------------------------------
    -- �o�ɑ��ۊǏꏊ
    IF lt_outside_subinv_div <> cv_subinv_div_other THEN
        --
        SELECT 
                count(1)                -- 1.�I���m��ό���
        INTO
                ln_work_count           -- 1.�I���m��ό���
        FROM    
                xxcoi_inv_control xic
        WHERE   
                xic.subinventory_code    = gt_outside_subinv_code
        AND     xic.inventory_year_month = TO_CHAR(g_hht_inv_if_tab( in_work_count ).invoice_date,cv_date_format_yyyymm)
        AND     xic.inventory_kbn        = ct_inventory_kbn_month
        AND     xic.inventory_status     = ct_inventory_status_fix
        AND     ROWNUM                   = 1;
        --
        IF ln_work_count = 1 THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application_short_name
                           , iv_name         => cv_inv_status_fix_err
                           , iv_token_name1  => cv_tkn_subinv
                           , iv_token_value1 => gt_outside_subinv_code
                         );
            --
            lv_errbuf := lv_errmsg;
            RAISE inv_status_fix_expt;
        END IF;
        --
    END IF;
    -- ���ɑ��ۊǏꏊ
    IF gt_inside_subinv_code IS NOT NULL
        AND lt_inside_subinv_div <> cv_subinv_div_other THEN
        --
        SELECT 
                count(1)                -- 1.�I���m��ό���
        INTO
                ln_work_count           -- 1.�I���m��ό���
        FROM    
                xxcoi_inv_control xic
        WHERE   
                xic.subinventory_code    = gt_inside_subinv_code
        AND     xic.inventory_year_month = TO_CHAR(g_hht_inv_if_tab( in_work_count ).invoice_date,cv_date_format_yyyymm)
        AND     xic.inventory_kbn        = ct_inventory_kbn_month
        AND     xic.inventory_status     = ct_inventory_status_fix
        AND     ROWNUM                   = 1;
        --
        IF ln_work_count = 1 THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application_short_name
                           , iv_name         => cv_inv_status_fix_err
                           , iv_token_name1  => cv_tkn_subinv
                           , iv_token_value1 => gt_inside_subinv_code
                         );
            --
            lv_errbuf := lv_errmsg;
            RAISE inv_status_fix_expt;
        END IF;
        --
    END IF;
--
-- == 2010/03/23 V1.6 Added START ===============================================================
    -- -------------------------------
    -- 3.AFF����L���`�F�b�N
    -- -------------------------------
    -- �o�ɑ��ۊǏꏊ
    xxcoi_common_pkg.get_subinv_aff_active_date(
        in_organization_id     => gt_org_id                                         -- �݌ɑg�DID
      , iv_subinv_code         => gt_outside_subinv_code                            -- �ۊǏꏊ�R�[�h
      , od_start_date_active   => lt_start_date_active                              -- �K�p�J�n��
      , ov_errbuf              => lv_errbuf
      , ov_retcode             => lv_retcode
      , ov_errmsg              => lv_errmsg
    );
    -- �K�p�J�n���̎擾�Ɏ��s�����ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_get_aff_dept_date_err
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_outside_base_code
                     , iv_token_name2  => cv_tkn_slip_num
                     , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).invoice_no
                   );
      RAISE cnv_subinv_expt;
    END IF;
    -- �`�[���t��AFF����K�p�J�n���ȑO�̏ꍇ
    IF ( g_hht_inv_if_tab( in_work_count ).invoice_date < NVL( lt_start_date_active
                                                             , g_hht_inv_if_tab( in_work_count ).invoice_date ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_aff_dept_inactive_err
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_outside_base_code
                     , iv_token_name2  => cv_tkn_slip_num
                     , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).invoice_no
                   );
      lv_errbuf := lv_errmsg;
      RAISE cnv_subinv_expt;
    END IF;
    -- ���ɑ��ۊǏꏊ
    xxcoi_common_pkg.get_subinv_aff_active_date(
        in_organization_id     => gt_org_id                                         -- �݌ɑg�DID
      , iv_subinv_code         => gt_inside_subinv_code                             -- �ۊǏꏊ�R�[�h
      , od_start_date_active   => lt_start_date_active                              -- �K�p�J�n��
      , ov_errbuf              => lv_errbuf
      , ov_retcode             => lv_retcode
      , ov_errmsg              => lv_errmsg
    );
    -- �K�p�J�n���̎擾�Ɏ��s�����ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_get_aff_dept_date_err
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_inside_base_code
                     , iv_token_name2  => cv_tkn_slip_num
                     , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).invoice_no
                   );
      RAISE cnv_subinv_expt;
    END IF;
    -- �`�[���t��AFF����K�p�J�n���ȑO�̏ꍇ
    IF ( g_hht_inv_if_tab( in_work_count ).invoice_date < NVL( lt_start_date_active
                                                             , g_hht_inv_if_tab( in_work_count ).invoice_date ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_aff_dept_inactive_err
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_inside_base_code
                     , iv_token_name2  => cv_tkn_slip_num
                     , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).invoice_no
                   );
      lv_errbuf := lv_errmsg;
      RAISE cnv_subinv_expt;
    END IF;
--
-- == 2010/03/23 V1.6 Added END   ===============================================================
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--  �ۊǏꏊ�ϊ���O
    WHEN cnv_subinv_expt THEN
        -- KEY���o��
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => g_hht_inv_if_tab( in_work_count ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => g_hht_inv_if_tab( in_work_count ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => g_hht_inv_if_tab( in_work_count ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => g_hht_inv_if_tab( in_work_count ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => g_hht_inv_if_tab( in_work_count ).item_code
                     );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_key_info || lv_errmsg );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => lv_key_info || lv_errbuf );
        --
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
--  �I���m��ϗ�O
    WHEN inv_status_fix_expt THEN
        -- KEY���o��
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => g_hht_inv_if_tab( in_work_count ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => g_hht_inv_if_tab( in_work_count ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => g_hht_inv_if_tab( in_work_count ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => g_hht_inv_if_tab( in_work_count ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => g_hht_inv_if_tab( in_work_count ).item_code
                     );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_key_info || lv_errmsg );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => lv_key_info || lv_errbuf );
        --
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
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
  END cnv_subinv_code;
--
  /**********************************************************************************
   * Procedure Name   : insert_hht_inv_tran
   * Description      : HHT���o��IF�̃��R�[�h�ǉ�(B-5)
   ***********************************************************************************/
  PROCEDURE insert_hht_inv_tran(
    in_work_count IN         NUMBER,       --   TABLE(INDEX)
    ov_errbuf     OUT nocopy VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT nocopy VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT nocopy VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'insert_hht_inv_tran';  -- �v���O������
    cv_record_type_20 CONSTANT VARCHAR2(2)   := '20';                   -- ���R�[�h��ʁFVD����
    cv_dummy          CONSTANT VARCHAR2(2)   := '99';                   -- �`�[�敪�F�_�~�[
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
    cv_hht_program_div_0     CONSTANT VARCHAR2(1) := '0'; -- ���o�ɃW���[�i�������敪�F�����ΏۊO
    cv_hht_inv_tran_status_0 CONSTANT VARCHAR2(1) := '0'; -- �����X�e�[�^�X�F������
    cv_hht_inv_tran_status_1 CONSTANT VARCHAR2(1) := '1'; -- �����X�e�[�^�X�F������
    cv_hht_inv_if_status     CONSTANT VARCHAR2(1) := 'N';
    --
    -- *** ���[�J���ϐ� ***
    --
    -- *** ���[�J���E��O ***
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- -------------------------------
    -- 1.HHT���o�Ɉꎞ�\�ւ̓o�^
    -- -------------------------------
    INSERT INTO XXCOI_HHT_INV_TRANSACTIONS(
         transaction_id                                         -- 1.���o�Ɉꎞ�\ID
        ,interface_id                                           -- 2.�C���^�[�t�F�[�XID
        ,form_header_id                                         -- 3.��ʓ��͗p�w�b�_ID
        ,base_code                                              -- 4.���_�R�[�h
        ,record_type                                            -- 5.���R�[�h���
        ,employee_num                                           -- 6.�c�ƈ��R�[�h
        ,invoice_no                                             -- 7.�`�[��
        ,item_code                                              -- 8.�i�ڃR�[�h�i�i���R�[�h�j
        ,case_quantity                                          -- 9.�P�[�X��
        ,case_in_quantity                                       -- 10.����
        ,quantity                                               -- 11.�{��
        ,invoice_type                                           -- 12.�`�[�敪
        ,base_delivery_flag                                     -- 13.���_�ԑq�փt���O
        ,outside_code                                           -- 14.�o�ɑ��R�[�h
        ,inside_code                                            -- 15.���ɑ��R�[�h
        ,invoice_date                                           -- 16.�`�[���t
        ,column_no                                              -- 17.�R������
        ,unit_price                                             -- 18.�P��
        ,hot_cold_div                                           -- 19.H/C
        ,department_flag                                        -- 20.�S�ݓX�t���O
        ,interface_date                                         -- 21.��M����
        ,other_base_code                                        -- 22.�����_�R�[�h
        ,outside_subinv_code                                    -- 23.�o�ɑ��ۊǏꏊ
        ,inside_subinv_code                                     -- 24.���ɑ��ۊǏꏊ
        ,outside_base_code                                      -- 25.�o�ɑ����_
        ,inside_base_code                                       -- 26.���ɑ����_
        ,total_quantity                                         -- 27.���{��
        ,inventory_item_id                                      -- 28.�i��ID
        ,primary_uom_code                                       -- 29.��P��
        ,outside_subinv_code_conv_div                           -- 30.�o�ɑ��ۊǏꏊ�ϊ��敪
        ,inside_subinv_code_conv_div                            -- 31.���ɑ��ۊǏꏊ�ϊ��敪
        ,outside_business_low_type                              -- 32.�o�ɑ��Ƒԋ敪
        ,inside_business_low_type                               -- 33.���ɑ��Ƒԋ敪
        ,outside_cust_code                                      -- 34.�o�ɑ��ڋq�R�[�h
        ,inside_cust_code                                       -- 35.���ɑ��ڋq�R�[�h
        ,hht_program_div                                        -- 36.���o�ɃW���[�i�������敪
        ,consume_vd_flag                                        -- 37.����VD��[�Ώۃt���O
        ,item_convert_div                                       -- 38.���i�U�֋敪
        ,stock_uncheck_list_div                                 -- 39.���ɖ��m�F���X�g�Ώۋ敪
        ,stock_balance_list_div                                 -- 40.���ɍ��يm�F���X�g�Ώۋ敪
        ,status                                                 -- 41.�����X�e�[�^�X
        ,column_if_flag                                         -- 42.�R�����ʓ]���σt���O
        ,column_if_date                                         -- 43.�R�����ʓ]����
        ,sample_if_flag                                         -- 44.���{�]���σt���O
        ,sample_if_date                                         -- 45.���{�]����
        ,output_flag                                            -- 46.�o�͍σt���O
        ,last_update_date                                       -- 47.�ŏI�X�V��
        ,last_updated_by                                        -- 48.�ŏI�X�V��
        ,creation_date                                          -- 49.�쐬��
        ,created_by                                             -- 50.�쐬��
        ,last_update_login                                      -- 51.�ŏI�X�V���[�U
        ,request_id                                             -- 52.�v��ID
        ,program_application_id                                 -- 53.�v���O�����A�v���P�[�V����ID
        ,program_id                                             -- 54.�v���O����ID
        ,program_update_date                                    -- 55.�v���O�����X�V��
    )
    VALUES(
         xxcoi_hht_inv_transactions_s01.NEXTVAL                  -- 1.���o�Ɉꎞ�\ID
        ,g_hht_inv_if_tab( in_work_count ).interface_id          -- 2.�C���^�[�t�F�[�XID
        ,NULL                                                    -- 3.��ʓ��͗p�w�b�_ID
        ,g_hht_inv_if_tab( in_work_count ).base_code             -- 4.���_�R�[�h
        ,g_hht_inv_if_tab( in_work_count ).record_type           -- 5.���R�[�h���
        ,g_hht_inv_if_tab( in_work_count ).employee_num          -- 6.�c�ƈ��R�[�h
        ,g_hht_inv_if_tab( in_work_count ).invoice_no            -- 7.�`�[��
        ,g_hht_inv_if_tab( in_work_count ).item_code             -- 8.�i�ڃR�[�h�i�i���R�[�h�j
        ,g_hht_inv_if_tab( in_work_count ).case_quantity         -- 9.�P�[�X��
        ,g_hht_inv_if_tab( in_work_count ).case_in_quantity      -- 10.����
        ,g_hht_inv_if_tab( in_work_count ).quantity              -- 11.�{��
        ,DECODE( g_hht_inv_if_tab( in_work_count ).record_type
                 ,cv_record_type_20,cv_dummy, g_hht_inv_if_tab( in_work_count ).invoice_type )         -- 12.�`�[�敪
        ,g_hht_inv_if_tab( in_work_count ).base_delivery_flag    -- 13.���_�ԑq�փt���O
        ,g_hht_inv_if_tab( in_work_count ).outside_code          -- 14.�o�ɑ��R�[�h
        ,g_hht_inv_if_tab( in_work_count ).inside_code           -- 15.���ɑ��R�[�h
        ,g_hht_inv_if_tab( in_work_count ).invoice_date          -- 16.�`�[���t
        ,g_hht_inv_if_tab( in_work_count ).column_no             -- 17.�R������
        ,g_hht_inv_if_tab( in_work_count ).unit_price            -- 18.�P��
        ,g_hht_inv_if_tab( in_work_count ).hot_cold_div          -- 19.H/C
        ,g_hht_inv_if_tab( in_work_count ).department_flag       -- 20.�S�ݓX�t���O
        ,g_hht_inv_if_tab( in_work_count ).interface_date        -- 21.��M����
        ,g_hht_inv_if_tab( in_work_count ).other_base_code       -- 22.�����_�R�[�h
        ,gt_outside_subinv_code                                  -- 23.�o�ɑ��ۊǏꏊ
        ,gt_inside_subinv_code                                   -- 24.���ɑ��ۊǏꏊ
        ,gt_outside_base_code                                    -- 25.�o�ɑ����_
        ,gt_inside_base_code                                     -- 26.���ɑ����_
        ,gn_total_quantity                                       -- 27.���{��
        ,gt_item_id                                              -- 28.�i��ID
        ,gt_primary_uom_code                                     -- 29.��P��
        ,gt_outside_subinv_code_conv                             -- 30.�o�ɑ��ۊǏꏊ�ϊ��敪
        ,gt_inside_subinv_code_conv                              -- 31.���ɑ��ۊǏꏊ�ϊ��敪
        ,gt_outside_business_low_type                            -- 32.�o�ɑ��Ƒԋ敪
        ,gt_inside_business_low_type                             -- 33.���ɑ��Ƒԋ敪
        ,gt_outside_cust_code                                    -- 34.�o�ɑ��ڋq�R�[�h
        ,gt_inside_cust_code                                     -- 35.���ɑ��ڋq�R�[�h
        ,gt_hht_program_div                                      -- 36.���o�ɃW���[�i�������敪
        ,gt_consume_vd_flag                                      -- 37.����VD��[�Ώۃt���O
        ,gt_item_convert_div                                     -- 38.���i�U�֋敪
        ,gt_stock_uncheck_list_div                               -- 39.���ɖ��m�F���X�g�Ώۋ敪
        ,gt_stock_balance_list_div                               -- 40.���ɍ��يm�F���X�g�Ώۋ敪
        ,DECODE( gt_hht_program_div
                 ,cv_hht_program_div_0 ,cv_hht_inv_tran_status_1
                 ,cv_hht_inv_tran_status_0 )                     -- 41.�����X�e�[�^�X
        ,cv_hht_inv_if_status                                    -- 42.�R�����ʓ]���σt���O
        ,NULL                                                    -- 43.�R�����ʓ]����
        ,cv_hht_inv_if_status                                    -- 44.���{�]���σt���O
        ,NULL                                                    -- 45.���{�]����
        ,cv_hht_inv_if_status                                    -- 46.�o�͍σt���O
        ,SYSDATE                                                 -- 47.�ŏI�X�V��
        ,cn_last_updated_by                                      -- 48.�ŏI�X�V��
        ,SYSDATE                                                 -- 49.�쐬��
        ,cn_created_by                                           -- 50.�쐬��
        ,cn_last_update_login                                    -- 51.�ŏI�X�V���[�U
        ,cn_request_id                                           -- 52.�v��ID
        ,cn_program_application_id                               -- 53.�v���O�����A�v���P�[�V����ID
        ,cn_program_id                                           -- 54.�v���O����ID
        ,cd_program_update_date                                  -- 55.�v���O�����X�V��
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
  END insert_hht_inv_tran;
--
  /**********************************************************************************
   * Procedure Name   : del_hht_inv_if_data
   * Description      : HHT���o��IF�̃��R�[�h�폜(B-7)
   ***********************************************************************************/
  PROCEDURE del_hht_inv_if_data(
    in_work_count IN         NUMBER,       --   TABLE(INDEX)
    ov_errbuf     OUT nocopy VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT nocopy VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT nocopy VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_hht_inv_if_data'; -- �v���O������
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
    -- *** ���[�J���E��O ***
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- -------------------------------
    -- 1.HHT���o��IF�̍폜
    -- -------------------------------
    DELETE 
    FROM xxcoi_in_hht_inv_transactions xihit    
    WHERE xihit.ROWID = g_hht_inv_if_tab( in_work_count ).hht_rowid;
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
  END del_hht_inv_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT nocopy VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT nocopy VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT nocopy VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_work_count    NUMBER := 0;                       -- LOOP����
    lv_work_status   VARCHAR2(1) := cv_status_normal;   -- ����p�X�e�[�^�X
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
    -- ===========================================
    -- �������� (B-1)
    -- ===========================================
    init(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
    --
        -- �G���[�����̃J�E���g�A�b�v
        gn_error_cnt := gn_error_cnt + 1;
        -- Init�̃G���[�͏������f
        RAISE global_process_expt;
    --
    END IF;
--
    -- ===========================================
    -- HHT���o��IF�f�[�^���o (B-2)
    -- ===========================================
    get_hht_inv_if_data(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- 0���̏ꍇ�͐���
    IF ( lv_retcode = cv_status_error ) THEN
    --
        -- �G���[�����̃J�E���g�A�b�v
        gn_error_cnt := gn_error_cnt + 1;
        -- ���b�N�A�܂���OTHERS��O�̂��ߏ������f
        RAISE global_process_expt;
    --
    END IF;
    --
    <<hht_inv_if_loop>>
    FOR ln_work_count IN 1..gn_target_cnt LOOP
    -- �x���X�e�[�^�X���Z�b�g
    lv_work_status := cv_status_normal;
    -- ===========================================
    -- HHT���o��IF�f�[�^�Ó����`�F�b�N (B-3)
    -- ===========================================
        chk_hht_inv_if_data(
            ln_work_count        -- TABLE(INDEX)
          , lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �x��
        IF ( lv_retcode = cv_status_warn ) THEN
        --
            -- �G���[�����̃J�E���g�A�b�v
            gn_error_cnt := gn_error_cnt + 1;
            -- �x���X�e�[�^�X�Z�b�g
            lv_work_status := cv_status_warn;
        -- �ُ�
        ELSIF ( lv_retcode = cv_status_error ) THEN
        --
            -- �G���[�����̃J�E���g�A�b�v
            gn_error_cnt := gn_error_cnt + 1;
            -- OTHERS��O�̂��ߏ������f
            RAISE global_process_expt;
    -- ===========================================
    -- HHT���o��IF�f�[�^�̕ۊǏꏊ�R�[�h�ϊ� (B-4)
    -- ===========================================
        -- ����
        ELSE
        --
            cnv_subinv_code(
                ln_work_count        -- TABLE(INDEX)
              , lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
              , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
              , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            --
            IF ( lv_retcode = cv_status_warn ) THEN
            --
                -- �G���[�����̃J�E���g�A�b�v
                gn_error_cnt := gn_error_cnt + 1;
                -- �x���X�e�[�^�X�Z�b�g
                lv_work_status := cv_status_warn;
            --
            ELSIF ( lv_retcode = cv_status_error ) THEN
            --
                -- �G���[�����̃J�E���g�A�b�v
                gn_error_cnt := gn_error_cnt + 1;
                -- OTHERS��O�̂��ߏ������f
                RAISE global_process_expt;
            --
            END IF;
        --
        END IF;
        --
    -- ===========================================
    -- HHT���o��IF�f�[�^�� HHT���o�Ɉꎞ�\�̒ǉ� (B-5)
    -- ===========================================
        IF lv_work_status = cv_status_normal THEN
            insert_hht_inv_tran(
                    ln_work_count        -- TABLE(INDEX)
                  , lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
             --
             IF ( lv_retcode != cv_status_normal ) THEN
             -- �G���[�����̃J�E���g�A�b�v
                gn_error_cnt := gn_error_cnt + 1;
             -- OTHERS��O�̂��ߏ������f
                RAISE global_process_expt;
             END IF;
        --
    -- ===========================================
    --  HHT���o��IF�f�[�^��HHT�G���[���X�g�\�ǉ�(B-6)
    -- ===========================================
        ELSE
            -- 
            xxcoi_common_pkg.add_hht_err_list_data(
                 ov_errbuf              => lv_errbuf                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,ov_retcode             => lv_retcode                                       -- ���^�[���E�R�[�h             --# �Œ� #
                ,ov_errmsg              => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                ,iv_base_code           => g_hht_inv_if_tab( ln_work_count ).base_code      -- 1.���_�R�[�h
                ,iv_origin_shipment     => g_hht_inv_if_tab( ln_work_count ).outside_code   -- 2.�o�ɑ��R�[�h
                ,iv_data_name           => gt_file_name                                     -- 3.�t�@�C�����i���o�Ƀf�[�^�j
                ,id_transaction_date    => g_hht_inv_if_tab( ln_work_count ).invoice_date   -- 4.�`�[���t
                ,iv_entry_number        => g_hht_inv_if_tab( ln_work_count ).invoice_no     -- 5.�`�[��
                ,iv_party_num           => g_hht_inv_if_tab( ln_work_count ).inside_code    -- 6.���ɑ��R�[�h
                ,iv_performance_by_code => g_hht_inv_if_tab( ln_work_count ).employee_num   -- 7.�c�ƈ��R�[�h
                ,iv_item_code           => g_hht_inv_if_tab( ln_work_count ).item_code      -- 8.�i�ڃR�[�h
                ,iv_error_message       => lv_errmsg                                        -- 9.�G���[���e
            );
            --
            IF ( lv_retcode != cv_status_normal ) THEN
            --
                -- �G���[�����̃J�E���g�A�b�v
                gn_error_cnt := gn_error_cnt + 1;
                -- OTHERS��O�̂��ߏ������f
                RAISE global_process_expt;
            --
            END IF;
            --
        END IF;
        --
    -- ===========================================
    --  HHT���o��IF�̃��R�[�h�폜(B-7)
    -- ===========================================
        del_hht_inv_if_data(
                ln_work_count        -- TABLE(INDEX)
              , lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
              , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
              , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
             --
        IF ( lv_retcode != cv_status_normal ) THEN
        --
            -- �G���[�����̃J�E���g�A�b�v
            gn_error_cnt := gn_error_cnt + 1;
            -- OTHERS��O�̂��ߏ������f
            RAISE global_process_expt;
        --
        END IF;
    --
    END LOOP hht_inv_if_loop;
    -- ===========================================
    --  �I������(B-8)
    -- ===========================================
    -- ���폈�������̐ݒ�
    gn_normal_cnt := gn_target_cnt - gn_warn_cnt - gn_error_cnt;
    -- �x���X�e�[�^�X�ݒ�
    IF gn_error_cnt > 0 THEN
        ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf        OUT nocopy VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT nocopy  VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
END XXCOI003A12C;
/
