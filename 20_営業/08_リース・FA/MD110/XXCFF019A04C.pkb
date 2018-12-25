CREATE OR REPLACE PACKAGE BODY XXCFF019A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A04C(body)
 * Description      : IFRS�䒠�C��
 * MD.050           : MD050_CFF_019_A04_IFRS�䒠�C��
 * Version          : 1.2
 *
 * Program List
 * ----------------------------- ----------------------------------------------------------
 *  Name                          Description
 * ----------------------------- ----------------------------------------------------------
 *  init                          ��������                                  (A-1)
 *  get_profile_values            �v���t�@�C���擾                          (A-2)
 *  chk_period                    ��v���ԃ`�F�b�N                          (A-3)
 *  get_exec_date                 �O����s�����擾                          (A-4)
 *  get_ifrs_adj_data             IFRS�䒠�C���f�[�^���o�E�o�^              (A-5)
 *  upd_exec_date                 ���s�����X�V                              (A-6)
 *  submain                       ���C�������v���V�[�W��
 *  main                          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/11/30    1.0   SCSK���H         �V�K�쐬
 *  2018/04/27    1.1   SCSK�X           E_�{�ғ�_15041�Ή�
 *  2018/12/14    1.2   SCSK���H         E_�{�ғ�_15399�Ή�
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
  --*** ��v���ԃ`�F�b�N�G���[
  chk_period_expt           EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  data_lock_expt            EXCEPTION;        -- ���R�[�h���b�N�G���[
  PRAGMA EXCEPTION_INIT(data_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100):= 'XXCFF019A04C'; -- �p�b�P�[�W��
--
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff            CONSTANT VARCHAR2(5)  := 'XXCFF';
--
  -- ***���b�Z�[�W��(�{��)
  cv_msg_cff_00007          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; -- ���b�N�G���[
  cv_msg_cff_00020          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- �v���t�@�C���擾�G���[
  cv_msg_cff_00037          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; -- ��v���ԃ`�F�b�N�G���[
  cv_msg_cff_00165          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- �擾�Ώۃf�[�^�������b�Z�[�W
  cv_msg_cff_00267          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00267'; -- �C��OIF�o�^���b�Z�[�W
  cv_msg_cff_00275          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00275'; -- IFRS�䒠�C���o�^�G���[
  cv_msg_cff_00276          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00276'; -- IFRS�䒠�C���X�L�b�v���b�Z�[�W
  cv_msg_cff_00281          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00281'; -- ���p���@�擾�G���[
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_msg_cff_50097          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50097'; -- ���p���@
  cv_msg_cff_50228          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50228'; -- XXCFF:�䒠���_�Œ莑�Y�䒠
  cv_msg_cff_50236          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50236'; -- �Œ莑�Y�i�C���j���
  cv_msg_cff_50314          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50314'; -- XXCFF:�䒠���_IFRS�䒠
  cv_msg_cff_50316          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50316'; -- IFRS�䒠�A�g�Z�b�g
--
  -- ***�g�[�N����
  cv_tkn_prof               CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_asset_number1      CONSTANT VARCHAR2(20) := 'ASSET_NUMBER1';
  cv_tkn_asset_number2      CONSTANT VARCHAR2(20) := 'ASSET_NUMBER2';
  cv_tkn_bk_type            CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period             CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_get_data           CONSTANT VARCHAR2(20) := 'GET_DATA';
  cv_tkn_table_name         CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_category           CONSTANT VARCHAR2(20) := 'CATEGORY';
--
  -- ***�v���t�@�C��
  cv_fixed_asset_register   CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER';       -- �䒠���_�Œ莑�Y�䒠
  cv_fixed_ifrs_asset_regi  CONSTANT VARCHAR2(35) := 'XXCFF1_FIXED_IFRS_ASSET_REGISTER';  -- �䒠���_IFRS�䒠
--
  -- ***�t�@�C���o��
  cv_file_type_out          CONSTANT VARCHAR2(10) := 'OUTPUT'; -- ���b�Z�[�W�o��
  cv_file_type_log          CONSTANT VARCHAR2(10) := 'LOG';    -- ���O�o��
--
  cv_yes                    CONSTANT VARCHAR2(1)  := 'Y';
-- 2018/12/14 1.2 ADD Y.Shoji START
  cv_no                     CONSTANT VARCHAR2(1)  := 'N';
-- 2018/12/14 1.2 ADD Y.Shoji END
  cv_space                  CONSTANT VARCHAR2(1)  := ' ';      -- �X�y�[�X
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  -- IFRS�䒠�C���Ώۃf�[�^���R�[�h�^
  TYPE g_ifrs_adj_rtype IS RECORD(
     asset_id                      fa_additions_b.asset_id%TYPE                  -- ���YID
    ,asset_number_fixed            fa_additions_b.asset_number%TYPE              -- ���Y�ԍ��i�Œ莑�Y�䒠�j
    ,asset_number_ifrs             fa_additions_b.asset_number%TYPE              -- ���Y�ԍ��iIFRS�䒠�j
    ,date_placed_in_service_ifrs   fa_books.date_placed_in_service%TYPE          -- ���Ƌ��p���iIFRS�䒠�j
    ,asset_category_id_ifrs        fa_additions_b.asset_category_id%TYPE         -- ���Y�J�e�S��ID�iIFRS�䒠�j
    ,category_code_ifrs            fa_additions_b.attribute_category_code%TYPE   -- ���Y�J�e�S���R�[�h�iIFRS�䒠�j
    ,date_placed_in_service_fixed  fa_books.date_placed_in_service%TYPE          -- ���Ƌ��p���i�Œ莑�Y�䒠�j
    ,description_fixed             fa_additions_tl.description%TYPE              -- �E�v�i�Œ莑�Y�䒠�j
    ,description_ifrs              fa_additions_tl.description%TYPE              -- �E�v�iIFRS�䒠�j
    ,current_units                 fa_additions_b.current_units%TYPE             -- �P��
    ,cost_fixed                    fa_books.cost%TYPE                            -- �擾���z�i�Œ莑�Y�䒠�j
    ,cost_ifrs                     fa_books.cost%TYPE                            -- �擾���z�iIFRS�䒠�j
    ,original_cost                 fa_books.original_cost%TYPE                   -- �����擾���z
    ,tag_number                    fa_additions_b.tag_number%TYPE                -- ���i�[�ԍ�
    ,serial_number                 fa_additions_b.serial_number%TYPE             -- �V���A���ԍ�
    ,asset_key_ccid                fa_additions_b.asset_key_ccid%TYPE            -- ���Y�L�[CCID
    ,key_segment1                  fa_asset_keywords.segment1%TYPE               -- ���Y�L�[�Z�O�����g1
    ,key_segment2                  fa_asset_keywords.segment2%TYPE               -- ���Y�L�[�Z�O�����g2
    ,parent_asset_id               fa_additions_b.parent_asset_id%TYPE           -- �e���YID
    ,lease_id                      fa_additions_b.lease_id%TYPE                  -- ���[�XID
    ,model_number                  fa_additions_b.model_number%TYPE              -- ���f��
    ,in_use_flag                   fa_additions_b.in_use_flag%TYPE               -- �g�p��
    ,inventorial                   fa_additions_b.inventorial%TYPE               -- ���n�I���t���O
    ,owned_leased                  fa_additions_b.owned_leased%TYPE              -- ���L��
    ,new_used                      fa_additions_b.new_used%TYPE                  -- �V�i/����
    ,attribute1                    fa_additions_b.attribute1%TYPE                -- �J�e�S��DFF1
    ,attribute2_ifrs               fa_additions_b.attribute2%TYPE                -- �擾���iIFRS�䒠�j
    ,attribute3                    fa_additions_b.attribute3%TYPE                -- �J�e�S��DFF3
    ,attribute4                    fa_additions_b.attribute4%TYPE                -- �J�e�S��DFF4
    ,attribute5                    fa_additions_b.attribute5%TYPE                -- �J�e�S��DFF5
    ,attribute6                    fa_additions_b.attribute6%TYPE                -- �J�e�S��DFF6
    ,attribute7                    fa_additions_b.attribute7%TYPE                -- �J�e�S��DFF7
    ,attribute8                    fa_additions_b.attribute8%TYPE                -- �J�e�S��DFF8
    ,attribute9                    fa_additions_b.attribute9%TYPE                -- �J�e�S��DFF9
    ,attribute10                   fa_additions_b.attribute10%TYPE               -- �J�e�S��DFF10
    ,attribute11                   fa_additions_b.attribute11%TYPE               -- �J�e�S��DFF11
    ,attribute12                   fa_additions_b.attribute12%TYPE               -- �J�e�S��DFF12
    ,attribute13                   fa_additions_b.attribute13%TYPE               -- �J�e�S��DFF13
    ,attribute14                   fa_additions_b.attribute14%TYPE               -- �J�e�S��DFF14
    ,attribute15_ifrs              fa_additions_b.attribute15%TYPE               -- IFRS�ϗp�N���iIFRS�䒠�j
    ,attribute16_ifrs              fa_additions_b.attribute16%TYPE               -- IFRS���p�iIFRS�䒠�j
    ,attribute17_ifrs              fa_additions_b.attribute17%TYPE               -- �s���Y�擾�ŁiIFRS�䒠�j
    ,attribute18_ifrs              fa_additions_b.attribute18%TYPE               -- �ؓ��R�X�g�iIFRS�䒠�j
    ,attribute19_ifrs              fa_additions_b.attribute19%TYPE               -- ���̑��iIFRS�䒠�j
    ,attribute20_ifrs              fa_additions_b.attribute20%TYPE               -- IFRS���Y�ȖځiIFRS�䒠�j
    ,attribute21_ifrs              fa_additions_b.attribute21%TYPE               -- �C���N�����iIFRS�䒠�j
    ,attribute22                   fa_additions_b.attribute22%TYPE               -- �J�e�S��DFF22
    ,attribute23                   fa_additions_b.attribute23%TYPE               -- �J�e�S��DFF23
    ,attribute24                   fa_additions_b.attribute24%TYPE               -- �J�e�S��DFF24
    ,attribute25                   fa_additions_b.attribute25%TYPE               -- �J�e�S��DFF27
    ,attribute26                   fa_additions_b.attribute26%TYPE               -- �J�e�S��DFF25
    ,attribute27                   fa_additions_b.attribute27%TYPE               -- �J�e�S��DFF26
    ,attribute28                   fa_additions_b.attribute28%TYPE               -- �J�e�S��DFF28
    ,attribute29                   fa_additions_b.attribute29%TYPE               -- �J�e�S��DFF29
    ,attribute30                   fa_additions_b.attribute30%TYPE               -- �J�e�S��DFF30
    ,salvage_value                 fa_books.salvage_value%TYPE                   -- �c�����z
    ,percent_salvage_value         fa_books.percent_salvage_value%TYPE           -- �c�����z%
    ,allowed_deprn_limit_amount    fa_books.allowed_deprn_limit_amount%TYPE      -- ���p���x�z
    ,allowed_deprn_limit           fa_books.allowed_deprn_limit%TYPE             -- ���p���x��
    ,depreciate_flag               fa_books.depreciate_flag%TYPE                 -- ���p��v��t���O
    ,deprn_method_code             fa_books.deprn_method_code%TYPE               -- ���p���@
    ,basic_rate                    fa_books.basic_rate%TYPE                      -- ���ʏ��p��
    ,adjusted_rate                 fa_books.adjusted_rate%TYPE                   -- �����㏞�p��
    ,life_in_months                fa_books.life_in_months%TYPE                  -- �ϗp�N��+����
    ,bonus_rule                    fa_books.bonus_rule%TYPE                      -- �{�[�i�X���[��
    ,cat_segment1                  fa_categories.segment1%TYPE                   -- ���Y�J�e�S��-��ށiIFRS�䒠�j
    ,cat_segment2                  fa_categories.segment2%TYPE                   -- ���Y�J�e�S��-�\�����p�iIFRS�䒠�j
    ,cat_segment3                  fa_categories.segment3%TYPE                   -- ���Y�J�e�S��-���Y����iIFRS�䒠�j
    ,cat_segment4                  fa_categories.segment4%TYPE                   -- ���Y�J�e�S��-���p�ȖځiIFRS�䒠�j
    ,cat_segment5                  fa_categories.segment5%TYPE                   -- ���Y�J�e�S��-�ϗp�N���iIFRS�䒠�j
    ,cat_segment6                  fa_categories.segment6%TYPE                   -- ���Y�J�e�S��-���p���@�iIFRS�䒠�j
    ,cat_segment7                  fa_categories.segment7%TYPE                   -- ���Y�J�e�S��-���[�X��ʁiIFRS�䒠�j
    ,attribute2_fixed              fa_additions_b.attribute2%TYPE                -- �擾���i�Œ莑�Y�䒠�j
    ,attribute15_fixed             fa_additions_b.attribute15%TYPE               -- IFRS�ϗp�N���i�Œ莑�Y�䒠�j
    ,attribute16_fixed             fa_additions_b.attribute16%TYPE               -- IFRS���p�i�Œ莑�Y�䒠�j
    ,attribute17_fixed             fa_additions_b.attribute17%TYPE               -- �s���Y�擾�Łi�Œ莑�Y�䒠�j
    ,attribute18_fixed             fa_additions_b.attribute18%TYPE               -- �ؓ��R�X�g�i�Œ莑�Y�䒠�j
    ,attribute19_fixed             fa_additions_b.attribute19%TYPE               -- ���̑��i�Œ莑�Y�䒠�j
    ,attribute20_fixed             fa_additions_b.attribute20%TYPE               -- IFRS���Y�Ȗځi�Œ莑�Y�䒠�j
    ,attribute21_fixed             fa_additions_b.attribute21%TYPE               -- �C���N�����i�Œ莑�Y�䒠�j
-- 2018/12/14 1.2 ADD Y.Shoji START
    ,amortized_flag                xx01_adjustment_oif.amortized_flag%TYPE             -- �C���z���p�t���O
    ,amortization_start_date       fa_transaction_headers.amortization_start_date%TYPE -- ���p�J�n��
-- 2018/12/14 1.2 ADD Y.Shoji END
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  -- IFRS�䒠�C���Ώۃf�[�^���R�[�h�z��
  TYPE g_ifrs_adj_ttype IS TABLE OF g_ifrs_adj_rtype
  INDEX BY BINARY_INTEGER;
--
  g_ifrs_adj_tab            g_ifrs_adj_ttype;  -- IFRS�䒠�C���Ώۃf�[�^
--
  -- �p�����[�^��v���Ԗ�
  gv_period_name            VARCHAR2(100);
--
  -- �O����s����
  gt_exec_date              xxcff_ifrs_sets.exec_date%TYPE;
--
  -- ***�v���t�@�C���l
  gv_fixed_asset_register   VARCHAR2(100);  -- �䒠���_�Œ莑�Y�䒠
  gv_fixed_ifrs_asset_regi  VARCHAR2(100);  -- �䒠���_IFRS�䒠
--
  -- ***��������
  -- IFRS�䒠�ꊇ�ǉ������ɂ����錏��
  gn_loop_cnt               NUMBER;     -- ����������
  gn_target_cnt             NUMBER;     -- �Ώی���
  gn_normal_cnt             NUMBER;     -- ���팏��
  gn_skip_cnt               NUMBER;     -- �X�L�b�v����
  gn_err_cnt                NUMBER;     -- �G���[����
--
  /**********************************************************************************
   * Procedure Name   : upd_exec_date
   * Description      : ���s�����X�V(A-6)
   ***********************************************************************************/
  PROCEDURE upd_exec_date(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_exec_date'; -- �v���O������
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
    UPDATE xxcff_ifrs_sets  xis       -- IFRS�䒠�A�g�Z�b�g
    SET    xis.exec_date              = cd_last_update_date         -- ���s����
          ,xis.last_updated_by        = cn_last_updated_by          -- �ŏI�X�V��
          ,xis.last_update_date       = cd_last_update_date         -- �ŏI�X�V��
          ,xis.last_update_login      = cn_last_update_login        -- �ŏI�X�V���O�C��ID
          ,xis.request_id             = cn_request_id               -- �v��ID
          ,xis.program_application_id = cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,xis.program_id             = cn_program_id               -- �R���J�����g�E�v���O����ID
          ,xis.program_update_date    = cd_program_update_date      -- �v���O�����X�V��
    WHERE  xis.exec_id                = cv_pkg_name                 -- ����ID
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
  END upd_exec_date;
--
  /**********************************************************************************
   * Procedure Name   : get_ifrs_adj_data
   * Description      : IFRS�䒠�C���f�[�^���o�E�o�^(A-5)
   ***********************************************************************************/
  PROCEDURE get_ifrs_adj_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'get_ifrs_adj_data';    -- �v���O������
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
    cv_value_zero       CONSTANT VARCHAR2(1)  := '0';          -- �����^�̃[��
    cv_lang             CONSTANT fa_additions_tl.language%TYPE := USERENV( 'LANG' );      -- ����
    cv_tran_type_adj    CONSTANT VARCHAR2(10) := 'ADJUSTMENT'; -- ����^�C�v�R�[�h(����)
    cv_format_yyyymm    CONSTANT VARCHAR2(7)  := 'YYYY-MM';    -- ���t�`���FYYYY-MM
    cv_status_pending   CONSTANT VARCHAR2(7)  := 'PENDING';    -- �X�e�[�^�X�FPENDING
    cv_haifun           CONSTANT VARCHAR2(1)  := '-';          -- �n�C�t��
--
    -- *** ���[�J���ϐ� ***
    ld_start_date         DATE;                                                   -- ��v���ԊJ�n�N����
    ld_end_date           DATE;                                                   -- ��v���ԏI���N����
    ld_dpis_date          DATE;                                                   -- ���Ɗ��
    lt_segment1           fa_categories.segment1%TYPE;                            -- ���
    lt_segment2           fa_categories.segment2%TYPE;                            -- �\�����p
    lt_segment3           fa_categories.segment3%TYPE;                            -- ���Y����
    lt_segment4           fa_categories.segment4%TYPE;                            -- ���p�Ȗ�
    lt_segment5           fa_categories.segment5%TYPE;                            -- �ϗp�N��
    lt_segment6           fa_categories.segment6%TYPE;                            -- ���p���@
    lt_segment7           fa_categories.segment7%TYPE;                            -- ���[�X���
    lt_asset_category_id  xx01_adjustment_oif.category_id_new%TYPE;               -- ���Y�J�e�S��CCID
    lt_deprn_method       fa_category_book_defaults.deprn_method%TYPE;            -- ���p���@
    lt_ifrs_assets_cost   xx01_adjustment_oif.cost%TYPE;                          -- �擾���z
    lt_deprn_reserve      xx01_adjustment_oif.deprn_reserve%TYPE;                 -- ���p�݌v�z
    ln_reval_rsv          NUMBER;                                                 -- �ĕ]���ϗ���
    lt_ytd_deprn          xx01_adjustment_oif.ytd_deprn%TYPE;                     -- �N���p�݌v�z
    ln_deprn_exp          NUMBER;                                                 -- �������p��
    lt_bonus_deprn_rsv    xx01_adjustment_oif.bonus_deprn_reserve%TYPE;           -- �{�[�i�X���p�݌v�z
    lt_bonus_ytd_deprn    xx01_adjustment_oif.bonus_ytd_deprn%TYPE;               -- �{�[�i�X�N���p�݌v�z
    lt_life_years         xx01_adjustment_oif.life_years%TYPE;                    -- �ϗp�N��
    lt_life_months        xx01_adjustment_oif.life_months%TYPE;                   -- �ϗp����
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���C���J�[�\��
    CURSOR ifrs_adj_cur
    IS
      SELECT 
             /*+
                LEADING(a)
                INDEX(fb_fixed FA_BOOKS_N1)
                INDEX(fab_fixed FA_ADDITIONS_B_U1)
                INDEX(fat_fixed FA_ADDITIONS_TL_U1)
                INDEX(fab_ifrs XXCFF_FA_ADDITIONS_B_N07)
                INDEX(fb_ifrs FA_BOOKS_N1)
                INDEX(fat_ifrs FA_ADDITIONS_TL_U1)
                INDEX(fc_ifrs.b FA_CATEGORIES_B_U1)
                INDEX(fc_ifrs.t FA_CATEGORIES_TL_U1)
                INDEX(fak_ifrs FA_ASSET_KEYWORDS_U1)
-- 2018/12/14 1.2 ADD Y.Shoji START
                INDEX(fth_ifrs FA_TRANSACTION_HEADERS_U1)
-- 2018/12/14 1.2 ADD Y.Shoji END
             */
              fab_ifrs.asset_id                   AS asset_id                      -- ���YID
             ,fab_fixed.asset_number              AS asset_number_fixed            -- ���Y�ԍ��i�Œ莑�Y�䒠�j
             ,fab_ifrs.asset_number               AS asset_number_ifrs             -- ���Y�ԍ��iIFRS�䒠�j
             ,fb_ifrs.date_placed_in_service      AS date_placed_in_service_ifrs   -- ���Ƌ��p���iIFRS�䒠�j
             ,fab_ifrs.asset_category_id          AS asset_category_id_ifrs        -- ���Y�J�e�S��ID�iIFRS�䒠�j
             ,fab_ifrs.attribute_category_code    AS category_code_ifrs            -- ���Y�J�e�S���R�[�h�iIFRS�䒠�j
             ,fb_fixed.date_placed_in_service     AS date_placed_in_service_fixed  -- ���Ƌ��p���i�Œ莑�Y�䒠�j
             ,fat_fixed.description               AS description_fixed             -- �E�v�i�Œ莑�Y�䒠�j
             ,fat_ifrs.description                AS description_ifrs              -- �E�v�iIFRS�䒠�j
             ,fab_ifrs.current_units              AS current_units                 -- �P��
-- 2018/04/27 1.1 MOD H.Mori START
--             ,fb_fixed.cost                       AS cost_fixed                    -- �擾���z�i�Œ莑�Y�䒠�j
             ,DECODE(fb_fixed.cost,0,fb_ifrs.cost,fb_fixed.cost) AS cost_fixed     -- �擾���z�i�Œ莑�Y�䒠�j
-- 2018/04/27 1.1 MOD H.Mori END
             ,fb_ifrs.cost                        AS cost_ifrs                     -- �擾���z�iIFRS�䒠�j
             ,fb_ifrs.original_cost               AS original_cost                 -- �����擾���z
             ,fab_ifrs.tag_number                 AS tag_number                    -- ���i�[�ԍ�
             ,fab_ifrs.serial_number              AS serial_number                 -- �V���A���ԍ�
             ,fab_ifrs.asset_key_ccid             AS asset_key_ccid                -- ���Y�L�[CCID
             ,fak_ifrs.segment1                   AS key_segment1                  -- ���Y�L�[�Z�O�����g1
             ,fak_ifrs.segment2                   AS key_segment2                  -- ���Y�L�[�Z�O�����g2
             ,fab_ifrs.parent_asset_id            AS parent_asset_id               -- �e���YID
             ,fab_ifrs.lease_id                   AS lease_id                      -- ���[�XID
             ,fab_ifrs.model_number               AS model_number                  -- ���f��
             ,fab_ifrs.in_use_flag                AS in_use_flag                   -- �g�p��
             ,fab_ifrs.inventorial                AS inventorial                   -- ���n�I���t���O
             ,fab_ifrs.owned_leased               AS owned_leased                  -- ���L��
             ,fab_ifrs.new_used                   AS new_used                      -- �V�i/����
             ,fab_ifrs.attribute1                 AS attribute1                    -- �J�e�S��DFF1
             ,fab_ifrs.attribute2                 AS attribute2_ifrs               -- �擾���iIFRS�䒠�j
             ,fab_ifrs.attribute3                 AS attribute3                    -- �J�e�S��DFF3
             ,fab_ifrs.attribute4                 AS attribute4                    -- �J�e�S��DFF4
             ,fab_ifrs.attribute5                 AS attribute5                    -- �J�e�S��DFF5
             ,fab_ifrs.attribute6                 AS attribute6                    -- �J�e�S��DFF6
             ,fab_ifrs.attribute7                 AS attribute7                    -- �J�e�S��DFF7
             ,fab_ifrs.attribute8                 AS attribute8                    -- �J�e�S��DFF8
             ,fab_ifrs.attribute9                 AS attribute9                    -- �J�e�S��DFF9
             ,fab_ifrs.attribute10                AS attribute10                   -- �J�e�S��DFF10
             ,fab_ifrs.attribute11                AS attribute11                   -- �J�e�S��DFF11
             ,fab_ifrs.attribute12                AS attribute12                   -- �J�e�S��DFF12
             ,fab_ifrs.attribute13                AS attribute13                   -- �J�e�S��DFF13
             ,fab_ifrs.attribute14                AS attribute14                   -- �J�e�S��DFF14
             ,fab_ifrs.attribute15                AS attribute15_ifrs              -- IFRS�ϗp�N���iIFRS�䒠�j
             ,fab_ifrs.attribute16                AS attribute16_ifrs              -- IFRS���p�iIFRS�䒠�j
             ,fab_ifrs.attribute17                AS attribute17_ifrs              -- �s���Y�擾�ŁiIFRS�䒠�j
             ,fab_ifrs.attribute18                AS attribute18_ifrs              -- �ؓ��R�X�g�iIFRS�䒠�j
             ,fab_ifrs.attribute19                AS attribute19_ifrs              -- ���̑��iIFRS�䒠�j
             ,fab_ifrs.attribute20                AS attribute20_ifrs              -- IFRS���Y�ȖځiIFRS�䒠�j
             ,fab_ifrs.attribute21                AS attribute21_ifrs              -- �C���N�����iIFRS�䒠�j
             ,fab_ifrs.attribute22                AS attribute22                   -- �J�e�S��DFF22
             ,fab_ifrs.attribute23                AS attribute23                   -- �J�e�S��DFF23
             ,fab_ifrs.attribute24                AS attribute24                   -- �J�e�S��DFF24
             ,fab_ifrs.attribute25                AS attribute25                   -- �J�e�S��DFF27
             ,fab_ifrs.attribute26                AS attribute26                   -- �J�e�S��DFF25
             ,fab_ifrs.attribute27                AS attribute27                   -- �J�e�S��DFF26
             ,fab_ifrs.attribute28                AS attribute28                   -- �J�e�S��DFF28
             ,fab_ifrs.attribute29                AS attribute29                   -- �J�e�S��DFF29
             ,fab_ifrs.attribute30                AS attribute30                   -- �J�e�S��DFF30
             ,fb_ifrs.salvage_value               AS salvage_value                 -- �c�����z
             ,fb_ifrs.percent_salvage_value       AS percent_salvage_value         -- �c�����z%
             ,fb_ifrs.allowed_deprn_limit_amount  AS allowed_deprn_limit_amount    -- ���p���x�z
             ,fb_ifrs.allowed_deprn_limit         AS allowed_deprn_limit           -- ���p���x��
             ,fb_ifrs.depreciate_flag             AS depreciate_flag               -- ���p��v��t���O
             ,fb_ifrs.deprn_method_code           AS deprn_method_code             -- ���p���@
             ,fb_ifrs.basic_rate                  AS basic_rate                    -- ���ʏ��p��
             ,fb_ifrs.adjusted_rate               AS adjusted_rate                 -- �����㏞�p��
             ,fb_ifrs.life_in_months              AS life_in_months                -- �ϗp�N��+����
             ,fb_ifrs.bonus_rule                  AS bonus_rule                    -- �{�[�i�X���[��
             ,fc_ifrs.segment1                    AS cat_segment1                  -- ���Y�J�e�S��-��ށiIFRS�䒠�j
             ,fc_ifrs.segment2                    AS cat_segment2                  -- ���Y�J�e�S��-�\�����p�iIFRS�䒠�j
             ,fc_ifrs.segment3                    AS cat_segment3                  -- ���Y�J�e�S��-���Y����iIFRS�䒠�j
             ,fc_ifrs.segment4                    AS cat_segment4                  -- ���Y�J�e�S��-���p�ȖځiIFRS�䒠�j
             ,fc_ifrs.segment5                    AS cat_segment5                  -- ���Y�J�e�S��-�ϗp�N���iIFRS�䒠�j
             ,fc_ifrs.segment6                    AS cat_segment6                  -- ���Y�J�e�S��-���p���@�iIFRS�䒠�j
             ,fc_ifrs.segment7                    AS cat_segment7                  -- ���Y�J�e�S��-���[�X��ʁiIFRS�䒠�j
             ,fab_fixed.attribute2                AS attribute2_fixed              -- �擾���i�Œ莑�Y�䒠�j
             ,fab_fixed.attribute15               AS attribute15_fixed             -- IFRS�ϗp�N���i�Œ莑�Y�䒠�j
             ,fab_fixed.attribute16               AS attribute16_fixed             -- IFRS���p�i�Œ莑�Y�䒠�j
             ,fab_fixed.attribute17               AS attribute17_fixed             -- �s���Y�擾�Łi�Œ莑�Y�䒠�j
             ,fab_fixed.attribute18               AS attribute18_fixed             -- �ؓ��R�X�g�i�Œ莑�Y�䒠�j
             ,fab_fixed.attribute19               AS attribute19_fixed             -- ���̑��i�Œ莑�Y�䒠�j
             ,fab_fixed.attribute20               AS attribute20_fixed             -- IFRS���Y�Ȗځi�Œ莑�Y�䒠�j
             ,fab_fixed.attribute21               AS attribute21_fixed             -- �C���N�����i�Œ莑�Y�䒠�j
-- 2018/12/14 1.2 ADD Y.Shoji START
             ,DECODE(fth_ifrs.amortization_start_date
                    ,NULL ,cv_no
                          ,cv_yes)                AS amortized_flag                -- �C���z���p�t���O
             ,fth_ifrs.amortization_start_date    AS amortization_start_date       -- ���p�J�n��
-- 2018/12/14 1.2 ADD Y.Shoji END
      FROM    fa_books                fb_fixed    -- ���Y�䒠���i�Œ莑�Y�䒠�j
             ,fa_additions_b          fab_fixed   -- ���Y�ڍ׏��i�Œ莑�Y�䒠�j
             ,fa_additions_tl         fat_fixed   -- ���Y�E�v���i�Œ莑�Y�䒠�j
             ,fa_books                fb_ifrs     -- ���Y�䒠���iIFRS�䒠�j
             ,fa_additions_b          fab_ifrs    -- ���Y�ڍ׏��iIFRS�䒠�j
             ,fa_additions_tl         fat_ifrs    -- ���Y�E�v���iIFRS�䒠�j
             ,fa_categories           fc_ifrs     -- ���Y�J�e�S���iIFRS�䒠�j
             ,fa_asset_keywords       fak_ifrs    -- ���Y�L�[�iIFRS�䒠�j
-- 2018/12/14 1.2 ADD Y.Shoji START
             ,fa_transaction_headers  fth_ifrs    -- ���Y����w�b�_�iIFRS�䒠�j
-- 2018/12/14 1.2 ADD Y.Shoji END
             ,(SELECT 
                      /*+
                          QB_NAME(a)
                      */
                      trn.asset_id  asset_id
               FROM   (
                       -- �����@�F�C���N�������Ώۂ̉�v����
                       SELECT 
                              /*+
                                 INDEX(fab1 XXCFF_FA_ADDITIONS_B_N05)
                                 INDEX(fb1 FA_BOOKS_N1)
                              */
                              fab1.asset_id  asset_id
                       FROM   fa_additions_b fab1      -- ���Y�ڍ׏��
                             ,fa_books       fb1       -- ���Y�䒠���
                       WHERE  TO_DATE(fab1.attribute21 ,'YYYY/MM/DD') BETWEEN ld_start_date
                                                                      AND     ld_end_date
                       AND    fab1.asset_id                                 = fb1.asset_id
                       AND    fb1.book_type_code                            = gv_fixed_asset_register  -- �䒠���_�Œ莑�Y�䒠
                       AND    fb1.date_ineffective                          IS NULL
                       --
                       UNION ALL
                       -- �����A�F�E�v���O����s���Ԉȍ~�ɍX�V
                       SELECT 
                              /*+
                                 INDEX(fat2 XXCFF_FA_ADDITIONS_TL_N01)
                                 INDEX(fb2 FA_BOOKS_N1)
                              */
                              fat2.asset_id  asset_id
                       FROM   fa_additions_tl fat2      -- ���Y�E�v���
                             ,fa_books        fb2       -- ���Y�䒠���
                       WHERE  fat2.language         = cv_lang
                       AND    fat2.last_update_date > gt_exec_date             -- �O����s����
                       AND    fat2.last_update_date <> fat2.creation_date
                       AND    fat2.asset_id         = fb2.asset_id
                       AND    fb2.book_type_code    = gv_fixed_asset_register  -- �䒠���_�Œ莑�Y�䒠
                       AND    fb2.date_ineffective  IS NULL
                       --
                       UNION ALL
                       -- �����B�F�O����s���Ԉȍ~�ɒ����̎��������
                       SELECT 
                              /*+
                                 INDEX(fth3 FA_TRANSACTION_HEADERS)
                              */
                              fth3.asset_id  asset_id
                       FROM   fa_transaction_headers fth3  -- ���Y����w�b�_
                       WHERE  fth3.transaction_type_code = cv_tran_type_adj         -- ����^�C�v�R�[�h(����)
                       AND    fth3.book_type_code        = gv_fixed_asset_register  -- �䒠���_�Œ莑�Y�䒠
                       AND    fth3.date_effective        > gt_exec_date             -- �O����s����
                       ) trn
               GROUP BY trn.asset_id
              ) target                            -- �Ώۂ̎��Y
      WHERE   target.asset_id                  = fb_fixed.asset_id
      AND     fb_fixed.book_type_code          = gv_fixed_asset_register  -- �䒠���_�Œ莑�Y�䒠
      AND     fb_fixed.date_ineffective        IS NULL
      AND     fb_fixed.asset_id                = fab_fixed.asset_id
      AND     fab_fixed.asset_id               = fat_fixed.asset_id
      AND     fat_fixed.language               = cv_lang
      AND     fab_fixed.asset_number           = fab_ifrs.attribute22
      AND     fab_ifrs.attribute23             IS NULL                    -- IFRS�Ώێ��Y�ԍ�
      AND     fab_ifrs.asset_id                = fb_ifrs.asset_id
      AND     fb_ifrs.book_type_code           = gv_fixed_ifrs_asset_regi -- �䒠���_IFRS�䒠
      AND     fb_ifrs.date_ineffective         IS NULL
      AND     fab_ifrs.asset_id                = fat_ifrs.asset_id
      AND     fat_ifrs.language                = cv_lang
      AND     fab_ifrs.asset_category_id       = fc_ifrs.category_id
      AND     fab_ifrs.asset_key_ccid          = fak_ifrs.code_combination_id(+)
-- 2018/12/14 1.2 ADD Y.Shoji START
      AND     fb_ifrs.transaction_header_id_in = fth_ifrs.transaction_header_id(+)
-- 2018/12/14 1.2 ADD Y.Shoji END
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
    -- ��v���Ԃ̊J�n�N�������擾
    ld_start_date := TO_DATE(gv_period_name ,cv_format_yyyymm);
    -- ��v���Ԃ̏I���N�������擾
    ld_end_date   := LAST_DAY(ld_start_date);
    -- ��v���Ԃ̗���������擾
    ld_dpis_date  := ADD_MONTHS(TO_DATE(gv_period_name ,cv_format_yyyymm) ,1);
--
    --==============================================================
    --���C���f�[�^���o
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN ifrs_adj_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH ifrs_adj_cur BULK COLLECT INTO  g_ifrs_adj_tab;
    -- �J�[�\���N���[�Y
    CLOSE ifrs_adj_cur;
    -- �Ώی����̎擾
    gn_target_cnt := g_ifrs_adj_tab.COUNT;
--
    -- �V�K�o�^�Ώی�����0���̏ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_cff_00165     -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_cff_50236)    -- �Œ莑�Y�i�C���j���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => gv_out_msg
      );
    END IF;
--
    -- ������
    gn_loop_cnt   := 0;
    gn_normal_cnt := 0;
    gn_skip_cnt   := 0;
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    --==============================================================
    --���C�����[�v����
    --==============================================================
    <<ifrs_fa_add_loop>>
    FOR ln_loop_cnt IN 1 .. gn_target_cnt LOOP
--
      -- LOOP���擾
      gn_loop_cnt := ln_loop_cnt;
--
      --==============================================================
      -- ���Y�J�e�S��CCID�擾 (A-5-1)
      --==============================================================
      -- ���Y�J�e�S����segment1-7�̒l��ݒ�
      lt_segment1 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment1;         -- ���Y�J�e�S��-��ށiIFRS�䒠�j
      lt_segment2 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment2;         -- ���Y�J�e�S��-�\�����p�iIFRS�䒠�j
      --
      -- ���Y����
      -- IFRS���Y�Ȗځi�Œ莑�Y�䒠�j�ɒl���ݒ肳��Ă���ꍇ
      IF (g_ifrs_adj_tab(ln_loop_cnt).attribute20_fixed IS NOT NULL) THEN
        lt_segment3 := g_ifrs_adj_tab(ln_loop_cnt).attribute20_fixed;  -- IFRS���Y�Ȗځi�Œ莑�Y�䒠�j
      ELSE
        lt_segment3 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment3;       -- ���Y�J�e�S��-���Y����iIFRS�䒠�j
      END IF;
      --
      lt_segment4 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment4;         -- ���Y�J�e�S��-���p�ȖځiIFRS�䒠�j
      --
      -- �ϗp�N��
      -- IFRS�ϗp�N���i�Œ莑�Y�䒠�j�ɒl���ݒ肳��Ă���ꍇ
      IF (g_ifrs_adj_tab(ln_loop_cnt).attribute15_fixed IS NOT NULL) THEN
        lt_segment5 := g_ifrs_adj_tab(ln_loop_cnt).attribute15_fixed;  -- IFRS�ϗp�N���i�Œ莑�Y�䒠�j
        -- OIF�o�^�p���ڂ�ݒ�
        lt_life_years  := g_ifrs_adj_tab(ln_loop_cnt).attribute15_fixed;            -- �ϗp�N��
        lt_life_months := 0;                                                        -- �ϗp����
      ELSE
        lt_segment5 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment5;       -- ���Y�J�e�S��-�ϗp�N���iIFRS�䒠�j
        -- OIF�o�^�p���ڂ�ݒ�
        lt_life_years  := TRUNC(g_ifrs_adj_tab(ln_loop_cnt).life_in_months / 12);   -- �ϗp�N��
        lt_life_months := MOD(g_ifrs_adj_tab(ln_loop_cnt).life_in_months, 12);      -- �ϗp����
      END IF;
      --
      -- ���p���@
      -- IFRS���p�i�Œ莑�Y�䒠�j�ɒl���ݒ肳��Ă���ꍇ
      IF (g_ifrs_adj_tab(ln_loop_cnt).attribute16_fixed IS NOT NULL) THEN
        lt_segment6 := g_ifrs_adj_tab(ln_loop_cnt).attribute16_fixed;  -- IFRS���p�i�Œ莑�Y�䒠�j
      ELSE
        lt_segment6 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment6;       -- ���Y�J�e�S��-���p���@�iIFRS�䒠�j
      END IF;
      --
      lt_segment7 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment7;         -- ���Y�J�e�S��-���[�X��ʁiIFRS�䒠�j
--
      -- ���Y�J�e�S���̑g�����`�F�b�N�����CCID�擾
      xxcff_common1_pkg.chk_fa_category(
         iv_segment1      => lt_segment1            -- ���
        ,iv_segment2      => lt_segment2            -- �\�����p
        ,iv_segment3      => lt_segment3            -- ���Y����
        ,iv_segment4      => lt_segment4            -- ���p�Ȗ�
        ,iv_segment5      => lt_segment5            -- �ϗp�N��
        ,iv_segment6      => lt_segment6            -- ���p���@
        ,iv_segment7      => lt_segment7            -- ���[�X���
        ,on_category_id   => lt_asset_category_id   -- ���Y�J�e�S��CCID
        ,ov_errbuf        => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode       => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      -- ���p���@�擾�iA-5-2�j
      --==============================================================
      BEGIN
        SELECT  fcbd.deprn_method   AS deprn_method     -- ���p���@
        INTO    lt_deprn_method
        FROM    fa_category_book_defaults  fcbd    -- ���Y�J�e�S�����p�
        WHERE   fcbd.category_id                 =  lt_asset_category_id      -- �J�e�S��ID
        AND     fcbd.book_type_code              =  gv_fixed_ifrs_asset_regi  -- �䒠���_IFRS�䒠
        AND     fcbd.start_dpis                  <  ld_dpis_date
        AND     NVL(fcbd.end_dpis ,ld_dpis_date) >= ld_dpis_date
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF
                                                        ,cv_msg_cff_00281         -- ���p���@�擾�G���[
                                                        ,cv_tkn_category          -- �g�[�N��'CATEGORY'
                                                        ,lt_segment1 || cv_haifun ||  -- ���
                                                         lt_segment2 || cv_haifun ||  -- �\�����p
                                                         lt_segment3 || cv_haifun ||  -- ���Y����
                                                         lt_segment4 || cv_haifun ||  -- ���p�Ȗ�
                                                         lt_segment5 || cv_haifun ||  -- �ϗp�N��
                                                         lt_segment6 || cv_haifun ||  -- ���p���@
                                                         lt_segment7                  -- ���[�X���
                                                                                  -- �J�e�S���R�[�h
                                                        ,cv_tkn_bk_type           -- �g�[�N��'BOOK_TYPE_CODE'
                                                        ,gv_fixed_ifrs_asset_regi -- �䒠���_IFRS�䒠
                                                        )    -- 
                                                        ,1
                                                        ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- �擾���z���Z�o
      lt_ifrs_assets_cost :=   NVL(g_ifrs_adj_tab(ln_loop_cnt).cost_fixed, 0)                                 -- �擾���z�i�Œ莑�Y�䒠�j
                             + TO_NUMBER(NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute17_fixed, cv_value_zero))   -- �s���Y�擾�Łi�Œ莑�Y�䒠�j
                             + TO_NUMBER(NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute18_fixed, cv_value_zero))   -- �ؓ��R�X�g�i�Œ莑�Y�䒠�j
                             + TO_NUMBER(NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute19_fixed, cv_value_zero));  -- ���̑��i�Œ莑�Y�䒠�j
--
      -- �C���Ώۂ̍��ڂ�1�ł��C��������ꍇ
      IF ( ( g_ifrs_adj_tab(ln_loop_cnt).date_placed_in_service_ifrs     <> g_ifrs_adj_tab(ln_loop_cnt).date_placed_in_service_fixed )-- ���Ƌ��p��
        OR ( g_ifrs_adj_tab(ln_loop_cnt).description_ifrs                <> g_ifrs_adj_tab(ln_loop_cnt).description_fixed )       -- �E�v
        OR ( g_ifrs_adj_tab(ln_loop_cnt).asset_category_id_ifrs          <> lt_asset_category_id )                                -- ���Y�J�e�S��ID
        OR ( g_ifrs_adj_tab(ln_loop_cnt).deprn_method_code               <> lt_deprn_method )                                     -- ���p���@
        OR ( g_ifrs_adj_tab(ln_loop_cnt).cost_ifrs                       <> lt_ifrs_assets_cost )                                 -- �擾���z
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute2_ifrs, cv_space ) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute2_fixed, cv_space ) )        -- �擾��
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute15_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute15_fixed, cv_space ) )       -- IFRS�ϗp�N��
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute16_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute16_fixed, cv_space ) )       -- IFRS���p
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute17_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute17_fixed, cv_space ) )       -- �s���Y�擾��
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute18_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute18_fixed, cv_space ) )       -- �ؓ��R�X�g
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute19_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute19_fixed, cv_space ) )       -- ���̑�
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute20_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute20_fixed, cv_space ) )       -- IFRS���Y�Ȗ�
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute21_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute21_fixed, cv_space ) )       -- �C���N����
         ) THEN
        --==============================================================
        -- �݌v�z�擾�iA-5-3�j
        --==============================================================
        -- ���p�݌v�z�E�N���p�݌v�z�E�{�[�i�X���p�݌v�z�E�{�[�i�X�N���p�݌v�z�̎擾
        xx01_conc_util_pkg.query_balances_bonus(
           in_asset_id         => g_ifrs_adj_tab(ln_loop_cnt).asset_id       -- ���YID
          ,iv_book_type_code   => gv_fixed_ifrs_asset_regi                   -- XXCFF:�䒠���_IFRS�䒠
          ,on_deprn_rsv        => lt_deprn_reserve                           -- ���p�݌v�z
          ,on_reval_rsv        => ln_reval_rsv                               -- �ĕ]���ϗ���
          ,on_ytd_deprn        => lt_ytd_deprn                               -- �N���p�݌v�z
          ,on_deprn_exp        => ln_deprn_exp                               -- �������p��
          ,on_bonus_deprn_rsv  => lt_bonus_deprn_rsv                         -- �{�[�i�X���p�݌v�z
          ,on_bonus_ytd_deprn  => lt_bonus_ytd_deprn                         -- �{�[�i�X�N���p�݌v�z
        );
--
        --==============================================================
        -- �C��OIF�o�^ (A-5-4)
        --==============================================================
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
-- 2018/12/14 1.2 ADD Y.Shoji START
          ,amortized_flag                  -- �C���z���p�t���O
          ,amortization_start_date         -- ���p�J�n��
-- 2018/12/14 1.2 ADD Y.Shoji END
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
          ,cat_attribute25                 -- �J�e�S��DFF25
          ,cat_attribute26                 -- �J�e�S��DFF26
          ,cat_attribute27                 -- �J�e�S��DFF27
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
           xx01_adjustment_oif_s.NEXTVAL                             -- ID
          ,gv_fixed_ifrs_asset_regi                                  -- �䒠��
          ,g_ifrs_adj_tab(ln_loop_cnt).asset_number_ifrs             -- ���Y�ԍ�
          ,g_ifrs_adj_tab(ln_loop_cnt).date_placed_in_service_ifrs   -- ���Ƌ��p���i�C���O�j
          ,g_ifrs_adj_tab(ln_loop_cnt).asset_category_id_ifrs        -- ���Y�J�e�S��ID�i�C���O�j
          ,g_ifrs_adj_tab(ln_loop_cnt).category_code_ifrs            -- ���Y�J�e�S���R�[�h�i�C���O�j
          ,g_ifrs_adj_tab(ln_loop_cnt).date_placed_in_service_fixed  -- ���Ƌ��p���i�C����j
          ,g_ifrs_adj_tab(ln_loop_cnt).description_fixed             -- �E�v�i�C����j
          ,g_ifrs_adj_tab(ln_loop_cnt).current_units                 -- �P��
          ,lt_ifrs_assets_cost                                       -- �擾���z
          ,g_ifrs_adj_tab(ln_loop_cnt).original_cost                 -- �����擾���z
          ,cv_yes                                                    -- �]�L�`�F�b�N�t���O
          ,cv_status_pending                                         -- �X�e�[�^�X
-- 2018/12/14 1.2 ADD Y.Shoji START
          ,g_ifrs_adj_tab(ln_loop_cnt).amortized_flag                -- �C���z���p�t���O
          ,g_ifrs_adj_tab(ln_loop_cnt).amortization_start_date       -- ���p�J�n��
-- 2018/12/14 1.2 ADD Y.Shoji END
          ,g_ifrs_adj_tab(ln_loop_cnt).asset_number_ifrs             -- ���Y�ԍ��i�C����j
          ,g_ifrs_adj_tab(ln_loop_cnt).tag_number                    -- ���i�[�ԍ�
          ,lt_asset_category_id                                      -- ���Y�J�e�S��ID�i�C����j
          ,g_ifrs_adj_tab(ln_loop_cnt).serial_number                 -- �V���A���ԍ�
          ,g_ifrs_adj_tab(ln_loop_cnt).asset_key_ccid                -- ���Y�L�[CCID
          ,g_ifrs_adj_tab(ln_loop_cnt).key_segment1                  -- ���Y�L�[�Z�O�����g1
          ,g_ifrs_adj_tab(ln_loop_cnt).key_segment2                  -- ���Y�L�[�Z�O�����g2
          ,g_ifrs_adj_tab(ln_loop_cnt).parent_asset_id               -- �e���YID
          ,g_ifrs_adj_tab(ln_loop_cnt).lease_id                      -- ���[�XID
          ,g_ifrs_adj_tab(ln_loop_cnt).model_number                  -- ���f��
          ,g_ifrs_adj_tab(ln_loop_cnt).in_use_flag                   -- �g�p��
          ,g_ifrs_adj_tab(ln_loop_cnt).inventorial                   -- ���n�I���t���O
          ,g_ifrs_adj_tab(ln_loop_cnt).owned_leased                  -- ���L��
          ,g_ifrs_adj_tab(ln_loop_cnt).new_used                      -- �V�i/����
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute1                    -- �J�e�S��DFF1
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute2_fixed              -- �J�e�S��DFF2�i�擾���j
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute3                    -- �J�e�S��DFF3
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute4                    -- �J�e�S��DFF4
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute5                    -- �J�e�S��DFF5
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute6                    -- �J�e�S��DFF6
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute7                    -- �J�e�S��DFF7
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute8                    -- �J�e�S��DFF8
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute9                    -- �J�e�S��DFF9
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute10                   -- �J�e�S��DFF10
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute11                   -- �J�e�S��DFF11
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute12                   -- �J�e�S��DFF12
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute13                   -- �J�e�S��DFF13
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute14                   -- �J�e�S��DFF14
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute15_fixed             -- �J�e�S��DFF15�iIFRS�ϗp�N���j
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute16_fixed             -- �J�e�S��DFF16�iIFRS���p�j
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute17_fixed             -- �J�e�S��DFF17�i�s���Y�擾�Łj
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute18_fixed             -- �J�e�S��DFF18�i�ؓ��R�X�g�j
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute19_fixed             -- �J�e�S��DFF19�i���̑��j
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute20_fixed             -- �J�e�S��DFF20�iIFRS���Y�Ȗځj
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute21_fixed             -- �J�e�S��DFF21�i�C���N�����j
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute22                   -- �J�e�S��DFF22
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute23                   -- �J�e�S��DFF23
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute24                   -- �J�e�S��DFF24
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute25                   -- �J�e�S��DFF25
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute26                   -- �J�e�S��DFF26
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute27                   -- �J�e�S��DFF27
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute28                   -- �J�e�S��DFF28
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute29                   -- �J�e�S��DFF29
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute30                   -- �J�e�S��DFF30
          ,lt_segment1 || cv_haifun ||  -- ���
           lt_segment2 || cv_haifun ||  -- �\�����p
           lt_segment3 || cv_haifun ||  -- ���Y����
           lt_segment4 || cv_haifun ||  -- ���p�Ȗ�
           lt_segment5 || cv_haifun ||  -- �ϗp�N��
           lt_segment6 || cv_haifun ||  -- ���p���@
           lt_segment7                  -- ���[�X���
                                                                     -- ���Y�J�e�S���R�[�h�i�C����j
          ,g_ifrs_adj_tab(ln_loop_cnt).salvage_value                 -- �c�����z
          ,g_ifrs_adj_tab(ln_loop_cnt).percent_salvage_value         -- �c�����z%
          ,g_ifrs_adj_tab(ln_loop_cnt).allowed_deprn_limit_amount    -- ���p���x�z
          ,g_ifrs_adj_tab(ln_loop_cnt).allowed_deprn_limit           -- ���p���x��
          ,lt_ytd_deprn                                              -- �N���p�݌v�z
          ,lt_deprn_reserve                                          -- ���p�݌v�z
          ,g_ifrs_adj_tab(ln_loop_cnt).depreciate_flag               -- ���p��v��t���O
          ,lt_deprn_method                                           -- ���p���@
          ,g_ifrs_adj_tab(ln_loop_cnt).basic_rate                    -- ���ʏ��p��
          ,g_ifrs_adj_tab(ln_loop_cnt).adjusted_rate                 -- �����㏞�p��
          ,lt_life_years                                             -- �ϗp�N��
          ,lt_life_months                                            -- �ϗp����
          ,g_ifrs_adj_tab(ln_loop_cnt).bonus_rule                    -- �{�[�i�X���[��
          ,lt_bonus_ytd_deprn                                        -- �{�[�i�X�N���p�݌v�z
          ,lt_bonus_deprn_rsv                                        -- �{�[�i�X���p�݌v�z
          ,cn_created_by                                             -- �쐬��
          ,cd_creation_date                                          -- �쐬��
          ,cn_last_updated_by                                        -- �ŏI�X�V��
          ,cd_last_update_date                                       -- �ŏI�X�V��
          ,cn_last_update_login                                      -- �ŏI�X�V���O�C��ID
          ,cn_request_id                                             -- ���N�G�X�gID
          ,cn_program_application_id                                 -- �A�v���P�[�V����ID
          ,cn_program_id                                             -- �v���O����ID
          ,cd_program_update_date                                    -- �v���O�����ŏI�X�V��
        )
        ;
--
        -- ���팏���J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
      -- �C�����ڂɏC�����Ȃ��ꍇ
      ELSE
        -- �X�L�b�v�ƂȂ������Y�����o�͂���
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                                  -- XXCFF
                                                       ,cv_msg_cff_00276                                -- IFRS�䒠�C���X�L�b�v���b�Z�[�W
                                                       ,cv_tkn_asset_number1                            -- �g�[�N��'ASSET_NUMBER1'
                                                       ,g_ifrs_adj_tab(gn_loop_cnt).asset_number_fixed  -- �Œ莑�Y�䒠�̎��Y�ԍ�
                                                       ,cv_tkn_asset_number2                            -- �g�[�N��'ASSET_NUMBER2'
                                                       ,g_ifrs_adj_tab(gn_loop_cnt).asset_number_ifrs)  -- IFRS�䒠�̎��Y�ԍ�
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- �X�L�b�v�����J�E���g
        gn_skip_cnt := gn_skip_cnt + 1;
      END IF;
--
    END LOOP ifrs_fa_add_loop;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_adj_cur%ISOPEN) THEN
        CLOSE ifrs_adj_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_adj_cur%ISOPEN) THEN
        CLOSE ifrs_adj_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_adj_cur%ISOPEN) THEN
        CLOSE ifrs_adj_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ifrs_adj_data;
--
  /**********************************************************************************
   * Procedure Name   : get_exec_date
   * Description      : �O����s�����擾����(A-4)
   ***********************************************************************************/
  PROCEDURE get_exec_date(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exec_date'; -- �v���O������
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
    BEGIN
      SELECT  xis.exec_date AS exec_date  -- �O����s����
      INTO    gt_exec_date
      FROM    xxcff_ifrs_sets  xis        -- IFRS�䒠�A�g�Z�b�g
      WHERE   xis.exec_id = cv_pkg_name
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_cff_00165     -- �擾�Ώۃf�[�^����
                                                      ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                      ,cv_msg_cff_50316)    -- IFRS�䒠�A�g�Z�b�g
                                                      ,1
                                                      ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN data_lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_cff_00007     -- ���b�N�G���[
                                                      ,cv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                      ,cv_msg_cff_50316)    -- IFRS�䒠�A�g�Z�b�g
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END get_exec_date;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : ��v���ԃ`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- �v���O������
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
    lt_deprn_run          fa_deprn_periods.deprn_run%TYPE := NULL;  -- �������p���s�t���O
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
    BEGIN
      -- ��v���ԃ`�F�b�N
      SELECT  fdp.deprn_run        AS deprn_run   -- �������p���s�t���O
      INTO    lt_deprn_run
      FROM    fa_deprn_periods  fdp               -- �������p����
      WHERE   fdp.book_type_code    = gv_fixed_ifrs_asset_regi
      AND     fdp.period_name       = gv_period_name
      AND     fdp.period_close_date IS NULL
      ;
    EXCEPTION
      -- ��v���Ԃ̎擾�������[�����̏ꍇ
      WHEN NO_DATA_FOUND THEN
        RAISE chk_period_expt;
    END;
--
    -- �������p�����s����Ă���ꍇ
    IF lt_deprn_run = cv_yes THEN
      RAISE chk_period_expt;
    END IF;
--
  EXCEPTION
    -- *** ��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_period_expt THEN
      -- �G���[���b�Z�[�W���Z�b�g
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff            -- XXCFF
                                                    ,cv_msg_cff_00037          -- ��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_bk_type            -- �g�[�N��'BOOK_TYPE_CODE'
                                                    ,gv_fixed_ifrs_asset_regi  -- ���Y�䒠��
                                                    ,cv_tkn_period             -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)           -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      --
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- �I���X�e�[�^�X�̓G���[�Ƃ���
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
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : �v���t�@�C���擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- �v���O������
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
    -- XXCFF:�䒠���_�Œ莑�Y�䒠
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_fixed_asset_register);
    IF (gv_fixed_asset_register IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_cff_00020     -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_cff_50228)    -- XXCFF:�䒠���_�Œ莑�Y�䒠
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�䒠���_IFRS�䒠
    gv_fixed_ifrs_asset_regi := FND_PROFILE.VALUE(cv_fixed_ifrs_asset_regi);
    IF (gv_fixed_ifrs_asset_regi IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_cff_00020     -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_cff_50314)    -- XXCFF:�䒠���_IFRS�䒠
                                                    ,1
                                                    ,5000);
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
  END get_profile_values;
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
    -- �R���J�����g�p�����[�^�l�o��(�o�͂̕\��)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(���O�̕\��)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     -- 1.��v���Ԗ�
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';      -- �v���O������
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- IN�p�����[�^(��v���Ԗ�)���O���[�o���ϐ��ɐݒ�
    gv_period_name := iv_period_name;
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���擾 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �O����s�����擾 (A-4)
    -- =========================================
    get_exec_date(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- IFRS�䒠�C���f�[�^���o�E�o�^ (A-5)
    -- =========================================
    get_ifrs_adj_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���s�����X�V(A-6)
    -- =========================================
    upd_exec_date(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
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
  PROCEDURE main(
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name IN  VARCHAR2       --   1.��v���Ԗ�
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
--
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_err_cnt    := 0;
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_period_name -- ��v���Ԗ�
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
  /**********************************************************************************
   * Description      : �I������(A-7)
   ***********************************************************************************/
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      -- ���팏����0�ɐݒ�
      gn_normal_cnt := 0;
      -- �X�L�b�v������0�ɐݒ�
      gn_skip_cnt   := 0;
      -- �G���[������1�ɐݒ�
      gn_err_cnt    := 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �Ώی������J�E���g����Ă���ꍇ
      IF ( gn_target_cnt > 0 ) THEN
        -- �G���[�ƂȂ������Y�����o�͂���
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                                  -- XXCFF
                                                       ,cv_msg_cff_00275                                -- IFRS�䒠�C���o�^�G���[
                                                       ,cv_tkn_asset_number1                            -- �g�[�N��'ASSET_NUMBER1'
                                                       ,g_ifrs_adj_tab(gn_loop_cnt).asset_number_fixed  -- �Œ莑�Y�䒠�̎��Y�ԍ�
                                                       ,cv_tkn_asset_number2                            -- �g�[�N��'ASSET_NUMBER2'
                                                       ,g_ifrs_adj_tab(gn_loop_cnt).asset_number_ifrs)  -- IFRS�䒠�̎��Y�ԍ�
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
    -- �Ώی�����0���A�܂��̓X�L�b�v���������݂���ꍇ
    ELSIF ( ( gn_target_cnt = 0 )
      OR    ( gn_skip_cnt   > 0 ) ) THEN
      -- �X�e�[�^�X���x���ɂ���
      lv_retcode := cv_status_warn;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================================
    -- IFRS�䒠�C���ɂ����錏���o��
    -- ===============================================================
    -- �C��OIF�o�^���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_cff_00267
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_err_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
END XXCFF019A04C;
/
