CREATE OR REPLACE PACKAGE BODY XXCOI003A13C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A13C(spec)
 * Description      : �ۊǏꏊ�]������f�[�^OIF�X�V�i�q�֏��j
 * MD.050           : �ۊǏꏊ�]������f�[�^OIF�X�V�i�q�֏��j MD050_COI_003_A13
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_kuragae_data       �q�փf�[�^���o���� (A-2)
 *  chk_kuragae_data       �q�փf�[�^�Ó����`�F�b�N���� (A-3)
 *  chk_ins_upd            �ǉ��^�X�V���菈�� (A-4)
 *  ins_storage_info_tab   ���ɏ��ꎞ�\�ǉ����� (A-5)
 *  upd_storage_info_tab   ���ɏ��ꎞ�\�X�V���� (A-6)
 *  ins_kuragae_data       �q�փf�[�^�ǉ����� (A-7)
 *  upd_hht_inv_tab        HHT���o�Ɉꎞ�\�X�V���� (A-8)
 *  del_hht_inv_tab        HHT���o�Ɉꎞ�\�폜���� (A-10)
 *  submain                ���C�������v���V�[�W��
 *                         �G���[���X�g�\�ǉ����� (A-9)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������ (A-11)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.0   K.Nakamura       �V�K�쐬
 *  2009/02/20    1.1   K.Nakamura       [��QCOI_024] �S�ݓXHHT�̓��Ɋm�F���X�V���A�]����q�ɃR�[�h�ݒ�Ή�
 *  2015/04/13    1.2   A.Uchida         [E_�{�ғ�_13008]�����_�c�ƎԂ̓��o�ɑΉ�
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
  lock_expt                      EXCEPTION; -- ���b�N�擾�G���[
  no_data_expt                   EXCEPTION; -- �擾�O����O
  outside_base_code_expt         EXCEPTION; -- �q�֑ΏۉۃG���[�i�o�ɑ����_�R�[�h�j
  inside_base_code_expt          EXCEPTION; -- �q�֑ΏۉۃG���[�i���ɑ����_�R�[�h�j
  acct_period_close_expt         EXCEPTION; -- �݌ɉ�v���ԃG���[
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ���b�N�擾��O
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(15)  := 'XXCOI003A13C'; -- �p�b�P�[�W��
  cv_appl_short_name             CONSTANT VARCHAR2(10)  := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_application_short_name      CONSTANT VARCHAR2(10)  := 'XXCOI';        -- �A�v���P�[�V�����Z�k��
  cv_flag_on                     CONSTANT VARCHAR2(1)   := 'Y';            -- �t���OON
  cv_flag_off                    CONSTANT VARCHAR2(1)   := 'N';            -- �t���OOFF
  cv_stock_uncheck_list_div_out  CONSTANT VARCHAR2(1)   := 'O';            -- ���ɖ��m�F���X�g�Ώۋ敪 O�F�o�ɑ����
  cv_stock_uncheck_list_div_in   CONSTANT VARCHAR2(1)   := 'I';            -- ���ɖ��m�F���X�g�Ώۋ敪 I�F���ɑ����
  cv_slip_type                   CONSTANT VARCHAR2(2)   := '20';           -- �`�[�敪 20:���_�ԑq��
  -- ���b�Z�[�W
  cv_no_para_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_org_code_get_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_org_id_get_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_no_data_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- �Ώۃf�[�^�������b�Z�[�W
  cv_tran_type_name_get_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00022'; -- ����^�C�v���擾�G���[���b�Z�[�W
  cv_tran_type_id_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00012'; -- ����^�C�vID�擾�G���[���b�Z�[�W
  cv_data_name_get_err_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10027'; -- �f�[�^���̎擾�G���[���b�Z�[�W
  cv_hht_table_lock_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10055'; -- ���b�N�擾�G���[���b�Z�[�W�iHHT���o�Ɉꎞ�\�j
  cv_info_table_lock_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10244'; -- ���b�N�擾�G���[���b�Z�[�W�i���ɏ��ꎞ�\�j
  cv_dept_code_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10052'; -- �q�֑ΏۉۃG���[���b�Z�[�W
  cv_acct_period_close_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10231'; -- �݌ɉ�v���ԃG���[���b�Z�[�W
  cv_key_info_msg                CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10342'; -- HHT���o�Ƀf�[�^�pKEY���
  -- 2015/04/27 Ver1.2 Add Start
  cv_lot_tran_temp_cre_error     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10453'; -- ���b�g�ʎ��TEMP�o�^�G���[���b�Z�[�W
  -- 2015/04/27 Ver1.2 Add End
  -- �g�[�N��
  cv_tkn_pro                     CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- �v���t�@�C����
  cv_tkn_org_code                CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- �݌ɑg�D�R�[�h
  cv_tkn_tran_type               CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- ����^�C�v��
  cv_tkn_lookup_type             CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';          -- �Q�ƃ^�C�v
  cv_tkn_lookup_code             CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';          -- �Q�ƃR�[�h
  cv_tkn_dept_code               CONSTANT VARCHAR2(20)  := 'DEPT_CODE';            -- ���_�R�[�h�i�o�ɑ��E���ɑ��j
  cv_tkn_invoice_date            CONSTANT VARCHAR2(20)  := 'INVOICE_DATE';         -- �`�[���t
  cv_tkn_base_code               CONSTANT VARCHAR2(20)  := 'BASE_CODE';            -- ���_�R�[�h
  cv_tkn_record_type             CONSTANT VARCHAR2(20)  := 'RECORD_TYPE';          -- ���R�[�h���
  cv_tkn_invoice_type            CONSTANT VARCHAR2(20)  := 'INVOICE_TYPE';         -- �`�[�敪
  cv_tkn_dept_flag               CONSTANT VARCHAR2(20)  := 'DEPT_FLAG';            -- �S�ݓX�t���O
  cv_tkn_invoice_no              CONSTANT VARCHAR2(20)  := 'INVOICE_NO';           -- �`�[No
  cv_tkn_column_no               CONSTANT VARCHAR2(20)  := 'COLUMN_NO';            -- �R����No
  cv_tkn_item_code               CONSTANT VARCHAR2(20)  := 'ITEM_CODE';            -- �i�ڃR�[�h
  -- 2015/04/27 Ver1.2 Add Start
  cv_tkn_name_err_msg           CONSTANT VARCHAR2(9)    := 'ERR_MSG';                   -- �G���[���b�Z�[�W
  -- 2015/04/27 Ver1.2 Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �q�փf�[�^���R�[�h�i�[�p
  TYPE gr_kuragae_data_rec IS RECORD(
      xhit_rowid                 rowid                                                  -- ROWID
    , invoice_no                 xxcoi_hht_inv_transactions.invoice_no%TYPE             -- �`�[No
    , transaction_id             xxcoi_hht_inv_transactions.transaction_id%TYPE         -- ���ɏ��ꎞ�\ID
    , base_code                  xxcoi_hht_inv_transactions.base_code%TYPE              -- ���_�R�[�h
    , record_type                xxcoi_hht_inv_transactions.record_type%TYPE            -- ���R�[�h���
    , employee_num               xxcoi_hht_inv_transactions.employee_num%TYPE           -- �c�ƈ��R�[�h
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE              -- �i�ڃR�[�h
    , case_in_quantity           xxcoi_hht_inv_transactions.case_in_quantity%TYPE       -- ����
    , case_quantity              xxcoi_hht_inv_transactions.case_quantity%TYPE          -- �P�[�X��
    , quantity                   xxcoi_hht_inv_transactions.quantity%TYPE               -- �{��
    , total_quantity             xxcoi_hht_inv_transactions.total_quantity%TYPE         -- ���{��
    , inventory_item_id          xxcoi_hht_inv_transactions.inventory_item_id%TYPE      -- �i��ID
    , primary_uom_code           xxcoi_hht_inv_transactions.primary_uom_code%TYPE       -- ��P��
    , invoice_date               xxcoi_hht_inv_transactions.invoice_date%TYPE           -- �`�[���t
    , invoice_type               xxcoi_hht_inv_transactions.invoice_type%TYPE           -- �`�[�敪
    , department_flag            xxcoi_hht_inv_transactions.department_flag%TYPE        -- �S�ݓX�t���O
    , column_no                  xxcoi_hht_inv_transactions.column_no%TYPE              -- �R����No
    , outside_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE    -- �o�ɑ��ۊǏꏊ
    , inside_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE     -- ���ɑ��ۊǏꏊ
    , outside_code               xxcoi_hht_inv_transactions.outside_code%TYPE           -- �o�ɑ��R�[�h
    , inside_code                xxcoi_hht_inv_transactions.inside_code%TYPE            -- ���ɑ��R�[�h
    , outside_base_code          xxcoi_hht_inv_transactions.outside_base_code%TYPE      -- �o�ɑ����_�R�[�h
    , inside_base_code           xxcoi_hht_inv_transactions.inside_base_code%TYPE       -- ���ɑ����_�R�[�h
    , stock_uncheck_list_div     xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE -- ���ɖ��m�F���X�g�Ώۋ敪
    -- 2015/04/27 Ver1.2 Add Start
    , interface_date             xxcoi_hht_inv_transactions.interface_date%TYPE         -- ��M����
    -- 2015/04/27 Ver1.2 Add End
  );
--
  TYPE gt_kuragae_data_ttype IS TABLE OF gr_kuragae_data_rec INDEX BY BINARY_INTEGER;
--
  -- ���ɏ��ꎞ�\�f�[�^���R�[�h�i�[�p
  TYPE gr_storage_info_rec IS RECORD(
      xsi_rowid                  rowid                                            -- ROWID
    , ship_case_qty              xxcoi_storage_information.ship_case_qty%TYPE     -- �o�ɐ��ʃP�[�X��
    , ship_singly_qty            xxcoi_storage_information.ship_singly_qty%TYPE   -- �o�ɐ��ʃo����
    , ship_summary_qty           xxcoi_storage_information.ship_summary_qty%TYPE  -- �o�ɐ��ʑ��o����
    , check_case_qty             xxcoi_storage_information.check_case_qty%TYPE    -- �m�F���ʃP�[�X��
    , check_singly_qty           xxcoi_storage_information.check_singly_qty%TYPE  -- �m�F���ʃo����
    , check_summary_qty          xxcoi_storage_information.check_summary_qty%TYPE -- �m�F���ʑ��o����
  );
--
  TYPE gt_storage_info_ttype IS TABLE OF gr_storage_info_rec INDEX BY BINARY_INTEGER;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_org_id                      mtl_parameters.organization_id%TYPE;                 -- �݌ɑg�DID
  gt_data_name                   fnd_profile_option_values.profile_option_value%TYPE; -- HHT�G���[���X�g���o�Ƀf�[�^����
  gt_tran_type_kuragae           mtl_transaction_types.transaction_type_id%TYPE;      -- ����^�C�vID �q��
  gt_tran_type_inout             mtl_transaction_types.transaction_type_id%TYPE;      -- ����^�C�vID ���o��
  gv_skip_flag                   VARCHAR2(1);                                         -- �X�L�b�v�p�t���O
  gv_auto_flag                   VARCHAR2(1);                                         -- �������Ɋm�F�t���O
  -- �J�E���^
  gn_kuragae_data_loop_cnt       NUMBER; -- �q�փf�[�^���[�v�J�E���^
  gn_storage_info_loop_cnt       NUMBER; -- ���ɏ��ꎞ�\�f�[�^���[�v�J�E���^
  gn_storage_info_cnt            NUMBER; -- ���ɏ��ꎞ�\�����J�E���^
  -- PL/SQL�\
  gt_kuragae_data_tab            gt_kuragae_data_ttype;
  gt_storage_info_tab            gt_storage_info_ttype;
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
    -- �v���t�@�C��
    cv_prf_org_code              CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE'; -- �݌ɑg�D�R�[�h
    cv_prf_data_name             CONSTANT VARCHAR2(30) := 'XXCOI1_HHT_ERR_DATA_NAME'; -- HHT�G���[���X�g�p���o�Ƀf�[�^��
    -- �Q�ƃ^�C�v
    cv_tran_type                 CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME'; -- ���[�U�[��`����^�C�v����
    -- �Q�ƃR�[�h
    cv_tran_type_kuragae         CONSTANT VARCHAR2(2)  := '20'; -- ����^�C�v �R�[�h �q��
    cv_tran_type_inout           CONSTANT VARCHAR2(2)  := '10'; -- ����^�C�v �R�[�h ���o��
--
    -- *** ���[�J���ϐ� ***
    lt_org_code                  mtl_parameters.organization_code%TYPE;            -- �݌ɑg�D�R�[�h
    lt_tran_type_kuragae         mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� �q��
    lt_tran_type_inout           mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� ���o��
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
    -- �v���t�@�C���擾�FHHT�G���[���X�g���o�Ƀf�[�^����
    -- ===============================
    gt_data_name := fnd_profile.value( cv_prf_data_name );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_data_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_data_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_data_name
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
   * Procedure Name   : get_kuragae_data
   * Description      : �q�փf�[�^���o���� (A-2)
   ***********************************************************************************/
  PROCEDURE get_kuragae_data(
    ov_errbuf     OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_kuragae_data'; -- �v���O������
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
    cv_hht_program_div_2         CONSTANT VARCHAR2(1) := '2'; -- ���o�ɃW���[�i�������敪 2:���_�ԑq��
    cv_status_pre                CONSTANT NUMBER      := 0;   -- �����X�e�[�^�X 0:������
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �q�փf�[�^���o
    CURSOR get_data_cur
    IS
      SELECT
             xhit.rowid                  AS xhit_rowid             -- ROWID
           , xhit.invoice_no             AS invoice_no             -- �`�[No
           , xhit.transaction_id         AS transaction_id         -- ���ɏ��ꎞ�\ID
           , xhit.base_code              AS base_code              -- ���_�R�[�h
           , xhit.record_type            AS record_type            -- ���R�[�h���
           , xhit.employee_num           AS employee_num           -- �c�ƈ��R�[�h
           , xhit.item_code              AS item_code              -- �i�ڃR�[�h
           , xhit.case_in_quantity       AS case_in_quantity       -- ����
           , xhit.case_quantity          AS case_quantity          -- �P�[�X��
           , xhit.quantity               AS quantity               -- �{��
           , xhit.total_quantity         AS total_quantity         -- ���{��
           , xhit.inventory_item_id      AS inventory_item_id      -- �i��ID
           , xhit.primary_uom_code       AS primary_uom_code       -- ��P��
           , xhit.invoice_date           AS invoice_date           -- �`�[���t
           , xhit.invoice_type           AS invoice_type           -- �`�[�敪
           , xhit.department_flag        AS department_flag        -- �S�ݓX�t���O
           , xhit.column_no              AS column_no              -- �R����No
           , xhit.outside_subinv_code    AS outside_subinv_code    -- �o�ɑ��ۊǏꏊ
           , xhit.inside_subinv_code     AS inside_subinv_code     -- ���ɑ��ۊǏꏊ
           , xhit.outside_code           AS outside_code           -- �o�ɑ��R�[�h
           , xhit.inside_code            AS inside_code            -- ���ɑ��R�[�h
           , xhit.outside_base_code      AS outside_base_code      -- �o�ɑ����_�R�[�h
           , xhit.inside_base_code       AS inside_base_code       -- ���ɑ����_�R�[�h
           , xhit.stock_uncheck_list_div AS stock_uncheck_list_div -- ���ɖ��m�F���X�g�Ώۋ敪
           -- 2015/04/27 Ver1.2 Add Start
           , xhit.interface_date         AS interface_date         -- ��M����
           -- 2015/04/27 Ver1.2 Add End
      FROM   xxcoi_hht_inv_transactions  xhit                      -- HHT���o�Ɉꎞ�\
      WHERE  xhit.status          = cv_status_pre                  -- �����X�e�[�^�X
      AND    xhit.hht_program_div = cv_hht_program_div_2           -- ���o�ɃW���[�i�������敪
      ORDER BY 
             xhit.inside_code                                      -- �ڋq�R�[�h
           , xhit.invoice_no                                       -- �`�[No
      FOR UPDATE OF xhit.status NOWAIT
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
    OPEN get_data_cur;
--
    -- ���R�[�h�ǂݍ���
    FETCH get_data_cur BULK COLLECT INTO gt_kuragae_data_tab;
--
    -- �Ώی����擾
    gn_target_cnt := gt_kuragae_data_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_data_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( get_data_cur%ISOPEN ) THEN
        CLOSE get_data_cur;
      END IF;
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_hht_table_lock_err_msg
                     );
      lv_errbuf   := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( get_data_cur%ISOPEN ) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( get_data_cur%ISOPEN ) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( get_data_cur%ISOPEN ) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_kuragae_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_kuragae_data
   * Description      : �q�փf�[�^�Ó����`�F�b�N���� (A-3)
   ***********************************************************************************/
  PROCEDURE chk_kuragae_data(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- �q�փf�[�^���[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_kuragae_data'; -- �v���O������
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
    cv_customer_class_code       CONSTANT VARCHAR2(1) := '1'; -- �ڋq�敪 1:���_
    cv_kuragae_div               CONSTANT VARCHAR2(1) := '0'; -- �q�֑Ώۉۋ敪   0:�q�֑Ώ۔ۋ��_
    cv_auto_flag_off             CONSTANT VARCHAR2(1) := 'N'; -- �������Ɋm�F�t���O N:�������Ɋm�F�ΏۊO
--
    -- *** ���[�J���ϐ� ***
    lt_outside_attribute6        hz_cust_accounts.attribute6%TYPE; -- �q�֑Ώۉۋ敪�i�o�ɑ����_�R�[�h�j
    lt_inside_attribute6         hz_cust_accounts.attribute6%TYPE; -- �q�֑Ώۉۋ敪�i���ɑ����_�R�[�h�j
    lb_chk_result                BOOLEAN;                          -- �݌ɉ�v���ԃI�[�v������
    lv_key_info                  VARCHAR2(5000);                   -- �ۊǏꏊ�]������f�[�^OIF�X�V�i�q�֏��j�pKEY���
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
    -- �ϐ�������
    lt_outside_attribute6 := NULL;
    lt_inside_attribute6  := NULL;
    gv_auto_flag          := NULL;
    lb_chk_result         := TRUE;
--
    -- �o�ɑ����_�R�[�h�Ɠ��ɑ����_�R�[�h���s��v�̏ꍇ�A�q�ւƔ��f���Ó����`�F�b�N
    IF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code
      <> gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code ) THEN
--
      SELECT hca.attribute6 AS attribute6                                                                -- �q�֑Ώۉۋ敪
      INTO   lt_outside_attribute6
      FROM   hz_cust_accounts hca                                                                        -- �ڋq�A�J�E���g
      WHERE  hca.account_number      = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code -- �ڋq�R�[�h = �o�ɑ����_�R�[�h
      AND    hca.customer_class_code = cv_customer_class_code                                            -- �ڋq�敪
      ;
--
      -- �i�o�ɑ����_�R�[�h���j�q�֑Ώ۔ۋ��_�ɐݒ肳��Ă���ꍇ
      IF ( lt_outside_attribute6 = cv_kuragae_div ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_dept_code_err_msg
                       , iv_token_name1  => cv_tkn_dept_code
                       , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code
                     );
        lv_errbuf := lv_errmsg;
        RAISE outside_base_code_expt;
      END IF;
--
      SELECT hca.attribute6 AS attribute6                                                                -- �q�֑Ώۉۋ敪
      INTO   lt_inside_attribute6
      FROM   hz_cust_accounts hca                                                                        -- �ڋq�A�J�E���g
      WHERE  hca.account_number      = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code  -- �ڋq�R�[�h = ���ɑ����_�R�[�h
      AND    hca.customer_class_code = cv_customer_class_code                                            -- �ڋq�敪
      ;
--
      -- �i���ɑ����_�R�[�h���j�q�֑Ώ۔ۋ��_�ɐݒ肳��Ă���ꍇ
      IF ( lt_inside_attribute6 = cv_kuragae_div ) THEN
        lv_errmsg:= xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_dept_code_err_msg
                      , iv_token_name1  => cv_tkn_dept_code
                      , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code
                    );
        lv_errbuf := lv_errmsg;
        RAISE inside_base_code_expt;
      END IF;
--
    END IF;
--
    -- �������Ɋm�F�t���O�̊m�F
    SELECT NVL( msi.attribute11, cv_auto_flag_off ) AS attribute11                                           -- �������Ɋm�F�t���O
    INTO   gv_auto_flag
    FROM   mtl_secondary_inventories msi                                                                     -- �ۊǏꏊ�}�X�^
    WHERE  msi.secondary_inventory_name = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code -- �ۊǏꏊ�R�[�h = ���ɑ��ۊǏꏊ
    AND    msi.organization_id          = gt_org_id                                                          -- �݌ɑg�DID
    ;
--
    -- �݌ɉ�v���ԃ`�F�b�N
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                                    -- �݌ɑg�DID
      , id_target_date     => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date -- �Ώۓ�
      , ob_chk_result      => lb_chk_result                                                -- �`�F�b�N����
      , ov_errbuf          => lv_errbuf                                                    -- �G���[���b�Z�[�W
      , ov_retcode         => lv_retcode                                                   -- ���^�[���E�R�[�h
      , ov_errmsg          => lv_errmsg                                                    -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    -- �߂�l�̃X�e�[�^�X��FALSE�̏ꍇ
    IF ( lb_chk_result = FALSE ) THEN
      lv_errmsg:= xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_acct_period_close_err_msg
                    , iv_token_name1  => cv_tkn_invoice_date
                    , iv_token_value1 => TO_CHAR( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date, 'YYYYMMDD' )
                  );
      lv_errbuf := lv_errmsg;
      RAISE acct_period_close_expt;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- �q�֑ΏۉۃG���[�i�o�ɑ����_�R�[�h�j
    WHEN outside_base_code_expt THEN
      -- KEY���o��
      lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
                     );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_key_info || lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_key_info || lv_errbuf
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- �q�֑ΏۉۃG���[�i���ɑ����_�R�[�h�j
    WHEN inside_base_code_expt THEN
      -- KEY���o��
      lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
                     );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_key_info || lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_key_info || lv_errbuf
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- �݌ɉ�v���ԃG���[
    WHEN acct_period_close_expt THEN
      -- KEY���o��
      lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
                     );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_key_info || lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_key_info || lv_errbuf
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
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
  END chk_kuragae_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_ins_upd
   * Description      : �ǉ��^�X�V���菈�� (A-4)
   ***********************************************************************************/
  PROCEDURE chk_ins_upd(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- �q�փf�[�^���[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_ins_upd'; -- �v���O������
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
    cv_department_flag_5         CONSTANT VARCHAR2(2) := '5'; -- �S�ݓX�t���O 5
--
    -- *** ���[�J���ϐ� ***
    lv_key_info                  VARCHAR2(5000);              -- �ۊǏꏊ�]������f�[�^OIF�X�V�i�q�֏��j�pKEY���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ɏ��ꎞ�\�f�[�^���o
    CURSOR chk_ins_upd_cur
    IS
      SELECT
             xsi.rowid                 AS xsi_rowid                                                  -- ROWID
           , xsi.ship_case_qty         AS ship_case_qty                                              -- �o�ɐ��ʃP�[�X��
           , xsi.ship_singly_qty       AS ship_singly_qty                                            -- �o�ɐ��ʃo����
           , xsi.ship_summary_qty      AS ship_summary_qty                                           -- �o�ɐ��ʑ��o����
           , xsi.check_case_qty        AS check_case_qty                                             -- �m�F���ʃP�[�X��
           , xsi.check_singly_qty      AS check_singly_qty                                           -- �m�F���ʃo����
           , xsi.check_summary_qty     AS check_summary_qty                                          -- �m�F���ʑ��o����
      FROM   xxcoi_storage_information xsi                                                           -- ���ɏ��ꎞ�\
      WHERE
             xsi.slip_num         = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no       -- �`�[No
      AND    xsi.slip_date        = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date     -- �`�[���t
      AND    xsi.ship_base_code   = CASE WHEN ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).department_flag = cv_department_flag_5 )
                                         THEN gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_code
                                         ELSE gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code
                                         END                                                         -- �o�ɑ����_�R�[�h
      AND    xsi.base_code        = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code -- ���_�R�[�h
      AND    xsi.parent_item_code = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code        -- �e�i�ڃR�[�h
      AND    xsi.slip_type        = cv_slip_type                                                     -- �`�[�敪
      FOR UPDATE OF xsi.slip_num NOWAIT
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
    -- ���ɏ��ꎞ�\�����J�E���^������
    gn_storage_info_cnt := 0;
--
    -- �J�[�\���I�[�v��
    OPEN chk_ins_upd_cur;
--
    -- ���R�[�h�ǂݍ���
    FETCH chk_ins_upd_cur BULK COLLECT INTO gt_storage_info_tab;
--
    -- ���ɏ��ꎞ�\�����J�E���g�Z�b�g
    gn_storage_info_cnt := gt_storage_info_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE chk_ins_upd_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( chk_ins_upd_cur%ISOPEN ) THEN
        CLOSE chk_ins_upd_cur;
      END IF;
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_info_table_lock_err_msg
                     );
      -- KEY���o��
      lv_errbuf   := lv_errmsg;
      lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
                     );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_key_info || CHR(10) || lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_key_info || CHR(10) || lv_errbuf
      );
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( chk_ins_upd_cur%ISOPEN ) THEN
        CLOSE chk_ins_upd_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( chk_ins_upd_cur%ISOPEN ) THEN
        CLOSE chk_ins_upd_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( chk_ins_upd_cur%ISOPEN ) THEN
        CLOSE chk_ins_upd_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_ins_upd;
--
  /**********************************************************************************
   * Procedure Name   : ins_storage_info_tab
   * Description      : ���ɏ��ꎞ�\�ǉ����� (A-5)
   ***********************************************************************************/
  PROCEDURE ins_storage_info_tab(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- �q�փf�[�^���[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_storage_info_tab'; -- �v���O������
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
    cv_zero                      CONSTANT VARCHAR2(1) := '0';  -- �Œ�l
--
    -- *** ���[�J���ϐ� ***
    -- 2015/04/27 Ver1.2 Add Start
    ln_cnt                NUMBER;
    lt_wh_flg             mtl_secondary_inventories.attribute14%TYPE;          -- �q�ɊǗ��Ώۋ敪
    ln_lot_tran_temp_id   xxcoi_lot_transactions_temp.transaction_id%TYPE;     -- ���b�g�ʎ��TEMPID
    ln_storage_info_id    xxcoi_storage_information.transaction_id%TYPE;       -- ���ɏ��ꎞ�\ID
    -- 2015/04/27 Ver1.2 Add End
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
    -- �o�ɑ����̏ꍇ�̓��ɏ��ꎞ�\�o�^
    IF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).stock_uncheck_list_div = cv_stock_uncheck_list_div_out ) THEN
      -- 2015/04/27 Ver1.2 Add Start
      -- �����ɓo�^����Ă���A�u�q�Ɂ��c�Ǝԁv�A�u�c�Ǝԁ��q�Ɂv������
      ln_cnt := 0;
      --
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   xxcoi_hht_inv_transactions   xhit
      WHERE  ((xhit.invoice_type   =  '1'
        AND    xhit.outside_subinv_code = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code)
        OR    (xhit.invoice_type   =  '2'
        AND    xhit.inside_subinv_code  = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code))
      AND    xhit.item_code      =  gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
      AND    xhit.case_quantity  =  gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity
      AND    xhit.quantity       =  gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity
      AND    xhit.invoice_date   =  gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date
      AND    xhit.interface_date =  gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).interface_date
      ;
      -- 2015/04/27 Ver1.2 Add End
--
      INSERT INTO xxcoi_storage_information(
          transaction_id                                                                       -- ���ID
        , base_code                                                                            -- ���ɋ��_�R�[�h
        , warehouse_code                                                                       -- �q�ɃR�[�h
        , slip_date                                                                            -- �`�[���t
        , slip_num                                                                             -- �`�[No
        , req_status                                                                           -- �o�Ɉ˗��X�e�[�^�X
        , parent_item_code                                                                     -- �e�i�ڃR�[�h
        , item_code                                                                            -- �q�i�ڃR�[�h
        , case_in_qty                                                                          -- ����
        , ship_case_qty                                                                        -- �o�ɐ��ʃP�[�X��
        , ship_singly_qty                                                                      -- �o�ɐ��ʃo����
        , ship_summary_qty                                                                     -- �o�ɐ��ʑ��o����
        , ship_warehouse_code                                                                  -- �]����q�ɃR�[�h
        , check_warehouse_code                                                                 -- �m�F�q�ɃR�[�h
        , check_case_qty                                                                       -- �m�F���ʃP�[�X��
        , check_singly_qty                                                                     -- �m�F���ʃo����
        , check_summary_qty                                                                    -- �m�F���ʑ��o����
        , material_transaction_unset_qty                                                       -- ���ގ�����A�g����
        , slip_type                                                                            -- �`�[�敪
        , ship_base_code                                                                       -- �o�ɋ��_�R�[�h
        , taste_term                                                                           -- �ܖ�����
        , difference_summary_code                                                              -- �H��ŗL�L��
        , summary_data_flag                                                                    -- �T�}���[�f�[�^�t���O
        , store_check_flag                                                                     -- ���Ɋm�F�t���O
        , material_transaction_set_flag                                                        -- ���ގ���A�g�σt���O
        , auto_store_check_flag                                                                -- �������Ɋm�F�t���O
        , created_by                                                                           -- �쐬��
        , creation_date                                                                        -- �쐬��
        , last_updated_by                                                                      -- �ŏI�X�V��
        , last_update_date                                                                     -- �ŏI�X�V��
        , last_update_login                                                                    -- �ŏI�X�V���O�C��
        , request_id                                                                           -- �v��ID
        , program_application_id                                                               -- �v���O�����A�v���P�[�V����ID
        , program_id                                                                           -- �v���O����ID
        , program_update_date                                                                  -- �v���O�����X�V��
      )
      VALUES(
          xxcoi_storage_information_s01.NEXTVAL                                                -- ���ID(�V�[�P���X)
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code                     -- ���ɋ��_�R�[�h
        , SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code, 6, 2 )  -- �q�ɃR�[�h
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date                         -- �`�[���t
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no                           -- �`�[No
        , NULL                                                                                 -- �o�Ɉ˗��X�e�[�^�X
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code                            -- �e�i�ڃR�[�h
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code                            -- �q�i�ڃR�[�h
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_in_quantity                     -- ����
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity                        -- �o�ɐ��ʃP�[�X��
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity                             -- �o�ɐ��ʃo����
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity                       -- �o�ɐ��ʑ��o����
        , NULL                                                                                 -- �]����q�ɃR�[�h
        , SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code, 6, 2 )  -- �m�F�q�ɃR�[�h
        , cv_zero                                                                              -- �m�F���ʃP�[�X��
        , cv_zero                                                                              -- �m�F���ʃo����
        , cv_zero                                                                              -- �m�F���ʑ��o����
        , cv_zero                                                                              -- ���ގ�����A�g����
        , cv_slip_type                                                                         -- �`�[�敪
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code                    -- �o�ɋ��_�R�[�h
        , NULL                                                                                 -- �ܖ�����
        , NULL                                                                                 -- �H��ŗL�L��
        , cv_flag_on                                                                           -- �T�}���[�f�[�^�t���O
        -- 2015/04/27 Ver1.2 Mod Start
--        , cv_flag_off                                                                          -- ���Ɋm�F�t���O
        , DECODE(ln_cnt
                ,0
                ,cv_flag_off
                ,cv_flag_on  )                                                                 -- ���Ɋm�F�t���O
        -- 2015/04/27 Ver1.2 Mod End
        , cv_flag_off                                                                          -- ���ގ���A�g�σt���O
        , gv_auto_flag                                                                         -- �������Ɋm�F�t���O
        , cn_created_by                                                                        -- �쐬��
        , cd_creation_date                                                                     -- �쐬��
        , cn_last_updated_by                                                                   -- �ŏI�X�V��
        , cd_last_update_date                                                                  -- �ŏI�X�V��
        , cn_last_update_login                                                                 -- �ŏI�X�V���O�C��
        , cn_request_id                                                                        -- �v��ID
        , cn_program_application_id                                                            -- �v���O�����A�v���P�[�V����ID
        , cn_program_id                                                                        -- �v���O����ID
        , cd_program_update_date                                                               -- �v���O�����X�V��
      -- 2015/04/27 Ver1.2 Mod Start
--      );
      )
      RETURNING transaction_id
      INTO      ln_storage_info_id;
      -- 2015/04/27 Ver1.2 Mod End
--
      -- 2015/04/27 Ver1.2 Add Start
      IF ln_cnt > 0 THEN
        BEGIN
          -- ���ɑ��q�ɂ̑q�ɊǗ��敪���擾
          SELECT msi.attribute14 AS wh_flg
          INTO   lt_wh_flg
          FROM   mtl_secondary_inventories   msi
          WHERE  msi.attribute1               IN ('1','4')
          AND    msi.attribute7               = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code
          AND    msi.secondary_inventory_name = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code
          AND    msi.organization_id          = gt_org_id
          AND    NVL(msi.disable_date,gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date+1)
                                              > gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lt_wh_flg := NULL;
        END;
--
        IF lt_wh_flg = cv_flag_on THEN
          -- ���ʊ֐��F���b�g�ʎ��TEMP�쐬 ���s
          xxcoi_common_pkg.cre_lot_trx_temp(
             in_trx_set_id       => NULL
            ,iv_parent_item_code => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
            ,iv_child_item_code  => NULL
            ,iv_lot              => NULL
            ,iv_diff_sum_code    => NULL
            ,iv_trx_type_code    => '20'
            ,id_trx_date         => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date
            ,iv_slip_num         => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no
            ,in_case_in_qty      => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_in_quantity
            ,in_case_qty         => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity
            ,in_singly_qty       => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity
            ,in_summary_qty      => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity
            ,iv_base_code        => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code
            ,iv_subinv_code      => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code
            ,iv_tran_subinv_code => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code
            ,iv_tran_loc_code    => NULL
            ,iv_inout_code       => '21'
            ,iv_source_code      => cv_pkg_name
            ,iv_relation_key     => ln_storage_info_id
            ,on_trx_id           => ln_lot_tran_temp_id
            ,ov_errbuf           => lv_errbuf
            ,ov_retcode          => lv_retcode
            ,ov_errmsg           => lv_errmsg
            );
--
          -- ���ʊ֐��ُ�I����
          IF ( lv_retcode <> cv_status_normal ) THEN
            -- �G���[���b�Z�[�W�̎擾
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application_short_name
                          ,iv_name         => cv_lot_tran_temp_cre_error
                          ,iv_token_name1  => cv_tkn_name_err_msg
                          ,iv_token_value1 => lv_errbuf
                          );
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
      -- 2015/04/27 Ver1.2 Add End
    -- �S�ݓXHHT���ɑ����̏ꍇ�̓��ɏ��ꎞ�\�o�^
    ELSIF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).stock_uncheck_list_div = cv_stock_uncheck_list_div_in ) THEN
--
      INSERT INTO xxcoi_storage_information(
          transaction_id                                                                       -- ���ID
        , base_code                                                                            -- ���ɋ��_�R�[�h
        , warehouse_code                                                                       -- �q�ɃR�[�h
        , slip_date                                                                            -- �`�[���t
        , slip_num                                                                             -- �`�[No
        , req_status                                                                           -- �o�Ɉ˗��X�e�[�^�X
        , parent_item_code                                                                     -- �e�i�ڃR�[�h
        , item_code                                                                            -- �q�i�ڃR�[�h
        , case_in_qty                                                                          -- ����
        , ship_case_qty                                                                        -- �o�ɐ��ʃP�[�X��
        , ship_singly_qty                                                                      -- �o�ɐ��ʃo����
        , ship_summary_qty                                                                     -- �o�ɐ��ʑ��o����
        , ship_warehouse_code                                                                  -- �]����q�ɃR�[�h
        , check_warehouse_code                                                                 -- �m�F�q�ɃR�[�h
        , check_case_qty                                                                       -- �m�F���ʃP�[�X��
        , check_singly_qty                                                                     -- �m�F���ʃo����
        , check_summary_qty                                                                    -- �m�F���ʑ��o����
        , material_transaction_unset_qty                                                       -- ���ގ�����A�g����
        , slip_type                                                                            -- �`�[�敪
        , ship_base_code                                                                       -- �o�ɋ��_�R�[�h
        , taste_term                                                                           -- �ܖ�����
        , difference_summary_code                                                              -- �H��ŗL�L��
        , summary_data_flag                                                                    -- �T�}���[�f�[�^�t���O
        , store_check_flag                                                                     -- ���Ɋm�F�t���O
        , material_transaction_set_flag                                                        -- ���ގ���A�g�σt���O
        , auto_store_check_flag                                                                -- �������Ɋm�F�t���O
        , created_by                                                                           -- �쐬��
        , creation_date                                                                        -- �쐬��
        , last_updated_by                                                                      -- �ŏI�X�V��
        , last_update_date                                                                     -- �ŏI�X�V��
        , last_update_login                                                                    -- �ŏI�X�V���O�C��
        , request_id                                                                           -- �v��ID
        , program_application_id                                                               -- �v���O�����A�v���P�[�V����ID
        , program_id                                                                           -- �v���O����ID
        , program_update_date                                                                  -- �v���O�����X�V��
      )
      VALUES(
          xxcoi_storage_information_s01.NEXTVAL                                                -- ���ID(�V�[�P���X)
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code                     -- ���ɋ��_�R�[�h
        , SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code, 6, 2 ) -- �q�ɃR�[�h
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date                         -- �`�[���t
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no                           -- �`�[No
        , NULL                                                                                 -- �o�Ɉ˗��X�e�[�^�X
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code                            -- �e�i�ڃR�[�h
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code                            -- �q�i�ڃR�[�h
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_in_quantity                     -- ����
        , cv_zero                                                                              -- �o�ɐ��ʃP�[�X��
        , cv_zero                                                                              -- �o�ɐ��ʃo����
        , cv_zero                                                                              -- �o�ɐ��ʑ��o����
        , SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code, 6, 5 )  -- �]����q�ɃR�[�h
        , SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code, 6, 2 ) -- �m�F�q�ɃR�[�h
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity                        -- �m�F���ʃP�[�X��
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity                             -- �m�F���ʃo����
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity                       -- �m�F���ʑ��o����
        , cv_zero                                                                              -- ���ގ�����A�g����
        , cv_slip_type                                                                         -- �`�[�敪
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_code                         -- �o�ɋ��_�R�[�h
        , NULL                                                                                 -- �ܖ�����
        , NULL                                                                                 -- �H��ŗL�L��
        , cv_flag_on                                                                           -- �T�}���[�f�[�^�t���O
        , cv_flag_on                                                                           -- ���Ɋm�F�t���O
        , cv_flag_off                                                                          -- ���ގ���A�g�σt���O
        , gv_auto_flag                                                                         -- �������Ɋm�F�t���O
        , cn_created_by                                                                        -- �쐬��
        , cd_creation_date                                                                     -- �쐬��
        , cn_last_updated_by                                                                   -- �ŏI�X�V��
        , cd_last_update_date                                                                  -- �ŏI�X�V��
        , cn_last_update_login                                                                 -- �ŏI�X�V���O�C��
        , cn_request_id                                                                        -- �v��ID
        , cn_program_application_id                                                            -- �v���O�����A�v���P�[�V����ID
        , cn_program_id                                                                        -- �v���O����ID
        , cd_program_update_date                                                               -- �v���O�����X�V��
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
  END ins_storage_info_tab;
--
  /**********************************************************************************
   * Procedure Name   : upd_storage_info_tab
   * Description      : ���ɏ��ꎞ�\�X�V���� (A-6)
   ***********************************************************************************/
  PROCEDURE upd_storage_info_tab(
    gn_storage_info_loop_cnt IN   NUMBER,    -- ���ɏ��ꎞ�\�f�[�^���[�v�J�E���^
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- �q�փf�[�^���[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �o�ɑ����̏ꍇ�̓��ɏ��ꎞ�\�X�V
    IF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).stock_uncheck_list_div = cv_stock_uncheck_list_div_out ) THEN
--
      UPDATE xxcoi_storage_information  xsi                                                                   -- ���ɏ��ꎞ�\
      SET    xsi.ship_case_qty          = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_case_qty     -- �o�ɐ��ʃP�[�X�� = 
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity )   -- �o�ɐ��ʃP�[�X�� + �P�[�X��
           , xsi.ship_singly_qty        = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_singly_qty   -- �o�ɐ��ʃo����
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity )        -- �o�ɐ��ʃo����   + �{��
           , xsi.ship_summary_qty       = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_summary_qty  -- �o�ɐ��ʑ��o����
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity )  -- �o�ɐ��ʑ��o���� + ����
           , xsi.last_updated_by        = cn_last_updated_by                                                  -- �ŏI�X�V��
           , xsi.last_update_date       = cd_last_update_date                                                 -- �ŏI�X�V��
           , xsi.last_update_login      = cn_last_update_login                                                -- �ŏI�X�V���O�C��
           , xsi.request_id             = cn_request_id                                                       -- �v��ID
           , xsi.program_application_id = cn_program_application_id                                           -- �v���O�����A�v���P�[�V����ID
           , xsi.program_id             = cn_program_id                                                       -- �v���O����ID
           , xsi.program_update_date    = cd_program_update_date                                              -- �v���O�����X�V��
      WHERE  xsi.rowid                  = gt_storage_info_tab( gn_storage_info_loop_cnt ).xsi_rowid           -- ROWID
      ;
--
    -- �S�ݓXHHT���ɑ����̏ꍇ�̓��ɏ��ꎞ�\�X�V
    ELSIF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).stock_uncheck_list_div = cv_stock_uncheck_list_div_in ) THEN
--
      UPDATE xxcoi_storage_information  xsi                                                                   -- ���ɏ��ꎞ�\
      SET    xsi.check_case_qty         = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).check_case_qty    -- �m�F���ʃP�[�X�� = 
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity )   -- �m�F���ʃP�[�X�� + �P�[�X��
           , xsi.check_singly_qty       = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).check_singly_qty  -- �m�F���ʃo����
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity )        -- �m�F���ʃo����   + �{��
           , xsi.check_summary_qty      = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).check_summary_qty -- �m�F���ʑ��o����
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity )  -- �m�F���ʑ��o���� + ����
           , xsi.ship_warehouse_code    = SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code, 6, 5 )  -- �]����q�ɃR�[�h
           , xsi.store_check_flag       = cv_flag_on                                                          -- ���Ɋm�F�t���O
           , xsi.last_updated_by        = cn_last_updated_by                                                  -- �ŏI�X�V��
           , xsi.last_update_date       = cd_last_update_date                                                 -- �ŏI�X�V��
           , xsi.last_update_login      = cn_last_update_login                                                -- �ŏI�X�V���O�C��
           , xsi.request_id             = cn_request_id                                                       -- �v��ID
           , xsi.program_application_id = cn_program_application_id                                           -- �v���O�����A�v���P�[�V����ID
           , xsi.program_id             = cn_program_id                                                       -- �v���O����ID
           , xsi.program_update_date    = cd_program_update_date                                              -- �v���O�����X�V��
      WHERE  xsi.rowid                  = gt_storage_info_tab( gn_storage_info_loop_cnt ).xsi_rowid           -- ROWID
      ;
--
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
   * Procedure Name   : ins_kuragae_data
   * Description      : �q�փf�[�^�ǉ����� (A-7)
   ***********************************************************************************/
  PROCEDURE ins_kuragae_data(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- �q�փf�[�^���[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_kuragae_data'; -- �v���O������
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
    cv_process_flag              CONSTANT VARCHAR2(1) := '1';  -- �v���Z�X�t���O 1�F�����Ώ�
    cv_transaction_mode          CONSTANT VARCHAR2(1) := '3';  -- ������[�h     3�F�o�b�N�O���E���h
    cv_source_line_id            CONSTANT VARCHAR2(1) := '1';  -- �\�[�X���C��ID 1�F�Œ�
--
    -- *** ���[�J���ϐ� ***
    lt_subinventory_code         mtl_transactions_interface.subinventory_code%TYPE;     -- �ۊǏꏊ
    lt_transfer_subinventory     mtl_transactions_interface.transfer_subinventory%TYPE; -- �����ۊǏꏊ
    lt_transaction_type_id       mtl_transactions_interface.transaction_type_id%TYPE;   -- ����^�C�vID
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
    -- ���[�J���ϐ��̏�����
    lt_subinventory_code     := NULL;
    lt_transfer_subinventory := NULL;
    lt_transaction_type_id   := NULL;
--
    -- �����ʂ̕������ɂ��ۊǏꏊ�A�����ۊǏꏊ�̔���
    IF ( SIGN( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity ) = 1 ) THEN
      lt_subinventory_code     := gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code;
      lt_transfer_subinventory := gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code;
    ELSIF ( SIGN( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity ) = ( -1 ) ) THEN
      lt_subinventory_code     := gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code;
      lt_transfer_subinventory := gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code;
    END IF;
--
    -- ����^�C�vID�̔���i���_�������ꍇ�͓��o�ɁA�قȂ�ꍇ�͑q�ցj
    IF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code
      = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code ) THEN
       lt_transaction_type_id := gt_tran_type_inout;
    ELSE
       lt_transaction_type_id := gt_tran_type_kuragae;
    END IF;
--
    -- ���ގ��OIF�֓o�^
    INSERT INTO mtl_transactions_interface(
        process_flag                                                             -- �v���Z�X�t���O
      , transaction_mode                                                         -- ������[�h
      , source_code                                                              -- �\�[�X�R�[�h
      , source_header_id                                                         -- �\�[�X�w�b�_�[ID
      , source_line_id                                                           -- �\�[�X���C��ID
      , inventory_item_id                                                        -- �i��ID
      , organization_id                                                          -- �݌ɑg�DID
      , transaction_quantity                                                     -- �������
      , primary_quantity                                                         -- ��P�ʐ���
      , transaction_uom                                                          -- ����P��
      , transaction_date                                                         -- �����
      , subinventory_code                                                        -- �ۊǏꏊ�R�[�h
      , transaction_type_id                                                      -- ����^�C�vID
      , transfer_subinventory                                                    -- �����ۊǏꏊ�R�[�h
      , transfer_organization                                                    -- �����݌ɑg�DID
      , attribute1                                                               -- �`�[No
      , created_by                                                               -- �쐬��
      , creation_date                                                            -- �쐬��
      , last_updated_by                                                          -- �ŏI�X�V��
      , last_update_date                                                         -- �ŏI�X�V��
      , last_update_login                                                        -- �ŏI�X�V���O�C��
      , request_id                                                               -- �v��ID
      , program_application_id                                                   -- �v���O�����A�v���P�[�V����ID
      , program_id                                                               -- �v���O����ID
      , program_update_date                                                      -- �v���O�����X�V��
    )
    VALUES(
        cv_process_flag                                                          -- �v���Z�X�t���O
      , cv_transaction_mode                                                      -- ������[�h
      , cv_pkg_name                                                              -- �\�[�X�R�[�h
      , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).transaction_id           -- �\�[�X�w�b�_�[ID
      , cv_source_line_id                                                        -- �\�[�X���C��ID
      , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inventory_item_id        -- �i��ID
      , gt_org_id                                                                -- �݌ɑg�DID
      , ( SIGN( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity )
          * ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity ) ) -- �������
      , ( SIGN( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity )
          * ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity ) ) -- ��P�ʐ���
      , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).primary_uom_code         -- ����P��
      , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date             -- �����
      , lt_subinventory_code                                                     -- �ۊǏꏊ�R�[�h
      , lt_transaction_type_id                                                   -- ����^�C�vID
      , lt_transfer_subinventory                                                 -- �����ۊǏꏊ�R�[�h
      , gt_org_id                                                                -- �����݌ɑg�DID
      , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no               -- �`�[No
      , cn_created_by                                                            -- �쐬��
      , cd_creation_date                                                         -- �쐬��
      , cn_last_updated_by                                                       -- �ŏI�X�V��
      , cd_last_update_date                                                      -- �ŏI�X�V��
      , cn_last_update_login                                                     -- �ŏI�X�V���O�C��
      , cn_request_id                                                            -- �v��ID
      , cn_program_application_id                                                -- �v���O�����A�v���P�[�V����ID
      , cn_program_id                                                            -- �v���O����ID
      , cd_program_update_date                                                   -- �v���O�����X�V��
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
  END ins_kuragae_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_hht_inv_tab
   * Description      : HHT���o�Ɉꎞ�\�X�V���� (A-8)
   ***********************************************************************************/
  PROCEDURE upd_hht_inv_tab(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- �q�փf�[�^���[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_hht_inv_tab'; -- �v���O������
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
    -- HHT���o�Ɉꎞ�\�X�V
    UPDATE xxcoi_hht_inv_transactions xhit                                                          -- HHT���o�Ɉꎞ�\
    SET    xhit.status                 = cv_status_post                                             -- �����X�e�[�^�X
         , xhit.last_updated_by        = cn_last_updated_by                                         -- �ŏI�X�V��
         , xhit.last_update_date       = cd_last_update_date                                        -- �ŏI�X�V��
         , xhit.last_update_login      = cn_last_update_login                                       -- �ŏI�X�V���O�C��
         , xhit.request_id             = cn_request_id                                              -- �v��ID
         , xhit.program_application_id = cn_program_application_id                                  -- �v���O�����A�v���P�[�V����ID
         , xhit.program_id             = cn_program_id                                              -- �v���O����ID
         , xhit.program_update_date    = cd_program_update_date                                     -- �v���O�����X�V��
    WHERE  xhit.rowid                  = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).xhit_rowid -- ROWID
    ;
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
  END upd_hht_inv_tab;
--
  /**********************************************************************************
   * Procedure Name   : del_hht_inv_tab
   * Description      : HHT���o�Ɉꎞ�\�폜���� (A-10)
   ***********************************************************************************/
  PROCEDURE del_hht_inv_tab(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- �q�փf�[�^���[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_hht_inv_tab'; -- �v���O������
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
    -- HHT���o�Ɉꎞ�\�̍폜
    DELETE
    FROM   xxcoi_hht_inv_transactions xhit                                         -- HHT���o�Ɉꎞ�\
    WHERE  xhit.rowid = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).xhit_rowid -- ROWID
    ;
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
  END del_hht_inv_tab;
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
    gn_target_cnt := 0; -- �Ώی���
    gn_normal_cnt := 0; -- ��������
    gn_error_cnt  := 0; -- �G���[����
    gn_warn_cnt   := 0; -- �X�L�b�v����
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
    -- �q�փf�[�^���o���� (A-2)
    -- ===============================
    get_kuragae_data(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �q�փf�[�^�擾������0���̏ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
      -- �q�փf�[�^���[�v�J�n
      <<gt_kuragae_data_tab_loop>>
      FOR gn_kuragae_data_loop_cnt IN 1 .. gn_target_cnt LOOP
--
        -- �X�L�b�v�p�t���O�̏�����
        gv_skip_flag := cv_flag_off;
--
        -- ===============================
        -- �q�փf�[�^�Ó����`�F�b�N���� (A-3)
        -- ===============================
        chk_kuragae_data(
            gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- �q�փf�[�^���[�v�J�E���^
          , ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- ===============================
          -- �G���[���X�g�\�ǉ����� (A-9)
          -- ===============================
          xxcoi_common_pkg.add_hht_err_list_data(
              iv_base_code           => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).base_code    -- ���_�R�[�h
            , iv_origin_shipment     => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_code -- �o�ɑ��R�[�h
            , iv_data_name           => gt_data_name                                                 -- �f�[�^����
            , id_transaction_date    => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date -- �����
            , iv_entry_number        => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no   -- �`�[No
            , iv_party_num           => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_code  -- ���ɑ��R�[�h
            , iv_performance_by_code => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).employee_num -- �c�ƈ��R�[�h
            , iv_item_code           => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code    -- �i�ڃR�[�h
            , iv_error_message       => lv_errmsg                                                    -- �G���[���e
            , ov_errbuf              => lv_errbuf                                                    -- �G���[�E���b�Z�[�W
            , ov_retcode             => lv_retcode                                                   -- ���^�[���E�R�[�h
            , ov_errmsg              => lv_errmsg                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- HHT���o�Ɉꎞ�\�폜���� (A-10)
          -- ===============================
          del_hht_inv_tab(
              gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- �q�փf�[�^���[�v�J�E���^
            , ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �X�L�b�v�p�t���O
          gv_skip_flag := cv_flag_on;
          -- �G���[����
          gn_error_cnt := gn_error_cnt + 1;
--
        END IF;
--
        -- �X�L�b�v�p�t���O��OFF�̏ꍇ
        IF ( gv_skip_flag = cv_flag_off ) THEN
--
          -- ===============================
          -- �ǉ��^�X�V���菈�� (A-4)
          -- ===============================
          chk_ins_upd(
              gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- �q�փf�[�^���[�v�J�E���^
            , ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- �X�L�b�v�p�t���O
            gv_skip_flag := cv_flag_on;
            -- �X�L�b�v����
            gn_warn_cnt := gn_warn_cnt + 1;
          END IF;
--
        END IF;
--
        -- �X�L�b�v�p�t���O��OFF�̏ꍇ
        IF ( gv_skip_flag = cv_flag_off ) THEN
--
          -- ���ɏ��ꎞ�\�f�[�^���擾�ł��Ȃ������ꍇ
          IF ( gn_storage_info_cnt = 0 ) THEN
            -- ====================================
            -- ���ɏ��ꎞ�\�ǉ����� (A-5)
            -- ====================================
            ins_storage_info_tab(
                gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- �q�փf�[�^���[�v�J�E���^
              , ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
              , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
              , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          -- ���ɏ��ꎞ�\�f�[�^���擾�ł����ꍇ
          ELSE
--
            -- ���ɏ��ꎞ�\�f�[�^���[�v�J�n
            <<gt_storage_info_tab_loop>>
            FOR gn_storage_info_loop_cnt IN 1 .. gn_storage_info_cnt LOOP
--
              -- ====================================
              -- ���ɏ��ꎞ�\�X�V���� (A-6)
              -- ====================================
              upd_storage_info_tab(
                  gn_storage_info_loop_cnt => gn_storage_info_loop_cnt -- ���ɏ��ꎞ�\�f�[�^���[�v�J�E���^
                , gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- �q�փf�[�^���[�v�J�E���^
                , ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
                , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
                , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
--
            END LOOP gt_storage_info_tab_loop;
--
          END IF;
--
          -- ========================================================
          -- �q�փf�[�^�ǉ����� (A-7)
          -- ========================================================
          ins_kuragae_data(
              gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- �q�փf�[�^���[�v�J�E���^
            , ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ====================================
          -- HHT���o�Ɉꎞ�\�X�V���� (A-8)
          -- ====================================
          upd_hht_inv_tab(
              gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- �q�փf�[�^���[�v�J�E���^
            , ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ��������
          gn_normal_cnt := gn_normal_cnt + 1;
--
        END IF;
--
      END LOOP gt_kuragae_data_tab_loop;
--
  EXCEPTION
    -- �擾����0��
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                      ,iv_name         => cv_no_data_msg
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
--
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
    -- �I���X�e�[�^�X���u�G���[�v�ȊO���A�X�L�b�v�����܂��̓G���[������1���ȏ゠��ꍇ�A�I���X�e�[�^�X�u�x���v�ɂ���
    IF ( ( lv_retcode <> cv_status_error ) AND ( ( gn_warn_cnt > 0 ) OR ( gn_error_cnt > 0 ) ) ) THEN
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
END XXCOI003A13C;
/
