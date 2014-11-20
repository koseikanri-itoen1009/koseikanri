CREATE OR REPLACE PACKAGE BODY XXCOK003A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK003A01C(body)
 * Description      : �ڍs�ڋq�̊�݌ɂ����ɋ����_����V���_�ւ̕ۊǏꏊ�]�������쐬�B
 * MD.050           : VD�݌ɕۊǏꏊ�]�����̍쐬 MD050_COK_003_A01
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_cust_shift_info    �ڋq�ڍs���̎擾 (A-2)
 *  chk_transfer_cust      �]���Ώۃ`�F�b�N (A-4)
 *  get_vd_inv_info        VD�݌ɕۊǏꏊ�]�����擾 (A-5)
 *  chk_item_info          ���ڃ`�F�b�N (A-6)
 *  ins_mtl_txn_oif        ���ގ��OIF�o�^ (A-7)
 *  upd_status             �ڋq�ڍs���X�V (A-8)
 *  submain                ���C�������v���V�[�W��
 *                         �Z�[�u�|�C���g�ݒ� (A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������ (A-9)
 *                         
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/20    1.0   T.Kojima        �V�K�쐬
 *  2009/02/20    1.1   T.Kojima        [��QCOK_051] �Ƒԏ����� �R�[�h�l�C��
 *  2009/12/10    1.2   S.Moriyama      [E_�{�ғ�_00405] VD�R�����}�X�^�O���A�������莞�ɋ󂫃R�����l����ǉ�
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
  gn_normal_cnt    NUMBER;                    -- ��������
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
  lock_expt                         EXCEPTION;  -- ���b�N�擾�G���[
  item_chk_expt                     EXCEPTION;  -- ���ڃ`�F�b�N�G���[(�i�ڃ`�F�b�N)
  primary_uom_chk_expt              EXCEPTION;  -- ���ڃ`�F�b�N�G���[(��P�ʃ`�F�b�N)
  sec_inv_expt                      EXCEPTION;  -- �ۊǏꏊ�`�F�b�N�G���[
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(100) := 'XXCOK003A01C';          -- �p�b�P�[�W��
  cv_appl_short_name_xxccp       CONSTANT VARCHAR2(10)  := 'XXCCP';                 -- �A�h�I���F���ʁEIF�̈�
  cv_appl_short_name_xxcok       CONSTANT VARCHAR2(10)  := 'XXCOK';                 -- �A�h�I���F�ʊJ���̈�
  cv_appl_short_name_xxcoi       CONSTANT VARCHAR2(10)  := 'XXCOI';                 -- �A�h�I���F�݌ɗ̈�
  cv_prm_job                     CONSTANT VARCHAR2(1)   := '1';                     -- �ʏ�N��(��ԃo�b�`)
  cv_prm_recovery                CONSTANT VARCHAR2(1)   := '2';                     -- ���J�o���N��
  cv_trnsfr_status_prev          CONSTANT VARCHAR2(1)   := '0';                     -- ���]��
  cv_trnsfr_status_trnsfr        CONSTANT VARCHAR2(1)   := '1';                     -- �]����
  cv_trnsfr_status_reserve       CONSTANT VARCHAR2(1)   := '2';                     -- �ۗ�
  cv_trnsfr_status_out           CONSTANT VARCHAR2(1)   := '3';                     -- �ΏۊO
  cv_trnsfr_status_error         CONSTANT VARCHAR2(1)   := 'E';                     -- �G���[����p
--
  -- ���b�Z�[�W
  cv_msg_prm                     CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00076';      -- �R���J�����g���̓p�����[�^���b�Z�[�W
  cv_msg_no_prm                  CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00077';      -- ���̓p�����[�^���ݒ�G���[�i�N���敪�j
  cv_msg_org_code_get_err        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005';      -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_org_id_get_err          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006';      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_process_date_get_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011';      -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_oprtn_date_get_err      CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00078';      -- �V�X�e���ғ����擾�G���[���b�Z�[�W
  cv_msg_org_acct_period_get_err CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00026';      -- �݌ɉ�v���ԃX�e�[�^�X�擾�G���[���b�Z�[�W
  cv_msg_org_acct_period_err     CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00043';      -- �݌ɉ�v���ԃG���[���b�Z�[�W
  cv_msg_tran_type_name_get_err  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00022';      -- ����^�C�v���擾�G���[���b�Z�[�W
  cv_msg_tran_type_id_get_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00012';      -- ����^�C�vID�擾�G���[���b�Z�[�W
  cv_msg_no_data                 CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00001';      -- �Ώۃf�[�^�������b�Z�[�W
  cv_msg_sec_inv_chk_err         CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10356';      -- �ۊǏꏊ�`�F�b�N�G���[���b�Z�[�W
  cv_msg_item_status_chk_err     CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10358';      -- �i�ڃX�e�[�^�X�L���`�F�b�N�G���[���b�Z�[�W
  cv_msg_sales_class_chk_err     CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10359';      -- �i�ڔ���Ώۋ敪�L���`�F�b�N�G���[���b�Z�[�W
  cv_msg_primary_uom_not_found   CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10360';      -- ��P�ʑ��݃`�F�b�N�G���[���b�Z�[�W
  cv_msg_primary_uom_disable     CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10361';      -- ��P�ʗL���`�F�b�N�G���[���b�Z�[�W
  cv_msg_lock_err                CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10384';      -- ���b�N�G���[���b�Z�[�W(�ڋq�ڍs���) 
  cv_msg_unit_cust               CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00038';      -- �ڋq�P�ʌ������b�Z�[�W
  cv_msg_unit_column_no          CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00037';      -- �R����No.�P�ʌ������b�Z�[�W
  cv_msg_out_rec                 CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10387';      -- �ۊǏꏊ�]�����쐬�ΏۊO�������b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_pro                     CONSTANT VARCHAR2(25)  := 'PRO_TOK';               -- �v���t�@�C����
  cv_tkn_org_code                CONSTANT VARCHAR2(25)  := 'ORG_CODE_TOK';          -- �݌ɑg�D�R�[�h
  cv_tkn_lookup_type             CONSTANT VARCHAR2(25)  := 'LOOKUP_TYPE';           -- �Q�ƃ^�C�v
  cv_tkn_lookup_code             CONSTANT VARCHAR2(25)  := 'LOOKUP_CODE';           -- �Q�ƃR�[�h
  cv_tkn_tran_type               CONSTANT VARCHAR2(25)  := 'TRANSACTION_TYPE_TOK';  -- ����^�C�v��
  cv_tkn_base_code               CONSTANT VARCHAR2(25)  := 'BASE_CODE';             -- ���_�R�[�h
  cv_tkn_item_code               CONSTANT VARCHAR2(25)  := 'ITEM_CODE';             -- �i�ڃR�[�h
  cv_tkn_cust_code               CONSTANT VARCHAR2(25)  := 'CUSTOMER_CODE';         -- �ڋq�R�[�h
  cv_tkn_column_no               CONSTANT VARCHAR2(25)  := 'COLUMN_NO';             -- �R����No.
  cv_tkn_sub_inv_code            CONSTANT VARCHAR2(25)  := 'SUBINVENTORY_CODE';     -- �ۊǏꏊ�R�[�h
  cv_tkn_trnsfr_sub_inv          CONSTANT VARCHAR2(25)  := 'TRANSFER_SUBINVENTORY'; -- �ړ���ۊǏꏊ�R�[�h
  cv_tkn_qty                     CONSTANT VARCHAR2(25)  := 'QUANTITY';              -- ����
  cv_tkn_primary_uom             CONSTANT VARCHAR2(25)  := 'PRIMARY_UOM';           -- ��P��
  cv_tkn_proc_date               CONSTANT VARCHAR2(25)  := 'PROC_DATE';             -- ������
  cv_tkn_target_date             CONSTANT VARCHAR2(25)  := 'TARGET_DATE';           -- �Ώۓ�
  cv_tkn_process_flag            CONSTANT VARCHAR2(25)  := 'PROCESS_FLAG';          -- �N���敪
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �ڋq�ڍs���i�[�p
  TYPE g_cust_shift_info_rtype IS RECORD(
      hca_cust_account_id         hz_cust_accounts.cust_account_id%TYPE                    -- 1.�ڋqID
    , xcsi_cust_shift_id          xxcok_cust_shift_info.cust_shift_id%TYPE                 -- 2.�ڋq�ڍs���ID
    , xcsi_cust_code              xxcok_cust_shift_info.cust_code%TYPE                     -- 3.�ڋq�R�[�h
    , xcsi_prev_base_code         xxcok_cust_shift_info.prev_base_code%TYPE                -- 4.���S�����_�R�[�h
    , xcsi_new_base_code          xxcok_cust_shift_info.new_base_code%TYPE                 -- 5.�V�S�����_�R�[�h
    , xcsi_cust_shift_date        xxcok_cust_shift_info.cust_shift_date%TYPE               -- 6.�ڋq�ڍs��
    , xcsi_vd_inv_trnsfr_status   xxcok_cust_shift_info.vd_inv_trnsfr_status%TYPE          -- 7.VD�݌ɕۊǏꏊ�]���X�e�[�^�X
    , msi_sec_inv_code_out        mtl_secondary_inventories.secondary_inventory_name%TYPE  -- 8.�o�ɑ��ۊǏꏊ�R�[�h
    , msi_sec_inv_code_in         mtl_secondary_inventories.secondary_inventory_name%TYPE  -- 9.���ɑ��ۊǏꏊ�R�[�h
  );
  TYPE g_cust_shift_info_ttype IS TABLE OF g_cust_shift_info_rtype INDEX BY BINARY_INTEGER;

  -- VD�݌ɕۊǏꏊ�]�����[�p
  TYPE g_vd_inv_trnsfr_info_rtype IS RECORD(
      xmvc_column_no              xxcoi_mst_vd_column.column_no%TYPE                       --  1.�R����No
    , xmvc_item_id                xxcoi_mst_vd_column.item_id%TYPE                         --  2.�i��ID
    , msib_item_code              mtl_system_items_b.segment1%TYPE                         --  3.�i�ڃR�[�h
    , xmvc_inv_qty                xxcoi_mst_vd_column.inventory_quantity%TYPE              --  4.��݌ɐ�
    , msib_primary_uom            mtl_system_items_b.primary_uom_code%TYPE                 --  5.��P��
    , msib_item_status            mtl_system_items_b.inventory_item_status_code%TYPE       --  6.�i�ڃX�e�[�^�X
    , msib_cust_order_flg         mtl_system_items_b.customer_order_enabled_flag%TYPE      --  7.�ڋq�󒍉\�t���O
    , msib_transaction_enable     mtl_system_items_b.mtl_transactions_enabled_flag%TYPE    --  8.����\
    , msib_stock_enabled_flg      mtl_system_items_b.stock_enabled_flag%TYPE               --  9.�݌ɕۗL�\�t���O
    , msib_return_enable          mtl_system_items_b.returnable_flag%TYPE                  -- 10.�ԕi�\
    , iimb_sales_class            ic_item_mst_b.attribute26%TYPE                           -- 11.����Ώۋ敪
  );
  TYPE g_vd_inv_trnsfr_info_ttype IS TABLE OF g_vd_inv_trnsfr_info_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_out_cnt                 NUMBER;                                          -- �ۊǏꏊ�]�����쐬�ΏۊO����
  gn_target_column_no_cnt    NUMBER;                                          -- �Ώی���(�R����No.�P�ʑ���)
  gn_normal_column_no_cnt    NUMBER;                                          -- ��������(�R����No.�P�ʑ���)
  gn_error_column_no_cnt     NUMBER;                                          -- �G���[����(�R����No.�P�ʑ���)
  gt_org_id                  mtl_parameters.organization_id%TYPE;             -- �݌ɑg�DID
  gt_tran_type_id            mtl_transaction_types.transaction_type_id%TYPE;  -- ����^�C�vID
  gd_proc_date               DATE;                                            -- ������
  gb_org_acct_period_flg     BOOLEAN;                                         -- �O���݌ɉ�v���ԃI�[�v���t���O
  g_cust_shift_info_tab      g_cust_shift_info_ttype;                         -- PL/SQL�\�F�ڋq�ڍs���i�[�p
  gn_cust_cnt                NUMBER;                                          -- PL/SQL�\�C���f�b�N�X
  g_vd_inv_trnsfr_info_tab   g_vd_inv_trnsfr_info_ttype;                      -- PL/SQL�\�FVD�݌ɕۊǏꏊ�]�����[�p
  gn_column_no_cnt           NUMBER;                                          -- PL/SQL�\�C���f�b�N�X

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_process_flag IN  VARCHAR2      -- �N���敪
    , ov_errbuf       OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_prf_org_code     CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';      -- �v���t�@�C�� �݌ɑg�D�R�[�h
    cv_lookup_type      CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME';  -- �Q�ƃ^�C�v ����^�C�v����
    cv_lookup_code      CONSTANT VARCHAR2(3)  := '290';                           -- �Q�ƃR�[�h ����^�C�v(���_����VD�݌ɐU��)
    cn_next_day         CONSTANT NUMBER       := 1;                               -- ����
    cn_proc_type        CONSTANT NUMBER       := 2;                               -- �����敪�F��
    cn_system_cal       CONSTANT NUMBER       := 1;                               -- �J�����_�[�敪�F�V�X�e���ғ����J�����_�[
--
    -- *** ���[�J���ϐ� ***
    lt_org_code                 mtl_parameters.organization_code%TYPE;            -- �݌ɑg�D�R�[�h
    lt_sys_cal_code             bom_calendar_dates.calendar_code%TYPE;            -- �V�X�e���ғ����J�����_�[�R�[�h
    lt_tran_type_name           mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v��
    ld_process_date             DATE;                                             -- �Ɩ����t
    ld_oprtn_date               DATE;                                             -- �V�X�e���ғ���
    ld_last_month_proc_date     DATE;                                             -- �O���������t(�������t�|�P�����̓��t)
    lb_org_acct_period_flg      BOOLEAN;                                          -- �����݌ɉ�v���ԃI�[�v���t���O

--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- �R���J�����g���̓p�����[�^���b�Z�[�W�o��
    -- ==============================================================
    -- ���̓p�����[�^���Ȃ������ꍇ
    IF ( iv_process_flag IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcok
                     , iv_name         => cv_msg_no_prm
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcok
                    , iv_name         => cv_msg_prm
                    , iv_token_name1  => cv_tkn_process_flag
                    , iv_token_value1 => iv_process_flag
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    -- ==============================================================
    -- �݌ɑg�DID�擾
    -- ==============================================================
    -- �݌ɑg�D�R�[�h�擾
    lt_org_code := fnd_profile.value( cv_prf_org_code );
    -- �v���t�@�C������݌ɑg�D�R�[�h���擾�ł��Ȃ��ꍇ
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_org_code_get_err
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �݌ɑg�DID�擾
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_code );
    -- �݌ɑg�DID���擾�ł��Ȃ��ꍇ
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_org_id_get_err
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => TO_CHAR( lt_org_code )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- �������擾
    -- ==============================================================
    -- �Ɩ����t�擾
    ld_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_process_date_get_err
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    
    -- �N���敪�����J�o���̏ꍇ:���������Ɩ����t
    IF ( iv_process_flag = cv_prm_recovery ) THEN
      gd_proc_date := ld_process_date;
    -- �N���敪���ʏ�N���̏ꍇ:�����������V�X�e���ғ���
    ELSE
      -- �V�X�e���ғ����擾(���V�X�e���ғ���)
      gd_proc_date := xxcok_common_pkg.get_operating_day_f (
                          id_proc_date     => ld_process_date  -- �������F�Ɩ����t
                        , in_days          => cn_next_day      -- �����F1
                        , in_proc_type     => cn_proc_type     -- �����敪�F��
                        , in_calendar_type => cn_system_cal    -- �J�����_�[�敪�F�V�X�e���ғ����J�����_�[
                      );
      -- �V�X�e���ғ������擾�ł��Ȃ��ꍇ
      IF ( gd_proc_date IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcok
                       , iv_name         => cv_msg_oprtn_date_get_err
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ==============================================================
    -- �݌ɉ�v���ԃX�e�[�^�X�擾
    -- ==============================================================
    -- �����݌ɉ�v���ԃX�e�[�^�X�擾
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id               -- �݌ɑg�DID
      , id_target_date     => gd_proc_date            -- ������
      , ob_chk_result      => lb_org_acct_period_flg  -- �`�F�b�N����
      , ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
    );
    -- �݌ɉ�v���ԃX�e�[�^�X�̎擾�Ɏ��s�����ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_org_acct_period_get_err
                     , iv_token_name1  => cv_tkn_target_date
                     , iv_token_value1 => TO_CHAR( gd_proc_date )
                   );
      RAISE global_api_expt;
    END IF;
    -- �����݌ɉ�v���Ԃ��N���[�Y�̏ꍇ
    IF ( NOT lb_org_acct_period_flg ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcok
                     , iv_name         => cv_msg_org_acct_period_err
                     , iv_token_name1  => cv_tkn_proc_date
                     , iv_token_value1 => TO_CHAR( gd_proc_date )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ��������1�����O�̓��t���擾
    ld_last_month_proc_date := ADD_MONTHS( gd_proc_date, -1 );
    -- �O���݌ɉ�v���ԃX�e�[�^�X�擾
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                  -- �݌ɑg�DID
      , id_target_date     => ld_last_month_proc_date    -- ������
      , ob_chk_result      => gb_org_acct_period_flg     -- �`�F�b�N����
      , ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
    );
    -- �݌ɉ�v���ԃX�e�[�^�X�̎擾�Ɏ��s�����ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_org_acct_period_get_err
                     , iv_token_name1  => cv_tkn_target_date
                     , iv_token_value1 => TO_CHAR( ld_last_month_proc_date )
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- ����^�C�vID�擾
    -- ==============================================================
    -- ����^�C�v���擾
    lt_tran_type_name := xxcoi_common_pkg.get_meaning( cv_lookup_type, cv_lookup_code );
    -- ���ʊ֐��̃��^�[���R�[�h��NULL�̏ꍇ
    IF ( lt_tran_type_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_tran_type_name_get_err
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_lookup_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_lookup_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    
    -- ����^�C�vID�擾
    gt_tran_type_id := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_name );
    -- ���ʊ֐��̃��^�[���R�[�h��NULL�̏ꍇ
    IF ( gt_tran_type_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_tran_type_id_get_err
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
   * Procedure Name   : get_cust_shift_info
   * Description      : �ڋq�ڍs���̎擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_cust_shift_info(
      on_cust_shift_cnt  OUT NUMBER        -- �擾����
    , ov_errbuf          OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode         OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg          OUT VARCHAR2 )    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_shift_info'; -- �v���O������
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
    cv_status_fix  CONSTANT VARCHAR2(1) := 'A';   -- �X�e�[�^�X�F�m��
    cv_fvd         CONSTANT VARCHAR2(2) := '25';  -- �t��VD
    cv_fvds        CONSTANT VARCHAR2(2) := '24';  -- �t��VD(����)
    cv_svd         CONSTANT VARCHAR2(2) := '27';  -- ����VD
    cv_v           CONSTANT VARCHAR2(1) := 'V';   -- �ۊǏꏊ�R�[�h�ϊ��p�FVD(�t��VD/�t��VD(����)/����VD����)
    cv_f           CONSTANT VARCHAR2(1) := 'F';   -- �ۊǏꏊ�R�[�h�ϊ��p�F�t��VD/�t��VD(����)
    cv_s           CONSTANT VARCHAR2(1) := 'S';   -- �ۊǏꏊ�R�[�h�ϊ��p�F����VD
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �ڋq�ڍ����擾
    CURSOR cust_shift_info_cur
    IS
      SELECT hca.cust_account_id         AS cust_account_id               -- 1.�ڋqID
           , xcs.cust_shift_id           AS cust_shift_id                 -- 2.�ڋq�ڍs���ID
           , xcs.cust_code               AS cust_code                     -- 3.�ڋq�R�[�h
           , xcs.prev_base_code          AS prev_base_code                -- 4.���S�����_�R�[�h
           , xcs.new_base_code           AS new_base_code                 -- 5.�V�S�����_�R�[�h
           , xcs.cust_shift_date         AS cust_shift_date               -- 6.�ڋq�ڍs��
           , CASE WHEN xca.business_low_type = cv_fvd                     -- 7.VD�݌ɕۊǏꏊ�]���X�e�[�^�X
                    OR xca.business_low_type = cv_fvds                    
                    OR xca.business_low_type = cv_svd 
                  THEN                                                    --  �Ƒԁi�����ށj:�t��VD/�t��VD(����)/����VD
                    xcs.vd_inv_trnsfr_status                              --    �擾����VD�݌ɕۊǏꏊ�]���X�e�[�^�X
                  ELSE                                                    --  �Ƒԁi�����ށj:���̑�
                    cv_trnsfr_status_out                                  --    �ΏۊO�ɐݒ�
             END                         AS vd_inv_trnsfr_status          -- 7.VD�݌ɕۊǏꏊ�]���X�e�[�^�X
           , CASE WHEN xca.business_low_type = cv_fvd                     -- 8.�o�ɑ��ۊǏꏊ�R�[�h  
                    OR xca.business_low_type = cv_fvds                    
                  THEN                                                    --  �Ƒԁi�����ށj:�t��VD/�t��VD(����)
                    cv_v || xcs.prev_base_code || cv_f                    --    'V'+���S�����_�R�[�h+'F'
                  WHEN xca.business_low_type = cv_svd THEN                --  �Ƒԁi�����ށj:����VD
                    cv_v || xcs.prev_base_code || cv_s                    --    'V'+���S�����_�R�[�h+'S'
                  ELSE                                                    --  �Ƒԁi�����ށj:���̑�
                    ''                                                    --    NULL
             END                         AS sec_inv_code_out              --  �o�ɑ��ۊǏꏊ�R�[�h
           , CASE WHEN xca.business_low_type = cv_fvd                     -- 9.���ɑ��ۊǏꏊ�R�[�h
                    OR xca.business_low_type = cv_fvds                    
                  THEN                                                    --  �Ƒԁi�����ށj:�t��VD/�t��VD(����)
                    cv_v || xcs.new_base_code  || cv_f                    --    'V'+�V�S�����_�R�[�h+'F'
                  WHEN xca.business_low_type = cv_svd THEN                --  �Ƒԁi�����ށj:����VD
                    cv_v || xcs.new_base_code  || cv_s                    --    'V'+�V�S�����_�R�[�h+'S'
                  ELSE                                                    --  �Ƒԁi�����ށj:���̑�
                    ''                                                    --    NULL
             END                         AS sec_inv_code_in               --  ���ɑ��ۊǏꏊ�R�[�h
      FROM   xxcok_cust_shift_info       xcs                              -- �ڋq�ڍs���e�[�u��
           , hz_cust_accounts            hca                              -- �ڋq�}�X�^
           , xxcmm_cust_accounts         xca                              -- �ڋq�ǉ����e�[�u��
      WHERE  xcs.status                  =   cv_status_fix                -- �X�e�[�^�X�i�m��j
      AND    xcs.cust_shift_date         <=  gd_proc_date                 -- �ڋq�ڍs�� <= ������
      AND    xcs.vd_inv_trnsfr_status                                     -- VD�݌ɕۊǏꏊ�]���X�e�[�^�X
        IN ( cv_trnsfr_status_prev, cv_trnsfr_status_reserve )            --    ����]��� ��ۗ��
      AND    xcs.cust_code               =   hca.account_number           -- �ڋq�R�[�h
      AND    hca.cust_account_id         =   xca.customer_id;             -- �ڋqID

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
    OPEN cust_shift_info_cur;
    
    FETCH cust_shift_info_cur BULK COLLECT INTO g_cust_shift_info_tab;

    -- �ڋq�����Z�b�g
    on_cust_shift_cnt := g_cust_shift_info_tab.COUNT;

    -- �J�[�\���N���[�Y
    CLOSE cust_shift_info_cur;
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
      -- �J�[�\�����I�[�v�����Ă�����N���[�Y
      IF ( cust_shift_info_cur%ISOPEN ) THEN
        CLOSE cust_shift_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_cust_shift_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_transfer_cust
   * Description      : �]���Ώۃ`�F�b�N (A-4)
   ***********************************************************************************/
  PROCEDURE chk_transfer_cust(
      ov_trnsfr_status       OUT   VARCHAR2        -- �]���X�e�[�^�X
    , ov_errbuf              OUT   VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode             OUT   VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg              OUT   VARCHAR2 )      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_transfer_cust'; -- �v���O������
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
    ln_last_manth_fix_info        NUMBER;  -- �O��VD�݌Ɋm����
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
    -- �����l�F�]���Ώ�(�u�]���ρv�X�V�Ώ�)
    ov_trnsfr_status := cv_trnsfr_status_trnsfr;  

    -- VD�݌ɕۊǏꏊ�]���X�e�[�^�X���u�ΏۊO�v�̏ꍇ(A-2�ŋƑԁi�����ށj:�t��VD/�t��VD(����)/����VD�ȊO)
    IF ( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_vd_inv_trnsfr_status = cv_trnsfr_status_out ) THEN
      -- �u�ΏۊO�v�X�V�ΏۂƂ���
      ov_trnsfr_status := cv_trnsfr_status_out;

    -- �Ƒԁi�����ށj:�t��VD/�t��VD(����)/����VD�̌ڋq�őO���݌ɉ�v���Ԃ��I�[�v�����ڋq�ڍs���������̏ꍇ
    ELSIF ( gb_org_acct_period_flg ) 
      AND ( TRUNC( gd_proc_date , 'MM' ) <= TRUNC( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_shift_date ) )
    THEN
      -- VD�݌ɕۊǏꏊ�]���X�e�[�^�X���u�ۗ��v�̏ꍇ
      IF ( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_vd_inv_trnsfr_status = cv_trnsfr_status_reserve ) THEN
        -- �u�ۗ��v�X�V�ΏۂƂ���
        ov_trnsfr_status := cv_trnsfr_status_reserve;

      -- VD�݌ɕۊǏꏊ�]���X�e�[�^�X���u���]���v�̏ꍇ
      ELSIF ( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_vd_inv_trnsfr_status = cv_trnsfr_status_prev ) THEN
        -- �ڋq�ڍs���������̏ꍇ
        IF ( TRUNC( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_shift_date, 'DD' )
           = TRUNC( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_shift_date, 'MM' ) )
        THEN
          --�u�ۗ��v�X�V�ΏۂƂ���
          ov_trnsfr_status := cv_trnsfr_status_reserve;

        -- �ڋq�ڍs���������ȊO�̏ꍇ
        ELSE
-- 2009/12/10 Ver.1.2 [E_�{�ғ�_00405] SCS S.Moriyama UPD START
--          -- �O��VD�݌Ɋm���񒊏o
--          SELECT   count(ROWID)                                                                  -- �O��VD�݌Ɋm����
--          INTO     ln_last_manth_fix_info
--          FROM     xxcoi_mst_vd_column   xmvc1                                                   -- VD�R�����}�X�^
--          WHERE    xmvc1.customer_id = g_cust_shift_info_tab( gn_cust_cnt ).hca_cust_account_id  -- �ڋqID
--          AND NOT EXISTS (
--            SELECT ROWID 
--            FROM   xxcoi_mst_vd_column xmvc2
--            WHERE  xmvc2.customer_id                   = xmvc1.customer_id
--            AND    xmvc2.column_no                     = xmvc1.column_no
--            AND    xmvc2.last_month_item_id            = xmvc1.item_id
--            AND    xmvc2.last_month_inventory_quantity = xmvc1.inventory_quantity
--            AND    xmvc2.last_month_price              = xmvc1.price
--          )
--          AND    ROWNUM = 1;
          -- �O��VD�݌Ɋm���񒊏o
          SELECT   count(ROWID)                                                                  -- �O��VD�݌Ɋm����
          INTO     ln_last_manth_fix_info
          FROM     xxcoi_mst_vd_column   xmvc1                                                   -- VD�R�����}�X�^
          WHERE    xmvc1.customer_id = g_cust_shift_info_tab( gn_cust_cnt ).hca_cust_account_id  -- �ڋqID
          AND NOT EXISTS (
            SELECT ROWID 
            FROM   xxcoi_mst_vd_column xmvc2
            WHERE  xmvc2.customer_id                           = xmvc1.customer_id
            AND    xmvc2.column_no                             = xmvc1.column_no
            AND    NVL(xmvc2.last_month_item_id,-1)            = NVL(xmvc1.item_id,-1)
            AND    NVL(xmvc2.last_month_inventory_quantity,-1) = NVL(xmvc1.inventory_quantity,-1)
            AND    NVL(xmvc2.last_month_price,-1)              = NVL(xmvc1.price,-1)
          )
          AND    ROWNUM = 1;
-- 2009/12/10 Ver.1.2 [E_�{�ғ�_00405] SCS S.Moriyama UPD END
          -- �O��VD�݌Ɋm����0���̏ꍇ
          IF ( ln_last_manth_fix_info = 0 ) THEN
            --�u�ۗ��v�X�V�ΏۂƂ���
            ov_trnsfr_status := cv_trnsfr_status_reserve;
          END IF;
        END IF;
      END IF;
    END IF;
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
  END chk_transfer_cust;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_inv_info�i�ڋq�ڍ���񃋁[�v���j
   * Description      : VD�݌ɕۊǏꏊ�]�����擾 (A-5)
   ***********************************************************************************/
  PROCEDURE get_vd_inv_info(
      on_vd_inv_info_cnt  OUT NUMBER        -- �擾����
    , ov_errbuf           OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode          OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg           OUT VARCHAR2 )    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_vd_inv_info'; -- �v���O������
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
    ln_sec_inv_cnt         NUMBER;                                                  -- �ۊǏꏊ�`�F�b�N�p�J�E���^
    lt_tkn_sub_inv_code    mtl_secondary_inventories.secondary_inventory_name%TYPE; -- �g�[�N��(�ۊǏꏊ�R�[�h)
    lt_tkn_base_code       xxcok_cust_shift_info.cust_code%TYPE;                    -- �g�[�N��(�ڋq�R�[�h)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �O��VD�݌Ɏ擾�p�J�[�\��
    CURSOR vd_inv_last_month_cur
    IS
      SELECT xmvc.column_no                      AS xmvc_column_no           --  1.�R����No.
           , xmvc.last_month_item_id             AS xmvc_item_id             --  2.�i��ID(�O�����i��ID)
           , msib.segment1                       AS msib_item_code           --  3.�i�ڃR�[�h
           , xmvc.last_month_inventory_quantity  AS xmvc_inv_qty             --  4.��݌ɐ�(�O������݌ɐ�)
           , msib.primary_uom_code               AS msib_primary_uom         --  5.��P��
           , msib.inventory_item_status_code     AS msib_item_status         --  6.�i�ڃX�e�[�^�X
           , msib.customer_order_enabled_flag    AS msib_cust_order_flg      --  7.�ڋq�󒍉\�t���O
           , msib.mtl_transactions_enabled_flag  AS msib_transaction_enable  --  8.����\
           , msib.stock_enabled_flag             AS msib_stock_enabled_flg   --  9.�݌ɕۗL�\�t���O
           , msib.returnable_flag                AS msib_return_enable       -- 10.�ԕi�\
           , iimb.attribute26                    AS iimb_sales_class         -- 11.����Ώۋ敪
      FROM   xxcoi_mst_vd_column                 xmvc                        -- VD�R�����}�X�^
           , mtl_system_items_b                  msib                        -- Disc�i�ڃ}�X�^
           , ic_item_mst_b                       iimb                        -- OPM�i�ڃ}�X�^
      WHERE  xmvc.customer_id
             = g_cust_shift_info_tab( gn_cust_cnt ).hca_cust_account_id
      AND    xmvc.last_month_item_id            = msib.inventory_item_id     -- �O�����i��ID
      AND    xmvc.organization_id               = msib.organization_id       -- �݌ɑg�DID
      AND    xmvc.last_month_inventory_quantity > 0                          -- �O������݌ɐ� > 0
      AND    iimb.item_no                       = msib.segment1;             -- �i�ڃR�[�h

    -- ����VD�݌Ɏ擾�p�J�[�\��
    CURSOR vd_inv_this_month_cur
    IS
      SELECT xmvc.column_no                      AS xmvc_column_no           --  1.�R����No.
           , xmvc.item_id                        AS xmvc_item_id             --  2.�i��ID
           , msib.segment1                       AS msib_item_code           --  3.�i�ڃR�[�h
           , xmvc.inventory_quantity             AS xmvc_inv_qty             --  4.��݌ɐ�
           , msib.primary_uom_code               AS msib_primary_uom         --  5.��P��
           , msib.inventory_item_status_code     AS msib_item_status         --  6.�i�ڃX�e�[�^�X
           , msib.customer_order_enabled_flag    AS msib_cust_order_flg      --  7.�ڋq�󒍉\�t���O
           , msib.mtl_transactions_enabled_flag  AS msib_transaction_enable  --  8.����\
           , msib.stock_enabled_flag             AS msib_stock_enabled_flg   --  9.�݌ɕۗL�\�t���O
           , msib.returnable_flag                AS msib_return_enable       -- 10.�ԕi�\
           , iimb.attribute26                    AS iimb_sales_class         -- 11.����Ώۋ敪
      FROM   xxcoi_mst_vd_column                 xmvc                        -- VD�R�����}�X�^
           , mtl_system_items_b                  msib                        -- Disc�i�ڃ}�X�^
           , ic_item_mst_b                       iimb                        -- OPM�i�ڃ}�X�^
      WHERE  xmvc.customer_id
             = g_cust_shift_info_tab( gn_cust_cnt ).hca_cust_account_id
      AND    xmvc.item_id                       = msib.inventory_item_id     -- �i��ID
      AND    xmvc.organization_id               = msib.organization_id       -- �݌ɑg�DID
      AND    xmvc.inventory_quantity            > 0                          -- ��݌ɐ� > 0
      AND    iimb.item_no                       = msib.segment1;             -- �i�ڃR�[�h


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

    -- VD�݌ɕۊǏꏊ�]���X�e�[�^�X���u�ۗ��v
    IF ( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_vd_inv_trnsfr_status = cv_trnsfr_status_reserve ) THEN
        
      -- �O�������擾
      -- �J�[�\���I�[�v��
      OPEN vd_inv_last_month_cur;
      -- �t�F�b�`
      FETCH vd_inv_last_month_cur BULK COLLECT INTO g_vd_inv_trnsfr_info_tab;
      -- VD�݌ɕۊǏꏊ�]�����擾�����Z�b�g
      on_vd_inv_info_cnt      := g_vd_inv_trnsfr_info_tab.COUNT;
      -- �J�[�\���N���[�Y
      CLOSE vd_inv_last_month_cur;

    -- VD�݌ɕۊǏꏊ�]���X�e�[�^�X���u���]���v
    ELSE

      -- �������擾
      -- �J�[�\���I�[�v��
      OPEN vd_inv_this_month_cur;
      -- �t�F�b�`
      FETCH vd_inv_this_month_cur BULK COLLECT INTO g_vd_inv_trnsfr_info_tab;
      -- VD�݌ɕۊǏꏊ�]�����擾�����Z�b�g
      on_vd_inv_info_cnt      := g_vd_inv_trnsfr_info_tab.COUNT;
      -- �J�[�\���N���[�Y
      CLOSE vd_inv_this_month_cur;

    END IF;

    -- �擾����0���̏ꍇ(���~�ڋq)
    IF ( on_vd_inv_info_cnt = 0 ) THEN
      RETURN;
    END IF;

    -- �ۊǏꏊ�`�F�b�N����
    -- �o�ɑ��ۊǏꏊ�`�F�b�N
    SELECT COUNT(1)
    INTO   ln_sec_inv_cnt
    FROM   mtl_secondary_inventories msi                                -- �ۊǏꏊ�}�X�^
    WHERE  msi.secondary_inventory_name 
           = g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_out  -- �o�ɑ��ۊǏꏊ�R�[�h
    AND    msi.organization_id               =   gt_org_id
    AND    TRUNC( NVL( msi.disable_date, SYSDATE + 1 ) )  > TRUNC( SYSDATE );
    
    -- �ۊǏꏊ������ł��Ȃ������ꍇ
    IF ( ln_sec_inv_cnt = 0 ) THEN
      lt_tkn_sub_inv_code := g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_out;
      lt_tkn_base_code      := g_cust_shift_info_tab( gn_cust_cnt ).xcsi_prev_base_code;
      RAISE sec_inv_expt;
    END IF;


    --���ɑ��ۊǏꏊ�`�F�b�N
    SELECT COUNT(1)
    INTO   ln_sec_inv_cnt
    FROM   mtl_secondary_inventories msi                                -- �ۊǏꏊ�}�X�^
    WHERE  msi.secondary_inventory_name 
           = g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_in   -- ���ɑ��ۊǏꏊ�R�[�h
    AND    msi.organization_id               =   gt_org_id
    AND    TRUNC( NVL( msi.disable_date, SYSDATE + 1 ) )  > TRUNC( SYSDATE );
    
    -- �ۊǏꏊ������ł��Ȃ������ꍇ
    IF ( ln_sec_inv_cnt = 0 ) THEN
      lt_tkn_sub_inv_code := g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_in;
      lt_tkn_base_code      := g_cust_shift_info_tab( gn_cust_cnt ).xcsi_new_base_code;
      RAISE sec_inv_expt;
    END IF;

--
  EXCEPTION
    -- *** �ۊǏꏊ�`�F�b�N�G���[ ***
    WHEN sec_inv_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcok
                     , iv_name         => cv_msg_sec_inv_chk_err
                     , iv_token_name1  => cv_tkn_cust_code
                     , iv_token_value1 => g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_code
                     , iv_token_name2  => cv_tkn_base_code
                     , iv_token_value2 => lt_tkn_base_code
                     , iv_token_name3  => cv_tkn_sub_inv_code
                     , iv_token_value3 => lt_tkn_sub_inv_code
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- �X�e�[�^�X���x���ɂ���
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
      -- �J�[�\�����I�[�v�����Ă�����N���[�Y
      IF ( vd_inv_last_month_cur%ISOPEN ) THEN
        CLOSE vd_inv_last_month_cur;
      END IF;
      IF ( vd_inv_this_month_cur%ISOPEN ) THEN
        CLOSE vd_inv_this_month_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_vd_inv_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_item_info
   * Description      : ���ڃ`�F�b�N (A-6)
   ***********************************************************************************/
  PROCEDURE chk_item_info(
      ov_errbuf       OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2 )    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item_info'; -- �v���O������
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
    cv_status_Inactive      CONSTANT VARCHAR2(10) := 'Inactive';          -- �X�e�[�^�X�FInactive
    cv_flg_y                CONSTANT VARCHAR2(1)  := 'Y';                 -- �t���O�l�FY
    cv_sales_classs_target  CONSTANT VARCHAR2(1)  := '1';                 -- ����Ώۋ敪�F�Ώ�
--
    -- *** ���[�J���ϐ� ***
    lt_disable_date           mtl_units_of_measure_tl.disable_date%TYPE;  -- ������
    lv_msg_name               VARCHAR2(100);                              -- ���b�Z�[�W
    
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
    -- �i�ڃX�e�[�^�X�L���`�F�b�N
    IF ( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_item_status = cv_status_Inactive         -- �i�ڃX�e�[�^�X
      OR NOT ( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_cust_order_flg     = cv_flg_y      -- �ڋq�󒍉\�t���O
        AND    g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_transaction_enable = cv_flg_y      -- ����\
        AND    g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_stock_enabled_flg  = cv_flg_y      -- �݌ɕۗL�\�t���O
        AND    g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_return_enable      = cv_flg_y ) )  -- �ԕi�\
    THEN
      lv_msg_name := cv_msg_item_status_chk_err;
      RAISE item_chk_expt;
    END IF;

    -- �i�ڔ���Ώۋ敪�L���`�F�b�N
    IF ( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).iimb_sales_class != cv_sales_classs_target ) THEN
      lv_msg_name := cv_msg_sales_class_chk_err;
      RAISE item_chk_expt;
    END IF;

    -- ��P�ʂ̖������擾
    xxcoi_common_pkg.get_uom_disable_info(
        iv_unit_code          => g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_primary_uom  -- 1.��P��
      , od_disable_date       => lt_disable_date                                                -- 2.������
      , ov_errbuf             => lv_errbuf                                                      -- 3.�G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                                     -- 4.���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                                      -- 5.���[�U�[�E�G���[�E���b�Z�[�W
    );

    -- ��P�ʂ̑��݃`�F�b�N
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_msg_name := cv_msg_primary_uom_not_found;
      RAISE primary_uom_chk_expt;
    END IF;

    -- ��P�ʂ̗L���`�F�b�N
    IF ( TRUNC( NVL( lt_disable_date, SYSDATE + 1 ) ) <= TRUNC( SYSDATE ) ) THEN 
      lv_msg_name := cv_msg_primary_uom_disable;
      RAISE primary_uom_chk_expt;
    END IF;

--
  EXCEPTION
    -- *** ���ڃ`�F�b�N�G���[(�i�ڃ`�F�b�N)�n���h�� ***
    WHEN item_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcok
                      , iv_name         => lv_msg_name
                      , iv_token_name1  => cv_tkn_cust_code
                      , iv_token_value1 => g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_code
                      , iv_token_name2  => cv_tkn_column_no
                      , iv_token_value2 => TO_CHAR( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_column_no )
                      , iv_token_name3  => cv_tkn_item_code
                      , iv_token_value3 => g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_item_code
                      , iv_token_name4  => cv_tkn_sub_inv_code
                      , iv_token_value4 => g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_out
                      , iv_token_name5  => cv_tkn_trnsfr_sub_inv
                      , iv_token_value5 => g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_in
                      , iv_token_name6  => cv_tkn_qty
                      , iv_token_value6 => TO_CHAR( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_inv_qty )
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- �X�e�[�^�X���x���ɂ���
      ov_retcode := cv_status_warn;
    -- *** ���ڃ`�F�b�N�G���[(��P�ʃ`�F�b�N) ***
    WHEN primary_uom_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcok
                      , iv_name         => lv_msg_name
                      , iv_token_name1  => cv_tkn_primary_uom
                      , iv_token_value1 => g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_primary_uom
                      , iv_token_name2  => cv_tkn_cust_code
                      , iv_token_value2 => g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_code
                      , iv_token_name3  => cv_tkn_column_no
                      , iv_token_value3 => TO_CHAR( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_column_no )
                      , iv_token_name4  => cv_tkn_item_code
                      , iv_token_value4 => g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_item_code
                      , iv_token_name5  => cv_tkn_sub_inv_code
                      , iv_token_value5 => g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_out
                      , iv_token_name6  => cv_tkn_trnsfr_sub_inv
                      , iv_token_value6 => g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_in
                      , iv_token_name7  => cv_tkn_qty
                      , iv_token_value7 => TO_CHAR( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_inv_qty )
                    );
      IF ( lv_errbuf IS NULL ) THEN
        lv_errbuf  := lv_errmsg;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- �X�e�[�^�X���x���ɂ���
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
  END chk_item_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_mtl_txn_oif
   * Description      : ���ގ��OIF�o�^ (A-7)
   ***********************************************************************************/
  PROCEDURE ins_mtl_txn_oif(
      ov_errbuf       OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2 )    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mtl_txn_oif'; -- �v���O������
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
    cn_oif_process_flg       CONSTANT NUMBER := 1;  -- �v���Z�X�t���O�F�����Ώ�
    cn_oif_transaction_mode  CONSTANT NUMBER := 3;  -- ������[�h�F�o�b�N�O���E���h
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
    -- ���ގ��OIF��VD�݌ɕۊǏꏊ�]������o�^
    -- �i��ID/��݌ɐ��cVD�݌ɕۊǏꏊ�]���X�e�[�^�X:���]�� �������/�ۗ��F�O�������
    INSERT INTO mtl_transactions_interface(
        source_code                                                    --  1.�\�[�X�R�[�h
      , source_header_id                                               --  2.�\�[�X�w�b�_ID
      , source_line_id                                                 --  3.�\�[�X���C��ID
      , process_flag                                                   --  4.�v���Z�X�t���O
      , transaction_mode                                               --  5.������[�h
      , transaction_type_id                                            --  6.����^�C�vID
      , transaction_date                                               --  7.�����
      , inventory_item_id                                              --  8.�i��ID
      , subinventory_code                                              --  9.�ۊǏꏊ
      , organization_id                                                -- 10.�݌ɑg�DID
      , transaction_quantity                                           -- 11.�������
      , primary_quantity                                               -- 12.��P�ʐ���
      , transaction_uom                                                -- 13.����P��
      , transfer_subinventory                                          -- 14.�ړ���ۊǏꏊ
      , transfer_organization                                          -- 15.�ړ���݌ɑg�D
      , created_by                                                     -- 16.�쐬��
      , creation_date                                                  -- 17.�쐬��
      , last_updated_by                                                -- 18.�ŏI�X�V��
      , last_update_date                                               -- 19.�ŏI�X�V��
      , last_update_login                                              -- 20.�ŏI�X�V���[�U
      , request_id                                                     -- 21.�v��ID
      , program_application_id                                         -- 22.�v���O�����A�v���P�[�V����ID
      , program_id                                                     -- 23.�v���O����ID
      , program_update_date                                            -- 24.�v���O�����X�V��
    )
    VALUES(
        cv_pkg_name                                                    --  1.�v���O�����Z�k��
      , g_cust_shift_info_tab( gn_cust_cnt ).hca_cust_account_id       --  2.�ڋqID
      , g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_column_no    --  3.�R����No.
      , cn_oif_process_flg                                             --  4.�����Ώ�(�Œ�)
      , cn_oif_transaction_mode                                        --  5.�o�b�N�O���E���h(�Œ�)
      , gt_tran_type_id                                                --  6.����^�C�vID(���_����VD�݌ɐU��)
      , g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_shift_date      --  7.�ڋq�ڍs��
      , g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_item_id      --  8.�i��ID
      , g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_out      --  9.�o�ɑ��ۊǏꏊ�R�[�h
      , gt_org_id                                                      -- 10.�݌ɑg�DID
      , g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_inv_qty      -- 11.��݌ɐ�
      , g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_inv_qty      -- 12.��݌ɐ�
      , g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_primary_uom  -- 13.��P��
      , g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_in       -- 14.���ɑ��ۊǏꏊ�R�[�h
      , gt_org_id                                                      -- 15.�݌ɑg�DID
      , cn_created_by                                                  -- 16.�쐬��
      , SYSDATE                                                        -- 17.�V�X�e�����t
      , cn_last_updated_by                                             -- 18.�ŏI�X�V��
      , SYSDATE                                                        -- 19.�V�X�e�����t
      , cn_last_update_login                                           -- 20.�ŏI�X�V�҃��O�C��
      , cn_request_id                                                  -- 21.�v��ID
      , cn_program_application_id                                      -- 22.�v���O�����A�v���P�[�V����ID
      , cn_program_id                                                  -- 23.�v���O����ID
      , SYSDATE                                                        -- 24.�V�X�e�����t
    );
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
  END ins_mtl_txn_oif;
--
  /**********************************************************************************
   * Procedure Name   : upd_status
   * Description      : �ڋq�ڍs���X�V (A-8)
   ***********************************************************************************/
  PROCEDURE upd_status(
      iv_trnsfr_status      IN  VARCHAR2      -- �]���X�e�[�^�X
    , ov_errbuf             OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode            OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg             OUT VARCHAR2 )    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_status'; -- �v���O������
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
    CURSOR upd_cust_shift_info_tbl_cur
    IS
      -- �ڋq�ڍs���e�[�u���̃��b�N�擾
      SELECT xcs.cust_shift_id            -- �ڋq�ڍs���ID
      FROM   xxcok_cust_shift_info   xcs  -- �ڋq�ڍs���e�[�u��
      WHERE  xcs.cust_shift_id = g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_shift_id
      FOR UPDATE NOWAIT;
      
--
    -- *** ���[�J���E���R�[�h ***
    upd_cust_shift_info_tbl_rec  upd_cust_shift_info_tbl_cur%ROWTYPE;
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
    -- VD�݌ɕۊǏꏊ�]���X�e�[�^�X�X�V
    -- ===============================
    -- �J�[�\���I�[�v��
    OPEN upd_cust_shift_info_tbl_cur;

    -- ���R�[�h�Ǎ�
    FETCH upd_cust_shift_info_tbl_cur INTO upd_cust_shift_info_tbl_rec;

    -- VD�݌ɕۊǏꏊ�]���X�e�[�^�X�X�V 
    UPDATE xxcok_cust_shift_info      xcs
    SET    xcs.vd_inv_trnsfr_status = iv_trnsfr_status                            -- 1.VD�݌ɕۊǏꏊ�]���X�e�[�^�X
         , last_updated_by          = cn_last_updated_by                          -- 2.�ŏI�X�V��
         , last_update_date         = SYSDATE                                     -- 3.�V�X�e�����t
         , last_update_login        = cn_last_update_login                        -- 4.�ŏI�X�V�҃��O�C��
         , request_id               = cn_request_id                               -- 5.�v��ID
         , program_application_id   = cn_program_application_id                   -- 6.�v���O�����A�v���P�[�V����ID
         , program_id               = cn_program_id                               -- 7.�v���O����ID
         , program_update_date      = SYSDATE                                     -- 8.�V�X�e�����t
    WHERE  xcs.cust_shift_id        = upd_cust_shift_info_tbl_rec.cust_shift_id;
    
    -- �J�[�\���N���[�Y
    CLOSE upd_cust_shift_info_tbl_cur;

--
  EXCEPTION
    -- *** ���b�N�G���[�n���h�� ***
    WHEN lock_expt THEN
      -- �J�[�\�����I�[�v�����Ă�����N���[�Y
      IF ( upd_cust_shift_info_tbl_cur%ISOPEN ) THEN
        CLOSE upd_cust_shift_info_tbl_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcok
                      , iv_name         => cv_msg_lock_err
                      , iv_token_name1  => cv_tkn_cust_code
                      , iv_token_value1 => g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_code
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- �X�e�[�^�X���x���ɂ���
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
      -- �J�[�\�����I�[�v�����Ă�����N���[�Y
      IF ( upd_cust_shift_info_tbl_cur%ISOPEN ) THEN
        CLOSE upd_cust_shift_info_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_status;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_process_flag IN  VARCHAR2      -- �N���敪
    , ov_errbuf       OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2 )    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lt_trnsfr_status        xxcok_cust_shift_info.vd_inv_trnsfr_status%TYPE;  -- �]���X�e�[�^�X(�ڋq�ڍs���X�V�p)
    ln_cust_shift_cnt       NUMBER DEFAULT 0;                                 -- �擾�����F�ڋq�ڍs���(A-2)
    ln_vd_inv_info_cnt      NUMBER DEFAULT 0;                                 -- �擾�����FVD�݌ɕۊǏꏊ�]�����(A-5)
    ln_target_column_no_cnt NUMBER DEFAULT 0;                                 -- �Ώی���  (�P�ڋq�P�ʃR������)
    ln_normal_column_no_cnt NUMBER DEFAULT 0;                                 -- ��������  (�P�ڋq�P�ʃR������)
    ln_error_column_no_cnt  NUMBER DEFAULT 0;                                 -- �G���[����(�P�ڋq�P�ʃR������)

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
    gn_target_cnt           := 0;  -- �Ώی���
    gn_normal_cnt           := 0;  -- ��������
    gn_error_cnt            := 0;  -- �G���[����
    gn_warn_cnt             := 0;  -- �X�L�b�v����
    gn_out_cnt              := 0;  -- �ۊǏꏊ�]�����쐬�ΏۊO����
    gn_target_column_no_cnt := 0;  -- �Ώی���  (�R����No.�P�ʑ���)
    gn_normal_column_no_cnt := 0;  -- ��������  (�R����No.�P�ʑ���)
    gn_error_column_no_cnt  := 0;  -- �G���[����(�R����No.�P�ʑ���)
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
        iv_process_flag => iv_process_flag  -- �N���敪
      , ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W
      , ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h
      , ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �ڋq�ڍs���̎擾 (A-2)
    -- ===============================
    get_cust_shift_info(
        on_cust_shift_cnt  => ln_cust_shift_cnt  -- �擾����
      , ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W
      , ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h
      , ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;

    -- �擾����0���̏ꍇ
    IF ( ln_cust_shift_cnt = 0 ) THEN
      -- �Ώۃf�[�^�������b�Z�[�W�o��
      gv_out_msg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcok
                       , iv_name         => cv_msg_no_data
                     );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      RETURN;
    END IF;

    -- �Ώی����Z�b�g(�ڋq�P��)
    gn_target_cnt := ln_cust_shift_cnt;

    <<cust_loop>>  -- �ڋq�P�ʃ��[�v
    FOR i IN 1 .. ln_cust_shift_cnt LOOP
      -- ������
      gn_cust_cnt             := i;                        -- PL/SQL�\�C���f�b�N�X
      ln_vd_inv_info_cnt      := 0;
      ln_target_column_no_cnt := 0;
      ln_normal_column_no_cnt := 0;
      ln_error_column_no_cnt  := 0;
--
      -- ===============================
      -- �Z�[�u�|�C���g�ݒ� (A-3)
      -- ===============================
      SAVEPOINT cust_point;
--
--
      -- ===============================
      -- �]���Ώۃ`�F�b�N (A-4)
      -- ===============================
      chk_transfer_cust(
          ov_trnsfr_status  => lt_trnsfr_status  -- �]���X�e�[�^�X
        , ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W
        , ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h
        , ov_errmsg         => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �]���Ώۂ̏ꍇ
      IF ( lt_trnsfr_status = cv_trnsfr_status_trnsfr ) THEN
--
        -- ===============================
        -- VD�݌ɕۊǏꏊ�]�����擾 (A-5)
        -- ===============================
        get_vd_inv_info(
            on_vd_inv_info_cnt  => ln_vd_inv_info_cnt  -- �擾����
          , ov_errbuf           => lv_errbuf           -- �G���[�E���b�Z�[�W
          , ov_retcode          => lv_retcode          -- ���^�[���E�R�[�h
          , ov_errmsg           => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;

        -- �ۊǏꏊ�`�F�b�N�G���[�����������ꍇ
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => lv_errmsg -- ���[�U�[�E�G���[���b�Z�[�W
          );
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => lv_errbuf -- �G���[���b�Z�[�W
          );
          -- �G���[����
          gn_error_cnt := gn_error_cnt + 1;
          -- �]���X�e�[�^�X�ɃG���[���Z�b�g(�X�V�ΏۊO�Ƃ���)
          lt_trnsfr_status := cv_trnsfr_status_error;
          -- �擾�������Z�b�g
          ln_vd_inv_info_cnt := 0;
          -- �X�e�[�^�X���x���ɂ���
          ov_retcode := cv_status_warn;

        -- �ڋq�ɑ΂���VD�݌ɕۊǏꏊ�]����񂪑��݂��Ȃ��ꍇ(���~�ڋq)
        ELSIF ( lv_retcode = cv_status_normal AND ln_vd_inv_info_cnt = 0 ) THEN
          -- �u�ΏۊO�v�X�V�ΏۂƂ���
          lt_trnsfr_status := cv_trnsfr_status_out;
        END IF;
--
      END IF;

      -- VD�݌ɕۊǏꏊ�]����񂪑��݂���ꍇ
      IF ( ln_vd_inv_info_cnt > 0 ) THEN

        -- �Ώی���(�P�ڋq�P�ʃR������)�Z�b�g
        ln_target_column_no_cnt := ln_vd_inv_info_cnt;

        <<column_no_loop>>  -- �R����No.�P�ʃ��[�v
        FOR j IN 1 .. ln_vd_inv_info_cnt LOOP
          -- ������
          gn_column_no_cnt := j;  -- PL/SQL�\�C���f�b�N�X
--
          -- ===============================
          -- ���ڃ`�F�b�N (A-6)
          -- ===============================
          chk_item_info(
              ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
            , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
            , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          -- ���ڃ`�F�b�N�G���[�����������ꍇ
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => lv_errmsg -- ���[�U�[�E�G���[���b�Z�[�W
            );
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
              , buff   => lv_errbuf -- �G���[���b�Z�[�W
            );
            -- �G���[����(�P�ڋq�P�ʃR������)�Z�b�g
            ln_error_column_no_cnt := ln_error_column_no_cnt + 1;
            -- �X�e�[�^�X���x���ɂ���
            ov_retcode := cv_status_warn;
          -- ���ڃ`�F�b�NOK
          ELSE
--
            -- ===============================
            -- ���ގ��OIF�o�^ (A-7)
            -- ===============================
            ins_mtl_txn_oif(
                ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
              , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
              , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
            -- ��������(�R����No.�P�ʑ���)
            ln_normal_column_no_cnt := ln_normal_column_no_cnt + 1;
--
          END IF;
        END LOOP column_no_loop;
      END IF;
--
      -- �]���X�e�[�^�X���G���[�ȊO�̏ꍇ
      IF ( lt_trnsfr_status != cv_trnsfr_status_error ) THEN
        -- ===============================
        -- �ڋq�ڍs���X�V (A-8)
        -- ===============================
        upd_status(
            iv_trnsfr_status  => lt_trnsfr_status  -- �]���X�e�[�^�X
          , ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W
          , ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h
          , ov_errmsg         => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        -- ���b�N�G���[�����������ꍇ
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => lv_errmsg -- ���[�U�[�E�G���[���b�Z�[�W
          );
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => lv_errbuf -- �G���[���b�Z�[�W
          );
          
          -- �G���[���� (VD�ۊǏꏊ�]���X�e�[�^�X���X�V)
          gn_error_cnt := gn_error_cnt + 1;
          -- �X�e�[�^�X���x���ɂ���
          ov_retcode := cv_status_warn;
          -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
          ROLLBACK TO SAVEPOINT cust_point;
        -- �X�e�[�^�X���X�V�����ꍇ
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          -- �]���X�e�[�^�X���u�]���ρv�ɍX�V�����ꍇ
          IF ( lt_trnsfr_status = cv_trnsfr_status_trnsfr ) THEN
            -- ��������
            gn_normal_cnt := gn_normal_cnt + 1;
          -- �]���X�e�[�^�X���u�ۗ��v  �ɍX�V�����ꍇ
          ELSIF  ( lt_trnsfr_status = cv_trnsfr_status_reserve ) THEN
            -- �X�L�b�v����
            gn_warn_cnt   := gn_warn_cnt + 1;
          -- �]���X�e�[�^�X���u�ΏۊO�v�ɍX�V�����ꍇ
          ELSIF  ( lt_trnsfr_status = cv_trnsfr_status_out ) THEN
            -- �ۊǏꏊ�]�����쐬�ΏۊO����
            gn_out_cnt    := gn_out_cnt + 1;
          END IF;
          -- �ڋq�P�ʂ̑Ώی���/��������/�G���[�����𑍌����ɉ��Z
          gn_target_column_no_cnt := gn_target_column_no_cnt + ln_target_column_no_cnt;
          gn_normal_column_no_cnt := gn_normal_column_no_cnt + ln_normal_column_no_cnt;
          gn_error_column_no_cnt  := gn_error_column_no_cnt  + ln_error_column_no_cnt;
        END IF;
      END IF;

    END LOOP cust_loop;

--
  EXCEPTION
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
      errbuf          OUT VARCHAR2     --  �G���[���b�Z�[�W #�Œ�#
    , retcode         OUT VARCHAR2     --  �G���[�R�[�h     #�Œ�#
    , iv_process_flag IN  VARCHAR2 )   --  �N���敪
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
        iv_process_flag => iv_process_flag  -- �N���敪
      , ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �X�e�[�^�X�F�ُ�
    IF ( lv_retcode = cv_status_error ) THEN
      -- �����Z�b�g
      gn_target_cnt           := 0;
      gn_normal_cnt           := 0;
      gn_error_cnt            := 1;
      gn_warn_cnt             := 0;
      gn_target_column_no_cnt := 0;
      gn_normal_column_no_cnt := 0;
      gn_error_column_no_cnt  := 0;
      -- �G���[�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg -- ���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf -- �G���[���b�Z�[�W
      );
    END IF;
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    
    -- �ڋq�P�ʌ������b�Z�[�W
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_xxcok
                , iv_name         => cv_msg_unit_cust
              );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );

    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- �X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- �ۊǏꏊ�]�����쐬�ΏۊO�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcok
                    , iv_name         => cv_msg_out_rec
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_out_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- �R����No.�P�ʌ������b�Z�[�W
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_xxcok
                , iv_name         => cv_msg_unit_column_no
              );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- �Ώی���(�R����No.�P�ʑ���)�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_column_no_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��������(�R����No.�P�ʑ���)�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_column_no_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- �G���[����(�R����No.�P�ʑ���)�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_column_no_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
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
END XXCOK003A01C;
/
