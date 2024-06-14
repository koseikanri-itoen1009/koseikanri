CREATE OR REPLACE PACKAGE BODY XXCOI007A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI007A01C(body)
 * Description      : ���ޔz�����̍��z�d�󁦂̐����B���������z(�W������-�c�ƌ���)
 * MD.050           : �����d�󎩓����� MD050_COI_007_A01
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_mtl_txn_acct       ���ޔz�����̒��o (A-2)
 *  del_xwcv_last_data     �������z���[�N�e�[�u���̑O��f�[�^�폜 (A-3)
 *  get_cost_info          �������擾���� (A-4)
 *  ins_xwcv               �������z���[�N�e�[�u���̍쐬 (A-5)
 *  ins_gl_if              �������z���GL-IF�o�^
 *                         - �������z���̒��o (A-6)
 *                         - ��v���ԃ`�F�b�N���� (A-7)
 *                         - GL�C���^�[�t�F�[�X�i�[ (A-8)
 *  ins_gl_if_gr_comp      �I�����Y���GL-IF�o�^(�O���[�v���) (A-10)
 *  ins_gl_if_reg          GL-IF�o�^����(A-11)
 *  ins_xwcv_bk            �݌Ɏ󕥕\�i�f��Ёj�e�[�u���̍쐬 (A-12)
 *  ins_gl_if_round_Journal �ۂߌ덷GL-IF�o�^ (A-13)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������ (A-9)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/14    1.0   T.Kojima        �V�K�쐬
 *  2009/03/26    1.1   H.Sasaki        [��QT1_0120]
 *  2009/05/11    1.2   T.Nakamura      [��QT1_0933]
 *  2009/05/11    1.3   T.Nakamura      [T1_1327]�c�ƌ����X�V���̒����d����������ǉ�
 *  2009/07/14    1.4   S.Moriyama      [0000261]�L���������������p�����[�^�w���or�Ɩ����t�֕ύX
 *                                      ��������O���̏ꍇ�͑O���������L�����Ƃ���
 *  2009/08/17    1.5   N.Abe           [0001089]PT�Ή�
 *  2009/08/25    1.6   H.Sasaki        [0001159]PT�Ή�
 *  2009/09/04    1.7   H.Sasaki        [0001241]����Ȗږ��̐ݒ���e�ύX
 *  2009/09/28    1.8   H.Sasaki        [E_T3_00605]���J�o������������
 *  2010/01/29    1.9   H.Sasaki        [E_�{�ғ�_01335]GL�o�b�`ID�擾�G���[���̃G���[�n���h�����O���C��
 *  2024/03/18    1.10  R.Oikawa        [E_�{�ғ�_19496] �O���[�v��БΉ�
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
  profile_expt        EXCEPTION;    -- �v���t�@�C���l�擾��O
-- == 2009/07/14 V1.4 Added START ===============================================================
  org_code_expt       EXCEPTION;    -- �݌ɑg�D�v���t�@�C���l�擾��O
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
  period_name_expt    EXCEPTION;    -- ��v���Ԗ��擾�G���[
-- == 2009/08/17 V1.5 Added END   ===============================================================
  lock_expt           EXCEPTION;    -- ���b�N������O
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCOI007A01C';     -- �p�b�P�[�W��
  cv_appl_short_name_xxccp   CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
  cv_appl_short_name_xxcoi   CONSTANT VARCHAR2(10)  := 'XXCOI';            -- �A�h�I���F�݌ɗ̈�
  cv_appl_short_name_sqlgl   CONSTANT VARCHAR2(10)  := 'SQLGL';            -- General Ledger
  cv_normal_record           CONSTANT VARCHAR2(1)   := 'Y';                -- �ʏ탌�R�[�h
  cv_error_record            CONSTANT VARCHAR2(1)   := 'N';                -- �G���[���R�[�h
  -- ���b�Z�[�W
  cv_msg_no_prm              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';    -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_msg_profile_get_err     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00032';    -- �v���t�@�C���l�擾�G���[
  cv_msg_group_id_get_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10320';    -- �O���[�vID�擾�G���[
  cv_msg_gl_batch_id_get_err CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10063';    -- GL�o�b�`ID�擾�G���[���b�Z�[�W
  cv_msg_no_data             CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008';    -- �Ώۃf�[�^�������b�Z�[�W
  cv_msg_acct_tbl_chk_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10123';    -- ����Ȗڃe�[�u���`�F�b�N�G���[���b�Z�[�W
  cv_msg_std_cost_get_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10124';    -- �W�������擾�G���[���b�Z�[�W
  cv_msg_oprtn_cost_get_err  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10125';    -- �c�ƌ����擾�G���[���b�Z�[�W
  cv_msg_acctg_period_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10319';    -- ��v���ԃG���[���b�Z�[�W
  cv_msg_lock_err            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10064';    -- ���b�N�G���[���b�Z�[�W�������z���[�N�e�[�u��
  cv_msg_unit_mtl_txn_acct   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10339';    -- ���ޔz�����P�ʌ������b�Z�[�W
  cv_msg_unit_cost_sum       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10340';    -- �������z�W��P�ʌ������b�Z�[�W
-- == 2009/06/04 V1.3 Added START ===============================================================
  cv_msg_code_xxcoi_10256    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-10256';   -- ����^�C�vID�擾�G���[���b�Z�[�W
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
  cv_msg_code_xxcoi_00005    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-00005';   -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_code_xxcoi_10384    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-10384';   -- �p�����[�^�ݒ�L�������b�Z�[�W
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
  cv_msg_code_xxcoi_10399    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-10399';   -- ��v���Ԗ��擾�G���[���b�Z�[�W
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- == 2009/09/28 V1.8 Added START ===============================================================
  cv_msg_code_xxcoi_10405    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-10405';   -- ��v���ԃI�[�v���`�F�b�N�G���[���b�Z�[�W
  cv_msg_code_xxcoi_10406    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-10406';   -- �L�����`�F�b�N�G���[���b�Z�[�W
-- == 2009/09/28 V1.8 Added END   ===============================================================
--
  -- �g�[�N��
  cv_tkn_profile             CONSTANT VARCHAR2(25)  := 'PRO_TOK';                 -- �v���t�@�C����
  cv_tkn_source              CONSTANT VARCHAR2(25)  := 'SOURCE';                  -- �d��\�[�X��
  cv_tkn_account_id          CONSTANT VARCHAR2(25)  := 'ACCOUNT_ID';              -- ����Ȗ�ID
  cv_tkn_account             CONSTANT VARCHAR2(25)  := 'ACCOUNT';                 -- ����Ȗ�
  cv_tkn_item_code           CONSTANT VARCHAR2(25)  := 'ITEM_CODE';               -- �i�ڃR�[�h
  cv_tkn_dept                CONSTANT VARCHAR2(25)  := 'DEPT';                    -- ����
  cv_tkn_period              CONSTANT VARCHAR2(25)  := 'PERIOD';                  -- ��v����
-- == 2009/03/26 V1.1 Added START ===============================================================
  cv_tkn_subacct             CONSTANT VARCHAR2(25)  := 'SUBACCT';                 -- �⏕�ȖڃR�[�h
-- == 2009/03/26 V1.1 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
  cv_date                    CONSTANT VARCHAR2(25)  := 'DATE';                     -- ��v����
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- == 2009/06/04 V1.3 Added START ===============================================================
  cv_tkn_transaction_type    CONSTANT VARCHAR2(30)  := 'TRANSACTION_TYPE_TOK';    -- ����^�C�v
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
  cv_prf_org                 CONSTANT VARCHAR2(25) := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:�݌ɑg�D�R�[�h
  cv_tkn_effective_date      CONSTANT VARCHAR2(25) := 'P_EFFECTIVE_DATE';         -- �ݒ�L����
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/09/28 V1.8 Added START ===============================================================
  cv_tkn_xxcoi_msg_10405     CONSTANT VARCHAR2(30)  :=  'ACCT_PERIOD';            -- ��v���Ԕ�r�Ώۓ��t
-- == 2009/09/28 V1.8 Added END   ===============================================================
-- Ver1.10 ADD START
  cv_prf_aff2_acc_dept_code  CONSTANT VARCHAR2(50)  :=  'XXCOI1_ACCOUT_DEPT_CODE';     -- XXCOI:�o�����p����R�[�h
  cv_prf_gl_category_inv_gr  CONSTANT VARCHAR2(50)  :=  'XXCOI1_GL_CATEGORY_INV_GR';   -- XXCOI:�d��J�e�S��_�݌ɃO���[�v��АU��
  cv_company_profit_rate     CONSTANT VARCHAR2(30)  :=  'XXCOI1_COMPANY_PROFIT_RATE';  -- �e�З��v��
  cv_conv_dept_code          CONSTANT VARCHAR2(30)  :=  'XXCFO1_CONV_DEPT_CODE';       -- ����R�[�h�ϊ�
  cv_conv_cost_dept          CONSTANT VARCHAR2(50)  :=  'XXCFO1_CONV_COST_DEPT';       -- ���㌴���̌v�㕔��
  cv_conv_cost_account       CONSTANT VARCHAR2(50)  :=  'XXCFO1_CONV_COST_ACCOUNT';    -- ���㌴���̊���ȖځE�⏕�ȖڃR�[�h�ϊ�
  cv_msg_code_xxcoi_10750    CONSTANT VARCHAR2(100) :=  'APP-XXCOI1-10750';            -- �Q�ƃ^�C�v�擾�G���[���b�Z�[�W
  cv_msg_code_xxcoi_10751    CONSTANT VARCHAR2(100) :=  'APP-XXCOI1-10751';            -- �O���[�v��ЏW��P�ʌ���
  cv_tkn_lookup_type         CONSTANT VARCHAR2(25)  :=  'LOOKUP_TYPE';                 -- �Q�ƃ^�C�v
  cv_0                       CONSTANT VARCHAR2(1)   :=  '0';                           -- 0
  cv_1                       CONSTANT VARCHAR2(1)   :=  '1';                           -- 1
  cn_transaction_type_118    CONSTANT NUMBER        :=  118;                           -- �H�꒼������
  cn_transaction_type_119    CONSTANT NUMBER        :=  119;                           -- �H�꒼�����ɐU��
  cn_transaction_type_120    CONSTANT NUMBER        :=  120;                           -- �H�꒼���o��
  cn_transaction_type_121    CONSTANT NUMBER        :=  121;                           -- �H�꒼���o�ɐU��
  cv_pkg_name_gr_comp        CONSTANT VARCHAR2(2)   :=  '_2';                          -- �d��(�O���[�v��Зp)
-- Ver1.10 ADD END
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���ޔz�����i�[�p
  TYPE g_mtl_txn_acct_rtype IS RECORD(
      mta_transaction_id         mtl_transaction_accounts.transaction_id%TYPE         --  1.�݌Ɏ��ID
    , gcc_dept_code              gl_code_combinations.segment2%TYPE                   --  2.����R�[�h
    , xwcv_adj_dept_code         gl_code_combinations.segment2%TYPE                   --  3.��������R�[�h
    , mta_account_id             mtl_transaction_accounts.reference_account%TYPE      --  4.����Ȗ�ID
    , gcc_account_code           gl_code_combinations.segment3%TYPE                   --  5.����ȖڃR�[�h
-- == 2009/03/26 V1.1 Added Start ===============================================================
    , gcc_subacct_code           gl_code_combinations.segment4%TYPE                   --  6.�⏕�ȖڃR�[�h
-- == 2009/03/26 V1.1 Added END   ===============================================================
    , mta_inventory_item_id      mtl_transaction_accounts.inventory_item_id%TYPE      --  7.�i��ID
    , msib_item_code             mtl_system_items_b.segment1%TYPE                     --  8.�i�ڃR�[�h
    , mta_transaction_date       mtl_transaction_accounts.transaction_date%TYPE       --  9.�����
    , mta_transaction_value      mtl_transaction_accounts.transaction_value%TYPE      -- 10.������z
    , mta_primary_quantity       mtl_transaction_accounts.primary_quantity%TYPE       -- 11.�������
    , mta_base_transaction_value mtl_transaction_accounts.base_transaction_value%TYPE -- 12.��P�ʋ��z
    , mta_organization_id        mtl_transaction_accounts.organization_id%TYPE        -- 13.�g�DID
    , mta_gl_batch_id            mtl_transaction_accounts.gl_batch_id%TYPE            -- 14.GL�o�b�`ID
-- == 2009/06/04 V1.3 Added Start ===============================================================
    , transaction_type_id        mtl_material_transactions.transaction_type_id%TYPE   -- 15.����^�C�vID
-- == 2009/06/04 V1.3 Added END   ===============================================================
  );
  TYPE g_mtl_txn_acct_ttype IS TABLE OF g_mtl_txn_acct_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_target_sum_cnt              NUMBER;                                              -- �Ώی���  (�������z�W��P��)
  gn_normal_sum_cnt              NUMBER;                                              -- ��������  (�������z�W��P��)
  gn_error_sum_cnt               NUMBER;                                              -- �G���[����(�������z�W��P��)
  gt_gl_set_of_bks_id            gl_interface.set_of_books_id%TYPE;                   -- ��v����ID
  gt_gl_set_of_bks_name          gl_interface.context%TYPE;                           -- ��v���떼
  gt_aff1_company_code           gl_interface.segment1%TYPE;                          -- ��ЃR�[�h
  gt_aff2_adj_dept_code          gl_interface.segment2%TYPE;                          -- ��������R�[�h
  gt_aff3_shizuoka_factory       gl_interface.segment3%TYPE;                          -- ����Ȗ�_�É��H�ꊨ��
  gt_aff4_dummy                  gl_interface.segment4%TYPE;                          -- �⏕�Ȗ�_�_�~�[�l
  gt_aff5_dummy                  gl_interface.segment5%TYPE;                          -- �ڋq�R�[�h_�_�~�[�l
  gt_aff6_dummy                  gl_interface.segment6%TYPE;                          -- ��ƃR�[�h_�_�~�[�l
  gt_aff7_dummy                  gl_interface.segment7%TYPE;                          -- �\���P_�_�~�[�l
  gt_aff8_dummy                  gl_interface.segment8%TYPE;                          -- �\���Q_�_�~�[�l
  gt_je_category_name_inv_cost   gl_interface.user_je_category_name%TYPE;             -- �d��J�e�S����(�݌Ɍ����U��)
  gt_je_source_name_inv_cost     gl_interface.user_je_source_name%TYPE;               -- �d��\�[�X��  (�݌Ɍ����U��)
  gt_sales_calendar              gl_periods.period_set_name%TYPE;                     -- ��v�J�����_
  gt_je_batch_name               gl_interface.reference1%TYPE;                        -- �d��o�b�`��
  gt_group_id                    gl_interface.group_id%TYPE;                          -- �O���[�vID
  gt_last_gl_batch_id            xxcoi_wk_cost_variance.gl_batch_id%TYPE;             -- �O��GL�o�b�`ID
  gt_pre_inventory_item_id       mtl_transaction_accounts.inventory_item_id%TYPE;     -- �O����F�i��ID
  gt_pre_transaction_date        mtl_transaction_accounts.transaction_date%TYPE;      -- �O����F�����
  gt_pre_errbuf_cmpnt_cost       VARCHAR2(1);                                         -- �O����F�W�������擾�G���[�E���b�Z�[�W
  gt_pre_retcode_cmpnt_cost      VARCHAR2(1);                                         -- �O����F�W�������擾���^�[���E�R�[�h
  gt_pre_errbuf_discrete_cost    VARCHAR2(1);                                         -- �O����F�c�ƌ����擾�G���[�E���b�Z�[�W
  gt_pre_retcode_discrete_cost   VARCHAR2(1);                                         -- �O����F�c�ƌ����擾���^�[���E�R�[�h
  g_mtl_txn_acct_tab             g_mtl_txn_acct_ttype;                                -- PL/SQL�\�F���ޔz�����i�[�p
  gn_mtl_txn_acct_cnt            NUMBER;                                              -- PL/SQL�\�C���f�b�N�X
-- == 2009/06/04 V1.3 Added START ===============================================================
  gt_trans_type_std_cost_upd     mtl_transaction_types.transaction_type_id%TYPE;      -- ����^�C�vID�i�W�������X�V�j
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
  gt_effective_date              gl_je_lines.effective_date%TYPE;                     -- �L����
  gt_last_period_date            gl_periods.end_date%TYPE;                            -- �O��v���ԍŏI��
  gt_min_org_acct_date           org_acct_periods.period_start_date%TYPE;             -- �݌ɉ�v���ԃI�[�v���ŌÓ��t
  gt_org_code                    mtl_parameters.organization_code%TYPE;               -- �݌ɑg�D�R�[�h
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
  gt_period_name_tm              gl_periods.period_name%TYPE;                         --��v���Ԗ�(����)
  gt_period_name_lm              gl_periods.period_name%TYPE;                         --��v���Ԗ�(�O��)
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- == 2009/09/04 V1.7 Added START ===============================================================
  gt_aff3_seihin                gl_interface.segment3%TYPE;                          -- ����Ȗ�_���i
  gt_aff3_shouhin               gl_interface.segment3%TYPE;                          -- ����Ȗ�_���i
-- == 2009/09/04 V1.7 Added END   ===============================================================
-- Ver1.10 ADD START
  gt_aff2_acc_dept_code         gl_interface.segment2%TYPE;                          -- �o�����p����R�[�h
  gt_aff2_cost_dept_dr          gl_interface.segment2%TYPE;                          -- ���㌴���̌v�㕔��i�ؕ��j
  gt_aff2_cost_dept_cr          gl_interface.segment2%TYPE;                          -- ���㌴���̌v�㕔��i�ݕ��j
  gt_aff3_cost_account          gl_interface.segment3%TYPE;                          -- ���㌴���̊���Ȗ�
  gt_aff4_cost_sub_acct         gl_interface.segment4%TYPE;                          -- ���㌴���̕⏕�Ȗ�
  gt_aff3_payable               gl_interface.segment3%TYPE;                          -- ����Ȗ�_���|��
  gt_aff4_payable               gl_interface.segment4%TYPE;                          -- �⏕�Ȗ�_���|��
  gt_aff3_rounding_error        gl_interface.segment3%TYPE;                          -- ����Ȗ�_�ۂߌ덷
  gt_aff4_rounding_error        gl_interface.segment4%TYPE;                          -- �⏕�Ȗ�_�ۂߌ덷
  gt_je_category_name_inv_gr    gl_interface.user_je_category_name%TYPE;             -- �d��J�e�S����(�݌ɃO���[�v��АU��)
  gn_target_sum_cnt_gr          NUMBER;                                              -- �Ώی���  (�O���[�v��ЏW��P��)
  gn_error_sum_cnt_gr           NUMBER;                                              -- �G���[����(�O���[�v��ЏW��P��)
-- Ver1.10 ADD END
--
-- == 2009/09/28 V1.8 Added START ===============================================================
  CURSOR mtl_txn_acct_cur
  IS
    SELECT  sub.mta_transaction_id                  --  1.�݌Ɏ��ID
           ,sub.gcc_dept_code                       --  2.����R�[�h
           ,sub.xwcv_adj_dept_code                  --  3.��������R�[�h
           ,sub.mta_account_id                      --  4.����Ȗ�ID
           ,sub.gcc_account_code                    --  5.����ȖڃR�[�h
           ,sub.gcc_subacct_code                    --  6.�⏕�ȖڃR�[�h
           ,sub.mta_inventory_item_id               --  7.�i��ID
           ,sub.msib_item_code                      --  8.�i�ڃR�[�h
           ,sub.mta_transaction_date                --  9.�����
           ,sub.mta_transaction_value               -- 10.������z
           ,sub.mta_primary_quantity                -- 11.�������
           ,sub.mta_base_transaction_value          -- 12.��P�ʋ��z
           ,sub.mta_organization_id                 -- 13.�g�DID
           ,sub.mta_gl_batch_id                     -- 14.GL�o�b�`ID
           ,sub.transaction_type_id                 -- 15.����^�C�vID
           ,sub.data_type                           -- 16.�f�[�^�^�C�v�i1:���ޔz���f�[�^�A2:���J�o���p�f�[�^�j
-- Ver1.10 ADD START
           ,CASE WHEN sub.transaction_type_id IN (cn_transaction_type_118,cn_transaction_type_119,
                                              cn_transaction_type_120,cn_transaction_type_121) THEN  -- �H�꒼������/�o��
                   NVL(sub.company_code, gt_aff1_company_code)
                 ELSE
                   xbdciv.company_code_bd
            END company_code                                  -- 17.��ЃR�[�h
           ,NVL(mtt.attribute6, cv_0) transfer_ownership_flg  -- 18.���L���ړ]����t���O
-- Ver1.10 ADD END
    FROM    (SELECT  /*+ LEADING(MTA) USE_NL(MTA MMT GCC MSIB) */
                     mta.transaction_id              AS mta_transaction_id            --  1
                    ,gcc.segment2                    AS gcc_dept_code                 --  2
                    ,CASE WHEN gcc.segment3 IN(gt_aff3_shizuoka_factory, gt_aff3_seihin, gt_aff3_shouhin) THEN  -- ����ȖڃR�[�h���É��H�ꊨ��̏ꍇ
                            gcc.segment2                                                                        -- ����R�[�h
                          ELSE                                                                                  -- ����ȊO�̏ꍇ
                            gt_aff2_adj_dept_code                                                               -- A-1.�Ŏ擾������������R�[�h
                     END                             AS xwcv_adj_dept_code            --  3
                    ,mta.reference_account           AS mta_account_id                --  4
                    ,gcc.segment3                    AS gcc_account_code              --  5
                    ,gcc.segment4                    AS gcc_subacct_code              --  6
                    ,mta.inventory_item_id           AS mta_inventory_item_id         --  7
                    ,msib.segment1                   AS msib_item_code                --  8
                    ,mta.transaction_date            AS mta_transaction_date          --  9
                    ,mta.transaction_value           AS mta_transaction_value         -- 10
                    ,mta.primary_quantity            AS mta_primary_quantity          -- 11
                    ,mta.base_transaction_value      AS mta_base_transaction_value    -- 12
                    ,mta.organization_id             AS mta_organization_id           -- 13
                    ,mta.gl_batch_id                 AS mta_gl_batch_id               -- 14
                    ,mmt.transaction_type_id         AS transaction_type_id           -- 15
                    ,1                               AS data_type                     -- 16
-- Ver1.10 ADD START
                    ,mmt.attribute7                  AS company_code                  -- 17
-- Ver1.10 ADD END
             FROM    mtl_transaction_accounts        mta                              -- ���ޔz���e�[�u��
                    ,gl_code_combinations            gcc                              -- ����Ȗڃe�[�u��
                    ,mtl_system_items_b              msib                             -- Disc�i�ڃ}�X�^
                    ,mtl_material_transactions       mmt                              -- ���ގ��
             WHERE  mta.reference_account       = gcc.code_combination_id             -- CCID
             AND    mta.gl_batch_id             > gt_last_gl_batch_id                 -- GL�o�b�`ID > �O��GL�o�b�`ID
             AND    msib.inventory_item_id      = mta.inventory_item_id               -- �i��ID
             AND    msib.organization_id        = mta.organization_id                 -- �g�DID
             AND    mta.transaction_id          = mmt.transaction_id                  -- ���ID
             AND    mta.transaction_date        BETWEEN gt_min_org_acct_date AND SYSDATE
             UNION ALL
             SELECT  xwecv.transaction_id            AS mta_transaction_id            --  1
                    ,xwecv.dept_code                 AS gcc_dept_code                 --  2
                    ,xwecv.adj_dept_code             AS xwcv_adj_dept_code            --  3
                    ,xwecv.account_id                AS mta_account_id                --  4
                    ,xwecv.account_code              AS gcc_account_code              --  5
                    ,xwecv.subacct_code              AS gcc_subacct_code              --  6
                    ,xwecv.inventory_item_id         AS mta_inventory_item_id         --  7
                    ,xwecv.item_code                 AS msib_item_code                --  8
                    ,xwecv.transaction_date          AS mta_transaction_date          --  9
                    ,xwecv.transaction_value         AS mta_transaction_value         -- 10
                    ,xwecv.primary_quantity          AS mta_primary_quantity          -- 11
                    ,xwecv.base_transaction_value    AS mta_base_transaction_value    -- 12
                    ,xwecv.organization_id           AS mta_organization_id           -- 13
                    ,xwecv.gl_batch_id               AS mta_gl_batch_id               -- 14
                    ,xwecv.transaction_type_id       AS transaction_type_id           -- 15
                    ,2                               AS data_type                     -- 16
-- Ver1.10 ADD START
                    ,xwecv.company_code              AS company_code                  -- 17
-- Ver1.10 ADD END
             FROM    xxcoi_wk_error_cost_variance    xwecv                            -- �������z���[�N�e�[�u���i�G���[�j
            ) sub
-- Ver1.10 ADD START
            ,xxcfr_bd_dept_comp_info_v xbdciv                              -- ��������Џ��r���[
            ,mtl_transaction_types     mtt                                 -- ����^�C�v�}�X�^
    WHERE  xbdciv.dept_code        = sub.gcc_dept_code                     -- ����
    AND    xbdciv.set_of_books_id  = gt_gl_set_of_bks_id                   -- ��v����ID
    AND    xbdciv.enabled_flag     = 'Y'
    AND    sub.mta_transaction_date BETWEEN NVL( xbdciv.comp_start_date, sub.mta_transaction_date )
                                AND     NVL( xbdciv.comp_end_date, sub.mta_transaction_date )
    AND    mtt.transaction_type_id = sub.transaction_type_id
-- Ver1.10 ADD END
    ORDER BY sub.mta_inventory_item_id                                                -- �i��ID
           , sub.mta_transaction_date;                                                -- �����
  --
  mtl_txn_acct_rec    mtl_txn_acct_cur%ROWTYPE;
-- == 2009/09/28 V1.8 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
-- == 2009/07/14 V1.4 Added START ===============================================================
      iv_effective_date  IN  VARCHAR2      -- �L����
-- == 2009/07/14 V1.4 Added END   ===============================================================
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
    -- �v���t�@�C��
    cv_prf_gl_set_of_bks_id           CONSTANT VARCHAR2(50) := 'GL_SET_OF_BKS_ID';                  -- ��v����ID
    cv_prf_gl_set_of_bks_name         CONSTANT VARCHAR2(50) := 'GL_SET_OF_BKS_NAME';                -- ��v���떼
    cv_prf_company_code               CONSTANT VARCHAR2(50) := 'XXCOI1_COMPANY_CODE';               -- XXCOI:��ЃR�[�h
    cv_prf_aff2_adj_dept_code         CONSTANT VARCHAR2(50) := 'XXCOI1_AFF2_ADJUSTMENT_DEPT_CODE';  -- XXCOI:��������R�[�h
    cv_prf_aff3_shizuoka_factory      CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_SHIZUOKA_FACTORY';      -- XXCOI:����Ȗ�_�É��H�ꊨ��
    cv_prf_aff4_subacct_dummy         CONSTANT VARCHAR2(50) := 'XXCOK1_AFF4_SUBACCT_DUMMY';         -- XXCOK:�⏕�Ȗ�_�_�~�[�l
    cv_prf_aff5_customer_dummy        CONSTANT VARCHAR2(50) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';        -- XXCOK:�ڋq�R�[�h_�_�~�[�l
    cv_prf_aff6_company_dummy         CONSTANT VARCHAR2(50) := 'XXCOK1_AFF6_COMPANY_DUMMY';         -- XXCOK:��ƃR�[�h_�_�~�[�l
    cv_prf_aff7_preliminary1_dummy    CONSTANT VARCHAR2(50) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';    -- XXCOK:�\���P_�_�~�[�l
    cv_prf_aff8_preliminary2_dummy    CONSTANT VARCHAR2(50) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';    -- XXCOK:�\���Q_�_�~�[�l
    cv_prf_gl_category_inv_cost       CONSTANT VARCHAR2(50) := 'XXCOI1_GL_CATEGORY_INV_COST';       -- XXCOI:�d��J�e�S��_�݌Ɍ����U��
    cv_prf_gl_source_inv_cost         CONSTANT VARCHAR2(50) := 'XXCOI1_GL_SOURCE_INV_COST';         -- XXCOI:�d��\�[�X_�݌Ɍ����U��
    cv_prf_sales_calendar             CONSTANT VARCHAR2(50) := 'XXCOI1_SALES_CALENDAR';             -- XXCOI:��v�J�����_
-- == 2009/06/04 V1.3 Added START ===============================================================
    cv_prf_trans_type_std_cost_upd    CONSTANT VARCHAR2(50) := 'XXCOI1_TRANS_TYPE_STD_COST_UPD';    -- XXCOI:����^�C�v��_�W�������X�V
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/09/04 V1.7 Added START ===============================================================
    cv_prf_aff3_seihin                CONSTANT VARCHAR2(30) :=  'XXCOI1_AFF3_SEIHIN';               -- XXCOI:����Ȗ�_���i
    cv_prf_aff3_shouhin               CONSTANT VARCHAR2(30) :=  'XXCOI1_AFF3_SHOUHIN';              -- XXCOI:����Ȗ�_���i
-- == 2009/09/04 V1.7 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
    cv_flag_n                          CONSTANT VARCHAR2(1)  := 'N';                                -- �t���O�l�FN
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- Ver1.10 ADD START
    cv_prf_aff3_payable               CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_PAYABLE';               -- XXCOI:����Ȗ�_���|��
    cv_prf_aff4_payable               CONSTANT VARCHAR2(50) := 'XXCOI1_AFF4_PAYABLE';               -- XXCOI:����Ȗ�_���|��
    cv_prf_aff3_rounding_error        CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_ROUNDING_ERROR';        -- XXCOI:����Ȗ�_�ۂߌ덷
    cv_prf_aff4_rounding_error        CONSTANT VARCHAR2(50) := 'XXCOI1_AFF4_ROUNDING_ERROR';        -- XXCOI:�⏕�Ȗ�_�ۂߌ덷
-- Ver1.10 ADD END
--
    -- *** ���[�J���ϐ� ***
    lv_tkn_profile   VARCHAR2(50);  -- �g�[�N���F�v���t�@�C��
-- == 2009/06/04 V1.3 Added START ===============================================================
    lt_std_cost_upd  mtl_transaction_types.transaction_type_name%TYPE;                              -- ����^�C�v���i�W�������X�V�j
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
    lv_effective_date  VARCHAR2(10);                                                                -- �L����
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/09/28 V1.8 Added START ===============================================================
    lb_acctg_period_chk BOOLEAN;                                                                    -- ��v���ԃ`�F�b�N�p TRUE�F�I�[�v��/FALSE�F�N���[�Y
-- == 2009/09/28 V1.8 Added END   ===============================================================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
-- == 2009/07/14 V1.4 Mod START ===============================================================
--    -- ==============================================================
--    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�o��
--    -- ==============================================================
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                      iv_application => cv_appl_short_name_xxccp
--                    , iv_name        => cv_msg_no_prm
--                  );
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcoi
                    , iv_name         => cv_msg_code_xxcoi_10384
                    , iv_token_name1  => cv_tkn_effective_date
                    , iv_token_value1 => SUBSTRB ( iv_effective_date , 1 , 10)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
-- == 2009/07/14 V1.4 Mod END ===============================================================
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
    -- �v���t�@�C���l�擾
    -- ==============================================================
    -- ��v����ID
    gt_gl_set_of_bks_id := fnd_profile.value( cv_prf_gl_set_of_bks_id );
    IF( gt_gl_set_of_bks_id IS NULL ) THEN
      lv_tkn_profile := cv_prf_gl_set_of_bks_id;
      RAISE profile_expt;
    END IF;
--
    -- ��v���떼
    gt_gl_set_of_bks_name := fnd_profile.value( cv_prf_gl_set_of_bks_name );
    IF( gt_gl_set_of_bks_name IS NULL ) THEN
      lv_tkn_profile := cv_prf_gl_set_of_bks_name;
      RAISE profile_expt;
    END IF;
--
    -- ��ЃR�[�h
    gt_aff1_company_code := fnd_profile.value( cv_prf_company_code );
    IF( gt_aff1_company_code IS NULL ) THEN
      lv_tkn_profile := cv_prf_company_code;
      RAISE profile_expt;
    END IF;
--
    -- ��������R�[�h
    gt_aff2_adj_dept_code := fnd_profile.value( cv_prf_aff2_adj_dept_code );
    IF( gt_aff2_adj_dept_code IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff2_adj_dept_code;
      RAISE profile_expt;
    END IF;
--
-- Ver1.10 ADD START
    -- �o�����p����R�[�h
    gt_aff2_acc_dept_code := fnd_profile.value( cv_prf_aff2_acc_dept_code );
    IF( gt_aff2_acc_dept_code IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff2_acc_dept_code;
      RAISE profile_expt;
    END IF;
--
    -- ����Ȗ�_���|��
    gt_aff3_payable := fnd_profile.value( cv_prf_aff3_payable );
    IF( gt_aff3_payable IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff3_payable;
      RAISE profile_expt;
    END IF;
--
    -- �⏕�Ȗ�_���|��
    gt_aff4_payable := fnd_profile.value( cv_prf_aff4_payable );
    IF( gt_aff4_payable IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff4_payable;
      RAISE profile_expt;
    END IF;
--
    -- �d��J�e�S����(�݌ɃO���[�v��АU��)
    gt_je_category_name_inv_gr := fnd_profile.value( cv_prf_gl_category_inv_gr );
    IF( gt_je_category_name_inv_gr IS NULL ) THEN
      lv_tkn_profile := cv_prf_gl_category_inv_gr;
      RAISE profile_expt;
    END IF;
--
    -- ����Ȗ�_�ۂߌ덷
    gt_aff3_rounding_error := fnd_profile.value( cv_prf_aff3_rounding_error );
    IF( gt_aff3_rounding_error IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff3_rounding_error;
      RAISE profile_expt;
    END IF;
--
    -- �⏕�Ȗ�_�ۂߌ덷
    gt_aff4_rounding_error := fnd_profile.value( cv_prf_aff4_rounding_error );
    IF( gt_aff4_rounding_error IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff4_rounding_error;
      RAISE profile_expt;
    END IF;
-- Ver1.10 ADD END
    -- ����Ȗ�_�É��H�ꊨ��
    gt_aff3_shizuoka_factory := fnd_profile.value( cv_prf_aff3_shizuoka_factory );
    IF( gt_aff3_shizuoka_factory IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff3_shizuoka_factory;
      RAISE profile_expt;
    END IF;
--
-- == 2009/03/26 V1.1 Deleted START ===============================================================
    -- �⏕�Ȗ�_�_�~�[�l
--    gt_aff4_dummy := fnd_profile.value( cv_prf_aff4_subacct_dummy );
--    IF( gt_aff4_dummy IS NULL ) THEN
--      lv_tkn_profile := cv_prf_aff4_subacct_dummy;
--      RAISE profile_expt;
--    END IF;
-- == 2009/03/26 V1.1 Deleted END   ===============================================================
--
    -- �ڋq�R�[�h_�_�~�[�l
    gt_aff5_dummy := fnd_profile.value( cv_prf_aff5_customer_dummy );
    IF( gt_aff5_dummy IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff5_customer_dummy;
      RAISE profile_expt;
    END IF;
--
    -- ��ƃR�[�h_�_�~�[�l
    gt_aff6_dummy := fnd_profile.value( cv_prf_aff6_company_dummy );
    IF( gt_aff6_dummy IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff6_company_dummy;
      RAISE profile_expt;
    END IF;
--
    -- �\���P_�_�~�[�l
    gt_aff7_dummy := fnd_profile.value( cv_prf_aff7_preliminary1_dummy );
    IF( gt_aff7_dummy IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff7_preliminary1_dummy;
      RAISE profile_expt;
    END IF;
--
    -- �\���Q_�_�~�[�l
    gt_aff8_dummy := fnd_profile.value( cv_prf_aff8_preliminary2_dummy );
    IF( gt_aff8_dummy IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff8_preliminary2_dummy;
      RAISE profile_expt;
    END IF;
--
    -- �d��J�e�S����(�݌Ɍ����U��)
    gt_je_category_name_inv_cost := fnd_profile.value( cv_prf_gl_category_inv_cost );
    IF( gt_je_category_name_inv_cost IS NULL ) THEN
      lv_tkn_profile := cv_prf_gl_category_inv_cost;
      RAISE profile_expt;
    END IF;
--
    -- �d��\�[�X��(�݌Ɍ����U��)
    gt_je_source_name_inv_cost := fnd_profile.value( cv_prf_gl_source_inv_cost );
    IF( gt_je_source_name_inv_cost IS NULL ) THEN
      lv_tkn_profile := cv_prf_gl_source_inv_cost;
      RAISE profile_expt;
    END IF;
--
    -- ��v�J�����_
    gt_sales_calendar := fnd_profile.value( cv_prf_sales_calendar );
    IF( gt_sales_calendar IS NULL ) THEN
      lv_tkn_profile := cv_prf_sales_calendar;
      RAISE profile_expt;
    END IF;
--
-- == 2009/09/04 V1.7 Added START ===============================================================
    -- ����Ȗ�_���i
    gt_aff3_seihin := fnd_profile.value( cv_prf_aff3_seihin );
    IF( gt_aff3_seihin IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff3_seihin;
      RAISE profile_expt;
    END IF;
--
    -- ����Ȗ�_���i
    gt_aff3_shouhin := fnd_profile.value(cv_prf_aff3_shouhin  );
    IF( gt_aff3_shouhin IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff3_shouhin;
      RAISE profile_expt;
    END IF;
-- == 2009/09/04 V1.7 Added END   ===============================================================
    -- ==============================================================
    -- �d��o�b�`���擾
    -- ==============================================================
    gt_je_batch_name := xxcok_common_pkg.get_batch_name_f( gt_je_category_name_inv_cost );
--
    -- ==============================================================
    -- �O���[�vID�擾
    -- ==============================================================
    SELECT gjs.attribute1 AS group_id
    INTO   gt_group_id
    FROM   gl_je_sources gjs
    WHERE  gjs.user_je_source_name = gt_je_source_name_inv_cost
    AND    gjs.language            = USERENV( 'LANG' )
    ;
    -- �O���[�vID�擾�G���[(�d��\�[�X�o�^�ςŃO���[�vID���o�^�̏ꍇ)
    IF( gt_group_id IS NULL ) THEN
      RAISE NO_DATA_FOUND;
    END IF;
--
    -- ==============================================================
    -- �������z���[�N�e�[�u���̑O��GL�o�b�`ID�擾
    -- ==============================================================
    SELECT MAX( xwcv.gl_batch_id ) AS gl_batch_id
    INTO   gt_last_gl_batch_id
    FROM   xxcoi_wk_cost_variance xwcv
    ;
    -- �O��GL�o�b�`ID�擾�G���[
-- == 2009/09/28 V1.8 Modified START ===============================================================
--    IF( gt_last_gl_batch_id IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name_xxcoi
--                     , iv_name         => cv_msg_gl_batch_id_get_err
--                   );
--      RAISE NO_DATA_FOUND;
--    END IF;
    IF( gt_last_gl_batch_id IS NULL ) THEN
      -- �������z���[�N�e�[�u�����擾����Ȃ��ꍇ�́A�G���[�e�[�u�����擾
      SELECT MAX( xwecv.gl_batch_id ) AS gl_batch_id
      INTO   gt_last_gl_batch_id
      FROM   xxcoi_wk_error_cost_variance xwecv
      ;
      IF( gt_last_gl_batch_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcoi
                       , iv_name         => cv_msg_gl_batch_id_get_err
                     );
-- == 2010/01/29 V1.9 Modified START ===============================================================
--        RAISE NO_DATA_FOUND;
        RAISE global_api_expt;
-- == 2010/01/29 V1.9 Modified END   ===============================================================
      END IF;
    END IF;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
--
    -- ==============================================================
    -- �W�������X�V�̎���^�C�vID�擾
    -- ==============================================================
-- == 2009/06/04 V1.3 Added START ===============================================================
    lt_std_cost_upd :=  fnd_profile.value(cv_prf_trans_type_std_cost_upd);
    --
    IF (lt_std_cost_upd IS NULL) THEN
      lv_tkn_profile := cv_prf_trans_type_std_cost_upd;
      RAISE profile_expt;
    END IF;
    --
    SELECT  mtt.transaction_type_id
    INTO    gt_trans_type_std_cost_upd
    FROM    mtl_transaction_types       mtt
    WHERE   mtt.transaction_type_name   =   lt_std_cost_upd
    AND     TRUNC(SYSDATE)             <=   TRUNC(NVL(mtt.disable_date, SYSDATE));
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
    -- ==============================================================
    -- �݌ɑg�D�R�[�h�擾
    -- ==============================================================
    gt_org_code := fnd_profile.value( cv_prf_org );
    IF( gt_org_code IS NULL ) THEN
      lv_tkn_profile := cv_prf_org;
      RAISE org_code_expt;
    END IF;
--
    -- ==============================================================
    -- �݌Ɍ����U�֐ݒ�L�����擾
    -- ==============================================================
    lv_effective_date := SUBSTRB(iv_effective_date,1,10);
    gt_effective_date := NVL ( TO_DATE( lv_effective_date ,'YYYY/MM/DD') , TRUNC(xxccp_common_pkg2.get_process_date) );
--
    -- ==============================================================
    -- �O����v���Ԗ����擾
    -- ==============================================================
    SELECT gp.end_date
-- == 2009/08/17 V1.5 Added START ===============================================================
          ,gp.period_name       -- ��v���Ԗ�(�O��)
-- == 2009/08/17 V1.5 Added START ===============================================================
    INTO   gt_last_period_date
-- == 2009/08/17 V1.5 Added START ===============================================================
          ,gt_period_name_lm
-- == 2009/08/17 V1.5 Added START ===============================================================
    FROM   gl_periods gp
    WHERE  gp.period_set_name = gt_sales_calendar
    AND    ADD_MONTHS ( xxccp_common_pkg2.get_process_date , -1 ) BETWEEN gp.start_date AND gp.end_date
    AND    gp.adjustment_period_flag = cv_error_record;
--
    -- ==============================================================
    -- ���ޔz�����o�����p�݌ɉ�v���ԃI�[�v���݌ɓ��t�擾
    -- ==============================================================
    SELECT MIN(oap.period_start_date)
    INTO   gt_min_org_acct_date
    FROM   org_acct_periods oap
    WHERE  oap.organization_id = xxcoi_common_pkg.get_organization_id ( gt_org_code )
    AND    oap.open_flag = cv_normal_record;
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
    BEGIN
      --�����̉�v���Ԗ�
      SELECT gp.period_name
      INTO   gt_period_name_tm
      FROM   gl_periods   gp                                  -- ��v�J�����_
      WHERE  gp.period_set_name         = gt_sales_calendar   -- ��v�J�����_���FSALES_CALENDAR
      AND    gp.adjustment_period_flag  = cv_flag_n           -- �������ԃt���O�FN
      AND    gt_effective_date BETWEEN gp.start_date
                               AND     gp.end_date;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE period_name_expt;
    END;
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- == 2009/09/28 V1.8 Added START ===============================================================
    -- ==================================
    --  �݌ɉ�v���Ԃ�GL��v���ԃ`�F�b�N
    -- ==================================
    lb_acctg_period_chk := xxcok_common_pkg.check_acctg_period_f(
                               gt_gl_set_of_bks_id
                             , gt_min_org_acct_date
                             , cv_appl_short_name_sqlgl
                           );
    -- �݌ɉ�v���Ԃ�OPEN�ŁAGL��v���Ԃ��N���[�Y���Ă���ꍇ�G���[
    IF NOT(lb_acctg_period_chk) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_code_xxcoi_10405
                     , iv_token_name1  => cv_tkn_xxcoi_msg_10405
                     , iv_token_value1 => TO_CHAR(gt_min_org_acct_date, 'YYYY/MM/DD')
                   );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ==================================
    --  �L�����`�F�b�N
    -- ==================================
    lb_acctg_period_chk := xxcok_common_pkg.check_acctg_period_f(
                               gt_gl_set_of_bks_id
                             , gt_effective_date
                             , cv_appl_short_name_sqlgl
                           );
    -- �p�����[�^�L�����ŁAGL��v���Ԃ��N���[�Y���Ă���ꍇ�G���[
    IF NOT(lb_acctg_period_chk) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_code_xxcoi_10406
                     , iv_token_name1  => cv_tkn_xxcoi_msg_10405
                     , iv_token_value1 => TO_CHAR(gt_effective_date, 'YYYY/MM/DD')
                   );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
-- == 2009/09/28 V1.8 Added END   ===============================================================
  EXCEPTION
-- == 2009/08/17 V1.5 Added START ===============================================================
    -- *** ��v���Ԗ��擾��O ***
    WHEN period_name_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_code_xxcoi_10399
                     , iv_token_name1  => cv_date
                     , iv_token_value1 => TO_CHAR(gt_effective_date, 'YYYY/MM')
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
    -- *** �v���t�@�C���l�擾��O ***
    WHEN org_code_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_code_xxcoi_00005
                     , iv_token_name1  => cv_tkn_profile
                     , iv_token_value1 => cv_prf_org
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
-- == 2009/07/14 V1.4 Added END   ===============================================================
    -- *** �v���t�@�C���l�擾��O ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_profile_get_err
                     , iv_token_name1  => cv_tkn_profile
                     , iv_token_value1 => lv_tkn_profile
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** �O���[�vID/�O��GL�o�b�`ID�擾��O ***
    WHEN NO_DATA_FOUND THEN
      -- �O���[�vID�擾�G���[
      IF( gt_group_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcoi
                       , iv_name         => cv_msg_group_id_get_err
                       , iv_token_name1  => cv_tkn_source
                       , iv_token_value1 => gt_je_source_name_inv_cost
                     );
      END IF;
-- == 2009/06/04 V1.3 Added START ===============================================================
      IF( gt_trans_type_std_cost_upd IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcoi
                       , iv_name         => cv_msg_code_xxcoi_10256
                       , iv_token_name1  => cv_tkn_transaction_type
                       , iv_token_value1 => lt_std_cost_upd
                     );
      END IF;
-- == 2009/06/04 V1.3 Added END   ===============================================================
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
-- == 2009/09/28 V1.8 Deleted START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : get_mtl_txn_acct
--   * Description      : ���ޔz�����̒��o (A-2)
--   ***********************************************************************************/
--  PROCEDURE get_mtl_txn_acct(
--      on_mtl_txn_acct_cnt OUT NUMBER        -- �擾����
--    , ov_errbuf           OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
--    , ov_retcode          OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
--    , ov_errmsg           OUT VARCHAR2 )    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_mtl_txn_acct'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���E�J�[�\�� ***
--    -- ���ޔz�����擾
--    CURSOR mtl_txn_acct_cur
--    IS
---- == 2009/08/25 V1.6 Modified START ===============================================================
------ == 2009/07/14 V1.4 Added START ===============================================================
------      SELECT mta.transaction_id          AS mta_transaction_id           --  1.�݌Ɏ��ID
------ == 2009/08/17 V1.5 Modified START ===============================================================
------      SELECT /*+ index(gcc xxcoi_gl_code_combinations_n34) */
----      SELECT /*+ use_nl(mta,gcc,mmt,msib) index(gcc xxcoi_gl_code_combinations_n34) */
------ == 2009/08/17 V1.5 Modified END   ===============================================================
----             mta.transaction_id          AS mta_transaction_id           --  1.�݌Ɏ��ID
------ == 2009/07/14 V1.4 Added End ===============================================================
----           , gcc.segment2                AS gcc_dept_code                --  2.����R�[�h
----           , CASE WHEN gcc.segment3      = gt_aff3_shizuoka_factory THEN --   5.����ȖڃR�[�h���É��H�ꊨ��̏ꍇ
----                    gcc.segment2                                         --     2.����R�[�h
----                  ELSE                                                   --   ����ȊO�̏ꍇ
----                    gt_aff2_adj_dept_code                                --     A-1.�Ŏ擾������������R�[�h
----             END                         AS xwcv_adj_dept_code           --  3.��������R�[�h
----           , mta.reference_account       AS mta_account_id               --  4.����Ȗ�ID
----           , gcc.segment3                AS gcc_account_code             --  5.����ȖڃR�[�h
------ == 2009/03/26 V1.1 Added START ===============================================================
----           , gcc.segment4                AS gcc_subacct_code             --  6.�⏕�ȖڃR�[�h
------ == 2009/03/26 V1.1 Added END   ===============================================================
----           , mta.inventory_item_id       AS mta_inventory_item_id        --  7.�i��ID
----           , msib.segment1               AS msib_item_code               --  8.�i�ڃR�[�h
----           , mta.transaction_date        AS mta_transaction_date         --  9.�����
----           , mta.transaction_value       AS mta_transaction_value        -- 10.������z
----           , mta.primary_quantity        AS mta_primary_quantity         -- 11.�������
----           , mta.base_transaction_value  AS mta_base_transaction_value   -- 12.��P�ʋ��z
----           , mta.organization_id         AS mta_organization_id          -- 13.�g�DID
----           , mta.gl_batch_id             AS mta_gl_batch_id              -- 14.GL�o�b�`ID
------ == 2009/06/04 V1.3 Added START ===============================================================
----           , mmt.transaction_type_id     AS transaction_type_id          -- 15.����^�C�vID
------ == 2009/06/04 V1.3 Added END   ===============================================================
----      FROM   mtl_transaction_accounts    mta                             -- ���ޔz���e�[�u��
----           , gl_code_combinations        gcc                             -- ����Ȗڃe�[�u��
----           , mtl_system_items_b          msib                            -- Disc�i�ڃ}�X�^
------ == 2009/06/04 V1.3 Added START ===============================================================
----           ,mtl_material_transactions    mmt                             -- ���ގ��
------ == 2009/06/04 V1.3 Added END   ===============================================================
----      WHERE  mta.reference_account       = gcc.code_combination_id       -- CCID
----      AND    mta.gl_batch_id             > gt_last_gl_batch_id           -- GL�o�b�`ID > �O��GL�o�b�`ID
----      AND    msib.inventory_item_id      = mta.inventory_item_id         -- �i��ID
----      AND    msib.organization_id        = mta.organization_id           -- �g�DID
------ == 2009/06/04 V1.3 Added START ===============================================================
----      AND    mta.transaction_id          = mmt.transaction_id            -- ���ID
------ == 2009/06/04 V1.3 Added END   ===============================================================
------ == 2009/07/14 V1.4 Added START ===============================================================
----      AND    mta.transaction_date        BETWEEN gt_min_org_acct_date AND TRUNC(SYSDATE)
------ == 2009/07/14 V1.4 Added END   ===============================================================
----      ORDER BY mta.inventory_item_id                                     -- �i��ID
----             , mta.transaction_date;                                     -- �����
----
--      SELECT /*+ LEADING(MTA) USE_NL(MTA MMT GCC MSIB) */
--             mta.transaction_id          AS mta_transaction_id           --  1.�݌Ɏ��ID
--           , gcc.segment2                AS gcc_dept_code                --  2.����R�[�h
---- == 2009/09/04 V1.7 Added START ===============================================================
----           , CASE WHEN gcc.segment3      = gt_aff3_shizuoka_factory THEN --   5.����ȖڃR�[�h���É��H�ꊨ��̏ꍇ
--           , CASE WHEN gcc.segment3 IN(gt_aff3_shizuoka_factory, gt_aff3_seihin, gt_aff3_shouhin) THEN --   5.����ȖڃR�[�h���É��H�ꊨ��̏ꍇ
---- == 2009/09/04 V1.7 Added END   ===============================================================
--                    gcc.segment2                                         --     2.����R�[�h
--                  ELSE                                                   --   ����ȊO�̏ꍇ
--                    gt_aff2_adj_dept_code                                --     A-1.�Ŏ擾������������R�[�h
--             END                         AS xwcv_adj_dept_code           --  3.��������R�[�h
--           , mta.reference_account       AS mta_account_id               --  4.����Ȗ�ID
--           , gcc.segment3                AS gcc_account_code             --  5.����ȖڃR�[�h
--           , gcc.segment4                AS gcc_subacct_code             --  6.�⏕�ȖڃR�[�h
--           , mta.inventory_item_id       AS mta_inventory_item_id        --  7.�i��ID
--           , msib.segment1               AS msib_item_code               --  8.�i�ڃR�[�h
--           , mta.transaction_date        AS mta_transaction_date         --  9.�����
--           , mta.transaction_value       AS mta_transaction_value        -- 10.������z
--           , mta.primary_quantity        AS mta_primary_quantity         -- 11.�������
--           , mta.base_transaction_value  AS mta_base_transaction_value   -- 12.��P�ʋ��z
--           , mta.organization_id         AS mta_organization_id          -- 13.�g�DID
--           , mta.gl_batch_id             AS mta_gl_batch_id              -- 14.GL�o�b�`ID
--           , mmt.transaction_type_id     AS transaction_type_id          -- 15.����^�C�vID
--      FROM   mtl_transaction_accounts    mta                             -- ���ޔz���e�[�u��
--           , gl_code_combinations        gcc                             -- ����Ȗڃe�[�u��
--           , mtl_system_items_b          msib                            -- Disc�i�ڃ}�X�^
--           ,mtl_material_transactions    mmt                             -- ���ގ��
--      WHERE  mta.reference_account       = gcc.code_combination_id       -- CCID
--      AND    mta.gl_batch_id             > gt_last_gl_batch_id           -- GL�o�b�`ID > �O��GL�o�b�`ID
--      AND    msib.inventory_item_id      = mta.inventory_item_id         -- �i��ID
--      AND    msib.organization_id        = mta.organization_id           -- �g�DID
--      AND    mta.transaction_id          = mmt.transaction_id            -- ���ID
--      AND    mta.transaction_date        BETWEEN gt_min_org_acct_date AND TRUNC(SYSDATE)
--      ORDER BY mta.inventory_item_id                                     -- �i��ID
--             , mta.transaction_date;                                     -- �����
---- == 2009/08/25 V1.6 Modified END   ===============================================================
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- �J�[�\���I�[�v��
--    OPEN mtl_txn_acct_cur;
--    -- �t�F�b�`
--    FETCH mtl_txn_acct_cur BULK COLLECT INTO g_mtl_txn_acct_tab;
--    -- �擾�����Z�b�g
--    on_mtl_txn_acct_cnt := g_mtl_txn_acct_tab.COUNT;
--    -- �J�[�\���N���[�Y
--    CLOSE mtl_txn_acct_cur;
----
--  EXCEPTION
----
----#################################  �Œ��O������ START   ####################################
----
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END get_mtl_txn_acct;
-- == 2009/09/28 V1.8 Deleted END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : del_xwcv_last_data
   * Description      : �������z���[�N�e�[�u���̑O��f�[�^�폜 (A-3)
   ***********************************************************************************/
  PROCEDURE del_xwcv_last_data(
      ov_errbuf             OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode            OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg             OUT VARCHAR2 )    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_xwcv_last_data'; -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR del_xwcv_tbl_cur
    IS
      -- �������z���[�N�e�[�u���̃��b�N�擾
      SELECT 'X'
      FROM   xxcoi_wk_cost_variance  xwcv             -- �������z���[�N�e�[�u��
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
    -- ���b�N�擾
    OPEN  del_xwcv_tbl_cur;
    CLOSE del_xwcv_tbl_cur;
    -- �������z���[�N�e�[�u���폜 
    DELETE FROM xxcoi_wk_cost_variance  xwcv;
--
  EXCEPTION
    -- *** ���b�N�G���[�n���h�� ***
    WHEN lock_expt THEN
      -- �J�[�\�����I�[�v�����Ă�����N���[�Y
      IF ( del_xwcv_tbl_cur%ISOPEN ) THEN
        CLOSE del_xwcv_tbl_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_msg_lock_err
                    );
      lv_errbuf  := lv_errmsg;
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
      -- �J�[�\�����I�[�v�����Ă�����N���[�Y
      IF ( del_xwcv_tbl_cur%ISOPEN ) THEN
        CLOSE del_xwcv_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_xwcv_last_data;
--
--
  /**********************************************************************************
   * Procedure Name   : get_cost_info
   * Description      : �������擾���� (A-4)
   ***********************************************************************************/
  PROCEDURE get_cost_info(
      ion_standard_cost  IN OUT NUMBER     -- �W������
    , ion_operation_cost IN OUT NUMBER     -- �c�ƌ���
    , ion_cost_variance  IN OUT NUMBER     -- �������z
-- == 2009/09/28 V1.8 Added START ===============================================================
    , ir_txn_acct_rec    IN  mtl_txn_acct_cur%ROWTYPE                      -- ���ޔz�����
-- == 2009/09/28 V1.8 Added END   ===============================================================
    , ov_errbuf          OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode         OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg          OUT VARCHAR2 )    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cost_info'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lv_errbuf_cmpnt_cost     VARCHAR2(1); -- �W�������擾�G���[�E���b�Z�[�W
    lv_retcode_cmpnt_cost    VARCHAR2(1); -- �W�������擾���^�[���E�R�[�h
    lv_errbuf_discrete_cost  VARCHAR2(1); -- �c�ƌ����擾�G���[�E���b�Z�[�W
    lv_retcode_discrete_cost VARCHAR2(1); -- �c�ƌ����擾���^�[���E�R�[�h
    ln_standard_cost         NUMBER;      -- �W������
    ln_operation_cost        NUMBER;      -- �c�ƌ���
    ln_cost_variance         NUMBER;      -- �������z
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���X�e�[�^�X������
    lv_retcode := cv_status_normal;
--
    -- �O����ƕi��/��������Ⴄ�ꍇ�́A�������擾
-- == 2009/09/28 V1.8 Modified START ===============================================================
--    IF       (( gt_pre_inventory_item_id IS NULL )  
--         AND  ( gt_pre_transaction_date  IS NULL ))
--      OR NOT (( gt_pre_inventory_item_id = g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_inventory_item_id )
--         AND  ( gt_pre_transaction_date  = g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date ))
--    THEN
    IF       (( gt_pre_inventory_item_id IS NULL )  
         AND  ( gt_pre_transaction_date  IS NULL ))
      OR NOT (( gt_pre_inventory_item_id = ir_txn_acct_rec.mta_inventory_item_id )
         AND  ( gt_pre_transaction_date  = ir_txn_acct_rec.mta_transaction_date ))
    THEN
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      -- ===============================
      -- �W�������擾
      -- ===============================
-- == 2009/09/28 V1.8 Modified START ===============================================================
--      xxcoi_common_pkg.get_cmpnt_cost(
--          in_item_id      => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_inventory_item_id  -- �i��ID
--        , in_org_id       => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_organization_id    -- �g�DID
--        , id_period_date  => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date   -- �Ώۓ�
--        , ov_cmpnt_cost   => ln_standard_cost                                                 -- �W������
--        , ov_errbuf       => lv_errbuf_cmpnt_cost                                             -- �G���[�E���b�Z�[�W
--        , ov_retcode      => lv_retcode_cmpnt_cost                                            -- ���^�[���R�[�h
--        , ov_errmsg       => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--      );
      xxcoi_common_pkg.get_cmpnt_cost(
          in_item_id      => ir_txn_acct_rec.mta_inventory_item_id  -- �i��ID
        , in_org_id       => ir_txn_acct_rec.mta_organization_id    -- �g�DID
        , id_period_date  => ir_txn_acct_rec.mta_transaction_date   -- �Ώۓ�
        , ov_cmpnt_cost   => ln_standard_cost                                                 -- �W������
        , ov_errbuf       => lv_errbuf_cmpnt_cost                                             -- �G���[�E���b�Z�[�W
        , ov_retcode      => lv_retcode_cmpnt_cost                                            -- ���^�[���R�[�h
        , ov_errmsg       => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      IF ( lv_retcode_cmpnt_cost <> cv_status_normal ) THEN
        ln_standard_cost  := 0;
      END IF;
--
      -- ===============================
      -- �c�ƌ����擾
      -- ===============================
-- == 2009/09/28 V1.8 Modified START ===============================================================
--      xxcoi_common_pkg.get_discrete_cost(
--          in_item_id       => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_inventory_item_id  -- �i��ID
--        , in_org_id        => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_organization_id    -- �g�DID
--        , id_target_date   => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date   -- �Ώۓ�
--        , ov_discrete_cost => ln_operation_cost                                                -- �c�ƌ���
--        , ov_errbuf        => lv_errbuf_discrete_cost                                          -- �G���[�E���b�Z�[�W
--        , ov_retcode       => lv_retcode_discrete_cost                                         -- ���^�[���R�[�h
--        , ov_errmsg        => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--      );
      xxcoi_common_pkg.get_discrete_cost(
          in_item_id       => ir_txn_acct_rec.mta_inventory_item_id  -- �i��ID
        , in_org_id        => ir_txn_acct_rec.mta_organization_id    -- �g�DID
        , id_target_date   => ir_txn_acct_rec.mta_transaction_date   -- �Ώۓ�
        , ov_discrete_cost => ln_operation_cost                                                -- �c�ƌ���
        , ov_errbuf        => lv_errbuf_discrete_cost                                          -- �G���[�E���b�Z�[�W
        , ov_retcode       => lv_retcode_discrete_cost                                         -- ���^�[���R�[�h
        , ov_errmsg        => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      IF   ( lv_retcode_discrete_cost <> cv_status_normal ) 
        OR ( ln_operation_cost IS NULL )
      THEN
        lv_retcode_discrete_cost := cv_status_error;
        ln_operation_cost        := 0;
      END IF;
--
      -- �O����Ɍ����R�[�h���Z�b�g
-- == 2009/09/28 V1.8 Modified START ===============================================================
--      gt_pre_inventory_item_id     := g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_inventory_item_id;
--      gt_pre_transaction_date      := g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date;
      gt_pre_inventory_item_id     := ir_txn_acct_rec.mta_inventory_item_id;
      gt_pre_transaction_date      := ir_txn_acct_rec.mta_transaction_date;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      gt_pre_errbuf_cmpnt_cost     := lv_errbuf_cmpnt_cost;
      gt_pre_retcode_cmpnt_cost    := lv_retcode_cmpnt_cost;
      gt_pre_errbuf_discrete_cost  := lv_errbuf_discrete_cost;
      gt_pre_retcode_discrete_cost := lv_retcode_discrete_cost;
--
    -- �O����ƕi��/������������ꍇ�́A�O������g�p
    ELSE
      -- �O������Z�b�g
      lv_errbuf_cmpnt_cost     := gt_pre_errbuf_cmpnt_cost;
      lv_retcode_cmpnt_cost    := gt_pre_retcode_cmpnt_cost;
      lv_errbuf_discrete_cost  := gt_pre_errbuf_discrete_cost;
      lv_retcode_discrete_cost := gt_pre_retcode_discrete_cost;
      ln_standard_cost         := ion_standard_cost ;
      ln_operation_cost        := ion_operation_cost;
    END IF;
--
    -- �����擾�G���[���b�Z�[�W�o��
    -- �W�������擾�G���[�̏ꍇ
    IF ( lv_retcode_cmpnt_cost = cv_status_error ) THEN
-- == 2009/09/28 V1.8 Modified START ===============================================================
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name_xxcoi
--                     , iv_name         => cv_msg_std_cost_get_err
--                     , iv_token_name1  => cv_tkn_item_code
--                     , iv_token_value1 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).msib_item_code
--                     , iv_token_name2  => cv_tkn_period
--                     , iv_token_value2 => TO_CHAR( g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date, 'YYYY-MM' )
--                     , iv_token_name3  => cv_tkn_dept
--                     , iv_token_value3 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).xwcv_adj_dept_code
--                     , iv_token_name4  => cv_tkn_account
--                     , iv_token_value4 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_account_code
---- == 2009/03/26 V1.1 Added START ===============================================================
--                     , iv_token_name5  => cv_tkn_subacct
--                     , iv_token_value5 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_subacct_code
---- == 2009/03/26 V1.1 Added END   ===============================================================
--                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_std_cost_get_err
                     , iv_token_name1  => cv_tkn_item_code
                     , iv_token_value1 => ir_txn_acct_rec.msib_item_code
                     , iv_token_name2  => cv_tkn_period
                     , iv_token_value2 => TO_CHAR( ir_txn_acct_rec.mta_transaction_date, 'YYYY-MM' )
                     , iv_token_name3  => cv_tkn_dept
                     , iv_token_value3 => ir_txn_acct_rec.xwcv_adj_dept_code
                     , iv_token_name4  => cv_tkn_account
                     , iv_token_value4 => ir_txn_acct_rec.gcc_account_code
                     , iv_token_name5  => cv_tkn_subacct
                     , iv_token_value5 => ir_txn_acct_rec.gcc_subacct_code
                   );
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf_cmpnt_cost, 1, 5000 );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf
      );
      lv_retcode := cv_status_warn;
    END IF;
    -- �c�ƌ����擾�G���[�̏ꍇ
    IF ( lv_retcode_discrete_cost = cv_status_error ) THEN
-- == 2009/09/28 V1.8 Modified START ===============================================================
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name_xxcoi
--                     , iv_name         => cv_msg_oprtn_cost_get_err
--                     , iv_token_name1  => cv_tkn_item_code
--                     , iv_token_value1 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).msib_item_code
--                     , iv_token_name2  => cv_tkn_period
--                     , iv_token_value2 => TO_CHAR( g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date, 'YYYY-MM' )
--                     , iv_token_name3  => cv_tkn_dept
--                     , iv_token_value3 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).xwcv_adj_dept_code
--                     , iv_token_name4  => cv_tkn_account
--                     , iv_token_value4 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_account_code
---- == 2009/03/26 V1.1 Added START ===============================================================
--                     , iv_token_name5  => cv_tkn_subacct
--                     , iv_token_value5 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_subacct_code
---- == 2009/03/26 V1.1 Added END   ===============================================================
--                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_oprtn_cost_get_err
                     , iv_token_name1  => cv_tkn_item_code
                     , iv_token_value1 => ir_txn_acct_rec.msib_item_code
                     , iv_token_name2  => cv_tkn_period
                     , iv_token_value2 => TO_CHAR( ir_txn_acct_rec.mta_transaction_date, 'YYYY-MM' )
                     , iv_token_name3  => cv_tkn_dept
                     , iv_token_value3 => ir_txn_acct_rec.xwcv_adj_dept_code
                     , iv_token_name4  => cv_tkn_account
                     , iv_token_value4 => ir_txn_acct_rec.gcc_account_code
                     , iv_token_name5  => cv_tkn_subacct
                     , iv_token_value5 => ir_txn_acct_rec.gcc_subacct_code
                   );
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf_discrete_cost, 1, 5000 );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf
      );
      lv_retcode := cv_status_warn;
    END IF;
--
    -- �W��/�c�ƌ����擾������
    IF    ( lv_retcode_cmpnt_cost    = cv_status_normal )
      AND ( lv_retcode_discrete_cost = cv_status_normal ) THEN
      -- ===============================
      -- �������z�Z�o
      -- ===============================
-- == 2009/09/28 V1.8 Modified START ===============================================================
---- == 2009/06/04 V1.3 Modified START ===============================================================
----      ln_cost_variance := g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_primary_quantity 
----                            * ( ln_standard_cost - ln_operation_cost );
----
--      IF (g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).transaction_type_id = gt_trans_type_std_cost_upd) THEN
--        -- �������z = ��P�ʋ��z * (-1)
--        ln_cost_variance  :=  ROUND(g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_base_transaction_value * (-1));
--      ELSE
--        -- �������z = ������� * ( �W������ �| �c�ƌ��� ) �i�����_�ȉ��l�̌ܓ��j
--        ln_cost_variance := ROUND(g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_primary_quantity 
--                                    * ( ln_standard_cost - ln_operation_cost ), 0);
--      END IF;
---- == 2009/06/04 V1.3 Modified END   ===============================================================
--    ELSE
--      ln_cost_variance := 0;
--    END IF;
      IF (ir_txn_acct_rec.transaction_type_id = gt_trans_type_std_cost_upd) THEN
        -- �������z = ��P�ʋ��z * (-1)
        ln_cost_variance  :=  ROUND(ir_txn_acct_rec.mta_base_transaction_value * (-1));
      ELSE
        -- �������z = ������� * ( �W������ �| �c�ƌ��� ) �i�����_�ȉ��l�̌ܓ��j
        ln_cost_variance := ROUND(ir_txn_acct_rec.mta_primary_quantity 
                                    * ( ln_standard_cost - ln_operation_cost ), 0);
      END IF;
    ELSE
      ln_cost_variance := 0;
    END IF;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
    -- �߂�l�Z�b�g
    ion_standard_cost  := ln_standard_cost;
    ion_operation_cost := ln_operation_cost;
    ion_cost_variance  := ln_cost_variance;
-- == 2009/03/26 V1.1 Deleted START ===============================================================
    -- ===============================
    -- �K�{���ڃ`�F�b�N����
    -- ===============================
    -- ����R�[�h�Ɗ���ȖڃR�[�h��NULL�`�F�b�N
--    IF   g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_dept_code    IS NULL
--      OR g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_account_code IS NULL 
--    THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name_xxcoi
--                     , iv_name         => cv_msg_acct_tbl_chk_err
--                     , iv_token_name1  => cv_tkn_account_id
--                     , iv_token_value1 => TO_CHAR( g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_account_id )
--                     , iv_token_name2  => cv_tkn_period
--                     , iv_token_value2 => TO_CHAR( g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date, 'YYYY-MM' )
--                     , iv_token_name3  => cv_tkn_dept
--                     , iv_token_value3 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).xwcv_adj_dept_code
--                     , iv_token_name4  => cv_tkn_account
--                     , iv_token_value4 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_account_code
--                   );
--      lv_errbuf := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => lv_errmsg
--      );
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.LOG
--        , buff   => lv_errbuf
--      );
--      lv_retcode := cv_status_warn;
--    END IF;
-- == 2009/03/26 V1.1 Deleted END   ===============================================================
--
    -- ���^�[���E�R�[�h�Z�b�g
    ov_retcode := lv_retcode;
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
  END get_cost_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_xwcv
   * Description      : �������z���[�N�e�[�u���̍쐬 (A-5)
   ***********************************************************************************/
  PROCEDURE ins_xwcv(
      in_standard_cost  IN  NUMBER        -- �W������
    , in_operation_cost IN  NUMBER        -- �c�ƌ���
    , in_cost_variance  IN  NUMBER        -- �������z
    , iv_status         IN  VARCHAR2      -- �X�e�[�^�X
-- == 2009/09/28 V1.8 Added START ===============================================================
    , ir_txn_acct_rec   IN  mtl_txn_acct_cur%ROWTYPE                      -- ���ޔz�����
-- == 2009/09/28 V1.8 Added END   ===============================================================
    , ov_errbuf         OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2 )    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xwcv'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
-- Ver1.10 ADD START
    lv_group_company_flg         xxcoi_wk_cost_variance.group_company_flg%TYPE;       -- �O���[�v��Ѓt���O
-- Ver1.10 ADD END
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- == 2009/09/28 V1.8 Modified START ===============================================================
--    -- �������z���[�N�e�[�u���}������
--    INSERT INTO xxcoi_wk_cost_variance(
--        transaction_id                                                       --  1.�݌Ɏ��ID
--      , dept_code                                                            --  2.����R�[�h
--      , adj_dept_code                                                        --  3.��������R�[�h
--      , account_code                                                         --  4.����ȖڃR�[�h
---- == 2009/03/26 V1.1 Added Start ===============================================================
--      , subacct_code                                                         --  5.�⏕�ȖڃR�[�h
---- == 2009/03/26 V1.1 Added END   ===============================================================
--      , inventory_item_id                                                    --  6.�i��ID
--      , transaction_date                                                     --  7.�����
--      , transaction_value                                                    --  8.������z
--      , primary_quantity                                                     --  9.�������
--      , base_transaction_value                                               -- 10.��P�ʋ��z
--      , organization_id                                                      -- 11.�g�DID
--      , gl_batch_id                                                          -- 12.GL�o�b�`ID
--      , standard_cost                                                        -- 13.�W������
--      , operation_cost                                                       -- 14.�c�ƌ���
--      , cost_variance                                                        -- 15.�������z
--      , status                                                               -- 16.�X�e�[�^�X
--      , created_by                                                           -- 17.�쐬��
--      , creation_date                                                        -- 18.�쐬��
--      , last_updated_by                                                      -- 19.�ŏI�X�V��
--      , last_update_date                                                     -- 20.�ŏI�X�V��
--      , last_update_login                                                    -- 21.�ŏI�X�V���O�C��
--      , request_id                                                           -- 22.�v��ID
--      , program_application_id                                               -- 23.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--      , program_id                                                           -- 24.�R���J�����g�E�v���O����ID
--      , program_update_date                                                  -- 25.�v���O�����X�V��
--    ) VALUES (
--        g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_id         --  1.�݌Ɏ��ID
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_dept_code              --  2.����R�[�h
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).xwcv_adj_dept_code         --  3.��������R�[�h
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_account_code           --  4.����ȖڃR�[�h
---- == 2009/03/26 V1.1 Added Start ===============================================================
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_subacct_code           --  5.�⏕�ȖڃR�[�h
---- == 2009/03/26 V1.1 Added END   ===============================================================
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_inventory_item_id      --  6.�i��ID
---- == 2009/07/14 V1.4 Mod Start ===============================================================
----      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date       --  7.�����
--      , CASE WHEN g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date > gt_last_period_date
--        THEN gt_effective_date
--        ELSE gt_last_period_date END                                         --  7.�����
---- == 2009/07/14 V1.4 Mod END   ===============================================================
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_value      --  8.������z
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_primary_quantity       --  9.�������
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_base_transaction_value -- 10.��P�ʋ��z
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_organization_id        -- 11.�g�DID
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_gl_batch_id            -- 12.GL�o�b�`ID
--      , in_standard_cost                                                     -- 13.�W������
--      , in_operation_cost                                                    -- 14.�c�ƌ���
--      , in_cost_variance                                                     -- 15.�������z
--      , iv_status                                                            -- 16.�X�e�[�^�X
--      , cn_created_by                                                        -- 17.�쐬��
--      , SYSDATE                                                              -- 18.�쐬��
--      , cn_last_updated_by                                                   -- 19.�ŏI�X�V��
--      , SYSDATE                                                              -- 20.�ŏI�X�V��
--      , cn_last_update_login                                                 -- 21.�ŏI�X�V���O�C��
--      , cn_request_id                                                        -- 22.�v��ID
--      , cn_program_application_id                                            -- 23.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--      , cn_program_id                                                        -- 24.�R���J�����g�E�v���O����ID
--      , SYSDATE                                                              -- 25.�v���O�����X�V��
--    );
--
-- Ver1.10 ADD START
    -- �O���[�v��Д���
    IF ( ir_txn_acct_rec.company_code = gt_aff1_company_code ) THEN
      lv_group_company_flg := cv_0;
    ELSE
      lv_group_company_flg := cv_1;
    END IF;
-- Ver1.10 ADD END
    IF (iv_status = cv_error_record AND ir_txn_acct_rec.data_type = 1)  THEN
      -- �G���[�f�[�^�ŁA���ޔz�����̏ꍇ
      INSERT INTO xxcoi_wk_error_cost_variance(
        transaction_id                                    -- 01.�݌Ɏ��ID
       ,dept_code                                         -- 02.����R�[�h
       ,adj_dept_code                                     -- 03.��������R�[�h
       ,account_id                                        -- 04.����Ȗ�ID
       ,account_code                                      -- 05.����ȖڃR�[�h
       ,subacct_code                                      -- 06.�⏕�ȖڃR�[�h
       ,inventory_item_id                                 -- 07.�i��ID
       ,item_code                                         -- 08.�i�ڃR�[�h
       ,transaction_date                                  -- 09.�����
       ,transaction_value                                 -- 10.������z
       ,primary_quantity                                  -- 11.�������
       ,base_transaction_value                            -- 12.��P�ʋ��z
       ,organization_id                                   -- 13.�g�DID
       ,gl_batch_id                                       -- 14.GL�o�b�`ID
       ,transaction_type_id                               -- 15.����^�C�vID
       ,standard_cost                                     -- 16.�W������
       ,operation_cost                                    -- 17.�c�ƌ���
       ,cost_variance                                     -- 18.�������z
       ,status                                            -- 19.�X�e�[�^�X
       ,created_by                                        -- 20.�쐬��
       ,creation_date                                     -- 21.�쐬��
       ,last_updated_by                                   -- 22.�ŏI�X�V��
       ,last_update_date                                  -- 23.�ŏI�X�V��
       ,last_update_login                                 -- 24.�ŏI�X�V���O�C��
       ,request_id                                        -- 25.�v��ID
       ,program_application_id                            -- 26.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                                        -- 27.�R���J�����g�E�v���O����ID
       ,program_update_date                               -- 28.�v���O�����X�V��
-- Ver1.10 ADD START
       ,company_code                                      -- 29.��ЃR�[�h
       ,group_company_flg                                 -- 30.�O���[�v��Ѓt���O
       ,transfer_ownership_flg                            -- 31.���L���ړ]����t���O
-- Ver1.10 ADD END
      )VALUES(
        ir_txn_acct_rec.mta_transaction_id                -- 01
       ,ir_txn_acct_rec.gcc_dept_code                     -- 02
       ,ir_txn_acct_rec.xwcv_adj_dept_code                -- 03
       ,ir_txn_acct_rec.mta_account_id                    -- 04
       ,ir_txn_acct_rec.gcc_account_code                  -- 05
       ,ir_txn_acct_rec.gcc_subacct_code                  -- 06
       ,ir_txn_acct_rec.mta_inventory_item_id             -- 07
       ,ir_txn_acct_rec.msib_item_code                    -- 08
       ,CASE WHEN ir_txn_acct_rec.mta_transaction_date > gt_last_period_date
          THEN gt_effective_date
          ELSE gt_last_period_date
        END                                               -- 09
       ,ir_txn_acct_rec.mta_transaction_value             -- 10
       ,ir_txn_acct_rec.mta_primary_quantity              -- 11
       ,ir_txn_acct_rec.mta_base_transaction_value        -- 12
       ,ir_txn_acct_rec.mta_organization_id               -- 13
       ,ir_txn_acct_rec.mta_gl_batch_id                   -- 14
       ,ir_txn_acct_rec.transaction_type_id               -- 15
       ,in_standard_cost                                  -- 16
       ,in_operation_cost                                 -- 17
       ,in_cost_variance                                  -- 18
       ,iv_status                                         -- 19
       ,cn_created_by                                     -- 20
       ,SYSDATE                                           -- 21
       ,cn_last_updated_by                                -- 22
       ,SYSDATE                                           -- 23
       ,cn_last_update_login                              -- 24
       ,cn_request_id                                     -- 25
       ,cn_program_application_id                         -- 26
       ,cn_program_id                                     -- 27
       ,SYSDATE                                           -- 28
-- Ver1.10 ADD START
       ,ir_txn_acct_rec.company_code                      -- 29
       ,lv_group_company_flg                              -- 30
       ,ir_txn_acct_rec.transfer_ownership_flg            -- 31
-- Ver1.10 ADD END
      );
      --
    ELSIF (iv_status <> cv_error_record)  THEN
      -- ����f�[�^�̏ꍇ
      -- �������z���[�N�e�[�u���}������
      INSERT INTO xxcoi_wk_cost_variance(
          transaction_id                                  --  1.�݌Ɏ��ID
        , dept_code                                       --  2.����R�[�h
        , adj_dept_code                                   --  3.��������R�[�h
        , account_code                                    --  4.����ȖڃR�[�h
        , subacct_code                                    --  5.�⏕�ȖڃR�[�h
        , inventory_item_id                               --  6.�i��ID
        , transaction_date                                --  7.�����
        , transaction_value                               --  8.������z
        , primary_quantity                                --  9.�������
        , base_transaction_value                          -- 10.��P�ʋ��z
        , organization_id                                 -- 11.�g�DID
        , gl_batch_id                                     -- 12.GL�o�b�`ID
        , standard_cost                                   -- 13.�W������
        , operation_cost                                  -- 14.�c�ƌ���
        , cost_variance                                   -- 15.�������z
        , status                                          -- 16.�X�e�[�^�X
        , created_by                                      -- 17.�쐬��
        , creation_date                                   -- 18.�쐬��
        , last_updated_by                                 -- 19.�ŏI�X�V��
        , last_update_date                                -- 20.�ŏI�X�V��
        , last_update_login                               -- 21.�ŏI�X�V���O�C��
        , request_id                                      -- 22.�v��ID
        , program_application_id                          -- 23.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                                      -- 24.�R���J�����g�E�v���O����ID
        , program_update_date                             -- 25.�v���O�����X�V��
-- Ver1.10 ADD START
        , company_code                                    -- 26.��ЃR�[�h
        , transaction_type_id                             -- 27.����^�C�vID
        , group_company_flg                               -- 28.�O���[�v��Ѓt���O
        , transfer_ownership_flg                          -- 29.���L���ړ]����t���O
        , reverse_flg                                     -- 30.���]�t���O
-- Ver1.10 ADD END
      ) VALUES (
          ir_txn_acct_rec.mta_transaction_id              --  1.�݌Ɏ��ID
        , ir_txn_acct_rec.gcc_dept_code                   --  2.����R�[�h
        , ir_txn_acct_rec.xwcv_adj_dept_code              --  3.��������R�[�h
        , ir_txn_acct_rec.gcc_account_code                --  4.����ȖڃR�[�h
        , ir_txn_acct_rec.gcc_subacct_code                --  5.�⏕�ȖڃR�[�h
        , ir_txn_acct_rec.mta_inventory_item_id           --  6.�i��ID
        , CASE WHEN ir_txn_acct_rec.mta_transaction_date > gt_last_period_date
            THEN gt_effective_date
            ELSE gt_last_period_date
          END                                             --  7.�����
        , ir_txn_acct_rec.mta_transaction_value           --  8.������z
        , ir_txn_acct_rec.mta_primary_quantity            --  9.�������
        , ir_txn_acct_rec.mta_base_transaction_value      -- 10.��P�ʋ��z
        , ir_txn_acct_rec.mta_organization_id             -- 11.�g�DID
        , ir_txn_acct_rec.mta_gl_batch_id                 -- 12.GL�o�b�`ID
        , in_standard_cost                                -- 13.�W������
        , in_operation_cost                               -- 14.�c�ƌ���
        , in_cost_variance                                -- 15.�������z
        , iv_status                                       -- 16.�X�e�[�^�X
        , cn_created_by                                   -- 17.�쐬��
        , SYSDATE                                         -- 18.�쐬��
        , cn_last_updated_by                              -- 19.�ŏI�X�V��
        , SYSDATE                                         -- 20.�ŏI�X�V��
        , cn_last_update_login                            -- 21.�ŏI�X�V���O�C��
        , cn_request_id                                   -- 22.�v��ID
        , cn_program_application_id                       -- 23.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , cn_program_id                                   -- 24.�R���J�����g�E�v���O����ID
        , SYSDATE                                         -- 25.�v���O�����X�V��
-- Ver1.10 ADD START
        , ir_txn_acct_rec.company_code                    -- 26.��ЃR�[�h
        , ir_txn_acct_rec.transaction_type_id             -- 27.����^�C�vID
        , lv_group_company_flg                            -- 28.�O���[�v��Ѓt���O
        , ir_txn_acct_rec.transfer_ownership_flg          -- 29.���L���ړ]����t���O
        , cv_0                                            -- 30.���]�t���O
-- Ver1.10 ADD END
      );
      --
-- Ver1.10 ADD START
      -- �ɓ����ȊO�͐ԃf�[�^�쐬
      IF ( ir_txn_acct_rec.company_code <> gt_aff1_company_code ) THEN
        INSERT INTO xxcoi_wk_cost_variance(
            transaction_id                                  --  1.�݌Ɏ��ID
          , dept_code                                       --  2.����R�[�h
          , adj_dept_code                                   --  3.��������R�[�h
          , account_code                                    --  4.����ȖڃR�[�h
          , subacct_code                                    --  5.�⏕�ȖڃR�[�h
          , inventory_item_id                               --  6.�i��ID
          , transaction_date                                --  7.�����
          , transaction_value                               --  8.������z
          , primary_quantity                                --  9.�������
          , base_transaction_value                          -- 10.��P�ʋ��z
          , organization_id                                 -- 11.�g�DID
          , gl_batch_id                                     -- 12.GL�o�b�`ID
          , standard_cost                                   -- 13.�W������
          , operation_cost                                  -- 14.�c�ƌ���
          , cost_variance                                   -- 15.�������z
          , status                                          -- 16.�X�e�[�^�X
          , created_by                                      -- 17.�쐬��
          , creation_date                                   -- 18.�쐬��
          , last_updated_by                                 -- 19.�ŏI�X�V��
          , last_update_date                                -- 20.�ŏI�X�V��
          , last_update_login                               -- 21.�ŏI�X�V���O�C��
          , request_id                                      -- 22.�v��ID
          , program_application_id                          -- 23.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , program_id                                      -- 24.�R���J�����g�E�v���O����ID
          , program_update_date                             -- 25.�v���O�����X�V��
          , company_code                                    -- 26.��ЃR�[�h
          , transaction_type_id                             -- 27.����^�C�vID
          , group_company_flg                               -- 28.�O���[�v��Ѓt���O
          , transfer_ownership_flg                          -- 29.���L���ړ]����t���O
          , reverse_flg                                     -- 30.���]�t���O
        ) VALUES (
            ir_txn_acct_rec.mta_transaction_id              --  1.�݌Ɏ��ID
          , ir_txn_acct_rec.gcc_dept_code                   --  2.����R�[�h
          , ir_txn_acct_rec.xwcv_adj_dept_code              --  3.��������R�[�h
          , ir_txn_acct_rec.gcc_account_code                --  4.����ȖڃR�[�h
          , ir_txn_acct_rec.gcc_subacct_code                --  5.�⏕�ȖڃR�[�h
          , ir_txn_acct_rec.mta_inventory_item_id           --  6.�i��ID
          , CASE WHEN ir_txn_acct_rec.mta_transaction_date > gt_last_period_date
              THEN gt_effective_date
              ELSE gt_last_period_date
            END                                               --  7.�����
          , ir_txn_acct_rec.mta_transaction_value             --  8.������z
          , (ir_txn_acct_rec.mta_primary_quantity * -1)       --  9.�������
          , (ir_txn_acct_rec.mta_base_transaction_value * -1) -- 10.��P�ʋ��z
          , ir_txn_acct_rec.mta_organization_id               -- 11.�g�DID
          , ir_txn_acct_rec.mta_gl_batch_id                   -- 12.GL�o�b�`ID
          , in_standard_cost                                  -- 13.�W������
          , in_operation_cost                                 -- 14.�c�ƌ���
          , (in_cost_variance * -1)                           -- 15.�������z
          , iv_status                                         -- 16.�X�e�[�^�X
          , cn_created_by                                     -- 17.�쐬��
          , SYSDATE                                           -- 18.�쐬��
          , cn_last_updated_by                                -- 19.�ŏI�X�V��
          , SYSDATE                                           -- 20.�ŏI�X�V��
          , cn_last_update_login                              -- 21.�ŏI�X�V���O�C��
          , cn_request_id                                     -- 22.�v��ID
          , cn_program_application_id                         -- 23.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , cn_program_id                                     -- 24.�R���J�����g�E�v���O����ID
          , SYSDATE                                           -- 25.�v���O�����X�V��
          , ir_txn_acct_rec.company_code                      -- 26.��ЃR�[�h
          , ir_txn_acct_rec.transaction_type_id               -- 27.����^�C�vID
          , lv_group_company_flg                              -- 28.�O���[�v��Ѓt���O
          , ir_txn_acct_rec.transfer_ownership_flg            -- 29.���L���ړ]����t���O
          , cv_1                                              -- 30.���]�t���O
        );
      END IF;
-- Ver1.10 ADD END
      IF (ir_txn_acct_rec.data_type = 2) THEN
        -- ���J�o���p�f�[�^�̏ꍇ
        DELETE  xxcoi_wk_error_cost_variance
        WHERE   transaction_id  =   ir_txn_acct_rec.mta_transaction_id;
      END IF;
    END IF;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
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
  END ins_xwcv;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_if
   * Description      : �������z���GL-IF�o�^ (A-6�AA-7�AA-8)
   ***********************************************************************************/
  PROCEDURE ins_gl_if(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_if'; -- �v���O������
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
    cv_flag_n            CONSTANT VARCHAR2(1) := 'N';     -- �t���O�l�FN
    cv_status_new        CONSTANT VARCHAR2(3) := 'NEW';   -- �Œ�l�FNEW
    cv_code_jpy          CONSTANT VARCHAR2(3) := 'JPY';   -- �Œ�l�FJPY
    cv_flag_a            CONSTANT VARCHAR2(1) := 'A';     -- �Œ�l�FA
--
    -- *** ���[�J���ϐ� ***
-- == 2009/09/28 V1.8 Deleted START ===============================================================
--    lb_acctg_period_chk  BOOLEAN;                         -- ��v���ԃ`�F�b�N�p TRUE�F�I�[�v��/FALSE�F�N���[�Y
-- == 2009/09/28 V1.8 Deleted END   ===============================================================
    lt_entered_dr        gl_interface.entered_dr%TYPE;    -- �ؕ����z
    lt_entered_cr        gl_interface.entered_cr%TYPE;    -- �ݕ����z
--
    -- ===============================
    -- �������z���̒��o (A-6)
    -- ===============================
    -- �������z���J�[�\��
    CURSOR xwcv_sum_cur
    IS
-- == 2009/08/17 V1.5 Modified START ===============================================================
--      SELECT   xwcv.adj_dept_code           AS xwcv_adj_dept_code          -- ��������R�[�h
--             , xwcv.account_code            AS xwcv_account_code           -- ����ȖڃR�[�h
---- == 2009/03/26 V1.1 Added START ===============================================================
--             , xwcv.subacct_code            AS xwcv_subacct_code           -- �⏕�ȖڃR�[�h
---- == 2009/03/26 V1.1 Added END   ===============================================================
--             , xwcv.transaction_date        AS xwcv_transaction_date       -- �����
--             , xwcv.gl_batch_id             AS xwcv_gl_batch_id            -- GL�o�b�`ID
--             , SUM( xwcv.cost_variance )    AS xwcv_cost_variance_sum      -- �������z(�W��l)
--             , gp.period_name               AS gp_period_name              -- ��v���Ԗ�
--      FROM     xxcoi_wk_cost_variance       xwcv                           -- �������z���[�N�e�[�u��
--             , gl_periods                   gp                             -- ��v�J�����_�e�[�u��
--      WHERE    xwcv.transaction_date BETWEEN gp.start_date AND gp.end_date -- ��������J�n���ƏI�����̊�
--      AND      gp.period_set_name          = gt_sales_calendar             -- ��v�J�����_���FSALES_CALENDAR
--      AND      gp.adjustment_period_flag   = cv_flag_n                     -- �������ԃt���O�FN
--      AND      xwcv.status                <> cv_error_record               -- �G���[���R�[�h�łȂ�
--      GROUP BY xwcv.adj_dept_code
--             , xwcv.account_code
---- == 2009/03/26 V1.1 Added START ===============================================================
--             , xwcv.subacct_code
---- == 2009/03/26 V1.1 Added END   ===============================================================
--             , xwcv.transaction_date
--             , xwcv.gl_batch_id
--             , gp.period_name
--      HAVING   SUM( xwcv.cost_variance )  <> 0                             -- �������z(�W��l)��0�łȂ�
--      ;
      SELECT   xwcv.adj_dept_code           AS xwcv_adj_dept_code          -- ��������R�[�h
             , xwcv.account_code            AS xwcv_account_code           -- ����ȖڃR�[�h
             , xwcv.subacct_code            AS xwcv_subacct_code           -- �⏕�ȖڃR�[�h
             , xwcv.transaction_date        AS xwcv_transaction_date       -- �����
             , xwcv.gl_batch_id             AS xwcv_gl_batch_id            -- GL�o�b�`ID
             , SUM( xwcv.cost_variance )    AS xwcv_cost_variance_sum      -- �������z(�W��l)
             , NULL                         AS gp_period_name              -- ��v���Ԗ�
      FROM     xxcoi_wk_cost_variance       xwcv                           -- �������z���[�N�e�[�u��
-- == 2009/09/28 V1.8 Deleted START ===============================================================
--      WHERE    xwcv.status                <> cv_error_record               -- �G���[���R�[�h�łȂ�
-- == 2009/09/28 V1.8 Deleted END   ===============================================================
-- Ver1.10 ADD START
      WHERE   xwcv.group_company_flg = cv_0                               -- ��ЁF�ɓ���
-- Ver1.10 ADD END
      GROUP BY xwcv.adj_dept_code
             , xwcv.account_code
             , xwcv.subacct_code
             , xwcv.transaction_date
             , xwcv.gl_batch_id
      ;
-- == 2009/08/17 V1.5 Modified END   ===============================================================
    -- �������z���J�[�\�� ���R�[�h�^
    xwcv_sumr_rec xwcv_sum_cur%ROWTYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    OPEN xwcv_sum_cur;
    LOOP
      FETCH xwcv_sum_cur INTO xwcv_sumr_rec;
      EXIT WHEN xwcv_sum_cur%NOTFOUND; 
--
-- == 2009/08/17 V1.5 Modified START ===============================================================
      IF (xwcv_sumr_rec.xwcv_cost_variance_sum <> 0) THEN
        --�������z(�W��l)��0�łȂ���Έȉ��̏��������{����
        IF (xwcv_sumr_rec.xwcv_transaction_date > gt_last_period_date) THEN
          xwcv_sumr_rec.gp_period_name := gt_period_name_tm;
        ELSE
          xwcv_sumr_rec.gp_period_name := gt_period_name_lm;
        END IF;
-- == 2009/08/17 V1.5 Modified END   ===============================================================
        -- ������
        lt_entered_dr  := NULL;  -- �ؕ����z
        lt_entered_cr  := NULL;  -- �ݕ����z
-- == 2009/09/28 V1.8 Modified START ===============================================================
--        -- ===============================
--        -- ��v���ԃ`�F�b�N���� (A-7)
--        -- ===============================
--        lb_acctg_period_chk := xxcok_common_pkg.check_acctg_period_f(
--                                   gt_gl_set_of_bks_id
--                                 , xwcv_sumr_rec.xwcv_transaction_date
--                                 , cv_appl_short_name_sqlgl
--                               );
--        -- ������̉�v���Ԃ��N���[�Y���Ă����ꍇ
--        IF( lb_acctg_period_chk = FALSE ) THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_appl_short_name_xxcoi
--                         , iv_name         => cv_msg_acctg_period_err
--                         , iv_token_name1  => cv_tkn_period
--                         , iv_token_value1 => xwcv_sumr_rec.gp_period_name
--                         , iv_token_name2  => cv_tkn_dept
--                         , iv_token_value2 => xwcv_sumr_rec.xwcv_adj_dept_code
--                         , iv_token_name3  => cv_tkn_account
--                         , iv_token_value3 => xwcv_sumr_rec.xwcv_account_code
--  -- == 2009/03/26 V1.1 Added START ===============================================================
--                         , iv_token_name4  => cv_tkn_subacct
--                         , iv_token_value4 => xwcv_sumr_rec.xwcv_subacct_code
--  -- == 2009/03/26 V1.1 Added END   ===============================================================
--                       );
--          lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
--          FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--            , buff   => lv_errmsg
--          );
--          FND_FILE.PUT_LINE(
--              which  => FND_FILE.LOG
--            , buff   => lv_errbuf
--          );
--          -- �G���[����(�������z�W��P��)�J�E���g
--          gn_error_sum_cnt := gn_error_sum_cnt + 1;
--        ELSE
--          -- ===============================
--          -- GL�C���^�[�t�F�[�X�i�[ (A-8)
--          -- ===============================
--          -- �������z���{�Ȃ�ؕ����z�ɃZ�b�g
--  -- == 2009/05/11 V1.2 Modified START ===============================================================
--  --        IF xwcv_sumr_rec.xwcv_cost_variance_sum < 0 THEN
--          IF xwcv_sumr_rec.xwcv_cost_variance_sum > 0 THEN
--  -- == 2009/05/11 V1.2 Modified END   ===============================================================
--            lt_entered_dr := ABS( xwcv_sumr_rec.xwcv_cost_variance_sum );
--          -- �������z���|�Ȃ�ݕ����z�ɃZ�b�g
--          ELSE
--            lt_entered_cr := ABS( xwcv_sumr_rec.xwcv_cost_variance_sum );
--          END IF;
--          -- ��ʉ�vOIF�}��(GL�C���^�[�t�F�[�X)
--          INSERT INTO gl_interface(
--              status                                    --  1.�X�e�[�^�X
--            , set_of_books_id                           --  2.��v����ID
--            , accounting_date                           --  3.�d��L�����t
--            , currency_code                             --  4.�ʉ݃R�[�h
--            , date_created                              --  5.�V�K�쐬���t
--            , created_by                                --  6.�V�K�쐬��ID
--            , actual_flag                               --  7.�c���^�C�v
--            , user_je_category_name                     --  8.�d��J�e�S����
--            , user_je_source_name                       --  9.�d��\�[�X��
--            , segment1                                  -- 10.��ЃR�[�h
--            , segment2                                  -- 11.����R�[�h
--            , segment3                                  -- 12.����ȖڃR�[�h
--            , segment4                                  -- 13.�⏕�ȖڃR�[�h
--            , segment5                                  -- 14.�ڋq�R�[�h
--            , segment6                                  -- 15.��ƃR�[�h
--            , segment7                                  -- 16.�\��1
--            , segment8                                  -- 17.�\��2
--            , entered_dr                                -- 18.�ؕ����z
--            , entered_cr                                -- 19.�ݕ����z
--            , reference1                                -- 20.�d��o�b�`��
--            , reference4                                -- 21.�d��
--            , reference21                               -- 22.GL�o�b�`ID
--            , period_name                               -- 23.��v���Ԗ�
--            , group_id                                  -- 24.�O���[�vID
--            , attribute3                                -- 25.�`�[�ԍ�
--            , attribute4                                -- 26.�N�[����R�[�h
--            , attribute5                                -- 27.�`�[���͎�
--            , context                                   -- 28.DFF�R���e�L�X�g
--          ) VALUES (
--              cv_status_new                             --  1.�Œ�l�FNEW
--            , gt_gl_set_of_bks_id                       --  2.�v���t�@�C���l�F��v����ID
--            , xwcv_sumr_rec.xwcv_transaction_date       --  3.�����
--            , cv_code_jpy                               --  4.�Œ�l�FJPY
--            , SYSDATE                                   --  5.�V�X�e�����t
--            , cn_created_by                             --  6.���[�U�[ID
--            , cv_flag_a                                 --  7.�Œ�l�FA
--            , gt_je_category_name_inv_cost              --  8.�v���t�@�C���l�F�݌Ɍ����U��
--            , gt_je_source_name_inv_cost                --  9.�v���t�@�C���l�F�݌Ɍ����U��
--            , gt_aff1_company_code                      -- 10.�v���t�@�C���l�F��ЃR�[�h
--            , xwcv_sumr_rec.xwcv_adj_dept_code          -- 11.��������R�[�h
--            , xwcv_sumr_rec.xwcv_account_code           -- 12.����ȖڃR�[�h
--  -- == 2009/03/26 V1.1 Added START ===============================================================
--  --          , gt_aff4_dummy                             -- 13.�v���t�@�C���l�F�⏕�Ȗ�_�_�~�[�l
--            , xwcv_sumr_rec.xwcv_subacct_code           -- 13.�⏕�ȖڃR�[�h
--  -- == 2009/03/26 V1.1 Added END   ===============================================================
--            , gt_aff5_dummy                             -- 14.�v���t�@�C���l�F�ڋq�R�[�h_�_�~�[�l
--            , gt_aff6_dummy                             -- 15.�v���t�@�C���l�F��ƃR�[�h_�_�~�[�l
--            , gt_aff7_dummy                             -- 16.�v���t�@�C���l�F�\���P_�_�~�[�l
--            , gt_aff8_dummy                             -- 17.�v���t�@�C���l�F�\���Q_�_�~�[�l
--            , lt_entered_dr                             -- 18.�ؕ����z
--            , lt_entered_cr                             -- 19.�ݕ����z
--            , gt_je_batch_name                          -- 20.�d��o�b�`��
--            , cv_pkg_name                               -- 21.�Œ�l�FXCOI007A01C(�v���O�����Z�k��)
--            , TO_CHAR( xwcv_sumr_rec.xwcv_gl_batch_id ) -- 22.GL�o�b�`ID
--            , xwcv_sumr_rec.gp_period_name              -- 23.��v���Ԗ�
--            , gt_group_id                               -- 24.�O���[�vID
--            , TO_CHAR( cn_request_id )                  -- 25.�v��ID
--            , xwcv_sumr_rec.xwcv_adj_dept_code          -- 26.��������R�[�h
--            , TO_CHAR( cn_created_by )                  -- 27.���[�U�[ID
--            , gt_gl_set_of_bks_name                     -- 28.�v���t�@�C���l�F��v���떼
--          );
--          -- ��������(�������z�W��P��)�J�E���g
--          gn_normal_sum_cnt := gn_normal_sum_cnt + 1;
--        END IF;
--
        -- ===============================
        -- GL�C���^�[�t�F�[�X�i�[ (A-8)
        -- ===============================
        -- �������z���{�Ȃ�ؕ����z�ɃZ�b�g
        IF xwcv_sumr_rec.xwcv_cost_variance_sum > 0 THEN
          lt_entered_dr := ABS( xwcv_sumr_rec.xwcv_cost_variance_sum );
        -- �������z���|�Ȃ�ݕ����z�ɃZ�b�g
        ELSE
          lt_entered_cr := ABS( xwcv_sumr_rec.xwcv_cost_variance_sum );
        END IF;
        -- ��ʉ�vOIF�}��(GL�C���^�[�t�F�[�X)
        INSERT INTO gl_interface(
            status                                    --  1.�X�e�[�^�X
          , set_of_books_id                           --  2.��v����ID
          , accounting_date                           --  3.�d��L�����t
          , currency_code                             --  4.�ʉ݃R�[�h
          , date_created                              --  5.�V�K�쐬���t
          , created_by                                --  6.�V�K�쐬��ID
          , actual_flag                               --  7.�c���^�C�v
          , user_je_category_name                     --  8.�d��J�e�S����
          , user_je_source_name                       --  9.�d��\�[�X��
          , segment1                                  -- 10.��ЃR�[�h
          , segment2                                  -- 11.����R�[�h
          , segment3                                  -- 12.����ȖڃR�[�h
          , segment4                                  -- 13.�⏕�ȖڃR�[�h
          , segment5                                  -- 14.�ڋq�R�[�h
          , segment6                                  -- 15.��ƃR�[�h
          , segment7                                  -- 16.�\��1
          , segment8                                  -- 17.�\��2
          , entered_dr                                -- 18.�ؕ����z
          , entered_cr                                -- 19.�ݕ����z
          , reference1                                -- 20.�d��o�b�`��
          , reference4                                -- 21.�d��
          , reference21                               -- 22.GL�o�b�`ID
          , period_name                               -- 23.��v���Ԗ�
          , group_id                                  -- 24.�O���[�vID
          , attribute3                                -- 25.�`�[�ԍ�
          , attribute4                                -- 26.�N�[����R�[�h
          , attribute5                                -- 27.�`�[���͎�
          , context                                   -- 28.DFF�R���e�L�X�g
        ) VALUES (
            cv_status_new                             --  1.�Œ�l�FNEW
          , gt_gl_set_of_bks_id                       --  2.�v���t�@�C���l�F��v����ID
          , xwcv_sumr_rec.xwcv_transaction_date       --  3.�����
          , cv_code_jpy                               --  4.�Œ�l�FJPY
          , SYSDATE                                   --  5.�V�X�e�����t
          , cn_created_by                             --  6.���[�U�[ID
          , cv_flag_a                                 --  7.�Œ�l�FA
          , gt_je_category_name_inv_cost              --  8.�v���t�@�C���l�F�݌Ɍ����U��
          , gt_je_source_name_inv_cost                --  9.�v���t�@�C���l�F�݌Ɍ����U��
          , gt_aff1_company_code                      -- 10.�v���t�@�C���l�F��ЃR�[�h
          , xwcv_sumr_rec.xwcv_adj_dept_code          -- 11.��������R�[�h
          , xwcv_sumr_rec.xwcv_account_code           -- 12.����ȖڃR�[�h
          , xwcv_sumr_rec.xwcv_subacct_code           -- 13.�⏕�ȖڃR�[�h
          , gt_aff5_dummy                             -- 14.�v���t�@�C���l�F�ڋq�R�[�h_�_�~�[�l
          , gt_aff6_dummy                             -- 15.�v���t�@�C���l�F��ƃR�[�h_�_�~�[�l
          , gt_aff7_dummy                             -- 16.�v���t�@�C���l�F�\���P_�_�~�[�l
          , gt_aff8_dummy                             -- 17.�v���t�@�C���l�F�\���Q_�_�~�[�l
          , lt_entered_dr                             -- 18.�ؕ����z
          , lt_entered_cr                             -- 19.�ݕ����z
          , gt_je_batch_name                          -- 20.�d��o�b�`��
          , cv_pkg_name                               -- 21.�Œ�l�FXCOI007A01C(�v���O�����Z�k��)
          , TO_CHAR( xwcv_sumr_rec.xwcv_gl_batch_id ) -- 22.GL�o�b�`ID
          , xwcv_sumr_rec.gp_period_name              -- 23.��v���Ԗ�
          , gt_group_id                               -- 24.�O���[�vID
          , TO_CHAR( cn_request_id )                  -- 25.�v��ID
          , xwcv_sumr_rec.xwcv_adj_dept_code          -- 26.��������R�[�h
          , TO_CHAR( cn_created_by )                  -- 27.���[�U�[ID
          , gt_gl_set_of_bks_name                     -- 28.�v���t�@�C���l�F��v���떼
        );
        -- ��������(�������z�W��P��)�J�E���g
        gn_normal_sum_cnt := gn_normal_sum_cnt + 1;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
-- == 2009/08/17 V1.5 Modified START ===============================================================
      END IF;
-- == 2009/08/17 V1.5 Modified END   ===============================================================
    END LOOP;
    -- �Ώی���(�������z�W��P��)�Z�b�g
    gn_target_sum_cnt := xwcv_sum_cur%ROWCOUNT;
    CLOSE xwcv_sum_cur;
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
      IF ( xwcv_sum_cur%ISOPEN ) THEN
        CLOSE xwcv_sum_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_gl_if;
--
-- Ver1.10 ADD START
  /**********************************************************************************
   * Procedure Name   : ins_gl_if_reg
   * Description      : GL-IF�o�^���� (A-11)
   ***********************************************************************************/
  PROCEDURE ins_gl_if_reg(
    id_accounting_date       IN  DATE,         --   �d��L�����t
    iv_segment1              IN  VARCHAR2,     --   ��ЃR�[�h
    iv_segment2              IN  VARCHAR2,     --   ����R�[�h
    iv_segment3              IN  VARCHAR2,     --   ����ȖڃR�[�h
    iv_segment4              IN  VARCHAR2,     --   �⏕�ȖڃR�[�h
    in_entered_dr            IN  NUMBER,       --   �ؕ����z
    in_entered_cr            IN  NUMBER,       --   �ݕ����z
    iv_reference21           IN  VARCHAR2,     --   GL�o�b�`ID
    iv_period_name           IN  VARCHAR2,     --   ��v���Ԗ�
    iv_user_je_category_name IN  VARCHAR2,     --   �d��J�e�S����
    ov_errbuf                OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode               OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg                OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_if_reg'; -- �v���O������
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
    cv_flag_n            CONSTANT VARCHAR2(1) := 'N';     -- �t���O�l�FN
    cv_status_new        CONSTANT VARCHAR2(3) := 'NEW';   -- �Œ�l�FNEW
    cv_code_jpy          CONSTANT VARCHAR2(3) := 'JPY';   -- �Œ�l�FJPY
    cv_flag_a            CONSTANT VARCHAR2(1) := 'A';     -- �Œ�l�FA
--
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
    -- ��ʉ�vOIF�}��
    INSERT INTO gl_interface(
        status                               --  1.�X�e�[�^�X
      , set_of_books_id                      --  2.��v����ID
      , accounting_date                      --  3.�d��L�����t
      , currency_code                        --  4.�ʉ݃R�[�h
      , date_created                         --  5.�V�K�쐬���t
      , created_by                           --  6.�V�K�쐬��ID
      , actual_flag                          --  7.�c���^�C�v
      , user_je_category_name                --  8.�d��J�e�S����
      , user_je_source_name                  --  9.�d��\�[�X��
      , segment1                             -- 10.��ЃR�[�h
      , segment2                             -- 11.����R�[�h
      , segment3                             -- 12.����ȖڃR�[�h
      , segment4                             -- 13.�⏕�ȖڃR�[�h
      , segment5                             -- 14.�ڋq�R�[�h
      , segment6                             -- 15.��ƃR�[�h
      , segment7                             -- 16.�\��1
      , segment8                             -- 17.�\��2
      , entered_dr                           -- 18.�ؕ����z
      , entered_cr                           -- 19.�ݕ����z
      , reference1                           -- 20.�d��o�b�`��
      , reference4                           -- 21.�d��
      , reference21                          -- 22.GL�o�b�`ID
      , period_name                          -- 23.��v���Ԗ�
      , group_id                             -- 24.�O���[�vID
      , attribute3                           -- 25.�`�[�ԍ�
      , attribute4                           -- 26.�N�[����R�[�h
      , attribute5                           -- 27.�`�[���͎�
      , context                              -- 28.DFF�R���e�L�X�g
    ) VALUES (
        cv_status_new                        --  1.�Œ�l�FNEW
      , gt_gl_set_of_bks_id                  --  2.�v���t�@�C���l�F��v����ID
      , id_accounting_date                   --  3.�����
      , cv_code_jpy                          --  4.�Œ�l�FJPY
      , SYSDATE                              --  5.�V�X�e�����t
      , cn_created_by                        --  6.���[�U�[ID
      , cv_flag_a                            --  7.�Œ�l�FA
      , iv_user_je_category_name             --  8.�d��J�e�S����
      , gt_je_source_name_inv_cost           --  9.�v���t�@�C���l�F�݌Ɍ����U��
      , iv_segment1                          -- 10.��ЃR�[�h
      , iv_segment2                          -- 11.��������R�[�h
      , iv_segment3                          -- 12.����ȖڃR�[�h
      , iv_segment4                          -- 13.�⏕�ȖڃR�[�h
      , gt_aff5_dummy                        -- 14.�v���t�@�C���l�F�ڋq�R�[�h_�_�~�[�l
      , gt_aff6_dummy                        -- 15.�v���t�@�C���l�F��ƃR�[�h_�_�~�[�l
      , gt_aff7_dummy                        -- 16.�v���t�@�C���l�F�\���P_�_�~�[�l
      , gt_aff8_dummy                        -- 17.�v���t�@�C���l�F�\���Q_�_�~�[�l
      , in_entered_dr                        -- 18.�ؕ����z
      , in_entered_cr                        -- 19.�ݕ����z
      , gt_je_batch_name                     -- 20.�d��o�b�`��
      , cv_pkg_name || cv_pkg_name_gr_comp   -- 21.�Œ�l�FXCOI007A01C(�v���O�����Z�k��)
      , iv_reference21                       -- 22.GL�o�b�`ID
      , iv_period_name                       -- 23.��v���Ԗ�
      , gt_group_id                          -- 24.�O���[�vID
      , TO_CHAR( cn_request_id )             -- 25.�v��ID
      , gt_aff2_adj_dept_code                -- 26.��������R�[�h
      , TO_CHAR( cn_created_by )             -- 27.���[�U�[ID
      , gt_gl_set_of_bks_name                -- 28.�v���t�@�C���l�F��v���떼
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
  END ins_gl_if_reg;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_if_gr_comp
   * Description      : �I�����Y���GL-IF�o�^(�O���[�v���) (A-10)
   ***********************************************************************************/
  PROCEDURE ins_gl_if_gr_comp(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_if_gr_comp'; -- �v���O������
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
    cv_flag_n            CONSTANT VARCHAR2(1) := 'N';     -- �t���O�l�FN
    cv_status_new        CONSTANT VARCHAR2(3) := 'NEW';   -- �Œ�l�FNEW
    cv_code_jpy          CONSTANT VARCHAR2(3) := 'JPY';   -- �Œ�l�FJPY
    cv_flag_a            CONSTANT VARCHAR2(1) := 'A';     -- �Œ�l�FA
--
    -- *** ���[�J���ϐ� ***
    lt_entered_dr        gl_interface.entered_dr%TYPE;    -- �ؕ����z
    lt_entered_cr        gl_interface.entered_cr%TYPE;    -- �ݕ����z
    lt_segment2          gl_interface.segment2%TYPE;      -- ����
    lt_segment3          gl_interface.segment3%TYPE;      -- ����Ȗ�
    lt_segment4          gl_interface.segment4%TYPE;      -- �⏕�Ȗ�
--
    -- ===============================
    -- �I�����Y���̒��o
    -- ===============================
    -- �I�����Y�d����J�[�\��
    CURSOR xwcv_sum_gr_cur
    IS
      SELECT
              xwcv2.dept_code                    AS xwcv_dept_code              -- ����R�[�h
            , xwcv2.grcp_adj_dept_code           AS xwcv_grcp_adj_dept_code     -- �ϊ��㒲������R�[�h
            , xwcv2.account_code                 AS xwcv_account_code           -- ����ȖڃR�[�h
            , xwcv2.subacct_code                 AS xwcv_subacct_code           -- �⏕�ȖڃR�[�h
            , xwcv2.transaction_date             AS xwcv_transaction_date       -- �����
            , xwcv2.gl_batch_id                  AS xwcv_gl_batch_id            -- GL�o�b�`ID
            , NULL                               AS gp_period_name              -- ��v���Ԗ�
            , xwcv2.company_code                 AS xwcv_company_code           -- ��ЃR�[�h
            , xwcv2.transfer_ownership_flg       AS transfer_ownership_flg      -- ���L���ړ]����t���O
            , ROUND( SUM( xwcv2.primary_quantity * operation_cost ),0)
                                                 AS sum_amount                  -- �c�ƌ������z
            , ROUND( SUM( xwcv2.primary_quantity * standard_cost ),0)
                                                 AS sum_cost_amount             -- �W���������z
            , ROUND( SUM( xwcv2.primary_quantity *
                ROUND( xwcv2.standard_cost * ( 1 + ( flv.attribute1 / 100 )),2)),0)
                                                 AS sum_purchase_amount         -- �w�����z
      FROM    xxcoi_wk_cost_variance    xwcv2                              -- �������z���[�N�e�[�u��
            , xxcfr_bd_company_info_v   flv                                -- �e�З��v��
      WHERE   xwcv2.group_company_flg = cv_1                               -- 1:�O���[�v���
      AND     xwcv2.reverse_flg       = cv_0                               -- 0:���f�[�^
      AND     flv.lookup_type         = cv_company_profit_rate
      AND     flv.company_code        = xwcv2.company_code
      AND     TRUNC( xwcv2.transaction_date )  BETWEEN NVL( flv.start_date_active, xwcv2.transaction_date )
                                           AND     NVL( flv.end_date_active, xwcv2.transaction_date )
      AND     xwcv2.transaction_type_id <> gt_trans_type_std_cost_upd      -- �W�������X�V�͏���
      GROUP BY xwcv2.dept_code
             , xwcv2.grcp_adj_dept_code
             , xwcv2.account_code
             , xwcv2.subacct_code
             , xwcv2.transaction_date
             , xwcv2.gl_batch_id
             , xwcv2.company_code
             , xwcv2.transfer_ownership_flg
      ;
    -- �I�����Y���J�[�\�� ���R�[�h�^
    xwcv_sumr_gr_rec xwcv_sum_gr_cur%ROWTYPE;
--
    -- ===============================
    -- �W�������X�V���̒��o
    -- ===============================
    -- �W�������X�V���J�[�\��
    CURSOR xwcv_sum_gr_cur2
    IS
      SELECT
              xwcv2.dept_code                    AS xwcv_dept_code              -- ����R�[�h
            , xwcv2.grcp_adj_dept_code           AS xwcv_grcp_adj_dept_code     -- �ϊ��㒲������R�[�h
            , xwcv2.account_code                 AS xwcv_account_code           -- ����ȖڃR�[�h
            , xwcv2.subacct_code                 AS xwcv_subacct_code           -- �⏕�ȖڃR�[�h
            , xwcv2.transaction_date             AS xwcv_transaction_date       -- �����
            , xwcv2.gl_batch_id                  AS xwcv_gl_batch_id            -- GL�o�b�`ID
            , NULL                               AS gp_period_name              -- ��v���Ԗ�
            , xwcv2.company_code                 AS xwcv_company_code           -- ��ЃR�[�h
            , xwcv2.transfer_ownership_flg       AS transfer_ownership_flg      -- ���L���ړ]����t���O
            , ROUND(SUM(xwcv2.base_transaction_value),0)
                                                 AS sum_amount                  -- �c�ƌ������z
      FROM    xxcoi_wk_cost_variance    xwcv2                                -- �������z���[�N�e�[�u��
      WHERE   xwcv2.group_company_flg   = cv_1                               -- 1:�O���[�v���
      AND     xwcv2.reverse_flg         = cv_0                               -- 0:���f�[�^
      AND     xwcv2.transaction_type_id = gt_trans_type_std_cost_upd         -- �W�������X�V
      GROUP BY xwcv2.dept_code
             , xwcv2.grcp_adj_dept_code
             , xwcv2.account_code
             , xwcv2.subacct_code
             , xwcv2.transaction_date
             , xwcv2.gl_batch_id
             , xwcv2.company_code
             , xwcv2.transfer_ownership_flg
      ;
    -- �W�������X�V���J�[�\�� ���R�[�h�^
    xwcv_sumr_gr_rec2 xwcv_sum_gr_cur2%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ============================================================
    -- �O���[�v��ЂƑ΂ɂȂ�d�󂪈ɓ����̏ꍇ�A�O���[�v��ЂƔ���
    -- ============================================================
    -- �O���[�v��Ѓt���O���X�V
    UPDATE xxcoi_wk_cost_variance xwcv
    SET    xwcv.group_company_flg = cv_1   -- 1:�O���[�v���
    WHERE  EXISTS ( SELECT 1
                    FROM   xxcoi_wk_cost_variance xwcv2
                    WHERE  xwcv.transaction_id     = xwcv2.transaction_id
                    AND    xwcv2.group_company_flg = cv_1
                  )
    ;
--
    -- �΂ɂȂ�ɓ����d��̐ԃf�[�^�쐬
    INSERT INTO xxcoi_wk_cost_variance(
        transaction_id                                  --  1.�݌Ɏ��ID
      , dept_code                                       --  2.����R�[�h
      , adj_dept_code                                   --  3.��������R�[�h
      , account_code                                    --  4.����ȖڃR�[�h
      , subacct_code                                    --  5.�⏕�ȖڃR�[�h
      , inventory_item_id                               --  6.�i��ID
      , transaction_date                                --  7.�����
      , transaction_value                               --  8.������z
      , primary_quantity                                --  9.�������
      , base_transaction_value                          -- 10.��P�ʋ��z
      , organization_id                                 -- 11.�g�DID
      , gl_batch_id                                     -- 12.GL�o�b�`ID
      , standard_cost                                   -- 13.�W������
      , operation_cost                                  -- 14.�c�ƌ���
      , cost_variance                                   -- 15.�������z
      , status                                          -- 16.�X�e�[�^�X
      , created_by                                      -- 17.�쐬��
      , creation_date                                   -- 18.�쐬��
      , last_updated_by                                 -- 19.�ŏI�X�V��
      , last_update_date                                -- 20.�ŏI�X�V��
      , last_update_login                               -- 21.�ŏI�X�V���O�C��
      , request_id                                      -- 22.�v��ID
      , program_application_id                          -- 23.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                                      -- 24.�R���J�����g�E�v���O����ID
      , program_update_date                             -- 25.�v���O�����X�V��
      , company_code                                    -- 26.��ЃR�[�h
      , transaction_type_id                             -- 27.����^�C�vID
      , group_company_flg                               -- 28.�O���[�v��Ѓt���O
      , transfer_ownership_flg                          -- 29.���L���ړ]����t���O
      , reverse_flg                                     -- 30.���]�t���O
    )
    SELECT
        xwcv.transaction_id                             --  1.�݌Ɏ��ID
      , xwcv.dept_code                                  --  2.����R�[�h
      , xwcv.adj_dept_code                              --  3.��������R�[�h
      , xwcv.account_code                               --  4.����ȖڃR�[�h
      , xwcv.subacct_code                               --  5.�⏕�ȖڃR�[�h
      , xwcv.inventory_item_id                          --  6.�i��ID
      , xwcv.transaction_date                           --  7.�����
      , xwcv.transaction_value                          --  8.������z
      , (xwcv.primary_quantity * -1)                    --  9.�������
      , (xwcv.base_transaction_value * -1)              -- 10.��P�ʋ��z
      , xwcv.organization_id                            -- 11.�g�DID
      , xwcv.gl_batch_id                                -- 12.GL�o�b�`ID
      , xwcv.standard_cost                              -- 13.�W������
      , xwcv.operation_cost                             -- 14.�c�ƌ���
      , (xwcv.cost_variance * -1)                       -- 15.�������z
      , xwcv.status                                     -- 16.�X�e�[�^�X
      , xwcv.created_by                                 -- 17.�쐬��
      , xwcv.creation_date                              -- 18.�쐬��
      , xwcv.last_updated_by                            -- 19.�ŏI�X�V��
      , xwcv.last_update_date                           -- 20.�ŏI�X�V��
      , xwcv.last_update_login                          -- 21.�ŏI�X�V���O�C��
      , xwcv.request_id                                 -- 22.�v��ID
      , xwcv.program_application_id                     -- 23.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , xwcv.program_id                                 -- 24.�R���J�����g�E�v���O����ID
      , xwcv.program_update_date                        -- 25.�v���O�����X�V��
      , xwcv.company_code                               -- 26.��ЃR�[�h
      , xwcv.transaction_type_id                        -- 27.����^�C�vID
      , xwcv.group_company_flg                          -- 28.�O���[�v��Ѓt���O
      , xwcv.transfer_ownership_flg                     -- 29.���L���ړ]����t���O
      , cv_1                                            -- 30.���]�t���O
    FROM  xxcoi_wk_cost_variance xwcv
    WHERE xwcv.group_company_flg = cv_1
    AND   xwcv.company_code      = gt_aff1_company_code
    ;
--
    -- ============================================================
    -- �O���[�v��Ђ��X�V
    -- ============================================================
    UPDATE xxcoi_wk_cost_variance xwcv
    SET    xwcv.company_code = (SELECT xwcv2.company_code
                                FROM   xxcoi_wk_cost_variance xwcv2
                                WHERE  xwcv.transaction_id    = xwcv2.transaction_id
                                AND    xwcv2.company_code    <> gt_aff1_company_code
                                AND    ROWNUM = 1)
    WHERE  xwcv.group_company_flg = cv_1                  -- 1:�O���[�v���
    AND    xwcv.company_code      = gt_aff1_company_code  -- �ɓ���
    ;
--
    -- ============================================================
    -- �O���[�v��Ђ̒�������ϊ�
    -- ============================================================
    UPDATE xxcoi_wk_cost_variance xwcv
    SET    xwcv.grcp_adj_dept_code = (CASE
                                      WHEN (xwcv.dept_code IN (gt_aff2_adj_dept_code,gt_aff2_acc_dept_code)  ) THEN
                                          (SELECT flv.attribute3
                                           FROM   fnd_lookup_values   flv
                                           WHERE  flv.lookup_type   = cv_conv_dept_code
                                           AND    flv.attribute1    = xwcv.company_code
                                           AND    flv.attribute2    = xwcv.dept_code
                                           AND    flv.language      = USERENV( 'LANG' ))
                                      ELSE
                                        xwcv.dept_code
                                      END)
    WHERE  xwcv.group_company_flg = cv_1      -- 1:�O���[�v���
    ;
--
    -- ====================================
    -- GL�C���^�[�t�F�[�X�i�[(�I�����Y���)
    -- ====================================
    OPEN xwcv_sum_gr_cur;
    LOOP
      FETCH xwcv_sum_gr_cur INTO xwcv_sumr_gr_rec;
      EXIT WHEN xwcv_sum_gr_cur%NOTFOUND; 
--
      IF (xwcv_sumr_gr_rec.sum_amount <> 0) THEN
        --���z��0�łȂ���Έȉ��̏��������{����
        IF (xwcv_sumr_gr_rec.xwcv_transaction_date > gt_last_period_date) THEN
          xwcv_sumr_gr_rec.gp_period_name := gt_period_name_tm;
        ELSE
          xwcv_sumr_gr_rec.gp_period_name := gt_period_name_lm;
        END IF;
--
        -- ������
        lt_entered_dr      := NULL;  -- �ؕ����z
        lt_entered_cr      := NULL;  -- �ݕ����z
--
        -- ���z���{�Ȃ�ؕ����z�ɃZ�b�g
        IF ( xwcv_sumr_gr_rec.sum_amount * -1 ) > 0 THEN
          lt_entered_dr := ABS( xwcv_sumr_gr_rec.sum_amount );
        -- ���z���|�Ȃ�ݕ����z�ɃZ�b�g
        ELSE
          lt_entered_cr := ABS( xwcv_sumr_gr_rec.sum_amount );
        END IF;
--
        -- ===============================
        -- GL-IF�o�^�����i�U��߂��j
        -- ===============================
        ins_gl_if_reg(
            id_accounting_date       => xwcv_sumr_gr_rec.xwcv_transaction_date,        -- �d��L�����t
            iv_segment1              => gt_aff1_company_code,                          -- ��ЃR�[�h
            iv_segment2              => xwcv_sumr_gr_rec.xwcv_dept_code,               -- ����R�[�h
            iv_segment3              => xwcv_sumr_gr_rec.xwcv_account_code,            -- ����ȖڃR�[�h
            iv_segment4              => xwcv_sumr_gr_rec.xwcv_subacct_code,            -- �⏕�ȖڃR�[�h
            in_entered_dr            => lt_entered_dr,                                 -- �ؕ����z
            in_entered_cr            => lt_entered_cr,                                 -- �ݕ����z
            iv_reference21           => TO_CHAR( xwcv_sumr_gr_rec.xwcv_gl_batch_id ),  -- GL�o�b�`ID
            iv_period_name           => xwcv_sumr_gr_rec.gp_period_name,               -- ��v���Ԗ�
            iv_user_je_category_name => gt_je_category_name_inv_gr,                    -- �d��J�e�S����
            ov_errbuf                => lv_errbuf    -- �G���[�E���b�Z�[�W
          , ov_retcode               => lv_retcode   -- ���^�[���E�R�[�h
          , ov_errmsg                => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ���L���ړ]����̏ꍇ
        IF ( xwcv_sumr_gr_rec.transfer_ownership_flg = cv_1 ) THEN
          -- ������
          lt_entered_dr      := NULL;  -- �ؕ����z
          lt_entered_cr      := NULL;  -- �ݕ����z
          lt_segment2        := NULL;  -- ����
          lt_segment3        := NULL;  -- ����Ȗ�
          lt_segment4        := NULL;  -- �⏕�Ȗ�
--
          -- �v�㕔��擾
          BEGIN
            SELECT  flv.attribute1  AS attribute1
                  , flv.attribute2  AS attribute2
            INTO    gt_aff2_cost_dept_dr
                  , gt_aff2_cost_dept_cr
            FROM   fnd_lookup_values   flv
            WHERE  flv.lookup_type   = cv_conv_cost_dept
            AND    flv.language      = USERENV( 'LANG' )
            AND    flv.enabled_flag  = 'Y'
            AND    TRUNC( xwcv_sumr_gr_rec.xwcv_transaction_date )  BETWEEN NVL( flv.start_date_active, xwcv_sumr_gr_rec.xwcv_transaction_date )
                                             AND     NVL( flv.end_date_active, xwcv_sumr_gr_rec.xwcv_transaction_date )
            ;
          EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_xxcoi
                           , iv_name         => cv_msg_code_xxcoi_10750
                           , iv_token_name1  => cv_tkn_lookup_type
                           , iv_token_value1 => cv_conv_cost_dept
                         );
            lv_errbuf :=  lv_errmsg;
            RAISE global_api_expt;
          END;
--
          -- ���㌴���̊���ȖځE�⏕�Ȗڎ擾
          BEGIN
            SELECT  flv.attribute1  AS attribute1
                  , flv.attribute2  AS attribute2
            INTO    gt_aff3_cost_account
                  , gt_aff4_cost_sub_acct
            FROM    fnd_lookup_values   flv
            WHERE   flv.lookup_type   = cv_conv_cost_account
            AND     flv.attribute3    = xwcv_sumr_gr_rec.xwcv_account_code
            AND     flv.attribute4    = xwcv_sumr_gr_rec.xwcv_subacct_code
            AND     flv.language      = USERENV( 'LANG' )
            AND     flv.enabled_flag  = 'Y'
            AND     TRUNC( xwcv_sumr_gr_rec.xwcv_transaction_date )  BETWEEN NVL( flv.start_date_active, xwcv_sumr_gr_rec.xwcv_transaction_date )
                                              AND     NVL( flv.end_date_active, xwcv_sumr_gr_rec.xwcv_transaction_date )
            ;
          EXCEPTION
          WHEN OTHERS THEN
            -- �ϊ��ΏۊO�̊���Ȗ�
            gt_aff3_cost_account  := xwcv_sumr_gr_rec.xwcv_account_code;
            gt_aff4_cost_sub_acct := xwcv_sumr_gr_rec.xwcv_subacct_code;
          END;
--
          -- ���z���{�Ȃ�ؕ����z�ɃZ�b�g
          IF xwcv_sumr_gr_rec.sum_cost_amount > 0 THEN
            lt_entered_dr := ABS( xwcv_sumr_gr_rec.sum_cost_amount );
            lt_segment2   := gt_aff2_cost_dept_dr;
            lt_segment3   := gt_aff3_cost_account;
            lt_segment4   := gt_aff4_cost_sub_acct;
          -- ���z���|�Ȃ�ݕ����z�ɃZ�b�g
          ELSE
            lt_entered_cr := ABS( xwcv_sumr_gr_rec.sum_cost_amount );
            lt_segment2   := gt_aff2_cost_dept_cr;
            lt_segment3   := xwcv_sumr_gr_rec.xwcv_account_code;
            lt_segment4   := xwcv_sumr_gr_rec.xwcv_subacct_code;
          END IF;
--
          -- ===============================
          -- GL-IF�o�^�����i���㌴���j
          -- ===============================
          ins_gl_if_reg(
              id_accounting_date       => xwcv_sumr_gr_rec.xwcv_transaction_date,        -- �d��L�����t
              iv_segment1              => gt_aff1_company_code,                          -- ��ЃR�[�h
              iv_segment2              => lt_segment2,                                   -- ����R�[�h
              iv_segment3              => lt_segment3,                                   -- ����ȖڃR�[�h
              iv_segment4              => lt_segment4,                                   -- �⏕�ȖڃR�[�h
              in_entered_dr            => lt_entered_dr,                                 -- �ؕ����z
              in_entered_cr            => lt_entered_cr,                                 -- �ݕ����z
              iv_reference21           => TO_CHAR( xwcv_sumr_gr_rec.xwcv_gl_batch_id ),  -- GL�o�b�`ID
              iv_period_name           => xwcv_sumr_gr_rec.gp_period_name,               -- ��v���Ԗ�
              iv_user_je_category_name => gt_je_category_name_inv_gr,                    -- �d��J�e�S����
              ov_errbuf                => lv_errbuf   -- �G���[�E���b�Z�[�W
            , ov_retcode               => lv_retcode  -- ���^�[���E�R�[�h
            , ov_errmsg                => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ������
          lt_entered_dr      := NULL;  -- �ؕ����z
          lt_entered_cr      := NULL;  -- �ݕ����z
          lt_segment2        := NULL;  -- ����
          lt_segment3        := NULL;  -- ����Ȗ�
          lt_segment4        := NULL;  -- �⏕�Ȗ�
          -- ���z���{�Ȃ�ؕ����z�ɃZ�b�g
          IF xwcv_sumr_gr_rec.sum_purchase_amount > 0 THEN
            lt_entered_dr := ABS( xwcv_sumr_gr_rec.sum_purchase_amount );
            lt_segment2   := xwcv_sumr_gr_rec.xwcv_grcp_adj_dept_code;
            lt_segment3   := xwcv_sumr_gr_rec.xwcv_account_code;
            lt_segment4   := xwcv_sumr_gr_rec.xwcv_subacct_code;
          -- ���z���|�Ȃ�ݕ����z�ɃZ�b�g
          ELSE
            lt_entered_cr := ABS( xwcv_sumr_gr_rec.sum_purchase_amount );
            lt_segment2   := xwcv_sumr_gr_rec.xwcv_grcp_adj_dept_code;
            lt_segment3   := gt_aff3_payable;    -- ���|��
            lt_segment4   := gt_aff4_payable;    -- ���|��(�⏕)
          END IF;
          -- ===============================
          -- GL-IF�o�^�����i�I�����Y�d��j
          -- ===============================
          ins_gl_if_reg(
              id_accounting_date       => xwcv_sumr_gr_rec.xwcv_transaction_date,        -- �d��L�����t
              iv_segment1              => xwcv_sumr_gr_rec.xwcv_company_code,            -- ��ЃR�[�h
              iv_segment2              => lt_segment2,                                   -- ����R�[�h
              iv_segment3              => lt_segment3,                                   -- ����ȖڃR�[�h
              iv_segment4              => lt_segment4,                                   -- �⏕�ȖڃR�[�h
              in_entered_dr            => lt_entered_dr,                                 -- �ؕ����z
              in_entered_cr            => lt_entered_cr,                                 -- �ݕ����z
              iv_reference21           => TO_CHAR( xwcv_sumr_gr_rec.xwcv_gl_batch_id ),  -- GL�o�b�`ID
              iv_period_name           => xwcv_sumr_gr_rec.gp_period_name,               -- ��v���Ԗ�
              iv_user_je_category_name => gt_je_category_name_inv_gr,                    -- �d��J�e�S����
              ov_errbuf                => lv_errbuf   -- �G���[�E���b�Z�[�W
            , ov_retcode               => lv_retcode  -- ���^�[���E�R�[�h
            , ov_errmsg                => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        ELSE
          -- ���L���ړ]����ȊO
          -- ������
          lt_entered_dr      := NULL;  -- �ؕ����z
          lt_entered_cr      := NULL;  -- �ݕ����z
          -- ���z���{�Ȃ�ؕ����z�ɃZ�b�g
          IF xwcv_sumr_gr_rec.sum_purchase_amount > 0 THEN
            lt_entered_dr := ABS( xwcv_sumr_gr_rec.sum_purchase_amount );
          -- ���z���|�Ȃ�ݕ����z�ɃZ�b�g
          ELSE
            lt_entered_cr := ABS( xwcv_sumr_gr_rec.sum_purchase_amount );
          END IF;
--
          -- ===============================
          -- GL-IF�o�^�����i�I�����Y�d��j
          -- ===============================
          ins_gl_if_reg(
              id_accounting_date       => xwcv_sumr_gr_rec.xwcv_transaction_date,        -- �d��L�����t
              iv_segment1              => xwcv_sumr_gr_rec.xwcv_company_code,            -- ��ЃR�[�h
              iv_segment2              => xwcv_sumr_gr_rec.xwcv_grcp_adj_dept_code,      -- ����R�[�h
              iv_segment3              => xwcv_sumr_gr_rec.xwcv_account_code,            -- ����ȖڃR�[�h
              iv_segment4              => xwcv_sumr_gr_rec.xwcv_subacct_code,            -- �⏕�ȖڃR�[�h
              in_entered_dr            => lt_entered_dr,                                 -- �ؕ����z
              in_entered_cr            => lt_entered_cr,                                 -- �ݕ����z
              iv_reference21           => TO_CHAR( xwcv_sumr_gr_rec.xwcv_gl_batch_id ),  -- GL�o�b�`ID
              iv_period_name           => xwcv_sumr_gr_rec.gp_period_name,               -- ��v���Ԗ�
              iv_user_je_category_name => gt_je_category_name_inv_gr,                    -- �d��J�e�S����
              ov_errbuf                => lv_errbuf   -- �G���[�E���b�Z�[�W
            , ov_retcode               => lv_retcode  -- ���^�[���E�R�[�h
            , ov_errmsg                => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
    END LOOP;
    -- �Ώی���(�O���[�v��ЏW��P��)�Z�b�g
    gn_target_sum_cnt_gr := xwcv_sum_gr_cur%ROWCOUNT;
    CLOSE xwcv_sum_gr_cur;
--
    -- ========================================
    -- GL�C���^�[�t�F�[�X�i�[(�W�������X�V���)
    -- ========================================
    OPEN xwcv_sum_gr_cur2;
    LOOP
      FETCH xwcv_sum_gr_cur2 INTO xwcv_sumr_gr_rec2;
      EXIT WHEN xwcv_sum_gr_cur2%NOTFOUND; 
--
      IF (xwcv_sumr_gr_rec2.sum_amount <> 0) THEN
        --���z��0�łȂ���Έȉ��̏��������{����
        IF (xwcv_sumr_gr_rec2.xwcv_transaction_date > gt_last_period_date) THEN
          xwcv_sumr_gr_rec2.gp_period_name := gt_period_name_tm;
        ELSE
          xwcv_sumr_gr_rec2.gp_period_name := gt_period_name_lm;
        END IF;
--
        -- ������
        lt_entered_dr      := NULL;  -- �ؕ����z
        lt_entered_cr      := NULL;  -- �ݕ����z
--
        -- ���z���{�Ȃ�ؕ����z�ɃZ�b�g
        IF ( xwcv_sumr_gr_rec2.sum_amount * -1 ) > 0 THEN
          lt_entered_dr := ABS( xwcv_sumr_gr_rec2.sum_amount );
        -- ���z���|�Ȃ�ݕ����z�ɃZ�b�g
        ELSE
          lt_entered_cr := ABS( xwcv_sumr_gr_rec2.sum_amount );
        END IF;
--
        -- ===============================
        -- GL-IF�o�^�����i�U��߂��j
        -- ===============================
        ins_gl_if_reg(
            id_accounting_date       => xwcv_sumr_gr_rec2.xwcv_transaction_date,        -- �d��L�����t
            iv_segment1              => gt_aff1_company_code,                           -- ��ЃR�[�h
            iv_segment2              => xwcv_sumr_gr_rec2.xwcv_dept_code,               -- ����R�[�h
            iv_segment3              => xwcv_sumr_gr_rec2.xwcv_account_code,            -- ����ȖڃR�[�h
            iv_segment4              => xwcv_sumr_gr_rec2.xwcv_subacct_code,            -- �⏕�ȖڃR�[�h
            in_entered_dr            => lt_entered_dr,                                  -- �ؕ����z
            in_entered_cr            => lt_entered_cr,                                  -- �ݕ����z
            iv_reference21           => TO_CHAR( xwcv_sumr_gr_rec2.xwcv_gl_batch_id ),  -- GL�o�b�`ID
            iv_period_name           => xwcv_sumr_gr_rec2.gp_period_name,               -- ��v���Ԗ�
            iv_user_je_category_name => gt_je_category_name_inv_gr,                     -- �d��J�e�S����
            ov_errbuf                => lv_errbuf    -- �G���[�E���b�Z�[�W
          , ov_retcode               => lv_retcode   -- ���^�[���E�R�[�h
          , ov_errmsg                => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP;
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
      IF ( xwcv_sum_gr_cur%ISOPEN ) THEN
        CLOSE xwcv_sum_gr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_gl_if_gr_comp;
--
  /**********************************************************************************
   * Procedure Name   : ins_xwcv_bk
   * Description      : �݌Ɏ󕥕\�i�f��Ёj�e�[�u���̍쐬 (A-12)
   ***********************************************************************************/
  PROCEDURE ins_xwcv_bk(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xwcv_bk'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �݌Ɏ󕥕\�i�f��Ёj�e�[�u���o�^
    INSERT INTO xxcoi_inv_recept_g_company(
            company_code                                                   -- 01.��ЃR�[�h
          , grcp_adj_dept_code                                             -- 02.�v�㋒�_
          , transaction_date                                               -- 03.�����
          , item_code                                                      -- 04.�i�ڃR�[�h
          , subinventory_code                                              -- 05.�ۊǏꏊ
          , quantity                                                       -- 06.����
          , purchase_unit_price                                            -- 07.�w���P��
          , purchase_amount                                                -- 08.�w�����z
          , transaction_type_name                                          -- 09.����^�C�v��
          , slip_number                                                    -- 10.�`�[�ԍ�
          , transfer_ownership_flg                                         -- 11.���L���ړ]����t���O
          , transfer_subinventory                                          -- 12.�ړ����ۊǏꏊ
          , sales_base_code                                                -- 13.���㋒�_
          , standard_cost                                                  -- 14.���W������
          , created_by                                                     -- 15.�쐬��
          , creation_date                                                  -- 16.�쐬��
          , last_updated_by                                                -- 17.�ŏI�X�V��
          , last_update_date                                               -- 18.�ŏI�X�V��
          , last_update_login                                              -- 19.�ŏI�X�V���O�C��
          , request_id                                                     -- 20.�v��ID
          , program_application_id                                         -- 21.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , program_id                                                     -- 22.�R���J�����g�E�v���O����ID
          , program_update_date                                            -- 23.�v���O�����X�V��
    )
    SELECT
            xwcv.company_code                   AS company_code            -- 01.��ЃR�[�h
          , xwcv.grcp_adj_dept_code             AS grcp_adj_dept_code      -- 02.�v�㋒�_
          , mmt.transaction_date                AS transaction_date        -- 03.�����
          , msib.segment1                       AS segment1                -- 04.�i�ڃR�[�h
          , mmt.subinventory_code               AS subinventory_code       -- 05.�ۊǏꏊ
          , xwcv.primary_quantity               AS transaction_quantity    -- 06.����
          , ROUND( xwcv.standard_cost * ( 1 + ( flv.attribute1 / 100 )),2)
                                                AS purchase_unit_price     -- 07.�w���P��
          , ROUND( xwcv.primary_quantity *
            ROUND( xwcv.standard_cost * ( 1 + ( flv.attribute1 / 100 )),2),2)
                                                AS purchase_amount         -- 08.�w�����z
          , mtt.transaction_type_name           AS transaction_type_name   -- 09.����^�C�v��
          , mmt.attribute1                      AS attribute1              -- 10.�`�[�ԍ�
          , xwcv.transfer_ownership_flg         AS transfer_ownership_flg  -- 11.���L���ړ]����t���O
          , mmt.transfer_subinventory           AS transfer_subinventory   -- 12.�ړ����ۊǏꏊ
          , NULL                                AS sales_base_code         -- 13.���㋒�_
          , xwcv.standard_cost                  AS standard_cost           -- 14.���W������
          , cn_created_by                       AS created_by              -- 15.�쐬��
          , SYSDATE                             AS creation_date           -- 16.�쐬��
          , cn_last_updated_by                  AS last_updated_by         -- 17.�ŏI�X�V��
          , SYSDATE                             AS last_update_date        -- 18.�ŏI�X�V��
          , cn_last_update_login                AS last_update_login       -- 19.�ŏI�X�V���O�C��
          , cn_request_id                       AS request_id              -- 20.�v��ID
          , cn_program_application_id           AS program_application_id  -- 21.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , cn_program_id                       AS program_id              -- 22.�R���J�����g�E�v���O����ID
          , SYSDATE                             AS program_update_date     -- 23.�v���O�����X�V��
    FROM    xxcoi_wk_cost_variance    xwcv     -- �������z���[�N�e�[�u��
          , mtl_material_transactions mmt      -- ���ގ��
          , mtl_system_items_b        msib     -- Disc�i�ڃ}�X�^
          , mtl_transaction_types     mtt      -- ����^�C�v�}�X�^
          , xxcfr_bd_company_info_v   flv      -- �e�З��v��
    WHERE   xwcv.group_company_flg   = cv_1                                -- 1:�O���[�v���
    AND     xwcv.reverse_flg         = cv_0                                -- 0:���f�[�^
    AND     xwcv.account_code        IN ( gt_aff3_seihin,gt_aff3_shouhin ) -- �i12204�F���i�A12109�F���i�j
    AND     xwcv.transaction_id      = mmt.transaction_id                  -- ���ID
    AND     msib.inventory_item_id   = mmt.inventory_item_id
    AND     msib.organization_id     = mmt.organization_id
    AND     mtt.transaction_type_id  = xwcv.transaction_type_id
    AND     mmt.organization_id      = xxcoi_common_pkg.get_organization_id ( gt_org_code )
    AND     flv.lookup_type          = cv_company_profit_rate
    AND     flv.company_code         = xwcv.company_code
      AND     TRUNC( xwcv.transaction_date )  BETWEEN NVL( flv.start_date_active, xwcv.transaction_date )
                                           AND     NVL( flv.end_date_active, xwcv.transaction_date )
    AND     xwcv.transaction_type_id <> gt_trans_type_std_cost_upd  -- �W�������X�V�͏���
    ;
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
  END ins_xwcv_bk;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_if_round_Journal
   * Description      : �ۂߌ덷GL-IF�o�^ (A-13)
   ***********************************************************************************/
  PROCEDURE ins_gl_if_round_Journal(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_if_round_Journal'; -- �v���O������
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
    cv_flag_n            CONSTANT VARCHAR2(1) := 'N';           -- �t���O�l�FN
    cv_status_new        CONSTANT VARCHAR2(3) := 'NEW';         -- �Œ�l�FNEW
    cv_code_jpy          CONSTANT VARCHAR2(3) := 'JPY';         -- �Œ�l�FJPY
    cv_flag_a            CONSTANT VARCHAR2(1) := 'A';           -- �Œ�l�FA
    cv_yyyymm            CONSTANT VARCHAR2(7) := 'YYYY/MM';     -- �Œ�l�FYYYY/MM
--
    -- *** ���[�J���ϐ� ***
    lt_entered_dr        gl_interface.entered_dr%TYPE;    -- �ؕ����z
    lt_entered_cr        gl_interface.entered_cr%TYPE;    -- �ݕ����z
    lt_segment2          gl_interface.segment2%TYPE;      -- ����
    lt_segment3          gl_interface.segment3%TYPE;      -- ����Ȗ�
    lt_segment4          gl_interface.segment4%TYPE;      -- �⏕�Ȗ�
--
    -- ===============================
    -- �ۂߌ덷���̒��o
    -- ===============================
    -- �ۂߌ덷���J�[�\��
    CURSOR gl_if_round_cur
    IS
      SELECT
              gi.segment1               AS company_code,          -- ���
              gi.user_je_category_name  AS user_je_category_name, -- �d��J�e�S����
              gi.period_name            AS period_name,           -- ��v���Ԗ�
              gi.reference21            AS gl_batch_id,           -- GL�o�b�`ID
              MAX( gi.accounting_date ) AS max_accounting_date,   -- �d��L�����t
              SUM( gi.entered_dr ) - SUM( gi.entered_cr )
                                        AS sum_adjustment_amount  -- ���v�ݎ؍��z
      FROM    gl_interface   gi
      WHERE   gi.user_je_category_name IN (gt_je_category_name_inv_gr,gt_je_category_name_inv_cost)
      AND     gi.user_je_source_name   = gt_je_category_name_inv_cost
      GROUP BY gi.segment1,
               gi.user_je_category_name,
               gi.period_name,
               gi.reference21
      ;
    -- �ۂߌ덷���J�[�\�� ���R�[�h�^
    gl_if_round_rec gl_if_round_cur%ROWTYPE;
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
    -- GL�C���^�[�t�F�[�X�i�[
    -- ===============================
    OPEN gl_if_round_cur;
    LOOP
      FETCH gl_if_round_cur INTO gl_if_round_rec;
      EXIT WHEN gl_if_round_cur%NOTFOUND;
--
      IF ( gl_if_round_rec.sum_adjustment_amount = 0) THEN
        NULL;
      ELSE
        -- ������
        lt_segment2        := NULL;  -- ����R�[�h
        lt_entered_dr      := NULL;  -- �ؕ����z
        lt_entered_cr      := NULL;  -- �ݕ����z
--
        -- ����R�[�h�擾
        SELECT flv.attribute3
        INTO   lt_segment2
        FROM   fnd_lookup_values   flv
        WHERE  flv.lookup_type   = cv_conv_dept_code
        AND    flv.attribute1    = gl_if_round_rec.company_code
        AND    flv.attribute2    = gt_aff2_adj_dept_code        -- ��������
        AND    flv.language      = USERENV( 'LANG' );
--
        -- ���v�ݎ؍��z���|�Ȃ�ؕ����z�ɃZ�b�g
        IF ( gl_if_round_rec.sum_adjustment_amount * -1 ) > 0 THEN
          lt_entered_dr := ABS( gl_if_round_rec.sum_adjustment_amount );
        -- ���v�ݎ؍��z���{�Ȃ�ݕ����z�ɃZ�b�g
        ELSE
          lt_entered_cr := ABS( gl_if_round_rec.sum_adjustment_amount );
        END IF;
--
        -- ===============================
        -- GL-IF�o�^�����i�ۂߌ덷�j
        -- ===============================
        ins_gl_if_reg(
            id_accounting_date       => gl_if_round_rec.max_accounting_date,       -- �d��L�����t
            iv_segment1              => gl_if_round_rec.company_code,              -- ��ЃR�[�h
            iv_segment2              => lt_segment2,                               -- ����R�[�h
            iv_segment3              => gt_aff3_rounding_error,                    -- ����ȖڃR�[�h
            iv_segment4              => gt_aff4_rounding_error,                    -- �⏕�ȖڃR�[�h
            in_entered_dr            => lt_entered_dr,                             -- �ؕ����z
            in_entered_cr            => lt_entered_cr,                             -- �ݕ����z
            iv_reference21           => gl_if_round_rec.gl_batch_id,               -- GL�o�b�`ID
            iv_period_name           => gl_if_round_rec.period_name,               -- ��v���Ԗ�
            iv_user_je_category_name => gl_if_round_rec.user_je_category_name,     -- �d��J�e�S����
            ov_errbuf                => lv_errbuf   -- �G���[�E���b�Z�[�W
          , ov_retcode               => lv_retcode  -- ���^�[���E�R�[�h
          , ov_errmsg                => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP;
    CLOSE gl_if_round_cur;
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
      IF ( gl_if_round_cur%ISOPEN ) THEN
        CLOSE gl_if_round_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_gl_if_round_Journal;
--
-- Ver1.10 ADD END
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
-- == 2009/07/14 V1.4 Added START ===============================================================
    iv_effective_date  IN VARCHAR2, -- �L����
-- == 2009/07/14 V1.4 Added END   ===============================================================
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
    ln_mtl_txn_acct_cnt  NUMBER DEFAULT 0;  -- �擾�����F���ޔz�����
    ln_standard_cost     NUMBER DEFAULT 0;  -- �W������
    ln_operation_cost    NUMBER DEFAULT 0;  -- �c�ƌ���
    ln_cost_variance     NUMBER DEFAULT 0;  -- �������z
    lv_status            VARCHAR2(1);       -- �X�e�[�^�X
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
    gn_target_cnt     := 0; -- �Ώی���  (���ޔz�����P��)
    gn_normal_cnt     := 0; -- ��������  (���ޔz�����P��)
    gn_error_cnt      := 0; -- �G���[����(���ޔz�����P��)
    gn_target_sum_cnt := 0; -- �Ώی���  (�������z�W��P��)
    gn_normal_sum_cnt := 0; -- ��������  (�������z�W��P��)
    gn_error_sum_cnt  := 0; -- �G���[����(�������z�W��P��)
-- Ver1.10 ADD START
    gn_target_sum_cnt_gr := 0; -- �Ώی���  (�O���[�v��ЏW��P��)
    gn_error_sum_cnt_gr  := 0; -- �G���[����(�O���[�v��ЏW��P��)
-- Ver1.10 ADD END
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
-- == 2009/07/14 V1.4 Added START ===============================================================
        iv_effective_date  => iv_effective_date   -- �L����
-- == 2009/07/14 V1.4 Added END   ===============================================================
      , ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W
      , ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h
      , ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
-- == 2009/09/28 V1.8 Deleted START ===============================================================
--    -- ===============================
--    -- ���ޔz�����̒��o (A-2)
--    -- ===============================
--    get_mtl_txn_acct(
--        on_mtl_txn_acct_cnt => ln_mtl_txn_acct_cnt -- �擾����
--      , ov_errbuf           => lv_errbuf           -- �G���[�E���b�Z�[�W
--      , ov_retcode          => lv_retcode          -- ���^�[���E�R�[�h
--      , ov_errmsg           => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
--    );
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- �擾����0���̏ꍇ
--    IF ( ln_mtl_txn_acct_cnt = 0 ) THEN
--      -- �Ώۃf�[�^�������b�Z�[�W�o��
--      gv_out_msg  := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_short_name_xxcoi
--                       , iv_name         => cv_msg_no_data
--                     );
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => gv_out_msg
--      );
--      RETURN;
--    END IF;
--    -- �Ώی����Z�b�g(���ޔz�����P��)
--    gn_target_cnt := ln_mtl_txn_acct_cnt;
-- == 2009/09/28 V1.8 Deleted END   ===============================================================
--
    -- =============================================
    -- �������z���[�N�e�[�u���̑O��f�[�^�폜 (A-3)
    -- =============================================
    del_xwcv_last_data(
        ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
      , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
      , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
-- == 2009/09/28 V1.8 Modified START ===============================================================
--    <<loop_1>>  -- �������z���i�[���[�v
--    FOR i IN 1 .. ln_mtl_txn_acct_cnt LOOP
--      -- ������
--      gn_mtl_txn_acct_cnt := i;                -- PL/SQL�\�C���f�b�N�X
--
    OPEN  mtl_txn_acct_cur;
    <<loop_1>>
    LOOP
      FETCH mtl_txn_acct_cur  INTO  mtl_txn_acct_rec;
      EXIT WHEN mtl_txn_acct_cur%NOTFOUND;
      --
      -- �Ώی����Z�b�g(���ޔz�����P��)
      gn_target_cnt := gn_target_cnt + 1;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      lv_status           := cv_normal_record; -- �X�e�[�^�X�F����
--
      -- ===============================
      -- �������擾���� (A-4)
      -- ===============================
      get_cost_info(
          ion_standard_cost  => ln_standard_cost  -- �W������
        , ion_operation_cost => ln_operation_cost -- �c�ƌ���
        , ion_cost_variance  => ln_cost_variance  -- �������z
-- == 2009/09/28 V1.8 Added START ===============================================================
        , ir_txn_acct_rec    => mtl_txn_acct_rec  -- ���ޔz�����
-- == 2009/09/28 V1.8 Added END   ===============================================================
        , ov_errbuf          => lv_errbuf         -- �G���[�E���b�Z�[�W
        , ov_retcode         => lv_retcode        -- ���^�[���E�R�[�h
        , ov_errmsg          => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      -- ���^�[���E�R�[�h���x���̏ꍇ�A�X�e�[�^�X��N�Z�b�g
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_status := cv_error_record;
      END IF;
--
      -- ===================================
      -- �������z���[�N�e�[�u���̍쐬 (A-5)
      -- ===================================
      ins_xwcv(
          in_standard_cost  => ln_standard_cost  -- �W������
        , in_operation_cost => ln_operation_cost -- �c�ƌ���
        , in_cost_variance  => ln_cost_variance  -- �������z
        , iv_status         => lv_status         -- �X�e�[�^�X
-- == 2009/09/28 V1.8 Added START ===============================================================
        , ir_txn_acct_rec   => mtl_txn_acct_rec  -- ���ޔz�����
-- == 2009/09/28 V1.8 Added END   ===============================================================
        , ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W
        , ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h
        , ov_errmsg         => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSE
        -- �G���[�f�[�^�o�^ �G���[����(���ޔz�����P��)�J�E���g
        IF ( lv_status = cv_error_record ) THEN
          gn_error_cnt := gn_error_cnt + 1;
        -- ����f�[�^�o�^   ��������(���ޔz�����P��)�J�E���g
        ELSE
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
      END IF;
    END LOOP loop_1;
--
-- == 2009/09/28 V1.8 Added START ===============================================================
    IF ( gn_target_cnt = 0 ) THEN
      -- �Ώۃf�[�^�������b�Z�[�W�o��
      gv_out_msg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcoi
                       , iv_name         => cv_msg_no_data
                     );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      RETURN;
    END IF;
-- == 2009/09/28 V1.8 Added END   ===============================================================
-- Ver1.10 ADD START
    -- ===================================================
    -- �I�����Y���GL-IF�o�^(�O���[�v���) (A-10)
    -- ===================================================
    ins_gl_if_gr_comp(
        ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
      , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
      , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- Ver1.10 ADD END
    -- =======================================
    -- �������z���GL-IF�o�^ (A-6�AA-7�AA-8)
    -- =======================================
    ins_gl_if(
        ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
      , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
      , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���ޔz�����P�ʂ������͌������z�W��P�ʂ�1���ł��G���[���������ꍇ
    IF gn_error_cnt > 0 OR gn_error_sum_cnt > 0 THEN
      -- �I���X�e�[�^�X�Ɍx���Z�b�g
      ov_retcode := cv_status_warn;
    END IF;
-- Ver1.10 ADD START
    -- ===================================================
    -- �݌Ɏ󕥕\�i�f��Ёj�e�[�u���̍쐬 (A-12)
    -- ===================================================
    ins_xwcv_bk(
        ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
      , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
      , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===================================================
    -- �ۂߌ덷GL-IF�o�^ (A-13)
    -- ===================================================
    ins_gl_if_round_Journal(
        ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
      , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
      , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- Ver1.10 ADD END
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
-- == 2009/07/14 V1.4 Added START ===============================================================
    , iv_effective_date  IN  VARCHAR2  --  �L����
-- == 2009/07/14 V1.4 Added END   ===============================================================
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
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
-- == 2009/07/14 V1.4 Added START ===============================================================
        iv_effective_date  => iv_effective_date   --  �L����
-- == 2009/07/14 V1.4 Added END   ===============================================================
      , ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �X�e�[�^�X�F�ُ�
    IF ( lv_retcode = cv_status_error ) THEN
      -- �����Z�b�g
      gn_target_cnt     := 0;
      gn_normal_cnt     := 0;
      gn_error_cnt      := 1;
      gn_target_sum_cnt := 0;
      gn_normal_sum_cnt := 0;
      gn_error_sum_cnt  := 0;
-- Ver1.10 ADD START
      gn_target_sum_cnt_gr := 0;
      gn_error_sum_cnt_gr  := 0;
-- Ver1.10 ADD END
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
--
    -- ���ޔz�����P�ʌ������b�Z�[�W
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_xxcoi
                , iv_name         => cv_msg_unit_mtl_txn_acct
              );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --�Ώی����o��(���ޔz�����P��)
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
    --���������o��(���ޔz�����P��)
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
    --�G���[�����o��(���ޔz�����P��)
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
    -- �������z�W��P�ʌ������b�Z�[�W
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_xxcoi
                , iv_name         => cv_msg_unit_cost_sum
              );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --�Ώی����o��(�������z�W��P��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_sum_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --���������o��(�������z�W��P��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_sum_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --�G���[�����o��(�������z�W��P��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_sum_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
-- Ver1.10 ADD START
    -- �O���[�v��ЏW��P�ʌ������b�Z�[�W
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_xxcoi
                , iv_name         => cv_msg_code_xxcoi_10751
              );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --�Ώی����o��(�I�����Y�W��P��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_sum_cnt_gr)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --���������o��(�I�����Y�W��P��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_sum_cnt_gr)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --�G���[�����o��(�I�����Y�W��P��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_sum_cnt_gr)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
-- Ver1.10 ADD END
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
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
      , buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
-- == 2009/09/28 V1.8 Modified START ===============================================================
--    IF (retcode = cv_status_error) THEN
--      ROLLBACK;
--    END IF;
    IF (   (retcode = cv_status_error)
        OR (gn_target_cnt = 0)
       )
    THEN
      ROLLBACK;
    END IF;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
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
END XXCOI007A01C;
/
