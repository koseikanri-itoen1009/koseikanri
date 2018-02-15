create or replace PACKAGE BODY      XXCFF017A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A04C(body)
 * Description      : ���̋@�������A�b�v���[�h
 * MD.050           : MD050_CFF_017_A04_���̋@�������A�b�v���[�h
 * Version          : 1.2
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         ��������                              (A-1)
 *  get_for_validation           �Ó����`�F�b�N�p�̒l�擾              (A-2)
 *  get_upload_data              �t�@�C���A�b�v���[�hIF�f�[�^�擾      (A-3)
 *  divide_item                  �f���~�^�������ڕ���                  (A-4)
 *  check_item_value             ���ڒl�`�F�b�N                        (A-5)
 *  ins_upload_wk                ���̋@�����A�b�v���[�h���[�N�쐬      (A-6)
 *  get_upload_wk                ���̋@�����A�b�v���[�h���[�N          (A-7)
 *  data_validation              �f�[�^�Ó����`�F�b�N                  (A-8)
 *  ins_upd_vd_object            ���̋@�������X�V                    (A-9)
 *
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/07/14    1.0  SCSK �R��         �V�K�쐬
 *  2014/08/06    1.1  SCSK �R��         E_�{�ғ�_12263�Ή�
 *  2017/11/07    1.2  SCSK ���         E_�{�ғ�_14502�Ή�
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
  -- ���b�N�G���[
  lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF017A04C'; -- �p�b�P�[�W��
--
  cv_csv_delimiter   CONSTANT VARCHAR2(1) := ','; --�J���}
  cv_const_y         CONSTANT VARCHAR2(1) := 'Y'; --'Y'
  cv_const_n         CONSTANT VARCHAR2(1) := 'N'; --'N'
  cv_upload_type_col CONSTANT NUMBER := 1; -- ���[�N�e�[�u���D�ύX�敪�̍��ڏ�
  cv_obj_code_col    CONSTANT NUMBER := 2; -- ���[�N�e�[�u���D�����R�[�h�̍��ڏ�
--
  -- �ύX�敪
  cv_upload_type_1   CONSTANT VARCHAR2(1) := '1';  -- 1�i�ړ��j
  cv_upload_type_2   CONSTANT VARCHAR2(1) := '2';  -- 2�i�C���j
  cv_upload_type_3   CONSTANT VARCHAR2(1) := '3';  -- 3�i�����p�j
  -- �����敪
  cv_process_type_103 CONSTANT VARCHAR2(3) := '103';  -- 101�i�ړ��j
  cv_process_type_104 CONSTANT VARCHAR2(3) := '104';  -- 104�i�C���j
  cv_process_type_105 CONSTANT VARCHAR2(3) := '105';  -- 105�i�����p�j
--
  -- �����X�e�[�^�X
  cv_ob_status_101    CONSTANT VARCHAR2(3) := '101';  -- ���m��
  cv_ob_status_102    CONSTANT VARCHAR2(3) := '102';  -- �m��
  cv_ob_status_103    CONSTANT VARCHAR2(3) := '103';  -- �ړ�
  cv_ob_status_104    CONSTANT VARCHAR2(3) := '104';  -- �C��
  cv_ob_status_105    CONSTANT VARCHAR2(3) := '105';  -- �����p
  cv_ob_status_106    CONSTANT VARCHAR2(3) := '106';  -- �����p���m��
--
  -- �����}�X�N
  cv_date_format      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- ���t����
  cv_format_yyyymm    CONSTANT VARCHAR2(7)   := 'YYYY-MM';     -- YYYYMM�^
--
  -- �o�̓^�C�v
  cv_file_type_out    CONSTANT VARCHAR2(10) := 'OUTPUT';      --�o��(���[�U���b�Z�[�W�p�o�͐�)
  cv_file_type_log    CONSTANT VARCHAR2(10) := 'LOG';         --���O(�V�X�e���Ǘ��җp�o�͐�)
--
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff      CONSTANT VARCHAR2(5) := 'XXCFF'; --�A�h�I���F��v�E���[�X�EFA�̈�
  cv_msg_kbn_ccp      CONSTANT VARCHAR2(5) := 'XXCCP'; --���ʂ̃��b�Z�[�W
--
  -- �v���t�@�C��
  cv_fixed_asset_register CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER'; -- �䒠���_�Œ莑�Y�䒠
-- 2017-11-07 T.Otsuka Add Start --
  cv_prf_cat_dep_ifrs CONSTANT VARCHAR2(30)  := 'XXCFF1_CAT_DEPRN_IFRS';          -- IFRS���p���@
-- 2017-11-07 T.Otsuka Add End --
--
  -- ���b�Z�[�W��
  cv_msg_name_00007   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007';  -- ���b�N�G���[
  cv_msg_name_00020   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00020';  -- �v���t�@�C���擾�G���[
  cv_msg_name_00062   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00062';  -- �Ώۃf�[�^�Ȃ�
  cv_msg_name_00094   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00094';  -- ���ʊ֐��G���[
  cv_msg_name_00095   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00095';  -- ���ʊ֐����b�Z�[�W
  cv_msg_name_00101   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00101';  -- �擾�G���[
  cv_msg_name_00123   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00123';  -- ���݃`�F�b�N�G���[
  cv_msg_name_00124   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00124';  -- ���ڒl�`�F�b�N�G���[
  cv_msg_name_00159   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00159';  -- �����G���[�Ώ�
  cv_msg_name_00167   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00167';  -- �A�b�v���[�h�����o�̓��b�Z�[�W
  cv_msg_name_00194   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00194';  -- ���[�X���������Ԏ擾�G���[
  cv_msg_name_00221   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00221';  -- ���͍��ڑÓ����`�F�b�N�G���[�i���̋@�����j
  cv_msg_name_00222   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00222';  -- �d���`�F�b�N�G���[�i���̋@�����j
  cv_msg_name_00223   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00223';  -- �����p�����G���[�i���̋@�����j
  cv_msg_name_00224   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00224';  -- �����p�X�e�[�^�X�G���[�i���̋@�����j
  cv_msg_name_00227   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00227';  -- �ύX�敪�s���G���[�i���̋@�����j
  cv_msg_name_00231   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00231';  -- �����p�t���O�Ó����G���[�i���̋@�����j
  cv_msg_name_00232   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00232';  -- FA�I�[�v�����ԊO�G���[�i���̋@�����j
  cv_msg_name_00234   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00234';  -- �A�b�v���[�hCSV�t�@�C�����擾�G���[
-- 2017-11-07 T.Otsuka Add Start --
  cv_msg_name_00256   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00256';  -- ���݃`�F�b�N�G���[
  cv_msg_name_00269   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00269';  -- ���͍��ڑÓ����`�F�b�N�G���[�i���̋@�����j
  cv_msg_name_00274   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00274';  -- ���͍��ڑÓ����`�F�b�N�G���[�i���̋@�����FIFRS���ځj
-- 2017-11-07 T.Otsuka Add End --
  cv_msg_name_90000   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
  cv_msg_name_90001   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
  cv_msg_name_90002   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
  cv_msg_name_90003   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90003';  -- �X�L�b�v�������b�Z�[�W
--
  -- ���b�Z�[�W��(�g�[�N��)
  cv_tkn_val_50130    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50130'; --��������
  cv_tkn_val_50131    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50131'; --BLOB�f�[�^�ϊ��p�֐�
  cv_tkn_val_50165    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50165'; --�f���~�^���������֐�
  cv_tkn_val_50166    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50166'; --���ڃ`�F�b�N
  cv_tkn_val_50141    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50141'; --���Ə��}�X�^�`�F�b�N
  cv_tkn_val_50175    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50175'; --�t�@�C���A�b�v���[�hI/F
  cv_tkn_val_50228    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50228'; -- XXCFF:�䒠���_�Œ莑�Y�䒠
  cv_tkn_val_50230    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50230'; -- �������p����
  cv_tkn_val_50238    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50238'; -- �J�����_���ԃN���[�Y��
  cv_tkn_val_50259    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50259'; --���̋@�������ύX�i�ړ��E�C���E�����p�j
  cv_tkn_val_50260    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50260'; --���̋@�����Ǘ�
  cv_tkn_val_50229    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50229'; --���̋@��������
-- 2017-11-07 T.Otsuka Add Start --
  cv_tkn_val_50306    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50306'; -- IFRS���Y�Ȗ�
  cv_tkn_val_50317    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50317'; -- IFRS���p
  cv_tkn_val_50318    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50318'; -- XXCFF:IFRS���p���@
-- 2017-11-07 T.Otsuka Add End --
--
  -- �g�[�N����
  cv_tkn_name_00007    CONSTANT VARCHAR2(100) := 'TABLE_NAME';  -- �e�[�u��
  cv_tkn_name_00094    CONSTANT VARCHAR2(100) := 'FUNC_NAME';   -- ���ʊ֐���
  cv_tkn_name_00095    CONSTANT VARCHAR2(100) := 'ERR_MSG';     -- �G���[���b�Z�[�W
  cv_tkn_name_00101    CONSTANT VARCHAR2(100) := 'INFO';        -- �Œ莑�Y���
  cv_tkn_name_00123    CONSTANT VARCHAR2(100) := 'COLUMN_DATA'; -- ���ڃf�[�^
  cv_tkn_name_00124_01 CONSTANT VARCHAR2(100) := 'COLUMN_NAME'; -- ���ږ�
  cv_tkn_name_00124_02 CONSTANT VARCHAR2(100) := 'COLUMN_INFO'; -- ���ڏ��
  cv_tkn_name_00159    CONSTANT VARCHAR2(100) := 'OBJECT_CODE'; -- �����R�[�h
  cv_tkn_name_00167_01 CONSTANT VARCHAR2(100) := 'FILE_NAME';   -- �t�@�C�����g�[�N��
  cv_tkn_name_00167_02 CONSTANT VARCHAR2(100) := 'CSV_NAME';    -- CSV�t�@�C�����g�[�N��
  cv_tkn_name_00194    CONSTANT VARCHAR2(100) := 'BOOK_ID';     -- ��v����ID
  cv_tkn_name_00020    CONSTANT VARCHAR2(100) := 'PROF_NAME';   -- �v���t�@�C����
  cv_tkn_name_00232    CONSTANT VARCHAR2(100) := 'COL_CLOSE_DATE';   -- �J�����_���ԃN���[�Y��
-- 2017-11-07 T.Otsuka Add Start --
  cv_tkn_input        CONSTANT VARCHAR2(100) := 'INPUT';                 -- ���ږ�
  cv_tkn_column_data  CONSTANT VARCHAR2(100) := 'COLUMN_DATA';           -- ���ڒl
  cv_tkn_line_no      CONSTANT VARCHAR2(100) := 'LINE_NO';               -- �s�ԍ�
--
  -- �l�Z�b�g��
  cv_ffv_dprn_method  CONSTANT VARCHAR2(100) := 'XXCFF_DPRN_METHOD'; -- ���p���@
-- 2017-11-07 T.Otsuka Add End --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �������ڕ�����f�[�^�i�[�z��
  TYPE g_load_data_ttype           IS TABLE OF VARCHAR2(600) INDEX BY PLS_INTEGER;
--
  -- �Ó����`�F�b�N�p�̒l�擾�p��`
  TYPE g_column_desc_ttype         IS TABLE OF xxcff_vd_object_info_upload_v.column_desc%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_ttype          IS TABLE OF xxcff_vd_object_info_upload_v.byte_count%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_decimal_ttype  IS TABLE OF xxcff_vd_object_info_upload_v.byte_count_decimal%TYPE INDEX BY PLS_INTEGER;
  TYPE g_pay_match_flag_name_ttype IS TABLE OF xxcff_vd_object_info_upload_v.payment_match_flag_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_item_attribute_ttype      IS TABLE OF xxcff_vd_object_info_upload_v.item_attribute%TYPE INDEX BY PLS_INTEGER;
--
    -- ���̋@�������A�b�v���[�h���[�N�擾�f�[�^���R�[�h�^
  TYPE g_vd_object_rtype IS RECORD(
    upload_type              xxcff_vd_object_info_upload_wk.upload_type%TYPE,            -- �ύX�敪
    object_code              xxcff_vd_object_info_upload_wk.object_code%TYPE,            -- �����R�[�h
    owner_company_type       xxcff_vd_object_info_upload_wk.owner_company_type%TYPE,     -- �{�Ё^�H��敪
    department_code          xxcff_vd_object_info_upload_wk.department_code%TYPE,        -- �Ǘ�����
    moved_date               xxcff_vd_object_info_upload_wk.moved_date%TYPE,             -- �ړ���
    installation_place       xxcff_vd_object_info_upload_wk.installation_place%TYPE,     -- �ݒu��
    installation_address     xxcff_vd_object_info_upload_wk.installation_address%TYPE,   -- �ݒu�ꏊ
    dclr_place               xxcff_vd_object_info_upload_wk.dclr_place%TYPE,             -- �\���n
    location                 xxcff_vd_object_info_upload_wk.location%TYPE,               -- ���Ə�
    manufacturer_name        xxcff_vd_object_info_upload_wk.manufacturer_name%TYPE,      -- ���[�J�[��
    model                    xxcff_vd_object_info_upload_wk.model%TYPE,                  -- �@��
    age_type                 xxcff_vd_object_info_upload_wk.age_type%TYPE,               -- �N��
    quantity                 xxcff_vd_object_info_upload_wk.quantity%TYPE,               -- ����
    date_placed_in_service   xxcff_vd_object_info_upload_wk.date_placed_in_service%TYPE, -- ���Ƌ��p��
    assets_date              xxcff_vd_object_info_upload_wk.assets_date%TYPE,            -- �擾��
    assets_cost              xxcff_vd_object_info_upload_wk.assets_cost%TYPE,            -- �擾���i
--    month_lease_charge       xxcff_vd_object_info_upload_wk.month_lease_charge%TYPE,     -- ���z���[�X��
--    re_lease_charge          xxcff_vd_object_info_upload_wk.re_lease_charge%TYPE,        -- �ă��[�X��
-- 2014-08-06 S.Yamashita Add Start --
    cash_price               xxcff_vd_object_info_upload_wk.cash_price%TYPE,             -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
    date_retired             xxcff_vd_object_info_upload_wk.date_retired%TYPE,           -- ���E���p��
    proceeds_of_sale         xxcff_vd_object_info_upload_wk.proceeds_of_sale%TYPE,       -- ���p���i
    cost_of_removal          xxcff_vd_object_info_upload_wk.cost_of_removal%TYPE,        -- �P����p
    retired_flag             xxcff_vd_object_info_upload_wk.retired_flag%TYPE,           -- �����p�m��t���O
-- 2017-11-07 T.Otsuka Add Start --
    ifrs_life_in_months      xxcff_vd_object_info_upload_wk.ifrs_life_in_months%TYPE,    -- IFRS�ϗp�N��
    ifrs_cat_deprn_method    xxcff_vd_object_info_upload_wk.ifrs_cat_deprn_method%TYPE,  -- IFRS���p
    real_estate_acq_tax      xxcff_vd_object_info_upload_wk.real_estate_acq_tax%TYPE,    -- �s���Y�擾��
    borrowing_cost           xxcff_vd_object_info_upload_wk.borrowing_cost%TYPE,         -- �ؓ��R�X�g
    other_cost               xxcff_vd_object_info_upload_wk.other_cost%TYPE,             -- ���̑�
    ifrs_asset_account       xxcff_vd_object_info_upload_wk.ifrs_asset_account%TYPE,     -- IFRS���Y�Ȗ�
    correct_date             xxcff_vd_object_info_upload_wk.correct_date%TYPE,           -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
    xvoh_owner_company_type       xxcff_vd_object_headers.owner_company_type%TYPE,         -- �{�Ё^�H��敪
    xvoh_department_code          xxcff_vd_object_headers.department_code%TYPE,            -- �Ǘ�����
    xvoh_moved_date               xxcff_vd_object_headers.moved_date%TYPE,                 -- �ړ���
    xvoh_installation_place       xxcff_vd_object_headers.installation_place%TYPE,         -- �ݒu��
    xvoh_installation_address     xxcff_vd_object_headers.installation_address%TYPE,       -- �ݒu�ꏊ
    xvoh_dclr_place               xxcff_vd_object_headers.dclr_place%TYPE,                 -- �\���n
    xvoh_location                 xxcff_vd_object_headers.location%TYPE,                   -- ���Ə� 
    xvoh_manufacturer_name        xxcff_vd_object_headers.manufacturer_name%TYPE,          -- ���[�J�[��
    xvoh_model                    xxcff_vd_object_headers.model%TYPE,                      -- �@��
    xvoh_age_type                 xxcff_vd_object_headers.age_type%TYPE,                   -- �N��
    xvoh_quantity                 xxcff_vd_object_headers.quantity%TYPE,                   -- ����
    xvoh_date_placed_in_service   xxcff_vd_object_headers.date_placed_in_service%TYPE,     -- ���Ƌ��p��
    xvoh_assets_date              xxcff_vd_object_headers.assets_date%TYPE,                -- �擾��
    xvoh_assets_cost              xxcff_vd_object_headers.assets_cost%TYPE,                -- �擾���i
--    xvoh_month_lease_charge       xxcff_vd_object_headers.month_lease_charge%TYPE,         -- ���z���[�X��
--    xvoh_re_lease_charge          xxcff_vd_object_headers.re_lease_charge%TYPE,            -- �ă��[�X��
-- 2014-08-06 S.Yamashita Add Start --
    xvoh_cash_price               xxcff_vd_object_headers.cash_price%TYPE,                 -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
    xvoh_date_retired             xxcff_vd_object_headers.date_retired%TYPE,               -- ���E���p��
    xvoh_proceeds_of_sale         xxcff_vd_object_headers.proceeds_of_sale%TYPE,           -- ���p���i
    xvoh_cost_of_removal          xxcff_vd_object_headers.cost_of_removal%TYPE,            -- �P����p
    xvoh_retired_flag             xxcff_vd_object_headers.retired_flag%TYPE,               -- �����p�m��t���O
    xvoh_object_header_id         xxcff_vd_object_headers.object_header_id%TYPE,           -- ����ID
    xvoh_object_status            xxcff_vd_object_headers.object_status%TYPE,              -- �����X�e�[�^�X
    xvoh_machine_type             xxcff_vd_object_headers.machine_type%TYPE,               -- �@��敪
    xvoh_customer_code            xxcff_vd_object_headers.customer_code%TYPE,              -- �ڋq�R�[�h
-- 2017-11-07 T.Otsuka Mod Start --
--    xvoh_ib_if_date               xxcff_vd_object_headers.ib_if_date%TYPE                  -- �ݒu�x�[�X���A�g��
    xvoh_ib_if_date               xxcff_vd_object_headers.ib_if_date%TYPE,                 -- �ݒu�x�[�X���A�g��
    xvoh_ifrs_life_in_months      xxcff_vd_object_headers.ifrs_life_in_months%TYPE,        -- IFRS�ϗp�N��
    xvoh_ifrs_cat_deprn_method    xxcff_vd_object_headers.ifrs_cat_deprn_method%TYPE,      -- IFRS���p
    xvoh_real_estate_acq_tax      xxcff_vd_object_headers.real_estate_acq_tax%TYPE,        -- �s���Y�擾��
    xvoh_borrowing_cost           xxcff_vd_object_headers.borrowing_cost%TYPE,             -- �ؓ��R�X�g
    xvoh_other_cost               xxcff_vd_object_headers.other_cost%TYPE,                 -- ���̑�
    xvoh_ifrs_asset_account       xxcff_vd_object_headers.ifrs_asset_account%TYPE,         -- IFRS���Y�Ȗ�
    xvoh_correct_date             xxcff_vd_object_headers.correct_date%TYPE                -- �C���N����
-- 2017-11-07 T.Otsuka Mod End --
  );
--
  -- ���̋@�����Ǘ����捞�Ώۃf�[�^���R�[�h�z��
  TYPE g_vd_object_ttype IS TABLE OF g_vd_object_rtype
  INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- �����l���
  g_init_rec                     xxcff_common1_pkg.init_rtype;
--
  --�t�@�C���A�b�v���[�hIF�f�[�^
  g_file_upload_if_data_tab      xxccp_common_pkg2.g_file_data_tbl;
--
  --�������ڕ�����f�[�^�i�[�z��
  g_load_data_tab                g_load_data_ttype;
--
  --CSV�̕����R�[�h��ێ�
  g_csv_object_code              VARCHAR2(100);
--
  -- ���ڒl�`�F�b�N�p�̒l�擾�p��`
  g_column_desc_tab              g_column_desc_ttype;
  g_byte_count_tab               g_byte_count_ttype;
  g_byte_count_decimal_tab       g_byte_count_decimal_ttype;
  g_pay_match_flag_name_tab      g_pay_match_flag_name_ttype;
  g_item_attribute_tab           g_item_attribute_ttype;
--
  -- �Ó����`�F�b�N�p�̕ϐ�
  gv_object_code_pre              VARCHAR2(100);
  gv_upload_type_pre              VARCHAR2(100);
--
  -- ���̋@�������A�b�v���[�h���[�N�擾�Ώۃf�[�^
  g_vd_object_tab  g_vd_object_ttype;
--
  -- �v���t�@�C���l
  gv_fixed_asset_register  VARCHAR2(100); -- �䒠���_�Œ莑�Y�䒠
-- 2017-11-07 T.Otsuka Add Start --
  gv_cat_dep_ifrs              VARCHAR2(100); -- IFRS���p���@
-- 2017-11-07 T.Otsuka Add End --
--
  -- �J�����_���ԃN���[�Y��
  g_cal_per_close_date     DATE;
--
  -- �G���[�t���O
  gb_err_flag                    BOOLEAN;
--
-- 2017-11-07 T.Otsuka Add Start --
  gd_process_date              DATE;          -- �Ɩ����t
--
-- 2017-11-07 T.Otsuka Add End --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       --   1.�t�@�C��ID
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
--
    -- *** ���[�J���ϐ� ***
    lv_file_name    xxccp_mrp_file_ul_interface.file_name%TYPE; -- �擾�t�@�C����
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
      -- �A�b�v���[�hCSV�t�@�C�����擾
      SELECT  xfu.file_name
        INTO  lv_file_name
        FROM  xxccp_mrp_file_ul_interface  xfu
       WHERE  xfu.file_id = in_file_id;
    EXCEPTION
      -- �A�b�v���[�hCSV�t�@�C�������擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff -- XXCFF
                                        ,cv_msg_name_00234)    -- �A�b�v���[�hCSV�t�@�C�����擾�G���[
                                        ,1
                                        ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- �t�@�C�������o�́i���O�j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => xxccp_common_pkg.get_msg(cv_msg_kbn_cff, cv_msg_name_00167
                                        ,cv_tkn_name_00167_01,   cv_tkn_val_50259
                                        ,cv_tkn_name_00167_02,    lv_file_name)
    );
    -- �t�@�C�������o�́i�o�́j
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(cv_msg_kbn_cff, cv_msg_name_00167
                                         ,cv_tkn_name_00167_01,   cv_tkn_val_50259
                                         ,cv_tkn_name_00167_02,    lv_file_name)
    );
--
    -- �R���J�����g�p�����[�^�l�o��(���O)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(�o��)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �����l���̎擾
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- �����l���
      ,ov_errbuf   => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �����l��񂪎擾�o���Ȃ������ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff        -- XXCFF
                                                    ,cv_msg_name_00094     -- ���ʊ֐��G���[
                                                    ,cv_tkn_name_00094     -- �g�[�N��'FUNC_NAME'
                                                    ,cv_tkn_val_50130 )    -- ��������
                                                    || cv_msg_part
                                                    || lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C���l�̎擾 XXCFF:�䒠���_�Œ莑�Y�䒠
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_fixed_asset_register);
    IF (gv_fixed_asset_register IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff      -- XXCFF
                                                    ,cv_msg_name_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_name_00020   -- �g�[�N��'PROF_NAME'
                                                    ,cv_tkn_val_50228)  -- XXCFF:�䒠���_�Œ莑�Y�䒠
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2017-11-07 T.Otsuka Add Start --
    -- XXCFF:IFRS���p���@
    gv_cat_dep_ifrs := FND_PROFILE.VALUE(cv_prf_cat_dep_ifrs);
    IF ( gv_cat_dep_ifrs IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff      -- XXCFF
                                                    ,cv_msg_name_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_name_00020   -- �g�[�N��'PROF_NAME'
                                                    ,cv_tkn_val_50318)  -- XXCFF:IFRS���p���@
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2017-11-07 T.Otsuka Add End --
    BEGIN
      -- �ŐV�̃J�����_���ԃN���[�Y�����擾
      SELECT  MAX(calendar_period_close_date)                   -- �J�����_���ԃN���[�Y��
      INTO    g_cal_per_close_date
      FROM    fa_deprn_periods     fdp
      WHERE   fdp.book_type_code   = gv_fixed_asset_register    -- �䒠���
      AND     fdp.period_close_date IS NOT NULL                 -- �N���[�Y�Ȃ�
      ;
    EXCEPTION
      -- �J�����_���ԃN���[�Y�����擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff -- XXCFF
                                        ,cv_msg_name_00101    -- �擾�G���[
                                        ,cv_tkn_name_00007    -- �g�[�N��'TABLE_NAME'
                                        ,cv_tkn_val_50230     -- �������p����
                                        ,cv_tkn_name_00101    -- �g�[�N��'INFO'
                                        ,cv_tkn_val_50238)    -- �J�����_���ԃN���[�Y��
                                        ,1
                                        ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- 2017-11-07 T.Otsuka Add Start --
--    
    -- �����l���O���[�o���ϐ��Ɋi�[
    gd_process_date            := g_init_rec.process_date;               -- �Ɩ����t
-- 2017-11-07 T.Otsuka Add End --
  --==============================================================
  --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
  --==============================================================
--
--#################################  �Œ��O������ START   ####################################
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
   * Procedure Name   : get_for_validation
   * Description      : �Ó����`�F�b�N�p�̒l�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_for_validation(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_for_validation'; -- �v���O������
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
    CURSOR get_validate_cur
    IS
      SELECT  xoa.column_desc               AS column_desc               -- ���ږ���
              ,xoa.byte_count               AS byte_count                -- �o�C�g��
              ,xoa.byte_count_decimal       AS byte_count_decimal        -- �o�C�g��_�����_�ȉ�
              ,xoa.payment_match_flag_name  AS payment_match_flag_name   -- �K�{�t���O
              ,xoa.item_attribute           AS item_attribute            -- ���ڑ���
        FROM  xxcff_vd_object_info_upload_v  xoa  -- ���̋@�������ύX�r���[
    ORDER BY  xoa.code ASC
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�J�[�\���̃I�[�v��
    OPEN get_validate_cur;
    FETCH get_validate_cur
    BULK COLLECT INTO g_column_desc_tab          --���ږ���
                     ,g_byte_count_tab           --�o�C�g��
                     ,g_byte_count_decimal_tab   --�o�C�g��_�����_�ȉ�
                     ,g_pay_match_flag_name_tab  --�K�{�t���O
                     ,g_item_attribute_tab       --���ڑ���
    ;
--
    --�J�[�\���̃N���[�Y
    CLOSE get_validate_cur;
--
--#################################  �Œ��O������ START   ####################################
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
      IF ( get_validate_cur%ISOPEN ) THEN
        CLOSE get_validate_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_for_validation;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
    in_file_id    IN  NUMBER,       --   1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- �v���O������
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
    -- �t�@�C���A�b�v���[�hIF�f�[�^���擾
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id                 -- �t�@�C��ID
     ,ov_file_data => g_file_upload_if_data_tab  -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���ʊ֐��G���[�̏ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_name_00094    -- ���ʊ֐��G���[
                                                    ,cv_tkn_name_00094    -- �g�[�N��'FUNC_NAME'
                                                    ,cv_tkn_val_50131 )   -- BLOB�f�[�^�ϊ��p�֐�
                                                    || cv_msg_part
                                                    || lv_errmsg          --���ʊ֐���װү����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : �f���~�^�������ڕ�������(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_loop_cnt_1 IN  NUMBER,       --   ���[�v�J�E���^1
    in_loop_cnt_2 IN  NUMBER,       --   ���[�v�J�E���^2
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_item'; -- �v���O������
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
    --�f���~�^���������̋��ʊ֐��̌ďo
    g_load_data_tab(in_loop_cnt_2) := xxccp_common_pkg.char_delim_partition(
                                        g_file_upload_if_data_tab(in_loop_cnt_1) --������������(�擾�f�[�^)
                                       ,cv_csv_delimiter                         --�f���~�^����
                                       ,in_loop_cnt_2                            --�ԋp�Ώ�INDEX
    );
    -- �������̕����R�[�h��ێ�
    IF ( in_loop_cnt_2 = cv_obj_code_col ) THEN
      g_csv_object_code := g_load_data_tab(in_loop_cnt_2);
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN 
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
      --�G���[���b�Z�[�W���o�͂���
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff      -- XXCFF
                                                    ,cv_msg_name_00094   -- ���ʊ֐��G���[
                                                    ,cv_tkn_name_00094   -- �g�[�N��'FUNC_NAME'
                                                    ,cv_tkn_val_50165 )  -- �f���~�^���������֐�
                                                    ,1
                                                    ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  -- ���b�Z�[�W�o��
        ,buff   => lv_errmsg
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END divide_item;
--
  /**********************************************************************************
   * Procedure Name   : check_item_value
   * Description      : ���ڒl�`�F�b�N����(A-5)
   ***********************************************************************************/
  PROCEDURE check_item_value(
    in_loop_cnt_2 IN  NUMBER,       -- ���[�v�J�E���^2
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_value'; -- �v���O������
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
    lv_warn_msg  VARCHAR2(5000); --�x�����b�Z�[�W
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
    -- ���ڃ`�F�b�N�̋��ʊ֐��̌ďo
    xxccp_common_pkg2.upload_item_check(
       iv_item_name    => g_column_desc_tab(in_loop_cnt_2)          -- ���ږ���
      ,iv_item_value   => g_load_data_tab(in_loop_cnt_2)            -- ���ڂ̒l
      ,in_item_len     => g_byte_count_tab(in_loop_cnt_2)           -- �o�C�g��/���ڂ̒���
      ,in_item_decimal => g_byte_count_decimal_tab(in_loop_cnt_2)   -- �o�C�g��_�����_�ȉ�/���ڂ̒����i�����_�ȉ��j
      ,iv_item_nullflg => g_pay_match_flag_name_tab(in_loop_cnt_2)  -- �K�{�t���O
      ,iv_item_attr    => g_item_attribute_tab(in_loop_cnt_2)       -- ���ڑ���
      ,ov_errbuf       => lv_errbuf                                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode                                -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���^�[���R�[�h���x���̏ꍇ�i�Ώۃf�[�^�ɕs�����������ꍇ�j
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF
                                                      ,cv_msg_name_00094        -- ���ʊ֐��G���[
                                                      ,cv_tkn_name_00094        -- �g�[�N��'FUNC_NAME'
                                                      ,cv_tkn_val_50166  )      -- ���ʊ֐���
                                                      ,1
                                                      ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_warn_msg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_warn_msg
      );
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff             -- XXCFF
                                                    ,cv_msg_name_00095          -- ���ʊ֐����b�Z�[�W
                                                    ,cv_tkn_name_00095          -- �g�[�N��'ERR_MSG'
                                                    ,lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- �����G���[�Ώ�
                                                       ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                                       ,g_csv_object_code       -- CSV�̕����R�[�h
                                                      )
                                                    ,1
                                                    ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
    -- ���^�[���R�[�h���G���[�̏ꍇ�i���ڃ`�F�b�N�ŃV�X�e���G���[�����������ꍇ�j
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
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
  END check_item_value;
--
  /**********************************************************************************
   * Procedure Name   : ins_upload_wk
   * Description      : ���̋@�������A�b�v���[�h���[�N�쐬����(A-6)
   ***********************************************************************************/
  PROCEDURE ins_upload_wk(
    in_file_id    IN  NUMBER,       --   1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upload_wk'; -- �v���O������
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
    -- ���̋@�������A�b�v���[�h���[�N�쐬
    INSERT INTO xxcff_vd_object_info_upload_wk (
      file_id                   -- �t�@�C��ID
     ,upload_type               -- �ύX�敪
     ,object_code               -- �����R�[�h
     ,history_num               -- ����ԍ�
     ,process_type              -- �����敪
     ,process_date              -- ������
     ,object_status             -- �����X�e�[�^�X
     ,owner_company_type        -- �{��;�H��敪
     ,department_code           -- �Ǘ�����
     ,machine_type              -- �@��敪
     ,vendor_code               -- �d����R�[�h
     ,manufacturer_name         -- ���[�J��
     ,model                     -- �@��
     ,age_type                  -- �N��
     ,customer_code             -- �ڋq�R�[�h
     ,quantity                  -- ����
     ,date_placed_in_service    -- ���Ƌ��p��
     ,assets_cost               -- �擾���i
--     ,month_lease_charge        -- ���z���[�X��
--     ,re_lease_charge           -- �ă��[�X��
-- 2014-08-06 S.Yamashita Add Start --
     ,cash_price                -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
     ,assets_date               -- �擾��
     ,moved_date                -- �ړ���
     ,installation_place        -- �ݒu��
     ,installation_address      -- �ݒu�ꏊ
     ,dclr_place                -- �\���n
     ,location                  -- ���Ə�
     ,date_retired              -- ������p��
     ,proceeds_of_sale          -- ���p���z
     ,cost_of_removal           -- �P����p
     ,retired_flag              -- �����p�m��t���O
     ,ib_if_date                -- �ݒu�x�[�X���A�g��
     ,fa_if_date                -- FA���A�g��
     ,ob_last_updated_by        -- �����Ǘ�_�ŏI�X�V��
-- 2017-11-07 T.Otsuka Add Start --
     ,ifrs_life_in_months       -- IFRS�ϗp�N��
     ,ifrs_cat_deprn_method     -- IFRS���p
     ,real_estate_acq_tax       -- �s���Y�擾��
     ,borrowing_cost            -- �ؓ��R�X�g
     ,other_cost                -- ���̑�
     ,ifrs_asset_account        -- IFRS���Y�Ȗ�
     ,correct_date              -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
     ,created_by                -- �쐬��
     ,creation_date             -- �쐬��
     ,last_updated_by           -- �ŏI�X�V��
     ,last_update_date          -- �ŏI�X�V��
     ,last_update_login         -- �ŏI�X�V���O�C��
     ,request_id                -- �v��ID
     ,program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     ,program_id                -- �R���J�����g�E�v���O����ID
     ,program_update_date       -- �v���O�����X�V��
    )
    VALUES (
      in_file_id                -- �t�@�C��ID
     ,g_load_data_tab(1)        -- �ύX�敪
     ,g_load_data_tab(2)        -- �����R�[�h
     ,g_load_data_tab(3)        -- ����ԍ�
     ,g_load_data_tab(4)        -- �����敪
     ,g_load_data_tab(5)        -- ������
     ,g_load_data_tab(6)        -- �����X�e�[�^�X
     ,g_load_data_tab(7)        -- �{��;�H��敪
     ,g_load_data_tab(8)        -- �Ǘ�����
     ,g_load_data_tab(9)        -- �@��敪
     ,g_load_data_tab(10)       -- �d����R�[�h
     ,g_load_data_tab(11)       -- ���[�J��
     ,g_load_data_tab(12)       -- �@��
     ,g_load_data_tab(13)       -- �N��
     ,g_load_data_tab(14)       -- �ڋq�R�[�h
     ,g_load_data_tab(15)       -- ����
     ,g_load_data_tab(16)       -- ���Ƌ��p��
     ,g_load_data_tab(17)       -- �擾���i
--     ,g_load_data_tab(17)       -- ���z���[�X��
--     ,g_load_data_tab(18)       -- �ă��[�X��
     ,g_load_data_tab(18)       -- �w�����i
     ,g_load_data_tab(19)       -- �擾��
     ,g_load_data_tab(20)       -- �ړ���
     ,g_load_data_tab(21)       -- �ݒu��
     ,g_load_data_tab(22)       -- �ݒu�ꏊ
     ,g_load_data_tab(23)       -- �\���n
     ,g_load_data_tab(24)       -- ���Ə�
     ,g_load_data_tab(25)       -- ������p��
     ,g_load_data_tab(26)       -- ���p���z
     ,g_load_data_tab(27)       -- �P����p
     ,g_load_data_tab(28)       -- �����p�m��t���O
     ,g_load_data_tab(29)       -- �ݒu�x�[�X���A�g��
     ,g_load_data_tab(30)       -- FA���A�g��
     ,g_load_data_tab(31)       -- �����Ǘ�_�ŏI�X�V��
-- 2017-11-07 T.Otsuka Add Start --
     ,g_load_data_tab(32)       -- IFRS�ϗp�N��
     ,g_load_data_tab(33)       -- IFRS���p
     ,g_load_data_tab(34)       -- �s���Y�擾��
     ,g_load_data_tab(35)       -- �ؓ��R�X�g
     ,g_load_data_tab(36)       -- ���̑�
     ,g_load_data_tab(37)       -- IFRS���Y�Ȗ�
     ,g_load_data_tab(38)       -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
     ,cn_created_by             -- �쐬��
     ,cd_creation_date          -- �쐬��
     ,cn_last_updated_by        -- �ŏI�X�V��
     ,cd_last_update_date       -- �ŏI�X�V��
     ,cn_last_update_login      -- �ŏI�X�V���O�C��
     ,cn_request_id             -- �v��ID
     ,cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����I
     ,cn_program_id             -- �R���J�����g�E�v���O����ID
     ,cd_program_update_date    -- �v���O�����X�V��
    );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
  EXCEPTION
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_upload_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_wk
   * Description      : ���̋@�������A�b�v���[�h���[�N�擾����(A-7)
   ***********************************************************************************/
  PROCEDURE get_upload_wk(
    in_file_id    IN  NUMBER,       --   1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_wk'; -- �v���O������
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
    CURSOR get_vd_object_upload_wk_cur
    IS
      SELECT
              xvoiu.upload_type             AS upload_type           -- �ύX�敪
             ,xvoiu.object_code             AS object_code           -- �����R�[�h
             ,xvoiu.owner_company_type      AS owner_company_type    -- �{��/�H��敪
             ,xvoiu.department_code         AS department_code       -- �Ǘ�����
             ,xvoiu.moved_date              AS moved_date            -- �ړ���
             ,xvoiu.installation_place      AS installation_place    -- �ݒu��
             ,xvoiu.installation_address    AS installation_address  -- �ݒu�ꏊ
             ,xvoiu.dclr_place              AS dclr_place            -- �\���n
             ,xvoiu.location                AS location              -- ���Ə�
             ,xvoiu.manufacturer_name       AS manufacturer_name     -- ���[�J�[��
             ,xvoiu.model                   AS model                 -- �@��
             ,xvoiu.age_type                AS age_type              -- �N��
             ,xvoiu.quantity                AS quantity              -- ����
             ,xvoiu.date_placed_in_service  AS date_placed_in_service-- ���Ƌ��p��
             ,xvoiu.assets_date             AS assets_date           -- �擾��
             ,xvoiu.assets_cost             AS assets_cost           -- �擾���i
--             ,xvoiu.month_lease_charge      AS month_lease_charge    -- ���z���[�X��
--             ,xvoiu.re_lease_charge         AS re_lease_charge       -- �ă��[�X��
-- 2014-08-06 S.Yamashita Add Start --
             ,xvoiu.cash_price              AS cash_price            -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
             ,xvoiu.date_retired            AS date_retired          -- ���E���p��
             ,xvoiu.proceeds_of_sale        AS proceeds_of_sale      -- ���p���i
             ,xvoiu.cost_of_removal         AS cost_of_removal       -- �P����p
             ,xvoiu.retired_flag            AS retired_flag          -- �����p�m��t���O
-- 2017-11-07 T.Otsuka Add Start --
             ,xvoiu.ifrs_life_in_months     AS ifrs_life_in_months   -- IFRS�ϗp�N��
             ,xvoiu.ifrs_cat_deprn_method   AS ifrs_cat_deprn_method -- IFRS���p
             ,xvoiu.real_estate_acq_tax     AS real_estate_acq_tax   -- �s���Y�擾��
             ,xvoiu.borrowing_cost          AS borrowing_cost        -- �ؓ��R�X�g
             ,xvoiu.other_cost              AS other_cost            -- ���̑�
             ,xvoiu.ifrs_asset_account      AS ifrs_asset_account    -- IFRS���Y�Ȗ�
             ,DECODE(xvoiu.object_status,
                      cv_ob_status_101,NULL,
                      xvoiu.correct_date)   AS correct_date          -- �C���N�����i�u���m��v����NULL�Ƃ���j
-- 2017-11-07 T.Otsuka Add End --
             ,xvoh.owner_company_type       AS xvoh_owner_company_type     -- �{�ЍH��(�����Ǘ�)
             ,xvoh.department_code          AS xvoh_department_code        -- �Ǘ�����(�����Ǘ�)
             ,xvoh.moved_date               AS xvoh_moved_date             -- �Ǘ�����(�����Ǘ�)
             ,xvoh.installation_place       AS xvoh_installation_place     -- �ݒu��(�����Ǘ�)
             ,xvoh.installation_address     AS xvoh_installation_address   -- �ݒu�ꏊ(�����Ǘ�)
             ,xvoh.dclr_place               AS xvoh_dclr_place             -- �\���n(�����Ǘ�)
             ,xvoh.location                 AS xvoh_location               -- ���Ə�(�����Ǘ�)
             ,xvoh.manufacturer_name        AS xvoh_manufacturer_name      -- ���[�J�[��(�����Ǘ�)
             ,xvoh.model                    AS xvoh_model                  -- �@��(�����Ǘ�)
             ,xvoh.age_type                 AS xvoh_age_type               -- �N��(�����Ǘ�)
             ,xvoh.quantity                 AS xvoh_quantity               -- ����(�����Ǘ�)
             ,xvoh.date_placed_in_service   AS xvoh_date_placed_in_service -- ���Ƌ��p��(�����Ǘ�)
             ,xvoh.assets_date              AS xvoh_assets_date            -- �擾��(�����Ǘ�)
             ,xvoh.assets_cost              AS xvoh_assets_cost            -- �擾���i(�����Ǘ�)
--             ,xvoh.month_lease_charge       AS xvoh_month_lease_charge     -- ���z���[�X��(�����Ǘ�)
--             ,xvoh.re_lease_charge          AS xvoh_re_lease_charge        -- �ă��[�X��(�����Ǘ�)
-- 2014-08-06 S.Yamashita Add Start --
             ,xvoh.cash_price               AS xvoh_cash_price             -- �w�����i(�����Ǘ�)
-- 2014-08-06 S.Yamashita Add End --
             ,xvoh.date_retired             AS xvoh_date_retired           -- ���E���p��(�����Ǘ�)
             ,xvoh.proceeds_of_sale         AS xvoh_proceeds_of_sale       -- ���p���i(�����Ǘ�)
             ,xvoh.cost_of_removal          AS xvoh_cost_of_removal        -- �P����p(�����Ǘ�)
             ,xvoh.retired_flag             AS xvoh_retired_flag           -- �����p�m��t���O(�����Ǘ�)
             ,xvoh.object_header_id         AS xvoh_object_header_id       -- ����ID(�����Ǘ�)
             ,xvoh.object_status            AS xvoh_object_status          -- �����X�e�[�^�X(�����Ǘ�)
             ,xvoh.machine_type             AS xvoh_machine_type           -- �@��敪(�����Ǘ�)
             ,xvoh.customer_code            AS xvoh_customer_code          -- �ڋq�R�[�h(�����Ǘ�)
             ,xvoh.ib_if_date               AS xvoh_ib_if_date             -- �ݒu�x�[�X���A�g��(�����Ǘ�)
-- 2017-11-07 T.Otsuka Add Start --
             ,xvoh.ifrs_life_in_months      AS xvoh_ifrs_life_in_months    -- IFRS�ϗp�N��(�����Ǘ�)
             ,xvoh.ifrs_cat_deprn_method    AS xvoh_ifrs_cat_deprn_method  -- IFRS���p(�����Ǘ�)
             ,xvoh.real_estate_acq_tax      AS xvoh_real_estate_acq_tax    -- �s���Y�擾��(�����Ǘ�)
             ,xvoh.borrowing_cost           AS xvoh_borrowing_cost         -- �ؓ��R�X�g(�����Ǘ�)
             ,xvoh.other_cost               AS xvoh_other_cost             -- ���̑�(�����Ǘ�)
             ,xvoh.ifrs_asset_account       AS xvoh_ifrs_asset_account     -- IFRS���Y�Ȗ�(�����Ǘ�)
             ,xvoh.correct_date             AS xvoh_correct_date           -- �C���N����(�����Ǘ�)
-- 2017-11-07 T.Otsuka Add End --
        FROM
              xxcff_vd_object_info_upload_wk  xvoiu  -- ���̋@�������A�b�v���[�h���[�N
             ,xxcff_vd_object_headers         xvoh   -- ���̋@�����Ǘ�
       WHERE
              xvoiu.object_code = xvoh.object_code(+)      --�����R�[�h
         AND  xvoiu.file_id     = in_file_id               --�t�@�C��ID
       ORDER BY
              xvoiu.object_code
             ,xvoiu.upload_type
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���̋@�����A�b�v���[�h���[�N�擾
    OPEN  get_vd_object_upload_wk_cur;
    FETCH get_vd_object_upload_wk_cur BULK COLLECT INTO g_vd_object_tab;
    CLOSE get_vd_object_upload_wk_cur;
--
--#################################  �Œ��O������ START   ####################################
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
      IF ( get_vd_object_upload_wk_cur%ISOPEN ) THEN
        CLOSE get_vd_object_upload_wk_cur;
      END IF;
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_upload_wk;
--
  /**********************************************************************************
   * Procedure Name   : data_validation
   * Description      : �f�[�^�Ó����`�F�b�N����(A-8)
   ***********************************************************************************/
  PROCEDURE data_validation(
    in_rec_no     IN  NUMBER,       --   �Ώۃ��R�[�h�ԍ�
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_validation'; -- �v���O������
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
    lv_warn_msg    VARCHAR2(5000);      -- �x�����b�Z�[�W
    ln_normal_cnt  PLS_INTEGER := 0;    -- ����J�E���^�[
    ln_error_cnt   PLS_INTEGER := 0;    -- �G���[�J�E���^�[
    ln_location_id NUMBER;              -- ���Ə�ID
-- 2017-11-07 T.Otsuka Add Start --
    lt_ifrs_cat_deprn_method     fnd_flex_values.flex_value%TYPE;           -- IFRS���p
    lt_ifrs_asset_account        xxcff_aff_account_v.aff_account_code%TYPE; -- IFRS���Y�Ȗ�
-- 2017-11-07 T.Otsuka Add End --
--
    -- *** ���[�J���E�J�[�\�� ***
-- 2017-11-07 T.Otsuka Add Start --
    -- �l�Z�b�g�`�F�b�N�J�[�\��
    CURSOR check_flex_value_cur(
       iv_flex_value_set_name IN VARCHAR2    -- �l�Z�b�g��
      ,iv_flex_value          IN VARCHAR2    -- �l
    )
    IS
      SELECT ffv.flex_value    AS flex_value
      FROM   fnd_flex_value_sets   ffvs    -- �l�Z�b�g
            ,fnd_flex_values       ffv     -- �l�Z�b�g�l
      WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name = iv_flex_value_set_name
      AND    ffv.flex_value           = iv_flex_value
      AND    ffv.enabled_flag         = cv_const_y
      AND    gd_process_date         >= NVL(ffv.start_date_active ,gd_process_date)
      AND    gd_process_date         <= NVL(ffv.end_date_active ,gd_process_date)
      ;
    -- �l�Z�b�g�`�F�b�N�J�[�\�����R�[�h�^
    check_flex_value_rec  check_flex_value_cur%ROWTYPE;
-- 2017-11-07 T.Otsuka Add End --
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
    -- �G���[�t���O�̏�����
    gb_err_flag := FALSE;
-- 2017-11-07 T.Otsuka Add Start --
    -- ���[�J���ϐ��̏�����
    lt_ifrs_cat_deprn_method     := NULL;  -- IFRS���p
    lt_ifrs_asset_account        := NULL;  -- IFRS���Y�Ȗ�
-- 2017-11-07 T.Otsuka Add End --
--
    -- �@�������݃`�F�b�N
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name_00123                    -- ���݃`�F�b�N�G���[
                                                      ,cv_tkn_name_00123                    -- �g�[�N��'COLUMN_DATA'
                                                      ,g_vd_object_tab(in_rec_no).object_code ) -- �����R�[�h
                                                      ,1
                                                      ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
    END IF;
--
    -- �A�}�X�^�`�F�b�N
    -- ���ʊ֐�(���Ə��}�X�^�`�F�b�N)�̌Ăяo��
    xxcff_common1_pkg.chk_fa_location(
      iv_segment1    => NVL( g_vd_object_tab(in_rec_no).dclr_place
                              ,g_vd_object_tab(in_rec_no).xvoh_dclr_place ),          -- �\���n
      iv_segment2    => NVL( g_vd_object_tab(in_rec_no).department_code
                              ,g_vd_object_tab(in_rec_no).xvoh_department_code ),     -- �Ǘ�����
      iv_segment3    => NVL( g_vd_object_tab(in_rec_no).location
                              ,g_vd_object_tab(in_rec_no).xvoh_location ),            -- ���Ə�
      iv_segment5    => NVL( g_vd_object_tab(in_rec_no).owner_company_type
                              ,g_vd_object_tab(in_rec_no).xvoh_owner_company_type ),  -- �{�Ё^�H��敪
      on_location_id => ln_location_id,  -- ���Ə�ID
      ov_retcode     => lv_retcode,      -- ���^�[���R�[�h
      ov_errbuf      => lv_errbuf,       -- �G���[���b�Z�[�W
      ov_errmsg      => lv_errmsg        -- ���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_name_00094    -- ���ʊ֐��G���[
                                                    ,cv_tkn_name_00094    -- �g�[�N��'FUNC_NAME'
                                                    ,cv_tkn_val_50141 )   -- ���Ə��}�X�^�`�F�b�N
                                                    || cv_msg_part
                                                    || lv_errmsg          --���ʊ֐���װү����
                                                    || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- �����G���[�Ώ�
                                                       ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                                       ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                                      )
                                                    ,1
                                                    ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
    END IF;
    --
    -- �B���͍��ڑÓ����`�F�b�N
    -- �ύX�敪���u1�i�ړ��j�̏ꍇ�v
    IF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_1 ) THEN
      -- ���L���ڂ��S��NULL�̏ꍇ�̓G���[
      IF ( COALESCE(
              g_vd_object_tab(in_rec_no).owner_company_type                  -- �{�Ё^�H��敪
             ,g_vd_object_tab(in_rec_no).department_code                     -- �Ǘ�����
             ,TO_CHAR(g_vd_object_tab(in_rec_no).moved_date,cv_date_format)  -- �ړ���
             ,g_vd_object_tab(in_rec_no).installation_place                  -- �ݒu��
             ,g_vd_object_tab(in_rec_no).installation_address                -- �ݒu�ꏊ
             ,g_vd_object_tab(in_rec_no).dclr_place                          -- �\���n
             ,g_vd_object_tab(in_rec_no).location                            -- ���Ə�
           ) IS NULL
      )
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF
                                                    ,cv_msg_name_00221          -- ���͍��ڑÓ����`�F�b�N�G���[�i���̋@�����j
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- �����G���[�Ώ�
                                                       ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                                       ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                                      )
                                                    ,1
                                                    ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
--
    -- �ύX�敪���u2�i�C���j�̏ꍇ�v
    ELSIF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_2 ) THEN
      -- ���L���ڂ��S��NULL�̏ꍇ�̓G���[
      IF ( COALESCE(
              g_vd_object_tab(in_rec_no).manufacturer_name                              -- ���[�J�[��
             ,g_vd_object_tab(in_rec_no).model                                          -- �@��
             ,g_vd_object_tab(in_rec_no).age_type                                       -- �N��
             ,TO_CHAR(g_vd_object_tab(in_rec_no).quantity)                              -- ����
             ,TO_CHAR(g_vd_object_tab(in_rec_no).date_placed_in_service,cv_date_format) -- ���Ƌ��p��
             ,TO_CHAR(g_vd_object_tab(in_rec_no).assets_date,cv_date_format)            -- �擾��
             ,TO_CHAR(g_vd_object_tab(in_rec_no).assets_cost)                           -- �擾���i
--             ,TO_CHAR(g_vd_object_tab(in_rec_no).month_lease_charge)                    -- ���z���[�X��
--             ,TO_CHAR(g_vd_object_tab(in_rec_no).re_lease_charge)                       -- �ă��[�X��
-- 2014-08-06 S.Yamashita Add Start --
             ,TO_CHAR(g_vd_object_tab(in_rec_no).cash_price)                            -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
-- 2017-11-07 T.Otsuka Add Start --
             ,TO_CHAR(g_vd_object_tab(in_rec_no).ifrs_life_in_months)                   -- IFRS�ϗp�N��
             ,TO_CHAR(g_vd_object_tab(in_rec_no).ifrs_cat_deprn_method)                 -- IFRS���p
             ,TO_CHAR(g_vd_object_tab(in_rec_no).real_estate_acq_tax)                   -- �s���Y�擾��
             ,TO_CHAR(g_vd_object_tab(in_rec_no).borrowing_cost)                        -- �ؓ��R�X�g
             ,TO_CHAR(g_vd_object_tab(in_rec_no).other_cost)                            -- ���̑�
             ,TO_CHAR(g_vd_object_tab(in_rec_no).ifrs_asset_account)                    -- IFRS���Y�Ȗ�
             ,TO_CHAR(g_vd_object_tab(in_rec_no).correct_date,cv_date_format)           -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
           ) IS NULL 
      )
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF
                                                    ,cv_msg_name_00221          -- ���͍��ڑÓ����`�F�b�N�G���[�i���̋@�����j
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- �����G���[�Ώ�
                                                       ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                                       ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                                      )
                                                    ,1
                                                    ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
-- 2017-11-07 T.Otsuka Add Start --
      -- �I�u�W�F�N�g�X�e�[�^�X�����m��ȊO�̏ꍇ�ł��A
      -- ���L���ڂ̂����ꂩ��NULL�łȂ��ꍇ�Ɂu�C���N�����v��NULL�̏ꍇ�̓G���[
      IF  g_vd_object_tab(in_rec_no).xvoh_object_status <> cv_ob_status_101
      AND ( COALESCE(
              TO_CHAR(g_vd_object_tab(in_rec_no).ifrs_life_in_months)                   -- IFRS�ϗp�N��
             ,TO_CHAR(g_vd_object_tab(in_rec_no).ifrs_cat_deprn_method)                 -- IFRS���p
             ,TO_CHAR(g_vd_object_tab(in_rec_no).real_estate_acq_tax)                   -- �s���Y�擾��
             ,TO_CHAR(g_vd_object_tab(in_rec_no).borrowing_cost)                        -- �ؓ��R�X�g
             ,TO_CHAR(g_vd_object_tab(in_rec_no).other_cost)                            -- ���̑�
             ,TO_CHAR(g_vd_object_tab(in_rec_no).ifrs_asset_account)                    -- IFRS���Y�Ȗ�
           ) IS NOT NULL 
      AND g_vd_object_tab(in_rec_no).correct_date IS NULL )                             -- �C���N����
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF
                                                    ,cv_msg_name_00274          -- ���͍��ڑÓ����`�F�b�N�G���[�i���̋@�����FIFRS���ځj
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- �����G���[�Ώ�
                                                       ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                                       ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                                      )
                                                    ,1
                                                    ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
      -- �w�����i�A�s���Y�擾�ŁA�ؓ��R�X�g�A���̑������Z���A1�ȏ�łȂ���΃G���[
      IF ( NVL( g_vd_object_tab(in_rec_no).cash_price
               ,g_vd_object_tab(in_rec_no).xvoh_cash_price ) +             -- �w�����i
           NVL( g_vd_object_tab(in_rec_no).real_estate_acq_tax
               ,g_vd_object_tab(in_rec_no).xvoh_real_estate_acq_tax ) +    -- �s���Y�擾��
           NVL( g_vd_object_tab(in_rec_no).borrowing_cost
               ,g_vd_object_tab(in_rec_no).xvoh_borrowing_cost ) +         -- �ؓ��R�X�g
           NVL( g_vd_object_tab(in_rec_no).other_cost
               ,g_vd_object_tab(in_rec_no).xvoh_other_cost )               -- ���̑�
         ) < 1
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF     APP-XXCFF1-00269
                                                    ,cv_msg_name_00269          -- ���͍��ڑÓ����`�F�b�N�G���[�i���̋@�����j�F���z���Z�l��1�ȏ�
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- �����G���[�Ώ�
                                                       ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                                       ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                                      )
                                                    ,1
                                                    ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- IFRS���p
      -- ===============================
      IF ( g_vd_object_tab(in_rec_no).ifrs_cat_deprn_method IS NOT NULL ) THEN
        << check_ifrs_cat_dep_metd_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dprn_method                             -- XXCFF_DPRN_METHOD
                                      ,g_vd_object_tab(in_rec_no).ifrs_cat_deprn_method  -- IFRS���p
                                    )
        LOOP
          lt_ifrs_cat_deprn_method := check_flex_value_rec.flex_value;
        END LOOP check_ifrs_cat_dep_metd_loop;
        -- �擾�l��NULL�̏ꍇ
        IF ( lt_ifrs_cat_deprn_method IS NULL ) THEN
          -- ���݃`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                                 -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_name_00256                              -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_line_no                                 -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                             -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_input                                   -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_val_50317                               -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_column_data                             -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_vd_object_tab(in_rec_no).ifrs_cat_deprn_method  -- �g�[�N���l3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- IFRS���Y�Ȗ�
      -- ===============================
      IF ( g_vd_object_tab(in_rec_no).ifrs_asset_account IS NOT NULL ) THEN
        BEGIN
          SELECT xaav.aff_account_code  AS ifrs_asset_account
          INTO   lt_ifrs_asset_account
          FROM   xxcff_aff_account_v  xaav   -- ����Ȗڃr���[
          WHERE  xaav.aff_account_code  = g_vd_object_tab(in_rec_no).ifrs_asset_account
          AND    xaav.enabled_flag      = cv_const_y
          AND    gd_process_date       >= NVL(xaav.start_date_active ,gd_process_date)
          AND    gd_process_date       <= NVL(xaav.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���݃`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                              -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00256                           -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no                              -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                          -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_input                                -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_tkn_val_50306                            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_column_data                          -- �g�[�N���R�[�h3
                           ,iv_token_value3 => g_vd_object_tab(in_rec_no).ifrs_asset_account  -- �g�[�N���l3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- �G���[�t���O���X�V
            gb_err_flag := TRUE;
        END;
      END IF;
--
-- 2017-11-07 T.Otsuka Add End --
--
    -- �ύX�敪���u3�i�����p�j�̏ꍇ�v
    ELSIF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_3 ) THEN
      -- ���L���ڂ��S��NULL�̏ꍇ�A�܂��͏����p�m��t���O���ݒ肳��Ă��Ȃ��ꍇ�̓G���[
      IF ( (COALESCE(
               TO_CHAR(g_vd_object_tab(in_rec_no).date_retired,cv_date_format)  -- ���E���p��
              ,TO_CHAR(g_vd_object_tab(in_rec_no).proceeds_of_sale)             -- ���p���i
              ,TO_CHAR(g_vd_object_tab(in_rec_no).cost_of_removal)              -- �P����p
            ) IS NULL
      )
      OR ( g_vd_object_tab(in_rec_no).retired_flag IS NULL )                -- �����p�m��t���O
      )   
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF
                                                    ,cv_msg_name_00221          -- ���͍��ڑÓ����`�F�b�N�G���[�i���̋@�����j
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- �����G���[�Ώ�
                                                       ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                                       ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                                      )
                                                    ,1
                                                    ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
    -- �ύX�敪����L�ȊO�̏ꍇ
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                            ,cv_msg_name_00227          -- �ύX�敪�s���G���[�i���̋@�����j
                                           )
                                           || xxccp_common_pkg.get_msg(
                                                cv_msg_kbn_cff          -- XXCFF
                                               ,cv_msg_name_00159       -- �����G���[�Ώ�
                                               ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                               ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                              )
                                            ,1
                                            ,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
    END IF;
--
    -- �C�d���`�F�b�N
    -- 1�̕����R�[�h�ɑ΂��ē���̕ύX�敪���ݒ肳��Ă���ꍇ�̓G���[
    IF ( ( g_vd_object_tab(in_rec_no).object_code = gv_object_code_pre )
    AND (  g_vd_object_tab(in_rec_no).upload_type = gv_upload_type_pre )
    )
    THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                           ,cv_msg_name_00222          -- �d���`�F�b�N�G���[�i���̋@�����j
                                          )
                                          || xxccp_common_pkg.get_msg(
                                               cv_msg_kbn_cff          -- XXCFF
                                              ,cv_msg_name_00159       -- �����G���[�Ώ�
                                              ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                              ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                             )
                                           ,1
                                           ,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
    END IF;
--
    -- �����R�[�h�ƕύX�敪��ۑ�
    gv_object_code_pre  := g_vd_object_tab(in_rec_no).object_code;
    gv_upload_type_pre := g_vd_object_tab(in_rec_no).upload_type;
--
    -- �D�����X�e�[�^�X�Ó����`�F�b�N
    -- �X�V�Ώۂ̕����X�e�[�^�X���u101�i���m��j�v�܂��́u102�i�m��ρj�v�ŁA�ύX�敪���u3�i�����p�j�v�ŘA�g���ꂽ�ꍇ
    IF ( ((g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_101)
      OR ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_102 ))
    AND ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_3 )
    )
    THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                            ,cv_msg_name_00223          -- �����p�����G���[�i���̋@�����j
                                           )
                                           || xxccp_common_pkg.get_msg(
                                                cv_msg_kbn_cff          -- XXCFF
                                               ,cv_msg_name_00159       -- �����G���[�Ώ�
                                               ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                               ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                              )
                                            ,1
                                            ,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
    END IF;
--
    -- �X�V�Ώۂ̕����X�e�[�^�X���u106�i�����p�j�v�̏ꍇ
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_106 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                            ,cv_msg_name_00224          -- �����p�X�e�[�^�X�G���[�i���̋@�����j
                                           )
                                           || xxccp_common_pkg.get_msg(
                                                cv_msg_kbn_cff          -- XXCFF
                                               ,cv_msg_name_00159       -- �����G���[�Ώ�
                                               ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                               ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                              )
                                            ,1
                                            ,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
    END IF;
--
    -- �EFA�I�[�v�����ԃ`�F�b�N
    -- �ړ������J�����_���ԃN���[�Y���ȑO�̏ꍇ
    IF(g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_1) THEN
      IF ( (g_vd_object_tab(in_rec_no).moved_date IS NOT NULL)
        AND ( g_vd_object_tab(in_rec_no).moved_date <= g_cal_per_close_date)
      )
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                              ,cv_msg_name_00232          -- FA�I�[�v�����ԊO�G���[�i���̋@�����j
                                              ,cv_tkn_name_00232
                                              ,TO_CHAR(g_cal_per_close_date,'YYYY/MM/DD')
                                             )
                                             || xxccp_common_pkg.get_msg(
                                                  cv_msg_kbn_cff          -- XXCFF
                                                 ,cv_msg_name_00159       -- �����G���[�Ώ�
                                                 ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                                 ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                                )
                                              ,1
                                              ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
      END IF;
    END IF;
--
    -- ���E���p�����J�����_���ԃN���[�Y���ȑO�̏ꍇ
    IF(g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_3) THEN
      IF ((g_vd_object_tab(in_rec_no).date_retired IS NOT NULL)
        AND (g_vd_object_tab(in_rec_no).date_retired <= g_cal_per_close_date)
      )
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                              ,cv_msg_name_00232          -- FA�I�[�v�����ԊO�G���[�i���̋@�����j
                                              ,cv_tkn_name_00232
                                              ,TO_CHAR(g_cal_per_close_date,'YYYY/MM/DD')
                                             )
                                             || xxccp_common_pkg.get_msg(
                                                  cv_msg_kbn_cff          -- XXCFF
                                                 ,cv_msg_name_00159       -- �����G���[�Ώ�
                                                 ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                                 ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                                )
                                              ,1
                                              ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
      END IF;
    END IF;
-- 2017-11-07 T.Otsuka Add Start --
    -- (IFRS)�C���N�������J�����_���ԃN���[�Y���ȑO�̏ꍇ
    IF(g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_2) THEN
      IF ((g_vd_object_tab(in_rec_no).correct_date IS NOT NULL)
        AND (g_vd_object_tab(in_rec_no).correct_date <= g_cal_per_close_date)
      )
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                              ,cv_msg_name_00232          -- FA�I�[�v�����ԊO�G���[�i���̋@�����j
                                              ,cv_tkn_name_00232
                                              ,TO_CHAR(g_cal_per_close_date,'YYYY/MM/DD')
                                             )
                                             || xxccp_common_pkg.get_msg(
                                                  cv_msg_kbn_cff          -- XXCFF
                                                 ,cv_msg_name_00159       -- �����G���[�Ώ�
                                                 ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                                 ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                                )
                                              ,1
                                              ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
      END IF;
    END IF;
-- 2017-11-07 T.Otsuka Add End --
--
    -- �F�����p�t���O�Ó����`�F�b�N
    -- �����p�m��t���O�ɁuY�v�A�uN�v�ȊO�̒l�����͂���Ă���ꍇ
    IF ( g_vd_object_tab(in_rec_no).retired_flag NOT IN (cv_const_y,cv_const_n) ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                            ,cv_msg_name_00231          -- �����p�t���O�Ó����G���[�i���̋@�����j
                                           )
                                           || xxccp_common_pkg.get_msg(
                                                cv_msg_kbn_cff          -- XXCFF
                                               ,cv_msg_name_00159       -- �����G���[�Ώ�
                                               ,cv_tkn_name_00159       -- �g�[�N��'OBJECT_CODE'
                                               ,g_vd_object_tab(in_rec_no).object_code  -- �����R�[�h
                                              )
                                            ,1
                                            ,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
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
-- 2017-11-07 T.Otsuka Add Start --
      IF ( check_flex_value_cur%ISOPEN ) THEN
        CLOSE check_flex_value_cur;
      END IF;
-- 2017-11-07 T.Otsuka Add End --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END data_validation;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_vd_object
   * Description      : ���̋@�������X�V����(A-9)
   ***********************************************************************************/
  PROCEDURE ins_upd_vd_object(
    in_rec_no     IN  NUMBER,       --   �Ώۃ��R�[�h�ԍ�
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_vd_object'; -- �v���O������
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
    cv_history_num_1   CONSTANT NUMBER := 1;
--
    -- *** ���[�J���ϐ� ***
    lv_warn_msg VARCHAR2(5000);      -- �x�����b�Z�[�W�o�͗p�ϐ�
    lv_process_type    VARCHAR2(3);  -- �����敪
    ln_history_num_max NUMBER;       -- ����ԍ��i�ő�l�j
--
    lv_nvl_owner_company_type      xxcff_vd_object_info_upload_wk.owner_company_type%TYPE;     -- �{�Ё^�H��敪
    lv_nvl_department_code         xxcff_vd_object_info_upload_wk.department_code%TYPE;        -- �Ǘ�����
    lv_nvl_moved_date              xxcff_vd_object_info_upload_wk.moved_date%TYPE;             -- �ړ���
    lv_nvl_installation_place      xxcff_vd_object_info_upload_wk.installation_place%TYPE;     -- �ݒu��
    lv_nvl_installation_address    xxcff_vd_object_info_upload_wk.installation_address%TYPE;   -- �ݒu�ꏊ
    lv_nvl_dclr_place              xxcff_vd_object_info_upload_wk.dclr_place%TYPE;             -- �\���n
    lv_nvl_location                xxcff_vd_object_info_upload_wk.location%TYPE;               -- ���Ə�
    lv_nvl_manufacturer_name       xxcff_vd_object_info_upload_wk.manufacturer_name%TYPE;      -- ���[�J�[��
    lv_nvl_model                   xxcff_vd_object_info_upload_wk.model%TYPE;                  -- �@��
    lv_nvl_age_type                xxcff_vd_object_info_upload_wk.age_type%TYPE;               -- �N��
    lv_nvl_quantity                xxcff_vd_object_info_upload_wk.quantity%TYPE;               -- ����
    lv_nvl_date_placed_in_service  xxcff_vd_object_info_upload_wk.date_placed_in_service%TYPE; -- ���Ƌ��p��
    lv_nvl_assets_date             xxcff_vd_object_info_upload_wk.assets_date%TYPE;            -- �擾��
    lv_nvl_assets_cost             xxcff_vd_object_info_upload_wk.assets_cost%TYPE;            -- �擾���i
-- 2014-08-06 S.Yamashita Add Start --
    lv_nvl_cash_price              xxcff_vd_object_info_upload_wk.cash_price%TYPE;             -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
    lv_nvl_date_retired            xxcff_vd_object_info_upload_wk.date_retired%TYPE;           -- ���E���p��
    lv_nvl_proceeds_of_sale        xxcff_vd_object_info_upload_wk.proceeds_of_sale%TYPE;       -- ���p���i
    lv_nvl_cost_of_removal         xxcff_vd_object_info_upload_wk.cost_of_removal%TYPE;        -- �P����p
    lv_nvl_retired_flag            xxcff_vd_object_info_upload_wk.retired_flag%TYPE;           -- �P����p
-- 2017-11-07 T.Otsuka Add Start --
    lv_nvl_ifrs_life_in_months     xxcff_vd_object_info_upload_wk.ifrs_life_in_months%TYPE;    -- IFRS�ϗp�N��
    lv_nvl_ifrs_cat_deprn_method   xxcff_vd_object_info_upload_wk.ifrs_cat_deprn_method%TYPE;  -- IFRS���p
    lv_nvl_real_estate_acq_tax     xxcff_vd_object_info_upload_wk.real_estate_acq_tax%TYPE;    -- �s���Y�擾��
    lv_nvl_borrowing_cost          xxcff_vd_object_info_upload_wk.borrowing_cost%TYPE;         -- �ؓ��R�X�g
    lv_nvl_other_cost              xxcff_vd_object_info_upload_wk.other_cost%TYPE;             -- ���̑�
    lv_nvl_ifrs_asset_account      xxcff_vd_object_info_upload_wk.ifrs_asset_account%TYPE;     -- IFRS���Y�Ȗ�
    lv_nvl_correct_date            xxcff_vd_object_info_upload_wk.correct_date%TYPE;           -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���̋@�����Ǘ�
    CURSOR lock_ob_cur
    IS
      SELECT  xvoh.object_header_id
        FROM  xxcff_vd_object_headers  xvoh  --���̋@�����Ǘ�
       WHERE  xvoh.object_header_id = g_vd_object_tab(in_rec_no).xvoh_object_header_id
      FOR UPDATE NOWAIT
    ;
    -- ���̋@�������� 
    CURSOR lock_hist_cur
    IS
      SELECT  xvohi.object_header_id
        FROM  xxcff_vd_object_histories  xvohi  --���̋@��������
       WHERE  xvohi.object_header_id = g_vd_object_tab(in_rec_no).xvoh_object_header_id
      FOR UPDATE NOWAIT
    ;
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
    -- ���[�J���ϐ��̏�����
    ln_history_num_max := 0;
--
    BEGIN
      -- ���̋@�����Ǘ��e�[�u�����b�N
      OPEN  lock_ob_cur;
      CLOSE lock_ob_cur;
      EXCEPTION
        WHEN lock_expt THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- XXCFF
                                                      ,cv_msg_name_00007    -- ���b�N�G���[
                                                      ,cv_tkn_name_00007    -- �g�[�N��'TABLE_NAME'
                                                      ,cv_tkn_val_50260 )   -- ���̋@�����Ǘ�
                                                      ,1
                                                      ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
    END;
--
    BEGIN
      -- ���̋@���������e�[�u�����b�N
      OPEN  lock_hist_cur;
      CLOSE lock_hist_cur;
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                                    ,cv_msg_name_00007    -- ���b�N�G���[
                                                    ,cv_tkn_name_00007    -- �g�[�N��'TABLE_NAME'
                                                    ,cv_tkn_val_50229 )   -- ���̋@��������
                                                    ,1
                                                    ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ���̋@�����Ǘ��e�[�u���̍X�V
    -- �ύX�敪=�u1�i�ړ��j�v�̏ꍇ
    IF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_1 ) THEN
      UPDATE xxcff_vd_object_headers  xvoh    -- ���̋@�����Ǘ�
      SET    xvoh.owner_company_type     = NVL( g_vd_object_tab(in_rec_no).owner_company_type
                                             ,g_vd_object_tab(in_rec_no).xvoh_owner_company_type ),   -- �{�Ё^�H��敪
             xvoh.department_code        = NVL( g_vd_object_tab(in_rec_no).department_code
                                             ,g_vd_object_tab(in_rec_no).xvoh_department_code ),      -- �Ǘ�����
             xvoh.moved_date             = NVL( g_vd_object_tab(in_rec_no).moved_date
                                             ,g_vd_object_tab(in_rec_no).xvoh_moved_date ),           -- �ړ���
             xvoh.installation_place     = NVL( g_vd_object_tab(in_rec_no).installation_place
                                             ,g_vd_object_tab(in_rec_no).xvoh_installation_place ),   -- �ݒu��
             xvoh.installation_address   = NVL( g_vd_object_tab(in_rec_no).installation_address
                                             ,g_vd_object_tab(in_rec_no).xvoh_installation_address ), -- �ݒu�ꏊ
             xvoh.dclr_place             = NVL( g_vd_object_tab(in_rec_no).dclr_place
                                             ,g_vd_object_tab(in_rec_no).xvoh_dclr_place ),           -- �\���n
             xvoh.location               = NVL( g_vd_object_tab(in_rec_no).location
                                             ,g_vd_object_tab(in_rec_no).xvoh_location ),             -- ���Ə�
             xvoh.last_updated_by        = cn_last_updated_by,                              -- �ŏI�X�V��
             xvoh.last_update_date       = cd_last_update_date,                             -- �ŏI�X�V��
             xvoh.last_update_login      = cn_last_update_login,                            -- �ŏI�X�V���O�C��
             xvoh.request_id             = cn_request_id,                                   -- �v��ID
             xvoh.program_application_id = cn_program_application_id,                       -- �R���J�����g��v���O������A�v���P�[�V����
             xvoh.program_id             = cn_program_id,                                   -- �R���J�����g��v���O����ID
             xvoh.program_update_date    = cd_program_update_date                           -- �v���O�����X�V��
      WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- ����ID
      ;
    -- �ύX�敪=�u2�i�C���j�v�̏ꍇ
    ELSIF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_2 ) THEN
      UPDATE xxcff_vd_object_headers  xvoh    -- ���̋@�����Ǘ�
      SET    xvoh.manufacturer_name      = NVL( g_vd_object_tab(in_rec_no).manufacturer_name
                                             ,g_vd_object_tab(in_rec_no).xvoh_manufacturer_name ),      -- ���[�J��
             xvoh.model                  = NVL( g_vd_object_tab(in_rec_no).model
                                             ,g_vd_object_tab(in_rec_no).xvoh_model ),                  -- �@��
             xvoh.age_type               = NVL( g_vd_object_tab(in_rec_no).age_type
                                             ,g_vd_object_tab(in_rec_no).xvoh_age_type ),               -- �N��
             xvoh.quantity               = NVL( g_vd_object_tab(in_rec_no).quantity
                                             ,g_vd_object_tab(in_rec_no).xvoh_quantity ),               -- ����
             xvoh.date_placed_in_service = NVL( g_vd_object_tab(in_rec_no).date_placed_in_service
                                             ,g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service ), -- ���Ƌ��p��
             xvoh.assets_date            = NVL( g_vd_object_tab(in_rec_no).assets_date
                                             ,g_vd_object_tab(in_rec_no).xvoh_assets_date ),            -- �擾��
             xvoh.assets_cost            = NVL( g_vd_object_tab(in_rec_no).assets_cost
                                             ,g_vd_object_tab(in_rec_no).xvoh_assets_cost ),            -- �擾���i
--             xvoh.month_lease_charge     = NVL( g_vd_object_tab(in_rec_no).month_lease_charge
--                                             ,g_vd_object_tab(in_rec_no).xvoh_month_lease_charge ),     -- ���z���[�X��
--             xvoh.re_lease_charge        = NVL( g_vd_object_tab(in_rec_no).re_lease_charge
--                                             ,g_vd_object_tab(in_rec_no).xvoh_re_lease_charge ),        -- �ă��[�X��
-- 2014-08-06 S.Yamashita Add Start --
             xvoh.cash_price             = NVL( g_vd_object_tab(in_rec_no).cash_price
                                             ,g_vd_object_tab(in_rec_no).xvoh_cash_price ),             -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
-- 2017-11-07 T.Otsuka Add Start --
             xvoh.ifrs_life_in_months    = NVL( g_vd_object_tab(in_rec_no).ifrs_life_in_months
                                             ,g_vd_object_tab(in_rec_no).xvoh_ifrs_life_in_months ),    -- IFRS�ϗp�N��
             xvoh.ifrs_cat_deprn_method  = NVL( g_vd_object_tab(in_rec_no).ifrs_cat_deprn_method
                                             ,g_vd_object_tab(in_rec_no).xvoh_ifrs_cat_deprn_method ),  -- IFRS���p
             xvoh.real_estate_acq_tax    = NVL( g_vd_object_tab(in_rec_no).real_estate_acq_tax
                                             ,g_vd_object_tab(in_rec_no).xvoh_real_estate_acq_tax ),    -- �s���Y�擾��
             xvoh.borrowing_cost         = NVL( g_vd_object_tab(in_rec_no).borrowing_cost
                                             ,g_vd_object_tab(in_rec_no).xvoh_borrowing_cost ),         -- �ؓ��R�X�g
             xvoh.other_cost             = NVL( g_vd_object_tab(in_rec_no).other_cost
                                             ,g_vd_object_tab(in_rec_no).xvoh_other_cost ),             -- ���̑�
             xvoh.ifrs_asset_account     = NVL( g_vd_object_tab(in_rec_no).ifrs_asset_account
                                             ,g_vd_object_tab(in_rec_no).xvoh_ifrs_asset_account ),     -- IFRS���Y�Ȗ�
             xvoh.correct_date           = NVL( g_vd_object_tab(in_rec_no).correct_date
                                             ,g_vd_object_tab(in_rec_no).xvoh_correct_date ),           -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
             xvoh.last_updated_by        = cn_last_updated_by,                              -- �ŏI�X�V��
             xvoh.last_update_date       = cd_last_update_date,                             -- �ŏI�X�V��
             xvoh.last_update_login      = cn_last_update_login,                            -- �ŏI�X�V���O�C��
             xvoh.request_id             = cn_request_id,                                   -- �v��ID
             xvoh.program_application_id = cn_program_application_id,                       -- �R���J�����g��v���O������A�v���P�[�V����
             xvoh.program_id             = cn_program_id,                                   -- �R���J�����g��v���O����ID
             xvoh.program_update_date    = cd_program_update_date                           -- �v���O�����X�V��
      WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- ����ID
      ;
    -- �ύX�敪=�u3�i�����p�j�v���X�V�Ώۂ̕����X�e�[�^�X=�u105�i�����p���m��j�v �̏ꍇ
    ELSIF ( (g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_3)
         AND ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_105 ) 
    )
    THEN
      UPDATE xxcff_vd_object_headers  xvoh    -- ���̋@�����Ǘ�
      SET    xvoh.date_retired           = NVL( g_vd_object_tab(in_rec_no).date_retired
                                             ,g_vd_object_tab(in_rec_no).xvoh_date_retired ),      -- ���E���p��
             xvoh.proceeds_of_sale       = NVL( g_vd_object_tab(in_rec_no).proceeds_of_sale
                                             ,g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale ),  -- ���p���i
             xvoh.cost_of_removal        = NVL( g_vd_object_tab(in_rec_no).cost_of_removal
                                             ,g_vd_object_tab(in_rec_no).xvoh_cost_of_removal ),   -- �P����p
             xvoh.retired_flag           = g_vd_object_tab(in_rec_no).retired_flag,                -- ���E���p�m��t���O
             xvoh.last_updated_by        = cn_last_updated_by,                              -- �ŏI�X�V��
             xvoh.last_update_date       = cd_last_update_date,                             -- �ŏI�X�V��
             xvoh.last_update_login      = cn_last_update_login,                            -- �ŏI�X�V���O�C��
             xvoh.request_id             = cn_request_id,                                   -- �v��ID
             xvoh.program_application_id = cn_program_application_id,                       -- �R���J�����g��v���O������A�v���P�[�V����
             xvoh.program_id             = cn_program_id,                                   -- �R���J�����g��v���O����ID
             xvoh.program_update_date    = cd_program_update_date                           -- �v���O�����X�V��
      WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- ����ID
      ;
    END IF;
--
    -- ���̋@���������e�[�u���̍X�V
    -- �X�V�Ώۂ̕����X�e�[�^�X���u���m��v�̏ꍇ
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_101 ) THEN
      -- �ύX�敪=�u1�i�ړ��j�v�̏ꍇ
      IF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_1 ) THEN
        UPDATE xxcff_vd_object_histories  xvohi    -- ���̋@��������
        SET    xvohi.process_date           = g_init_rec.process_date,                                  -- �Ɩ����t
               xvohi.owner_company_type     = NVL( g_vd_object_tab(in_rec_no).owner_company_type
                                               ,g_vd_object_tab(in_rec_no).xvoh_owner_company_type ),   -- �{�Ё^�H��敪
               xvohi.department_code        = NVL( g_vd_object_tab(in_rec_no).department_code
                                               ,g_vd_object_tab(in_rec_no).xvoh_department_code ),      -- �Ǘ�����
               xvohi.moved_date             = NVL( g_vd_object_tab(in_rec_no).moved_date
                                               ,g_vd_object_tab(in_rec_no).xvoh_moved_date ),           -- �ړ���
               xvohi.installation_place     = NVL( g_vd_object_tab(in_rec_no).installation_place
                                               ,g_vd_object_tab(in_rec_no).xvoh_installation_place ),   -- �ݒu��
               xvohi.installation_address   = NVL( g_vd_object_tab(in_rec_no).installation_address
                                               ,g_vd_object_tab(in_rec_no).xvoh_installation_address ), -- �ݒu�ꏊ
               xvohi.dclr_place             = NVL( g_vd_object_tab(in_rec_no).dclr_place
                                               ,g_vd_object_tab(in_rec_no).xvoh_dclr_place ),           -- �\���n
               xvohi.location               = NVL( g_vd_object_tab(in_rec_no).location
                                               ,g_vd_object_tab(in_rec_no).xvoh_location ),             -- ���Ə�
               xvohi.last_updated_by        = cn_last_updated_by,                              -- �ŏI�X�V��
               xvohi.last_update_date       = cd_last_update_date,                             -- �ŏI�X�V��
               xvohi.last_update_login      = cn_last_update_login,                            -- �ŏI�X�V���O�C��
               xvohi.request_id             = cn_request_id,                                   -- �v��ID
               xvohi.program_application_id = cn_program_application_id,                       -- �R���J�����g��v���O������A�v���P�[�V����
               xvohi.program_id             = cn_program_id,                                   -- �R���J�����g��v���O����ID
               xvohi.program_update_date    = cd_program_update_date                           -- �v���O�����X�V��
        WHERE  xvohi.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- ����ID
        AND    xvohi.history_num = cv_history_num_1  -- ����ԍ�
        ;
      -- �ύX�敪=�u2�i�C���j�v�̏ꍇ
      ELSIF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_2 ) THEN
        UPDATE xxcff_vd_object_histories  xvohi    -- ���̋@��������
        SET    xvohi.process_date           = g_init_rec.process_date,                                    -- �Ɩ����t
               xvohi.manufacturer_name      = NVL( g_vd_object_tab(in_rec_no).manufacturer_name
                                               ,g_vd_object_tab(in_rec_no).xvoh_manufacturer_name ),      -- ���[�J��
               xvohi.model                  = NVL( g_vd_object_tab(in_rec_no).model
                                               ,g_vd_object_tab(in_rec_no).xvoh_model ),                  -- �@��
               xvohi.age_type               = NVL( g_vd_object_tab(in_rec_no).age_type
                                               ,g_vd_object_tab(in_rec_no).xvoh_age_type ),               -- �N��
               xvohi.quantity               = NVL( g_vd_object_tab(in_rec_no).quantity
                                               ,g_vd_object_tab(in_rec_no).xvoh_quantity ),               -- ����
               xvohi.date_placed_in_service = NVL( g_vd_object_tab(in_rec_no).date_placed_in_service
                                               ,g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service ), -- ���Ƌ��p��
               xvohi.assets_date            = NVL( g_vd_object_tab(in_rec_no).assets_date
                                               ,g_vd_object_tab(in_rec_no).xvoh_assets_date ),            -- �擾��
               xvohi.assets_cost            = NVL( g_vd_object_tab(in_rec_no).assets_cost
                                               ,g_vd_object_tab(in_rec_no).xvoh_assets_cost ),            -- �擾���i
-- 2014-08-06 S.Yamashita Add Start --
               xvohi.cash_price             = NVL( g_vd_object_tab(in_rec_no).cash_price
                                               ,g_vd_object_tab(in_rec_no).xvoh_cash_price ),             -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
-- 2017-11-07 T.Otsuka Add Start --
             xvohi.ifrs_life_in_months      = NVL( g_vd_object_tab(in_rec_no).ifrs_life_in_months
                                               ,g_vd_object_tab(in_rec_no).xvoh_ifrs_life_in_months ),    -- IFRS�ϗp�N��
             xvohi.ifrs_cat_deprn_method    = NVL( g_vd_object_tab(in_rec_no).ifrs_cat_deprn_method
                                               ,g_vd_object_tab(in_rec_no).xvoh_ifrs_cat_deprn_method ),  -- IFRS���p
             xvohi.real_estate_acq_tax      = NVL( g_vd_object_tab(in_rec_no).real_estate_acq_tax
                                               ,g_vd_object_tab(in_rec_no).xvoh_real_estate_acq_tax ),    -- �s���Y�擾��
             xvohi.borrowing_cost           = NVL( g_vd_object_tab(in_rec_no).borrowing_cost
                                               ,g_vd_object_tab(in_rec_no).xvoh_borrowing_cost ),         -- �ؓ��R�X�g
             xvohi.other_cost               = NVL( g_vd_object_tab(in_rec_no).other_cost
                                               ,g_vd_object_tab(in_rec_no).xvoh_other_cost ),             -- ���̑�
             xvohi.ifrs_asset_account       = NVL( g_vd_object_tab(in_rec_no).ifrs_asset_account
                                               ,g_vd_object_tab(in_rec_no).xvoh_ifrs_asset_account ),     -- IFRS���Y�Ȗ�
             xvohi.correct_date             = NVL( g_vd_object_tab(in_rec_no).correct_date
                                               ,g_vd_object_tab(in_rec_no).xvoh_correct_date ),           -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
--               xvohi.month_lease_charge     = NVL( g_vd_object_tab(in_rec_no).month_lease_charge
--                                               ,g_vd_object_tab(in_rec_no).xvoh_month_lease_charge ),     -- ���z���[�X��
--               xvohi.re_lease_charge        = NVL( g_vd_object_tab(in_rec_no).re_lease_charge
--                                               ,g_vd_object_tab(in_rec_no).xvoh_re_lease_charge ),        -- �ă��[�X��
               xvohi.last_updated_by        = cn_last_updated_by,                              -- �ŏI�X�V��
               xvohi.last_update_date       = cd_last_update_date,                             -- �ŏI�X�V��
               xvohi.last_update_login      = cn_last_update_login,                            -- �ŏI�X�V���O�C��
               xvohi.request_id             = cn_request_id,                                   -- �v��ID
               xvohi.program_application_id = cn_program_application_id,                       -- �R���J�����g��v���O������A�v���P�[�V����
               xvohi.program_id             = cn_program_id,                                   -- �R���J�����g��v���O����ID
               xvohi.program_update_date    = cd_program_update_date                           -- �v���O�����X�V��
        WHERE  xvohi.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- ����ID
        AND    xvohi.history_num = cv_history_num_1  -- ����ԍ�
        ;
      END IF;
    -- �X�V�Ώۂ̕����X�e�[�^�X���u�m��ρv�܂��́u�����p���m��v�̏ꍇ
    ELSIF ( (g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_102)
      OR (g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_105)
    )
    THEN
      -- ����ԍ��i�ő�l�j���擾
      SELECT MAX(xvohi.history_num)
      INTO   ln_history_num_max  -- ����ԍ��i�ő�l�j
      FROM   xxcff_vd_object_histories xvohi  -- ���̋@��������
      WHERE  xvohi.object_header_id = g_vd_object_tab(in_rec_no).xvoh_object_header_id
      ;
      ln_history_num_max := ln_history_num_max + 1;
      -- �ړ��̏ꍇ
      IF (  g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_1 ) THEN
        -- �����敪�̐ݒ�
        lv_process_type := cv_process_type_103;
        -- �o�^�l�̐ݒ�
        lv_nvl_owner_company_type     := NVL( g_vd_object_tab(in_rec_no).owner_company_type
                                                 ,g_vd_object_tab(in_rec_no).xvoh_owner_company_type ); -- �{�Ё^�H��敪
        lv_nvl_department_code        := NVL( g_vd_object_tab(in_rec_no).department_code
                                                 ,g_vd_object_tab(in_rec_no).xvoh_department_code );    -- �Ǘ�����
        lv_nvl_moved_date             := NVL( g_vd_object_tab(in_rec_no).moved_date
                                                 ,g_vd_object_tab(in_rec_no).xvoh_moved_date );         -- �ړ���
        lv_nvl_installation_place     := NVL( g_vd_object_tab(in_rec_no).installation_place
                                             ,g_vd_object_tab(in_rec_no).xvoh_installation_place );     -- �ݒu��
        lv_nvl_installation_address   := NVL( g_vd_object_tab(in_rec_no).installation_address
                                                 ,g_vd_object_tab(in_rec_no).xvoh_installation_address );   -- �ݒu�ꏊ
        lv_nvl_dclr_place             := NVL( g_vd_object_tab(in_rec_no).dclr_place
                                                 ,g_vd_object_tab(in_rec_no).xvoh_dclr_place );             -- �\���n
        lv_nvl_location               := NVL( g_vd_object_tab(in_rec_no).location
                                                 ,g_vd_object_tab(in_rec_no).xvoh_location );               -- ���Ə�
        lv_nvl_manufacturer_name      := g_vd_object_tab(in_rec_no).xvoh_manufacturer_name;             -- ���[�J�[��
        lv_nvl_model                  := g_vd_object_tab(in_rec_no).xvoh_model;                         -- �@��
        lv_nvl_age_type               := g_vd_object_tab(in_rec_no).xvoh_age_type;                      -- �N��
        lv_nvl_quantity               := g_vd_object_tab(in_rec_no).xvoh_quantity;                      -- ����
        lv_nvl_date_placed_in_service := g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service;        -- ���Ƌ��p��
        lv_nvl_assets_date            := g_vd_object_tab(in_rec_no).xvoh_assets_date;                   -- �擾��
        lv_nvl_assets_cost            := g_vd_object_tab(in_rec_no).xvoh_assets_cost;                   -- �擾���i
-- 2014-08-06 S.Yamashita Add Start --
        lv_nvl_cash_price             := g_vd_object_tab(in_rec_no).xvoh_cash_price;                    -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
        lv_nvl_date_retired           := g_vd_object_tab(in_rec_no).xvoh_date_retired;                  -- ���E���p��
        lv_nvl_proceeds_of_sale       := g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale;              -- ���p���i
        lv_nvl_cost_of_removal        := g_vd_object_tab(in_rec_no).xvoh_cost_of_removal;               -- �P����p
        lv_nvl_retired_flag           := g_vd_object_tab(in_rec_no).xvoh_retired_flag;                  -- �����p�m��t���O
-- 2017-11-07 T.Otsuka Add Start --
        lv_nvl_ifrs_life_in_months    :=g_vd_object_tab(in_rec_no).xvoh_ifrs_life_in_months;            -- IFRS�ϗp�N��
        lv_nvl_ifrs_cat_deprn_method  :=g_vd_object_tab(in_rec_no).xvoh_ifrs_cat_deprn_method;          -- IFRS���p
        lv_nvl_real_estate_acq_tax    :=g_vd_object_tab(in_rec_no).xvoh_real_estate_acq_tax;            -- �s���Y�擾��
        lv_nvl_borrowing_cost         :=g_vd_object_tab(in_rec_no).xvoh_borrowing_cost;                 -- �ؓ��R�X�g
        lv_nvl_other_cost             :=g_vd_object_tab(in_rec_no).xvoh_other_cost;                     -- ���̑�
        lv_nvl_ifrs_asset_account     :=g_vd_object_tab(in_rec_no).xvoh_ifrs_asset_account;             -- IFRS���Y�Ȗ�
        lv_nvl_correct_date           :=g_vd_object_tab(in_rec_no).xvoh_correct_date;                   -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
      -- �C���̏ꍇ
      ELSIF (  g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_2 ) THEN
        -- �����敪�̐ݒ�
        lv_process_type := cv_process_type_104;
        -- �o�^�l�̐ݒ�
        lv_nvl_owner_company_type     := g_vd_object_tab(in_rec_no).xvoh_owner_company_type;     -- �{�Ё^�H��敪
        lv_nvl_department_code        := g_vd_object_tab(in_rec_no).xvoh_department_code;        -- �Ǘ�����
        lv_nvl_moved_date             := g_vd_object_tab(in_rec_no).xvoh_moved_date;             -- �ړ���
        lv_nvl_installation_place     := g_vd_object_tab(in_rec_no).xvoh_installation_place;     -- �ݒu��
        lv_nvl_installation_address   := g_vd_object_tab(in_rec_no).xvoh_installation_address;   -- �ݒu�ꏊ
        lv_nvl_dclr_place             := g_vd_object_tab(in_rec_no).xvoh_dclr_place;             -- �\���n
        lv_nvl_location               := g_vd_object_tab(in_rec_no).xvoh_location;               -- ���Ə�
        lv_nvl_manufacturer_name      := NVL( g_vd_object_tab(in_rec_no).manufacturer_name
                                                 ,g_vd_object_tab(in_rec_no).xvoh_manufacturer_name ); -- ���[�J�[��
        lv_nvl_model                  := NVL( g_vd_object_tab(in_rec_no).model
                                                 ,g_vd_object_tab(in_rec_no).xvoh_model );    -- �@��
        lv_nvl_age_type               := NVL( g_vd_object_tab(in_rec_no).age_type
                                                 ,g_vd_object_tab(in_rec_no).xvoh_age_type ); -- �N��
        lv_nvl_quantity               := NVL( g_vd_object_tab(in_rec_no).quantity
                                                 ,g_vd_object_tab(in_rec_no).xvoh_quantity ); -- ����
        lv_nvl_date_placed_in_service := NVL( g_vd_object_tab(in_rec_no).date_placed_in_service
                                                 ,g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service ); -- ���Ƌ��p��
        lv_nvl_assets_date            := NVL( g_vd_object_tab(in_rec_no).assets_date
                                                 ,g_vd_object_tab(in_rec_no).xvoh_assets_date );  -- �擾��
        lv_nvl_assets_cost            := NVL( g_vd_object_tab(in_rec_no).assets_cost
                                                 ,g_vd_object_tab(in_rec_no).xvoh_assets_cost );  -- �擾���i
-- 2014-08-06 S.Yamashita Add Start --
        lv_nvl_cash_price             := NVL( g_vd_object_tab(in_rec_no).cash_price
                                                 ,g_vd_object_tab(in_rec_no).xvoh_cash_price );   -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
        lv_nvl_date_retired           := g_vd_object_tab(in_rec_no).xvoh_date_retired;             -- ���E���p��
        lv_nvl_proceeds_of_sale       := g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale;         -- ���p���i
        lv_nvl_cost_of_removal        := g_vd_object_tab(in_rec_no).xvoh_cost_of_removal;          -- �P����p
        lv_nvl_retired_flag           := g_vd_object_tab(in_rec_no).xvoh_retired_flag;             -- �����p�m��t���O
-- 2017-11-07 T.Otsuka Add Start --
        lv_nvl_ifrs_life_in_months    := NVL( g_vd_object_tab(in_rec_no).ifrs_life_in_months
                                                 ,g_vd_object_tab(in_rec_no).xvoh_ifrs_life_in_months );   -- IFRS�ϗp�N��
        lv_nvl_ifrs_cat_deprn_method  := NVL( g_vd_object_tab(in_rec_no).ifrs_cat_deprn_method
                                                 ,g_vd_object_tab(in_rec_no).xvoh_ifrs_cat_deprn_method ); -- IFRS���p
        lv_nvl_real_estate_acq_tax    := NVL( g_vd_object_tab(in_rec_no).real_estate_acq_tax
                                                 ,g_vd_object_tab(in_rec_no).xvoh_real_estate_acq_tax );   -- �s���Y�擾��
        lv_nvl_borrowing_cost         := NVL( g_vd_object_tab(in_rec_no).borrowing_cost
                                                 ,g_vd_object_tab(in_rec_no).xvoh_borrowing_cost );        -- �ؓ��R�X�g
        lv_nvl_other_cost             := NVL( g_vd_object_tab(in_rec_no).other_cost
                                                 ,g_vd_object_tab(in_rec_no).xvoh_other_cost );            -- ���̑�
        lv_nvl_ifrs_asset_account     := NVL( g_vd_object_tab(in_rec_no).ifrs_asset_account
                                                 ,g_vd_object_tab(in_rec_no).xvoh_ifrs_asset_account );    -- IFRS���Y�Ȗ�
        lv_nvl_correct_date           := NVL( g_vd_object_tab(in_rec_no).correct_date
                                                 ,g_vd_object_tab(in_rec_no).xvoh_correct_date );          -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
      -- �����p�̏ꍇ
      ELSE
        -- �����敪
        lv_process_type := cv_process_type_105;
        -- �o�^�l�̐ݒ�
        lv_nvl_owner_company_type     := g_vd_object_tab(in_rec_no).xvoh_owner_company_type;     -- �{�Ё^�H��敪
        lv_nvl_department_code        := g_vd_object_tab(in_rec_no).xvoh_department_code;        -- �Ǘ�����
        lv_nvl_moved_date             := g_vd_object_tab(in_rec_no).xvoh_moved_date;             -- �ړ���
        lv_nvl_installation_place     := g_vd_object_tab(in_rec_no).xvoh_installation_place;     -- �ݒu��
        lv_nvl_installation_address   := g_vd_object_tab(in_rec_no).xvoh_installation_address;   -- �ݒu�ꏊ
        lv_nvl_dclr_place             := g_vd_object_tab(in_rec_no).xvoh_dclr_place;             -- �\���n
        lv_nvl_location               := g_vd_object_tab(in_rec_no).xvoh_location;               -- ���Ə�
        lv_nvl_manufacturer_name      := g_vd_object_tab(in_rec_no).xvoh_manufacturer_name;             -- ���[�J�[��
        lv_nvl_model                  := g_vd_object_tab(in_rec_no).xvoh_model;                         -- �@��
        lv_nvl_age_type               := g_vd_object_tab(in_rec_no).xvoh_age_type;                      -- �N��
        lv_nvl_quantity               := g_vd_object_tab(in_rec_no).xvoh_quantity;                      -- ����
        lv_nvl_date_placed_in_service := g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service;        -- ���Ƌ��p��
        lv_nvl_assets_date            := g_vd_object_tab(in_rec_no).xvoh_assets_date;                   -- �擾��
        lv_nvl_assets_cost            := g_vd_object_tab(in_rec_no).xvoh_assets_cost;                   -- �擾���i
-- 2014-08-06 S.Yamashita Add Start --
        lv_nvl_cash_price             := g_vd_object_tab(in_rec_no).xvoh_cash_price;                    -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
        lv_nvl_date_retired           := NVL( g_vd_object_tab(in_rec_no).date_retired
                                                 ,g_vd_object_tab(in_rec_no).xvoh_date_retired );  -- ���E���p��
        lv_nvl_proceeds_of_sale       := NVL( g_vd_object_tab(in_rec_no).proceeds_of_sale
                                                 ,g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale ); -- ���p���i
        lv_nvl_cost_of_removal        := NVL( g_vd_object_tab(in_rec_no).cost_of_removal
                                                 ,g_vd_object_tab(in_rec_no).xvoh_cost_of_removal );  -- �P����p
        lv_nvl_retired_flag           := NVL( g_vd_object_tab(in_rec_no).retired_flag
                                                 ,g_vd_object_tab(in_rec_no).xvoh_retired_flag );  -- �����p�m��t���O
-- 2017-11-07 T.Otsuka Add Start --
        lv_nvl_ifrs_life_in_months    :=g_vd_object_tab(in_rec_no).xvoh_ifrs_life_in_months;            -- IFRS�ϗp�N��
        lv_nvl_ifrs_cat_deprn_method  :=g_vd_object_tab(in_rec_no).xvoh_ifrs_cat_deprn_method;          -- IFRS���p
        lv_nvl_real_estate_acq_tax    :=g_vd_object_tab(in_rec_no).xvoh_real_estate_acq_tax;            -- �s���Y�擾��
        lv_nvl_borrowing_cost         :=g_vd_object_tab(in_rec_no).xvoh_borrowing_cost;                 -- �ؓ��R�X�g
        lv_nvl_other_cost             :=g_vd_object_tab(in_rec_no).xvoh_other_cost;                     -- ���̑�
        lv_nvl_ifrs_asset_account     :=g_vd_object_tab(in_rec_no).xvoh_ifrs_asset_account;             -- IFRS���Y�Ȗ�
        lv_nvl_correct_date           :=g_vd_object_tab(in_rec_no).xvoh_correct_date;                   -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
      END IF;
--
      -- ���̋@��������o�^
      INSERT INTO xxcff_vd_object_histories(
             object_header_id        -- ����ID
           , object_code             -- �����R�[�h
           , history_num             -- ����ԍ�
           , process_type            -- �����敪
           , process_date            -- ������
           , object_status           -- �����X�e�[�^�X
           , owner_company_type      -- �{�Ё^�H��敪
           , department_code         -- �Ǘ�����
           , machine_type            -- �@��敪
           , manufacturer_name       -- ���[�J�[��
           , model                   -- �@��
           , age_type                -- �N��
           , customer_code           -- �ڋq�R�[�h
           , quantity                -- ����
           , date_placed_in_service  -- ���Ƌ��p��
           , assets_cost             -- �擾���i
--           , month_lease_charge      -- ���z���[�X��
--           , re_lease_charge         -- �ă��[�X��
-- 2014-08-06 S.Yamashita Add Start --
           , cash_price              -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
-- 2017-11-07 T.Otsuka Add Start --
           , ifrs_life_in_months     -- IFRS�ϗp�N��
           , ifrs_cat_deprn_method   -- IFRS���p
           , real_estate_acq_tax     -- �s���Y�擾��
           , borrowing_cost          -- �ؓ��R�X�g
           , other_cost              -- ���̑�
           , ifrs_asset_account      -- IFRS���Y�Ȗ�
           , correct_date            -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
           , assets_date             -- �擾��
           , moved_date              -- �ړ���
           , installation_place      -- �ݒu��
           , installation_address    -- �ݒu�ꏊ
           , dclr_place              -- �\���n
           , location                -- ���Ə�
           , date_retired            -- ���E���p��
           , proceeds_of_sale        -- ���p���i
           , cost_of_removal         -- �P����p
           , retired_flag            -- �����p�m��t���O
           , ib_if_date              -- �ݒu�x�[�X���A�g��
           , fa_if_date              -- FA���A�g��
           , fa_if_flag              -- FA�A�g�t���O
           , created_by              -- �쐬��
           , creation_date           -- �쐬��
           , last_updated_by         -- �ŏI�X�V��
           , last_update_date        -- �ŏI�X�V��
           , last_update_login       -- �ŏI�X�V۸޲�
           , request_id              -- �v��ID
           , program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
           , program_id              -- �ݶ��ĥ��۸���ID
           , program_update_date     -- ��۸��эX�V��
          )
          VALUES(
             g_vd_object_tab(in_rec_no).xvoh_object_header_id        -- ����ID
           , g_vd_object_tab(in_rec_no).object_code                  -- �����R�[�h
           , ln_history_num_max                                      -- ����ԍ�
           , lv_process_type                                         -- �����敪
           , g_init_rec.process_date                                 -- ������
           , g_vd_object_tab(in_rec_no).xvoh_object_status           -- �����X�e�[�^�X
           , lv_nvl_owner_company_type                               -- �{�Ё^�H��敪
           , lv_nvl_department_code                                  -- �Ǘ�����
           , g_vd_object_tab(in_rec_no).xvoh_machine_type            -- �@��敪
           , lv_nvl_manufacturer_name                                -- ���[�J�[��
           , lv_nvl_model                                            -- �@��
           , lv_nvl_age_type                                         -- �N��
           , g_vd_object_tab(in_rec_no).xvoh_customer_code           -- �ڋq�R�[�h
           , lv_nvl_quantity                                         -- ����
           , lv_nvl_date_placed_in_service                           -- ���Ƌ��p��
           , lv_nvl_assets_cost                                      -- �擾���i
--           , NVL( g_vd_object_tab(in_rec_no).month_lease_charge
--               ,g_vd_object_tab(in_rec_no).xvoh_month_lease_charge ) -- ���z���[�X��
--           , NVL( g_vd_object_tab(in_rec_no).re_lease_charge
--               ,g_vd_object_tab(in_rec_no).xvoh_re_lease_charge )    -- �ă��[�X��
-- 2014-08-06 S.Yamashita Add Start --
           , lv_nvl_cash_price                                       -- �w�����i
-- 2014-08-06 S.Yamashita Add End --
-- 2017-11-07 T.Otsuka Add Start --
           , lv_nvl_ifrs_life_in_months                              -- IFRS�ϗp�N��
           , lv_nvl_ifrs_cat_deprn_method                            -- IFRS���p
           , lv_nvl_real_estate_acq_tax                              -- �s���Y�擾��
           , lv_nvl_borrowing_cost                                   -- �ؓ��R�X�g
           , lv_nvl_other_cost                                       -- ���̑�
           , lv_nvl_ifrs_asset_account                               -- IFRS���Y�Ȗ�
           , lv_nvl_correct_date                                     -- �C���N����
-- 2017-11-07 T.Otsuka Add End --
           , lv_nvl_assets_date                                      -- �擾��
           , lv_nvl_moved_date                                       -- �ړ���
           , lv_nvl_installation_place                               -- �ݒu��
           , lv_nvl_installation_address                             -- �ݒu�ꏊ
           , lv_nvl_dclr_place                                       -- �\���n
           , lv_nvl_location                                         -- ���Ə�
           , lv_nvl_date_retired                                     -- ���E���p��
           , lv_nvl_proceeds_of_sale                                 -- ���p���i
           , lv_nvl_cost_of_removal                                  -- �P����p
           , lv_nvl_retired_flag                                     -- �����p�m��t���O
           , g_vd_object_tab(in_rec_no).xvoh_ib_if_date              -- �ݒu�x�[�X���A�g��
           , NULL                                                    -- FA���A�g��
           , cv_const_n                                              -- FA�A�g�t���O
           , cn_created_by                                           -- �쐬��
           , cd_creation_date                                        -- �쐬��
           , cn_last_updated_by                                      -- �ŏI�X�V��
           , cd_last_update_date                                     -- �ŏI�X�V��
           , cn_last_update_login                                    -- �ŏI�X�V۸޲�
           , cn_request_id                                           -- �v��ID
           , cn_program_application_id                               -- �ݶ��ĥ��۸��ѥ���ع����ID
           , cn_program_id                                           -- �ݶ��ĥ��۸���ID
           , cd_program_update_date                                  -- ��۸��эX�V��
          )
          ;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
      IF ( lock_ob_cur%ISOPEN ) THEN
        CLOSE lock_ob_cur;
      END IF;
      IF ( lock_hist_cur%ISOPEN ) THEN
        CLOSE lock_hist_cur;
      END IF;
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_upd_vd_object;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER,       -- 1.�t�@�C��ID
    iv_file_format  IN   VARCHAR2,     -- 2.�t�@�C���t�H�[�}�b�g
    ov_errbuf       OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT  VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_error_cnt   NUMBER;
--
    -- ���[�v���̃J�E���g
    ln_loop_cnt_1  NUMBER;
    ln_loop_cnt_2  NUMBER;
    ln_loop_cnt_3  NUMBER;
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
    gn_target_cnt               := 0;
    gn_normal_cnt               := 0;
    gn_error_cnt                := 0;
    gn_warn_cnt                 := 0;
    gb_err_flag                 := FALSE;
    gv_object_code_pre          := 'DUMMY';
    gv_upload_type_pre          := 'DUMMY'; 
--
    -- ���[�J���ϐ��̏�����
    ln_loop_cnt_1               := 0;
    ln_loop_cnt_2               := 0;
    ln_loop_cnt_3               := 0;
    ln_error_cnt                := 0;
--

--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    -- ============================================
    -- A-1�D��������
    -- ============================================
    init(
       in_file_id        -- 1.�t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�D�Ó����`�F�b�N�p�̒l�擾
    -- ============================================
    get_for_validation(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3�D�t�@�C���A�b�v���[�hIF�f�[�^�擾
    -- ============================================
    get_upload_data(
       in_file_id        -- 1.�t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --���C�����[�v�@
    <<MAIN_LOOP_1>>
    FOR ln_loop_cnt_1 IN g_file_upload_if_data_tab.FIRST .. g_file_upload_if_data_tab.LAST LOOP
      --�P�s�ڂ̏ꍇ�J�����s�̏����ƂȂ�ׁA�X�L�b�v���ĂQ�s�ڂ̏����ɑJ�ڂ���
      IF ( ln_loop_cnt_1 <> 1 ) THEN
        --���C�����[�v�A�J�E���^�̃��Z�b�g
        ln_loop_cnt_2 := 0;
--
        --���C�����[�v�A
        <<MAIN_LOOP_2>>
        FOR ln_loop_cnt_2 IN g_column_desc_tab.FIRST .. g_column_desc_tab.LAST LOOP
          -- ============================================
          -- A-4�D�f���~�^�������ڕ���
          -- ============================================
          divide_item(
             ln_loop_cnt_1     -- ���[�v�J�E���^1
            ,ln_loop_cnt_2     -- ���[�v�J�E���^2
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          IF ( gb_err_flag ) THEN
            EXIT MAIN_LOOP_2;
          END IF;
--
          -- ���ڂ�NULL�łȂ��ꍇ�̂݁AA-5�̃`�F�b�N���s��
          IF ( g_load_data_tab(ln_loop_cnt_2) IS NOT NULL ) THEN
            -- ============================================
            -- A-5�D���ڒl�`�F�b�N
            -- ============================================
            check_item_value(
               ln_loop_cnt_2     -- ���[�v�J�E���^2
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode = cv_status_error ) THEN -- �V�X�e���G���[�̏ꍇ
              RAISE global_process_expt;
            END IF;
          END IF;
--
        END LOOP MAIN_LOOP_2;
--
        -- ���ڒl�`�F�b�N�ŃG���[�����������ꍇ�A�G���[�������J�E���g���AA-6�̏������X�L�b�v
        IF ( gb_err_flag ) THEN
          --  �Ώی������J�E���g
          gn_target_cnt := gn_target_cnt + 1;
          --�G���[�������J�E���g
          ln_error_cnt := ln_error_cnt + 1;
          gn_error_cnt := gn_error_cnt + 1;
          --�������p���ׁ̈A�G���[�t���O��߂�
          gb_err_flag := FALSE;
        ELSE
          
          -- �ύX�敪��NULL�łȂ����R�[�h�̂ݓo�^����
          IF ( g_load_data_tab(cv_upload_type_col) IS NOT NULL ) THEN
            --  �Ώی������J�E���g
            gn_target_cnt := gn_target_cnt + 1;
--
            -- ============================================
            -- A-6�D���̋@�������A�b�v���[�h���[�N�쐬
            -- ============================================
              ins_upload_wk(
                 in_file_id        -- 1.�t�@�C��ID
                ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
                ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
            IF ( lv_retcode = cv_status_error ) THEN
              --�G���[�������J�E���g
              ln_error_cnt := ln_error_cnt + 1;
              gn_error_cnt := gn_error_cnt + 1;
              RAISE global_process_expt;
            END IF;
          END IF;
        END IF;
      END IF;
--
    END LOOP MAIN_LOOP_1;
--
    -- 1���ł��G���[�����݂���ꍇ�͏������I������
    IF ( ln_error_cnt <> 0 ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-7�D���̋@�������A�b�v���[�h���[�N�擾
    -- ============================================
    get_upload_wk(
       in_file_id        -- 1.�t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- A-7�Ŏ擾������1���ȏ�̏ꍇ
    IF ( g_vd_object_tab.COUNT <> 0 ) THEN
--
      -- ���C�����[�v�B
      <<MAIN_LOOP_3>>
      FOR ln_loop_cnt_3 IN g_vd_object_tab.FIRST .. g_vd_object_tab.LAST LOOP
--
        -- �G���[�t���O�̏�����
        gb_err_flag := FALSE;
--
        -- ============================================
        -- A-8�D�f�[�^�Ó����`�F�b�N
        -- ============================================
        data_validation(
           ln_loop_cnt_3     -- ���[�v�J�E���^3�i�Ώۃ��R�[�h�ԍ��j
          ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �G���[�����������ꍇ�A�G���[�������J�E���g
        IF ( gb_err_flag ) THEN
          ln_error_cnt := ln_error_cnt + 1;
          gn_error_cnt := gn_error_cnt + 1;
        -- �`�F�b�N�G���[���������Ȃ������f�[�^�̂ݏ�����i�߂�
        ELSE
          -- ============================================
          -- A-9�D���̋@�������X�V
          -- ============================================
          ins_upd_vd_object(
             ln_loop_cnt_3     -- ���[�v�J�E���^3�i�Ώۃ��R�[�h�ԍ��j
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
      END LOOP MAIN_LOOP_3;
--
      -- 1���ł��G���[�����݂���ꍇ�G���[�I��
      IF ( ln_error_cnt <> 0 ) THEN
        ov_retcode := cv_status_error;
      END IF;
--
    ELSE
      -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�́A�Ώۃf�[�^�Ȃ����b�Z�[�W��\��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_msg_kbn_cff,   -- �A�v���P�[�V�����Z�k��
                     iv_name        => cv_msg_name_00062  -- ���b�Z�[�W�R�[�h
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      ov_retcode := cv_status_warn;
    END IF;
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
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
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT   VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    in_file_id       IN    NUMBER,          --   1.�t�@�C��ID(�K�{)
    iv_file_format   IN    VARCHAR2         --   2.�t�@�C���t�H�[�}�b�g(�K�{)
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
      ,iv_which   => cv_file_type_out
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
       in_file_id      -- 1.�t�@�C��ID
      ,iv_file_format  -- 2.�t�@�C���t�H�[�}�b�g
      ,lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    IF (  lv_retcode <> cv_status_normal ) THEN
      -- �@����ȊO�̏ꍇ�A���[���o�b�N�𔭍s
      ROLLBACK;
    ELSE
      -- ����̏ꍇ
      -- ���̋@�����A�b�v���[�h���[�N�폜
      DELETE FROM
        xxcff_vd_object_info_upload_wk  --���̋@�����A�b�v���[�h���[�N
      WHERE
        file_id = in_file_id
      ;
      -- �폜�܂Ő����������R�[�h�����A���������ɐݒ�
      gn_normal_cnt := SQL%ROWCOUNT;
    END IF;
--
      -- �t�@�C���A�b�v���[�hI/F�폜
      DELETE FROM
        xxccp_mrp_file_ul_interface  --�t�@�C���A�b�v���[�hI/F
      WHERE
        file_id = in_file_id
      ;
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      COMMIT;
    END IF;
--
    -- ���ʂ̃��O���b�Z�[�W�̏o��
    -- ===============================================
    -- �G���[���̏o�͌����ݒ�
    -- ===============================================
    IF (( lv_retcode <> cv_status_normal ) OR ( gn_error_cnt <> 0 )) THEN
      -- ���������Ƀ[�������Z�b�g����
      gn_normal_cnt := 0;
--
      --�����I�������ꍇ(�G���[�ɂȂ����������G���[�J�E���g�ɃC���N�������g����Ă��Ȃ�)
      IF ( gn_error_cnt = 0 ) THEN
        IF ( gn_target_cnt = 0 ) THEN  --�Ώی��������擾�̏ꍇ
          NULL;
        ELSE
          gn_error_cnt := 1;
          gn_warn_cnt  := ( gn_target_cnt - gn_error_cnt );
        END IF;
      ELSE
        --�X�L�b�v�������Z�b�g����
        gn_warn_cnt   := ( gn_target_cnt - gn_error_cnt );
      END IF;
    END IF;
--
    -- ===============================================================
    -- ���ʂ̃��O���b�Z�[�W�̏o��
    -- ===============================================================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_name_90000
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_name_90001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_name_90002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_name_90003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --���ʂ̃��O���b�Z�[�W�̏o�͏I��
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�I�����b�Z�[�W�̐ݒ�A�o��
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
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
END XXCFF017A04C;
/
