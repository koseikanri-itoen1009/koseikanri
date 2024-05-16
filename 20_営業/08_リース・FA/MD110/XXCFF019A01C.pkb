CREATE OR REPLACE PACKAGE BODY APPS.XXCFF019A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A01C(body)
 * Description      : �Œ莑�Y�f�[�^�A�b�v���[�h
 * MD.050           : MD050_CFF_019_A01_�Œ莑�Y�f�[�^�A�b�v���[�h
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         ��������(A-1)
 *  get_for_validation           �Ó����`�F�b�N�p�̒l�擾(A-2)
 *  get_upload_data              �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-3)
 *  divide_item                  �f���~�^�������ڕ���(A-4)
 *  check_item_value             ���ڒl�`�F�b�N(A-5)
 *  ins_upload_wk                �Œ莑�Y�A�b�v���[�h���[�N�쐬(A-6)
 *  get_upload_wk                �Œ莑�Y�A�b�v���[�h���[�N�擾(A-7)
 *  data_validation              �f�[�^�Ó����`�F�b�N(A-8)
 *  insert_add_oif               �ǉ�OIF�o�^(A-9)
 *  insert_adj_oif               �C��OIF�o�^(A-10)
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                               �Ώۃf�[�^�폜(A-11)
 *                               �I������(A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/10/31    1.0   S.Niki           E_�{�ғ�_14502�Ή��i�V�K�쐬�j
 *  2024/02/09    1.1   Y.Sato           E_�{�ғ�_19496 �O���[�v��Г����Ή�
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
  -- ��v���ԃ`�F�b�N�G���[
  chk_period_expt       EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF019A01C';          -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff      CONSTANT VARCHAR2(5)   := 'XXCFF';                 -- �A�h�I���F��v�E���[�X�EFA�̈�
  cv_msg_kbn_ccp      CONSTANT VARCHAR2(5)   := 'XXCCP';                 -- �A�h�I���F���ʁEIF�̈�
--
  -- �v���t�@�C��
  cv_prf_cmp_cd_itoen CONSTANT VARCHAR2(30)  := 'XXCFF1_COMPANY_CD_ITOEN';       -- ��ЃR�[�h_�{��
  cv_prf_fixd_ast_reg CONSTANT VARCHAR2(30)  := 'XXCFF1_FIXED_ASSET_REGISTER';   -- �䒠���_�Œ莑�Y�䒠
-- Ver1.1 Del Start
--  cv_prf_own_itoen    CONSTANT VARCHAR2(30)  := 'XXCFF1_OWN_COMP_ITOEN';         -- �{�ЍH��敪_�{��
--  cv_prf_own_sagara   CONSTANT VARCHAR2(30)  := 'XXCFF1_OWN_COMP_SAGARA';        -- �{�ЍH��敪_�H��
-- Ver1.1 Del End
  cv_prf_feed_sys_nm  CONSTANT VARCHAR2(30)  := 'XXCFF1_FEEDER_SYSTEM_NAME_FA';  -- �����V�X�e����_FA�A�b�v���[�h
  cv_prf_cat_dep_ifrs CONSTANT VARCHAR2(30)  := 'XXCFF1_CAT_DEPRN_IFRS';         -- IFRS���p���@
--
  -- ���b�Z�[�W��
  cv_msg_name_00234   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00234';      -- �A�b�v���[�hCSV�t�@�C�����擾�G���[
  cv_msg_name_00167   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00167';      -- �A�b�v���[�h�t�@�C�����
  cv_msg_name_00020   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00020';      -- �v���t�@�C���擾�G���[
  cv_msg_name_00236   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00236';      -- �ŐV��v���Ԗ��擾�x��
  cv_msg_name_00037   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00037';      -- ��v���ԃ`�F�b�N�G���[
  cv_msg_name_00062   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00062';      -- �Ώۃf�[�^����
  cv_msg_name_00252   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00252';      -- �����敪�G���[
  cv_msg_name_00253   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00253';      -- ���͍��ڑÓ����`�F�b�N�G���[
  cv_msg_name_00279   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00279';      -- ���Y�ԍ��d���G���[
  cv_msg_name_00254   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00254';      -- ���Y�ԍ��o�^�ς݃G���[
  cv_msg_name_00255   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00255';      -- ���ږ��ݒ�`�F�b�N�G���[
  cv_msg_name_00256   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00256';      -- ���݃`�F�b�N�G���[
  cv_msg_name_00257   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00257';      -- �ϗp�N���G���[
  cv_msg_name_00258   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00258';      -- ���ʊ֐��G���[
  cv_msg_name_00259   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00259';      -- ���Y�J�e�S�����o�^�G���[
  cv_msg_name_00260   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00260';      -- ���Y�L�[CCID�擾�G���[
  cv_msg_name_00261   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00261';      -- �C���N�����`�F�b�N�G���[
  cv_msg_name_00270   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00270';      -- ���Ƌ��p���`�F�b�N�G���[
  cv_msg_name_00271   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00271';      -- ���E�l�G���[
  cv_msg_name_00264   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00264';      -- ���Y�ԍ��̔ԃG���[
  cv_msg_name_00265   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00265';      -- �O��f�[�^���݃`�F�b�N�G���[
  cv_msg_name_00102   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00102';      -- �o�^�G���[
  cv_msg_name_00104   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00104';      -- �폜�G���[
  cv_msg_name_00266   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00266';      -- �ǉ�OIF�o�^���b�Z�[�W
  cv_msg_name_00267   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00267';      -- �C��OIF�o�^���b�Z�[�W
--Ver1.1 Add Start
  cv_msg_name_00189   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00189';      -- �Q�ƃ^�C�v�擾�G���[
--Ver1.1 Add End
--
  -- ���b�Z�[�W��(�g�[�N��)
  cv_tkn_val_50295    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50295';      -- �Œ莑�Y�f�[�^
  cv_tkn_val_50130    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50130';      -- ��������
  cv_tkn_val_50131    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50131';      -- BLOB�f�[�^�ϊ��p�֐�
  cv_tkn_val_50165    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50165';      -- �f���~�^���������֐�
  cv_tkn_val_50166    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50166';      -- ���ڃ`�F�b�N
  cv_tkn_val_50175    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50175';      -- �t�@�C���A�b�v���[�hI/F�e�[�u��
  cv_tkn_val_50076    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50076';      -- XXCFF:��ЃR�[�h_�{��
  cv_tkn_val_50228    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50228';      -- XXCFF:�䒠���_�Œ莑�Y�䒠
-- Ver1.1 Del Start
--  cv_tkn_val_50095    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50095';      -- XXCFF:�{�ЍH��敪_�{��
--  cv_tkn_val_50096    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50096';      -- XXCFF:�{�ЍH��敪_�H��
-- Ver1.1 Del End
  cv_tkn_val_50305    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50305';      -- XXCFF:�����V�X�e����_FA�A�b�v���[�h
  cv_tkn_val_50318    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50318';      -- XXCFF:IFRS���p���@
  cv_tkn_val_50296    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50296';      -- �Œ莑�Y�A�b�v���[�h���[�N
  cv_tkn_val_50241    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50241';      -- ���Y�ԍ�
  cv_tkn_val_50242    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50242';      -- �E�v
  cv_tkn_val_50297    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50297';      -- �o�^
  cv_tkn_val_50298    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50298';      -- �C��
  cv_tkn_val_50072    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50072';      -- ���Y���
  cv_tkn_val_50299    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50299';      -- ���p�\��
  cv_tkn_val_50270    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50270';      -- ���Y����
  cv_tkn_val_50300    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50300';      -- ���p�Ȗ�
  cv_tkn_val_50302    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50302';      -- ���p�⏕�Ȗ�
  cv_tkn_val_50307    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50307';      -- �ϗp�N��
  cv_tkn_val_50097    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50097';      -- ���p���@
  cv_tkn_val_50017    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50017';      -- ���[�X���
  cv_tkn_val_50262    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50262';      -- ���Ƌ��p��
  cv_tkn_val_50308    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50308';      -- �擾���z
  cv_tkn_val_50309    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50309';      -- �P�ʐ���
  cv_tkn_val_50274    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50274';      -- ��ЃR�[�h
  cv_tkn_val_50301    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50301';      -- ����R�[�h
  cv_tkn_val_50246    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50246';      -- �\���n
  cv_tkn_val_50265    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50265';      -- ���Ə�
  cv_tkn_val_50266    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50266';      -- �ݒu�ꏊ
  cv_tkn_val_50310    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50310';      -- �擾��
  cv_tkn_val_50311    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50311';      -- �\��1
  cv_tkn_val_50312    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50312';      -- �\��2
  cv_tkn_val_50313    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50313';      -- �C���N����
  cv_tkn_val_50317    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50317';      -- IFRS���p
  cv_tkn_val_50306    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50306';      -- IFRS���Y�Ȗ�
  cv_tkn_val_50303    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50303';      -- ���Y�J�e�S���`�F�b�N
  cv_tkn_val_50304    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50304';      -- CCID�擾�֐�
  cv_tkn_val_50141    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50141';      -- ���Ə��}�X�^�`�F�b�N
  cv_tkn_val_50319    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50319';      -- �ǉ�OIF
  cv_tkn_val_50320    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50320';      -- �C��OIF
  cv_tkn_val_50321    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50321';      -- IFRS�擾���z���v�l
-- Ver1.1 Add Start
  cv_tkn_val_50331    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50331';      -- �{��/�H��敪�R�[�h  
-- Ver1.1 Add End
--
  -- �g�[�N����
  cv_tkn_file_name    CONSTANT VARCHAR2(100) := 'FILE_NAME';             -- �t�@�C����
  cv_tkn_csv_name     CONSTANT VARCHAR2(100) := 'CSV_NAME';              -- CSV�t�@�C����
  cv_tkn_prof_name    CONSTANT VARCHAR2(100) := 'PROF_NAME';             -- �v���t�@�C����
  cv_tkn_param_name   CONSTANT VARCHAR2(100) := 'PARAM_NAME';            -- �p�����[�^��
  cv_tkn_book_type    CONSTANT VARCHAR2(100) := 'BOOK_TYPE_CODE';        -- �䒠��
  cv_tkn_period_name  CONSTANT VARCHAR2(100) := 'PERIOD_NAME';           -- ��v���Ԗ�
  cv_tkn_open_date    CONSTANT VARCHAR2(100) := 'PERIOD_OPEN_DATE';      -- ��v���ԃI�[�v����
  cv_tkn_close_date   CONSTANT VARCHAR2(100) := 'PERIOD_CLOSE_DATE';     -- ��v���ԃN���[�Y��
  cv_tkn_min_value    CONSTANT VARCHAR2(100) := 'MIN_VALUE';             -- ���E�l
  cv_tkn_func_name    CONSTANT VARCHAR2(100) := 'FUNC_NAME';             -- ���ʊ֐���
  cv_tkn_proc_type    CONSTANT VARCHAR2(100) := 'PROC_TYPE';             -- �����敪
  cv_tkn_input        CONSTANT VARCHAR2(100) := 'INPUT';                 -- ���ږ�
  cv_tkn_column_data  CONSTANT VARCHAR2(100) := 'COLUMN_DATA';           -- ���ڒl
  cv_tkn_line_no      CONSTANT VARCHAR2(100) := 'LINE_NO';               -- �s�ԍ�
  cv_tkn_err_msg      CONSTANT VARCHAR2(100) := 'ERR_MSG';               -- �G���[���b�Z�[�W
  cv_tkn_table_name   CONSTANT VARCHAR2(100) := 'TABLE_NAME';            -- �e�[�u����
  cv_tkn_info         CONSTANT VARCHAR2(100) := 'INFO';                  -- �ڍ׏��
--Ver1.1 Add Start
  cv_tkn_lookup_type  CONSTANT VARCHAR2(100) := 'LOOKUP_TYPE';           -- �Q�ƃ^�C�v��
--Ver1.1 Add End
--
  -- �l�Z�b�g��
  cv_ffv_dclr_dprn    CONSTANT VARCHAR2(100) := 'XXCFF_DCLR_DPRN';       -- ���p�\��
  cv_ffv_asset_acct   CONSTANT VARCHAR2(100) := 'XXCFF_ASSET_ACCOUNT';   -- ���Y����
  cv_ffv_deprn_acct   CONSTANT VARCHAR2(100) := 'XXCFF_DEPRN_ACCOUNT';   -- ���p�Ȗ�
  cv_ffv_dprn_method  CONSTANT VARCHAR2(100) := 'XXCFF_DPRN_METHOD';     -- ���p���@
  cv_ffv_dclr_place   CONSTANT VARCHAR2(100) := 'XXCFF_DCLR_PLACE';      -- �\���n
  cv_ffv_mng_place    CONSTANT VARCHAR2(100) := 'XXCFF_MNG_PLACE';       -- ���Ə�
--
--Ver1.1 Add Start 
  -- �Q�ƃ^�C�v�E�R�[�h
  cv_flvv_own_comp_cd CONSTANT VARCHAR2(100) := 'XXCFF1_OWNER_COMPANY_CODE'; -- �{��/�H��敪�R�[�h
--Ver1.1 Add End
  -- �o�̓^�C�v
  cv_file_type_out    CONSTANT VARCHAR2(10)  := 'OUTPUT';                -- �o��
  cv_file_type_log    CONSTANT VARCHAR2(10)  := 'LOG';                   -- ���O
--
  -- �f���~�^����
  cv_csv_delimiter    CONSTANT VARCHAR2(1)   := ',';                     -- �J���}
--
  -- �����敪
  cv_process_type_1   CONSTANT VARCHAR2(1)   := '1';                     -- 1�i�o�^�j
  cv_process_type_2   CONSTANT VARCHAR2(1)   := '2';                     -- 2�i�C���j
--
  cv_yes              CONSTANT VARCHAR2(1)   := 'Y';                     -- YES
  cv_no               CONSTANT VARCHAR2(1)   := 'N';                     -- NO
  cv_date_fmt_std     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';            -- ���t����
  cv_lang_ja          CONSTANT VARCHAR2(2)   := 'JA';                    -- ���{��
--
  -- �Z�O�����g�l
  cv_segment5_dummy   CONSTANT VARCHAR2(30)  := '000000000';             -- �ڋq�R�[�h
  cv_segment6_dummy   CONSTANT VARCHAR2(30)  := '000000';                -- ��ƃR�[�h
  cv_segment7_dummy   CONSTANT VARCHAR2(30)  := '0';                     -- �\���P
  cv_segment8_dummy   CONSTANT VARCHAR2(30)  := '0';                     -- �\���Q
--
  -- �Œ萔�l
  cn_0                CONSTANT NUMBER        := 0;                       -- ���l0
  cn_1                CONSTANT NUMBER        := 1;                       -- ���l1
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �������ڕ�����f�[�^�i�[�z��
  TYPE g_load_data_ttype           IS TABLE OF VARCHAR2(600) INDEX BY PLS_INTEGER;
--
  -- �Ó����`�F�b�N�p�̒l�擾�p��`
  TYPE g_column_desc_ttype         IS TABLE OF xxcff_fa_upload_v.column_desc%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_ttype          IS TABLE OF xxcff_fa_upload_v.byte_count%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_decimal_ttype  IS TABLE OF xxcff_fa_upload_v.byte_count_decimal%TYPE INDEX BY PLS_INTEGER;
  TYPE g_pay_match_flag_name_ttype IS TABLE OF xxcff_fa_upload_v.payment_match_flag_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_item_attribute_ttype      IS TABLE OF xxcff_fa_upload_v.item_attribute%TYPE INDEX BY PLS_INTEGER;
--
    -- �Œ莑�Y�A�b�v���[�h���[�N�擾�f�[�^���R�[�h�^
  TYPE g_upload_rtype IS RECORD(
     line_no                       xxcff_fa_upload_work.line_no%TYPE                     -- �s�ԍ�
    ,process_type                  xxcff_fa_upload_work.process_type%TYPE                -- �����敪
    ,asset_number                  xxcff_fa_upload_work.asset_number%TYPE                -- ���Y�ԍ�
    ,description                   xxcff_fa_upload_work.description%TYPE                 -- �E�v
    ,asset_category                xxcff_fa_upload_work.asset_category%TYPE              -- ���
    ,deprn_declaration             xxcff_fa_upload_work.deprn_declaration%TYPE           -- ���p�\��
    ,asset_account                 xxcff_fa_upload_work.asset_account%TYPE               -- ���Y����
    ,deprn_account                 xxcff_fa_upload_work.deprn_account%TYPE               -- ���p�Ȗ�
    ,deprn_sub_account             xxcff_fa_upload_work.deprn_sub_account%TYPE           -- ���p�⏕�Ȗ�
    ,life_in_months                xxcff_fa_upload_work.life_in_months%TYPE              -- �ϗp�N��
    ,cat_deprn_method              xxcff_fa_upload_work.cat_deprn_method%TYPE            -- ���p���@
    ,lease_class                   xxcff_fa_upload_work.lease_class%TYPE                 -- ���[�X���
    ,date_placed_in_service        xxcff_fa_upload_work.date_placed_in_service%TYPE      -- ���Ƌ��p��
    ,original_cost                 xxcff_fa_upload_work.original_cost%TYPE               -- �擾���z
    ,quantity                      xxcff_fa_upload_work.quantity%TYPE                    -- �P�ʐ���
    ,company_code                  xxcff_fa_upload_work.company_code%TYPE                -- ���
    ,department_code               xxcff_fa_upload_work.department_code%TYPE             -- ����
    ,dclr_place                    xxcff_fa_upload_work.dclr_place%TYPE                  -- �\���n
    ,location_name                 xxcff_fa_upload_work.location_name%TYPE               -- ���Ə�
    ,location_place                xxcff_fa_upload_work.location_place%TYPE              -- �ꏊ
    ,yobi1                         xxcff_fa_upload_work.yobi1%TYPE                       -- �\��1
    ,yobi2                         xxcff_fa_upload_work.yobi2%TYPE                       -- �\��2
    ,assets_date                   xxcff_fa_upload_work.assets_date%TYPE                 -- �擾��
    ,ifrs_life_in_months           xxcff_fa_upload_work.ifrs_life_in_months%TYPE         -- IFRS�ϗp�N��
    ,ifrs_cat_deprn_method         xxcff_fa_upload_work.ifrs_cat_deprn_method%TYPE       -- IFRS���p
    ,real_estate_acq_tax           xxcff_fa_upload_work.real_estate_acq_tax%TYPE         -- �s���Y�擾��
    ,borrowing_cost                xxcff_fa_upload_work.borrowing_cost%TYPE              -- �ؓ��R�X�g
    ,other_cost                    xxcff_fa_upload_work.other_cost%TYPE                  -- ���̑�
    ,ifrs_asset_account            xxcff_fa_upload_work.ifrs_asset_account%TYPE          -- IFRS���Y�Ȗ�
    ,correct_date                  xxcff_fa_upload_work.correct_date%TYPE                -- �C���N����
  );
--
    -- �Œ莑�Y�f�[�^���R�[�h�^
  TYPE g_fa_rtype IS RECORD(
     asset_number_old              xx01_adjustment_oif.asset_number_old%TYPE              -- ���Y�ԍ�
    ,dpis_old                      xx01_adjustment_oif.dpis_old%TYPE                      -- ���Ƌ��p���i�C���O�j
    ,category_id_old               xx01_adjustment_oif.category_id_old%TYPE               -- ���Y�J�e�S��ID�i�C���O�j
    ,cat_attribute_category_old    xx01_adjustment_oif.cat_attribute_category_old%TYPE    -- ���Y�J�e�S���R�[�h�i�C���O�j
    ,description                   xx01_adjustment_oif.description%TYPE                   -- �E�v
    ,transaction_units             xx01_adjustment_oif.transaction_units%TYPE             -- �P��
    ,cost                          xx01_adjustment_oif.cost%TYPE                          -- �擾���z
    ,original_cost                 xx01_adjustment_oif.original_cost%TYPE                 -- �����擾���z
    ,asset_number_new              xx01_adjustment_oif.asset_number_new%TYPE              -- ���Y�ԍ��i�C����j
    ,tag_number                    xx01_adjustment_oif.tag_number%TYPE                    -- ���i�[�ԍ�
    ,category_id_new               xx01_adjustment_oif.category_id_new%TYPE               -- ���Y�J�e�S��ID�i�C����j
    ,serial_number                 xx01_adjustment_oif.serial_number%TYPE                 -- �V���A���ԍ�
    ,asset_key_ccid                xx01_adjustment_oif.asset_key_ccid%TYPE                -- ���Y�L�[CCID
    ,key_segment1                  xx01_adjustment_oif.key_segment1%TYPE                  -- ���Y�L�[�Z�O�����g1
    ,key_segment2                  xx01_adjustment_oif.key_segment2%TYPE                  -- ���Y�L�[�Z�O�����g2
    ,parent_asset_id               xx01_adjustment_oif.parent_asset_id%TYPE               -- �e���YID
    ,lease_id                      xx01_adjustment_oif.lease_id%TYPE                      -- ���[�XID
    ,model_number                  xx01_adjustment_oif.model_number%TYPE                  -- ���f��
    ,in_use_flag                   xx01_adjustment_oif.in_use_flag%TYPE                   -- �g�p��
    ,inventorial                   xx01_adjustment_oif.inventorial%TYPE                   -- ���n�I���t���O
    ,owned_leased                  xx01_adjustment_oif.owned_leased%TYPE                  -- ���L��
    ,new_used                      xx01_adjustment_oif.new_used%TYPE                      -- �V�i/����
    ,cat_attribute1                xx01_adjustment_oif.cat_attribute1%TYPE                -- �J�e�S��DFF1
    ,cat_attribute2                xx01_adjustment_oif.cat_attribute2%TYPE                -- �J�e�S��DFF2
    ,cat_attribute3                xx01_adjustment_oif.cat_attribute3%TYPE                -- �J�e�S��DFF3
    ,cat_attribute4                xx01_adjustment_oif.cat_attribute4%TYPE                -- �J�e�S��DFF4
    ,cat_attribute5                xx01_adjustment_oif.cat_attribute5%TYPE                -- �J�e�S��DFF5
    ,cat_attribute6                xx01_adjustment_oif.cat_attribute6%TYPE                -- �J�e�S��DFF6
    ,cat_attribute7                xx01_adjustment_oif.cat_attribute7%TYPE                -- �J�e�S��DFF7
    ,cat_attribute8                xx01_adjustment_oif.cat_attribute8%TYPE                -- �J�e�S��DFF8
    ,cat_attribute9                xx01_adjustment_oif.cat_attribute9%TYPE                -- �J�e�S��DFF9
    ,cat_attribute10               xx01_adjustment_oif.cat_attribute10%TYPE               -- �J�e�S��DFF10
    ,cat_attribute11               xx01_adjustment_oif.cat_attribute11%TYPE               -- �J�e�S��DFF11
    ,cat_attribute12               xx01_adjustment_oif.cat_attribute12%TYPE               -- �J�e�S��DFF12
    ,cat_attribute13               xx01_adjustment_oif.cat_attribute13%TYPE               -- �J�e�S��DFF13
    ,cat_attribute14               xx01_adjustment_oif.cat_attribute14%TYPE               -- �J�e�S��DFF14
    ,cat_attribute15               xx01_adjustment_oif.cat_attribute15%TYPE               -- �J�e�S��DFF15(IFRS�ϗp�N��)
    ,cat_attribute16               xx01_adjustment_oif.cat_attribute16%TYPE               -- �J�e�S��DFF16(IFRS���p)
    ,cat_attribute17               xx01_adjustment_oif.cat_attribute17%TYPE               -- �J�e�S��DFF17(�s���Y�擾��)
    ,cat_attribute18               xx01_adjustment_oif.cat_attribute18%TYPE               -- �J�e�S��DFF18(�ؓ��R�X�g)
    ,cat_attribute19               xx01_adjustment_oif.cat_attribute19%TYPE               -- �J�e�S��DFF19(���̑�)
    ,cat_attribute20               xx01_adjustment_oif.cat_attribute20%TYPE               -- �J�e�S��DFF20(IFRS���Y�Ȗ�)
    ,cat_attribute21               xx01_adjustment_oif.cat_attribute21%TYPE               -- �J�e�S��DFF21(�C���N����)
    ,cat_attribute22               xx01_adjustment_oif.cat_attribute22%TYPE               -- �J�e�S��DFF22
    ,cat_attribute23               xx01_adjustment_oif.cat_attribute23%TYPE               -- �J�e�S��DFF23
    ,cat_attribute24               xx01_adjustment_oif.cat_attribute24%TYPE               -- �J�e�S��DFF24
    ,cat_attribute25               xx01_adjustment_oif.cat_attribute25%TYPE               -- �J�e�S��DFF27
    ,cat_attribute26               xx01_adjustment_oif.cat_attribute26%TYPE               -- �J�e�S��DFF25
    ,cat_attribute27               xx01_adjustment_oif.cat_attribute27%TYPE               -- �J�e�S��DFF26
    ,cat_attribute28               xx01_adjustment_oif.cat_attribute28%TYPE               -- �J�e�S��DFF28
    ,cat_attribute29               xx01_adjustment_oif.cat_attribute29%TYPE               -- �J�e�S��DFF29
    ,cat_attribute30               xx01_adjustment_oif.cat_attribute30%TYPE               -- �J�e�S��DFF30
    ,cat_attribute_category_new    xx01_adjustment_oif.cat_attribute_category_new%TYPE    -- ���Y�J�e�S���R�[�h�i�C����j
    ,salvage_value                 xx01_adjustment_oif.salvage_value%TYPE                 -- �c�����z
    ,percent_salvage_value         xx01_adjustment_oif.percent_salvage_value%TYPE         -- �c�����z%
    ,allowed_deprn_limit_amount    xx01_adjustment_oif.allowed_deprn_limit_amount%TYPE    -- ���p���x�z
    ,allowed_deprn_limit           xx01_adjustment_oif.allowed_deprn_limit%TYPE           -- ���p���x��
    ,ytd_deprn                     xx01_adjustment_oif.ytd_deprn%TYPE                     -- �N���p�݌v�z
    ,deprn_reserve                 xx01_adjustment_oif.deprn_reserve%TYPE                 -- ���p�݌v�z
    ,depreciate_flag               xx01_adjustment_oif.depreciate_flag%TYPE               -- ���p��v��t���O
    ,deprn_method_code             xx01_adjustment_oif.deprn_method_code%TYPE             -- ���p���@
    ,basic_rate                    xx01_adjustment_oif.basic_rate%TYPE                    -- ���ʏ��p��
    ,adjusted_rate                 xx01_adjustment_oif.adjusted_rate%TYPE                 -- �����㏞�p��
    ,life_in_months                NUMBER                                                 -- �ϗp�N���{����
    ,bonus_rule                    xx01_adjustment_oif.bonus_rule%TYPE                    -- �{�[�i�X���[��
    ,bonus_ytd_deprn               xx01_adjustment_oif.bonus_ytd_deprn%TYPE               -- �{�[�i�X�N���p�݌v�z
    ,bonus_deprn_reserve           xx01_adjustment_oif.bonus_deprn_reserve%TYPE           -- �{�[�i�X���p�݌v�z
  );
--
  -- �Œ莑�Y�f�[�^�捞�Ώۃf�[�^���R�[�h�z��
  TYPE g_upload_ttype          IS TABLE OF g_upload_rtype
    INDEX BY BINARY_INTEGER;
  -- �Œ莑�Y�f�[�^���R�[�h�z��
  TYPE g_fa_ttype              IS TABLE OF g_fa_rtype
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- �p�����[�^
  gn_file_id                   NUMBER;                                           -- �t�@�C��ID
  gd_process_date              DATE;                                             -- �Ɩ����t
  gn_set_of_book_id            NUMBER(15);                                       -- ��v����ID
  gt_chart_of_account_id       gl_sets_of_books.chart_of_accounts_id%TYPE;       -- �Ȗڑ̌nID
  gt_application_short_name    fnd_application.application_short_name%TYPE;      -- GL�A�v���P�[�V�����Z�k��
  gt_id_flex_code              fnd_id_flex_structures_vl.id_flex_code%TYPE;      -- �L�[�t���b�N�X�R�[�h
--
  -- �v���t�@�C���l
  gv_company_cd_itoen          VARCHAR2(100);                                    -- ��ЃR�[�h_�{��
  gv_fixed_asset_register      VARCHAR2(100);                                    -- �䒠���_�Œ莑�Y�䒠
-- Ver1.1 Del Start
--  gv_own_comp_itoen            VARCHAR2(100);                                    -- �{�ЍH��敪_�{��
--  gv_own_comp_sagara           VARCHAR2(100);                                    -- �{�ЍH��敪_�H��
-- Ver1.1 Del End
  gv_feed_sys_nm               VARCHAR2(100);                                    -- �����V�X�e����_FA�A�b�v���[�h
  gv_cat_dep_ifrs              VARCHAR2(100);                                    -- IFRS���p���@
--
  gt_period_name               fa_deprn_periods.period_name%TYPE;                -- �ŐV��v���Ԗ�
  gt_period_open_date          fa_deprn_periods.calendar_period_open_date%TYPE;  -- �ŐV��v���ԊJ�n��
  gt_period_close_date         fa_deprn_periods.calendar_period_close_date%TYPE; -- �ŐV��v���ԏI����
--
  -- ��������
  -- �ǉ�OIF�o�^�ɂ����錏��
  gn_add_target_cnt            NUMBER;        -- �Ώی���
  gn_add_normal_cnt            NUMBER;        -- ���팏��
  gn_add_error_cnt             NUMBER;        -- �G���[����
  -- �C��OIF�o�^�ɂ����錏��
  gn_adj_target_cnt            NUMBER;        -- �Ώی���
  gn_adj_normal_cnt            NUMBER;        -- ���팏��
  gn_adj_error_cnt             NUMBER;        -- �G���[����
--
  -- �����l���
  g_init_rec                   xxcff_common1_pkg.init_rtype;
--
  --�t�@�C���A�b�v���[�hIF�f�[�^
  g_if_data_tab                xxccp_common_pkg2.g_file_data_tbl;
--
  --�������ڕ�����f�[�^�i�[�z��
  g_load_data_tab              g_load_data_ttype;
--
  -- ���ڒl�`�F�b�N�p�̒l�擾�p��`
  g_column_desc_tab            g_column_desc_ttype;
  g_byte_count_tab             g_byte_count_ttype;
  g_byte_count_decimal_tab     g_byte_count_decimal_ttype;
  g_pay_match_flag_name_tab    g_pay_match_flag_name_ttype;
  g_item_attribute_tab         g_item_attribute_ttype;
--
  -- �Z�O�����g�l�z��(EBS�W���֐�fnd_flex_ext�p)
  g_segments_tab               fnd_flex_ext.segmentarray;
--
  -- �Œ莑�Y�A�b�v���[�h���[�N�擾�Ώۃf�[�^
  g_upload_tab                 g_upload_ttype;
  -- �Œ莑�Y�f�[�^
  g_fa_tab                     g_fa_ttype;
--
  -- �G���[�t���O
  gb_err_flag                  BOOLEAN;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER       --   1.�t�@�C��ID
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lt_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE;        -- CSV�t�@�C����
    lt_deprn_run         fa_deprn_periods.deprn_run%TYPE;                   -- �������p���s�t���O
    lv_param             VARCHAR2(1000);                                    -- �p�����[�^�o�͗p
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
    -- ===============================
    -- CSV�t�@�C�����擾
    -- ===============================
    BEGIN
      SELECT xfu.file_name AS file_name
      INTO   lt_file_name
      FROM   xxccp_mrp_file_ul_interface  xfu  -- �t�@�C���A�b�v���[�hI/F�e�[�u��
      WHERE  xfu.file_id   = in_file_id
      ;
    EXCEPTION
      -- �A�b�v���[�hCSV�t�@�C�������擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cff       -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_name_00234    -- ���b�Z�[�W
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �p�����[�^�o��
    -- ===============================
    lv_param := xxccp_common_pkg.get_msg(
                   iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_msg_name_00167      -- ���b�Z�[�W
                  ,iv_token_name1  => cv_tkn_file_name       -- �g�[�N���R�[�h1
                  ,iv_token_value1 => cv_tkn_val_50295       -- �g�[�N���l1
                  ,iv_token_name2  => cv_tkn_csv_name        -- �g�[�N���R�[�h2
                  ,iv_token_value2 => lt_file_name           -- �g�[�N���l2
                );
--
    -- �A�b�v���[�h�t�@�C�����́ACSV�t�@�C�����o�́i���O�j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param
    );
    -- �A�b�v���[�h�t�@�C�����́ACSV�t�@�C�����o�́i�o�́j
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param
    );
--
    -- �R���J�����g�p�����[�^�l�o��(���O)
    xxcff_common1_pkg.put_log_param(
       iv_which     => cv_file_type_log    -- �o�͋敪
      ,ov_errbuf    => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(�o��)
    xxcff_common1_pkg.put_log_param(
       iv_which     => cv_file_type_out    -- �o�͋敪
      ,ov_errbuf    => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �����l���擾
    -- ===============================
    xxcff_common1_pkg.init(
       or_init_rec  => g_init_rec           -- �����l���
      ,ov_errbuf    => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���ʊ֐����G���[�̏ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_name_00258      -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => 0                      -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_func_name       -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_tkn_val_50130       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_info            -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_errmsg              -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���擾
    -- ===============================
    -- XXCFF:��ЃR�[�h_�{��
    gv_company_cd_itoen := FND_PROFILE.VALUE(cv_prf_cmp_cd_itoen);
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_company_cd_itoen IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_name_00020      -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_prof_name       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_val_50076       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�䒠���_�Œ莑�Y�䒠
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_prf_fixd_ast_reg);
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_fixed_asset_register IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_name_00020      -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_prof_name       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_val_50228       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- Ver1.1 Del Start
----
--    -- XXCFF:�{�ЍH��敪_�{��
--    gv_own_comp_itoen := FND_PROFILE.VALUE(cv_prf_own_itoen);
--    -- �擾�l��NULL�̏ꍇ
--    IF ( gv_own_comp_itoen IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
--                     ,iv_name         => cv_msg_name_00020      -- ���b�Z�[�W
--                     ,iv_token_name1  => cv_tkn_prof_name       -- �g�[�N���R�[�h1
--                     ,iv_token_value1 => cv_tkn_val_50095       -- �g�[�N���l1
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    -- XXCFF:�{�ЍH��敪_�H��
--    gv_own_comp_sagara := FND_PROFILE.VALUE(cv_prf_own_sagara);
--    -- �擾�l��NULL�̏ꍇ
--    IF ( gv_own_comp_sagara IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
--                     ,iv_name         => cv_msg_name_00020      -- ���b�Z�[�W
--                     ,iv_token_name1  => cv_tkn_prof_name       -- �g�[�N���R�[�h1
--                     ,iv_token_value1 => cv_tkn_val_50096       -- �g�[�N���l1
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- Ver1.1 Del End
--
    -- XXCFF:�����V�X�e����_FA�A�b�v���[�h
    gv_feed_sys_nm := FND_PROFILE.VALUE(cv_prf_feed_sys_nm);
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_feed_sys_nm IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_name_00020      -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_prof_name       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_val_50305       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:IFRS���p���@
    gv_cat_dep_ifrs := FND_PROFILE.VALUE(cv_prf_cat_dep_ifrs);
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_cat_dep_ifrs IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_name_00020      -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_prof_name       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_val_50318       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �ŐV��v���Ԏ擾
    -- ===============================
    SELECT MAX(fdp.period_name)                AS period_name
          ,MAX(fdp.calendar_period_open_date)  AS period_open_date
          ,MAX(fdp.calendar_period_close_date) AS period_close_date
    INTO   gt_period_name
          ,gt_period_open_date
          ,gt_period_close_date
    FROM   fa_deprn_periods  fdp  -- �������p����
    WHERE  fdp.book_type_code  =  gv_fixed_asset_register
    ;
    -- �ŐV��v���Ԃ��擾�ł��Ȃ��ꍇ
    IF ( gt_period_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff           -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_name_00236        -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_param_name        -- �g�[�N���R�[�h1
                    ,iv_token_value1 => gv_fixed_asset_register  -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N
    -- ===============================
    BEGIN
      SELECT fdp.deprn_run AS deprn_run
      INTO   lt_deprn_run
      FROM   fa_deprn_periods  fdp  -- �������p����
      WHERE  fdp.book_type_code    = gv_fixed_asset_register
      AND    fdp.period_name       = gt_period_name
      AND    fdp.period_close_date IS NULL
      ;
    EXCEPTION
      -- �������p���s�t���O���擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        RAISE chk_period_expt;
    END;
--
    -- �������p���s�ς݂̏ꍇ
    IF ( lt_deprn_run = cv_yes ) THEN
      RAISE chk_period_expt;
    END IF;
--
    -- �����l���O���[�o���ϐ��Ɋi�[
    gn_file_id                 := in_file_id;                            -- �t�@�C��ID
    gd_process_date            := g_init_rec.process_date;               -- �Ɩ����t
    gn_set_of_book_id          := g_init_rec.set_of_books_id;            -- ��v����ID
    gt_chart_of_account_id     := g_init_rec.chart_of_accounts_id;       -- �Ȗڑ̌nID
    gt_application_short_name  := g_init_rec.gl_application_short_name;  -- GL�A�v���P�[�V�����Z�k��
    gt_id_flex_code            := g_init_rec.id_flex_code;               -- �L�[�t���b�N�X�R�[�h
--
  EXCEPTION
--
    -- *** ��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_period_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff           -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_name_00037        -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_book_type         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => gv_fixed_asset_register  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_period_name       -- �g�[�N���R�[�h2
                     ,iv_token_value2 => gt_period_name           -- �g�[�N���l2
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_for_validation
   * Description      : �Ó����`�F�b�N�p�̒l�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_for_validation(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
      SELECT xfu.column_desc               AS column_desc               -- ���ږ���
            ,xfu.byte_count                AS byte_count                -- �o�C�g��
            ,xfu.byte_count_decimal        AS byte_count_decimal        -- �o�C�g��_�����_�ȉ�
            ,xfu.payment_match_flag_name   AS payment_match_flag_name   -- �K�{�t���O
            ,xfu.item_attribute            AS item_attribute            -- ���ڑ���
      FROM   xxcff_fa_upload_v  xfu    -- �Œ莑�Y�A�b�v���[�h�r���[
      ORDER BY
             xfu.code ASC
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
    BULK COLLECT INTO g_column_desc_tab               -- ���ږ���
                     ,g_byte_count_tab                -- �o�C�g��
                     ,g_byte_count_decimal_tab        -- �o�C�g��_�����_�ȉ�
                     ,g_pay_match_flag_name_tab       -- �K�{�t���O
                     ,g_item_attribute_tab            -- ���ڑ���
    ;
--
    --�J�[�\���̃N���[�Y
    CLOSE get_validate_cur;
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
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
      in_file_id   => gn_file_id       -- �t�@�C��ID
     ,ov_file_data => g_if_data_tab    -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���ʊ֐��G���[�̏ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_name_00258      -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => 0                      -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_func_name       -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_tkn_val_50131       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_info            -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_errmsg              -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �����Ώی������i�[(�w�b�_����������)
    gn_target_cnt := g_if_data_tab.COUNT - 1 ;
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : �f���~�^�������ڕ���(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_loop_cnt_1 IN  NUMBER       --   ���[�v�J�E���^1
   ,in_loop_cnt_2 IN  NUMBER       --   ���[�v�J�E���^2
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    -- �f���~�^���������̋��ʊ֐��̌ďo
    g_load_data_tab(in_loop_cnt_2) := xxccp_common_pkg.char_delim_partition(
                                         g_if_data_tab(in_loop_cnt_1)         -- ������������
                                        ,cv_csv_delimiter                     -- �f���~�^����
                                        ,in_loop_cnt_2                        -- �ԋp�Ώ�INDEX
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
  END divide_item;
--
  /**********************************************************************************
   * Procedure Name   : check_item_value
   * Description      : ���ڒl�`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE check_item_value(
    in_lino_no    IN  NUMBER       -- �s�ԍ��J�E���^
   ,in_loop_cnt_2 IN  NUMBER       -- ���[�v�J�E���^2
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
       iv_item_name    => g_column_desc_tab(in_loop_cnt_2)            -- ���ږ���
      ,iv_item_value   => g_load_data_tab(in_loop_cnt_2)              -- ���ڂ̒l
      ,in_item_len     => g_byte_count_tab(in_loop_cnt_2)             -- �o�C�g��/���ڂ̒���
      ,in_item_decimal => g_byte_count_decimal_tab(in_loop_cnt_2)     -- �o�C�g��_�����_�ȉ�/���ڂ̒����i�����_�ȉ��j
      ,iv_item_nullflg => g_pay_match_flag_name_tab(in_loop_cnt_2)    -- �K�{�t���O
      ,iv_item_attr    => g_item_attribute_tab(in_loop_cnt_2)         -- ���ڑ���
      ,ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���^�[���R�[�h���x���̏ꍇ�i�Ώۃf�[�^�ɕs�����������ꍇ�j
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_name_00258            -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_line_no               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => TO_CHAR(in_lino_no)          -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_func_name             -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_tkn_val_50166             -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_info                  -- �g�[�N���R�[�h3
                     ,iv_token_value3 => LTRIM(lv_errmsg)             -- �g�[�N���l3
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
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
  END check_item_value;
--
  /**********************************************************************************
   * Procedure Name   : ins_upload_wk
   * Description      : �Œ莑�Y�A�b�v���[�h���[�N�쐬(A-6)
   ***********************************************************************************/
  PROCEDURE ins_upload_wk(
    in_line_no    IN  NUMBER       -- �s�ԍ�
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    BEGIN
      -- �Œ莑�Y�A�b�v���[�h���[�N�쐬
      INSERT INTO xxcff_fa_upload_work(
        file_id                        -- �t�@�C��ID
       ,line_no                        -- �s�ԍ�
       ,process_type                   -- �����敪
       ,asset_number                   -- ���Y�ԍ�
       ,description                    -- �E�v
       ,asset_category                 -- ���
       ,deprn_declaration              -- ���p�\��
       ,asset_account                  -- ���Y����
       ,deprn_account                  -- ���p�Ȗ�
       ,deprn_sub_account              -- ���p�⏕�Ȗ�
       ,life_in_months                 -- �ϗp�N��
       ,cat_deprn_method               -- ���p���@
       ,lease_class                    -- ���[�X���
       ,date_placed_in_service         -- ���Ƌ��p��
       ,original_cost                  -- �擾���z
       ,quantity                       -- �P�ʐ���
       ,company_code                   -- ���
       ,department_code                -- ����
       ,dclr_place                     -- �\���n
       ,location_name                  -- ���Ə�
       ,location_place                 -- �ꏊ
       ,yobi1                          -- �\��1
       ,yobi2                          -- �\��2
       ,assets_date                    -- �擾��
       ,ifrs_life_in_months            -- IFRS�ϗp�N��
       ,ifrs_cat_deprn_method          -- IFRS���p
       ,real_estate_acq_tax            -- �s���Y�擾��
       ,borrowing_cost                 -- �ؓ��R�X�g
       ,other_cost                     -- ���̑�
       ,ifrs_asset_account             -- IFRS���Y�Ȗ�
       ,correct_date                   -- �C���N����
       ,created_by                     -- �쐬��
       ,creation_date                  -- �쐬��
       ,last_updated_by                -- �ŏI�X�V��
       ,last_update_date               -- �ŏI�X�V��
       ,last_update_login              -- �ŏI�X�V���O�C��
       ,request_id                     -- �v��ID
       ,program_application_id         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                     -- �R���J�����g�E�v���O����ID
       ,program_update_date            -- �v���O�����X�V��
      )
      VALUES (
        gn_file_id                                      -- �t�@�C��ID
       ,in_line_no                                      -- �s�ԍ�
       ,g_load_data_tab(1)                              -- �����敪
       ,g_load_data_tab(2)                              -- ���Y�ԍ�
       ,g_load_data_tab(3)                              -- �E�v
       ,g_load_data_tab(4)                              -- ���
       ,g_load_data_tab(5)                              -- ���p�\��
       ,g_load_data_tab(6)                              -- ���Y����
       ,g_load_data_tab(7)                              -- ���p�Ȗ�
       ,g_load_data_tab(8)                              -- ���p�⏕�Ȗ�
       ,g_load_data_tab(9)                              -- �ϗp�N��
       ,g_load_data_tab(10)                             -- ���p���@
       ,g_load_data_tab(11)                             -- ���[�X���
       ,TO_DATE(g_load_data_tab(12) ,cv_date_fmt_std)   -- ���Ƌ��p��
       ,g_load_data_tab(13)                             -- �擾���z
       ,g_load_data_tab(14)                             -- �P�ʐ���
       ,g_load_data_tab(15)                             -- ���
       ,g_load_data_tab(16)                             -- ����
       ,g_load_data_tab(17)                             -- �\���n
       ,g_load_data_tab(18)                             -- ���Ə�
       ,g_load_data_tab(19)                             -- �ꏊ
       ,g_load_data_tab(20)                             -- �\��1
       ,g_load_data_tab(21)                             -- �\��2
       ,TO_DATE(g_load_data_tab(22) ,cv_date_fmt_std)   -- �擾��
       ,g_load_data_tab(23)                             -- IFRS�ϗp�N��
       ,g_load_data_tab(24)                             -- IFRS���p
       ,g_load_data_tab(25)                             -- �s���Y�擾��
       ,g_load_data_tab(26)                             -- �ؓ��R�X�g
       ,g_load_data_tab(27)                             -- ���̑�
       ,g_load_data_tab(28)                             -- IFRS���Y�Ȗ�
       ,TO_DATE(g_load_data_tab(29) ,cv_date_fmt_std)   -- �C���N����
       ,cn_created_by                                   -- �쐬��
       ,cd_creation_date                                -- �쐬��
       ,cn_last_updated_by                              -- �ŏI�X�V��
       ,cd_last_update_date                             -- �ŏI�X�V��
       ,cn_last_update_login                            -- �ŏI�X�V���O�C��
       ,cn_request_id                                   -- �v��ID
       ,cn_program_application_id                       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����I
       ,cn_program_id                                   -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date                          -- �v���O�����X�V��
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- �o�^�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00102        -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_table_name        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_val_50296         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_info              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ���Y�ԍ����ݒ肳��Ă���ꍇ
    IF ( g_load_data_tab(2) IS NOT NULL ) THEN
      -- ���Y�ԍ��`�F�b�N�ꎞ�\�쐬
      INSERT INTO xxcff_tmp_check_asset_num(
        asset_number    -- ���Y�ԍ�
       ,line_no         -- �s�ԍ�
      )
      VALUES (
        g_load_data_tab(2)  -- ���Y�ԍ�
       ,in_line_no          -- �s�ԍ�
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
   * Description      : �Œ莑�Y�A�b�v���[�h���[�N�擾(A-7)
   ***********************************************************************************/
  PROCEDURE get_upload_wk(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    CURSOR get_fa_upload_wk_cur
    IS
      SELECT xfuw.line_no                     AS line_no                      -- �s�ԍ�
            ,xfuw.process_type                AS process_type                 -- �����敪
            ,xfuw.asset_number                AS asset_number                 -- ���Y�ԍ�
            ,xfuw.description                 AS description                  -- �E�v
            ,xfuw.asset_category              AS asset_category               -- ���
            ,xfuw.deprn_declaration           AS deprn_declaration            -- ���p�\��
            ,xfuw.asset_account               AS asset_account                -- ���Y����
            ,xfuw.deprn_account               AS deprn_account                -- ���p�Ȗ�
            ,xfuw.deprn_sub_account           AS deprn_sub_account            -- ���p�⏕�Ȗ�
            ,xfuw.life_in_months              AS life_in_months               -- �ϗp�N��
            ,xfuw.cat_deprn_method            AS cat_deprn_method             -- ���p���@
            ,xfuw.lease_class                 AS lease_class                  -- ���[�X���
            ,xfuw.date_placed_in_service      AS date_placed_in_service       -- ���Ƌ��p��
            ,xfuw.original_cost               AS original_cost                -- �擾���z
            ,xfuw.quantity                    AS quantity                     -- �P�ʐ���
            ,xfuw.company_code                AS company_code                 -- ���
            ,xfuw.department_code             AS department_code              -- ����
            ,xfuw.dclr_place                  AS dclr_place                   -- �\���n
            ,xfuw.location_name               AS location_name                -- ���Ə�
            ,xfuw.location_place              AS location_place               -- �ꏊ
            ,xfuw.yobi1                       AS yobi1                        -- �\��1
            ,xfuw.yobi2                       AS yobi2                        -- �\��2
            ,xfuw.assets_date                 AS assets_date                  -- �擾��
            ,xfuw.ifrs_life_in_months         AS ifrs_life_in_months          -- IFRS�ϗp�N��
            ,xfuw.ifrs_cat_deprn_method       AS ifrs_cat_deprn_method        -- IFRS���p
            ,xfuw.real_estate_acq_tax         AS real_estate_acq_tax          -- �s���Y�擾��
            ,xfuw.borrowing_cost              AS borrowing_cost               -- �ؓ��R�X�g
            ,xfuw.other_cost                  AS other_cost                   -- ���̑�
            ,xfuw.ifrs_asset_account          AS ifrs_asset_account           -- IFRS���Y�Ȗ�
            ,xfuw.correct_date                AS correct_date                 -- �C���N����
      FROM   xxcff_fa_upload_work  xfuw  -- �Œ莑�Y�A�b�v���[�h���[�N
      WHERE  xfuw.file_id   = gn_file_id
      ORDER BY
             xfuw.line_no
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
    -- �Œ莑�Y�A�b�v���[�h���[�N�擾
    OPEN  get_fa_upload_wk_cur;
    FETCH get_fa_upload_wk_cur BULK COLLECT INTO g_upload_tab;
    CLOSE get_fa_upload_wk_cur;
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
      IF ( get_fa_upload_wk_cur%ISOPEN ) THEN
        CLOSE get_fa_upload_wk_cur;
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
   * Description      : �f�[�^�Ó����`�F�b�N(A-8)
   ***********************************************************************************/
  PROCEDURE data_validation(
    in_rec_no     IN  NUMBER        --   �Ώۃ��R�[�h�ԍ�
   ,ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    ln_tmp_asset_number          NUMBER;                                                  -- �����Y�ԍ�
    lt_initial_asset_id          fa_system_controls.initial_asset_id%TYPE;                -- �������YID
    lt_use_cust_asset_num_flag   fa_system_controls.use_custom_asset_numbers_flag%TYPE;   -- ���[�U�[���Y�ԍ��g�p�t���O
    lt_adjustment_oif_id         xx01_adjustment_oif.adjustment_oif_id%TYPE;              -- �C��OIFID
    ln_ifrs_org_cost             NUMBER;                                                  -- IFRS�擾���z
--
    lv_asset_number              VARCHAR2(15);                                            -- ���Y�ԍ�
    lt_asset_category            xxcff_category_v.category_code%TYPE;                     -- ���Y���
    lt_deprn_declaration         fnd_flex_values.flex_value%TYPE;                         -- ���p�\��
    lt_asset_account             fnd_flex_values.flex_value%TYPE;                         -- ���Y����
    lt_deprn_account             fnd_flex_values.flex_value%TYPE;                         -- ���p�Ȗ�
    lt_deprn_sub_account         xxcff_aff_sub_account_v.aff_sub_account_code%TYPE;       -- ���p�⏕�Ȗ�
    lt_cat_deprn_method          fnd_flex_values.flex_value%TYPE;                         -- ���p���@
    lt_lease_class               xxcff_lease_class_v.lease_class_code%TYPE;               -- ���[�X���
    lt_company_code              xxcff_aff_company_v.aff_company_code%TYPE;               -- ���
    lt_department_code           xxcff_aff_department_v.aff_department_code%TYPE;         -- ����
    lt_dclr_place                fnd_flex_values.flex_value%TYPE;                         -- �\���n
    lt_location_name             fnd_flex_values.flex_value%TYPE;                         -- ���Ə�
    lt_yobi1                     xxcff_aff_project_v.aff_project_code%TYPE;               -- �\��1
    lt_yobi2                     xxcff_aff_project_v.aff_project_code%TYPE;               -- �\��2
    lt_ifrs_cat_deprn_method     fnd_flex_values.flex_value%TYPE;                         -- IFRS���p
    lt_ifrs_asset_account        xxcff_aff_account_v.aff_account_code%TYPE;               -- IFRS���Y�Ȗ�
--
    -- *** ���[�J���E�J�[�\�� ***
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
      AND    ffv.enabled_flag         = cv_yes
      AND    gd_process_date         >= NVL(ffv.start_date_active ,gd_process_date)
      AND    gd_process_date         <= NVL(ffv.end_date_active ,gd_process_date)
      ;
    -- �l�Z�b�g�`�F�b�N�J�[�\�����R�[�h�^
    check_flex_value_rec  check_flex_value_cur%ROWTYPE;
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
    -- ���[�J���ϐ��̏�����
    ln_tmp_asset_number          := NULL;  -- �����Y�ԍ�
    lt_initial_asset_id          := NULL;  -- �������YID
    lt_use_cust_asset_num_flag   := NULL;  -- ���[�U�[���Y�ԍ��g�p�t���O
    lt_adjustment_oif_id         := NULL;  -- �C��OIFID
    ln_ifrs_org_cost             := NULL;  -- IFRS�擾���z
    lv_asset_number              := NULL;  -- ���Y�ԍ�
    lt_asset_category            := NULL;  -- ���Y���
    lt_deprn_declaration         := NULL;  -- ���p�\��
    lt_asset_account             := NULL;  -- ���Y����
    lt_deprn_account             := NULL;  -- ���p�Ȗ�
    lt_deprn_sub_account         := NULL;  -- ���p�⏕�Ȗ�
    lt_cat_deprn_method          := NULL;  -- ���p���@
    lt_lease_class               := NULL;  -- ���[�X���
    lt_company_code              := NULL;  -- ���
    lt_department_code           := NULL;  -- ����
    lt_dclr_place                := NULL;  -- �\���n
    lt_location_name             := NULL;  -- ���Ə�
    lt_yobi1                     := NULL;  -- �\��1
    lt_yobi2                     := NULL;  -- �\��2
    lt_ifrs_cat_deprn_method     := NULL;  -- IFRS���p
    lt_ifrs_asset_account        := NULL;  -- IFRS���Y�Ȗ�
--
    -- ===============================
    -- ���͍��ڑÓ����`�F�b�N
    -- ===============================
--
    -- �����敪���u 1�i�o�^�j�v�̏ꍇ
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
      -- �Ώی����J�E���g
      gn_add_target_cnt := gn_add_target_cnt + 1;
--
    -- �����敪���u 2�i�C���j�v�̏ꍇ
    ELSIF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 ) THEN
      -- �Ώی����J�E���g
      gn_adj_target_cnt := gn_adj_target_cnt + 1;
--
      -- IFRS���ڂ̂������NULL�łȂ����`�F�b�N
      IF (  ( g_upload_tab(in_rec_no).ifrs_life_in_months IS NULL )    -- IFRS�ϗp�N��
        AND ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NULL )  -- IFRS���p
        AND ( g_upload_tab(in_rec_no).real_estate_acq_tax IS NULL )    -- �s���Y�擾��
        AND ( g_upload_tab(in_rec_no).borrowing_cost IS NULL )         -- �ؓ��R�X�g
        AND ( g_upload_tab(in_rec_no).other_cost IS NULL )             -- ���̑�
        AND ( g_upload_tab(in_rec_no).ifrs_asset_account IS NULL )     -- IFRS���Y�Ȗ�
      ) THEN
        -- ���͍��ڑÓ����`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00253      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
--
    -- �����敪����L�ȊO�̏ꍇ
    ELSE
--
      -- �����敪�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_name_00252      -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gb_err_flag := TRUE;
--
    END IF;
--
    -- �����敪���u 1�i�o�^�j�v�u 2�i�C���j�v�̏ꍇ
    IF ( g_upload_tab(in_rec_no).process_type IN ( cv_process_type_1 ,cv_process_type_2 ) ) THEN
      -- ===============================
      -- ���Y�ԍ�
      -- ===============================
      -- �����敪���u 2�i�C���j�v���A���Y�ԍ���NULL�̏ꍇ
      IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 )
        AND ( g_upload_tab(in_rec_no).asset_number IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50298       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50241       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
--
      -- ���Y�ԍ���NULL�ȊO�̏ꍇ
      ELSIF ( g_upload_tab(in_rec_no).asset_number IS NOT NULL ) THEN
--
        -- ****************************
        -- ���Y�ԍ��d���`�F�b�N
        -- ****************************
        BEGIN
          SELECT xtcan.asset_number  AS asset_number
          INTO   lv_asset_number
          FROM   xxcff_tmp_check_asset_num xtcan  -- ���Y�ԍ��`�F�b�N�ꎞ�\
          WHERE  xtcan.asset_number =  g_upload_tab(in_rec_no).asset_number
          AND    xtcan.line_no      <> g_upload_tab(in_rec_no).line_no
          AND    ROWNUM             =  cn_1
          ;
          -- ���Y�ԍ��d���G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_name_00279                        -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_column_data                       -- �g�[�N���R�[�h2
                         ,iv_token_value2 => g_upload_tab(in_rec_no).asset_number     -- �g�[�N���l2
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gb_err_flag := TRUE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        -- ****************************
        -- ���Y�ԍ��`�F�b�N
        -- ****************************
        BEGIN
          SELECT /*+
                   INDEX(fab FA_ADDITIONS_B_U2)
                   INDEX(fb  FA_BOOKS_N1)
                 */
                 fab.asset_number                  AS asset_number_old            -- ���Y�ԍ�
                ,fb.date_placed_in_service         AS dpis_old                    -- ���Ƌ��p��
                ,fab.asset_category_id             AS category_id_old             -- ���Y�J�e�S��ID
                ,fab.attribute_category_code       AS cat_attribute_category_old  -- ���Y�J�e�S���R�[�h
                ,fat.description                   AS description                 -- �E�v
                ,fab.current_units                 AS transaction_units           -- ���ݒP��
                ,fb.cost                           AS cost                        -- �擾���z
                ,fb.original_cost                  AS original_cost               -- �����擾���z
                ,fab.asset_number                  AS asset_number_new            -- ���Y�ԍ�
                ,fab.tag_number                    AS tag_number                  -- ���i�[�ԍ�
                ,fab.asset_category_id             AS category_id_new             -- ���Y�J�e�S��ID
                ,fab.serial_number                 AS serial_number               -- �V���A���ԍ�
                ,fab.asset_key_ccid                AS asset_key_ccid              -- ���Y�L�[CCID
                ,fak.segment1                      AS key_segment1                -- ���Y�L�[�Z�O�����g1
                ,fak.segment2                      AS key_segment2                -- ���Y�L�[�Z�O�����g2
                ,fab.parent_asset_id               AS parent_asset_id             -- �e���YID
                ,fab.lease_id                      AS lease_id                    -- ���[�XID
                ,fab.model_number                  AS model_number                -- ���f��
                ,fab.in_use_flag                   AS in_use_flag                 -- �g�p��
                ,fab.inventorial                   AS inventorial                 -- ���n�I���t���O
                ,fab.owned_leased                  AS owned_leased                -- ���L��
                ,fab.new_used                      AS new_used                    -- �V�i/����
                ,fab.attribute1                    AS cat_attribute1              -- �J�e�S��DFF1
                ,fab.attribute2                    AS cat_attribute2              -- �J�e�S��DFF2
                ,fab.attribute3                    AS cat_attribute3              -- �J�e�S��DFF3
                ,fab.attribute4                    AS cat_attribute4              -- �J�e�S��DFF4
                ,fab.attribute5                    AS cat_attribute5              -- �J�e�S��DFF5
                ,fab.attribute6                    AS cat_attribute6              -- �J�e�S��DFF6
                ,fab.attribute7                    AS cat_attribute7              -- �J�e�S��DFF7
                ,fab.attribute8                    AS cat_attribute8              -- �J�e�S��DFF8
                ,fab.attribute9                    AS cat_attribute9              -- �J�e�S��DFF9
                ,fab.attribute10                   AS cat_attribute10             -- �J�e�S��DFF10
                ,fab.attribute11                   AS cat_attribute11             -- �J�e�S��DFF11
                ,fab.attribute12                   AS cat_attribute12             -- �J�e�S��DFF12
                ,fab.attribute13                   AS cat_attribute13             -- �J�e�S��DFF13
                ,fab.attribute14                   AS cat_attribute14             -- �J�e�S��DFF14
                ,fab.attribute15                   AS cat_attribute15             -- �J�e�S��DFF15(IFRS�ϗp�N��)
                ,fab.attribute16                   AS cat_attribute16             -- �J�e�S��DFF16(IFRS���p)
                ,fab.attribute17                   AS cat_attribute17             -- �J�e�S��DFF17(�s���Y�擾��)
                ,fab.attribute18                   AS cat_attribute18             -- �J�e�S��DFF18(�ؓ��R�X�g)
                ,fab.attribute19                   AS cat_attribute19             -- �J�e�S��DFF19(���̑�)
                ,fab.attribute20                   AS cat_attribute20             -- �J�e�S��DFF20(IFRS���Y�Ȗ�)
                ,fab.attribute21                   AS cat_attribute21             -- �J�e�S��DFF21(�C���N����)
                ,fab.attribute22                   AS cat_attribute22             -- �J�e�S��DFF22
                ,fab.attribute23                   AS cat_attribute23             -- �J�e�S��DFF23
                ,fab.attribute24                   AS cat_attribute24             -- �J�e�S��DFF24
                ,fab.attribute25                   AS cat_attribute25             -- �J�e�S��DFF27
                ,fab.attribute26                   AS cat_attribute26             -- �J�e�S��DFF25
                ,fab.attribute27                   AS cat_attribute27             -- �J�e�S��DFF26
                ,fab.attribute28                   AS cat_attribute28             -- �J�e�S��DFF28
                ,fab.attribute29                   AS cat_attribute29             -- �J�e�S��DFF29
                ,fab.attribute30                   AS cat_attribute30             -- �J�e�S��DFF30
                ,fab.attribute_category_code       AS cat_attribute_category_new  -- ���Y�J�e�S���R�[�h
                ,fb.salvage_value                  AS salvage_value               -- �c�����z
                ,fb.percent_salvage_value          AS percent_salvage_value       -- �c�����z%
                ,fb.allowed_deprn_limit_amount     AS allowed_deprn_limit_amount  -- ���p���x�z
                ,fb.allowed_deprn_limit            AS allowed_deprn_limit         -- ���p���x��
                ,fb.depreciate_flag                AS depreciate_flag             -- ���p��v��t���O
                ,fb.deprn_method_code              AS deprn_method_code           -- ���p���@
                ,fb.basic_rate                     AS basic_rate                  -- ���ʏ��p��
                ,fb.adjusted_rate                  AS adjusted_rate               -- �����㏞�p��
                ,fb.life_in_months                 AS life_in_months              -- �ϗp�N���{����
                ,fb.bonus_rule                     AS bonus_rule                  -- �{�[�i�X���[��
            INTO g_fa_tab(in_rec_no).asset_number_old            -- ���Y�ԍ��i�C���O�j
                ,g_fa_tab(in_rec_no).dpis_old                    -- ���Ƌ��p���i�C���O�j
                ,g_fa_tab(in_rec_no).category_id_old             -- ���Y�J�e�S��ID�i�C���O�j
                ,g_fa_tab(in_rec_no).cat_attribute_category_old  -- ���Y�J�e�S���R�[�h�i�C���O�j
                ,g_fa_tab(in_rec_no).description                 -- �E�v�i�C����j
                ,g_fa_tab(in_rec_no).transaction_units           -- �P��
                ,g_fa_tab(in_rec_no).cost                        -- �擾���z
                ,g_fa_tab(in_rec_no).original_cost               -- �����擾���z
                ,g_fa_tab(in_rec_no).asset_number_new            -- ���Y�ԍ��i�C����j
                ,g_fa_tab(in_rec_no).tag_number                  -- ���i�[�ԍ�
                ,g_fa_tab(in_rec_no).category_id_new             -- ���Y�J�e�S��ID�i�C����j
                ,g_fa_tab(in_rec_no).serial_number               -- �V���A���ԍ�
                ,g_fa_tab(in_rec_no).asset_key_ccid              -- ���Y�L�[CCID
                ,g_fa_tab(in_rec_no).key_segment1                -- ���Y�L�[�Z�O�����g1
                ,g_fa_tab(in_rec_no).key_segment2                -- ���Y�L�[�Z�O�����g2
                ,g_fa_tab(in_rec_no).parent_asset_id             -- �e���YID
                ,g_fa_tab(in_rec_no).lease_id                    -- ���[�XID
                ,g_fa_tab(in_rec_no).model_number                -- ���f��
                ,g_fa_tab(in_rec_no).in_use_flag                 -- �g�p��
                ,g_fa_tab(in_rec_no).inventorial                 -- ���n�I���t���O
                ,g_fa_tab(in_rec_no).owned_leased                -- ���L��
                ,g_fa_tab(in_rec_no).new_used                    -- �V�i/����
                ,g_fa_tab(in_rec_no).cat_attribute1              -- �J�e�S��DFF1
                ,g_fa_tab(in_rec_no).cat_attribute2              -- �J�e�S��DFF2
                ,g_fa_tab(in_rec_no).cat_attribute3              -- �J�e�S��DFF3
                ,g_fa_tab(in_rec_no).cat_attribute4              -- �J�e�S��DFF4
                ,g_fa_tab(in_rec_no).cat_attribute5              -- �J�e�S��DFF5
                ,g_fa_tab(in_rec_no).cat_attribute6              -- �J�e�S��DFF6
                ,g_fa_tab(in_rec_no).cat_attribute7              -- �J�e�S��DFF7
                ,g_fa_tab(in_rec_no).cat_attribute8              -- �J�e�S��DFF8
                ,g_fa_tab(in_rec_no).cat_attribute9              -- �J�e�S��DFF9
                ,g_fa_tab(in_rec_no).cat_attribute10             -- �J�e�S��DFF10
                ,g_fa_tab(in_rec_no).cat_attribute11             -- �J�e�S��DFF11
                ,g_fa_tab(in_rec_no).cat_attribute12             -- �J�e�S��DFF12
                ,g_fa_tab(in_rec_no).cat_attribute13             -- �J�e�S��DFF13
                ,g_fa_tab(in_rec_no).cat_attribute14             -- �J�e�S��DFF14
                ,g_fa_tab(in_rec_no).cat_attribute15             -- �J�e�S��DFF15(IFRS�ϗp�N��)
                ,g_fa_tab(in_rec_no).cat_attribute16             -- �J�e�S��DFF16(IFRS���p)
                ,g_fa_tab(in_rec_no).cat_attribute17             -- �J�e�S��DFF17(�s���Y�擾��)
                ,g_fa_tab(in_rec_no).cat_attribute18             -- �J�e�S��DFF18(�ؓ��R�X�g)
                ,g_fa_tab(in_rec_no).cat_attribute19             -- �J�e�S��DFF19(���̑�)
                ,g_fa_tab(in_rec_no).cat_attribute20             -- �J�e�S��DFF20(IFRS���Y�Ȗ�)
                ,g_fa_tab(in_rec_no).cat_attribute21             -- �J�e�S��DFF21(�C���N����)
                ,g_fa_tab(in_rec_no).cat_attribute22             -- �J�e�S��DFF22
                ,g_fa_tab(in_rec_no).cat_attribute23             -- �J�e�S��DFF23
                ,g_fa_tab(in_rec_no).cat_attribute24             -- �J�e�S��DFF24
                ,g_fa_tab(in_rec_no).cat_attribute25             -- �J�e�S��DFF27
                ,g_fa_tab(in_rec_no).cat_attribute26             -- �J�e�S��DFF25
                ,g_fa_tab(in_rec_no).cat_attribute27             -- �J�e�S��DFF26
                ,g_fa_tab(in_rec_no).cat_attribute28             -- �J�e�S��DFF28
                ,g_fa_tab(in_rec_no).cat_attribute29             -- �J�e�S��DFF29
                ,g_fa_tab(in_rec_no).cat_attribute30             -- �J�e�S��DFF30
                ,g_fa_tab(in_rec_no).cat_attribute_category_new  -- ���Y�J�e�S���R�[�h�i�C����j
                ,g_fa_tab(in_rec_no).salvage_value               -- �c�����z
                ,g_fa_tab(in_rec_no).percent_salvage_value       -- �c�����z%
                ,g_fa_tab(in_rec_no).allowed_deprn_limit_amount  -- ���p���x�z
                ,g_fa_tab(in_rec_no).allowed_deprn_limit         -- ���p���x��
                ,g_fa_tab(in_rec_no).depreciate_flag             -- ���p��v��t���O
                ,g_fa_tab(in_rec_no).deprn_method_code           -- ���p���@
                ,g_fa_tab(in_rec_no).basic_rate                  -- ���ʏ��p��
                ,g_fa_tab(in_rec_no).adjusted_rate               -- �����㏞�p��
                ,g_fa_tab(in_rec_no).life_in_months              -- �ϗp�N���{����
                ,g_fa_tab(in_rec_no).bonus_rule                  -- �{�[�i�X���[��
          FROM   fa_additions_b         fab   -- ���Y�ڍ׏��
                ,fa_additions_tl        fat   -- ���Y�E�v���
                ,fa_asset_keywords      fak   -- ���Y�L�[
                ,fa_books               fb    -- ���Y�䒠���
          WHERE  fab.asset_id                 = fb.asset_id
          AND    fat.asset_id                 = fab.asset_id
          AND    fat.language                 = cv_lang_ja
          AND    fab.asset_key_ccid           = fak.code_combination_id(+)
          AND    fab.asset_number             = g_upload_tab(in_rec_no).asset_number
          AND    fb.book_type_code            = gv_fixed_asset_register
          AND    fb.date_ineffective          IS NULL
          ;
--
          -- �����敪���u 1�i�o�^�j�v�̏ꍇ
          IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
            -- �o�^�ς݃G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00254                        -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_column_data                       -- �g�[�N���R�[�h2
                           ,iv_token_value2 => g_upload_tab(in_rec_no).asset_number     -- �g�[�N���l2
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- �G���[�t���O���X�V
            gb_err_flag := TRUE;
--
          -- �����敪���u 2�i�C���j�v�̏ꍇ
          ELSE
--
            -- ****************************
            -- �O��f�[�^���݃`�F�b�N
            -- ****************************
            BEGIN
              SELECT xao.adjustment_oif_id  AS adjustment_oif_id
              INTO   lt_adjustment_oif_id
              FROM   xx01_adjustment_oif  xao   -- �C��OIF
              WHERE  xao.book_type_code    = gv_fixed_asset_register
              AND    xao.asset_number_old  = g_fa_tab(in_rec_no).asset_number_old
              ;
              -- �O��f�[�^���݃`�F�b�N�G���[
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => cv_msg_name_00265                        -- ���b�Z�[�W
                             ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                             ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                             ,iv_token_name2  => cv_tkn_column_data                       -- �g�[�N���R�[�h2
                             ,iv_token_value2 => g_fa_tab(in_rec_no).asset_number_old     -- �g�[�N���l2
                           );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
              );
              -- �G���[�t���O���X�V
              gb_err_flag := TRUE;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
--
            -- �����敪���u 1�i�o�^�j�v�̏ꍇ
            IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
              -- �����Y�ԍ�
              ln_tmp_asset_number := TO_NUMBER(g_upload_tab(in_rec_no).asset_number);
--
              BEGIN
                SELECT fsc.initial_asset_id               AS initial_asset_id
                      ,fsc.use_custom_asset_numbers_flag  AS use_custom_asset_numbers_flag
                INTO   lt_initial_asset_id
                      ,lt_use_cust_asset_num_flag
                FROM   fa_system_controls fsc       -- FA�V�X�e���R���g���[��
                ;
                -- ****************************
                -- ���Y�ԍ��̔ԃ`�F�b�N
                -- ****************************
                IF ( ln_tmp_asset_number >= lt_initial_asset_id )
                  AND ( NVL(lt_use_cust_asset_num_flag, cv_no) <> cv_yes ) THEN
                  -- ���Y�ԍ��̔ԃG���[
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                                 ,iv_name         => cv_msg_name_00264                        -- ���b�Z�[�W
                                 ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                                 ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                                 ,iv_token_name2  => cv_tkn_column_data                       -- �g�[�N���R�[�h2
                                 ,iv_token_value2 => g_upload_tab(in_rec_no).asset_number     -- �g�[�N���l2
                               );
                  FND_FILE.PUT_LINE(
                    which  => FND_FILE.OUTPUT
                   ,buff   => lv_errmsg
                  );
                  -- �G���[�t���O���X�V
                  gb_err_flag := TRUE;
                END IF;
              EXCEPTION
                WHEN INVALID_NUMBER OR VALUE_ERROR THEN
                 NULL;
              END;
--
            -- �����敪���u 2�i�C���j�v�̏ꍇ
            ELSE
--
              -- ���݃`�F�b�N�G���[
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => cv_msg_name_00256                        -- ���b�Z�[�W
                             ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                             ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                             ,iv_token_name2  => cv_tkn_input                             -- �g�[�N���R�[�h2
                             ,iv_token_value2 => cv_tkn_val_50241                         -- �g�[�N���l2
                             ,iv_token_name3  => cv_tkn_column_data                       -- �g�[�N���R�[�h3
                             ,iv_token_value3 => g_upload_tab(in_rec_no).asset_number     -- �g�[�N���l3
                           );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
              );
              -- �G���[�t���O���X�V
              gb_err_flag := TRUE;
            END IF;
        END;
      END IF;
    END IF;
--
    -- �����敪���u 1�i�o�^�j�v�̏ꍇ
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
      -- ===============================
      -- �E�v
      -- ===============================
      IF ( g_upload_tab(in_rec_no).description IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50242       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- ���
      -- ===============================
      IF ( g_upload_tab(in_rec_no).asset_category IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50072       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        BEGIN
          SELECT xcv.category_code  AS asset_category
          INTO   lt_asset_category
          FROM   xxcff_category_v  xcv   -- ���Y��ރr���[
          WHERE  xcv.category_code  = g_upload_tab(in_rec_no).asset_category
          AND    xcv.enabled_flag   = cv_yes
          AND    gd_process_date   >= NVL(xcv.start_date_active ,gd_process_date)
          AND    gd_process_date   <= NVL(xcv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���݃`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00256                        -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_input                             -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_tkn_val_50072                         -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_column_data                       -- �g�[�N���R�[�h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).asset_category   -- �g�[�N���l3
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
      -- ===============================
      -- ���p�\��
      -- ===============================
      IF ( g_upload_tab(in_rec_no).deprn_declaration IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50299       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        << check_deprn_declaration_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dclr_dprn                            -- XXCFF_DCLR_DPRN
                                      ,g_upload_tab(in_rec_no).deprn_declaration   -- ���p�\��
                                    )
        LOOP
          lt_deprn_declaration := check_flex_value_rec.flex_value;
        END LOOP check_deprn_declaration_loop;
        -- �擾�l��NULL�̏ꍇ
        IF ( lt_deprn_declaration IS NULL ) THEN
          -- ���݃`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                             -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_name_00256                          -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_line_no                             -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                         -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_input                               -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_val_50299                           -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_column_data                         -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).deprn_declaration  -- �g�[�N���l3
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
      -- ���Y����
      -- ===============================
      IF ( g_upload_tab(in_rec_no).asset_account IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50270       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        << check_asset_account_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_asset_acct                        -- XXCFF_ASSET_ACCOUNT
                                      ,g_upload_tab(in_rec_no).asset_account    -- ���Y����
                                    )
        LOOP
          lt_asset_account := check_flex_value_rec.flex_value;
        END LOOP check_asset_account_loop;
        -- �擾�l��NULL�̏ꍇ
        IF ( lt_asset_account IS NULL ) THEN
          -- ���݃`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_name_00256                        -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_input                             -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_val_50270                         -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_column_data                       -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).asset_account    -- �g�[�N���l3
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
      -- ���p�Ȗ�
      -- ===============================
      IF ( g_upload_tab(in_rec_no).deprn_account IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50300       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        << check_deprn_account_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_deprn_acct                       -- XXCFF_DEPRN_ACCOUNT
                                      ,g_upload_tab(in_rec_no).deprn_account   -- ���p�Ȗ�
                                    )
        LOOP
          lt_deprn_account := check_flex_value_rec.flex_value;
        END LOOP check_deprn_account_loop;
        -- �擾�l��NULL�̏ꍇ
        IF ( lt_deprn_account IS NULL ) THEN
          -- ���݃`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_name_00256                        -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_input                             -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_val_50300                         -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_column_data                       -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).deprn_account    -- �g�[�N���l3
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
      -- ���p�⏕�Ȗ�
      -- ===============================
      IF ( g_upload_tab(in_rec_no).deprn_sub_account IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50302       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
--
      -- ���p�⏕�ȖځA���p�Ȗڂ�NULL�ȊO�̏ꍇ
      ELSIF ( g_upload_tab(in_rec_no).deprn_sub_account IS NOT NULL )
        AND ( lt_deprn_account IS NOT NULL ) THEN
--
        BEGIN
          SELECT xasav.aff_sub_account_code  AS deprn_sub_account
          INTO   lt_deprn_sub_account
          FROM   xxcff_aff_sub_account_v  xasav   -- �⏕�Ȗڃr���[
          WHERE  xasav.aff_sub_account_code = g_upload_tab(in_rec_no).deprn_sub_account
          AND    xasav.aff_account_name     = lt_deprn_account
          AND    xasav.enabled_flag         = cv_yes
          AND    gd_process_date           >= NVL(xasav.start_date_active ,gd_process_date)
          AND    gd_process_date           <= NVL(xasav.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���݃`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                             -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00256                          -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no                             -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                         -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_input                               -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_tkn_val_50302                           -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_column_data                         -- �g�[�N���R�[�h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).deprn_sub_account  -- �g�[�N���l3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- �G���[�t���O���X�V
            gb_err_flag := TRUE;
        END;
--
      -- ��L�ȊO�̏ꍇ
      ELSE
        NULL;
      END IF;
--
      -- ===============================
      -- �ϗp�N��
      -- ===============================
      IF ( g_upload_tab(in_rec_no).life_in_months IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50307       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
--
      -- ���Y��ށA�ϗp�N����NULL�ȊO�̏ꍇ
      ELSIF ( lt_asset_category IS NOT NULL )
        AND ( g_upload_tab(in_rec_no).life_in_months IS NOT NULL ) THEN
--
        -- �ϗp�N���`�F�b�N
        xxcff_common1_pkg.chk_life(
          iv_category     => lt_asset_category                        -- 1.���Y���
         ,iv_life         => g_upload_tab(in_rec_no).life_in_months   -- 2.�ϗp�N��
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- �ϗp�N���G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_name_00257                        -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
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
      -- ���p���@
      -- ===============================
      IF ( g_upload_tab(in_rec_no).cat_deprn_method IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50097       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        << check_cat_deprn_method_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dprn_method                        -- XXCFF_DPRN_METHOD
                                      ,g_upload_tab(in_rec_no).cat_deprn_method  -- ���p���@
                                    )
        LOOP
          lt_cat_deprn_method := check_flex_value_rec.flex_value;
        END LOOP check_cat_deprn_method_loop;
        -- �擾�l��NULL�̏ꍇ
        IF ( lt_cat_deprn_method IS NULL ) THEN
          -- ���݃`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                            -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_name_00256                         -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_line_no                            -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                        -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_input                              -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_val_50097                          -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_column_data                        -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).cat_deprn_method  -- �g�[�N���l3
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
      -- ���[�X���
      -- ===============================
      IF ( g_upload_tab(in_rec_no).lease_class IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50017       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- ���Ƌ��p��
      -- ===============================
      IF ( g_upload_tab(in_rec_no).date_placed_in_service IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50262       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- ���Ƌ��p���`�F�b�N
        -- ********************************
        IF ( gt_period_close_date < g_upload_tab(in_rec_no).date_placed_in_service ) THEN
            -- ���Ƌ��p���`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                                  -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00270                               -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no                                  -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                              -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_close_date                               -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(gt_period_close_date ,cv_date_fmt_std)  -- �g�[�N���l2
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
      -- �擾���z
      -- ===============================
      IF ( g_upload_tab(in_rec_no).original_cost IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50308       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- ���E�l�G���[�`�F�b�N
        -- ********************************
        IF ( g_upload_tab(in_rec_no).original_cost < cn_1 ) THEN
            -- ���E�l�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00271      -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_input           -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_tkn_val_50308       -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_min_value       -- �g�[�N���R�[�h3
                           ,iv_token_value3 => cn_1                   -- �g�[�N���l3
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
      -- �P�ʐ���
      -- ===============================
      IF ( g_upload_tab(in_rec_no).quantity IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50309       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- ���E�l�G���[�`�F�b�N
        -- ********************************
        IF ( g_upload_tab(in_rec_no).quantity < cn_1 ) THEN
            -- ���E�l�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00271      -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_input           -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_tkn_val_50309       -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_min_value       -- �g�[�N���R�[�h3
                           ,iv_token_value3 => cn_1                   -- �g�[�N���l3
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
      -- ���
      -- ===============================
      IF ( g_upload_tab(in_rec_no).company_code IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50274       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        BEGIN
          SELECT xacv.aff_company_code  AS company_code
          INTO   lt_company_code
          FROM   xxcff_aff_company_v  xacv   -- ��Ѓr���[
          WHERE  xacv.aff_company_code  = g_upload_tab(in_rec_no).company_code
          AND    xacv.enabled_flag      = cv_yes
          AND    gd_process_date       >= NVL(xacv.start_date_active ,gd_process_date)
          AND    gd_process_date       <= NVL(xacv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���݃`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00256                        -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_input                             -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_tkn_val_50274                         -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_column_data                       -- �g�[�N���R�[�h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).company_code     -- �g�[�N���l3
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
      -- ===============================
      -- ����
      -- ===============================
      IF ( g_upload_tab(in_rec_no).department_code IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50301       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        BEGIN
          SELECT xadv.aff_department_code  AS department_code
          INTO   lt_department_code
          FROM   xxcff_aff_department_v  xadv   -- ����r���[
          WHERE  xadv.aff_department_code  = g_upload_tab(in_rec_no).department_code
          AND    xadv.enabled_flag         = cv_yes
          AND    gd_process_date          >= NVL(xadv.start_date_active ,gd_process_date)
          AND    gd_process_date          <= NVL(xadv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���݃`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00256                        -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_input                             -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_tkn_val_50301                         -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_column_data                       -- �g�[�N���R�[�h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).department_code  -- �g�[�N���l3
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
      -- ===============================
      -- �\���n
      -- ===============================
      IF ( g_upload_tab(in_rec_no).dclr_place IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50246       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        << check_dclr_place_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dclr_place                        -- XXCFF_DCLR_PLACE
                                      ,g_upload_tab(in_rec_no).dclr_place       -- �\���n
                                    )
        LOOP
          lt_dclr_place := check_flex_value_rec.flex_value;
        END LOOP check_dclr_place_loop;
        -- �擾�l��NULL�̏ꍇ
        IF ( lt_dclr_place IS NULL ) THEN
          -- ���݃`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_name_00256                        -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_input                             -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_val_50246                         -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_column_data                       -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).dclr_place       -- �g�[�N���l3
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
      -- ���Ə�
      -- ===============================
      IF ( g_upload_tab(in_rec_no).location_name IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50265       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        << check_dclr_place_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_mng_place                         -- XXCFF_MNG_PLACE
                                      ,g_upload_tab(in_rec_no).location_name    -- ���Ə�
                                    )
        LOOP
          lt_location_name := check_flex_value_rec.flex_value;
        END LOOP check_dclr_place_loop;
        -- �擾�l��NULL�̏ꍇ
        IF ( lt_location_name IS NULL ) THEN
          -- ���݃`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_name_00256                        -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_input                             -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_val_50265                         -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_column_data                       -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).location_name    -- �g�[�N���l3
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
      -- �ꏊ
      -- ===============================
      IF ( g_upload_tab(in_rec_no).location_place IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50266       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- �\��1
      -- ===============================
      IF ( g_upload_tab(in_rec_no).yobi1 IS NOT NULL ) THEN
        BEGIN
          SELECT xcapv.aff_project_code  AS yobi1
          INTO   lt_yobi1
          FROM   xxcff_aff_project_v  xcapv   -- �\���P�r���[
          WHERE  xcapv.aff_project_code  = g_upload_tab(in_rec_no).yobi1
          AND    xcapv.enabled_flag      = cv_yes
          AND    gd_process_date        >= NVL(xcapv.start_date_active ,gd_process_date)
          AND    gd_process_date        <= NVL(xcapv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���݃`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00256                        -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_input                             -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_tkn_val_50311                         -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_column_data                       -- �g�[�N���R�[�h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).yobi1            -- �g�[�N���l3
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
      -- ===============================
      -- �\��2
      -- ===============================
      IF ( g_upload_tab(in_rec_no).yobi2 IS NOT NULL ) THEN
        BEGIN
          SELECT xafv.aff_future_code  AS yobi2
          INTO   lt_yobi2
          FROM   xxcff_aff_future_v  xafv   -- �\���Q�r���[
          WHERE  xafv.aff_future_code   = g_upload_tab(in_rec_no).yobi2
          AND    xafv.enabled_flag      = cv_yes
          AND    gd_process_date       >= NVL(xafv.start_date_active ,gd_process_date)
          AND    gd_process_date       <= NVL(xafv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���݃`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00256                        -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no                           -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_input                             -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_tkn_val_50312                         -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_column_data                       -- �g�[�N���R�[�h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).yobi2            -- �g�[�N���l3
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
      -- ===============================
      -- �擾��
      -- ===============================
      IF ( g_upload_tab(in_rec_no).assets_date IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50310       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
--
    END IF;
--
    -- �����敪���u 1�i�o�^�j�v�u 2�i�C���j�v�̏ꍇ
    IF ( g_upload_tab(in_rec_no).process_type IN ( cv_process_type_1 ,cv_process_type_2 ) ) THEN
--
      -- ===============================
      -- IFRS�擾���z
      -- ===============================
      -- �����敪���u 1�i�o�^�j�v�̏ꍇ
      IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
        -- IFRS�擾���z�̎Z�o
        ln_ifrs_org_cost := NVL(g_upload_tab(in_rec_no).original_cost ,cn_0)         -- �擾���z
                          + NVL(g_upload_tab(in_rec_no).real_estate_acq_tax ,cn_0)   -- �s���Y�擾��
                          + NVL(g_upload_tab(in_rec_no).borrowing_cost ,cn_0)        -- �ؓ��R�X�g
                          + NVL(g_upload_tab(in_rec_no).other_cost ,cn_0)            -- ���̑�
                         ;
--
      -- �����敪����L�ȊO�̏ꍇ
      ELSE
--
        -- IFRS�擾���z�̎Z�o
        ln_ifrs_org_cost := g_fa_tab(in_rec_no).cost                                 -- �擾���z
                          + CASE WHEN g_upload_tab(in_rec_no).real_estate_acq_tax IS NOT NULL THEN
                              g_upload_tab(in_rec_no).real_estate_acq_tax
                            ELSE
                              NVL(g_fa_tab(in_rec_no).cat_attribute17 ,cn_0)
                            END                                                      -- �s���Y�擾��
                          + CASE WHEN g_upload_tab(in_rec_no).borrowing_cost IS NOT NULL THEN
                              g_upload_tab(in_rec_no).borrowing_cost
                            ELSE
                              NVL(g_fa_tab(in_rec_no).cat_attribute18 ,cn_0)
                            END                                                      -- �ؓ��R�X�g
                          + CASE WHEN g_upload_tab(in_rec_no).other_cost IS NOT NULL THEN
                              g_upload_tab(in_rec_no).other_cost
                            ELSE
                              NVL(g_fa_tab(in_rec_no).cat_attribute19 ,cn_0)
                            END                                                      -- ���̑�
                         ;
--
      END IF;
--
      -- ********************************
      -- ���E�l�G���[�`�F�b�N
      -- ********************************
      IF ( ln_ifrs_org_cost < cn_1 ) THEN
          -- ���E�l�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_name_00271      -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_input           -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_val_50321       -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_min_value       -- �g�[�N���R�[�h3
                         ,iv_token_value3 => cn_1                   -- �g�[�N���l3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- IFRS���p
      -- ===============================
      IF ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NOT NULL ) THEN
        << check_ifrs_cat_dep_metd_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dprn_method                             -- XXCFF_DPRN_METHOD
                                      ,g_upload_tab(in_rec_no).ifrs_cat_deprn_method  -- IFRS���p
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
                         ,iv_token_value3 => g_upload_tab(in_rec_no).ifrs_cat_deprn_method  -- �g�[�N���l3
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
      IF ( g_upload_tab(in_rec_no).ifrs_asset_account IS NOT NULL ) THEN
        BEGIN
          SELECT xaav.aff_account_code  AS ifrs_asset_account
          INTO   lt_ifrs_asset_account
          FROM   xxcff_aff_account_v  xaav   -- ����Ȗڃr���[
          WHERE  xaav.aff_account_code  = g_upload_tab(in_rec_no).ifrs_asset_account
          AND    xaav.enabled_flag      = cv_yes
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
                           ,iv_token_value3 => g_upload_tab(in_rec_no).ifrs_asset_account  -- �g�[�N���l3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- �G���[�t���O���X�V
            gb_err_flag := TRUE;
        END;
      END IF;
    END IF;
--
    -- �����敪���u 2�i�C���j�v�̏ꍇ
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 ) THEN
--
      -- ===============================
      -- �C���N����
      -- ===============================
      IF ( g_upload_tab(in_rec_no).correct_date IS NULL ) THEN
        -- ���ږ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00255      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_proc_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50298       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_input           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_val_50313       -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- �C���N�����`�F�b�N
        -- ********************************
        IF ( gt_period_open_date > g_upload_tab(in_rec_no).correct_date ) THEN
            -- �C���N�����`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                                 -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00261                              -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no                                 -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                             -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_open_date                               -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(gt_period_open_date ,cv_date_fmt_std)  -- �g�[�N���l2
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- �G���[�t���O���X�V
            gb_err_flag := TRUE;
        END IF;
      END IF;
    END IF;
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
      IF ( check_flex_value_cur%ISOPEN ) THEN
        CLOSE check_flex_value_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END data_validation;
--
  /**********************************************************************************
   * Procedure Name   : insert_add_oif
   * Description      : �ǉ�OIF�o�^(A-9)
   ***********************************************************************************/
  PROCEDURE insert_add_oif(
    in_rec_no     IN  NUMBER        --   �Ώۃ��R�[�h�ԍ�
   ,ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_add_oif'; -- �v���O������
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
    cn_segment_cnt            CONSTANT NUMBER        := 8;              -- �Z�O�����g��
    cv_posting_status         CONSTANT VARCHAR2(4)   := 'POST';         -- �]�L�X�e�[�^�X
    cv_queue_name             CONSTANT VARCHAR2(4)   := 'POST';         -- �L���[��
    cv_depreciate_flag        CONSTANT VARCHAR2(3)   := 'YES';          -- ���p��v��t���O
    cv_asset_type             CONSTANT VARCHAR2(11)  := 'CAPITALIZED';  -- ���Y�^�C�v
    cv_dummy                  CONSTANT VARCHAR2(5)   := 'DUMMY';        -- �_�~�[
--
    -- *** ���[�J���ϐ� ***
    lb_ret                    BOOLEAN;                                         -- �֐����^�[���E�R�[�h
    lt_asset_category_id      gl_code_combinations.code_combination_id%TYPE;   -- ���Y�J�e�S��CCID
    lt_exp_code_comb_id       gl_code_combinations.code_combination_id%TYPE;   -- �������p���CCID
    lt_location_id            gl_code_combinations.code_combination_id%TYPE;   -- ���Ə�CCID
    lt_asset_key_ccid         fa_asset_keywords.code_combination_id%TYPE;      -- ���Y�L�[CCID
    lt_deprn_method           fa_category_book_defaults.deprn_method%TYPE;     -- ���p���@
    lt_life_in_months         fa_category_book_defaults.life_in_months%TYPE;   -- �v�Z����
    lt_basic_rate             fa_category_book_defaults.basic_rate%TYPE;       -- ���ʏ��p��
    lt_adjusted_rate          fa_category_book_defaults.adjusted_rate%TYPE;    -- �����㏞�p��
    lv_segment5               VARCHAR2(100);                                   -- �{�ЍH��敪
--
    lt_ifrs_life_in_months    fa_mass_additions.attribute15%TYPE;              -- IFRS�ϗp�N��
    lt_ifrs_cat_deprn_method  fa_mass_additions.attribute16%TYPE;              -- IFRS���p
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
    -- ���[�J���ϐ��̏�����
    lb_ret                     := FALSE;   -- �֐����^�[���E�R�[�h
    lt_asset_category_id       := NULL;    -- ���Y�J�e�S��CCID
    lt_exp_code_comb_id        := NULL;    -- �������p���CCID
    lt_location_id             := NULL;    -- ���Ə�CCID
    lt_asset_key_ccid          := NULL;    -- ���Y�L�[CCID
    lt_deprn_method            := NULL;    -- ���p���@
    lt_life_in_months          := NULL;    -- �v�Z����
    lt_basic_rate              := NULL;    -- ���ʏ��p��
    lt_adjusted_rate           := NULL;    -- �����㏞�p��
    lv_segment5                := NULL;    -- �{�ЍH��敪
    lt_ifrs_life_in_months     := NULL;    -- IFRS�ϗp�N��
    lt_ifrs_cat_deprn_method   := NULL;    -- IFRS���p
--
    -- �����敪���u 1�i�o�^�j�v�̏ꍇ
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
      -- ===============================
      -- ���Y�J�e�S��CCID�擾
      -- ===============================
      -- ���Y�J�e�S���`�F�b�N
      xxcff_common1_pkg.chk_fa_category(
        iv_segment1    => g_upload_tab(in_rec_no).asset_category      -- ���
       ,iv_segment2    => g_upload_tab(in_rec_no).deprn_declaration   -- ���p�\��
       ,iv_segment3    => g_upload_tab(in_rec_no).asset_account       -- ���Y����
       ,iv_segment4    => g_upload_tab(in_rec_no).deprn_account       -- ���p�Ȗ�
       ,iv_segment5    => g_upload_tab(in_rec_no).life_in_months      -- �ϗp�N��
       ,iv_segment6    => g_upload_tab(in_rec_no).cat_deprn_method    -- ���p���@
       ,iv_segment7    => g_upload_tab(in_rec_no).lease_class         -- ���[�X���
       ,on_category_id => lt_asset_category_id                        -- ���Y�J�e�S��CCID
       ,ov_errbuf      => lv_errbuf 
       ,ov_retcode     => lv_retcode
       ,ov_errmsg      => lv_errmsg
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- ���ʊ֐��G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00258      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_func_name       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50303       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_info            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lv_errmsg              -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- ���Y�J�e�S�����擾
      -- ===============================
      IF ( lt_asset_category_id IS NOT NULL ) THEN
        BEGIN
          SELECT fcbd.deprn_method      AS deprn_method     -- ���p���@
                ,fcbd.life_in_months    AS life_in_months   -- �v�Z����
                ,fcbd.basic_rate        AS basic_rate       -- ���ʏ��p��
                ,fcbd.adjusted_rate     AS adjusted_rate    -- �����㏞�p��
          INTO   lt_deprn_method
                ,lt_life_in_months
                ,lt_basic_rate
                ,lt_adjusted_rate
          FROM   fa_categories_b            fcb     -- ���Y�J�e�S���}�X�^
                ,fa_category_book_defaults  fcbd    -- ���Y�J�e�S�����p�
          WHERE  fcb.category_id       = fcbd.category_id
          AND    fcb.category_id       = lt_asset_category_id  -- ���Y�J�e�S��CCID
          AND    fcbd.book_type_code   = gv_fixed_asset_register
          AND    gd_process_date      >= fcbd.start_dpis
          AND    gd_process_date      <= NVL(fcbd.end_dpis ,gd_process_date)
          ;
        EXCEPTION
          -- ���Y�J�e�S�����擾�ł��Ȃ��ꍇ
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff           -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00259        -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_line_no           -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)       -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_param_name        -- �g�[�N���R�[�h2
                           ,iv_token_value2 => gv_fixed_asset_register  -- �g�[�N���l2
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
      -- ===============================
      -- �������p���CCID�擾
      -- ===============================
      -- �Z�O�����g�l�z�񏉊���
      g_segments_tab.DELETE;
      -- �Z�O�����g�l�z��ݒ�(SEG1:���)
      g_segments_tab(1) := g_upload_tab(in_rec_no).company_code;
      -- �Z�O�����g�l�z��ݒ�(SEG2:����R�[�h)
      g_segments_tab(2) := g_upload_tab(in_rec_no).department_code;
      -- �Z�O�����g�l�z��ݒ�(SEG3:���p�Ȗ�)
      g_segments_tab(3) := g_upload_tab(in_rec_no).deprn_account;
      -- �Z�O�����g�l�z��ݒ�(SEG4:�⏕�Ȗ�)
      g_segments_tab(4) := g_upload_tab(in_rec_no).deprn_sub_account;
      -- �Z�O�����g�l�z��ݒ�(SEG5:�ڋq�R�[�h)
      g_segments_tab(5) := cv_segment5_dummy;
      -- �Z�O�����g�l�z��ݒ�(SEG6:��ƃR�[�h)
      g_segments_tab(6) := cv_segment6_dummy;
      -- �Z�O�����g�l�z��ݒ�(SEG7:�\���P)
      g_segments_tab(7) := cv_segment7_dummy;
      -- �Z�O�����g�l�z��ݒ�(SEG8:�\���Q)
      g_segments_tab(8) := cv_segment8_dummy;
--
      -- CCID�擾�֐��Ăяo��
      lb_ret := fnd_flex_ext.get_combination_id(
                   application_short_name  => gt_application_short_name       -- �A�v���P�[�V�����Z�k��(GL)
                  ,key_flex_code           => gt_id_flex_code                 -- �L�[�t���b�N�X�R�[�h
                  ,structure_number        => gt_chart_of_account_id          -- ����Ȗڑ̌n�ԍ�
                  ,validation_date         => gd_process_date                 -- ���t�`�F�b�N
                  ,n_segments              => cn_segment_cnt                  -- �Z�O�����g��
                  ,segments                => g_segments_tab                  -- �Z�O�����g�l�z��
                  ,combination_id          => lt_exp_code_comb_id             -- �������p���CCID
                );
      IF NOT lb_ret THEN
        lv_errmsg := fnd_flex_ext.get_message;
        -- ���ʊ֐��G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00258      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_func_name       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50304       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_info            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lv_errmsg              -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- ���Ə�CCID�擾
      -- ===============================
-- Ver1.1 Mod Start
--      -- �{�ЍH��敪�̔���
--      IF ( g_upload_tab(in_rec_no).company_code = gv_company_cd_itoen ) THEN
--        -- �{�ЍH��敪_�{��
--        lv_segment5 := gv_own_comp_itoen;
--      ELSE
--        -- �{�ЍH��敪_�H��
--        lv_segment5 := gv_own_comp_sagara;
--      END IF;
      -- �{�ЍH��敪
      BEGIN
        SELECT flvv.description AS segment5                   --��Ж�
        INTO   lv_segment5
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type   = cv_flvv_own_comp_cd
        AND    flvv.lookup_code   = g_upload_tab(in_rec_no).company_code
        AND    flvv.enabled_flag  = cv_yes
        AND    gd_process_date   >= NVL(flvv.start_date_active ,gd_process_date)
        AND    gd_process_date   <= NVL(flvv.end_date_active ,gd_process_date)
        ;
      EXCEPTION
        WHEN OTHERS THEN
        -- �Q�ƃ^�C�v�E�R�[�h���擾�ł��Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>cv_msg_kbn_cff
                         ,iv_name         => cv_msg_name_00189
                         ,iv_token_name1  => cv_tkn_lookup_type
                         ,iv_token_value1 => cv_tkn_val_50331
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
-- Ver1.1 Mod End
--
      -- ���Ə��}�X�^�`�F�b�N
      xxcff_common1_pkg.chk_fa_location(
         iv_segment1      => g_upload_tab(in_rec_no).dclr_place        -- �\���n
        ,iv_segment2      => g_upload_tab(in_rec_no).department_code   -- ����
        ,iv_segment3      => g_upload_tab(in_rec_no).location_name     -- ���Ə�
        ,iv_segment4      => g_upload_tab(in_rec_no).location_place    -- �ꏊ
        ,iv_segment5      => lv_segment5                               -- �{�ЍH��敪
        ,on_location_id   => lt_location_id                            -- ���Ə�CCID
        ,ov_errbuf        => lv_errbuf                                 -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode       => lv_retcode                                -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- ���ʊ֐��G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_name_00258      -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_func_name       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_50141       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_info            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lv_errmsg              -- �g�[�N���l3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- ���Y�L�[CCID�擾
      -- ===============================
      BEGIN
        SELECT fak.code_combination_id   AS asset_key_ccid     -- ���Y�L�[CCID
        INTO   lt_asset_key_ccid
        FROM   fa_asset_keywords  fak       -- ���Y�L�[
        WHERE  NVL(fak.segment1 ,cv_dummy)  = NVL(g_upload_tab(in_rec_no).yobi1 ,cv_dummy)
        AND    NVL(fak.segment2 ,cv_dummy)  = NVL(g_upload_tab(in_rec_no).yobi2 ,cv_dummy)
        AND    fak.enabled_flag             = cv_yes
        AND    gd_process_date             >= NVL(fak.start_date_active ,gd_process_date)
        AND    gd_process_date             <= NVL(fak.end_date_active ,gd_process_date)
        ;
      EXCEPTION
        -- ���Y�L�[CCID���擾�ł��Ȃ��ꍇ
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_name_00260        -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_line_no           -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)       -- �g�[�N���l1
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gb_err_flag := TRUE;
      END;
--
      -- �G���[���Ȃ���Ώ����p��
      IF ( gb_err_flag ) THEN
        NULL;
      ELSE
--
        -- ===============================
        -- IFRS�ϗp�N���AIFRS���p�Z�b�g
        -- ===============================
        -- IFRS�ϗp�N��
        IF ( g_upload_tab(in_rec_no).ifrs_life_in_months IS NOT NULL ) THEN
          -- IFRS�ϗp�N�����Z�b�g
          lt_ifrs_life_in_months := g_upload_tab(in_rec_no).ifrs_life_in_months;
        ELSE
          -- �ϗp�N�����Z�b�g
          lt_ifrs_life_in_months := g_upload_tab(in_rec_no).life_in_months;
        END IF;
        -- IFRS���p
        IF ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NOT NULL ) THEN
          -- IFRS���p���Z�b�g
          lt_ifrs_cat_deprn_method := g_upload_tab(in_rec_no).ifrs_cat_deprn_method;
        ELSE
          -- IFRS���p���@(�����l)���Z�b�g
          lt_ifrs_cat_deprn_method := gv_cat_dep_ifrs;
        END IF;
--
        -- ****************************
        -- �ǉ�OIF�o�^
        -- ****************************
        BEGIN
          INSERT INTO fa_mass_additions(
             mass_addition_id                  -- �ǉ�OIF����ID
            ,asset_number                      -- ���Y�ԍ�
            ,description                       -- �E�v
            ,asset_category_id                 -- ���Y�J�e�S��CCID
            ,book_type_code                    -- �䒠
            ,date_placed_in_service            -- ���Ƌ��p��
            ,fixed_assets_cost                 -- �擾���z
            ,payables_units                    -- AP����
            ,fixed_assets_units                -- ���Y����
            ,expense_code_combination_id       -- �������p���CCID
            ,location_id                       -- ���Ə��t���b�N�X�t�B�[���hCCID
            ,feeder_system_name                -- �����V�X�e����
            ,last_update_date                  -- �ŏI�X�V��
            ,last_updated_by                   -- �ŏI�X�V��
            ,posting_status                    -- �]�L�X�e�[�^�X
            ,queue_name                        -- �L���[��
            ,payables_cost                     -- ���Y�����擾���z
            ,depreciate_flag                   -- ���p��v��t���O
            ,asset_key_ccid                    -- ���Y�L�[CCID
            ,asset_type                        -- ���Y�^�C�v
            ,deprn_method_code                 -- ���p���@
            ,life_in_months                    -- �v�Z����
            ,basic_rate                        -- ���ʏ��p��
            ,adjusted_rate                     -- �����㏞�p��
            ,attribute2                        -- DFF2(�擾��)
            ,attribute15                       -- DFF15(IFRS�ϗp�N��)
            ,attribute16                       -- DFF16(IFRS���p)
            ,attribute17                       -- DFF17(�s���Y�擾��)
            ,attribute18                       -- DFF18(�ؓ��R�X�g)
            ,attribute19                       -- DFF19(���̑�)
            ,attribute20                       -- DFF20(IFRS���Y�Ȗ�)
            ,created_by                        -- �쐬��ID
            ,creation_date                     -- �쐬��
            ,last_update_login                 -- �ŏI�X�V���O�C��ID
            ,request_id                        -- �v��ID
          )
          VALUES (
             fa_mass_additions_s.NEXTVAL                                     -- �ǉ�OIF����ID
            ,g_upload_tab(in_rec_no).asset_number                            -- ���Y�ԍ�
            ,g_upload_tab(in_rec_no).description                             -- �E�v
            ,lt_asset_category_id                                            -- ���Y�J�e�S��CCID
            ,gv_fixed_asset_register                                         -- �䒠
            ,g_upload_tab(in_rec_no).date_placed_in_service                  -- ���Ƌ��p��
            ,g_upload_tab(in_rec_no).original_cost                           -- �擾���z
            ,g_upload_tab(in_rec_no).quantity                                -- AP����
            ,g_upload_tab(in_rec_no).quantity                                -- ���Y����
            ,lt_exp_code_comb_id                                             -- �������p���CCID
            ,lt_location_id                                                  -- ���Ə��t���b�N�X�t�B�[���hCCID
            ,gv_feed_sys_nm                                                  -- �����V�X�e����_FA�A�b�v���[�h
            ,cd_last_update_date                                             -- �ŏI�X�V��
            ,cn_last_updated_by                                              -- �ŏI�X�V��
            ,cv_posting_status                                               -- �]�L�X�e�[�^�X
            ,cv_queue_name                                                   -- �L���[��
            ,g_upload_tab(in_rec_no).original_cost                           -- �擾���z
            ,cv_depreciate_flag                                              -- ���p��v��t���O
            ,lt_asset_key_ccid                                               -- ���Y�L�[CCID
            ,cv_asset_type                                                   -- ���Y�^�C�v
            ,lt_deprn_method                                                 -- ���p���@
            ,lt_life_in_months                                               -- �v�Z����
            ,lt_basic_rate                                                   -- ���ʏ��p��
            ,lt_adjusted_rate                                                -- �����㏞�p��
            ,TO_CHAR(g_upload_tab(in_rec_no).assets_date ,cv_date_fmt_std)   -- �擾��
            ,lt_ifrs_life_in_months                                          -- IFRS�ϗp�N��
            ,lt_ifrs_cat_deprn_method                                        -- IFRS���p
            ,g_upload_tab(in_rec_no).real_estate_acq_tax                     -- �s���Y�擾��
            ,g_upload_tab(in_rec_no).borrowing_cost                          -- �ؓ��R�X�g
            ,g_upload_tab(in_rec_no).other_cost                              -- ���̑�
            ,g_upload_tab(in_rec_no).ifrs_asset_account                      -- IFRS���Y�Ȗ�
            ,cn_created_by                                                   -- �쐬��
            ,cd_creation_date                                                -- �쐬��
            ,cn_last_update_login                                            -- �ŏI�X�V���O�C��
            ,cn_request_id                                                   -- �v��ID
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- �o�^�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff           -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00102        -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_table_name        -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_val_50319         -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_info              -- �g�[�N���R�[�h2
                           ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- �ǉ�OIF�o�^�����J�E���g
        gn_add_normal_cnt := gn_add_normal_cnt + 1;
--
      END IF;
    END IF;
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
  END insert_add_oif;
--
  /**********************************************************************************
   * Procedure Name   : insert_adj_oif
   * Description      : �C��OIF�o�^(A-10)
   ***********************************************************************************/
  PROCEDURE insert_adj_oif(
    in_rec_no     IN  NUMBER        --   �Ώۃ��R�[�h�ԍ�
   ,ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_adj_oif'; -- �v���O������
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
    cv_status                 CONSTANT VARCHAR2(11)  := 'PENDING';  -- �X�e�[�^�X
    cn_months                 NUMBER                 := 12;         -- 12����
--
    -- *** ���[�J���ϐ� ***
    ln_life_years             NUMBER;                                      -- �ϗp�N��
    ln_life_months            NUMBER;                                      -- �ϗp����
    lt_cat_attribute15        xx01_adjustment_oif.cat_attribute15%TYPE;    -- �J�e�S��DFF15(IFRS�ϗp�N��)
    lt_cat_attribute16        xx01_adjustment_oif.cat_attribute16%TYPE;    -- �J�e�S��DFF16(IFRS���p)
    lt_cat_attribute17        xx01_adjustment_oif.cat_attribute17%TYPE;    -- �J�e�S��DFF17(�s���Y�擾��)
    lt_cat_attribute18        xx01_adjustment_oif.cat_attribute18%TYPE;    -- �J�e�S��DFF18(�ؓ��R�X�g)
    lt_cat_attribute19        xx01_adjustment_oif.cat_attribute19%TYPE;    -- �J�e�S��DFF19(���̑�)
    lt_cat_attribute20        xx01_adjustment_oif.cat_attribute20%TYPE;    -- �J�e�S��DFF20(IFRS���Y�Ȗ�)
    lt_cat_attribute21        xx01_adjustment_oif.cat_attribute21%TYPE;    -- �J�e�S��DFF21(�C���N����)
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
    -- ���[�J���ϐ��̏�����
    ln_life_years       := NULL;  -- �ϗp�N��
    ln_life_months      := NULL;  -- �ϗp����
    lt_cat_attribute15  := NULL;  -- �J�e�S��DFF15(IFRS�ϗp�N��)
    lt_cat_attribute16  := NULL;  -- �J�e�S��DFF16(IFRS���p)
    lt_cat_attribute17  := NULL;  -- �J�e�S��DFF17(�s���Y�擾��)
    lt_cat_attribute18  := NULL;  -- �J�e�S��DFF18(�ؓ��R�X�g)
    lt_cat_attribute19  := NULL;  -- �J�e�S��DFF19(���̑�)
    lt_cat_attribute20  := NULL;  -- �J�e�S��DFF20(IFRS���Y�Ȗ�)
    lt_cat_attribute21  := NULL;  -- �J�e�S��DFF21(�C���N����)
--
    -- �����敪���u 2�i�C���j�v�̏ꍇ
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 ) THEN
--
      -- ===============================
      -- �ϗp�N���A�ϗp�����Z�o
      -- ===============================
      -- �ϗp�N��
      ln_life_years  := TRUNC(g_fa_tab(in_rec_no).life_in_months / cn_months);
      -- �ϗp����
      ln_life_months := MOD(g_fa_tab(in_rec_no).life_in_months, cn_months);
--
      -- ===============================
      -- IFRS���ڃZ�b�g
      -- ===============================
      -- �J�e�S��DFF15(IFRS�ϗp�N��)
      IF ( g_upload_tab(in_rec_no).ifrs_life_in_months IS NOT NULL ) THEN
        lt_cat_attribute15 := g_upload_tab(in_rec_no).ifrs_life_in_months;
      ELSE
        lt_cat_attribute15 := g_fa_tab(in_rec_no).cat_attribute15;
      END IF;
--
      -- �J�e�S��DFF16(IFRS���p)
      IF ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NOT NULL ) THEN
        lt_cat_attribute16 := g_upload_tab(in_rec_no).ifrs_cat_deprn_method;
      ELSE
        lt_cat_attribute16 := g_fa_tab(in_rec_no).cat_attribute16;
      END IF;
--
      -- �J�e�S��DFF17(�s���Y�擾��)
      IF ( g_upload_tab(in_rec_no).real_estate_acq_tax IS NOT NULL ) THEN
        lt_cat_attribute17 := g_upload_tab(in_rec_no).real_estate_acq_tax;
      ELSE
        lt_cat_attribute17 := g_fa_tab(in_rec_no).cat_attribute17;
      END IF;
--
      -- �J�e�S��DFF18(�ؓ��R�X�g)
      IF ( g_upload_tab(in_rec_no).borrowing_cost IS NOT NULL ) THEN
        lt_cat_attribute18 := g_upload_tab(in_rec_no).borrowing_cost;
      ELSE
        lt_cat_attribute18 := g_fa_tab(in_rec_no).cat_attribute18;
      END IF;
--
      -- �J�e�S��DFF19(���̑�)
      IF ( g_upload_tab(in_rec_no).other_cost IS NOT NULL ) THEN
        lt_cat_attribute19 := g_upload_tab(in_rec_no).other_cost;
      ELSE
        lt_cat_attribute19 := g_fa_tab(in_rec_no).cat_attribute19;
      END IF;
--
      -- �J�e�S��DFF20(IFRS���Y�Ȗ�)
      IF ( g_upload_tab(in_rec_no).ifrs_asset_account IS NOT NULL ) THEN
        lt_cat_attribute20 := g_upload_tab(in_rec_no).ifrs_asset_account;
      ELSE
        lt_cat_attribute20 := g_fa_tab(in_rec_no).cat_attribute20;
      END IF;
--
      -- ****************************
      -- �C��OIF�o�^
      -- ****************************
      BEGIN
        INSERT INTO xx01_adjustment_oif(
           adjustment_oif_id               -- ID
          ,book_type_code                  -- �䒠��
          ,asset_number_old                -- ���Y�ԍ�
          ,dpis_old                        -- ���Ƌ��p���i�C���O�j
          ,category_id_old                 -- ���Y�J�e�S��ID�i�C���O�j
          ,cat_attribute_category_old      -- ���Y�J�e�S���R�[�h�i�C���O�j
          ,dpis_new                        -- ���Ƌ��p���i�C����j
          ,description                     -- �E�v�i�C����j
          ,transaction_units               -- �P��
          ,cost                            -- �擾���z
          ,original_cost                   -- �����擾���z
          ,posting_flag                    -- �]�L�`�F�b�N�t���O
          ,status                          -- �X�e�[�^�X
          ,asset_number_new                -- ���Y�ԍ��i�C����j
          ,tag_number                      -- ���i�[�ԍ�
          ,category_id_new                 -- ���Y�J�e�S��ID�i�C����j
          ,serial_number                   -- �V���A���ԍ�
          ,asset_key_ccid                  -- ���Y�L�[CCID
          ,key_segment1                    -- ���Y�L�[�Z�O�����g1
          ,key_segment2                    -- ���Y�L�[�Z�O�����g2
          ,parent_asset_id                 -- �e���YID
          ,lease_id                        -- ���[�XID
          ,model_number                    -- ���f��
          ,in_use_flag                     -- �g�p��
          ,inventorial                     -- ���n�I���t���O
          ,owned_leased                    -- ���L��
          ,new_used                        -- �V�i/����
          ,cat_attribute1                  -- �J�e�S��DFF1
          ,cat_attribute2                  -- �J�e�S��DFF2
          ,cat_attribute3                  -- �J�e�S��DFF3
          ,cat_attribute4                  -- �J�e�S��DFF4
          ,cat_attribute5                  -- �J�e�S��DFF5
          ,cat_attribute6                  -- �J�e�S��DFF6
          ,cat_attribute7                  -- �J�e�S��DFF7
          ,cat_attribute8                  -- �J�e�S��DFF8
          ,cat_attribute9                  -- �J�e�S��DFF9
          ,cat_attribute10                 -- �J�e�S��DFF10
          ,cat_attribute11                 -- �J�e�S��DFF11
          ,cat_attribute12                 -- �J�e�S��DFF12
          ,cat_attribute13                 -- �J�e�S��DFF13
          ,cat_attribute14                 -- �J�e�S��DFF14
          ,cat_attribute15                 -- �J�e�S��DFF15
          ,cat_attribute16                 -- �J�e�S��DFF16
          ,cat_attribute17                 -- �J�e�S��DFF17
          ,cat_attribute18                 -- �J�e�S��DFF18
          ,cat_attribute19                 -- �J�e�S��DFF19
          ,cat_attribute20                 -- �J�e�S��DFF20
          ,cat_attribute21                 -- �J�e�S��DFF21
          ,cat_attribute22                 -- �J�e�S��DFF22
          ,cat_attribute23                 -- �J�e�S��DFF23
          ,cat_attribute24                 -- �J�e�S��DFF24
          ,cat_attribute25                 -- �J�e�S��DFF27
          ,cat_attribute26                 -- �J�e�S��DFF25
          ,cat_attribute27                 -- �J�e�S��DFF26
          ,cat_attribute28                 -- �J�e�S��DFF28
          ,cat_attribute29                 -- �J�e�S��DFF29
          ,cat_attribute30                 -- �J�e�S��DFF30
          ,cat_attribute_category_new      -- ���Y�J�e�S���R�[�h�i�C����j
          ,salvage_value                   -- �c�����z
          ,percent_salvage_value           -- �c�����z%
          ,allowed_deprn_limit_amount      -- ���p���x�z
          ,allowed_deprn_limit             -- ���p���x��
          ,ytd_deprn                       -- �N���p�݌v�z
          ,deprn_reserve                   -- ���p�݌v�z
          ,depreciate_flag                 -- ���p��v��t���O
          ,deprn_method_code               -- ���p���@
          ,basic_rate                      -- ���ʏ��p��
          ,adjusted_rate                   -- �����㏞�p��
          ,life_years                      -- �ϗp�N��
          ,life_months                     -- �ϗp����
          ,bonus_rule                      -- �{�[�i�X���[��
          ,bonus_ytd_deprn                 -- �{�[�i�X�N���p�݌v�z
          ,bonus_deprn_reserve             -- �{�[�i�X���p�݌v�z
          ,created_by                      -- �쐬��
          ,creation_date                   -- �쐬��
          ,last_updated_by                 -- �ŏI�X�V��
          ,last_update_date                -- �ŏI�X�V��
          ,last_update_login               -- �ŏI�X�V���O�C��ID
          ,request_id                      -- �v��ID
          ,program_application_id          -- �A�v���P�[�V����ID
          ,program_id                      -- �v���O����ID
          ,program_update_date             -- �v���O�����ŏI�X�V��
        )
        VALUES (
           xx01_adjustment_oif_s.NEXTVAL                                    -- ID
          ,gv_fixed_asset_register                                          -- �䒠��
          ,g_fa_tab(in_rec_no).asset_number_old                             -- ���Y�ԍ��i�C���O�j
          ,g_fa_tab(in_rec_no).dpis_old                                     -- ���Ƌ��p���i�C���O�j
          ,g_fa_tab(in_rec_no).category_id_old                              -- ���Y�J�e�S��ID�i�C���O�j
          ,g_fa_tab(in_rec_no).cat_attribute_category_old                   -- ���Y�J�e�S���R�[�h�i�C���O�j
          ,g_fa_tab(in_rec_no).dpis_old                                     -- ���Ƌ��p���i�C���O�j
          ,g_fa_tab(in_rec_no).description                                  -- �E�v�i�C����j
          ,g_fa_tab(in_rec_no).transaction_units                            -- �P��
          ,g_fa_tab(in_rec_no).cost                                         -- �擾���z
          ,g_fa_tab(in_rec_no).original_cost                                -- �����擾���z
          ,cv_yes                                                           -- �]�L�`�F�b�N�t���O
          ,cv_status                                                        -- �X�e�[�^�X
          ,g_fa_tab(in_rec_no).asset_number_new                             -- ���Y�ԍ��i�C����j
          ,g_fa_tab(in_rec_no).tag_number                                   -- ���i�[�ԍ�
          ,g_fa_tab(in_rec_no).category_id_new                              -- ���Y�J�e�S��ID�i�C����j
          ,g_fa_tab(in_rec_no).serial_number                                -- �V���A���ԍ�
          ,g_fa_tab(in_rec_no).asset_key_ccid                               -- ���Y�L�[CCID
          ,g_fa_tab(in_rec_no).key_segment1                                 -- ���Y�L�[�Z�O�����g1
          ,g_fa_tab(in_rec_no).key_segment2                                 -- ���Y�L�[�Z�O�����g2
          ,g_fa_tab(in_rec_no).parent_asset_id                              -- �e���YID
          ,g_fa_tab(in_rec_no).lease_id                                     -- ���[�XID
          ,g_fa_tab(in_rec_no).model_number                                 -- ���f��
          ,g_fa_tab(in_rec_no).in_use_flag                                  -- �g�p��
          ,g_fa_tab(in_rec_no).inventorial                                  -- ���n�I���t���O
          ,g_fa_tab(in_rec_no).owned_leased                                 -- ���L��
          ,g_fa_tab(in_rec_no).new_used                                     -- �V�i/����
          ,g_fa_tab(in_rec_no).cat_attribute1                               -- �J�e�S��DFF1
          ,g_fa_tab(in_rec_no).cat_attribute2                               -- �J�e�S��DFF2
          ,g_fa_tab(in_rec_no).cat_attribute3                               -- �J�e�S��DFF3
          ,g_fa_tab(in_rec_no).cat_attribute4                               -- �J�e�S��DFF4
          ,g_fa_tab(in_rec_no).cat_attribute5                               -- �J�e�S��DFF5
          ,g_fa_tab(in_rec_no).cat_attribute6                               -- �J�e�S��DFF6
          ,g_fa_tab(in_rec_no).cat_attribute7                               -- �J�e�S��DFF7
          ,g_fa_tab(in_rec_no).cat_attribute8                               -- �J�e�S��DFF8
          ,g_fa_tab(in_rec_no).cat_attribute9                               -- �J�e�S��DFF9
          ,g_fa_tab(in_rec_no).cat_attribute10                              -- �J�e�S��DFF10
          ,g_fa_tab(in_rec_no).cat_attribute11                              -- �J�e�S��DFF11
          ,g_fa_tab(in_rec_no).cat_attribute12                              -- �J�e�S��DFF12
          ,g_fa_tab(in_rec_no).cat_attribute13                              -- �J�e�S��DFF13
          ,g_fa_tab(in_rec_no).cat_attribute14                              -- �J�e�S��DFF14
          ,lt_cat_attribute15                                               -- IFRS�ϗp�N���iDFF15�j
          ,lt_cat_attribute16                                               -- IFRS���p�iDFF16�j
          ,lt_cat_attribute17                                               -- �s���Y�擾�ŁiDFF17�j
          ,lt_cat_attribute18                                               -- �ؓ��R�X�g�iDFF18�j
          ,lt_cat_attribute19                                               -- ���̑��iDFF19�j
          ,lt_cat_attribute20                                               -- IFRS���Y�ȖځiDFF20�j
          ,TO_CHAR(g_upload_tab(in_rec_no).correct_date ,cv_date_fmt_std)   -- �C���N�����iDFF21�j
          ,g_fa_tab(in_rec_no).cat_attribute22                              -- �J�e�S��DFF22
          ,g_fa_tab(in_rec_no).cat_attribute23                              -- �J�e�S��DFF23
          ,g_fa_tab(in_rec_no).cat_attribute24                              -- �J�e�S��DFF24
          ,g_fa_tab(in_rec_no).cat_attribute25                              -- �J�e�S��DFF27
          ,g_fa_tab(in_rec_no).cat_attribute26                              -- �J�e�S��DFF25
          ,g_fa_tab(in_rec_no).cat_attribute27                              -- �J�e�S��DFF26
          ,g_fa_tab(in_rec_no).cat_attribute28                              -- �J�e�S��DFF28
          ,g_fa_tab(in_rec_no).cat_attribute29                              -- �J�e�S��DFF29
          ,g_fa_tab(in_rec_no).cat_attribute30                              -- �J�e�S��DFF30
          ,g_fa_tab(in_rec_no).cat_attribute_category_new                   -- ���Y�J�e�S���R�[�h�i�C����j
          ,g_fa_tab(in_rec_no).salvage_value                                -- �c�����z
          ,g_fa_tab(in_rec_no).percent_salvage_value                        -- �c�����z%
          ,g_fa_tab(in_rec_no).allowed_deprn_limit_amount                   -- ���p���x�z
          ,g_fa_tab(in_rec_no).allowed_deprn_limit                          -- ���p���x��
          ,g_fa_tab(in_rec_no).ytd_deprn                                    -- �N���p�݌v�z
          ,g_fa_tab(in_rec_no).deprn_reserve                                -- ���p�݌v�z
          ,g_fa_tab(in_rec_no).depreciate_flag                              -- ���p��v��t���O
          ,g_fa_tab(in_rec_no).deprn_method_code                            -- ���p���@
          ,g_fa_tab(in_rec_no).basic_rate                                   -- ���ʏ��p��
          ,g_fa_tab(in_rec_no).adjusted_rate                                -- �����㏞�p��
          ,ln_life_years                                                    -- �ϗp�N��
          ,ln_life_months                                                   -- �ϗp����
          ,g_fa_tab(in_rec_no).bonus_rule                                   -- �{�[�i�X���[��
          ,g_fa_tab(in_rec_no).bonus_ytd_deprn                              -- �{�[�i�X�N���p�݌v�z
          ,g_fa_tab(in_rec_no).bonus_deprn_reserve                          -- �{�[�i�X���p�݌v�z
          ,cn_created_by                                                    -- �쐬��
          ,cd_creation_date                                                 -- �쐬��
          ,cn_last_updated_by                                               -- �ŏI�X�V��
          ,cd_last_update_date                                              -- �ŏI�X�V��
          ,cn_last_update_login                                             -- �ŏI�X�V���O�C��ID
          ,cn_request_id                                                    -- �v��ID
          ,cn_program_application_id                                        -- �A�v���P�[�V����ID
          ,cn_program_id                                                    -- �v���O����ID
          ,cd_program_update_date                                           -- �v���O�����ŏI�X�V��
        )
        ;
        EXCEPTION
          WHEN OTHERS THEN
            -- �o�^�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff           -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_name_00102        -- ���b�Z�[�W
                           ,iv_token_name1  => cv_tkn_table_name        -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_val_50320         -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_info              -- �g�[�N���R�[�h2
                           ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
      -- �C��OIF�o�^�����J�E���g
      gn_adj_normal_cnt := gn_adj_normal_cnt + 1;
--
    END IF;
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
  END insert_adj_oif;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER       -- 1.�t�@�C��ID
   ,iv_file_format  IN   VARCHAR2     -- 2.�t�@�C���t�H�[�}�b�g
   ,ov_errbuf       OUT  VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode      OUT  VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg       OUT  VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_loop_cnt_1  NUMBER;   -- ���[�v�J�E���^1
    ln_loop_cnt_2  NUMBER;   -- ���[�v�J�E���^2
    ln_loop_cnt_3  NUMBER;   -- ���[�v�J�E���^3
    ln_line_no     NUMBER;   -- �s�ԍ��J�E���^(�^�C�g���s���܂܂Ȃ��J�E���^)
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
    gn_target_cnt      := 0;
    gn_normal_cnt      := 0;
    gn_error_cnt       := 0;
    gn_warn_cnt        := 0;
--
    gn_add_target_cnt  := 0;
    gn_add_normal_cnt  := 0;
    gn_add_error_cnt   := 0;
    gn_adj_target_cnt  := 0;
    gn_adj_normal_cnt  := 0;
    gn_adj_error_cnt   := 0;
    gb_err_flag        := FALSE;
    -- ���[�J���ϐ��̏�����
    ln_loop_cnt_1      := 0;
    ln_loop_cnt_2      := 0;
    ln_loop_cnt_3      := 0;
    ln_line_no         := 0;
    ln_error_cnt       := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ============================================
    -- ��������(A-1)
    -- ============================================
    init(
       in_file_id        -- 1.�t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �Ó����`�F�b�N�p�̒l�擾(A-2)
    -- ============================================
    get_for_validation(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-3)
    -- ============================================
    get_upload_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --���C�����[�v�@
    <<main_loop_1>>
    FOR ln_loop_cnt_1 IN g_if_data_tab.FIRST .. g_if_data_tab.LAST LOOP
--
      -- �G���[�t���O������
      gb_err_flag := FALSE;
--
      --�P�s�ڂ̓J�����s�̂��߃X�L�b�v
      IF ( ln_loop_cnt_1 <> 1 ) THEN
        -- �s�ԍ��̃J�E���g
        ln_line_no := ln_line_no + 1;
        --���C�����[�v�A�J�E���^�̃��Z�b�g
        ln_loop_cnt_2 := 0;
--
        --���C�����[�v�A
        <<main_loop_2>>
        FOR ln_loop_cnt_2 IN g_column_desc_tab.FIRST .. g_column_desc_tab.LAST LOOP
          -- ============================================
          -- �f���~�^�������ڕ���(A-4)
          -- ============================================
          divide_item(
             ln_loop_cnt_1     -- ���[�v�J�E���^1
            ,ln_loop_cnt_2     -- ���[�v�J�E���^2
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- ���ڒl�`�F�b�N(A-5)
          -- ============================================
          check_item_value(
             ln_line_no        -- �s�ԍ��J�E���^
            ,ln_loop_cnt_2     -- ���[�v�J�E���^2
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END LOOP main_loop_2;
--
        -- ���ڒl�`�F�b�N�ŃG���[�����������ꍇ�́AA-6�X�L�b�v
        IF ( gb_err_flag ) THEN
          -- �G���[�������J�E���g
          ln_error_cnt := ln_error_cnt + 1;
        ELSE
          -- ============================================
          -- �Œ莑�Y�A�b�v���[�h���[�N�쐬(A-6)
          -- ============================================
          ins_upload_wk(
             ln_line_no        -- �s�ԍ��J�E���^
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop_1;
--
    -- 1���ł��G���[�����݂���ꍇ�͏������I������
    IF ( ln_error_cnt <> 0 ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �Œ莑�Y�A�b�v���[�h���[�N�擾(A-7)
    -- ============================================
    get_upload_wk(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- A-7�Ŏ擾������1���ȏ�̏ꍇ
    IF ( g_upload_tab.COUNT <> 0 ) THEN
--
      -- ���C�����[�v�B
      <<main_loop_3>>
      FOR ln_loop_cnt_3 IN g_upload_tab.FIRST .. g_upload_tab.LAST LOOP
--
        -- �G���[�t���O�̏�����
        gb_err_flag := FALSE;
--
        -- ============================================
        -- �f�[�^�Ó����`�F�b�N(A-8)
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
        -- �`�F�b�N�G���[���Ȃ��ꍇ�͏������p��
        ELSE
          -- ============================================
          -- �ǉ�OIF�o�^(A-9)
          -- ============================================
          insert_add_oif(
             ln_loop_cnt_3     -- ���[�v�J�E���^3�i�Ώۃ��R�[�h�ԍ��j
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          -- �G���[�����������ꍇ�A�G���[�������J�E���g
          IF ( gb_err_flag ) THEN
            ln_error_cnt := ln_error_cnt + 1;
          END IF;
--
          -- ============================================
          -- �C��OIF�o�^(A-10)
          -- ============================================
          insert_adj_oif(
             ln_loop_cnt_3     -- ���[�v�J�E���^3�i�Ώۃ��R�[�h�ԍ��j
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
      END LOOP main_loop_3;
--
      -- 1���ł��G���[�����݂���ꍇ�̓G���[�I��
      IF ( ln_error_cnt <> 0 ) THEN
        ov_retcode := cv_status_error;
      END IF;
--
    ELSE
      -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�́A�Ώۃf�[�^�Ȃ����b�Z�[�W��\��
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cff       -- �A�v���P�[�V�����Z�k��
                     ,iv_name        => cv_msg_name_00062    -- ���b�Z�[�W�R�[�h
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      ov_retcode := cv_status_error;
    END IF;
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
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT   VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    in_file_id       IN    NUMBER,          --   1.�t�@�C��ID
    iv_file_format   IN    VARCHAR2         --   2.�t�@�C���t�H�[�}�b�g
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
    -- �G���[�o��
    IF (lv_retcode = cv_status_error) THEN
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- �ǉ�OIF�o�^�ɂ����錏��
      gn_add_target_cnt := 0;  -- �Ώی���
      gn_add_normal_cnt := 0;  -- ���팏��
      gn_add_error_cnt  := 1;  -- �G���[����
      -- �C��OIF�o�^�ɂ����錏��
      gn_adj_target_cnt := 0;  -- �Ώی���
      gn_adj_normal_cnt := 0;  -- ���팏��
      gn_adj_error_cnt  := 1;  -- �G���[����
--
    END IF;
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ����ȊO�̏ꍇ�A���[���o�b�N�𔭍s
      ROLLBACK;
    ELSE
      -- ============================================
      -- �Ώۃf�[�^�폜(A-11)
      -- ============================================
      -- �Œ莑�Y�A�b�v���[�h���[�N�폜
      DELETE FROM
        xxcff_fa_upload_work xfuw
      WHERE
        xfuw.file_id = in_file_id
      ;
--
      -- �t�@�C���A�b�v���[�hI/F�e�[�u���폜
      DELETE FROM
        xxccp_mrp_file_ul_interface xmfui
      WHERE
        xmfui.file_id = in_file_id
      ;
    END IF;
--
    -- �e�[�u���폜��̃R�~�b�g
    IF ( lv_retcode <> cv_status_normal ) THEN
      COMMIT;
    END IF;
--
    --===============================================================
    --�ǉ�OIF�o�^�ɂ����錏���o��
    --===============================================================
    -- �ǉ�OIF�o�^���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff               -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_name_00266            -- ���b�Z�[�W
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- ���b�Z�[�W�o��
      ,buff   => gv_out_msg
    );
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_target_rec_msg            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_cnt_token                 -- �g�[�N���R�[�h1
                    ,iv_token_value1 => TO_CHAR(gn_add_target_cnt)   -- �g�[�N���l1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- ���b�Z�[�W�o��
      ,buff   => gv_out_msg
    );
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_success_rec_msg           -- ���b�Z�[�W
                    ,iv_token_name1  => cv_cnt_token                 -- �g�[�N���R�[�h1
                    ,iv_token_value1 => TO_CHAR(gn_add_normal_cnt)   -- �g�[�N���l1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- ���b�Z�[�W�o��
      ,buff   => gv_out_msg
    );
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_error_rec_msg             -- ���b�Z�[�W
                    ,iv_token_name1  => cv_cnt_token                 -- �g�[�N���R�[�h1
                    ,iv_token_value1 => TO_CHAR(gn_add_error_cnt)    -- �g�[�N���l1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- ���b�Z�[�W�o��
      ,buff   => gv_out_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --�C��OIF�o�^�ɂ����錏���o��
    --===============================================================
    -- �C��OIF�o�^���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff               -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_name_00267            -- ���b�Z�[�W
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- ���b�Z�[�W�o��
      ,buff   => gv_out_msg
    );
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_target_rec_msg            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_cnt_token                 -- �g�[�N���R�[�h1
                    ,iv_token_value1 => TO_CHAR(gn_adj_target_cnt)   -- �g�[�N���l1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- ���b�Z�[�W�o��
      ,buff   => gv_out_msg
    );
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_success_rec_msg           -- ���b�Z�[�W
                    ,iv_token_name1  => cv_cnt_token                 -- �g�[�N���R�[�h1
                    ,iv_token_value1 => TO_CHAR(gn_adj_normal_cnt)   -- �g�[�N���l1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- ���b�Z�[�W�o��
      ,buff   => gv_out_msg
    );
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_error_rec_msg             -- ���b�Z�[�W
                    ,iv_token_name1  => cv_cnt_token                 -- �g�[�N���R�[�h1
                    ,iv_token_value1 => TO_CHAR(gn_adj_error_cnt)    -- �g�[�N���l1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- ���b�Z�[�W�o��
      ,buff   => gv_out_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- �I�����b�Z�[�W�̐ݒ�A�o��
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp           -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => lv_message_code          -- ���b�Z�[�W
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG     -- ���O�o��
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- ���b�Z�[�W�o��
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
END XXCFF019A01C;
/