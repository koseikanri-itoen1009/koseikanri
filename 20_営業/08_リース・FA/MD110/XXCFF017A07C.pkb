CREATE OR REPLACE PACKAGE BODY XXCFF017A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF017A07C(body)
 * Description      : ���̋@����U��
 * MD.050           : MD050_CFF_017_A07_���̋@����U��
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                       ��������                                  (A-1)
 *  get_profile_values         �v���t�@�C���l�擾                        (A-2)
 *  chk_period                 ��v���ԃ`�F�b�N                          (A-3)
 *  chk_data_exist             �O��쐬�ςݕ���U�֎d�󑶍݃`�F�b�N      (A-4)
 *  ins_gl_oif_lease           ��ʉ�vOIF�o�^�����i���[�X�����U�ցj     (A-5)
 *  ins_gl_oif_vd              ��ʉ�vOIF�o�^�����i���̋@�����U�ցj     (A-6)
 *  submain                    ���C�������v���V�[�W��
 *  main                       �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/04/14    1.0   SCSK���H���O     �V�K�쐬
 *  2017/05/15    1.1   SCSK���H���O     E_�{�ғ�_14030 �p�t�H�[�}���X�Ή�
 *  2017/06/22    1.2   SCSK���H���O     E_�{�ғ�_14369�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by    CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(20) := 'XXCFF017A07C';     --�p�b�P�[�W��
--
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff         CONSTANT VARCHAR2(5)  := 'XXCFF';
--
  -- ***���b�Z�[�W��(�{��)
  cv_msg_xxcff_00020     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- �v���t�@�C���擾�G���[
  cv_msg_xxcff_00115     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00115'; -- ��ʉ�vOIF�쐬���b�Z�[�W
  cv_msg_xxcff_00130     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00130'; -- GL��v���ԃ`�F�b�N�G���[
  cv_msg_xxcff_00165     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- �擾�Ώۃf�[�^����
  cv_msg_xxcff_00181     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00181'; -- �擾�G���[
  cv_msg_xxcff_00246     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00246'; -- ���[�X��������U�֎d�󑶍݃`�F�b�N�iOIF�j
  cv_msg_xxcff_00247     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00247'; -- ���̋@��������U�֎d�󑶍݃`�F�b�N�iOIF�j
  cv_msg_xxcff_00248     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00248'; -- ���[�X��������U�֎d�󑶍݃`�F�b�N�i�d��w�b�_�j
  cv_msg_xxcff_00249     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00249'; -- ���̋@��������U�֎d�󑶍݃`�F�b�N�i�d��w�b�_�j
  cv_msg_xxcff_00250     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00250'; -- ���[�X��������U�֎d�󌏐�
  cv_msg_xxcff_00251     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00251'; -- ���̋@��������U�֎d�󌏐�
--
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_msg_xxcff_50078     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50078'; -- XXCFF:����R�[�h_��������
  cv_msg_xxcff_50079     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50079'; -- XXCFF:�ڋq�R�[�h_��`�Ȃ�
  cv_msg_xxcff_50080     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50080'; -- XXCFF:��ƃR�[�h_��`�Ȃ�
  cv_msg_xxcff_50081     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50081'; -- XXCFF:�\��1_��`�Ȃ�
  cv_msg_xxcff_50082     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50082'; -- XXCFF:�\��2_��`�Ȃ�
  cv_msg_xxcff_50146     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50146'; -- XXCFF:�d��\�[�X_���[�X
  cv_msg_xxcff_50154     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50154'; -- ���O�C��(���[�U��,��������)���
  cv_msg_xxcff_50155     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50155'; -- XXCFF:�`�[�ԍ�_���[�X
  cv_msg_xxcff_50160     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50160'; -- ��v���떼
  cv_msg_xxcff_50167     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50167'; -- ���O�C�����[�UID=
  cv_msg_xxcff_50168     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50168'; -- ��v����ID
  cv_msg_xxcff_50255     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50255'; -- XXCFF:�d��\�[�X_���̋@����
  cv_msg_xxcff_50273     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50273'; -- XXCFF:�䒠��
  cv_msg_xxcff_50287     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50287'; -- XXCFF:�䒠��_FIN���[�X�䒠
  cv_msg_xxcff_50288     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50288'; -- XXCFF:�d��J�e�S��_���̋@����U��
  cv_msg_xxcff_50289     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50289'; -- ���[�X�����U��
  cv_msg_xxcff_50290     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50290'; -- ���̋@�����U��
  cv_msg_xxcff_50291     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50291'; -- XXCFF:�d��\�[�X_���Y�Ǘ�
  cv_msg_xxcff_50292     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50292'; -- XXCFF:�d��J�e�S��_�������p
--
  -- ***�g�[�N����
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_name        CONSTANT VARCHAR2(20) := 'KEY_NAME';
  cv_tkn_key_val         CONSTANT VARCHAR2(20) := 'KEY_VAL';
  cv_tkn_prof            CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_period          CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_get_data        CONSTANT VARCHAR2(20) := 'GET_DATA';
--
  -- ***�v���t�@�C��
  cv_fin_lease_books     CONSTANT VARCHAR2(40) := 'XXCFF1_FIN_LEASE_BOOKS';             -- �䒠��_FIN���[�X�䒠
  cv_fixed_assets_books  CONSTANT VARCHAR2(40) := 'XXCFF1_FIXED_ASSETS_BOOKS';          -- �䒠��
  cv_je_src_lease        CONSTANT VARCHAR2(40) := 'XXCFF1_JE_SOURCE_LEASE';             -- �d��\�[�X_���[�X
  cv_je_src_vending      CONSTANT VARCHAR2(40) := 'XXCFF1_JE_SOURCE_VENDING';           -- �d��\�[�X_���̋@����
  cv_je_src_asset_man    CONSTANT VARCHAR2(40) := 'XXCFF1_JE_SOURCE_ASSET_MANAGEMENT';  -- �d��\�[�X_���Y�Ǘ�
  cv_je_cat_vd_dep       CONSTANT VARCHAR2(40) := 'XXCFF1_JE_CATEGORY_VD_DEP';          -- �d��J�e�S��_���̋@����U��
  cv_je_cat_dep          CONSTANT VARCHAR2(40) := 'XXCFF1_JE_CATEGORY_DEPRECIATION';    -- �d��J�e�S��_�������p
  cv_dep_cd_chosei       CONSTANT VARCHAR2(40) := 'XXCFF1_DEP_CD_CHOSEI';               -- ����R�[�h_��������
  cv_ptnr_cd_dammy       CONSTANT VARCHAR2(40) := 'XXCFF1_PTNR_CD_DAMMY';               -- �ڋq�R�[�h_��`�Ȃ�
  cv_busi_cd_dammy       CONSTANT VARCHAR2(40) := 'XXCFF1_BUSI_CD_DAMMY';               -- ��ƃR�[�h_��`�Ȃ�
  cv_project_dammy       CONSTANT VARCHAR2(40) := 'XXCFF1_PROJECT_DAMMY';               -- �\��1_��`�Ȃ�
  cv_future_dammy        CONSTANT VARCHAR2(40) := 'XXCFF1_FUTURE_DAMMY';                -- �\��2_��`�Ȃ�
  cv_slip_num_lease      CONSTANT VARCHAR2(40) := 'XXCFF1_SLIP_NUM_LEASE';              -- �`�[�ԍ�_���[�X
--
  -- ***�t�@�C���o��
  cv_file_type_out       CONSTANT VARCHAR2(10) := 'OUTPUT';                     --���b�Z�[�W�o��
  cv_file_type_log       CONSTANT VARCHAR2(10) := 'LOG';                        --���O�o��
--
  -- ***��񒊏o�p
  cv_flag_y              CONSTANT VARCHAR2(1)  := 'Y';
  cv_flag_n              CONSTANT VARCHAR2(1)  := 'N';
  cv_lang                CONSTANT VARCHAR2(50) := USERENV('LANG');
  cv_actual_flag_a       CONSTANT VARCHAR2(1)  := 'A';
-- 2017/06/22 Ver.1.2 Y.Shoji ADD Start
  ct_adj_type_expense    CONSTANT fa_adjustments.adjustment_type%TYPE  := 'EXPENSE';       -- �����^�C�v
-- 2017/06/22 Ver.1.2 Y.Shoji ADD End
--
  -- ***�o�^�p
  cv_status_new          CONSTANT VARCHAR2(3)  := 'NEW';
  cv_tax_code            CONSTANT VARCHAR2(4)  := '0000';
--
  -- ***���t����
  cv_yyyymm              CONSTANT VARCHAR2(7)  := 'YYYY-MM';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***�o���N�t�F�b�`�p��`
  TYPE g_segment1_ttype       IS TABLE OF gl_code_combinations.segment1%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment3_ttype       IS TABLE OF gl_code_combinations.segment3%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment4_ttype       IS TABLE OF gl_code_combinations.segment4%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment3_to_ttype    IS TABLE OF fnd_lookup_values.attribute2%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment4_to_ttype    IS TABLE OF fnd_lookup_values.attribute3%TYPE INDEX BY PLS_INTEGER;
  TYPE g_amount_ttype         IS TABLE OF fa_deprn_detail.deprn_amount%TYPE INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  g_segment1_tab             g_segment1_ttype;
  g_segment3_tab             g_segment3_ttype;
  g_segment4_tab             g_segment4_ttype;
  g_segment3_to_tab          g_segment3_to_ttype;
  g_segment4_to_tab          g_segment4_to_ttype;
  g_amount_tab               g_amount_ttype;
--
  -- ***��������
  -- ��ʉ�vOIF�o�^�����ɂ����錏���o��
  gn_target_lease_cnt       NUMBER;     -- �Ώی���(���[�X)
  gn_target_vd_cnt          NUMBER;     -- �Ώی���(���̋@)
  gn_normal_lease_cnt       NUMBER;     -- ���팏��(���[�X)
  gn_normal_vd_cnt          NUMBER;     -- ���팏��(���̋@)
  gn_error_cnt              NUMBER;     -- �G���[����
--
  -- �����l���
  g_init_rec      xxcff_common1_pkg.init_rtype;
--
  -- �p�����[�^��v���Ԗ�
  gv_period_name  VARCHAR2(100);
--
  -- ***���[�U���
  -- ���O�C�����[�U
  gt_login_user_name  xx03_users_v.user_name%TYPE;
  -- �N�[����(��������)
  gt_login_dept_code  per_people_f.attribute28%TYPE;
  -- ***��v������
  -- ��v���떼
  gt_sob_name         gl_sets_of_books.name%TYPE;
--
  -- ***�v���t�@�C���l
  gv_fin_lease_books       VARCHAR2(100);    -- �䒠��_FIN���[�X�䒠
  gv_fixed_assets_books    VARCHAR2(100);    -- �䒠��
  gv_je_src_lease          VARCHAR2(100);    -- �d��\�[�X_���[�X
  gv_je_src_vending        VARCHAR2(100);    -- �d��\�[�X_���̋@����
  gv_je_src_asset_man      VARCHAR2(100);    -- �d��\�[�X_���Y�Ǘ�
  gv_je_cat_vd_dep         VARCHAR2(100);    -- �d��J�e�S��_���̋@����U��
  gv_je_cat_dep            VARCHAR2(100);    -- �d��J�e�S��_�������p
  gv_dep_cd_chosei         VARCHAR2(100);    -- ����R�[�h_��������
  gv_ptnr_cd_dammy         VARCHAR2(100);    -- �ڋq�R�[�h_��`�Ȃ�
  gv_busi_cd_dammy         VARCHAR2(100);    -- ��ƃR�[�h_��`�Ȃ�
  gv_project_dammy         VARCHAR2(100);    -- �\��1_��`�Ȃ�
  gv_future_dammy          VARCHAR2(100);    -- �\��2_��`�Ȃ�
  gv_slip_num_lease        VARCHAR2(100);    -- �`�[�ԍ�_���[�X
--
  -- ***�J�[�\����`
--
  -- ***�e�[�u���^�z��
--
  /**********************************************************************************
   * Procedure Name   : delete_collections
   * Description      : �R���N�V�����폜
   ***********************************************************************************/
  PROCEDURE delete_collections(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_collections'; -- �v���O������
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
    --�R���N�V���������z��̍폜
    g_segment1_tab.DELETE;     -- ��ЃR�[�h
    g_segment3_tab.DELETE;     -- ����Ȗ�
    g_segment4_tab.DELETE;     -- �⏕�Ȗ�
    g_segment3_to_tab.DELETE;  -- �U�֐抨��Ȗ�
    g_segment4_to_tab.DELETE;  -- �U�֐�⏕�Ȗ�
    g_amount_tab.DELETE;       -- �ؕ����v
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
  END delete_collections;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_vd
   * Description      : ��ʉ�vOIF�o�^�����i���̋@�����U�ցj (A-6)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_vd(
    ov_errbuf         OUT    VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT    VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_vd'; -- �v���O������
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
    cv_xxcff1_asset_category_id  CONSTANT VARCHAR2(30)  := 'XXCFF1_ASSET_CATEGORY_ID'; -- �Q�ƃ^�C�v�F���̋@���Y�J�e�S���Œ�l
    cv_attribute9_1              CONSTANT VARCHAR2(1)   := '1';                        -- DFF9�F1
    cv_attribute9_3              CONSTANT VARCHAR2(1)   := '3';                        -- DFF9�F3
--
    -- *** ���[�J���ϐ� ***
    ln_cnt_chk     NUMBER DEFAULT 0;    -- �`�F�b�N�p����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �Œ莑�Y�䒠�̌������p�̎d�󒊏o�J�[�\��
    CURSOR gl_oif_vd_cur
    IS
-- 2017/06/22 Ver.1.2 Y.Shoji MOD Start
--      SELECT 
--             /*+
--               INDEX(gjh GL_JE_HEADERS_N2)
--               INDEX(gjl GL_JE_LINES_U1)
--               INDEX(fdp FA_DEPRN_PERIODS_U1)
--               INDEX(fdd FA_DEPRN_DETAIL_N3)
--               INDEX(fab FA_ADDITIONS_B_U1)
--               INDEX(xvoh XXCFF_VD_OBJECT_HEADERS_U01)
--             */
--             gcc.segment1           AS segment1        -- ��ЃR�[�h
--            ,gcc.segment3           AS segment3        -- ����Ȗ�
--            ,gcc.segment4           AS segment4        -- �⏕�Ȗ�
--            ,flv.attribute10        AS segment3_to     -- �U�֐抨��Ȗ�
--            ,flv.attribute11        AS segment4_to     -- �U�֐�⏕�Ȗ�
--            ,SUM(fdd.deprn_amount)  AS amount          -- �ؕ����v
--      FROM   gl_je_headers            gjh   -- �d��w�b�_
--            ,gl_je_lines              gjl   -- �d�󖾍�
--            ,gl_je_sources_tl         gjst  -- �d��\�[�X
--            ,gl_je_categories_tl      gjct  -- �d��J�e�S��
--            ,gl_code_combinations     gcc   -- ����Ȗڑg�����}�X�^
--            ,fa_deprn_detail          fdd   -- �������p�ڍ�
--            ,fa_deprn_periods         fdp   -- �������p����
--            ,fa_additions_b           fab   -- ���Y�ڍ׏��
--            ,xxcff_vd_object_headers  xvoh  -- ���̋@����
--            ,fnd_lookup_values        flv   -- �Q�ƕ\
--      WHERE  gjh.je_source              = gjst.je_source_name
--      AND    gjst.language              = cv_lang
--      AND    gjst.user_je_source_name   = gv_je_src_asset_man
--      AND    gjh.je_category            = gjct.je_category_name
--      AND    gjct.language              = cv_lang
--      AND    gjct.user_je_category_name = gv_je_cat_dep
--      AND    gjh.set_of_books_id        = g_init_rec.set_of_books_id    -- ��v����ID
--      AND    gjh.period_name            = gv_period_name                -- ��v����
--      AND    gjh.actual_flag            = cv_actual_flag_a              -- �c���^�C�v
--      AND    gjh.je_header_id           = gjl.je_header_id
--      AND    gjl.reference_5            = gv_fixed_assets_books         -- �䒠
--      AND    gjl.code_combination_id    = gcc.code_combination_id
--      AND    gcc.segment3               = flv.attribute4
--      AND    gcc.segment4               = flv.attribute8
--      AND    gjl.je_header_id           = fdd.je_header_id
--      AND    gjl.je_line_num            = fdd.deprn_expense_je_line_num
--      AND    fdd.book_type_code         = gv_fixed_assets_books         -- �䒠
--      AND    fdd.book_type_code         = fdp.book_type_code
--      AND    fdd.period_counter         = fdp.period_counter
--      AND    fdp.period_name            = gv_period_name                -- ��v����
--      AND    fdd.asset_id               = fab.asset_id
--      AND    fab.tag_number             = xvoh.object_code
--      AND    xvoh.machine_type          = flv.lookup_code
--      AND    flv.lookup_type            = cv_xxcff1_asset_category_id
--      AND    flv.attribute9             IN (cv_attribute9_1 ,cv_attribute9_3)
--      AND    flv.language               = cv_lang
--      AND    flv.enabled_flag           = cv_flag_y
--      AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
--                                                          AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
--      GROUP BY gcc.segment1
--              ,gcc.segment3
--              ,gcc.segment4
--              ,flv.attribute10
--              ,flv.attribute11
      SELECT trn.segment1             segment1      -- ��ЃR�[�h
            ,trn.segment3             segment3      -- ����Ȗ�
            ,trn.segment4             segment4      -- �⏕�Ȗ�
            ,trn.segment3_to          segment3_to   -- �U�֐抨��Ȗ�
            ,trn.segment4_to          segment4_to   -- �U�֐�⏕�Ȗ�
            ,SUM(trn.amount)          amount        -- ���z
      FROM  (SELECT 
                    /*+ 
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(flv FND_LOOKUP_VALUES_U2)
                        INDEX(fdd FA_DEPRN_DETAIL_N2)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xvoh XXCFF_VD_OBJECT_HEADERS_U01)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    gcc.segment1             segment1       -- ��ЃR�[�h
                   ,gcc.segment3             segment3       -- ����Ȗ�
                   ,gcc.segment4             segment4       -- �⏕�Ȗ�
                   ,flv.attribute10          segment3_to    -- �U�֐抨��Ȗ�
                   ,flv.attribute11          segment4_to    -- �U�֐�⏕�Ȗ�
                   ,fdd.deprn_amount - fdd.deprn_adjustment_amount
                                             amount         -- ���z
             FROM   fa_deprn_periods         fdp   -- �������p����
                   ,fa_deprn_detail          fdd   -- �������p�ڍ�
                   ,fa_additions_b           fab   -- ���Y�ڍ׏��
                   ,gl_code_combinations     gcc   -- ����Ȗڑg�����}�X�^
                   ,xxcff_vd_object_headers  xvoh  -- ���̋@����
                   ,fnd_lookup_values        flv   -- ���̋@���Y�J�e�S���Œ�l
             WHERE  fdp.book_type_code                           = gv_fixed_assets_books         -- �䒠
             AND    fdp.period_name                              = gv_period_name                -- ��v����
             AND    fdp.book_type_code                           = fdd.book_type_code
             AND    fdp.period_counter                           = fdd.period_counter
             AND    fdd.deprn_expense_je_line_num                IS NOT NULL
             AND    fdd.deprn_expense_ccid                       = gcc.code_combination_id
             AND    gcc.segment3                                 = flv.attribute4
             AND    gcc.segment4                                 = flv.attribute8
             AND    fdd.asset_id                                 = fab.asset_id
             AND    fab.tag_number                               = xvoh.object_code
             AND    xvoh.machine_type                            = flv.lookup_code
             AND    flv.lookup_type                              = cv_xxcff1_asset_category_id
             AND    flv.attribute9                               IN (cv_attribute9_1 ,cv_attribute9_3)
             AND    flv.language                                 = cv_lang
             AND    flv.enabled_flag                             = cv_flag_y
             AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                                 AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
             UNION ALL
             SELECT 
                    /*+ 
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(flv FND_LOOKUP_VALUES_U2)
                        INDEX(faj FA_ADJUSTMENTS_N4)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xvoh XXCFF_VD_OBJECT_HEADERS_U01) 
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    gcc.segment1             segment1       -- ��ЃR�[�h
                   ,gcc.segment3             segment3       -- ����Ȗ�
                   ,gcc.segment4             segment4       -- �⏕�Ȗ�
                   ,flv.attribute10          segment3_to    -- �U�֐抨��Ȗ�
                   ,flv.attribute11          segment4_to    -- �U�֐�⏕�Ȗ�
                   ,faj.adjustment_amount    amount         -- ���z
             FROM   fa_deprn_periods         fdp   -- �������p����
                   ,fa_adjustments           faj   -- ���Y�������
                   ,fa_additions_b           fab   -- ���Y�ڍ׏��
                   ,gl_code_combinations     gcc   -- ����Ȗڑg�����}�X�^
                   ,xxcff_vd_object_headers  xvoh  -- ���̋@����
                   ,fnd_lookup_values        flv   -- ���̋@���Y�J�e�S���Œ�l
             WHERE  fdp.book_type_code                           = gv_fixed_assets_books         -- �䒠
             AND    fdp.period_name                              = gv_period_name                -- ��v����
             AND    fdp.book_type_code                           = faj.book_type_code
             AND    fdp.period_counter                           = faj.period_counter_created
             AND    faj.adjustment_type                          = ct_adj_type_expense           -- �����^�C�v�FEXPENSE
             AND    faj.code_combination_id                      = gcc.code_combination_id
             AND    gcc.segment3                                 = flv.attribute4
             AND    gcc.segment4                                 = flv.attribute8
             AND    faj.asset_id                                 = fab.asset_id
             AND    fab.tag_number                               = xvoh.object_code
             AND    xvoh.machine_type                            = flv.lookup_code
             AND    flv.lookup_type                              = cv_xxcff1_asset_category_id
             AND    flv.attribute9                               IN (cv_attribute9_1 ,cv_attribute9_3)
             AND    flv.language                                 = cv_lang
             AND    flv.enabled_flag                             = cv_flag_y
             AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                                 AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
            )     trn
      GROUP BY trn.segment1
              ,trn.segment3
              ,trn.segment4
              ,trn.segment3_to
              ,trn.segment4_to
-- 2017/06/22 Ver.1.2 Y.Shoji MOD End
      ;
    g_gl_oif_vd_rec  gl_oif_vd_cur%ROWTYPE;
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
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- 1.���̋@������FA�������p�̎d��f�[�^���擾
    OPEN  gl_oif_vd_cur;
    FETCH gl_oif_vd_cur
    BULK COLLECT INTO 
                      g_segment1_tab     -- ��ЃR�[�h
                     ,g_segment3_tab     -- ����Ȗ�
                     ,g_segment4_tab     -- �⏕�Ȗ�
                     ,g_segment3_to_tab  -- �U�֐抨��Ȗ�
                     ,g_segment4_to_tab  -- �U�֐�⏕�Ȗ�
                     ,g_amount_tab       -- �ؕ����v
                     ;
    --�Ώی����J�E���g
    gn_target_vd_cnt := g_segment1_tab.COUNT; -- test
    CLOSE gl_oif_vd_cur;
--
    -- �擾����������0���̏ꍇ
    IF ( gn_target_vd_cnt = 0 ) THEN
--
      -- 2.����U�֑Ώۂ̋@��敪���݃`�F�b�N
      SELECT COUNT(0) cnt_chk
      INTO   ln_cnt_chk
      FROM   fnd_lookup_values     flv   -- �Q�ƕ\
      WHERE  flv.lookup_type            = cv_xxcff1_asset_category_id
      AND    flv.attribute9             IN (cv_attribute9_1 ,cv_attribute9_3)
      AND    flv.language               = cv_lang
      AND    flv.enabled_flag           = cv_flag_y
      AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                          AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
      ;
--
      -- �擾����������1���ȏ�̏ꍇ
      IF ( ln_cnt_chk > 0 ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_xxcff_00165   -- �擾�Ώۃf�[�^����
                                                      ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                      ,cv_msg_xxcff_50290)  -- ���̋@�����U��
                                                      ,1
                                                      ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- �擾����������1���ȏ�̏ꍇ
    ELSE
      <<gl_oif_vd_loop>>
      FOR ln_loop_cnt IN 1 .. gn_target_vd_cnt LOOP
--
        -- 3.��ʉ�vOIF�e�[�u���֓o�^�i�ؕ��j
        INSERT INTO gl_interface(
           status                -- �X�e�[�^�X
          ,set_of_books_id       -- ��v����ID
          ,accounting_date       -- �d��L�����t
          ,currency_code         -- �ʉ݃R�[�h
          ,date_created          -- �V�K�쐬���t
          ,created_by            -- �V�K�쐬��ID
          ,actual_flag           -- �c���^�C�v
          ,user_je_category_name -- �d��J�e�S����
          ,user_je_source_name   -- �d��\�[�X��
          ,segment1              -- ��ЃR�[�h
          ,segment2              -- ����R�[�h
          ,segment3              -- ����ȖڃR�[�h
          ,segment4              -- �⏕�ȖڃR�[�h
          ,segment5              -- �ڋq�R�[�h
          ,segment6              -- ��ƃR�[�h
          ,segment7              -- �\��1
          ,segment8              -- �\��2
          ,entered_dr            -- �ؕ����z
          ,entered_cr            -- �ݕ����z
          ,period_name           -- ��v���Ԗ�
          ,attribute1            -- �ŋ敪
          ,attribute3            -- �`�[�ԍ�
          ,attribute4            -- �N�[����
          ,attribute5            -- �`�[���͎�
          ,context               -- �R���e�L�X�g
        ) VALUES (
           cv_status_new                                -- �X�e�[�^�X
          ,g_init_rec.set_of_books_id                   -- ��v����ID
          ,LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) -- �d��L�����t
          ,g_init_rec.currency_code                     -- �ʉ݃R�[�h
          ,cd_creation_date                             -- �V�K�쐬���t
          ,cn_created_by                                -- �V�K�쐬��ID
          ,cv_actual_flag_a                             -- �c���^�C�v
          ,gv_je_cat_vd_dep                             -- �d��J�e�S����
          ,gv_je_src_vending                            -- �d��\�[�X��
          ,g_segment1_tab(ln_loop_cnt)                  -- ��ЃR�[�h
          ,gv_dep_cd_chosei                             -- ����R�[�h
          ,g_segment3_to_tab(ln_loop_cnt)               -- ����ȖڃR�[�h
          ,g_segment4_to_tab(ln_loop_cnt)               -- �⏕�ȖڃR�[�h
          ,gv_ptnr_cd_dammy                             -- �ڋq�R�[�h
          ,gv_busi_cd_dammy                             -- ��ƃR�[�h
          ,gv_project_dammy                             -- �\��1
          ,gv_future_dammy                              -- �\��2
          ,g_amount_tab(ln_loop_cnt)                    -- �ؕ����z
          ,0                                            -- �ݕ����z
          ,gv_period_name                               -- ��v���Ԗ�
          ,cv_tax_code                                  -- �ŋ敪
          ,gv_slip_num_lease                            -- �`�[�ԍ�
          ,gt_login_dept_code                           -- �N�[����
          ,gt_login_user_name                           -- �`�[���͎�
          ,gt_sob_name                                  -- ��v���떼
        );
--
        -- 4.��ʉ�vOIF�e�[�u���֓o�^�i�ݕ��j
        INSERT INTO gl_interface(
           status                -- �X�e�[�^�X
          ,set_of_books_id       -- ��v����ID
          ,accounting_date       -- �d��L�����t
          ,currency_code         -- �ʉ݃R�[�h
          ,date_created          -- �V�K�쐬���t
          ,created_by            -- �V�K�쐬��ID
          ,actual_flag           -- �c���^�C�v
          ,user_je_category_name -- �d��J�e�S����
          ,user_je_source_name   -- �d��\�[�X��
          ,segment1              -- ��ЃR�[�h
          ,segment2              -- ����R�[�h
          ,segment3              -- ����ȖڃR�[�h
          ,segment4              -- �⏕�ȖڃR�[�h
          ,segment5              -- �ڋq�R�[�h
          ,segment6              -- ��ƃR�[�h
          ,segment7              -- �\��1
          ,segment8              -- �\��2
          ,entered_dr            -- �ؕ����z
          ,entered_cr            -- �ݕ����z
          ,period_name           -- ��v���Ԗ�
          ,attribute1            -- �ŋ敪
          ,attribute3            -- �`�[�ԍ�
          ,attribute4            -- �N�[����
          ,attribute5            -- �`�[���͎�
          ,context               -- �R���e�L�X�g
        ) VALUES (
           cv_status_new                                -- �X�e�[�^�X
          ,g_init_rec.set_of_books_id                   -- ��v����ID
          ,LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) -- �d��L�����t
          ,g_init_rec.currency_code                     -- �ʉ݃R�[�h
          ,cd_creation_date                             -- �V�K�쐬���t
          ,cn_created_by                                -- �V�K�쐬��ID
          ,cv_actual_flag_a                             -- �c���^�C�v
          ,gv_je_cat_vd_dep                             -- �d��J�e�S����
          ,gv_je_src_vending                            -- �d��\�[�X��
          ,g_segment1_tab(ln_loop_cnt)                  -- ��ЃR�[�h
          ,gv_dep_cd_chosei                             -- ����R�[�h
          ,g_segment3_tab(ln_loop_cnt)                  -- ����ȖڃR�[�h
          ,g_segment4_tab(ln_loop_cnt)                  -- �⏕�ȖڃR�[�h
          ,gv_ptnr_cd_dammy                             -- �ڋq�R�[�h
          ,gv_busi_cd_dammy                             -- ��ƃR�[�h
          ,gv_project_dammy                             -- �\��1
          ,gv_future_dammy                              -- �\��2
          ,0                                            -- �ؕ����z
          ,g_amount_tab(ln_loop_cnt)                    -- �ݕ����z
          ,gv_period_name                               -- ��v���Ԗ�
          ,cv_tax_code                                  -- �ŋ敪
          ,gv_slip_num_lease                            -- �`�[�ԍ�
          ,gt_login_dept_code                           -- �N�[����
          ,gt_login_user_name                           -- �`�[���͎�
          ,gt_sob_name                                  -- ��v���떼
        );
--
        -- ���������J�E���g
        gn_normal_vd_cnt := gn_normal_vd_cnt + 1;
--
      END LOOP gl_oif_lease_loop;
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
  END ins_gl_oif_vd;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_lease
   * Description      : ��ʉ�vOIF�o�^�����i���[�X�����U�ցj (A-5)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_lease(
    ov_errbuf         OUT    VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT    VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_lease'; -- �v���O������
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
    cv_xxcff1_lease_class_check  CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_CLASS_CHECK'; -- �Q�ƃ^�C�v�F���[�X��ʃ`�F�b�N
--
    -- *** ���[�J���ϐ� ***
    ln_cnt_chk     NUMBER DEFAULT 0;    -- �`�F�b�N�p����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- FIN���[�X�䒠�̌������p�̎d�󒊏o�J�[�\��
    CURSOR gl_oif_lease_cur
    IS
-- 2017/06/22 Ver.1.2 Y.Shoji MOD Start
--      SELECT 
--             /*+
---- 2017/05/15 Ver.1.1 Y.Shoji MOD Start
----               INDEX(gjh GL_JE_HEADERS_N2)
--               LEADING(xlcv.ffvs fdp gjct gjst flv xlcv.ffv gcc gjl fdd fab xcl)
--               USE_NL(gjl gjh)
--               USE_NL(xcl xoh)
--               INDEX(xoh XXCFF_OBJECT_HEADERS_PK)
---- 2017/05/15 Ver.1.1 Y.Shoji MOD End
--             */
--             gcc.segment1           AS segment1        -- ��ЃR�[�h
--            ,gcc.segment3           AS segment3        -- ����Ȗ�
--            ,gcc.segment4           AS segment4        -- �⏕�Ȗ�
--            ,flv.attribute2         AS segment3_to     -- �U�֐抨��Ȗ�
--            ,flv.attribute3         AS segment4_to     -- �U�֐�⏕�Ȗ�
--            ,SUM(fdd.deprn_amount)  AS amount          -- �ؕ����v
--      FROM   gl_je_headers         gjh   -- �d��w�b�_
--            ,gl_je_lines           gjl   -- �d�󖾍�
--            ,gl_je_sources_tl      gjst  -- �d��\�[�X
--            ,gl_je_categories_tl   gjct  -- �d��J�e�S��
--            ,gl_code_combinations  gcc   -- ����Ȗڑg�����}�X�^
--            ,fa_deprn_detail       fdd   -- �������p�ڍ�
--            ,fa_deprn_periods      fdp   -- �������p����
--            ,fa_additions_b        fab   -- ���Y�ڍ׏��
--            ,xxcff_contract_lines  xcl   -- ���[�X�_�񖾍�
--            ,xxcff_object_headers  xoh   -- ���[�X����
--            ,xxcff_lease_class_v   xlcv  -- ���[�X��ʃr���[
--            ,fnd_lookup_values     flv   -- �Q�ƕ\
--      WHERE  gjh.je_source              = gjst.je_source_name
--      AND    gjst.language              = cv_lang
--      AND    gjst.user_je_source_name   = gv_je_src_asset_man
--      AND    gjh.je_category            = gjct.je_category_name
--      AND    gjct.language              = cv_lang
--      AND    gjct.user_je_category_name = gv_je_cat_dep
--      AND    gjh.set_of_books_id        = g_init_rec.set_of_books_id    -- ��v����ID
--      AND    gjh.period_name            = gv_period_name                -- ��v����
--      AND    gjh.actual_flag            = cv_actual_flag_a              -- �c���^�C�v
--      AND    gjh.je_header_id           = gjl.je_header_id
--      AND    gjl.reference_5            = gv_fin_lease_books            -- �䒠
--      AND    gjl.code_combination_id    = gcc.code_combination_id
--      AND    gcc.segment3               = xlcv.deprn_acct
--      AND    gcc.segment4               = xlcv.deprn_sub_acct
--      AND    gjl.je_header_id           = fdd.je_header_id
--      AND    gjl.je_line_num            = fdd.deprn_expense_je_line_num
--      AND    fdd.book_type_code         = gv_fin_lease_books            -- �䒠
--      AND    fdd.book_type_code         = fdp.book_type_code
--      AND    fdd.period_counter         = fdp.period_counter
--      AND    fdp.period_name            = gv_period_name                -- ��v����
--      AND    fdd.asset_id               = fab.asset_id
--      AND    TO_NUMBER(fab.attribute10) = xcl.contract_line_id
--      AND    xcl.object_header_id       = xoh.object_header_id
--      AND    xoh.lease_class            = xlcv.lease_class_code
--      AND    xlcv.lease_class_code      = flv.lookup_code
--      AND    flv.lookup_type            = cv_xxcff1_lease_class_check
--      AND    flv.attribute1             = cv_flag_y
--      AND    flv.language               = cv_lang
--      AND    flv.enabled_flag           = cv_flag_y
--      AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
--                                                          AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
--      GROUP BY gcc.segment1
--              ,gcc.segment3
--              ,gcc.segment4
--              ,flv.attribute2
--              ,flv.attribute3
      SELECT trn.segment1             segment1      -- ��ЃR�[�h
            ,trn.segment3             segment3      -- ����Ȗ�
            ,trn.segment4             segment4      -- �⏕�Ȗ�
            ,trn.segment3_to          segment3_to   -- �U�֐抨��Ȗ�
            ,trn.segment4_to          segment4_to   -- �U�֐�⏕�Ȗ�
            ,SUM(trn.amount)          amount        -- ���z
      FROM  (SELECT 
                    /*+ 
                        LEADING(a)
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(fdd FA_DEPRN_DETAIL_N2)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xcl XXCFF_CONTRACT_LINES_PK)
                        INDEX(xoh XXCFF_OBJECT_HEADERS_PK)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    gcc.segment1             segment1       -- ��ЃR�[�h
                   ,gcc.segment3             segment3       -- ����Ȗ�
                   ,gcc.segment4             segment4       -- �⏕�Ȗ�
                   ,xlcv2.segment3_to        segment3_to    -- �U�֐抨��Ȗ�
                   ,xlcv2.segment4_to        segment4_to    -- �U�֐�⏕�Ȗ�
                   ,fdd.deprn_amount - fdd.deprn_adjustment_amount
                                             amount         -- ���z
             FROM   
                    fa_deprn_periods      fdp   -- �������p����
                   ,fa_deprn_detail       fdd   -- �������p�ڍ�
                   ,fa_additions_b        fab   -- ���Y�ڍ׏��
                   ,gl_code_combinations  gcc   -- ����Ȗڑg�����}�X�^
                   ,xxcff_contract_lines  xcl   -- ���[�X�_�񖾍�
                   ,xxcff_object_headers  xoh   -- ���[�X����
                   ,(SELECT 
                            /*+ 
                                QB_NAME(a)
                                LEADING(flv xlcv.ffvs xlcv.ffvt xlcv.ffv)
                                INDEX(flv FND_LOOKUP_VALUES_U2)
                                INDEX(xlcv.ffv FND_FLEX_VALUES_N1)
                                INDEX(xlcv.ffvt FND_FLEX_VALUES_TL_U1)
                                INDEX(xlcv.ffvt FND_FLEX_VALUE_SETS_U2)
                             */
                            xlcv.lease_class_code  lease_class_code -- ���[�X��ʃR�[�h
                           ,xlcv.deprn_acct        deprn_acct       -- �U�֌�����Ȗ�
                           ,xlcv.deprn_sub_acct    deprn_sub_acct   -- �U�֌��⏕�Ȗ�
                           ,flv.attribute2         segment3_to      -- �U�֐抨��Ȗ�
                           ,flv.attribute3         segment4_to      -- �U�֐�⏕�Ȗ�
                     FROM   xxcff_lease_class_v   xlcv  -- ���[�X��ʃr���[
                           ,fnd_lookup_values     flv   -- ���[�X��ʃ`�F�b�N
                     WHERE  flv.lookup_code                              = xlcv.lease_class_code
                     AND    flv.lookup_type                              = cv_xxcff1_lease_class_check
                     AND    flv.attribute1                               = cv_flag_y
                     AND    flv.language                                 = cv_lang
                     AND    flv.enabled_flag                             = cv_flag_y
                     AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                                         AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                    )                          xlcv2
             WHERE  fdp.book_type_code         = gv_fin_lease_books            -- �䒠
             AND    fdp.period_name            = gv_period_name                -- ��v����
             AND    fdp.book_type_code         = fdd.book_type_code
             AND    fdp.period_counter         = fdd.period_counter
             AND    fdd.deprn_expense_je_line_num IS NOT NULL
             AND    fdd.deprn_expense_ccid     = gcc.code_combination_id
             AND    gcc.segment3               = xlcv2.deprn_acct 
             AND    gcc.segment4               = xlcv2.deprn_sub_acct
             AND    fdd.asset_id               = fab.asset_id
             AND    TO_NUMBER(fab.attribute10) = xcl.contract_line_id
             AND    xcl.object_header_id       = xoh.object_header_id
             AND    xoh.lease_class            = xlcv2.lease_class_code
             UNION ALL
             SELECT 
                    /*+ 
                        LEADING(b)
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(faj FA_ADJUSTMENTS_N4)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xcl XXCFF_CONTRACT_LINES_PK)
                        INDEX(xoh XXCFF_OBJECT_HEADERS_PK)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    gcc.segment1             segment1       -- ��ЃR�[�h
                   ,gcc.segment3             segment3       -- ����Ȗ�
                   ,gcc.segment4             segment4       -- �⏕�Ȗ�
                   ,xlcv2.segment3_to        segment3_to    -- �U�֐抨��Ȗ�
                   ,xlcv2.segment4_to        segment4_to    -- �U�֐�⏕�Ȗ�
                   ,faj.adjustment_amount    amount         -- ���z
             FROM   fa_deprn_periods      fdp   -- �������p����
                   ,fa_adjustments        faj   -- ���Y�������
                   ,fa_additions_b        fab   -- ���Y�ڍ׏��
                   ,gl_code_combinations  gcc   -- ����Ȗڑg�����}�X�^
                   ,xxcff_contract_lines  xcl   -- ���[�X�_�񖾍�
                   ,xxcff_object_headers  xoh   -- ���[�X����
                   ,(SELECT 
                            /*+ 
                                QB_NAME(b)
                                LEADING(flv xlcv.ffvs xlcv.ffvt xlcv.ffv)
                                INDEX(flv FND_LOOKUP_VALUES_U2)
                                INDEX(xlcv.ffv FND_FLEX_VALUES_N1)
                                INDEX(xlcv.ffvt FND_FLEX_VALUES_TL_U1)
                                INDEX(xlcv.ffvt FND_FLEX_VALUE_SETS_U2)
                             */
                            xlcv.lease_class_code  lease_class_code -- ���[�X��ʃR�[�h
                           ,xlcv.deprn_acct        deprn_acct       -- �U�֌�����Ȗ�
                           ,xlcv.deprn_sub_acct    deprn_sub_acct   -- �U�֌��⏕�Ȗ�
                           ,flv.attribute2         segment3_to      -- �U�֐抨��Ȗ�
                           ,flv.attribute3         segment4_to      -- �U�֐�⏕�Ȗ�
                     FROM   xxcff_lease_class_v   xlcv  -- ���[�X��ʃr���[
                           ,fnd_lookup_values     flv   -- ���[�X��ʃ`�F�b�N
                     WHERE  flv.lookup_code                              = xlcv.lease_class_code
                     AND    flv.lookup_type                              = cv_xxcff1_lease_class_check
                     AND    flv.attribute1                               = cv_flag_y
                     AND    flv.language                                 = cv_lang
                     AND    flv.enabled_flag                             = cv_flag_y
                     AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                                         AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                    )                          xlcv2
             WHERE  fdp.book_type_code         = gv_fin_lease_books            -- �䒠
             AND    fdp.period_name            = gv_period_name                -- ��v����
             AND    fdp.book_type_code         = faj.book_type_code
             AND    fdp.period_counter         = faj.period_counter_created
             AND    faj.adjustment_type        = ct_adj_type_expense           -- �����^�C�v�FEXPENSE
             AND    faj.code_combination_id    = gcc.code_combination_id
             AND    gcc.segment3               = xlcv2.deprn_acct 
             AND    gcc.segment4               = xlcv2.deprn_sub_acct
             AND    faj.asset_id               = fab.asset_id
             AND    TO_NUMBER(fab.attribute10) = xcl.contract_line_id
             AND    xcl.object_header_id       = xoh.object_header_id
             AND    xoh.lease_class            = xlcv2.lease_class_code
             ) trn
      GROUP BY trn.segment1
              ,trn.segment3
              ,trn.segment4
              ,trn.segment3_to
              ,trn.segment4_to
-- 2017/06/22 Ver.1.2 Y.Shoji MOD End
      ;
    g_gl_oif_lease_rec  gl_oif_lease_cur%ROWTYPE;
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
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- 1.���[�X������FA�������p�̎d��f�[�^���擾
    OPEN  gl_oif_lease_cur;
    FETCH gl_oif_lease_cur
    BULK COLLECT INTO 
                      g_segment1_tab     -- ��ЃR�[�h
                     ,g_segment3_tab     -- ����Ȗ�
                     ,g_segment4_tab     -- �⏕�Ȗ�
                     ,g_segment3_to_tab  -- �U�֐抨��Ȗ�
                     ,g_segment4_to_tab  -- �U�֐�⏕�Ȗ�
                     ,g_amount_tab       -- �ؕ����v
                     ;
    --�Ώی����J�E���g
    gn_target_lease_cnt := g_segment1_tab.COUNT; -- test
    CLOSE gl_oif_lease_cur;
--
    -- �擾����������0���̏ꍇ
    IF ( gn_target_lease_cnt = 0 ) THEN
--
      -- 2.����U�֑Ώۂ̃��[�X��ʑ��݃`�F�b�N
      SELECT COUNT(0) cnt_chk
      INTO   ln_cnt_chk
      FROM   fnd_lookup_values     flv   -- �Q�ƕ\
      WHERE  flv.lookup_type            = cv_xxcff1_lease_class_check
      AND    flv.attribute1             = cv_flag_y
      AND    flv.language               = cv_lang
      AND    flv.enabled_flag           = cv_flag_y
      AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                          AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
      ;
--
      -- �擾����������1���ȏ�̏ꍇ
      IF ( ln_cnt_chk > 0 ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_xxcff_00165   -- �擾�Ώۃf�[�^����
                                                      ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                      ,cv_msg_xxcff_50289)  -- ���[�X�����U��
                                                      ,1
                                                      ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- �擾����������1���ȏ�̏ꍇ
    ELSE
      <<gl_oif_lease_loop>>
      FOR ln_loop_cnt IN 1 .. gn_target_lease_cnt LOOP
--
        -- 3.��ʉ�vOIF�e�[�u���֓o�^�i�ؕ��j
        INSERT INTO gl_interface(
           status                -- �X�e�[�^�X
          ,set_of_books_id       -- ��v����ID
          ,accounting_date       -- �d��L�����t
          ,currency_code         -- �ʉ݃R�[�h
          ,date_created          -- �V�K�쐬���t
          ,created_by            -- �V�K�쐬��ID
          ,actual_flag           -- �c���^�C�v
          ,user_je_category_name -- �d��J�e�S����
          ,user_je_source_name   -- �d��\�[�X��
          ,segment1              -- ��ЃR�[�h
          ,segment2              -- ����R�[�h
          ,segment3              -- ����ȖڃR�[�h
          ,segment4              -- �⏕�ȖڃR�[�h
          ,segment5              -- �ڋq�R�[�h
          ,segment6              -- ��ƃR�[�h
          ,segment7              -- �\��1
          ,segment8              -- �\��2
          ,entered_dr            -- �ؕ����z
          ,entered_cr            -- �ݕ����z
          ,period_name           -- ��v���Ԗ�
          ,attribute1            -- �ŋ敪
          ,attribute3            -- �`�[�ԍ�
          ,attribute4            -- �N�[����
          ,attribute5            -- �`�[���͎�
          ,context               -- �R���e�L�X�g
        ) VALUES (
           cv_status_new                                -- �X�e�[�^�X
          ,g_init_rec.set_of_books_id                   -- ��v����ID
          ,LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) -- �d��L�����t
          ,g_init_rec.currency_code                     -- �ʉ݃R�[�h
          ,cd_creation_date                             -- �V�K�쐬���t
          ,cn_created_by                                -- �V�K�쐬��ID
          ,cv_actual_flag_a                             -- �c���^�C�v
          ,gv_je_cat_vd_dep                             -- �d��J�e�S����
          ,gv_je_src_lease                              -- �d��\�[�X��
          ,g_segment1_tab(ln_loop_cnt)                  -- ��ЃR�[�h
          ,gv_dep_cd_chosei                             -- ����R�[�h
          ,g_segment3_to_tab(ln_loop_cnt)               -- ����ȖڃR�[�h
          ,g_segment4_to_tab(ln_loop_cnt)               -- �⏕�ȖڃR�[�h
          ,gv_ptnr_cd_dammy                             -- �ڋq�R�[�h
          ,gv_busi_cd_dammy                             -- ��ƃR�[�h
          ,gv_project_dammy                             -- �\��1
          ,gv_future_dammy                              -- �\��2
          ,g_amount_tab(ln_loop_cnt)                    -- �ؕ����z
          ,0                                            -- �ݕ����z
          ,gv_period_name                               -- ��v���Ԗ�
          ,cv_tax_code                                  -- �ŋ敪
          ,gv_slip_num_lease                            -- �`�[�ԍ�
          ,gt_login_dept_code                           -- �N�[����
          ,gt_login_user_name                           -- �`�[���͎�
          ,gt_sob_name                                  -- ��v���떼
        );
--
        -- 4.��ʉ�vOIF�e�[�u���֓o�^�i�ݕ��j
        INSERT INTO gl_interface(
           status                -- �X�e�[�^�X
          ,set_of_books_id       -- ��v����ID
          ,accounting_date       -- �d��L�����t
          ,currency_code         -- �ʉ݃R�[�h
          ,date_created          -- �V�K�쐬���t
          ,created_by            -- �V�K�쐬��ID
          ,actual_flag           -- �c���^�C�v
          ,user_je_category_name -- �d��J�e�S����
          ,user_je_source_name   -- �d��\�[�X��
          ,segment1              -- ��ЃR�[�h
          ,segment2              -- ����R�[�h
          ,segment3              -- ����ȖڃR�[�h
          ,segment4              -- �⏕�ȖڃR�[�h
          ,segment5              -- �ڋq�R�[�h
          ,segment6              -- ��ƃR�[�h
          ,segment7              -- �\��1
          ,segment8              -- �\��2
          ,entered_dr            -- �ؕ����z
          ,entered_cr            -- �ݕ����z
          ,period_name           -- ��v���Ԗ�
          ,attribute1            -- �ŋ敪
          ,attribute3            -- �`�[�ԍ�
          ,attribute4            -- �N�[����
          ,attribute5            -- �`�[���͎�
          ,context               -- �R���e�L�X�g
        ) VALUES (
           cv_status_new                                -- �X�e�[�^�X
          ,g_init_rec.set_of_books_id                   -- ��v����ID
          ,LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) -- �d��L�����t
          ,g_init_rec.currency_code                     -- �ʉ݃R�[�h
          ,cd_creation_date                             -- �V�K�쐬���t
          ,cn_created_by                                -- �V�K�쐬��ID
          ,cv_actual_flag_a                             -- �c���^�C�v
          ,gv_je_cat_vd_dep                             -- �d��J�e�S����
          ,gv_je_src_lease                              -- �d��\�[�X��
          ,g_segment1_tab(ln_loop_cnt)                  -- ��ЃR�[�h
          ,gv_dep_cd_chosei                             -- ����R�[�h
          ,g_segment3_tab(ln_loop_cnt)                  -- ����ȖڃR�[�h
          ,g_segment4_tab(ln_loop_cnt)                  -- �⏕�ȖڃR�[�h
          ,gv_ptnr_cd_dammy                             -- �ڋq�R�[�h
          ,gv_busi_cd_dammy                             -- ��ƃR�[�h
          ,gv_project_dammy                             -- �\��1
          ,gv_future_dammy                              -- �\��2
          ,0                                            -- �ؕ����z
          ,g_amount_tab(ln_loop_cnt)                    -- �ݕ����z
          ,gv_period_name                               -- ��v���Ԗ�
          ,cv_tax_code                                  -- �ŋ敪
          ,gv_slip_num_lease                            -- �`�[�ԍ�
          ,gt_login_dept_code                           -- �N�[����
          ,gt_login_user_name                           -- �`�[���͎�
          ,gt_sob_name                                  -- ��v���떼
        );
--
        -- ���������J�E���g
        gn_normal_lease_cnt := gn_normal_lease_cnt + 1;
--
      END LOOP gl_oif_lease_loop;
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
  END ins_gl_oif_lease;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_exist
   * Description      : �O��쐬�ςݕ���U�֎d�󑶍݃`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE chk_data_exist(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_data_exist'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
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
    ln_cnt_chk     NUMBER DEFAULT 0;    -- �`�F�b�N�p����
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
    --==============================================================
    -- 1.��ʉ�vOIF�Ƀ��[�X�����̕���U�֎d�󂪑��݂��Ȃ����Ƃ��m�F
    --==============================================================
    SELECT COUNT(0) cnt_chk
    INTO   ln_cnt_chk
    FROM   gl_interface    gi -- ��ʉ�vOIF
    WHERE  gi.user_je_source_name   = gv_je_src_lease   -- �d��\�[�X_���[�X
    AND    gi.user_je_category_name = gv_je_cat_vd_dep  -- �d��J�e�S��_���̋@����U��
    AND    gi.period_name           = gv_period_name
    ;
--
    -- �擾����������1���ȏ�̏ꍇ
    IF ( ln_cnt_chk > 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00246   -- ���[�X�����d�󑶍݃`�F�b�N(��ʉ�vOIF)
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.��ʉ�vOIF�Ɏ��̋@�����̕���U�֎d�󂪑��݂��Ȃ����Ƃ��m�F
    --==============================================================
    SELECT COUNT(0) cnt_chk
    INTO   ln_cnt_chk
    FROM   gl_interface    gi -- ��ʉ�vOIF
    WHERE  gi.user_je_source_name   = gv_je_src_vending  -- �d��\�[�X_���̋@����
    AND    gi.user_je_category_name = gv_je_cat_vd_dep   -- �d��J�e�S��_���̋@����U��
    AND    gi.period_name           = gv_period_name
    ;
--
    -- �擾����������1���ȏ�̏ꍇ
    IF ( ln_cnt_chk > 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00247   -- ���̋@�����d�󑶍݃`�F�b�N(��ʉ�vOIF)
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 3.�d��w�b�_�Ƀ��[�X�����̕���U�֎d�󂪑��݂��Ȃ����Ƃ��m�F
    --==============================================================
    SELECT COUNT(0) cnt_chk
    INTO   ln_cnt_chk
    FROM   gl_je_headers       gjh  -- �d��w�b�_
          ,gl_je_sources_tl    gjst -- �d��\�[�X
          ,gl_je_categories_tl gjct -- �d��J�e�S��
    WHERE  gjh.je_source              = gjst.je_source_name
    AND    gjst.language              = cv_lang
    AND    gjst.user_je_source_name   = gv_je_src_lease          -- �d��\�[�X_���[�X
    AND    gjh.je_category            = gjct.je_category_name
    AND    gjct.language              = cv_lang
    AND    gjct.user_je_category_name = gv_je_cat_vd_dep         -- �d��J�e�S��_���̋@����U��
    AND    gjh.period_name            = gv_period_name
    ;
--
    -- �擾����������1���ȏ�̏ꍇ
    IF ( ln_cnt_chk > 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00248   -- ���[�X��������U�֎d�󑶍݃`�F�b�N�i�d��w�b�_�j
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 4.�d��w�b�_�Ɏ��̋@�����̕���U�֎d�󂪑��݂��Ȃ����Ƃ��m�F
    --==============================================================
    SELECT COUNT(0) cnt_chk
    INTO   ln_cnt_chk
    FROM   gl_je_headers       gjh  -- �d��w�b�_
          ,gl_je_sources_tl    gjst -- �d��\�[�X
          ,gl_je_categories_tl gjct -- �d��J�e�S��
    WHERE  gjh.je_source              = gjst.je_source_name
    AND    gjst.language              = cv_lang
    AND    gjst.user_je_source_name   = gv_je_src_vending      -- �d��\�[�X_���̋@����
    AND    gjh.je_category            = gjct.je_category_name
    AND    gjct.language              = cv_lang
    AND    gjct.user_je_category_name = gv_je_cat_vd_dep       -- �d��J�e�S��_���̋@����U��
    AND    gjh.period_name            = gv_period_name
    ;
--
    -- �擾����������1���ȏ�̏ꍇ
    IF ( ln_cnt_chk > 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00249   -- ���̋@��������U�֎d�󑶍݃`�F�b�N�i�d��w�b�_�j
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
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
  END chk_data_exist;
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
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_closing_status_o   CONSTANT VARCHAR2(1)  := 'O';      -- �X�e�[�^�X�F�I�[�v��
    cv_app_short_name     CONSTANT VARCHAR2(5)  := 'SQLGL';  -- GL
--
    -- *** ���[�J���ϐ� ***
    ln_cnt_chk            NUMBER DEFAULT 0;    -- �`�F�b�N�p����
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
    --======================================
    -- GL��v���ԃ`�F�b�N
    --======================================
    SELECT count(0)   cnt_chk
    INTO   ln_cnt_chk
    FROM   gl_period_statuses  gps   -- ��v�J�����_�X�e�[�^�X
          ,fnd_application     fa    -- �A�v���P�[�V����
    WHERE  gps.period_name            = gv_period_name
    AND    gps.closing_status         = cv_closing_status_o
    AND    gps.adjustment_period_flag = cv_flag_n
    AND    gps.set_of_books_id        = g_init_rec.set_of_books_id
    AND    gps.application_id         = fa.application_id
    AND    fa.application_short_name  = cv_app_short_name
    ;
--
    -- ��v���ԃX�e�[�^�X�擾
    IF ( ln_cnt_chk = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00130   -- GL��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
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
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : �v���t�@�C���擾����(A-2)
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
    -- 1.�䒠��_FIN���[�X�䒠
    gv_fin_lease_books := FND_PROFILE.VALUE(cv_fin_lease_books);
    IF (gv_fin_lease_books IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50287)  -- XXCFF:�䒠��_FIN���[�X�䒠
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 2.�䒠��
    gv_fixed_assets_books := FND_PROFILE.VALUE(cv_fixed_assets_books);
    IF (gv_fixed_assets_books IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50273)  -- XXCFF:�䒠��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 3.�d��\�[�X_���[�X
    gv_je_src_lease := FND_PROFILE.VALUE(cv_je_src_lease);
    IF (gv_je_src_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50146)  -- XXCFF:�d��\�[�X_���[�X
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 4.�d��\�[�X_���̋@����
    gv_je_src_vending := FND_PROFILE.VALUE(cv_je_src_vending);
    IF (gv_je_src_vending IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50255)  -- XXCFF:�d��\�[�X_���̋@����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 5.�d��\�[�X_���Y�Ǘ�
    gv_je_src_asset_man := FND_PROFILE.VALUE(cv_je_src_asset_man);
    IF (gv_je_src_asset_man IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50291)  -- XXCFF:�d��\�[�X_���Y�Ǘ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 6.�d��J�e�S��_���̋@����U��
    gv_je_cat_vd_dep := FND_PROFILE.VALUE(cv_je_cat_vd_dep);
    IF (gv_je_cat_vd_dep IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50288)  -- XXCFF:�d��J�e�S��_���̋@����U��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 7.�d��J�e�S��_�������p
    gv_je_cat_dep := FND_PROFILE.VALUE(cv_je_cat_dep);
    IF (gv_je_cat_dep IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50292)  -- XXCFF:�d��J�e�S��_�������p
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 8.����R�[�h_��������
    gv_dep_cd_chosei := FND_PROFILE.VALUE(cv_dep_cd_chosei);
    IF (gv_dep_cd_chosei IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50078)  -- XXCFF:����R�[�h_��������
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 9.�ڋq�R�[�h_��`�Ȃ�
    gv_ptnr_cd_dammy := FND_PROFILE.VALUE(cv_ptnr_cd_dammy);
    IF (gv_ptnr_cd_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50079)  -- XXCFF:�ڋq�R�[�h_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 10.��ƃR�[�h_��`�Ȃ�
    gv_busi_cd_dammy := FND_PROFILE.VALUE(cv_busi_cd_dammy);
    IF (gv_busi_cd_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50080)  -- XXCFF:��ƃR�[�h_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 11.�\��1_��`�Ȃ�
    gv_project_dammy := FND_PROFILE.VALUE(cv_project_dammy);
    IF (gv_project_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50081)  -- XXCFF:�\��1_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 12.�\��2_��`�Ȃ�
    gv_future_dammy := FND_PROFILE.VALUE(cv_future_dammy);
    IF (gv_future_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50082)  -- XXCFF:�\��2_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 13.�`�[�ԍ�_���[�X
    gv_slip_num_lease := FND_PROFILE.VALUE(cv_slip_num_lease);
    IF (gv_slip_num_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_xxcff_50155)  -- XXCFF:�`�[�ԍ�_���[�X
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
    -- �����l���̎擾
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- �����l���
      ,ov_errbuf   => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
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
    -- �R���J�����g�p�����[�^�l�o��(���O)
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
    --===========================================
    -- ���[�U���(���O�C�����[�U�A��������)�擾
    --===========================================
    BEGIN
      SELECT xuv.user_name   login_user_name   --���O�C�����[�U
            ,ppf.attribute28 login_dept_code   --�N�[���� (��������)
      INTO   gt_login_user_name
            ,gt_login_dept_code
      FROM   xx03_users_v xuv
            ,per_people_f ppf
      WHERE  xuv.user_id     = cn_created_by
      AND    xuv.employee_id = ppf.person_id
      AND    SYSDATE         BETWEEN ppf.effective_start_date
                             AND     ppf.effective_end_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff       -- XXCFF
                                                       ,cv_msg_xxcff_00181   -- �擾�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE_NAME'
                                                       ,cv_msg_xxcff_50154   -- ���O�C��(���[�U��,��������)���
                                                       ,cv_tkn_key_name      -- �g�[�N��'KEY_NAME'
                                                       ,cv_msg_xxcff_50167   -- ���O�C�����[�UID=
                                                       ,cv_tkn_key_val       -- �g�[�N��'KEY_VAL'
                                                       ,cn_created_by)       -- ���O�C�����[�UID
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --===========================================
    -- ��v���떼�̎擾
    --===========================================
    BEGIN
      SELECT gsob.name   sob_name   --��v���떼
      INTO   gt_sob_name
      FROM   gl_sets_of_books gsob
      WHERE  gsob.set_of_books_id = g_init_rec.set_of_books_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff              -- XXCFF
                                                       ,cv_msg_xxcff_00181          -- �擾�G���[
                                                       ,cv_tkn_table                -- �g�[�N��'TABLE_NAME'
                                                       ,cv_msg_xxcff_50160          -- ��v���떼
                                                       ,cv_tkn_key_name             -- �g�[�N��'KEY_NAME'
                                                       ,cv_msg_xxcff_50168          -- ��v����ID=
                                                       ,cv_tkn_key_val              -- �g�[�N��'KEY_VAL'
                                                       ,g_init_rec.set_of_books_id) -- ��v����ID
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
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
    gn_warn_cnt           := 0;
    gn_target_lease_cnt   := 0;
    gn_target_vd_cnt      := 0;
    gn_normal_lease_cnt   := 0;
    gn_normal_vd_cnt      := 0;
    gn_error_cnt          := 0;
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
    -- �v���t�@�C���l�擾 (A-2)
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
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �O��쐬�ςݕ���U�֎d�󑶍݃`�F�b�N (A-4)
    -- ============================================
    chk_data_exist(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- ��ʉ�vOIF�o�^�����i���[�X�����U�ցj (A-5)
    -- ====================================
    ins_gl_oif_lease(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- ��ʉ�vOIF�o�^�����i���̋@�����U�ցj (A-6)
    -- ====================================
    ins_gl_oif_vd(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
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
    iv_period_name IN  VARCHAR2       -- 1.��v���Ԗ�
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
       iv_period_name -- ��v���Ԗ�
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�o��
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
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    -- �G���[���̏o�͌����ݒ�
    --===============================================================
    IF (lv_retcode = cv_status_error) THEN
      -- �����������[���ɃN���A����
      gn_normal_lease_cnt      := 0;
      gn_normal_vd_cnt         := 0;
      -- �G���[�����ɑΏی�����ݒ肷��
      gn_error_cnt             := gn_target_lease_cnt + gn_target_vd_cnt;
    END IF;
--
    --===============================================================
    -- ��ʉ�vOIF�o�^�����ɂ����錏���o��
    --===============================================================
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- ���̋@�����d��쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_xxcff_00115
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --===============================================================
    -- ���[�X��������U�֎d�󌏐�
    --===============================================================
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���[�X��������U�֎d�󌏐�
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_xxcff_00250
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
                    ,iv_token_value1 => TO_CHAR(gn_target_lease_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_lease_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --===============================================================
    -- ���̋@��������U�֎d�󌏐�
    --===============================================================
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���̋@��������U�֎d�󌏐�
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_xxcff_00251
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
                    ,iv_token_value1 => TO_CHAR(gn_target_vd_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_vd_cnt)
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
END XXCFF017A07C;
/
