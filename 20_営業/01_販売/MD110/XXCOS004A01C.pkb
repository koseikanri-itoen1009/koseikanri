CREATE OR REPLACE PACKAGE BODY XXCOS004A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A01C (body)
 * Description      : �X�ܕʊ|���쐬
 * MD.050           : �X�ܕʊ|���쐬 MD050_COS_004_A01
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0)
 *  pram_chk               �p�����[�^�`�F�b�N(A-1)
 *  data_del_former        �X�ܕʗp�����v�Z���̑O��f�[�^�폜(A-2)
 *  get_cust_data          �ڋq�}�X�^�f�[�^�擾����(A-3)
 *  data_del_now           �X�ܕʗp�����v�Z���̍���f�[�^�폜(A-4)
 *  init_header            �w�b�_�P�ʏ���������(A-5)
 *  get_ar_data            AR������擾����(A-6)(A-7)
 *  get_inv_data           INV�����݌Ɏ󕥂��\���擾����(A-8)(A-9)(A-10)(A-11)
 *  set_header             �X�ܕʗp�����v�Z�w�b�_�o�^����(A-12)
 *  insert_lines           �X�ܕʗp�����v�Z���׃e�[�u���o�^
 *  insert_headers         �X�ܕʗp�����v�Z�w�b�_�e�[�u���o�^
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19    1.0   T.Kitajima       �V�K�쐬
 *  2009/02/06    1.1   K.Kakishita      [COS_036]AR����^�C�v�}�X�^�̒��o�����ɉc�ƒP�ʂ�ǉ�
 *  2009/02/10    1.2   T.kitajima       [COS_057]�ڋq�敪�i�荞�ݏ����s���Ή�(�d�l�R��)
 *  2009/02/17    1.3   T.kitajima       get_msg�̃p�b�P�[�W���C��
 *  2009/02/24    1.4   T.kitajima       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/03/05    1.5   N.Maeda          �I�����Ղ̒��o���̌v�Z�����폜
 *                                       �E�C���O
 *                                         ��sirm.inv_wear * -1
 *                                       �E�C����
 *                                         ��sirm.inv_wear
 *  2009/03/19    1.6   T.kitajima       [T1_0093]INV�����݌Ɏ󕥂��\���擾�C��
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
  global_common_expt          EXCEPTION;                              --���ʃG���[
  global_get_profile_expt     EXCEPTION;                              --�v���t�@�C���G���[
  global_proc_date_err_expt   EXCEPTION;                              --�Ɩ����t�擾�G���[��O
  global_require_param_expt   EXCEPTION;                              --�K�{���̓p�����[�^���ݒ�G���[��O
  global_call_api_expt        EXCEPTION;                              --API�ďo�G���[��O
  global_data_lock_expt       EXCEPTION;                              --���b�N�G���[
  global_data_del_expt        EXCEPTION;                              --�폜�G���[
  global_select_err_expt      EXCEPTION;                              --SELECT�G���[
  global_no_data_expt         EXCEPTION;                              --�Ώۃf�[�^�Ȃ�
  global_get_item_err_expt    EXCEPTION;                              --�i�ڃ}�X�^�擾�G���[
  global_insert_expt          EXCEPTION;                              --�f�[�^�o�^�G���[
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );                --���b�N�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                   CONSTANT  VARCHAR2(100) := 'XXCOS004A01C';
                                                                      -- �p�b�P�[�W��
--
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE
                                          := 'XXCOS';                 --�̕��Z�k�A�v����
  --�̕����b�Z�[�W
  ct_msg_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00001';      --���b�N�擾�G���[���b�Z�[�W
  cv_msg_nodata_err             CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00003';      --�Ώۃf�[�^�����G���[
  ct_msg_get_profile_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00004';      --�v���t�@�C���擾�G���[
  ct_msg_require_param_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00006';      --�K�{���̓p�����[�^���ݒ�G���[
  ct_msg_delete_data_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00012';      --�f�[�^�폜�G���[���b�Z�[�W
  ct_msg_process_date_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00014';      --�Ɩ����t�擾�G���[
  ct_msg_call_api_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00017';      --API�ďo�G���[���b�Z�[�W
  ct_msg_pram_date              CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10901';      --�p�����[�^���b�Z�[�W
  ct_msg_select_count           CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10902';      --�Ώی������b�Z�[�W
  ct_msg_warn_count             CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10903';      --�x���������b�Z�[�W
  cv_msg_select_cust_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10909';      --�ڋq��񒊏o�G���[
  cv_msg_select_salesreps_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10911';      --�c�ƒS�����R�[�h�擾�G���[
  cv_msg_select_ar_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10912';      --AR������擾�G���[
  cv_msg_select_inv_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10913';      --INV�����݌Ɏ󕥕\���擾�G���[
  cv_msg_select_item_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10914';      --�i�ڃ}�X�^���擾�G���[
  cv_msg_inser_lines_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10915';      --�X�ܕʗp�����v�Z���׃e�[�u���o�^�G���[
  cv_msg_inser_headers_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10916';      --�X�ܕʗp�����v�Z�w�b�_�e�[�u���o�^�G���[
  --������p
  ct_msg_base_code              CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00055';      --���_�R�[�h
  ct_msg_max_date               CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00056';      --XXCOS:MAX���t
  ct_msg_org_id                 CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00047';      --MO:�c�ƒP��
  ct_msg_get_organization_code  CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00048';      --XXCOI:�݌ɑg�D�R�[�h
  ct_msg_get_organization_id    CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10904';      --�݌ɑg�DID�̎擾
  ct_msg_get_shop_hdr_name      CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10905';      --�X�ܕʗp�����v�Z�w�b�_�e�[�u��
  ct_msg_get_shop_line_name     CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10906';      --�X�ܕʗp�����v�Z���׃e�[�u��
  ct_msg_get_shop_data_name     CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10907';      --�X�ܕʗp�����v�Z���
  ct_msg_key_info1              CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10908';      --�L�[���i�����v�Z���N�����j
  ct_msg_key_info2              CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10910';      --�L�[���i�����v�Z���N����,�ڋq�R�[�h�j
  --�v���t�@�C������
  ct_prof_max_date              CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_MAX_DATE';       --MAX���t
  ct_prof_org_id                CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'ORG_ID';                --MO:�c�ƒP��
  ct_prof_organization_code     CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOI1_ORGANIZATION_CODE';
                                                                      --XXCOI:�݌ɑg�D�R�[�h
  --�N�C�b�N�R�[�h�^�C�v
  ct_qct_cust_type              CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                          := 'XXCOS1_CUS_CLASS_MST_004_A01';
                                                                      --�ڋq�敪����}�X�^
  ct_qct_gyo_type               CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                          := 'XXCOS1_GYOTAI_SHO_MST_004_A01';
                                                                      --�Ƒԏ����ޓ���}�X�^_004_A01
  ct_qct_customer_trx_type      CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                          := 'XXCOS1_AR_TRX_TYPE_MST_004_A01';
                                                                      --�`�q����^�C�v����}�X�^_004_A01
  --�N�C�b�N�R�[�h
  ct_qcc_it_code                CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_004_A01%';        --�C���V���b�v/���В��c�X
  ct_qcc_customer_trx_type1     CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                          := 'XXCOS_004_A01_1%';      --�`�q����^�C�v����}�X�^(�ʏ�)
  ct_qcc_customer_trx_type2     CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                          := 'XXCOS_004_A01_2%';      --�`�q����^�C�v����}�X�^(���|������)
  ct_qcc_cust_code_1            CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_004_A01_1%';      --���_
  ct_qcc_cust_code_2            CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_004_A01_2%';      --�ڋq
  --�g�[�N��
  cv_tkn_in_param               CONSTANT  VARCHAR2(100) := 'IN_PARAM';--�L�[�f�[�^
  cv_tkn_parm_data1             CONSTANT  VARCHAR2(10)  := 'PARAM1';  --�p�����[�^1
  cv_tkn_parm_data2             CONSTANT  VARCHAR2(10)  := 'PARAM2';  --�p�����[�^2
  cv_tkn_cnt_data1              CONSTANT  VARCHAR2(10)  := 'COUNT1';  --�J�E���g1
  cv_tkn_cnt_data2              CONSTANT  VARCHAR2(10)  := 'COUNT2';  --�J�E���g2
  cv_tkn_cnt_data3              CONSTANT  VARCHAR2(10)  := 'COUNT3';  --�J�E���g3
  cv_tkn_profile                CONSTANT  VARCHAR2(100) := 'PROFILE'; --�v���t�@�C��
  cv_tkn_table                  CONSTANT  VARCHAR2(100) := 'TABLE';   --�e�[�u��
  cv_tkn_table_name             CONSTANT  VARCHAR2(100) := 'TABLE_NAME';
                                                                      --�e�[�u������
  cv_tkn_key_data               CONSTANT  VARCHAR2(100) := 'KEY_DATA';--�L�[�f�[�^
  cv_tkn_api_name               CONSTANT  VARCHAR2(100) := 'API_NAME';--�`�o�h����
  cv_tkn_diges_due_dt           CONSTANT  VARCHAR2(100) := 'DIGES_DUE_DT';
                                                                      --�����v�Z���N����
  --�t�H�[�}�b�g
  cv_fmt_date                   CONSTANT  VARCHAR2(10)  := 'RRRR/MM/DD';
  cv_fmt_yyyymm                 CONSTANT  VARCHAR2(6)   := 'YYYYMM';
  cv_fmt_mm                     CONSTANT  VARCHAR2(6)   := 'MM';
  --�g�p�\�t���O�萔
  ct_enabled_flag_yes           CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                          := 'Y';                     --�g�p�\
  --�X�܃w�b�_�p�t���O
  ct_make_flag_yes              CONSTANT  xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE
                                          := 'Y';                     --�쐬�ς�
  ct_make_flag_no               CONSTANT  xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE
                                          := 'N';                     --���쐬
  --�����t���O
  ct_complete_flag_yes          CONSTANT  ra_customer_trx_all.complete_flag%TYPE
                                          := 'Y';                     --����
  --���׃^�C�v
  ct_line_type_line             CONSTANT  ra_customer_trx_lines_all.line_type%TYPE
                                          := 'LINE';                  --LINE
  --���v�Z�敪
  ct_uncalc_class_0             CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                          := '0';
  ct_uncalc_class_1             CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                          := '1';
  ct_uncalc_class_2             CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                          := '2';
  ct_uncalc_class_3             CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                          := '3';
  --�I���Ώۋ敪
  ct_secondary_class_2         CONSTANT   mtl_secondary_inventories.attribute5%TYPE
                                          := '2';                     --����
  --�I���敪
  ct_inventory_class_2         CONSTANT   xxcoi_inv_reception_monthly.inventory_kbn%TYPE
                                          := '2';                     --����
  --Disc�i�ڕύX�����A�h�I��(�K�p�t���O)
  ct_apply_flag_yes            CONSTANT   xxcmm_system_items_b_hst.apply_flag%TYPE
                                          := 'Y';                     --�K�p
  --���v�Z�^�C�v
  cv_uncalculate_type_init      CONSTANT  VARCHAR2(1) := '0';         --INIT
  cv_uncalculate_type_nof       CONSTANT  VARCHAR2(1) := '1';         --NOF
  cv_uncalculate_type_zero      CONSTANT  VARCHAR2(1) := '2';         --ZERO
  --���݃t���O
  cv_exists_flag_yes            CONSTANT  VARCHAR2(1) := 'Y';         --���݂���
  cv_exists_flag_no             CONSTANT  VARCHAR2(1) := 'N';         --���݂Ȃ�
  --���z�f�t�H���g
  cn_amount_default             CONSTANT  NUMBER      := 0;           --���z
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  --�ڋq���e�[�u��
  TYPE g_rec_cust_data IS RECORD
    (
      --�ڋq�}�X�^.�ڋqID
      cust_account_id           hz_cust_accounts.cust_account_id%TYPE,
      --�ڋq�}�X�^.�ڋq�R�[�h
      account_number            hz_cust_accounts.account_number%TYPE,
      --�ڋq�}�X�^.�p�[�e�BID
      party_id                  hz_cust_accounts.party_id%TYPE,
      --�ڋq�A�h�I���}�X�^.�����v�Z�p�|��
      rate                      xxcmm_cust_accounts.rate%TYPE,
      --�ڋq�A�h�I���}�X�^.�O�����㋒�_�R�[�h   or ���㋒�_�R�[�h
      past_sale_base_code       xxcmm_cust_accounts.past_sale_base_code%TYPE,
      --�ڋq�A�h�I���}�X�^.�Ƒԏ�����
      business_low_type         xxcmm_cust_accounts.business_low_type%TYPE,
      --�ڋq�A�h�I���}�X�^.�[�i���_�R�[�h
      delivery_base_code        xxcmm_cust_accounts.delivery_base_code%TYPE,
      --�X�ܕʗp�����v�Z�w�b�_.�X�ܕʗp�����v�Z�w�b�_ID
      shop_digestion_hdr_id     xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE
  );
--
  --�i�ڏ��e�[�u��
  TYPE g_rec_item_data IS RECORD
    (
      --�i�ڃ}�X�^.�i�ڃR�[�h
      segment1                  mtl_system_items_b.segment1%TYPE,
      --�i�ڃ}�X�^.�P�ʃR�[�h
      primary_unit_of_measure   mtl_system_items_b.primary_unit_of_measure%TYPE,
      --�i�ډc�Ɨ����A�h�I��.�艿
      fixed_price               xxcmm_system_items_b_hst.fixed_price%TYPE
  );
--
  --�e�[�u����`
  TYPE g_tab_cust_data          IS TABLE OF g_rec_cust_data                   INDEX BY PLS_INTEGER;
                                                                      --�X�ܕʗp�����v�Z�f�[�^�i�[�p�ϐ�
  TYPE g_tab_item_data          IS TABLE OF g_rec_item_data                   INDEX BY PLS_INTEGER;
                                                                      --�i�ڃ}�X�^�i�[�p
  TYPE g_tab_shop_lns           IS TABLE OF xxcos_shop_digestion_lns%ROWTYPE  INDEX BY PLS_INTEGER;
                                                                      --�X�ܕʗp�����v�Z���׃e�[�u��
  TYPE g_tab_shop_hdrs          IS TABLE OF xxcos_shop_digestion_hdrs%ROWTYPE INDEX BY PLS_INTEGER;
                                                                      --�X�ܕʗp�����v�Z�w�b�_�e�[�u��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --���̓p�����[�^
  gv_base_code                  VARCHAR2(10);                         -- ���_�R�[�h
  gv_cust_code                  VARCHAR2(10);                         -- �ڋq�R�[�h
  --�O���[�o���J�E���^�[
  gn_cust_cnt                   NUMBER;                               -- �ڋq�}�X�^�Ώی���
  gn_ar_cnt                     NUMBER;                               -- AR������w�b�_�Ώی���
  gn_inv_cnt                    NUMBER;                               -- INV�����I���󕥕\�Ώی���
  gn_uncalc_cnt1                NUMBER;                               -- ���v�Z�敪�P����
  gn_uncalc_cnt2                NUMBER;                               -- ���v�Z�敪�Q����
  gn_uncalc_cnt3                NUMBER;                               -- ���v�Z�敪�R����
  gn_line_count                 NUMBER;                               -- ���׃J�E���g
  gn_header_count               NUMBER;                               -- �w�b�_�J�E���g
  --
  gn_org_id                     NUMBER;                               -- �c�ƒP��
  --���t�֘A
  gd_process_date               DATE;                                 -- �Ɩ����t
  gd_begi_month_date            DATE;                                 -- �O���J�n��
  gd_last_month_date            DATE;                                 -- �O������
  gv_month_date                 VARCHAR(6);                           -- �O��(�N��)
  gd_max_date                   DATE;                                 -- MAX���t
--
  gt_organization_code          mtl_parameters.organization_code%TYPE;-- �݌ɑg�D�R�[�h
  gt_organization_id            mtl_parameters.organization_id%TYPE;  -- �݌ɑg�DID
--
  gt_tab_cust_data              g_tab_cust_data;                      --�Ώیڋq�f�[�^�擾�p
  gt_tab_item_data              g_tab_item_data;                      --�i�ڃ}�X�^�ꎞ�i�[�p
  gt_tab_shop_hdrs              g_tab_shop_hdrs;                      --�X�ܕʗp�����v�Z�w�b�_�i�[�p
  gt_tab_shop_lns               g_tab_shop_lns;                       --�X�ܕʗp�����v�Z���׊i�[�p
  gt_tab_shop_del_hdrs          g_tab_shop_hdrs;                      --����폜�X�ܕʗp�����v�Z�w�b�_�i�[�p
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --���͍��ڕ\��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_pram_date
                    ,iv_token_name1  => cv_tkn_parm_data1
                    ,iv_token_value1 => gv_base_code
                    ,iv_token_name2  => cv_tkn_parm_data2
                    ,iv_token_value2 => gv_cust_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : pram_chk
   * Description      : �p���[���[�^�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE pram_chk(
    ov_errbuf     OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pram_chk'; -- �v���O������
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
    lv_org_id                     VARCHAR2(5000);
    lv_max_date                   VARCHAR2(5000);
    --�G���[���b�Z�[�W�p
    lv_str_api_name               VARCHAR2(5000);                     --�֐���
    lv_str_profile_name           VARCHAR2(5000);                     --�v���t�@�C����
    lv_str_in_param               VARCHAR2(5000);                     --���̓p�����[�^��
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
    --1.�Ɩ����t�擾
    --==============================================================
    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --==================================
    -- 2.XXCOS:MAX���t
    --==================================
    lv_max_date := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_max_date IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_max_date
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date               := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 3.MO:�c�ƒP��
    --==================================
    lv_org_id                 := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_org_id IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_org_id
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_org_id                 := TO_NUMBER( lv_org_id );
--
    --============================================
    -- 4.XXCOI:�݌ɑg�D�R�[�h
    --============================================
    gt_organization_code      := FND_PROFILE.VALUE( ct_prof_organization_code );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_organization_code IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_organization_code
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    --============================================
    -- 5. �݌ɑg�DID�̎擾
    --============================================
    gt_organization_id        := xxcoi_common_pkg.get_organization_id(
                                   iv_organization_code          => gt_organization_code
                                 );
    --
    IF ( gt_organization_id IS NULL ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_organization_id
                                         );
      RAISE global_call_api_expt;
    END IF;
--
    --============================================
    -- 6. ���t�擾
    --============================================
    --�O���J�n�N�����擾
    gd_begi_month_date := TRUNC( ADD_MONTHS( gd_process_date, -1 ), cv_fmt_mm );
    --�O���I���N�����擾
    gd_last_month_date := LAST_DAY( ADD_MONTHS( gd_process_date, -1 ) );
    --�O���N���擾
    gv_month_date      := TO_CHAR( gd_begi_month_date, cv_fmt_yyyymm );
--
    --============================================
    -- 7. ���_�R�[�h�K�{�`�F�b�N
    --============================================
    IF ( gv_base_code IS NULL ) THEN
      lv_str_in_param         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_base_code
                                 );
      RAISE global_require_param_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_process_date_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C���擾��O�n���h�� ***
    WHEN global_get_profile_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_profile_err,
                                   iv_token_name1        => cv_tkn_profile,
                                   iv_token_value1       => lv_str_profile_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐��G���[��O�n���h�� ***
    WHEN global_call_api_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_call_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_str_api_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �K�{���̓p�����[�^���ݒ��O�n���h�� ***
    WHEN global_require_param_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_require_param_err,
                                   iv_token_name1        => cv_tkn_in_param,
                                   iv_token_value1       => lv_str_in_param
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END pram_chk;
--
  /**********************************************************************************
   * Procedure Name   : data_del_former
   * Description      : �X�ܕʗp�����v�Z���̑O��f�[�^�폜(A-2)
   ***********************************************************************************/
  PROCEDURE data_del_former(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_del_former'; -- �v���O������
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    ln_idx                        NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT xsdh.shop_digestion_hdr_id
        FROM xxcos_shop_digestion_hdrs xsdh,
             xxcos_shop_digestion_lns  xsdl
       WHERE xsdh.digestion_due_date         < gd_last_month_date
         AND xsdh.sales_result_creation_flag = ct_make_flag_yes
         AND xsdh.shop_digestion_hdr_id      = xsdl.shop_digestion_ln_id(+)
       FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_lock_rec lock_cur%ROWTYPE;
--
    -- *** ���[�J���E�֐� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.�f�[�^���b�N
    --==================================
    BEGIN
      FOR l_lock_rec IN lock_cur LOOP
        --==================================
        -- 1.�w�b�_���폜
        --==================================
        BEGIN
          DELETE
            FROM xxcos_shop_digestion_hdrs xsdh
           WHERE xsdh.shop_digestion_hdr_id = l_lock_rec.shop_digestion_hdr_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_str_table_name       := xxccp_common_pkg.get_msg(
                                         iv_application        => ct_xxcos_appl_short_name,
                                         iv_name               => ct_msg_get_shop_hdr_name
                                       );
            RAISE global_data_del_expt;
        END;
--
        --==================================
        -- 2.���ו��폜
        --==================================
        BEGIN
          DELETE
            FROM xxcos_shop_digestion_lns xsds
           WHERE xsds.shop_digestion_hdr_id = l_lock_rec.shop_digestion_hdr_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_str_table_name       := xxccp_common_pkg.get_msg(
                                         iv_application        => ct_xxcos_appl_short_name,
                                         iv_name               => ct_msg_get_shop_line_name
                                       );
            RAISE global_data_del_expt;
        END;
      END LOOP;
    EXCEPTION
      --�폜�G���[
      WHEN global_data_del_expt THEN
        lv_str_key_data         := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_key_info1,
                                     iv_token_name1        => cv_tkn_diges_due_dt,
                                     iv_token_value1       => TO_CHAR( gd_last_month_date, cv_fmt_date )
                                   );
        RAISE global_data_del_expt;
      --���b�N�G���[
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      --�e�[�u�����擾
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_shop_data_name
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_lock_err,
                                   iv_token_name1        => cv_tkn_table,
                                   iv_token_value1       => lv_str_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �����Ώۃf�[�^�폜�n���h�� ***
    WHEN global_data_del_expt THEN
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_delete_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END data_del_former;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_data
   * Description      : �ڋq�}�X�^�f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust_data(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_data'; -- �v���O������
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
    CURSOR get_data_cur
    IS
      SELECT hca.cust_account_id cust_account_id,                     --�ڋq�}�X�^.�ڋqID
             hca.account_number  account_number,                      --�ڋq�}�X�^.�ڋq�R�[�h
             hca.party_id        party_id,                            --�ڋq�}�X�^.�p�[�e�BID
             xca.rate            rate,                                --�ڋq�A�h�I���}�X�^.�����v�Z�p�|��
             NVL( xca.past_sale_base_code, xca.sale_base_code ) base_code,
                                                                      --�ڋq�A�h�I���}�X�^.�O�����㋒�_�R�[�h
                                                                      -- or ���㋒�_�R�[�h
             xca.business_low_type business_low_type,                 --�ڋq�A�h�I���}�X�^.�Ƒԏ�����
             xca.delivery_base_code delivery_base_code,               --�ڋq�A�h�I���}�X�^.�[�i���_�R�[�h
             xsh.shop_digestion_hdr_id                                --�X�ܕʗp�����v�Z�w�b�_.�X�ܕʗp�����v�Z�w�b�_ID
        FROM hz_cust_accounts          hca,                           --�ڋq�}�X�^
             xxcmm_cust_accounts       xca,                           --�ڋq�A�h�I���}�X�^
             xxcos_shop_digestion_hdrs xsh                            --�X�ܕʗp�����v�Z�w�b�_�e�[�u��
       -- �ڋq�}�X�^.�ڋqID = �ڋq�A�h�I���}�X�^.�ڋqID
       WHERE hca.cust_account_id       = xca.customer_id
         --�ڋq�A�h�I���}�X�^.�Ƒԏ�����=�C���V���b�v,���В��c�X
         AND EXISTS (SELECT flv.meaning                   meaning
                       FROM fnd_application               fa,
                            fnd_lookup_types              flt,
                            fnd_lookup_values             flv
                      WHERE fa.application_id                               =    flt.application_id
                        AND flt.lookup_type                                 =    flv.lookup_type
                        AND fa.application_short_name                       =    ct_xxcos_appl_short_name
                        AND flv.lookup_type                                 =    ct_qct_gyo_type
                        AND flv.lookup_code                                 LIKE ct_qcc_it_code
                        AND flv.start_date_active                          <=    gd_last_month_date
                        AND NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
                        AND flv.enabled_flag                                =    ct_enabled_flag_yes
                        AND flv.language                                    =    USERENV( 'LANG' )
                        AND flv.meaning                                     =    xca.business_low_type
             )
         --NVL(�ڋq�A�h�I��.�O�����㋒�_�R�[�h,�ڋq�A�h�I��.���㋒�_�R�[�h) IN ���_�R�[�h�ɑ����鋒�_���T�u�N�G��
         AND NVL( xca.past_sale_base_code, xca.sale_base_code ) IN (
                    SELECT gv_base_code         base_code             -- ���[�U�[���_�R�[�h
                      FROM DUAL
                    UNION
                    SELECT hcai.account_number  base_code             -- ���[�U�[���_�R�[�h
                      FROM hz_cust_accounts    hcai,                  -- �ڋq�}�X�^
                           xxcmm_cust_accounts xcai                   -- �ڋq�A�h�I���}�X�^
                     -- �ڋq�}�X�^.�ڋqID = �ڋq�A�h�I���}�X�^.�ڋqID
                     WHERE hcai.cust_account_id      = xcai.customer_id
                       --�ڋq�A�h�I���}�X�^.�Ǘ������_�R�[�h = �p�����[�^�̋��_�R�[�h
                       AND xcai.management_base_code = gv_base_code
                       --�ڋq�}�X�^.�ڋq�敪 = 1(���_)
                       AND EXISTS (SELECT flv.meaning                   meaning
                                   FROM   fnd_application               fa,
                                          fnd_lookup_types              flt,
                                          fnd_lookup_values             flv
                                   WHERE  fa.application_id                               =    flt.application_id
                                     AND  flt.lookup_type                                 =    flv.lookup_type
                                     AND  fa.application_short_name                       =    ct_xxcos_appl_short_name
                                     AND  flv.lookup_type                                 =    ct_qct_cust_type
                                     AND  flv.lookup_code                                 LIKE ct_qcc_cust_code_1
                                     AND  flv.start_date_active                          <=    gd_last_month_date
                                     AND  NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
                                     AND  flv.enabled_flag                                =    ct_enabled_flag_yes
                                     AND  flv.language                                    =    USERENV( 'LANG' )
                                     AND  flv.meaning                                     =    hcai.customer_class_code
                                  )
             )
         --�ڋq�}�X�^.�ڋq�R�[�h = NVL(IN�p��(�ڋq�R�[�h),�ڋq�}�X�^.�ڋq�R�[�h)
         AND hca.account_number                = NVL( gv_cust_code, hca.account_number )
         --�X�ܕʗp�����v�Z�w�b�_.�����v�Z���N����(+) = �O���I���N����
         AND xsh.digestion_due_date(+)         = gd_last_month_date
         --�ڋq�}�X�^.�ڋqID = �X�ܕʗp�����v�Z�w�b�_.�ڋqID(+)
         AND hca.cust_account_id               = xsh.cust_account_id(+)
         --�X�ܕʗp�����v�Z�w�b�_.�̔����э쐬�t���O(+) = 'N'
         AND xsh.sales_result_creation_flag(+) = ct_make_flag_no
         --NVL(�ڋq�A�h�I���}�X�^.���~���ϓ�,�O���I���N����) BETWEEN �O���J�n�� AND �O���I���N����
         AND NVL( xca.stop_approval_date, gd_last_month_date ) BETWEEN gd_begi_month_date AND gd_last_month_date
         --�ڋq�}�X�^.�ڋq�敪 = 10:�ڋq(2009/02/10 1.2)
         AND EXISTS (SELECT flv.meaning
                     FROM   fnd_application               fa,
                            fnd_lookup_types              flt,
                            fnd_lookup_values             flv
                     WHERE  fa.application_id                               =    flt.application_id
                     AND    flt.lookup_type                                 =    flv.lookup_type
                     AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
                     AND    flv.lookup_type                                 =    ct_qct_cust_type
                     AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_2
                     AND    flv.start_date_active                          <=    gd_last_month_date
                     AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
                     AND    flv.enabled_flag                                =    ct_enabled_flag_yes
                     AND    flv.language                                    =    USERENV( 'LANG' )
                     AND    flv.meaning                                     =    hca.customer_class_code
                    )
      ORDER BY hca.account_number --�ڋq�}�X�^.�ڋq�R�[�h
    ;
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
    --�Ώۃf�[�^�擾�p�J�[�\��OPEN
    BEGIN
      OPEN get_data_cur;
      -- �o���N�t�F�b�`
      FETCH get_data_cur BULK COLLECT INTO gt_tab_cust_data;
      --�擾����
      gn_cust_cnt := get_data_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE get_data_cur;
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�[�i�w�b�_���[�N�e�[�u���f�[�^�擾
        IF ( get_data_cur%ISOPEN ) THEN
          CLOSE get_data_cur;
        END IF;
        --
        RAISE global_select_err_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --���o�Ώۂ�0���������ꍇ
    IF ( gn_cust_cnt = 0 ) THEN
      RAISE global_no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ώۃf�[�^�O���G���[ ***
    WHEN global_no_data_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  cv_msg_nodata_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    -- *** SQL SELECT �G���[ ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_select_cust_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => gv_base_code,
                                   iv_token_name2        => cv_tkn_parm_data2,
                                   iv_token_value2       => gv_cust_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#####################################  �Œ蕔 START ##########################################
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
  END get_cust_data;
--
  /**********************************************************************************
   * Procedure Name   : data_del_now
   * Description      : �X�ܕʗp�����v�Z���̍���f�[�^�폜(A-4)
   ***********************************************************************************/
  PROCEDURE data_del_now(
    ov_errbuf          OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_del_now'; -- �v���O������
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    ln_idx                        NUMBER;
    lt_customer_number            xxcos_shop_digestion_hdrs.customer_number%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur(
      it_customer_number          xxcos_shop_digestion_hdrs.customer_number%TYPE
    )
    IS
      SELECT xsdh.customer_number        customer_number
        FROM xxcos_shop_digestion_hdrs   xsdh,
             xxcos_shop_digestion_lns    xsdl
       WHERE xsdh.digestion_due_date         = gd_last_month_date
         AND xsdh.shop_digestion_hdr_id      = xsdl.shop_digestion_ln_id(+)
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_lock_rec lock_cur%ROWTYPE;
--
    -- *** ���[�J���E�֐� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.����VD���f�[�^���b�N
    --==================================
    <<lock_loop>>
    FOR i IN 1..gt_tab_shop_del_hdrs.COUNT LOOP
      --�ڋq�R�[�h�ݒ�
      lt_customer_number := gt_tab_shop_del_hdrs(i).customer_number;
      --==================================
      -- 1.����VD���f�[�^���b�N
      --==================================
      BEGIN
        OPEN lock_cur( it_customer_number => gt_tab_shop_del_hdrs(i).customer_number );
        CLOSE lock_cur;
      EXCEPTION
        WHEN global_data_lock_expt THEN
          RAISE global_data_lock_expt;
      END;
  --
      --==================================
      -- 1.�w�b�_���폜
      --==================================
      BEGIN
        DELETE
          FROM xxcos_shop_digestion_hdrs xsdh
         WHERE xsdh.customer_number            = gt_tab_shop_del_hdrs(i).customer_number
           AND xsdh.digestion_due_date         = gd_last_month_date
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_str_table_name       := xxccp_common_pkg.get_msg(
                                       iv_application        => ct_xxcos_appl_short_name,
                                       iv_name               => ct_msg_get_shop_hdr_name
                                     );
          RAISE global_data_del_expt;
      END;
  --
      --==================================
      -- 2.���ו��폜
      --==================================
      BEGIN
        DELETE
          FROM xxcos_shop_digestion_lns xsds
         WHERE xsds.customer_number            = gt_tab_shop_del_hdrs(i).customer_number
           AND xsds.digestion_due_date         = gd_last_month_date
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_str_table_name       := xxccp_common_pkg.get_msg(
                                       iv_application        => ct_xxcos_appl_short_name,
                                       iv_name               => ct_msg_get_shop_line_name
                                     );
          RAISE global_data_del_expt;
      END;
    END LOOP lock_loop;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --�e�[�u�����擾
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_shop_data_name
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_lock_err,
                                   iv_token_name1        => cv_tkn_table,
                                   iv_token_value1       => lv_str_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �����Ώۃf�[�^�폜�n���h�� ***
    WHEN global_data_del_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      lv_str_key_data         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_key_info2,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => TO_CHAR( gd_last_month_date, cv_fmt_date ),
                                   iv_token_name2        => cv_tkn_parm_data2,
                                   iv_token_value2       => lt_customer_number
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_delete_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END data_del_now;
--
  /**********************************************************************************
   * Procedure Name   : init_header
   * Description      : �w�b�_�P�ʏ���������(A-5)
   ***********************************************************************************/
  PROCEDURE init_header(
    it_party_id                    IN  hz_cust_accounts.party_id%TYPE,--  �p�[�e�BID
    it_customer_number             IN  xxcos_shop_digestion_hdrs.customer_number%TYPE,
                                                                      --  �ڋq�R�[�h
    ot_shop_digestion_hdr_id       OUT xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE,
                                                                      --  �X�ܕʗp�����v�Z�w�b�_ID
    ov_ar_uncalculate_type         OUT VARCHAR2,                      --  AR���v�Z�敪
    ov_inv_uncalculate_type        OUT VARCHAR2,                      --  INV���v�Z�敪
    on_sales_amount                OUT NUMBER,                        --  �X�ܕʔ�����z
    on_check_amount                OUT NUMBER,                        --  �`�F�b�N�p�X�ܕʔ�����z
    ot_performance_by_code         OUT xxcos_shop_digestion_hdrs.performance_by_code%TYPE,
                                                                      --  �c�ƒS�����R�[�h
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_header'; -- �v���O������
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
    --==================================
    -- 1.����VD�p�����v�Z�w�b�_ID�̎擾
    --==================================
    BEGIN
      SELECT xxcos_shop_digestion_hdrs_s01.NEXTVAL       shop_digestion_hdr_id
        INTO ot_shop_digestion_hdr_id
        FROM dual
      ;
    END;
--
    --==================================
    -- 2.�e��ϐ��N���A����
    --==================================
    ov_ar_uncalculate_type   := cv_uncalculate_type_init;
    ov_inv_uncalculate_type  := cv_uncalculate_type_init;
    on_sales_amount          := cn_amount_default;
    on_check_amount          := cn_amount_default;
--
    --==================================
    -- 3.�c�ƒS�����R�[�h�擾
    --==================================
    BEGIN
      SELECT xsv.employee_number
        INTO ot_performance_by_code
        FROM xxcos_salesreps_v xsv
       WHERE xsv.party_id                                         = it_party_id
         AND xsv.effective_start_date                            <= gd_last_month_date
         AND NVL( xsv.effective_end_date, gd_last_month_date )   >= gd_last_month_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_select_err_expt;
    END;
--
  EXCEPTION
    -- *** SQL SELECT �G���[ ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_select_salesreps_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => it_customer_number
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END init_header;
--
  /**********************************************************************************
   * Procedure Name   : get_ar_data
   * Description      : AR������擾����(A-6)
   ***********************************************************************************/
  PROCEDURE get_ar_data(
    it_cust_account_id     IN  hz_cust_accounts.cust_account_id%TYPE, --�ڋqID
    it_account_number      IN  hz_cust_accounts.account_number%TYPE,  --�ڋq�R�[�h
    ov_ar_uncalculate_type OUT VARCHAR2,                              --AR���v�Z�敪
    on_sales_amount        OUT NUMBER,                                --�X�ܕʔ�����z
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_data'; -- �v���O������
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
    ln_ar_amount                        NUMBER;                       --������z���v
    lv_exists_flag                      VARCHAR2(1);
--
    -- *** ���[�J���E�J�[�\�� ***
    -- AR������擾����
    CURSOR ar_cur
    IS
      SELECT rctlgda.gl_date                     gl_date,             --����v���
             rctla.extended_amount               extended_amount      --�{�̋��z
        FROM ra_customer_trx_all                 rcta,                --AR������e�[�u��
             ra_customer_trx_lines_all           rctla,               --AR������׃e�[�u��
             ra_cust_trx_line_gl_dist_all        rctlgda,             --AR������׉�v�z���e�[�u��
             ra_cust_trx_types_all               rctta                --AR����^�C�v�}�X�^
       WHERE rcta.ship_to_customer_id          = it_cust_account_id
         AND rcta.customer_trx_id              = rctla.customer_trx_id
         AND rctla.customer_trx_id             = rctlgda.customer_trx_id
         AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
         AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
         AND rctla.line_type                   = ct_line_type_line
         AND rcta.complete_flag                = ct_complete_flag_yes
         AND rctlgda.gl_date                  >= gd_begi_month_date
         AND rctlgda.gl_date                  <= gd_last_month_date
         AND rcta.org_id                       = gn_org_id
         AND EXISTS(SELECT cv_exists_flag_yes               exists_flag
                      FROM fnd_application                  fa,
                           fnd_lookup_types                 flt,
                           fnd_lookup_values                flv
                     WHERE fa.application_id           =    flt.application_id
                       AND flt.lookup_type             =    flv.lookup_type
                       AND fa.application_short_name   =    ct_xxcos_appl_short_name
                       AND flv.lookup_type             =    ct_qct_customer_trx_type
                       AND flv.lookup_code             LIKE ct_qcc_customer_trx_type1
                       AND flv.meaning                 =    rctta.name
                       AND rctlgda.gl_date            >=    flv.start_date_active
                       AND rctlgda.gl_date            <=    NVL( flv.end_date_active, gd_max_date )
                       AND flv.enabled_flag            =    ct_enabled_flag_yes
                       AND flv.language                =    USERENV( 'LANG' )
                       AND ROWNUM                      =    1
             )
      UNION ALL
      SELECT rctlgda.gl_date                     gl_date,             --����v���
             rctla.extended_amount               extended_amount      --�{�̋��z
        FROM ra_customer_trx_all                 rcta,                --����������e�[�u��
             ra_customer_trx_lines_all           rctla,               --����������׃e�[�u��
             ra_cust_trx_line_gl_dist_all        rctlgda,             --����������׉�v�z���e�[�u��
             ra_cust_trx_types_all               rctta                --��������^�C�v�}�X�^
       WHERE rcta.ship_to_customer_id          = it_cust_account_id
         AND rcta.customer_trx_id              = rctla.customer_trx_id
         AND rctla.customer_trx_id             = rctlgda.customer_trx_id
         AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
         AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
         AND rctla.line_type                   = ct_line_type_line
         AND rcta.complete_flag                = ct_complete_flag_yes
         AND rctlgda.gl_date                  >= gd_begi_month_date
         AND rctlgda.gl_date                  <= gd_last_month_date
         AND rcta.org_id                       = gn_org_id
         AND rcta.org_id                       = rctta.org_id
         AND EXISTS(SELECT cv_exists_flag_yes               exists_flag
                      FROM fnd_application                  fa,
                           fnd_lookup_types                 flt,
                           fnd_lookup_values                flv
                     WHERE fa.application_id           =    flt.application_id
                       AND flt.lookup_type             =    flv.lookup_type
                       AND fa.application_short_name   =    ct_xxcos_appl_short_name
                       AND flv.lookup_type             =    ct_qct_customer_trx_type
                       AND flv.lookup_code             LIKE ct_qcc_customer_trx_type2
                       AND flv.meaning                 =    rctta.name
                       AND rctlgda.gl_date            >=    flv.start_date_active
                       AND rctlgda.gl_date            <=    NVL( flv.end_date_active, gd_max_date )
                       AND flv.enabled_flag            =    ct_enabled_flag_yes
                       AND flv.language                =    USERENV( 'LANG' )
                       AND ROWNUM                      =    1
             )
         AND rcta.previous_customer_trx_id     IS NULL
      UNION ALL
      SELECT rctlgda.gl_date                     gl_date,             --����v���
             rctla.extended_amount               extended_amount      --�{�̋��z
        FROM ra_customer_trx_all                 rcta,                --����������e�[�u��
             ra_customer_trx_lines_all           rctla,               --����������׃e�[�u��
             ra_cust_trx_line_gl_dist_all        rctlgda,             --����������׉�v�z���e�[�u��
             ra_cust_trx_types_all               rctta,               --��������^�C�v�}�X�^
             ra_customer_trx_all                 rcta2,               --����������e�[�u��(��)
             ra_cust_trx_types_all               rctta2               --��������^�C�v�}�X�^(��)
       WHERE rcta.ship_to_customer_id          = it_cust_account_id
         AND rcta.customer_trx_id              = rctla.customer_trx_id
         AND rctla.customer_trx_id             = rctlgda.customer_trx_id
         AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
         AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
         AND rctla.line_type                   = ct_line_type_line
         AND rcta.complete_flag                = ct_complete_flag_yes
         AND rctlgda.gl_date                  >= gd_begi_month_date
         AND rctlgda.gl_date                  <= gd_last_month_date
         AND rcta.org_id                       = gn_org_id
         AND rcta.org_id                       = rctta.org_id
         AND EXISTS(SELECT cv_exists_flag_yes               exists_flag
                      FROM fnd_application                  fa,
                           fnd_lookup_types                 flt,
                           fnd_lookup_values                flv
                     WHERE fa.application_id           =    flt.application_id
                       AND flt.lookup_type             =    flv.lookup_type
                       AND fa.application_short_name   =    ct_xxcos_appl_short_name
                       AND flv.lookup_type             =    ct_qct_customer_trx_type
                       AND flv.lookup_code             LIKE ct_qcc_customer_trx_type2
                       AND flv.meaning                 =    rctta.name
                       AND rctlgda.gl_date            >=    flv.start_date_active
                       AND rctlgda.gl_date            <=    NVL( flv.end_date_active, gd_max_date )
                       AND flv.enabled_flag            =    ct_enabled_flag_yes
                       AND flv.language                =    USERENV( 'LANG' )
                       AND ROWNUM                      =    1
             )
         AND rcta.previous_customer_trx_id     = rcta2.customer_trx_id
         AND rcta2.cust_trx_type_id            = rctta2.cust_trx_type_id
         AND rcta2.org_id                      = rctta2.org_id
         AND EXISTS(SELECT cv_exists_flag_yes               exists_flag
                      FROM fnd_application                  fa,
                           fnd_lookup_types                 flt,
                           fnd_lookup_values                flv
                     WHERE fa.application_id           =    flt.application_id
                       AND flt.lookup_type             =    flv.lookup_type
                       AND fa.application_short_name   =    ct_xxcos_appl_short_name
                       AND flv.lookup_type             =    ct_qct_customer_trx_type
                       AND flv.lookup_code             LIKE ct_qcc_customer_trx_type1
                       AND flv.meaning                 =    rctta2.name
                       AND rctlgda.gl_date            >=    flv.start_date_active
                       AND rctlgda.gl_date            <=    NVL( flv.end_date_active, gd_max_date )
                       AND flv.enabled_flag            =    ct_enabled_flag_yes
                       AND flv.language                =    USERENV( 'LANG' )
                       AND ROWNUM                      =    1
             )
      ;
    -- AR������ ���R�[�h�^
    l_ar_rec ar_cur%ROWTYPE;
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
    -- ������
    lv_exists_flag            := cv_exists_flag_no;
    ln_ar_amount              := cn_amount_default;
    --
    -- ===================================================
    --1.AR������
    -- ===================================================
    BEGIN
      <<ar_loop>>
      FOR ar_rec IN ar_cur
      LOOP
        --�Z�b�g
        l_ar_rec                := ar_rec;
        -- ���݃t���O
        lv_exists_flag          := cv_exists_flag_yes;
        -- ===================================================
        -- A-7  ������z�W�v����
        -- ===================================================
        ln_ar_amount            := ln_ar_amount + l_ar_rec.extended_amount;
      --
      END LOOP ar_loop;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_select_err_expt;
    END;
    --
    IF ( lv_exists_flag = cv_exists_flag_no ) THEN
      ov_ar_uncalculate_type := cv_uncalculate_type_nof;
    ELSIF ( ln_ar_amount = cn_amount_default ) THEN
      ov_ar_uncalculate_type := cv_uncalculate_type_zero;
    ELSE
      ov_ar_uncalculate_type := cv_uncalculate_type_init;
    END IF;
    -- �ԋp
    on_sales_amount              := ln_ar_amount;
--
  EXCEPTION
    -- *** SQL SELECT �G���[ ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_select_ar_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => it_account_number
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_ar_data;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_data
   * Description      : INV�����݌Ɏ󕥂��\���擾����(A-8)
   ***********************************************************************************/
  PROCEDURE get_inv_data(
    it_tab_cust_data         IN g_rec_cust_data,                      --�ڋq���
    it_shop_digestion_hdr_id IN xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE,
                                                                      --�X�ܕʗp�����v�Z�w�b�_ID
    ov_inv_uncalculate_type  OUT VARCHAR2,                            --INV���v�Z�敪
    on_check_amount          OUT NUMBER,                              --�`�F�b�N�p�X�ܕʔ�����z
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_data'; -- �v���O������
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
    lv_exists_flag                      VARCHAR2(1);
    lv_branch_num                       NUMBER;                       --�}��
    ln_check_amount                     NUMBER;                       --�`�F�b�N�p�X�ܕʔ�����z
    lt_inventory_item_id                xxcoi_inv_reception_monthly.inventory_item_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- INV������擾����
    CURSOR inv_cur
    IS
      SELECT sirm.inv_seq                inv_seq,                     --�I��SEQ
             sirm.inventory_item_id      inventory_item_id,           --�i��ID
             sirm.organization_id        organization_id,             --�݌ɑg�DID
             sirm.operation_cost         operation_cost,              --�c�ƌ���
             sirm.standard_cost          standard_cost,               --�W������
             sirm.inv_wear               inv_wear,                    --�̔���(�I������)
--             sirm.inv_wear * -1          inv_wear,                    --�̔���(�I������)
             sirm.subinventory_code      subinventory_code            --�ۊǏꏊ
        FROM xxcoi_inv_reception_monthly sirm,
             mtl_secondary_inventories   msi
       --INV�����݌Ɏ󕥕\.�ۊǏꏊ      = �ۊǏꏊ�}�X�^.�ۊǏꏊ
       WHERE sirm.subinventory_code = msi.secondary_inventory_name
         --�ۊǏꏊ�}�X�^.[DFF2]�I���敪   = '2'�u�����v
         AND msi.attribute5         = ct_secondary_class_2
         --�ۊǏꏊ�}�X�^.[DFF4]�ڋq�R�[�h = �ڋq�R�[�h
         AND msi.attribute4         = it_tab_cust_data.account_number
         --�ۊǏꏊ�}�X�^.[DFF7]���_�R�[�h = �[�i���_�R�[�h
--******************************* 2009/03/19 1.6 T.Kitajima MOD START ***************************************
--         --�ۊǏꏊ�}�X�^.[DFF7]���_�R�[�h = �[�i���_�R�[�h
--         AND msi.attribute7         = it_tab_cust_data.delivery_base_code
--         --INV�����݌Ɏ󕥕\.���_�R�[�h    = �[�i���_�R�[�h
--         AND sirm.base_code         = it_tab_cust_data.delivery_base_code
         --�ۊǏꏊ�}�X�^.[DFF7]���_�R�[�h = �ڋq�A�h�I���}�X�^.�O�����㋒�_�R�[�h or ���㋒�_�R�[�h
         AND msi.attribute7         = it_tab_cust_data.past_sale_base_code
         --INV�����݌Ɏ󕥕\.���_�R�[�h    = �ڋq�A�h�I���}�X�^.�O�����㋒�_�R�[�h or ���㋒�_�R�[�h
         AND sirm.base_code         = it_tab_cust_data.past_sale_base_code
--******************************* 2009/03/19 1.6 T.Kitajima MOD  END  ***************************************
         --INV�����݌Ɏ󕥕\.�g�DID        = �݌ɑg�DID
         AND sirm.organization_id   = gt_organization_id
         --INV�����݌Ɏ󕥕\.�N��          = �O���N��
         AND sirm.practice_month    = gv_month_date
         --INV�����݌Ɏ󕥕\.�I���敪      = '2'�u�����v
         AND sirm.inventory_kbn     = ct_inventory_class_2
      ;
    -- INV������ ���R�[�h�^
    l_inv_rec inv_cur%ROWTYPE;
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
    -- ������
    lv_exists_flag            := cv_exists_flag_no;
    lv_branch_num             := 1;
    ln_check_amount           := 0;
    --
    --INV�f�[�^���[�v
    BEGIN
      <<inv_loop>>
      FOR inv_rec IN inv_cur LOOP
        --�Z�b�g
        l_inv_rec            := inv_rec;
        lv_exists_flag       := cv_exists_flag_yes;
        lt_inventory_item_id := l_inv_rec.inventory_item_id;
--
        -- ===============================
        -- A-9.�i�ڃ}�X�^�f�[�^�擾����
        -- ===============================
        IF ( gt_tab_item_data.COUNT = 0 ) OR
           ( gt_tab_item_data.EXISTS( lt_inventory_item_id )  = FALSE ) THEN
--
          --�i�ڃ}�X�^����擾
          BEGIN
            SELECT itm.segment1                segment1,
                   itm.primary_unit_of_measure primary_unit_of_measure,
                   itm.fixed_price             fixed_price
              INTO gt_tab_item_data(lt_inventory_item_id)
              FROM (SELECT mib.segment1                segment1,                    --�i�ڃR�[�h
                           mib.primary_unit_of_measure primary_unit_of_measure,     --�P�ʃR�[�h
                           csi.fixed_price             fixed_price                  --�艿
                      FROM mtl_system_items_b         mib,                          --�i�ڃ}�X�^
                           xxcmm_system_items_b_hst   csi                           --Disc�i�ڕύX�����A�h�I��
                     --�i�ڃ}�X�^.�i��ID               = �i��ID
                     WHERE mib.inventory_item_id      = lt_inventory_item_id
                       --�i�ڃ}�X�^.�݌ɑg�DID           = �݌ɑg�DID
                       AND mib.organization_id        = gt_organization_id
                       --�i�ڃ}�X�^.�i�ڃR�[�h           = Disc�i�ڕύX�����A�h�I��.�i�ڃR�[�h
                       AND mib.segment1               = csi.item_code
                       --Disc�i�ڕύX�����A�h�I��.�K�p�� ���O���I���N����
                       AND csi.apply_date            <= gd_last_month_date
                       --Disc�i�ڕύX�����A�h�I��.�K�p�t���O = 'Y'
                       AND csi.apply_flag             = ct_apply_flag_yes
                       --Disc�i�ڕύX�����A�h�I��.�艿 IS NOT NULL
                       AND csi.fixed_price            IS NOT NULL
                     ORDER BY mib.segment1,
                              csi.apply_date DESC
                   ) itm
             WHERE ROWNUM                     = 1
            ;
          EXCEPTION
            WHEN OTHERS THEN
              RAISE global_get_item_err_expt;
          END;
        END IF;
--
        -- ===============================
        -- A-10.�X�ܕʗp�����v�Z���דo�^����
        -- ===============================
        --�X�ܕʗp�����v�Z����ID
        SELECT xxcos_shop_digestion_lns_s01.NEXTVAL
          INTO gt_tab_shop_lns(gn_line_count).shop_digestion_ln_id
          FROM DUAL
        ;
        --�X�ܕʗp�����v�Z�w�b�_ID
        gt_tab_shop_lns(gn_line_count).shop_digestion_hdr_id
                                          := it_shop_digestion_hdr_id;
        --�����v�Z���N����
        gt_tab_shop_lns(gn_line_count).digestion_due_date
                                          := gd_last_month_date;
        --�ڋq�R�[�h
        gt_tab_shop_lns(gn_line_count).customer_number
                                          := it_tab_cust_data.account_number;
        --�}��
        gt_tab_shop_lns(gn_line_count).digestion_ln_number
                                          := lv_branch_num;
        lv_branch_num                     := lv_branch_num + 1;
        --�i�ڃR�[�h
        gt_tab_shop_lns(gn_line_count).item_code
                                          := gt_tab_item_data(lt_inventory_item_id).segment1;
        --�I��SEQ
        gt_tab_shop_lns(gn_line_count).invent_seq
                                          := l_inv_rec.inv_seq;
        --�艿
        gt_tab_shop_lns(gn_line_count).item_price
                                          := gt_tab_item_data(lt_inventory_item_id).fixed_price;
        --�i��ID
        gt_tab_shop_lns(gn_line_count).inventory_item_id
                                          := lt_inventory_item_id;
        --�c�ƌ���
        gt_tab_shop_lns(gn_line_count).business_cost
                                          := l_inv_rec.operation_cost;
        --�W������
        gt_tab_shop_lns(gn_line_count).standard_cost
                                          := l_inv_rec.standard_cost;
        --�X�ܕi�ڕʔ̔����z
        gt_tab_shop_lns(gn_line_count).item_sales_amount
                                          := l_inv_rec.inv_wear * gt_tab_shop_lns(gn_line_count).item_price;
        --�P�ʃR�[�h
        gt_tab_shop_lns(gn_line_count).uom_code
                                          := gt_tab_item_data(lt_inventory_item_id).primary_unit_of_measure;
        --�̔���
        gt_tab_shop_lns(gn_line_count).sales_quantity
                                          := l_inv_rec.inv_wear;
        --�[�i���_�R�[�h
        gt_tab_shop_lns(gn_line_count).delivery_base_code
                                          := it_tab_cust_data.delivery_base_code;
        --�o�׌��ۊǏꏊ
        gt_tab_shop_lns(gn_line_count).ship_from_subinventory_code
                                          := l_inv_rec.subinventory_code;
        --�쐬��
        gt_tab_shop_lns(gn_line_count).created_by
                                          := cn_created_by;
        --�쐬��
        gt_tab_shop_lns(gn_line_count).creation_date
                                          := cd_creation_date;
        --�ŏI�X�V��
        gt_tab_shop_lns(gn_line_count).last_updated_by
                                          := cn_last_updated_by;
        --�ŏI�X�V��
        gt_tab_shop_lns(gn_line_count).last_update_date
                                          := cd_last_update_date;
        --�ŏI�X�V۸޲�
        gt_tab_shop_lns(gn_line_count).last_update_login
                                          := cn_last_update_login;
        --�v��ID
        gt_tab_shop_lns(gn_line_count).request_id
                                          := cn_request_id;
        --�ݶ��ĥ��۸��ѥ���ع����ID
        gt_tab_shop_lns(gn_line_count).program_application_id
                                          := cn_program_application_id;
        --�ݶ��ĥ��۸���ID
        gt_tab_shop_lns(gn_line_count).program_id
                                          := cn_program_id;
        --��۸��эX�V��
        gt_tab_shop_lns(gn_line_count).program_update_date
                                          := cd_program_update_date;
--
      -- ===============================
      -- A-11.�`�F�b�N�p������z�W�v����
      -- ===============================
        ln_check_amount                   := ln_check_amount
                                               + TO_NUMBER( gt_tab_shop_lns(gn_line_count).item_sales_amount );
--
        --���׃J�E���g�A�b�v
        gn_line_count                     := gn_line_count + 1;
--
      END LOOP inv_loop;
--
    EXCEPTION
      WHEN global_get_item_err_expt THEN
        RAISE global_get_item_err_expt;
      WHEN OTHERS THEN
        RAISE global_select_err_expt;
    END;
--
    --�擾�ł��Ă��邩
    IF ( lv_exists_flag = cv_exists_flag_no ) THEN
      ov_inv_uncalculate_type := cv_uncalculate_type_nof;
    --�`�F�b�N�p���㍇�v��0��
    ELSIF ( ln_check_amount = 0 ) THEN
      ov_inv_uncalculate_type := cv_uncalculate_type_zero;
    ELSE
      ov_inv_uncalculate_type := cv_uncalculate_type_init;
    END IF;
    --�`�F�b�N���z�ԋp
    on_check_amount := ln_check_amount;
--
  EXCEPTION
    -- *** �i�ڃ}�X�^�擾 �G���[ ***
    WHEN global_get_item_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_select_item_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => lt_inventory_item_id
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** SQL SELECT �G���[ ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_select_inv_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => it_tab_cust_data.account_number
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_inv_data;
--
  /**********************************************************************************
   * Procedure Name   : set_header
   * Description      : �X�ܕʗp�����v�Z�w�b�_�o�^����(A-12)
   ***********************************************************************************/
  PROCEDURE set_header(
    it_tab_cust_data         IN g_rec_cust_data,                      --�ڋq���
    it_shop_digestion_hdr_id IN xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE,
                                                                      --�X�ܕʗp�����v�Z�w�b�_ID
    iv_ar_uncalculate_type   IN VARCHAR2,                             --AR���v�Z�敪
    iv_inv_uncalculate_type  IN VARCHAR2,                             --INV���v�Z�敪
    in_sales_amount          IN NUMBER,                               --�X�ܕʔ�����z
    in_check_amount          IN NUMBER,                               --�`�F�b�N�p�X�ܕʔ�����z
    it_performance_by_code   IN xxcos_shop_digestion_hdrs.performance_by_code%TYPE,
                                                                      --�c�ƒS�����R�[�h
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_header'; -- �v���O������
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
      --�X�ܕʗp�����v�Z�w�b�_ID
      gt_tab_shop_hdrs(gn_header_count).shop_digestion_hdr_id
                                          := it_shop_digestion_hdr_id;
      --�����v�Z���N����
      gt_tab_shop_hdrs(gn_header_count).digestion_due_date
                                          := gd_last_month_date;
      --�ڋq�R�[�h
      gt_tab_shop_hdrs(gn_header_count).customer_number
                                          := it_tab_cust_data.account_number;
      --���㋒�_�R�[�h
      gt_tab_shop_hdrs(gn_header_count).sales_base_code
                                          := it_tab_cust_data.past_sale_base_code;
      --�ڋqID
      gt_tab_shop_hdrs(gn_header_count).cust_account_id
                                          := it_tab_cust_data.cust_account_id;
      --�����v�Z���s��
      gt_tab_shop_hdrs(gn_header_count).digestion_exe_date
                                          := gd_process_date;
      --�X�ܕʔ�����z
      gt_tab_shop_hdrs(gn_header_count).ar_sales_amount
                                          := in_sales_amount;
      --�`�F�b�N�p������z
      gt_tab_shop_hdrs(gn_header_count).check_sales_amount
                                          := in_check_amount;
      --�����v�Z�|��
      IF ( in_sales_amount = 0 )
        OR ( in_check_amount  = 0 )
      THEN
        gt_tab_shop_hdrs(gn_header_count).digestion_calc_rate
                                          := 0;
      ELSE
        gt_tab_shop_hdrs(gn_header_count).digestion_calc_rate
                                          := ROUND( (in_sales_amount / in_check_amount) * 100, 2 );
      END IF;
      --�}�X�^�|��
      gt_tab_shop_hdrs(gn_header_count).master_rate
                                          := it_tab_cust_data.rate * 100;
      --���z
      gt_tab_shop_hdrs(gn_header_count).balance_amount
                                          := ROUND( in_sales_amount - ( in_check_amount * it_tab_cust_data.rate ), 0 );
      --�Ƒԏ�����
      gt_tab_shop_hdrs(gn_header_count).cust_gyotai_sho
                                          := it_tab_cust_data.business_low_type;
      --���ю҃R�[�h
      gt_tab_shop_hdrs(gn_header_count).performance_by_code
                                          := it_performance_by_code;
      --�̔����ѓo�^��
      gt_tab_shop_hdrs(gn_header_count).sales_result_creation_date
                                          := NULL;
      --�̔����э쐬�σt���O
      gt_tab_shop_hdrs(gn_header_count).sales_result_creation_flag
                                          := ct_make_flag_no;
      --�O������v�Z���N����
      gt_tab_shop_hdrs(gn_header_count).pre_digestion_due_date
                                          := gd_begi_month_date -1;
      --���v�Z�敪
      IF ( iv_ar_uncalculate_type  = cv_uncalculate_type_nof )
        AND ( iv_inv_uncalculate_type = cv_uncalculate_type_nof )
      THEN
        gt_tab_shop_hdrs(gn_header_count).uncalculate_class
                                          := ct_uncalc_class_1;
        gn_uncalc_cnt1                    := gn_uncalc_cnt1 + 1;
      ELSIF ( ( iv_ar_uncalculate_type   = cv_uncalculate_type_nof )
        AND   ( iv_inv_uncalculate_type  != cv_uncalculate_type_nof ) )
        OR  ( ( iv_ar_uncalculate_type   = cv_uncalculate_type_zero )
        AND   ( iv_inv_uncalculate_type  = cv_uncalculate_type_init ) )
      THEN
        gt_tab_shop_hdrs(gn_header_count).uncalculate_class
                                          := ct_uncalc_class_2;
        gn_uncalc_cnt2                    := gn_uncalc_cnt2 + 1;
      ELSIF ( ( iv_ar_uncalculate_type  != cv_uncalculate_type_nof )
        AND   ( iv_inv_uncalculate_type  = cv_uncalculate_type_nof ) )
        OR  ( ( iv_ar_uncalculate_type   = cv_uncalculate_type_init )
        AND   ( iv_inv_uncalculate_type  = cv_uncalculate_type_zero ) )
      THEN
        gt_tab_shop_hdrs(gn_header_count).uncalculate_class
                                          := ct_uncalc_class_3;
        gn_uncalc_cnt3                    := gn_uncalc_cnt3 + 1;
      ELSE
        gt_tab_shop_hdrs(gn_header_count).uncalculate_class
                                          := ct_uncalc_class_0;
      END IF;
      --�쐬��
      gt_tab_shop_hdrs(gn_header_count).created_by
                                          := cn_created_by;
      --�쐬��
      gt_tab_shop_hdrs(gn_header_count).creation_date
                                          := cd_creation_date;
      --�ŏI�X�V��
      gt_tab_shop_hdrs(gn_header_count).last_updated_by
                                          := cn_last_updated_by;
      --�ŏI�X�V��
      gt_tab_shop_hdrs(gn_header_count).last_update_date
                                          := cd_last_update_date;
      --�ŏI�X�V۸޲�
      gt_tab_shop_hdrs(gn_header_count).last_update_login
                                          := cn_last_update_login;
      --�v��ID
      gt_tab_shop_hdrs(gn_header_count).request_id
                                          := cn_request_id;
      --�ݶ��ĥ��۸��ѥ���ع����ID
      gt_tab_shop_hdrs(gn_header_count).program_application_id
                                          := cn_program_application_id;
      --�ݶ��ĥ��۸���ID
      gt_tab_shop_hdrs(gn_header_count).program_id
                                          := cn_program_id;
      --��۸��эX�V��
      gt_tab_shop_hdrs(gn_header_count).program_update_date
                                          := cd_program_update_date;
      --�w�b�_�J�E���g�A�b�v
      gn_header_count                     := gn_header_count + 1;
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
  END set_header;
--
  /**********************************************************************************
   * Procedure Name   : insert_lines
   * Description      : �X�ܕʗp�����v�Z���׃e�[�u���o�^
   ***********************************************************************************/
  PROCEDURE insert_lines(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_lines'; -- �v���O������
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
    ln_i    NUMBER;
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
      FORALL ln_i IN 1..gt_tab_shop_lns.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_shop_digestion_lns VALUES gt_tab_shop_lns(ln_i);
    EXCEPTION
--
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        RAISE global_insert_expt;
--
    END;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --�o�^��O
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name
                     ,iv_name               =>  cv_msg_inser_lines_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#####################################  �Œ蕔 START ##########################################
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
  END insert_lines;
--
  /**********************************************************************************
   * Procedure Name   : insert_headers
   * Description      : �X�ܕʗp�����v�Z�w�b�_�e�[�u���o�^
   ***********************************************************************************/
  PROCEDURE insert_headers(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_headers'; -- �v���O������
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
    ln_i    NUMBER;
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
    BEGIN
      FORALL ln_i IN 1..gt_tab_shop_hdrs.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_shop_digestion_hdrs VALUES gt_tab_shop_hdrs(ln_i);
      --�Ώی����𐳏팏����
      gn_normal_cnt := SQL%ROWCOUNT;
    EXCEPTION
--
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        RAISE global_insert_expt;
--
    END;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --�o�^��O
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name
                     ,iv_name               =>  cv_msg_inser_headers_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#####################################  �Œ蕔 START ##########################################
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
  END insert_headers;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code        IN         VARCHAR2,     -- ���_�R�[�h
    iv_customer_number  IN         VARCHAR2,     -- �ڋq�R�[�h
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lt_shop_digestion_hdr_id     xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE;  --  �X�ܕʗp�����v�Z�w�b�_ID
    lv_ar_uncalculate_type       VARCHAR2(1);                                           --  AR���v�Z�敪
    lv_inv_uncalculate_type      VARCHAR2(1);                                           --  INV���v�Z�敪
    ln_sales_amount              NUMBER;                                                --  �X�ܕʔ�����z
    ln_check_amount              NUMBER;                                                --  �`�F�b�N�p�X�ܕʔ�����z
    ln_index                     NUMBER;
    lt_performance_by_code       xxcos_shop_digestion_hdrs.performance_by_code%TYPE;    --  �c�ƒS�����R�[�h
--
    -- *** ���[�J���ϐ� ***
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_error_cnt    := 0;
    gn_warn_cnt     := 0;
    gn_cust_cnt     := 0;
    gn_ar_cnt       := 0;
    gn_inv_cnt      := 0;
    gn_uncalc_cnt1  := 0;
    gn_uncalc_cnt2  := 0;
    gn_uncalc_cnt3  := 0;
    gn_line_count   := 1;
    gn_header_count := 1;
    ln_index        := 1;
    gv_base_code    := iv_base_code;
    gv_cust_code    := iv_customer_number;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-0.��������
    -- ===============================
    init(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
--
    -- ===============================
    -- A-1.�p�����[�^�`�F�b�N
    -- ===============================
    pram_chk(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
--
    -- ===============================
    -- A-2.�X�ܕʗp�����v�Z���̑O��f�[�^�폜
    -- ===============================
    data_del_former(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    ELSE
      COMMIT;
    END IF;
--
    -- ===============================
    -- A-3.�ڋq�}�X�^�f�[�^�擾����
    -- ===============================
    get_cust_data(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    END IF;
--
    -- ===============================
    -- <�������A���[�v����> (�������ʂɂ���Č㑱�����𐧌䂷��ꍇ)
    -- ===============================
    <<gt_tab_cust_data_loop>>
    FOR i IN 1..gt_tab_cust_data.COUNT LOOP
      -- ===============================
      -- A-5.�w�b�_�P�ʏ���������
      -- ===============================
      init_header(
         gt_tab_cust_data(i).party_id          -- �ڋq�p�[�e�BID
        ,gt_tab_cust_data(i).account_number    -- �ڋq�R�[�h
        ,lt_shop_digestion_hdr_id              -- �X�ܕʗp�����v�Z�w�b�_ID
        ,lv_ar_uncalculate_type                -- AR���v�Z�敪
        ,lv_inv_uncalculate_type               -- INV���v�Z�敪
        ,ln_sales_amount                       -- �X�ܕʔ�����z
        ,ln_check_amount                       -- �`�F�b�N�p�X�ܕʔ�����z
        ,lt_performance_by_code                -- �c�ƒS�����R�[�h
        ,lv_errbuf                             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_common_expt;
      END IF;
--
      -- ===============================
      -- A-6.AR������擾����
      -- ===============================
      get_ar_data(
         gt_tab_cust_data(i).cust_account_id   -- �ڋqID
        ,gt_tab_cust_data(i).account_number    -- �ڋq�R�[�h
        ,lv_ar_uncalculate_type                -- AR���v�Z�敪
        ,ln_sales_amount                       -- �X�ܕʔ�����z
        ,lv_errbuf                             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_common_expt;
      ELSE
        IF ( lv_ar_uncalculate_type != cv_uncalculate_type_nof ) THEN
          gn_ar_cnt := gn_ar_cnt +1;
        END IF;
      END IF;
--
      -- ===============================
      -- A-8.INV�����݌Ɏ󕥕\���擾����
      -- ===============================
      get_inv_data(
         gt_tab_cust_data(i)                   -- �ڋq���
        ,lt_shop_digestion_hdr_id              -- �X�ܕʗp�����v�Z�w�b�_ID
        ,lv_inv_uncalculate_type               -- INV���v�Z�敪
        ,ln_check_amount                       -- �`�F�b�N�p�X�ܕʔ�����z
        ,lv_errbuf                             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_common_expt;
      ELSE
        IF ( lv_inv_uncalculate_type != cv_uncalculate_type_nof ) THEN
          gn_inv_cnt := gn_inv_cnt + 1;
        END IF;
      END IF;
--
      -- ===============================
      -- A-12.�X�ܕʗp�����v�Z�w�b�_�o�^����
      -- ===============================
      set_header(
         gt_tab_cust_data(i)                   -- �ڋq���
        ,lt_shop_digestion_hdr_id              -- �X�ܕʗp�����v�Z�w�b�_ID
        ,lv_ar_uncalculate_type                -- AR���v�Z�敪
        ,lv_inv_uncalculate_type               -- INV���v�Z�敪
        ,ln_sales_amount                       -- �X�ܕʔ�����z
        ,ln_check_amount                       -- �`�F�b�N�p�X�ܕʔ�����z
        ,lt_performance_by_code                -- �c�ƒS�����R�[�h
        ,lv_errbuf                             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_common_expt;
      END IF;
--
      --�폜�p�w�b�_ID�ۊ�
      gt_tab_shop_del_hdrs(ln_index).shop_digestion_hdr_id := gt_tab_cust_data(i).shop_digestion_hdr_id;
      gt_tab_shop_del_hdrs(ln_index).customer_number       := gt_tab_cust_data(i).account_number;
      --
      ln_index                                             := ln_index + 1;
    END LOOP gt_tab_cust_data_loop;
--
    -- ===============================
    -- A-4.�X�ܕʗp�����v�Z���̍���f�[�^�폜
    -- ===============================
    data_del_now(
       lv_errbuf                             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    END IF;
--
  -- ===============================
  -- �X�ܕʗp�����v�Z���׃e�[�u���o�^
  -- ===============================
    insert_lines(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
      IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    END IF;
--
  -- ===============================
  -- �X�ܕʗp�����v�Z�w�b�_�e�[�u���o�^
  -- ===============================
    insert_headers(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
      IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_common_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
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
    errbuf                    OUT VARCHAR2,    --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                   OUT VARCHAR2,    --   ���^�[���E�R�[�h    --# �Œ� #
    iv_base_code              IN  VARCHAR2,    -- 1.���_�R�[�h
    iv_customer_number        IN  VARCHAR2     -- 2.�ڋq�R�[�h
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
       iv_base_code         -- 1.���_�R�[�h
      ,iv_customer_number   -- 2.�ڋq�R�[�h
      ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --*** �G���[�o�͂͗v���ɂ���Ďg�������Ă������� ***--
    --�G���[�o��
/*
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
*/
    --�G���[�o�́F�u�x���v���umain�Ń��b�Z�[�W���o�́v����v���̂���ꍇ
    IF (lv_retcode != cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      --������
      gn_uncalc_cnt1 := 0;
      gn_uncalc_cnt2 := 0;
      gn_uncalc_cnt3 := 0;
      gn_cust_cnt    := 0;
      gn_ar_cnt      := 0;
      gn_inv_cnt     := 0;
      gn_normal_cnt  := 0;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_select_count
                    ,iv_token_name1  => cv_tkn_cnt_data1
                    ,iv_token_value1 => TO_CHAR(gn_cust_cnt)
                    ,iv_token_name2  => cv_tkn_cnt_data2
                    ,iv_token_value2 => TO_CHAR(gn_ar_cnt)
                    ,iv_token_name3  => cv_tkn_cnt_data3
                    ,iv_token_value3 => TO_CHAR(gn_inv_cnt)
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
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_warn_count
                    ,iv_token_name1  => cv_tkn_cnt_data1
                    ,iv_token_value1 => TO_CHAR(gn_uncalc_cnt1)
                    ,iv_token_name2  => cv_tkn_cnt_data2
                    ,iv_token_value2 => TO_CHAR(gn_uncalc_cnt2)
                    ,iv_token_name3  => cv_tkn_cnt_data3
                    ,iv_token_value3 => TO_CHAR(gn_uncalc_cnt3)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
/*
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
*/
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
END XXCOS004A01C;
/
