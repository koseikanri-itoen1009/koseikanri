create or replace
PACKAGE BODY XXCOI003A14C  
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A14C(body)
 * Description      : ���̑�����f�[�^OIF�X�V
 * MD.050           : ���̑�����f�[�^OIF�X�V�iHHT���o�Ƀf�[�^�j MD050_COI_003_A14 
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������                                 (A-1)
 *  chk_inout_kuragae_data ���o�ɁE�q�փf�[�^�Ó����`�F�b�N         (A-3)
 *  ins_inout_kuragae_data ���o�ɁE�q�փf�[�^�̎��ގ��OIF�ǉ�      (A-4)
 *  update_xhit_data       HHT���o�Ɉꎞ�\�̏����X�e�[�^�X�X�V      (A-5)(A-12)(A-21)
 *  del_xhit_data          HHT���o�Ɉꎞ�\�̃G���[���R�[�h�폜      (A-7)(A-14)(A-23)
 *  get_inout_kuragae_data ���o�ɁE�q�փf�[�^�擾                   (A-2)
 *  chk_svd_data           ����VD��[�f�[�^ �Ó����`�F�b�N          (A-10)
 *  ins_temp_svd_data      ����VD��[�f�[�^�̈ꎞ�\�ǉ�             (A-11)
 *  ins_oif_svd_data       ����VD��[�f�[�^�̎��ގ��OIF�ǉ�        (A-15)
 *  get_svd_data           ����VD��[�f�[�^�擾                     (A-9)
 *  chk_item_conv_data     ���i�U�փf�[�^�Ó����`�F�b�N             (A-18)
 *  ins_oif_item_conv_data ���i�U�փf�[�^�̎��ގ��OIF�ǉ�          (A-20)
 *  get_item_conv_data     ���i�U�փf�[�^�擾                       (A-17)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19   1.0   H.Nakajima        �V�K�쐬
 *  2009/11/24   1.1   N.Abe             [E_�{�ғ�_00025]��ʓ��͎�VD�R�����i�ڃ`�F�b�N�̉���
 *  2009/11/25   1.2   H.Sasaki          [E_�{�ғ�_00025]��ʓ��͎�VD�R�����i�ڃ`�F�b�N�̍폜
 *  2010/08/31   1.3   H.Sasaki          [E_�{�ғ�_04663]PT�Ή�
 *  2020/01/22   1.4   H.Sasaki          [E_�{�ғ�_16192]E_�{�ғ�_15992�ɔ����Ή�
 *                                       �������`�[�ΏۊO�i���i�U�ցA����VD�͏����j
 *  2020/02/07   1.5   Y.Sasaki          [E_�{�ғ�_16220]�o�Ɉ˗��A�b�v���[�h��Q�Ή�
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
  lock_expt                      EXCEPTION; -- ���b�N�擾�G���[
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(15)  := 'XXCOI003A14C';       -- �p�b�P�[�W��
  cv_appl_short_name              CONSTANT VARCHAR2(10)  := 'XXCCP';              -- �A�h�I���F���ʁEIF�̈�
  cv_application_short_name       CONSTANT VARCHAR2(10)  := 'XXCOI';              -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W
  cv_no_para_msg                  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90008';    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_org_code_get_err             CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';    -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_org_id_get_err               CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';    -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_hht_name_get_err             CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10027';    -- HHT�G���[���X�g���擾�G���[���b�Z�[�W
  cv_no_data_msg                  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';    -- �Ώۃf�[�^�������b�Z�[�W
  cv_msg_process_date_get_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011';    -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_tran_type_name_get_err_msg   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00022';    -- ����^�C�v���擾�G���[���b�Z�[�W
  cv_tran_type_id_get_err_msg     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00012';    -- ����^�C�vID�擾�G���[���b�Z�[�W
  cv_hht_table_lock_err_msg       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10055';    -- ���b�N�擾�G���[���b�Z�[�W�iHHT���o�Ɉꎞ�\�j
  cv_msg_org_acct_period_err      CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00026';    -- �݌ɉ�v���Ԏ擾�`�F�b�N�G���[
  cv_invoice_date_invalid_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10231';    -- �݌ɉ�v���ԃ`�F�b�N�G���[
  cv_key_info                     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10342';    -- HHT���o�Ƀf�[�^�pKEY���
  cv_dept_code_err_msg            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10052';    -- �q�֑ΏۉۃG���[���b�Z�[�W
  cv_inout_kuragae_start_msg      CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10248';    -- �������b�Z�[�W�i���o�ɁE�q�ցj
  cv_svd_start_msg                CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10249';    -- �������b�Z�[�W�i����VD��[�j
  cv_item_conv_msg                CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10250';    -- �������b�Z�[�W�i���i�U�ցj
  cv_inout_kuragae_no_data_msg    CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10245';    -- �Ώۃf�[�^�������b�Z�[�W�i���o�ɁE�q���j
  cv_svd_no_data_msg              CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10246';    -- �Ώۃf�[�^�������b�Z�[�W�i����VD��[�j
  cv_item_conv_no_data_msg        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10247';    -- �Ώۃf�[�^�������b�Z�[�W�i���i�U�ցj
  cv_column_no_is_null_err_msg    CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10025';    -- �K�{���ڃG���[�i�R�������j
  cv_up_is_null_err_mag           CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10026';    -- �K�{���ڃG���[�i�P���j
  cv_vd_item_err_msg              CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10348';    -- VD�R�����i�ڕs��v�G���[
  cv_vd_last_month_item_err_msg   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10349';    -- VD�R�����O�����i�ڕs��v�G���[
  cv_get_disposition_id_err_msg   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10351';    -- ����Ȗڕʖ�ID�擾�G���[
  cv_oif_ins_cnt_msg              CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10335';    -- ����쐬�������b�Z�[�W
  cv_end_msg                      CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10352';    -- ���̑����OIF�X�V�iHHT���o�Ƀf�[�^�j�����������b�Z�[�W
  -- �g�[�N�� 
  cv_tkn_pro                      CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- TKN�F�v���t�@�C����
  cv_tkn_org_code                 CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- TKN�F�݌ɑg�D�R�[�h
  cv_tkn_tran_type                CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- TKN�F����^�C�v��
  cv_tkn_lookup_type              CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';          -- TKN�F�Q�ƃ^�C�v
  cv_tkn_lookup_code              CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';          -- TKN�F�Q�ƃR�[�h
  cv_tkn_proc_date                CONSTANT VARCHAR2(20)  := 'INVOICE_DATE';         -- TKN�F�`�[���t
  cv_tkn_target_date              CONSTANT VARCHAR2(20)  := 'TARGET_DATE';          -- TKN�F�Ώۓ�
  cv_tkn_record_type              CONSTANT VARCHAR2(20)  := 'RECORD_TYPE';          -- TKN�Fں��ގ��
  cv_tkn_invoice_type             CONSTANT VARCHAR2(20)  := 'INVOICE_TYPE';         -- TKN�F�`�[�敪
  cv_tkn_dept_flag                CONSTANT VARCHAR2(20)  := 'DEPT_FLAG';            -- TKN�F�S�ݓX�׸�
  cv_tkn_base_code                CONSTANT VARCHAR2(20)  := 'BASE_CODE';            -- TKN�F���_����
  cv_tkn_column_no                CONSTANT VARCHAR2(20)  := 'COLUMN_NO';            -- TKN�F�R������
  cv_tkn_invoice_no               CONSTANT VARCHAR2(20)  := 'INVOICE_NO';           -- TKN�F�`�[�ԍ�
  cv_tkn_item_code                CONSTANT VARCHAR2(20)  := 'ITEM_CODE';            -- TKN�F�i�ں���
  cv_tkn_dept_code                CONSTANT VARCHAR2(20)  := 'DEPT_CODE';            -- TKN�F���_�R�[�h
  cv_tkn_acct_type                CONSTANT VARCHAR2(20)  := 'INV_ACCOUNT_TYPE';     -- TKN�F���o�Ɋ���敪
  --
  cv_flag_y                       CONSTANT VARCHAR2(1)  := 'Y';                     -- �t���O�FY
  cv_flag_n                       CONSTANT VARCHAR2(1)  := 'N';                     -- �t���O�FN
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �q�փf�[�^���R�[�h�i�[�p
  TYPE gr_inout_kuragae_data_rec IS RECORD(
      xhit_rowid                 rowid                                                  -- ROWID
    , invoice_no                 xxcoi_hht_inv_transactions.invoice_no%TYPE             -- �`�[No
    , transaction_id             xxcoi_hht_inv_transactions.transaction_id%TYPE         -- ���ɏ��ꎞ�\ID
    , record_type                xxcoi_hht_inv_transactions.record_type%TYPE            -- ���R�[�h���
    , invoice_type               xxcoi_hht_inv_transactions.invoice_type%TYPE           -- �`�[�敪
    , department_flag            xxcoi_hht_inv_transactions.department_flag%TYPE        -- �S�ݓX�t���O
    , column_no                  xxcoi_hht_inv_transactions.column_no%TYPE              -- �R������  
    , base_code                  xxcoi_hht_inv_transactions.base_code%TYPE              -- ���_�R�[�h
    , employee_num               xxcoi_hht_inv_transactions.employee_num%TYPE           -- �c�ƈ��R�[�h
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE              -- �i�ڃR�[�h
    , case_in_quantity           xxcoi_hht_inv_transactions.case_in_quantity%TYPE       -- ����
    , case_quantity              xxcoi_hht_inv_transactions.case_quantity%TYPE          -- �P�[�X��
    , quantity                   xxcoi_hht_inv_transactions.quantity%TYPE               -- �{��
    , total_quantity             xxcoi_hht_inv_transactions.total_quantity%TYPE         -- ������
    , inventory_item_id          xxcoi_hht_inv_transactions.inventory_item_id%TYPE      -- �i��ID
    , primary_uom_code           xxcoi_hht_inv_transactions.primary_uom_code%TYPE       -- ��P��
    , invoice_date               xxcoi_hht_inv_transactions.invoice_date%TYPE           -- �`�[���t
    , outside_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE    -- �o�ɑ��ۊǏꏊ
    , inside_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE     -- ���ɑ��ۊǏꏊ
    , outside_code               xxcoi_hht_inv_transactions.outside_code%TYPE           -- �o�ɑ��R�[�h
    , inside_code                xxcoi_hht_inv_transactions.inside_code%TYPE            -- ���ɑ��R�[�h
    , outside_base_code          xxcoi_hht_inv_transactions.outside_base_code%TYPE      -- �o�ɑ����_�R�[�h
    , inside_base_code           xxcoi_hht_inv_transactions.inside_base_code%TYPE       -- ���ɑ����_�R�[�h
  );
  TYPE gt_inout_kuragae_data_ttype IS TABLE OF gr_inout_kuragae_data_rec INDEX BY BINARY_INTEGER;
  -- ����VD��[�f�[�^���R�[�h�i�[�p
  TYPE gr_svd_data_rec IS RECORD(
      xhit_rowid                 rowid                                                      -- ROWID
    , invoice_no                 xxcoi_hht_inv_transactions.invoice_no%TYPE                 -- �`�[No
    , transaction_id             xxcoi_hht_inv_transactions.transaction_id%TYPE             -- ���ɏ��ꎞ�\ID
    , record_type                xxcoi_hht_inv_transactions.record_type%TYPE                -- ���R�[�h���
    , invoice_type               xxcoi_hht_inv_transactions.invoice_type%TYPE               -- �`�[�敪
    , department_flag            xxcoi_hht_inv_transactions.department_flag%TYPE            -- �S�ݓX�t���O
    , column_no                  xxcoi_hht_inv_transactions.column_no%TYPE                  -- �R������  
    , unit_price                 xxcoi_hht_inv_transactions.unit_price%TYPE                 -- �P��
    , base_code                  xxcoi_hht_inv_transactions.base_code%TYPE                  -- ���_�R�[�h
    , employee_num               xxcoi_hht_inv_transactions.employee_num%TYPE               -- �c�ƈ��R�[�h
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE                  -- �i�ڃR�[�h
    , case_in_quantity           xxcoi_hht_inv_transactions.case_in_quantity%TYPE           -- ����
    , case_quantity              xxcoi_hht_inv_transactions.case_quantity%TYPE              -- �P�[�X��
    , quantity                   xxcoi_hht_inv_transactions.quantity%TYPE                   -- �{��
    , total_quantity             xxcoi_hht_inv_transactions.total_quantity%TYPE             -- ������
    , inventory_item_id          xxcoi_hht_inv_transactions.inventory_item_id%TYPE          -- �i��ID
    , primary_uom_code           xxcoi_hht_inv_transactions.primary_uom_code%TYPE           -- ��P��
    , invoice_date               xxcoi_hht_inv_transactions.invoice_date%TYPE               -- �`�[���t
    , outside_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE        -- �o�ɑ��ۊǏꏊ
    , inside_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE         -- ���ɑ��ۊǏꏊ
    , outside_code               xxcoi_hht_inv_transactions.outside_code%TYPE               -- �o�ɑ��R�[�h
    , inside_code                xxcoi_hht_inv_transactions.inside_code%TYPE                -- ���ɑ��R�[�h
    , outside_base_code          xxcoi_hht_inv_transactions.outside_base_code%TYPE          -- �o�ɑ����_�R�[�h
    , inside_base_code           xxcoi_hht_inv_transactions.inside_base_code%TYPE           -- ���ɑ����_�R�[�h
    , outside_business_low_type  xxcoi_hht_inv_transactions.outside_business_low_type%TYPE  -- �o�ɑ��Ƒԏ�����
    , inside_business_low_type   xxcoi_hht_inv_transactions.inside_business_low_type%TYPE   -- ���ɑ��Ƒԏ�����
  );
  TYPE gt_svd_data_ttype IS TABLE OF gr_svd_data_rec INDEX BY BINARY_INTEGER;
  -- ���i�U�փf�[�^���R�[�h�i�[�p
  TYPE gr_item_conv_data_rec IS RECORD(
      xhit_rowid                 rowid                                                  -- ROWID
    , invoice_no                 xxcoi_hht_inv_transactions.invoice_no%TYPE             -- �`�[No
    , transaction_id             xxcoi_hht_inv_transactions.transaction_id%TYPE         -- ���ɏ��ꎞ�\ID
    , record_type                xxcoi_hht_inv_transactions.record_type%TYPE            -- ���R�[�h���
    , invoice_type               xxcoi_hht_inv_transactions.invoice_type%TYPE           -- �`�[�敪
    , department_flag            xxcoi_hht_inv_transactions.department_flag%TYPE        -- �S�ݓX�t���O
    , column_no                  xxcoi_hht_inv_transactions.column_no%TYPE              -- �R������  
    , base_code                  xxcoi_hht_inv_transactions.base_code%TYPE              -- ���_�R�[�h
    , employee_num               xxcoi_hht_inv_transactions.employee_num%TYPE           -- �c�ƈ��R�[�h
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE              -- �i�ڃR�[�h
    , case_in_quantity           xxcoi_hht_inv_transactions.case_in_quantity%TYPE       -- ����
    , case_quantity              xxcoi_hht_inv_transactions.case_quantity%TYPE          -- �P�[�X��
    , quantity                   xxcoi_hht_inv_transactions.quantity%TYPE               -- �{��
    , total_quantity             xxcoi_hht_inv_transactions.total_quantity%TYPE         -- ������
    , inventory_item_id          xxcoi_hht_inv_transactions.inventory_item_id%TYPE      -- �i��ID
    , primary_uom_code           xxcoi_hht_inv_transactions.primary_uom_code%TYPE       -- ��P��
    , invoice_date               xxcoi_hht_inv_transactions.invoice_date%TYPE           -- �`�[���t
    , outside_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE    -- �o�ɑ��ۊǏꏊ
    , inside_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE     -- ���ɑ��ۊǏꏊ
    , outside_code               xxcoi_hht_inv_transactions.outside_code%TYPE           -- �o�ɑ��R�[�h
    , inside_code                xxcoi_hht_inv_transactions.inside_code%TYPE            -- ���ɑ��R�[�h
    , outside_base_code          xxcoi_hht_inv_transactions.outside_base_code%TYPE      -- �o�ɑ����_�R�[�h
    , inside_base_code           xxcoi_hht_inv_transactions.inside_base_code%TYPE       -- ���ɑ����_�R�[�h
    , item_convert_div           xxcoi_hht_inv_transactions.item_convert_div%TYPE       -- ���i�U�֋敪
  );
  TYPE gt_item_conv_data_ttype IS TABLE OF gr_item_conv_data_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- PL/SQL�\
  gt_inout_kuragae_data_tab       gt_inout_kuragae_data_ttype;
  gt_svd_data_tab                 gt_svd_data_ttype;
  gt_item_conv_data_tab           gt_item_conv_data_ttype;
  -- ���������擾�ϐ�
  gt_org_id                       mtl_parameters.organization_id%TYPE;                    -- �݌ɑg�DID
  gt_file_name                    fnd_profile_option_values.profile_option_value%TYPE;    -- HHT�G���[���X�g�t�@�C����
  gd_process_date                 DATE;                                                   -- �Ɩ����t
  gt_tran_type_id_kuragae         mtl_transaction_types.transaction_type_id%TYPE;         -- ����^�C�vID �q��
  gt_tran_type_id_inout           mtl_transaction_types.transaction_type_id%TYPE;         -- ����^�C�vID ���o��
  gt_tran_type_id_item_conv_new   mtl_transaction_types.transaction_type_id%TYPE;         -- ����^�C�vID ���i�U��(�V)
  gt_tran_type_id_item_conv_old   mtl_transaction_types.transaction_type_id%TYPE;         -- ����^�C�vID ���i�U��(��)
  gt_tran_type_id_svd             mtl_transaction_types.transaction_type_id%TYPE;         -- ����^�C�vID ����VD��[
  gt_transaction_source_id        mtl_transactions_interface.transaction_source_id%TYPE;  -- ����\�[�XID
  gv_kuragae_flag                 VARCHAR2(1);
  -- ���o�ɁE�q�� ��������
  gn_target_inout_kuragae_cnt     NUMBER;
  gn_normal_inout_kuragae_cnt     NUMBER;
  gn_warn_inout_kuragae_cnt       NUMBER;
  gn_error_inout_kuragae_cnt      NUMBER;
  -- ����VD��[ ��������
  gn_target_svd_cnt               NUMBER;
  gn_normal_svd_cnt               NUMBER;
  gn_warn_svd_cnt                 NUMBER;
  gn_error_svd_cnt                NUMBER;
  gn_oif_ins_svd_cnt              NUMBER;
  -- ���i�U�� ��������
  gn_target_item_conv_cnt         NUMBER;
  gn_normal_item_conv_cnt         NUMBER;
  gn_warn_item_conv_cnt           NUMBER;
  gn_error_item_conv_cnt          NUMBER;
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
    cv_prf_org_code              CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
    cv_prf_file_name             CONSTANT VARCHAR2(30) := 'XXCOI1_HHT_ERR_DATA_NAME';
    --
    -- �Q�ƃ^�C�v
    cv_tran_type                 CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME'; -- ���[�U�[��`����^�C�v����
    -- �Q�ƃR�[�h
    cv_tran_type_inout           CONSTANT VARCHAR2(2)  := '10';                           -- ����^�C�v �R�[�h ���o��
    cv_tran_type_kuragae         CONSTANT VARCHAR2(2)  := '20';                           -- ����^�C�v �R�[�h �q��
    cv_tran_type_item_conv_new   CONSTANT VARCHAR2(2)  := '40';                           -- ����^�C�v �R�[�h ���i�U��(�V)
    cv_tran_type_item_conv_old   CONSTANT VARCHAR2(2)  := '30';                           -- ����^�C�v �R�[�h ���i�U��(��)
    cv_tran_type_svd             CONSTANT VARCHAR2(2)  := '70';                           -- ����^�C�v �R�[�h ����VD��[
--
    -- *** ���[�J���ϐ� ***
    lt_org_code                  mtl_parameters.organization_code%TYPE;                   -- �݌ɑg�D�R�[�h
    lt_tran_type_kuragae         mtl_transaction_types.transaction_type_name%TYPE;        -- ����^�C�v�� �q��
    lt_tran_type_inout           mtl_transaction_types.transaction_type_name%TYPE;        -- ����^�C�v�� ���o��
    lt_tran_type_item_conv_new   mtl_transaction_types.transaction_type_name%TYPE;        -- ����^�C�v�� ���i�U��(�V)
    lt_tran_type_item_conv_old   mtl_transaction_types.transaction_type_name%TYPE;        -- ����^�C�v�� ���i�U��(��)
    lt_tran_type_svd             mtl_transaction_types.transaction_type_name%TYPE;        -- ����^�C�v�� ����VD��[
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
    gt_tran_type_id_inout := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_inout );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_id_inout IS NULL ) THEN
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
    gt_tran_type_id_kuragae := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_kuragae );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_id_kuragae IS NULL ) THEN
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
    -- ����^�C�v���擾�i���i�U�ցF�V�j
    -- ===============================
    lt_tran_type_item_conv_new := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_item_conv_new );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_item_conv_new IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_item_conv_new
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i���i�U�ցF�V�j
    -- ===============================
    gt_tran_type_id_item_conv_new := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_item_conv_new );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_id_item_conv_new IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_item_conv_new
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i���i�U�ցF���j
    -- ===============================
    lt_tran_type_item_conv_old := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_item_conv_old );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_item_conv_old IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_item_conv_old
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i���i�U�ցF���j
    -- ===============================
    gt_tran_type_id_item_conv_old := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_item_conv_old );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_id_item_conv_old IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_item_conv_old
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�v���擾�i����VD��[�j
    -- ===============================
    lt_tran_type_svd := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_svd );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( lt_tran_type_svd IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_svd
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����^�C�vID�擾�i����VD��[�j
    -- ===============================
    gt_tran_type_id_svd := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_svd );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_tran_type_id_svd IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_svd
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
   * Procedure Name   : chk_inout_kuragae_data
   * Description      : ���o�ɁE�q�փf�[�^�Ó����`�F�b�N (A-3)
   ***********************************************************************************/
  PROCEDURE chk_inout_kuragae_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_inout_kuragae_data'; -- �v���O������
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
    cv_kuragae_kahi_div_0       CONSTANT VARCHAR2(1) := '0';        -- �q�֑Ώۉۋ敪   0:�q�֑Ώ۔ۋ��_
    cv_cust_class_code_base     CONSTANT VARCHAR2(1) := '1';        -- �ڋq�敪           1:���_
--
    -- *** ���[�J���ϐ� ***
    lv_key_info                     VARCHAR2(500);                      -- KEY���
    lb_org_acct_period_flg          BOOLEAN;                            -- �����݌ɉ�v���ԃI�[�v���t���O
    lt_kuragae_kahi_count           hz_cust_accounts.attribute6%TYPE;   -- �q�֑Ώۉۋ敪�i�o�ɑ����_�R�[�h�j
    -- *** ���[�J���E��O ***
    invalid_value_expt              EXCEPTION;                                  -- �`�F�b�N��O
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
--  �ϐ��̏�����
    gv_kuragae_flag := NULL;
    --
    -- =========================
    --  1.�݌ɉ�v���ԃ`�F�b�N
    -- =========================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                                 -- �݌ɑg�DID
      , id_target_date     => gt_inout_kuragae_data_tab( in_index ).invoice_date    -- �`�[���t
      , ob_chk_result      => lb_org_acct_period_flg                                    -- �`�F�b�N����
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
                     , iv_token_value1 => TO_CHAR( gt_inout_kuragae_data_tab( in_index ).invoice_date ,'yyyymmdd' )
                   );
      RAISE global_api_expt;
    END IF;
    -- �����݌ɉ�v���Ԃ��N���[�Y�̏ꍇ
    IF ( NOT lb_org_acct_period_flg ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_invoice_date_invalid_err
                     , iv_token_name1  => cv_tkn_proc_date
                     , iv_token_value1 => TO_CHAR( gt_inout_kuragae_data_tab( in_index ).invoice_date ,'yyyymmdd' )
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
    -- =========================
    --  2.���o�ɁE�q�֔���
    -- =========================
    IF ( gt_inout_kuragae_data_tab(in_index).outside_base_code 
         = gt_inout_kuragae_data_tab(in_index).inside_base_code ) THEN
    -- ���o��
      gv_kuragae_flag := cv_flag_n;
    --
    ELSE
    -- �q��
      gv_kuragae_flag := cv_flag_y;
      -- ------------------------
      -- (1) �o�ɑ��F�q�։۔���
      -- ------------------------
      SELECT COUNT(1)                  -- �q�֑Ώەs����
      INTO   lt_kuragae_kahi_count
      FROM   hz_cust_accounts hca 
      WHERE  hca.account_number      = gt_inout_kuragae_data_tab(in_index).outside_base_code
      AND    hca.customer_class_code = cv_cust_class_code_base
      AND    hca.attribute6          = cv_kuragae_kahi_div_0
      AND    ROWNUM                 <= 1;
      -- �q�֕s�̏ꍇ
      IF lt_kuragae_kahi_count = 1 THEN
      --
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_dept_code_err_msg
                          , iv_token_name1  => cv_tkn_dept_code
                          , iv_token_value1 => gt_inout_kuragae_data_tab(in_index).outside_base_code
                        );
        --
        lv_errbuf := lv_errmsg;
        --
        RAISE invalid_value_expt;
        --
      END IF;
      -- ------------------------
      -- (2) ���ɑ��F�q�։۔���
      -- ------------------------
      SELECT COUNT(1)                  -- �q�֑Ώەs����
      INTO   lt_kuragae_kahi_count
      FROM   hz_cust_accounts hca 
      WHERE  hca.account_number      = gt_inout_kuragae_data_tab(in_index).inside_base_code
      AND    hca.customer_class_code = cv_cust_class_code_base
      AND    hca.attribute6          = cv_kuragae_kahi_div_0
      AND    ROWNUM                 <= 1;
      -- �q�֕s�̏ꍇ
      IF lt_kuragae_kahi_count = 1 THEN
      --
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_dept_code_err_msg
                          , iv_token_name1  => cv_tkn_dept_code
                          , iv_token_value1 => gt_inout_kuragae_data_tab(in_index).inside_base_code
                        );
        --
        lv_errbuf := lv_errmsg;
        --
        RAISE invalid_value_expt;
        --
      END IF;
    --
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �s���l��O�n���h�� ***
    WHEN invalid_value_expt THEN
      -- KEY���擾
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_key_info
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_inout_kuragae_data_tab( in_index ).base_code
                     , iv_token_name2  => cv_tkn_record_type
                     , iv_token_value2 => gt_inout_kuragae_data_tab( in_index ).record_type
                     , iv_token_name3  => cv_tkn_invoice_type
                     , iv_token_value3 => gt_inout_kuragae_data_tab( in_index ).invoice_type
                     , iv_token_name4  => cv_tkn_dept_flag
                     , iv_token_value4 => gt_inout_kuragae_data_tab( in_index ).department_flag
                     , iv_token_name5  => cv_tkn_invoice_no
                     , iv_token_value5 => gt_inout_kuragae_data_tab( in_index ).invoice_no
                     , iv_token_name6  => cv_tkn_column_no
                     , iv_token_value6 => gt_inout_kuragae_data_tab( in_index ).column_no
                     , iv_token_name7  => cv_tkn_item_code
                     , iv_token_value7 => gt_inout_kuragae_data_tab( in_index ).item_code );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
         , buff   => lv_key_info || lv_errmsg );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
         , buff   => lv_key_info || lv_errbuf );
      --
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                             --# �C�� #
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
  END chk_inout_kuragae_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_inout_kuragae_data
   * Description      : ���o�ɁE�q�փf�[�^�̎��ގ��OIF�ǉ� (A-4)
   ***********************************************************************************/
  PROCEDURE ins_inout_kuragae_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inout_kuragae_data'; -- �v���O������
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
    lt_tran_type_id              mtl_transaction_types.transaction_type_id%TYPE;         -- ����^�C�vID
    lt_subinventory_code         mtl_transactions_interface.subinventory_code%TYPE;      -- �ۊǏꏊ
    lt_transfer_subinventory     mtl_transactions_interface.transfer_subinventory%TYPE;  -- �����ۊǏꏊ
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
--  �ϐ��̏�����
    lt_tran_type_id := NULL;
    lt_subinventory_code := NULL;
    lt_transfer_subinventory := NULL;
    -- =======================
    -- ����^�C�v����
    -- =======================
    IF gv_kuragae_flag = cv_flag_y THEN
      -- �q��
      lt_tran_type_id := gt_tran_type_id_kuragae;
      --
    ELSE
      -- ���o��
      lt_tran_type_id := gt_tran_type_id_inout;
      --
    END IF;
    -- =======================
    -- ���ʂɂ��ۊǏꏊ����
    -- =======================
    IF ( SIGN( gt_inout_kuragae_data_tab( in_index ).total_quantity ) = 1 ) THEN
      -- ���]
      lt_subinventory_code     := gt_inout_kuragae_data_tab( in_index ).outside_subinv_code;
      lt_transfer_subinventory := gt_inout_kuragae_data_tab( in_index ).inside_subinv_code;
      --
    ELSIF ( SIGN( gt_inout_kuragae_data_tab( in_index ).total_quantity ) = ( -1 ) ) THEN
      -- ���]
      lt_subinventory_code     := gt_inout_kuragae_data_tab( in_index ).inside_subinv_code;
      lt_transfer_subinventory := gt_inout_kuragae_data_tab( in_index ).outside_subinv_code;
      --
    END IF;
    -- =======================
    -- ���ގ��OIF�֓o�^
    -- =======================
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
      , gt_inout_kuragae_data_tab( in_index ).transaction_id                     -- �\�[�X�w�b�_�[ID
      , cv_source_line_id                                                        -- �\�[�X���C��ID
      , gt_inout_kuragae_data_tab( in_index ).inventory_item_id                  -- �i��ID
      , gt_org_id                                                                -- �݌ɑg�DID
      , ( SIGN( gt_inout_kuragae_data_tab( in_index ).total_quantity )
          * ( gt_inout_kuragae_data_tab( in_index ).total_quantity ) )           -- �������
      , ( SIGN( gt_inout_kuragae_data_tab( in_index ).total_quantity )
          * ( gt_inout_kuragae_data_tab( in_index ).total_quantity ) )           -- ��P�ʐ���
      , gt_inout_kuragae_data_tab( in_index ).primary_uom_code                   -- ����P��
      , gt_inout_kuragae_data_tab( in_index ).invoice_date                       -- �����
      , lt_subinventory_code                                                     -- �ۊǏꏊ�R�[�h
      , lt_tran_type_id                                                          -- ����^�C�vID
      , lt_transfer_subinventory                                                 -- �����ۊǏꏊ�R�[�h
      , gt_org_id                                                                -- �����݌ɑg�DID
      , gt_inout_kuragae_data_tab( in_index ).invoice_no                         -- �`�[No
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
  END ins_inout_kuragae_data;
--
  /**********************************************************************************
   * Procedure Name   : update_xhit_data
   * Description      : HHT���o�Ɉꎞ�\�̏����X�e�[�^�X�X�V (A-5)(A-12)(A-21)
   ***********************************************************************************/
  PROCEDURE update_xhit_data(
    ir_rowid      IN  ROWID,        -- 1.ROWID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_xhit_data'; -- �v���O������
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
    cn_status_post               CONSTANT NUMBER := 1;  -- �����X�e�[�^�X 1�F������
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
    -- HHT���o�Ɉꎞ�\�X�V
    UPDATE xxcoi_hht_inv_transactions xhit                              -- HHT���o�Ɉꎞ�\
    SET    xhit.status                 = cn_status_post                 -- �����X�e�[�^�X
         , xhit.last_updated_by        = cn_last_updated_by             -- �ŏI�X�V��
         , xhit.last_update_date       = cd_last_update_date            -- �ŏI�X�V��
         , xhit.last_update_login      = cn_last_update_login           -- �ŏI�X�V���O�C��
         , xhit.request_id             = cn_request_id                  -- �v��ID
         , xhit.program_application_id = cn_program_application_id      -- �v���O�����A�v���P�[�V����ID
         , xhit.program_id             = cn_program_id                  -- �v���O����ID
         , xhit.program_update_date    = cd_program_update_date         -- �v���O�����X�V��
    WHERE  xhit.rowid                  = ir_rowid                       -- ROWID
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
  END update_xhit_data;
--
  /**********************************************************************************
   * Procedure Name   : del_xhit_data
   * Description      : HHT���o�Ɉꎞ�\�̃G���[���R�[�h�폜 (A-7)(A-14)(A-23)
   ***********************************************************************************/
  PROCEDURE del_xhit_data(
    ir_rowid      IN  ROWID,       -- 1.ROWID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_xhit_data'; -- �v���O������
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
    -- HHT���o�Ɉꎞ�\�̍폜
    DELETE
    FROM   xxcoi_hht_inv_transactions xhit                               -- HHT���o�Ɉꎞ�\
    WHERE  xhit.rowid = ir_rowid                                         -- ROWID
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
  END del_xhit_data;
--
  /**********************************************************************************
   * Procedure Name   : get_inout_kuragae_data
   * Description      : ���o�ɁE�q�փf�[�^�擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_inout_kuragae_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inout_kuragae_data'; -- �v���O������
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
    cv_hht_program_div_5          CONSTANT VARCHAR2(1) := '5';        -- ���o�ɼެ��ُ����敪�F���̑����o��
    cn_status_pre                 CONSTANT NUMBER      := 0;          -- �����X�e�[�^�X�F������
    cv_business_low_type_27       CONSTANT VARCHAR2(2) := '27';       -- �Ƒԏ����ށF����VD
    cv_business_low_type_dummy    CONSTANT VARCHAR2(2) := 'XX';       -- �Ƒԏ����ށF�_�~�[
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    CURSOR inout_kuragae_data_cur
    IS
      SELECT             
-- == 2010/08/31 V1.3 Added START ===============================================================
              /*+ INDEX(xhit xxcoi_hht_inv_transactions_n04) */
-- == 2010/08/31 V1.3 Added END   ===============================================================
              xhit.rowid                  AS xhit_rowid             -- ROWID
            , xhit.invoice_no             AS invoice_no             -- �`�[No
            , xhit.transaction_id         AS transaction_id         -- ���ɏ��ꎞ�\ID
            , xhit.record_type            AS record_type          -- ���R�[�h���
            , xhit.invoice_type           AS invoice_type         -- �`�[�敪
            , xhit.department_flag        AS department_flag      -- �S�ݓX�t���O
            , xhit.column_no              AS column_no            -- �R������  
            , xhit.base_code              AS base_code              -- ���_�R�[�h
            , xhit.employee_num           AS employee_num           -- �c�ƈ��R�[�h
            , xhit.item_code              AS item_code              -- �i�ڃR�[�h
            , xhit.case_in_quantity       AS case_in_quantity       -- ����
            , xhit.case_quantity          AS case_quantity          -- �P�[�X��
            , xhit.quantity               AS quantity               -- �{��
            , xhit.total_quantity         AS total_quantity         -- ������
            , xhit.inventory_item_id      AS inventory_item_id      -- �i��ID
            , xhit.primary_uom_code       AS primary_uom_code       -- ��P��
            , xhit.invoice_date           AS invoice_date           -- �`�[���t
            , xhit.outside_subinv_code    AS outside_subinv_code    -- �o�ɑ��ۊǏꏊ
            , xhit.inside_subinv_code     AS inside_subinv_code     -- ���ɑ��ۊǏꏊ
            , xhit.outside_code           AS outside_code           -- �o�ɑ��R�[�h
            , xhit.inside_code            AS inside_code            -- ���ɑ��R�[�h
            , xhit.outside_base_code      AS outside_base_code      -- �o�ɑ����_�R�[�h
            , xhit.inside_base_code       AS inside_base_code       -- ���ɑ����_�R�[�h
      FROM    
              xxcoi_hht_inv_transactions  xhit                      -- HHT���o�Ɉꎞ�\
      WHERE   
              xhit.hht_program_div = cv_hht_program_div_5           -- ���o�ɃW���[�i�������敪(5)
      AND     xhit.status          = cn_status_pre                  -- �����X�e�[�^�X
      AND     NVL( xhit.outside_business_low_type,cv_business_low_type_dummy ) <> cv_business_low_type_27
      AND     NVL( xhit.inside_business_low_type,cv_business_low_type_dummy  ) <> cv_business_low_type_27
--  V1.4 Added START
--  Ver1.5 Mod Start
--      AND     xhit.invoice_date     <   TRUNC( SYSDATE ) + 1        --  �������s������00:00:00 �����̂ݑΏہi�݌Ɏ�����[�J�[�G���[�Ή��j
      AND     xhit.invoice_date    < TRUNC( gd_process_date ) + 1   --  �Ɩ����t����00:00:00 �����̂ݑΏہi�݌Ɏ�����[�J�[�G���[�Ή��j
--  Ver1.5 Mod End
--  V1.4 Added END
      ORDER BY
                xhit.base_code
              , xhit.record_type    
              , xhit.invoice_type   
              , xhit.department_flag
              , xhit.invoice_no
              , xhit.column_no
              , xhit.item_code
      FOR UPDATE NOWAIT;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    -- =======================
    -- ���o�ɁE�q�փf�[�^�擾
    -- =======================
    -- �J�[�\���I�[�v��
    OPEN inout_kuragae_data_cur;
    -- ���R�[�h�ǂݍ���
    FETCH inout_kuragae_data_cur BULK COLLECT INTO gt_inout_kuragae_data_tab;
    -- �Ώی����擾
    gn_target_inout_kuragae_cnt := gt_inout_kuragae_data_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE inout_kuragae_data_cur;
    -- =======================
    -- 0������
    -- =======================
    IF gn_target_inout_kuragae_cnt = 0 THEN
    --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_inout_kuragae_no_data_msg
                    );
      -- 0�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --�G���[���b�Z�[�W
      );
      --
      ov_retcode := cv_status_normal;
      RETURN;
    --
    END IF;
    -- =======================
    -- LOOP����
    -- =======================
    <<inout_kuragae_data_loop>>
    FOR ln_index IN 1..gn_target_inout_kuragae_cnt LOOP
        -- ===============================================================
        -- ���o�ɁE�q�փf�[�^�Ó����`�F�b�N���� (A-3)
        -- ===============================================================
        --
        chk_inout_kuragae_data(
            in_index     => ln_index                 -- ���[�v�J�E���^
          , ov_errbuf    => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode   => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg    => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- ����̏ꍇ
        IF (lv_retcode = cv_status_normal) THEN
        --
        -- ===============================================================
        -- ���o�ɁE�q�փf�[�^�̎��ގ��OIF�ǉ� (A-4)
        -- ===============================================================
          ins_inout_kuragae_data(
              in_index     => ln_index                 -- ���[�v�J�E���^
            , ov_errbuf    => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode   => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg    => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- ���o�ɁE�q�փf�[�^�� HHT���o�Ɉꎞ�\�̏����X�e�[�^�X�X�V (A-5)
        -- ===============================================================
          update_xhit_data(
              ir_rowid     => gt_inout_kuragae_data_tab(ln_index).xhit_rowid  -- ROWID
            , ov_errbuf    => lv_errbuf                                       -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode   => lv_retcode                                      -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg    => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
        --
          -- ----------------
          -- ���팏���J�E���g
          -- ----------------
          gn_normal_inout_kuragae_cnt := gn_normal_inout_kuragae_cnt + 1;
        -- �x���̏ꍇ
        ELSIF (lv_retcode = cv_status_warn) THEN
        -- ===============================================================
        -- ���o�ɁE�q�փf�[�^��HHT�G���[���X�g�\�ǉ� (A-6)
        -- ===============================================================
          xxcoi_common_pkg.add_hht_err_list_data(
              iv_base_code           => gt_inout_kuragae_data_tab( ln_index ).base_code    -- ���_�R�[�h
            , iv_origin_shipment     => gt_inout_kuragae_data_tab( ln_index ).outside_code -- �o�ɑ��R�[�h
            , iv_data_name           => gt_file_name                                       -- �f�[�^����
            , id_transaction_date    => gt_inout_kuragae_data_tab( ln_index ).invoice_date -- �����
            , iv_entry_number        => gt_inout_kuragae_data_tab( ln_index ).invoice_no   -- �`�[No
            , iv_party_num           => gt_inout_kuragae_data_tab( ln_index ).inside_code  -- ���ɑ��R�[�h
            , iv_performance_by_code => gt_inout_kuragae_data_tab( ln_index ).employee_num -- �c�ƈ��R�[�h
            , iv_item_code           => gt_inout_kuragae_data_tab( ln_index ).item_code    -- �i�ڃR�[�h
            , iv_error_message       => lv_errmsg                                          -- �G���[���e
            , ov_errbuf              => lv_errbuf                                          -- �G���[�E���b�Z�[�W
            , ov_retcode             => lv_retcode                                         -- ���^�[���E�R�[�h
            , ov_errmsg              => lv_errmsg                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- HHT���o�Ɉꎞ�\�̃G���[���R�[�h�폜 (A-7)
        -- ===============================================================
          del_xhit_data(
              ir_rowid     => gt_inout_kuragae_data_tab( ln_index ).xhit_rowid  -- ROWID
            , ov_errbuf    => lv_errbuf                                         -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode   => lv_retcode                                        -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg    => lv_errmsg                                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
          -- ----------------
          -- �x�������J�E���g
          -- ----------------
          gn_warn_inout_kuragae_cnt := gn_warn_inout_kuragae_cnt + 1;
          --
        ELSE
          --(�G���[����)
          RAISE global_api_expt;
          --
        END IF;
    --
    END LOOP inout_kuragae_data_loop;
    --
    
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( inout_kuragae_data_cur%ISOPEN ) THEN
        CLOSE inout_kuragae_data_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_hht_table_lock_err_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_inout_kuragae_data;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_svd_data
   * Description      : ����VD��[�f�[�^ �Ó����`�F�b�N (A-10)
   ***********************************************************************************/
  PROCEDURE chk_svd_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_svd_data'; -- �v���O������
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
    cv_business_low_type_27       CONSTANT VARCHAR2(2) := '27';       -- �Ƒԏ����ށF����VD
    cv_business_low_type_dummy    CONSTANT VARCHAR2(2) := 'XX';       -- �Ƒԏ����ށF�_�~�[
    -- *** ���[�J���ϐ� ***
    lv_key_info             VARCHAR2(500);                            -- KEY���
    lb_org_acct_period_flg  BOOLEAN;                                  -- �����݌ɉ�v���ԃI�[�v���t���O
    lt_cust_code            hz_cust_accounts.account_number%TYPE;     -- �ڋq�R�[�h
    ln_count                NUMBER;                                   -- �i�ڈ�v����
    -- *** ���[�J���E��O ***
    invalid_value_expt      EXCEPTION;                                -- �`�F�b�N��O
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
--  �ϐ��̏�����
    ln_count := 0;
    --
    -- =========================
    --  1.�݌ɉ�v���ԃ`�F�b�N
    -- =========================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                    -- �݌ɑg�DID
      , id_target_date     => gt_svd_data_tab( in_index ).invoice_date     -- �`�[���t
      , ob_chk_result      => lb_org_acct_period_flg                       -- �`�F�b�N����
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
                     , iv_token_value1 => TO_CHAR( gt_svd_data_tab( in_index ).invoice_date ,'YYYYMMDD' )
                   );
      RAISE global_api_expt;
    END IF;
    -- �����݌ɉ�v���Ԃ��N���[�Y�̏ꍇ
    IF ( NOT lb_org_acct_period_flg ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_invoice_date_invalid_err
                     , iv_token_name1  => cv_tkn_proc_date
                     , iv_token_value1 => TO_CHAR( gt_svd_data_tab( in_index ).invoice_date ,'YYYYMMDD' )
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
    -- =========================
    --  2.����VD��[�f�[�^�̕K�{�`�F�b�N
    -- =========================
    -- �R������
    IF ( gt_svd_data_tab( in_index ).column_no IS NULL ) THEN
    --
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_column_no_is_null_err_msg );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    --
    END IF;
    -- �P��
    IF ( gt_svd_data_tab( in_index ).unit_price IS NULL ) THEN
    --
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_up_is_null_err_mag );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    --
    END IF;
    -- =========================
    --  3.����VD��[�f�[�^�̕i�ڈ�v�`�F�b�N
    -- =========================
    -- �ڋq�R�[�h�̐ݒ�
    IF ( NVL( gt_svd_data_tab( in_index ).outside_business_low_type , cv_business_low_type_dummy )
            = cv_business_low_type_27 ) 
    THEN
      lt_cust_code := gt_svd_data_tab( in_index ).outside_code;
    ELSE
      lt_cust_code := gt_svd_data_tab( in_index ).inside_code;
    END IF;
-- == 2009/11/25 V1.2 Deleted START ===============================================================
---- == 2009/11/24 V1.1 Added START ===============================================================
--    --��ʓ��͂��ꂽ�f�[�^��VD�R�����}�X�^�Ƃ̃`�F�b�N���s��Ȃ�
--    IF (SUBSTRB(gt_svd_data_tab(in_index).invoice_no, 1, 1) <> 'E') THEN
---- == 2009/11/24 V1.1 Added END   ===============================================================
--      -- -------------
--      -- (1)�����̏ꍇ
--      -- -------------
--      IF ( TRUNC(gt_svd_data_tab( in_index ).invoice_date,'MM') = TRUNC(gd_process_date,'MM') ) THEN
--      --
--        SELECT  COUNT(1)
--        INTO    ln_count
--        FROM    hz_cust_accounts hca,
--                xxcoi_mst_vd_column xmvc
--        WHERE   hca.cust_account_id = xmvc.customer_id 
--        AND     hca.account_number  = lt_cust_code
--        AND     xmvc.column_no      = gt_svd_data_tab( in_index ).column_no
--        AND     xmvc.item_id        = gt_svd_data_tab( in_index ).inventory_item_id
--        AND     ROWNUM <= 1;
--        -- ��v������0�̏ꍇ
--        IF ln_count = 0 THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_application_short_name
--                         , iv_name         => cv_vd_item_err_msg );
--          lv_errbuf := lv_errmsg;
--          RAISE invalid_value_expt;
--        END IF;
--      -- -------------
--      -- (2)�O���̏ꍇ
--      -- -------------
--      ELSE
--      --
--        SELECT  COUNT(1)
--        INTO    ln_count
--        FROM    hz_cust_accounts hca,
--                xxcoi_mst_vd_column xmvc
--        WHERE   hca.cust_account_id     = xmvc.customer_id 
--        AND     hca.account_number      = lt_cust_code
--        AND     xmvc.column_no          = gt_svd_data_tab( in_index ).column_no
--        AND     xmvc.last_month_item_id = gt_svd_data_tab( in_index ).inventory_item_id
--        AND     ROWNUM <= 1;
--        -- ��v������0�̏ꍇ
--        IF ln_count = 0 THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_application_short_name
--                         , iv_name         => cv_vd_last_month_item_err_msg );
--          lv_errbuf := lv_errmsg;
--          RAISE invalid_value_expt;
--        END IF;
--      --
--      END IF;
---- == 2009/11/24 V1.1 Added START ===============================================================
--    END IF;
---- == 2009/11/24 V1.1 Added END   ===============================================================
-- == 2009/11/25 V1.2 Deleted END   ===============================================================
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �s���l��O�n���h�� ***
    WHEN invalid_value_expt THEN
      -- KEY���擾
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_key_info
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_svd_data_tab( in_index ).base_code
                     , iv_token_name2  => cv_tkn_record_type
                     , iv_token_value2 => gt_svd_data_tab( in_index ).record_type
                     , iv_token_name3  => cv_tkn_invoice_type
                     , iv_token_value3 => gt_svd_data_tab( in_index ).invoice_type
                     , iv_token_name4  => cv_tkn_dept_flag
                     , iv_token_value4 => gt_svd_data_tab( in_index ).department_flag
                     , iv_token_name5  => cv_tkn_invoice_no
                     , iv_token_value5 => gt_svd_data_tab( in_index ).invoice_no
                     , iv_token_name6  => cv_tkn_column_no
                     , iv_token_value6 => gt_svd_data_tab( in_index ).column_no
                     , iv_token_name7  => cv_tkn_item_code
                     , iv_token_value7 => gt_svd_data_tab( in_index ).item_code );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
         , buff   => lv_key_info || lv_errmsg );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
         , buff   => lv_key_info || lv_errbuf );
      --
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                             --# �C�� #
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
  END chk_svd_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_temp_svd_data
   * Description      : ����VD��[�f�[�^�̈ꎞ�\�ǉ� (A-11)
   ***********************************************************************************/
  PROCEDURE ins_temp_svd_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_temp_svd_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
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
    -- ����VD��[���[�N�e�[�u���֓o�^
    INSERT INTO xxcoi_tmp_svd_transactions(
       item_id                                                                -- �i��ID
      ,primary_uom_code                                                       -- ��P�ʃR�[�h
      ,invoice_date                                                           -- �`�[���t
      ,outside_subinv_code                                                    -- �o�ɑ��ۊǏꏊ�R�[�h
      ,inside_subinv_code                                                     -- ���ɑ��ۊǏꏊ�R�[�h
      ,total_quantity                                                         -- ������
    )
    VALUES(
       gt_svd_data_tab( in_index ).inventory_item_id                          -- �i��ID
      ,gt_svd_data_tab( in_index ).primary_uom_code                           -- ��P�ʃR�[�h
      ,gt_svd_data_tab( in_index ).invoice_date                               -- �`�[���t
      ,gt_svd_data_tab( in_index ).outside_subinv_code                        -- �o�ɑ��ۊǏꏊ�R�[�h
      ,gt_svd_data_tab( in_index ).inside_subinv_code                         -- ���ɑ��ۊǏꏊ�R�[�h
      ,gt_svd_data_tab( in_index ).total_quantity                             -- ������
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
  END ins_temp_svd_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_svd_data
   * Description      : ����VD��[�f�[�^�̎��ގ��OIF�ǉ� (A-15)
   ***********************************************************************************/
  PROCEDURE ins_oif_svd_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_svd_data'; -- �v���O������
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
    cv_process_flag              CONSTANT VARCHAR2(1) := '1';  -- �v���Z�X�t���O   1�F�����Ώ�
    cv_transaction_mode          CONSTANT VARCHAR2(1) := '3';  -- ������[�h       3�F�o�b�N�O���E���h
    cv_source_head_id            CONSTANT VARCHAR2(1) := '1';  -- �\�[�X�w�b�_�[ID 1�F�Œ�
    cv_source_line_id            CONSTANT VARCHAR2(1) := '1';  -- �\�[�X���C��ID   1�F�Œ�
    -- *** ���[�J���ϐ� ***
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
    -- =======================
    -- ���ގ��OIF�֓o�^
    -- =======================
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
    SELECT
        cv_process_flag                                                          -- �v���Z�X�t���O
      , cv_transaction_mode                                                      -- ������[�h
      , cv_pkg_name                                                              -- �\�[�X�R�[�h
      , cv_source_head_id                                                        -- �\�[�X�w�b�_�[ID
      , cv_source_line_id                                                        -- �\�[�X���C��ID
      , xtst.item_id                                                             -- �i��ID
      , gt_org_id                                                                -- �݌ɑg�DID
      , ( SIGN( SUM(xtst.total_quantity) ) * SUM(xtst.total_quantity) )          -- �������
      , ( SIGN( SUM(xtst.total_quantity) ) * SUM(xtst.total_quantity) )          -- ��P�ʐ���
      , xtst.primary_uom_code                                                    -- ����P��
      , xtst.invoice_date                                                        -- �����
      , DECODE( SIGN( SUM(xtst.total_quantity) )
                    , 1 , xtst.outside_subinv_code
                        , xtst.inside_subinv_code  )                             -- �ۊǏꏊ�R�[�h
      , gt_tran_type_id_svd                                                      -- ����^�C�vID
      , DECODE( SIGN( SUM(xtst.total_quantity) )
                    , 1 , xtst.inside_subinv_code
                        , xtst.outside_subinv_code )                             -- �����ۊǏꏊ�R�[�h
      , gt_org_id                                                                -- �����݌ɑg�DID
      , cn_created_by                                                            -- �쐬��
      , cd_creation_date                                                         -- �쐬��
      , cn_last_updated_by                                                       -- �ŏI�X�V��
      , cd_last_update_date                                                      -- �ŏI�X�V��
      , cn_last_update_login                                                     -- �ŏI�X�V���O�C��
      , cn_request_id                                                            -- �v��ID
      , cn_program_application_id                                                -- �v���O�����A�v���P�[�V����ID
      , cn_program_id                                                            -- �v���O����ID
      , cd_program_update_date                                                   -- �v���O�����X�V��
    FROM
          xxcoi_tmp_svd_transactions xtst
    HAVING    SUM(xtst.total_quantity) <> 0
    GROUP BY  xtst.item_id
            , xtst.primary_uom_code
            , xtst.invoice_date
            , xtst.outside_subinv_code
            , xtst.inside_subinv_code
    ;
    -- �o�^�������擾
    gn_oif_ins_svd_cnt := SQL%ROWCOUNT;
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
  END ins_oif_svd_data;
--
  /**********************************************************************************
   * Procedure Name   : get_svd_data
   * Description      : ����VD��[�f�[�^�擾 (A-9)
   ***********************************************************************************/
  PROCEDURE get_svd_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_svd_data'; -- �v���O������
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
    cv_hht_program_div_5          CONSTANT VARCHAR2(1) := '5';        -- ���o�ɼެ��ُ����敪�F���̑����o��
    cn_status_pre                 CONSTANT NUMBER      := 0;          -- �����X�e�[�^�X�F������
    cv_business_low_type_27       CONSTANT VARCHAR2(2) := '27';       -- �Ƒԏ����ށF����VD
    cv_business_low_type_dummy    CONSTANT VARCHAR2(2) := 'XX';       -- �Ƒԏ����ށF�_�~�[
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    CURSOR svd_cur
    IS
      SELECT             
-- == 2010/08/31 V1.3 Added START ===============================================================
              /*+ INDEX(xhit xxcoi_hht_inv_transactions_n04) */
-- == 2010/08/31 V1.3 Added END   ===============================================================
              xhit.rowid                      AS xhit_rowid                 -- ROWID
            , xhit.invoice_no                 AS invoice_no                 -- �`�[No
            , xhit.transaction_id             AS transaction_id             -- ���ɏ��ꎞ�\ID
            , xhit.record_type                AS record_type                -- ���R�[�h���
            , xhit.invoice_type               AS invoice_type               -- �`�[�敪
            , xhit.department_flag            AS department_flag            -- �S�ݓX�t���O
            , xhit.column_no                  AS column_no                  -- �R������  
            , xhit.unit_price                 AS unit_price                 -- �P��
            , xhit.base_code                  AS base_code                  -- ���_�R�[�h
            , xhit.employee_num               AS employee_num               -- �c�ƈ��R�[�h
            , xhit.item_code                  AS item_code                  -- �i�ڃR�[�h
            , xhit.case_in_quantity           AS case_in_quantity           -- ����
            , xhit.case_quantity              AS case_quantity              -- �P�[�X��
            , xhit.quantity                   AS quantity                   -- �{��
            , xhit.total_quantity             AS total_quantity             -- ������
            , xhit.inventory_item_id          AS inventory_item_id          -- �i��ID
            , xhit.primary_uom_code           AS primary_uom_code           -- ��P��
            , xhit.invoice_date               AS invoice_date               -- �`�[���t
            , xhit.outside_subinv_code        AS outside_subinv_code        -- �o�ɑ��ۊǏꏊ
            , xhit.inside_subinv_code         AS inside_subinv_code         -- ���ɑ��ۊǏꏊ
            , xhit.outside_code               AS outside_code               -- �o�ɑ��R�[�h
            , xhit.inside_code                AS inside_code                -- ���ɑ��R�[�h
            , xhit.outside_base_code          AS outside_base_code          -- �o�ɑ����_�R�[�h
            , xhit.inside_base_code           AS inside_base_code           -- ���ɑ����_�R�[�h
            , xhit.outside_business_low_type  AS outside_business_low_type  -- �o�ɑ��Ƒԏ�����
            , xhit.inside_business_low_type   AS inside_business_low_type   -- ���ɑ��Ƒԏ�����
      FROM    
              xxcoi_hht_inv_transactions  xhit                              -- HHT���o�Ɉꎞ�\
      WHERE   
              xhit.hht_program_div = cv_hht_program_div_5                   -- ���o�ɃW���[�i�������敪(5)
      AND     xhit.status          = cn_status_pre                          -- �����X�e�[�^�X(0)
      AND     xhit.consume_vd_flag = cv_flag_y                              -- ����VD��[�Ώۃt���O(Y)
      AND     ( NVL( xhit.outside_business_low_type,cv_business_low_type_dummy ) = cv_business_low_type_27
                OR NVL( xhit.inside_business_low_type,cv_business_low_type_dummy  ) = cv_business_low_type_27 )
      ORDER BY
                xhit.base_code
              , xhit.record_type    
              , xhit.invoice_type   
              , xhit.department_flag
              , xhit.invoice_no
              , xhit.column_no
              , xhit.item_code
      FOR UPDATE NOWAIT;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--  �ϐ��̏�����
    -- =======================
    -- ���o�ɁE�q�փf�[�^�擾
    -- =======================
    -- �J�[�\���I�[�v��
    OPEN svd_cur;
    -- ���R�[�h�ǂݍ���
    FETCH svd_cur BULK COLLECT INTO gt_svd_data_tab;
    -- �Ώی����擾
    gn_target_svd_cnt := gt_svd_data_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE svd_cur;
    -- =======================
    -- 0������
    -- =======================
    IF gn_target_svd_cnt = 0 THEN
    --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_svd_no_data_msg
                    );
      -- 0�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --�G���[���b�Z�[�W
      );
      --
      ov_retcode := cv_status_normal;
      RETURN;
    --
    END IF;
    -- =======================
    -- LOOP����
    -- =======================
    <<svd_data_loop>>
    FOR ln_index IN 1..gn_target_svd_cnt LOOP

        -- ===============================================================
        -- ����VD��[�f�[�^ �Ó����`�F�b�N (A-10)
        -- ===============================================================
        --
        chk_svd_data(
            in_index     => ln_index                 -- ���[�v�J�E���^
          , ov_errbuf    => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode   => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg    => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- ����̏ꍇ
        IF (lv_retcode = cv_status_normal) THEN
        -- ===============================================================
        -- ����VD��[�f�[�^�̈ꎞ�\�ǉ� (A-11)
        -- ===============================================================
          ins_temp_svd_data(
              in_index     => ln_index                 -- ���[�v�J�E���^
            , ov_errbuf    => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode   => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg    => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- ����VD��[�� HHT���o�Ɉꎞ�\�̏����X�e�[�^�X�X�V (A-12)
        -- ===============================================================
          update_xhit_data(
              ir_rowid     => gt_svd_data_tab( ln_index ).xhit_rowid   -- ROWID
            , ov_errbuf    => lv_errbuf                                -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode   => lv_retcode                               -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg    => lv_errmsg                                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
          -- ----------------
          -- ���팏���J�E���g
          -- ----------------
          gn_normal_svd_cnt := gn_normal_svd_cnt + 1;
        --
        -- �x���̏ꍇ
        ELSIF (lv_retcode = cv_status_warn) THEN
        -- ===============================================================
        -- ����VD��[��HHT�G���[���X�g�\�ǉ� (A-13)
        -- ===============================================================
          xxcoi_common_pkg.add_hht_err_list_data(
              iv_base_code           => gt_svd_data_tab( ln_index ).base_code    -- ���_�R�[�h
            , iv_origin_shipment     => gt_svd_data_tab( ln_index ).outside_code -- �o�ɑ��R�[�h
            , iv_data_name           => gt_file_name                             -- �f�[�^����
            , id_transaction_date    => gt_svd_data_tab( ln_index ).invoice_date -- �����
            , iv_entry_number        => gt_svd_data_tab( ln_index ).invoice_no   -- �`�[No
            , iv_party_num           => gt_svd_data_tab( ln_index ).inside_code  -- ���ɑ��R�[�h
            , iv_performance_by_code => gt_svd_data_tab( ln_index ).employee_num -- �c�ƈ��R�[�h
            , iv_item_code           => gt_svd_data_tab( ln_index ).item_code    -- �i�ڃR�[�h
            , iv_error_message       => lv_errmsg                                -- �G���[���e
            , ov_errbuf              => lv_errbuf                                -- �G���[�E���b�Z�[�W
            , ov_retcode             => lv_retcode                               -- ���^�[���E�R�[�h
            , ov_errmsg              => lv_errmsg                                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- HHT���o�Ɉꎞ�\�̃G���[���R�[�h�폜 (A-14)
        -- ===============================================================
          del_xhit_data(
              ir_rowid     => gt_svd_data_tab( ln_index ).xhit_rowid    -- ROWID
            , ov_errbuf    => lv_errbuf                                 -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode   => lv_retcode                                -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg    => lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
          -- ----------------
          -- �x�������J�E���g
          -- ----------------
          gn_warn_svd_cnt := gn_warn_svd_cnt + 1;
        -- �ُ�̏ꍇ
        ELSE
          --
          RAISE global_api_expt;
          --
        END IF;
    --
    END LOOP svd_data_loop;
    -- ===============================================================
    -- ����VD��[�f�[�^�̎��ގ��OIF�ǉ� (A-15)
    -- ===============================================================
    ins_oif_svd_data(
        ov_errbuf    => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- 
    IF (lv_retcode <> cv_status_normal) THEN
      --(�G���[����)
      RAISE global_api_expt;
      --
    END IF;    
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( svd_cur%ISOPEN ) THEN
        CLOSE svd_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_hht_table_lock_err_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_svd_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_item_conv_data
   * Description      : ���i�U�փf�[�^�Ó����`�F�b�N (A-18)
   ***********************************************************************************/
  PROCEDURE chk_item_conv_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item_conv_data'; -- �v���O������
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
    cv_inv_acct_type_item_conv    CONSTANT VARCHAR2(2) := '14';      -- ���o�Ɋ���敪�F���i�U��(14)
    -- *** ���[�J���ϐ� ***
    lv_key_info                            VARCHAR2(500);            -- KEY���
    lb_org_acct_period_flg                 BOOLEAN;                  -- �����݌ɉ�v���ԃI�[�v���t���O
    -- *** ���[�J���E��O ***
    invalid_value_expt                     EXCEPTION;                -- �`�F�b�N��O
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
    -- =========================
    --  1.�݌ɉ�v���ԃ`�F�b�N
    -- =========================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                      -- �݌ɑg�DID
      , id_target_date     => gt_item_conv_data_tab( in_index ).invoice_date  -- �`�[���t
      , ob_chk_result      => lb_org_acct_period_flg                         -- �`�F�b�N����
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
                     , iv_token_value1 => TO_CHAR( gt_item_conv_data_tab( in_index ).invoice_date ,'YYYYMMDD' )
                   );
      RAISE global_api_expt;
    END IF;
    -- �����݌ɉ�v���Ԃ��N���[�Y�̏ꍇ
    IF ( NOT lb_org_acct_period_flg ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_invoice_date_invalid_err
                     , iv_token_name1  => cv_tkn_proc_date
                     , iv_token_value1 => TO_CHAR( gt_item_conv_data_tab( in_index ).invoice_date ,'YYYYMMDD' )
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
    -- =========================
    --  2.����Ȗڕʖ��̎擾 (A-19)
    --  �ϊ���̋��_�R�[�h���擾
    -- =========================
    gt_transaction_source_id := xxcoi_common_pkg.get_disposition_id(
                                     iv_inv_account_kbn    => cv_inv_acct_type_item_conv                            -- ���o�Ɋ���敪 14:���i�U��
                                   , iv_dept_code          => gt_item_conv_data_tab( in_index ).outside_base_code   -- �o�ɑ����_�R�[�h
                                   , in_organization_id    => gt_org_id                                             -- �݌ɑg�DID
                                 );
    --
    IF gt_transaction_source_id IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_get_disposition_id_err_msg
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_item_conv_data_tab( in_index ).outside_base_code
                     , iv_token_name2  => cv_tkn_acct_type
                     , iv_token_value2 => cv_inv_acct_type_item_conv
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �s���l��O�n���h�� ***
    WHEN invalid_value_expt THEN
      -- KEY���擾
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_key_info
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_item_conv_data_tab( in_index ).base_code
                     , iv_token_name2  => cv_tkn_record_type
                     , iv_token_value2 => gt_item_conv_data_tab( in_index ).record_type
                     , iv_token_name3  => cv_tkn_invoice_type
                     , iv_token_value3 => gt_item_conv_data_tab( in_index ).invoice_type
                     , iv_token_name4  => cv_tkn_dept_flag
                     , iv_token_value4 => gt_item_conv_data_tab( in_index ).department_flag
                     , iv_token_name5  => cv_tkn_invoice_no
                     , iv_token_value5 => gt_item_conv_data_tab( in_index ).invoice_no
                     , iv_token_name6  => cv_tkn_column_no
                     , iv_token_value6 => gt_item_conv_data_tab( in_index ).column_no
                     , iv_token_name7  => cv_tkn_item_code
                     , iv_token_value7 => gt_item_conv_data_tab( in_index ).item_code );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
         , buff   => lv_key_info || lv_errmsg );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
         , buff   => lv_key_info || lv_errbuf );
      --
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                             --# �C�� #
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
  END chk_item_conv_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_item_conv_data
   * Description      : ���i�U�փf�[�^�̎��ގ��OIF�ǉ� (A-20)
   ***********************************************************************************/
  PROCEDURE ins_oif_item_conv_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_item_conv_data'; -- �v���O������
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
    cv_new_item                  CONSTANT VARCHAR2(1) := '1';  -- ���i�U�֋敪   1�F�V���i
    cv_old_item                  CONSTANT VARCHAR2(1) := '2';  -- ���i�U�֋敪   2�F�����i
--
    -- *** ���[�J���ϐ� ***
    ln_tran_qty                  mtl_transactions_interface.transaction_quantity%TYPE;   -- �������
    lt_tran_type_id              mtl_transaction_types.transaction_type_id%TYPE;         -- ����^�C�vID
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
--  �ϐ��̏�����
    ln_tran_qty := 0;
    lt_tran_type_id := NULL;
    -- =======================
    -- ����^�C�v/���ʕ�������
    -- =======================
    -- �u���i�U��(�V)�v������
    IF gt_item_conv_data_tab( in_index ).item_convert_div = cv_new_item
          AND SIGN( gt_item_conv_data_tab( in_index ).total_quantity ) = 1
    THEN
      -- ���i�U��(�V)
      lt_tran_type_id := gt_tran_type_id_item_conv_new;
      -- �����(��)
      ln_tran_qty     := gt_item_conv_data_tab( in_index ).total_quantity;
      --
    -- �u���i�U��(�V)�v������
    ELSIF gt_item_conv_data_tab( in_index ).item_convert_div = cv_new_item
          AND SIGN( gt_item_conv_data_tab( in_index ).total_quantity ) = -1
    THEN
      -- ���i�U��(��)
      lt_tran_type_id := gt_tran_type_id_item_conv_old;
      -- �����(��)
      ln_tran_qty     := gt_item_conv_data_tab( in_index ).total_quantity;
      --
    -- �u���i�U��(��)�v������
    ELSIF gt_item_conv_data_tab( in_index ).item_convert_div = cv_old_item
          AND SIGN( gt_item_conv_data_tab( in_index ).total_quantity ) = 1
    THEN
      -- ���i�U��(��)
      lt_tran_type_id := gt_tran_type_id_item_conv_old;
      -- �����(��)
      ln_tran_qty     := gt_item_conv_data_tab( in_index ).total_quantity * (-1);
      --
    -- �u���i�U��(��)�v������
    ELSE
      -- ���i�U��(�V)
      lt_tran_type_id := gt_tran_type_id_item_conv_new;
      -- �����(��)
      ln_tran_qty     := gt_item_conv_data_tab( in_index ).total_quantity * (-1);
      --
    END IF;
    -- =======================
    -- ���ގ��OIF�֓o�^
    -- =======================
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
      , transaction_source_id                                                    -- ����\�[�XID
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
      , gt_item_conv_data_tab( in_index ).transaction_id                         -- �\�[�X�w�b�_�[ID
      , cv_source_line_id                                                        -- �\�[�X���C��ID
      , gt_item_conv_data_tab( in_index ).inventory_item_id                      -- �i��ID
      , gt_org_id                                                                -- �݌ɑg�DID
      , ln_tran_qty                                                              -- �������
      , ln_tran_qty                                                              -- ��P�ʐ���
      , gt_item_conv_data_tab( in_index ).primary_uom_code                       -- ����P��
      , gt_item_conv_data_tab( in_index ).invoice_date                           -- �����
      , gt_item_conv_data_tab( in_index ).outside_subinv_code                    -- �ۊǏꏊ�R�[�h
      , lt_tran_type_id                                                          -- ����^�C�vID
      , NULL                                                                     -- �����ۊǏꏊ�R�[�h
      , NULL                                                                     -- �����݌ɑg�DID
      , gt_transaction_source_id                                                 -- ����\�[�XID
      , gt_item_conv_data_tab( in_index ).invoice_no                             -- �`�[No
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
  END ins_oif_item_conv_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item_conv_data
   * Description      : ���i�U�փf�[�^�擾 (A-17)
   ***********************************************************************************/
  PROCEDURE get_item_conv_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_conv_data'; -- �v���O������
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
    cv_hht_program_div_3          CONSTANT VARCHAR2(1) := '3';        -- ���o�ɼެ��ُ����敪�F���i�U��(3)
    cn_status_pre                 CONSTANT NUMBER := 0;               -- �����X�e�[�^�X�F������(0)
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    CURSOR item_conv_cur
    IS
      SELECT             
-- == 2010/08/31 V1.3 Added START ===============================================================
              /*+ INDEX(xhit xxcoi_hht_inv_transactions_n04) */
-- == 2010/08/31 V1.3 Added END   ===============================================================
              xhit.rowid                      AS xhit_rowid                 -- ROWID
            , xhit.invoice_no                 AS invoice_no                 -- �`�[No
            , xhit.transaction_id             AS transaction_id             -- ���ɏ��ꎞ�\ID
            , xhit.record_type                AS record_type                -- ���R�[�h���
            , xhit.invoice_type               AS invoice_type               -- �`�[�敪
            , xhit.department_flag            AS department_flag            -- �S�ݓX�t���O
            , xhit.column_no                  AS column_no                  -- �R������  
            , xhit.base_code                  AS base_code                  -- ���_�R�[�h
            , xhit.employee_num               AS employee_num               -- �c�ƈ��R�[�h
            , xhit.item_code                  AS item_code                  -- �i�ڃR�[�h
            , xhit.case_in_quantity           AS case_in_quantity           -- ����
            , xhit.case_quantity              AS case_quantity              -- �P�[�X��
            , xhit.quantity                   AS quantity                   -- �{��
            , xhit.total_quantity             AS total_quantity             -- ������
            , xhit.inventory_item_id          AS inventory_item_id          -- �i��ID
            , xhit.primary_uom_code           AS primary_uom_code           -- ��P��
            , xhit.invoice_date               AS invoice_date               -- �`�[���t
            , xhit.outside_subinv_code        AS outside_subinv_code        -- �o�ɑ��ۊǏꏊ
            , xhit.inside_subinv_code         AS inside_subinv_code         -- ���ɑ��ۊǏꏊ
            , xhit.outside_code               AS outside_code               -- �o�ɑ��R�[�h
            , xhit.inside_code                AS inside_code                -- ���ɑ��R�[�h
            , xhit.outside_base_code          AS outside_base_code          -- �o�ɑ����_�R�[�h
            , xhit.inside_base_code           AS inside_base_code           -- ���ɑ����_�R�[�h
            , xhit.item_convert_div           AS item_convert_div           -- ���i�U�֋敪
      FROM    
              xxcoi_hht_inv_transactions  xhit                      -- HHT���o�Ɉꎞ�\
      WHERE   
              xhit.hht_program_div = cv_hht_program_div_3           -- ���o�ɃW���[�i�������敪(3)
      AND     xhit.status          = cn_status_pre                  -- �����X�e�[�^�X
      ORDER BY 
                xhit.base_code
              , xhit.record_type    
              , xhit.invoice_type   
              , xhit.department_flag
              , xhit.invoice_no
              , xhit.column_no
              , xhit.item_code
      FOR UPDATE NOWAIT;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    -- =======================
    -- ���i�U�փf�[�^�擾
    -- =======================
    -- �J�[�\���I�[�v��
    OPEN item_conv_cur;
    -- ���R�[�h�ǂݍ���
    FETCH item_conv_cur BULK COLLECT INTO gt_item_conv_data_tab;
    -- �Ώی����擾
    gn_target_item_conv_cnt := gt_item_conv_data_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE item_conv_cur;
    -- =======================
    -- 0������
    -- =======================
    IF gn_target_item_conv_cnt = 0 THEN
    --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_item_conv_no_data_msg
                    );
      -- 0�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --�G���[���b�Z�[�W
      );
      --
      ov_retcode := cv_status_normal;
      RETURN;
    --
    END IF;
    -- =======================
    -- LOOP����
    -- =======================
    <<item_conv_data_loop>>
    FOR ln_index IN 1..gn_target_item_conv_cnt LOOP
        -- ===============================================================
        -- ���i�U�փf�[�^ �Ó����`�F�b�N (A-18)
        -- ����Ȗڕʖ��̎擾(A-19)
        -- ===============================================================
        --
        chk_item_conv_data(
            in_index     => ln_index                 -- ���[�v�J�E���^
          , ov_errbuf    => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode   => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg    => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- ����̏ꍇ
        IF (lv_retcode = cv_status_normal) THEN
        -- ===============================================================
        -- ���i�U�փf�[�^�̈ꎞ�\�ǉ� (A-20)
        -- ===============================================================
          ins_oif_item_conv_data(
              in_index     => ln_index                 -- ���[�v�J�E���^
            , ov_errbuf    => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode   => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg    => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- ���i�U�ւ� HHT���o�Ɉꎞ�\�̏����X�e�[�^�X�X�V (A-21)
        -- ===============================================================
          update_xhit_data(
              ir_rowid     => gt_item_conv_data_tab( ln_index ).xhit_rowid   -- ROWID
            , ov_errbuf    => lv_errbuf                                -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode   => lv_retcode                               -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg    => lv_errmsg                                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
          -- ----------------
          -- ���팏���J�E���g
          -- ----------------
          gn_normal_item_conv_cnt := gn_normal_item_conv_cnt +1;
        -- �x���̏ꍇ
        ELSIF (lv_retcode = cv_status_warn) THEN
        -- ===============================================================
        -- ���i�U�ւ�HHT�G���[���X�g�\�ǉ� (A-22)
        -- ===============================================================
          xxcoi_common_pkg.add_hht_err_list_data(
              iv_base_code           => gt_item_conv_data_tab( ln_index ).base_code    -- ���_�R�[�h
            , iv_origin_shipment     => gt_item_conv_data_tab( ln_index ).outside_code -- �o�ɑ��R�[�h
            , iv_data_name           => gt_file_name                             -- �f�[�^����
            , id_transaction_date    => gt_item_conv_data_tab( ln_index ).invoice_date -- �����
            , iv_entry_number        => gt_item_conv_data_tab( ln_index ).invoice_no   -- �`�[No
            , iv_party_num           => gt_item_conv_data_tab( ln_index ).inside_code  -- ���ɑ��R�[�h
            , iv_performance_by_code => gt_item_conv_data_tab( ln_index ).employee_num -- �c�ƈ��R�[�h
            , iv_item_code           => gt_item_conv_data_tab( ln_index ).item_code    -- �i�ڃR�[�h
            , iv_error_message       => lv_errmsg                                -- �G���[���e
            , ov_errbuf              => lv_errbuf                                -- �G���[�E���b�Z�[�W
            , ov_retcode             => lv_retcode                               -- ���^�[���E�R�[�h
            , ov_errmsg              => lv_errmsg                                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- HHT���o�Ɉꎞ�\�̃G���[���R�[�h�폜 (A-23)
        -- ===============================================================
          del_xhit_data(
              ir_rowid     => gt_item_conv_data_tab( ln_index ).xhit_rowid    -- ROWID
            , ov_errbuf    => lv_errbuf                                 -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode   => lv_retcode                                -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg    => lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
            --
          END IF;
          -- ----------------
          -- �x�������J�E���g
          -- ----------------
          gn_warn_item_conv_cnt := gn_warn_item_conv_cnt + 1;
        ELSE
          --(�G���[����)
          RAISE global_api_expt;
          --
        END IF;
    --
    END LOOP item_conv_data_loop;
    --
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( item_conv_cur%ISOPEN ) THEN
        CLOSE item_conv_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_hht_table_lock_err_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_item_conv_data;
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    -- *** ���[�J���ϐ� ***
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
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
    -- ���o�ɁE�q�ւ̏�����
    gn_target_inout_kuragae_cnt := 0;
    gn_normal_inout_kuragae_cnt := 0;
    gn_warn_inout_kuragae_cnt   := 0;
    gn_error_inout_kuragae_cnt  := 0;
    -- ����VD�̏�����
    gn_target_svd_cnt  := 0;
    gn_normal_svd_cnt  := 0;
    gn_warn_svd_cnt    := 0;
    gn_error_svd_cnt   := 0;
    gn_oif_ins_svd_cnt := 0;
    -- ���i�U�ւ̏�����
    gn_target_item_conv_cnt := 0;
    gn_normal_item_conv_cnt := 0;
    gn_warn_item_conv_cnt   := 0;
    gn_error_item_conv_cnt  := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===========================================
    -- �������� (A-1)
    -- ===========================================
    init(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
        -- �G���[�����̃J�E���g�A�b�v
        gn_error_cnt := gn_error_cnt + 1;
        -- Init�̃G���[�͏������f
        RAISE global_process_expt;
    END IF;
    --
    --*********************************************
    --***             ���o�ɁE�q��              ***
    --*********************************************
    --
    -- =======================
    -- ���o�ɁE�q�ւ̊J�n����
    -- =======================
    --SAVE POINT1
    SAVEPOINT inout_kuragae_point;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_inout_kuragae_start_msg
                  );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
       , buff   => gv_out_msg );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
       , buff   => gv_out_msg );
    -- ===========================================
    -- ���o�ɁE�q�փf�[�^�擾 (A-2)
    -- ===========================================
    get_inout_kuragae_data(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- ===========================================
    -- ���o�ɁE�q�ւ̏I������ (A-8)
    -- ===========================================
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
        -- ���o�ɁE�q�֏�����ROLLBACK;
        ROLLBACK TO SAVEPOINT inout_kuragae_point;
        -- �ُ폈�������Z�b�g
        gn_error_inout_kuragae_cnt  := 1;
        gn_warn_inout_kuragae_cnt   := 1;
        gn_normal_inout_kuragae_cnt := 0;
        -- �G���[���b�Z�[�W�o��
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
                    ,iv_token_value1 => TO_CHAR(gn_target_inout_kuragae_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_inout_kuragae_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_warn_inout_kuragae_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( gn_error_inout_kuragae_cnt > 0 ) THEN
      lv_message_code := cv_error_msg;
    ELSIF ( gn_warn_inout_kuragae_cnt > 0 ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( gn_target_inout_kuragae_cnt = gn_normal_inout_kuragae_cnt ) THEN
      lv_message_code := cv_normal_msg;
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
    --
    --*********************************************
    --***             ����VD��[                ***
    --*********************************************
    --
    -- =======================
    -- ����VD��[�̊J�n����
    -- =======================
    --SAVE POINT2
    SAVEPOINT svd_point;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_svd_start_msg
                  );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
       , buff   => gv_out_msg );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
       , buff   => gv_out_msg );
    -- ===========================================
    -- ����VD��[�f�[�^�擾 (A-9)
    -- ===========================================
    get_svd_data(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- ===========================================
    -- ����VD��[�̏I������ (A-16)
    -- ===========================================
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
        -- ����VD��[������ROLLBACK;
        ROLLBACK TO SAVEPOINT svd_point;
        -- ���������Z�b�g
        gn_error_svd_cnt  := 1;
        gn_warn_svd_cnt   := 1;
        gn_normal_svd_cnt := 0;
        -- �G���[���b�Z�[�W�o��
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
                    ,iv_token_value1 => TO_CHAR(gn_target_svd_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_svd_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_warn_svd_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --����쐬�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application_short_name
                    ,iv_name         => cv_oif_ins_cnt_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_oif_ins_svd_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�I�����b�Z�[�W
    IF ( gn_error_svd_cnt > 0 ) THEN
      lv_message_code := cv_error_msg;
    ELSIF ( gn_warn_svd_cnt > 0 ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( gn_target_svd_cnt = gn_normal_svd_cnt ) THEN
      lv_message_code := cv_normal_msg;
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
    --
    --*********************************************
    --***              ���i�U��                 ***
    --*********************************************
    --
    -- =======================
    -- ���i�U�ւ̊J�n����
    -- =======================
    --SAVE POINT3
    SAVEPOINT svd_item_conv;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_item_conv_msg
                  );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
       , buff   => gv_out_msg );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
       , buff   => gv_out_msg );
    -- ===========================================
    --  ���i�U�փf�[�^�擾 (A-17)
    -- ===========================================
    get_item_conv_data(
        lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- ===========================================
    -- ���i�U�ւ̏I������ (A-24)
    -- ===========================================
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
        -- ���i�U�֏�����ROLLBACK;
        ROLLBACK TO SAVEPOINT svd_item_conv;
        -- ���������Z�b�g
        gn_error_item_conv_cnt  := 1;
        gn_warn_item_conv_cnt   := 1;
        gn_normal_item_conv_cnt := 0;
        -- �G���[���b�Z�[�W�o��
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
                    ,iv_token_value1 => TO_CHAR(gn_target_item_conv_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_item_conv_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_warn_item_conv_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�I�����b�Z�[�W
    IF ( gn_error_item_conv_cnt > 0 ) THEN
      lv_message_code := cv_error_msg;
    ELSIF ( gn_warn_item_conv_cnt > 0 ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( gn_target_item_conv_cnt = gn_normal_item_conv_cnt ) THEN
      lv_message_code := cv_normal_msg;
    END IF;
    --
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --*********************************************
    --***              �I������                 ***
    --*********************************************
    --
    gn_target_cnt := gn_target_inout_kuragae_cnt + gn_target_svd_cnt + gn_target_item_conv_cnt;
    gn_normal_cnt := gn_normal_inout_kuragae_cnt + gn_normal_svd_cnt + gn_normal_item_conv_cnt;
    gn_error_cnt  := gn_error_inout_kuragae_cnt + gn_error_svd_cnt + gn_error_item_conv_cnt;
    gn_warn_cnt   := gn_warn_inout_kuragae_cnt + gn_warn_svd_cnt + gn_warn_item_conv_cnt;
    --
    -- �ُ픻��(���o�ɁE�q�ցA����VD��[�A���i�U�֋@�\���S�Ĉُ�)
    -- �S��ROLLBACK�Ƃ���
    IF gn_error_cnt = 3 THEN
    --
      ov_retcode := cv_status_error;
    --
    ELSE
    --
        -- �x������
        IF gn_warn_cnt > 0 THEN
          ov_retcode   := cv_status_warn;
          gn_error_cnt := gn_warn_cnt;
        -- ����
        ELSE
          ov_retcode := cv_status_normal;
        END IF;
    --
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- �v
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_end_msg
                  );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
       , buff   => gv_out_msg );
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
END XXCOI003A14C;
/
