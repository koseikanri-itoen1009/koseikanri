CREATE OR REPLACE PACKAGE BODY XXCOI001A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI001A07C(body)
 * Description      : ���̑�����f�[�^OIF�X�V
 * MD.050           : ���̑�����f�[�^OIF�X�V MD050_COI_001_A07
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_slip_num           �Ώۓ`�[No�擾���� (A-2)
 *  get_inside_info        ���ɏ��擾���� (A-4)
 *  chk_category           ���ڃ`�F�b�N���� (A-5)
 *  ins_mtl_tran_if_tab    ���ގ��OIF�}������ (A-6)
 *  get_lock               ���b�N�擾���� (A-7)
 *  upd_storage_info_tab   ���ɏ��ꎞ�\�X�V���� (A-8)
 *  submain                ���C�������v���V�[�W��
 *                         �Z�[�u�|�C���g�ݒ� (A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������ (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/19    1.0   K.Nakamura       �V�K�쐬
 *  2009/02/12    1.1   S.Moriyama       �����e�X�g��QNo003�Ή�
 *  2009/04/28    1.2   T.Nakamura       �V�X�e���e�X�g��QT1_0640�Ή�
 *  2009/05/18    1.3   T.Nakamura       �V�X�e���e�X�g��QT1_0640�Ή�
 *  2009/11/13    1.4   N.Abe            [E_T4_00189]�i��1���ڂ�5,6�����ނƂ��ď���
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
  no_data_expt                   EXCEPTION; -- �擾����0����O
  lock_expt                      EXCEPTION; -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ���b�N�擾��O
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(100) := 'XXCOI001A07C'; -- �p�b�P�[�W
  cv_appl_short_name             CONSTANT VARCHAR2(10)  := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_application_short_name      CONSTANT VARCHAR2(10)  := 'XXCOI';        -- �A�v���P�[�V�����Z�k��
  cv_flag_on                     CONSTANT VARCHAR2(1)   := 'Y';            -- �t���OON
  cv_flag_off                    CONSTANT VARCHAR2(1)   := 'N';            -- �t���OOFF
  cv_slip_type_10                CONSTANT VARCHAR2(2)   := '10';           -- �`�[�敪 10:�H�����
  cv_slip_type_20                CONSTANT VARCHAR2(2)   := '20';           -- �`�[�敪 20:���_�ԓ���
  cv_segment1                    CONSTANT VARCHAR2(1)   := '2';            -- �i�ڋ敪  2:����
  -- ���b�Z�[�W
  cv_no_para_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_org_code_get_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_org_id_get_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_no_data_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- �Ώۃf�[�^�������b�Z�[�W
  cv_process_date_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_tran_type_id_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00012'; -- ����^�C�vID�擾�G���[���b�Z�[�W
  cv_tran_type_name_get_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00022'; -- ����^�C�v���擾�G���[���b�Z�[�W
  cv_item_category_get_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10146'; -- �i�ڋ敪�J�e�S���Z�b�g���擾�G���[���b�Z�[�W
  cv_acc_dept_code_get_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10080'; -- �o���p����R�[�h�擾�G���[���b�Z�[�W
  cv_item_found_chk_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10071'; -- �i�ڑ��݃`�F�b�N�G���[���b�Z�[�W
  cv_item_status_chk_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10072'; -- �i�ڃX�e�[�^�X�L���`�F�b�N�G���[���b�Z�[�W
  cv_primary_found_chk_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10073'; -- ��P�ʑ��݃`�F�b�N�G���[���b�Z�[�W
  cv_primary_valid_chk_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10074'; -- ��P�ʗL���`�F�b�N�G���[���b�Z�[�W
  cv_subinv_found_chk_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10075'; -- �ۊǏꏊ���݃`�F�b�N�G���[���b�Z�[�W
  cv_subinv_valid_chk_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10076'; -- �ۊǏꏊ�L���`�F�b�N�G���[���b�Z�[�W
  cv_act_type_found_chk_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10077'; -- ����Ȗڕʖ����݃`�F�b�N�G���[���b�Z�[�W
  cv_act_type_valid_chk_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10078'; -- ����Ȗڕʖ��L���`�F�b�N�G���[���b�Z�[�W
  cv_inv_acc_period_chk_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10079'; -- �`�[���t�݌ɉ�v���ԃ`�F�b�N�G���[���b�Z�[�W
  cv_table_lock_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10029'; -- ���b�N�G���[���b�Z�[�W�i���ɏ��ꎞ�\�T�}���s�j
  cv_table_lock_err_2_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10325'; -- ���b�N�G���[���b�Z�[�W�i���ɏ��ꎞ�\�j
  cv_no_data_inside_info_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10350'; -- ���ɏ��ꎞ�\�f�[�^�擾�G���[���b�Z�[�W
  -- �g�[�N��
  cv_tkn_item_code               CONSTANT VARCHAR2(20)  := 'ITEM_CODE';            -- �e�i�ڃR�[�h
  cv_tkn_org_code                CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- �݌ɑg�D�R�[�h
  cv_tkn_primary_uom             CONSTANT VARCHAR2(20)  := 'PRIMARY_UOM';          -- �����
  cv_tkn_subinventory_code       CONSTANT VARCHAR2(20)  := 'SUBINVENTORY_CODE';    -- �ۊǏꏊ�R�[�h
  cv_tkn_den_no                  CONSTANT VARCHAR2(20)  := 'DEN_NO';               -- �`�[No
  cv_tkn_entry_date              CONSTANT VARCHAR2(20)  := 'ENTRY_DATE';           -- �`�[���t
  cv_tkn_base_code               CONSTANT VARCHAR2(20)  := 'BASE_CODE';            -- ���_�R�[�h
  cv_tkn_store_code              CONSTANT VARCHAR2(20)  := 'STORE_CODE';           -- �q�ɃR�[�h(�m�F�q�ɁE�]����q��)
  cv_tkn_act_type                CONSTANT VARCHAR2(20)  := 'ACT_TYPE';             -- ���o�Ɋ���敪
  cv_tkn_pro                     CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- �v���t�@�C����
  cv_tkn_tran_type               CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- ����^�C�v��
  cv_tkn_lookup_type             CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';          -- �Q�ƃ^�C�v
  cv_tkn_lookup_code             CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';          -- �Q�ƃR�[�h
  cv_tkn_item_status             CONSTANT VARCHAR2(20)  := 'ITEM_STATUS';          -- �i�ڃX�e�[�^�X
  cv_tkn_tran_id                 CONSTANT VARCHAR2(20)  := 'TRANSACTION_ID';       -- ���ID
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ����^�C�vID�i�[�p
  TYPE gt_transaction_types_ttype IS TABLE OF mtl_transaction_types.transaction_type_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- �`�[No���R�[�h�i�[�p
  TYPE gt_slip_num_ttype IS TABLE OF xxcoi_storage_information.slip_num%TYPE INDEX BY BINARY_INTEGER;
--
  -- ���ɏ�񃌃R�[�h�i�[�p
  TYPE gr_inside_info_rec IS RECORD(
      transaction_id                      xxcoi_storage_information.transaction_id%TYPE                 -- ���ID
    , slip_num                            xxcoi_storage_information.slip_num%TYPE                       -- �`�[�ԍ�
    , slip_date                           xxcoi_storage_information.slip_date%TYPE                      -- �`�[���t
    , base_code                           xxcoi_storage_information.base_code%TYPE                      -- ���_�R�[�h
    , check_warehouse_code                xxcoi_storage_information.check_warehouse_code%TYPE           -- �m�F�q�ɃR�[�h
    , ship_warehouse_code                 xxcoi_storage_information.ship_warehouse_code%TYPE            -- �]����q�ɃR�[�h
    , parent_item_code                    xxcoi_storage_information.parent_item_code%TYPE               -- �e�i�ڃR�[�h
    , inventory_item_id                   mtl_system_items_b.inventory_item_id%TYPE                     -- �i��ID
    , item_code                           xxcoi_storage_information.item_code%TYPE                      -- �q�i�ڃR�[�h
    , material_transaction_unset_qty      xxcoi_storage_information.material_transaction_unset_qty%TYPE -- �������
    , slip_type                           xxcoi_storage_information.slip_type%TYPE                      -- �`�[�敪
    , segment1                            mtl_categories_b.segment1%TYPE                                -- �i�ڋ敪
    , ship_base_code                      xxcoi_storage_information.ship_base_code%TYPE                 -- �o�ɋ��_�R�[�h
  );
--
  TYPE gt_inside_info_ttype IS TABLE OF gr_inside_info_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_org_id                      mtl_parameters.organization_id%TYPE;                     -- �݌ɑg�DID
  gt_acc_dept_code               fnd_profile_option_values.profile_option_value%TYPE;     -- �o�����p����R�[�h
  gt_item_category_class         fnd_profile_option_values.profile_option_value%TYPE;     -- �i�ڋ敪�J�e�S���Z�b�g��
  gt_tran_type_factory_stock     mtl_transaction_types.transaction_type_id%TYPE;          -- ����^�C�vID �H�����
  gt_tran_type_factory_stock_b   mtl_transaction_types.transaction_type_id%TYPE;          -- ����^�C�vID �H����ɐU��
  gt_tran_type_inout             mtl_transaction_types.transaction_type_id%TYPE;          -- ����^�C�vID ���o��
  gt_tran_type_pack_receive      mtl_transaction_types.transaction_type_id%TYPE;          -- ����^�C�vID ����ޗ��ꎞ���
  gt_tran_type_pack_receive_b    mtl_transaction_types.transaction_type_id%TYPE;          -- ����^�C�vID ����ޗ��ꎞ����U��
  gt_tran_type_transfer_cost     mtl_transaction_types.transaction_type_id%TYPE;          -- ����^�C�vID ����ޗ������U��
  gt_tran_type_transfer_cost_b   mtl_transaction_types.transaction_type_id%TYPE;          -- ����^�C�vID ����ޗ������U�֐U��
  gd_date                        DATE;                                                    -- �Ɩ����t
  gt_primary_uom_code            mtl_system_items_b.primary_uom_code%TYPE;                -- ��P�ʃR�[�h
  gt_sec_inv_nm                  mtl_secondary_inventories.secondary_inventory_name%TYPE; -- �ۊǏꏊ�R�[�h
  gt_sec_inv_nm_2                mtl_secondary_inventories.secondary_inventory_name%TYPE; -- �ۊǏꏊ�R�[�h(�`�[�敪���u20�v)
  gn_disposition_id              mtl_generic_dispositions.disposition_id%TYPE;            -- ����Ȗڕʖ�ID
  gn_disposition_id_2            mtl_generic_dispositions.disposition_id%TYPE;            -- ����Ȗڕʖ�ID(����ޗ������U��)
  -- �J�E���^
  gn_slip_loop_cnt               NUMBER; -- �`�[�P�ʃ��[�v�J�E���^
  gn_inside_info_loop_cnt        NUMBER; -- ���ID�P�ʃ��[�v�J�E���^
  gn_inside_info_cnt             NUMBER; -- ���ID�P�ʃJ�E���^
  gn_err_flag_cnt                NUMBER; -- �G���[���ʗp�J�E���^
  -- PL/SQL�\
  gt_transaction_types_tab       gt_transaction_types_ttype;
  gt_slip_num_tab                gt_slip_num_ttype;
  gt_inside_info_tab             gt_inside_info_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �v���t�@�C��
    cv_prf_org_code                CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';   -- �݌ɑg�D�R�[�h
    cv_prf_acc_dept_code           CONSTANT VARCHAR2(30) := 'XXCOI1_ACCOUT_DEPT_CODE';    -- �o�����p����R�[�h
    cv_prf_item_category_class     CONSTANT VARCHAR2(30) := 'XXCOI1_ITEM_CATEGORY_CLASS'; -- �i�ڋ敪�J�e�S���Z�b�g��
    -- �Q�ƃ^�C�v ���[�U�[��`����^�C�v����
    cv_tran_type                   CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME';
    -- �Q�ƃR�[�h
    cv_tran_type_factory_stock     CONSTANT VARCHAR2(3)  := '150'; -- ����^�C�v �R�[�h �H�����
    cv_tran_type_factory_stock_b   CONSTANT VARCHAR2(3)  := '160'; -- ����^�C�v �R�[�h �H����ɐU��
    cv_tran_type_inout             CONSTANT VARCHAR2(3)  := '10';  -- ����^�C�v �R�[�h ���o��
    cv_tran_type_pack_receive      CONSTANT VARCHAR2(3)  := '250'; -- ����^�C�v �R�[�h ����ޗ��ꎞ���
    cv_tran_type_pack_receive_b    CONSTANT VARCHAR2(3)  := '260'; -- ����^�C�v �R�[�h ����ޗ��ꎞ����U��
    cv_tran_type_transfer_cost     CONSTANT VARCHAR2(3)  := '270'; -- ����^�C�v �R�[�h ����ޗ������U��
    cv_tran_type_transfer_cost_b   CONSTANT VARCHAR2(3)  := '280'; -- ����^�C�v �R�[�h ����ޗ������U�֐U��
--
    -- *** ���[�J���ϐ� ***
    lt_org_code                    mtl_parameters.organization_code%TYPE;            -- �݌ɑg�D�R�[�h
    lt_tran_type_factory_stock     mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �H�����
    lt_tran_type_factory_stock_b   mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �H����ɐU��
    lt_tran_type_inout             mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� ���o��
    lt_tran_type_pack_receive      mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� ����ޗ��ꎞ���
    lt_tran_type_pack_receive_b    mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� ����ޗ��ꎞ����U��
    lt_tran_type_transfer_cost     mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� ����ޗ������U��
    lt_tran_type_transfer_cost_b   mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� ����ޗ������U�֐U��
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
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W���O�o��
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
    -- ����^�C�v���擾�i�H����Ɂj
    -- ===============================
    lt_tran_type_factory_stock := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_stock );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_factory_stock IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_stock
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i�H����Ɂj
    -- ===============================
    gt_tran_type_factory_stock := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_stock );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_factory_stock IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_stock
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i�H����ɐU�߁j
    -- ===============================
    lt_tran_type_factory_stock_b := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_stock_b );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_factory_stock_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_stock_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i�H����ɐU�߁j
    -- ===============================
    gt_tran_type_factory_stock_b := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_stock_b );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_factory_stock_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_stock_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i���o�Ɂj
    -- ===============================
    lt_tran_type_inout := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_inout );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_inout IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_inout
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i���o�Ɂj
    -- ===============================
    gt_tran_type_inout := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_inout );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_inout IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_inout
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i����ޗ��ꎞ����j
    -- ===============================
    lt_tran_type_pack_receive := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_pack_receive );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_pack_receive IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_pack_receive
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i����ޗ��ꎞ����j
    -- ===============================
    gt_tran_type_pack_receive := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_pack_receive );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_pack_receive IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_pack_receive
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i����ޗ��ꎞ����U�߁j
    -- ===============================
    lt_tran_type_pack_receive_b := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_pack_receive_b );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_pack_receive_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_pack_receive_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i����ޗ��ꎞ����U�߁j
    -- ===============================
    gt_tran_type_pack_receive_b := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_pack_receive_b );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_pack_receive_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_pack_receive_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i����ޗ������U�ցj
    -- ===============================
    lt_tran_type_transfer_cost := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_transfer_cost );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_transfer_cost IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_transfer_cost
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i����ޗ������U�ցj
    -- ===============================
    gt_tran_type_transfer_cost := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_transfer_cost );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_transfer_cost IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_transfer_cost
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i����ޗ������U�֐U�߁j
    -- ===============================
    lt_tran_type_transfer_cost_b := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_transfer_cost_b );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_transfer_cost_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_transfer_cost_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i����ޗ������U�֐U�߁j
    -- ===============================
    gt_tran_type_transfer_cost_b := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_transfer_cost_b );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_transfer_cost_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_transfer_cost_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �Ɩ����t�擾
    -- ===============================
    gd_date := xxccp_common_pkg2.get_process_date;
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gd_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_process_date_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���擾�F�o�����p����R�[�h
    -- ===============================
    gt_acc_dept_code := fnd_profile.value( cv_prf_acc_dept_code );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_acc_dept_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_acc_dept_code_get_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_acc_dept_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���擾�F�i�ڋ敪�J�e�S���Z�b�g��
    -- ===============================
    gt_item_category_class := fnd_profile.value( cv_prf_item_category_class );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_item_category_class IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_item_category_get_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_item_category_class
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
    WHEN global_api_expt THEN
    -- *** ���ʊ֐���O�n���h�� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Description      : �Ώۓ`�[No�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_slip_num(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_slip_num'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �`�[�P�ʎ擾
    CURSOR slip_num_cur
    IS
      SELECT  DISTINCT xsi.slip_num             AS slip_num                      -- �`�[No
      FROM    xxcoi_storage_information         xsi                              -- ���ɏ��ꎞ�\
      WHERE   xsi.store_check_flag              = cv_flag_on                     -- ���Ɋm�F�t���O
      AND     xsi.material_transaction_set_flag = cv_flag_off                    -- ���ގ���A�g�σt���O
      AND ( ( xsi.slip_type                     = cv_slip_type_10 )              -- �`�[�敪���u10�v
      OR  ( ( xsi.slip_type                     = cv_slip_type_20 )              -- �`�[�敪���u20�v
      AND   ( xsi.check_warehouse_code          <> xsi.ship_warehouse_code ) ) ) -- �m�F�q�ɃR�[�h <> �]����q�ɃR�[�h
      ORDER BY xsi.slip_num                                                      -- �`�[No
    ;
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
    -- �J�[�\���I�[�v��
    OPEN slip_num_cur;
--
    -- ���R�[�h�ǂݍ���
    FETCH slip_num_cur BULK COLLECT INTO gt_slip_num_tab;
--
    -- �Ώی����Z�b�g
    gn_target_cnt := gt_slip_num_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE slip_num_cur;
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
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_slip_num;
--
  /**********************************************************************************
   * Procedure Name   : get_inside_info
   * Description      : ���ɏ��擾���� (A-4)
   ***********************************************************************************/
  PROCEDURE get_inside_info(
    gn_slip_loop_cnt IN  NUMBER,       --   �`�[�P�ʃ��[�v�J�E���^
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inside_info'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���ID�P�ʎ擾
    CURSOR inside_info_cur
    IS
      SELECT
              xsi.transaction_id                 AS transaction_id                               -- ���ID
            , xsi.slip_num                       AS slip_num                                     -- �`�[No
            , xsi.slip_date                      AS slip_date                                    -- �`�[���t
            , xsi.base_code                      AS base_code                                    -- ���_�R�[�h
            , xsi.check_warehouse_code           AS check_warehouse_code                         -- �m�F�q�ɃR�[�h
            , xsi.ship_warehouse_code            AS ship_warehouse_code                          -- �]����q�ɃR�[�h
            , xsi.parent_item_code               AS parent_item_code                             -- �e�i�ڃR�[�h
            , msib.inventory_item_id             AS inventory_item_id                            -- �i��ID
            , xsi.item_code                      AS item_code                                    -- �q�i�ڃR�[�h
            , xsi.material_transaction_unset_qty AS material_transaction_unset_qty               -- ���ގ�����A�g���� 
            , xsi.slip_type                      AS slip_type                                    -- �`�[�敪
-- == 2009/11/13 V1.4 Modified START =============================================================
--            , mcb.segment1                       AS segment1                                     -- �i�ڋ敪
            , DECODE(SUBSTRB(xsi.parent_item_code, 1, 1), '5', '2'
                                                        , '6', '2'
                                                        , mcb.segment1) AS segment1              -- �i�ڋ敪
-- == 2009/11/13 V1.4 Modified END   =============================================================
            , xsi.ship_base_code                 AS ship_base_code                               -- �o�ɋ��_�R�[�h
      FROM
              xxcoi_storage_information          xsi                                             -- ���ɏ��ꎞ�\
            , mtl_system_items_b                 msib                                            -- Disc�i�ڃ}�X�^
            , mtl_category_sets_tl               mcst                                            -- �i�ڃJ�e�S���Z�b�g
            , mtl_item_categories                mic                                             -- �i�ڃJ�e�S������
            , mtl_categories_b                   mcb                                             -- �i�ڃJ�e�S��
      WHERE
              xsi.slip_num                       = gt_slip_num_tab( gn_slip_loop_cnt )           -- �`�[No
      AND     xsi.store_check_flag               = cv_flag_on                                    -- ���Ɋm�F�t���O���uY�v
      AND     xsi.material_transaction_set_flag  = cv_flag_off                                   -- ���ގ���A�g�σt���O
      AND ( ( xsi.slip_type                      = cv_slip_type_10 )                             -- �`�[�敪���u10�v
      OR  ( ( xsi.slip_type                      = cv_slip_type_20 )                             -- �`�[�敪���u20�v
      AND   ( xsi.check_warehouse_code           <> xsi.ship_warehouse_code ) ) )                -- �m�F�q�ɃR�[�h <> �]����q�ɃR�[�h
      AND     msib.segment1                      = xsi.parent_item_code                          -- �e�i�ڃR�[�h
      AND     msib.organization_id               = gt_org_id                                     -- �݌ɑg�DID
      AND     mcst.category_set_name             = gt_item_category_class                        -- �J�e�S���Z�b�g��
      AND     mcst.language                      = USERENV('LANG')                               -- ����
      AND     mic.category_set_id                = mcst.category_set_id                          -- �J�e�S���Z�b�gID
      AND     mic.inventory_item_id              = msib.inventory_item_id                        -- �i��ID
      AND     mic.organization_id                = msib.organization_id                          -- �݌ɑg�DID
      AND     mcb.category_id                    = mic.category_id                               -- �J�e�S��ID
      AND     mcb.enabled_flag                   = cv_flag_on                                    -- �g�p�\�t���O
      AND     gd_date                            < NVL( TRUNC( mcb.disable_date ), gd_date + 1 ) -- ������
-- == 2009/11/13 V1.4 Added START =============================================================
      UNION
      SELECT
              xsi.transaction_id                 AS transaction_id                               -- ���ID
            , xsi.slip_num                       AS slip_num                                     -- �`�[No
            , xsi.slip_date                      AS slip_date                                    -- �`�[���t
            , xsi.base_code                      AS base_code                                    -- ���_�R�[�h
            , xsi.check_warehouse_code           AS check_warehouse_code                         -- �m�F�q�ɃR�[�h
            , xsi.ship_warehouse_code            AS ship_warehouse_code                          -- �]����q�ɃR�[�h
            , xsi.parent_item_code               AS parent_item_code                             -- �e�i�ڃR�[�h
            , msib.inventory_item_id             AS inventory_item_id                            -- �i��ID
            , xsi.item_code                      AS item_code                                    -- �q�i�ڃR�[�h
            , xsi.material_transaction_unset_qty AS material_transaction_unset_qty               -- ���ގ�����A�g���� 
            , xsi.slip_type                      AS slip_type                                    -- �`�[�敪
            , '2'                                AS segment1                                     -- �i�ڋ敪
            , xsi.ship_base_code                 AS ship_base_code                               -- �o�ɋ��_�R�[�h
      FROM
              xxcoi_storage_information          xsi                                             -- ���ɏ��ꎞ�\
            , mtl_system_items_b                 msib                                            -- Disc�i�ڃ}�X�^
      WHERE
              xsi.slip_num                       = gt_slip_num_tab( gn_slip_loop_cnt )           -- �`�[No
      AND     xsi.store_check_flag               = cv_flag_on                                    -- ���Ɋm�F�t���O���uY�v
      AND     xsi.material_transaction_set_flag  = cv_flag_off                                   -- ���ގ���A�g�σt���O
      AND ( ( xsi.slip_type                      = cv_slip_type_10 )                             -- �`�[�敪���u10�v
      OR  ( ( xsi.slip_type                      = cv_slip_type_20 )                             -- �`�[�敪���u20�v
      AND   ( xsi.check_warehouse_code           <> xsi.ship_warehouse_code ) ) )                -- �m�F�q�ɃR�[�h <> �]����q�ɃR�[�h
      AND     msib.segment1                      = xsi.parent_item_code                          -- �e�i�ڃR�[�h
      AND     msib.organization_id               = gt_org_id                                     -- �݌ɑg�DID
      AND   ( msib.segment1                      LIKE '5%'
      OR      msib.segment1                      LIKE '6%' )
-- == 2009/11/13 V1.4 Added END   =============================================================
-- == 2009/04/28 V1.2 Added START ===============================================================
-- == 2009/05/18 V1.3 Deleted START =============================================================
--      AND     xsi.material_transaction_unset_qty <> 0                                            -- ���ގ�����A�g���� <> 0
-- == 2009/05/18 V1.3 Deleted END   =============================================================
-- == 2009/04/28 V1.2 Added END   ===============================================================
    ;
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
    -- ���ID�P�ʌ���������
    gn_inside_info_cnt := 0;
--
    -- �J�[�\���I�[�v��
    OPEN inside_info_cur;
--
    -- ���R�[�h�ǂݍ���
    FETCH inside_info_cur BULK COLLECT INTO gt_inside_info_tab;
--
    -- ���ID�P�ʌ����Z�b�g
    gn_inside_info_cnt := gt_inside_info_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE inside_info_cur;
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
      IF ( inside_info_cur%ISOPEN ) THEN
        CLOSE inside_info_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( inside_info_cur%ISOPEN ) THEN
        CLOSE inside_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( inside_info_cur%ISOPEN ) THEN
        CLOSE inside_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inside_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_category
   * Description      : ���ڃ`�F�b�N���� (A-5)
   ***********************************************************************************/
  PROCEDURE chk_category(
    gn_inside_info_loop_cnt  IN   NUMBER,    -- ���ID�P�ʃ��[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_category'; -- �v���O������
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
    cv_inactive                  CONSTANT VARCHAR2(10) := 'Inactive'; -- �i�ڃX�e�[�^�X Inactive
    cv_sales_class_1             CONSTANT VARCHAR2(1)  := '1';        -- �i�ڃX�e�[�^�X 1:�Ώ�
    cv_inv_account_kbn_01        CONSTANT VARCHAR2(2)  := '01';       -- ���o�Ɋ���敪 01
    cv_inv_account_kbn_02        CONSTANT VARCHAR2(2)  := '02';       -- ���o�Ɋ���敪 02
    cv_inv_account_kbn_21        CONSTANT VARCHAR2(2)  := '21';       -- ���o�Ɋ���敪 21
--
    -- *** ���[�J���ϐ� ***
    -- �i�ڃ`�F�b�N
    lt_item_status               mtl_system_items_b.inventory_item_status_code%TYPE;    -- �i�ڃX�e�[�^�X
    lt_cust_order_flg            mtl_system_items_b.customer_order_enabled_flag%TYPE;   -- �ڋq�󒍉\�t���O
    lt_transaction_enable        mtl_system_items_b.mtl_transactions_enabled_flag%TYPE; -- ����\
    lt_stock_enabled_flg         mtl_system_items_b.stock_enabled_flag%TYPE;            -- �݌ɕۗL�\�t���O
    lt_return_enable             mtl_system_items_b.returnable_flag%TYPE;               -- �ԕi�\
    lt_sales_class               ic_item_mst_b.attribute26%TYPE;                        -- ����Ώۋ敪
    lt_primary_unit              mtl_system_items_b.primary_unit_of_measure%TYPE;       -- ��P��
    lt_inventory_item_id         mtl_system_items_b.inventory_item_id%TYPE;             -- �i��ID
    -- ��P�ʃ`�F�b�N
    lt_disable_date              mtl_units_of_measure_tl.disable_date%TYPE;             -- ������
    -- �ۊǏꏊ�R�[�h�`�F�b�N
    lt_sec_inv_disable_date      mtl_secondary_inventories.disable_date%TYPE;           -- ������
    -- �݌ɉ�v���ԃ`�F�b�N
    lb_chk_result                BOOLEAN;                                               -- �X�e�[�^�X
    --
    lv_disposition_id_chk_flag   VARCHAR2(1); -- ����Ȗڕʖ�ID�`�F�b�N�G���[���ʗp�t���O
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
    -- �ϐ��̏�����
    -- �i�ڃ`�F�b�N
    lt_item_status             := NULL; -- �i�ڃX�e�[�^�X
    lt_cust_order_flg          := NULL; -- �ڋq�󒍉\�t���O
    lt_transaction_enable      := NULL; -- ����\
    lt_stock_enabled_flg       := NULL; -- �݌ɕۗL�\�t���O
    lt_return_enable           := NULL; -- �ԕi�\
    lt_sales_class             := NULL; -- ����Ώۋ敪
    lt_primary_unit            := NULL; -- ��P��
    lt_inventory_item_id       := NULL; -- �i��ID
    -- ��P�ʃ`�F�b�N
    gt_primary_uom_code        := NULL; -- ��P�ʃR�[�h
    lt_disable_date            := NULL; -- ������
    -- �ۊǏꏊ�R�[�h�`�F�b�N
    gt_sec_inv_nm              := NULL; -- �ۊǏꏊ�R�[�h
    gt_sec_inv_nm_2            := NULL; -- �ۊǏꏊ�R�[�h(�`�[�敪���u20�v)
    lt_sec_inv_disable_date    := NULL; -- ������
    -- ����Ȗڕʖ��`�F�b�N
    gn_disposition_id          := NULL; -- ����Ȗڕʖ�ID
    gn_disposition_id_2        := NULL; -- ����Ȗڕʖ�ID(����ޗ������U��)
    -- �݌ɉ�v���ԃ`�F�b�N
    lb_chk_result              := TRUE; -- �X�e�[�^�X
    --
    lv_disposition_id_chk_flag := cv_flag_off; -- ����Ȗڕʖ�ID�`�F�b�N�G���[���ʗp�t���O
--
    -- ===============================
    -- �i�ڃ`�F�b�N
    -- ===============================
    xxcoi_common_pkg.get_item_info2(
        iv_item_code          => gt_inside_info_tab( gn_inside_info_loop_cnt ).parent_item_code -- �i�ڃR�[�h
      , in_org_id             => gt_org_id                                                      -- �݌ɑg�DID
      , ov_item_status        => lt_item_status                                                 -- �i�ڃX�e�[�^�X
      , ov_cust_order_flg     => lt_cust_order_flg                                              -- �ڋq�󒍉\�t���O
      , ov_transaction_enable => lt_transaction_enable                                          -- ����\
      , ov_stock_enabled_flg  => lt_stock_enabled_flg                                           -- �݌ɕۗL�\�t���O
      , ov_return_enable      => lt_return_enable                                               -- �ԕi�\
      , ov_sales_class        => lt_sales_class                                                 -- ����Ώۋ敪(�g�p���Ȃ�)
      , ov_primary_unit       => lt_primary_unit                                                -- ��P��(�g�p���Ȃ�)
      , on_inventory_item_id  => lt_inventory_item_id                                           -- �i��ID(�g�p���Ȃ�)
      , ov_primary_uom_code   => gt_primary_uom_code                                            -- ��P�ʃR�[�h
      , ov_errbuf             => lv_errbuf                                                      -- �G���[���b�Z�[�W
      , ov_retcode            => lv_retcode                                                     -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                                      -- ���[�U�[�E�G���[���b�Z�[�W
   );
--
    -- �߂�l�̕i�ڃX�e�[�^�X��NULL�̏ꍇ
    IF ( lt_item_status IS NULL ) THEN
      -- �i�ڑ��݃`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_item_found_chk_err_msg
                      , iv_token_name1  => cv_tkn_item_code
                      , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).parent_item_code
                      , iv_token_name2  => cv_tkn_den_no
                      , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --�G���[���b�Z�[�W
      );
    END IF;
--
    -- �߂�l�̕i�ڃX�e�[�^�X���uInactive�v���ڋq�󒍉\�t���O���uY�v������\���uY�v����
    -- �݌ɕۗL�\�t���O���uY�v���ԕi�\���uY�v�ȊO�̏ꍇ
    IF ( ( lt_item_status         =  cv_inactive )
      AND ( lt_cust_order_flg     =  cv_flag_on )
      AND ( lt_transaction_enable =  cv_flag_on )
      AND ( lt_stock_enabled_flg  =  cv_flag_on )
      AND ( lt_return_enable      <> cv_flag_on ) ) THEN
      -- �i�ڃX�e�[�^�X�L���`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_item_status_chk_err_msg
                      , iv_token_name1  => cv_tkn_item_code
                      , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).parent_item_code
                      , iv_token_name2  => cv_tkn_item_status
                      , iv_token_value2 => lt_item_status
                      , iv_token_name3  => cv_tkn_den_no
                      , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --�G���[���b�Z�[�W
      );
    END IF;
--
    -- �i�ڃX�e�[�^�X��NULL�̏ꍇ�̓X�L�b�v
    IF ( lt_item_status IS NOT NULL ) THEN
      -- ===============================
      -- ��P�ʃ`�F�b�N
      -- ===============================
      xxcoi_common_pkg.get_uom_disable_info(
          iv_unit_code    => gt_primary_uom_code -- �P�ʃR�[�h
        , od_disable_date => lt_disable_date     -- ������
        , ov_errbuf       => lv_errbuf           -- �G���[���b�Z�[�W
        , ov_retcode      => lv_retcode          -- ���^�[���E�R�[�h
        , ov_errmsg       => lv_errmsg           -- ���[�U�[�E�G���[���b�Z�[�W
      );
  --
      -- �߂�l�̃��^�[���E�R�[�h���u0�v�i����j�ȊO�̏ꍇ
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- ��P�ʑ��݃`�F�b�N�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_primary_found_chk_err_msg
                        , iv_token_name1  => cv_tkn_primary_uom
                        , iv_token_value1 => gt_primary_uom_code
                        , iv_token_name2  => cv_tkn_den_no
                        , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --�G���[���b�Z�[�W
        );
      -- �߂�l�̖�������TRUNC(NVL(������, �V�X�e�����t+1)) <= TRUNC(�V�X�e�����t)�̏ꍇ
      ELSIF ( TRUNC( NVL( lt_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
        -- ��P�ʗL���`�F�b�N�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_primary_valid_chk_err_msg
                        , iv_token_name1  => cv_tkn_primary_uom
                        , iv_token_value1 => gt_primary_uom_code
                        , iv_token_name2  => cv_tkn_den_no
                        , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --�G���[���b�Z�[�W
        );
      END IF;
--
    END IF;
--
    -- ===============================
    -- �ۊǏꏊ�R�[�h�`�F�b�N
    -- ===============================
    -- �`�[�敪���u10�v�i�H����Ɂj�̏ꍇ
    IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 ) THEN
--
      -- �]����q�ɃR�[�h��NULL�̏ꍇ
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code IS NULL ) THEN
--
        -- �ۊǏꏊ�R�[�h�̃`�F�b�N
        xxcoi_common_pkg.get_subinventory_info1(
            iv_base_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code            -- ���_�R�[�h
          , iv_whse_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).check_warehouse_code -- �m�F�q�ɃR�[�h
          , ov_sec_inv_nm   => gt_sec_inv_nm                                                      -- �ۊǏꏊ�R�[�h
          , od_disable_date => lt_sec_inv_disable_date                                            -- ������
          , ov_errbuf       => lv_errbuf                                                          -- �G���[���b�Z�[�W
          , ov_retcode      => lv_retcode                                                         -- ���^�[���E�R�[�h
          , ov_errmsg       => lv_errmsg                                                          -- ���[�U�[�E�G���[���b�Z�[�W
        );
--
        -- �߂�l�̕ۊǏꏊ�R�[�h��NULL�̏ꍇ
        IF ( gt_sec_inv_nm IS NULL ) THEN
          -- �ۊǏꏊ���݃`�F�b�N�G���[
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_subinv_found_chk_err_msg
                          , iv_token_name1  => cv_tkn_base_code
                          , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                          , iv_token_name2  => cv_tkn_store_code
                          , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).check_warehouse_code
                          , iv_token_name3  => cv_tkn_den_no
                          , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                        );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --�G���[���b�Z�[�W
          );
        -- �߂�l�̖�������TRUNC(NVL(������, �V�X�e�����t+1)) <= TRUNC(�V�X�e�����t)�̏ꍇ
        ELSIF ( TRUNC( NVL( lt_sec_inv_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
          -- �ۊǏꏊ�L���`�F�b�N�G���[
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_subinv_valid_chk_err_msg
                          , iv_token_name1  => cv_tkn_subinventory_code
                          , iv_token_value1 => gt_sec_inv_nm
                          , iv_token_name2  => cv_tkn_den_no
                          , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                        );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --�G���[���b�Z�[�W
          );
        END IF;
--
      -- �]����q�ɃR�[�h��NULL�łȂ��ꍇ
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code IS NOT NULL ) THEN
--
        -- �ۊǏꏊ�R�[�h�̃`�F�b�N
        xxcoi_common_pkg.get_subinventory_info2(
            iv_base_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code           -- ���_�R�[�h
          , iv_shop_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code -- �]����q�ɃR�[�h
          , ov_sec_inv_nm   => gt_sec_inv_nm                                                     -- �ۊǏꏊ�R�[�h
          , od_disable_date => lt_sec_inv_disable_date                                           -- ������
          , ov_errbuf       => lv_errbuf                                                         -- �G���[���b�Z�[�W
          , ov_retcode      => lv_retcode                                                        -- ���^�[���E�R�[�h
          , ov_errmsg       => lv_errmsg                                                         -- ���[�U�[�E�G���[���b�Z�[�W
        );
--
        -- �߂�l�̕ۊǏꏊ�R�[�h��NULL�̏ꍇ
        IF ( gt_sec_inv_nm IS NULL ) THEN
          -- �ۊǏꏊ���݃`�F�b�N�G���[
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_subinv_found_chk_err_msg
                          , iv_token_name1  => cv_tkn_base_code
                          , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                          , iv_token_name2  => cv_tkn_store_code
                          , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code
                          , iv_token_name3  => cv_tkn_den_no
                          , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                        );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --�G���[���b�Z�[�W
          );
        -- �߂�l�̖�������TRUNC(NVL(������, �V�X�e�����t+1)) <= TRUNC(�V�X�e�����t)�̏ꍇ
        ELSIF ( TRUNC( NVL( lt_sec_inv_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
          -- �ۊǏꏊ�L���`�F�b�N�G���[
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_subinv_valid_chk_err_msg
                          , iv_token_name1  => cv_tkn_subinventory_code
                          , iv_token_value1 => gt_sec_inv_nm
                          , iv_token_name2  => cv_tkn_den_no
                          , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                        );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --�G���[���b�Z�[�W
          );
        END IF;
--
      END IF;
--
    -- �`�[�敪���u20�v�i���_�ԓ��Ɂj�̏ꍇ
    ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_20 ) THEN
--
      -- �m�F�q�ɃR�[�h�ɕR�Â��ۊǏꏊ�R�[�h�̃`�F�b�N
      xxcoi_common_pkg.get_subinventory_info1(
          iv_base_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code            -- ���_�R�[�h
        , iv_whse_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).check_warehouse_code -- �m�F�q�ɃR�[�h
        , ov_sec_inv_nm   => gt_sec_inv_nm_2                                                    -- �ۊǏꏊ�R�[�h
        , od_disable_date => lt_sec_inv_disable_date                                            -- ������
        , ov_errbuf       => lv_errbuf                                                          -- �G���[���b�Z�[�W
        , ov_retcode      => lv_retcode                                                         -- ���^�[���E�R�[�h
        , ov_errmsg       => lv_errmsg                                                          -- ���[�U�[�E�G���[���b�Z�[�W
      );
--
      -- �߂�l�̕ۊǏꏊ�R�[�h��NULL�̏ꍇ
      IF ( gt_sec_inv_nm_2 IS NULL ) THEN
        -- �ۊǏꏊ���݃`�F�b�N�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_subinv_found_chk_err_msg
                        , iv_token_name1  => cv_tkn_base_code
                        , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                        , iv_token_name2  => cv_tkn_store_code
                        , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).check_warehouse_code
                        , iv_token_name3  => cv_tkn_den_no
                        , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --�G���[���b�Z�[�W
        );
      -- �߂�l�̖�������TRUNC(NVL(������, �V�X�e�����t+1)) <= TRUNC(�V�X�e�����t)�̏ꍇ
      ELSIF ( TRUNC( NVL( lt_sec_inv_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
        -- �ۊǏꏊ�L���`�F�b�N�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_subinv_valid_chk_err_msg
                        , iv_token_name1  => cv_tkn_subinventory_code
                        , iv_token_value1 => gt_sec_inv_nm_2
                        , iv_token_name2  => cv_tkn_den_no
                        , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --�G���[���b�Z�[�W
        );
      END IF;
--
      -- �ۊǏꏊ�R�[�h��NULL�̏ꍇ�̓X�L�b�v
      IF ( gt_sec_inv_nm_2 IS NOT NULL ) THEN
--
        -- ���[�J���ϐ��̏�����(������)
        lt_sec_inv_disable_date := NULL;
--
        -- �]����q�ɃR�[�h��2���̏ꍇ
        IF ( LENGTHB( gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code ) = 2 ) THEN
--
          -- �]����R�[�h�ɕR�Â��ۊǏꏊ�R�[�h�̃`�F�b�N
          xxcoi_common_pkg.get_subinventory_info1(
              iv_base_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code           -- ���_�R�[�h
            , iv_whse_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code -- �]����q�ɃR�[�h
            , ov_sec_inv_nm   => gt_sec_inv_nm                                                     -- �ۊǏꏊ�R�[�h
            , od_disable_date => lt_sec_inv_disable_date                                           -- ������
            , ov_errbuf       => lv_errbuf                                                         -- �G���[���b�Z�[�W
            , ov_retcode      => lv_retcode                                                        -- ���^�[���E�R�[�h
            , ov_errmsg       => lv_errmsg                                                         -- ���[�U�[�E�G���[���b�Z�[�W
          );
--
          -- �߂�l�̕ۊǏꏊ�R�[�h��NULL�̏ꍇ
          IF ( gt_sec_inv_nm IS NULL ) THEN
            -- �ۊǏꏊ���݃`�F�b�N�G���[
            lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application_short_name
                            , iv_name         => cv_subinv_found_chk_err_msg
                            , iv_token_name1  => cv_tkn_base_code
                            , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                            , iv_token_name2  => cv_tkn_store_code
                            , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code
                            , iv_token_name3  => cv_tkn_den_no
                            , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                          );
            lv_errbuf  := lv_errmsg;
            ov_errmsg  := lv_errmsg;
            ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
            ov_retcode := cv_status_warn;
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => ov_errmsg --�G���[���b�Z�[�W
            );
          -- �߂�l�̖�������TRUNC(NVL(������, �V�X�e�����t+1)) <= TRUNC(�V�X�e�����t)�̏ꍇ
          ELSIF ( TRUNC( NVL( lt_sec_inv_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
            -- �ۊǏꏊ�L���`�F�b�N�G���[
            lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application_short_name
                            , iv_name         => cv_subinv_valid_chk_err_msg
                            , iv_token_name1  => cv_tkn_subinventory_code
                            , iv_token_value1 => gt_sec_inv_nm
                            , iv_token_name2  => cv_tkn_den_no
                            , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                          );
            lv_errbuf  := lv_errmsg;
            ov_errmsg  := lv_errmsg;
            ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
            ov_retcode := cv_status_warn;
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => ov_errmsg --�G���[���b�Z�[�W
            );
          END IF;
--
        -- �]����q�ɃR�[�h��5���̏ꍇ
        ELSIF ( LENGTHB( gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code ) = 5 ) THEN
--
          -- �]����R�[�h�ɕR�Â��ۊǏꏊ�R�[�h�̃`�F�b�N
          xxcoi_common_pkg.get_subinventory_info2(
              iv_base_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code           -- ���_�R�[�h
            , iv_shop_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code -- �]����q�ɃR�[�h
            , ov_sec_inv_nm   => gt_sec_inv_nm                                                     -- �ۊǏꏊ�R�[�h
            , od_disable_date => lt_sec_inv_disable_date                                           -- ������
            , ov_errbuf       => lv_errbuf                                                         -- �G���[���b�Z�[�W
            , ov_retcode      => lv_retcode                                                        -- ���^�[���E�R�[�h
            , ov_errmsg       => lv_errmsg                                                         -- ���[�U�[�E�G���[���b�Z�[�W
          );
--
          -- �߂�l�̕ۊǏꏊ�R�[�h��NULL�̏ꍇ
          IF ( gt_sec_inv_nm IS NULL ) THEN
            -- �ۊǏꏊ���݃`�F�b�N�G���[
            lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application_short_name
                            , iv_name         => cv_subinv_found_chk_err_msg
                            , iv_token_name1  => cv_tkn_base_code
                            , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                            , iv_token_name2  => cv_tkn_store_code
                            , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code
                            , iv_token_name3  => cv_tkn_den_no
                            , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                          );
            lv_errbuf  := lv_errmsg;
            ov_errmsg  := lv_errmsg;
            ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
            ov_retcode := cv_status_warn;
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => ov_errmsg --�G���[���b�Z�[�W
            );
          -- �߂�l�̖�������TRUNC(NVL(������, �V�X�e�����t+1)) <= TRUNC(�V�X�e�����t)�̏ꍇ
          ELSIF ( TRUNC( NVL( lt_sec_inv_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
            -- �ۊǏꏊ�L���`�F�b�N�G���[
            lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application_short_name
                            , iv_name         => cv_subinv_valid_chk_err_msg
                            , iv_token_name1  => cv_tkn_subinventory_code
                            , iv_token_value1 => gt_sec_inv_nm
                            , iv_token_name2  => cv_tkn_den_no
                            , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                          );
            lv_errbuf  := lv_errmsg;
            ov_errmsg  := lv_errmsg;
            ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
            ov_retcode := cv_status_warn;
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => ov_errmsg --�G���[���b�Z�[�W
            );
          END IF;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -- ===============================
    -- ����Ȗڕʖ����݃`�F�b�N
    -- ===============================
    -- �`�[�敪���u10�v�i�H����Ɂj���i�ڋ敪���u2�v�i���ށj�ȊO�̏ꍇ
    IF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 )
      AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 <> cv_segment1 ) ) THEN
--
      -- ����Ȗڕʖ�ID�̎擾
      gn_disposition_id := xxcoi_common_pkg.get_disposition_id_2(
                               iv_inv_account_kbn => cv_inv_account_kbn_01 -- ���o�Ɋ���敪
                             , iv_dept_code       => gt_acc_dept_code      -- ����R�[�h
                             , in_organization_id => gt_org_id             -- �݌ɑg�DID
                           );
--
      -- �߂�l�̊���Ȗڕʖ�ID��NULL�̏ꍇ
      IF ( gn_disposition_id IS NULL ) THEN
        -- ����Ȗڕʖ����݃`�F�b�N�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_act_type_found_chk_err_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_acc_dept_code
                       , iv_token_name2  => cv_tkn_act_type
                       , iv_token_value2 => cv_inv_account_kbn_01
                       , iv_token_name3  => cv_tkn_den_no
                       , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                     );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- ����Ȗڕʖ�ID�`�F�b�N�G���[���ʗp�t���OON
        lv_disposition_id_chk_flag := cv_flag_on;
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --�G���[���b�Z�[�W
        );
      END IF;
--
    -- �`�[�敪���u10�v�i�H����Ɂj���i�ڋ敪���u2�v�i���ށj�̏ꍇ
    ELSIF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 )
      AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 = cv_segment1 ) ) THEN
--
      -- ����ޗ��ꎞ����̊���Ȗڕʖ�ID�̎擾
      gn_disposition_id := xxcoi_common_pkg.get_disposition_id_2(
                               iv_inv_account_kbn => cv_inv_account_kbn_02 -- ���o�Ɋ���敪
                             , iv_dept_code       => gt_acc_dept_code      -- ����R�[�h
                             , in_organization_id => gt_org_id             -- �݌ɑg�DID
                           );
--
      -- �߂�l�̊���Ȗڕʖ�ID��NULL�̏ꍇ
      IF ( gn_disposition_id IS NULL ) THEN
        -- ����Ȗڕʖ����݃`�F�b�N�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_act_type_found_chk_err_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_acc_dept_code
                       , iv_token_name2  => cv_tkn_act_type
                       , iv_token_value2 => cv_inv_account_kbn_02
                       , iv_token_name3  => cv_tkn_den_no
                       , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                     );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- ����Ȗڕʖ�ID�`�F�b�N�G���[���ʗp�t���OON
        lv_disposition_id_chk_flag := cv_flag_on;
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --�G���[���b�Z�[�W
        );
      END IF;
--
      -- ����ޗ������U�ւ̊���Ȗڕʖ�ID�̎擾
      gn_disposition_id_2 := xxcoi_common_pkg.get_disposition_id_2(
                                 iv_inv_account_kbn => cv_inv_account_kbn_21                                   -- ���o�Ɋ���敪
                               , iv_dept_code       => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code -- ����R�[�h
                               , in_organization_id => gt_org_id                                               -- �݌ɑg�DID
                             );
--
      -- �߂�l�̊���Ȗڕʖ�ID��NULL�̏ꍇ
      IF ( gn_disposition_id_2 IS NULL ) THEN
        -- ����Ȗڕʖ����݃`�F�b�N�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_act_type_found_chk_err_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                       , iv_token_name2  => cv_tkn_act_type
                       , iv_token_value2 => cv_inv_account_kbn_21
                       , iv_token_name3  => cv_tkn_den_no
                       , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                     );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- ����Ȗڕʖ�ID�`�F�b�N�G���[���ʗp�t���OON
        lv_disposition_id_chk_flag := cv_flag_on;
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --�G���[���b�Z�[�W
        );
      END IF;
--
    END IF;
--
    -- ===============================
    -- ����Ȗڕʖ��L���`�F�b�N
    -- ===============================
    -- ����Ȗڕʖ�ID��NULL�̏ꍇ�̓X�L�b�v
    IF ( lv_disposition_id_chk_flag = cv_flag_off ) THEN
--
      -- ���[�J���ϐ��̏�����(����Ȗڕʖ�ID)
      gn_disposition_id   := NULL; -- ����Ȗڕʖ�ID
      gn_disposition_id_2 := NULL; -- ����Ȗڕʖ�ID(����ޗ������U��)
--
      -- �`�[�敪���u10�v�i�H����Ɂj���i�ڋ敪���u2�v�i���ށj�ȊO�ꍇ
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10
        AND gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 <> cv_segment1 ) THEN
--
        -- ����Ȗڕʖ�ID�̎擾
        gn_disposition_id := xxcoi_common_pkg.get_disposition_id(
                                 iv_inv_account_kbn => cv_inv_account_kbn_01 -- ���o�Ɋ���敪
                               , iv_dept_code       => gt_acc_dept_code      -- ����R�[�h
                               , in_organization_id => gt_org_id             -- �݌ɑg�DID
                             );
--
        -- �߂�l�̊���Ȗڕʖ�ID��NULL�̏ꍇ
        IF ( gn_disposition_id IS NULL ) THEN
          -- ����Ȗڕʖ��L���`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application_short_name
                         , iv_name         => cv_act_type_valid_chk_err_msg
                         , iv_token_name1  => cv_tkn_base_code
                         , iv_token_value1 => gt_acc_dept_code
                         , iv_token_name2  => cv_tkn_act_type
                         , iv_token_value2 => cv_inv_account_kbn_01
                         , iv_token_name3  => cv_tkn_den_no
                         , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                       );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --�G���[���b�Z�[�W
          );
        END IF;
--
      -- �`�[�敪���u10�v�i�H����Ɂj���i�ڋ敪���u2�v�i���ށj�̏ꍇ
      ELSIF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 )
        AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 = cv_segment1 ) ) THEN
--
        -- ����ޗ��ꎞ����̊���Ȗڕʖ�ID�̎擾
        gn_disposition_id := xxcoi_common_pkg.get_disposition_id(
                                 iv_inv_account_kbn => cv_inv_account_kbn_02 -- ���o�Ɋ���敪
                               , iv_dept_code       => gt_acc_dept_code      -- ����R�[�h
                               , in_organization_id => gt_org_id             -- �݌ɑg�DID
                             );
--
        -- �߂�l�̊���Ȗڕʖ�ID��NULL�̏ꍇ
        IF ( gn_disposition_id IS NULL ) THEN
          -- ����Ȗڕʖ��L���`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application_short_name
                         , iv_name         => cv_act_type_valid_chk_err_msg
                         , iv_token_name1  => cv_tkn_base_code
                         , iv_token_value1 => gt_acc_dept_code
                         , iv_token_name2  => cv_tkn_act_type
                         , iv_token_value2 => cv_inv_account_kbn_02
                         , iv_token_name3  => cv_tkn_den_no
                         , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                       );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --�G���[���b�Z�[�W
          );
        END IF;
--
        -- ����ޗ������U�ւ̊���Ȗڕʖ�ID�̎擾
        gn_disposition_id_2 := xxcoi_common_pkg.get_disposition_id(
                                   iv_inv_account_kbn => cv_inv_account_kbn_21                                   -- ���o�Ɋ���敪
                                 , iv_dept_code       => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code -- ����R�[�h
                                 , in_organization_id => gt_org_id                                               -- �݌ɑg�DID
                               );
--
        -- �߂�l�̊���Ȗڕʖ�ID��NULL�̏ꍇ
        IF ( gn_disposition_id_2 IS NULL ) THEN
          -- ����Ȗڕʖ��L���`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application_short_name
                         , iv_name         => cv_act_type_valid_chk_err_msg
                         , iv_token_name1  => cv_tkn_base_code
                         , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                         , iv_token_name2  => cv_tkn_act_type
                         , iv_token_value2 => cv_inv_account_kbn_21
                         , iv_token_name3  => cv_tkn_den_no
                         , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                       );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --�G���[���b�Z�[�W
          );
        END IF;
--
      END IF;
--
    END IF;
--
    -- ===============================
    -- �݌ɉ�v���ԃ`�F�b�N
    -- ===============================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                               -- �݌ɑg�DID
      , id_target_date     => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_date -- �Ώۓ�
      , ob_chk_result      => lb_chk_result                                           -- �`�F�b�N����
      , ov_errbuf          => lv_errbuf                                               -- �G���[���b�Z�[�W
      , ov_retcode         => lv_retcode                                              -- ���^�[���E�R�[�h
      , ov_errmsg          => lv_errmsg                                               -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
   -- �߂�l�̃X�e�[�^�X��FALSE�̏ꍇ
   IF ( lb_chk_result = FALSE ) THEN
     -- �`�[���t�݌ɉ�v���ԃ`�F�b�N�G���[
     lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_inv_acc_period_chk_err_msg
                    , iv_token_name1  => cv_tkn_den_no
                    , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                    , iv_token_name2  => cv_tkn_entry_date
                    , iv_token_value2 => TO_CHAR( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_date, 'YYYY/MM/DD' )
                  );
     lv_errbuf  := lv_errmsg;
     ov_errmsg  := lv_errmsg;
     ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
     ov_retcode := cv_status_warn;
     -- ���b�Z�[�W�o��
     FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
       , buff   => ov_errmsg --�G���[���b�Z�[�W
     );
   END IF;
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
  END chk_category;
--
  /**********************************************************************************
   * Procedure Name   : ins_mtl_tran_if_tab
   * Description      : ���ގ��OIF�}������ (A-6)
   ***********************************************************************************/
  PROCEDURE ins_mtl_tran_if_tab(
    gn_inside_info_loop_cnt  IN   NUMBER,    -- ���ID�P�ʃ��[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mtl_tran_if_tab'; -- �v���O������
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
    cv_1                         CONSTANT VARCHAR2(1) := '1';  -- �Œ�l 1
    cv_3                         CONSTANT VARCHAR2(1) := '3';  -- �Œ�l 3
--
    -- *** ���[�J���ϐ� ***
    lv_subinventory_code         VARCHAR2(100); -- �ۊǏꏊ�R�[�h
    lv_source_code               VARCHAR2(100); -- ����\�[�XID
    lv_transaction_type_id       VARCHAR2(100); -- ����^�C�vID
    lv_transaction_quantity      VARCHAR2(100); -- �������
    lv_transfer_subinventory     VARCHAR2(100); -- �����ۊǏꏊ�R�[�h
    lv_transfer_organization     VARCHAR2(100); -- �����݌ɑg�DID
    lv_attribute5                VARCHAR2(100); -- ATTRIBUTE5�i�o�ɋ��_�R�[�h�j
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
    -- ���[�J���ϐ��̏�����
    lv_subinventory_code     := NULL; -- �ۊǏꏊ�R�[�h
    lv_source_code           := NULL; -- ����\�[�XID
    lv_transaction_type_id   := NULL; -- ����^�C�vID
    lv_transaction_quantity  := NULL; -- �������
    lv_transfer_subinventory := NULL; -- �����ۊǏꏊ�R�[�h
    lv_transfer_organization := NULL; -- �����݌ɑg�DID
    lv_attribute5            := NULL; -- ATTRIBUTE5�i�o�ɋ��_�R�[�h�j
--
    -- �l�̐ݒ�
    -- �`�[�敪���u10�v�i�H����Ɂj�̏ꍇ
    IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 ) THEN
--
      lv_subinventory_code     := gt_sec_inv_nm; -- �ۊǏꏊ�R�[�h
--
      -- �i�ڋ敪���u2�v�i���ށj�ȊO�̏ꍇ
      -- �i�ڋ敪���u2�v�i���ށj�̏ꍇ�i����ޗ��ꎞ����j
      lv_source_code           := gn_disposition_id; -- ����\�[�XID
--
      -- �i�ڋ敪���u2�v�i���ށj�ȊO��������� > 0�̏ꍇ
      IF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 <> cv_segment1 )
        AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) ) THEN
        lv_transaction_type_id := gt_tran_type_factory_stock;   -- ����^�C�vID �H�����
      -- �i�ڋ敪���u2�v�i���ށj�ȊO��������� < 0�̏ꍇ
      ELSIF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 <> cv_segment1 )
        AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) ) THEN
        lv_transaction_type_id := gt_tran_type_factory_stock_b; -- ����^�C�vID �H����ɐU��
      -- �i�ڋ敪���u2�v�i���ށj��������� > 0�̏ꍇ
      ELSIF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 = cv_segment1 )
        AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) ) THEN
        lv_transaction_type_id := gt_tran_type_pack_receive;    -- ����^�C�vID ����ޗ��ꎞ���
      -- �i�ڋ敪���u2�v�i���ށj��������� < 0�̏ꍇ
      ELSIF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 = cv_segment1 )
        AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) ) THEN
        lv_transaction_type_id := gt_tran_type_pack_receive_b;  -- ����^�C�vID ����ޗ��ꎞ����U��
      END IF;
--
      lv_transaction_quantity  := gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty; -- �������
      lv_transfer_subinventory := NULL; -- �����ۊǏꏊ�R�[�h
      lv_transfer_organization := NULL; -- �����݌ɑg�DID
--
      -- ������� > 0�̏ꍇ
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_base_code; -- ATTRIBUTE5�i�o�ɋ��_�R�[�h�j
      -- ������� < 0�̏ꍇ
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code; -- ATTRIBUTE5�i�o�ɋ��_�R�[�h�j
      END IF;
--
    -- �`�[�敪���u20�v�i���_�ԓ��Ɂj�̏ꍇ
    ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_20 ) THEN
--
      -- ������� > 0�̏ꍇ
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_subinventory_code   := gt_sec_inv_nm_2; -- �ۊǏꏊ�R�[�h
      -- ������� < 0�̏ꍇ
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_subinventory_code   := gt_sec_inv_nm; -- �ۊǏꏊ�R�[�h
      END IF;
--
      lv_source_code           := NULL; -- ����\�[�XID
      lv_transaction_type_id   := gt_tran_type_inout; -- ����^�C�vID ���o��
      lv_transaction_quantity  := ABS( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty ); -- �������
--
      -- ������� > 0�̏ꍇ
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_transfer_subinventory := gt_sec_inv_nm; -- �����ۊǏꏊ�R�[�h
      -- ������� < 0�̏ꍇ
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_transfer_subinventory := gt_sec_inv_nm_2; -- �����ۊǏꏊ�R�[�h
      END IF;
--
      lv_transfer_organization := gt_org_id; -- �����݌ɑg�DID
--
      -- ������� > 0�̏ꍇ
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_base_code; -- ATTRIBUTE5�i�o�ɋ��_�R�[�h�j
      -- ������� < 0�̏ꍇ
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code; -- ATTRIBUTE5�i�o�ɋ��_�R�[�h�j
      END IF;
--
    END IF;
--
    -- �H����ɁA�H����ɐU�߁A����ޗ��ꎞ����A����ޗ��ꎞ����U�߁A���o�ɂ̎��ގ���f�[�^�����ގ��OIF�֓o�^
    INSERT INTO mtl_transactions_interface(
        source_code                                                     -- �\�[�X�R�[�h
      , source_line_id                                                  -- �\�[�X���C��ID
      , source_header_id                                                -- �\�[�X�w�b�_�[ID
      , process_flag                                                    -- �v���Z�X�t���O
      , transaction_mode                                                -- ������[�h
      , inventory_item_id                                               -- �i��ID
      , organization_id                                                 -- �݌ɑg�DID
      , transaction_quantity                                            -- �������
      , primary_quantity                                                -- ��P�ʐ���
      , transaction_uom                                                 -- ��P��
      , transaction_date                                                -- �����
      , subinventory_code                                               -- �ۊǏꏊ�R�[�h
      , transaction_source_id                                           -- ����\�[�XID
      , transaction_type_id                                             -- ����^�C�vID
      , transfer_subinventory                                           -- �����ۊǏꏊ�R�[�h
      , transfer_organization                                           -- �����݌ɑg�DID
      , attribute1                                                      -- �`�[No
      , attribute3                                                      -- �q�i�ڃR�[�h
      , attribute5                                                      -- �o�ɋ��_�R�[�h
      , created_by                                                      -- �쐬��
      , creation_date                                                   -- �쐬��
      , last_updated_by                                                 -- �ŏI�X�V��
      , last_update_date                                                -- �ŏI�X�V��
      , last_update_login                                               -- �ŏI�X�V���O�C��
      , request_id                                                      -- �v��ID
      , program_application_id                                          -- �v���O�����A�v���P�[�V����ID
      , program_id                                                      -- �v���O����ID
      , program_update_date                                             -- �v���O�����X�V��
    )
    VALUES(
        cv_pkg_name                                                     -- �\�[�X�R�[�h
      , cv_1                                                            -- �\�[�X���C��ID
      , gt_inside_info_tab( gn_inside_info_loop_cnt ).transaction_id    -- �\�[�X�w�b�_�[ID
      , cv_1                                                            -- �v���Z�X�t���O
      , cv_3                                                            -- ������[�h
      , gt_inside_info_tab( gn_inside_info_loop_cnt ).inventory_item_id -- �i��ID
      , gt_org_id                                                       -- �݌ɑg�DID
      , lv_transaction_quantity                                         -- �������
      , lv_transaction_quantity                                         -- ��P�ʐ���
      , gt_primary_uom_code                                             -- ��P��
      , gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_date         -- �����
      , lv_subinventory_code                                            -- �ۊǏꏊ�R�[�h
      , lv_source_code                                                  -- ����\�[�XID
      , lv_transaction_type_id                                          -- ����^�C�vID
      , lv_transfer_subinventory                                        -- �����ۊǏꏊ�R�[�h
      , lv_transfer_organization                                        -- �����݌ɑg�DID
      , gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num          -- �`�[No
      , gt_inside_info_tab( gn_inside_info_loop_cnt ).item_code         -- �q�i�ڃR�[�h
      , lv_attribute5                                                   -- �o�ɋ��_�R�[�h
      , cn_created_by                                                   -- �쐬��
      , cd_creation_date                                                -- �쐬��
      , cn_last_updated_by                                              -- �ŏI�X�V��
      , cd_last_update_date                                             -- �ŏI�X�V��
      , cn_last_update_login                                            -- �ŏI�X�V���O�C��
      , cn_request_id                                                   -- �v��ID
      , cn_program_application_id                                       -- �v���O�����A�v���P�[�V����ID
      , cn_program_id                                                   -- �v���O����ID
      , cd_program_update_date                                          -- �v���O�����X�V��
    );
--
    -- �l�̐ݒ�
    -- �`�[�敪���u10�v�i�H����Ɂj���i�ڋ敪���u2�v�i���ށj�̏ꍇ
    IF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 )
      AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 = cv_segment1 ) ) THEN
--
      -- ������� > 0�̏ꍇ
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_transaction_type_id := gt_tran_type_transfer_cost;   -- ����^�C�vID
      -- ������� < 0�̏ꍇ
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_transaction_type_id := gt_tran_type_transfer_cost_b; -- ����^�C�vID
      END IF;
--
      -- ������� > 0�̏ꍇ
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_base_code; -- ATTRIBUTE5�i�o�ɋ��_�R�[�h�j
      -- ������� < 0�̏ꍇ
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code; -- ATTRIBUTE5�i�o�ɋ��_�R�[�h�j
      END IF;
--
      -- ����ޗ������U�ցA����ޗ������U�֐U�߂̎��ގ���f�[�^�����ގ��OIF�֓o�^
      INSERT INTO mtl_transactions_interface(
          source_code                                                                               -- �\�[�X�R�[�h
        , source_line_id                                                                            -- �\�[�X���C��ID
        , source_header_id                                                                          -- �\�[�X�w�b�_�[ID
        , process_flag                                                                              -- �v���Z�X�t���O
        , transaction_mode                                                                          -- ������[�h
        , inventory_item_id                                                                         -- �i��ID
        , organization_id                                                                           -- �݌ɑg�DID
        , transaction_quantity                                                                      -- �������
        , primary_quantity                                                                          -- ��P�ʐ���
        , transaction_uom                                                                           -- ��P��
        , transaction_date                                                                          -- �����
        , subinventory_code                                                                         -- �ۊǏꏊ�R�[�h
        , transaction_source_id                                                                     -- ����\�[�XID
        , transaction_type_id                                                                       -- ����^�C�vID
        , transfer_subinventory                                                                     -- �����ۊǏꏊ�R�[�h
        , transfer_organization                                                                     -- �����݌ɑg�DID
        , attribute1                                                                                -- �`�[No
        , attribute3                                                                                -- �q�i�ڃR�[�h
        , attribute5                                                                                -- �o�ɋ��_�R�[�h
        , created_by                                                                                -- �쐬��
        , creation_date                                                                             -- �쐬��
        , last_updated_by                                                                           -- �ŏI�X�V��
        , last_update_date                                                                          -- �ŏI�X�V��
        , last_update_login                                                                         -- �ŏI�X�V���O�C��
        , request_id                                                                                -- �v��ID
        , program_application_id                                                                    -- �v���O�����A�v���P�[�V����ID
        , program_id                                                                                -- �v���O����ID
        , program_update_date                                                                       -- �v���O�����X�V��
      )
      VALUES(
          cv_pkg_name                                                                               -- �\�[�X�R�[�h
        , cv_1                                                                                      -- �\�[�X���C��ID
        , gt_inside_info_tab( gn_inside_info_loop_cnt ).transaction_id                              -- �\�[�X�w�b�_�[ID
        , cv_1                                                                                      -- �v���Z�X�t���O
        , cv_3                                                                                      -- ������[�h
        , gt_inside_info_tab( gn_inside_info_loop_cnt ).inventory_item_id                           -- �i��ID
        , gt_org_id                                                                                 -- �݌ɑg�DID
        , ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty * ( -1 ) ) -- �������
        , ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty * ( -1 ) ) -- ��P�ʐ���
        , gt_primary_uom_code                                                                       -- ��P��
        , gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_date                                   -- �����
        , gt_sec_inv_nm                                                                             -- �ۊǏꏊ�R�[�h
        , gn_disposition_id_2                                                                       -- ����\�[�XID
        , lv_transaction_type_id                                                                    -- ����^�C�vID
        , NULL                                                                                      -- �����ۊǏꏊ�R�[�h
        , NULL                                                                                      -- �����݌ɑg�DID
        , gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num                                    -- �`�[No
        , gt_inside_info_tab( gn_inside_info_loop_cnt ).item_code                                   -- �q�i�ڃR�[�h
        , lv_attribute5                                                                             -- �o�ɋ��_�R�[�h
        , cn_created_by                                                                             -- �쐬��
        , cd_creation_date                                                                          -- �쐬��
        , cn_last_updated_by                                                                        -- �ŏI�X�V��
        , cd_last_update_date                                                                       -- �ŏI�X�V��
        , cn_last_update_login                                                                      -- �ŏI�X�V���O�C��
        , cn_request_id                                                                             -- �v��ID
        , cn_program_application_id                                                                 -- �v���O�����A�v���P�[�V����ID
        , cn_program_id                                                                             -- �v���O����ID
        , cd_program_update_date                                                                    -- �v���O�����X�V��
      );
--
    END IF;
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
  END ins_mtl_tran_if_tab;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ���b�N�擾���� (A-7)
   ***********************************************************************************/
  PROCEDURE get_lock(
    gn_slip_loop_cnt        IN  NUMBER DEFAULT NULL,  -- �`�[�P�ʃ��[�v�J�E���^
    gn_inside_info_loop_cnt IN  NUMBER DEFAULT NULL,  -- ���ID�P�ʃ��[�v�J�E���^
    ov_errbuf               OUT VARCHAR2,             -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode              OUT VARCHAR2,             -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg               OUT VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���ɏ��ꎞ�\���b�N�擾(���ގ��OIF�ւ̃f�[�^�쐬������I��)
    CURSOR transaction_id_cur
    IS
      SELECT  xsi.slip_num              AS slip_num                                                    -- �`�[No
      FROM    xxcoi_storage_information xsi                                                            -- ���ɏ��ꎞ�\
      WHERE   xsi.transaction_id        = gt_inside_info_tab( gn_inside_info_loop_cnt ).transaction_id -- ���ID
      FOR UPDATE OF xsi.slip_num NOWAIT
    ;
--
    -- ���ɏ��ꎞ�\���b�N�擾(���ڃ`�F�b�N�܂��̓��b�N�擾�����ŃG���[�̏ꍇ)
    CURSOR xsi_slip_num_cur
    IS
      SELECT  xsi.slip_num              AS slip_num                           -- �`�[No
      FROM    xxcoi_storage_information xsi                                   -- ���ɏ��ꎞ�\
      WHERE   xsi.slip_num              = gt_slip_num_tab( gn_slip_loop_cnt ) -- �`�[No
      FOR UPDATE OF xsi.slip_num NOWAIT
    ;
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
    -- ���ގ��OIF�ւ̃f�[�^�쐬������̏ꍇ
    IF ( gn_err_flag_cnt = 0 ) THEN
      -- �J�[�\���I�[�v��
      OPEN transaction_id_cur;
      -- �J�[�\���N���[�Y
      CLOSE transaction_id_cur;
    -- ���ڃ`�F�b�N�܂��̓��b�N�擾�����ŃG���[�̏ꍇ
    ELSIF ( gn_err_flag_cnt > 0 ) THEN
      -- �J�[�\���I�[�v��
      OPEN xsi_slip_num_cur;
      -- �J�[�\���N���[�Y
      CLOSE xsi_slip_num_cur;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( transaction_id_cur%ISOPEN ) THEN
        CLOSE transaction_id_cur;
      ELSIF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      -- ���ގ��OIF�ւ̃f�[�^�쐬������̏ꍇ
      IF ( gn_err_flag_cnt = 0 ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_table_lock_err_2_msg
                        , iv_token_name1  => cv_tkn_tran_id
                        , iv_token_value1 => TO_CHAR( gt_inside_info_tab( gn_inside_info_loop_cnt ).transaction_id )
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --�G���[���b�Z�[�W
        );
      -- ���ڃ`�F�b�N�܂��̓��b�N�擾�����ŃG���[�̏ꍇ
      ELSIF ( gn_err_flag_cnt > 0 ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_table_lock_err_msg
                        , iv_token_name1  => cv_tkn_den_no
                        , iv_token_value1 => gt_slip_num_tab( gn_slip_loop_cnt )
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --�G���[���b�Z�[�W
        );
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( transaction_id_cur%ISOPEN ) THEN
        CLOSE transaction_id_cur;
      ELSIF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( transaction_id_cur%ISOPEN ) THEN
        CLOSE transaction_id_cur;
      ELSIF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( transaction_id_cur%ISOPEN ) THEN
        CLOSE transaction_id_cur;
      ELSIF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lock;
--
  /**********************************************************************************
   * Procedure Name   : upd_storage_info_tab
   * Description      : ���ɏ��ꎞ�\�X�V���� (A-8)
   ***********************************************************************************/
  PROCEDURE upd_storage_info_tab(
    gn_slip_loop_cnt         IN   NUMBER DEFAULT NULL,  -- �`�[�P�ʃ��[�v�J�E���^
    gn_inside_info_loop_cnt  IN   NUMBER DEFAULT NULL,  -- �q�փf�[�^���[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,             -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_storage_info_tab'; -- �v���O������
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
    cv_status_post               CONSTANT VARCHAR2(1) := '1';  -- �����X�e�[�^�X 1�F������
    cv_zero                      CONSTANT VARCHAR2(1) := '0';  -- �Œ�l 0
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
    -- ���ގ��OIF�ւ̃f�[�^�쐬������̏ꍇ
    IF ( gn_err_flag_cnt = 0 ) THEN
      -- ���ɏ��ꎞ�\�̍X�V
      UPDATE xxcoi_storage_information xsi                                                                       -- ���ɏ��ꎞ�\
      SET    xsi.material_transaction_set_flag  = cv_flag_on                                                     -- ���ގ���A�g�σt���O
           , xsi.material_transaction_unset_qty = cv_zero                                                        -- ���ގ�����A�g����
           , xsi.last_updated_by                = cn_last_updated_by                                             -- �ŏI�X�V��
           , xsi.last_update_date               = cd_last_update_date                                            -- �ŏI�X�V��
           , xsi.last_update_login              = cn_last_update_login                                           -- �ŏI�X�V���O�C��
           , xsi.request_id                     = cn_request_id                                                  -- �v��ID
           , xsi.program_application_id         = cn_program_application_id                                      -- �v���O�����A�v���P�[�V����ID
           , xsi.program_id                     = cn_program_id                                                  -- �v���O����ID
           , xsi.program_update_date            = cd_program_update_date                                         -- �v���O�����X�V��
      WHERE  xsi.transaction_id                 = gt_inside_info_tab( gn_inside_info_loop_cnt ).transaction_id   -- ���ID
      ;
    -- ���ڃ`�F�b�N�܂��̓��b�N�擾�����ŃG���[�̏ꍇ
    ELSIF ( gn_err_flag_cnt > 0 ) THEN
      -- ���ɏ��ꎞ�\�̍X�V
      UPDATE xxcoi_storage_information xsi                                                                       -- ���ɏ��ꎞ�\
      SET    xsi.check_case_qty                 = DECODE( ( xsi.check_summary_qty - xsi.material_transaction_unset_qty ), 0, 0,
                                                    DECODE( xsi.case_in_qty, 0, 0,
                                                      TRUNC( ( xsi.check_summary_qty - xsi.material_transaction_unset_qty )
                                                           / xsi.case_in_qty ) ) )                               -- �m�F���ʃP�[�X��
           , xsi.check_singly_qty               = DECODE( ( xsi.check_summary_qty - xsi.material_transaction_unset_qty ), 0, 0,
                                                    MOD( ( xsi.check_summary_qty - xsi.material_transaction_unset_qty ),
                                                           xsi.case_in_qty ) )                                   -- �m�F���ʃo����
           , xsi.check_summary_qty              = ( xsi.check_summary_qty - xsi.material_transaction_unset_qty ) -- �m�F���ʑ��o����
           , xsi.material_transaction_unset_qty = 0                                                              -- ���ގ�����A�g����
           , xsi.store_check_flag               = DECODE( ( xsi.check_summary_qty - xsi.material_transaction_unset_qty ), 0, cv_flag_off,
                                                            xsi.store_check_flag )                               -- ���Ɋm�F�t���O
           , xsi.last_updated_by                = cn_last_updated_by                                             -- �ŏI�X�V��
           , xsi.last_update_date               = cd_last_update_date                                            -- �ŏI�X�V��
           , xsi.last_update_login              = cn_last_update_login                                           -- �ŏI�X�V���O�C��
           , xsi.request_id                     = cn_request_id                                                  -- �v��ID
           , xsi.program_application_id         = cn_program_application_id                                      -- �v���O�����A�v���P�[�V����ID
           , xsi.program_id                     = cn_program_id                                                  -- �v���O����ID
           , xsi.program_update_date            = cd_program_update_date                                         -- �v���O�����X�V��
      WHERE  xsi.slip_num                       = gt_slip_num_tab( gn_slip_loop_cnt )                            -- �`�[No
      AND    xsi.material_transaction_set_flag  = cv_flag_off                                                    -- ���ގ���A�g�σt���O
      ;
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
  END upd_storage_info_tab;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_lock_err_flag             VARCHAR2(1); -- ���b�N�擾�G���[���ʗp�t���O
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--    gn_warn_cnt   := 0;
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
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ώۓ`�[No�擾���� (A-2)
    -- ===============================
    get_slip_num(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �`�[�P�ʃ��[�v�J�n
    <<gt_slip_num_tab_loop>>
    FOR gn_slip_loop_cnt IN 1 .. gn_target_cnt LOOP
--
      -- �G���[���ʗp�J�E���^������
      gn_err_flag_cnt := 0;
--
      -- ===============================
      -- �Z�[�u�|�C���g�ݒ� (A-3)
      -- ===============================
      SAVEPOINT slip_point;
--
      -- ===============================
      -- ���ɏ��擾���� (A-4)
      -- ===============================
      get_inside_info(
          gn_slip_loop_cnt => gn_slip_loop_cnt -- �`�[�P�ʃ��[�v�J�E���^
        , ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���ID�P�ʌ�����0���̏ꍇ
      IF ( gn_inside_info_cnt = 0 ) THEN
        -- ���ɏ��f�[�^�������b�Z�[�W
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_no_data_inside_info_msg
                        , iv_token_name1  => cv_tkn_den_no
                        , iv_token_value1 => gt_slip_num_tab( gn_slip_loop_cnt )
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --�G���[���b�Z�[�W
        );
        -- �G���[����
        gn_error_cnt := gn_error_cnt + 1;
      -- ���ID�P�ʌ�����1���ȏ�擾�ł����ꍇ
      ELSIF ( gn_inside_info_cnt > 0 ) THEN
--
        -- ���ID�P�ʃ��[�v�J�n
        <<gt_inside_info_tab_loop>>
        FOR gn_inside_info_loop_cnt IN 1 .. gn_inside_info_cnt LOOP
--
-- == 2009/05/18 V1.3 Added START ===============================================================
        -- ���ގ�����A�g���� <> 0�̏ꍇ
        IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty <> 0 ) THEN
-- == 2009/05/18 V1.3 Added END   ===============================================================
          -- ===============================
          -- ���ڃ`�F�b�N���� (A-5)
          -- ===============================
          chk_category(
              gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- ���ID�P�ʃ��[�v�J�E���^
            , ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- �G���[���ʗp�J�E���^
            gn_err_flag_cnt := gn_err_flag_cnt + 1;
          END IF;
--
          -- ���ڃ`�F�b�N�ɂăG���[���������Ă��Ȃ��ꍇ
          IF ( gn_err_flag_cnt = 0 ) THEN
--
            -- ===============================
            -- ���ގ��OIF�}������ (A-6)
            -- ===============================
            ins_mtl_tran_if_tab(
                gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- ���ID�P�ʃ��[�v�J�E���^
              , ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
              , ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
              , ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ===============================
            -- ���b�N�擾���� (A-7)
            -- ===============================
            get_lock(
                gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- ���ID�P�ʃ��[�v�J�E���^
              , ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
              , ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
              , ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            ELSIF ( lv_retcode = cv_status_warn ) THEN
              -- �G���[���ʗp�J�E���^
              gn_err_flag_cnt := gn_err_flag_cnt + 1;
            END IF;
--
            -- ���b�N�擾�G���[���������Ă��Ȃ��ꍇ
            IF ( gn_err_flag_cnt = 0 ) THEN
--
              -- ===============================
              -- ���ɏ��ꎞ�\�X�V���� (A-8)
              -- ===============================
              upd_storage_info_tab(
                  gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- ���ID�P�ʃ��[�v�J�E���^
                , ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
                , ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
                , ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
--
            END IF;
--
          END IF;
--
-- == 2009/05/18 V1.3 Added START ===============================================================
        -- ���ގ�����A�g���� = 0�̏ꍇ
        ELSE
          -- ===============================
          -- ���b�N�擾���� (A-7)
          -- ===============================
          get_lock(
              gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- ���ID�P�ʃ��[�v�J�E���^
            , ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- �G���[���ʗp�J�E���^
            gn_err_flag_cnt := gn_err_flag_cnt + 1;
          END IF;
--
          -- ���b�N�擾�G���[���������Ă��Ȃ��ꍇ
          IF ( gn_err_flag_cnt = 0 ) THEN
--
            -- ===============================
            -- ���ɏ��ꎞ�\�X�V���� (A-8)
            -- ===============================
            upd_storage_info_tab(
                gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- ���ID�P�ʃ��[�v�J�E���^
              , ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
              , ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
              , ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
        END IF;
--
-- == 2009/05/18 V1.3 Added END   ===============================================================
        END LOOP gt_inside_info_tab_loop;
--
        -- ����̏ꍇ
        IF ( gn_err_flag_cnt = 0 ) THEN
          -- ��������
          gn_normal_cnt := gn_normal_cnt + 1;
        -- �G���[���������Ă���ꍇ
        ELSIF ( gn_err_flag_cnt > 0 ) THEN
--
          -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
          ROLLBACK TO SAVEPOINT slip_point;
--
          -- ���b�N�擾�G���[���ʗp�t���O������
          lv_lock_err_flag := cv_flag_off;
--
          -- ===============================
          -- ���b�N�擾���� (A-7)
          -- ===============================
          get_lock(
              gn_slip_loop_cnt => gn_slip_loop_cnt -- �`�[�P�ʃ��[�v�J�E���^
            , ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- ���b�N�擾�G���[���ʗp�t���O
            lv_lock_err_flag := cv_flag_on;
          END IF;
--
          -- ���b�N�擾�G���[���������Ă��Ȃ��ꍇ
          IF ( lv_lock_err_flag = cv_flag_off ) THEN
            -- ===============================
            -- ���ɏ��ꎞ�\�X�V���� (A-8)
            -- ===============================
            upd_storage_info_tab(
                gn_slip_loop_cnt => gn_slip_loop_cnt -- �`�[�P�ʃ��[�v�J�E���^
              , ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
              , ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
              , ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
          -- �G���[����
          gn_error_cnt := gn_error_cnt + 1;
--
        END IF;
--
      END IF;
--
    END LOOP gt_slip_num_tab_loop;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- �I���X�e�[�^�X�u�G���[�v�̏ꍇ�A�Ώی����E���팏���̏������ƃG���[�����̃Z�b�g
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
--    --�X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name
--                    , iv_name         => cv_skip_rec_msg
--                    , iv_token_name1  => cv_cnt_token
--                    , iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- �I���X�e�[�^�X���u�G���[�v�ȊO���A�G���[������1���ȏ゠��ꍇ�A�I���X�e�[�^�X�u�x���v�ɂ���
    IF ( ( lv_retcode <> cv_status_error ) AND ( gn_error_cnt > 0 ) ) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    --�I�����b�Z�[�W
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
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
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
END XXCOI001A07C;
/
